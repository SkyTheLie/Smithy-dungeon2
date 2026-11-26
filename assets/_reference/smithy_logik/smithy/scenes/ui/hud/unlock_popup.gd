class_name UnlockPopup
extends Control
## Something new is unlocked (UnlockNotices): a small see-through box in the foreground with a
## picture, the name and a short text. One at a time: the next comes when it was clicked away or
## after SECONDS, each with its sound. The rest of the screen stays clickable. Every scene has its own HUD, so the
## queue is static; a scene change throws away what is on screen and still waiting (it does not come again).

const SECONDS: float = 3.0
const FADE_SECONDS: float = 0.15
## The whole box with its text, see-through.
const ALPHA: float = 0.8
const ICON_SIZE: float = 32.0
const TEXT_WIDTH: float = 170.0
## Space above the thin bars.
const GAP: float = 3.0
const COLOR_TITLE: Color = Color(1.0, 0.85, 0.3)

## Tells the HUD how high the box stands (0 = gone): the messages move up meanwhile.
signal height_changed(height: float)

## Waiting boxes: {"icon", "title", "text"}; the one on screen stays first until it is gone.
static var _queue: Array[Dictionary] = []

## The thin experience bars, the box sits right on top of them (set before adding to the tree).
var anchor_control: Control

var _box: PanelContainer
var _icon: TextureRect
var _title: Label
var _text: Label
var _time_left: float = 0.0
var _closing: bool = false


static func add(icon: Texture2D, title: String, text: String) -> void:
	_queue.append({"icon": icon, "title": title, "text": text})


## New game or a loaded save: nothing left over.
static func clear() -> void:
	_queue.clear()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	_box = PanelContainer.new()
	_box.theme_type_variation = &"HudPanel"
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.gui_input.connect(_on_box_input)
	_box.hide()
	add_child(_box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	_box.add_child(row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	_title = _label(11)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	texts.add_child(_title)
	_text = _label(11)
	texts.add_child(_text)


## Leaving the map (the HUD goes with the scene): the popups are gone, not repeated in the next one.
func _exit_tree() -> void:
	clear()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _closing:
		return
	if _box.visible:
		_time_left -= delta
		if _time_left <= 0.0:
			_close()
	elif not _queue.is_empty():
		_show_first()


func _show_first() -> void:
	var entry: Dictionary = _queue[0]
	_icon.texture = entry["icon"]
	_icon.visible = entry["icon"] != null
	_title.text = entry["title"]
	_text.text = entry["text"]
	_text.visible = not String(entry["text"]).is_empty()
	_box.reset_size()
	_box.position = Vector2(roundf((size.x - _box.size.x) / 2.0), roundf(anchor_control.position.y - _box.size.y - GAP))
	_box.modulate.a = 0.0
	_box.show()
	move_to_front()
	_time_left = SECONDS
	AudioManager.play_sound("unlock")
	height_changed.emit(_box.size.y + GAP)
	create_tween().tween_property(_box, "modulate:a", ALPHA, FADE_SECONDS)


func _close() -> void:
	_closing = true
	var tween := create_tween()
	tween.tween_property(_box, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void:
		_box.hide()
		_closing = false
		height_changed.emit(0.0)
		_queue.pop_front())


func _on_box_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and not _closing:
		accept_event()
		_close()


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.custom_minimum_size.x = TEXT_WIDTH
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
