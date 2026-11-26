class_name BattleFigure
extends RefCounted
## Battle figures drawn with PixelLab per hero class and metal: the hero is shown in the metal most
## of his set pieces are made of (Hero.get_lead_metal, "cloth" without metal), the weapon and the
## shield stay own pictures in their own metal (the blade/head counts, not the grip).
##
## Files: res://assets/sprites/heroes/battle/<class id>/figure.json + <tier>_<pose>.png (frames in a
## row, feet on figure.json "feet"); held pictures: battle/held/<type>_<metal>.png + held.json (the
## pixel the hand holds; shields: their middle). Made by assets/_reference/paladin_battle/.
## A class without a figure, or a weapon of another weapon class, keeps the CharacterBaker figure.

const DIR: String = "res://assets/sprites/heroes/battle/"
const NO_METAL: String = "cloth"

static var _figures: Dictionary = {}
static var _held_data: Dictionary = {}
static var _held_loaded: bool = false
static var _textures: Dictionary = {}


## figure.json of a class ({} = the class has no battle figure).
static func get_figure(class_id: String) -> Dictionary:
	if not _figures.has(class_id):
		var path: String = DIR + class_id + "/figure.json"
		var data: Variant = null
		if FileAccess.file_exists(path):
			data = JSON.parse_string(FileAccess.get_file_as_string(path))
		_figures[class_id] = data if data is Dictionary else {}
	return _figures[class_id]


## Class id of a hero with a battle figure for the weapon class he holds ("" = none, old figure).
## `weapon_class`: BattleStage.WEAPON_CLASS of the held weapon, "" = no weapon.
static func get_class_for(hero: Hero, weapon_class: String) -> String:
	if hero == null or hero.hero_class == null or hero.get_own_appearance().is_fixed():
		return ""
	var class_id: String = String(hero.hero_class.id)
	var figure: Dictionary = get_figure(class_id)
	if figure.is_empty():
		return ""
	if not weapon_class.is_empty() and weapon_class != figure.get("weapon_class", ""):
		return ""
	return class_id


## The tier picture the hero is drawn in: his lead metal, or the next lower one the figure has.
static func get_tier(class_id: String, hero: Hero) -> String:
	var tiers: Array = get_figure(class_id).get("tiers", [])
	var index: int = Hero.TIER_METALS.find(hero.get_lead_metal())
	while index > 0:
		if tiers.has(Hero.TIER_METALS[index]):
			return Hero.TIER_METALS[index]
		index -= 1
	return NO_METAL


static func get_sheet(class_id: String, tier: String, pose: String) -> Texture2D:
	return _load(DIR + class_id + "/" + tier + "_" + pose + ".png")


static func get_frame_count(class_id: String, pose: String) -> int:
	return get_figure(class_id).get("poses", {}).get(pose, []).size()


## {"weapon": Vector2 fist, "angle": degrees (0 = up, + = forward), "shield": Vector2 fist}.
static func get_hands(class_id: String, pose: String, frame: int) -> Dictionary:
	var frames: Array = get_figure(class_id).get("poses", {}).get(pose, [])
	if frames.is_empty():
		return {"weapon": Vector2.ZERO, "angle": 0.0, "shield": Vector2.ZERO}
	var info: Dictionary = frames[clampi(frame, 0, frames.size() - 1)]
	return {"weapon": Vector2(info["weapon"][0], info["weapon"][1]), "angle": float(info["angle"]),
			"shield": Vector2(info["shield"][0], info["shield"][1])}


## The held picture of a weapon type or "shield" in a material: {"texture", "anchor"}, {} = none.
## The material counts by its tier (Hero.TIER_METALS); below copper the copper picture is used.
static func get_held(type_id: String, material_id: String) -> Dictionary:
	if not _held_loaded:
		_held_loaded = true
		var path: String = DIR + "held/held.json"
		if FileAccess.file_exists(path):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			_held_data = data if data is Dictionary else {}
	var tier: int = int(ContentDB.material_info(material_id).get("tier", 0))
	var index: int = clampi(tier, 1, Hero.TIER_METALS.size() - 1)
	var name: String = type_id + "_" + Hero.TIER_METALS[index]
	if not _held_data.has(name):
		return {}
	var anchor: Array = _held_data[name]
	return {"texture": _load(DIR + "held/" + name + ".png"), "anchor": Vector2(anchor[0], anchor[1])}


static func _load(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]
