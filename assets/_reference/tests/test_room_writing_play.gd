extends "res://assets/_reference/_lib/base_test.gd"
## Writing on the walls (scenes/run/room_writing.gd): every dungeon has its own lines plus the shared
## ones, the plan never uses a line twice and keeps to max_per_floor, and in the real run scene the
## lines hang on a short wall inside normal rooms.

var game: Node
var content: Script
var writing: Script


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	writing = script("res://scenes/run/room_writing.gd")
	_check_data()
	_check_plan()
	var found: int = 0
	for seed_value in range(1, 13):
		found += await _writings_of_run(seed_value)
	check(found > 0, "some runs have writing on the walls (%d)" % found)


func _check_data() -> void:
	var rules: Dictionary = content.call("floors_extra", "writings")
	check(float(rules.get("chance", -1.0)) > 0.0 and int(rules.get("max_per_floor", 0)) > 0, "writings rules set")
	check(not (content.call("story", "walls") as Array).is_empty(), "shared wall lines")
	for id: String in (content.call("dungeons") as Dictionary):
		var lines: Array = content.call("story", "walls_%s" % id)
		check(not lines.is_empty(), "dungeon %s has its own wall lines" % id)
		var all: Array = writing.call("lines_for", id)
		check(all.size() == lines.size() + (content.call("story", "walls") as Array).size(), "%s: shared and own lines" % id)


func _check_plan() -> void:
	var cells: Array[Vector2i] = []
	for i in 6:
		cells.append(Vector2i(i, 0))
	var lines: Array[String] = ["a", "b", "c"]
	var plan: Dictionary = writing.call("plan", cells, lines, {"chance": 1.0, "max_per_floor": 5}, 7)
	check_eq(plan.size(), 3, "no more lines than there are")
	var used: Array = plan.values()
	used.sort()
	check_eq(used, ["a", "b", "c"], "every line once")
	plan = writing.call("plan", cells, lines, {"chance": 1.0, "max_per_floor": 2}, 7)
	check_eq(plan.size(), 2, "max_per_floor")
	plan = writing.call("plan", cells, lines, {"chance": 0.0, "max_per_floor": 2}, 7)
	check_eq(plan.size(), 0, "chance 0 = none")


## Starts a run, checks the writings; returns how many there are.
func _writings_of_run(seed_value: int) -> int:
	content.set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(seed_value))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var builder: Script = script("res://scenes/run/room_builder.gd")
	var half_w: float = float(builder.get("ROOM_W")) / 2.0 - float(builder.get("WALL_T"))
	var count: int = 0
	var rooms: Dictionary = dungeon.get("rooms")
	for cell: Vector2i in rooms:
		var room: Node3D = rooms[cell]
		var label := room.get_node_or_null("Writing") as Label3D
		if label == null:
			continue
		count += 1
		check_eq(String(room.get("type")), "normal", "writing only in normal rooms")
		check(absf(absf(label.position.x) - half_w) < 0.1, "writing hangs on the east or west wall")
		check(absf(label.position.z) < 3.2 and label.position.y > 0.8 and label.position.y < 2.2, "writing at eye height on the wall")
		check(not label.text.is_empty(), "writing has text")
		# Facing into the room: its front (+Z of the label) points away from the wall.
		var front: Vector3 = label.global_transform.basis.z
		check(front.x * signf(label.position.x) < -0.9, "writing faces into the room")
	var rules: Dictionary = content.call("floors_extra", "writings")
	check(count <= int(rules.get("max_per_floor", 0)), "at most max_per_floor writings")
	scene.queue_free()
	await process_frame
	return count
