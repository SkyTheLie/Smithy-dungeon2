class_name Station
extends StaticBody2D
## A workstation (anvil, smelter, ...) the player can use with the interact key.
## `required_flag`: the station only exists once this story flag is set (e.g. the water trough
## is bought later). `blocked`: can't be used right now (e.g. covered by a cobweb).
## Every station gets a golden outline (GuideOutline) that shows while the story guide points at
## it (Guide, target `get_guide_id()`, e.g. "station:smelter").

## Emitted when the player presses the interact key while standing next to the station.
## When several things are in reach, E goes to the nearest one that wants it (is_nearest_interactable).
signal interacted
## Emitted when the player walks out of the interaction area (used to close the menu).
signal player_left

## Story flag (GameState.story) the station needs to exist. Empty = always there.
@export var required_flag: String = ""
## Story flag from which E works here; before it the station stands there but takes no E (e.g. the
## anvil of the altar of the nine: only for the true setting at the end). Empty = always usable.
@export var usable_flag: String = ""

## Target name for the guide (Guide). Empty = "station:<scene or script file name>".
@export var guide_id: String = ""

## Everything E can reach (stations, story figures, doors with needs_interact); E goes to the
## nearest one that wants it.
const INTERACT_GROUP: StringName = &"interactables"

## true = interacting does nothing (e.g. a Cobweb covers the station).
var blocked: bool = false
var _player_in_range: bool = false


func _ready() -> void:
	if not GameState.story.has_flag(required_flag):
		queue_free()
		return
	add_to_group(INTERACT_GROUP)
	if GameState.house.is_station_stored(get_store_id()):
		set_stored(true)


# Also for subclasses whose _ready() does not call super() (Merchant, Cobweb).
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY and not is_queued_for_deletion():
		GuideOutline.attach(self, is_guide_target, get_guide_shape())


## E.g. "station:smelter" (smelter.tscn), "station:storage_chest" (a node with that script).
func get_guide_id() -> String:
	if not guide_id.is_empty():
		return guide_id
	var path: String = scene_file_path if not scene_file_path.is_empty() else (get_script() as Script).resource_path
	return "station:" + path.get_file().get_basename()


## Whether the guide points at this station now (merchants: whether they have a ware to buy).
func is_guide_target() -> bool:
	return visible and not blocked and is_usable() and Guide.is_target(get_guide_id())


## For stations without a Sprite2D: Callable returning {"texture", "rect"} of their picture
## (GuideOutline). Invalid = the outline uses the first Sprite2D child.
func get_guide_shape() -> Callable:
	return Callable()


## The id of this station in economy.json "stations" (bought stations, their `flag` is our
## `required_flag`); only those can go into the house storage (HouseEditor). "" = none.
func get_store_id() -> String:
	if required_flag.is_empty():
		return ""
	var offers: Dictionary = ContentDB.economy("stations")
	for id: String in offers:
		if offers[id].get("flag", "") == required_flag:
			return id
	return ""


## In storage: invisible, not usable, no collision (a disabled node leaves the physics).
func set_stored(stored: bool) -> void:
	visible = not stored
	process_mode = Node.PROCESS_MODE_DISABLED if stored else Node.PROCESS_MODE_INHERIT
	if stored:
		_player_in_range = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and wants_interact() and is_nearest_interactable(self):
		interacted.emit()
		GameState.story.show_hint(get_first_use_hint())
		get_viewport().set_input_as_handled()


## Tip shown the first time the player uses this station (only once per tip): general.json
## "station_hints" by guide id, e.g. "station:anvil" » "anvil". So the long station tips come when
## the player really forges, not while cleaning cobwebs. "" = none.
func get_first_use_hint() -> String:
	return str(Story.get_data("station_hints").get(get_guide_id(), ""))


## true if E would do something here now (player in reach, not blocked). Subclasses add their rules.
func wants_interact() -> bool:
	return _player_in_range and not blocked and visible and is_usable()


## false while `usable_flag` is not set yet.
func is_usable() -> bool:
	return GameState.story.has_flag(usable_flag)


## Higher wins over nearer: e.g. a story figure whose conversation is open (E turns the page).
func interact_priority() -> int:
	return 0


## true if `candidate` is the one E belongs to: of everything in INTERACT_GROUP that wants it, the
## highest interact_priority(), then the nearest to the player.
static func is_nearest_interactable(candidate: Node) -> bool:
	var player := candidate.get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null:
		return true
	var best: Node = null
	var best_priority: int = -1
	var best_distance: float = INF
	for node: Node in candidate.get_tree().get_nodes_in_group(INTERACT_GROUP):
		if not node.wants_interact():
			continue
		var priority: int = node.interact_priority()
		var distance: float = (node as Node2D).global_position.distance_to(player.global_position)
		if priority > best_priority or (priority == best_priority and distance < best_distance):
			best = node
			best_priority = priority
			best_distance = distance
	return best == null or best == candidate


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		player_left.emit()
