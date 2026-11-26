class_name Tanning
extends RefCounted
## Tanning rack: turns fur into leather (ItemData.tan_result, "tan_to" in items.json).
## The whole stack is tanned at once; the leather keeps amount and rarity of the fur
## (rat fur R2 -> leather R2), one tier better per rank of the skill "Gerber".


## Why this stack can't be tanned ("" = it can).
static func get_blocker(slot: InventorySlot) -> String:
	if slot.is_empty():
		return Language.translate("Leg ein Fell hinein.")
	if slot.item.tan_result == null:
		return Language.translate("Das ist kein Fell.")
	return ""


## The leather `slot` turns into (same amount and rarity). Empty slot if it can't be tanned.
static func get_result(slot: InventorySlot) -> InventorySlot:
	var result := InventorySlot.new()
	if get_blocker(slot) != "":
		return result
	result.item = slot.item.tan_result
	result.amount = slot.amount
	# Skill "Gerber": the leather comes out rarer than the fur.
	var bonus: int = ForgeQuality._game_state().player_stats.get_tan_rarity_bonus()
	result.rarity = mini(slot.rarity + bonus, Rarity.Tier.size() - 1) as Rarity.Tier
	return result


## Turns the fur in `slot` into leather in place. Returns false if it can't be tanned.
static func tan(slot: InventorySlot) -> bool:
	var result: InventorySlot = get_result(slot)
	if result.is_empty():
		return false
	slot.copy_properties_from(result)
	return true
