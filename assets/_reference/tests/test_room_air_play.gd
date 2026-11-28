extends "res://assets/_reference/_lib/base_test.gd"
## Things in the air (floors.json theme "air" -> "air_types", scenes/run/room_air.gd): every theme
## names a known kind with sensible values; in the real run scene every room has its particles,
## already emitting, filling the room.

var game: Node
var content: Script


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	var floors: Dictionary = content.call("get_file", "floors")
	var kinds: Dictionary = floors.get("air_types", {})
	for theme_id: String in (floors.get("themes", {}) as Dictionary):
		var kind_id: String = String((floors["themes"] as Dictionary)[theme_id].get("air", ""))
		check(kinds.has(kind_id), "theme %s has a known air kind (%s)" % [theme_id, kind_id])
	for kind_id: String in kinds:
		if kind_id.begins_with("_"):
			continue
		var kind: Dictionary = kinds[kind_id]
		check((kind.get("color", []) as Array).size() == 4, "%s: color has 4 values" % kind_id)
		check(int(kind.get("amount", 0)) > 0 and int(kind.get("amount", 0)) <= 200, "%s: amount 1..200" % kind_id)
		check(float(kind.get("lifetime", 0.0)) > 0.5, "%s: lifetime sensible" % kind_id)
		check((kind.get("gravity", []) as Array).size() == 3 and (kind.get("speed", []) as Array).size() == 2, "%s: gravity and speed" % kind_id)
	for dungeon_id: String in ["", "vulkan", "frost"]:
		await _check_run(dungeon_id)
	content.set("active_dungeon", "")


func _check_run(dungeon_id: String) -> void:
	content.set("active_dungeon", dungeon_id)
	game.set("run", script("res://scripts/systems/run_state.gd").new(11))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var rooms: Dictionary = scene.get_node("%Dungeon").get("rooms")
	check(rooms.size() > 0, "%s: rooms built" % dungeon_id)
	for cell: Vector2i in rooms:
		var air: Node = (rooms[cell] as Node).get_node_or_null("Air")
		check(air is CPUParticles3D, "%s: room %s has air particles" % [dungeon_id, cell])
		if air is CPUParticles3D:
			check((air as CPUParticles3D).emitting and (air as CPUParticles3D).amount > 0, "%s: particles emit" % dungeon_id)
	scene.queue_free()
	await process_frame
