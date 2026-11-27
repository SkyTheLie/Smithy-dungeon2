class_name BagWindow
extends CanvasLayer
## Tab during a run: the bag (RunState.bag). The game stops while it is open.
##   - every place shows its loot with a frame in its rarity colour and the count;
##   - drag and drop between places sorts (same things stack, else they swap);
##   - dragging a place out of the window drops it on the floor in front of the player
##     (Dungeon.drop_from_bag), to make room;
##   - the safe place (golden frame) keeps its things when the player dies;
##   - the gold of the run lies in the bag like everything else (Bag.GOLD): drop it, stack it,
##     put it into the safe place;
##   - opened with F at the merchant (open(true), Dungeon.trading) it is his trade window: a right
##     click sells a place (Dungeon.sell_from_bag), above the bag he offers a relic
##     (Dungeon.merchant_relic, button: Dungeon.buy_relic);
##   - left the hero: his equipment from home (HeroPanel, only shown) and below it the values of
##     the run (damage, attack speed, walking speed, luck);
##   - right the whole floor (Minimap.always_big), zoomed out so every known room fits;
##   - below the items of the run, big, with their description when the mouse is over one.
## Only shows and forwards; the rules are in Bag and Dungeon. Built in code (no .tscn).

signal closed

const SLOT_SIZE := Vector2(36, 36)
const ICON_SIZE := Vector2(27, 27)
const COLUMNS: int = 6
const MAP_SIZE := Vector2(180, 200)
const ITEM_SIZE := Vector2(26, 26)
const STATS_COLOR := Color(1, 0.9, 0.75)
const SAFE_COLOR := Color(1.0, 0.78, 0.3)
const EMPTY_BORDER := Color(0.32, 0.27, 0.24)
const PANEL_COLOR := Color(0.11, 0.08, 0.07, 0.96)
const SLOT_COLOR := Color(0.18, 0.14, 0.12)

var run: RunState
var dungeon: Dungeon

var _backdrop: ColorRect
var _panel: PanelContainer
var _map_panel: PanelContainer
var _hero: HeroPanel
var _stats: Label
var _items: HFlowContainer
## The floor map beside the bag.
var map: Minimap
var _slots: Array[Panel] = []
var _info_name: Label
var _info_text: Label
var _hint: Label
## The merchant's relic offer (only shown in the trade window).
var _offer: HBoxContainer
var _offer_icon: TextureRect
var _offer_text: Label
var _offer_button: Button


func _init() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(run_state: RunState, the_dungeon: Dungeon) -> void:
	run = run_state
	dungeon = the_dungeon
	_build()
	run.bag.changed.connect(_refresh)
	hide()


## `trade` = opened at the merchant (F): his trade window.
func open(trade: bool = false) -> void:
	if dungeon:
		dungeon.trading = trade and dungeon.in_shop()
	_refresh_offer()
	_hint.text = _hint_text()
	_refresh()
	_refresh_run()
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
	if dungeon:
		dungeon.trading = false
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
	# Left the hero and his values, in the middle the bag, right the floor; below the items.
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(outer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(row)
	row.add_child(_build_hero())
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, Color(0.55, 0.38, 0.2), 2, 6))
	# Only as tall as its content, not as tall as the hero column / map beside it.
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	outer.add_child(_build_items())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)

	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Inventar")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	column.add_child(title)
	column.add_child(_build_offer())

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

	_info_name = Label.new()
	_info_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	column.add_child(_info_name)
	_info_text = Label.new()
	_info_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_info_text.add_theme_font_size_override("font_size", 8)
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_text.custom_minimum_size = Vector2(220, 22)
	_info_text.modulate = Color(0.85, 0.8, 0.75)
	column.add_child(_info_text)

	_hint = Label.new()
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.text = _hint_text()
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.modulate = Color(0.7, 0.65, 0.6)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)


func _in_shop() -> bool:
	return dungeon != null and dungeon.trading


func _hint_text() -> String:
	if _in_shop():
		return Language.translate("Rechtsklick: an den Händler verkaufen · Ziehen: sortieren · Tab: schließen")
	if dungeon != null and dungeon.in_shop():
		return Language.translate("Verkaufen: zum Händler gehen und %s drücken · Tab: schließen") % Controls.key_name(Controls.get_key(Controls.TALK))
	return Language.translate("Ziehen: sortieren · Aus dem Fenster ziehen: fallen lassen · Tab: schließen")


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
	slot.gui_input.connect(_on_slot_input.bind(index))
	_slots.append(slot)
	return slot


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


## The merchant's relic offer: picture, name, runs and price, a button to buy it.
func _build_offer() -> Control:
	_offer = HBoxContainer.new()
	_offer.add_theme_constant_override("separation", 6)
	_offer_icon = TextureRect.new()
	_offer_icon.custom_minimum_size = ITEM_SIZE
	_offer_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_offer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_offer_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_offer.add_child(_offer_icon)
	_offer_text = Label.new()
	_offer_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_offer_text.add_theme_font_size_override("font_size", 8)
	_offer_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_offer_text.custom_minimum_size = Vector2(150, 0)
	_offer_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_offer.add_child(_offer_text)
	_offer_button = Button.new()
	_offer_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_offer_button.add_theme_font_size_override("font_size", 8)
	_offer_button.focus_mode = Control.FOCUS_NONE
	_offer_button.pressed.connect(buy_relic)
	_offer.add_child(_offer_button)
	_offer.hide()
	return _offer


## Shows the relic offer in the trade window (hidden without one or outside the trade window).
func _refresh_offer() -> void:
	if _offer == null:
		return
	var relic: Dictionary = dungeon.merchant_relic if dungeon != null and dungeon.trading else {}
	_offer.visible = not relic.is_empty()
	if relic.is_empty():
		return
	var data: Dictionary = Content.item(String(relic["id"]))
	_offer_icon.texture = load(String(data.get("icon", ""))) as Texture2D
	var runs: int = int(relic.get("left", -1))
	var lasts: String = Language.translate("hält für immer") if ShopGoods.relic_forever(relic) else Language.translate("hält %d Runs") % runs
	_offer_text.text = "%s: %s (%s)
%s" % [Language.translate("Relikt"), Language.translate(String(data.get("name", ""))), lasts, Language.translate(String(data.get("desc", "")))]
	_offer_text.modulate = Rarity.color(ShopGoods.relic_tier(String(relic["id"])))
	_offer_button.text = Language.translate("Kaufen: %d Gold") % int(relic.get("price", 0))
	_offer_button.disabled = run.coins < int(relic.get("price", 0))


## Buys the merchant's relic (Dungeon.buy_relic); the offer goes away.
func buy_relic() -> bool:
	if dungeon == null or not dungeon.buy_relic():
		return false
	_refresh_offer()
	_info_name.text = ""
	_info_text.text = Language.translate("Gekauft! Das Relikt wartet zu Hause im Inventar.")
	return true


## The hero's equipment (only shown: it is changed at home) and the values below it.
func _build_hero() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_hero = HeroPanel.new()
	column.add_child(_hero)
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, Color(0.55, 0.38, 0.2), 2, 6))
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stats_panel)
	_stats = Label.new()
	_stats.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_stats.add_theme_font_size_override("font_size", 10)
	_stats.add_theme_color_override("font_color", STATS_COLOR)
	stats_panel.add_child(_stats)
	return column


## The items of the run in a row, each with its name and description as tooltip.
func _build_items() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, Color(0.55, 0.38, 0.2), 2, 6))
	_items = HFlowContainer.new()
	_items.add_theme_constant_override("h_separation", 4)
	_items.add_theme_constant_override("v_separation", 4)
	_items.custom_minimum_size = Vector2(ITEM_SIZE.x, ITEM_SIZE.y)
	panel.add_child(_items)
	return panel


# --- The run (left and below) ---------------------------------------------------

## Equipment, values and items as they are now.
func _refresh_run() -> void:
	_hero.refresh()
	var s: ShotStats = run.stats
	_stats.text = "%s: %s
%s: %s/s
%s: %s
%s: %s" % [
		Language.translate("Schaden"), PauseMenu.format_number(s.damage),
		Language.translate("Angriffstempo"), PauseMenu.format_number(1.0 / s.fire_delay),
		Language.translate("Tempo"), PauseMenu.format_number(s.move_speed),
		Language.translate("Glück"), PauseMenu.format_number(s.luck)]
	for child: Node in _items.get_children():
		child.queue_free()
	var counts: Dictionary[String, int] = {}
	for id: String in run.items:
		counts[id] = counts.get(id, 0) + 1
	for id: String in counts:
		var data: Dictionary = Content.item(id)
		var icon := TextureRect.new()
		icon.texture = load(String(data.get("icon", ""))) as Texture2D
		icon.custom_minimum_size = ITEM_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var name_text: String = Language.translate(String(data.get("name", id)))
		if counts[id] > 1:
			name_text += " ×%d" % counts[id]
		icon.tooltip_text = name_text + "
" + Language.translate(String(data.get("desc", "")))
		_items.add_child(icon)
	if counts.is_empty():
		var none := Label.new()
		none.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		none.text = Language.translate("Noch keine Items in diesem Run.")
		none.add_theme_font_size_override("font_size", 10)
		none.modulate = Color(0.7, 0.65, 0.6)
		_items.add_child(none)


# --- Showing --------------------------------------------------------------------

func _refresh() -> void:
	if _offer != null and _offer.visible:
		_offer_button.disabled = run.coins < int(dungeon.merchant_relic.get("price", 0))
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


## Right click in the shop room: the merchant buys the place.
func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT and _in_shop():
		sell(index)


## Sells place `index` to the merchant (only in the shop room). Returns the gold.
func sell(index: int) -> int:
	if dungeon == null:
		return 0
	var gold: int = dungeon.sell_from_bag(index)
	if gold > 0:
		_show_info(index)
		_info_text.text = Language.translate("Verkauft für %d Gold") % gold
	return gold


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
	var worth: String = Language.translate("Wert: %d Gold") % int(data.get("value", 0))
	if _in_shop() and run.sell_price(index) > 0:
		worth = Language.translate("Rechtsklick: verkaufen für %d Gold") % run.sell_price(index)
	_info_text.text = "%s · %s\n%s" % [Rarity.label(tier), worth, Language.translate(String(data.get("desc", "")))]


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
