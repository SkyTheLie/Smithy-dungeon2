class_name DungeonBoard
extends PanelContainer
## Egon's dungeon board (the button at the bottom right of the shop), like the dungeon board of the
## adventurers' guild in Smithy: left one tab per region (data/dungeons.json "region"), a click
## opens or closes its dungeon list; right the chosen dungeon (name, level, floors, areas from
## floors.json, description) and "Betreten". Built in code.

## "Betreten" for dungeon `id` (the shop then asks for the character).
signal entered(id: String)

const FONT_SIZE: int = 12
const COLOR_TITLE := Color(1, 0.86, 0.55)
const COLOR_HINT := Color(0.62, 0.6, 0.56)
const LIST_WIDTH: float = 140.0

var _selected: String = ""
## true = Egon sends you off (end of his tour): no "Schließen", Escape does nothing.
var forced: bool = false
var _close_button: Button
var _regions: VBoxContainer
var _name_label: Label
var _facts_label: Label
var _desc_label: Label
var _enter_button: Button
var _group := ButtonGroup.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(440, 230)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := _label(Language.translate("Dungeon-Brett"), COLOR_TITLE, 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close_button = _button(Language.translate("Schließen"))
	_close_button.pressed.connect(hide)
	header.add_child(_close_button)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	box.add_child(columns)
	_regions = VBoxContainer.new()
	_regions.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	_regions.add_theme_constant_override("separation", 2)
	columns.add_child(_regions)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	columns.add_child(details)
	_name_label = _label("", COLOR_TITLE, 16)
	details.add_child(_name_label)
	_facts_label = _label("", COLOR_HINT, FONT_SIZE)
	details.add_child(_facts_label)
	_desc_label = _label("", Color.WHITE, FONT_SIZE)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(_desc_label)
	_enter_button = _button(Language.translate("Betreten"))
	_enter_button.add_theme_font_size_override("font_size", 16)
	_enter_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_enter_button.pressed.connect(func() -> void:
			if not _selected.is_empty():
				entered.emit(_selected))
	details.add_child(_enter_button)


## Shows the board with every region open and the first dungeon chosen. `must_go` = it cannot
## be closed (Egon sends you off).
func open(must_go: bool = false) -> void:
	forced = must_go
	_close_button.visible = not forced
	_build_regions()
	if _selected.is_empty() or not Content.dungeons().has(_selected):
		_selected = String(Content.dungeons().keys().front()) if not Content.dungeons().is_empty() else ""
	_show_dungeon()
	show()


func get_selected() -> String:
	return _selected


func _build_regions() -> void:
	for child: Node in _regions.get_children():
		_regions.remove_child(child)
		child.queue_free()
	var lists: Dictionary = {}
	for id: String in Content.dungeons():
		var data: Dictionary = Content.dungeons()[id]
		var region: String = String(data.get("region", ""))
		if not lists.has(region):
			var tab := _button(Language.translate(region))
			tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_regions.add_child(tab)
			var list := VBoxContainer.new()
			list.add_theme_constant_override("separation", 1)
			_regions.add_child(list)
			tab.pressed.connect(func() -> void: list.visible = not list.visible)
			lists[region] = list
		var button := _button(Language.translate(String(data.get("name", id))))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = _group
		button.button_pressed = id == _selected
		button.pressed.connect(func() -> void:
				_selected = id
				_show_dungeon())
		# Indented under its tab.
		var row := MarginContainer.new()
		row.add_theme_constant_override("margin_left", 8)
		row.add_child(button)
		(lists[region] as VBoxContainer).add_child(row)


func _show_dungeon() -> void:
	var data: Dictionary = Content.dungeons().get(_selected, {})
	_enter_button.disabled = data.is_empty()
	if data.is_empty():
		_name_label.text = ""
		_facts_label.text = ""
		_desc_label.text = Language.translate("Wähle links einen Dungeon.")
		return
	_name_label.text = Language.translate(String(data.get("name", _selected)))
	_facts_label.text = Language.translate("Stufe %d · %d Ebenen") % [int(data.get("level", 1)), Content.floors().size()] \
			+ "\n" + Language.translate("Gebiete: %s") % ", ".join(_areas())
	_desc_label.text = Language.translate(String(data.get("desc", "")))


## The names of the floors' themes, each once, in order (Rattenkeller, Goblinstollen …).
func _areas() -> Array[String]:
	var names: Array[String] = []
	for i in Content.floors().size():
		var area: String = Language.translate(String(Content.floor_data(i).get("name", "")))
		if not area.is_empty() and not names.has(area):
			names.append(area)
	return names


func _unhandled_input(event: InputEvent) -> void:
	if visible and not forced and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
