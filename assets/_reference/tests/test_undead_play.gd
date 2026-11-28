extends "res://assets/_reference/_lib/base_test.gd"
## Undead stand up again (enemies.json "revive" with "times" 0): in the real run scene a zombie
## collapses instead of dying, a glow lies under the body, left alone it stands up after its
## time with half of its full life, and that happens again and again (not just once); hitting
## the body while it lies there kills it for good. The Strohmann (times 2) still stays down after
## its second fall.

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
	await _again_and_again()
	await _destroy_body()
	await _limited()


func _spawn(id: String) -> Node:
	var enemy: Node = dungeon.call("spawn_enemy", id, player.global_position + Vector3(5.0, 0, 5.0))
	return enemy


func _glow(enemy: Node) -> bool:
	var glow: Variant = enemy.get("_rise_glow")
	return glow != null and is_instance_valid(glow)


func _again_and_again() -> void:
	var zombie: Node = _spawn("zombie")
	await physics_frame
	var full: float = float(zombie.get("max_hp"))
	for round_index: int in 3:
		zombie.call("take_damage", float(zombie.get("hp")) + 1.0, Vector3.ZERO, false)
		check(zombie.get("alive") and zombie.call("is_downed"), "fall %d: it collapses instead of dying" % (round_index + 1))
		check(_glow(zombie), "fall %d: a glow under the body" % (round_index + 1))
		check(await wait_until(func() -> bool: return not zombie.call("is_downed"), 4.5), "fall %d: left alone it stands up" % (round_index + 1))
		check(zombie.get("alive"), "fall %d: still alive" % (round_index + 1))
		check(is_equal_approx(float(zombie.get("hp")), full * 0.5), "fall %d: with half of its full life" % (round_index + 1))
		check(not _glow(zombie), "fall %d: the glow is gone" % (round_index + 1))
	await _clear_enemies()


func _destroy_body() -> void:
	var skeleton: Node = _spawn("skeleton")
	await physics_frame
	skeleton.call("take_damage", float(skeleton.get("max_hp")) + 1.0, Vector3.ZERO, false)
	check(skeleton.call("is_downed"), "the skeleton lies there")
	skeleton.call("take_damage", float(skeleton.get("hp")) + 0.5, Vector3.ZERO, false)
	check(not skeleton.get("alive"), "hit the body: gone for good")
	await physics_frame


func _limited() -> void:
	var straw: Node = _spawn("scarecrow")
	await physics_frame
	for round_index: int in 2:
		straw.call("take_damage", float(straw.get("hp")) + 1.0, Vector3.ZERO, false)
		check(straw.call("is_downed"), "Strohmann fall %d" % (round_index + 1))
		await wait_until(func() -> bool: return not straw.call("is_downed"), 4.5)
	straw.call("take_damage", float(straw.get("hp")) + 1.0, Vector3.ZERO, false)
	check(not straw.get("alive"), "after two falls the Strohmann stays down")
	await _clear_enemies()


func _clear_enemies() -> void:
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
