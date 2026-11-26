class_name WitchVisionCutscene
extends StoryCutscene
## Muhme Grisla's vision in the swamp (dialogue "witch_vision"):
## - witch_drinks: she pulls the cork with her teeth and empties the phial in one gulp, her eyes go
##   milky and stare (she pales, a pale shimmer around her)
## - witch_spits: she shakes herself, her eyes clear, she spits a little green cloud into the fire
## - witch_brews (side quest "witch_cauldron"): things go into the cauldron, it bubbles green and
##   steams

@export var witch: NodePath
@export var cauldron: NodePath

const BREW: String = "res://assets/sprites/items/seers_brew.png"
const MILKY: Color = Color(1.25, 1.25, 1.35)
const GREEN: Color = Color(0.5, 0.95, 0.35)

var _trance: Node2D


func _play_beat(id: String) -> bool:
	match id:
		"witch_drinks":
			_drink()
		"witch_spits":
			_spit()
		"witch_brews":
			_brew()
		_:
			return false
	return true


func _drink() -> void:
	var grisla := node2d(witch)
	if grisla == null:
		return
	face_npc(grisla, "down")
	var phial := Sprite2D.new()
	phial.texture = load(BREW)
	phial.scale = Vector2(0.6, 0.6)
	phial.position = Vector2(7, -20)
	grisla.add_child(phial)
	AudioManager.play_sound("ui_click", 0.6)
	if not await wait(0.4):
		return
	# up to the mouth and down in one gulp
	var gulp := create_tween()
	gulp.tween_property(phial, "position", Vector2(2, -27), 0.3)
	gulp.parallel().tween_property(phial, "rotation", -2.2, 0.3)
	gulp.tween_interval(0.5)
	gulp.tween_property(phial, "modulate:a", 0.0, 0.2)
	gulp.tween_callback(phial.queue_free)
	await gulp.finished
	if not is_instance_valid(grisla):
		return
	var figure := figure_of(grisla)
	if figure:
		create_tween().tween_property(figure, "modulate", MILKY, 0.5)
	_trance = Node2D.new()
	add_child(_trance)
	_trance.global_position = grisla.global_position
	fx.add_loop(_trance, "aura_spirit", Color(0.85, 0.9, 1.0))


func _spit() -> void:
	var grisla := node2d(witch)
	if grisla == null:
		return
	var figure := figure_of(grisla)
	if figure:
		var home: Vector2 = figure.position
		for i in 6:
			figure.position = home + Vector2(1.0 if i % 2 == 0 else -1.0, 0)
			if not await wait(0.06):
				return
		figure.position = home
		create_tween().tween_property(figure, "modulate", Color.WHITE, 0.3)
	if _trance:
		fx.remove_loop(_trance)
		_trance.queue_free()
		_trance = null
	var pot := node2d(cauldron)
	var fire: Vector2 = (pot.global_position if pot else grisla.global_position + Vector2(-30, 0)) + Vector2(0, -12)
	face_npc(grisla, "left" if fire.x < grisla.global_position.x else "right")
	if not await wait(0.2):
		return
	fx.spawn("poison_bolt", fire, GREEN, -1.0 if fire.x < grisla.global_position.x else 1.0, grisla.global_position + Vector2(0, -20), 0.45)
	AudioManager.play_sound("quench_hiss", 0.6)
	if not await wait(0.45):
		return
	fx.spawn("area_poison", fire + Vector2(0, 8), GREEN)
	fx.spawn("fire_hit", fire, Color.WHITE)


func _brew() -> void:
	var grisla := node2d(witch)
	var pot := node2d(cauldron)
	if grisla == null:
		return
	var at: Vector2 = (pot.global_position if pot else grisla.global_position + Vector2(-30, 0)) + Vector2(0, -12)
	face_npc(grisla, "left" if at.x < grisla.global_position.x else "right")
	for i in 3:
		fx.spawn("poison_bolt", at, GREEN, -1.0 if at.x < grisla.global_position.x else 1.0, grisla.global_position + Vector2(0, -18), 0.35)
		AudioManager.play_sound("plant_pick", 0.5)
		if not await wait(0.4):
			return
	for i in 4:
		fx.spawn("poison_hit", at + Vector2(randf_range(-6, 6), randf_range(-4, 2)), GREEN)
		AudioManager.play_sound("quench_hiss", 0.35)
		if not await wait(0.3):
			return
