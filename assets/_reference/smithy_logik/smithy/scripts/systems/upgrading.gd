class_name Upgrading
extends RefCounted
## Upgrade table: a weapon, armor piece or a stack of arrows (left slot) is upgraded with a
## material (right slot) that has an "upgrade" in items.json (UpgradeData), e.g. a rat venom
## fang: +1-2 poison damage per hit and 10 % chance to poison (R2 fang: +2-3, 15 %); crystals
## (ruby, sapphire ...) give armor and shields a resistance.
## One material is used up per upgrade. Weapons/armor: the item is upgraded. Arrows: only
## UpgradeData.arrows_per_use of the stack (99) are upgraded and split off, the rest stays.
## Every item can only be upgraded once.


## Why this can't be upgraded ("" = it can).
static func get_blocker(target: InventorySlot, material: InventorySlot) -> String:
	if target.is_empty():
		return Language.translate("Leg links eine Waffe, Rüstung oder Pfeile hinein.")
	if not is_upgradeable(target.item):
		return Language.translate("Das lässt sich nicht aufwerten.")
	if target.hot:
		return Language.translate("Erst im Wassertrog abkühlen.")
	if target.upgrade_item:
		return Language.translate("Ist schon aufgewertet (%s).") % target.get_upgrade().display_name
	if material.is_empty():
		return Language.translate("Leg rechts ein Material zum Aufwerten hinein (z. B. einen Kristall).")
	var upgrade: UpgradeData = material.item.upgrade
	if upgrade == null:
		return Language.translate("Damit kann man nichts aufwerten.")
	if not upgrade.fits(target.item):
		return Language.translate("%s wirkt nur auf %s.") % [material.item.display_name, upgrade.get_targets_text()]
	return ""


## Items that can go into the left slot at all.
static func is_upgradeable(item: ItemData) -> bool:
	return item != null and (item.is_weapon() or item.is_armor() or item.type == ItemData.ItemType.ARROWS)


## Materials that can go into the right slot.
static func is_material(item: ItemData) -> bool:
	return item != null and item.upgrade != null


## How many pieces of the target one material upgrades (arrows: up to 30, otherwise 1).
static func get_upgraded_amount(target: InventorySlot, material: InventorySlot) -> int:
	if target.item.type == ItemData.ItemType.ARROWS:
		return mini(target.amount, material.item.upgrade.arrows_per_use)
	return 1


## Upgrades and uses up one material. Returns the upgraded stack: the target itself if all of it
## was upgraded, otherwise a new stack split off the target (the target keeps the rest).
## null = not possible.
static func upgrade(target: InventorySlot, material: InventorySlot) -> InventorySlot:
	if get_blocker(target, material) != "":
		return null
	var amount: int = get_upgraded_amount(target, material)
	var result: InventorySlot = target
	if amount < target.amount:
		result = target.copy_with_amount(amount)
		target.amount -= amount
	result.upgrade_item = material.item
	result.upgrade_rarity = material.rarity
	material.amount -= 1
	if material.amount <= 0:
		material.clear()
	return result
