extends "res://assets/_reference/_lib/base_test.gd"
## Shot colours (enemies.json shot_colors): every step is complete and has its own colour, the
## steps go up in damage; EnemyShot.look_for picks the step by damage (½ green, 1 red, 1½
## violet, 2 black, more gold); in the real run scene an enemy's shot shows the ball of its
## damage, heavier shots sound deeper, and a laser takes the colour of its damage.

var scene: Node
var dungeon: Node
var player: Node3D
var shot_script: Script


func run() -> void:
	shot_script = script("res://scenes/actors/enemy_shot.gd")
	_data()
	_steps()
	await _in_run()


func _data() -> void:
	var colors: Dictionary = (script("res://scripts/core/content.gd").call("get_file", "enemies") as Dictionary).get("shot_colors", {})
	var steps: Array = colors.get("steps", [])
	check(steps.size() >= 4, "at least four colour steps")
	var last: int = 0
	var seen: Array[String] = []
	for step: Variant in steps:
		var entry: Dictionary = step
		check(int(entry.get("damage", 0)) > last, "steps go up in damage")
		last = int(entry.get("damage", 0))
		check((entry.get("color", []) as Array).size() == 3 and (entry.get("core", []) as Array).size() == 3, "step %d has colour and core" % last)
		check(float(entry.get("size", 0.0)) > 0.0 and float(entry.get("pitch", 0.0)) > 0.0, "step %d has size and pitch" % last)
		var key: String = str(entry.get("color"))
		check(not seen.has(key), "step %d has its own colour" % last)
		seen.append(key)
		var trail: String = String(entry.get("trail", ""))
		check(trail in ["", "smoke", "sparks"], "step %d: known trail" % last)


func _steps() -> void:
	check_eq(int((shot_script.call("look_for", 1) as Dictionary).get("damage")), 1, "½ Kohle = first step")
	check_eq(int((shot_script.call("look_for", 0) as Dictionary).get("damage")), 1, "below the first step = first step")
	check_eq(int((shot_script.call("look_for", 3) as Dictionary).get("damage")), 3, "1½ = its own step")
	check_eq(int((shot_script.call("look_for", 9) as Dictionary).get("damage")), 5, "a lot = the last step")
	var green: Color = shot_script.call("color_for", 1)
	var red: Color = shot_script.call("color_for", 2)
	var violet: Color = shot_script.call("color_for", 3)
	check(green.g > green.r and green.g > green.b, "½ is green")
	check(red.r > red.g and red.r > red.b, "1 is red")
	check(violet.b > violet.g and violet.r > violet.g, "1½ is violet")
	check((shot_script.call("color_for", 4) as Color).get_luminance() < 0.2, "2 is black")
	check((shot_script.call("glow_color", 4) as Color).get_luminance() > 0.3, "but its light is bright (core)")
	check(float(shot_script.call("pitch_for", 4)) < float(shot_script.call("pitch_for", 1)), "heavier shots sound deeper")
	check(shot_script.call("ball_for", 1) != shot_script.call("ball_for", 2), "each step has its own ball")


func _in_run() -> void:
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
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", player.global_position + Vector3(4.0, 0, 0))
	await physics_frame
	for damage: int in [1, 3, 4]:
		rat.call("shoot", Vector3.BACK, {"damage": damage})
		var shot: Node3D = _newest_shot()
		check(shot != null, "the enemy shoots (damage %d)" % damage)
		if shot == null:
			continue
		var sprite: Sprite3D = null
		var light: OmniLight3D = null
		for child: Node in shot.get_children():
			if child is Sprite3D:
				sprite = child
			elif child is OmniLight3D:
				light = child
		check(sprite != null and sprite.texture == shot_script.call("ball_for", damage), "shot with damage %d shows its ball" % damage)
		check(light != null and light.light_color.is_equal_approx(shot_script.call("glow_color", damage)), "its light has the colour of its damage")
		shot.queue_free()
	var beam: Node3D = rat.call("fire_beam", Vector3.BACK, {"damage": 3, "aim": 0.2, "fire": 0.1})
	check((beam.get("color") as Color).is_equal_approx(shot_script.call("color_for", 3)), "a laser with 1½ is violet")
	beam.queue_free()
	await physics_frame


func _newest_shot() -> Node3D:
	var shots: Array[Node] = root.get_tree().get_nodes_in_group(&"enemy_shots")
	if shots.is_empty():
		return null
	return shots[shots.size() - 1] as Node3D
