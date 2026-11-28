extends "res://assets/_reference/_lib/base_test.gd"
## The colourful feedback in the real run scene: a hit makes a damage number pop up over the
## enemy and the hit marker flash at the crosshair (red for a kill, with confetti); loot from the
## floor shows "+1 …" at the side; low life makes the edge pulse red; every button gets UiJuice;
## the end screen fills the EXP bar and bursts "Stufe X!" for a new level. Mood: a hit paints the
## enemy white for a moment, torches flicker their light, fireballs have a soft light spot.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object


func run() -> void:
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	script("res://scripts/systems/meta_state.gd").call("start_new")
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
	await _hits()
	await _flash_and_torches()
	await _loot()
	await _low_life()
	await _buttons()
	await _end_screen()


func _labels_in(node: Node) -> Array:
	return node.get_children().filter(func(n: Node) -> bool: return n is Label3D)


func _hits() -> void:
	var effects: Node3D = dungeon.get("effects")
	var crosshair: Control = scene.get_node("HUD/Crosshair")
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", player.global_position + Vector3(0, 0, -4.0))
	rat.call("take_damage", 1.0, Vector3.ZERO, false)
	var numbers: Array = _labels_in(effects)
	check_eq(numbers.size(), 1, "a hit: a number pops up")
	check(numbers.size() > 0 and (numbers[0] as Label3D).text == "1", "showing the damage")
	check(float(crosshair.get("_hit_left")) > 0.0 and not crosshair.get("_hit_killed"), "the hit marker flashes")
	rat.call("take_damage", 999.0, Vector3.ZERO, false)
	check(crosshair.get("_hit_killed"), "a kill: the marker turns red")
	check(_labels_in(effects).any(func(n: Label3D) -> bool: return n.text == "999" and n.font_size > 32), "a strong hit: a big number")
	check(effects.get_children().any(func(n: Node) -> bool: return n is CPUParticles3D), "confetti when it dies")
	check(await wait_until(func() -> bool: return _labels_in(effects).is_empty(), 2.0), "the numbers fade away")


func _flash_and_torches() -> void:
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", player.global_position + Vector3(2.0, 0, -4.0))
	await physics_frame
	var material: ShaderMaterial = rat.get("_material")
	check(material != null and material.get_shader_parameter("sprite_texture") != null, "the enemy picture has its own material with the sheet")
	rat.call("take_damage", 0.01, Vector3.ZERO, false)
	check_eq(material.get_shader_parameter("flash"), 1.0, "a hit paints the enemy white")
	check(await wait_until(func() -> bool: return float(material.get_shader_parameter("flash")) == 0.0, 0.5), "and only for a moment")
	rat.call("take_damage", 999.0, Vector3.ZERO, false)
	# Torches: their light changes over time.
	var room: Node = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")]
	var torch: Node = null
	for child: Node in room.get_children():
		if child is Sprite3D and child.get("light") != null:
			torch = child
	check(torch != null, "a torch with its light")
	if torch:
		var light: OmniLight3D = torch.get("light")
		var energies: Dictionary = {}
		for i: int in 20:
			await process_frame
			energies[snappedf(light.light_energy, 0.001)] = true
		check(energies.size() > 3, "the torch light flickers")
	# A fireball carries a light spot (Fx.halo: a quad with an additive material).
	var shot: Node3D = load("res://scenes/actors/projectile.gd").new()
	effects_holder().add_child(shot)
	shot.set_physics_process(false)
	check(shot.get_children().any(func(n: Node) -> bool: return n is MeshInstance3D and (n as MeshInstance3D).mesh is QuadMesh), "a fireball has a light spot")
	shot.queue_free()
	await wait_until(func() -> bool: return dungeon.call("get_enemies").is_empty(), 2.0)


func effects_holder() -> Node3D:
	return dungeon.get("effects")


func _loot() -> void:
	var popups: Control = scene.get_node("HUD").get("_loot_popups")
	var pickup: Node3D = dungeon.call("_drop_loot", (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")], player.global_position, "rat_fur", 2, false)
	check(pickup != null, "loot on the floor")
	check(await wait_until(func() -> bool: return popups.get_child_count() > 0, 2.0), "picking it up shows a line")
	if popups.get_child_count() > 0:
		check_eq((popups.get_child(0) as Label).text, "+2 Rattenfell", "\"+2 Rattenfell\"")


func _low_life() -> void:
	var hud: Node = scene.get_node("HUD")
	check(not hud.call("is_low_life_shown"), "full life: no warning")
	run_state.set("health", 1)
	run_state.emit_signal("changed")
	check(hud.call("is_low_life_shown"), "half a heart left: the edge pulses red")
	run_state.set("health", int(run_state.get("max_hearts")) * 2)
	run_state.emit_signal("changed")
	check(not hud.call("is_low_life_shown"), "healed: gone")


func _buttons() -> void:
	var button := Button.new()
	button.text = "x"
	root.add_child(button)
	await process_frame
	check(button.has_meta("juice"), "every new button gets UiJuice")
	button.mouse_entered.emit()
	for i in 12:
		await process_frame
	check(button.scale.x > 1.01, "it grows under the mouse")
	button.mouse_exited.emit()
	for i in 12:
		await process_frame
	check(is_equal_approx(button.scale.x, 1.0), "and shrinks back")
	button.queue_free()


func _end_screen() -> void:
	run_state.set("exp_earned", 120)
	run_state.set("levels_gained", script("res://scripts/systems/meta_state.gd").call("add_exp", 120))
	check(int(run_state.get("levels_gained")) >= 1, "enough EXP for a level")
	var end_screen: CanvasLayer = scene.get_node("EndScreen")
	end_screen.call("open", run_state, false, true)
	var bar: ProgressBar = end_screen.find_child("ExpBar", true, false)
	check(bar != null and bar.is_visible_in_tree(), "the EXP bar under the title")
	check(await wait_until(func() -> bool: return String(end_screen.call("level_burst_text")).begins_with("Stufe"), 3.0), "a new level bursts")
	paused = false
	scene.queue_free()
	await process_frame
