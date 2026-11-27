class_name DialogBox
extends PanelContainer
## Speech window of a character (data/story.json: speaker, portrait, lines): the face on the left,
## the name and the text, which types itself letter by letter. speak(lines) shows them one after
## the other and returns when the last one was confirmed: Space, Enter or a click anywhere
## (the first press shows the whole text at once). bark(text) shows one line without waiting.
## Built in code; the caller places it (anchors).

## The player confirmed the current line.
signal confirmed

const LETTERS_PER_SECOND: float = 45.0
## Egon's face in his 48x48 sprite.
const FACE_REGION := Rect2(12, 4, 24, 24)
const FACE_SIZE := Vector2(40, 40)
const NAME_COLOR := Color(1, 0.86, 0.55)

var _face: TextureRect
var _name: Label
var _text: Label
var _more: Label
var _typing: Tween
## true while speak() waits for the player (then clicks belong to the box).
var _waiting: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme_type_variation = &"HudPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_face = TextureRect.new()
	var face := AtlasTexture.new()
	face.atlas = load(String(Content.get_file("story").get("portrait", ""))) as Texture2D
	face.region = FACE_REGION
	_face.texture = face
	_face.custom_minimum_size = FACE_SIZE
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_face)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	_name = _label(String(Content.get_file("story").get("speaker", "")), 12, NAME_COLOR)
	column.add_child(_name)
	_text = _label("", 12, Color.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_text)
	_more = _label("▼", 10, NAME_COLOR)
	_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_more)
	var blink := create_tween().set_loops()
	blink.tween_property(_more, "modulate:a", 0.2, 0.4)
	blink.tween_property(_more, "modulate:a", 1.0, 0.4)
	_more.hide()


## Shows `lines` (German keys) one after the other; returns after the last one was confirmed.
## The box stays open (the caller hides it). `insert` goes into a "%s" of a line (after the
## translation, e.g. the name of a key).
func speak(lines: Array, insert: String = "") -> void:
	show()
	for line: Variant in lines:
		var text: String = Language.translate(String(line))
		if not insert.is_empty() and text.contains("%s"):
			text = text % insert
		_show_line(text)
		_waiting = true
		await confirmed
		if not is_inside_tree():
			return
	_waiting = false
	_more.hide()


## One line (German key) without waiting, e.g. Egon's comment when something is bought.
func bark(line: String) -> void:
	show()
	_show_line(Language.translate(line))
	_more.hide()


func is_waiting() -> bool:
	return _waiting


func _show_line(text: String) -> void:
	_text.text = text
	_text.visible_ratio = 0.0
	_more.hide()
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(0.1, text.length() / LETTERS_PER_SECOND))
	_typing.tween_callback(_more.show)


## While waiting: the first press shows the whole line, the next one goes on.
func _input(event: InputEvent) -> void:
	if not _waiting or not visible:
		return
	var click := event as InputEventMouseButton
	var pressed: bool = (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) \
			or event.is_action_pressed("ui_accept")
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _text.visible_ratio < 1.0:
		if _typing:
			_typing.kill()
		_text.visible_ratio = 1.0
		_more.show()
		return
	_waiting = false
	confirmed.emit()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
