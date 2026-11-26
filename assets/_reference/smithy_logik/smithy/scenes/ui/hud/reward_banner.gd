class_name RewardBanner
extends Control
## Big announcement in the upper third of the screen for the moments that matter (player level,
## reputation rank): a gold title pops up with a subtitle below, stays a moment and fades out.
## Several wait in a queue, none overwrites another. Doesn't take clicks. Built in code (HUD).

const COLOR_TITLE: Color = Color(1.0, 0.85, 0.3)
const COLOR_SUBTITLE: Color = Color(1.0, 0.95, 0.85)
const COLOR_BAND: Color = Color(0.04, 0.03, 0.05, 0.6)
## Seconds: pop in, stay, fade out.
const POP_SECONDS: float = 0.3
const HOLD_SECONDS: float = 2.2
const FADE_SECONDS: float = 0.5
## Height of the dark band behind the texts and its distance from the top (share of the screen).
const BAND_HEIGHT: float = 52.0
const TOP_SHARE: float = 0.22

## Waiting banners: {"title", "subtitle", "color"}.
var _queue: Array[Dictionary] = []
var _showing: bool = false
var _box: VBoxContainer
var _title: Label
var _subtitle: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	_title = _label(22, COLOR_TITLE)
	_box.add_child(_title)
	_subtitle = _label(11, COLOR_SUBTITLE)
	_box.add_child(_subtitle)
	_box.hide()
	resized.connect(_place)


## Queues a banner; `color` tints the title (default gold).
func announce(title: String, subtitle: String = "", color: Color = COLOR_TITLE) -> void:
	_queue.append({"title": title, "subtitle": subtitle, "color": color})
	if not _showing:
		_show_next()


func is_showing() -> bool:
	return _showing


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_box.hide()
		queue_redraw()
		return
	var entry: Dictionary = _queue.pop_front()
	_showing = true
	_title.text = entry["title"]
	_title.add_theme_color_override("font_color", entry["color"])
	_subtitle.text = entry["subtitle"]
	_subtitle.visible = not String(entry["subtitle"]).is_empty()
	_place()
	_box.modulate.a = 1.0
	_box.pivot_offset = _box.size / 2.0
	_box.scale = Vector2(1.6, 1.6)
	_box.show()
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(_box, "scale", Vector2.ONE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(_box, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(_show_next)


func _place() -> void:
	_box.size = Vector2(size.x, BAND_HEIGHT)
	_box.position = Vector2(0, roundf(size.y * TOP_SHARE))
	_box.pivot_offset = _box.size / 2.0


func _draw() -> void:
	if _showing:
		draw_rect(Rect2(_box.position, _box.size), Color(COLOR_BAND, COLOR_BAND.a * _box.modulate.a))


func _process(_delta: float) -> void:
	if _showing:
		queue_redraw()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
