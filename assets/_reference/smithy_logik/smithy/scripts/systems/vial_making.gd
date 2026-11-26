class_name VialMaking
extends RefCounted
## Vial table: blows sand into vials (ItemData.vial_result, "vial_to" in items.json).
## 1 sand = 1 vial (same rarity). The heat comes from fuel like in the smelter: one piece makes
## as many vials as it smelts ores (ItemData.smelt_charges: wood 1, coal 2). As many vials as
## sand and fuel allow are made at once. The burning is the same ForgeFire as forge and smelter,
## made anew for each batch: what is left of a started piece is gone, no skill counts here.


## Why nothing can be made from these stacks ("" = it can).
static func get_blocker(sand: InventorySlot, fuel: InventorySlot) -> String:
	if sand.is_empty():
		return Language.translate("Leg Sand hinein.")
	if sand.item.vial_result == null:
		return Language.translate("Daraus wird keine Phiole.")
	if fuel.is_empty():
		return Language.translate("Leg Holz oder Kohle zum Heizen hinein.")
	if fuel.item.type != ItemData.ItemType.FUEL:
		return Language.translate("Das brennt nicht.")
	return ""


## A fire that burns `fuel` (the slot itself): every piece gives at least one vial.
static func _fire_on(fuel: InventorySlot) -> ForgeFire:
	var fire := ForgeFire.new()
	fire.base_charges = func(item: ItemData) -> float: return float(maxi(item.smelt_charges, 1))
	fire.fuel = fuel
	return fire


## How many vials `sand` and `fuel` make (0 = none).
static func get_count(sand: InventorySlot, fuel: InventorySlot) -> int:
	if get_blocker(sand, fuel) != "":
		return 0
	return mini(sand.amount, _fire_on(fuel).get_heat())


## How many pieces of fuel making `count` vials burns (a started piece counts whole).
static func get_fuel_needed(fuel: InventorySlot, count: int) -> int:
	var fire: ForgeFire = _fire_on(fuel.copy_with_amount(fuel.amount))
	var before: int = fire.fuel.amount
	for i in count:
		if not fire.use_heat():
			break
	return before - fire.fuel.amount


## The vials `sand` and `fuel` make (empty slot if none).
static func get_result(sand: InventorySlot, fuel: InventorySlot) -> InventorySlot:
	var result := InventorySlot.new()
	var count: int = get_count(sand, fuel)
	if count <= 0:
		return result
	result.item = sand.item.vial_result
	result.amount = count
	result.rarity = sand.rarity
	return result


## Takes the sand and fuel for get_result out of the two stacks and returns the vials.
## Empty slot (and nothing taken) if nothing can be made.
static func make(sand: InventorySlot, fuel: InventorySlot) -> InventorySlot:
	var result: InventorySlot = get_result(sand, fuel)
	if result.is_empty():
		return result
	var burnt: int = get_fuel_needed(fuel, result.amount)
	sand.amount -= result.amount
	if sand.amount <= 0:
		sand.clear()
	fuel.amount -= burnt
	if fuel.amount <= 0:
		fuel.clear()
	return result
