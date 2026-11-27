class_name AdminMenu
extends CanvasLayer
## P during a run, only in debug builds (started from the editor): a menu for testing quickly.
## The game stops while it is open; P or Esc closes it. Built in code (no .tscn).
##   Reise       other dungeon / floor (same run, Game.travel), rooms of this floor, the boss hall,
##               skip the boss hall scene, the old test room with every item on a pedestal
##   Items       give any item of the run (data/items.json), drop all
##   Ausrüstung  put on gear (gear.json, with rarity), relics (relics.json) and potions, take off
##               (MetaState, so it stays after the run; the run takes it at once)
##   Cheats      full life, invulnerable, kill the room, bombs/keys, gold into the box, a level,
##               mark the dungeon as won
## A tool for the developers: its texts are German only and not translated (on purpose).
## Only calls the rules (Dungeon, RunState, MetaState, Game); has none of its own.

signal closed

const PANEL_COLOR := Color(0.08, 0.07, 0.1, 0.97)
const LIST_HEIGHT: float = 170.0

var run: RunState
var dungeon: Dungeon
var player: Player
## Cheat: the player takes no damage while this is on (kept while the menu is closed).
var god_mode: bool = false

var _panel: PanelContainer
var _status: Label
var _dungeon_pick: OptionButton
var _floor_pick: SpinBox
var _item_filter: LineEdit
var _item_list: ItemList
var _gear_filter: LineEdit
var _gear_list: ItemList
var _rarity: SpinBox
var _worn: VBoxContainer
var _item_ids: Array[String] = []
## Pieces in the gear list: {"kind": "gear" / "relic" / "potion", "id"}.
var _gear_entries: Array[Dictionary] = []


func _init() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func setup(run_state: RunState, the_dungeon: Dungeon, the_player: Player) -> void:
	run = run_state
	dungeon = the_dungeon
	player = the_player
	_build()
	hide()


func open() -> void:
	_refresh_items()
	_refresh_gear()
	_refresh_worn()
	_status.text = "Dungeon: %s · Ebene %d · Raum %s" % [Content.dungeon_id(), run.floor_index + 1, str(dungeon.current_cell)]
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(Controls.TEST_ROOM) or event.is_action_pressed(Controls.PAUSE)):
		get_viewport().set_input_as_handled()
		close()


func _process(_delta: float) -> void:
	if god_mode and player and is_instance_valid(player):
		player.invulnerable = maxf(player.invulnerable, 0.5)


# --- Building ---------------------------------------------------------------------------

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.5)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.border_color = Color(0.9, 0.3, 0.25)
	box.set_border_width_all(2)
	box.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.custom_minimum_size = Vector2(420, 300)
	center.add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	var title := Label.new()
	title.text = "ADMIN (nur im Editor) · P / Esc: schließen"
	title.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	column.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 10)
	column.add_child(_status)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	tabs.add_child(_build_travel())
	tabs.add_child(_build_items())
	tabs.add_child(_build_gear())
	tabs.add_child(_build_cheats())


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


func _build_travel() -> Control:
	var page := _page("Reise")
	var row := _row(page)
	_dungeon_pick = OptionButton.new()
	for id: String in Content.dungeons():
		_dungeon_pick.add_item("%s (%s)" % [String((Content.dungeons()[id] as Dictionary).get("name", id)), id])
		_dungeon_pick.set_item_metadata(_dungeon_pick.item_count - 1, id)
		if id == Content.dungeon_id():
			_dungeon_pick.select(_dungeon_pick.item_count - 1)
	row.add_child(_dungeon_pick)
	var floor_label := Label.new()
	floor_label.text = "Ebene"
	row.add_child(floor_label)
	_floor_pick = SpinBox.new()
	_floor_pick.min_value = 1
	_floor_pick.max_value = 9
	_floor_pick.value = run.floor_index + 1
	row.add_child(_floor_pick)
	_button(row, "Hinreisen", _on_travel)
	var rooms := HFlowContainer.new()
	page.add_child(rooms)
	_button(rooms, "Boss-Halle", func() -> void: _act(dungeon.teleport_to_boss_hall))
	_button(rooms, "Boss-Szene überspringen", _on_skip_scene)
	for type: String in [FloorLayout.START_ROOM, FloorLayout.BOSS, FloorLayout.ITEM, FloorLayout.SHOP, FloorLayout.SECRET, FloorLayout.SACRIFICE, FloorLayout.SPECIAL]:
		_button(rooms, "Raum: %s" % type, _on_room.bind(type))
	_button(rooms, "Testraum (alle Items)", func() -> void: _act(dungeon.toggle_test_room))
	return page


func _build_items() -> Control:
	var page := _page("Items")
	_item_filter = LineEdit.new()
	_item_filter.placeholder_text = "Suchen (Name oder Id) …"
	_item_filter.text_changed.connect(func(_t: String) -> void: _refresh_items())
	page.add_child(_item_filter)
	_item_list = ItemList.new()
	_item_list.custom_minimum_size.y = LIST_HEIGHT
	_item_list.item_activated.connect(_on_give_item)
	page.add_child(_item_list)
	var row := _row(page)
	_button(row, "Geben (Doppelklick)", func() -> void:
		for index: int in _item_list.get_selected_items():
			_on_give_item(index))
	_button(row, "Alle Items ablegen", func() -> void:
		run.clear_items()
		_note("Alle Items abgelegt"))
	return page


func _build_gear() -> Control:
	var page := _page("Ausrüstung")
	var row := _row(page)
	_gear_filter = LineEdit.new()
	_gear_filter.placeholder_text = "Suchen …"
	_gear_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_filter.text_changed.connect(func(_t: String) -> void: _refresh_gear())
	row.add_child(_gear_filter)
	var rarity_label := Label.new()
	rarity_label.text = "Seltenheit"
	row.add_child(rarity_label)
	_rarity = SpinBox.new()
	_rarity.min_value = 1
	_rarity.max_value = maxi(1, (Content.get_file("gear").get("rarity_stats", [1]) as Array).size())
	_rarity.value = 1
	row.add_child(_rarity)
	_gear_list = ItemList.new()
	_gear_list.custom_minimum_size.y = LIST_HEIGHT * 0.6
	_gear_list.item_activated.connect(_on_wear)
	page.add_child(_gear_list)
	_button(page, "Anlegen (Doppelklick)", func() -> void:
		for index: int in _gear_list.get_selected_items():
			_on_wear(index))
	var worn_label := Label.new()
	worn_label.text = "Angelegt (Klick = ablegen):"
	page.add_child(worn_label)
	_worn = VBoxContainer.new()
	page.add_child(_worn)
	return page


func _build_cheats() -> Control:
	var page := _page("Cheats")
	var flow := HFlowContainer.new()
	page.add_child(flow)
	_button(flow, "Leben voll", func() -> void:
		run.heal(99)
		_note("Leben voll"))
	var god := CheckButton.new()
	god.text = "Unverwundbar"
	god.toggled.connect(func(on: bool) -> void: god_mode = on)
	flow.add_child(god)
	_button(flow, "Raum leeren", func() -> void:
		dungeon.end_fight_now()
		_note("Gegner weg"))
	_button(flow, "+5 Bomben", func() -> void: run.add_bombs(5))
	_button(flow, "+5 Schlüssel", func() -> void: run.add_keys(5))
	_button(flow, "+1000 Gold (Dose)", func() -> void:
		MetaState.gift_gold(1000)
		_note("Dose: %d Gold" % MetaState.box()))
	_button(flow, "+1 Spielerstufe", func() -> void:
		var need: int = Skills.exp_to_next(MetaState.level())
		if need > 0:
			MetaState.add_exp(need - MetaState.exp_points())
		_note("Stufe %d" % MetaState.level()))
	_button(flow, "Dungeon geschafft", func() -> void:
		MetaState.win_dungeon(Content.dungeon_id())
		_note("%s gilt als geschafft" % Content.dungeon_id()))
	return page


# --- Lists -----------------------------------------------------------------------------

func _matches(filter: String, texts: Array[String]) -> bool:
	if filter.is_empty():
		return true
	for text: String in texts:
		if text.to_lower().contains(filter.to_lower()):
			return true
	return false


func _refresh_items() -> void:
	_item_list.clear()
	_item_ids.clear()
	var ids: Array = Content.items().keys()
	ids.sort()
	for id: Variant in ids:
		var item_name: String = String(Content.item(String(id)).get("name", id))
		if not _matches(_item_filter.text, [String(id), item_name]):
			continue
		_item_ids.append(String(id))
		var mark: String = " ✓" if run.has_item(String(id)) else ""
		var icon_path: String = String(Content.item(String(id)).get("icon", ""))
		var icon: Texture2D = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
		_item_list.add_item("%s (%s)%s" % [item_name, id, mark], icon)


func _refresh_gear() -> void:
	_gear_list.clear()
	_gear_entries.clear()
	for id: String in Content.gear():
		var piece_name: String = String(Content.gear_item(id).get("name", id))
		if _matches(_gear_filter.text, [id, piece_name, "ausrüstung"]):
			_gear_entries.append({"kind": "gear", "id": id})
			_gear_list.add_item("Ausrüstung: %s (%s)" % [piece_name, id])
	for id: String in (Content.relics().get("items", {}) as Dictionary):
		var relic_name: String = String(Content.item(id).get("name", id))
		if _matches(_gear_filter.text, [id, relic_name, "relikt"]):
			_gear_entries.append({"kind": "relic", "id": id})
			_gear_list.add_item("Relikt %d: %s (%s)" % [ShopGoods.relic_tier(id), relic_name, id])
	for id: String in (Content.potions().get("potions", {}) as Dictionary):
		var potion_name: String = String(Content.potion(id).get("name", id))
		if _matches(_gear_filter.text, [id, potion_name, "trank"]):
			_gear_entries.append({"kind": "potion", "id": id})
			_gear_list.add_item("Trank: %s (%s)" % [potion_name, id])


func _refresh_worn() -> void:
	for child: Node in _worn.get_children():
		child.queue_free()
	var worn: Dictionary = MetaState.equipment()
	if worn.is_empty():
		var none := Label.new()
		none.text = "(nichts)"
		_worn.add_child(none)
	for slot: String in worn:
		var piece: Dictionary = worn[slot]
		_button(_worn, "%s: %s" % [slot, String(piece.get("id", ""))], _on_take_off.bind(slot))


# --- Actions ---------------------------------------------------------------------------

## Closes the menu, then does `action` (so the game runs again for the room change).
func _act(action: Callable) -> void:
	close()
	action.call()


func _note(text: String) -> void:
	_status.text = text


func _on_travel() -> void:
	var id: String = String(_dungeon_pick.get_item_metadata(_dungeon_pick.selected))
	var index: int = int(_floor_pick.value) - 1
	Content.active_dungeon = id
	if index >= Content.floors().size():
		_note("Dieser Dungeon hat nur %d Ebenen" % Content.floors().size())
		return
	close()
	Game.travel(id, index)


func _on_room(type: String) -> void:
	var cell: Vector2i = dungeon.layout.cell_of(type)
	if cell == Vector2i(-1, -1):
		_note("Diese Ebene hat keinen Raum %s" % type)
		return
	_act(dungeon.teleport_to_cell.bind(cell))


func _on_skip_scene() -> void:
	if not dungeon.in_boss_hall():
		dungeon.teleport_to_boss_hall()
	close()
	dungeon.hall.skip_intro()


func _on_give_item(index: int) -> void:
	if index < 0 or index >= _item_ids.size():
		return
	run.add_item(_item_ids[index])
	_note("Item: %s" % _item_ids[index])
	_refresh_items()


## Puts the piece on at once (into the inventory at home, then worn) and lets the run use it.
func _on_wear(index: int) -> void:
	if index < 0 or index >= _gear_entries.size():
		return
	var entry: Dictionary = _gear_entries[index]
	var id: String = String(entry["id"])
	var piece: Dictionary = {}
	match String(entry["kind"]):
		"gear":
			piece = ShopGoods.make_piece(id, int(_rarity.value))
		"relic":
			piece = ShopGoods.make_relic(id)
		"potion":
			piece = ShopGoods.make_potion(id)
	if not MetaState.equip(MetaState.give_piece(piece)):
		_note("Kann %s nicht anlegen" % id)
		return
	# A relic works like its item: the run gets it now (once).
	if String(entry["kind"]) == "relic" and not run.has_item(id):
		run.add_item(id)
	_apply_gear()
	_refresh_worn()
	_note("Angelegt: %s" % id)


func _on_take_off(slot: String) -> void:
	MetaState.unequip(slot)
	_apply_gear()
	_refresh_worn()
	_note("Abgelegt: %s (liegt im Inventar zu Hause)" % slot)


## The run uses the worn gear and potions again (relics are items of the run already, so they
## are left out here; use_gear would add them a second time).
func _apply_gear() -> void:
	var worn: Dictionary = MetaState.equipment()
	var without_relics: Dictionary = {}
	for slot: String in worn:
		if not ShopGoods.is_relic(worn[slot]):
			without_relics[slot] = worn[slot]
	run.use_gear(without_relics)
