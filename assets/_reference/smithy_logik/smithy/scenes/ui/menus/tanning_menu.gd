class_name TanningMenu
extends StationMenu
## Tanning rack window: one slot for fur (drag a stack in or right-click it in the inventory;
## Ctrl/Shift + right click = 1 piece / half). "Gerben" turns the whole stack into leather of
## the same rarity (see Tanning). Clicking the slot or closing the window puts it back.
## Fur onto finished leather swaps them: the leather goes into the inventory, the fur onto the rack.
## Guide target "tanning:slot": the empty slot glows, then "Gerben" while fur lies on the rack.

## The stack lying on the rack (fur before, leather after tanning; empty = nothing).
var _slot: InventorySlot = InventorySlot.new()

@onready var _slot_ui: ItemSlotUI = %FurSlot
@onready var _info_label: Label = %InfoLabel
@onready var _tan_button: Button = %TanButton


func _ready() -> void:
	super()
	_slot_ui.gui_input.connect(_on_slot_gui_input)
	_slot_ui.drag_out = true
	_slot_ui.set_drag_forwarding(Callable(), _can_drop_into, _drop_into)
	_tan_button.pressed.connect(_on_tan_pressed)
	GuideFrame.attach(_slot_ui, func() -> bool: return _slot.is_empty() and Guide.is_target("tanning:slot"))
	GuideFrame.attach(_tan_button, func() -> bool: return not _tan_button.disabled and Guide.is_target("tanning:slot"))
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _refresh() -> void:
	_slot_ui.display(_slot)
	var blocker: String = Tanning.get_blocker(_slot)
	_tan_button.disabled = blocker != ""
	if blocker != "":
		_info_label.text = blocker
		return
	var result: InventorySlot = Tanning.get_result(_slot)
	_info_label.text = "%d× %s » %d× %s" % [_slot.amount, _slot.get_display_name(),
			result.amount, result.get_display_name()]


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not _can_drop_into(Vector2.ZERO, data):
		return false
	_drop_into(Vector2.ZERO, data)
	return true


## Accepts fur into the empty slot, more of the same fur onto it, or fur in exchange for the
## finished leather lying there.
func _can_drop_into(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	if source.is_empty() or source.item.tan_result == null:
		return false
	return (_slot.is_empty() or _is_tanned()
			or (_slot.can_stack_with(source) and _slot.amount < _slot.item.max_stack))


func _drop_into(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var amount: int = get_move_amount(data, source)
	if _is_tanned():
		_swap_leather(index, amount)
		return
	if _slot.is_empty():
		_slot = source.copy_with_amount(amount)
	else:
		amount = mini(amount, _slot.item.max_stack - _slot.amount)
		_slot.amount += amount
	GameState.inventory.remove_from_slot(index, amount)
	_refresh()


## true if the rack holds finished leather (something that can't be tanned any more).
func _is_tanned() -> bool:
	return not _slot.is_empty() and _slot.item.tan_result == null


## Takes `amount` fur from inventory slot `index` onto the rack and puts the leather into the
## inventory. If the leather doesn't fit, everything stays as it was.
func _swap_leather(index: int, amount: int) -> void:
	var fur: InventorySlot = GameState.inventory.slots[index].copy_with_amount(amount)
	GameState.inventory.remove_from_slot(index, amount)
	if GameState.inventory.get_free_space(_slot) < _slot.amount:
		GameState.inventory.add_stack(fur)
		_info_label.text = Language.translate("Kein Platz im Inventar für das Leder.")
		return
	GameState.inventory.add_stack(_slot)
	_slot = fur
	_refresh()


func _on_tan_pressed() -> void:
	if Tanning.tan(_slot):
		GameState.achievements.count_material(_slot)
		_refresh()
		_info_label.text = Language.translate("Gegerbt: %d× %s.") % [_slot.amount, _slot.get_display_name()]


func _on_slot_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_return_stack()


func _on_visibility_changed() -> void:
	if not visible:
		_return_stack()


## Puts as much of the stack back into the inventory as fits (the rest stays on the rack).
func _return_stack() -> void:
	if _slot.is_empty():
		return
	_slot.amount = GameState.inventory.add_stack(_slot)
	if _slot.amount <= 0:
		_slot = InventorySlot.new()
	_refresh()
