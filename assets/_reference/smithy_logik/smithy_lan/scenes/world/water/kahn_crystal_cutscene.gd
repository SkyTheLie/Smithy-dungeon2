class_name KahnCrystalCutscene
extends Node
## Kahn's throne hall, "Rat in der Strömung" (dialogue kahn_council): Kahn takes the water crystal out
## of the base of his ice throne and hands it to King Albrecht. The dialogue lines start each part
## with the story action "cutscene:<id>" (Events.cutscene_requested) and wait for it:
## - kahn_to_throne: Kahn turns round and steps up to the base of the throne
## - kahn_break_seal: he kneels, the ice seal bursts (water/ice_throne_break.png), he lifts the
##   glowing crystal over his head (residents/kahn_lift_crystal.png)
## - kahn_give_crystal: he carries it to the king, who takes it; then Kahn goes back to his place
## Until the crystal is given (GIVEN_FLAG) the throne shows it sealed in the ice, glowing; after that
## the base is broken open.

const GIVEN_FLAG: String = "water_crystal_given"
const SEALED: Texture2D = preload("res://assets/sprites/water/ice_throne_sealed.png")
const BROKEN: Texture2D = preload("res://assets/sprites/water/ice_throne_broken.png")
const BREAK_SHEET: Texture2D = preload("res://assets/sprites/water/ice_throne_break.png")
const BREAK_FRAMES: int = 9
const LIFT_SHEET: Texture2D = preload("res://assets/sprites/residents/kahn_lift_crystal.png")
const LIFT_FRAMES: int = 11
## Kahn's lift frames: kneeling and working (the seal bursts on this one), arms up (the crystal shows).
const BURST_FRAME: int = 5
const RAISED_FRAME: int = 9
const LIFT_FPS: float = 6.0
const BREAK_FPS: float = 12.0
const WALK_SPEED: float = 45.0
## Where the crystal is over Kahn's raised hands / in front of him while he carries it.
const ABOVE_HEAD: Vector2 = Vector2(0, -46)
const CARRIED: Vector2 = Vector2(0, -26)

@export var throne: Sprite2D
## Light on the crystal in the throne base (a NightLight; dark once the crystal is out).
@export var seal_glow: PointLight2D
## The crystal Kahn holds up (hidden until he lifts it), with its own light.
@export var crystal: Node2D
@export var kahn_path: NodePath
@export var king_path: NodePath
## Where Kahn kneels in front of the base, and where he hands the crystal to the king.
@export var kneel_point: Vector2 = Vector2(0, -110)
@export var give_point: Vector2 = Vector2(-30, -46)

var _kahn_home: Vector2


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)
	crystal.hide()
	var given: bool = GameState.story.has_flag(GIVEN_FLAG)
	_set_throne(BROKEN if given else SEALED)
	if given:
		seal_glow.set("night_energy", 0.0)
	var kahn := _kahn()
	if kahn:
		_kahn_home = kahn.position


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"kahn_to_throne":
			_to_throne()
		"kahn_break_seal":
			_break_seal()
		"kahn_give_crystal":
			_give_crystal()


func _kahn() -> Node2D:
	return get_node_or_null(kahn_path) as Node2D


func _figure() -> Sprite2D:
	var kahn := _kahn()
	return kahn.get_node_or_null("Figure") as Sprite2D if kahn else null


func _set_throne(texture: Texture2D) -> void:
	throne.texture = texture
	throne.hframes = 1
	throne.frame = 0


## Kahn walks along `points` (scene coordinates of his parent) with his walk frames, the crystal
## (if shown) moving with him.
func _walk(points: PackedVector2Array, end_facing: String) -> void:
	var kahn := _kahn()
	if kahn == null:
		return
	var time: float = 0.0
	for target in points:
		while is_inside_tree() and is_instance_valid(kahn) and kahn.position.distance_to(target) > 0.5:
			var delta: float = get_physics_process_delta_time()
			var step: Vector2 = target - kahn.position
			var direction: String = ("right" if step.x > 0.0 else "left") if absf(step.x) > absf(step.y) \
					else ("down" if step.y > 0.0 else "up")
			time += delta
			kahn.call("_face", direction, 1 + int(time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1))
			kahn.position += step.limit_length(WALK_SPEED * delta)
			if crystal.visible:
				crystal.position = kahn.position + CARRIED
			await get_tree().physics_frame
	if is_instance_valid(kahn):
		kahn.call("_face", end_facing)


func _to_throne() -> void:
	await _walk(PackedVector2Array([kneel_point]), "up")


## He kneels, the seal bursts, he stands up with the crystal over his head (and stays like that).
func _break_seal() -> void:
	var kahn := _kahn()
	var figure := _figure()
	if kahn == null or figure == null:
		return
	kahn.position = kneel_point
	figure.texture = LIFT_SHEET
	for frame in LIFT_FRAMES:
		if not is_inside_tree() or not is_instance_valid(figure):
			return
		figure.region_rect = Rect2(frame * CharacterBaker.FRAME, 0, CharacterBaker.FRAME, CharacterBaker.FRAME)
		if frame == BURST_FRAME:
			_burst()
		if frame == RAISED_FRAME:
			_show_crystal(kahn.position + ABOVE_HEAD)
		await get_tree().create_timer(1.0 / LIFT_FPS, false).timeout


func _burst() -> void:
	AudioManager.play_sound("rock_break", 1.4)
	_shake_camera(0.35, 1.0)
	create_tween().tween_property(seal_glow, "night_energy", 0.0, 0.5)
	throne.texture = BREAK_SHEET
	throne.hframes = BREAK_FRAMES
	for frame in BREAK_FRAMES:
		if not is_inside_tree():
			return
		throne.frame = frame
		await get_tree().create_timer(1.0 / BREAK_FPS, false).timeout
	_set_throne(BROKEN)


func _show_crystal(at: Vector2) -> void:
	AudioManager.play_sound("item_reveal")
	crystal.position = at
	crystal.modulate.a = 0.0
	crystal.show()
	create_tween().tween_property(crystal, "modulate:a", 1.0, 0.3)


## Back to his walk sheet, down to the king; the crystal passes into the king's hands and is gone
## (he hides it away), then Kahn goes back to his place.
func _give_crystal() -> void:
	var kahn := _kahn()
	var figure := _figure()
	if kahn == null or figure == null:
		return
	figure.texture = kahn.call("_get_resident_sheet")
	if not crystal.visible:
		_show_crystal(kahn.position + CARRIED)
	await _walk(PackedVector2Array([Vector2(kneel_point.x, give_point.y), give_point]), "down")
	if not is_inside_tree():
		return
	var king := get_node_or_null(king_path) as Node2D
	var hands: Vector2 = (king.position if king else give_point + Vector2(0, 26)) + Vector2(0, -20)
	var tween := create_tween()
	tween.tween_property(crystal, "position", hands, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.4)
	tween.tween_property(crystal, "modulate:a", 0.0, 0.4)
	tween.tween_callback(crystal.hide)
	await tween.finished
	if not is_inside_tree():
		return
	await _walk(PackedVector2Array([Vector2(_kahn_home.x, give_point.y), _kahn_home]), "down")


func _shake_camera(seconds: float, strength: float) -> void:
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
