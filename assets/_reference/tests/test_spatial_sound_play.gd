extends "res://assets/_reference/_lib/base_test.gd"
## Enemy sounds are 3D (AudioManager.play_sound_at / play_stream_at): an AudioStreamPlayer3D at
## the enemy in the dungeon world, heard by the camera of the run's SubViewport. Music stays plain.

func run() -> void:
	var game: Node = root.get_node("Game")
	var audio: Node = root.get_node("AudioManager")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(5))
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	player.set("invulnerable", 999.0)
	var viewport: SubViewport = scene.get_node("View/Viewport")
	check(viewport.audio_listener_enable_3d, "the dungeon view hears 3D sounds")
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", player.global_position + Vector3(6.0, 0, 0))
	var effects: Node3D = dungeon.get("effects")
	rat.call("sound", "enemy_shoot")
	var players: Array = effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D)
	check_eq(players.size(), 1, "an enemy sound is a 3D sound")
	if not players.is_empty():
		var sound: AudioStreamPlayer3D = players[0]
		check(Vector2(sound.global_position.x, sound.global_position.z).distance_to(Vector2(rat.global_position.x, rat.global_position.z)) < 0.01, "at the enemy")
		check(sound.max_distance > 0.0 and sound.unit_size > 0.0, "quieter further away (audio.json spatial)")
	rat.call("take_damage", 1.0, Vector3.ZERO, false)
	check(effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D).size() >= 2, "its hit sound too")
	audio.call("play_sound", "pickup")
	check_eq(effects.get_children().filter(func(n: Node) -> bool: return n is AudioStreamPlayer3D).size(), int(audio.call("spatial_count")), "the player's own sounds stay plain")
	scene.queue_free()
	await process_frame
