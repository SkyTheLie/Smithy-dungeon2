class_name Intro
extends Control
## "Neues Spiel" (beginners' scene): black for a moment, then it gets light. An old mine tunnel;
## far ahead, in front of the dark shaft, a man waves you over: Egon, the merchant. You walk to him
## in a few steps (each one zooms the picture towards him, with a little bob like footsteps), he
## keeps waving. Then it goes dark and Egon's shop opens (Game.to_shop).
## Space, Enter or a click: go on at once. Escape: skip to the shop.
## Built in code; the pictures are a cave from Smithy (battle/mine_rats.png) and Egon
## (npcs/black_market_dealer.png) with a waving arm (WavingHand).

const CAVE: Texture2D = preload("res://assets/sprites/battle/mine_rats.png")
const MERCHANT: Texture2D = preload("res://assets/sprites/npcs/black_market_dealer.png")
## Where Egon stands in the cave picture (its pixels): his feet, in front of the dark shaft.
const FEET := Vector2(300, 94)
## Egon's feet in his own sprite (pixels).
const SPRITE_FEET := Vector2(24, 41)
## Egon's size: cave pixels per sprite pixel (far away = small).
const MERCHANT_SCALE: float = 0.6
## One entry per picture: zoom of the cave (1 = its height fills the screen). Every next one is a
## few steps closer.
const ZOOMS: Array[float] = [1.0, 1.6, 2.4]
## A little more than "cover", so the bob never shows the edge of the picture.
const OVERSCAN: float = 1.04
## Where Egon's feet go on the screen (share of width and height), clamped so the cave covers it.
const FEET_ON_SCREEN := Vector2(0.5, 0.9)
const DARK_TIME: float = 0.5
const FADE_IN_TIME: float = 1.0
const LOOK_TIME: float = 1.5
const WALK_TIME: float = 1.2
const STEPS_PER_WALK: int = 4
## Screen pixels the view bobs up with each step.
const BOB: float = 5.0
const FADE_OUT_TIME: float = 0.6

var _cave: TextureRect
var _black: ColorRect
## The fade of the black cover running now (killed when leaving starts).
var _fade: Tween
var _zoom: float = ZOOMS[0]
var _bob: float = 0.0
## A key or click asked to go on (ends the current look at a picture).
var _go_on: bool = false
var _leaving: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_apply_layout)
	_apply_layout()
	AudioManager.play_music("title")
	_play()


func _build() -> void:
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_cave = TextureRect.new()
	_cave.texture = CAVE
	_cave.size = CAVE.get_size()
	_cave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cave)
	var merchant := TextureRect.new()
	merchant.texture = MERCHANT
	merchant.size = MERCHANT.get_size()
	merchant.scale = Vector2.ONE * MERCHANT_SCALE
	merchant.position = FEET - SPRITE_FEET * MERCHANT_SCALE
	merchant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	merchant.add_child(WavingHand.new())
	_cave.add_child(merchant)
	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Leertaste: weiter · Esc: überspringen")
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_constant_override("outline_size", 4)
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position -= Vector2(6, 4)
	add_child(hint)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)


## Dark, light, look; walk, look; walk, look; dark, shop.
func _play() -> void:
	if not await _pause(DARK_TIME):
		return
	_fade = create_tween()
	_fade.tween_property(_black, "modulate:a", 0.0, FADE_IN_TIME)
	await _fade.finished
	for i in range(1, ZOOMS.size()):
		if not await _pause(LOOK_TIME):
			return
		var walk := create_tween()
		walk.tween_method(_walk_to.bind(ZOOMS[i - 1], ZOOMS[i]), 0.0, 1.0, WALK_TIME)
		await walk.finished
	if await _pause(LOOK_TIME):
		_leave()


## Waits `seconds` (or until a key or click). false if the scene is gone or leaving.
func _pause(seconds: float) -> bool:
	_go_on = false
	var left: float = seconds
	while left > 0.0 and not _go_on:
		if _leaving or not is_inside_tree():
			return false
		await get_tree().process_frame
		if not is_inside_tree():
			return false
		left -= get_process_delta_time()
	return not _leaving and is_inside_tree()


## One walk between two pictures; `progress` 0..1. Every step bobs the view up a little.
func _walk_to(progress: float, from: float, to: float) -> void:
	_zoom = lerpf(from, to, ease(progress, -1.6))
	_bob = -absf(sin(progress * PI * STEPS_PER_WALK)) * BOB
	_apply_layout()


## Scales the cave (with Egon on it) and puts his feet where they belong on the screen.
func _apply_layout() -> void:
	if _cave == null or size.x <= 0.0:
		return
	var picture: Vector2 = CAVE.get_size()
	var cover: float = maxf(size.x / picture.x, size.y / picture.y) * OVERSCAN
	var scale_by: float = cover * _zoom
	var at: Vector2 = size * FEET_ON_SCREEN - FEET * scale_by
	var lowest: Vector2 = size - picture * scale_by
	at.x = clampf(at.x, lowest.x, 0.0)
	at.y = clampf(clampf(at.y, lowest.y, 0.0) + _bob, lowest.y, 0.0)
	_cave.scale = Vector2.ONE * scale_by
	_cave.position = at


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed()):
		get_viewport().set_input_as_handled()
		_go_on = true


## It goes dark, then the shop.
func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_black, "modulate:a", 1.0, FADE_OUT_TIME)
	_fade.tween_callback(Game.to_shop)
