extends "res://assets/_reference/_lib/base_test.gd"
## Arrow traps (floors.json "arrow_traps", ArrowTrap, PressurePlate): the data is complete; in the
## real run scene a timed hole warns first (glows, no arrow yet), then an arrow flies and hurts
## the player; a row of holes shoots one after another; a pressure plate makes its holes shoot
## when the player steps on it, and also when an enemy does; an arrow hurts an enemy in its way.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var room: Node3D


func run() -> void:
	_data()
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
	await _timed()
	await _row()
	await _plate()


func _data() -> void:
	var rules: Dictionary = script("res://scripts/core/content.gd").call("floors_extra", "arrow_traps")
	check(float(rules.get("chance", 0.0)) > 0.0, "arrow traps have a chance")
	check(float(rules.get("warn", 0.0)) >= 0.4, "a fair warning before every arrow")
	check(int(rules.get("damage", 0)) > 0 and float(rules.get("enemy_damage", 0.0)) > 0.0, "they hurt player and enemies")
	for entry: Variant in rules.get("kinds", []):
		check(String((entry as Array)[0]) in ["timed", "row", "plate"], "known kind %s" % (entry as Array)[0])
		check(rules.has(String((entry as Array)[0])), "settings for %s" % (entry as Array)[0])


func _clear() -> void:
	for trap: Node in (room.get("arrow_traps") as Array):
		trap.queue_free()
	for plate: Node in (room.get("plates") as Array):
		plate.queue_free()
	(room.get("arrow_traps") as Array).clear()
	(room.get("plates") as Array).clear()
	for shot: Node in root.get_tree().get_nodes_in_group(&"enemy_shots"):
		shot.queue_free()
	await physics_frame


func _life() -> int:
	return int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))


func _timed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	dungeon.call("add_arrow_traps", room, "timed", rng)
	var traps: Array = room.get("arrow_traps")
	check(traps.size() >= 1, "timed: at least one hole")
	var trap: Node3D = traps[0]
	# Stand in its lane, in the middle of the room.
	player.global_position = Vector3(room.global_position.x, player.global_position.y, trap.global_position.z)
	player.set("invulnerable", 0.0)
	var before: int = _life()
	check(await wait_until(func() -> bool: return trap.call("is_warning"), 4.0), "it warns before it shoots")
	check(root.get_tree().get_nodes_in_group(&"enemy_shots").is_empty(), "no arrow during the warning")
	check(await wait_until(func() -> bool: return _life() < before, 4.0), "then the arrow hurts the player in its lane")
	player.set("invulnerable", 999.0)
	await _clear()


func _row() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	dungeon.call("add_arrow_traps", room, "row", rng)
	var traps: Array = room.get("arrow_traps")
	check(traps.size() == 4, "row: four holes")
	check(await wait_until(func() -> bool: return (traps[0] as Node).call("is_warning"), 3.0), "the first hole warns")
	check(not (traps[3] as Node).call("is_warning"), "the last one later (one after another)")
	check(await wait_until(func() -> bool: return (traps[3] as Node).call("is_warning"), 2.0), "then the last one")
	await _clear()


func _plate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	player.global_position = room.global_position + Vector3(0, 0, -4.8)
	dungeon.call("add_arrow_traps", room, "plate", rng)
	var traps: Array = room.get("arrow_traps")
	var plate: Node3D = (room.get("plates") as Array)[0]
	await physics_frame
	check(not (traps[0] as Node).call("is_warning"), "plate holes wait")
	player.global_position = Vector3(plate.global_position.x, player.global_position.y, plate.global_position.z)
	await physics_frame
	await physics_frame
	check((traps[0] as Node).call("is_warning") and (traps[1] as Node).call("is_warning"), "stepping on the plate starts them")
	player.global_position = room.global_position + Vector3(0, 0, 0.2)
	await wait_until(func() -> bool: return not (traps[0] as Node).call("is_warning"), 2.0)
	for shot: Node in root.get_tree().get_nodes_in_group(&"enemy_shots"):
		shot.queue_free()
	await create_timer(2.2).timeout
	# An enemy on the plate starts them too, and their arrow hurts an enemy in the lane.
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", Vector3(plate.global_position.x, 0, plate.global_position.z))
	rat.set("_awake", false)
	rat.set("_wake_left", 99.0)
	await physics_frame
	await physics_frame
	check((traps[0] as Node).call("is_warning") or (traps[1] as Node).call("is_warning"), "an enemy on the plate starts them too")
	var hp: float = float(rat.get("hp"))
	check(await wait_until(func() -> bool: return not is_instance_valid(rat) or float(rat.get("hp")) < hp, 3.0), "the arrow hurts the enemy in its lane")
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await _clear()
