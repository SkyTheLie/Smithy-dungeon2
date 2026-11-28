extends "res://assets/_reference/_lib/base_test.gd"
## Quiet sounds of the place (scenes/run/room_sounds.gd): every theme has a list of known, quiet
## sound types; in the run scene the sounds come as 3D sounds from inside the player's room, and
## by themselves after a few seconds.

var game: Node
var content: Script


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	_check_data()
	await _check_run()


func _check_data() -> void:
	var floors: Dictionary = content.call("get_file", "floors")
	var types: Dictionary = floors.get("ambience_types", {})
	var settings: Dictionary = floors.get("ambience", {})
	check((settings.get("every", []) as Array).size() == 2 and float(settings["every"][0]) > 1.0, "ambience every set")
	check((settings.get("distance", []) as Array).size() == 2, "ambience distance set")
	for theme_id: String in (floors.get("themes", {}) as Dictionary):
		var table: Array = (floors["themes"] as Dictionary)[theme_id].get("ambience", [])
		check(not table.is_empty(), "theme %s has ambience" % theme_id)
		for entry: Array in table:
			check(types.has(String(entry[0])), "%s: ambience type %s exists" % [theme_id, entry[0]])
			check(float(entry[1]) > 0.0, "%s: weight > 0" % theme_id)
	for kind: String in types:
		if kind.begins_with("_"):
			continue
		var voice: Dictionary = types[kind]
		check(float(voice.get("volume", 0.0)) <= -12.0, "%s stays quiet" % kind)
		check(float(voice.get("length", 0.0)) > 0.0 and float(voice.get("length", 0.0)) <= 3.0, "%s has a sensible length" % kind)


func _check_run() -> void:
	content.set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(3))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var audio: Node = root.get_node("AudioManager")
	var sounds: Node = dungeon.get_node_or_null("RoomSounds")
	check(sounds != null, "the dungeon has room sounds")
	if sounds == null:
		scene.queue_free()
		return
	var table: Array = (content.call("floor_data", 0) as Dictionary).get("ambience", [])
	var kinds: Array = []
	for entry: Array in table:
		kinds.append(String(entry[0]))
	var effects: Node = dungeon.get("effects")
	var before: int = effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D).size()
	var played: String = sounds.call("play_next")
	check(kinds.has(played), "plays a sound of the theme (%s)" % played)
	var players: Array = effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D)
	check(players.size() == before + 1, "as a 3D sound")
	if players.size() > before:
		var at: Vector3 = (players.back() as Node3D).global_position
		var player: Node3D = dungeon.get("player")
		var builder: Script = script("res://scenes/run/room_builder.gd")
		check_eq(builder.call("cell_at", at), builder.call("cell_at", player.global_position), "in the player's room")
	# By itself: within the longest wait a new sound starts.
	var count_before: int = int(audio.call("spatial_count"))
	var every: Array = (content.call("floors_extra", "ambience") as Dictionary).get("every", [5.0, 11.0])
	var more: bool = await wait_until(func() -> bool: return int(audio.call("spatial_count")) > count_before or effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D).size() > players.size(), float(every[1]) + 1.0)
	check(more, "sounds come by themselves")
	scene.queue_free()
	await process_frame
