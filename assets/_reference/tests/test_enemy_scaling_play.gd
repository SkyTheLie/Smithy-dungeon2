extends "res://assets/_reference/_lib/base_test.gd"
## Enemies hurt more in deeper dungeons (dungeons.json "damage_mult", Enemy.hit_damage): the
## dungeons go up in damage and life; in the real run scene of the Glutschlund an enemy's shot
## and touch hurt twice as much as in the Glut (rounded, at least half a heart, 0 stays 0).

func run() -> void:
	var content: Script = script("res://scripts/core/content.gd")
	var dungeons: Dictionary = content.call("dungeons")
	var last_damage: float = 0.0
	for id: String in ["glut", "moor", "frost", "vulkan"]:
		var mult: float = float((dungeons[id] as Dictionary).get("damage_mult", 0.0))
		check(mult >= 1.0 and mult >= last_damage, "%s: damage_mult goes up (%.1f)" % [id, mult])
		last_damage = mult
	check(is_equal_approx(float((content.call("floor_data", 0, "vulkan") as Dictionary).get("damage_mult", 0.0)), float((dungeons["vulkan"] as Dictionary)["damage_mult"])), "the floors know the dungeon's damage_mult")
	var game: Node = root.get_node("Game")
	content.set("active_dungeon", "vulkan")
	game.set("run", script("res://scripts/systems/run_state.gd").new(5))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	var mult: float = float((dungeons["vulkan"] as Dictionary)["damage_mult"])
	var enemy: Node = dungeon.call("spawn_enemy", "giant_rat", player.global_position + Vector3(5, 0, 5))
	await physics_frame
	check_eq(int(enemy.call("hit_damage", 1)), maxi(1, roundi(1 * mult)), "half a heart becomes more")
	check_eq(int(enemy.call("hit_damage", 2)), roundi(2 * mult), "a heart becomes more")
	check_eq(int(enemy.call("hit_damage", 0)), 0, "0 stays 0")
	enemy.call("shoot", Vector3.BACK, {"damage": 2})
	var shots: Array[Node] = root.get_tree().get_nodes_in_group(&"enemy_shots")
	check(not shots.is_empty() and int(shots[shots.size() - 1].get("damage")) == roundi(2 * mult), "its shots hurt more too")
	enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
	content.set("active_dungeon", "")
