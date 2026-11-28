extends "res://assets/_reference/_lib/base_test.gd"
## Wall ghost (enemies.json ai "wall_ghost", EnemyMoves): in the real run scene the Wandgeist
## starts hidden in a wall (cannot be hurt), comes out at a wall with a warning, pulls the player
## towards itself while out, claws a player who comes close, and sinks back after a hit.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object


func run() -> void:
	var data: Dictionary = script("res://scripts/core/content.gd").call("enemy", "wall_wraith")
	for key: String in ["emerge", "out", "hide", "pull", "reach", "claw_windup"]:
		check(float(data.get(key, 0.0)) > 0.0, "Wandgeist: %s" % key)
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
	var room: Node3D = dungeon.call("get_room", dungeon.get("current_cell"))
	player.global_position = room.global_position
	var ghost: Node3D = dungeon.call("spawn_enemy", "wall_wraith", room.global_position + Vector3(3, 0, 2))
	await physics_frame
	check(ghost.get("hidden_phase"), "it starts hidden")
	var hp: float = float(ghost.get("hp"))
	ghost.call("take_damage", 3.0, Vector3.ZERO, false)
	check(is_equal_approx(float(ghost.get("hp")), hp), "hidden it cannot be hurt")
	var moves: Object = ghost.get("_moves")
	check(await wait_until(func() -> bool: return int(moves.get("_state")) == 1, 3.0), "it starts to come out (warning)")
	var spot: Vector3 = moves.get("place")
	var rect: Rect2 = dungeon.call("rect_of", dungeon.get("current_cell"), 0.0)
	var to_wall: float = minf(minf(absf(spot.x - rect.position.x), absf(rect.end.x - spot.x)), minf(absf(spot.z - rect.position.y), absf(rect.end.y - spot.z)))
	check(to_wall < 1.0, "it comes out at a wall")
	check(await wait_until(func() -> bool: return not ghost.get("hidden_phase"), 2.0), "then it is out")
	# Pulled: standing still, the player drifts towards it.
	player.global_position = Vector3(room.global_position.x, player.global_position.y, room.global_position.z)
	var before: float = player.global_position.distance_to(spot)
	await create_timer(0.5).timeout
	check(player.global_position.distance_to(spot) < before - 0.2, "it pulls the player towards itself")
	# Close: it claws.
	player.set("invulnerable", 0.0)
	var life: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
	player.global_position = Vector3(spot.x, player.global_position.y, spot.z) + (Vector3(rect.get_center().x, 0, rect.get_center().y) - Vector3(spot.x, 0, spot.z)).normalized() * 1.0
	check(await wait_until(func() -> bool: return int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue")) < life, 2.0), "close to it, it claws")
	player.set("invulnerable", 999.0)
	check(await wait_until(func() -> bool: return ghost.get("hidden_phase"), 2.0), "after the claw it sinks back")
	check(await wait_until(func() -> bool: return not ghost.get("hidden_phase"), 6.0), "and comes out again")
	ghost.call("take_damage", 2.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return ghost.get("hidden_phase"), 1.0), "a hit sends it back into the wall")
	ghost.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
