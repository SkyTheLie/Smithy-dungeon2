class_name AlloySmelter
extends Smelter
## Alloy tab of the smelter: two input slots (ore_slot + second_slot), one fuel slot, one output.
## Fuel (like the Smelter: coal lasts for 2 alloys, glow carries over) + the amounts of an alloy recipe (items.json "alloy", e.g. bronze = 1 copper ingot +
## 1 iron ingot) -> 1 alloy ingot after the alloy's smelt_time. Works like the normal Smelter
## (batches, fuel/inputs consumed when a unit is done), only the recipe lookup differs.
## Runs on its own next to the normal smelting (GameState.alloy_smelter). The alloy gets the
## lower rarity of its two inputs.

@export var second_slot: InventorySlot = InventorySlot.new()


## The alloy the two inputs make (null = none, e.g. a slot is empty).
func get_alloy() -> ItemData:
	return ContentDB.find_alloy(ore_slot.item, second_slot.item)


func get_batch_time_left() -> float:
	if not is_smelting():
		return 0.0
	return time_left + _get_queued_units() * get_unit_time(get_alloy())


## Inputs take items that are part of an alloy; one item kind per slot.
func accepts(slot: InventorySlot, item: ItemData) -> bool:
	if item == null:
		return false
	if slot == fuel_slot:
		return super(slot, item)
	if slot != ore_slot and slot != second_slot:
		return false
	return ContentDB.is_alloy_ingredient(item)


## An input goes with the other one if the other is empty or both make an alloy (e.g. platinum
## ingot + soul shard); fuel always.
func goes_with_others(slot: InventorySlot, item: ItemData) -> bool:
	if slot != ore_slot and slot != second_slot:
		return true
	var other: InventorySlot = second_slot if slot == ore_slot else ore_slot
	return other.is_empty() or ContentDB.find_alloy(item, other.item) != null


## Rarity of the alloy: the lower one of the two inputs.
func get_alloy_rarity() -> Rarity.Tier:
	return mini(ore_slot.rarity, second_slot.rarity) as Rarity.Tier


func can_start() -> bool:
	if is_smelting() or not has_heat():
		return false
	var alloy: ItemData = get_alloy()
	if alloy == null or not _has_inputs_for(alloy, 1):
		return false
	return output_slot.is_empty() or (output_slot.item == alloy and output_slot.rarity == get_alloy_rarity()
			and output_slot.amount < alloy.max_stack)


func _start_unit() -> void:
	total_time = get_unit_time(get_alloy())
	time_left = total_time
	emit_changed()


func _finish() -> void:
	var alloy: ItemData = get_alloy()
	output_slot.item = alloy
	output_slot.rarity = get_alloy_rarity()
	output_slot.amount += 1
	ingot_finished.emit()
	_burn_for_one_unit()
	for slot: InventorySlot in [ore_slot, second_slot]:
		for i in alloy.alloy_ingredients.get(slot.item, 0):
			_consume_one(slot)
	emit_changed()
	if can_start():
		_start_unit()


func _get_queued_units() -> int:
	var alloy: ItemData = get_alloy()
	if alloy == null:
		return 0
	var units: int = get_heat_units()
	for slot: InventorySlot in [ore_slot, second_slot]:
		units = mini(units, floori(slot.amount / float(alloy.alloy_ingredients.get(slot.item, 1))))
	var room: int = alloy.max_stack - output_slot.amount - 1
	return maxi(mini(units - 1, room), 0)


func _has_inputs_for(alloy: ItemData, units: int) -> bool:
	for slot: InventorySlot in [ore_slot, second_slot]:
		if slot.amount < int(alloy.alloy_ingredients.get(slot.item, 1)) * units:
			return false
	return true


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	var data: Dictionary = super()
	data["second"] = second_slot.to_save_data()
	return data


func load_save_data(data: Dictionary) -> void:
	second_slot = InventorySlot.from_save_data(data.get("second", {}))
	super(data)
	if time_left > 0.0 and get_alloy() == null:
		time_left = 0.0
		emit_changed()
