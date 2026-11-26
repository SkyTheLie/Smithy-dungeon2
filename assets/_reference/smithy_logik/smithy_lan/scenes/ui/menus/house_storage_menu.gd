class_name HouseStorageMenu
extends StationMenu
## The furniture storage of the house while moving things (HouseEditor, key B): every piece in
## storage (GameState.house.owned, bought at the furniture trader) and every bought station put
## away (GameState.house.stored_stations) and the decoration of this `room` put away
## (GameState.house.stored_decor). A click emits piece_chosen, station_chosen or decor_chosen (the
## editor then lets the player place it). Closing the window ends the mode.
## Not a station window: a right click in the inventory does nothing here.

signal piece_chosen(id: String)
signal station_chosen(id: String)
signal decor_chosen(path: String)
## "Wände & Böden" was pressed (the room designer opens, RoomDesignMenu).
signal design_requested

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLUMNS: int = 5
const MIN_SLOTS: int = 10
## Stations in `_ids`: "station:<id>" (economy.json "stations").
const STATION_PREFIX: String = "station:"
## Decoration in `_ids`: "decor:<node path>" (house.json "decorations").
const DECOR_PREFIX: String = "decor:"
const COLOR_HINT: String = "#9e9a8f"
const HINT: String = "Klick: aufstellen. Anheben: Klick im Raum.\nRechtsklick auf Möbel, Deko oder ein gekauftes Gerät: einlagern.\nB oder Fenster schließen: fertig."

## Room key of the HouseEditor (its stored decoration is shown).
var room: String = ""
## Room key of the furniture placed here (FurnitureLayer.room, e.g. "shop" in the shop, whose
## HouseEditor room is "shop_small"): only furniture that may stand there is listed. Empty = `room`.
var furniture_room: String = ""
## Shows the "Wände & Böden" button (the room has a RoomStyleLayer).
var can_design: bool = false:
	set(value):
		can_design = value
		if _design_button:
			_design_button.visible = value
var _design_button: Button
var _ids: Array[String] = []
var _slot_uis: Array[ItemSlotUI] = []

@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	# Not a station: right clicks in the inventory must not be offered to this window.
	remove_from_group(QUICK_MOVE_GROUP)
	_grid.columns = COLUMNS
	_design_button = Button.new()
	_design_button.text = Language.translate("Wände & Böden")
	_design_button.focus_mode = Control.FOCUS_NONE
	_design_button.visible = can_design
	_design_button.pressed.connect(func() -> void: design_requested.emit())
	_grid.add_sibling(_design_button)
	GameState.house.changed.connect(_refresh)
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	var house: House = GameState.house
	_ids.clear()
	for id: String in ContentDB.house("furniture"):
		# Plant pots only in the greenhouse, the jewel case only in the shop (house.json "rooms").
		if house.get_owned(id) > 0 and House.can_stand_in(id, room if furniture_room.is_empty() else furniture_room):
			_ids.append(id)
	for id in house.stored_stations:
		_ids.append(STATION_PREFIX + id)
	for path: String in house.get_stored_decor(room):
		_ids.append(DECOR_PREFIX + path)
	while _slot_uis.size() < maxi(_ids.size(), MIN_SLOTS):
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(_slot_uis.size()))
		_grid.add_child(slot_ui)
		_slot_uis.append(slot_ui)
	for i in _slot_uis.size():
		if i >= _ids.size():
			_slot_uis[i].display(InventorySlot.new())
			continue
		var station: bool = _ids[i].begins_with(STATION_PREFIX)
		var decor: bool = _ids[i].begins_with(DECOR_PREFIX)
		var data: Dictionary
		var count: String
		if station:
			data = Economy.get_station_offer(_ids[i].trim_prefix(STATION_PREFIX))
			count = Language.translate("Gerät, im Lager")
		elif decor:
			data = House.get_decoration(_ids[i].trim_prefix(DECOR_PREFIX).get_file())
			count = Language.translate("Deko, im Lager")
		else:
			data = House.get_furniture(_ids[i])
			count = Language.translate("%d im Lager") % house.get_owned(_ids[i])
		var text: String = "[b]%s[/b] (%s)\n[color=%s]%s[/color]" % [
				data.get("name", _ids[i]), count, COLOR_HINT, data.get("description", "")]
		var path: String = data.get("icon" if station or decor else "texture", "")
		_slot_uis[i].display_custom(load(path) if ResourceLoader.exists(path) else null, text)
	var empty: String = Language.translate("Lager leer: Möbel gibt es bei der Möbelhändlerin.\n") if _ids.is_empty() else ""
	_status_label.text = empty + Language.translate(HINT)


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and index < _ids.size():
		if _ids[index].begins_with(STATION_PREFIX):
			station_chosen.emit(_ids[index].trim_prefix(STATION_PREFIX))
		elif _ids[index].begins_with(DECOR_PREFIX):
			decor_chosen.emit(_ids[index].trim_prefix(DECOR_PREFIX))
		else:
			piece_chosen.emit(_ids[index])
