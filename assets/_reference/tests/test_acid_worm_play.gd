extends "res://assets/_reference/_lib/base_test.gd"
## Acid worm (enemies.json "acid_worm", BossBrain worm_dive / acid_spit, trait underground): in the
## real run scene it hides under the floor between attacks (cannot be hurt); worm_dive jumps out
## onto the spot where the player stood (visible in the air); acid_spit comes up and its blobs
## leave acid puddles ("acid" hazard; like every floor trap they spare a flying player).

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var room: Node3D


func run() -> void:
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
	player.set("invulnerable", 999.0)
	room = dungeon.call("get_room", dungeon.get("current_cell"))
	player.global_position = room.global_position + Vector3(-3.0, 0, 0)
	var worm: Node3D = dungeon.call("spawn_enemy", "acid_worm", room.global_position + Vector3(4.0, 0, 0))
	await physics_frame
	var brain: Object = worm.get("_brain")
	brain.set("_wait", 99.0)
	await physics_frame
	await physics_frame
	check(worm.get("hidden_phase"), "between attacks it is under the floor")
	var hp: float = float(worm.get("hp"))
	worm.call("take_damage", 5.0, Vector3.ZERO, false)
	check(is_equal_approx(float(worm.get("hp")), hp), "under the floor it cannot be hurt")
	# worm_dive: the jump lands where the player stood.
	var stood: Vector3 = player.global_position
	brain.set("_attack", "worm_dive")
	brain.call("_start", Vector3.LEFT)
	check(await wait_until(func() -> bool: return not worm.get("hidden_phase"), 3.0), "it jumps out (visible)")
	check(float(worm.get("_jump_y")) > 0.1 or await wait_until(func() -> bool: return float(worm.get("_jump_y")) > 0.1, 0.5), "in a high arc")
	check(await wait_until(func() -> bool: return float(brain.get("_step")) >= 1.0, 1.5), "and lands")
	var landed: Vector3 = worm.global_position
	check(Vector2(landed.x - stood.x, landed.z - stood.z).length() < 1.2, "on the spot where the player stood")
	await wait_until(func() -> bool: return String(brain.get("_attack")).is_empty(), 2.0)
	await physics_frame
	check(worm.get("hidden_phase"), "then it is under the floor again")
	# acid_spit: puddles.
	var hazards_before: int = (room.get("hazards") as Array).size()
	brain.set("_attack", "acid_spit")
	brain.call("_start", Vector3.LEFT)
	check(not worm.get("hidden_phase"), "to spit it comes up")
	check(await wait_until(func() -> bool: return (room.get("hazards") as Array).size() > hazards_before, 3.0), "the acid leaves puddles")
	var puddle: Node3D = (room.get("hazards") as Array)[(room.get("hazards") as Array).size() - 1]
	check(String(puddle.get("kind")) == "acid", "an acid puddle")
	worm.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
