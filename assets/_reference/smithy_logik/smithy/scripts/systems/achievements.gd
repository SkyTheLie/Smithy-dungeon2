class_name Achievements
extends RefCounted
## Achievements ("Erfolge", character window): data/content/achievements.json (format:
## docs/CONTENT.md). The game only counts things under names ("counters", e.g. "kill:rat_king",
## "forge", "made:helmet:copper", list in achievements.json "_hilfe"); every achievement reads one
## of them:
##   "counter" + "levels" [1, 5, 50, ...]: level 1 at 1, level 2 at 5 ... (one entry = one level)
##   "all" [counters]: done (level 1) when every counter is at least 1 (e.g. a whole copper set)
##   "flag": done when the story flag is set (counters "flag:<flag>" work too)
## Some counters are worked out instead of counted (`computed`, e.g. "lexicon:enemies" = percent of
## the lexicon's monsters discovered); GameState sets them.
## Only the counters are saved; levels are worked out from them, so changed levels in the JSON
## apply to old saves as well.
## Steam: every level is its own Steam achievement (get_steam_names, achievements.json "steam");
## SteamBridge reports them, the game itself works the same without Steam.

## An achievement reached a new level (the HUD shows a message).
signal unlocked(id: String, level: int)
signal changed

## Counter name -> value.
var counters: Dictionary = {}
## Achievement id -> level the player was told about (no message twice).
var _announced: Dictionary = {}
## Story flags are read through this (set by GameState).
var has_flag: Callable = func(_flag: String) -> bool: return false
## Counter name -> Callable returning its value, for counters that are worked out from other
## systems (set by GameState). # not saved on purpose (derived from the saved lexicon)
var computed: Dictionary[String, Callable] = {}
## Counter prefix -> Callable(rest: String) -> int, e.g. "seen:" -> 1 if the lexicon knows the item
## "seen:<item>". # not saved on purpose (derived)
var computed_prefix: Dictionary[String, Callable] = {}


## Adds `amount` to a counter and announces new levels. `announce` false = only count (while loading
## a save: no messages, see FEHLERKLASSEN rule 5).
func count(counter: String, amount: int = 1, announce: bool = true) -> void:
	if amount == 0:
		return
	counters[counter] = int(counters.get(counter, 0)) + amount
	if announce:
		check()
	changed.emit()


## Sets a counter to 1 the first time (things that happen once and must not go back, e.g. a fully
## learned skill tree: resetting the skills later keeps the achievement).
func count_once(counter: String, announce: bool = true) -> void:
	if get_value(counter) == 0:
		count(counter, 1, announce)


## Raises a counter to `value` if that is higher (best hero level, reputation rank, house level:
## things that can go down again, the achievement keeps the best).
func raise_to(counter: String, value: int, announce: bool = true) -> void:
	var current: int = int(counters.get(counter, 0))
	if value > current:
		count(counter, value - current, announce)


## Counts finished equipment and jewels of the top rarities: "made_rarity:legendary" (Legendär or
## better) and "made_rarity:mythic".
func count_rarity(stack: InventorySlot) -> void:
	if stack == null or stack.is_empty():
		return
	if stack.rarity >= Rarity.Tier.LEGENDARY:
		count("made_rarity:legendary")
	if stack.rarity >= Rarity.Tier.MYTHIC:
		count("made_rarity:mythic")


## Counts "material:<material>" for something the player made (anvil, mold): the first platinum
## part reaches the achievement "Platin" (achievements.json "material:platinum").
func count_material(stack: InventorySlot) -> void:
	if stack == null or stack.item == null or stack.item.material_id.is_empty():
		return
	count("material:" + stack.item.material_id)


## Looks for achievements that reached a new level (also after story flags changed).
func check() -> void:
	for id: String in get_all():
		var level: int = get_level(id)
		if level > int(_announced.get(id, 0)):
			_announced[id] = level
			unlocked.emit(id, level)


## Value of a counter; "flag:<flag>" is 1 while the story flag is set.
func get_value(counter: String) -> int:
	if counter.begins_with("flag:"):
		return 1 if has_flag.call(counter.trim_prefix("flag:")) else 0
	if computed.has(counter):
		return int(computed[counter].call())
	for prefix: String in computed_prefix:
		if counter.begins_with(prefix):
			return int(computed_prefix[prefix].call(counter.trim_prefix(prefix)))
	return int(counters.get(counter, 0))


# --- Definitions ------------------------------------------------------------------------

static func get_all() -> Dictionary:
	return ContentDB.achievements().get("achievements", {})


## Categories in display order: [{"id", "name"}].
static func get_categories() -> Array:
	var list: Array = []
	var data: Dictionary = ContentDB.achievements().get("categories", {})
	for id: String in data:
		list.append({"id": id, "name": data[id].get("name", id)})
	return list


## Achievement ids of a category, in the order of the JSON file.
static func get_in_category(category: String) -> Array[String]:
	var ids: Array[String] = []
	var all: Dictionary = get_all()
	for id: String in all:
		if all[id].get("category", "") == category:
			ids.append(id)
	return ids


static func get_data(id: String) -> Dictionary:
	return get_all().get(id, {})


## Targets of the levels: [1, 5, 50] for "counter", [n] for "all" (n = number of counters),
## [1] for "flag".
static func get_targets(id: String) -> Array[int]:
	var data: Dictionary = get_data(id)
	var targets: Array[int] = []
	if data.has("all"):
		targets.append((data["all"] as Array).size())
	elif data.has("levels"):
		for value: Variant in data["levels"]:
			targets.append(int(value))
	else:
		targets.append(1)
	return targets


static func get_max_level(id: String) -> int:
	return get_targets(id).size()


# --- Steam ------------------------------------------------------------------------------

## Settings from achievements.json "steam": {"enabled", "app_id", "name_pattern", ...}.
static func get_steam_settings() -> Dictionary:
	return ContentDB.achievements().get("steam", {})


## API names of the Steam achievements of one achievement, one per level (index 0 = level 1).
## From the JSON field "steam_id" (else the id in capitals) and "name_pattern" ({ID}, {LEVEL});
## an achievement with one level leaves out "_{LEVEL}" (pattern "single_pattern"). "steam": false
## = not on Steam (empty list).
static func get_steam_names(id: String) -> Array[String]:
	var data: Dictionary = get_data(id)
	var names: Array[String] = []
	if data.is_empty() or not data.get("steam", true):
		return names
	var settings: Dictionary = get_steam_settings()
	var base: String = String(data.get("steam_id", id)).to_upper()
	var max_level: int = get_max_level(id)
	var pattern: String = settings.get("name_pattern", "ACH_{ID}_{LEVEL}") if max_level > 1 			else settings.get("single_pattern", "ACH_{ID}")
	for level in range(1, max_level + 1):
		names.append(pattern.format({"ID": base, "LEVEL": level}))
	return names


## Name of the Steam stat that shows the progress of this achievement (JSON "steam_stat",
## "" = none). Only useful for "counter" achievements.
static func get_steam_stat(id: String) -> String:
	return String(get_data(id).get("steam_stat", ""))


# --- Progress ---------------------------------------------------------------------------

## Current amount towards the targets: the counter, the number of finished "all" counters, or 1/0
## for a flag.
func get_progress(id: String) -> int:
	var data: Dictionary = get_data(id)
	if data.has("all"):
		var done: int = 0
		for counter: String in data["all"]:
			if get_value(counter) > 0:
				done += 1
		return done
	if data.has("flag"):
		return 1 if has_flag.call(String(data["flag"])) else 0
	return get_value(String(data.get("counter", "")))


## Reached level: 0 = not yet, get_max_level = max.
func get_level(id: String) -> int:
	var progress: int = get_progress(id)
	var level: int = 0
	for target in get_targets(id):
		if progress >= target:
			level += 1
	return level


func is_max(id: String) -> bool:
	return get_level(id) >= get_max_level(id)


## Secret achievements show "?" until level 1.
func is_hidden(id: String) -> bool:
	return get_data(id).get("secret", false) and get_level(id) == 0


## Target of the next level (the last one at max level).
func get_next_target(id: String) -> int:
	var targets: Array[int] = get_targets(id)
	return targets[mini(get_level(id), targets.size() - 1)]


## 0..1 towards the next level (1 at max level).
func get_fraction(id: String) -> float:
	if is_max(id):
		return 1.0
	var targets: Array[int] = get_targets(id)
	var level: int = get_level(id)
	var start: int = targets[level - 1] if level > 0 else 0
	var end: int = targets[level]
	return clampf(float(get_progress(id) - start) / maxf(end - start, 1), 0.0, 1.0)


# --- Saving -------------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"counters": counters.duplicate()}


func load_save_data(data: Dictionary) -> void:
	counters = data.get("counters", {}).duplicate()
	mark_known()


## Levels reached so far count as announced (after loading or a skipped story: no flood of messages).
func mark_known() -> void:
	_announced.clear()
	for id: String in get_all():
		_announced[id] = get_level(id)
	changed.emit()
