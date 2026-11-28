extends "res://assets/_reference/_lib/base_test.gd"
## Decoration in the rooms (floors.json theme "props", scenes/run/room_props.gd): every theme has a
## list whose pictures exist; in the real run scene the rooms get a few props along the walls,
## inside the room, never in a doorway; only crates, barrels … (props "break") have a body, and a
## bomb or a shot breaks them. Same seed = same props.

var game: Node
var content: Script


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	_check_data()
	var first: Array[Vector3] = await _props_of_run(5)
	check(first.size() > 0, "rooms have decoration")
	var again: Array[Vector3] = await _props_of_run(5)
	check_eq(again, first, "same seed, same decoration")
	await _check_breaking()


func _check_data() -> void:
	var floors: Dictionary = content.call("get_file", "floors")
	var settings: Dictionary = floors.get("props", {})
	check(settings.has("count") and settings.has("min_gap") and settings.has("inset"), "props settings complete")
	for theme_id: String in (floors.get("themes", {}) as Dictionary):
		var table: Array = (floors["themes"] as Dictionary)[theme_id].get("props", [])
		check(not table.is_empty(), "theme %s has props" % theme_id)
		for entry: Array in table:
			check(entry.size() == 3, "%s: prop entry has texture, weight, height" % theme_id)
			check(ResourceLoader.exists(String(entry[0])), "%s: picture exists %s" % [theme_id, entry[0]])
			check(float(entry[1]) > 0.0 and float(entry[2]) > 0.1 and float(entry[2]) < 3.0, "%s: weight and height sensible" % theme_id)
	var rules: Dictionary = settings.get("break", {})
	var sounds: Dictionary = (content.call("get_file", "audio") as Dictionary).get("sounds", {})
	check(not (rules.get("textures", {}) as Dictionary).is_empty(), "props break lists textures")
	for texture: String in (rules.get("textures", {}) as Dictionary):
		check(ResourceLoader.exists(texture), "breakable picture exists %s" % texture)
		check(sounds.has(String(rules["textures"][texture])), "break sound exists for %s" % texture)
	check(float(rules.get("coin_chance", -1.0)) >= 0.0 and (rules.get("coins", []) as Array).size() == 2, "break coins set")


## Starts a run with `seed_value`, checks every room's props, returns their positions (world).
func _props_of_run(seed_value: int) -> Array[Vector3]:
	content.set("active_dungeon", "")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(seed_value)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var builder: Script = script("res://scenes/run/room_builder.gd")
	var half_w: float = float(builder.get("ROOM_W")) / 2.0 - float(builder.get("WALL_T"))
	var half_d: float = float(builder.get("ROOM_D")) / 2.0 - float(builder.get("WALL_T"))
	var door_clear: float = float(builder.get("DOOR_W")) / 2.0
	var positions: Array[Vector3] = []
	var rooms: Dictionary = dungeon.get("rooms")
	for cell: Vector2i in rooms:
		var room: Node3D = rooms[cell]
		var holder: Node = room.get_node_or_null("Props")
		check(holder != null, "room has a Props node")
		if holder == null:
			continue
		for child: Node in holder.get_children():
			var at: Vector3 = (child as Node3D).position
			positions.append(room.position + at)
			check(absf(at.x) <= half_w and absf(at.z) <= half_d, "prop inside the room")
			if child is Sprite3D:
				check(child.get_child_count() == 0, "plain prop has no collision")
			else:
				check(child is StaticBody3D and (room.get("breakables") as Array).has(child), "breakable prop is a body the room knows")
			# Near a wall that has a doorway, the prop keeps out of the opening.
			for dir: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
				if not rooms.has(cell + dir):
					continue
				var near_wall: bool = (dir.y != 0 and absf(at.z) > half_d - 1.0 and signf(at.z) == dir.y) \
						or (dir.x != 0 and absf(at.x) > half_w - 1.0 and signf(at.x) == dir.x)
				var along: float = at.x if dir.y != 0 else at.z
				if near_wall:
					check(absf(along) > door_clear, "prop not in a doorway")
	scene.queue_free()
	await process_frame
	return positions


## A bomb next to a crate breaks it (gone from the room), a shot at another one too.
func _check_breaking() -> void:
	content.set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(5))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var props: Array = []
	for room: Node3D in (dungeon.get("rooms") as Dictionary).values():
		for prop: Variant in room.get("breakables"):
			props.append(prop)
	check(props.size() >= 2, "the run has crates or barrels (%d)" % props.size())
	if props.size() < 2:
		scene.queue_free()
		return
	var first: Node3D = props[0]
	var room_of_first: Node = first.get_parent().get_parent()
	dungeon.call("explode", first.global_position + Vector3(0.3, 0.2, 0), 1.0, 1.0, false)
	check(not (room_of_first.get("breakables") as Array).has(first), "bomb breaks the crate")
	await process_frame
	check(not is_instance_valid(first), "broken crate is gone")
	# A shot flying at the second one.
	var second: Node3D = props[1]
	var target: Vector3 = second.global_position + Vector3(0, 0.3, 0)
	var inward: Vector3 = ((second.get_parent().get_parent() as Node3D).global_position - target) * Vector3(1, 0, 1)
	var from: Vector3 = target + inward.normalized() * 1.5
	var player: Node3D = dungeon.get("player")
	var stats: Object = (game.get("run") as Object).get("stats")
	var shot: Object = script("res://scenes/actors/projectile.gd").new()
	shot.call("setup", dungeon, player, stats, -inward.normalized(), 0.0, false)
	(dungeon.get("effects") as Node).add_child(shot)
	(shot as Node3D).global_position = from
	await wait_until(func() -> bool: return not is_instance_valid(second), 3.0)
	check(not is_instance_valid(second), "a shot breaks the barrel")
	scene.queue_free()
	await process_frame
