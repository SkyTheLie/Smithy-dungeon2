class_name MineCaveCutscene
extends StoryCutscene
## The cave-in in the small mine (dialogues "miner_cave_in" and "miner_hole"). Each beat is a line
## with "hide_for" (the dialogue box is out of sight while it plays) and "cutscene:<id>":
## - miner_knock: Gustav knocks three times against the rubble with his pickaxe
## - cave_in: a rumble, dust trickles from the ceiling, the rubble collapses into the hole
##   (flag mine_cave_in at the end: CaveInRubble goes, MineHole comes)
## - rats_out: red eyes flash in the hole, then the rats scurry out to their places
##   (flag mine_rats_out: MineRats)
## - miner_peek: Gustav climbs over the stones and shines his lamp into the hole
## - board_hole: Gustav nails three boards over the hole, one after the other (flag
##   mine_hole_boarded: BoardedHole, until the old mine is opened)

@export var miner: NodePath
@export var rubble: NodePath
@export var hole: NodePath
@export var rats: NodePath
@export var boards: NodePath

const EYES: String = "res://assets/sprites/props/rat_eyes.png"
const LAMP: Color = Color(1.0, 0.8, 0.45)


func _ready() -> void:
	super()


func _play_beat(id: String) -> bool:
	match id:
		"miner_knock":
			_knock()
		"cave_in":
			_cave_in()
		"rats_out":
			_rats_out()
		"miner_peek":
			_peek()
		"board_hole":
			_board_hole()
		_:
			return false
	return true


func _knock() -> void:
	var gustav := node2d(miner)
	var wall := node2d(rubble)
	if gustav == null:
		return
	gustav.call("_face", "up")
	var figure := gustav.get_node_or_null("Figure") as Node2D
	for i in 3:
		if figure:
			var swing := create_tween()
			swing.tween_property(figure, "position:y", figure.position.y - 3.0, 0.1)
			swing.tween_property(figure, "position:y", figure.position.y, 0.08)
		if not await wait(0.18):
			return
		AudioManager.play_sound("pickaxe_hit", 0.8)
		if wall:
			fx.spawn("impact", wall.global_position + Vector2(randf_range(-6, 6), -8), Color.WHITE)
		if not await wait(0.22):
			return


func _cave_in() -> void:
	var wall := node2d(rubble)
	var center: Vector2 = wall.global_position if wall else global_position
	AudioManager.play_sound("rock_break", 0.5)
	# the rumble, dust from the ceiling all over the tunnel
	shake(1.6, 1.5)
	for i in 7:
		fx.spawn("earth_hit", center + Vector2(randf_range(-90, 90), randf_range(-30, 50)), Color.WHITE)
		if not await wait(0.14):
			return
	# the rubble collapses in itself
	AudioManager.play_sound("rock_break", 1.0)
	fx.spawn("area_quake", center + Vector2(0, 6), Color.WHITE)
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
	var opening := node2d(hole)
	if opening:
		opening.modulate.a = 0.0
		create_tween().tween_property(opening, "modulate:a", 1.0, 0.4)
	fx.spawn("earth_hit", center + Vector2(0, 4), Color.WHITE)


func _rats_out() -> void:
	var opening := node2d(hole)
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
	var pack := node2d(rats)
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
	var gustav := node2d(miner)
	var opening := node2d(hole)
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
	fx.add_loop(light, "glow", LAMP)
	await wait(2.2)
	if is_inside_tree():
		fx.remove_loop(light)
		light.queue_free()




func _board_hole() -> void:
	var gustav := node2d(miner)
	var opening := node2d(hole)
	var cover := node2d(boards)
	if cover == null:
		return
	for board in cover.get_children():
		(board as CanvasItem).visible = false
	GameState.run_story_action("set_flag:mine_hole_boarded")
	if gustav and opening:
		var target: Vector2 = opening.global_position + Vector2(0, 20)
		while is_inside_tree() and is_instance_valid(gustav) and gustav.global_position.distance_to(target) > 1.0:
			gustav.call("_walk_step", target - gustav.global_position, 40.0, get_process_delta_time())
			await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(gustav):
			return
		gustav.call("_face", "up")
	var figure := gustav.get_node_or_null("Figure") as Node2D if gustav else null
	for board in cover.get_children():
		var plank := board as Node2D
		var home: Vector2 = plank.position
		plank.position = home + Vector2(0, -6)
		plank.modulate.a = 0.0
		plank.visible = true
		var put := create_tween().set_parallel()
		put.tween_property(plank, "position", home, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		put.tween_property(plank, "modulate:a", 1.0, 0.15)
		await put.finished
		if not is_inside_tree():
			return
		# two blows on the nails, one on each end
		for side in [-1.0, 1.0]:
			if figure and is_instance_valid(figure):
				var swing := create_tween()
				swing.tween_property(figure, "position:y", figure.position.y - 3.0, 0.08)
				swing.tween_property(figure, "position:y", figure.position.y, 0.06)
			if not await wait(0.12):
				return
			AudioManager.play_sound("axe_hit", 1.3)
			fx.spawn("impact", plank.global_position + Vector2(side * 21.0, 0), Color(1.0, 0.95, 0.8))
			if not await wait(0.16):
				return
