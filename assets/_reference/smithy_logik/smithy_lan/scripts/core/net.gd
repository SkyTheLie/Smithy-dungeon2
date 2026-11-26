extends Node
## LAN play for two (autoload "Net", PROTOTYPE): one player hosts (admin panel, tab "LAN"), the
## other joins from the main menu ("LAN": games found in the network, or an IP address).
##
## How the prototype works:
## - The host plays his game as always. While he hosts, he announces the game every second by
##   UDP broadcast (DISCOVERY_PORT); the main menu of the other player lists it (servers).
## - Joining: the guest gets a snapshot of the host's game (SaveData.collect, like a save) and plays
##   on that copy with his own name and look. Gold, inventory and smelting of the guest are his own
##   copy; they are NOT saved (SaveSystem refuses to write while is_guest()). Later steps make the
##   host the only owner of the game state (MULTIPLAYER_PLAN.md, steps 2-5).
## - Both send their place ~20 times a second (scene, position, animation). On the same map the
##   other one shows up as a RemotePlayer next to the own figure.
## - The host's clock is the clock of both; the guest doesn't run story checks (GameState._process)
##   and sleeps when the host sleeps.
## Offline (mode OFFLINE) none of this runs and the single player game is unchanged.

## A guest joined, a guest left, hosting started or stopped, joining worked or failed.
signal status_changed
## The list of games found in the network changed (servers).
signal servers_changed

## Port of the game connection (ENet, UDP).
const GAME_PORT: int = 7777
## Port where hosts announce their game (UDP broadcast).
const DISCOVERY_PORT: int = 7778
## Players besides the host (the prototype handles one guest).
const MAX_GUESTS: int = 1
## Marks our announcements, so other programs on the port are ignored. Raise it when the
## protocol changes, then older versions don't find each other.
const PROTOCOL: String = "smithy-lan-1"
## Seconds between two announcements of a host.
const ANNOUNCE_INTERVAL: float = 1.0
## A game that didn't announce itself for this long leaves the list.
const SERVER_TIMEOUT_MSEC: int = 3500
## Seconds between two position updates (20 per second).
const POSE_INTERVAL: float = 0.05
## Seconds between two clock updates of the host.
const CLOCK_INTERVAL: float = 2.0
## The guest appears this far beside the host when he joins.
const JOIN_OFFSET := Vector2(20, 0)
## Name of the guest if he has no save to take his name from.
const DEFAULT_GUEST_NAME: String = "Gast"
const REMOTE_PLAYER_SCENE: PackedScene = preload("res://scenes/actors/remote_player.tscn")

enum Mode { OFFLINE, HOST, GUEST }

# Nothing here is saved on purpose: a connection is never part of a save.
var mode: Mode = Mode.OFFLINE
## Last problem for the windows (already translated), "" if none.
var last_error: String = ""
## The other players: peer id -> {"name", "look" (Appearance data), "scene", "position", "animation", "speed"}.
var peers: Dictionary[int, Dictionary] = {}
## Games found in the network: "ip:port" -> {"ip", "port", "name", "seen"} (seen = msec).
var servers: Dictionary[String, Dictionary] = {}
## true while the guest has the host's world (between joining and leaving).
var _in_world: bool = false
## true while the guest sleeps because the host slept (GameState.sleep lets him then).
var _following_host_sleep: bool = false
var _announcer: PacketPeerUDP
var _listener: PacketPeerUDP
var _announce_left: float = 0.0
var _pose_left: float = 0.0
var _clock_left: float = 0.0
## Figures of the other players in the current scene: peer id -> RemotePlayer. Untyped on purpose:
## a figure is freed with its scene, and a freed object must not land in a typed variable.
var _remote_nodes: Dictionary = {}


func _ready() -> void:
	# Keeps talking while the game is paused (settings window, morning report).
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	GameState.slept.connect(_on_host_slept)


func is_online() -> bool:
	return mode != Mode.OFFLINE


func is_host() -> bool:
	return mode == Mode.HOST


func is_guest() -> bool:
	return mode == Mode.GUEST


## Guest: true once the host's world arrived and is loaded.
func has_world() -> bool:
	return _in_world


## Whether GameState.sleep may run: always offline and for the host, for the guest only when the
## host sleeps (he is taken along).
func may_sleep() -> bool:
	return not is_guest() or _following_host_sleep


## Name of the other player (the first one), "" if nobody is there.
func get_partner_name() -> String:
	for id: int in peers:
		return str(peers[id].get("name", ""))
	return ""


# --- Hosting and joining ---------------------------------------------------------------

## Opens the running game for one guest and announces it in the network. Returns OK or the error
## (e.g. the port is taken by another running game); last_error then says why.
func host_game() -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(GAME_PORT, MAX_GUESTS)
	if error != OK:
		last_error = Language.translate("Hosten ging nicht (Port %d belegt?).") % GAME_PORT
		status_changed.emit()
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	last_error = ""
	_start_announcing()
	status_changed.emit()
	return OK


## Connects to a host (IP address or name). The world comes with _receive_world; until then
## is_guest() is true but the guest still is in the main menu.
func join_game(address: String) -> Error:
	leave()
	address = address.strip_edges()
	if address.is_empty():
		last_error = Language.translate("Bitte eine IP-Adresse eingeben.")
		status_changed.emit()
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, GAME_PORT)
	if error != OK:
		last_error = Language.translate("Keine Verbindung zu %s.") % address
		status_changed.emit()
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.GUEST
	last_error = ""
	status_changed.emit()
	return OK


## Ends hosting or leaves the host. The own game goes on (host) or stays as it is (guest; the
## main menu calls this when he goes back to it).
func leave() -> void:
	_stop_announcing()
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var was_online: bool = mode != Mode.OFFLINE
	mode = Mode.OFFLINE
	_in_world = false
	_following_host_sleep = false
	peers.clear()
	for id: int in _remote_nodes.keys():
		_remove_remote(id)
	if was_online:
		status_changed.emit()


## The IPv4 addresses of this PC in the local network (for the admin panel: "the guest types this").
static func get_local_addresses() -> Array[String]:
	var found: Array[String] = []
	for address: String in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		found.append(address)
	return found


func _on_peer_connected(id: int) -> void:
	# The guest says who he is (_request_join); a second guest is sent away there.
	if is_host() and peers.size() >= MAX_GUESTS:
		multiplayer.multiplayer_peer.disconnect_peer(id)


func _on_peer_disconnected(id: int) -> void:
	if not peers.has(id):
		return
	var who: String = str(peers[id].get("name", ""))
	peers.erase(id)
	_remove_remote(id)
	Events.message_requested.emit(Language.translate("%s hat das Spiel verlassen.") % who)
	status_changed.emit()


func _on_connected_to_server() -> void:
	var identity: Dictionary = get_own_identity()
	_request_join.rpc_id(1, PROTOCOL, identity["name"], identity["look"])


func _on_connection_failed() -> void:
	leave()
	last_error = Language.translate("Keine Verbindung zum Host.")
	status_changed.emit()


## The host ended the game or the network broke: the guest goes back to the main menu.
func _on_server_disconnected() -> void:
	var was_in_world: bool = _in_world
	leave()
	last_error = Language.translate("Die Verbindung zum Host ist weg.")
	status_changed.emit()
	if was_in_world:
		GameState.return_to_main_menu()


## Name and look the guest plays with: those of his newest save, else a random look.
static func get_own_identity() -> Dictionary:
	var slot: int = SaveSystem.get_newest_slot()
	var data: Dictionary = SaveSystem.read(slot) if slot != -1 else {}
	var look: Dictionary = data.get("player_appearance", {})
	if look.is_empty():
		look = Appearance.create_random().to_save_data()
	var player_name: String = str(data.get("player_name", ""))
	if player_name.is_empty():
		player_name = Language.translate(DEFAULT_GUEST_NAME)
	return {"name": player_name, "look": look}


## Host: a guest says hello. Wrong version or already a guest: he is sent away.
@rpc("any_peer", "call_remote", "reliable")
func _request_join(protocol: String, guest_name: String, look: Dictionary) -> void:
	if not is_host():
		return
	var id: int = multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL or peers.size() >= MAX_GUESTS:
		_join_refused.rpc_id(id, protocol != PROTOCOL)
		return
	peers[id] = {"name": guest_name, "look": look, "scene": "", "position": Vector2.ZERO, "animation": "idle_down", "speed": 1.0}
	_send_world(id)
	Events.message_requested.emit(Language.translate("%s ist beigetreten.") % guest_name)
	status_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _join_refused(wrong_version: bool) -> void:
	leave()
	last_error = Language.translate("Der Host hat eine andere Spielversion.") if wrong_version \
			else Language.translate("Das Spiel ist schon voll.")
	status_changed.emit()


## Host: sends the whole game (like a save) with the place of the host, so the guest starts there.
func _send_world(id: int) -> void:
	var data: Dictionary = SaveData.collect()
	var scene: Node = get_tree().current_scene
	data["scene"] = scene.scene_file_path if scene else GameState.START_SCENE
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player:
		var at: Vector2 = player.global_position + JOIN_OFFSET
		data["player_position"] = [at.x, at.y]
	_receive_world.rpc_id(id, pack_world(data), GameState.get_player_name(), GameState.player_appearance.to_save_data())


## Guest: the host's world arrives. Loaded like a save, then the own name and look are put back.
@rpc("authority", "call_remote", "reliable")
func _receive_world(packet: Dictionary, host_name: String, host_look: Dictionary) -> void:
	if not is_guest():
		return
	var data: Dictionary = unpack_world(packet)
	if data.is_empty():
		leave()
		last_error = Language.translate("Die Spielwelt kam kaputt an.")
		status_changed.emit()
		return
	peers[1] = {"name": host_name, "look": host_look, "scene": "", "position": Vector2.ZERO, "animation": "idle_down", "speed": 1.0}
	var identity: Dictionary = get_own_identity()
	GameState.load_from_data(data, Language.translate("Bei %s beigetreten") % host_name)
	GameState.player_name = identity["name"]
	GameState.player_appearance = Appearance.from_save_data(identity["look"])
	_in_world = true
	status_changed.emit()


## A save dictionary as a small packet (JSON, compressed). JSON on purpose: the guest gets exactly
## what loading a save file would give (numbers as floats and so on).
static func pack_world(data: Dictionary) -> Dictionary:
	var raw: PackedByteArray = JSON.stringify(data).to_utf8_buffer()
	return {"size": raw.size(), "bytes": raw.compress(FileAccess.COMPRESSION_ZSTD)}


## The other way round; {} if the packet is broken.
static func unpack_world(packet: Dictionary) -> Dictionary:
	var size: int = int(packet.get("size", 0))
	var bytes: Variant = packet.get("bytes")
	if size <= 0 or not bytes is PackedByteArray:
		return {}
	var raw: PackedByteArray = (bytes as PackedByteArray).decompress(size, FileAccess.COMPRESSION_ZSTD)
	var data: Variant = _parse_quietly(raw.get_string_from_utf8())
	return data if data is Dictionary else {}


## JSON.parse_string prints an error for every broken text; packets from other programs on the
## port must not fill the log.
static func _parse_quietly(text: String) -> Variant:
	var json := JSON.new()
	return json.data if json.parse(text) == OK else null


# --- Running together -----------------------------------------------------------------------

func _process(delta: float) -> void:
	_poll_discovery(delta)
	if not is_online() or peers.is_empty():
		return
	_pose_left -= delta
	if _pose_left <= 0.0:
		_pose_left = POSE_INTERVAL
		_send_pose()
	if is_host():
		_clock_left -= delta
		if _clock_left <= 0.0:
			_clock_left = CLOCK_INTERVAL
			_receive_clock.rpc(GameState.day_cycle.day, GameState.day_cycle.minutes)


## Sends where the own figure is (scene "" = no figure, e.g. in the main menu).
func _send_pose() -> void:
	if is_guest() and not _in_world:
		return
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var scene: Node = get_tree().current_scene
	if player == null or scene == null or GameState.in_main_menu:
		_receive_pose.rpc("", Vector2.ZERO, "", 1.0)
		return
	var pose: Dictionary = player.get_pose()
	_receive_pose.rpc(scene.scene_file_path, player.global_position, pose["animation"], pose["speed"])


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _receive_pose(scene: String, at: Vector2, animation: String, speed: float) -> void:
	var id: int = multiplayer.get_remote_sender_id()
	if not peers.has(id):
		return
	var info: Dictionary = peers[id]
	info["scene"] = scene
	info["position"] = at
	info["animation"] = animation
	info["speed"] = speed
	_update_remote(id)


## Shows, moves or removes the figure of player `id`: only on the same map as the own figure.
func _update_remote(id: int) -> void:
	var info: Dictionary = peers[id]
	var stored: Variant = _remote_nodes.get(id)
	var node: Node2D = stored if is_instance_valid(stored) else null
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var scene: Node = get_tree().current_scene
	var same_map: bool = player != null and scene != null and not str(info["scene"]).is_empty() \
			and info["scene"] == scene.scene_file_path
	if not same_map:
		_remove_remote(id)
		return
	if node == null or node.get_parent() != player.get_parent():
		_remove_remote(id)
		node = REMOTE_PLAYER_SCENE.instantiate()
		node.call("setup", str(info["name"]), Appearance.from_save_data(info["look"]))
		# Beside the own figure, so both are sorted by height (y_sort) the same way.
		player.get_parent().add_child(node)
		node.global_position = info["position"]
		_remote_nodes[id] = node
	node.call("move_to", info["position"], info["animation"], info["speed"])


func _remove_remote(id: int) -> void:
	var stored: Variant = _remote_nodes.get(id)
	_remote_nodes.erase(id)
	if is_instance_valid(stored):
		(stored as Node).queue_free()


## Guest: the host's clock. The day comes along too (the host slept or rode a carriage).
@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_clock(day: int, minutes: float) -> void:
	if not _in_world:
		return
	GameState.day_cycle.day = day
	GameState.day_cycle.set_minutes(minutes)


## Host slept: the guest sleeps too (his smelters catch up, morning screen), then the clock
## update brings both to the same morning.
func _on_host_slept(day: int) -> void:
	if is_host() and not peers.is_empty():
		_receive_host_sleep.rpc(day)


@rpc("authority", "call_remote", "reliable")
func _receive_host_sleep(_day: int) -> void:
	if not _in_world:
		return
	_following_host_sleep = true
	GameState.sleep()
	_following_host_sleep = false
	_clock_left = 0.0


# --- Finding games in the network -------------------------------------------------------------

func _start_announcing() -> void:
	_announcer = PacketPeerUDP.new()
	_announcer.set_broadcast_enabled(true)
	_announcer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_announce_left = 0.0


func _stop_announcing() -> void:
	if _announcer:
		_announcer.close()
	_announcer = null


## Main menu, window "LAN": listens for hosts until stop_discovery.
func start_discovery() -> void:
	if _listener:
		return
	_listener = PacketPeerUDP.new()
	var error: Error = _listener.bind(DISCOVERY_PORT)
	if error != OK:
		# e.g. a second game on the same PC listens already: only the IP field helps then.
		push_warning("LAN search: port %d is taken (error %d)." % [DISCOVERY_PORT, error])
		_listener = null
	servers.clear()
	servers_changed.emit()


func stop_discovery() -> void:
	if _listener:
		_listener.close()
	_listener = null
	servers.clear()


## The announcement a host sends (also used by the test).
static func make_announcement(host_name: String, open_slots: int) -> PackedByteArray:
	return JSON.stringify({"protocol": PROTOCOL, "name": host_name, "port": GAME_PORT, "open": open_slots}).to_utf8_buffer()


## Reads an announcement; {} if it is none of ours.
static func parse_announcement(bytes: PackedByteArray) -> Dictionary:
	var data: Variant = _parse_quietly(bytes.get_string_from_utf8())
	if not data is Dictionary or data.get("protocol", "") != PROTOCOL:
		return {}
	return {"name": str(data.get("name", "?")), "port": int(data.get("port", GAME_PORT)), "open": int(data.get("open", 0))}


func _poll_discovery(delta: float) -> void:
	if _announcer:
		_announce_left -= delta
		if _announce_left <= 0.0:
			_announce_left = ANNOUNCE_INTERVAL
			_announcer.put_packet(make_announcement(GameState.get_player_name(), MAX_GUESTS - peers.size()))
	if _listener == null:
		return
	var changed: bool = false
	while _listener.get_available_packet_count() > 0:
		var bytes: PackedByteArray = _listener.get_packet()
		var ip: String = _listener.get_packet_ip()
		var info: Dictionary = parse_announcement(bytes)
		if info.is_empty():
			continue
		var key: String = "%s:%d" % [ip, info["port"]]
		changed = changed or not servers.has(key) or servers[key]["open"] != info["open"]
		info["ip"] = ip
		info["seen"] = Time.get_ticks_msec()
		servers[key] = info
	for key: String in servers.keys():
		if Time.get_ticks_msec() - int(servers[key]["seen"]) > SERVER_TIMEOUT_MSEC:
			servers.erase(key)
			changed = true
	if changed:
		servers_changed.emit()
