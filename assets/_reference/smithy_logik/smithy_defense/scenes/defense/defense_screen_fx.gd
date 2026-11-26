class_name DefenseScreenFx
extends Control
## Screen effects of the forge defense, in the HUD over the field: a coloured glow at the edges
## (`vignette`, the smithy is hit), a white flash (`flash`), the picture turning grey (`gray`, the
## smithy falls), a wave banner that flies through (`banner`), a big title card (`title_card`,
## boss) and arrows at the edge of the screen pointing at enemies outside the view (grouped by
## direction, the boss bigger and gold). Its nodes are built once in `_ready`; the arrows are
## drawn from the game's enemy list without making anything new (FEHLERKLASSEN 12).

const VIGNETTE_SHADER: Shader = preload("res://scenes/defense/defense_vignette.gdshader")
const GRAY_SHADER: Shader = preload("res://scenes/defense/defense_gray.gdshader")
const ARROW_SECTORS: int = 24
const ARROW_INSET: float = 12.0
const ARROW_COLOR := Color(1.0, 0.35, 0.25, 0.85)
const BOSS_ARROW_COLOR := Color(1.0, 0.8, 0.3, 1.0)
const BANNER_Y: float = 64.0
const BANNER_FONT_SIZE: int = 28
const TITLE_FONT_SIZE: int = 40

## The game whose enemies the arrows point at (set by the game).
var game: DefenseGame = null

var _vignette: ColorRect
var _vignette_tween: Tween = null
var _flash: ColorRect
var _gray: ColorRect
var _gray_amount: float = 0.0
var _banner: Label
var _banner_tween: Tween = null
var _title: Label
var _subtitle: Label
var _title_tween: Tween = null
## Per sector: how many enemies are out there, and whether the boss is one of them (reused).
var _counts := PackedInt32Array()
var _boss_in := PackedInt32Array()
## One arrow's triangle and outline (reused while drawing).
var _arrow := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _arrow_line := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counts.resize(ARROW_SECTORS)
	_boss_in.resize(ARROW_SECTORS)
	_gray = _cover()
	var gray_material := ShaderMaterial.new()
	gray_material.shader = GRAY_SHADER
	_gray.material = gray_material
	_gray.hide()
	_vignette = _cover()
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = VIGNETTE_SHADER
	_vignette.material = vignette_material
	_vignette.hide()
	_flash = _cover()
	_flash.color = Color(1, 1, 1, 0)
	_flash.hide()
	_banner = _big_label(BANNER_FONT_SIZE)
	_banner.position.y = BANNER_Y
	_title = _big_label(TITLE_FONT_SIZE)
	_subtitle = _big_label(int(BANNER_FONT_SIZE / 2.0) + 4)


func _cover() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _big_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.hide()
	add_child(label)
	return label


# --- Effects ---------------------------------------------------------------------------

## The edges glow in `color` with `strength` (0..1) and fade over `time` seconds.
func vignette(color: Color, strength: float, time: float) -> void:
	var shader: ShaderMaterial = _vignette.material
	shader.set_shader_parameter("tint", color)
	if _vignette_tween:
		_vignette_tween.kill()
	_vignette.show()
	_vignette_tween = create_tween()
	_vignette_tween.tween_method(func(value: float) -> void: shader.set_shader_parameter("amount", value), strength, 0.0, time)
	_vignette_tween.tween_callback(_vignette.hide)


## The whole screen flashes white and fades over `time` real seconds (also in slow motion).
func flash(strength: float = 0.85, time: float = 0.35) -> void:
	_flash.show()
	_flash.color = Color(1, 1, 1, strength)
	var fade := create_tween().set_ignore_time_scale(true)
	fade.tween_property(_flash, "color:a", 0.0, time)
	fade.tween_callback(_flash.hide)


## The picture turns grey (1) or gets its colour back (0) over `time` real seconds.
func gray(amount: float, time: float) -> void:
	_gray.show()
	var fade := create_tween().set_ignore_time_scale(true)
	fade.tween_method(_set_gray, _gray_amount, amount, time)
	if amount <= 0.0:
		fade.tween_callback(_gray.hide)


func _set_gray(value: float) -> void:
	_gray_amount = value
	(_gray.material as ShaderMaterial).set_shader_parameter("amount", value)


func is_gray() -> bool:
	return _gray.visible


## A line of text flies in from the left, stays a moment and flies out to the right.
func banner(text: String, color: Color) -> void:
	if _banner_tween:
		_banner_tween.kill()
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.size = Vector2(size.x, 0)
	_banner.position = Vector2(-size.x, BANNER_Y)
	_banner.show()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "position:x", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_banner_tween.tween_interval(0.9)
	_banner_tween.tween_property(_banner, "position:x", size.x, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_banner_tween.tween_callback(_banner.hide)


## A big title in the middle (boss name) that slams in, with a smaller line under it.
func title_card(text: String, subtitle: String, color: Color) -> void:
	if _title_tween:
		_title_tween.kill()
	for label: Label in [_title, _subtitle]:
		label.size = Vector2(size.x, 0)
		label.pivot_offset = Vector2(size.x / 2.0, 0)
		label.modulate = Color.WHITE
		label.show()
	_title.text = text
	_title.add_theme_color_override("font_color", color)
	_title.position = Vector2(0, size.y * 0.32)
	_subtitle.text = subtitle
	_subtitle.add_theme_color_override("font_color", Color(1, 0.9, 0.75))
	_subtitle.position = Vector2(0, size.y * 0.32 + TITLE_FONT_SIZE + 2)
	_subtitle.visible = not subtitle.is_empty()
	_title.scale = Vector2(2.2, 2.2)
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_title_tween.tween_interval(1.6)
	_title_tween.tween_property(_title, "modulate:a", 0.0, 0.4)
	_title_tween.parallel().tween_property(_subtitle, "modulate:a", 0.0, 0.4)
	_title_tween.tween_callback(_title.hide)
	_title_tween.tween_callback(_subtitle.hide)


# --- Arrows at the edge ----------------------------------------------------------------

func _process(_delta: float) -> void:
	if game != null and game.is_fighting():
		queue_redraw()


func _draw() -> void:
	if game == null or not game.is_fighting() or size.x < 32.0 or size.y < 32.0:
		return
	var view: Transform2D = game.get_viewport().get_canvas_transform()
	var inner: Rect2 = get_rect().grow(-2.0)
	var middle: Vector2 = size / 2.0
	_counts.fill(0)
	_boss_in.fill(0)
	for enemy: DefenseEnemy in game.enemies():
		if not enemy.is_alive():
			continue
		var on_screen: Vector2 = view * enemy.global_position
		if inner.has_point(on_screen):
			continue
		var angle: float = (on_screen - middle).angle()
		var sector: int = int(floor((angle + PI) / TAU * ARROW_SECTORS)) % ARROW_SECTORS
		_counts[sector] += 1
		if enemy.elite:
			_boss_in[sector] = 1
	var half: Vector2 = middle - Vector2(ARROW_INSET, ARROW_INSET)
	for sector in ARROW_SECTORS:
		if _counts[sector] == 0:
			continue
		var direction: Vector2 = Vector2.from_angle((float(sector) + 0.5) / ARROW_SECTORS * TAU - PI)
		var reach: float = minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
		var tip: Vector2 = middle + direction * reach
		var boss: bool = _boss_in[sector] == 1
		var length: float = (11.0 if boss else 6.0) + minf(float(_counts[sector]), 12.0) * 0.4
		var back: Vector2 = tip - direction * length
		var side: Vector2 = direction.orthogonal() * length * 0.55
		_arrow[0] = tip
		_arrow[1] = back + side
		_arrow[2] = back - side
		for i in 3:
			_arrow_line[i] = _arrow[i]
		_arrow_line[3] = tip
		draw_colored_polygon(_arrow, BOSS_ARROW_COLOR if boss else ARROW_COLOR)
		draw_polyline(_arrow_line, Color(0.13, 0.075, 0.12, 0.9), 1.0)
