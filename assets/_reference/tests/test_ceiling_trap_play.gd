extends "res://assets/_reference/_lib/base_test.gd"
## Monster trap (floors.json "ceiling_traps"): the data is complete; in the real run scene the
## hidden plate is invisible; stepping on it shows it, warns (red shadows, no enemies yet), then
## enemies of the floor drop around the player and the doors close; it works only once.

var scene: Node
var dungeon: Node
var player: Node3D
var room: Node3D


func run() -> void:
	var rules: Dictionary = script("res://scripts/core/content.gd").call("floors_extra", "ceiling_traps")
	check(float(rules.get("chance", 0.0)) > 0.0 and float(rules.get("warn", 0.0)) >= 0.6, "monster trap: chance and a fair warning")
	check((rules.get("count", []) as Array).size() == 2 and (rules.get("spread", []) as Array).size() == 2, "count and spread")
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(5))
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	player.set("invulnerable", 999.0)
	room = dungeon.call("get_room", dungeon.get("current_cell"))
	player.global_position = room.global_position + Vector3(-5.0, 0, 0)
	var plate: Node3D = dungeon.call("add_ceiling_trap", room, Vector3(3.0, 0, 2.0))
	await physics_frame
	var stone: MeshInstance3D = plate.get("_stone")
	check(not stone.visible, "the plate is hidden")
	var before: int = (dungeon.call("get_enemies") as Array).size()
	player.global_position = plate.global_position
	await physics_frame
	await physics_frame
	check(stone.visible and plate.get("spent"), "stepping on it shows it")
	check((dungeon.call("get_enemies") as Array).size() == before, "no enemies yet (warning first)")
	check(await wait_until(func() -> bool: return (dungeon.call("get_enemies") as Array).size() > before, 3.0), "then enemies drop down")
	check(dungeon.call("is_fighting"), "and it is a fight (doors shut)")
	var count: int = (dungeon.call("get_enemies") as Array).size()
	player.global_position = room.global_position + Vector3(-5.0, 0, 0)
	await physics_frame
	player.global_position = plate.global_position
	await create_timer(1.5).timeout
	check((dungeon.call("get_enemies") as Array).size() == count, "it works only once")
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
