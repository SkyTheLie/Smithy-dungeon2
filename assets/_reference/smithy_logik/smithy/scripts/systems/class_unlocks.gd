class_name ClassUnlocks
extends RefCounted
## Hero classes come to the guilds only once the player can make a weapon they may carry
## (weapon_types.json "classes"): a known weapon recipe whose station the player has (bow table,
## enchanting table: economy.json "stations" flag; workbench always) and whose parts can all be
## made (a known recipe for each part). Example: Holger's axe -> warrior, paladin, ranger;
## the enchanting table (wooden staff) -> mage, priest. GameState remembers the day of each unlock
## (class_unlock_days, saved, with a tip); the guilds offer a class from the next day on.

const ALL_CLASS_IDS: Array[String] = ["warrior", "paladin", "rogue", "ranger", "mage", "priest"]


## Ids of all unlocked classes, in the order of ALL_CLASS_IDS.
static func get_unlocked_class_ids() -> Array[String]:
	var unlocked: Array[String] = []
	for recipe in ContentDB.get_all_recipes():
		if recipe.result == null or not recipe.result.is_weapon() or recipe.result.weapon_type == null:
			continue
		var type: WeaponType = recipe.result.weapon_type
		if type.classes.all(func(class_id: String) -> bool: return unlocked.has(class_id)):
			continue
		if not can_make_weapon(recipe):
			continue
		for class_id in (ALL_CLASS_IDS if type.classes.is_empty() else type.classes):
			if not unlocked.has(class_id):
				unlocked.append(class_id)
	var ordered: Array[String] = []
	for class_id in ALL_CLASS_IDS:
		if unlocked.has(class_id):
			ordered.append(class_id)
	return ordered


static func is_unlocked(class_id: String) -> bool:
	return get_unlocked_class_ids().has(class_id)


## Classes the guilds offer today: unlocked before today (GameState.class_unlock_days).
static func get_available_class_ids() -> Array[String]:
	var available: Array[String] = []
	for class_id in ALL_CLASS_IDS:
		if GameState.class_unlock_days.has(class_id) and int(GameState.class_unlock_days[class_id]) < GameState.day_cycle.day:
			available.append(class_id)
	return available


## Text of the tip for a new class: what it is, which weapons it carries, when it comes.
static func get_unlock_text(class_id: String) -> String:
	var hero_class: HeroClass = HeroClass.load_class(class_id)
	var weapons: Array[String] = []
	for type in ContentDB.get_all_weapon_types():
		if type.classes.has(class_id) or type.classes.is_empty():
			weapons.append(type.display_name)
	return Language.translate("%s\n\nTrägt: %s.\n\nAb morgen findest du Helden dieser Klasse in der Abenteurergilde.") % [
			hero_class.description, ", ".join(weapons)]


## The player knows the recipe, has its station and can make all its parts.
static func can_make_weapon(recipe: RecipeData) -> bool:
	if not GameState.is_recipe_unlocked(recipe) or not has_station(recipe.station):
		return false
	return GameState.can_make_all_parts(recipe)


## Workbench, forge and anvil are always there; bought stations need their story flag.
static func has_station(station: StringName) -> bool:
	var info: Dictionary = ContentDB.economy("stations").get(String(station), {})
	var flag: String = info.get("flag", "")
	return flag.is_empty() or GameState.story.has_flag(flag)
