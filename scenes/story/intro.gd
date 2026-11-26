class_name Intro
extends Control
## "Neues Spiel" (beginners' scene, sketch b1): black for a moment, then it gets light. Outside
## in front of a rock wall with the entrance of the dungeon, a glowing path leads into it. Left of
## the entrance, at his little stall, a man waves and calls you over (Egon, data/story.json
## intro_call). You walk to him in two steps (the picture zooms towards him, with a little bob like
## footsteps), then he introduces himself (story.json intro). Then it goes dark and his shop opens
## (Game.to_shop). Space, Enter or a click: next line. Escape: skip to the shop.
## Built in code on a small stage (STAGE pixels, scaled up): rock wall from Smithy
## (mine/cliff_open.png), ground and path drawn, Egon (npcs/black_market_dealer.png) with a
## waving arm (WavingHand), his stall (finster/hideout_table.png).

const CLIFF: Texture2D = preload("res://assets/sprites/mine/cliff_open.png")
const MERCHANT: Texture2D = preload("res://assets/sprites/npcs/black_market_dealer.png")
const STALL: Texture2D = preload("res://assets/sprites/finster/hideout_table.png")
## The stage in picture pixels (scaled to cover the screen).
const STAGE := Vector2(320, 180)
## The part of the rock wall with the entrance (its jagged top edge is above the screen).
const WALL_REGION := Rect2(180, 0, 320, 118)
const WALL_TOP: float = -8.0
const GROUND_TOP: float = 110.0
## The dark opening of the entrance on the stage (glows a little).
const DOOR_INSIDE := Rect2(122, 52, 36, 58)
## The glowing path from the entrance down to the front edge.
const PATH: PackedVector2Array = [
	Vector2(126, 110), Vector2(156, 110), Vector2(158, 125), Vector2(150, 145), Vector2(136, 165),
	Vector2(126, 180), Vector2(80, 180), Vector2(96, 160), Vector2(112, 140), Vector2(120, 124)]
const GROUND_COLOR := Color(0.27, 0.22, 0.17)
const PEBBLE_COLOR := Color(0.2, 0.16, 0.13)
const EMBER_COLOR := Color(1.0, 0.5, 0.12)
const EMBER_LIGHT := Color(1.0, 0.75, 0.3)
## Egon's feet on the stage, his feet in his sprite, his size on the stage.
const FEET := Vector2(92, 116)
const SPRITE_FEET := Vector2(24, 41)
const MERCHANT_SCALE: float = 0.75
const STALL_FEET := Vector2(60, 116)
const STALL_SCALE: float = 0.45
## One entry per picture: zoom of the stage (1 = covers the screen). Every next one is closer.
const ZOOMS: Array[float] = [1.0, 1.7, 2.6]
const OVERSCAN: float = 1.04
const FEET_ON_SCREEN := Vector2(0.5, 0.62)
const DARK_TIME: float = 0.5
const FADE_IN_TIME: float = 1.0
const BEFORE_CALL_TIME: float = 0.8
const STEP_PAUSE: float = 0.25
const WALK_TIME: float = 1.2
const STEPS_PER_WALK: int = 4
const BOB: float = 5.0
const FADE_OUT_TIME: float = 0.6
const PEBBLES: int = 40

var _stage: Control
var _ground: Control
var _black: ColorRect
var _dialog: DialogBox
var _fade: Tween
var _zoom: float = ZOOMS[0]
var _bob: float = 0.0
var _leaving: bool = false
## Pebbles on the ground (rectangles), rolled once with a fixed seed.
var _pebbles: Array[Rect2] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roll_pebbles()
	_build()
	resized.connect(_apply_layout)
	_apply_layout()
	AudioManager.play_music("title")
	_play()


func _roll_pebbles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in PEBBLES:
		var at := Vector2(rng.randf_range(0, STAGE.x), rng.randf_range(GROUND_TOP + 2, STAGE.y))
		_pebbles.append(Rect2(at.round(), Vector2(rng.randi_range(1, 3), 1)))


func _build() -> void:
	var back := ColorRect.new()
	back.color = Color(0.08, 0.07, 0.07)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_stage = Control.new()
	_stage.size = STAGE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_stage.add_child(_wall(WALL_REGION, WALL_TOP))
	var door_glow := ColorRect.new()
	door_glow.color = Color(EMBER_COLOR, 0.18)
	door_glow.position = DOOR_INSIDE.position
	door_glow.size = DOOR_INSIDE.size
	door_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(door_glow)
	var flicker := create_tween().set_loops()
	flicker.tween_property(door_glow, "modulate:a", 0.5, 0.7).set_trans(Tween.TRANS_SINE)
	flicker.tween_property(door_glow, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	_ground = Control.new()
	_ground.size = STAGE
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground.draw.connect(_draw_ground)
	_stage.add_child(_ground)
	_stage.add_child(_standing(STALL, STALL_FEET, Vector2(STALL.get_width() / 2.0, STALL.get_height()), STALL_SCALE))
	var merchant := _standing(MERCHANT, FEET, SPRITE_FEET, MERCHANT_SCALE)
	merchant.add_child(WavingHand.new())
	_stage.add_child(merchant)

	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Leertaste: weiter · Esc: überspringen")
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_constant_override("outline_size", 4)
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.position += Vector2(-6, 4)
	add_child(hint)
	_dialog = DialogBox.new()
	add_child(_dialog)
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dialog.offset_left = 40
	_dialog.offset_right = -40
	_dialog.offset_top = -96
	_dialog.offset_bottom = -10
	_dialog.hide()
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)


func _wall(region: Rect2, top: float) -> TextureRect:
	var part := AtlasTexture.new()
	part.atlas = CLIFF
	part.region = region
	var wall := TextureRect.new()
	wall.texture = part
	wall.position = Vector2(0, top)
	wall.size = region.size
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return wall


## A picture standing with its `feet` (its own pixels) on `at` of the stage.
func _standing(texture: Texture2D, at: Vector2, feet: Vector2, scale_by: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.size = texture.get_size()
	picture.scale = Vector2.ONE * scale_by
	picture.position = at - feet * scale_by
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


func _draw_ground() -> void:
	_ground.draw_rect(Rect2(0, GROUND_TOP, STAGE.x, STAGE.y - GROUND_TOP), GROUND_COLOR)
	for pebble: Rect2 in _pebbles:
		_ground.draw_rect(pebble, PEBBLE_COLOR)
	_ground.draw_colored_polygon(PATH, EMBER_COLOR)
	# A brighter seam in the middle of the path.
	_ground.draw_line(Vector2(141, 111), Vector2(103, 180), EMBER_LIGHT, 2.0)


## Dark, light, he calls; walk, walk; he introduces himself; dark, shop.
func _play() -> void:
	if not await _wait(DARK_TIME):
		return
	_fade = create_tween()
	_fade.tween_property(_black, "modulate:a", 0.0, FADE_IN_TIME)
	if not await _wait(FADE_IN_TIME + BEFORE_CALL_TIME):
		return
	await _dialog.speak(Content.story("intro_call"))
	if _leaving or not is_inside_tree():
		return
	_dialog.hide()
	for i in range(1, ZOOMS.size()):
		var walk := create_tween()
		walk.tween_method(_walk_to.bind(ZOOMS[i - 1], ZOOMS[i]), 0.0, 1.0, WALK_TIME)
		await walk.finished
		if not await _wait(STEP_PAUSE):
			return
	await _dialog.speak(Content.story("intro"))
	if not _leaving and is_inside_tree():
		_leave()


## Waits `seconds`; false if the scene is gone or leaving.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds, false).timeout
	return not _leaving and is_inside_tree()


## One walk between two pictures; `progress` 0..1. Every step bobs the view up a little.
func _walk_to(progress: float, from: float, to: float) -> void:
	_zoom = lerpf(from, to, ease(progress, -1.6))
	_bob = -absf(sin(progress * PI * STEPS_PER_WALK)) * BOB
	_apply_layout()


## Scales the stage and puts Egon's feet where they belong on the screen.
func _apply_layout() -> void:
	if _stage == null or size.x <= 0.0:
		return
	var cover: float = maxf(size.x / STAGE.x, size.y / STAGE.y) * OVERSCAN
	var scale_by: float = cover * _zoom
	var at: Vector2 = size * FEET_ON_SCREEN - FEET * scale_by
	var lowest: Vector2 = size - STAGE * scale_by
	at.x = clampf(at.x, lowest.x, 0.0)
	at.y = clampf(clampf(at.y, lowest.y, 0.0) + _bob, lowest.y, 0.0)
	_stage.scale = Vector2.ONE * scale_by
	_stage.position = at


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


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
