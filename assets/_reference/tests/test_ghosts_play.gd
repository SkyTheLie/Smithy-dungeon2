extends "res://assets/_reference/_lib/base_test.gd"
## Ghosts fade out (enemies.json "invisible"): the data is complete for every ghost; in the real
## run scene an awake ghost fades out after a while (no picture, no ring), it does not hurt the
## player by touching while unseen, aiming help skips it, a hit shows it for a moment, and it
## shows again after its time. Fixed: the test waits for conditions, not for seconds.

var scene: Node
var dungeon: Node
var player: Node3D


func run() -> void:
	_data()
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
	await _fades()


func _data() -> void:
	var enemies: Dictionary = script("res://scripts/core/content.gd").call("enemies")
	var ghosts: int = 0
	for id: String in enemies:
		var cfg: Dictionary = (enemies[id] as Dictionary).get("invisible", {})
		if cfg.is_empty():
			continue
		ghosts += 1
		var every: Array = cfg.get("every", [])
		check(every.size() == 2 and float(every[0]) > 0.5 and float(every[1]) >= float(every[0]), "%s: invisible every [min, max]" % id)
		check(float(cfg.get("duration", 0.0)) > 0.5, "%s: invisible duration" % id)
		check(float(cfg.get("hit_reveal", 0.0)) > 0.0, "%s: a hit shows it" % id)
		check(not (cfg.get("whisper", {}) as Dictionary).is_empty(), "%s: it whispers while unseen (sound rule)" % id)
	check(ghosts >= 3, "at least three ghosts can fade out")


func _fades() -> void:
	var ghost: Node = dungeon.call("spawn_enemy", "ghost", player.global_position + Vector3(6.0, 0, 6.0))
	await physics_frame
	ghost.set("_awake", true)
	check(await wait_until(func() -> bool: return ghost.call("is_unseen"), 6.0), "the ghost fades out")
	var ring: Node3D = ghost.get("_ring")
	await physics_frame
	check(not ring.visible, "no ring while unseen")
	check((ghost.get("_sprite") as Sprite3D).modulate.a < 0.5, "its picture is (nearly) gone")
	check(dungeon.call("nearest_enemy", player.global_position, 100.0, []) != ghost, "aiming help skips it")
	# Touching the player while unseen does nothing.
	player.set("invulnerable", 0.0)
	var run_state: Object = root.get_node("Game").get("run")
	var before: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
	ghost.set("global_position", player.global_position + Vector3(0.2, 0, 0))
	await physics_frame
	await physics_frame
	if ghost.get("invisible"):
		check(int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue")) == before, "unseen it does not hurt by touching")
	ghost.set("global_position", player.global_position + Vector3(6.0, 0, 6.0))
	player.set("invulnerable", 999.0)
	if ghost.get("invisible"):
		ghost.call("take_damage", 0.5, Vector3.ZERO, false)
		check(not ghost.call("is_unseen"), "a hit shows it for a moment")
	check(await wait_until(func() -> bool: return not ghost.get("invisible"), 4.0), "it shows again after its time")
	await physics_frame
	check(ring.visible, "ring back when seen")
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
