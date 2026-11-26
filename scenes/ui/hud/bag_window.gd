class_name BagWindow
extends CanvasLayer
## Tab during a run: the bag (RunState.bag). The game stops while it is open.
##   - every place shows its loot with a frame in its rarity colour and the count;
##   - drag and drop between places sorts (same things stack, else they swap);
##   - dragging a place out of the window drops it on the floor in front of the player
##     (Dungeon.drop_from_bag), to make room;
##   - the safe place (golden frame) keeps its things when the player dies;
##   - the money bundle shows the coins of the run (they are lost on death, too);
##   - right of it the whole floor (Minimap.always_big), zoomed out so every known room fits.
## Only shows and forwards; the rules are in Bag and Dungeon. Built in code (no .tscn).

signal closed

const SLOT_SIZE := Vector2(40, 40)
const ICON_SIZE := Vector2(30, 30)
const COLUMNS: int = 6
const MAP_SIZE := Vector2(290, 230)
const PURSE_ICON: String = "res://assets/sprites/items/coin_purse.png"
const SAFE_COLOR := Color(1.0, 0.78, 0.3)
const EMPTY_BORDER := Color(0.32, 0.27, 0.24)
const PANEL_COLOR := Color(0.11, 0.08, 0.07, 0.96)
const SLOT_COLOR := Color(0.18, 0.14, 0.12)

var run: RunState
var dungeon: Dungeon

var _backdrop: ColorRect
var _panel: PanelContainer
var _map_panel: PanelContainer
## The floor map beside the bag.
var map: Minimap
var _slots: Array[Panel] = []
var _coins: Label
var _info_name: Label
var _info_text: Label


func _init() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(run_state: RunState, the_dungeon: Dungeon) -> void:
	run = run_state
	dungeon = the_dungeon
	_build()
	run.bag.changed.connect(_refresh)
	run.changed.connect(_refresh_coins)
	hide()


func open() -> void:
	_refresh()
	_refresh_coins()
	_show_info(-1)
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Pops open: a little smaller and see-through at first.
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.modulate.a = 0.0
	_backdrop.color.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.12)
	tween.tween_property(_backdrop, "color:a", 0.45, 0.16)
	AudioManager.play_sound("pickup", 0.8)


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(Controls.BAG) or event.is_action_pressed(Controls.PAUSE)):
		get_viewport().set_input_as_handled()
		close()


# --- Building -------------------------------------------------------------------

func _build() -> void:
	# The dark backdrop is also the "floor": things dropped on it fall out of the bag.
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.45)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.set_drag_forwarding(Callable(), _can_drop_on_floor, _drop_on_floor)
	add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	# The bag on the left, the whole floor on the right.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, Color(0.55, 0.38, 0.2), 2, 6))
	row.add_child(_panel)
	_map_panel = PanelContainer.new()
	_map_panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, Color(0.55, 0.38, 0.2), 2, 6))
	row.add_child(_map_panel)
	map = Minimap.new()
	map.always_big = true
	map.custom_minimum_size = MAP_SIZE
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(map)
	map.setup(dungeon, dungeon.player)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)

	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Inventar")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	column.add_child(grid)
	for i in run.bag.normal_count:
		grid.add_child(_make_slot(i))

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	column.add_child(bottom)
	for i in range(run.bag.normal_count, run.bag.size()):
		bottom.add_child(_make_slot(i))
	var safe_text := Label.new()
	safe_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	safe_text.text = Language.translate("Sicherer Platz: bleibt, wenn du stirbst")
	safe_text.add_theme_color_override("font_color", SAFE_COLOR)
	safe_text.add_theme_font_size_override("font_size", 8)
	safe_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safe_text.custom_minimum_size = Vector2(120, 0)
	safe_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(safe_text)
	bottom.add_child(_make_purse())

	_info_name = Label.new()
	_info_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	column.add_child(_info_name)
	_info_text = Label.new()
	_info_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_info_text.add_theme_font_size_override("font_size", 8)
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_text.custom_minimum_size = Vector2(264, 22)
	_info_text.modulate = Color(0.85, 0.8, 0.75)
	column.add_child(_info_text)

	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Ziehen: sortieren · Aus dem Fenster ziehen: fallen lassen · Tab: schließen")
	hint.add_theme_font_size_override("font_size", 8)
	hint.modulate = Color(0.7, 0.65, 0.6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)


func _make_slot(index: int) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size = ICON_SIZE
	icon.position = (SLOT_SIZE - ICON_SIZE) / 2.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var count := Label.new()
	count.name = "Count"
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.add_theme_font_size_override("font_size", 8)
	count.add_theme_color_override("font_outline_color", Color.BLACK)
	count.add_theme_constant_override("outline_size", 3)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.size = Vector2(SLOT_SIZE.x - 4, 12)
	count.position = Vector2(0, SLOT_SIZE.y - 13)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	slot.set_drag_forwarding(_get_drag.bind(index), _can_drop_on_slot.bind(index), _drop_on_slot.bind(index))
	slot.mouse_entered.connect(_show_info.bind(index))
	slot.mouse_exited.connect(_show_info.bind(-1))
	_slots.append(slot)
	return slot


## The money bundle: the coins of the run (not a place of the bag, cannot be dragged).
func _make_purse() -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var frame := Panel.new()
	frame.custom_minimum_size = SLOT_SIZE
	frame.add_theme_stylebox_override("panel", _box(SLOT_COLOR, Color(0.85, 0.7, 0.3), 2, 4))
	var icon := TextureRect.new()
	icon.texture = load(PURSE_ICON) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size = ICON_SIZE
	icon.position = (SLOT_SIZE - ICON_SIZE) / 2.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)
	frame.mouse_entered.connect(_show_purse_info)
	frame.mouse_exited.connect(_show_info.bind(-1))
	box.add_child(frame)
	_coins = Label.new()
	_coins.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_coins.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	_coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins.custom_minimum_size = Vector2(36, 0)
	box.add_child(_coins)
	return box


static func _box(fill: Color, border: Color, width: int, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


# --- Showing --------------------------------------------------------------------

func _refresh() -> void:
	for i in _slots.size():
		var place: Dictionary = run.bag.get_place(i)
		var slot: Panel = _slots[i]
		var icon := slot.get_node("Icon") as TextureRect
		var count := slot.get_node("Count") as Label
		var border: Color = SAFE_COLOR if run.bag.is_safe(i) else EMPTY_BORDER
		if place.is_empty():
			icon.texture = null
			count.text = ""
		else:
			var data: Dictionary = Content.material(String(place["id"]))
			icon.texture = load(String(data.get("icon", ""))) as Texture2D
			count.text = str(int(place["count"])) if int(place["count"]) > 1 else ""
			if not run.bag.is_safe(i):
				border = Rarity.color(int(data.get("rarity", 1)))
		slot.add_theme_stylebox_override("panel", _box(SLOT_COLOR, border, 3 if run.bag.is_safe(i) else 2, 4))


func _refresh_coins() -> void:
	if _coins:
		_coins.text = str(run.coins)


func _show_info(index: int) -> void:
	var place: Dictionary = run.bag.get_place(index) if index >= 0 else {}
	if place.is_empty():
		_info_name.text = Language.translate("Sicherer Platz") if run.bag.is_safe(index) else ""
		_info_name.modulate = SAFE_COLOR
		_info_text.text = Language.translate("Was hier liegt, verlierst du nicht, wenn du stirbst.") if run.bag.is_safe(index) else ""
		return
	var data: Dictionary = Content.material(String(place["id"]))
	var tier: int = int(data.get("rarity", 1))
	_info_name.text = "%s ×%d" % [Language.translate(String(data.get("name", ""))), int(place["count"])]
	_info_name.modulate = Rarity.color(tier)
	_info_text.text = "%s · %s\n%s" % [Rarity.label(tier), Language.translate("Wert: %d Gold") % int(data.get("value", 0)), Language.translate(String(data.get("desc", "")))]


func _show_purse_info() -> void:
	_info_name.text = Language.translate("Geldbündel: %d Gold") % run.coins
	_info_name.modulate = Color(1.0, 0.86, 0.35)
	_info_text.text = Language.translate("Stirbst du, ist das Geld weg. Bring es nach Hause in deine Dose.")


# --- Drag and drop --------------------------------------------------------------

func _get_drag(_at: Vector2, index: int) -> Variant:
	var place: Dictionary = run.bag.get_place(index)
	if place.is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture = (_slots[index].get_node("Icon") as TextureRect).texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.size = ICON_SIZE
	preview.position = -ICON_SIZE / 2.0
	var holder := Control.new()
	holder.add_child(preview)
	_slots[index].set_drag_preview(holder)
	return {"bag_index": index}


func _can_drop_on_slot(_at: Vector2, data: Variant, _index: int) -> bool:
	return data is Dictionary and (data as Dictionary).has("bag_index")


func _drop_on_slot(_at: Vector2, data: Variant, index: int) -> void:
	run.bag.move(int((data as Dictionary)["bag_index"]), index)
	AudioManager.play_sound("pickup", 1.3)


func _can_drop_on_floor(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("bag_index")


func _drop_on_floor(_at: Vector2, data: Variant) -> void:
	if dungeon and dungeon.drop_from_bag(int((data as Dictionary)["bag_index"])):
		AudioManager.play_sound("pickup", 0.6)
