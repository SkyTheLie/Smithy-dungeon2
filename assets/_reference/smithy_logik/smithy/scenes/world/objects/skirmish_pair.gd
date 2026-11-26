class_name SkirmishPair
extends StaticBody2D
## Two fighters in the world that fight each other without end (background battle, e.g. the yard
## of the Finsterburg): a soldier (PixelLab resident sheet, left, looks right) and an enemy (its
## battle sprites, right, looks left). In turns the soldier lunges and slashes, the enemy plays its
## attack and the soldier parries, or both shuffle a step to the side. Both in their normal size
## (no scaling), each pair at its own pace.

## Sheet in assets/sprites/residents/ for the soldier.
@export var soldier_resident: String = "leon_soldier_a"
## Enemy id: assets/sprites/enemies/<foe>.png (standing), <foe>_walk.png and <foe>_attack.png
## (6 frames each, looking left).
@export var foe: String = "dark_knight"
## Gone (freed) once this story flag is set.
@export var hidden_when_flag: String = ""
## Distance between the two (pixels).
@export var gap: float = 26.0
## Higher = faster fight (each pair gets a little randomness on top).
@export var pace: float = 1.0

const ENEMY_DIR: String = "res://assets/sprites/enemies/"
const FOE_FRAME: int = 48
const FOE_FRAMES: int = 6
const SOLDIER_Y: float = -13.0
const FOE_Y: float = -22.0
const LUNGE: float = 7.0
const RECOIL: float = 3.0
## How far the pair may drift from its place while shuffling.
const MAX_DRIFT: float = 14.0
const SHUFFLE_STEP: float = 6.0
## Share of hits that ring out (several pairs at once would be too loud).
const SOUND_CHANCE: float = 0.12
const COLOR_STEEL: Color = Color(1.0, 0.95, 0.8)

var _soldier: Sprite2D
var _foe: Sprite2D
var _fx: WorldVfx
var _foe_stand: Texture2D
var _foe_walk: Texture2D
var _foe_attack: Texture2D
var _drift: float = 0.0


func _ready() -> void:
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag):
		queue_free()
		return
	pace *= randf_range(0.8, 1.25)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(gap + 14.0, 6.0)
	shape.shape = rect
	add_child(shape)
	_soldier = Sprite2D.new()
	_soldier.texture = load(CharacterBaker.RESIDENT_DIR + soldier_resident + ".png")
	_soldier.region_enabled = true
	_soldier.position = Vector2(-gap / 2.0, SOLDIER_Y)
	add_child(_soldier)
	_foe_stand = load(ENEMY_DIR + foe + ".png")
	_foe_walk = load(ENEMY_DIR + foe + "_walk.png")
	_foe_attack = load(ENEMY_DIR + foe + "_attack.png")
	_foe = Sprite2D.new()
	_foe.region_enabled = true
	_foe.position = Vector2(gap / 2.0, FOE_Y)
	add_child(_foe)
	_fx = WorldVfx.new()
	add_child(_fx)
	_soldier_frame(0)
	_foe_frame(_foe_stand, 0)
	_fight()


func _soldier_frame(frame: int) -> void:
	_soldier.region_rect = CharacterBaker.get_frame_rect("right", frame)


func _foe_frame(sheet: Texture2D, frame: int) -> void:
	_foe.texture = sheet
	_foe.region_rect = Rect2(frame * FOE_FRAME if sheet != _foe_stand else 0, 0, FOE_FRAME, FOE_FRAME)


func _wait(seconds: float) -> void:
	if not is_inside_tree():  # the map was left in the middle of a move
		return
	await get_tree().create_timer(seconds / pace, false).timeout


func _fight() -> void:
	await _wait(randf_range(0.0, 1.0))
	while is_inside_tree():
		var roll: float = randf()
		if roll < 0.4:
			await _soldier_attacks()
		elif roll < 0.8:
			await _foe_attacks()
		else:
			await _shuffle()
		await _wait(randf_range(0.25, 0.8))


func _soldier_attacks() -> void:
	var home: float = _soldier.position.x
	_soldier_frame(3)
	var tween := create_tween()
	tween.tween_property(_soldier, "position:x", home + LUNGE, 0.12 / pace)
	await tween.finished
	_fx.spawn("slash", _foe.global_position + Vector2(-4, 4), COLOR_STEEL, 1.0)
	_ring()
	_recoil(_foe, RECOIL)
	_soldier_frame(5)
	tween = create_tween()
	tween.tween_property(_soldier, "position:x", home, 0.2 / pace)
	await tween.finished
	_soldier_frame(0)


func _foe_attacks() -> void:
	for frame in FOE_FRAMES:
		_foe_frame(_foe_attack, frame)
		if frame == 3:
			_fx.spawn("block", _soldier.global_position + Vector2(5, 2), COLOR_STEEL, -1.0)
			_ring()
			_recoil(_soldier, -RECOIL)
		await _wait(0.09)
	_foe_frame(_foe_stand, 0)


## Both step a bit to one side together (the fight moves back and forth).
func _shuffle() -> void:
	var step: float = SHUFFLE_STEP if randf() < 0.5 else -SHUFFLE_STEP
	if absf(_drift + step) > MAX_DRIFT:
		step = -step
	_drift += step
	var tween := create_tween().set_parallel()
	tween.tween_property(_soldier, "position:x", _soldier.position.x + step, 0.5 / pace)
	tween.tween_property(_foe, "position:x", _foe.position.x + step, 0.5 / pace)
	for frame in FOE_FRAMES:
		_soldier_frame(1 + frame)
		_foe_frame(_foe_walk, frame)
		await _wait(0.5 / FOE_FRAMES)
	_soldier_frame(0)
	_foe_frame(_foe_stand, 0)


func _recoil(sprite: Sprite2D, by: float) -> void:
	var home: float = sprite.position.x
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", home + by, 0.06)
	tween.parallel().tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6), 0.06)
	tween.tween_property(sprite, "position:x", home, 0.15)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _ring() -> void:
	if randf() < SOUND_CHANCE:
		AudioManager.play_sound("anvil_good", randf_range(1.5, 1.9))
