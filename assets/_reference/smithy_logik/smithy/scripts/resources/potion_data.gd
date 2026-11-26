class_name PotionData
extends Resource
## An enchanting potion (data/content/mortar.json "potions", see docs/CONTENT.md), brewed in the
## mortar from its `crystal` (or its dust), its `plant` (moon lily, nightshade, sunflower; or its
## dust) and a vial; combo potions take a second, different crystal (`crystal2`). At the
## enchanting table (tab "Verzaubern") it enchants a weapon (`weapon_bonus`, e.g. +fire damage)
## or an armor piece / shield (`armor_bonus`, e.g. fire resistance); the level of the bonus is the
## rarity of the potion (R1 = level 1). The potion itself is an item with the same id.

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export var crystal: ItemData
## Second crystal of a combo potion (null = none), e.g. topaz for magma (ruby + topaz).
@export var crystal2: ItemData
## Plant it is brewed with (mortar.json "plant" unless the potion names another one).
@export var plant: ItemData
## Bonus (sockets.json) for weapons and for armor/shields.
@export var weapon_bonus: SocketBonus
@export var armor_bonus: SocketBonus
## The potion item.
@export var item: ItemData


## Ingredients in the mortar (without the vial), e.g. [ruby, moon lily] or [ruby, topaz, moon lily].
func get_ingredients() -> Array[ItemData]:
	var list: Array[ItemData] = [crystal]
	if crystal2:
		list.append(crystal2)
	list.append(plant)
	return list


## Secret recipes (other plants, combo potions) only show in the books once brewed (Enchanting.is_known).
func is_secret() -> bool:
	return crystal2 != null or plant != ContentDB.mortar_item("plant")


## The bonus this potion gives `target` (null = it can't be enchanted with it).
func get_bonus_for(target: ItemData) -> SocketBonus:
	if target == null:
		return null
	if target.is_weapon():
		return weapon_bonus
	if target.is_armor():
		return armor_bonus
	return null


## e.g. "Waffe: Feuerzauber 1: +5 % Feuer-Schaden · Rüstung: Feuerschutz 1: +3 Feuer-Resistenz".
func describe(rarity: Rarity.Tier) -> String:
	var level: int = Enchanting.get_level(rarity)
	var parts: Array[String] = []
	for entry: Array in [[Language.translate("Waffe"), weapon_bonus], [Language.translate("Rüstung"), armor_bonus]]:
		var bonus: SocketBonus = entry[1]
		if bonus:
			var shown: int = mini(level, bonus.get_max_level())
			parts.append("%s: %s %d: %s" % [entry[0], bonus.display_name, shown, bonus.get_effect_text(shown)])
	return "\n".join(parts)
