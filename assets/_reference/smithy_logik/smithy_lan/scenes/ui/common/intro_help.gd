class_name IntroHelp
extends VBoxContainer
## Introduction (tab "Einleitung" of SettingsPanel): a scrollable list of tips (title + text);
## with `collapsible` a button "Einleitung" opens/closes it.
## Always listed: story.json "intro_hints" (in that order); every other tip from "hints" only
## once the game has shown it (GameState.story.shown_hints), so the list never spoils the story.
## Builds its own children, so it can simply be added with IntroHelp.new().

const FONT_SIZE: int = 11
const LIST_SIZE: Vector2 = Vector2(200, 110)
const COLOR_TITLE: Color = Color(0.95, 0.82, 0.5)
const COLOR_TEXT: Color = Color(0.85, 0.82, 0.75)

## true = a button opens/closes the list; false = the list is always shown (fills the space).
var collapsible: bool = true

var _scroll: ScrollContainer
var _text: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text.add_theme_color_override("default_color", COLOR_TEXT)
	_scroll.add_child(_text)
	if not collapsible:
		visibility_changed.connect(func() -> void: _on_toggled(is_visible_in_tree()))
		_on_toggled(true)
		return
	_scroll.custom_minimum_size = LIST_SIZE
	_scroll.hide()
	var button := Button.new()
	button.text = Language.translate("Einleitung")
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(button)
	move_child(button, 0)
	button.toggled.connect(_on_toggled)


func _on_toggled(pressed: bool) -> void:
	_scroll.visible = pressed
	if pressed:
		_text.text = "\n\n".join(get_entries().map(_format_entry))
		_scroll.scroll_vertical = 0


## The tips to list (dictionaries with "title" and "text"), see the class comment.
static func get_entries() -> Array:
	var hints: Dictionary = Story.get_data("hints")
	var ids: Array = Story.get_data("intro_hints").duplicate()
	for hint_id: String in hints:
		if not ids.has(hint_id) and GameState.story.shown_hints.has(hint_id):
			ids.append(hint_id)
	var entries: Array = []
	for hint_id: String in ids:
		if hints.has(hint_id):
			entries.append(hints[hint_id])
	return entries


func _format_entry(hint: Dictionary) -> String:
	var title: String = GameState.format_story_text(hint.get("title", ""))
	var text: String = GameState.format_story_text(hint.get("text", ""))
	return "[color=#%s]%s[/color]\n%s" % [COLOR_TITLE.to_html(false), _escape(title), _escape(text)]


## Tip texts are plain text: "[" would start a BBCode tag.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
