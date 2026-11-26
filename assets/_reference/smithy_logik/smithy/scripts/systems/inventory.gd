class_name Inventory
extends Resource
## The player's inventory. Slots 0-7 are the hotbar, the rest is the bag. A backpack makes the
## bag bigger (resize, GameState.get_inventory_size).
## Emits the built-in `changed` signal whenever the contents change.

const HOTBAR_SIZE: int = 8
const BAG_SIZE: int = 16

@export var slots: Array[InventorySlot] = []

## Open batches (begin_batch) and whether something changed inside them.
var _batch_depth: int = 0
var _batch_dirty: bool = false


## `size` = number of slots (the player's inventory: hotbar + bag; chests can be bigger).
func _init(size: int = HOTBAR_SIZE + BAG_SIZE) -> void:
	for i in size:
		slots.append(InventorySlot.new())


## Several changes in a row (e.g. the workbench filling all its slots): between begin_batch() and
## end_batch() `changed` is held back and emitted once at the end. Batches can be nested; every
## begin_batch() needs its end_batch(), also on an early return.
func begin_batch() -> void:
	_batch_depth += 1


func end_batch() -> void:
	if _batch_depth == 0:
		push_error("Inventory.end_batch() without begin_batch()")
		return
	_batch_depth -= 1
	if _batch_depth == 0 and _batch_dirty:
		_batch_dirty = false
		emit_changed()


## Use this instead of emit_changed() (which can't be overridden) so batches work.
func _notify_changed() -> void:
	if _batch_depth > 0:
		_batch_dirty = true
	else:
		emit_changed()


## Adds items, filling existing stacks first, then empty slots.
## Rarity -1 = the item's base rarity (from its material).
## Returns how many items did not fit (0 = everything was added).
func add_item(item: ItemData, amount: int = 1, quality: int = 0, rarity: int = -1) -> int:
	var stack := InventorySlot.new()
	stack.item = item
	stack.amount = amount
	stack.quality = quality
	stack.rarity = (item.base_rarity if rarity < 0 else rarity) as Rarity.Tier
	return add_stack(stack)


## Adds a whole stack (keeps quality, rarity and bonus attributes). Fills matching stacks
## first, then empty slots. Returns how many items did not fit (0 = everything was added).
func add_stack(stack: InventorySlot) -> int:
	if stack.is_empty() or stack.amount <= 0:
		# nothing to add (an amount of 0 or less would leave a slot with an item and no pieces)
		return 0
	var max_stack: int = stack.get_max_stack()
	var remaining: int = stack.amount
	for slot in slots:
		if remaining == 0:
			break
		if not slot.is_empty() and slot.can_stack_with(stack) and slot.amount < max_stack:
			var added: int = mini(remaining, max_stack - slot.amount)
			slot.add_from(stack, added)
			remaining -= added
	for slot in slots:
		if remaining == 0:
			break
		if slot.is_empty():
			var added: int = mini(remaining, max_stack)
			slot.copy_properties_from(stack)
			slot.amount = added
			remaining -= added
	if remaining != stack.amount:
		_notify_changed()
	return remaining


## How many items like `stack` (same quality, rarity, attributes) still fit into the inventory.
func get_free_space(stack: InventorySlot) -> int:
	var space: int = 0
	for slot in slots:
		if slot.is_empty():
			space += stack.get_max_stack()
		elif slot.can_stack_with(stack):
			space += stack.item.max_stack - slot.amount
	return space


## Removes items of any quality/rarity, starting from the last slot, and returns what was
## removed as separate stacks (to know their quality, rarity and attributes).
## Removes nothing and returns an empty array if there are not enough.
func take_item(item: ItemData, amount: int = 1) -> Array[InventorySlot]:
	return take_matching(func(other: ItemData) -> bool: return other == item, amount)


## Like take_item(), but takes every item for which `filter` (ItemData -> bool) is true,
## e.g. Ingredient.matches for "any blade". `rarity` >= 0: only stacks of this rarity.
func take_matching(filter: Callable, amount: int = 1, rarity: int = -1, min_rarity: int = -1) -> Array[InventorySlot]:
	var taken: Array[InventorySlot] = []
	if amount <= 0 or count_matching(filter, rarity, min_rarity) < amount:
		return taken
	var remaining: int = amount
	for i in range(slots.size() - 1, -1, -1):
		var slot: InventorySlot = slots[i]
		if remaining == 0:
			break
		if _slot_matches(slot, filter, rarity, min_rarity):
			var removed: int = mini(remaining, slot.amount)
			taken.append(slot.copy_with_amount(removed))
			slot.amount -= removed
			remaining -= removed
			if slot.amount == 0:
				slot.clear()
	_notify_changed()
	return taken


## Removes items of any quality/rarity, starting from the last slot. Removes nothing and
## returns false if there are not enough.
func remove_item(item: ItemData, amount: int = 1) -> bool:
	return not take_item(item, amount).is_empty()


## Removes up to `amount` items from one specific slot.
func remove_from_slot(index: int, amount: int) -> void:
	if amount <= 0:
		return
	var slot: InventorySlot = slots[index]
	slot.amount -= mini(amount, slot.amount)
	if slot.amount == 0:
		slot.clear()
	_notify_changed()


## Moves the contents of slot `from` onto slot `to`: stacks onto the same item as far as
## it fits, otherwise the two slots swap their contents.
func move_slot(from: int, to: int) -> void:
	var source: InventorySlot = slots[from]
	var target: InventorySlot = slots[to]
	if from == to or source.is_empty():
		return
	if not target.is_empty() and target.can_stack_with(source):
		var moved: int = mini(source.amount, source.item.max_stack - target.amount)
		target.add_from(source, moved)
		source.amount -= moved
		if source.amount == 0:
			source.clear()
	else:
		slots[from] = target
		slots[to] = source
	_notify_changed()


func count_item(item: ItemData) -> int:
	return count_matching(func(other: ItemData) -> bool: return other == item)


## Number of items for which `filter` (ItemData -> bool) is true. `rarity` >= 0: only that rarity.
func count_matching(filter: Callable, rarity: int = -1, min_rarity: int = -1) -> int:
	var total: int = 0
	for slot in slots:
		if _slot_matches(slot, filter, rarity, min_rarity):
			total += slot.amount
	return total


## Rarities of the items `filter` accepts, lowest first (e.g. [R1, R2] for copper ingots).
func get_matching_rarities(filter: Callable) -> Array[int]:
	var rarities: Array[int] = []
	for slot in slots:
		if _slot_matches(slot, filter, -1) and not rarities.has(int(slot.rarity)):
			rarities.append(int(slot.rarity))
	rarities.sort()
	return rarities


## `min_rarity`: only pieces of at least this rarity (-1 = any).
func _slot_matches(slot: InventorySlot, filter: Callable, rarity: int, min_rarity: int = -1) -> bool:
	return not slot.is_empty() and filter.call(slot.item) and (rarity < 0 or int(slot.rarity) == rarity) \
			and (min_rarity < 0 or int(slot.rarity) >= min_rarity)


## Sorts the bag (not the hotbar, `first` = first slot that is sorted): equal stacks are merged,
## then ordered by item type, name, rarity (highest first) and quality.
func sort(first: int = HOTBAR_SIZE) -> void:
	var stacks: Array[InventorySlot] = []
	for i in range(first, slots.size()):
		if not slots[i].is_empty():
			stacks.append(slots[i].copy_with_amount(slots[i].amount))
			slots[i].clear()
	stacks.sort_custom(_sorts_before)
	var index: int = first
	for stack in stacks:
		# Merge into the stack before, as far as it fits.
		var previous: InventorySlot = slots[index - 1] if index > first else null
		if previous and previous.can_stack_with(stack) and previous.amount < stack.item.max_stack:
			var moved: int = mini(stack.amount, stack.item.max_stack - previous.amount)
			previous.add_from(stack, moved)
			stack.amount -= moved
		while stack.amount > 0 and index < slots.size():
			# Glowing pieces get one slot each.
			var placed: int = mini(stack.amount, stack.get_max_stack())
			slots[index].copy_properties_from(stack)
			slots[index].amount = placed
			stack.amount -= placed
			index += 1
	_notify_changed()


static func _sorts_before(a: InventorySlot, b: InventorySlot) -> bool:
	if a.item.type != b.item.type:
		return a.item.type < b.item.type
	if a.get_display_name() != b.get_display_name():
		return a.get_display_name() < b.get_display_name()
	if a.rarity != b.rarity:
		return a.rarity > b.rarity
	if a.hot != b.hot:
		return a.hot
	return a.quality > b.quality


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Array:
	var data: Array = []
	for slot in slots:
		data.append(slot.to_save_data())
	return data


## Whether the inventory can shrink to `size` slots: everything in the slots that go away (plus
## `extra` more stacks, e.g. the backpack that is taken off) fits into empty slots below `size`.
## `emptied` = a slot that will be empty by then (e.g. where the new backpack came from).
func can_resize(size: int, extra: int = 0, emptied: int = -1) -> bool:
	var moving: int = extra
	var free: int = 0
	for i in slots.size():
		var empty: bool = slots[i].is_empty() or i == emptied
		if i >= size and not empty:
			moving += 1
		elif i < size and empty:
			free += 1
	return moving <= free


## Grows or shrinks the inventory to `size` slots. Items in slots that go away move into empty
## slots first. Returns the stacks that did not fit anywhere (only when shrinking; the caller
## checks can_resize first, or puts them somewhere else).
func resize(size: int) -> Array[InventorySlot]:
	var left_over: Array[InventorySlot] = []
	if size == slots.size():
		return left_over
	while slots.size() < size:
		slots.append(InventorySlot.new())
	while slots.size() > size:
		var removed: InventorySlot = slots.pop_back()
		if not removed.is_empty():
			left_over.append(removed)
	left_over.reverse()
	var lost: Array[InventorySlot] = []
	for stack in left_over:
		var empty: int = slots.find_custom(func(slot: InventorySlot) -> bool: return slot.is_empty())
		if empty >= 0:
			slots[empty] = stack
		else:
			lost.append(stack)
	_notify_changed()
	return lost


func load_save_data(data: Array) -> void:
	# A save with a backpack has more slots; GameState.update_inventory_size fixes the size after
	# the tools are loaded.
	while slots.size() < data.size():
		slots.append(InventorySlot.new())
	for i in slots.size():
		slots[i] = InventorySlot.from_save_data(data[i]) if i < data.size() else InventorySlot.new()
	_split_oversized_stacks()
	_notify_changed()


## Older saves may have stacks above the item's limit (e.g. stacked swords): the extra pieces
## move into free slots; what does not fit stays in the stack.
func _split_oversized_stacks() -> void:
	for slot in slots:
		if slot.is_empty() or slot.amount <= slot.get_max_stack():
			continue
		for other in slots:
			if slot.amount <= slot.get_max_stack():
				break
			if other.is_empty():
				var moved: int = mini(slot.amount - slot.get_max_stack(), slot.get_max_stack())
				other.copy_properties_from(slot)
				other.amount = moved
				slot.amount -= moved
