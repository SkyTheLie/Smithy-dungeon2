class_name Sharpening
extends RefCounted
## Polishing table (economy.json station "polishing_table", SharpenMenu with `polish`): every
## armor piece can be polished once the same way (same minigame, same points, the same mark
## `sharpened`), so armor reaches the same rarity as weapons.
## Every weapon (swords, hammers, bows, staves ... so no weapon type is ahead) can be
## sharpened once in a minigame (SharpeningMinigame): the longer the ball stays green, the more
## quality points (ForgeQuality.grindstone_points, up to economy.json "crafting_quality.grindstone";
## the skill "Meisterhand" adds more and makes the minigame easier). Above 100 the rarity rises
## (ForgeQuality) and the random attributes are rolled again for the new rarity.
## Crystals (ItemData.grind_result, "grind_to" in items.json, e.g. ruby -> cut ruby) are ground
## into a gem for rings, one at a time: the gem has its own rarity (items.json) plus the tiers
## the crystal had above R1 (a ruby R2 gives a cut ruby one tier above its own).


## Why this stack can't be sharpened or ground ("" = it can). `polish` = at the polishing table
## (armor) instead of the grindstone (weapons, crystals).
static func get_blocker(slot: InventorySlot, polish: bool = false) -> String:
	if slot.is_empty():
		return Language.translate("Leg ein Rüstungsteil hinein.") if polish else Language.translate("Leg eine Waffe oder einen Kristall hinein.")
	if polish and not slot.item.is_armor():
		return Language.translate("Polieren kann man nur Rüstungen, Helme und Schilde.")
	if not polish and slot.item.is_armor():
		return Language.translate("Rüstung poliert man am Poliertisch.")
	if is_grindable(slot):
		return ""
	if not (slot.item.is_weapon() or slot.item.is_armor()):
		return Language.translate("Schärfen kann man nur Waffen.")
	if slot.hot:
		return Language.translate("Erst im Wassertrog abkühlen.")
	if slot.sharpened:
		return Language.translate("Wurde schon poliert.") if slot.item.is_armor() else Language.translate("Wurde schon geschärft.")
	return ""


## A crystal that becomes a gem here.
static func is_grindable(slot: InventorySlot) -> bool:
	return not slot.is_empty() and slot.item.grind_result != null


## Whether this item may lie on the grindstone (`polish`: on the polishing table) at all.
static func accepts(item: ItemData, polish: bool = false) -> bool:
	if item == null:
		return false
	return item.is_armor() if polish else (item.is_weapon() or item.grind_result != null)


## Rarity and quality after sharpening with the ball green for `share` (0-1) of the minigame:
## + ForgeQuality.grindstone_points (with the skill "Meisterhand"). Returns {"rarity", "quality"}.
static func get_sharpened(slot: InventorySlot, share: float = 1.0) -> Dictionary:
	var preview: InventorySlot = slot.copy_with_amount(slot.amount)
	ForgeQuality.add(preview, ForgeQuality.grindstone_points(share))
	return {"rarity": preview.rarity, "quality": preview.quality}


## Sharpens the weapon (or polishes the armor piece) in `slot`; `share` (0-1): how long the ball
## stayed green in the minigame.
static func sharpen(slot: InventorySlot, share: float = 1.0) -> bool:
	if slot.is_empty() or get_blocker(slot, slot.item.is_armor()) != "" or is_grindable(slot):
		return false
	ForgeQuality.add(slot, ForgeQuality.grindstone_points(share))
	slot.sharpened = true
	return true


## The gem one crystal of `slot` becomes (one piece). Empty slot if it is no crystal.
static func get_ground(slot: InventorySlot) -> InventorySlot:
	var result := InventorySlot.new()
	if not is_grindable(slot):
		return result
	var gem: ItemData = slot.item.grind_result
	result.item = gem
	result.amount = 1
	result.rarity = mini(gem.base_rarity + slot.rarity, Rarity.Tier.MYTHIC) as Rarity.Tier
	return result


## Grinds the crystal in `slot` (one piece) into its gem, in place. false = it is no crystal.
static func grind(slot: InventorySlot) -> bool:
	if slot.amount != 1:
		return false
	var result: InventorySlot = get_ground(slot)
	if result.is_empty():
		return false
	slot.copy_properties_from(result)
	return true
