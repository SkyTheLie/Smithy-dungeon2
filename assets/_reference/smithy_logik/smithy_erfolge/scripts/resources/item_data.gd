class_name ItemData
extends Resource
## Static definition of an item type (e.g. "Iron Ore"). Created by ContentDB from
## res://data/content/items.json (format: docs/CONTENT.md); referenced everywhere by `id`.
## Composed items (e.g. a sword) store their parts per item in InventorySlot.components;
## their icon, name and stats are built from those parts.

## PART = intermediate product that gets assembled (e.g. blade, handle).
## ARMOR, HELMET, BOOTS are armor pieces (show armor instead of damage).
## New types must be appended at the end, existing .tres files store the number.
## PICKAXE, GLOVES, BACKPACK, SHOES = the player's tool slots (character window); SHOULDERS ... SHIELD
## and BOOTS = hero equipment slots (boots are for heroes, shoes only for the smith). New types only at the end (saves and JSON use the names, not numbers).
enum ItemType { MATERIAL, FUEL, ORE, INGOT, WEAPON, ARMOR, ACCESSORY, PART, HELMET, BOOTS, PICKAXE,
		SHOULDERS, CLOAK, LEGS, NECKLACE, RING, SHIELD, GLOVES, BACKPACK, SHOES, ARROWS, QUIVER, LUMBER_AXE,
		WATERING_CAN }

## Which slot a part fills in a composed item. New types must be appended at the end.
enum PartType { NONE, BLADE, HANDLE, AXE_HEAD, SHAFT, DAGGER_BLADE, GREATSWORD_BLADE, SPEAR_HEAD,
		HAMMER_HEAD, MACE_HEAD, GREATAXE_HEAD, SHIELD_PLATE, PICKAXE_HEAD, CHEST_PLATE, HELMET_PLATE,
		SHOULDER_PLATE, BOOT_PLATE, GLOVE_PLATE, LEATHER,
		BOW_FRAME, LONGBOW_FRAME, ARROW_TIP, ARROW_SHAFT, STAFF_ROD, LUMBER_AXE_HEAD,
		RING_BAND, GEM, LEG_PLATE, BACKPACK_FRAME, FLETCHING, AMULET_BAND, CAN_BODY,
		COMPASS_CASE, COMPASS_NEEDLE, COMPASS_ROSE, COMPASS_LID }

const PART_TYPE_NAMES: Array[String] = ["", "Klinge", "Griff", "Axtkopf", "Stiel", "Dolchklinge",
		"Zweihandklinge", "Speerspitze", "Hammerkopf", "Keulenkopf", "Zweihandaxtkopf", "Schildplatte",
		"Spitzhackenkopf", "Brustplatte", "Helmschale", "Schulterplatte", "Stiefelplatte", "Handschuhplatte", "Leder",
		"Bogenrahmen", "Langbogenrahmen", "Pfeilspitze", "Pfeilschaft", "Zauberstab-Kern", "Holzfälleraxtkopf",
		"Ringfassung", "Edelstein", "Beinplatte", "Rucksackgestell", "Befiederung", "Amulettfassung", "Kannenkörper",
		"Kompassgehäuse", "Kompassnadel", "Windrose", "Kompassdeckel"]

## Unique name in items.json, e.g. "iron_blade" (also used in save files).
@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
@export var type: ItemType = ItemType.MATERIAL
## Rarity of a new piece of this item (all materials are R1; rarer pieces come from finds,
## merchants and good forging, see ForgeQuality).
@export var base_rarity: Rarity.Tier = Rarity.Tier.COMMON
## Tier of the material (materials.json "tier": wood 0, copper 1, iron 2, bronze 3, silver 4,
## gold 5, platinum 6, palladium 7; leather and feathers like their metal): order prices and how hard the minigames are (ForgeQuality).
@export var material_tier: int = 0
## Needed by the story (items.json "story_item"): can not be thrown away.
@export var story_item: bool = false
## Silhouette of its mold when it is no part (items.json "mold_shape", e.g. "spear_head" for the
## harpoon tip; a file name in assets/sprites/molds/).
@export var mold_shape: String = ""
## Part made only for a quest (items.json "quest_part", e.g. the desert compass): its mold is listed
## below the copper molds in the character window.
@export var quest_part: bool = false
## Part whose mold is only a prize of the league tournaments (items.json "tournament_part", e.g. the
## tournament blades): never a random mold from dungeons.
@export var tournament_part: bool = false
## How much money (gold) the item is worth.
@export var value: int = 1
## Fixed price a merchant pays for one R1 piece (items.json "sell_price"); -1 = from the value
## (Economy.get_sell_price). Each rarity tier above R1 multiplies it by sell_price_factor.
@export var sell_price: int = -1
## Factor per rarity tier for sell_price (items.json "sell_price_factor"); 0 = economy.json
## prices.sell_price_factor.
@export var sell_price_factor: float = 0.0
## Icon shown everywhere (slots, lists ...): the picture moved into the middle of its canvas.
@export var icon: Texture2D
## The picture as drawn, at its place on the canvas (e.g. a pickaxe head at the top, where it sits
## on the pickaxe): ItemIcons.compose layers these into the icon of a composed item. Empty = icon.
@export var layer_icon: Texture2D
## How many of this item fit into one inventory slot.
@export var max_stack: int = 99
## Item this one turns into in the smelter (e.g. ore -> ingot). Empty = not smeltable.
@export var smelt_result: ItemData
## Seconds it takes to smelt this item into smelt_result (alloys: to make one of this item).
@export var smelt_time: float = 10.0
## Seeds (items.json "plant"): what grows from it in a plant bed, after how many days, how many.
@export var grows_into: ItemData
@export var grow_days: int = 3
@export var harvest_amount: int = 1
## Picture of the ready plant in the bed (empty = the icon of grows_into).
@export var bloom_texture: Texture2D
## Pictures of the growing plant, from seedling to bud (items.json "plant": {"stages": [...]}); empty
## = the shared sprout and growing pictures of Planter.
@export var stage_textures: Array[Texture2D] = []
## Harvested on a full moon (GameCalendar.is_full_moon) the crop is one rarity tier better
## (items.json "plant": {"full_moon": true}, the moon lily).
@export var full_moon_bonus: bool = false
## Soil for the plant pots in the greenhouse (items.json "soil": true, see Garden).
@export var is_soil: bool = false
## Better soil (items.json "soil_bonus"): rarity tiers more for every harvest from this pot; the
## whole part always, the rest as a chance (0.5 = half the harvests one tier better, 1.5 = one tier,
## half of them two). See Garden.get_soil_tiers.
@export var soil_bonus: float = 0.0
## Alloys (e.g. bronze): ItemData -> amount needed in the smelter's alloy tab, e.g. 1 copper ingot +
## 1 iron ingot. Empty = not an alloy.
@export var alloy_ingredients: Dictionary = {}
## Item this one turns into at the tanning rack (fur -> leather). Empty = can't be tanned.
@export var tan_result: ItemData
## Item this one turns into at the vial table (sand -> vial, "vial_to"). Empty = none.
@export var vial_result: ItemData
## Item this one turns into at the grindstone (crystal -> cut gem for rings, "grind_to"). Empty = none.
@export var grind_result: ItemData
## Own pattern for the anvil minigame (id in forging_patterns.json, e.g. for unique items);
## empty = the pattern of its part type (ContentDB.forging_pattern_for).
@export var forging_pattern: String = ""
## Fuel for the forge: how many castings one piece heats (wood 1, coal 5). 0 = no forge fuel.
@export var heat_charges: int = 0
## Fuel in the smelter: how many ores one piece smelts (wood 1, coal 2).
@export var smelt_charges: int = 1
## Materials for the upgrade table (e.g. rat venom fang): what they do to weapons/arrows. null = none.
@export var upgrade: UpgradeData
## Quivers: how many stacks of arrows fit in (InventorySlot.contents), e.g. leather quiver 2.
@export var quiver_slots: int = 0
## Crystals for the jewel table (items.json "jewel"): effects a ring / an amulet with this crystal
## can get, {"ring": {stat: value at R1}, "amulet": {...}} (see Jewelry). Empty = no jewel crystal.
@export var jewel_effects: Dictionary = {}

@export_group("Part")
## Set for parts of composed items (e.g. BLADE). NONE = not a part.
@export var part_type: PartType = PartType.NONE
## Material word for the name of composed items: "Eisen" + "Schwert" -> "Eisenschwert".
@export var material_name: String = "":
	get:
		return Language.translate(material_name)
## Material id from materials.json ("copper"); its "colors" tint visible equipment in fights.
@export var material_id: String = ""
## Draw order when the part icons are layered into the icon of the composed item
## (higher = on top). All parts of one item kind are drawn on the same canvas.
@export var layer_order: int = 0
## true = the item always shows its own icon, even when it remembers parts (e.g. an iron staff
## whose crystal is no part: the icon of the rod alone would hide the element).
@export var own_icon: bool = false
## Icon per built-in part instead of the layered one: part item id -> icon (items.json
## "part_icons", e.g. the leather cloak per leather, the backpack per frame metal).
@export var part_icons: Dictionary = {}

@export_group("Combat")
## Damage range at rarity Common. For composed weapons the parts' damage is added
## (e.g. the blade brings the damage), the rarity adds a bonus (see Rarity).
@export var damage_min: int = 0
@export var damage_max: int = 0
## Armor value at rarity Common (armor pieces and their parts).
@export var armor: int = 0
## Reduces all magic damage (elements and pure magic) like armor reduces physical damage.
@export var magic_resistance: int = 0
## Physical damage type (weapons and their damage parts, e.g. blade = slash).
@export var damage_type: DamageType.Type = DamageType.Type.NONE
## Element of the damage (later: staffs). NONE = no element.
@export var element: Element.Type = Element.Type.NONE
@export var attributes: Array[ItemAttribute] = []
## Magic damage range (staffs, later); added to magic skills instead of the physical damage.
@export var magic_damage_min: int = 0
@export var magic_damage_max: int = 0
## How the damage of this weapon is split into kinds (DamageKinds ids -> share, adds up to 1),
## e.g. {"slash": 0.5, "fire": 0.5}. Empty = from damage_type (or physical).
@export var damage_split: Dictionary = {}
## Resistances it gives when worn: DamageKinds id -> value (e.g. {"fire": 10}).
@export var resistances: Dictionary = {}
## Extra crit chance (0.05 = +5 %) and crit damage (0.25 = +25 %) when worn.
@export var crit_chance: float = 0.0
@export var crit_damage: float = 0.0
## Armor / magic penetration when worn (CombatRules.penetration, e.g. a spear that ignores 10 %
## armor: {"armor_percent": 0.1}). Empty = none.
@export var penetration: Dictionary = {}
## Kind of weapon (Schwerter, Zauberstäbe ...): category in the station menu and how it is held.
## null = no weapon type.
@export var weapon_type: WeaponType
## Special effect text shown in the tooltip. Empty = no effect.
@export_multiline var effect: String = ""
## Potion for heroes (Hero.HERO_POTIONS: "skill_point", "attribute_point", "reset_skills",
## "reset_attributes", "iq"), used by right click while a hero window is open. Empty = no potion.
@export var hero_potion: String = ""
## Potions with an amount ("iq"): this much, plus hero_potion_per_rarity per tier above R1
## (get_hero_potion_amount).
@export var hero_potion_value: int = 0
@export var hero_potion_per_rarity: int = 0
## Quality potion: quality points it gives a weapon or armor piece at the enchanting table (100 =
## one rarity tier), plus quality_per_rarity per tier above R1 (get_quality_points). 0 = none.
@export var quality_points: int = 0
@export var quality_per_rarity: int = 0
## Kinds of reroll potions (mortar.json brews "reroll"), see Enchanting.
const REROLLS: Array[String] = ["attributes", "sockets"]
## Reroll potion at the enchanting table (REROLLS): "attributes" = new random attribute
## types (values stay, they follow the rarity), "sockets" = every socket gets a new random bonus and
## level. Empty = none. Can be used on the same piece again and again.
@export var reroll: String = ""

@export_group("Tool")
## Pickaxes: extra damage per hit on rocks.
@export var mining_damage: int = 0
## Coin purse (dropped by bandits): when the loot goes into the loot chest, each purse becomes
## this much gold ([min, max]; empty = no purse).
@export var purse_gold: Array = []
## Lumber axes (and their heads): extra damage on trees.
@export var chopping_damage: int = 0
## Shoes: faster walking in percent at R1, +2 per rarity tier above (InventorySlot.get_move_speed).
@export var move_speed: int = 0
## Gloves: more quality points when the smith forges, joins and sharpens, in percent (5 = +5 %),
## only in the smith's gloves slot (PlayerStats.get_quality_gain), e.g. the master gloves.
@export var forge_quality: int = 0
## Gloves: the forging and workbench minigames run this many percent slower (items.json
## "minigame_calm", e.g. the sandsmith gloves; ForgeQuality.get_difficulty).
@export var minigame_calm: int = 0
## Backpacks (and their frames): extra slots in the player's inventory (InventorySlot.get_inventory_slots).
@export var inventory_slots: int = 0
## Watering cans (and their can bodies): how many fields one filling waters (InventorySlot.get_water_capacity).
@export var water_charges: int = 0
## Luck in % while a hero wears it (the goblin king's crown): in a dungeon monsters drop loot more
## often and rarer (Adventure.loot_luck); only the best piece of the party counts.
@export var loot_luck: float = 0.0


func is_weapon() -> bool:
	return type == ItemType.WEAPON


## Weapons held with both hands (weapon type "two"): the left hand stays empty, no shield.
func is_two_handed() -> bool:
	return is_weapon() and weapon_type != null and weapon_type.hands == WeaponType.Hands.TWO


## Bows and longbows (weapon type "uses_arrows"): shoot the arrows in the left hand.
func uses_arrows() -> bool:
	return is_weapon() and weapon_type != null and weapon_type.uses_arrows


## Attack speed factor of the weapon type (1.0 = normal, see WeaponType.attack_speed).
func get_attack_speed() -> float:
	return weapon_type.attack_speed if weapon_type else 1.0


## Things that are worn or used as a tool (weapons, armor, jewelry, tools): they never stack.
func is_equipment() -> bool:
	return type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.ACCESSORY, ItemType.HELMET, ItemType.BOOTS,
			ItemType.PICKAXE, ItemType.SHOULDERS, ItemType.CLOAK, ItemType.LEGS, ItemType.NECKLACE,
			ItemType.RING, ItemType.SHIELD, ItemType.GLOVES, ItemType.BACKPACK, ItemType.SHOES, ItemType.QUIVER,
			ItemType.LUMBER_AXE]


## Rings and necklaces (composed of parts, random attributes from their rarity).
func is_jewelry() -> bool:
	return type in [ItemType.RING, ItemType.NECKLACE]


## Worn pieces with an armor value (composed of parts, random attributes); shields count too.
func is_armor() -> bool:
	return type in [ItemType.ARMOR, ItemType.HELMET, ItemType.BOOTS, ItemType.SHIELD, ItemType.SHOULDERS,
			ItemType.CLOAK, ItemType.LEGS, ItemType.GLOVES]


## What a hero potion of this rarity gives (e.g. IQ +4 for an R1 elixir, +5 for R2).
func get_hero_potion_amount(rarity: int) -> int:
	return hero_potion_value + hero_potion_per_rarity * rarity


## Quality points a quality potion of this rarity gives (R1 100, R2 115, R3 130 ...).
func get_quality_points(rarity: int) -> int:
	return quality_points + quality_per_rarity * rarity
