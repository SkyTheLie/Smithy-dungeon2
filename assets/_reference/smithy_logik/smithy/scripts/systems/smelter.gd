class_name Smelter
extends Resource
## Smelting logic: fuel + 1 ore -> the ore's smelt_result after the ore's smelt_time.
## One piece of fuel smelts ItemData.smelt_charges ores (wood 1, coal 2), times the skill
## "Glutwächter" (PlayerStats.get_fuel_factor). What is left of a burning piece glows on in the
## oven (`heat_left`) and smelts the next ores before new fuel is taken.
## The ingot gets the rarity of the ore (a rare R2 ore gives an R2 ingot); one rarity per slot.
## Fuel and ore are only consumed when a unit finishes. After that the next unit starts
## automatically as long as there is fuel, ore and room in the output slot.
## All units smelted in a row form one batch: remaining time and progress cover the whole batch
## (e.g. 2 ores at 10 s = 20 s), the ingots still come out one by one.
## While smelting, the unit in use stays locked; the rest can be topped up or taken out.
## Emits the built-in `changed` signal whenever slot contents or the smelting state change.

## One unit is done (e.g. one ingot is in the output slot).
signal ingot_finished

## Percent faster smelting (set by GameState: workshop upgrades "smelt_speed"). Not saved.
var speed_bonus: Callable = func() -> float: return 0.0
## Chance (0-1) that one ore gives one ingot more (skill "Feuerprobe", set by GameState).
var extra_chance: Callable = func() -> float: return 0.0

## The fuel in the oven. It is the heat slot of `fire` (the same object).
@export var fuel_slot: InventorySlot = InventorySlot.new():
	set(value):
		fuel_slot = value
		fire.fuel = value
@export var ore_slot: InventorySlot = InventorySlot.new()
@export var output_slot: InventorySlot = InventorySlot.new()
## Duration of the current unit in seconds.
@export var total_time: float = 0.0
## Seconds until the current unit finishes. 0 = not smelting.
@export var time_left: float = 0.0
## Seconds smelted so far in the current batch.
@export var batch_elapsed: float = 0.0
## Ores the burning fuel can still smelt (glow in the oven), e.g. 1 after the first of two coal ores.
## Kept under this name for the save and the window; the value lives in `fire` (heat + carry).
var heat_left: float:
	get:
		return fire.heat + fire.carry
	set(value):
		fire.heat = floori(value + HEAT_EPSILON)
		fire.carry = maxf(0.0, value - fire.heat)

## The fire of this oven (ForgeFire): what is burning and the fuel in the slot. One piece smelts
## ItemData.smelt_charges ores, times the skill "Glutwächter".
var fire: ForgeFire = _make_fire()

## Rounding margin for heat_left.
const HEAT_EPSILON: float = 0.001


func is_smelting() -> bool:
	return time_left > 0.0


## Seconds until the whole batch is done (current unit + every unit that can follow it).
func get_batch_time_left() -> float:
	if not is_smelting():
		return 0.0
	return time_left + _get_queued_units() * get_unit_time(ore_slot.item)


## Progress of the whole batch from 0.0 (just started) to 1.0 (done). 0.0 when idle.
## Topping up ore or fuel while smelting makes the batch longer, so the progress goes back a bit.
func get_progress() -> float:
	var total: float = batch_elapsed + get_batch_time_left()
	if not is_smelting() or total <= 0.0:
		return 0.0
	return batch_elapsed / total


func _make_fire() -> ForgeFire:
	var result := ForgeFire.new()
	result.fuel = fuel_slot
	result.base_charges = func(item: ItemData) -> float: return float(item.smelt_charges)
	result.charge_factor = func() -> float: return GameState.player_stats.get_fuel_factor()
	return result


## Whether `item` (of this `rarity`, -1 = any) may be put into `slot` (fuel_slot or ore_slot).
func can_insert(slot: InventorySlot, item: ItemData, rarity: int = -1) -> bool:
	return accepts(slot, item) and _fits_stack(slot, item, rarity)


## Whether `item` belongs into `slot` at all, whatever lies there now (fuel or smeltable ore;
## the selection list of the window, SmelterMenu).
func accepts(slot: InventorySlot, item: ItemData) -> bool:
	if item == null:
		return false
	if slot == fuel_slot:
		return item.type == ItemData.ItemType.FUEL
	if slot == ore_slot:
		return item.smelt_result != null
	return false


## Whether `item` in `slot` goes with what the other inputs hold (normal smelter: always).
func goes_with_others(_slot: InventorySlot, _item: ItemData) -> bool:
	return true


## An empty slot takes anything; a filled one only the same item with the same rarity (fuel: any).
func _fits_stack(slot: InventorySlot, item: ItemData, rarity: int) -> bool:
	if slot.is_empty():
		return true
	return slot.item == item and (rarity < 0 or slot == fuel_slot or slot.rarity == rarity)


## Puts up to `amount` items (of this `rarity`) into `slot`. Returns how many were inserted.
func insert(slot: InventorySlot, item: ItemData, amount: int, rarity: int = 0) -> int:
	if not can_insert(slot, item, rarity):
		return 0
	var inserted: int = mini(amount, item.max_stack - slot.amount)
	if slot.is_empty():
		slot.rarity = rarity as Rarity.Tier
	slot.item = item
	slot.amount += inserted
	emit_changed()
	return inserted


## Moves the contents of `slot` into `inventory`. While smelting, one fuel and one ore
## stay in their slots because they are in use. Whatever does not fit stays in the slot.
func take_into(slot: InventorySlot, inventory: Inventory) -> void:
	var in_use: int = 1 if is_smelting() and slot != output_slot else 0
	if slot == fuel_slot and has_glow():
		# The running ore burns on the glow, no fuel piece is in use.
		in_use = 0
	var amount: int = slot.amount - in_use
	if slot.is_empty() or amount <= 0:
		return
	var leftover: int = inventory.add_stack(slot.copy_with_amount(amount))
	slot.amount -= amount - leftover
	if slot.amount <= 0:
		slot.clear()
	emit_changed()


## The oven still glows enough for one more ore without new fuel.
func has_glow() -> bool:
	return fire.heat >= 1


## Glow or fuel for at least one ore.
func has_heat() -> bool:
	return has_glow() or not fuel_slot.is_empty()


## How many ores the glow and the fuel in the slot can smelt in total.
func get_heat_units() -> int:
	return fire.get_heat()


## One ore is done: it burns on the glow, or a new piece of fuel is lit for it.
func _burn_for_one_unit() -> void:
	fire.use_heat()


func can_start() -> bool:
	if is_smelting() or not has_heat() or ore_slot.is_empty():
		return false
	var result: ItemData = ore_slot.item.smelt_result
	return output_slot.is_empty() or (output_slot.item == result and output_slot.rarity == ore_slot.rarity
			and output_slot.amount < result.max_stack)


## Starts a new batch.
func start() -> void:
	if not can_start():
		return
	batch_elapsed = 0.0
	_start_unit()


func tick(delta: float) -> void:
	if not is_smelting():
		return
	batch_elapsed += minf(delta, time_left)
	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		_finish()


## Seconds one unit of `ore` needs: its smelt_time, faster with the workshop upgrades.
func get_unit_time(ore: ItemData) -> float:
	return ore.smelt_time / (1.0 + maxf(0.0, float(speed_bonus.call())) / 100.0)


func _start_unit() -> void:
	total_time = get_unit_time(ore_slot.item)
	time_left = total_time
	emit_changed()


func _finish() -> void:
	output_slot.item = ore_slot.item.smelt_result
	output_slot.rarity = ore_slot.rarity
	output_slot.amount += 1
	if output_slot.amount < output_slot.item.max_stack and randf() < float(extra_chance.call()):
		output_slot.amount += 1
	ingot_finished.emit()
	_burn_for_one_unit()
	_consume_one(ore_slot)
	emit_changed()
	# Keep going (same batch) while fuel and ore are left.
	if can_start():
		_start_unit()


## How many more units can be smelted after the current one with the fuel, ore and output room left.
func _get_queued_units() -> int:
	var result: ItemData = ore_slot.item.smelt_result
	var room: int = result.max_stack - output_slot.amount - 1
	return maxi(mini(mini(ore_slot.amount, get_heat_units()) - 1, room), 0)


func _consume_one(slot: InventorySlot) -> void:
	slot.amount -= 1
	if slot.amount <= 0:
		slot.clear()


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {
		"fuel": fuel_slot.to_save_data(),
		"ore": ore_slot.to_save_data(),
		"output": output_slot.to_save_data(),
		"total_time": total_time,
		"time_left": time_left,
		"batch_elapsed": batch_elapsed,
		"heat_left": heat_left,
	}


func load_save_data(data: Dictionary) -> void:
	fuel_slot = InventorySlot.from_save_data(data.get("fuel", {}))
	ore_slot = InventorySlot.from_save_data(data.get("ore", {}))
	output_slot = InventorySlot.from_save_data(data.get("output", {}))
	total_time = float(data.get("total_time", 0.0))
	time_left = float(data.get("time_left", 0.0))
	batch_elapsed = float(data.get("batch_elapsed", 0.0))
	heat_left = float(data.get("heat_left", 0.0))
	# A unit can only be running if its fuel (or glow) and ore are still there.
	if time_left > 0.0 and (not has_heat() or ore_slot.is_empty()):
		time_left = 0.0
	emit_changed()
