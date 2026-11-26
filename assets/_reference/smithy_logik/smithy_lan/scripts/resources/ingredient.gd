class_name Ingredient
extends Resource
## One ingredient of a recipe: a specific item, or (with part_type) any part of that type,
## e.g. "any blade" at the workbench.

@export var item: ItemData
## If set, every item with this part type is accepted and `item` is ignored.
@export var part_type: ItemData.PartType = ItemData.PartType.NONE
## With part_type: only parts of these materials count (e.g. ["wood"]: pickaxes only take the
## wooden shaft). Empty = any material.
@export var materials: Array[String] = []
@export var amount: int = 1
## If not empty, any of these items is accepted (slot of a recipe group, e.g. any crystal for which
## a staff recipe is known); `alternatives_name` is then shown as the slot name.
@export var alternatives: Array[ItemData] = []
@export var alternatives_name: String = "":
	get:
		return Language.translate(alternatives_name)
## Lowest rarity (Rarity.Tier) a piece must have to count, -1 = any (e.g. the crown: gold R3).
@export var min_rarity: int = -1


func matches(other: ItemData) -> bool:
	if other == null:
		return false
	if not alternatives.is_empty():
		return alternatives.has(other)
	if part_type != ItemData.PartType.NONE:
		return other.part_type == part_type and (materials.is_empty() or materials.has(other.material_id))
	return other == item


func get_display_name() -> String:
	var suffix: String = Language.translate(" (ab %s)") % Rarity.get_display_name(min_rarity as Rarity.Tier) if min_rarity >= 0 else ""
	if not alternatives.is_empty():
		return (alternatives_name if alternatives_name != "" else Language.translate("Wahl")) + suffix
	if part_type != ItemData.PartType.NONE:
		if materials.size() == 1:
			return "%s (%s)" % [Language.translate(ItemData.PART_TYPE_NAMES[part_type]), ContentDB.material_name(materials[0])] + suffix
		return Language.translate(ItemData.PART_TYPE_NAMES[part_type]) + suffix
	return item.display_name + suffix


## Icon of the required item, or null for "any part of a type".
func get_icon() -> Texture2D:
	if part_type != ItemData.PartType.NONE or item == null or not alternatives.is_empty():
		return null
	return item.icon
