class_name Progress
extends RefCounted
## What stays between runs (user://progress.cfg): items picked up at least once (for the
## Lexikon), enemies killed, bosses beaten, runs won, achievements (data/achievements.json), and
## from that the unlocked items.
## An item with "unlock" in data/items.json is not in any pool until its condition is met:
##   {"type": "boss", "id": "rat_king"}   beat that boss once
##   {"type": "wins", "count": 1}          win that many runs
##   {"type": "kills", "count": 200}       kill that many enemies (all runs together)
##   {"type": "discovered", "count": 25}   pick up that many different items
##   {"type": "best", "key": "coins", "count": 55}   reach that value once in some run; keys:
##        hearts (heart containers at once), coins, blue (blue hearts at once), clean_floors
##        (floors in a row without a hit), pacts (in one run), floor (floor reached)
##   {"type": "fast_win", "count": 25}     win a run in less than that many minutes
## The functions that count something return the ids unlocked by it (for the "Freigeschaltet"
## banner). Runs themselves are still not saved.

const PATH: String = "user://progress.cfg"
const SECTION: String = "progress"

## Loaded once; written after every change (small file).
static var _config: ConfigFile


static func is_unlocked(id: String) -> bool:
	return meets(Content.item(id).get("unlock", {}))


## true if an "unlock" condition (items, characters) is met; an empty one always is.
static func meets(unlock: Dictionary) -> bool:
	if unlock.is_empty():
		return true
	match String(unlock.get("type", "")):
		"boss":
			return beaten_bosses().has(String(unlock.get("id", "")))
		"wins":
			return wins() >= int(unlock.get("count", 1))
		"kills":
			return kills() >= int(unlock.get("count", 1))
		"discovered":
			return discovered().size() >= int(unlock.get("count", 1))
		"best":
			return best(String(unlock.get("key", ""))) >= int(unlock.get("count", 1))
		"fast_win":
			var fastest: float = float(_read("fastest_win", 0.0))
			return fastest > 0.0 and fastest < int(unlock.get("count", 1)) * 60.0
	return false


## The best value of `key` ever reached (see "best" above).
static func best(key: String) -> int:
	return int((_read("best", {}) as Dictionary).get(key, 0))


## Remembers `value` if it beats the best of `key`.
static func note_best(key: String, value: int) -> Array[String]:
	if value <= best(key):
		return []
	var all: Dictionary = (_read("best", {}) as Dictionary).duplicate()
	all[key] = value
	return _change("best", all)


static func discovered() -> Array:
	return _read("discovered", [])


static func is_discovered(id: String) -> bool:
	return discovered().has(id)


static func kills() -> int:
	return int(_read("kills", 0))


static func wins() -> int:
	return int(_read("wins", 0))


static func beaten_bosses() -> Array:
	return _read("bosses", [])


## An item was picked up.
static func discover(id: String) -> Array[String]:
	if is_discovered(id) or Content.item(id).is_empty():
		return []
	var list: Array = discovered().duplicate()
	list.append(id)
	return _change("discovered", list)


static func add_kills(amount: int) -> Array[String]:
	if amount <= 0:
		return []
	return _change("kills", kills() + amount)


static func beat_boss(id: String) -> Array[String]:
	if beaten_bosses().has(id):
		return []
	var list: Array = beaten_bosses().duplicate()
	list.append(id)
	return _change("bosses", list)


## A won run, `seconds` long (for fast_win).
static func add_win(seconds: float = 0.0) -> Array[String]:
	var fastest: float = float(_read("fastest_win", 0.0))
	if seconds > 0.0 and (fastest <= 0.0 or seconds < fastest):
		_load().set_value(SECTION, "fastest_win", seconds)
	return _change("wins", wins() + 1)


## Achievements reached (ids of data/achievements.json), for all save slots.
static func achievements() -> Array:
	return _read("achievements", [])


static func has_achievement(id: String) -> bool:
	return achievements().has(id)


## Achievement `id` reached: remembered and saved. true if it is new (then the game shows it).
static func unlock_achievement(id: String) -> bool:
	if has_achievement(id) or Content.achievement(id).is_empty():
		return false
	var list: Array = achievements().duplicate()
	list.append(id)
	_load().set_value(SECTION, "achievements", list)
	_load().save(PATH)
	return true


## Sets a value, saves, and returns the items that were locked before and are open now.
static func _change(key: String, value: Variant) -> Array[String]:
	var locked_before: Array[String] = []
	for id: String in Content.items():
		if not is_unlocked(id):
			locked_before.append(id)
	var characters_before: Array[String] = []
	for id: String in Content.characters():
		if not meets(Content.character(id).get("unlock", {})):
			characters_before.append(id)
	_load().set_value(SECTION, key, value)
	_load().save(PATH)
	var opened: Array[String] = []
	for id: String in locked_before:
		if is_unlocked(id):
			opened.append(id)
	for id: String in characters_before:
		if meets(Content.character(id).get("unlock", {})):
			opened.append(id)
	return opened


static func _read(key: String, default: Variant) -> Variant:
	return _load().get_value(SECTION, key, default)


static func _load() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(PATH)
	return _config


## Forgets the loaded file; the next call reads it again (tests).
static func reload() -> void:
	_config = null
