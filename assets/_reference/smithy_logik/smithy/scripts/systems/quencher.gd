class_name Quencher
extends Resource
## Water trough: cools glowing items (InventorySlot.hot), e.g. a freshly forged blade.
## An item put into the slot starts hissing right away; after `cool_time` seconds the whole
## stack is cool and can be taken out. Lives in GameState (ticked there) like the smelter.

## Seconds until a stack is cool.
@export var cool_time: float = 2.0
@export var slot: InventorySlot = InventorySlot.new()
## Seconds until the stack in the slot is cool. 0 = not cooling.
@export var time_left: float = 0.0
## Quality points a piece gains when it is cool (skill "Härtekunst", set by GameState).
var quality_bonus: Callable = func() -> int: return 0


func is_cooling() -> bool:
	return time_left > 0.0


## Progress of the cooling from 0.0 (just put in) to 1.0 (cool).
func get_progress() -> float:
	if not is_cooling():
		return 1.0 if not slot.is_empty() else 0.0
	return 1.0 - time_left / cool_time


## Only glowing items, and only into an empty trough (one stack at a time).
func can_insert(stack: InventorySlot) -> bool:
	return slot.is_empty() and not stack.is_empty() and stack.hot


## A glowing stack can replace a cooled one (swap_in): the trough is done cooling.
func can_swap(stack: InventorySlot) -> bool:
	return not slot.is_empty() and not is_cooling() and not stack.is_empty() and stack.hot


## Swap: up to `amount` pieces (-1 = all) of the inventory slot `index` go in, the cooled stack
## goes into the inventory (also into the slot the glowing stack came from, if it moved
## completely). Returns false (nothing changes) if there is no room for the cooled stack.
func swap_in(inventory: Inventory, index: int, amount: int = -1) -> bool:
	var stack: InventorySlot = inventory.slots[index]
	if not can_swap(stack):
		return false
	var taken: int = stack.amount if amount < 0 else mini(amount, stack.amount)
	var room: int = inventory.get_free_space(slot) + (slot.item.max_stack if taken == stack.amount else 0)
	if room < slot.amount:
		return false
	var cooled: InventorySlot = slot.copy_with_amount(slot.amount)
	slot.clear()
	insert(stack, taken)
	inventory.remove_from_slot(index, taken)
	inventory.add_stack(cooled)
	return true


## Puts up to `amount` pieces of the stack (-1 = all) into the trough and starts cooling.
## Returns how many were taken.
func insert(stack: InventorySlot, amount: int = -1) -> int:
	if not can_insert(stack):
		return 0
	var taken: int = stack.amount if amount < 0 else mini(amount, stack.amount)
	slot.copy_properties_from(stack)
	slot.amount = taken
	time_left = cool_time
	emit_changed()
	return taken


## Moves the cooled stack into the inventory (not possible while it is still cooling).
func take_into(inventory: Inventory) -> void:
	if slot.is_empty() or is_cooling():
		return
	var leftover: int = inventory.add_stack(slot)
	if leftover == 0:
		slot.clear()
	else:
		slot.amount = leftover
	emit_changed()


func tick(delta: float) -> void:
	if not is_cooling():
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		slot.hot = false
		var bonus: int = int(quality_bonus.call())
		if bonus > 0:
			ForgeQuality.add(slot, bonus)
		emit_changed()


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"slot": slot.to_save_data(), "time_left": time_left}


func load_save_data(data: Dictionary) -> void:
	slot = InventorySlot.from_save_data(data.get("slot", {}))
	time_left = float(data.get("time_left", 0.0)) if not slot.is_empty() else 0.0
	emit_changed()
