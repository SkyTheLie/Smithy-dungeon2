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


## The dungeon of the run (data/dungeons.json id); Game.start_new_run sets it. "" = the first.
static var active_dungeon: String = ""


## The dungeon in use: `id`, else active_dungeon, else the first of dungeons.json.
static func dungeon_id(id: String = "") -> String:
	if id.is_empty():
		id = active_dungeon
	if not dungeons().has(id):
		id = String(dungeons().keys().front()) if not dungeons().is_empty() else ""
	return id


static func dungeon(id: String = "") -> Dictionary:
	return dungeons().get(dungeon_id(id), {})


## The floors of a dungeon (dungeons.json "floors" = a list name in floors.json, default "floors").
static func floors(id: String = "") -> Array:
	return get_file("floors").get(String(dungeon(id).get("floors", "floors")), [])


## Floor `index` of a dungeon with the values of its theme (name, textures, music, enemies,
## bosses); values of the floor itself win. The dungeon's numbers (dungeons.json) are worked in:
## hp_mult = floor x dungeon, damage_mult = enemy damage (floor x dungeon), exp_mult and shop_mult (dungeon, the shop also floors.json shop
## floor_step dearer per floor). A new Dictionary each call (called once per floor).
static func floor_data(index: int, id: String = "") -> Dictionary:
	var list: Array = floors(id)
	if list.is_empty():
		return {}
	index = clampi(index, 0, list.size() - 1)
	var floor_entry: Dictionary = list[index]
	var result: Dictionary = (get_file("floors").get("themes", {}) as Dictionary).get(String(floor_entry.get("theme", "")), {}).duplicate()
	result.merge(floor_entry, true)
	var info: Dictionary = dungeon(id)
	result["hp_mult"] = float(result.get("hp_mult", 1.0)) * float(info.get("hp_mult", 1.0))
	result["exp_mult"] = float(info.get("exp_mult", 1.0))
	result["damage_mult"] = float(result.get("damage_mult", 1.0)) * float(info.get("damage_mult", 1.0))
	var step: float = float((floors_extra("shop") as Dictionary).get("floor_step", 0.0))
	result["shop_mult"] = float(info.get("shop_mult", 1.0)) * (1.0 + step * index)
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


## Every enemy of dungeon `id` (floors.json: its floors' enemies, first-room enemies and
## bosses, then the end boss), each once, in the order they come.
static func dungeon_enemies(id: String) -> Array[String]:
	var list: Array[String] = []
	for index in floors(id).size():
		var data: Dictionary = floor_data(index, id)
		var ids: Array = []
		for entry: Variant in data.get("enemies", []):
			ids.append(entry[0] if entry is Array else entry)
		ids.append_array(data.get("first_room_enemies", []))
		ids.append_array(data.get("bosses", []))
		for enemy_id: Variant in ids:
			if not list.has(String(enemy_id)) and not enemy(String(enemy_id)).is_empty():
				list.append(String(enemy_id))
	var end_boss: String = String(dungeon(id).get("end_boss", ""))
	if not end_boss.is_empty() and not list.has(end_boss):
		list.append(end_boss)
	return list


## The picture of enemy `id` for menus: the first frame of its idle (or walk) sheet.
static func enemy_icon(id: String) -> Texture2D:
	var data: Dictionary = enemy(id)
	var base: String = String(data.get("sprite", ""))
	var path: String = base + ".png" if ResourceLoader.exists(base + ".png") else base + "_walk.png"
	if base.is_empty() or not ResourceLoader.exists(path):
		return null
	var sheet: Texture2D = load(path) as Texture2D
	var frame: Array = data.get("frame", [48, 48])
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, mini(int(frame[0]), sheet.get_width()), mini(int(frame[-1]), sheet.get_height()))
	return atlas


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


## Potions (data/potions.json): unlock_deaths, slots, table_chance, potions (id -> {name, heal …}).
static func potions() -> Dictionary:
	return get_file("potions")


static func potion(id: String) -> Dictionary:
	return (potions().get("potions", {}) as Dictionary).get(id, {})


## Egon's shop rules (data/shop.json).
static func shop() -> Dictionary:
	return get_file("shop")


## Texts of the characters (data/story.json): `key` -> list of lines (or the barks dictionary).
static func story(key: String) -> Variant:
	return get_file("story").get(key, [])


## Values between runs (data/meta.json): "bag", "money_box", "ruby_quest".
static func meta(section: String) -> Dictionary:
	return get_file("meta").get(section, {})


## Achievements (data/achievements.json): id -> {name, desc, icon}.
static func achievements() -> Dictionary:
	return get_file("achievements").get("achievements", {})


static func achievement(id: String) -> Dictionary:
	return achievements().get(id, {})


## The end boss of a dungeon (dungeons.json "end_boss", waits in the Boss-Altar); "" = none.
static func end_boss(id: String = "") -> String:
	var boss: String = String(dungeon(id).get("end_boss", ""))
	return boss if not enemy(boss).is_empty() else ""


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
