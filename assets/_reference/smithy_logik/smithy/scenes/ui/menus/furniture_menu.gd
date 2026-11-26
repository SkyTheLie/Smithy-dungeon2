class_name FurnitureMenu
extends StationMenu
## Window of the furnishing book in the player's shop: the furniture in storage
## (GameState.house.owned, bought at the furniture trader on the market). A click on a piece
## starts placing it (FurnitureLayer), "Wegräumen" lets the player click placed pieces to put them
## back. Shows the price bonus all placed pieces give the shop.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLUMNS: int = 6
const COLOR_HINT: String = "#9e9a8f"
const COLOR_BONUS: String = "#8fd18a"

## The furniture layer of the room (placing mode).
@export var furniture_layer: FurnitureLayer

var _ids: Array[String] = []
var _slot_uis: Array[ItemSlotUI] = []

@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	_grid.columns = COLUMNS
	%PickButton.pressed.connect(_on_pick_pressed)
	GameState.house.changed.connect(_refresh)
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	var house: House = GameState.house
	_ids.clear()
	for id: String in ContentDB.house("furniture"):
		if house.get_owned(id) > 0:
			_ids.append(id)
	while _slot_uis.size() < maxi(_ids.size(), COLUMNS):
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(_slot_uis.size()))
		_slot_uis.append(slot_ui)
	for i in _slot_uis.size():
		if i >= _ids.size():
			_slot_uis[i].display(InventorySlot.new())
			continue
		var data: Dictionary = House.get_furniture(_ids[i])
		var text: String = Language.translate("[b]%s[/b] ×%d\n[color=%s]%s[/color]\n[color=%s]Preise im Laden +%s %%[/color]\n[color=%s]Klick: aufstellen[/color]") % [
				data.get("name", _ids[i]), house.get_owned(_ids[i]), COLOR_HINT, data.get("description", ""),
				COLOR_BONUS, _percent(float(data.get("bonus", 0.0))), COLOR_HINT]
		var path: String = data.get("texture", "")
		_slot_uis[i].display_custom(load(path) if ResourceLoader.exists(path) else null, text)
	var max_bonus: float = float(ContentDB.house("shop").get("max_furniture_bonus", 0.5))
	var lines: Array[String] = []
	if _ids.is_empty():
		lines.append(Language.translate("Dein Lager ist leer. Möbel gibt es beim Möbelhändler auf dem Markt."))
	lines.append(Language.translate("Aufgestellt: %d Stück, Preise +%s %% (höchstens +%s %%)") % [house.count_placed(House.SHOP_ROOM),
			_percent(house.get_price_bonus()), _percent(max_bonus)])
	lines.append(KeyBindings.fill(Language.translate("Linksklick stellt auf, Rechtsklick oder Esc beendet. Mit {key_build} kannst du alles im Haus verschieben.")))
	_status_label.text = "\n".join(lines)


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and index < _ids.size() and furniture_layer:
		close()
		furniture_layer.start_placing(_ids[index])


func _on_pick_pressed() -> void:
	if furniture_layer:
		close()
		furniture_layer.start_picking()
		GameState.show_message(Language.translate("Klick auf ein Möbelstück räumt es ins Lager. Rechtsklick beendet."))


static func _percent(value: float) -> String:
	return String.num(value * 100.0, 1).trim_suffix(".0")
