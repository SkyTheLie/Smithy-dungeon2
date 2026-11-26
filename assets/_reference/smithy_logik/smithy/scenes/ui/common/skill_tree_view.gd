class_name SkillTreeView
extends Control
## A skill tree: a picture of the class in the background, the skills as icons on it.
## Row 0 (tier 0) is at the bottom, higher tiers grow upwards like the tree. A line connects
## a skill with the one it requires. Each icon shows its level ("2/5", bottom right on the icon
## like a stack count); unlearned skills are
## greyed out, skills that can be learned/raised now have a golden frame. Hovering shows the
## skill's details (tooltip), clicking learns it / raises its level.
##
## setup() takes one Dictionary per skill:
##   icon: Texture2D, tier: int, level: int, max_level: int, tooltip: String (BBCode),
##   tooltip_details: String (BBCode, shown while Shift is held; optional),
##   can_learn: bool, requires, requires_also: index of the required skills in the list (-1 = none),
##   passive: bool (optional, drawn with an inner frame: always active, never used),
##   on_learn: Callable (called on click when can_learn)
##   on_right_click: Callable (optional, right click, e.g. the command of a learned hero skill)

## Like an item slot: 2 px frame around the 24x24 icon.
const ICON_BOX: Vector2 = Vector2(28, 28)
const ROW_STEP: float = 38.0
const BOTTOM_MARGIN: float = 16.0
## Space above the highest row.
const TOP_MARGIN: float = 2.0
const COLOR_FRAME: Color = Color(0.13, 0.075, 0.12, 0.9)
const COLOR_LEARNED: Color = Color(0.65, 0.5, 0.36)
const COLOR_CAN_LEARN: Color = Color(1.0, 0.82, 0.35)
const COLOR_LINE: Color = Color(0.85, 0.7, 0.45, 0.8)
const COLOR_LINE_INACTIVE: Color = Color(0.4, 0.35, 0.35, 0.7)
const COLOR_LEVEL: Color = Color(0.95, 0.9, 0.8)
const COLOR_PASSIVE: Color = Color(0.55, 0.7, 0.85, 0.8)
const FONT_SIZE: int = 11

## Skill icon with a coloured tooltip (HoverCard: the mouse can move into it and click the status
## effects in it).
class SkillIcon:
	extends Control
	var tooltip_normal: String = ""
	var tooltip_details: String = ""


var background: Texture2D
var _entries: Array[Dictionary] = []
var _buttons: Array[Control] = []


func _ready() -> void:
	clip_contents = true
	resized.connect(_layout)


func setup(tree_background: Texture2D, entries: Array[Dictionary]) -> void:
	background = tree_background
	_entries = entries
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	for i in entries.size():
		var button := SkillIcon.new()
		button.custom_minimum_size = ICON_BOX
		button.size = ICON_BOX
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_normal = entries[i].get("tooltip", "")
		button.tooltip_details = entries[i].get("tooltip_details", "")
		HoverCard.attach(button, button.tooltip_normal, button.tooltip_details)
		button.gui_input.connect(_on_button_input.bind(i))
		add_child(button)
		_buttons.append(button)
	_layout()


func _layout() -> void:
	var rows: Dictionary = {}
	for i in _entries.size():
		var tier: int = _entries[i].get("tier", 0)
		if not rows.has(tier):
			rows[tier] = []
		rows[tier].append(i)
	# Rows move closer together when there are more tiers than fit (top icon stays inside).
	var highest: int = rows.keys().max() if not rows.is_empty() else 0
	var step: float = ROW_STEP
	if highest > 0:
		step = minf(ROW_STEP, (size.y - BOTTOM_MARGIN - ICON_BOX.y / 2.0 - TOP_MARGIN) / highest)
	for tier: int in rows:
		var members: Array = rows[tier]
		for j in members.size():
			var x: float = size.x * (j + 1) / (members.size() + 1)
			var y: float = size.y - BOTTOM_MARGIN - tier * step
			_buttons[members[j]].position = (Vector2(x, y) - ICON_BOX / 2.0).round()
	queue_redraw()


func _draw() -> void:
	if background:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)
	for i in _entries.size():
		for required: int in [_entries[i].get("requires", -1), _entries[i].get("requires_also", -1)]:
			if required >= 0 and required < _buttons.size():
				var color: Color = COLOR_LINE if _entries[i].get("level", 0) > 0 else COLOR_LINE_INACTIVE
				draw_line(_center(required), _center(i), color, 2.0)
	var font: Font = get_theme_default_font()
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var rect := Rect2(_buttons[i].position, ICON_BOX)
		var level: int = entry.get("level", 0)
		var frame: Color = COLOR_CAN_LEARN if entry.get("can_learn", false) else (COLOR_LEARNED if level > 0 else COLOR_FRAME)
		draw_rect(rect, COLOR_FRAME)
		draw_rect(rect, frame, false, 1.0)
		if entry.get("passive", false):
			draw_rect(rect.grow(-2.0), COLOR_PASSIVE, false, 1.0)
		var icon: Texture2D = entry.get("icon")
		if icon:
			var tint: Color = Color.WHITE if level > 0 else Color(0.55, 0.55, 0.55, 0.85)
			# 1:1 in the middle (24x24 fills the box, older 16x16 icons sit smaller)
			var icon_size: Vector2 = icon.get_size()
			draw_texture_rect(icon, Rect2((rect.position + (ICON_BOX - icon_size) / 2.0).floor(), icon_size), false, tint)
		var text: String = "%d/%d" % [level, entry.get("max_level", 1)]
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(roundf(rect.end.x - width), rect.end.y - 1.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, COLOR_FRAME)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_LEVEL)


func _center(index: int) -> Vector2:
	return _buttons[index].position + ICON_BOX / 2.0


func _on_button_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		var clicked: Dictionary = _entries[index]
		if clicked.has("on_right_click"):
			(clicked["on_right_click"] as Callable).call()
		return
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		var entry: Dictionary = _entries[index]
		if entry.get("can_learn", false):
			(entry["on_learn"] as Callable).call()
