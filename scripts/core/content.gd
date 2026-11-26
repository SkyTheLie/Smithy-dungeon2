class_name Content
extends RefCounted
## Reads the JSON files in res://data/ (items, synergies, enemies, floors, player) once and keeps
## them. Every number and list of the game comes from there (see docs/CONTENT.md).
## Texts (name, desc) stay German here; they are translated where they are shown
## (Language.translate).

const DIR: String = "res://data/"

## File name -> parsed JSON. A cache of read-only data, not game state.
static var _cache: Dictionary = {}


static func get_file(file: String) -> Dictionary:
	if not _cache.has(file):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + file + ".json"))
		if not data is Dictionary:
			push_error("Content: %s%s.json is missing or not valid JSON." % [DIR, file])
			data = {}
		_cache[file] = data
	return _cache[file]


static func reload() -> void:
	_cache.clear()


static func items() -> Dictionary:
	return get_file("items").get("items", {})


static func item(id: String) -> Dictionary:
	return items().get(id, {})


static func synergies() -> Dictionary:
	return get_file("synergies").get("synergies", {})


static func enemies() -> Dictionary:
	return get_file("enemies").get("enemies", {})


static func enemy(id: String) -> Dictionary:
	return enemies().get(id, {})


static func floors() -> Array:
	return get_file("floors").get("floors", [])


## Floor `index` with the values of its theme (name, textures, music, enemies, bosses); values
## of the floor itself win. A new Dictionary each call (called once per floor).
static func floor_data(index: int) -> Dictionary:
	var list: Array = floors()
	if list.is_empty():
		return {}
	var floor_entry: Dictionary = list[clampi(index, 0, list.size() - 1)]
	var result: Dictionary = (get_file("floors").get("themes", {}) as Dictionary).get(String(floor_entry.get("theme", "")), {}).duplicate()
	result.merge(floor_entry, true)
	return result


static func floors_extra(key: String) -> Variant:
	return get_file("floors").get(key, {})


## Playable characters in their order (data/characters.json).
static func characters() -> Dictionary:
	return get_file("characters").get("characters", {})


static func character(id: String) -> Dictionary:
	return characters().get(id, {})


static func player() -> Dictionary:
	return get_file("player")


## Loot that goes into the bag (data/loot.json "materials").
static func materials() -> Dictionary:
	return get_file("loot").get("materials", {})


static func material(id: String) -> Dictionary:
	return materials().get(id, {})


## What enemy `id` can drop into the bag: a list of {id, chance, amount}.
static func enemy_loot(id: String) -> Array:
	return (get_file("loot").get("enemies", {}) as Dictionary).get(id, [])


## Dungeons on Egon's board (data/dungeons.json): id -> {name, region, desc, level}, in order.
static func dungeons() -> Dictionary:
	return get_file("dungeons").get("dungeons", {})


## Equipment that stays between runs (data/gear.json "gear"): id -> {name, desc, slot, icon, price, stats}.
static func gear() -> Dictionary:
	return get_file("gear").get("gear", {})


static func gear_item(id: String) -> Dictionary:
	return gear().get(id, {})


## The places on the hero (data/gear.json "slots"), in order: slot -> {name, hint, at}.
static func gear_slots() -> Dictionary:
	return get_file("gear").get("slots", {})


## Relics (data/relics.json): table_chance, tiers, items (item id -> tier).
static func relics() -> Dictionary:
	return get_file("relics")


## Egon's shop rules (data/shop.json).
static func shop() -> Dictionary:
	return get_file("shop")


## Texts of the characters (data/story.json): `key` -> list of lines (or the barks dictionary).
static func story(key: String) -> Variant:
	return get_file("story").get(key, [])


## Values between runs (data/meta.json): "bag", "money_box".
static func meta(section: String) -> Dictionary:
	return get_file("meta").get(section, {})


## Ids of all items in `pool`: "item" (item room) = every item that is not "secret": true;
## "secret" (secret rooms) = the secret ones;
## "shop", "boss" = the items that list it in "pools". Locked items are still in here
## (RunState.pick_item leaves them out).
static func pool(pool_name: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in items():
		var data: Dictionary = items()[id]
		if pool_name == "item":
			if not bool(data.get("secret", false)):
				ids.append(id)
		elif pool_name == "secret":
			if bool(data.get("secret", false)):
				ids.append(id)
		elif (data.get("pools", []) as Array).has(pool_name):
			ids.append(id)
	return ids


## Picks one id from a list of [id, weight] pairs.
static func pick_weighted(table: Array, rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for entry: Array in table:
		total += float(entry[1])
	var roll: float = rng.randf() * total
	for entry: Array in table:
		roll -= float(entry[1])
		if roll <= 0.0:
			return String(entry[0])
	return String(table.back()[0]) if not table.is_empty() else ""
