class_name ShopAdminMenu
extends CanvasLayer
## P in Egon's shop, only in debug builds (started from the editor): a menu for testing quickly,
## like the AdminMenu of the dungeon. P or Esc closes it. Built in code (no .tscn).
##   Geben       gear (with rarity, a random Bauart if ticked), relics, potions, backpacks and loot into the stash, put on
##               at once, empty the stash
##   Laden       gold into the box / empty the box, new goods for free, lever free again, a new day
##   Fortschritt a level, skill points, a dungeon won / all dungeons open, a quest done without its
##               stone, skip Egon's tour, potion show / ruby errand, open the shop again
## A tool for the developers: its texts are German only and not translated (on purpose).
## Only calls the rules (MetaState, ShopGoods, Game); has none of its own. After every change the
## shop shows the new state (MerchantShop.refresh_all).

signal closed

const PANEL_COLOR := Color(0.08, 0.07, 0.1, 0.97)
const LIST_HEIGHT: float = 130.0

var shop: MerchantShop

var _status: Label
var _filter: LineEdit
var _list: ItemList
var _rarity: SpinBox
## On: gear gets a random Bauart (gear.json types), off: normal.
var _random_type: CheckBox
## Pieces in the list: {"kind": "gear" / "relic" / "potion" / "backpack" / "loot", "id"}.
var _entries: Array[Dictionary] = []
var _dungeon_pick: OptionButton
var _quest_pick: OptionButton
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func setup(the_shop: MerchantShop) -> void:
	shop = the_shop
	_rng.randomize()
	_build()
	hide()


func open() -> void:
	_refresh_list()
	_refresh_quests()
	_show_state()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(Controls.TEST_ROOM) or event.is_action_pressed(Controls.PAUSE)):
		get_viewport().set_input_as_handled()
		close()


# --- Building ---------------------------------------------------------------------------

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.5)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.border_color = Color(0.9, 0.3, 0.25)
	box.set_border_width_all(2)
	box.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(440, 300)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "ADMIN LADEN (nur im Editor) · P / Esc: schließen"
	title.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	column.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 10)
	column.add_child(_status)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	tabs.add_child(_build_give())
	tabs.add_child(_build_shop())
	tabs.add_child(_build_progress())


func _page(page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = page_name
	return page


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	return row


func _build_give() -> Control:
	var page := _page("Geben")
	var row := _row(page)
	_filter = LineEdit.new()
	_filter.placeholder_text = "Suchen (Name, Id, ausrüstung, relikt, trank, rucksack, beute) …"
	_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter.text_changed.connect(func(_t: String) -> void: _refresh_list())
	row.add_child(_filter)
	var rarity_label := Label.new()
	rarity_label.text = "Seltenheit"
	row.add_child(rarity_label)
	_rarity = SpinBox.new()
	_rarity.min_value = 1
	_rarity.max_value = maxi(1, (Content.get_file("gear").get("rarity_stats", [1]) as Array).size())
	_rarity.value = 1
	row.add_child(_rarity)
	_random_type = CheckBox.new()
	_random_type.text = "Bauart würfeln"
	row.add_child(_random_type)
	_list = ItemList.new()
	_list.custom_minimum_size.y = LIST_HEIGHT
	_list.select_mode = ItemList.SELECT_MULTI
	_list.item_activated.connect(_on_give)
	page.add_child(_list)
	var buttons := _row(page)
	_button(buttons, "Ins Lager (Doppelklick)", func() -> void:
		for index: int in _list.get_selected_items():
			_on_give(index))
	_button(buttons, "Geben + anlegen", func() -> void:
		for index: int in _list.get_selected_items():
			_on_give(index, true))
	_button(buttons, "Lager leeren", func() -> void:
		MetaState.admin_clear_stash()
		_done("Lager leer"))
	return page


func _build_shop() -> Control:
	var page := _page("Laden")
	var gold := HFlowContainer.new()
	page.add_child(gold)
	for amount: int in [100, 1000, 10000]:
		_button(gold, "+%d Gold (Dose)" % amount, func() -> void:
			MetaState.gift_gold(amount)
			_done("Dose: %d Gold" % MetaState.box()))
	_button(gold, "Dose leeren", func() -> void:
		MetaState.admin_set_box(0)
		_done("Dose leer"))
	var lever := HFlowContainer.new()
	page.add_child(lever)
	_button(lever, "Neue Ware (gratis)", func() -> void:
		MetaState.admin_roll_table(_rng)
		_done("Neue Ware auf dem Tisch"))
	_button(lever, "Tisch leeren", func() -> void:
		MetaState.admin_reset_lever()
		MetaState.admin_clear_table()
		_done("Tisch leer, Hebel gratis"))
	_button(lever, "Hebel wieder gratis", func() -> void:
		MetaState.admin_reset_lever()
		_done("Hebel gratis"))
	_button(lever, "Neuer Tag", func() -> void:
		MetaState.admin_next_day()
		_done("Tag %d" % MetaState.day()))
	return page


func _build_progress() -> Control:
	var page := _page("Fortschritt")
	var level := HFlowContainer.new()
	page.add_child(level)
	_button(level, "+1 Spielerstufe", func() -> void:
		var need: int = Skills.exp_to_next(MetaState.level())
		if need > 0:
			MetaState.add_exp(need - MetaState.exp_points())
		_done("Stufe %d" % MetaState.level()))
	_button(level, "+5 Skillpunkte", func() -> void:
		MetaState.admin_add_skill_points(5)
		_done("Skillpunkte: %d" % MetaState.skill_points()))
	var dungeons := _row(page)
	_dungeon_pick = OptionButton.new()
	for id: String in Content.dungeons():
		_dungeon_pick.add_item("%s (%s)" % [String((Content.dungeons()[id] as Dictionary).get("name", id)), id])
		_dungeon_pick.set_item_metadata(_dungeon_pick.item_count - 1, id)
	dungeons.add_child(_dungeon_pick)
	_button(dungeons, "geschafft", func() -> void:
		var id: String = String(_dungeon_pick.get_item_metadata(_dungeon_pick.selected))
		MetaState.win_dungeon(id)
		_done("%s gilt als geschafft" % id))
	_button(dungeons, "Alle geschafft", func() -> void:
		for id: String in Content.dungeons():
			MetaState.win_dungeon(id)
		_done("Alle Dungeons geschafft"))
	var quests := _row(page)
	_quest_pick = OptionButton.new()
	quests.add_child(_quest_pick)
	_button(quests, "Quest erledigen (ohne Stein)", _on_finish_quest)
	var story := HFlowContainer.new()
	page.add_child(story)
	_button(story, "Egons Tour überspringen", func() -> void:
		MetaState.finish_tutorial()
		_done("Tour erledigt"))
	_button(story, "Rubin abgegeben", func() -> void:
		MetaState.admin_ruby_delivered()
		_done("Egon hat seinen Rubin"))
	_button(story, "Tränke freischalten", func() -> void:
		MetaState.unlock_potions()
		_done("Tränke frei"))
	_button(story, "Trank-Vorführung zeigen", func() -> void:
		MetaState.admin_potion_tour_due()
		Game.to_shop())
	_button(story, "Laden neu öffnen", func() -> void: Game.to_shop())
	return page


# --- Lists -----------------------------------------------------------------------------

func _matches(texts: Array[String]) -> bool:
	var filter: String = _filter.text.to_lower()
	if filter.is_empty():
		return true
	for text: String in texts:
		if text.to_lower().contains(filter):
			return true
	return false


func _add_entry(kind: String, id: String, text: String, search: Array[String]) -> void:
	if not _matches(search):
		return
	_entries.append({"kind": kind, "id": id})
	_list.add_item(text)


func _refresh_list() -> void:
	_list.clear()
	_entries.clear()
	for id: String in Content.gear():
		var piece_name: String = String(Content.gear_item(id).get("name", id))
		_add_entry("gear", id, "Ausrüstung: %s (%s)" % [piece_name, id], [id, piece_name, "ausrüstung"])
	for id: String in (Content.relics().get("items", {}) as Dictionary):
		var relic_name: String = String(Content.item(id).get("name", id))
		_add_entry("relic", id, "Relikt %d: %s (%s)" % [ShopGoods.relic_tier(id), relic_name, id], [id, relic_name, "relikt"])
	for id: String in (Content.potions().get("potions", {}) as Dictionary):
		var potion_name: String = String(Content.potion(id).get("name", id))
		_add_entry("potion", id, "Trank: %s (%s)" % [potion_name, id], [id, potion_name, "trank"])
	for id: String in BagLayout.backpacks():
		var pack_name: String = String(BagLayout.backpack(id).get("name", id))
		_add_entry("backpack", id, "Rucksack: %s (%s)" % [pack_name, id], [id, pack_name, "rucksack"])
	for id: String in Content.materials():
		var loot_name: String = String(Content.material(id).get("name", id))
		_add_entry("loot", id, "Beute: %s (%s)" % [loot_name, id], [id, loot_name, "beute"])


func _refresh_quests() -> void:
	_quest_pick.clear()
	for id: String in Quests.all():
		var mark: String = " ✓" if MetaState.quest_done(id) else ""
		_quest_pick.add_item("%s%s" % [id, mark])
		_quest_pick.set_item_metadata(_quest_pick.item_count - 1, id)


func _show_state() -> void:
	_status.text = "Platz %s · Tag %d · Stufe %d · Dose %d · Ort %s · Hebel-Züge heute %d" % [
		MetaState.slot(), MetaState.day(), MetaState.level(), MetaState.box(), MetaState.location(), MetaState.pulls_today()]


# --- Actions ---------------------------------------------------------------------------

## The shop shows the new state, the status line says what happened.
func _done(text: String) -> void:
	if shop and is_instance_valid(shop):
		shop.refresh_all()
	_show_state()
	_status.text = text + " · " + _status.text


## Puts the piece into the stash (free); `wear`: puts it on at once.
func _on_give(index: int, wear: bool = false) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	var id: String = String(entry["id"])
	var kind: String = String(entry["kind"])
	if kind == "loot":
		MetaState.admin_give_loot(id)
		_done("Beute: %s" % id)
		return
	var piece: Dictionary = {}
	match kind:
		"gear":
			var type: String = ShopGoods.pick_type(id, _rng) if _random_type.button_pressed else ""
			piece = ShopGoods.make_piece(id, int(_rarity.value), type)
		"relic":
			piece = ShopGoods.make_relic(id)
		"potion":
			piece = ShopGoods.make_potion(id)
		"backpack":
			piece = ShopGoods.make_backpack(id)
	var place: int = MetaState.give_piece(piece)
	if wear and place >= 0:
		var worn: bool = MetaState.attach_backpack_anywhere(place) if kind == "backpack" else MetaState.equip(place)
		_done(("Angelegt: %s" if worn else "Ins Lager (anlegen ging nicht): %s") % id)
		return
	_done("Ins Lager: %s" % id)


func _on_finish_quest() -> void:
	if _quest_pick.item_count == 0:
		return
	var id: String = String(_quest_pick.get_item_metadata(_quest_pick.selected))
	var before: String = MetaState.location()
	if not MetaState.admin_finish_quest(id):
		_done("Quest %s schon erledigt" % id)
		return
	_refresh_quests()
	_done("Quest %s erledigt" % id)
	if MetaState.location() != before:
		Game.to_shop()
