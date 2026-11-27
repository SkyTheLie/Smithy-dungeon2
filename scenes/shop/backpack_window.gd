class_name BackpackWindow
extends PanelContainer
## The backpack window in Egon's shop (button "Rucksäcke", shown once a backpack is owned): left
## the grid with the bag and the attached backpacks (BackpackBoard), right the backpacks that are
## not attached yet (drag them onto the grid; drag an attached one back onto the list to take it
## off). Backpacks come from the skill tree (group Rucksack). R or the right mouse button turns
## the dragged backpack. Esc / "Schließen". The rules are in MetaState / BagLayout.

const COLOR_TITLE := Color(1, 0.86, 0.55)
const BOARD_ROOM := Vector2(340, 210)
const LOOSE_SIZE := Vector2(40, 40)

var board: BackpackBoard
var _loose: VBoxContainer
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Rucksäcke")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	board = BackpackBoard.new()
	board.name = "BackpackBoard"
	var area: Rect2i = BagLayout.board_rect()
	board.cell_px = BagBoard.fit_cell(area.size, BOARD_ROOM)
	board.changed.connect(_refresh)
	row.add_child(board)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 4)
	side.custom_minimum_size = Vector2(110, 0)
	row.add_child(side)
	var loose_title := Label.new()
	loose_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	loose_title.text = Language.translate("Nicht angebaut")
	loose_title.add_theme_font_size_override("font_size", 11)
	side.add_child(loose_title)
	# The list is also where an attached backpack is dropped to take it off.
	var drop_area := PanelContainer.new()
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.07, 0.05, 0.06, 0.8)
	back.set_content_margin_all(4)
	drop_area.add_theme_stylebox_override("panel", back)
	drop_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drop_area.set_drag_forwarding(Callable(), _can_drop_on_list, _drop_on_list)
	side.add_child(drop_area)
	_loose = VBoxContainer.new()
	_loose.add_theme_constant_override("separation", 4)
	_loose.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_area.add_child(_loose)
	_info = Label.new()
	_info.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_info.add_theme_font_size_override("font_size", 9)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(110, 0)
	_info.modulate = Color(0.85, 0.8, 0.75)
	side.add_child(_info)
	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Ziehen: anbauen · R / Rechtsklick beim Ziehen: drehen · Auf die Liste ziehen: abnehmen")
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.7, 0.65, 0.6)
	column.add_child(hint)
	var close_button := Button.new()
	close_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	close_button.text = Language.translate("Schließen")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(hide)
	column.add_child(close_button)


func open() -> void:
	_refresh()
	show()


func _refresh() -> void:
	board.refresh()
	for child: Node in _loose.get_children():
		child.queue_free()
	var loose: Array[String] = MetaState.loose_backpacks()
	for id: String in loose:
		_loose.add_child(_make_loose(id))
	if loose.is_empty():
		_info.text = Language.translate("Alle Rucksäcke sind angebaut. Mehr gibt es im Skillbaum.")
	else:
		_info.text = Language.translate("Zieh einen Rucksack an dein Inventar. Er muss es an einer Kante berühren.")


## One loose backpack in the list: picture, name and size; drag it onto the grid.
func _make_loose(id: String) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 4)
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.mouse_default_cursor_shape = Control.CURSOR_DRAG
	var icon := TextureRect.new()
	icon.texture = board.icon_of(id)
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(icon)
	var label := Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var cells: Vector2i = BagLayout.backpack_size(id)
	label.text = "%s %d×%d" % [Language.translate(String(BagLayout.backpack(id).get("name", id))), cells.x, cells.y]
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", BackpackBoard.color_of(id).lightened(0.4))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(label)
	entry.tooltip_text = Language.translate(String(BagLayout.backpack(id).get("desc", "")))
	entry.set_drag_forwarding(func(_at: Vector2) -> Variant: return board.make_drag(entry, id, false, Vector2i.ZERO), _can_drop_on_list, _drop_on_list)
	return entry


func _can_drop_on_list(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("backpack")


func _drop_on_list(_at: Vector2, data: Variant) -> void:
	if MetaState.remove_backpack(String((data as Dictionary)["backpack"])):
		AudioManager.play_sound("pickup", 0.9)
	elif not MetaState.loose_backpacks().has(String((data as Dictionary)["backpack"])):
		AudioManager.play_sound("denied")
		_info.text = Language.translate("Daran hängt noch ein anderer Rucksack.")
		return
	_refresh()


func _input(event: InputEvent) -> void:
	if visible and BagBoard.is_turn_event(event) and BagBoard.rotate_drag(get_viewport()):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()
