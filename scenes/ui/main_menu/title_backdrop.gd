class_name TitleBackdrop
extends SubViewport
## Moving picture behind the title screen and main menu, drawn at the game's base resolution
## (640x360) so smoke and sparks stay sharp pixels; the menu shows it through a TextureRect.
##
## Outside: the smithy at dusk with its door shut. Smoke rises from the chimney, light leaks
## through the door, and now and then somebody inside hammers on the anvil (sound "title_hammer",
## Ambience bus; each stroke lights the door up and throws sparks out of the chimney).
## `enter()`: the double door swings open (fire inside, PixelLab frames title_fire.png), the camera
## is pulled into the door, a flash of fire light, and we are inside: the forge burns
## (title_inside_fire.png), the camera closes in on the anvil where the menu waits.
## `strike()`: a sledgehammer comes down on the anvil (sparks, flash, shake, "title_strike").
## Every movement is a tween or particles, so it runs at the full frame rate.
## Pictures: assets/_reference/title_anim/make_title_door.py.

## Emitted when the hammer of `strike()` hits the anvil.
signal struck
## Emitted when `enter()` has arrived at the anvil (or `skip()` jumped there).
signal entered

enum Stage { DOOR, OPENING, INSIDE }

const OUTSIDE: Texture2D = preload("res://assets/ui/title_outside.png")
const INSIDE: Texture2D = preload("res://assets/ui/title_inside.png")
const DOOR_LEFT: Texture2D = preload("res://assets/ui/title_door_left.png")
const DOOR_RIGHT: Texture2D = preload("res://assets/ui/title_door_right.png")
const HAMMER: Texture2D = preload("res://assets/ui/title_hammer.png")
const FIRE_SHEET: Texture2D = preload("res://assets/ui/title_fire.png")
const INSIDE_FIRE_SHEET: Texture2D = preload("res://assets/ui/title_inside_fire.png")
const FIRE_SIZE: int = 64
const FIRE_FPS: float = 12.0

## --- outside (title picture coordinates) ---
const FIRE_AT := Vector2(288, 226)
## Hinges of the two door leaves (top end): left leaf turns about its left edge, right about its right.
const DOOR_LEFT_HINGE := Vector2(290, 221)
const DOOR_RIGHT_HINGE := Vector2(349, 221)
## Middle of the door: the camera is pulled in here, the hint sits on it.
const DOOR_CENTER := Vector2(319, 272)
const CHIMNEY := Vector2(402, 59)
const DOOR_LIGHT := Vector2(321, 286)
const OUTSIDE_RECT := Rect2(0, 0, 640, 360)
## Colours of the painted smoke the moving one replaces.
const SMOKE_COLORS: Array[Color] = [Color8(90, 63, 99), Color8(76, 82, 98), Color8(104, 96, 120)]
const SPARK_COLOR := Color(1.0, 0.72, 0.32)
## Door light while shut (only the gaps glow) and wide open.
const GLOW_SHUT: float = 0.05
const GLOW_OPEN: float = 0.3

## --- inside (the inside picture is drawn at INSIDE_AT, so its middle is the screen's) ---
const INSIDE_AT := Vector2(-24, -12)
const INSIDE_RECT := Rect2(-24, -12, 688, 384)
const INSIDE_FIRE_AT := Vector2(288, 156)
const FORGE_LIGHT := Vector2(321, 196)
const CANDLES: Array[Vector2] = [Vector2(11, 164), Vector2(627, 166)]
## Middle of the anvil's face, where the hammer lands.
const ANVIL_TOP := Vector2(318, 251)
## Camera at the end: the anvil right of the middle, the menu on the left beside it.
const MENU_VIEW := Vector2(276, 278)
const MENU_ZOOM: float = 2.0
## The hammer picture: end of the handle (pivot) and the middle of the striking face.
const HAMMER_GRIP := Vector2(118, 26)
const HAMMER_FACE := Vector2(12, 54)
## Hammer swing: raised (out of the picture), drawn back, and the bounce after the hit (degrees).
const HAMMER_RAISED: float = 80.0
const HAMMER_BACK: float = 88.0
const HAMMER_BOUNCE: float = 9.0

## Hammering outside: strokes per round, seconds between strokes and between rounds.
const STROKES_MIN: int = 2
const STROKES_MAX: int = 5
const STROKE_GAP: float = 0.55
const PAUSE_MIN: float = 3.5
const PAUSE_MAX: float = 8.0

## Timing of `enter()` (seconds).
const DOOR_TIME: float = 0.75
const PULL_DELAY: float = 0.35
const PULL_TIME: float = 0.95
const PULL_ZOOM: float = 7.0
const FLASH_TIME: float = 0.3
const CLOSE_IN_TIME: float = 1.1

var stage: Stage = Stage.DOOR

var _camera: Camera2D
var _outside: Node2D
var _inside: Node2D
var _fire: Sprite2D
var _inside_fire: Sprite2D
var _fire_time: float = 0.0
var _door_left: Sprite2D
var _door_right: Sprite2D
var _glow: Sprite2D
var _glow_base: float = GLOW_SHUT
var _forge_glow: Sprite2D
var _candles: Array[Sprite2D] = []
var _sparks: CPUParticles2D
var _hammer: Node2D
var _strike_sparks: CPUParticles2D
## Full-screen colour over the picture (fire light when stepping in, white on a hit).
var _veil: ColorRect
## Extra light of a hammer stroke, fades out quickly.
var _flash: float = 0.0
var _shake: float = 0.0
var _playing: bool = true
var _tweens: Array[Tween] = []
var _striking: bool = false


func _init() -> void:
	size = Vector2i(640, 360)
	snap_2d_transforms_to_pixel = true
	snap_2d_vertices_to_pixel = true
	canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _ready() -> void:
	_outside = Node2D.new()
	add_child(_outside)
	_build_outside()
	_inside = Node2D.new()
	_inside.visible = false
	add_child(_inside)
	_build_inside()
	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()
	_set_camera(OUTSIDE_RECT.get_center(), 1.0, OUTSIDE_RECT)
	var layer := CanvasLayer.new()
	add_child(layer)
	_veil = ColorRect.new()
	_veil.size = Vector2(size)
	_veil.color = Color(1.0, 0.6, 0.25, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_veil)
	_hammer_loop()


func _exit_tree() -> void:
	_playing = false


func _process(delta: float) -> void:
	_fire_time += delta
	var frame: int = int(_fire_time * FIRE_FPS)
	_fire.frame = frame % _fire.hframes
	_inside_fire.frame = frame % _inside_fire.hframes
	# Lights breathe slowly, flicker a little and jump up with each stroke.
	_flash = maxf(0.0, _flash - delta * 2.5)
	var t: float = Time.get_ticks_msec() / 1000.0
	var flicker: float = 0.03 * sin(t * 2.1) + 0.02 * sin(t * 7.3) + randf_range(-0.01, 0.01)
	var stroke: float = _flash * (0.25 if stage != Stage.DOOR else 0.1)
	_glow.modulate.a = clampf(_glow_base + flicker + stroke, 0.0, 1.0)
	_forge_glow.modulate.a = clampf(0.2 + flicker * 1.5 + _flash * 0.3, 0.0, 1.0)
	for i in _candles.size():
		_candles[i].modulate.a = 0.32 + 0.05 * sin(t * (5.0 + i * 1.7)) + randf_range(-0.03, 0.03)
	_shake = maxf(0.0, _shake - delta * 14.0)
	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake if _shake > 0.0 else Vector2.ZERO


# --- outside ------------------------------------------------------------------------------------

func _build_outside() -> void:
	_outside.add_child(_sprite(OUTSIDE, Vector2.ZERO))
	_fire = _sheet_sprite(FIRE_SHEET, FIRE_AT)
	_outside.add_child(_fire)
	_door_left = _sprite(DOOR_LEFT, DOOR_LEFT_HINGE)
	_outside.add_child(_door_left)
	_door_right = _sprite(DOOR_RIGHT, DOOR_RIGHT_HINGE)
	_door_right.offset = Vector2(-DOOR_RIGHT.get_width(), 0)
	_outside.add_child(_door_right)
	_glow = _light(DOOR_LIGHT, Vector2i(120, 90), Color(1.0, 0.62, 0.3))
	_outside.add_child(_glow)
	_outside.add_child(_make_smoke())
	_sparks = _make_chimney_sparks()
	_outside.add_child(_sparks)


## 0 = shut, 1 = wide open: the leaves turn inwards about their hinges, so seen from the front
## they get narrower and darker.
func _set_door_open(amount: float) -> void:
	var width: float = cos(amount * PI / 2.0)
	for leaf in [_door_left, _door_right]:
		leaf.scale.x = width
		leaf.visible = width > 0.04
		var shade: float = lerpf(1.0, 0.45, amount)
		leaf.modulate = Color(shade, shade, shade)
	_glow_base = lerpf(GLOW_SHUT, GLOW_OPEN, amount)


## Soft round puff of pixels, the smoke particles grow from it.
static func _puff_texture() -> Texture2D:
	var image := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			var d: float = Vector2(x - 3, y - 3).length()
			if d <= 3.2:
				image.set_pixel(x, y, Color(1, 1, 1, 1.0 if d <= 2.2 else 0.55))
	return ImageTexture.create_from_image(image)


func _make_smoke() -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.texture = _puff_texture()
	smoke.position = CHIMNEY
	smoke.amount = 70
	smoke.lifetime = 9.0
	smoke.preprocess = 9.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(4, 1)
	smoke.direction = Vector2.UP
	smoke.spread = 6.0
	smoke.initial_velocity_min = 5.0
	smoke.initial_velocity_max = 7.0
	# The wind takes it to the right the higher it gets (like the painted smoke did).
	smoke.gravity = Vector2(1.6, -0.2)
	smoke.damping_min = 0.2
	smoke.damping_max = 0.4
	smoke.scale_amount_min = 0.9
	smoke.scale_amount_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.8))
	grow.add_point(Vector2(1.0, 2.4))
	smoke.scale_amount_curve = grow
	var tint := Gradient.new()
	tint.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	tint.colors = PackedColorArray(SMOKE_COLORS)
	smoke.color_initial_ramp = tint
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.04, 0.55, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.8),
			Color(1, 1, 1, 0.0)])
	smoke.color_ramp = fade
	return smoke


## A few glowing sparks out of the chimney with each hammer stroke.
func _make_chimney_sparks() -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.position = CHIMNEY
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 5
	sparks.lifetime = 1.6
	sparks.explosiveness = 0.8
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(4, 1)
	sparks.direction = Vector2.UP
	sparks.spread = 25.0
	sparks.initial_velocity_min = 12.0
	sparks.initial_velocity_max = 24.0
	sparks.gravity = Vector2(3, -2)
	sparks.color = SPARK_COLOR
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.4, 0.2, 0)])
	sparks.color_ramp = fade
	return sparks


## Somebody in the smithy: a round of strokes, a pause, the next round. Stops once we are inside
## (then we are the smith).
func _hammer_loop() -> void:
	await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
	while _playing and is_inside_tree() and stage != Stage.INSIDE:
		for i in randi_range(STROKES_MIN, STROKES_MAX):
			if not _playing or not is_inside_tree() or stage == Stage.INSIDE:
				return
			_stroke()
			await get_tree().create_timer(STROKE_GAP + randf_range(-0.05, 0.05)).timeout
		if not is_inside_tree():
			return
		await get_tree().create_timer(randf_range(PAUSE_MIN, PAUSE_MAX)).timeout


func _stroke() -> void:
	AudioManager.play_sound("title_hammer", randf_range(0.92, 1.04))
	_flash = 1.0
	if randf() < 0.6:
		_sparks.restart()


# --- stepping in --------------------------------------------------------------------------------

## The door opens, the camera is pulled in, inside it closes in on the anvil, then `entered`.
func enter() -> void:
	if stage != Stage.DOOR:
		return
	stage = Stage.OPENING
	AudioManager.play_sound("title_door")
	var door := _tween()
	# A short jolt (the heavy door gives), then it swings open.
	door.tween_method(_set_door_open, 0.0, 0.06, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	door.tween_method(_set_door_open, 0.06, 1.0, DOOR_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var pull := _tween()
	pull.tween_interval(PULL_DELAY)
	# Faster and faster into the door: the zoom goes up evenly in steps of "times as big".
	pull.tween_method(_pull_into_door, 0.0, 1.0, PULL_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	pull.parallel().tween_property(_veil, "color:a", 1.0, FLASH_TIME) \
			.set_delay(PULL_TIME - FLASH_TIME).set_ease(Tween.EASE_IN)
	await pull.finished
	if stage != Stage.OPENING:
		return
	_go_inside()
	_set_camera(INSIDE_RECT.get_center(), 1.0, INSIDE_RECT)
	var close_in := _tween()
	close_in.tween_property(_veil, "color:a", 0.0, FLASH_TIME).set_ease(Tween.EASE_OUT)
	close_in.parallel().tween_method(_close_in_on_anvil, 0.0, 1.0, CLOSE_IN_TIME) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await close_in.finished
	if stage == Stage.OPENING:
		stage = Stage.INSIDE
		entered.emit()


## Cuts `enter()` short (or starts right at the anvil, e.g. back from the character creator).
func skip() -> void:
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_set_door_open(1.0)
	_go_inside()
	_veil.color.a = 0.0
	_close_in_on_anvil(1.0)
	var was_inside: bool = stage == Stage.INSIDE
	stage = Stage.INSIDE
	if not was_inside:
		entered.emit()


func _pull_into_door(amount: float) -> void:
	var zoom: float = pow(PULL_ZOOM, amount)
	_set_camera(OUTSIDE_RECT.get_center().lerp(DOOR_CENTER, minf(1.0, amount * 1.6)), zoom, OUTSIDE_RECT)


func _close_in_on_anvil(amount: float) -> void:
	var start: Vector2 = INSIDE_RECT.get_center()
	_set_camera(start.lerp(MENU_VIEW, amount), lerpf(1.0, MENU_ZOOM, amount), INSIDE_RECT)


func _go_inside() -> void:
	_outside.visible = false
	_inside.visible = true
	_glow_base = GLOW_OPEN


## Camera on `center` at `zoom`, kept inside `bounds` so nothing outside the picture shows.
func _set_camera(center: Vector2, zoom: float, bounds: Rect2) -> void:
	var half: Vector2 = Vector2(size) / zoom / 2.0
	center.x = clampf(center.x, bounds.position.x + half.x, bounds.end.x - half.x)
	center.y = clampf(center.y, bounds.position.y + half.y, bounds.end.y - half.y)
	_camera.zoom = Vector2(zoom, zoom)
	_camera.position = center


## Where the middle of the anvil's face is on the 640x360 picture (for the menu's glowing word).
func get_anvil_point() -> Vector2:
	return (ANVIL_TOP - _camera.position) * _camera.zoom + Vector2(size) / 2.0


func _tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


# --- inside -------------------------------------------------------------------------------------

func _build_inside() -> void:
	_inside.add_child(_sprite(INSIDE, INSIDE_AT))
	_inside_fire = _sheet_sprite(INSIDE_FIRE_SHEET, INSIDE_FIRE_AT)
	_inside.add_child(_inside_fire)
	_forge_glow = _light(FORGE_LIGHT, Vector2i(220, 160), Color(1.0, 0.55, 0.25))
	_inside.add_child(_forge_glow)
	for at in CANDLES:
		var candle := _light(at, Vector2i(44, 44), Color(1.0, 0.75, 0.4))
		_candles.append(candle)
		_inside.add_child(candle)
	_inside.add_child(_make_embers())
	_hammer = Node2D.new()
	_hammer.position = ANVIL_TOP + (HAMMER_GRIP - HAMMER_FACE)
	_hammer.rotation_degrees = HAMMER_RAISED
	_hammer.visible = false
	var head := _sprite(HAMMER, Vector2.ZERO)
	head.offset = -HAMMER_GRIP
	_hammer.add_child(head)
	_inside.add_child(_hammer)
	_strike_sparks = _make_strike_sparks()
	_inside.add_child(_strike_sparks)


## Embers rising from the forge.
func _make_embers() -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.position = INSIDE_FIRE_AT + Vector2(32, 40)
	embers.amount = 10
	embers.lifetime = 2.2
	embers.preprocess = 2.2
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(20, 2)
	embers.direction = Vector2.UP
	embers.spread = 15.0
	embers.initial_velocity_min = 14.0
	embers.initial_velocity_max = 26.0
	embers.gravity = Vector2(0, -4)
	embers.color = SPARK_COLOR
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.4, 0.2, 0)])
	embers.color_ramp = fade
	return embers


func _make_strike_sparks() -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.position = ANVIL_TOP + Vector2(0, -2)
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 28
	sparks.lifetime = 0.7
	sparks.explosiveness = 1.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(8, 1)
	sparks.direction = Vector2.UP
	sparks.spread = 85.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 120.0
	sparks.gravity = Vector2(0, 260)
	var tint := Gradient.new()
	tint.colors = PackedColorArray([Color(1, 0.95, 0.6), Color(1, 0.6, 0.2)])
	sparks.color_initial_ramp = tint
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.7, 0.4, 0.9), Color(1, 0.3, 0.1, 0)])
	sparks.color_ramp = fade
	return sparks


## The sledgehammer comes down on the anvil. Returns shortly after the hit (`struck`); the hammer
## goes back up on its own.
func strike() -> void:
	if _striking:
		return
	_striking = true
	if stage != Stage.INSIDE:
		skip()
	_hammer.visible = true
	_hammer.rotation_degrees = HAMMER_RAISED
	var swing := _tween()
	swing.tween_property(_hammer, "rotation_degrees", HAMMER_BACK, 0.14) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	swing.tween_property(_hammer, "rotation_degrees", 0.0, 0.13) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await swing.finished
	_hit()
	var after := _tween()
	after.tween_property(_hammer, "rotation_degrees", HAMMER_BOUNCE, 0.09) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	after.tween_property(_hammer, "rotation_degrees", 0.0, 0.1).set_ease(Tween.EASE_IN)
	after.tween_interval(0.12)
	after.tween_property(_hammer, "rotation_degrees", HAMMER_RAISED, 0.3) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	after.tween_callback(_hammer.hide)
	after.tween_callback(func() -> void: _striking = false)
	await get_tree().create_timer(0.3).timeout


func _hit() -> void:
	AudioManager.play_sound("title_strike", randf_range(0.97, 1.03))
	_strike_sparks.restart()
	_flash = 1.0
	_shake = 3.0
	_veil.color = Color(1.0, 0.92, 0.75, 0.3)
	var fade := _tween()
	fade.tween_property(_veil, "color:a", 0.0, 0.25).set_ease(Tween.EASE_OUT)
	struck.emit()


# --- helpers ------------------------------------------------------------------------------------

func _sprite(texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = at
	return sprite


## Frames side by side (FIRE_SIZE each), drawn over the picture at `at`.
func _sheet_sprite(sheet: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := _sprite(sheet, at)
	sprite.hframes = maxi(1, floori(float(sheet.get_width()) / FIRE_SIZE))
	return sprite


## Warm light added on top of the picture (flickers in _process).
func _light(at: Vector2, area: Vector2i, color: Color) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = area.x
	texture.height = area.y
	var light := Sprite2D.new()
	light.texture = texture
	light.position = at
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = add
	return light
