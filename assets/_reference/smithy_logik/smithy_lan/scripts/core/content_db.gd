class_name ContentDB
extends RefCounted
## All game content from the JSON files in res://data/content/ (format: docs/CONTENT.md).
## Loaded once on first access. Everything is identified by its id (e.g. "iron_blade").
##
## Items (items.json + materials.json) become ItemData. From each part the recipes are
## generated automatically, depending on its material's "process":
##   cast  (metals):  forge  "mold_<part>"  ingot -> hot blank "hot_<part>_blank"
##                    anvil  "<part>"       hot blank -> part (glowing, cool it in the trough)
##   carve (wood):    workbench "<part>"    raw material -> part
## Weapons/armor with "parts" get a workbench recipe "<id>" that joins any parts of those kinds.
## Weapon types (weapon_types.json: Schwerter, Zauberstäbe ...) are the categories of the weapon
## tab at the workbench and the enchanting table; they are listed even without recipes.
## Extra recipes can be written in recipes.json.
## Fights: status_effects.json (buffs/debuffs), skills.json (shared by heroes and monsters),
## enemies.json (monsters) and combat.json (attribute formulas, see CombatRules).
## Dungeons: dungeons.json (stages, enemy waves with chances, bosses, time limit, rewards).
## Economy: economy.json (price factors, customers, reputation), see Economy and Customers.
## Looks of characters: appearance.json (races, skin tones, hair, eyes, sizes), see Appearance.
## Story: story.json (intro, steps, dialogues, tips, story figures), see Story.
## Anvil minigame: forging_patterns.json (workpiece picture and strike spots per part type or
## item), see ForgingPattern.
## House: house.json (upgrade levels of the player's house, own shop, furniture), see House.
## Sockets: sockets.json (bonuses for equipment sockets, levels 1-9 with chances), see SocketBonus.
## Mortar: mortar.json (dusts crushed from crystals and the moon lily, enchanting potions; each is
## also an item), see DustData, PotionData and Enchanting.
## Fixed villagers: npcs.json (name, home, partner, daily schedule), see Residents.
## Mistakes in the files are reported with file and id (Godot output / debugger).
## Top-level keys starting with "_" (the "_hilfe" block in every file) are help for people and ignored.

const CONTENT_DIR: String = "res://data/content/"
## Placeholder pictures when a JSON entry has no picture (yet) or its file is missing, so new
## entries can be written before their graphics exist.
const DEFAULT_ITEM_ICON: String = "res://assets/sprites/items/default.png"
const DEFAULT_SKILL_ICON: String = "res://assets/sprites/skills/default.png"
const DEFAULT_EFFECT_ICON: String = "res://assets/sprites/effects/default.png"
const DEFAULT_ENEMY_SPRITE: String = "res://assets/sprites/enemies/default.png"
## Icon for hot blanks of parts without their own "hot_icon" / hot_<part>_blank.png.
const DEFAULT_HOT_ICON: String = "res://assets/sprites/items/hot_blank.png"
## Forging pattern of items without their own and without a part type pattern.
const DEFAULT_FORGING_PATTERN: String = "default"
## Files without texts for players (names in them are ids, e.g. audio buses).
const UNTRANSLATED_FILES: Array[String] = ["audio.json"]
## Old ids that were renamed (old saves are converted with this).
const RENAMED_IDS: Dictionary = {"bronze_compass_case": "gold_compass_case", "mold_bronze_compass_case": "mold_gold_compass_case", "gold_compass_lid": "bronze_compass_lid", "mold_gold_compass_lid": "mold_bronze_compass_lid", "hot_copper_axe_blank": "hot_copper_axe_head_blank", "warrior_sword_strike": "sword_strike"}

const ITEM_TYPES: Dictionary = {
	"material": ItemData.ItemType.MATERIAL, "fuel": ItemData.ItemType.FUEL, "ore": ItemData.ItemType.ORE,
	"ingot": ItemData.ItemType.INGOT, "weapon": ItemData.ItemType.WEAPON, "armor": ItemData.ItemType.ARMOR,
	"accessory": ItemData.ItemType.ACCESSORY, "part": ItemData.ItemType.PART, "helmet": ItemData.ItemType.HELMET,
	"boots": ItemData.ItemType.BOOTS, "pickaxe": ItemData.ItemType.PICKAXE, "shoulders": ItemData.ItemType.SHOULDERS,
	"cloak": ItemData.ItemType.CLOAK, "legs": ItemData.ItemType.LEGS, "necklace": ItemData.ItemType.NECKLACE,
	"ring": ItemData.ItemType.RING, "shield": ItemData.ItemType.SHIELD, "gloves": ItemData.ItemType.GLOVES,
	"arrows": ItemData.ItemType.ARROWS, "quiver": ItemData.ItemType.QUIVER,
	"backpack": ItemData.ItemType.BACKPACK, "shoes": ItemData.ItemType.SHOES,
	"lumber_axe": ItemData.ItemType.LUMBER_AXE, "watering_can": ItemData.ItemType.WATERING_CAN,
}
const PART_TYPES: Dictionary = {
	"blade": ItemData.PartType.BLADE, "handle": ItemData.PartType.HANDLE,
	"axe_head": ItemData.PartType.AXE_HEAD, "shaft": ItemData.PartType.SHAFT,
	"dagger_blade": ItemData.PartType.DAGGER_BLADE, "greatsword_blade": ItemData.PartType.GREATSWORD_BLADE,
	"spear_head": ItemData.PartType.SPEAR_HEAD, "hammer_head": ItemData.PartType.HAMMER_HEAD,
	"mace_head": ItemData.PartType.MACE_HEAD, "greataxe_head": ItemData.PartType.GREATAXE_HEAD,
	"shield_plate": ItemData.PartType.SHIELD_PLATE, "pickaxe_head": ItemData.PartType.PICKAXE_HEAD,
	"chest_plate": ItemData.PartType.CHEST_PLATE, "helmet_plate": ItemData.PartType.HELMET_PLATE,
	"shoulder_plate": ItemData.PartType.SHOULDER_PLATE, "boot_plate": ItemData.PartType.BOOT_PLATE,
	"glove_plate": ItemData.PartType.GLOVE_PLATE, "leather": ItemData.PartType.LEATHER,
	"bow_frame": ItemData.PartType.BOW_FRAME, "longbow_frame": ItemData.PartType.LONGBOW_FRAME,
	"arrow_tip": ItemData.PartType.ARROW_TIP, "arrow_shaft": ItemData.PartType.ARROW_SHAFT,
	"staff_rod": ItemData.PartType.STAFF_ROD, "lumber_axe_head": ItemData.PartType.LUMBER_AXE_HEAD,
	"ring_band": ItemData.PartType.RING_BAND, "gem": ItemData.PartType.GEM,
	"leg_plate": ItemData.PartType.LEG_PLATE, "backpack_frame": ItemData.PartType.BACKPACK_FRAME,
	"fletching": ItemData.PartType.FLETCHING, "amulet_band": ItemData.PartType.AMULET_BAND,
	"can_body": ItemData.PartType.CAN_BODY,
	"compass_case": ItemData.PartType.COMPASS_CASE, "compass_needle": ItemData.PartType.COMPASS_NEEDLE,
	"compass_rose": ItemData.PartType.COMPASS_ROSE, "compass_lid": ItemData.PartType.COMPASS_LID,
}
const DAMAGE_TYPES: Dictionary = {
	"none": DamageType.Type.NONE, "stab": DamageType.Type.STAB, "blunt": DamageType.Type.BLUNT, "slash": DamageType.Type.SLASH,
}
const ELEMENTS: Dictionary = {
	"none": Element.Type.NONE, "fire": Element.Type.FIRE, "water": Element.Type.WATER, "earth": Element.Type.EARTH,
	"air": Element.Type.AIR, "dark": Element.Type.DARK, "light": Element.Type.LIGHT, "lightning": Element.Type.LIGHTNING,
	"ice": Element.Type.ICE, "poison": Element.Type.POISON,
}
const ATTRIBUTES: Dictionary = {
	"str": ItemAttribute.Type.STRENGTH, "agi": ItemAttribute.Type.AGILITY, "con": ItemAttribute.Type.CONSTITUTION,
	"int": ItemAttribute.Type.INTELLIGENCE, "wis": ItemAttribute.Type.WISDOM, "res": ItemAttribute.Type.RESISTANCE,
}
const DAMAGE_KINDS: Dictionary = {"physical": SkillData.DamageKind.PHYSICAL, "magic": SkillData.DamageKind.MAGIC}
const TARGETS: Dictionary = {"enemy": SkillData.Target.ENEMY, "self": SkillData.Target.SELF, "ally": SkillData.Target.ALLY,
		"all_enemies": SkillData.Target.ALL_ENEMIES, "all_allies": SkillData.Target.ALL_ALLIES}
const EFFECT_KINDS: Dictionary = {"buff": StatusEffectData.Kind.BUFF, "debuff": StatusEffectData.Kind.DEBUFF}
const STACKING: Dictionary = {"stack": StatusEffectData.Stacking.STACK, "refresh": StatusEffectData.Stacking.REFRESH}
const STAGE_TYPES: Dictionary = {
	"normal": DungeonData.StageType.NORMAL, "mini_boss": DungeonData.StageType.MINI_BOSS,
	"boss": DungeonData.StageType.BOSS,
}
const TABS: Dictionary = {
	"weapon": RecipeData.Tab.WEAPON, "armor": RecipeData.Tab.ARMOR,
	"jewelry": RecipeData.Tab.JEWELRY, "accessory": RecipeData.Tab.EXTRA, "enchant": RecipeData.Tab.ENCHANT,
	"arrows": RecipeData.Tab.ARROWS,
}
const HANDS: Dictionary = {
	"one": WeaponType.Hands.ONE, "two": WeaponType.Hands.TWO, "either": WeaponType.Hands.EITHER,
	"left": WeaponType.Hands.LEFT,
}

static var _loaded: bool = false
static var _materials: Dictionary = {}
## id -> WeaponType, in file order.
static var _weapon_types: Dictionary = {}
## id -> ItemData, in file order.
static var _items: Dictionary = {}
## id -> RecipeData, in the order they were created.
static var _recipes: Dictionary = {}
static var _status_effects: Dictionary = {}
## status_effects.json as read (skills build stronger versions per level from it).
static var _effect_json: Dictionary = {}
static var _skills: Dictionary = {}
## skill_trees.json: class id -> [{"id", "name", "skills": Array[SkillData]}].
static var _skill_trees: Dictionary = {}
## id -> SummonData (summons.json).
static var _summons: Dictionary = {}
static var _enemies: Dictionary = {}
static var _dungeons: Dictionary = {}
## Values of combat.json (formulas).
static var _combat: Dictionary = {}
## Values of economy.json (sections "prices", "customers", "reputation").
static var _economy: Dictionary = {}
## Values of appearance.json (character builder).
static var _appearance: Dictionary = {}
## Values of story.json (steps, dialogues, tips).
static var _story: Dictionary = {}
static var _calendar: Dictionary = {}
## Values of house.json (house upgrades, own shop, furniture), see House.
static var _house: Dictionary = {}
## id -> ForgingPattern (anvil minigame).
static var _forging_patterns: Dictionary = {}
## id -> SocketBonus, in file order.
static var _socket_bonuses: Dictionary = {}
## id -> DustData / PotionData, in file order; mortar.json as read (plant, vial, failed).
static var _dusts: Dictionary = {}
static var _potions: Dictionary = {}
## id -> BrewData (mortar.json "brews": IQ potions, quality potion ...), in file order.
static var _brews: Dictionary = {}
static var _mortar: Dictionary = {}
## Values of npcs.json (fixed villagers).
## achievements.json (Achievements).
static var _achievements: Dictionary = {}
## npcs.json: id -> NpcInfo.
static var _npcs: Dictionary[String, NpcInfo] = {}
## desert.json (DesertMaze).
static var _desert: Dictionary = {}
## arena.json (HeroTournament).
static var _arena: Dictionary = {}
## leagues.json (TournamentRanking).
static var _leagues: Dictionary = {}
## world_map.json (CrystalMapView: regions, places, crystals, teleporter spots).
static var _world_map: Dictionary = {}


# --- Items --------------------------------------------------------------------------

## The item with this id (also accepts old save values like "res://data/items/x.tres").
## null (with an error) if it does not exist.
static func item(id: String) -> ItemData:
	_ensure_loaded()
	var key: String = normalize_id(id)
	if not _items.has(key):
		push_error("ContentDB: unknown item '%s'." % id)
		return null
	return _items[key]


static func has_item(id: String) -> bool:
	_ensure_loaded()
	return _items.has(normalize_id(id))


static func get_all_items() -> Array:
	_ensure_loaded()
	return _items.values()


## A stack from a short text: "wood" (one wood), "wood*5" (five) or a composed item with its
## parts: "sword:iron_blade+iron_handle". A finished jewel names its crystal and effect after "#":
## "jewel_ring:silver_ring_band#ruby.lifesteal" ("#ruby" = a random effect of the crystal, "#any" =
## a random crystal too). Used e.g. for merchant offers. null if invalid.
## "@R4+" = at least this rarity (story hand-ins like "take_items:polearm:bronze_spear_head@R4+"):
## the stack gets meta MIN_RARITY_META, GameState then accepts any rarity from R4 up and only
## compares the named parts (here the spear head, any shaft).
## Meta flag on a stack from make_stack("…@R4+"): its rarity is the lowest one accepted.
const MIN_RARITY_META: StringName = &"min_rarity"


static func make_stack(spec: String) -> InventorySlot:
	var amount: int = 1
	var text: String = spec.strip_edges()
	# "@R3" = this rarity, "@R3-R4" = one of these (random), e.g. rare ingots of the traveler.
	var rarity_text: String = ""
	if "@" in text:
		rarity_text = text.get_slice("@", 1)
		text = text.get_slice("@", 0)
	if "*" in text:
		amount = int(text.get_slice("*", 1))
		text = text.get_slice("*", 0)
	var jewel_text: String = ""
	if "#" in text:
		jewel_text = text.get_slice("#", 1)
		text = text.get_slice("#", 0)
	var parts_text: String = text.get_slice(":", 1) if ":" in text else ""
	var base: ItemData = item(text.get_slice(":", 0))
	if base == null:
		return null
	var components: Array[ItemData] = []
	for part_id in parts_text.split("+", false):
		var part: ItemData = item(part_id)
		if part:
			components.append(part)
	var rarity: Rarity.Tier = Crafting.get_base_rarity(base, components)
	var at_least: bool = rarity_text.ends_with("+")
	rarity_text = rarity_text.trim_suffix("+")
	if not rarity_text.is_empty():
		var low: int = _parse_rarity(rarity_text.get_slice("-", 0), spec)
		var high: int = _parse_rarity(rarity_text.get_slice("-", 1), spec) if "-" in rarity_text else low
		rarity = randi_range(low, maxi(low, high)) as Rarity.Tier
	var stack: InventorySlot = Crafting.create_result(base, amount, 0, rarity, components)
	if at_least:
		stack.set_meta(MIN_RARITY_META, true)
	if not jewel_text.is_empty() and not _set_jewel(stack, jewel_text):
		return null
	return stack


## Crystal and effect of a finished jewel from "ruby.lifesteal", "ruby" (random effect) or "any"
## (random crystal). false if the band, crystal or effect does not fit.
static func _set_jewel(stack: InventorySlot, jewel_text: String) -> bool:
	var kind: String = Jewelry.get_kind(stack.components[0]) if not stack.components.is_empty() else ""
	if kind.is_empty():
		return false
	var crystal_id: String = jewel_text.get_slice(".", 0)
	var crystal: ItemData = null
	if crystal_id == "any":
		var crystals: Array = get_all_items().filter(func(candidate: ItemData) -> bool:
				return candidate.jewel_effects.has(kind))
		crystal = crystals.pick_random() if not crystals.is_empty() else null
	elif has_item(crystal_id):
		crystal = item(crystal_id)
	if crystal == null or not crystal.jewel_effects.has(kind):
		return false
	var effects: Dictionary = crystal.jewel_effects[kind]
	var effect: String = jewel_text.get_slice(".", 1) if "." in jewel_text else str(effects.keys().pick_random())
	if not effects.has(effect):
		return false
	stack.jewel_crystal = crystal
	stack.jewel_effect = effect
	return true


## Converts old save values (resource paths) and renamed ids to the current id.
static func normalize_id(value: String) -> String:
	var id: String = value
	if id.begins_with("res://"):
		id = id.get_file().get_basename()
	# Nickel became bronze (nickel_blade -> bronze_blade, mold_nickel_blade -> mold_bronze_blade).
	if "nickel" in id:
		id = id.replace("nickel", "bronze")
	return RENAMED_IDS.get(id, id)


## Items that are made from others in the smelter's alloy tab (items.json "alloy"), in file order.
static func get_alloys() -> Array[ItemData]:
	_ensure_loaded()
	var result: Array[ItemData] = []
	for item_data: ItemData in _items.values():
		if not item_data.alloy_ingredients.is_empty():
			result.append(item_data)
	return result


## Whether `item_data` is needed for any alloy.
static func is_alloy_ingredient(item_data: ItemData) -> bool:
	for alloy in get_alloys():
		if alloy.alloy_ingredients.has(item_data):
			return true
	return false


## The alloy made of exactly these two items (any order), or null.
static func find_alloy(first: ItemData, second: ItemData) -> ItemData:
	if first == null or second == null or first == second:
		return null
	for alloy in get_alloys():
		var needed: Dictionary = alloy.alloy_ingredients
		if needed.size() == 2 and needed.has(first) and needed.has(second):
			return alloy
	return null


# --- Mortar: dusts and enchanting potions ----------------------------------------------

## Picture of every dust without its own icon, tinted with its "color".
const DUST_ICON: String = "res://assets/sprites/items/magic_dust.png"
## Picture of every potion without its own icon, tinted with its "color".
const POTION_ICON: String = "res://assets/sprites/items/enchant_potion.png"


static func get_dusts() -> Array[DustData]:
	_ensure_loaded()
	var result: Array[DustData] = []
	result.assign(_dusts.values())
	return result


static func dust(id: String) -> DustData:
	return _get_entry(_dusts, id, "dust")


static func has_dust(id: String) -> bool:
	_ensure_loaded()
	return _dusts.has(id)


## The dust `item` is crushed into in the mortar (null = it can't be crushed).
static func dust_from(item: ItemData) -> DustData:
	_ensure_loaded()
	for dust_data: DustData in _dusts.values():
		if dust_data.source == item:
			return dust_data
	return null


## The dust that is this item (null = it is no dust).
static func dust_of_item(item: ItemData) -> DustData:
	_ensure_loaded()
	return _dusts.get(String(item.id)) if item else null


static func get_potions() -> Array[PotionData]:
	_ensure_loaded()
	var result: Array[PotionData] = []
	result.assign(_potions.values())
	return result


## The potion that is this item (null = it is no potion).
static func potion_of_item(item: ItemData) -> PotionData:
	_ensure_loaded()
	return _potions.get(String(item.id)) if item else null


## The potion brewed from this crystal with `plant` (null = mortar.json "plant"), and for combo
## potions a second, different crystal (order does not matter). null = no such potion.
static func potion_from_crystal(crystal: ItemData, plant: ItemData = null, crystal2: ItemData = null) -> PotionData:
	_ensure_loaded()
	if plant == null:
		plant = mortar_item("plant")
	for potion_data: PotionData in _potions.values():
		if potion_data.plant != plant:
			continue
		if crystal2 == null and potion_data.crystal == crystal and potion_data.crystal2 == null:
			return potion_data
		if crystal2 and potion_data.crystal2 and ((potion_data.crystal == crystal and potion_data.crystal2 == crystal2)
				or (potion_data.crystal == crystal2 and potion_data.crystal2 == crystal)):
			return potion_data
	return null


## The plants enchanting potions are brewed with (moon lily, nightshade ...).
static func get_potion_plants() -> Array[ItemData]:
	_ensure_loaded()
	var plants: Array[ItemData] = []
	for potion_data: PotionData in _potions.values():
		if not plants.has(potion_data.plant):
			plants.append(potion_data.plant)
	return plants


static func get_brews() -> Array[BrewData]:
	_ensure_loaded()
	var result: Array[BrewData] = []
	result.assign(_brews.values())
	return result


static func has_brew(id: String) -> bool:
	_ensure_loaded()
	return _brews.has(id)


## The brew that is this item (null = it is no brew).
static func brew_of_item(item: ItemData) -> BrewData:
	_ensure_loaded()
	return _brews.get(String(item.id)) if item else null


## mortar.json "plant", "vial", "failed" as items (null if missing).
static func mortar_item(key: String) -> ItemData:
	_ensure_loaded()
	var id: String = _mortar.get(key, "")
	return _items.get(id)


static func _load_mortar() -> void:
	var file: String = "mortar.json"
	_mortar = _read_json(file)
	for key: String in ["plant", "vial", "failed"]:
		if not _items.has(_mortar.get(key, "")):
			push_error("ContentDB: %s: '%s' needs an item id, '%s' does not exist." % [file, key, _mortar.get(key, "")])
	var dusts: Dictionary = _mortar.get("dusts", {})
	for id: String in dusts:
		var data: Dictionary = dusts[id]
		var dust_data := DustData.new()
		dust_data.id = id
		dust_data.display_name = data.get("name", id)
		dust_data.source = _items.get(data.get("from", ""))
		if dust_data.source == null:
			push_error("ContentDB: %s, dusts '%s': unknown item in from: '%s'." % [file, id, data.get("from", "")])
			continue
		var description: String = Language.translate("Zerkleinerte %s aus dem Mörser. Zählt in Tränken wie %s.") % [
				dust_data.source.display_name, dust_data.source.display_name]
		dust_data.item = _create_mortar_item(file, id, dust_data.display_name, description, data, DUST_ICON, "#9fc8ff")
		_dusts[id] = dust_data
	var potions: Dictionary = _mortar.get("potions", {})
	for id: String in potions:
		var data: Dictionary = potions[id]
		var potion_data := PotionData.new()
		potion_data.id = id
		potion_data.display_name = data.get("name", id)
		potion_data.crystal = _items.get(data.get("crystal", ""))
		if potion_data.crystal == null:
			push_error("ContentDB: %s, potions '%s': unknown crystal '%s'." % [file, id, data.get("crystal", "")])
			continue
		# "plant": other plant than mortar.json "plant" (e.g. nightshade); "crystal2": a second,
		# different crystal (combo potion, e.g. ruby + topaz = magma).
		potion_data.plant = _items.get(data.get("plant", _mortar.get("plant", "")))
		if potion_data.plant == null:
			push_error("ContentDB: %s, potions '%s': unknown plant '%s'." % [file, id, data.get("plant", "")])
			continue
		if data.has("crystal2"):
			potion_data.crystal2 = _items.get(data["crystal2"])
			if potion_data.crystal2 == null or potion_data.crystal2 == potion_data.crystal:
				push_error("ContentDB: %s, potions '%s': crystal2 '%s' is unknown or the same crystal." % [file, id, data["crystal2"]])
				continue
		for key: String in ["weapon", "armor"]:
			var bonus_id: String = data.get(key, "")
			if bonus_id.is_empty() and data.has("weapon" if key == "armor" else "armor"):
				continue  # only one of them, e.g. the feather potion works on weapons only
			if not _socket_bonuses.has(bonus_id):
				push_error("ContentDB: %s, potions '%s': unknown bonus in %s: '%s' (see sockets.json)." % [file, id, key, bonus_id])
				continue
			if key == "weapon":
				potion_data.weapon_bonus = _socket_bonuses[bonus_id]
			else:
				potion_data.armor_bonus = _socket_bonuses[bonus_id]
		var targets: String = Language.translate("eine Waffe oder ein Rüstungsteil") if potion_data.armor_bonus else Language.translate("eine Waffe")
		if potion_data.weapon_bonus == null:
			targets = Language.translate("ein Rüstungsteil")
		var made_of: String = potion_data.crystal.display_name
		if potion_data.crystal2:
			made_of += Language.translate(" und ") + potion_data.crystal2.display_name
		if potion_data.plant != mortar_item("plant"):
			made_of += Language.translate(" mit ") + potion_data.plant.display_name
		var description: String = Language.translate("Verzauberungstrank aus %s. Am Zaubertisch (Reiter Verzaubern) auf %s geben; je seltener der Trank, desto stärker der Zauber.") % [made_of, targets]
		potion_data.item = _create_mortar_item(file, id, potion_data.display_name, description, data, POTION_ICON, "#c8a0ff")
		_potions[id] = potion_data
	var brews: Dictionary = _mortar.get("brews", {})
	for id: String in brews:
		var data: Dictionary = brews[id]
		var brew := BrewData.new()
		brew.id = id
		for ingredient_id: String in data.get("ingredients", []):
			if not _items.has(ingredient_id):
				push_error("ContentDB: %s, brews '%s': unknown ingredient '%s'." % [file, id, ingredient_id])
				continue
			brew.ingredients.append(_items[ingredient_id])
		if brew.ingredients.is_empty() or brew.ingredients.size() > Enchanting.MAX_INGREDIENTS:
			push_error("ContentDB: %s, brews '%s': needs 1-%d ingredients." % [file, id, Enchanting.MAX_INGREDIENTS])
			continue
		brew.rarity_from = _items.get(data.get("rarity_from", ""))
		brew.locked = bool(data.get("locked", false))
		if _items.has(id) and not data.has("name"):
			# Story potions (e.g. seers_brew) live in items.json; the mortar only brews them.
			brew.item = _items[id]
		else:
			brew.item = _create_mortar_item(file, id, data.get("name", id), data.get("description", ""), data, POTION_ICON, "#c8a0ff")
			_parse_potion_fields(brew.item, data, file, id)
			brew.item.max_stack = int(data.get("stack", 20))
		_brews[id] = brew


## Fields of hero potions and quality potions (items.json and mortar.json "brews").
static func _parse_potion_fields(item_data: ItemData, data: Dictionary, file: String, id: String) -> void:
	item_data.effect = data.get("effect", item_data.effect)
	item_data.hero_potion = data.get("hero_potion", "")
	if not item_data.hero_potion.is_empty() and not Hero.HERO_POTIONS.has(item_data.hero_potion):
		push_error("ContentDB: %s, '%s': hero_potion: unknown kind '%s' (%s)." % [file, id, item_data.hero_potion, ", ".join(Hero.HERO_POTIONS)])
		item_data.hero_potion = ""
	item_data.hero_potion_value = int(data.get("hero_potion_value", 0))
	item_data.hero_potion_per_rarity = int(data.get("hero_potion_per_rarity", 0))
	item_data.quality_points = int(data.get("quality_points", 0))
	item_data.quality_per_rarity = int(data.get("quality_per_rarity", 0))
	item_data.reroll = data.get("reroll", "")
	if not item_data.reroll.is_empty() and item_data.reroll not in ItemData.REROLLS:
		push_error("ContentDB: %s, '%s': reroll: unknown kind '%s' (%s)." % [file, id, item_data.reroll, ", ".join(ItemData.REROLLS)])
		item_data.reroll = ""


static func _create_mortar_item(file: String, id: String, display_name: String, description: String, data: Dictionary,
		default_icon: String, default_color: String) -> ItemData:
	if _items.has(id):
		push_error("ContentDB: %s, '%s': an item with this id exists already." % [file, id])
	var item_data := ItemData.new()
	item_data.id = id
	item_data.display_name = display_name
	item_data.description = description
	item_data.type = ItemData.ItemType.MATERIAL
	item_data.value = int(data.get("value", 10))
	item_data.base_rarity = _parse_rarity(data.get("rarity", "R1"), id)
	if data.has("icon"):
		item_data.icon = _load_texture(data["icon"], id, default_icon)
	else:
		item_data.icon = _tinted(load(default_icon), Color.html(data.get("color", default_color)))
	_items[id] = item_data
	return item_data


## Copy of a picture with every pixel multiplied by `tint` (for the dust icons).
static func _tinted(texture: Texture2D, tint: Color) -> Texture2D:
	var image: Image = texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, image.get_pixel(x, y) * tint)
	return ImageTexture.create_from_image(image)


# --- Fixed villagers -----------------------------------------------------------------

## Entry of npcs.json ({} if there is none).
## achievements.json: {"categories": {...}, "achievements": {...}} (see Achievements).
static func achievements() -> Dictionary:
	_ensure_loaded()
	return _achievements


## desert.json: the maze of the desert (DesertMaze).
static func desert() -> Dictionary:
	_ensure_loaded()
	return _desert


## arena.json: Kahn's hero tournament (HeroTournament, HeroBuilder).
static func arena() -> Dictionary:
	_ensure_loaded()
	return _arena


## leagues.json: league tournaments and the ranking (TournamentRanking).
static func leagues() -> Dictionary:
	_ensure_loaded()
	return _leagues


## world_map.json: the world map (CrystalMapView).
static func world_map() -> Dictionary:
	_ensure_loaded()
	return _world_map


## The fixed villager `id` from npcs.json; never null: for an unknown id an empty NpcInfo with
## `exists` false (all defaults).
static func npc_info(id: String) -> NpcInfo:
	_ensure_loaded()
	return _npcs[id] if _npcs.has(id) else NpcInfo.missing(id)


static func get_npc_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	ids.assign(_npcs.keys())
	return ids


## npcs.json as NpcInfo objects; wrong or unknown fields are reported (NpcInfo.from_json).
static func _load_npcs() -> void:
	var data: Dictionary = _read_json("npcs.json", true)
	for id: String in data:
		if not data[id] is Dictionary:
			push_error("ContentDB: npcs.json '%s' must be an object { ... }." % id)
			continue
		var errors: Array[String] = []
		_npcs[id] = NpcInfo.from_json(id, data[id], errors)
		for error in errors:
			push_error("ContentDB: " + error)


# --- Sockets ------------------------------------------------------------------------

## The socket bonus with this id (sockets.json). null (with an error) if it does not exist.
static func socket_bonus(id: String) -> SocketBonus:
	return _get_entry(_socket_bonuses, id, Language.translate("socket bonus"))


static func has_socket_bonus(id: String) -> bool:
	_ensure_loaded()
	return _socket_bonuses.has(id)


static func get_socket_bonuses() -> Array[SocketBonus]:
	_ensure_loaded()
	var result: Array[SocketBonus] = []
	result.assign(_socket_bonuses.values())
	return result


## All bonuses that can sit in a socket of `item` (its "slots" allow the item's type; enchantments
## from potions are not among them).
static func get_socket_bonuses_for(item_data: ItemData) -> Array[SocketBonus]:
	return get_socket_bonuses().filter(func(bonus: SocketBonus) -> bool: return bonus.fits(item_data) and not bonus.enchant_only)


static func _create_socket_bonus(id: String, data: Dictionary) -> SocketBonus:
	var file: String = "sockets.json"
	var bonus := SocketBonus.new()
	bonus.id = id
	bonus.display_name = data.get("name", id)
	bonus.effect = _lookup(SocketBonus.EFFECT_IDS, data.get("effect", ""), file, id, "effect") as SocketBonus.Effect
	if bonus.effect in SocketBonus.KIND_EFFECTS:
		bonus.kind = data.get("kind", "")
		if not DamageKinds.is_valid(bonus.kind):
			push_error("ContentDB: %s, '%s': unknown kind '%s'. Allowed: %s" % [file, id, bonus.kind,
					", ".join(PackedStringArray(DamageKinds.NAMES.keys()))])
	if bonus.effect == SocketBonus.Effect.ATTRIBUTE:
		bonus.attribute = _lookup(ATTRIBUTES, data.get("attribute", ""), file, id, "attribute") as ItemAttribute.Type
	if bonus.effect == SocketBonus.Effect.ON_HIT:
		bonus.status_id = data.get("status", "")
		if not _status_effects.has(bonus.status_id):
			push_error("ContentDB: %s, '%s': unknown status '%s' (see status_effects.json)." % [file, id, bonus.status_id])
	if bonus.effect == SocketBonus.Effect.COMBO:
		# The parts are linked when all bonuses exist (_link_socket_combos); levels come from them.
		bonus.combo_factor = float(data.get("combo_factor", 1.0))
		bonus.set_meta("combo_ids", data.get("combo", []))
		data = data.duplicate()
		data["levels"] = [0]
		data["chances"] = [1]
	for value: Variant in data.get("levels", []):
		bonus.levels.append(float(value))
	for value: Variant in data.get("chances", []):
		bonus.chances.append(float(value))
	if bonus.levels.is_empty() or bonus.levels.size() > SocketBonus.MAX_LEVEL:
		push_error("ContentDB: %s, '%s': levels needs 1 to %d values." % [file, id, SocketBonus.MAX_LEVEL])
		if bonus.levels.is_empty():
			bonus.levels.append(0.0)
		bonus.levels.resize(mini(bonus.levels.size(), SocketBonus.MAX_LEVEL))
	if bonus.chances.size() != bonus.levels.size():
		push_error("ContentDB: %s, '%s': chances needs as many values as levels (%d), every level is equally likely now." % [
				file, id, bonus.levels.size()])
		bonus.chances.clear()
		for i in bonus.levels.size():
			bonus.chances.append(1.0)
	for slot: String in data.get("slots", []):
		var type_key: String = slot.get_slice(":", 0)
		if slot.begins_with("weapon:"):
			if not _weapon_types.has(slot.get_slice(":", 1)):
				push_error("ContentDB: %s, '%s': unknown weapon type in slots: '%s'." % [file, id, slot])
		elif not ITEM_TYPES.has(type_key) and not SocketBonus.SLOT_GROUPS.has(type_key):
			push_error("ContentDB: %s, '%s': unknown slot '%s'. Allowed: item types (%s), %s, weapon:<weapon type>." % [
					file, id, slot, ", ".join(PackedStringArray(ITEM_TYPES.keys())),
					", ".join(PackedStringArray(SocketBonus.SLOT_GROUPS.keys()))])
		bonus.slots.append(slot)
	if bonus.slots.is_empty():
		push_error("ContentDB: %s, '%s': no slots." % [file, id])
	bonus.enchant_only = bool(data.get("enchant", false))
	return bonus


# --- Weapon types -------------------------------------------------------------------

## The weapon type with this id (e.g. "sword"). null (with an error) if it does not exist.
static func weapon_type(id: String) -> WeaponType:
	_ensure_loaded()
	return _get_entry(_weapon_types, id, Language.translate("weapon type"))


## Weapon types one station lists ("workbench", "enchanting_table"), in file order.
## All weapon types in the order of weapon_types.json.
static func get_all_weapon_types() -> Array[WeaponType]:
	_ensure_loaded()
	var list: Array[WeaponType] = []
	list.assign(_weapon_types.values())
	return list


static func get_weapon_types(station: StringName) -> Array[WeaponType]:
	_ensure_loaded()
	var list: Array[WeaponType] = []
	for type: WeaponType in _weapon_types.values():
		if type.station == station:
			list.append(type)
	return list


# --- Recipes ------------------------------------------------------------------------

static func recipe(id: String) -> RecipeData:
	_ensure_loaded()
	var key: String = normalize_id(id)
	if not _recipes.has(key):
		push_error("ContentDB: unknown recipe '%s'." % id)
		return null
	return _recipes[key]


static func has_recipe(id: String) -> bool:
	_ensure_loaded()
	return _recipes.has(normalize_id(id))


static func get_all_recipes() -> Array[RecipeData]:
	_ensure_loaded()
	var list: Array[RecipeData] = []
	list.assign(_recipes.values())
	return list


## Recipes of one station ("forge", "anvil", "workbench"), in file order.
static func get_station_recipes(station: StringName) -> Array[RecipeData]:
	var list: Array[RecipeData] = []
	for recipe_data in get_all_recipes():
		if recipe_data.station == station:
			list.append(recipe_data)
	return list


## All molds (forge recipes "mold_<part>") of one metal from materials.json, e.g. "copper",
## without quest parts (items.json "quest_part", the compass): these only come from their dungeons.
static func get_mold_recipes(material_id: String) -> Array[RecipeData]:
	_ensure_loaded()
	var list: Array[RecipeData] = []
	var ingot: String = _materials.get(material_id, {}).get("ingot", "")
	if ingot.is_empty():
		push_error("ContentDB: unknown material '%s' (see materials.json)." % material_id)
		return list
	for recipe_data in get_station_recipes(&"forge"):
		# Quest parts (the desert compass) only come from their own dungeons, never as a random mold.
		var part: ItemData = recipe_data.get_mold_part()
		if part and part.quest_part:
			continue
		if String(recipe_data.id).begins_with("mold_") and recipe_data.ingredients.size() == 1 \
				and recipe_data.ingredients[0].item and String(recipe_data.ingredients[0].item.id) == ingot:
			list.append(recipe_data)
	return list


## Cast metals (materials.json "process" "cast") in the order of materials.json, lowest first.
static func get_cast_metals() -> Array[String]:
	_ensure_loaded()
	var list: Array[String] = []
	for material_id: String in _materials:
		if not material_id.begins_with("_") and _materials[material_id].get("process", "cast") == "cast" 				and not String(_materials[material_id].get("ingot", "")).is_empty():
			list.append(material_id)
	return list


## Metal of an ore or ingot ("iron" for iron ore and the iron ingot: materials.json "ingot"),
## "" for anything else.
static func metal_of(item: ItemData) -> String:
	_ensure_loaded()
	if item == null:
		return ""
	var ingot: ItemData = item.smelt_result if item.type == ItemData.ItemType.ORE else item
	if ingot == null or ingot.type != ItemData.ItemType.INGOT:
		return ""
	for material_id: String in _materials:
		if not material_id.begins_with("_") and String(_materials[material_id].get("ingot", "")) == String(ingot.id):
			return material_id
	return ""


## Story flag from which ore and ingots of this metal drop as loot (materials.json
## "unlock_flag"), "" = from the start.
static func material_unlock_flag(material_id: String) -> String:
	_ensure_loaded()
	return String(_materials.get(material_id, {}).get("unlock_flag", ""))


## How armour of this material is worked (materials.json "armor_detail", see CharacterBaker), or {}.
static func material_armor_detail(material_id: String) -> Dictionary:
	return _materials.get(material_id, {}).get("armor_detail", {})


## How a material is worked (materials.json "process": "cast" = metal, "carve", "tan"), "" if unknown.
static func material_process(material_id: String) -> String:
	_ensure_loaded()
	return String(_materials.get(material_id, {}).get("process", ""))


## Colours of a material (materials.json "colors", 5 shades light to dark), [] if it has none.
static func material_colors(material_id: String) -> Array:
	_ensure_loaded()
	return _materials.get(material_id, {}).get("colors", [])


## Display name of a material ("Kupfer"), the id if it has none.
## Entry of materials.json ({} if unknown), e.g. {"name", "tier", "rarity", ...}.
static func material_info(material_id: String) -> Dictionary:
	_ensure_loaded()
	return _materials.get(material_id, {})


static func material_name(material_id: String) -> String:
	_ensure_loaded()
	return _materials.get(material_id, {}).get("name", material_id)


## A mold and the anvil recipe of its part (e.g. "mold_copper_blade" and "copper_blade").
static func get_mold_unlocks(mold: RecipeData) -> Array[RecipeData]:
	var list: Array[RecipeData] = [mold]
	var part_id: String = String(mold.id).trim_prefix("mold_")
	if has_recipe(part_id):
		list.append(recipe(part_id))
	return list


# --- Fights -------------------------------------------------------------------------

static func status_effect(id: String) -> StatusEffectData:
	return _get_entry(_status_effects, id, Language.translate("status effect"))


## Every status effect of status_effects.json (file order).
static func all_status_effects() -> Array[StatusEffectData]:
	_ensure_loaded()
	var result: Array[StatusEffectData] = []
	result.assign(_status_effects.values())
	return result


## Ids of the hero classes that have skill trees (skill_trees.json).
static func skill_tree_class_ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	result.assign(_skill_trees.keys())
	return result


static func has_status_effect(id: String) -> bool:
	_ensure_loaded()
	return _status_effects.has(id)


static func skill(id: String) -> SkillData:
	return _get_entry(_skills, id, "skill")


## Like skill(), but null without an error (e.g. old saves with removed skills).
static func find_skill(id: String) -> SkillData:
	_ensure_loaded()
	return _skills.get(id)


## The three skill trees of a class: [{"id": String, "name": String, "skills": Array[SkillData]}]
## (empty if skill_trees.json has none for it).
static func skill_trees(class_id: String) -> Array:
	_ensure_loaded()
	return _skill_trees.get(class_id, [])


static func summon_data(id: String) -> SummonData:
	return _get_entry(_summons, id, "summon")


static func enemy(id: String) -> EnemyData:
	return _get_entry(_enemies, id, "enemy")


static func has_enemy(id: String) -> bool:
	_ensure_loaded()
	return _enemies.has(id)


static func dungeon(id: String) -> DungeonData:
	return _get_entry(_dungeons, id, "dungeon")


## All dungeons, easiest (lowest level) first.
static func get_all_dungeons() -> Array[DungeonData]:
	_ensure_loaded()
	var list: Array[DungeonData] = []
	list.assign(_dungeons.values())
	list.sort_custom(func(a: DungeonData, b: DungeonData) -> bool: return a.level < b.level)
	return list


## One section of economy.json ("prices", "customers" or "reputation").
static func economy(section: String) -> Dictionary:
	_ensure_loaded()
	return _economy.get(section, {})


## One section of story.json ("start", "intro", "steps", "npcs", "dialogues", "hints", "skip_flags").
static func story_section(section: String) -> Variant:
	_ensure_loaded()
	return _story.get(section, [] if section in ["intro", "skip_flags", "skip_recipes", "legacy_recipes", "side_dialogues", "overnight", "daily_rewards"] else {})


## One section of house.json ("levels", "shop", "furniture"), see House.
static func house(section: String) -> Variant:
	_ensure_loaded()
	return _house.get(section, [] if section == "levels" else {})


## A value from calendar.json (see GameCalendar).
static func calendar_value(key: String, default: Variant) -> Variant:
	_ensure_loaded()
	return _calendar.get(key, default)


## One section of appearance.json, e.g. "races" or "skin_tones" (id -> entry).
static func appearance_section(section: String) -> Dictionary:
	_ensure_loaded()
	var value: Variant = _appearance.get(section, {})
	return value if value is Dictionary else {}


## A single value of appearance.json (e.g. "base", "portrait_rect").
static func appearance_value(key: String, default: Variant) -> Variant:
	_ensure_loaded()
	return _appearance.get(key, default)


## A number from combat.json (see CombatRules).
static func combat_value(key: String, default: float) -> float:
	_ensure_loaded()
	return float(_combat.get(key, default))


## A list from combat.json (e.g. "parallel_dungeons_flags"), [] if missing.
static func combat_list(key: String) -> Array:
	_ensure_loaded()
	var value: Variant = _combat.get(key, [])
	return value if value is Array else []


## combat.json "dungeon_loot" (more and rarer monster loot, ingots from bosses, see Adventure):
## {"chance_factor", "rarity": [[Rarity.Tier, chance], ...] (highest first), "boss_ingot_chance",
## "boss_ingot_rarity": like "rarity"}. Which ingot: the dungeon's own "boss_ingot" (dungeons.json).
static func dungeon_loot() -> Dictionary:
	_ensure_loaded()
	var data: Dictionary = _combat.get("dungeon_loot", {})
	return {"chance_factor": float(data.get("chance_factor", 1.0)),
			"rarity": _rarity_chances(data.get("rarity", {}), "dungeon_loot"),
			"boss_ingot_chance": float(data.get("boss_ingot_chance", 0.0)),
			"boss_ingot_rarity": _rarity_chances(data.get("boss_ingot_rarity", {}), "dungeon_loot")}


## {"R2": 0.3, "R3": 0.1} -> [[Rarity.Tier, chance], ...], highest tier first.
static func _rarity_chances(data: Dictionary, context: String) -> Array:
	var rarities: Array = []
	for key: String in data:
		rarities.append([_parse_rarity(key, context), float(data[key])])
	rarities.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	return rarities


static func _get_entry(table: Dictionary, id: String, what: String) -> Variant:
	_ensure_loaded()
	var key: String = normalize_id(id)
	if not table.has(key):
		push_error("ContentDB: unknown %s '%s'." % [what, id])
		return null
	return table[key]


# --- Anvil minigame -----------------------------------------------------------------

static func forging_pattern(id: String) -> ForgingPattern:
	return _get_entry(_forging_patterns, id, Language.translate("forging pattern"))


## Pattern an item is forged with: its own "forging_pattern", else the one named like its part
## type ("blade", "pickaxe_head" ...), else "default".
static func forging_pattern_for(item_data: ItemData) -> ForgingPattern:
	_ensure_loaded()
	if item_data:
		if _forging_patterns.has(item_data.forging_pattern):
			return _forging_patterns[item_data.forging_pattern]
		var part_id: String = PART_TYPES.find_key(item_data.part_type) if item_data.part_type != ItemData.PartType.NONE else ""
		if _forging_patterns.has(part_id):
			return _forging_patterns[part_id]
	return _forging_patterns.get(DEFAULT_FORGING_PATTERN)


static func _create_forging_pattern(id: String, data: Dictionary) -> ForgingPattern:
	var pattern := ForgingPattern.new()
	pattern.id = id
	pattern.display_name = data.get("name", id)
	pattern.image = _load_texture(data.get("image", ""), id, "res://assets/sprites/forging/default.png")
	for spot: Dictionary in data.get("spots", []):
		var spot_size := Vector2(float(spot.get("w", 8)), float(spot.get("h", 8)))
		var center := Vector2(float(spot.get("x", 0)), float(spot.get("y", 0)))
		pattern.spots.append(Rect2(center - spot_size / 2.0, spot_size))
	if pattern.spots.is_empty():
		push_error("ContentDB: forging_patterns.json, '%s': no spots." % id)
	return pattern


# --- Loading ------------------------------------------------------------------------

## Reads all content again, e.g. in the new language. Only safe while no game runs (main menu):
## items in an inventory would keep their old objects.
static func reload() -> void:
	for cache: Dictionary in [_materials, _weapon_types, _items, _recipes, _status_effects, _effect_json, _skills,
			_skill_trees, _summons, _enemies, _dungeons, _combat, _economy, _appearance, _story, _calendar, _house,
			_forging_patterns, _socket_bonuses, _dusts, _potions, _brews, _mortar, _achievements, _npcs, _desert, _arena, _leagues, _world_map]:
		cache.clear()
	_loaded = false
	_ensure_loaded()


## An item made of "parts" without its own "icon" (the general hammer, helmet, ring ...) shows the
## parts of the lowest material instead of the default question mark, e.g. in the recipe book,
## shops and the workbench preview. A piece that has its parts still shows those.
static func _give_example_icon(id: String, data: Dictionary) -> void:
	if data.has("icon") or not data.has("parts"):
		return
	var parts: Array[ItemData] = []
	for part_name: String in data["parts"]:
		var part_type: ItemData.PartType = PART_TYPES.get(part_name, ItemData.PartType.NONE)
		if part_type in [ItemData.PartType.NONE, ItemData.PartType.LEATHER, ItemData.PartType.FLETCHING]:
			continue
		var best: ItemData = null
		for candidate: ItemData in _items.values():
			if candidate.part_type == part_type and candidate.icon and (best == null or candidate.material_tier < best.material_tier):
				best = candidate
		if best and not parts.has(best):
			parts.append(best)
	var icon: Texture2D = ItemIcons.compose(parts) if not parts.is_empty() else null
	if icon:
		_items[id].icon = icon


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_materials = _read_json("materials.json")
	var pattern_data: Dictionary = _read_json("forging_patterns.json")
	for id: String in pattern_data:
		_forging_patterns[id] = _create_forging_pattern(id, pattern_data[id])
	var weapon_type_data: Dictionary = _read_json("weapon_types.json")
	for id: String in weapon_type_data:
		_weapon_types[id] = _create_weapon_type(id, weapon_type_data[id])
	var item_data: Dictionary = _read_json("items.json")
	for id: String in item_data:
		_items[id] = _create_item(id, item_data[id])
	for id: String in item_data:
		_link_item(id, item_data[id])
	for id: String in item_data:
		_generate_recipes(id, item_data[id])
	for id: String in item_data:
		_give_example_icon(id, item_data[id])
	_load_extra_recipes(_read_json("recipes.json", true))
	_combat = _read_json("combat.json")
	_economy = _read_json("economy.json")
	_appearance = _read_json("appearance.json")
	_story = _read_json("story.json")
	_calendar = _read_json("calendar.json", true)
	_house = _read_json("house.json", true)
	var effect_data: Dictionary = _read_json("status_effects.json")
	_effect_json = effect_data
	for id: String in effect_data:
		_status_effects[id] = _create_status_effect(id, effect_data[id])
	for effect: StatusEffectData in _status_effects.values():
		if not effect.on_hit_effect_id.is_empty() and not _status_effects.has(effect.on_hit_effect_id):
			push_error("ContentDB: status_effects.json, '%s': on_hit_effect: unknown effect '%s'." % [effect.id, effect.on_hit_effect_id])
			effect.on_hit_effect_id = ""
	for upgrade_item: ItemData in _items.values():
		if upgrade_item.upgrade and not upgrade_item.upgrade.effect_id.is_empty() 				and not _status_effects.has(upgrade_item.upgrade.effect_id):
			push_error("ContentDB: items.json, '%s': upgrade.effect: unknown status effect '%s'." % [upgrade_item.id, upgrade_item.upgrade.effect_id])
			upgrade_item.upgrade.effect_id = ""
	var skill_data: Dictionary = _read_json("skills.json")
	for id: String in skill_data:
		_skills[id] = _create_skill(id, skill_data[id])
	for id: String in skill_data:
		for field: String in ["requires", "requires_also"]:
			var required: String = skill_data[id].get(field, "")
			if not required.is_empty() and not _skills.has(required):
				push_error("ContentDB: skills.json, '%s': %s unknown skill '%s'." % [id, field, required])
		for upgrade: Dictionary in (_skills[id] as SkillData).summon_upgrades:
			if not skill_data.has(upgrade["skill"]):
				push_error("ContentDB: skills.json, '%s': summon_upgrades: unknown skill '%s'." % [id, upgrade["skill"]])
	_load_skill_trees(_read_json("skill_trees.json", true))
	var enemy_data: Dictionary = _read_json("enemies.json")
	for id: String in enemy_data:
		_enemies[id] = _create_enemy(id, enemy_data[id])
	# Helpers a boss calls (enemies.json "summon"), now that every enemy exists.
	for id: String in _enemies:
		var summon: Dictionary = (_enemies[id] as EnemyData).summon
		if summon.is_empty():
			continue
		var pool: Array[EnemyData] = []
		for helper_id: String in summon.get("enemies", []):
			if _enemies.has(helper_id):
				pool.append(_enemies[helper_id])
			else:
				push_error("ContentDB: enemies.json, '%s': summon: unknown enemy '%s'." % [id, helper_id])
		summon["pool"] = pool
		summon["every"] = float(summon.get("every_percent", 25)) / 100.0
		summon["count"] = int(summon.get("count", 2))
	for skill_entry: SkillData in _skills.values():
		for enemy_id: String in skill_entry.summon_enemy_ids:
			if not _enemies.has(enemy_id):
				push_error("ContentDB: skills.json, '%s': summon_enemies: unknown enemy '%s'." % [skill_entry.id, enemy_id])
		skill_entry.summon_enemy_ids.assign(skill_entry.summon_enemy_ids.filter(func(enemy_id: String) -> bool: return _enemies.has(enemy_id)))
	# Phases of a boss (enemies.json "phases"): their skills, now that every skill exists.
	for id: String in _enemies:
		for phase: Dictionary in (_enemies[id] as EnemyData).phases:
			var phase_skills: Array[SkillData] = []
			for skill_id: String in phase.get("skill_ids", []):
				if _skills.has(skill_id):
					phase_skills.append(_skills[skill_id])
				else:
					push_error("ContentDB: enemies.json, '%s': phases: unknown skill '%s'." % [id, skill_id])
			phase["skills"] = phase_skills
	var summons_json: Dictionary = _read_json("summons.json", true)
	for id: String in summons_json:
		_summons[id] = _create_summon(id, summons_json[id])
	for skill_entry: SkillData in _skills.values():
		for summon_id: String in [skill_entry.summon_id] + skill_entry.summon_upgrades.map(func(upgrade: Dictionary) -> String: return upgrade["summon"]):
			if not summon_id.is_empty() and not _summons.has(summon_id):
				push_error("ContentDB: skills.json, '%s': unknown summon '%s' (see summons.json)." % [skill_entry.id, summon_id])
	var dungeon_data: Dictionary = _read_json("dungeons.json")
	for id: String in dungeon_data:
		_dungeons[id] = _create_dungeon(id, dungeon_data[id])
	_load_npcs()
	_achievements = _read_json("achievements.json", true)
	_desert = _read_json("desert.json", true)
	_arena = _read_json("arena.json", true)
	_leagues = _read_json("leagues.json", true)
	_world_map = _read_json("world_map.json", true)
	var socket_data: Dictionary = _read_json("sockets.json")
	for id: String in socket_data:
		_socket_bonuses[id] = _create_socket_bonus(id, socket_data[id])
	_link_socket_combos()
	_load_mortar()


## sockets.json "combo": the bonuses of a combo, its levels = as many as its smallest part has.
static func _link_socket_combos() -> void:
	for bonus: SocketBonus in _socket_bonuses.values():
		if bonus.effect != SocketBonus.Effect.COMBO:
			continue
		for part_id: String in bonus.get_meta("combo_ids", []):
			var part: SocketBonus = _socket_bonuses.get(part_id)
			if part == null or part.effect == SocketBonus.Effect.COMBO:
				push_error("ContentDB: sockets.json, '%s': combo needs other bonuses, '%s' is none." % [bonus.id, part_id])
				continue
			bonus.combo.append(part)
		bonus.remove_meta("combo_ids")
		if bonus.combo.is_empty():
			push_error("ContentDB: sockets.json, '%s': combo is empty." % bonus.id)
			continue
		var count: int = SocketBonus.MAX_LEVEL
		for part in bonus.combo:
			count = mini(count, part.get_max_level())
		bonus.levels.clear()
		bonus.chances.clear()
		for i in count:
			bonus.levels.append(0.0)
			bonus.chances.append(1.0)


static func _read_json(file_name: String, optional: bool = false) -> Dictionary:
	var path: String = CONTENT_DIR + file_name
	if not FileAccess.file_exists(path):
		if not optional:
			push_error("ContentDB: %s is missing." % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("ContentDB: %s line %d: %s" % [file_name, json.get_error_line(), json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		push_error("ContentDB: %s must contain an object { ... }." % file_name)
		return {}
	# JSON has no comments: keys starting with "_" (e.g. "_hilfe") are notes for people, not content.
	var data: Dictionary = json.data
	for key: String in data.keys():
		if key.begins_with("_"):
			data.erase(key)
	# Texts in another language (Language: German text = key, ids are never in the .po files).
	Language.apply()
	if not Language.is_base() and not UNTRANSLATED_FILES.has(file_name):
		Language.translate_data(data)
	return data


## Penetration fields (items, skills, status effects): "armor_pen" / "magic_pen" in percent
## (30 = ignores 30 %), "armor_pen_flat" / "magic_pen_flat" in points. {} when none is set.
static func _parse_penetration(data: Dictionary) -> Dictionary:
	if not (data.has("armor_pen") or data.has("armor_pen_flat") or data.has("magic_pen") or data.has("magic_pen_flat")):
		return {}
	return CombatRules.penetration(float(data.get("armor_pen", 0.0)) / 100.0, float(data.get("armor_pen_flat", 0.0)),
			float(data.get("magic_pen", 0.0)) / 100.0, float(data.get("magic_pen_flat", 0.0)))


static func _create_status_effect(id: String, data: Dictionary) -> StatusEffectData:
	var effect := StatusEffectData.new()
	effect.id = id
	effect.display_name = data.get("name", id)
	effect.description = data.get("description", "")
	effect.icon = _load_texture(data.get("icon", ""), id, DEFAULT_EFFECT_ICON)
	effect.kind = _lookup(EFFECT_KINDS, data.get("kind", "debuff"), "status_effects.json", id, "kind")
	effect.duration = float(data.get("duration", 5.0))
	effect.stacking = _lookup(STACKING, data.get("stacking", "refresh"), "status_effects.json", id, "stacking")
	effect.max_stacks = int(data.get("max_stacks", 1))
	effect.damage_per_second = float(data.get("damage_per_second", 0.0))
	effect.damage_from_magic = float(data.get("damage_from_magic", 0.0)) / 100.0
	effect.damage_attribute = _lookup(ATTRIBUTES, data.get("damage_scaling", "int"), "status_effects.json", id, "damage_scaling")
	effect.element = _lookup(ELEMENTS, data.get("element", "none"), "status_effects.json", id, "element")
	effect.damage_percent_on_expire = float(data.get("damage_percent_on_expire", 0.0))
	effect.damage_percent_per_second = float(data.get("damage_percent_per_second", 0.0))
	effect.heal_percent_per_second = float(data.get("heal_percent_per_second", 0.0))
	effect.block_health_regen = bool(data.get("block_health_regen", false))
	effect.shield_percent = float(data.get("shield_percent", 0.0))
	effect.caster_shield = bool(data.get("caster_shield", false))
	var attributes: Dictionary = data.get("attributes", {})
	for key: String in attributes:
		effect.attribute_multipliers[_lookup(ATTRIBUTES, key, "status_effects.json", id, "attributes")] = float(attributes[key])
	effect.resistances = _parse_resistances(data.get("resistances", {}), "status_effects.json", id)
	effect.crit_chance = float(data.get("crit_chance", 0.0)) / 100.0
	effect.crit_damage = float(data.get("crit_damage", 0.0)) / 100.0
	effect.attack_speed = float(data.get("attack_speed", 0.0)) / 100.0
	effect.damage_bonus = float(data.get("damage_bonus", 0.0)) / 100.0
	effect.armor_percent = float(data.get("armor_percent", 0.0)) / 100.0
	effect.magic_resistance_percent = float(data.get("magic_resistance_percent", 0.0)) / 100.0
	effect.penetration = _parse_penetration(data)
	effect.stun = bool(data.get("stun", false))
	effect.taunt = bool(data.get("taunt", false))
	effect.evasion = float(data.get("evasion", 0.0)) / 100.0
	effect.lifesteal = float(data.get("lifesteal", 0.0)) / 100.0
	effect.cleanse = bool(data.get("cleanse", false))
	effect.revive_percent = float(data.get("revive_percent", 0.0))
	effect.cleanse_count = int(data.get("cleanse_count", 0))
	effect.damage_taken = float(data.get("damage_taken", 0.0)) / 100.0
	effect.silence = bool(data.get("silence", false))
	effect.untargetable = bool(data.get("untargetable", false))
	effect.undying = bool(data.get("undying", false))
	effect.stun_immune = bool(data.get("stun_immune", false))
	effect.thorns = float(data.get("thorns", 0.0)) / 100.0
	effect.guard_share = float(data.get("guard_share", 0.0)) / 100.0
	effect.extra_damage = float(data.get("extra_damage", 0.0)) / 100.0
	effect.extra_damage_kind = data.get("extra_damage_kind", "")
	if effect.extra_damage > 0.0 and not DamageKinds.is_valid(effect.extra_damage_kind):
		push_error("ContentDB: status_effects.json, '%s': extra_damage_kind: unknown kind '%s'." % [id, effect.extra_damage_kind])
		effect.extra_damage = 0.0
	effect.physical_damage = float(data.get("physical_damage", 0.0)) / 100.0
	effect.magic_damage = float(data.get("magic_damage", 0.0)) / 100.0
	effect.mana_regen = float(data.get("mana_regen", 0.0))
	effect.heal_percent_on_expire = float(data.get("heal_percent_on_expire", 0.0))
	effect.on_hit_effect_id = data.get("on_hit_effect", "")
	effect.on_hit_chance = float(data.get("on_hit_chance", 0.0)) / 100.0
	effect.spread_on_death = bool(data.get("spread_on_death", false))
	effect.cleave = bool(data.get("cleave", false))
	effect.shield_attribute = _lookup(ATTRIBUTES, data.get("shield_attribute", "wis"), "status_effects.json", id, "shield_attribute")
	effect.shield_factor = float(data.get("shield_factor", 1.0))
	var mix: Dictionary = data.get("shield_attributes", {})
	for key: String in mix:
		effect.shield_attributes[_lookup(ATTRIBUTES, key, "status_effects.json", id, "shield_attributes")] = float(mix[key])
	effect.color = Color.from_string(data.get("color", "#ffffff"), Color.WHITE)
	effect.aura = data.get("aura", "")
	if not effect.aura.is_empty() and BattleVfx.get_sheet("aura_" + effect.aura).is_empty():
		push_error("ContentDB: status_effects.json, '%s': unknown aura '%s' (sheet aura_<name> in %s)." % [id, effect.aura, BattleVfx.SHEET_DIR])
		effect.aura = ""
	effect.apply_vfx = data.get("apply_vfx", "")
	if not effect.apply_vfx.is_empty() and not BattleVfx.is_kind(effect.apply_vfx):
		push_error("ContentDB: status_effects.json, '%s': unknown apply_vfx '%s'." % [id, effect.apply_vfx])
		effect.apply_vfx = ""
	return effect


## A status effect with some fields changed (skills.json "set" / "per_level" for one skill
## level): the JSON of the effect, "set" on top, "per_level" x (level - 1) added. Numbers in
## dictionaries (e.g. "attributes": {"str": 0.02}) are added one by one.
static func _effect_variant(effect_id: String, changes: Dictionary, per_level: Dictionary, level: int) -> StatusEffectData:
	var data: Dictionary = (_effect_json.get(effect_id, {}) as Dictionary).duplicate(true)
	for key: String in changes:
		data[key] = changes[key]
	_add_per_level(data, per_level, level - 1)
	return _create_status_effect(effect_id, data)


static func _add_per_level(data: Dictionary, per_level: Dictionary, times: int) -> void:
	for key: String in per_level:
		if per_level[key] is Dictionary:
			if not data.get(key) is Dictionary:
				data[key] = {}
			_add_per_level(data[key], per_level[key], times)
		else:
			data[key] = float(data.get(key, 0.0)) + float(per_level[key]) * times


static func _create_skill(id: String, data: Dictionary) -> SkillData:
	var skill_data := SkillData.new()
	skill_data.id = id
	skill_data.display_name = data.get("name", id)
	skill_data.description = data.get("description", "")
	skill_data.icon = _load_texture(data.get("icon", ""), id, DEFAULT_SKILL_ICON)
	# Passives have no cooldown unless they trigger themselves (e.g. Märtyrer).
	skill_data.cooldown = float(data.get("cooldown", 0.0 if data.has("passive") else 5.0))
	skill_data.mana_cost = int(data.get("mana", 0))
	skill_data.mana_per_level = float(data.get("mana_per_level", -1.0))
	skill_data.damage_multiplier = float(data.get("damage", 1.0))
	skill_data.damage_kind = _lookup(DAMAGE_KINDS, data.get("damage_kind", "physical"), "skills.json", id, "damage_kind")
	skill_data.element = _lookup(ELEMENTS, data.get("element", "none"), "skills.json", id, "element")
	skill_data.damage_type = _lookup(DAMAGE_TYPES, data.get("damage_type", "none"), "skills.json", id, "damage_type")
	skill_data.target = _lookup(TARGETS, data.get("target", "enemy"), "skills.json", id, "target")
	skill_data.damage_split = _parse_split(data.get("damage_split", {}), "skills.json", id)
	skill_data.crit_chance = float(data.get("crit_chance", 0.0)) / 100.0
	skill_data.penetration = _parse_penetration(data)
	skill_data.max_level = int(data.get("max_level", data.get("max_rank", 5)))
	skill_data.effects = _parse_skill_effects(data.get("effects", []), id, skill_data.max_level)
	skill_data.pet_effects = _parse_skill_effects(data.get("pet_effects", []), id, skill_data.max_level)
	skill_data.tier = int(data.get("tier", 0))
	skill_data.required_points = int(data.get("points", 0))
	skill_data.required_skill_id = data.get("requires", "")
	skill_data.extra_required_skill_id = data.get("requires_also", "")
	# Passive skills: never used, their values count all the time.
	skill_data.passive_skill = data.has("passive")
	if skill_data.passive_skill:
		skill_data.damage_multiplier = 0.0
		var stats: Dictionary = data["passive"]
		for stat: String in stats:
			var values: Array = stats[stat] if stats[stat] is Array else [stats[stat], 0.0]
			if not SkillData.PASSIVE_NAMES.has(stat):
				push_error("ContentDB: skills.json, '%s': passive: unknown value '%s' (see docs/CONTENT.md)." % [id, stat])
				continue
			skill_data.passive[stat] = [float(values[0]), float(values[1]) if values.size() > 1 else 0.0]
		# "passive_scaling": {"damage_poison": {"int": 0.5}} = +0.5 per intelligence point.
		var scaling: Dictionary = data.get("passive_scaling", {})
		for stat: String in scaling:
			if not skill_data.passive.has(stat) or not scaling[stat] is Dictionary:
				push_error("ContentDB: skills.json, '%s': passive_scaling '%s' needs the value in \"passive\" and {attribute: per point}." % [id, stat])
				continue
			var per_point: Dictionary = {}
			for key: String in scaling[stat]:
				per_point[_lookup(ATTRIBUTES, key, "skills.json", id, "passive_scaling")] = float(scaling[stat][key])
			skill_data.passive_scaling[stat] = per_point
	skill_data.unlock_weapons = data.get("unlock_weapons", {})
	var heal: Array = data.get("heal", [0.0, 0.0])
	skill_data.heal_percent = float(heal[0])
	skill_data.heal_per_level = float(heal[1]) if heal.size() > 1 else 0.0
	skill_data.self_damage_percent = float(data.get("self_damage", 0.0))
	skill_data.hits = maxi(1, int(data.get("hits", 1)))
	skill_data.random_targets = bool(data.get("random_targets", false))
	for split: Dictionary in data.get("hit_splits", []):
		skill_data.hit_splits.append(_parse_split(split, "skills.json", id))
	skill_data.chain_targets = maxi(1, int(data.get("chain", 1)))
	skill_data.chain_falloff = float(data.get("chain_falloff", 0.0)) / 100.0
	skill_data.execute_below = float(data.get("execute_below", 0.0)) / 100.0
	skill_data.execute_factor = float(data.get("execute_factor", 1.0))
	skill_data.bonus_vs_kind = data.get("bonus_vs", "")
	skill_data.bonus_vs_factor = float(data.get("bonus_vs_factor", 1.0))
	skill_data.crit_damage = float(data.get("crit_damage", 0.0)) / 100.0
	skill_data.crit_from_stealth = bool(data.get("crit_from_stealth", false))
	skill_data.reset_on_kill = bool(data.get("reset_on_kill", false))
	skill_data.once_per_dungeon = bool(data.get("once_per_dungeon", false))
	skill_data.base_from = data.get("base_from", {})
	skill_data.summon_id = data.get("summon", "")
	var share: Array = data.get("summon_share", [0.0, 0.0])
	skill_data.summon_share = float(share[0]) / 100.0
	skill_data.summon_share_per_level = (float(share[1]) if share.size() > 1 else 0.0) / 100.0
	skill_data.summon_duration = float(data.get("summon_duration", 0.0))
	for upgrade: Dictionary in data.get("summon_upgrades", []):
		skill_data.summon_upgrades.append({"skill": upgrade.get("skill", ""), "summon": upgrade.get("summon", ""),
				"share": float(upgrade.get("share", 100.0)) / 100.0})
	skill_data.pet_attack = bool(data.get("pet_attack", false))
	skill_data.sacrifice_summon = bool(data.get("sacrifice_summon", false))
	skill_data.detonate_effect_id = data.get("detonate", "")
	if not skill_data.detonate_effect_id.is_empty() and not _status_effects.has(skill_data.detonate_effect_id):
		push_error("ContentDB: skills.json, '%s': detonate: unknown effect '%s'." % [id, skill_data.detonate_effect_id])
		skill_data.detonate_effect_id = ""
	var refresh: Dictionary = data.get("allies_refresh", {})
	skill_data.allies_cooldown = float(refresh.get("cooldown", 0.0))
	var mana: Array = refresh.get("mana_percent", [0.0, 0.0])
	skill_data.allies_mana_percent = float(mana[0])
	skill_data.allies_mana_per_level = float(mana[1]) if mana.size() > 1 else 0.0
	skill_data.heal_allies_from_damage = float(data.get("heal_allies_from_damage", 0.0)) / 100.0
	# Checked once every enemy exists (_ensure_loaded).
	for enemy_id: String in data.get("summon_enemies", []):
		skill_data.summon_enemy_ids.append(enemy_id)
	skill_data.summon_enemy_count = int(data.get("summon_count", 1))
	skill_data.summon_enemy_max = int(data.get("summon_max", 2))
	skill_data.hits_self = bool(data.get("hits_self", false))
	skill_data.random_ally = bool(data.get("random_ally", false))
	skill_data.requires_effect_id = data.get("requires_effect", "")
	if not skill_data.requires_effect_id.is_empty() and not _status_effects.has(skill_data.requires_effect_id):
		push_error("ContentDB: skills.json, '%s': requires_effect: unknown effect '%s'." % [id, skill_data.requires_effect_id])
		skill_data.requires_effect_id = ""
	for type_id: String in data.get("requires_weapon", []):
		if _weapon_types.has(type_id):
			skill_data.required_weapon_types.append(type_id)
		else:
			push_error("ContentDB: skills.json, '%s': requires_weapon: unknown weapon type '%s' (see weapon_types.json)." % [id, type_id])
	skill_data.damage_per_level = float(data.get("damage_per_level", 0.15))
	_parse_skill_scaling(skill_data, data.get("scaling", null), id)
	skill_data.spell_from_weapon = data.get("base", "") == "weapon"
	if data.has("base") and data["base"] != "weapon":
		push_error("ContentDB: skills.json, '%s': base must be \"weapon\" (or left out)." % id)
	skill_data.adds_weapon_damage = bool(data.get("weapon_damage", true))
	skill_data.anim = data.get("anim", "")
	if not skill_data.anim.is_empty() and not FighterMotion.POSES.has(skill_data.anim):
		push_error("ContentDB: skills.json, '%s': unknown anim '%s' (%s)." % [id, skill_data.anim, ", ".join(FighterMotion.POSES)])
		skill_data.anim = ""
	skill_data.vfx = data.get("vfx", "")
	if not skill_data.vfx.is_empty() and not BattleVfx.is_kind(skill_data.vfx):
		push_error("ContentDB: skills.json, '%s': unknown vfx '%s' (%s or a sheet in %s)." % [id, skill_data.vfx, ", ".join(BattleVfx.KINDS), BattleVfx.SHEET_DIR])
		skill_data.vfx = ""
	skill_data.area_vfx = data.get("area_vfx", "")
	if not skill_data.area_vfx in ["", "none"] and BattleVfx.get_sheet(skill_data.area_vfx).is_empty():
		push_error("ContentDB: skills.json, '%s': unknown area_vfx '%s' (a sheet in %s)." % [id, skill_data.area_vfx, BattleVfx.SHEET_DIR])
		skill_data.area_vfx = ""
	return skill_data


## skills.json "scaling": an attribute ("wis" = 100 %) or attribute -> percent ({"agi": 100, "str": 40}).
## Without it: spells intelligence, everything else strength (100 %).
static func _parse_skill_scaling(skill_data: SkillData, raw: Variant, id: String) -> void:
	var shares: Dictionary = {}
	if raw is String:
		shares[raw] = 100.0
	elif raw is Dictionary:
		shares = raw
	elif raw == null:
		shares["int" if skill_data.damage_kind == SkillData.DamageKind.MAGIC else "str"] = 100.0
	else:
		push_error("ContentDB: skills.json, '%s': scaling must be an attribute or {attribute: percent}." % id)
		shares["str"] = 100.0
	var best: float = -1.0
	for key: String in shares:
		var type: int = _lookup(ATTRIBUTES, key, "skills.json", id, "scaling")
		var share: float = float(shares[key]) / 100.0
		skill_data.scaling[type] = skill_data.scaling.get(type, 0.0) + share
		if share > best:
			best = share
			skill_data.scaling_attribute = type


## The "effects" of a skill (format: SkillData.effects). With "set" / "per_level" the effect gets
## one stronger version per skill level.
static func _parse_skill_effects(entries: Array, id: String, max_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var effect_id: String = entry.get("effect", "")
		var effect: StatusEffectData = _status_effects.get(effect_id)
		if effect == null:
			push_error("ContentDB: skills.json, '%s': unknown effect '%s' (see status_effects.json)." % [id, effect_id])
			continue
		var levels: Array[StatusEffectData] = []
		if entry.has("set") or entry.has("per_level"):
			for level in range(1, max_level + 1):
				levels.append(_effect_variant(effect_id, entry.get("set", {}), entry.get("per_level", {}), level))
			effect = levels[0]
		result.append({
			"effect": effect,
			"levels": levels,
			"chance": float(entry.get("chance", 1.0)),
			"chance_per_level": float(entry.get("chance_per_level", 0.0)),
			"target": _lookup(TARGETS, entry.get("target", "enemy"), "skills.json", id, "effects.target"),
			"stacks": int(entry.get("stacks", 1)),
			"duration": float(entry.get("duration", 0.0)),
		})
	return result


## skill_trees.json: per class its trees with the skills in order (unknown ids are left out).
static func _load_skill_trees(data: Dictionary) -> void:
	for class_id: String in data:
		var trees: Array = []
		for tree: Dictionary in data[class_id]:
			var skills: Array[SkillData] = []
			for skill_id: String in tree.get("skills", []):
				if _skills.has(skill_id):
					skills.append(_skills[skill_id])
				else:
					push_error("ContentDB: skill_trees.json, '%s': unknown skill '%s'." % [class_id, skill_id])
			trees.append({"id": tree.get("id", ""), "name": tree.get("name", ""), "skills": skills,
					"outfit": tree.get("outfit", {})})
		_skill_trees[class_id] = trees


static func _create_summon(id: String, data: Dictionary) -> SummonData:
	var summon := SummonData.new()
	summon.id = id
	summon.display_name = data.get("name", id)
	summon.look = _enemies.get(data.get("look", ""))
	if summon.look == null:
		push_error("ContentDB: summons.json, '%s': look: unknown enemy '%s'." % [id, data.get("look", "")])
	summon.tint = Color.from_string(data.get("tint", ""), summon.look.tint if summon.look else Color.WHITE)
	summon.scale = float(data.get("scale", summon.look.scale if summon.look else 1.0))
	summon.damage_split = DamageKinds.normalized(_parse_split(data.get("damage_split", {"physical": 100}), "summons.json", id))
	summon.magic = bool(data.get("magic", false))
	summon.health_factor = float(data.get("health_factor", 1.0))
	summon.attack_speed = float(data.get("attack_speed", 1.0))
	summon.buffable = bool(data.get("buffable", false))
	for skill_id: String in data.get("skills", []):
		if _skills.has(skill_id):
			summon.skills.append(_skills[skill_id])
		else:
			push_error("ContentDB: summons.json, '%s': unknown skill '%s'." % [id, skill_id])
	for entry: Dictionary in data.get("on_hit", []):
		if _status_effects.has(entry.get("effect", "")):
			summon.on_hit.append({"effect": _status_effects[entry["effect"]], "chance": float(entry.get("chance", 0.0))})
		else:
			push_error("ContentDB: summons.json, '%s': on_hit: unknown effect '%s'." % [id, entry.get("effect", "")])
	return summon


static func _create_enemy(id: String, data: Dictionary) -> EnemyData:
	var enemy_data := EnemyData.new()
	enemy_data.id = id
	enemy_data.display_name = data.get("name", id)
	enemy_data.level = int(data.get("level", 1))
	var sprite: Dictionary = data.get("sprite", {})
	enemy_data.sprite_sheet = _load_texture(sprite.get("path", ""), id)
	var frame: Array = sprite.get("frame_size", [16, 16])
	enemy_data.frame_size = Vector2i(int(frame[0]), int(frame[1]))
	enemy_data.frame_count = int(sprite.get("frames", 1))
	if enemy_data.sprite_sheet == null:
		enemy_data.sprite_sheet = load(DEFAULT_ENEMY_SPRITE)
		enemy_data.frame_size = Vector2i(16, 16)
		enemy_data.frame_count = 1
	enemy_data.frames_per_second = float(sprite.get("fps", 4.0))
	var animations: Dictionary = sprite.get("anims", {})
	for key in animations:
		var animation: Dictionary = animations[key]
		var sheet: Texture2D = _load_texture(animation.get("path", ""), id)
		if sheet:
			enemy_data.animations[key] = {"sheet": sheet, "frames": int(animation.get("frames", 1)),
					"fps": float(animation.get("fps", 10.0))}
			if animation.has("frame_size"):
				var size: Array = animation["frame_size"]
				enemy_data.animations[key]["frame_size"] = Vector2i(int(size[0]), int(size[1]))
	enemy_data.scale = float(data.get("scale", 1.0))
	enemy_data.tint = Color.from_string(data.get("tint", "#ffffff"), Color.WHITE)
	enemy_data.hover = bool(data.get("hover", false))
	enemy_data.faces_right = bool(data.get("faces_right", false))
	enemy_data.attack_vfx = data.get("attack_vfx", "")
	var hp: Array = _as_range(data.get("hp", 10))
	enemy_data.health_min = hp[0]
	enemy_data.health_max = hp[1]
	enemy_data.mana = int(data.get("mana", 0))
	var damage: Array = _as_range(data.get("damage", 1))
	enemy_data.damage_min = damage[0]
	enemy_data.damage_max = damage[1]
	enemy_data.attack_interval = float(data.get("attack_interval", 1.0))
	enemy_data.armor = int(data.get("armor", 0))
	enemy_data.magic_resistance = int(data.get("magic_resistance", 0))
	if data.has("damage_split"):
		enemy_data.damage_split = _parse_split(data["damage_split"], "enemies.json", id)
	elif data.has("damage_type"):
		enemy_data.damage_split = _parse_split({data["damage_type"]: 1}, "enemies.json", id)
	var magic: Array = _as_range(data.get("magic_damage", 0))
	enemy_data.magic_damage_min = magic[0]
	enemy_data.magic_damage_max = magic[1]
	enemy_data.resistances = _parse_resistances(data.get("resistances", {}), "enemies.json", id)
	enemy_data.crit_chance = float(data.get("crit_chance", 0.0)) / 100.0
	enemy_data.health_regen = float(data.get("hp_regen", 0.0))
	enemy_data.mana_regen = float(data.get("mana_regen", 0.0))
	var attributes: Dictionary = data.get("attributes", {})
	for key: String in attributes:
		enemy_data.attributes[_lookup(ATTRIBUTES, key, "enemies.json", id, "attributes")] = int(attributes[key])
	for skill_id: String in data.get("skills", []):
		if _skills.has(skill_id):
			enemy_data.skills.append(_skills[skill_id])
		else:
			push_error("ContentDB: enemies.json, '%s': unknown skill '%s'." % [id, skill_id])
	for entry: Dictionary in data.get("on_hit", []):
		if _status_effects.has(entry.get("effect", "")):
			enemy_data.on_hit.append({"effect": _status_effects[entry["effect"]], "chance": float(entry.get("chance", 0.0)) / 100.0})
		else:
			push_error("ContentDB: enemies.json, '%s': on_hit: unknown status effect '%s'." % [id, entry.get("effect", "")])
	for drop: Dictionary in data.get("drops", []):
		# "sword:copper_blade+copper_handle" = a whole weapon with its parts.
		var spec: String = str(drop.get("item", ""))
		var drop_item_id: String = spec.get_slice(":", 0)
		if not _items.has(drop_item_id):
			push_error("ContentDB: enemies.json, '%s': unknown drop item '%s'." % [id, spec])
			continue
		var amount: Array = _as_range(drop.get("amount", 1))
		# Chances of a better rarity, highest first: [[Rarity.Tier, chance], ...].
		var rarities: Array = _rarity_chances(drop.get("rarity", {}), id)
		enemy_data.drops.append({"item": _items[drop_item_id], "spec": spec if ":" in spec else "",
				"chance": float(drop.get("chance", 1.0)), "min": amount[0], "max": amount[1], "rarities": rarities})
	enemy_data.experience = int(data.get("exp", 0))
	enemy_data.back_row = data.get("row", "front") == "back"
	enemy_data.summon = data.get("summon", {}).duplicate()
	enemy_data.summon_shout = data.get("summon_shout", enemy_data.summon_shout)
	enemy_data.shroud_effect_id = data.get("shroud", "")
	if not enemy_data.shroud_effect_id.is_empty() and not _status_effects.has(enemy_data.shroud_effect_id):
		push_error("ContentDB: enemies.json, '%s': shroud: unknown status effect '%s'." % [id, enemy_data.shroud_effect_id])
		enemy_data.shroud_effect_id = ""
	var split: Dictionary = data.get("split", {})
	if not split.is_empty():
		enemy_data.split = {"below": float(split.get("below_percent", 25)) / 100.0, "count": maxi(1, int(split.get("count", 2))),
				"share": float(split.get("share_percent", 50)) / 100.0, "size": float(split.get("size", 0.75)),
				"times": maxi(1, int(split.get("times", 2)))}
	var regrow: Dictionary = data.get("regrow", {})
	if not regrow.is_empty():
		var shares: Array[float] = []
		for percent in regrow.get("health_percent", [50]):
			shares.append(clampf(float(percent) / 100.0, 0.01, 1.0))
		enemy_data.regrow = {"group": str(regrow.get("group", id)), "seconds": maxf(1.0, float(regrow.get("seconds", 30))),
				"health": shares, "text": str(regrow.get("text", ""))}
	enemy_data.body = str(data.get("body", ""))
	enemy_data.body_label = str(data.get("body_label", ""))
	var absorb: Dictionary = data.get("absorb", {})
	for kind: String in absorb:
		if DamageKinds.is_valid(kind):
			enemy_data.absorb[kind] = float(absorb[kind]) / 100.0
		else:
			push_error("ContentDB: enemies.json, '%s': absorb: unknown damage kind '%s'." % [id, kind])
	for phase_data: Dictionary in data.get("phases", []):
		enemy_data.phases.append(_parse_phase(phase_data, enemy_data))
	return enemy_data


## One more health bar of a boss (enemies.json "phases"); values it leaves out stay as before.
## Its skill ids are turned into skills in _ensure_loaded.
static func _parse_phase(data: Dictionary, enemy_data: EnemyData) -> Dictionary:
	var hp: Array = _as_range(data.get("hp", [enemy_data.health_min, enemy_data.health_max]))
	var phase: Dictionary = {"name": data.get("name", ""), "text": data.get("text", ""), "hp_min": hp[0], "hp_max": hp[1],
			"skill_ids": data.get("skills", [])}
	if data.has("damage"):
		var damage: Array = _as_range(data["damage"])
		phase["damage_min"] = damage[0]
		phase["damage_max"] = damage[1]
	if data.has("magic_damage"):
		var magic: Array = _as_range(data["magic_damage"])
		phase["magic_min"] = magic[0]
		phase["magic_max"] = magic[1]
	for key: String in ["attack_interval", "armor", "magic_resistance", "hp_regen", "scale", "mana_regen"]:
		if data.has(key):
			phase[key] = float(data[key])
	return phase


static func _create_dungeon(id: String, data: Dictionary) -> DungeonData:
	var dungeon_data := DungeonData.new()
	dungeon_data.id = id
	dungeon_data.display_name = data.get("name", id)
	dungeon_data.description = data.get("description", "")
	dungeon_data.level = int(data.get("level", 1))
	dungeon_data.required_flag = data.get("required_flag", "")
	dungeon_data.hidden = bool(data.get("hidden", false))
	dungeon_data.gone_flag = data.get("gone_flag", "")
	dungeon_data.required_dungeon = data.get("required_dungeon", "")
	dungeon_data.cost = int(data.get("cost", 0))
	dungeon_data.free_until_won = bool(data.get("free_until_won", false))
	dungeon_data.stamina_cost = int(data.get("stamina", combat_value("dungeon_stamina", 20.0)))
	dungeon_data.stage_count = int(data.get("stages", 10))
	dungeon_data.region = data.get("region", Language.translate(DungeonData.DEFAULT_REGION))
	dungeon_data.time_limit = float(data.get("time_limit", DungeonData.DEFAULT_TIME_LIMIT))
	var enemy_scale: Dictionary = data.get("enemy_scale", {})
	dungeon_data.enemy_health_factor = float(enemy_scale.get("health", 1.0))
	dungeon_data.enemy_damage_factor = float(enemy_scale.get("damage", 1.0))
	dungeon_data.battle_background = _load_texture(data.get("background", ""), id)
	dungeon_data.background_mirror = bool(data.get("background_mirror", false))
	dungeon_data.default_wave = _parse_wave(data.get("enemies", {}), id, "enemies")
	var special: Dictionary = data.get("special_stages", {})
	for key: String in special:
		var stage: int = int(key)
		if stage < 1 or stage > dungeon_data.stage_count:
			push_error("ContentDB: dungeons.json, '%s': special stage %s is outside 1-%d." % [id, key, dungeon_data.stage_count])
			continue
		var wave_data: Dictionary = special[key]
		# Without its own pool a special stage draws its extra enemies from the normal pool.
		if not wave_data.has("pool"):
			wave_data = wave_data.duplicate()
			wave_data["pool"] = data.get("enemies", {}).get("pool", [])
		dungeon_data.special_waves[stage] = _parse_wave(wave_data, id, "special_stages." + key)
	var rewards: Dictionary = data.get("rewards", {})
	dungeon_data.reward_gold = _parse_chance_amount(rewards.get("gold", 0))
	dungeon_data.reward_experience = _parse_chance_amount(rewards.get("exp", 0))
	dungeon_data.drop_factor = float(rewards.get("drop_factor", 1.0))
	if rewards.has("random_mold"):
		var mold: Dictionary = rewards["random_mold"]
		if _materials.has(mold.get("material", "")):
			dungeon_data.random_mold_material = mold["material"]
			dungeon_data.random_mold_chance = float(mold.get("chance", 1.0))
		else:
			push_error("ContentDB: dungeons.json, '%s': random_mold has unknown material '%s'." % [id, mold.get("material", "")])
	for metal in rewards.get("early_metals", []):
		if _materials.has(str(metal)):
			dungeon_data.early_metals.append(str(metal))
		else:
			push_error("ContentDB: dungeons.json, '%s': early_metals has unknown material '%s'." % [id, metal])
	if rewards.has("boss_ingot"):
		if _items.has(rewards["boss_ingot"]):
			dungeon_data.boss_ingot = _items[rewards["boss_ingot"]]
		else:
			push_error("ContentDB: dungeons.json, '%s': unknown boss_ingot '%s'." % [id, rewards["boss_ingot"]])
	for entry: Dictionary in rewards.get("items", []):
		if not _items.has(entry.get("item", "")):
			push_error("ContentDB: dungeons.json, '%s': unknown reward item '%s'." % [id, entry.get("item", "")])
			continue
		var amount: Array = _as_range(entry.get("amount", 1))
		dungeon_data.reward_items.append({"item": _items[entry["item"]], "min": amount[0], "max": amount[1],
				"chance": float(entry.get("chance", 1.0))})
	for recipe_id: String in rewards.get("recipes", []):
		if _recipes.has(recipe_id):
			dungeon_data.reward_recipe_ids.append(recipe_id)
		else:
			push_error("ContentDB: dungeons.json, '%s': unknown reward recipe '%s'." % [id, recipe_id])
	return dungeon_data


## Gold/EXP reward: a number, [min, max] or {"amount": number or [min, max], "chance": 0-1}
## -> {"min", "max", "chance"}.
static func _parse_chance_amount(value: Variant) -> Dictionary:
	var data: Dictionary = value if value is Dictionary else {"amount": value}
	var amount: Array = _as_range(data.get("amount", 0))
	return {"min": amount[0], "max": amount[1], "chance": float(data.get("chance", 1.0))}


## One wave: "type", "fixed" (enemy ids that always come), "count" (how many from the pool)
## and "pool" (entries {"enemy", "chance", "from_stage", "to_stage"}).
static func _parse_wave(data: Dictionary, id: String, field: String) -> Dictionary:
	var wave: Dictionary = {
		"type": _lookup(STAGE_TYPES, data.get("type", "normal"), "dungeons.json", id, field + ".type"),
		"count": _as_range(data.get("count", 1 if data.get("fixed", []).is_empty() else 0)),
		"fixed": [],
		"pool": [],
	}
	for enemy_id: String in data.get("fixed", []):
		if _enemies.has(enemy_id):
			wave["fixed"].append(_enemies[enemy_id])
		else:
			push_error("ContentDB: dungeons.json, '%s', %s: unknown enemy '%s'." % [id, field, enemy_id])
	for entry: Dictionary in data.get("pool", []):
		if not _enemies.has(entry.get("enemy", "")):
			push_error("ContentDB: dungeons.json, '%s', %s: unknown enemy '%s'." % [id, field, entry.get("enemy", "")])
			continue
		wave["pool"].append({"enemy": _enemies[entry["enemy"]], "chance": float(entry.get("chance", 1.0)),
				"from": int(entry.get("from_stage", 1)), "to": int(entry.get("to_stage", 0))})
	if wave["fixed"].is_empty() and wave["pool"].is_empty():
		push_error("ContentDB: dungeons.json, '%s', %s: no enemies." % [id, field])
	return wave


## 5 -> [5, 5], [3, 7] -> [3, 7].
static func _as_range(value: Variant) -> Array:
	if value is Array:
		return [int(value[0]), int(value[value.size() - 1])]
	return [int(value), int(value)]


static func _create_weapon_type(id: String, data: Dictionary) -> WeaponType:
	var type := WeaponType.new()
	type.id = id
	type.display_name = data.get("name", id)
	type.hands = _lookup(HANDS, data.get("hands", "one"), "weapon_types.json", id, "hands")
	type.station = StringName(data.get("station", "workbench"))
	type.attack_speed = maxf(float(data.get("attack_speed", 1.0)), 0.1)
	type.uses_arrows = bool(data.get("uses_arrows", false))
	type.attack_anim = data.get("attack_anim", "swing")
	type.hit_vfx = data.get("hit_vfx", "")
	if not FighterMotion.POSES.has(type.attack_anim):
		push_error("ContentDB: weapon_types.json, '%s': unknown attack_anim '%s' (%s)." % [id, type.attack_anim, ", ".join(FighterMotion.POSES)])
		type.attack_anim = "swing"
	for class_id: String in data.get("classes", []):
		if HeroClass.exists(class_id):
			type.classes.append(class_id)
		else:
			push_error("ContentDB: weapon_types.json, '%s': unknown class '%s' (see data/hero_classes/)." % [id, class_id])
	return type


static func _create_item(id: String, data: Dictionary) -> ItemData:
	var item_data := ItemData.new()
	item_data.id = id
	item_data.display_name = data.get("name", id)
	item_data.description = data.get("description", "")
	item_data.type = _lookup(ITEM_TYPES, data.get("type", "material"), "items.json", id, "type")
	item_data.value = int(data.get("value", 1))
	item_data.story_item = bool(data.get("story_item", false))
	item_data.mold_shape = data.get("mold_shape", "")
	item_data.quest_part = bool(data.get("quest_part", false))
	item_data.sell_price = int(data.get("sell_price", -1))
	item_data.sell_price_factor = float(data.get("sell_price_factor", 0.0))
	# Pictures bigger than a slot (e.g. 32x32 helmets) are drawn on 16x16 with all their pixels.
	# Shown centred; composed items layer the pictures at their own place (layer_icon).
	var picture: Texture2D = _load_texture(data.get("icon", ""), id, DEFAULT_ITEM_ICON)
	var icon_frames: int = int(data.get("icon_frames", 1))
	if icon_frames > 1 and data.has("icon"):
		# Animated icon (holy crystals): a strip of frames, played at "icon_fps" or, with
		# "icon_slosh", moved by the player's walking (WaterSlosh).
		var animated: AnimatedTexture = ItemIcons.animated(picture, icon_frames, float(data.get("icon_fps", 10.0)))
		if bool(data.get("icon_slosh", false)):
			WaterSlosh.register(animated)
		item_data.layer_icon = HiResTexture.for_item_icon(animated)
		item_data.icon = item_data.layer_icon
	else:
		item_data.layer_icon = HiResTexture.for_item_icon(picture)
		item_data.icon = HiResTexture.for_item_icon(ItemIcons.centered(picture))
	item_data.own_icon = bool(data.get("own_icon", false))
	for part_id: String in data.get("part_icons", {}):
		var part_picture: Texture2D = _load_texture(data["part_icons"][part_id], id, DEFAULT_ITEM_ICON)
		item_data.part_icons[StringName(part_id)] = HiResTexture.for_item_icon(ItemIcons.centered(part_picture))
	item_data.is_soil = bool(data.get("soil", false))
	item_data.soil_bonus = float(data.get("soil_bonus", 0.0))
	item_data.part_type = _lookup(PART_TYPES, data.get("part", ""), "items.json", id, "part") if data.has("part") else ItemData.PartType.NONE
	# Equipment (weapons, armor, jewelry, tools) and forged/carved parts (blades, grips, plates ...)
	# never stack, whatever "stack" says. Leather and feathers (fletching) are materials and stack.
	var single: bool = item_data.is_equipment() or item_data.part_type not in [ItemData.PartType.NONE, ItemData.PartType.LEATHER,
			ItemData.PartType.FLETCHING]
	item_data.max_stack = 1 if single else int(data.get("stack", 99))
	item_data.layer_order = int(data.get("layer", 0))
	var material: Dictionary = _get_material(data.get("material", ""), id)
	item_data.material_name = material.get("name", "")
	item_data.material_id = data.get("material", "") if not material.is_empty() else ""
	item_data.base_rarity = _parse_rarity(data.get("rarity", material.get("rarity", "R1")), id)
	item_data.material_tier = int(material.get("tier", 0))
	var damage: Array = data.get("damage", [0, 0])
	item_data.damage_min = int(damage[0])
	item_data.damage_max = int(damage[damage.size() - 1])
	item_data.armor = int(data.get("armor", 0))
	item_data.magic_resistance = int(data.get("magic_resistance", 0))
	item_data.damage_type = _lookup(DAMAGE_TYPES, data.get("damage_type", "none"), "items.json", id, "damage_type")
	item_data.element = _lookup(ELEMENTS, data.get("element", "none"), "items.json", id, "element")
	var magic: Array = _as_range(data.get("magic_damage", 0))
	item_data.magic_damage_min = magic[0]
	item_data.magic_damage_max = magic[1]
	item_data.damage_split = _parse_split(data.get("damage_split", {}), "items.json", id)
	item_data.resistances = _parse_resistances(data.get("resistances", {}), "items.json", id)
	item_data.crit_chance = float(data.get("crit_chance", 0.0)) / 100.0
	item_data.crit_damage = float(data.get("crit_damage", 0.0)) / 100.0
	item_data.penetration = _parse_penetration(data)
	var attributes: Dictionary = data.get("attributes", {})
	for key: String in attributes:
		item_data.attributes.append(ItemAttribute.create(_lookup(ATTRIBUTES, key, "items.json", id, "attributes"), int(attributes[key])))
	item_data.effect = data.get("effect", "")
	_parse_potion_fields(item_data, data, "items.json", id)
	item_data.smelt_time = float(data.get("smelt_time", 10.0))
	item_data.heat_charges = int(data.get("heat", 0))
	item_data.smelt_charges = int(data.get("smelt_charges", 1))
	item_data.mining_damage = int(data.get("mining_damage", 0))
	item_data.chopping_damage = int(data.get("chopping_damage", 0))
	if data.has("purse_gold"):
		item_data.purse_gold = _as_range(data["purse_gold"])
	item_data.move_speed = int(data.get("move_speed", 0))
	item_data.forge_quality = int(data.get("forge_quality", 0))
	item_data.minigame_calm = clampi(int(data.get("minigame_calm", 0)), 0, 90)
	item_data.inventory_slots = maxi(0, int(data.get("inventory_slots", 0)))
	item_data.water_charges = maxi(0, int(data.get("water_charges", 0)))
	item_data.loot_luck = float(data.get("loot_luck", 0.0))
	item_data.quiver_slots = maxi(0, int(data.get("quiver_slots", 0)))
	if data.has("upgrade"):
		item_data.upgrade = _create_upgrade(id, data["upgrade"])
	if data.has("jewel"):
		item_data.jewel_effects = _create_jewel_effects(id, data["jewel"])
	item_data.forging_pattern = data.get("forging_pattern", "")
	if not item_data.forging_pattern.is_empty() and not _forging_patterns.has(item_data.forging_pattern):
		push_error("ContentDB: items.json, '%s': unknown forging_pattern '%s' (see forging_patterns.json)." % [id, item_data.forging_pattern])
		item_data.forging_pattern = ""
	if data.has("weapon_type"):
		if _weapon_types.has(data["weapon_type"]):
			item_data.weapon_type = _weapon_types[data["weapon_type"]]
		else:
			push_error("ContentDB: items.json, '%s': unknown weapon_type '%s' (see weapon_types.json)." % [id, data["weapon_type"]])
	return item_data


## Upgrade-table block of a material: {"name", "targets", "damage_kind", "effect", "arrows",
## "resistance_kind", "tiers": {"R1": {"damage": [1, 2], "chance": 10, "resistance": 2}, ...}}
## (chance in percent).
## items.json "jewel" of a crystal: {"ring": {stat: value}, "amulet": {stat: value}}; unknown
## kinds or stats (Jewelry.STATS) are left out with an error.
static func _create_jewel_effects(id: String, data: Dictionary) -> Dictionary:
	var effects: Dictionary = {}
	for kind: String in data:
		if not Jewelry.KINDS.has(kind):
			push_error("ContentDB: items.json, '%s': jewel: unknown kind '%s' (%s)." % [id, kind, ", ".join(Jewelry.KINDS)])
			continue
		var stats: Dictionary = {}
		for stat: String in data[kind]:
			if Jewelry.STATS.has(stat):
				stats[stat] = float(data[kind][stat])
			else:
				push_error("ContentDB: items.json, '%s': jewel %s: unknown effect '%s'." % [id, kind, stat])
		effects[kind] = stats
	return effects


## The effect id is checked later (status effects are loaded after the items).
static func _create_upgrade(id: String, data: Dictionary) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.display_name = data.get("name", Language.translate("Aufgewertet"))
	for target: String in data.get("targets", []):
		if target in ["weapon", "armor", "arrows"]:
			upgrade.targets.append(target)
		else:
			push_error("ContentDB: items.json, '%s': upgrade.targets: unknown target '%s' (weapon, armor, arrows)." % [id, target])
	upgrade.damage_kind = data.get("damage_kind", DamageKinds.PHYSICAL)
	if not DamageKinds.is_valid(upgrade.damage_kind):
		push_error("ContentDB: items.json, '%s': upgrade.damage_kind: unknown kind '%s'." % [id, upgrade.damage_kind])
		upgrade.damage_kind = DamageKinds.PHYSICAL
	upgrade.effect_id = data.get("effect", "")
	upgrade.arrows_per_use = maxi(1, int(data.get("arrows", 99)))
	upgrade.resistance_kind = data.get("resistance_kind", "")
	if not upgrade.resistance_kind.is_empty() and not DamageKinds.is_valid(upgrade.resistance_kind):
		push_error("ContentDB: items.json, '%s': upgrade.resistance_kind: unknown kind '%s'." % [id, upgrade.resistance_kind])
		upgrade.resistance_kind = ""
	var tiers: Dictionary = data.get("tiers", {})
	for key: String in tiers:
		var tier: Dictionary = tiers[key]
		var damage: Array = _as_range(tier.get("damage", 0))
		upgrade.tiers.append([_parse_rarity(key, id), {"damage_min": damage[0], "damage_max": damage[1],
				"chance": float(tier.get("chance", 0.0)) / 100.0, "resistance": float(tier.get("resistance", 0.0))}])
	upgrade.tiers.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if upgrade.tiers.is_empty():
		push_error("ContentDB: items.json, '%s': upgrade needs at least one entry in \"tiers\"." % id)
	return upgrade


## Second pass: references to other items.
static func _link_item(id: String, data: Dictionary) -> void:
	if data.has("smelt_to"):
		if _items.has(data["smelt_to"]):
			_items[id].smelt_result = _items[data["smelt_to"]]
		else:
			push_error("ContentDB: items.json, '%s': smelt_to '%s' does not exist." % [id, data["smelt_to"]])
	if data.has("tan_to"):
		if _items.has(data["tan_to"]):
			_items[id].tan_result = _items[data["tan_to"]]
		else:
			push_error("ContentDB: items.json, '%s': tan_to '%s' does not exist." % [id, data["tan_to"]])
	if data.has("vial_to"):
		if _items.has(data["vial_to"]):
			_items[id].vial_result = _items[data["vial_to"]]
		else:
			push_error("ContentDB: items.json, '%s': vial_to '%s' does not exist." % [id, data["vial_to"]])
	if data.has("grind_to"):
		if _items.has(data["grind_to"]):
			_items[id].grind_result = _items[data["grind_to"]]
		else:
			push_error("ContentDB: items.json, '%s': grind_to '%s' does not exist." % [id, data["grind_to"]])
	var plant: Dictionary = data.get("plant", {})
	if not plant.is_empty():
		if _items.has(plant.get("grows", "")):
			_items[id].grows_into = _items[plant["grows"]]
			_items[id].grow_days = maxi(1, int(plant.get("days", 3)))
			_items[id].harvest_amount = maxi(1, int(plant.get("amount", 1)))
			_items[id].bloom_texture = _load_texture(plant.get("bloom", ""), id)
			for path: String in plant.get("stages", []):
				var stage: Texture2D = _load_texture(path, id)
				if stage:
					_items[id].stage_textures.append(stage)
			_items[id].full_moon_bonus = bool(plant.get("full_moon", false))
		else:
			push_error("ContentDB: items.json, '%s': plant.grows '%s' does not exist." % [id, plant.get("grows", "")])
	var alloy: Dictionary = data.get("alloy", {})
	for ingredient_id: String in alloy:
		if _items.has(ingredient_id):
			_items[id].alloy_ingredients[_items[ingredient_id]] = maxi(1, int(alloy[ingredient_id]))
		else:
			push_error("ContentDB: items.json, '%s': alloy ingredient '%s' does not exist." % [id, ingredient_id])
	if not alloy.is_empty() and alloy.size() != 2:
		push_error("ContentDB: items.json, '%s': alloy needs exactly 2 different items (the smelter has 2 slots)." % id)


static func _generate_recipes(id: String, data: Dictionary) -> void:
	var item_data: ItemData = _items[id]
	var locked: bool = bool(data.get("locked", false))
	# Weapons with a weapon_type appear in its category (e.g. "Schwerter").
	var category: String = data.get("category", item_data.weapon_type.display_name if item_data.weapon_type else "")
	if item_data.part_type != ItemData.PartType.NONE and data.has("material"):
		var material: Dictionary = _get_material(data["material"], id)
		match material.get("process", "cast"):
			"cast":
				var tab: RecipeData.Tab = _lookup(TABS, data.get("tab", "weapon"), "items.json", id, "tab")
				var blank: ItemData = _create_hot_blank(id, data, material)
				var ingot: ItemData = _items.get(material.get("ingot", ""))
				if ingot == null:
					push_error("ContentDB: materials.json: material of '%s' has no valid \"ingot\"." % id)
					return
				_add_recipe("mold_" + id, &"forge", Language.translate("Gussform: ") + item_data.display_name,
						[_ingredient(ingot, int(data.get("ingots", 1)))], blank, false, tab, category, locked)
				_add_recipe(id, &"anvil", "", [_ingredient(blank)], item_data, true, tab, category, locked)
			"carve":
				var raw: ItemData = _items.get(material.get("raw", ""))
				if raw == null:
					push_error("ContentDB: materials.json: material of '%s' has no valid \"raw\"." % id)
					return
				var tab: RecipeData.Tab = _lookup(TABS, data.get("tab", "accessory"), "items.json", id, "tab")
				# "station": carved somewhere else (e.g. bow parts at the bow table).
				_add_recipe(id, StringName(data.get("station", "workbench")), item_data.display_name, [_ingredient(raw)],
						item_data, false, tab, category, locked)
	# Workbench: "parts" (any part of that type) plus "needs" (fixed items, e.g. {"rope": 1}).
	# "part_materials" limits a part type to some materials (pickaxe: {"shaft": ["wood"]}).
	# The same part type several times is one ingredient with that amount (cloak: 3 leather).
	if data.has("parts") or data.has("needs"):
		var ingredients: Array[Ingredient] = []
		for part_name: String in data.get("parts", []):
			var part_type: ItemData.PartType = _lookup(PART_TYPES, part_name, "items.json", id, "parts")
			var existing: Ingredient = null
			for other in ingredients:
				if other.part_type == part_type:
					existing = other
			if existing:
				existing.amount += 1
				continue
			var ingredient := Ingredient.new()
			ingredient.part_type = part_type
			for material_id: String in data.get("part_materials", {}).get(part_name, []):
				if _materials.has(material_id):
					ingredient.materials.append(material_id)
				else:
					push_error("ContentDB: items.json, '%s': part_materials has unknown material '%s'." % [id, material_id])
			ingredients.append(ingredient)
		var needs: Dictionary = data.get("needs", {})
		for need_id: String in needs:
			if _items.has(need_id):
				ingredients.append(_ingredient(_items[need_id], int(needs[need_id])))
			else:
				push_error("ContentDB: items.json, '%s': needs unknown item '%s'." % [id, need_id])
		var default_tab: String = "weapon" if item_data.is_weapon() else ("jewelry" if item_data.type == ItemData.ItemType.ACCESSORY else "armor")
		var tab: RecipeData.Tab = _lookup(TABS, data.get("tab", default_tab), "items.json", id, "tab")
		# "station": built somewhere else (bows and arrows at the bow table); "amount": pieces per build.
		var recipe_data: RecipeData = _add_recipe(id, StringName(data.get("station", "workbench")), item_data.display_name,
				ingredients, item_data, false, tab, category, locked)
		recipe_data.result_amount = maxi(1, int(data.get("amount", 1)))


## Hot blank of a cast part, e.g. "Heißer Eisenbarren (Klinge)".
static func _create_hot_blank(part_id: String, data: Dictionary, material: Dictionary) -> ItemData:
	var part: ItemData = _items[part_id]
	var blank := ItemData.new()
	blank.id = "hot_%s_blank" % part_id
	blank.display_name = Language.translate("Heißer %sbarren (%s)") % [material.get("name", ""), Language.translate(ItemData.PART_TYPE_NAMES[part.part_type])]
	blank.description = Language.translate("Glühender Barren in Form von „%s“. Am Amboss fertig schmieden.") % part.display_name
	blank.type = ItemData.ItemType.PART
	blank.base_rarity = part.base_rarity
	blank.material_id = part.material_id
	blank.material_tier = part.material_tier
	var icon_path: String = data.get("hot_icon", "res://assets/sprites/items/%s.png" % blank.id)
	blank.layer_icon = _load_texture(icon_path if ResourceLoader.exists(icon_path) else DEFAULT_HOT_ICON, blank.id)
	blank.icon = ItemIcons.centered(blank.layer_icon)
	_items[blank.id] = blank
	return blank


static func _load_extra_recipes(data: Dictionary) -> void:
	for id: String in data:
		var entry: Dictionary = data[id]
		var result: ItemData = _items.get(entry.get("result", ""))
		if result == null:
			push_error("ContentDB: recipes.json, '%s': unknown result '%s'." % [id, entry.get("result", "")])
			continue
		var ingredients: Array[Ingredient] = []
		for need: Dictionary in entry.get("ingredients", []):
			var ingredient := Ingredient.new()
			ingredient.amount = int(need.get("amount", 1))
			if need.has("part"):
				ingredient.part_type = _lookup(PART_TYPES, need["part"], "recipes.json", id, "part")
				# "materials": only parts of these metals, e.g. a bronze staff needs a bronze rod.
				for material_id: String in need.get("materials", []):
					if _materials.has(material_id):
						ingredient.materials.append(material_id)
					else:
						push_error("ContentDB: recipes.json, '%s': unknown material '%s'." % [id, material_id])
			elif _items.has(need.get("item", "")):
				ingredient.item = _items[need["item"]]
			else:
				push_error("ContentDB: recipes.json, '%s': unknown ingredient %s." % [id, need])
				continue
			if need.has("min_rarity"):
				ingredient.min_rarity = _parse_rarity(need["min_rarity"], id)
			ingredients.append(ingredient)
		var recipe_data: RecipeData = _add_recipe(id, StringName(entry.get("station", "workbench")), entry.get("name", ""),
				ingredients, result, bool(entry.get("hot", false)),
				_lookup(TABS, entry.get("tab", "weapon"), "recipes.json", id, "tab"), entry.get("category", ""),
				bool(entry.get("locked", false)))
		recipe_data.result_amount = int(entry.get("amount", 1))
		recipe_data.group = String(entry.get("group", ""))
		recipe_data.group_slot_name = String(entry.get("group_slot", ""))


static func _add_recipe(id: String, station: StringName, display_name: String, ingredients: Array[Ingredient],
		result: ItemData, hot: bool, tab: RecipeData.Tab, category: String, locked: bool) -> RecipeData:
	if _recipes.has(id):
		push_error("ContentDB: recipe id '%s' exists twice." % id)
	var recipe_data := RecipeData.new()
	recipe_data.id = id
	recipe_data.station = station
	recipe_data.display_name = display_name
	recipe_data.ingredients = ingredients
	recipe_data.result = result
	recipe_data.result_is_hot = hot
	recipe_data.tab = tab
	recipe_data.category = category
	recipe_data.unlocked_by_default = not locked
	_recipes[id] = recipe_data
	return recipe_data


static func _ingredient(item_data: ItemData, amount: int = 1) -> Ingredient:
	var ingredient := Ingredient.new()
	ingredient.item = item_data
	ingredient.amount = amount
	return ingredient


static func _get_material(material_id: String, item_id: String) -> Dictionary:
	if material_id.is_empty():
		return {}
	if not _materials.has(material_id):
		push_error("ContentDB: items.json, '%s': unknown material '%s' (see materials.json)." % [item_id, material_id])
		return {}
	return _materials[material_id]


static func _lookup(table: Dictionary, key: String, file_name: String, id: String, field: String) -> int:
	if table.has(key):
		return table[key]
	push_error("ContentDB: %s, '%s': unknown %s '%s'. Allowed: %s" % [file_name, id, field, key, ", ".join(PackedStringArray(table.keys()))])
	return 0


static func _parse_rarity(value: Variant, id: String) -> Rarity.Tier:
	var text: String = str(value).to_upper().trim_prefix("R")
	if not text.is_valid_int() or int(text) < 1 or int(text) > Rarity.Tier.size():
		push_error("ContentDB: '%s': rarity must be R1 ... R%d, not '%s'." % [id, Rarity.Tier.size(), value])
		return Rarity.Tier.COMMON
	return (int(text) - 1) as Rarity.Tier


## Loads a picture; without a path (or if the file is missing) the `fallback` picture is used.
static func _load_texture(path: String, id: String, fallback: String = "") -> Texture2D:
	if not path.is_empty():
		if ResourceLoader.exists(path):
			return load(path)
		push_error("ContentDB: '%s': picture '%s' not found." % [id, path])
	return load(fallback) if not fallback.is_empty() else null


## {"fire": 50, "slash": 50} -> shares that add up to 1; unknown kinds are reported.
static func _parse_split(data: Dictionary, file_name: String, id: String) -> Dictionary:
	var checked: Dictionary = {}
	for kind: String in data:
		if DamageKinds.is_valid(kind):
			checked[kind] = float(data[kind])
		else:
			push_error("ContentDB: %s, '%s': unknown damage kind '%s' (see docs/CONTENT.md)." % [file_name, id, kind])
	return DamageKinds.normalized(checked) if not checked.is_empty() else {}


## {"fire": 10, "slash": -5} with checked kinds.
static func _parse_resistances(data: Dictionary, file_name: String, id: String) -> Dictionary:
	var checked: Dictionary = {}
	for kind: String in data:
		if DamageKinds.is_valid(kind) and kind != DamageKinds.TRUE_DAMAGE:
			checked[kind] = float(data[kind])
		else:
			push_error("ContentDB: %s, '%s': unknown resistance '%s' (see docs/CONTENT.md)." % [file_name, id, kind])
	return checked
