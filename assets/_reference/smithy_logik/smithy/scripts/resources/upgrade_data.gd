class_name UpgradeData
extends Resource
## What a material does at the upgrade table (items.json "upgrade" of the material, e.g. the
## rat venom fang): which items it fits (weapons, armor, arrows), extra damage of one kind per
## hit and a chance to put a status effect on the target. The values depend on the rarity of
## the material (tiers, e.g. R1: +1-2 poison and 10 %, R2: +2-3 and 15 %); an upgraded item
## remembers the material and its rarity (InventorySlot.upgrade_item / upgrade_rarity).
## Arrows: one material upgrades `arrows_per_use` arrows of a stack (the rest stays as it was).
## Crystals (e.g. ruby) give a resistance instead: `resistance_kind` + tier "resistance"
## (ruby R1: fire +2, i.e. about 2 % less fire damage).

## Name of the upgrade in tooltips, e.g. "Vergiftet".
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## What it fits: "weapon", "armor", "arrows".
@export var targets: Array[String] = []
## DamageKinds id of the extra damage, e.g. "poison".
@export var damage_kind: String = ""
## Status effect id (status_effects.json) the hit can apply, e.g. "poison". Empty = none.
@export var effect_id: String = ""
## Arrows upgraded by one material.
@export var arrows_per_use: int = 99
## DamageKinds id of the resistance it gives (crystals), e.g. "fire". Empty = none.
@export var resistance_kind: String = ""
## Sorted from the lowest tier: [[Rarity.Tier, {"damage_min", "damage_max", "chance", "resistance"}], ...].
## chance = 0..1.
@export var tiers: Array = []


## Whether this upgrade can go onto the item.
func fits(item: ItemData) -> bool:
	if item == null:
		return false
	if item.type == ItemData.ItemType.ARROWS:
		return targets.has("arrows")
	if item.is_weapon():
		return targets.has("weapon")
	if item.is_armor():
		return targets.has("armor")
	return false


## Values for a material of this rarity: the highest tier at or below it (an R3 fang counts as R2).
func get_values(rarity: Rarity.Tier) -> Dictionary:
	var result: Dictionary = {}
	for tier: Array in tiers:
		if tier[0] <= rarity or result.is_empty():
			result = tier[1]
	return result


func get_effect() -> StatusEffectData:
	return ContentDB.status_effect(effect_id) if not effect_id.is_empty() else null


## e.g. "Vergiftet: +1-2 Gift, 10 % Chance auf Gift".
func describe(rarity: Rarity.Tier) -> String:
	var values: Dictionary = get_values(rarity)
	var parts: Array[String] = []
	if int(values.get("damage_max", 0)) > 0:
		parts.append("+%d-%d %s" % [values["damage_min"], values["damage_max"], DamageKinds.get_display_name(damage_kind)])
	var effect: StatusEffectData = get_effect()
	if effect and float(values.get("chance", 0.0)) > 0.0:
		parts.append(Language.translate("%d %% Chance auf %s") % [roundi(values["chance"] * 100.0), effect.display_name])
	if not resistance_kind.is_empty() and float(values.get("resistance", 0.0)) != 0.0:
		parts.append("%s-Resistenz %+d" % [DamageKinds.get_display_name(resistance_kind), roundi(values["resistance"])])
	return "%s: %s" % [display_name, ", ".join(parts)]


## Names of the targets for messages, e.g. "Waffen und Pfeile".
func get_targets_text() -> String:
	var names: Array[String] = []
	for target in targets:
		names.append({"weapon": Language.translate("Waffen"), "armor": Language.translate("Rüstungen"), "arrows": Language.translate("Pfeile")}.get(target, target))
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, names.size() - 1)) + Language.translate(" und ") + names[-1]
