extends "res://assets/_reference/_lib/base_test.gd"
## The quarter of the ring under an enemy shows where it looks (Enemy.look_direction): a rat that
## runs at the player looks at him; the wedge turns with it; a shield bearer shows its shield
## side. Fixed seed.

var scene: Node
var dungeon: Node
var player: Node3D


func run() -> void:
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
	var base: Vector3 = player.global_position
	var rat: Node3D = dungeon.call("spawn_enemy", "rat", base + Vector3(4.0, 0, 0))
	var wedge: MeshInstance3D = rat.get_node("FacingWedge")
	check(wedge != null and wedge.visible, "a wedge lies under the enemy")
	check(await wait_until(func() -> bool:
			var to_player: Vector3 = (player.global_position - rat.global_position) * Vector3(1, 0, 1)
			return (rat.call("look_direction") as Vector3).dot(to_player.normalized()) > 0.9, 2.0), "running at the player it looks at him")
	var look: Vector3 = rat.call("look_direction")
	var wedge_forward: Vector3 = -wedge.global_basis.z
	check(Vector3(wedge_forward.x, 0, wedge_forward.z).normalized().dot(look) > 0.95, "the wedge points where it looks")
	var guard_id: String = ""
	for id: String in script("res://scripts/core/content.gd").call("enemies"):
		if bool((script("res://scripts/core/content.gd").call("enemy", id) as Dictionary).get("front_guard", false)):
			guard_id = id
			break
	if not guard_id.is_empty():
		var guard: Node3D = dungeon.call("spawn_enemy", guard_id, base + Vector3(-4.0, 0, 0))
		for i in 10:
			await physics_frame
		check((guard.call("look_direction") as Vector3).dot(guard.get("_facing") as Vector3) > 0.9, "a shield bearer shows its shield side")
	scene.queue_free()
	await process_frame
