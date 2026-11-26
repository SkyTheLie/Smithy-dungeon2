class_name ShopDisplayMenu
extends StationMenu
## Window of the display in Nina's shop or the player's own shop (`shop`, see
## GameState.get_consignment_shop): one slot per display place in use.
## Weapons are dragged or right-clicked in from the inventory, a click on a slot takes the
## piece back. With `jewelry` it shows the places of the jewel case of the own shop (rings and
## amulets). With `dummy` the window shows the armor dummy of Nina's expanded shop instead
## or the armor stand of the own shop (one place per armor type, ConsignmentShop.get_dummy_slots); otherwise the weapon places. The tooltip shows the price (from material, rarity and reputation) and what the
## player gets (after Nina's commission; the own shop has none). Sold pieces vanish; the money
## waits with Nina or in the cash box of the own shop.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLOR_PRICE: String = "#f2cc80"
const MAX_COLUMNS: int = 6

## Which shop: "nina" (Nina's shop at the market) or "house" (the player's own shop).
@export_enum("nina", "house") var shop: String = "nina"
## true = the armor dummy of Nina's expanded shop.
@export var dummy: bool = false
## true = the jewel case of the own shop (rings and amulets, ConsignmentShop.get_jewel_slots).
@export var jewelry: bool = false

var _slot_uis: Array[ItemSlotUI] = []
## Display place of the shop behind each slot of the window.
var _indexes: Array[int] = []
var _shop: ConsignmentShop

@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	# Buying, selling and laying out need the inventory next to the window.
	opens_inventory = true
	super()
	_shop = GameState.get_consignment_shop(shop)
	if jewelry:
		_indexes = _shop.get_jewel_slots()
	else:
		_indexes = _shop.get_dummy_slots() if dummy else _shop.get_weapon_slots()
	var in_use: int = _indexes.filter(func(i: int) -> bool: return _shop.is_active(i)).size()
	_grid.columns = clampi(in_use, 1, 4 if dummy or jewelry else MAX_COLUMNS)
	if jewelry:
		%HintLabel.text = Language.translate("Ringe und Amulette hineinziehen oder Rechtsklick im Inventar. Klick nimmt sie zurück. Alles Gold gehört dir.")
	elif dummy and shop == "house":
		%HintLabel.text = Language.translate("Rüstungsteile anlegen: hineinziehen oder Rechtsklick im Inventar. Klick nimmt sie zurück. Alles Gold gehört dir.")
	elif dummy:
		%HintLabel.text = Language.translate("Rüstungsteile anlegen: hineinziehen oder Rechtsklick im Inventar. Klick nimmt sie zurück. Nina behält %d %%.") % 				roundi(_shop.get_setting("commission", 0.15) * 100.0)
	elif shop == "house":
		%HintLabel.text = Language.translate("Waffen hineinziehen oder Rechtsklick im Inventar. Klick nimmt sie zurück. Alles Gold gehört dir.")
	else:
		%HintLabel.text = Language.translate("Waffen hineinziehen oder Rechtsklick im Inventar. Klick nimmt sie zurück. Nina behält %d %%.") % \
				roundi(_shop.get_setting("commission", 0.15) * 100.0)
	for i: int in _indexes:
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(i), _drop_into.bind(i))
		_slot_uis.append(slot_ui)
	_shop.changed.connect(_refresh)
	GameState.reputation.changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	var bonus: float = GameState.reputation.get_price_bonus()
	for n in _slot_uis.size():
		var i: int = _indexes[n]
		_slot_uis[n].visible = _shop.is_active(i)
		var stack: InventorySlot = _shop.slots[i]
		_slot_uis[n].extra_tooltip = "" if stack.is_empty() else Language.translate("[color=%s]Preis: %d Gold, für dich: %d Gold[/color]") % [
				COLOR_PRICE, _shop.price_of(stack, bonus), _shop.payout_of(stack, bonus)]
		if stack.is_empty() and dummy:
			_slot_uis[n].display_custom(null, ConsignmentShop.get_dummy_name(_shop.slot_types[i]))
		else:
			_slot_uis[n].display(stack)
	var lines: Array[String] = []
	if _shop.pending_gold > 0:
		lines.append((Language.translate("In deiner Kasse: %d Gold") if shop == "house" else Language.translate("Bei Nina abzuholen: %d Gold")) % _shop.pending_gold)
	if _shop.price_bonus > 0.0:
		lines.append(Language.translate("Einrichtung: Preise +%d %%") % roundi(_shop.price_bonus * 100.0))
	var skill_bonus: float = GameState.player_stats.get_sell_price_bonus()
	if skill_bonus > 0.0:
		lines.append(Language.translate("Verkaufstalent: Preise +%d %%") % roundi(skill_bonus * 100.0))
	lines.append(Language.translate("Verkauft wird von %d bis %d Uhr.") % [int(_shop.get_setting("open_from_hour", 6)),
			int(_shop.get_setting("open_until_hour", 20))])
	_status_label.text = "\n".join(lines)


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if not _shop.slots[index].is_empty() and not _shop.take_back(index, GameState.inventory):
			_status_label.text = Language.translate("Kein Platz im Inventar.")


func _can_drop_into(_at_position: Vector2, data: Variant, index: int) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	return _shop.slots[index].is_empty() and _shop.can_place(index, GameState.inventory.slots[data["inventory_index"]])


func _drop_into(_at_position: Vector2, data: Variant, index: int) -> void:
	_shop.place(index, GameState.inventory, data["inventory_index"])


## Right click on a piece in the inventory: onto the first free place of this window that takes it.
func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	var stack: InventorySlot = GameState.inventory.slots[inventory_index]
	for i: int in _indexes:
		if _shop.slots[i].is_empty() and _shop.can_place(i, stack):
			return _shop.place(i, GameState.inventory, inventory_index)
	return false
