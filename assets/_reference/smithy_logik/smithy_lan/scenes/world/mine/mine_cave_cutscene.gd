class_name MineCaveCutscene
extends Node2D
## The cave-in in the small mine (dialogues "miner_cave_in" and "miner_hole"). Each beat is a line
## with "hide_for" (the dialogue box is out of sight while it plays) and "cutscene:<id>":
## - miner_knock: Gustav knocks three times against the rubble with his pickaxe
## - cave_in: a rumble, dust trickles from the ceiling, the rubble collapses into the hole
##   (flag mine_cave_in at the end: CaveInRubble goes, MineHole comes)
## - rats_out: red eyes flash in the hole, then the rats scurry out to their places
##   (flag mine_rats_out: MineRats)
## - miner_peek: Gustav climbs over the stones and shines his lamp into the hole

@export var miner: NodePath
@export var rubble: NodePath
@export var hole: NodePath
@export var rats: NodePath

const EYES: String = "res://assets/sprites/props/rat_eyes.png"
const LAMP: Color = Color(1.0, 0.8, 0.45)

var _fx: WorldVfx


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)
	_fx = WorldVfx.new()
	add_child(_fx)


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"miner_knock":
			_knock()
		"cave_in":
			_cave_in()
		"rats_out":
			_rats_out()
		"miner_peek":
			_peek()


func _node(path: NodePath) -> Node2D:
	return get_node_or_null(path) as Node2D


func _knock() -> void:
	var gustav := _node(miner)
	var wall := _node(rubble)
	if gustav == null:
		return
	gustav.call("_face", "up")
	var figure := gustav.get_node_or_null("Figure") as Node2D
	for i in 3:
		if figure:
			var swing := create_tween()
			swing.tween_property(figure, "position:y", figure.position.y - 3.0, 0.1)
			swing.tween_property(figure, "position:y", figure.position.y, 0.08)
		await get_tree().create_timer(0.18, false).timeout
		if not is_inside_tree():
			return
		AudioManager.play_sound("pickaxe_hit", 0.8)
		if wall:
			_fx.spawn("impact", wall.global_position + Vector2(randf_range(-6, 6), -8), Color.WHITE)
		await get_tree().create_timer(0.22, false).timeout
		if not is_inside_tree():
			return


func _cave_in() -> void:
	var wall := _node(rubble)
	var center: Vector2 = wall.global_position if wall else global_position
	AudioManager.play_sound("rock_break", 0.5)
	# the rumble, dust from the ceiling all over the tunnel
	_shake(1.6, 1.5)
	for i in 7:
		_fx.spawn("earth_hit", center + Vector2(randf_range(-90, 90), randf_range(-30, 50)), Color.WHITE)
		await get_tree().create_timer(0.14, false).timeout
		if not is_inside_tree():
			return
	# the rubble collapses in itself
	AudioManager.play_sound("rock_break", 1.0)
	_fx.spawn("area_quake", center + Vector2(0, 6), Color.WHITE)
	if wall:
		var sprite := wall.get_node_or_null("Sprite2D") as Node2D
		if sprite:
			var fall := create_tween().set_parallel()
			fall.tween_property(sprite, "scale:y", 0.3, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall.tween_property(sprite, "position:y", sprite.position.y + 14.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall.tween_property(sprite, "modulate:a", 0.0, 0.5).set_delay(0.2)
			await fall.finished
			if not is_inside_tree():
				return
	GameState.run_story_action("set_flag:mine_cave_in")
	var opening := _node(hole)
	if opening:
		opening.modulate.a = 0.0
		create_tween().tween_property(opening, "modulate:a", 1.0, 0.4)
	_fx.spawn("earth_hit", center + Vector2(0, 4), Color.WHITE)


func _rats_out() -> void:
	var opening := _node(hole)
	var center: Vector2 = opening.global_position if opening else global_position
	# red eyes in the dark, blinking
	var eyes := Sprite2D.new()
	eyes.texture = load(EYES)
	eyes.z_index = 1
	add_child(eyes)
	eyes.global_position = center + Vector2(0, -10)
	eyes.modulate.a = 0.0
	var blink := create_tween()
	blink.tween_property(eyes, "modulate:a", 1.0, 0.2)
	blink.tween_interval(0.3)
	blink.tween_property(eyes, "modulate:a", 0.0, 0.08)
	blink.tween_property(eyes, "modulate:a", 1.0, 0.08)
	blink.tween_interval(0.3)
	AudioManager.play_sound("ui_click", 0.4)
	await blink.finished
	if not is_inside_tree():
		return
	eyes.queue_free()
	# then they scurry out to their places
	GameState.run_story_action("set_flag:mine_rats_out")
	var pack := _node(rats)
	if pack == null:
		return
	pack.show()
	var delay: float = 0.0
	for rat in pack.get_children():
		var sprite := rat as Node2D
		if sprite == null:
			continue
		var home: Vector2 = sprite.position
		sprite.global_position = center + Vector2(0, -6)
		sprite.modulate.a = 0.0
		var run := create_tween().set_parallel()
		run.tween_property(sprite, "modulate:a", 1.0, 0.15).set_delay(delay)
		run.tween_property(sprite, "position", home, 0.45).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		delay += 0.12


func _peek() -> void:
	var gustav := _node(miner)
	var opening := _node(hole)
	if gustav == null or opening == null:
		return
	var target: Vector2 = opening.global_position + Vector2(0, 20)
	var shape := gustav.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	while is_inside_tree() and is_instance_valid(gustav) and gustav.global_position.distance_to(target) > 1.0:
		gustav.call("_walk_step", target - gustav.global_position, 40.0, get_process_delta_time())
		await get_tree().process_frame
	if not is_instance_valid(gustav):
		return
	gustav.global_position = target
	gustav.call("_face", "up")
	# his lamp lights up the hole
	var light := Node2D.new()
	add_child(light)
	light.global_position = opening.global_position + Vector2(0, -6)
	_fx.add_loop(light, "glow", LAMP)
	await get_tree().create_timer(2.2, false).timeout
	if is_inside_tree():
		_fx.remove_loop(light)
		light.queue_free()


func _shake(seconds: float, strength: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + seconds
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera):
		camera.offset = home + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home
