class_name Appearance
extends Resource
## Look of a character (player, customers, heroes, quest givers): race, skin tone, hair style and
## colour, eye shape and colour, size, clothes (outfit) and their colour, horns and their colour
## (only races with "horns"), the shape of the ears (only races with "ears") and the figure (body:
## "male", "female" = with eyelashes, narrower waist and a hint of a bust; every figure may wear every
## piece of clothing). All values are ids from data/content/appearance.json
## (format: docs/CONTENT.md). CharacterBaker turns an Appearance into a sprite sheet.

@export var race: String = "human"
@export var skin: String = "light"
@export var hair_style: String = "short"
@export var hair_color: String = "brown"
@export var eye_type: String = "normal"
@export var eye_color: String = "brown"
@export var size: String = "normal"
@export var outfit: String = "smith"
@export var clothes_color: String = "green"
@export var horn_style: String = "bull"
@export var horn_color: String = "ivory"
## Empty for races without ears of their own; normalize picks the first of the race.
@export var ear_style: String = ""
## "male" or "female" (appearance.json "bodies"). Random looks are always "male".
@export var body: String = "male"

## How much darker (negative = lighter) the 5 shades of an own colour are; skin has a narrower ramp,
## like the skin tones of appearance.json.
const CUSTOM_SHADES: Array[float] = [-0.15, 0.0, 0.2, 0.35, 0.55]
const CUSTOM_SKIN_SHADES: Array[float] = [-0.08, 0.0, 0.06, 0.11, 0.2]
## Horns have 4 shades (appearance.json "horn_colors").
const CUSTOM_HORN_SHADES: Array[float] = [-0.2, 0.0, 0.35, 0.55]

## Order of the choices in to_save_data and create_random (new fields at the end, so the random
## looks of heroes and NPCs made from their id stay the same).
const FIELDS: Array[String] = ["race", "skin", "hair_style", "hair_color", "eye_type", "eye_color", "size",
		"outfit", "clothes_color", "horn_style", "horn_color", "ear_style", "body"]
## Fields that hold a colour: an id of appearance.json or an own colour "#rrggbb" (colour wheel of
## the character creator, get_colors makes the shades).
const COLOR_FIELDS: Array[String] = ["skin", "hair_color", "eye_color", "clothes_color", "horn_color"]


## A random look. `race_id` empty = random race.
static func create_random(rng: RandomNumberGenerator = null, race_id: String = "") -> Appearance:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var look := Appearance.new()
	var races: Array = get_options("race")
	look.race = race_id if races.has(race_id) else races[rng.randi() % races.size()]
	for field in FIELDS:
		# Random looks keep the male figure (and so the clothes they always had).
		if field != "race" and field != "body":
			var options: Array = look.get_options_for(field)
			if field == "outfit":
				options = options.filter(is_random_outfit)
			look.set(field, options[rng.randi() % options.size()])
	look.normalize()
	return look


## false for clothes random looks never wear (appearance.json outfit "random": false, the dresses):
## a random look picks from the same list as before they existed, so heroes keep their look.
static func is_random_outfit(outfit_id: String) -> bool:
	return ContentDB.appearance_section("outfits").get(outfit_id, {}).get("random", true)


## Always the same look for the same text (e.g. a hero's id), so fixed NPCs keep their face.
static func from_seed(seed_text: String, race_id: String = "") -> Appearance:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	return create_random(rng, race_id)


## All ids of one section of appearance.json, e.g. get_options("race") -> ["human", "elf", ...].
## Fixed outfits (one particular person, e.g. Bruno) are not offered.
static func get_options(field: String) -> Array:
	var section: Dictionary = ContentDB.appearance_section(_section(field))
	if field == "outfit":
		return section.keys().filter(func(id: String) -> bool: return not section[id].get("fixed", false))
	return section.keys()


## true for the figure of one particular person (appearance.json outfit with "fixed", e.g. Bruno):
## its base picture is the whole figure, nothing is chosen or recoloured.
func is_fixed() -> bool:
	return get_outfit_data().get("fixed", false)


## The look to draw in a fight: a fixed figure with "battle_look" (Bruno) is drawn as that builder
## figure there, so it has all fight poses; else this look.
func get_battle_look() -> Appearance:
	var battle: Dictionary = get_outfit_data().get("battle_look", {})
	return from_save_data(battle) if not battle.is_empty() else self


static func _section(field: String) -> String:
	match field:
		"race":
			return "races"
		"skin":
			return "skin_tones"
		"hair_style":
			return "hair_styles"
		"hair_color":
			return "hair_colors"
		"eye_type":
			return "eye_types"
		"eye_color":
			return "eye_colors"
		"outfit":
			return "outfits"
		"clothes_color":
			return "clothes_colors"
		"horn_style":
			return "horn_styles"
		"horn_color":
			return "horn_colors"
		"ear_style":
			return "ear_styles"
		"body":
			return "bodies"
	return "sizes"


## Choices for a field that fit this look: skin tones of the race; no hair styles for hairless races.
func get_options_for(field: String) -> Array:
	var race_data: Dictionary = get_race_data()
	if field == "skin":
		return race_data.get("skin_tones", get_options("skin"))
	if field == "hair_style" and race_data.get("no_hair", false):
		return ["bald"]
	if field == "clothes_color" and not get_outfit_data().get("colorable", false):
		return [clothes_color]
	if (field == "horn_style" or field == "horn_color") and not has_horns():
		return [get(field)]
	if field == "ear_style":
		return race_data.get("ears", [ear_style])
	if field == "outfit":
		# Clothes for one figure only (outfit "body", none at the moment: dresses are for everyone).
		var outfits: Dictionary = ContentDB.appearance_section("outfits")
		return get_options(field).filter(func(id: String) -> bool:
			return str(outfits[id].get("body", "")).is_empty() or outfits[id]["body"] == body)
	return get_options(field)


## Display name of the current choice of a field, e.g. "Elf", "Blond".
func get_option_name(field: String) -> String:
	if is_custom_color(String(get(field))):
		return Language.translate("Eigene Farbe")
	var entry: Dictionary = ContentDB.appearance_section(_section(field)).get(get(field), {})
	if field == "outfit" and has_lashes() and entry.has("name_female"):
		return entry["name_female"]
	return entry.get("name", String(get(field)))


## true for races with horns (appearance.json races.<id>.horns): horn_style and horn_color count.
func has_horns() -> bool:
	return get_race_data().get("horns", false)


## true for races with ears of their own (appearance.json races.<id>.ears, e.g. elves, cats):
## ear_style counts.
func has_ears() -> bool:
	return not get_race_data().get("ears", []).is_empty()


func get_race_data() -> Dictionary:
	return ContentDB.appearance_section("races").get(race, {})


## What a race gives a hero, e.g. "Lichtschaden +5 % · Resistenz gegen Licht +5": "hero_bonus"
## (names of the passive skill values, SkillData.PASSIVE_NAMES) and "hero_resistances".
static func get_race_hero_text(race_id: String) -> String:
	var data: Dictionary = ContentDB.appearance_section("races").get(race_id, {})
	var parts: Array[String] = []
	var bonus: Dictionary = data.get("hero_bonus", {})
	for stat: String in bonus:
		parts.append(Language.translate(SkillData.PASSIVE_NAMES.get(stat, stat + " %s")) % DamageKinds.format_number(float(bonus[stat])))
	var resistances: Dictionary = data.get("hero_resistances", {})
	for kind: String in resistances:
		parts.append(Language.translate("Resistenz gegen %s +%s") % [DamageKinds.get_display_name(kind), DamageKinds.format_number(float(resistances[kind]))])
	return " · ".join(parts)


func get_outfit_data() -> Dictionary:
	return ContentDB.appearance_section("outfits").get(outfit, {})


## Outfit whose parts (hair, ears), attack poses and other sheets this one uses when it has none
## of its own (appearance.json "body_of", e.g. the dresses use the tunic's); else the outfit itself.
func get_body_outfit() -> String:
	return str(get_outfit_data().get("body_of", outfit))


## true for the female figure (appearance.json "bodies.<id>.lashes"): CharacterBaker adds eyelashes.
func has_lashes() -> bool:
	return bool(ContentDB.appearance_section("bodies").get(body, {}).get("lashes", false))


## true for the female figure (appearance.json "bodies.<id>.shape"): CharacterBaker narrows the
## waist and shades under the bust (placeholder).
func has_female_shape() -> bool:
	return bool(ContentDB.appearance_section("bodies").get(body, {}).get("shape", false))


## Puts every value back into its allowed range (e.g. after the race changed).
func normalize() -> void:
	if is_fixed():
		# A fixed figure has its own size; the other fields don't change its picture.
		size = "normal"
		return
	if not get_options("race").has(race):
		race = "human"
	for field in FIELDS:
		if COLOR_FIELDS.has(field) and is_custom_color(String(get(field))):
			continue
		var options: Array = get_options_for(field)
		if not options.is_empty() and not options.has(get(field)):
			set(field, options[0])


## true for an own colour "#rrggbb" instead of an id of appearance.json.
static func is_custom_color(value: String) -> bool:
	return value.begins_with("#")


## Shades of a colour field from light to dark (eyes: colour and glint): the "colors" of the id in
## appearance.json, or made from an own colour (it is the second shade, the main one of skin and hair).
static func get_colors(field: String, value: String) -> Array[Color]:
	var colors: Array[Color] = []
	if is_custom_color(value):
		var color := Color.html(value)
		if field == "eye_color":
			colors.append(color)
			colors.append(color.lightened(0.45))
			return colors
		var spread: Array = CUSTOM_SHADES
		if field == "skin":
			spread = CUSTOM_SKIN_SHADES
		elif field == "horn_color":
			spread = CUSTOM_HORN_SHADES
		for shift: float in spread:
			colors.append(color.lightened(-shift) if shift < 0.0 else color.darkened(shift))
		return colors
	for text: String in ContentDB.appearance_section(_section(field)).get(value, {}).get("colors", ["#ff00ff"]):
		colors.append(Color.html(text))
	return colors


func get_scale() -> float:
	return float(ContentDB.appearance_section("sizes").get(size, {}).get("scale", 1.0))


## Same text for the same look (cache key of CharacterBaker; the size is not part of the picture,
## the horns only for races with horns, the ears only for races with ears).
func get_key() -> String:
	var key: String = "%s|%s|%s|%s|%s|%s|%s|%s" % [race, skin, hair_style, hair_color, eye_type, eye_color, outfit, clothes_color]
	if has_horns():
		key += "|%s|%s" % [horn_style, horn_color]
	if has_ears():
		key += "|" + ear_style
	if has_lashes():
		key += "|" + body
	return key


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for field in FIELDS:
		data[field] = get(field)
	return data


static func from_save_data(data: Dictionary) -> Appearance:
	var look := Appearance.new()
	for field in FIELDS:
		if data.has(field):
			look.set(field, str(data[field]))
	look.normalize()
	return look
