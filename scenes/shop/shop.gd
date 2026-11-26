class_name MerchantShop
extends Control
## Egon's shop between the days (after the intro, "Weiter", after every run). Layout like the
## sketch (bild2): top Egon's table (ShopGoods places, 5 x 2), right of it the lever with today's
## price below, left the hero with his equipment (HeroPanel), bottom the inventory (MetaState
## stash), in the middle Egon's speech window (DialogBox), Egon himself on the right.
##   Lever: MetaState.pull_lever (first pull of a day free, then dearer); the table flips over.
##   Click on goods: buy (MetaState.buy). Click on gear in the inventory: put it on (equip),
##   click on a hero place: take it off (unequip).
##   "Skills" (bottom right): the skill tree (SkillTreeWindow); the day, the player level and the
##   EXP at the top left.
##   "Dungeons" (bottom right): the dungeon board; "Betreten" starts the run at once, as the
##   character of the weapon on the hero (MetaState.run_character), no choice window.
## First visit (MetaState.tutorial_done false): Egon shows everything himself: he pulls the lever,
## his gifts (data/shop.json tutorial) shine, he buys them, they land in the inventory, he puts
## them on the hero, then he sends you off: the dungeon board opens and cannot be closed.
## All rules live in MetaState / ShopGoods; this screen only shows them and plays the animations.

const CAVE: Texture2D = preload("res://assets/sprites/battle/mine_rats.png")
const MERCHANT: Texture2D = preload("res://assets/sprites/npcs/black_market_dealer.png")
const LEVER_UP: Texture2D = preload("res://assets/sprites/fortress/lever_up.png")
const LEVER_DOWN: Texture2D = preload("res://assets/sprites/fortress/lever_down.png")
const COIN: Texture2D = preload("res://assets/ui/icon_coin.png")
const CAVE_SHADE := Color(0.45, 0.4, 0.4)
const GOLD_COLOR := Color(1, 0.86, 0.35)
const SCREEN := Vector2(640, 360)
const TABLE_COLUMNS: int = 5
const INVENTORY_COLUMNS: int = 8
const INVENTORY_MIN_PLACES: int = 16
const MERCHANT_SCALE: float = 3.0
const FADE_TIME: float = 0.5
const FLY_TIME: float = 0.45
const FLIP_TIME: float = 0.18

var _frame: Control
var _table_grid: GridContainer
var _table_slots: Array[ShopSlot] = []
var _inventory_grid: GridContainer
var _inventory_slots: Array[ShopSlot] = []
var _hero: HeroPanel
var _lever: TextureButton
var _lever_price: Label
var _gold: Label
var _day: Label
var _dialog: DialogBox
var _menu_button: Button
var _dungeons_button: Button
var _board: DungeonBoard
var _skills_button: Button
var _skill_window: SkillTreeWindow
var _black: ColorRect
## true while Egon does something by himself (tutorial, lever): clicks are ignored.
var _locked: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_build()
	_refresh()
	AudioManager.play_music("title")
	create_tween().tween_property(_black, "modulate:a", 0.0, FADE_TIME)
	if not MetaState.tutorial_done():
		_run_tutorial()
	elif not MetaState.broken_relic().is_empty():
		_bark("relic_broken")
		MetaState.clear_broken_relic()


# --- Building ---------------------------------------------------------------------

func _build() -> void:
	var cave := TextureRect.new()
	cave.texture = CAVE
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
	merchant.position = Vector2(500, 108)
	merchant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(merchant)

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

	_hero = HeroPanel.new()
	_hero.position = Vector2(8, 52)
	_hero.slot_clicked.connect(_on_hero_slot_clicked)
	_frame.add_child(_hero)

	var table_panel := _panel(Vector2(170, 10))
	_table_grid = GridContainer.new()
	_table_grid.columns = TABLE_COLUMNS
	_table_grid.add_theme_constant_override("h_separation", 6)
	_table_grid.add_theme_constant_override("v_separation", 6)
	table_panel.add_child(_table_grid)
	for i in ShopGoods.empty_table().size():
		var place := ShopSlot.new()
		place.show_price = true
		place.clicked.connect(_on_table_clicked.bind(i))
		_table_grid.add_child(place)
		_table_slots.append(place)

	_lever = TextureButton.new()
	_lever.name = "Lever"
	_lever.texture_normal = LEVER_UP
	_lever.texture_pressed = LEVER_DOWN
	_lever.ignore_texture_size = true
	_lever.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_lever.size = LEVER_UP.get_size() * 2.0
	_lever.position = Vector2(410, 12)
	_lever.focus_mode = Control.FOCUS_NONE
	_lever.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_lever.pressed.connect(_on_lever_pressed)
	_frame.add_child(_lever)
	_lever_price = _label("", 12, GOLD_COLOR)
	_lever_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lever_price.position = Vector2(392, 98)
	_lever_price.size = Vector2(88, 16)
	_frame.add_child(_lever_price)

	var inventory_panel := _panel(Vector2(170, 252))
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.custom_minimum_size = Vector2(
			INVENTORY_COLUMNS * ShopSlot.SIZE.x + (INVENTORY_COLUMNS - 1) * 4 + 4, 2 * ShopSlot.SIZE.y + 4)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_panel.add_child(inventory_scroll)
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = INVENTORY_COLUMNS
	_inventory_grid.add_theme_constant_override("h_separation", 4)
	_inventory_grid.add_theme_constant_override("v_separation", 4)
	inventory_scroll.add_child(_inventory_grid)

	_dialog = DialogBox.new()
	_dialog.position = Vector2(170, 132)
	_dialog.custom_minimum_size = Vector2(320, 100)
	_dialog.size = Vector2(320, 100)
	_frame.add_child(_dialog)
	_dialog.hide()

	_menu_button = _button(Language.translate("Hauptmenü"), Vector2(8, 326))
	_menu_button.pressed.connect(Game.to_main_menu)
	_dungeons_button = _button(Language.translate("Dungeons"), Vector2(0, 322))
	_dungeons_button.name = "DungeonsButton"
	_dungeons_button.add_theme_font_size_override("font_size", 18)
	_dungeons_button.pressed.connect(_open_board)
	_dungeons_button.position.x = SCREEN.x - 8 - _dungeons_button.get_combined_minimum_size().x
	_skills_button = _button(Language.translate("Skills"), Vector2(0, 322))
	_skills_button.name = "SkillsButton"
	_skills_button.add_theme_font_size_override("font_size", 18)
	_skills_button.pressed.connect(_open_skills)

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
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_black)


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
	_gold.text = str(MetaState.purse())
	var price: int = MetaState.lever_price()
	_lever_price.text = Language.translate("Gratis") if price == 0 else Language.translate("%d Gold") % price
	var table: Array[Dictionary] = MetaState.table()
	for i in _table_slots.size():
		_table_slots[i].show_entry(table[i] if i < table.size() else {})
	_refresh_inventory()
	_hero.refresh()


func _refresh_inventory() -> void:
	var own: Array[Dictionary] = MetaState.stash()
	var places: int = maxi(INVENTORY_MIN_PLACES, ceili(own.size() / float(INVENTORY_COLUMNS)) * INVENTORY_COLUMNS)
	while _inventory_slots.size() < places:
		var place := ShopSlot.new()
		place.clicked.connect(_on_inventory_clicked.bind(_inventory_slots.size()))
		_inventory_grid.add_child(place)
		_inventory_slots.append(place)
	for i in _inventory_slots.size():
		_inventory_slots[i].show_entry(own[i] if i < own.size() else {})


func _bark(key: String) -> void:
	_dialog.bark(String((Content.story("barks") as Dictionary).get(key, "")))


# --- Player actions -----------------------------------------------------------------

func _on_lever_pressed() -> void:
	if _locked:
		return
	if not await _pull_lever(false):
		_bark("too_poor")
		AudioManager.play_sound("denied")
		return
	_bark("rolled")


func _on_table_clicked(index: int) -> void:
	if _locked or _table_slots[index].is_empty():
		return
	var from: ShopSlot = _table_slots[index]
	var icon: Texture2D = from.get_icon()
	if not MetaState.buy(index):
		_bark("too_poor")
		AudioManager.play_sound("denied")
		return
	AudioManager.play_sound("buy")
	_bark("bought")
	_refresh()
	var target: ShopSlot = _inventory_slots[MetaState.stash().size() - 1]
	await _fly(icon, from, target)


func _on_inventory_clicked(index: int) -> void:
	var own: Array[Dictionary] = MetaState.stash()
	if _locked or index >= own.size():
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
	AudioManager.play_sound("pickup")
	_refresh()


# --- Animations ---------------------------------------------------------------------

## The lever goes down, the table flips over and comes back with the new goods. `tutorial` =
## Egon's free first pull with his gifts. false (nothing happens) without enough gold.
func _pull_lever(tutorial: bool) -> bool:
	if not tutorial and MetaState.lever_price() > MetaState.purse():
		return false
	_locked = true
	_lever.texture_normal = LEVER_DOWN
	AudioManager.play_sound("door")
	var table_panel: Control = _table_grid.get_parent()
	table_panel.pivot_offset = table_panel.size / 2.0
	var flip := create_tween()
	flip.tween_property(table_panel, "scale:y", 0.0, FLIP_TIME).set_ease(Tween.EASE_IN)
	await flip.finished
	if tutorial:
		MetaState.lay_tutorial_table()
	else:
		MetaState.pull_lever(_rng)
	_refresh()
	flip = create_tween()
	flip.tween_property(table_panel, "scale:y", 1.0, FLIP_TIME).set_ease(Tween.EASE_OUT)
	await flip.finished
	for place: ShopSlot in _table_slots:
		if not place.is_empty():
			place.pop()
	_lever.texture_normal = LEVER_UP
	_locked = false
	return true


## Puts inventory place `index` on the hero, with the picture flying there.
func _equip_animated(index: int) -> void:
	var slot: String = MetaState.slot_of(MetaState.stash()[index])
	var from: ShopSlot = _inventory_slots[index]
	var icon: Texture2D = from.get_icon()
	if not MetaState.equip(index):
		return
	AudioManager.play_sound("item")
	_refresh()
	await _fly(icon, from, _hero.get_slot(slot))


## A picture flies from one place to another (both stay as they are; refresh first).
func _fly(icon: Texture2D, from: Control, to: Control) -> void:
	if icon == null or from == null or to == null:
		return
	to.modulate.a = 0.0
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size = ShopSlot.ICON_SIZE
	picture.z_index = 10
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(picture)
	var offset: Vector2 = (ShopSlot.SIZE - ShopSlot.ICON_SIZE) / 2.0
	picture.global_position = from.global_position + offset
	var fly := create_tween()
	fly.tween_property(picture, "global_position", to.global_position + offset, FLY_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fly.finished
	picture.queue_free()
	to.modulate.a = 1.0
	if to is ShopSlot:
		(to as ShopSlot).pop()


# --- Egon's tour (first visit) ---------------------------------------------------------

func _run_tutorial() -> void:
	_locked = true
	_menu_button.hide()
	_dungeons_button.hide()
	_skills_button.hide()
	await get_tree().create_timer(FADE_TIME, false).timeout
	if not await _say("tutorial_welcome"):
		return
	_lever.modulate = Color(1.4, 1.3, 0.9)
	if not await _say("tutorial_lever"):
		return
	_lever.modulate = Color.WHITE
	_dialog.hide()
	await _pull_lever(true)
	_locked = true
	if not is_inside_tree() or not await _say("tutorial_goods"):
		return
	var gifts: Array = (Content.shop().get("tutorial", {}) as Dictionary).get("gifts", [])
	var gift_cells: Array[int] = []
	var table: Array[Dictionary] = MetaState.table()
	for i in table.size():
		if not table[i].is_empty() and gifts.has(String(table[i]["id"])):
			gift_cells.append(i)
			_table_slots[i].set_glow(true)
	if not await _say("tutorial_gifts"):
		return
	# Egon buys them: one after the other into the inventory.
	for cell: int in gift_cells:
		_table_slots[cell].set_glow(false)
		var from: ShopSlot = _table_slots[cell]
		var icon: Texture2D = from.get_icon()
		MetaState.buy(cell, true)
		AudioManager.play_sound("buy")
		_refresh()
		await _fly(icon, from, _inventory_slots[MetaState.stash().size() - 1])
		if not is_inside_tree():
			return
	for place: ShopSlot in _inventory_slots:
		place.set_glow(not place.is_empty())
	if not await _say("tutorial_bag"):
		return
	for place: ShopSlot in _inventory_slots:
		place.set_glow(false)
	if not await _say("tutorial_dress"):
		return
	# … and puts them on: every gift from the inventory onto its place.
	for id: Variant in gifts:
		var index: int = _stash_index(String(id))
		if index >= 0:
			await _equip_animated(index)
			if not is_inside_tree():
				return
	if not await _say("tutorial_dungeon"):
		return
	MetaState.finish_tutorial()
	_dialog.hide()
	_locked = false
	_menu_button.show()
	_dungeons_button.show()
	_skills_button.show()
	# Off you go: the board opens and stays open.
	_board.open(true)


## Egon says the lines of story.json `key`. false if the shop is gone meanwhile.
func _say(key: String) -> bool:
	await _dialog.speak(Content.story(key))
	return is_inside_tree()


func _stash_index(id: String) -> int:
	var own: Array[Dictionary] = MetaState.stash()
	for i in own.size():
		if String(own[i].get("id", "")) == id and own[i].has("rarity"):
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
	_skill_window.open()


func _open_board() -> void:
	if _locked:
		return
	_skill_window.hide()
	_board.open()


## "Betreten": straight into the dungeon (every dungeon plays floors.json so far).
func _on_dungeon_entered(_id: String) -> void:
	_board.hide()
	Game.start_new_run(MetaState.run_character())
