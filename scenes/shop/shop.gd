class_name MerchantShop
extends Control
## Egon's shop between the days (after the intro, "Weiter", after every run). Layout like the
## sketch of the developer: top Egon's table (a grid, ItemBoard: every piece covers its cells,
## price in the corner), right of it the lever with today's price below, left two tabs
## (Ausrüstung: the hero with his equipment, HeroPanel; Inventar: the bag of the next run with its
## backpacks and the safe place, BackpackBoard), bottom the stash (a grid 5 × 4, MetaState.stash;
## what has no room lies beside it under "Kein Platz"), in the middle Egon's speech window
## (DialogBox), Egon himself on the right, the buttons along the bottom edge.
##   Lever: MetaState.pull_lever (first pull of a day free, then dearer); the table flips over.
##   Click on goods: buy (MetaState.buy). Click on gear in the stash: put it on (equip), click on
##   a backpack: attach it (attach_backpack_anywhere), click on a hero place: take it off.
##   Drag and drop in the stash: move (move_in_stash), R or the right mouse button while dragging
##   turns. A backpack from the stash onto the Inventar tab: attach it there; an attached one back
##   into the stash: take it off (detach_backpack).
##   The money box (Dose, bottom right): all gold at home is in it (also the number at the top
##   left). "120/200" above it, green up to the limit, red above it (then Egon may help himself,
##   MetaState.roll_theft). Only shown: buying pays from it, selling fills it.
##   Drag and drop: from the table into the stash = buy (on that cell), from the stash onto the
##   table = sell (MetaState.sell), from the stash onto a hero place = put on, from a hero place
##   into the stash = take off. While dragging the picture is under the mouse and the cells or
##   places below show green (it goes there) or red.
##   Top right the quest place: drag the stone of an open quest there (MetaState.deliver_quest);
##   Egon talks, pays, and moves on with his shop (MetaState.location: another background).
##   "Quests" (bottom): the quest window (QuestWindow).
##   "Skills" (bottom right): the skill tree (SkillTreeWindow); the day, the player level and the
##   EXP at the top left.
##   "Dungeons" (bottom right): the dungeon board; "Betreten" starts the run at once, as the
##   character of the weapon on the hero (MetaState.run_character), no choice window.
## First visit (MetaState.tutorial_done false): Egon shows everything himself: he pulls the lever,
## his gifts (data/shop.json tutorial) shine, he buys them, they land in the inventory, he puts
## them on the hero, then he sends you off: the dungeon board opens and cannot be closed.
## Egon's potion show (MetaState.potion_tour_due: after the second death in the dungeon): he is
## worried for a moment, turns the table once (only a potion on it), gives the potion away, it
## flies into the inventory and from there into the potion place under the hero. From then on
## potions can come on the table (ShopGoods.roll).
## Egon's ruby (MetaState.ruby_due: after climbing out at the rope of the first boss): the ruby
## shines in the inventory and flies over to Egon (MetaState.deliver_ruby); without one he asks
## for it again (until one comes home).
## Containers (data/containers.json) lie in the stash: a click opens one (ContainerWindow above
## the stash); drag a piece onto a container or one of its places = put it in, a place into the
## stash = take one out (MetaState.container_put / container_take).
## P (only in debug builds, started from the editor): the admin menu of the shop (ShopAdminMenu).
## All rules live in MetaState / ShopGoods; this screen only shows them and plays the animations.

const MERCHANT: Texture2D = preload("res://assets/sprites/npcs/black_market_dealer.png")
const LEVER_UP: Texture2D = preload("res://assets/sprites/fortress/lever_up.png")
const LEVER_DOWN: Texture2D = preload("res://assets/sprites/fortress/lever_down.png")
const COIN: Texture2D = preload("res://assets/ui/icon_coin.png")
const BOX_ICON: String = "res://assets/sprites/props/chest.png"
const BOX_SAFE := Color(0.45, 0.9, 0.45)
const BOX_DANGER := Color(1.0, 0.4, 0.35)
const CAVE_SHADE := Color(0.45, 0.4, 0.4)
const GOLD_COLOR := Color(1, 0.86, 0.35)
const SCREEN := Vector2(640, 360)
const TABLE_CELL: float = 20.0
const STASH_CELL: float = 26.0
## Room for the bag and its backpacks in the Inventar tab (the cells shrink to fit).
const BAG_ROOM := Vector2(212, 140)
## Where the things right of the wide left column start.
const MIDDLE_X: float = 244.0
const BUTTON_Y: float = 334.0
const MERCHANT_SCALE: float = 3.0
const FADE_TIME: float = 0.5
const FLY_TIME: float = 0.45
const FLIP_TIME: float = 0.18

var _frame: Control
var _table_panel: PanelContainer
var _table_board: ItemBoard
var _stash_panel: PanelContainer
var _stash_board: ItemBoard
## Pieces of the stash without room in the grid ("Kein Platz"), as single places.
var _overflow: HFlowContainer
var _overflow_slots: Dictionary[int, ShopSlot] = {}
var _hero: HeroPanel
## An open container of the stash (click on it; ContainerWindow).
var _container_window: ContainerWindow
## Left: the tabs Ausrüstung / Inventar.
var _equipment_tab: Button
var _inventory_tab_button: Button
var _inventory_tab: PanelContainer
## The Tausch tab: loot against containers, backpacks … (TradePanel, data/trades.json).
var _trade_tab_button: Button
var _trade_panel: TradePanel
var _backpack_board: BackpackBoard
## "Rucksäcke 1/2" over the bag: attached / allowed (MetaState.backpack_limit).
var _backpack_count: Label
## The safe place of the bag at home (an ItemBoard in its own coordinates, Bag.SAFE_ORIGIN).
var _safe_board: ItemBoard
var _lever: TextureButton
var _lever_price: Label
var _chance_bar: ChanceBar
## Pulsing gold frames around what Egon explains (tour).
var _spotlights: Array[Control] = []
var _spot_tween: Tween
var _gold_row: Control
var _box_panel: Control
var _quest_panel: Control
var _quest_slot: ShopSlot
var _quest_label: Label
var _quest_window: QuestWindow
var _quests_button: Button
var _cave: TextureRect
var _location: Label
var _gold: Label
var _day: Label
var _dialog: DialogBox
var _merchant: TextureRect
var _menu_button: Button
var _dungeons_button: Button
var _board: DungeonBoard
var _skills_button: Button
var _box_slot: ShopSlot
var _box_label: Label
var _box_warning: Label
var _skill_window: SkillTreeWindow
var _black: ColorRect
## true while Egon does something by himself (tutorial, lever): clicks are ignored.
var _locked: bool = false
var _rng := RandomNumberGenerator.new()
## Under the stash: sorts it (T), right click changes how.
var _sort_button: Button
## Buying back: one place per remembered sale (MetaState.sold_today).
var _buy_back_slots: Array[ShopSlot] = []
## The set buttons under the hero (shown with the hero).
var _gear_sets: HBoxContainer
## Readiness check before a run: warned once for this visit (the second click goes).
var _ready_warned: bool = false
## Egon at his place (quests.json locations "egon"): where his picture stands, his gimmick
## (shiver, sweat, mosquitoes, sneeze) and its timer and little helpers (mosquitoes, drops).
var _merchant_base: Vector2 = Vector2.ZERO
var _gimmick: String = ""
var _gimmick_wait: float = 3.0
var _gimmick_time: float = 0.0
var _gimmick_bits: Array[ColorRect] = []
## Chance that a lever pull brings a line of Egon's place instead of the usual one.
const PLACE_LINE_CHANCE: float = 0.35
const CHATTER := {"wave": "square", "freq": 900, "slide": 1.0, "length": 0.03, "noise": 0.4, "vibrato": 0, "repeat": 6, "gap": 0.04}
const SLAP := {"wave": "noise", "freq": 1200, "slide": 0.5, "length": 0.06, "noise": 1.0, "vibrato": 0}
const SNEEZE := {"wave": "noise", "freq": 2200, "slide": 0.4, "length": 0.3, "noise": 0.9, "vibrato": 0.2}
## P (only in debug builds): the admin menu for testing (ShopAdminMenu), null otherwise.
var admin_menu: ShopAdminMenu = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_build()
	_refresh()
	if OS.is_debug_build():
		admin_menu = ShopAdminMenu.new()
		admin_menu.name = "ShopAdminMenu"
		add_child(admin_menu)
		admin_menu.setup(self)
	AudioManager.play_music("title")
	create_tween().tween_property(_black, "modulate:a", 0.0, FADE_TIME)
	if not MetaState.tutorial_done():
		_run_tutorial()
	elif MetaState.ruby_due():
		_run_ruby()
	elif MetaState.potion_tour_due():
		_run_potion_tour()
	elif not MetaState.broken_relic().is_empty():
		_bark("relic_broken")
		MetaState.clear_broken_relic()
	elif not _new_quest().is_empty():
		_announce_quest(_new_quest())


# --- Building ---------------------------------------------------------------------

func _build() -> void:
	var cave := TextureRect.new()
	_cave = cave
	cave.texture = _location_background()
	cave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cave.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cave.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cave.modulate = CAVE_SHADE
	cave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cave)
	# Everything else on a 640x360 frame in the middle (wider windows only show more cave).
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -SCREEN.x / 2.0
	_frame.offset_top = -SCREEN.y / 2.0
	_frame.offset_right = SCREEN.x / 2.0
	_frame.offset_bottom = SCREEN.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	var merchant := TextureRect.new()
	merchant.texture = MERCHANT
	merchant.size = MERCHANT.get_size()
	merchant.scale = Vector2.ONE * MERCHANT_SCALE
	merchant.position = Vector2(500, 84)
	merchant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(merchant)
	_merchant = merchant
	_merchant_base = merchant.position
	_apply_place_look()

	_day = _label("", 14, Color.WHITE)
	_day.position = Vector2(10, 6)
	_frame.add_child(_day)
	var gold_row := HBoxContainer.new()
	gold_row.position = Vector2(10, 24)
	gold_row.add_theme_constant_override("separation", 3)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gold_row.add_child(coin)
	_gold = _label("", 14, GOLD_COLOR)
	gold_row.add_child(_gold)
	_frame.add_child(gold_row)
	_gold_row = gold_row
	_location = _label("", 10, Color(0.8, 0.75, 0.7))
	_location.name = "Location"
	gold_row.add_child(_location)

	_hero = HeroPanel.new()
	_hero.position = Vector2(50, 66)
	_hero.slot_clicked.connect(_on_hero_slot_clicked)
	_hero.drag_for = _hero_drag
	_hero.judge_for = _hero_judge
	_hero.drop_for = _hero_drop
	_frame.add_child(_hero)
	_build_gear_sets()
	_build_tabs()

	_table_panel = _panel(Vector2(MIDDLE_X, 10))
	_table_board = ItemBoard.new()
	_table_board.name = "TableBoard"
	_table_board.cell_px = TABLE_CELL
	_table_board.show_price = true
	_table_board.drag_from = "table"
	_table_board.accepts = func(data: Dictionary) -> bool: return String(data.get("from", "")) in ["stash", "bag"]
	_table_board.judge = _table_judge
	_table_board.dropped.connect(_on_table_dropped)
	_table_board.clicked.connect(_on_table_clicked)
	_table_panel.add_child(_table_board)

	_lever = TextureButton.new()
	_lever.name = "Lever"
	_lever.texture_normal = LEVER_UP
	_lever.texture_pressed = LEVER_DOWN
	_lever.ignore_texture_size = true
	_lever.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_lever.size = LEVER_UP.get_size() * 2.0
	_lever.position = Vector2(436, 30)
	_lever.focus_mode = Control.FOCUS_NONE
	_lever.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_lever.pressed.connect(_on_lever_pressed)
	_frame.add_child(_lever)
	_lever_price = _label("", 12, GOLD_COLOR)
	_lever_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lever_price.position = Vector2(418, 114)
	_lever_price.size = Vector2(88, 16)
	_frame.add_child(_lever_price)
	_chance_bar = ChanceBar.new()
	_chance_bar.name = "ChanceBar"
	_chance_bar.position = Vector2(420, 8)
	_chance_bar.size = Vector2(82, 20)
	_frame.add_child(_chance_bar)
	_build_quest_place()
	_build_money_box()

	_build_stash()

	_dialog = DialogBox.new()
	_dialog.position = Vector2(MIDDLE_X, 134)
	_dialog.custom_minimum_size = Vector2(256, 72)
	_dialog.size = Vector2(256, 72)
	_frame.add_child(_dialog)
	_dialog.hide()
	_container_window = ContainerWindow.new()
	_container_window.position = Vector2(MIDDLE_X, 112)
	_container_window.changed.connect(_refresh)
	_frame.add_child(_container_window)

	# The buttons along the bottom edge.
	_menu_button = _button(Language.translate("Hauptmenü"), Vector2(8, BUTTON_Y))
	_menu_button.pressed.connect(Game.to_main_menu)
	_dungeons_button = _button(Language.translate("Dungeons"), Vector2(0, BUTTON_Y))
	_dungeons_button.name = "DungeonsButton"
	_dungeons_button.pressed.connect(_open_board)
	_dungeons_button.position.x = SCREEN.x - 8 - _dungeons_button.get_combined_minimum_size().x
	_skills_button = _button(Language.translate("Skills"), Vector2(0, BUTTON_Y))
	_skills_button.name = "SkillsButton"
	_skills_button.pressed.connect(_open_skills)
	_quests_button = _button(Language.translate("Quests"), Vector2(0, BUTTON_Y))
	_quests_button.name = "QuestsButton"
	_quests_button.pressed.connect(_open_quests)

	var windows := CanvasLayer.new()
	add_child(windows)
	_board = DungeonBoard.new()
	_board.hide()
	_board.entered.connect(_on_dungeon_entered)
	windows.add_child(_board)
	_skill_window = SkillTreeWindow.new()
	_skill_window.hide()
	_skill_window.learned.connect(func(_id: String) -> void: _refresh())
	windows.add_child(_skill_window)
	_quest_window = QuestWindow.new()
	_quest_window.hide()
	_quest_window.deliver_requested.connect(func(index: int, from_bag: bool) -> void:
		_quest_window.hide()
		_deliver(index, from_bag))
	windows.add_child(_quest_window)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_black)


## Left above the hero: the tabs Ausrüstung and Inventar; the Inventar tab shows the bag of the
## next run (BackpackBoard) and the safe place.
func _build_tabs() -> void:
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(8, 46)
	tabs.add_theme_constant_override("separation", 2)
	_frame.add_child(tabs)
	_equipment_tab = _tab_button(Language.translate("Ausrüstung"), "equipment")
	tabs.add_child(_equipment_tab)
	_inventory_tab_button = _tab_button(Language.translate("Inventar"), "inventory")
	_inventory_tab_button.name = "InventoryTab"
	tabs.add_child(_inventory_tab_button)
	_trade_tab_button = _tab_button(Language.translate("Tausch"), "trade")
	_trade_tab_button.name = "TradeTab"
	tabs.add_child(_trade_tab_button)
	_trade_panel = TradePanel.new()
	_trade_panel.position = Vector2(8, 66)
	_trade_panel.trade_requested.connect(_on_trade_requested)
	_frame.add_child(_trade_panel)
	_inventory_tab = _panel(Vector2(8, 66))
	_inventory_tab.name = "InventoryPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_inventory_tab.add_child(column)
	var title := _label(Language.translate("Inventar: das nimmst du mit in den Dungeon"), 10, Color(1, 0.86, 0.55))
	title.add_theme_constant_override("outline_size", 0)
	column.add_child(title)
	_backpack_count = _label("", 9, BOX_SAFE)
	_backpack_count.name = "BackpackCount"
	_backpack_count.add_theme_constant_override("outline_size", 0)
	_backpack_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_backpack_count.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(_backpack_count)
	_backpack_board = BackpackBoard.new()
	_backpack_board.name = "BackpackBoard"
	_backpack_board.cell_px = _bag_cell()
	_backpack_board.changed.connect(_refresh)
	column.add_child(_backpack_board)
	var safe_title := _label(Language.translate("Sicherer Platz: bleibt, wenn du stirbst"), 8, Color(1.0, 0.78, 0.3))
	safe_title.add_theme_constant_override("outline_size", 0)
	column.add_child(safe_title)
	_safe_board = ItemBoard.new()
	_safe_board.name = "SafeBoard"
	_safe_board.cell_px = _bag_cell()
	_safe_board.drag_from = "bag"
	_safe_board.accepts = func(data: Dictionary) -> bool: return not BackpackBoard.dragged_loot(data).is_empty()
	_safe_board.judge = func(data: Dictionary, cell: Vector2i, _rot: bool) -> int:
		return 1 if BackpackBoard.loot_allowed(data, cell + Bag.SAFE_ORIGIN) else 0
	_safe_board.dropped.connect(func(data: Dictionary, cell: Vector2i, _rot: bool) -> void:
		AudioManager.play_sound("pickup" if BackpackBoard.drop_loot(data, cell + Bag.SAFE_ORIGIN) else "denied", 1.2)
		_refresh())
	column.add_child(_safe_board)
	var hint := _label(Language.translate("Beute aus dem Dungeon bleibt hier. Ins Lager ziehen, auf den Tisch ziehen (verkaufen) oder wieder mitnehmen. Rucksäcke aus dem Lager an den Rand ziehen (R dreht)."), 8, Color(0.75, 0.7, 0.65))
	hint.add_theme_constant_override("outline_size", 0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(BAG_ROOM.x, 0)
	column.add_child(hint)
	_show_tab("equipment")


## Cell size of the bag in the Inventar tab: the whole board fits into BAG_ROOM.
func _bag_cell() -> float:
	var area: Vector2i = BagLayout.board_rect().size
	return floorf(minf(BAG_ROOM.x / float(area.x), BAG_ROOM.y / float(area.y)))


func _tab_button(text: String, tab: String) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(_show_tab.bind(tab))
	return button


## "equipment" (the hero), "inventory" (the bag of the next run) or "trade" (Egon's exchange).
func _show_tab(tab: String) -> void:
	_hero.visible = tab == "equipment"
	if _gear_sets:
		_gear_sets.visible = _hero.visible
	_inventory_tab.visible = tab == "inventory"
	_trade_panel.visible = tab == "trade"
	_equipment_tab.set_pressed_no_signal(tab == "equipment")
	_inventory_tab_button.set_pressed_no_signal(tab == "inventory")
	_trade_tab_button.set_pressed_no_signal(tab == "trade")
	if tab == "inventory":
		_refresh_bag()
	elif tab == "trade":
		_trade_panel.refresh()


func get_inventory_tab() -> PanelContainer:
	return _inventory_tab


func get_trade_panel() -> TradePanel:
	return _trade_panel


## Tausch: MetaState.trade; the new piece shines in the stash, Egon is pleased.
func _on_trade_requested(id: String) -> void:
	if _locked or not MetaState.trade(id):
		AudioManager.play_sound("denied")
		return
	AudioManager.play_sound("unlock", 1.1)
	_bark("traded")
	_refresh()
	if Trades.piece_of(Trades.find(id)).is_empty():
		return
	var index: int = MetaState.stash().size() - 1
	_stash_board.set_glow(index, true)
	get_tree().create_timer(1.2, false).timeout.connect(func() -> void:
		if is_instance_valid(_stash_board):
			_stash_board.set_glow(index, false))


func get_backpack_board() -> BackpackBoard:
	return _backpack_board


func _safe_size() -> Vector2i:
	var safe: Array = Content.meta("bag").get("safe", [2, 2])
	return Vector2i(int(safe[0]) + int(Skills.bonus("safe_slots")), int(safe[1]))


## The bag at home in the Inventar tab: the board with backpacks and loot, the safe place.
func _refresh_bag() -> void:
	_backpack_board.refresh()
	var attached: int = MetaState.backpacks().size()
	var limit: int = MetaState.backpack_limit()
	_backpack_count.text = Language.translate("Rucksäcke %d/%d") % [attached, limit]
	_backpack_count.add_theme_color_override("font_color", BOX_SAFE if attached < limit else GOLD_COLOR)
	_backpack_count.tooltip_text = Language.translate("So viele Rucksäcke kannst du anbauen. Mehr mit dem Skill Rucksack-Riemen.")
	var safe_pieces: Array = []
	for place: Dictionary in MetaState.bag_places():
		if int(place["x"]) >= Bag.SAFE_ORIGIN.x:
			var shifted: Dictionary = place.duplicate()
			shifted["x"] = int(place["x"]) - Bag.SAFE_ORIGIN.x
			shifted["y"] = int(place["y"]) - Bag.SAFE_ORIGIN.y
			safe_pieces.append(shifted)
		else:
			safe_pieces.append({})
	_safe_board.show_pieces(safe_pieces, _safe_size())


## Bottom: the stash grid and beside it what has no room ("Kein Platz").
func _build_stash() -> void:
	_stash_panel = _panel(Vector2(MIDDLE_X, 210))
	_stash_panel.name = "StashPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_stash_panel.add_child(row)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	var title := _label(Language.translate("Lager"), 10, Color(1, 0.86, 0.55))
	title.add_theme_constant_override("outline_size", 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_stash_board = ItemBoard.new()
	_stash_board.name = "StashBoard"
	_stash_board.cell_px = STASH_CELL
	_stash_board.drag_from = "stash"
	_stash_board.accepts = _stash_accepts
	_stash_board.judge = _stash_judge
	_stash_board.clicked.connect(_on_inventory_clicked)
	_stash_board.dropped.connect(_on_stash_dropped)
	_stash_board.lock_clicked.connect(_on_lock_clicked)
	_stash_board.show_sell_value = true
	column.add_child(_stash_board)
	_sort_button = Button.new()
	_sort_button.name = "SortButton"
	_sort_button.focus_mode = Control.FOCUS_NONE
	_sort_button.add_theme_font_size_override("font_size", 8)
	_sort_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_sort_button.tooltip_text = Language.translate("Klick: sortieren (T) · Rechtsklick: Sortierung wechseln · Strg+Klick auf ein Teil: sperren")
	_sort_button.pressed.connect(sort_stash)
	_sort_button.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
			MetaState.next_sort_mode()
			_refresh_sort_button())
	column.add_child(_sort_button)
	_refresh_sort_button()
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 2)
	row.add_child(side)
	var none := _label(Language.translate("Kein Platz"), 9, Color(1.0, 0.55, 0.45))
	none.add_theme_constant_override("outline_size", 0)
	none.tooltip_text = Language.translate("Hier liegt, was nicht ins Lager passt. Mach Platz oder verkauf es.")
	none.mouse_filter = Control.MOUSE_FILTER_STOP
	side.add_child(none)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(100, 4 * STASH_CELL - 12)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_overflow = HFlowContainer.new()
	_overflow.custom_minimum_size = Vector2(96, 0)
	_overflow.add_theme_constant_override("h_separation", 3)
	_overflow.add_theme_constant_override("v_separation", 3)
	scroll.add_child(_overflow)


func get_stash_board() -> ItemBoard:
	return _stash_board


func get_table_board() -> ItemBoard:
	return _table_board


func get_container_window() -> ContainerWindow:
	return _container_window


## The stash takes pieces of the stash (also from "Kein Platz"), goods from the table (buy),
## what the hero wears (take off) and attached backpacks.
func _stash_accepts(data: Dictionary) -> bool:
	return String(data.get("from", "")) in ["stash", "table", "hero", "bag", "container"] or data.has("backpack")


## 1 = fits, 2 = swaps with one other piece, 0 = no.
func _stash_judge(data: Dictionary, cell: Vector2i, rot: bool) -> int:
	var own: Array[Dictionary] = MetaState.stash()
	var grid: Vector2i = MetaState.stash_grid()
	if data.has("backpack"):
		var piece: Dictionary = {"id": String(data["backpack"]), "backpack": true}
		return 1 if ItemGrid.fits(own, grid, piece, cell, rot) else 0
	if String(data.get("from", "")) == "table":
		var price: int = int((data["piece"] as Dictionary).get("price", 0))
		return 1 if price <= MetaState.box() and ItemGrid.fits(own, grid, data["piece"], cell, rot) else 0
	if String(data.get("from", "")) in ["hero", "container"]:
		return 1 if ItemGrid.fits(own, grid, data["piece"], cell, rot) else 0
	if String(data.get("from", "")) == "bag":
		var single: Dictionary = (data["piece"] as Dictionary).duplicate()
		for key: String in ["x", "y", "rot"]:
			single.erase(key)
		single["count"] = 1
		return 1 if ItemGrid.fits(own, grid, single, cell, rot) else 0
	var index: int = int(data.get("index", -1))
	if index < 0 or index >= own.size():
		return 0
	# Onto a container that takes it: in it goes.
	if _container_under(data, cell) >= 0:
		return 1
	if ItemGrid.fits(own, grid, own[index], cell, rot, [index]):
		return 1
	var under: Array[int] = []
	for c: Vector2i in ItemGrid.cells_of(own[index], cell, rot):
		if not Rect2i(Vector2i.ZERO, grid).has_point(c):
			return 0
		var other: int = ItemGrid.index_at(own, c)
		if other >= 0 and other != index and not under.has(other):
			under.append(other)
	return 2 if under.size() == 1 and ItemGrid.is_placed(own[index]) else 0


func _on_stash_dropped(data: Dictionary, cell: Vector2i, rot: bool) -> void:
	if _locked:
		return
	var done: bool = false
	if data.has("backpack"):
		done = MetaState.detach_backpack(String(data["backpack"]), cell, rot)
	elif String(data.get("from", "")) == "table":
		# Bought by dragging it down into the stash.
		if not MetaState.buy(int(data["index"]), false, cell, rot):
			_bark("too_poor" if int((data["piece"] as Dictionary).get("price", 0)) > MetaState.box() else "no_room")
			AudioManager.play_sound("denied")
			_refresh()
			return
		AudioManager.play_sound("buy")
		_bark("bought")
		_refresh()
		return
	elif String(data.get("from", "")) == "hero":
		done = MetaState.unequip(String(data["slot"]), cell, rot)
	elif String(data.get("from", "")) == "bag":
		done = MetaState.bag_to_stash(int(data["index"]), cell, rot)
	elif String(data.get("from", "")) == "container":
		done = MetaState.container_take(int(data["uid"]), int(data["index"]), cell, rot)
	elif _container_under(data, cell) >= 0:
		done = MetaState.container_put(_container_under(data, cell), int(data["index"]))
	else:
		done = MetaState.move_in_stash(int(data["index"]), cell, rot)
	AudioManager.play_sound("pickup" if done else "denied", 1.2)
	_refresh()


## The uid of the container under the mouse when stash piece `data` is dropped with its top left
## on `cell`, if it takes the piece (MetaState.container_fits); -1 otherwise.
func _container_under(data: Dictionary, cell: Vector2i) -> int:
	if String(data.get("from", "")) != "stash":
		return -1
	var own: Array[Dictionary] = MetaState.stash()
	var target: int = ItemGrid.index_at(own, cell + (data.get("grab", Vector2i.ZERO) as Vector2i))
	var index: int = int(data.get("index", -1))
	if target < 0 or target == index or not ShopGoods.is_container(own[target]):
		return -1
	var uid: int = int(own[target].get("uid", 0))
	return uid if MetaState.container_fits(uid, index) else -1


## R or the right mouse button while dragging turns the dragged piece or backpack.
func _input(event: InputEvent) -> void:
	if BagBoard.is_turn_event(event) and BagBoard.rotate_drag(get_viewport()):
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == SORT_KEY and not get_viewport().gui_is_dragging() and not _board.visible:
		get_viewport().set_input_as_handled()
		sort_stash()


# --- Equipment sets (under the hero: click = put on, right click = save) -----------------

func _build_gear_sets() -> void:
	var row := HBoxContainer.new()
	row.name = "GearSets"
	row.add_theme_constant_override("separation", 2)
	_frame.add_child(row)
	_gear_sets = row
	# Right under the hero, once the hero panel has its size.
	(func() -> void: row.position = _hero.position + Vector2(0, _hero.size.y + 3)).call_deferred()
	for number in range(1, MetaState.GEAR_SETS + 1):
		var button := Button.new()
		button.name = "Set%d" % number
		button.text = Language.translate("Set %d") % number
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 8)
		button.tooltip_text = Language.translate("Klick: dieses Set anlegen · Rechtsklick: Getragenes als Set speichern")
		button.pressed.connect(wear_gear_set.bind(number))
		button.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
				save_gear_set(number))
		row.add_child(button)


func wear_gear_set(number: int) -> void:
	if _locked:
		return
	if MetaState.gear_set(number).is_empty():
		AudioManager.play_sound("denied")
		_dialog.bark(Language.translate("Set %d ist leer. Rechtsklick speichert, was du trägst.") % number)
		return
	var changed: int = MetaState.wear_gear_set(number)
	AudioManager.play_sound("item" if changed > 0 else "denied")
	_refresh()


func save_gear_set(number: int) -> void:
	if _locked:
		return
	MetaState.save_gear_set(number)
	AudioManager.play_sound("unlock", 1.2)
	_dialog.bark(Language.translate("Set %d gespeichert.") % number)


# --- Stash comfort: sort (T), lock (Strg+Klick) ----------------------------------------

const SORT_KEY: Key = KEY_T


## Packs the stash (MetaState.sort_stash), with a little sound.
func sort_stash() -> void:
	if _locked:
		return
	MetaState.sort_stash()
	AudioManager.play_sound("pickup", 1.1)
	_refresh()


func _refresh_sort_button() -> void:
	var mode: String = Language.translate("Art")
	match MetaState.sort_mode():
		"rarity":
			mode = Language.translate("Seltenheit")
		"value":
			mode = Language.translate("Wert")
	_sort_button.text = Language.translate("Sortieren: %s") % mode


func _on_lock_clicked(index: int) -> void:
	if _locked:
		return
	var locked: bool = MetaState.toggle_lock(index)
	AudioManager.play_sound("unlock", 1.3 if locked else 0.9)
	_refresh()


## P: the admin menu (debug builds only).
func _unhandled_input(event: InputEvent) -> void:
	if admin_menu != null and not admin_menu.visible and event.is_action_pressed(Controls.TEST_ROOM):
		get_viewport().set_input_as_handled()
		admin_menu.open()


## After a change from the admin menu: background, table, stash, hero, everything new.
func refresh_all() -> void:
	_cave.texture = _location_background()
	_refresh()


func _panel(at: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HudPanel"
	panel.position = at
	_frame.add_child(panel)
	return panel


func _button(text: String, at: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.position = at
	_frame.add_child(button)
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# --- Showing ----------------------------------------------------------------------

func _refresh() -> void:
	var to_next: int = Skills.exp_to_next(MetaState.level())
	var exp_text: String = "" if to_next == 0 else " (%d/%d EXP)" % [MetaState.exp_points(), to_next]
	_day.text = Language.translate("Tag %d") % MetaState.day() + " · " + Language.translate("Stufe %d") % MetaState.level() + exp_text
	# "Skills (2)" while skill points wait; it stays left of "Dungeons".
	var points: int = MetaState.skill_points()
	_skills_button.text = Language.translate("Skills") + (" (%d)" % points if points > 0 else "")
	_skills_button.reset_size()
	_skills_button.position.x = _dungeons_button.position.x - 6 - _skills_button.get_combined_minimum_size().x
	_refresh_quest_place()
	_refresh_buy_back()
	_quests_button.reset_size()
	_quests_button.position.x = _skills_button.position.x - 6 - _quests_button.get_combined_minimum_size().x
	_gold.text = str(MetaState.box())
	var price: int = MetaState.lever_price()
	_lever_price.text = Language.translate("Gratis") if price == 0 else Language.translate("%d Gold") % price
	var laid: Array = table_layout(MetaState.table())
	_table_board.gold_limit = MetaState.box()
	_table_board.better = better_pieces(laid)
	_table_board.show_pieces(laid, table_grid())
	_refresh_inventory()
	if _inventory_tab.visible:
		_refresh_bag()
	if _trade_panel.visible:
		_trade_panel.refresh()
	_hero.refresh()
	_chance_bar.refresh()


## Width × height of the table grid (shop.json table_grid).
static func table_grid() -> Vector2i:
	var cells: Array = Content.shop().get("table_grid", [8, 4])
	return Vector2i(int(cells[0]), int(cells[1]))


## Egon's table as it lies on the grid: the goods in table order on the first free cells
## (every place index stays the same; empty places and goods without room are not drawn).
static func table_layout(table: Array[Dictionary]) -> Array:
	var laid: Array = []
	for piece: Dictionary in table:
		laid.append(piece.duplicate())
	var grid: Vector2i = table_grid()
	for i in laid.size():
		var piece: Dictionary = laid[i]
		if piece.is_empty():
			continue
		var others: Array[int] = []
		for j in range(i, laid.size()):
			others.append(j)
		var spot: Dictionary = ItemGrid.free_spot(laid, grid, piece, others)
		if not spot.is_empty():
			piece.merge(spot, true)
	return laid


func _refresh_inventory() -> void:
	var own: Array[Dictionary] = MetaState.stash()
	_stash_board.show_pieces(own, MetaState.stash_grid())
	for child: Node in _overflow.get_children():
		child.queue_free()
	_overflow_slots.clear()
	for i in own.size():
		if ItemGrid.is_placed(own[i]):
			continue
		var place := ShopSlot.new()
		place.show_entry(own[i])
		place.clicked.connect(_on_inventory_clicked.bind(i))
		var piece: Dictionary = own[i]
		var index: int = i
		place.set_drag_forwarding(func(_at: Vector2) -> Variant:
			return ItemBoard.make_drag(place, "stash", index, piece, false, Vector2i.ZERO, STASH_CELL), Callable(), Callable())
		_overflow.add_child(place)
		_overflow_slots[i] = place
	if _container_window.visible:
		_container_window.refresh()
	_refresh_quest_place()
	_refresh_money_box()


## Where stash place `index` is on screen (in the grid, under "Kein Platz", else the stash).
func _stash_rect(index: int) -> Rect2:
	var rect: Rect2 = _stash_board.rect_of(index)
	if rect.has_area():
		return rect
	if _overflow_slots.has(index):
		return _rect(_overflow_slots[index])
	return _rect(_stash_panel)


static func _rect(control: Control) -> Rect2:
	return Rect2(control.global_position, control.size * control.get_global_transform().get_scale())


# --- Selling: drag onto the table ----------------------------------------------------

## A stash piece over the table: green when Egon buys it (not the quest stones), else red.
func _table_judge(data: Dictionary, _cell: Vector2i, _rot: bool) -> int:
	if String(data.get("from", "")) == "bag":
		var id: String = String((data["piece"] as Dictionary).get("id", ""))
		return 0 if Quests.is_stone(id) or id == Bag.GOLD else 1
	var own: Array[Dictionary] = MetaState.stash()
	var index: int = int(data.get("index", -1))
	if index < 0 or index >= own.size() or Quests.is_stone(String(own[index].get("id", ""))):
		return 0
	return 1 if ShopGoods.sell_price(own[index]) > 0 else 0


func _on_table_dropped(data: Dictionary, _cell: Vector2i, _rot: bool) -> void:
	if _locked or not String(data.get("from", "")) in ["stash", "bag"]:
		return
	var gold: int = MetaState.sell_from_bag(int(data["index"])) if String(data["from"]) == "bag" else MetaState.sell(int(data["index"]))
	if gold <= 0:
		AudioManager.play_sound("denied")
		_bark("not_for_sale")
		return
	AudioManager.play_sound("coin")
	_bark("sold")
	_refresh()


# --- The hero: drag and drop ----------------------------------------------------------

## Drag data of what is worn on `slot` (null when nothing).
func _hero_drag(place: ShopSlot, slot: String) -> Variant:
	if _locked:
		return null
	var worn: Dictionary = MetaState.equipment().get(slot, {})
	if worn.is_empty():
		return null
	var piece: Dictionary = worn.duplicate()
	piece["count"] = 1
	var data: Dictionary = ItemBoard.make_drag(place, "hero", -1, piece, false, Vector2i.ZERO, STASH_CELL)
	data["slot"] = slot
	return data


## 1 = a stash piece that goes on `slot`, 2 = a stash piece that does not, 0 = no stash piece.
func _hero_judge(slot: String, data: Variant) -> int:
	if not data is Dictionary or String((data as Dictionary).get("from", "")) != "stash":
		return 0
	var own: Array[Dictionary] = MetaState.stash()
	var index: int = int((data as Dictionary).get("index", -1))
	if index < 0 or index >= own.size():
		return 2
	return 1 if _fits_slot(own[index], slot) else 2


## true if `piece` can be worn on `slot` (relics on relic places, potions on potion places).
func _fits_slot(piece: Dictionary, slot: String) -> bool:
	if ShopGoods.is_relic(piece):
		return slot.begins_with("relic_")
	if ShopGoods.is_potion(piece):
		return slot.begins_with("potion_") and MetaState.potions_unlocked()
	return not MetaState.slot_of(piece).is_empty() and MetaState.slot_of(piece) == slot


func _hero_drop(slot: String, data: Variant) -> void:
	if _locked or _hero_judge(slot, data) != 1:
		AudioManager.play_sound("denied")
		return
	if MetaState.equip(int((data as Dictionary)["index"]), slot):
		AudioManager.play_sound("item")
		var place: ShopSlot = _hero.get_slot(slot)
		_refresh()
		if place:
			place.pop()


# --- Egon's quests (quest place top right, QuestWindow) ---------------------------------

## The quest place: the stone of the first open quest shows faintly; drop the stone on it.
func _build_quest_place() -> void:
	var panel := _panel(Vector2(508, 10))
	panel.name = "QuestPanel"
	_quest_panel = panel
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := _label(Language.translate("Quest"), 12, GOLD_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_quest_slot = ShopSlot.new()
	_quest_slot.name = "QuestSlot"
	_quest_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_quest_slot.clicked.connect(_open_quests)
	_quest_slot.set_drag_forwarding(Callable(), _can_drop_on_quest, _drop_on_quest)
	column.add_child(_quest_slot)
	_quest_label = _label("", 9, Color(0.85, 0.8, 0.75))
	_quest_label.add_theme_constant_override("outline_size", 0)
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_label.custom_minimum_size = Vector2(110, 0)
	column.add_child(_quest_label)
	# Buying back: the last sales of today, for the same price.
	var back_title := _label(Language.translate("Zurückkaufen"), 9, GOLD_COLOR)
	back_title.add_theme_constant_override("outline_size", 0)
	back_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_title.tooltip_text = Language.translate("Heute Verkauftes zum gleichen Preis zurückkaufen")
	back_title.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(back_title)
	var back_row := HBoxContainer.new()
	back_row.add_theme_constant_override("separation", 2)
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(back_row)
	for i in MetaState.BUY_BACK_PLACES:
		var slot := ShopSlot.new()
		slot.name = "BuyBack%d" % i
		slot.show_price = true
		slot.clicked.connect(buy_back.bind(i))
		back_row.add_child(slot)
		_buy_back_slots.append(slot)


## Buys back the sale on place `index` (MetaState.buy_back): Egon is a little sorry.
func buy_back(index: int) -> void:
	if _locked:
		return
	if MetaState.buy_back(index):
		AudioManager.play_sound("buy")
		_dialog.bark(String((Content.story("barks") as Dictionary).get("bought_back", "")))
	else:
		AudioManager.play_sound("denied")
		if index < MetaState.sold_today().size():
			_bark("too_poor")
	_refresh()


func _refresh_buy_back() -> void:
	var sold: Array[Dictionary] = MetaState.sold_today()
	for i in _buy_back_slots.size():
		var slot: ShopSlot = _buy_back_slots[i]
		if i < sold.size():
			var piece: Dictionary = (sold[i]["piece"] as Dictionary).duplicate()
			piece["price"] = int(sold[i].get("gold", 0))
			slot.show_entry(piece)
			slot.tooltip_text = ShopSlot.describe(piece, true)
		else:
			slot.show_entry({})
			slot.tooltip_text = ""


func _refresh_quest_place() -> void:
	var open: Array[String] = Quests.open_quests()
	var stone: String = String(Quests.data(open[0]).get("item", "")) if not open.is_empty() else ""
	_quest_slot.show_entry({})
	_quest_slot.hint = ShopSlot.icon_of(stone) if not stone.is_empty() else null
	_quest_slot.hint_name = Language.translate("Den Quest-Stein hierher ziehen") if not stone.is_empty() else Language.translate("Egon hat gerade keinen Auftrag.")
	_quest_slot.show_entry({})
	_quest_label.text = Language.translate(String(Quests.data(open[0]).get("name", ""))) if not open.is_empty() else Language.translate("Keine Quest")
	var ready_now: bool = Quests.deliverable_index() >= 0 or Quests.stone_in_bag() >= 0
	_quest_slot.set_glow(ready_now)
	_quests_button.text = Language.translate("Quests") + (" !" if ready_now else "")
	_location.text = "  " + Language.translate(String(Quests.location_data(MetaState.location()).get("name", "")))


func _can_drop_on_quest(_at: Vector2, data: Variant) -> bool:
	if data is Dictionary and String((data as Dictionary).get("from", "")) == "bag":
		var stone: String = String(((data as Dictionary).get("piece", {}) as Dictionary).get("id", ""))
		_quest_slot.set_drop_hint(1 if not Quests.quest_of_stone(stone).is_empty() else 2)
		return true
	if not data is Dictionary or String((data as Dictionary).get("from", "")) != "stash":
		return false
	var own: Array[Dictionary] = MetaState.stash()
	var index: int = int((data as Dictionary).get("index", -1))
	var ok: bool = index >= 0 and index < own.size() and not Quests.quest_of_stone(String(own[index].get("id", ""))).is_empty()
	_quest_slot.set_drop_hint(1 if ok else 2)
	return true


func _drop_on_quest(_at: Vector2, data: Variant) -> void:
	_quest_slot.set_drop_hint(0)
	_deliver(int((data as Dictionary).get("index", -1)), String((data as Dictionary).get("from", "stash")) == "bag")


func get_quest_slot() -> ShopSlot:
	return _quest_slot


func get_quest_window() -> QuestWindow:
	return _quest_window


func _open_quests() -> void:
	if _locked:
		return
	_board.hide()
	_skill_window.hide()
	_quest_window.open()


## The first open quest Egon has not told about yet ("" = none).
func _new_quest() -> String:
	if not MetaState.tutorial_done():
		return ""
	for id: String in Quests.open_quests():
		if not MetaState.quest_announced(id):
			return id
	return ""


## Egon tells about quest `id` once (one line, the shop stays usable; the quest place shines).
func _announce_quest(id: String) -> void:
	MetaState.announce_quest(id)
	var lines: Variant = Content.story("quest_%s_intro" % id)
	_dialog.bark(String((lines as Array)[0]) if lines is Array and not (lines as Array).is_empty() else "")
	_quest_slot.set_glow(true)


## Hands in the stone on stash place `index`: it flies to Egon, he talks, pays and moves on
## (the screen goes dark, the new place shows). Nothing happens for anything else.
func _deliver(index: int, from_bag: bool = false) -> void:
	var own: Array[Dictionary] = MetaState.bag_places() if from_bag else MetaState.stash()
	if _locked or index < 0 or index >= own.size() or Quests.quest_of_stone(String(own[index].get("id", ""))).is_empty():
		AudioManager.play_sound("denied")
		return
	_locked = true
	var icon: Texture2D = ShopSlot.icon_of_piece(own[index])
	var from: Vector2 = _rect(_inventory_tab).get_center() if from_bag else _stash_rect(index).position
	var before: String = MetaState.location()
	var id: String = MetaState.deliver_quest_from_bag(index) if from_bag else MetaState.deliver_quest(index)
	_refresh()
	await _fly_to_egon(icon, from)
	if not is_inside_tree():
		return
	AudioManager.play_sound("unlock")
	if not await _say("quest_%s_done" % id):
		return
	_dialog.hide()
	if MetaState.location() != before:
		await _move_shop()
		if not is_inside_tree():
			return
	_locked = false
	_refresh()


## Egon moves on: dark, the new background, light again.
func _move_shop() -> void:
	var fade := create_tween()
	fade.tween_property(_black, "modulate:a", 1.0, FADE_TIME)
	await fade.finished
	_cave.texture = _location_background()
	_apply_place_look()
	_refresh()
	AudioManager.play_sound("door")
	fade = create_tween()
	fade.tween_property(_black, "modulate:a", 0.0, FADE_TIME)
	await fade.finished
	# Arrived: Egon says something about his new place.
	var arrive: String = _place_line("arrive")
	if not arrive.is_empty():
		_dialog.bark(arrive)


## Indices of table pieces that are better than what the hero wears (green arrow).
static func better_pieces(laid: Array) -> Array[int]:
	var worn: Dictionary = MetaState.equipment()
	var character: String = MetaState.run_character()
	var result: Array[int] = []
	for i in laid.size():
		if laid[i] is Dictionary and not (laid[i] as Dictionary).is_empty() and ShopGoods.better_than_worn(laid[i], worn, character):
			result.append(i)
	return result


## What is missing before a run ("" = all fine): an empty potion place (once potions are open),
## a relic with only one run left, an almost full inventory. One line, Egon's words.
func readiness_warning() -> String:
	var parts: PackedStringArray = []
	if MetaState.potions_unlocked() and MetaState.worn_potions().is_empty():
		parts.append(Language.translate("dein Trank-Platz ist leer"))
	var worn: Dictionary = MetaState.equipment()
	for slot: String in MetaState.relic_slot_names():
		if worn.has(slot) and int((worn[slot] as Dictionary).get("left", -1)) == 1:
			parts.append(Language.translate("dein Relikt hält nur noch einen Run"))
			break
	var bag: Bag = MetaState._bag_model()
	var cells: int = bag.section_cells(Bag.MAIN).size()
	var used: int = 0
	for place: Dictionary in MetaState.bag_places():
		var span: Vector2i = BagLayout.loot_size(String(place.get("id", ""))) if not Bag.is_piece(place) else ShopGoods.piece_size(place)
		used += span.x * span.y
	if cells > 0 and float(used) / cells >= READY_FULL:
		parts.append(Language.translate("dein Inventar ist fast voll"))
	if parts.is_empty():
		return ""
	return Language.translate("Moment, Partner: %s. Nochmal klicken, dann geht's los.") % ", ".join(parts)


## Inventory this full (share of cells) counts as almost full.
const READY_FULL: float = 0.8


## The picture behind the shop at Egon's place (data/quests.json locations).
static func _location_background() -> Texture2D:
	var path: String = String(Quests.location_data(MetaState.location()).get("background", ""))
	if not ResourceLoader.exists(path):
		path = String(Quests.location_data(Quests.start()).get("background", ""))
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


# --- The money box (Dose) ------------------------------------------------------------

func _build_money_box() -> void:
	var panel := _panel(Vector2(500, 226))
	_box_panel = panel
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	_box_label = _label("", 12, BOX_SAFE)
	_box_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_box_label)
	_box_slot = ShopSlot.new()
	_box_slot.name = "MoneyBox"
	var icon: Texture2D = load(BOX_ICON) as Texture2D
	_box_slot.hint = icon
	_box_slot.hint_alpha = 1.0
	_box_slot.hint_name = Language.translate("Dose: hier liegt dein ganzes Gold")
	_box_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_box_slot)
	_box_warning = _label(Language.translate("Egon könnte klauen!"), 9, BOX_DANGER)
	_box_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box_warning.tooltip_text = Language.translate("Über dem Limit: Egon schielt auf deine Dose!")
	_box_warning.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(_box_warning)


## "120/200" over the box: green up to the limit, red above it (with Egon's warning).
func _refresh_money_box() -> void:
	var gold: int = MetaState.box()
	var limit: int = MetaState.box_limit()
	_box_label.text = "%s %d/%d" % [Language.translate("Dose"), gold, limit]
	var over: bool = gold > limit
	_box_label.add_theme_color_override("font_color", BOX_DANGER if over else BOX_SAFE)
	_box_warning.visible = over
	# Always the can; how much is in it stands above.
	_box_slot.show_entry({})
	_box_slot.tooltip_text = Language.translate("Dose: %d Gold. Bis %d ist es sicher.") % [gold, limit]


func get_money_box() -> ShopSlot:
	return _box_slot


func _bark(key: String) -> void:
	_dialog.bark(String((Content.story("barks") as Dictionary).get(key, "")))


# --- Player actions -----------------------------------------------------------------

func _on_lever_pressed() -> void:
	if _locked:
		return
	if not await _pull_lever():
		_bark("too_poor")
		AudioManager.play_sound("denied")
		return
	var line: String = _place_line("lever")
	if not line.is_empty() and _rng.randf() < PLACE_LINE_CHANCE:
		_dialog.bark(line)
	else:
		_bark("rolled")


# --- Egon at his place (quests.json locations "egon", story.json place_lines) -------------

## A line of story.json place_lines for Egon's place: "arrive" or a random "lever_N"; "" = none.
func _place_line(kind: String) -> String:
	var lines: Dictionary = Content.story("place_lines") if Content.story("place_lines") is Dictionary else {}
	var place: String = MetaState.location()
	if kind == "arrive":
		return String(lines.get("%s_arrive" % place, ""))
	var choices: Array[String] = []
	for key: String in lines:
		if key.begins_with("%s_lever_" % place):
			choices.append(String(lines[key]))
	return "" if choices.is_empty() else choices[_rng.randi_range(0, choices.size() - 1)]


## Egon's look at this place: a colour and a gimmick (shiver, sweat, mosquitoes, sneeze).
func _apply_place_look() -> void:
	var look: Dictionary = Quests.location_data(MetaState.location()).get("egon", {})
	var tint: Array = look.get("tint", [1, 1, 1])
	_merchant.modulate = Color(float(tint[0]), float(tint[1]), float(tint[2]))
	_merchant.position = _merchant_base
	_gimmick = String(look.get("gimmick", ""))
	_gimmick_wait = _rng.randf_range(2.0, 4.0)
	for bit: ColorRect in _gimmick_bits:
		bit.queue_free()
	_gimmick_bits.clear()
	if _gimmick == "mosquitoes":
		for i in 3:
			var mosquito := ColorRect.new()
			mosquito.color = Color(0.1, 0.1, 0.1)
			mosquito.size = Vector2(2, 2)
			mosquito.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_frame.add_child(mosquito)
			_gimmick_bits.append(mosquito)


## The gimmick moves every frame; now and then it does its thing (with a sound).
func _process(delta: float) -> void:
	if _merchant == null or _gimmick.is_empty():
		return
	_gimmick_time += delta
	_gimmick_wait -= delta
	var head: Vector2 = _merchant_base + Vector2(_merchant.size.x * MERCHANT_SCALE * 0.5, _merchant.size.y * MERCHANT_SCALE * 0.22)
	match _gimmick:
		"shiver":
			_merchant.position = _merchant_base + Vector2(_rng.randf_range(-1.0, 1.0), 0)
			if _gimmick_wait <= 0.0:
				_gimmick_wait = _rng.randf_range(3.0, 6.0)
				AudioManager.play_stream(SoundSynth.make(CHATTER, "cry"), 1.0, -8.0)
		"mosquitoes":
			for i in _gimmick_bits.size():
				var angle: float = _gimmick_time * (3.0 + i) + i * 2.1
				_gimmick_bits[i].position = head + Vector2(cos(angle) * (14 + i * 5), sin(angle * 1.3) * 9)
			if _gimmick_wait <= 0.0:
				_gimmick_wait = _rng.randf_range(4.0, 7.0)
				AudioManager.play_stream(SoundSynth.make(SLAP, "cry"), 1.0, -6.0)
				var slap := create_tween()
				slap.tween_property(_merchant, "position", _merchant_base + Vector2(-3, 0), 0.05)
				slap.tween_property(_merchant, "position", _merchant_base, 0.1)
		"sneeze":
			if _gimmick_wait <= 0.0:
				_gimmick_wait = _rng.randf_range(5.0, 9.0)
				AudioManager.play_stream(SoundSynth.make(SNEEZE, "cry"), 1.0, -6.0)
				var pop := create_tween()
				pop.tween_property(_merchant, "position", _merchant_base + Vector2(0, -6), 0.08)
				pop.tween_property(_merchant, "position", _merchant_base, 0.15)
		"sweat":
			if _gimmick_wait <= 0.0:
				_gimmick_wait = _rng.randf_range(1.0, 1.8)
				var drop := ColorRect.new()
				drop.color = Color(0.6, 0.8, 1.0, 0.9)
				drop.size = Vector2(2, 3)
				drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
				drop.position = head + Vector2(_rng.randf_range(-10, 10), 0)
				_frame.add_child(drop)
				var fall := create_tween()
				fall.tween_property(drop, "position:y", drop.position.y + 24, 0.8)
				fall.parallel().tween_property(drop, "modulate:a", 0.0, 0.8)
				fall.tween_callback(drop.queue_free)


func _on_table_clicked(index: int) -> void:
	var table: Array[Dictionary] = MetaState.table()
	if _locked or index < 0 or index >= table.size() or table[index].is_empty():
		return
	var from: Rect2 = _table_board.rect_of(index)
	var icon: Texture2D = ShopSlot.icon_of_piece(table[index])
	if not MetaState.buy(index):
		_bark("too_poor")
		AudioManager.play_sound("denied")
		return
	AudioManager.play_sound("buy")
	_bark("bought")
	_refresh()
	await _fly(icon, from, _stash_rect(MetaState.stash().size() - 1))


func _on_inventory_clicked(index: int) -> void:
	var own: Array[Dictionary] = MetaState.stash()
	if _locked or index < 0 or index >= own.size():
		return
	# A container: open it (again: close it).
	if ShopGoods.is_container(own[index]):
		var uid: int = int(own[index].get("uid", 0))
		if _container_window.visible and _container_window.uid == uid:
			_container_window.close_box()
		else:
			_container_window.show_box(uid)
		AudioManager.play_sound("pickup", 0.9)
		return
	# A backpack: attach it to the bag (where it fits first), the Inventar tab shows it.
	if ShopGoods.is_backpack(own[index]):
		if MetaState.attach_backpack_anywhere(index):
			AudioManager.play_sound("unlock", 1.2)
			_show_tab("inventory")
		else:
			AudioManager.play_sound("denied")
		_refresh()
		return
	var slot: String = MetaState.slot_of(own[index])
	if slot.is_empty():
		_bark("no_slot")
		AudioManager.play_sound("denied")
		return
	await _equip_animated(index)


func _on_hero_slot_clicked(slot: String) -> void:
	if _locked or not MetaState.unequip(slot):
		return
	_show_tab("equipment")
	AudioManager.play_sound("pickup")
	_refresh()


# --- Animations ---------------------------------------------------------------------

## The lever goes down, the table flips over and comes back with the new goods. `kind`:
## "" = a normal pull (paid), "tutorial" = Egon's free first pull with his gifts, "potion" = his
## free potion show. false (nothing happens) without enough gold.
func _pull_lever(kind: String = "") -> bool:
	if kind.is_empty() and MetaState.lever_price() > MetaState.box():
		return false
	_locked = true
	_lever.texture_normal = LEVER_DOWN
	AudioManager.play_sound("door")
	var table_panel: Control = _table_panel
	table_panel.pivot_offset = table_panel.size / 2.0
	var flip := create_tween()
	flip.tween_property(table_panel, "scale:y", 0.0, FLIP_TIME).set_ease(Tween.EASE_IN)
	await flip.finished
	if kind == "tutorial":
		MetaState.lay_tutorial_table()
	elif kind == "potion":
		MetaState.lay_potion_table()
	else:
		MetaState.pull_lever(_rng)
	_refresh()
	flip = create_tween()
	flip.tween_property(table_panel, "scale:y", 1.0, FLIP_TIME).set_ease(Tween.EASE_OUT)
	await flip.finished
	_lever.texture_normal = LEVER_UP
	_locked = false
	return true


## Puts stash place `index` on the hero, with the picture flying there.
func _equip_animated(index: int) -> void:
	_show_tab("equipment")
	var own: Array[Dictionary] = MetaState.stash()
	var slot: String = MetaState.slot_of(own[index])
	var from: Rect2 = _stash_rect(index)
	var icon: Texture2D = ShopSlot.icon_of_piece(own[index])
	if not MetaState.equip(index):
		return
	AudioManager.play_sound("item")
	_refresh()
	var target: ShopSlot = _hero.get_slot(slot)
	if target:
		await _fly(icon, from, _rect(target), target)


## A picture flies from one place to another (global rects; refresh first). `target`: a ShopSlot
## that stays hidden until the picture arrives and then jumps.
func _fly(icon: Texture2D, from: Rect2, to: Rect2, target: Control = null) -> void:
	if icon == null or not from.has_area() or not to.has_area():
		return
	if target:
		target.modulate.a = 0.0
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.z_index = 10
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(picture)
	picture.global_position = from.position
	picture.size = from.size
	var fly := create_tween().set_parallel(true)
	fly.tween_property(picture, "global_position", to.position, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(picture, "size", to.size, FLY_TIME)
	await fly.finished
	picture.queue_free()
	if target and is_instance_valid(target):
		target.modulate.a = 1.0
		if target is ShopSlot:
			(target as ShopSlot).pop()


# --- Egon's tour (first visit) ---------------------------------------------------------

func _run_tutorial() -> void:
	_locked = true
	_menu_button.hide()
	_dungeons_button.hide()
	_skills_button.hide()
	_quests_button.hide()
	_show_tab("equipment")
	await get_tree().create_timer(FADE_TIME, false).timeout
	var table_panel: Control = _table_panel
	var inventory_panel: Control = _stash_panel
	if not await _explain("tutorial_welcome", [table_panel]):
		return
	if not await _explain("tutorial_lever", [_lever]):
		return
	_dialog.hide()
	await _pull_lever("tutorial")
	_locked = true
	if not is_inside_tree() or not await _explain("tutorial_goods", [table_panel]):
		return
	if not await _explain("tutorial_chances", [_chance_bar]):
		return
	if not await _explain("tutorial_reroll", [_lever, _lever_price]):
		return
	var gifts: Array = (Content.shop().get("tutorial", {}) as Dictionary).get("gifts", [])
	var gift_cells: Array[int] = []
	var table: Array[Dictionary] = MetaState.table()
	for i in table.size():
		if not table[i].is_empty() and gifts.has(String(table[i]["id"])):
			gift_cells.append(i)
			_table_board.set_glow(i, true)
	if not await _say("tutorial_gifts"):
		return
	# Egon buys them: one after the other into the inventory.
	for cell: int in gift_cells:
		_table_board.set_glow(cell, false)
		var from: Rect2 = _table_board.rect_of(cell)
		var icon: Texture2D = ShopSlot.icon_of_piece(table[cell])
		MetaState.buy(cell, true)
		AudioManager.play_sound("buy")
		_refresh()
		await _fly(icon, from, _stash_rect(_stash_index(String(table[cell]["id"]))))
		if not is_inside_tree():
			return
	if not await _explain("tutorial_bag", [inventory_panel]):
		return
	if not await _explain("tutorial_dress", [_hero]):
		return
	# … and puts them on: every gift from the inventory onto its place.
	for id: Variant in gifts:
		var index: int = _stash_index(String(id))
		if index >= 0:
			await _equip_animated(index)
			if not is_inside_tree():
				return
	if not await _explain("tutorial_equip", [_hero, inventory_panel]):
		return
	# A little start money: it goes into the box.
	MetaState.gift_gold(int((Content.shop().get("tutorial", {}) as Dictionary).get("gold", 0)))
	AudioManager.play_sound("coin")
	_refresh()
	if not await _explain("tutorial_money", [_gold_row]):
		return
	if not await _explain("tutorial_box", [_box_panel]):
		return
	if not await _explain("tutorial_sell", [_table_panel]):
		return
	_skills_button.show()
	_quests_button.show()
	if not await _explain("tutorial_skills", [_skills_button]):
		return
	_dungeons_button.show()
	if not await _explain("tutorial_dungeon", [_dungeons_button]):
		return
	MetaState.finish_tutorial()
	_dialog.hide()
	_locked = false
	_menu_button.show()
	# Off you go: the board opens and stays open.
	_board.open(true)


# --- Egon's potion show (after the second death) ---------------------------------------

func _run_potion_tour() -> void:
	_locked = true
	_menu_button.hide()
	_dungeons_button.hide()
	_skills_button.hide()
	_quests_button.hide()
	_show_tab("equipment")
	await get_tree().create_timer(FADE_TIME, false).timeout
	if not is_inside_tree() or not await _explain("potion_worried", []):
		return
	if not await _explain("potion_lever", [_lever]):
		return
	_dialog.hide()
	await _pull_lever("potion")
	_locked = true
	if not is_inside_tree():
		return
	var cell: int = -1
	var table: Array[Dictionary] = MetaState.table()
	for i in table.size():
		if ShopGoods.is_potion(table[i]):
			cell = i
			_table_board.set_glow(i, true)
	if not await _say("potion_gift"):
		return
	if cell >= 0:
		# Egon buys it for you (free) and it lands in the inventory.
		_table_board.set_glow(cell, false)
		var from: Rect2 = _table_board.rect_of(cell)
		var icon: Texture2D = ShopSlot.icon_of_piece(table[cell])
		MetaState.buy(cell, true)
		MetaState.unlock_potions()
		AudioManager.play_sound("buy")
		_refresh()
		var index: int = _stash_index(String(table[cell]["id"]), true)
		if index >= 0:
			await _fly(icon, from, _stash_rect(index))
	MetaState.unlock_potions()
	_refresh()
	if not is_inside_tree() or not await _explain("potion_slot", [_hero.get_potion_row()]):
		return
	# … and puts it into the potion place under the hero.
	var potion_index: int = _stash_index(String(Content.potions().get("tour_potion", "")), true)
	if potion_index >= 0:
		await _equip_animated(potion_index)
		if not is_inside_tree():
			return
	_spotlight([_hero.get_potion_row()])
	if not await _say("potion_drink", Controls.key_name(Controls.get_key(Controls.POTION))):
		return
	_spotlight([])
	_dialog.hide()
	_locked = false
	_menu_button.show()
	_dungeons_button.show()
	_skills_button.show()
	_quests_button.show()
	_refresh()


# --- Egon's ruby (after the rope of the first boss) -----------------------------------

func _run_ruby() -> void:
	_locked = true
	_menu_button.hide()
	_dungeons_button.hide()
	_skills_button.hide()
	_quests_button.hide()
	await get_tree().create_timer(FADE_TIME, false).timeout
	if not is_inside_tree():
		return
	var index: int = MetaState.ruby_index()
	if index < 0:
		if not await _say("ruby_missing"):
			return
	else:
		_stash_board.set_glow(index, true)
		if not await _say("ruby_found"):
			return
		_stash_board.set_glow(index, false)
		var icon: Texture2D = ShopSlot.icon_of_piece(MetaState.stash()[index])
		var from: Vector2 = _stash_rect(index).position
		MetaState.deliver_ruby()
		_refresh()
		await _fly_to_egon(icon, from)
		if not is_inside_tree() or not await _say("ruby_taken"):
			return
		# His thanks: a relic for a few runs (meta.json ruby_quest reward_relic), it shines in the stash.
		var gift: int = _gift_index(String(MetaState.ruby_reward().get("id", "")))
		if gift >= 0:
			_stash_board.set_glow(gift, true)
			if not await _say("ruby_reward"):
				return
			_stash_board.set_glow(gift, false)
	_dialog.hide()
	_locked = false
	_menu_button.show()
	_dungeons_button.show()
	_skills_button.show()
	_quests_button.show()
	_refresh()


## Place of the last relic `id` in the stash (Egon's gift), -1 if there is none.
func _gift_index(id: String) -> int:
	var own: Array[Dictionary] = MetaState.stash()
	for i in range(own.size() - 1, -1, -1):
		if String(own[i].get("id", "")) == id and ShopGoods.is_relic(own[i]):
			return i
	return -1


## `icon` flies from `from` (global) into Egon's hands and is gone.
func _fly_to_egon(icon: Texture2D, from: Vector2) -> void:
	if icon == null:
		return
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size = ShopSlot.ICON_SIZE
	picture.z_index = 10
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(picture)
	picture.global_position = from + (ShopSlot.SIZE - ShopSlot.ICON_SIZE) / 2.0
	var hands: Vector2 = _merchant.global_position + _merchant.size * _merchant.scale * Vector2(0.5, 0.55)
	var fly := create_tween()
	fly.tween_property(picture, "global_position", hands - ShopSlot.ICON_SIZE / 2.0, FLY_TIME * 1.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(picture, "modulate:a", 0.0, 0.2)
	await fly.finished
	picture.queue_free()
	AudioManager.play_sound("coin")


## Egon says story.json `key` while `targets` shine. false if the shop is gone meanwhile.
func _explain(key: String, targets: Array) -> bool:
	_spotlight(targets)
	var still_here: bool = await _say(key)
	_spotlight([])
	return still_here


## Pulsing gold frames around `targets` (Controls of the shop); [] = none.
func _spotlight(targets: Array) -> void:
	for frame: Control in _spotlights:
		frame.queue_free()
	_spotlights.clear()
	if _spot_tween:
		_spot_tween.kill()
		_spot_tween = null
	if targets.is_empty():
		return
	for target: Variant in targets:
		if not target is Control:
			continue
		var control: Control = target
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.z_index = 20
		frame.add_theme_stylebox_override("panel", ShopSlot.box(Color(1, 0.85, 0.35, 0.08), ShopSlot.GLOW_COLOR, 3))
		var rect := Rect2(control.global_position - _frame.global_position, control.size * control.get_global_transform().get_scale()).grow(5.0)
		frame.position = rect.position
		frame.size = rect.size
		_frame.add_child(frame)
		_spotlights.append(frame)
	_spot_tween = create_tween().set_loops()
	for frame: Control in _spotlights:
		_spot_tween.parallel().tween_property(frame, "modulate:a", 0.35, 0.45)
	_spot_tween.chain()
	for frame: Control in _spotlights:
		_spot_tween.parallel().tween_property(frame, "modulate:a", 1.0, 0.45)


func get_spotlights() -> Array[Control]:
	return _spotlights


## Egon says the lines of story.json `key` (`insert` goes into a "%s"). false if the shop is gone
## meanwhile.
func _say(key: String, insert: String = "") -> bool:
	await _dialog.speak(Content.story(key), insert)
	return is_inside_tree()


## Where gear `id` (or potion `id` with `potion`) lies in the inventory; -1 = nowhere.
func _stash_index(id: String, potion: bool = false) -> int:
	var own: Array[Dictionary] = MetaState.stash()
	for i in own.size():
		var kind_fits: bool = ShopGoods.is_potion(own[i]) if potion else own[i].has("rarity")
		if String(own[i].get("id", "")) == id and kind_fits:
			return i
	return -1


# --- Dungeon board ------------------------------------------------------------------

func get_board() -> DungeonBoard:
	return _board


func get_dialog() -> DialogBox:
	return _dialog


func get_skill_window() -> SkillTreeWindow:
	return _skill_window


func _open_skills() -> void:
	if _locked:
		return
	_board.hide()
	_quest_window.hide()
	_skill_window.open()


func _open_board() -> void:
	if _locked:
		return
	_skill_window.hide()
	_quest_window.hide()
	_board.open()


## "Betreten": straight into dungeon `id` (its floors, dungeons.json "floors").
func _on_dungeon_entered(id: String) -> void:
	if not MetaState.is_dungeon_open(id):
		return
	# Readiness check: Egon mentions what is missing once; going again starts the run.
	var warning: String = readiness_warning()
	if not warning.is_empty() and not _ready_warned:
		_ready_warned = true
		_board.hide()
		_dialog.bark(warning)
		AudioManager.play_sound("denied", 1.2)
		return
	_board.hide()
	Game.start_new_run(MetaState.run_character(), id)
