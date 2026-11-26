class_name VialMenu
extends StationMenu
## Vial table window: one slot for sand, one for fuel (drag a stack in or right-click it in the
## inventory; Ctrl/Shift + right click = 1 piece / half). "Phiolen blasen" turns as much sand as
## the fuel allows into vials, which go straight into the inventory (see VialMaking).
## Clicking a slot or closing the window puts its stack back.

## The stacks lying on the table (empty = nothing).
var _sand: InventorySlot = InventorySlot.new()
var _fuel: InventorySlot = InventorySlot.new()

@onready var _sand_ui: ItemSlotUI = %SandSlot
@onready var _fuel_ui: ItemSlotUI = %FuelSlot
@onready var _info_label: Label = %InfoLabel
@onready var _make_button: Button = %MakeButton


func _ready() -> void:
	super()
	for slot_ui: ItemSlotUI in [_sand_ui, _fuel_ui]:
		var is_fuel: bool = slot_ui == _fuel_ui
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(is_fuel))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(is_fuel), _drop_into.bind(is_fuel))
	_make_button.pressed.connect(_on_make_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _refresh() -> void:
	_sand_ui.display(_sand)
	_fuel_ui.display(_fuel)
	var blocker: String = VialMaking.get_blocker(_sand, _fuel)
	_make_button.disabled = blocker != ""
	if blocker != "":
		_info_label.text = blocker
		return
	var result: InventorySlot = VialMaking.get_result(_sand, _fuel)
	_info_label.text = "%d× %s » %d× %s" % [result.amount, _sand.get_display_name(),
			result.amount, result.get_display_name()]


## Right click in the inventory: fuel goes onto the fuel slot, everything else onto the sand slot.
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	for is_fuel: bool in [true, false]:
		if _can_drop_into(Vector2.ZERO, data, is_fuel):
			_drop_into(Vector2.ZERO, data, is_fuel)
			return true
	return false


func _get_slot(is_fuel: bool) -> InventorySlot:
	return _fuel if is_fuel else _sand


## Sand (something with vial_to) onto the sand slot, fuel onto the fuel slot; onto an empty slot
## or more of the same stack.
func _can_drop_into(_at_position: Vector2, data: Variant, is_fuel: bool) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	if source.is_empty():
		return false
	if is_fuel and source.item.type != ItemData.ItemType.FUEL:
		return false
	if not is_fuel and source.item.vial_result == null:
		return false
	var target: InventorySlot = _get_slot(is_fuel)
	return target.is_empty() or (target.can_stack_with(source) and target.amount < target.item.max_stack)


func _drop_into(_at_position: Vector2, data: Variant, is_fuel: bool) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var amount: int = get_move_amount(data, source)
	var target: InventorySlot = _get_slot(is_fuel)
	if target.is_empty():
		target.copy_properties_from(source)
		target.amount = amount
	else:
		amount = mini(amount, target.item.max_stack - target.amount)
		target.amount += amount
	GameState.inventory.remove_from_slot(index, amount)
	_refresh()


func _on_make_pressed() -> void:
	var result: InventorySlot = VialMaking.get_result(_sand, _fuel)
	if result.is_empty():
		return
	if GameState.inventory.get_free_space(result) < result.amount:
		_info_label.text = Language.translate("Kein Platz im Inventar für die Phiolen.")
		return
	result = VialMaking.make(_sand, _fuel)
	GameState.inventory.add_stack(result)
	_refresh()
	_info_label.text = Language.translate("Geblasen: %d× %s.") % [result.amount, result.get_display_name()]


func _on_slot_gui_input(event: InputEvent, is_fuel: bool) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_return_stack(_get_slot(is_fuel))
		_refresh()


func _on_visibility_changed() -> void:
	if not visible:
		_return_stack(_sand)
		_return_stack(_fuel)
		_refresh()


## Puts as much of `slot` back into the inventory as fits (the rest stays on the table).
func _return_stack(slot: InventorySlot) -> void:
	if slot.is_empty():
		return
	slot.amount = GameState.inventory.add_stack(slot)
	if slot.amount <= 0:
		slot.clear()
