class_name ForgeFire
extends RefCounted
## A fire fed with fuel: how many uses (castings, ores, vials) it still gives. Burning heat (`heat`)
## plus unburned fuel in the heat slot (`fuel`); one piece is lit when the heat runs out.
## The fire of the forge (Esse) lives in GameState.forge_fire, so it is the same at every forge and
## survives scene changes. Every Smelter has its own (Smelter.fire, counts ores by
## ItemData.smelt_charges), the vial table makes one per batch (VialMaking).
## GameState keeps the old names (forge_heat, forge_fuel, get_forge_heat() ...) and passes them on.
## Logic without a scene: what a piece of fuel is worth comes from `charge_factor` (the player's
## skill and the workshop upgrade), the places to take fuel from are handed in.

## Heat or fuel changed; `heat` = castings left in total (get_heat()).
signal heat_changed(heat: int)

## Castings left of the burning piece (wood: 1, coal: 5 per piece, ItemData.heat_charges).
var heat: int = 0
## Part of a casting left over from the last piece (factors like 1.5 per piece add up over time).
var carry: float = 0.0
## Unburned fuel in the heat slot. Can be taken back out (take_fuel_into).
var fuel: InventorySlot = InventorySlot.new()
## () -> float: castings per heat charge of the fuel (skill "Glutwächter" x workshop upgrade); 1 if unset.
var charge_factor: Callable
## (ItemData) -> float: what one piece gives before the factor. Unset = ItemData.heat_charges (the
## forge); the smelter and the vial table count by ItemData.smelt_charges.
var base_charges: Callable


## Castings left in total: the burning piece plus the unburned fuel in the slot.
func get_heat() -> int:
	if fuel.is_empty():
		return heat
	return heat + floori(fuel.amount * get_charges(fuel.item) + carry + 0.001)


## Castings one piece of `item` gives.
func get_charges(item: ItemData) -> float:
	var factor: float = float(charge_factor.call()) if charge_factor.is_valid() else 1.0
	return get_base_charges(item) * factor


## Uses one piece of `item` gives without the factor.
func get_base_charges(item: ItemData) -> float:
	return float(base_charges.call(item)) if base_charges.is_valid() else float(item.heat_charges)


## Whether `item` can go into the heat slot (fuel with heat, same kind as what is there).
func can_add_fuel(item: ItemData) -> bool:
	if item == null or get_base_charges(item) <= 0.0:
		return false
	return fuel.is_empty() or fuel.item == item


## Puts up to `amount` pieces of `stack` into the heat slot (the stack itself is not changed).
## Returns how many were taken.
func add_fuel(stack: InventorySlot, amount: int) -> int:
	if stack.is_empty() or not can_add_fuel(stack.item):
		return 0
	var added: int = mini(amount, stack.item.max_stack - fuel.amount)
	if added <= 0:
		return 0
	if fuel.is_empty():
		fuel.item = stack.item
		fuel.rarity = stack.rarity
	fuel.amount += added
	heat_changed.emit(get_heat())
	return added


## Moves the unburned fuel into `inventory` (whatever does not fit stays in the forge).
func take_fuel_into(inventory: Inventory) -> void:
	if fuel.is_empty():
		return
	var leftover: int = inventory.add_stack(fuel)
	if leftover == 0:
		fuel.clear()
	else:
		fuel.amount = leftover
	heat_changed.emit(get_heat())


## The fuel stack refuel() would use from `sources` (in their order; the one that lasts longest,
## e.g. coal before wood), or null.
func find_fuel(sources: Array[Inventory]) -> InventorySlot:
	var best: InventorySlot = null
	for source in sources:
		for slot in source.slots:
			if not slot.is_empty() and can_add_fuel(slot.item) \
					and (best == null or slot.item.heat_charges > best.item.heat_charges):
				best = slot
	return best


## The forge is cold: puts one piece of fuel from `sources` into the heat slot. Returns false if
## there is none (true if the forge is still hot).
func refuel(sources: Array[Inventory]) -> bool:
	if get_heat() > 0:
		return true
	var best: InventorySlot = find_fuel(sources)
	if best == null:
		return false
	add_fuel(best, 1)
	best.amount -= 1
	if best.amount == 0:
		best.clear()
	for source in sources:
		source.emit_changed()
	return true


## Uses the heat for one casting; lights the next fuel piece if needed.
## Returns false if the forge is cold.
func use_heat() -> bool:
	if heat <= 0 and not fuel.is_empty():
		var charges: float = get_charges(fuel.item) + carry
		heat += floori(charges + 0.001)
		carry = maxf(0.0, charges - floori(charges + 0.001))
		fuel.amount -= 1
		if fuel.amount == 0:
			fuel.clear()
	if heat <= 0:
		return false
	heat -= 1
	heat_changed.emit(get_heat())
	return true
