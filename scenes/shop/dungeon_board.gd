class_name DungeonBoard
extends PanelContainer
## Egon's dungeon board (the button at the bottom right of the shop), like the dungeon board of the
## adventurers' guild in Smithy: left one tab per region (data/dungeons.json "region"), a click
## opens or closes its dungeon list; right the chosen dungeon (name, level, floors, areas from
## floors.json, description, its enemies as small pictures: the ones beaten already with their
## name, the others as black silhouettes, like the lexicon) and "Betreten". Only dungeons that
## are open (MetaState.is_dungeon_open) are on the board; a line says that winning opens the next.
## Built in code.

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
## The enemies of the chosen dungeon (Content.dungeon_enemies).
var _enemies: HFlowContainer
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
	details.add_child(_label(Language.translate("Gegner:"), COLOR_HINT, 10))
	_enemies = HFlowContainer.new()
	_enemies.name = "Enemies"
	_enemies.add_theme_constant_override("h_separation", 2)
	_enemies.add_theme_constant_override("v_separation", 2)
	details.add_child(_enemies)
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
	if _selected.is_empty() or not MetaState.is_dungeon_open(_selected):
		var open_ones: Array[String] = open_dungeons()
		_selected = open_ones.back() if not open_ones.is_empty() else ""
	_show_dungeon()
	show()


func get_selected() -> String:
	return _selected


## The dungeons on the board: the open ones, in dungeons.json order.
static func open_dungeons() -> Array[String]:
	var list: Array[String] = []
	for id: String in Content.dungeons():
		if MetaState.is_dungeon_open(id):
			list.append(id)
	return list


func _build_regions() -> void:
	for child: Node in _regions.get_children():
		_regions.remove_child(child)
		child.queue_free()
	var lists: Dictionary = {}
	for id: String in open_dungeons():
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
		button.name = "Dungeon_" + id
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
	# More to come: winning the last open dungeon opens the next one.
	if open_dungeons().size() < Content.dungeons().size():
		var more := _label(Language.translate("Schaffe einen Dungeon, dann öffnet sich der nächste."), COLOR_HINT, 9)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		more.custom_minimum_size = Vector2(LIST_WIDTH, 0)
		_regions.add_child(more)


func _show_dungeon() -> void:
	var data: Dictionary = Content.dungeons().get(_selected, {})
	_enter_button.disabled = data.is_empty() or not MetaState.is_dungeon_open(_selected)
	if data.is_empty():
		_name_label.text = ""
		_facts_label.text = ""
		_desc_label.text = Language.translate("Wähle links einen Dungeon.")
		return
	_name_label.text = Language.translate(String(data.get("name", _selected)))
	_facts_label.text = Language.translate("Stufe %d · %d Ebenen") % [int(data.get("level", 1)), Content.floors(_selected).size()] \
			+ "\n" + Language.translate("Gebiete: %s") % ", ".join(_areas())
	_desc_label.text = Language.translate(String(data.get("desc", "")))
	if not MetaState.is_dungeon_open(_selected):
		_desc_label.text += "\n\n" + lock_text(_selected)
	elif MetaState.has_won(_selected):
		_desc_label.text += "\n\n" + Language.translate("Schon einmal geschafft!")
	_show_enemies()


## The enemies of the chosen dungeon: known ones with picture and name (tooltip), others black.
func _show_enemies() -> void:
	for child: Node in _enemies.get_children():
		_enemies.remove_child(child)
		child.queue_free()
	for id: String in Content.dungeon_enemies(_selected):
		var icon := TextureRect.new()
		icon.name = "Enemy_" + id
		icon.texture = Content.enemy_icon(id)
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		if Progress.has_met(id):
			icon.tooltip_text = Language.translate(String(Content.enemy(id).get("name", id)))
		else:
			icon.modulate = Color(0, 0, 0, 0.85)
			icon.tooltip_text = "???"
		_enemies.add_child(icon)


## What opens dungeon `id`: "Gesperrt: erst Dungeon der Glut schaffen." ("" = open).
static func lock_text(id: String) -> String:
	var unlock: Dictionary = Content.dungeons().get(id, {}).get("unlock", {})
	if MetaState.meets(unlock):
		return ""
	if unlock.has("dungeon") and not MetaState.has_won(String(unlock["dungeon"])):
		var before: String = Language.translate(String(Content.dungeon(String(unlock["dungeon"])).get("name", unlock["dungeon"])))
		return Language.translate("Gesperrt: erst %s schaffen.") % before
	return Language.translate("Gesperrt: ab Stufe %d.") % int(unlock.get("level", 0))


## The names of the floors' themes, each once, in order (Rattenkeller, Goblinstollen …).
func _areas() -> Array[String]:
	var names: Array[String] = []
	for i in Content.floors(_selected).size():
		var area: String = Language.translate(String(Content.floor_data(i, _selected).get("name", "")))
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
