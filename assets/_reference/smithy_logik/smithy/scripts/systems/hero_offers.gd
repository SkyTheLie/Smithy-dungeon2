class_name HeroOffers
extends RefCounted
## The heroes the adventurers' guild offers for hire: a new group every day, generated from
## data/content/guild_heroes.json (count, level, price, attributes per class, names). The same
## day always gives the same heroes (seeded by the day number), so nothing has to be saved
## until a hero is hired; hired heroes save all their data (Hero.to_save_data, "generated").
## Only classes the player has unlocked (ClassUnlocks) are offered.

const DATA_PATH: String = "res://data/content/guild_heroes.json"
const CLASS_PATH: String = "res://data/hero_classes/%s.tres"
const ATTRIBUTES: Array[String] = ["strength", "agility", "constitution", "intelligence", "wisdom", "resistance"]

static var _data: Dictionary = {}
static var _cached_day: int = -1
static var _cached_classes: Array[String] = []
static var _cached_guild: Dictionary = {}
static var _cached: Array[Hero] = []


## Heroes on offer on `day` (always the same list for the same day and classes), only of the
## `classes` given (ids; empty = no heroes). `guild` = entry of the reached guild level
## (GuildLevel.get_info): its "level" and "count" replace the base values.
static func for_day(day: int, classes: Array[String], guild: Dictionary = {}) -> Array[Hero]:
	if day == _cached_day and classes == _cached_classes and guild == _cached_guild:
		return _cached
	_cached_guild = guild.duplicate()
	var data: Dictionary = _load().duplicate()
	for key in ["level", "count"]:
		if guild.has(key):
			data[key] = guild[key]
	var allowed: Array = (data.get("classes", {}) as Dictionary).keys().filter(func(id: String) -> bool: return classes.has(id))
	if allowed.is_empty():
		_cached_day = day
		_cached_classes = classes.duplicate()
		_cached = []
		return _cached
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("guild_heroes_%d" % day)
	var count_range: Array = data.get("count", [5, 9])
	var count: int = rng.randi_range(int(count_range[0]), int(count_range[1]))
	var names: Array = data.get("names", [Language.translate("Held")]).duplicate()
	for i in range(names.size() - 1, 0, -1):  # shuffle with the day's random numbers
		var j: int = rng.randi_range(0, i)
		var swap: Variant = names[i]
		names[i] = names[j]
		names[j] = swap
	var offers: Array[Hero] = []
	for i in count:
		offers.append(_create(day, i, rng, data, str(names[i % names.size()]), allowed))
	_cached_day = day
	_cached_classes = classes.duplicate()
	_cached = offers
	return offers


static func _create(day: int, index: int, rng: RandomNumberGenerator, data: Dictionary, hero_name: String, class_ids: Array) -> Hero:
	var hero := Hero.new()
	hero.id = StringName("guild_%d_%d" % [day, index])
	hero.display_name = hero_name
	var classes: Dictionary = data.get("classes", {})
	var class_id: String = class_ids[rng.randi() % class_ids.size()]
	hero.hero_class = load(CLASS_PATH % class_id) as HeroClass
	var level_range: Array = data.get("level", [1, 1])
	hero.level = rng.randi_range(int(level_range[0]), int(level_range[1]))
	var races: Array = Appearance.get_options("race")
	hero.race = races[rng.randi() % races.size()]
	hero.appearance = Appearance.from_seed(String(hero.id), hero.race)
	_roll_attributes(hero, rng, data.get("attributes", {}), classes[class_id].get("focus", {}))
	var cost: Dictionary = data.get("cost", {})
	var extra: Array = cost.get("random", [0, 0])
	hero.hire_cost = int(cost.get("base", 40)) + int(cost.get("per_level", 0)) * hero.level \
			+ rng.randi_range(int(extra[0]), int(extra[1]))
	return hero


## Every attribute starts at `base`; the free points go to the attributes by the class weights.
static func _roll_attributes(hero: Hero, rng: RandomNumberGenerator, rules: Dictionary, focus: Dictionary) -> void:
	var values: Dictionary = {}
	for attribute in ATTRIBUTES:
		values[attribute] = int(rules.get("base", 2))
	var points: int = int(rules.get("points", 9)) + int(rules.get("points_per_level", 2)) * (hero.level - 1)
	var total_weight: int = 0
	for attribute in ATTRIBUTES:
		total_weight += int(focus.get(attribute, 1))
	for p in points:
		var roll: int = rng.randi_range(1, total_weight)
		for attribute in ATTRIBUTES:
			roll -= int(focus.get(attribute, 1))
			if roll <= 0:
				values[attribute] += 1
				break
	for attribute in ATTRIBUTES:
		hero.set(attribute, values[attribute])


static func _load() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data
