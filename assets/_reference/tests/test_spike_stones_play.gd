extends "res://assets/_reference/_lib/base_test.gd"
## Spiked stones (floors.json "spike_stones", SpikeStone): the data is complete; in the real run
## scene a stone on a line moves and turns round at the end (back and forth), one on a loop goes
## round; touching it hurts the player and pushes them away; a flying player is safe.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var room: Node3D


func run() -> void:
	var rules: Dictionary = script("res://scripts/core/content.gd").call("floors_extra", "spike_stones")
	check(float(rules.get("chance", 0.0)) > 0.0 and int(rules.get("damage", 0)) > 0, "spike stones: chance and damage")
	for entry: Variant in rules.get("paths", []):
		check(String((entry as Array)[0]) in ["line_x", "line_z", "square", "circle"], "known path %s" % (entry as Array)[0])
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	run_state = script("res://scripts/systems/run_state.gd").new(5)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	room = dungeon.call("get_room", dungeon.get("current_cell"))
	player.global_position = room.global_position
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var line: Node3D = dungeon.call("add_spike_stone", room, "line_x", 0, rng)
	var start: Vector3 = line.position
	await physics_frame
	await physics_frame
	check(line.position.distance_to(start) > 0.01, "the stone moves")
	check(await wait_until(func() -> bool: return line.position.x > 5.7, 7.0), "it reaches the end of its line")
	check(await wait_until(func() -> bool: return line.position.x < 5.0, 2.0), "and turns round")
	var loop: Node3D = dungeon.call("add_spike_stone", room, "square", 1, rng)
	check(await wait_until(func() -> bool: return loop.position.distance_to(Vector3(4.5, 0, 3.0)) < 0.2, 12.0), "a loop stone goes round its corners")
	# Touching hurts and pushes.
	player.set("invulnerable", 0.0)
	var before: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
	player.global_position = line.global_position + Vector3(0, 0, 0.3)
	await physics_frame
	check(int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue")) < before, "touching it hurts")
	check((player.get("velocity") as Vector3).length() > 1.0, "and pushes the player away")
	player.set("invulnerable", 999.0)
