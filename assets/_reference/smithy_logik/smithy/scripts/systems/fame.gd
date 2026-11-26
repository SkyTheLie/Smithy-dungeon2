class_name Fame
extends RefCounted
## The smith's fame (docs/BINDUNG.md Paket 4), tab "Ruhm" in the character window. Lives in
## GameState.fame.
## Masterpieces: the best piece of every item type the player ever finished (GameState.item_revealed;
## rarity first, then quality), kept even after it was sold.
## Famous weapons: weapons with a history (InventorySlot.history) that killed the most monsters,
## looked up in the bag, the storage chest and the heroes' hands (get_famous_weapons).

## How many famous weapons the tab lists.
const FAMOUS_COUNT: int = 5

## Item id -> {"name", "rarity", "quality", "day"} of the best piece of that type.
var masterpieces: Dictionary = {}


## A finished piece: kept if it beats the best of its type.
func note_item(slot: InventorySlot, _rarity_up: bool = false) -> void:
	var id: String = String(slot.item.id)
	var best: Dictionary = masterpieces.get(id, {})
	if not best.is_empty() and (int(best["rarity"]) > slot.rarity
			or (int(best["rarity"]) == slot.rarity and int(best["quality"]) >= slot.quality)):
		return
	masterpieces[id] = {"name": slot.get_display_name(), "rarity": int(slot.rarity), "quality": slot.quality,
			"day": GameState.day_cycle.day}


## Masterpieces, rarest first.
func get_masterpieces() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id: String in masterpieces:
		list.append(masterpieces[id])
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["quality"]) > int(b["quality"])))
	return list


## Weapons with kills, most first: [{"slot": InventorySlot, "owner": hero name or ""}].
static func get_famous_weapons(state: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for hero: Hero in state.heroes:
		var weapon: InventorySlot = hero.get_weapon()
		if weapon and not weapon.is_empty() and weapon.get_kills() > 0:
			found.append({"slot": weapon, "owner": hero.display_name})
	for inventory: Inventory in [state.inventory, state.storage_chest]:
		for slot in inventory.slots:
			if not slot.is_empty() and slot.get_kills() > 0:
				found.append({"slot": slot, "owner": ""})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["slot"] as InventorySlot).get_kills() > (b["slot"] as InventorySlot).get_kills())
	return found.slice(0, FAMOUS_COUNT)


func to_save_data() -> Dictionary:
	return {"masterpieces": masterpieces.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	masterpieces = (data.get("masterpieces", {}) as Dictionary).duplicate(true)
