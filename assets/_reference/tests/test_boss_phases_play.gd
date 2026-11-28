extends "res://assets/_reference/_lib/base_test.gd"
## Boss phases (enemies.json "boss_phases", BossBrain): the data is complete; in the real run
## scene a boss starts in phase 1; below half life it roars (cannot be hurt meanwhile), turns a
## new colour, gets a new attack and shorter pauses (phase 2); below a quarter phase 3 with even
## shorter pauses and faster shots.

var scene: Node
var dungeon: Node
var player: Node3D


func run() -> void:
	var rules: Dictionary = script("res://scripts/core/content.gd").call("get_file", "enemies").get("boss_phases", {})
	var at: Array = rules.get("at", [])
	check(at.size() == 2 and float(at[0]) > float(at[1]), "two phase marks, going down")
	check((rules.get("pause", []) as Array).size() == 3 and (rules.get("shot_speed", []) as Array).size() == 3 and (rules.get("tint", []) as Array).size() == 3, "pause, shot speed and colour per phase")
	check(float((rules.get("pause", []) as Array)[2]) < float((rules.get("pause", []) as Array)[0]), "rage: shorter pauses")
	check(float(rules.get("transition", 0.0)) >= 0.8, "a roar between the phases")
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
	var boss: Node = dungeon.call("spawn_enemy", "ghost_lord", player.global_position + Vector3(0, 0, -5.0))
	await physics_frame
	var brain: Object = boss.get("_brain")
	check(int(brain.get("phase")) == 1, "starts in phase 1")
	var attacks_before: int = (brain.get("_attacks") as Array).size()
	var colour_before: Color = boss.get("_base_color")
	var full: float = float(boss.get("max_hp"))
	boss.call("take_damage", full * 0.52, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
	check(int(brain.get("phase")) == 2, "below half life: phase 2")
	check(brain.call("in_transition"), "it roars first")
	var hp: float = float(boss.get("hp"))
	boss.call("take_damage", 5.0, Vector3.ZERO, false)
	check(is_equal_approx(float(boss.get("hp")), hp), "cannot be hurt while roaring")
	check((boss.get("_base_color") as Color) != colour_before, "new colour")
	check((brain.get("_attacks") as Array).size() > attacks_before, "a new attack joins")
	check(float(brain.call("_pause_factor")) < 1.0, "shorter pauses")
	check(float(root.get_node("AudioManager").call("get_music_intensity")) > 1.0, "the music gets faster")
	check(await wait_until(func() -> bool: return not brain.call("in_transition"), 3.0), "the roar ends")
	boss.call("take_damage", float(boss.get("hp")) - full * 0.2, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
	check(int(brain.get("phase")) == 3, "below a quarter: phase 3")
	check(float(brain.call("shot_factor")) > 1.0, "faster shots in the rage")
	boss.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
