class_name BagWindow
extends CanvasLayer
## Tab during a run: the bag (RunState.bag). The game stops while it is open. Kept small:
##   - in the middle the bag as a grid (BagBoard, Bag.MAIN: the bag and the backpacks attached at
##     home), below it the safe place (golden, Bag.SAFE): what lies there stays when the player
##     dies. Every piece of loot covers its cells (a rat fur 2×2, a staff 4×1, a ruby 3×3);
##   - drag and drop moves it (the same thing stacks, else two pieces swap), R or the right mouse
##     button while dragging turns it; dragging it out of the window drops it on the floor in
##     front of the player (Dungeon.drop_from_bag), to make room;
##   - the gold of the run lies in the bag like everything else (Bag.GOLD);
##   - opened with F at the merchant (open(true), Dungeon.trading) it is his trade window: a right
##     click sells a piece (Dungeon.sell_from_bag), above the bag he offers a relic
##     (Dungeon.merchant_relic, button: Dungeon.buy_relic);
##   - left, small: the hero's equipment from home (HeroPanel, only shown) and the values of the
##     run; right the whole floor (Minimap.always_big); below the items of the run;
##   - the guide of the first run (DungeonGuide) can show a line at the top and let the safe place
##     pulse (set_guide);
##   - under the safe place: what the bag is worth (what Egon pays for the loot, Bag.total_value);
##   - holding X over a piece of loot for DROP_HOLD seconds throws it on the floor (no dragging);
##   - the values of the run end with the number of active synergies (their names as tooltip).
## Only shows and forwards; the rules are in Bag and Dungeon. Built in code (no .tscn).

signal closed

const MAP_SIZE := Vector2(132, 150)
const ITEM_SIZE := Vector2(18, 18)
const HERO_SCALE: float = 0.6
## Room for the bag grid (with its backpacks) in the middle; the cells shrink to fit.
const BOARD_ROOM := Vector2(250, 130)
## The middle panel always has this size (it does not grow or jump while the text changes).
const PANEL_SIZE := Vector2(300, 292)
## The description of the piece under the mouse: this wide, at most this many lines (fixed room).
const INFO_WIDTH: float = 200.0
const INFO_LINES: int = 6
## Holding X this long over loot throws it on the floor.
const DROP_HOLD: float = 0.45
const DROP_KEY: Key = KEY_X
const STATS_COLOR := Color(1, 0.9, 0.75)
const SAFE_COLOR := Color(1.0, 0.78, 0.3)
const GUIDE_COLOR := Color(0.55, 1.0, 0.6)
const PANEL_COLOR := Color(0.11, 0.08, 0.07, 0.96)
const PANEL_BORDER := Color(0.55, 0.38, 0.2)

var run: RunState
var dungeon: Dungeon

var _backdrop: ColorRect
var _panel: PanelContainer
var _hero: HeroPanel
var _hero_holder: Control
var _stats: Label
var _items: HFlowContainer
## The floor map beside the bag.
var map: Minimap
## The bag with its backpacks, and the safe place.
var main_board: BagBoard
var safe_board: BagBoard
var _info_name: Label
var _info_text: Label
var _hint: Label
var _worth: Label
## Quick drop: the piece under the mouse and how long X is held.
var _hovered: int = -1
var _drop_held: float = 0.0
var _guide: Label
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
	hide()


## `trade` = opened at the merchant (F): his trade window.
func open(trade: bool = false) -> void:
	if dungeon:
		dungeon.trading = trade and dungeon.in_shop()
	_refresh_offer()
	_hint.text = _hint_text()
	_hint.visible = key_help_on()
	main_board.refresh()
	safe_board.refresh()
	_refresh_run()
	_show_info(-1)
	_refresh_worth()
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


## The guide's line at the top ("" = none) and whether the safe place pulses.
func set_guide(text: String, point_at_safe: bool) -> void:
	_guide.text = text
	_guide.visible = not text.is_empty()
	safe_board.pulse = point_at_safe


func _input(event: InputEvent) -> void:
	# Turning a dragged piece (before the GUI sees the right click).
	if visible and BagBoard.is_turn_event(event) and BagBoard.rotate_drag(get_viewport()):
		get_viewport().set_input_as_handled()


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
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(outer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(row)
	row.add_child(_build_hero())
	_panel = _new_panel()
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_panel)
	var map_panel: PanelContainer = _new_panel()
	map_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(map_panel)
	map = Minimap.new()
	map.always_big = true
	map.custom_minimum_size = MAP_SIZE
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map)
	map.setup(dungeon, dungeon.player)
	outer.add_child(_build_items())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)
	var title := _small_label(Language.translate("Inventar"), 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	column.add_child(title)
	_guide = _small_label("", 8)
	_guide.add_theme_color_override("font_color", GUIDE_COLOR)
	_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_guide.custom_minimum_size = Vector2(180, 0)
	_guide.hide()
	column.add_child(_guide)
	column.add_child(_build_offer())

	main_board = BagBoard.new()
	main_board.name = "MainBoard"
	safe_board = BagBoard.new()
	safe_board.name = "SafeBoard"
	var cell: float = BagBoard.fit_cell(_span_of(Bag.MAIN), BOARD_ROOM)
	main_board.cell_px = cell
	safe_board.cell_px = cell
	main_board.setup(run.bag, Bag.MAIN)
	safe_board.setup(run.bag, Bag.SAFE)
	for board: BagBoard in [main_board, safe_board]:
		board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		board.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		board.hovered.connect(_show_info)
		board.dropped.connect(_refresh_worth)
		board.right_clicked.connect(_on_right_click)
		board.shift_clicked.connect(shift_move)
		board.dropped.connect(func() -> void: _show_info(-1))
	column.add_child(main_board)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	column.add_child(bottom)
	bottom.add_child(safe_board)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(info)
	var safe_text := _small_label(Language.translate("Sicherer Platz: bleibt, wenn du stirbst"), 8)
	safe_text.add_theme_color_override("font_color", SAFE_COLOR)
	safe_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safe_text.custom_minimum_size = Vector2(110, 0)
	info.add_child(safe_text)
	_worth = _small_label("", 8)
	_worth.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	info.add_child(_worth)
	_info_name = _small_label("", 8)
	_info_name.custom_minimum_size = Vector2(INFO_WIDTH, 0)
	_info_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(_info_name)
	_info_text = _small_label("", 8)
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Fixed room: always INFO_LINES lines high, longer texts are cut (the window keeps its size).
	_info_text.max_lines_visible = INFO_LINES
	_info_text.custom_minimum_size = Vector2(INFO_WIDTH, INFO_LINES * 10.0)
	_info_text.modulate = Color(0.85, 0.8, 0.75)
	info.add_child(_info_text)

	_hint = _small_label(_hint_text(), 8)
	_hint.modulate = Color(0.7, 0.65, 0.6)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(180, 0)
	column.add_child(_hint)


## Width × height in cells of a section of the bag (to pick the cell size).
func _span_of(section: String) -> Vector2i:
	var cells: Array[Vector2i] = run.bag.section_cells(section)
	if cells.is_empty():
		return Vector2i.ONE
	var low: Vector2i = cells[0]
	var high: Vector2i = cells[0]
	for c: Vector2i in cells:
		low = low.min(c)
		high = high.max(c)
	return high - low + Vector2i.ONE


func _new_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR, PANEL_BORDER, 2, 5))
	return panel


func _small_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _in_shop() -> bool:
	return dungeon != null and dungeon.trading


## What the bag is worth: what Egon pays for all the loot in it.
func _refresh_worth() -> void:
	_worth.text = Language.translate("Wert der Tasche: %d Gold") % run.bag.total_value()


## Quick drop: X held over a piece of loot fills a bar, then it falls on the floor.
func _process(delta: float) -> void:
	if not visible:
		return
	if not Input.is_physical_key_pressed(DROP_KEY) or _hovered < 0 or not _can_drop_index(_hovered):
		if _drop_held > 0.0:
			_drop_held = 0.0
			_show_info(_hovered)
		return
	_drop_held += delta
	var filled: int = clampi(int(_drop_held / DROP_HOLD * 5.0), 0, 5)
	_info_text.text = Language.translate("Wegwerfen …") + " " + "■".repeat(filled) + "□".repeat(5 - filled)
	if _drop_held >= DROP_HOLD:
		_drop_held = 0.0
		if dungeon and dungeon.drop_from_bag(_hovered):
			AudioManager.play_sound("pickup", 0.6)
			main_board.refresh()
			safe_board.refresh()
			_refresh_worth()
		_hovered = -1
		_show_info(-1)


func _can_drop_index(index: int) -> bool:
	var place: Dictionary = run.bag.get_place(index)
	return not place.is_empty() and not Bag.is_piece(place)


func _hint_text() -> String:
	var turn: String = Language.translate("R / Rechtsklick beim Ziehen: drehen") + " · " + Language.translate("X halten: wegwerfen") + " · " + Language.translate("Shift+Klick: sicherer Platz")
	if _in_shop():
		return Language.translate("Rechtsklick: an den Händler verkaufen · Ziehen: sortieren · Tab: schließen") + "\n" + turn
	if dungeon != null and dungeon.in_shop():
		return Language.translate("Verkaufen: zum Händler gehen und %s drücken · Tab: schließen") % Controls.key_name(Controls.get_key(Controls.TALK)) + "\n" + turn
	return Language.translate("Ziehen: sortieren · Aus dem Fenster ziehen: fallen lassen · Tab: schließen") + "\n" + turn


static func _box(fill: Color, border: Color, width: int, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


## The merchant's relic offer: picture, name, runs and price, a button to buy it.
func _build_offer() -> Control:
	_offer = HBoxContainer.new()
	_offer.add_theme_constant_override("separation", 4)
	_offer_icon = TextureRect.new()
	_offer_icon.custom_minimum_size = ITEM_SIZE
	_offer_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_offer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_offer_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_offer.add_child(_offer_icon)
	_offer_text = _small_label("", 8)
	_offer_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_offer_text.custom_minimum_size = Vector2(120, 0)
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
	_offer_text.text = "%s: %s (%s)\n%s" % [Language.translate("Relikt"), Language.translate(String(data.get("name", ""))), lasts, Language.translate(String(data.get("desc", "")))]
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


## The hero's equipment (small, only shown: it is changed at home) and the values below it.
func _build_hero() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_hero_holder = Control.new()
	_hero_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_hero_holder)
	_hero = HeroPanel.new()
	_hero.scale = Vector2(HERO_SCALE, HERO_SCALE)
	_hero_holder.add_child(_hero)
	var stats_panel: PanelContainer = _new_panel()
	column.add_child(stats_panel)
	_stats = _small_label("", 8)
	_stats.add_theme_color_override("font_color", STATS_COLOR)
	stats_panel.add_child(_stats)
	return column


## The items of the run in a row, each with its name and description as tooltip.
func _build_items() -> Control:
	var panel: PanelContainer = _new_panel()
	_items = HFlowContainer.new()
	_items.add_theme_constant_override("h_separation", 3)
	_items.add_theme_constant_override("v_separation", 3)
	_items.custom_minimum_size = Vector2(ITEM_SIZE.x, ITEM_SIZE.y)
	panel.add_child(_items)
	return panel


# --- The run (left and below) ---------------------------------------------------

## Equipment, values and items as they are now.
func _refresh_run() -> void:
	_hero.refresh()
	_hero_holder.custom_minimum_size = _hero.get_combined_minimum_size() * HERO_SCALE
	var s: ShotStats = run.stats
	_stats.text = "%s: %s\n%s: %s/s\n%s: %s\n%s: %s" % [
			Language.translate("Schaden"), PauseMenu.format_number(s.damage),
			Language.translate("Angriffstempo"), PauseMenu.format_number(1.0 / s.fire_delay),
			Language.translate("Tempo"), PauseMenu.format_number(s.move_speed),
			Language.translate("Glück"), PauseMenu.format_number(s.luck)]
	# Active synergies: how many, their names as tooltip.
	var names: PackedStringArray = []
	for id: String in run.synergies:
		names.append(Language.translate(String((Content.synergies().get(id, {}) as Dictionary).get("name", id))))
	_stats.text += "\n%s: %d" % [Language.translate("Synergien"), names.size()]
	_stats.tooltip_text = "\n".join(names)
	_stats.mouse_filter = Control.MOUSE_FILTER_STOP
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
		icon.tooltip_text = name_text + "\n" + Language.translate(String(data.get("desc", "")))
		_items.add_child(icon)
	if counts.is_empty():
		var none := _small_label(Language.translate("Noch keine Items in diesem Run."), 8)
		none.modulate = Color(0.7, 0.65, 0.6)
		_items.add_child(none)


# --- Showing --------------------------------------------------------------------

## Shift+click: the piece goes from the bag into the safe place or back (where there is room).
func shift_move(index: int) -> bool:
	var place: Dictionary = run.bag.get_place(index)
	if place.is_empty():
		return false
	var from: String = run.bag.section_of(Vector2i(int(place["x"]), int(place["y"])))
	var target: String = Bag.SAFE if from == Bag.MAIN else Bag.MAIN
	var spot: Dictionary = run.bag.free_spot_for(place, target)
	if spot.is_empty() or not run.bag.move_to(index, Vector2i(int(spot["x"]), int(spot["y"])), bool(spot["rot"])):
		AudioManager.play_sound("denied")
		_info_text.text = Language.translate("Kein Platz")
		return false
	AudioManager.play_sound("pickup", 1.1)
	main_board.refresh()
	safe_board.refresh()
	_show_info(-1)
	return true


## Key help on (settings: "Tastenhilfe anzeigen").
static func key_help_on() -> bool:
	return bool(WindowLayout.get_setting("ui", "key_help", true))


## Right click on a piece: in the trade window the merchant buys it.
func _on_right_click(index: int) -> void:
	if _in_shop():
		sell(index)


## Sells place `index` to the merchant (only in the shop room). Returns the gold.
func sell(index: int) -> int:
	if dungeon == null:
		return 0
	var gold: int = dungeon.sell_from_bag(index)
	if gold > 0:
		_refresh_offer()
		_refresh_worth()
		_info_name.text = ""
		_info_text.text = Language.translate("Verkauft für %d Gold") % gold
	return gold


func _show_info(index: int) -> void:
	_hovered = index
	var place: Dictionary = run.bag.get_place(index) if index >= 0 else {}
	if place.is_empty():
		_info_name.text = ""
		_info_text.text = ""
		return
	if Bag.is_piece(place):
		# Gear, a relic or a potion carried along: the same text as in Egon's shop.
		var lines: PackedStringArray = ShopSlot.describe(place, false).split("
", false, 1)
		_info_name.text = lines[0]
		_info_name.modulate = Rarity.color(ShopSlot.rarity_of(place))
		_info_text.text = lines[1] if lines.size() > 1 else ""
		return
	var data: Dictionary = Content.material(String(place["id"]))
	var tier: int = int(data.get("rarity", 1))
	_info_name.text = "%s ×%d" % [Language.translate(String(data.get("name", ""))), int(place["count"])]
	_info_name.modulate = Rarity.color(tier)
	var cells: Vector2i = BagLayout.loot_size(String(place["id"]))
	var worth: String = Language.translate("Wert: %d Gold") % int(data.get("value", 0))
	if _in_shop() and run.sell_price(index) > 0:
		worth = Language.translate("Rechtsklick: verkaufen für %d Gold") % run.sell_price(index)
	_info_text.text = "%s · %d×%d · %s\n%s" % [Rarity.label(tier), cells.x, cells.y, worth, Language.translate(String(data.get("desc", "")))]


# --- Dropping on the floor --------------------------------------------------------

## Loot can be thrown on the floor; gear, relics and potions cannot (there is no pickup for them).
func _can_drop_on_floor(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("bag_index") 			and not Bag.is_piece(run.bag.get_place(int((data as Dictionary)["bag_index"])))


func _drop_on_floor(_at: Vector2, data: Variant) -> void:
	if dungeon and dungeon.drop_from_bag(int((data as Dictionary)["bag_index"])):
		AudioManager.play_sound("pickup", 0.6)
		_show_info(-1)
		_refresh_worth()
