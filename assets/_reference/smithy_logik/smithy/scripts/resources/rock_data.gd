class_name RockData
extends Resource
## A kind of mineable rock (coal, iron, copper ...). One .tres per kind in res://data/rocks/.

enum Tool { PICKAXE, AXE, HAND }

@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## How it is farmed: ore with the pickaxe (mining damage), trees with the axe (chopping
## damage), plants by hand (one press).
@export var tool: Tool = Tool.PICKAXE
## Placeholder color of the rock until there is a sprite.
@export var color: Color = Color(0.5, 0.5, 0.5)
## Sprite of the rock (bottom centre = rock position). Without one, a block in `color` is shown.
@export var texture: Texture2D
@export var max_health: int = 10
## Item the player gets when the rock breaks.
## Story flag that must be set before this rock can appear ("" = always).
@export var required_flag: String = ""
@export var drop_item_id: String = ""
@export var drop_amount: int = 1
## Chance that the drop is one rarity tier better than the item's own (e.g. hemp: 0.1 = 10 % R2).
@export_range(0.0, 1.0) var better_rarity_chance: float = 0.0
## Fixed rarity chances of the drop, one per tier starting at R1 (e.g. old mine: [0, 0.5, 0.3, 0.2]
## = 50 % R2, 30 % R3, 20 % R4). Replaces the item's own rarity; empty = not used.
@export var rarity_chances: Array[float] = []
## Optional extra drop with a chance per break (e.g. tree: feather, 0.07 = 7 %).
@export var bonus_drop_item_id: String = ""
@export_range(0.0, 1.0) var bonus_drop_chance: float = 0.0
## Optional rare drop with a chance per break: one of these items at random (e.g. iron: crystals).
@export var rare_drop_item_ids: Array[String] = []
@export_range(0.0, 1.0) var rare_drop_chance: float = 0.0
## How often this rock appears compared to others (higher = more often).
@export var spawn_weight: float = 1.0


func get_drop_item() -> ItemData:
	return ContentDB.item(drop_item_id)


## null if this resource has no bonus drop.
func get_bonus_drop_item() -> ItemData:
	return ContentDB.item(bonus_drop_item_id) if not bonus_drop_item_id.is_empty() else null


## Rarity tier rolled from `rarity_chances`, -1 if the rock has none.
func roll_rarity() -> int:
	var roll: float = randf()
	for tier in rarity_chances.size():
		roll -= rarity_chances[tier]
		if roll < 0.0:
			return tier
	return rarity_chances.size() - 1 if not rarity_chances.is_empty() else -1
