extends "res://assets/_reference/_lib/base_test.gd"
## The guide of the very first run (DungeonGuide) in the real run scene: the start room doors stay
## shut, walking, looking and shooting open the door to the practice room, the practice rat does
## no harm and drops a rat fur, picking it up, opening the bag and putting the fur into the safe
## place ends the guide (MetaState.guide_done, all doors open). A run without the guide has none.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var guide: Node


func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	check(not meta.call("guide_done"), "a new game: the guide is still to come")
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(21)
	run_state.set("guided", true)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	guide = scene.get("guide")
	check(guide != null, "the guide leads the first run")
	if guide == null:
		return
	var hud: Node = scene.get_node("HUD")
	var box: Control = hud.get("guide_box")
	check(box != null and box.visible, "its line is shown")
	var start: Vector2i = dungeon.get("current_cell")
	var guide_cell: Vector2i = dungeon.get("guide_cell")
	check(guide_cell != Vector2i(-1, -1), "a practice room next to the start")
	check(_start_doors().all(func(door: Node) -> bool: return door.get("closed")), "the doors of the start room are shut")

	# 1-3: walk, look, shoot.
	check_eq(guide.get("step"), 0, "first: walking")
	player.global_position += Vector3(0, 0, -3.5)
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 1, 1.0), "walked: now looking")
	player.call("look", Vector2(4000, 0))
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 2, 1.0), "looked around: now shooting")
	Input.action_press(&"shoot")
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 3, 1.0), "shot: now go through the door")
	Input.action_release(&"shoot")
	for door: Node in _start_doors():
		var leads_to_practice: bool = (door.get("cells") as Array).has(guide_cell)
		check(door.get("closed") != leads_to_practice, "only the door to the practice room opens")

	# 4-5: the practice room and its rat.
	var room: Node3D = (dungeon.get("rooms") as Dictionary)[guide_cell]
	player.global_position = Vector3(room.global_position.x, 0, room.global_position.z + 2.5)
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 4, 2.0), "in the practice room: shoot the rat")
	var enemies: Array = dungeon.call("get_enemies")
	check(enemies.size() == 1 and (enemies[0] as Node).get("id") == "tutorial_rat", "only the practice rat")
	if enemies.is_empty():
		return
	var rat: Node3D = enemies[0]
	var health: int = run_state.get("health")
	rat.global_position = player.global_position + Vector3(0.3, 0, 0)
	for i in 40:
		await physics_frame
	check_eq(run_state.get("health"), health, "the practice rat does no harm")
	rat.call("take_damage", 99.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 5, 2.0), "rat beaten: pick up its loot")

	# 6: the fur.
	var fur: Node3D = null
	for node: Variant in room.get("loot"):
		if is_instance_valid(node) and (node as Node).get("material_id") == "rat_fur":
			fur = node
	check(fur != null, "it dropped a rat fur")
	if fur == null:
		return
	player.global_position = Vector3(fur.global_position.x, 0, fur.global_position.z)
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 6, 2.0), "picked up: now open the bag")

	# 7-8: the bag and the safe place.
	var window: CanvasLayer = scene.get("bag_window")
	window.call("open")
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 7, 1.0), "bag open: into the safe place")
	check((window.get("safe_board") as Object).get("pulse"), "the safe place pulses")
	check((window.get("_guide") as Label).visible, "the line is in the bag window too")
	var bag: Object = run_state.get("bag")
	var index: int = -1
	for i: int in bag.call("size"):
		if (bag.call("get_place", i) as Dictionary).get("id") == "rat_fur":
			index = i
	check(bag.call("move_to", index, bag.get("SAFE_ORIGIN"), false), "the fur goes into the safe place")
	check(await wait_until(func() -> bool: return int(guide.get("step")) == 8, 1.0), "done")
	check(meta.call("guide_done"), "the guide is saved as done")
	window.call("close")
	paused = false
	await physics_frame
	check(_start_doors().all(func(door: Node) -> bool: return not door.get("closed")), "every door of the start room is open")
	check_eq(start, Vector2i(4, 4), "(the start room)")

	# A run without the guide.
	scene.queue_free()
	await process_frame
	await process_frame
	run_state = script("res://scripts/systems/run_state.gd").new(22)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	check(scene.get("guide") == null, "later runs have no guide")
	dungeon = scene.get_node("%Dungeon")
	check(not _start_doors().is_empty() and _start_doors().all(func(door: Node) -> bool: return not door.get("closed")), "and open doors")


func _start_doors() -> Array:
	return dungeon.call("doors_of", Vector2i(4, 4))
