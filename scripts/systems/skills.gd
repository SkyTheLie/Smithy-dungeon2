class_name Skills
extends RefCounted
## The skill tree (data/skills.json) and the player levels (data/levels.json). Only rules: what a
## skill level costs (gold and skill points), what it needs (player level, the skill before it),
## and what all bought levels give together (bonus / run_stats). The levels bought are saved by
## MetaState (skill_level, buy_skill); the shop shows the tree (SkillTreeWindow).


static func all() -> Dictionary:
	return Content.get_file("skills").get("skills", {})


static func data(id: String) -> Dictionary:
	return all().get(id, {})


static func max_level(id: String) -> int:
	return int(data(id).get("max_level", 1))


## The value of list `key` (gold, points, min_level) for skill level `level` (1 = the first);
## the last entry counts for higher levels.
static func _per_level(id: String, key: String, level: int) -> int:
	var list: Variant = data(id).get(key, [0])
	if not list is Array:
		return int(list)
	var values: Array = list
	if values.is_empty():
		return 0
	return int(values[clampi(level - 1, 0, values.size() - 1)])


## Gold, skill points and player level that level `level` (1 = the first) of `id` needs.
static func gold_at(id: String, level: int) -> int:
	return _per_level(id, "gold", level)


static func points_at(id: String, level: int) -> int:
	return _per_level(id, "points", level)


## The dungeon that must be open for level `level` of `id` ("" = none; skills.json "dungeon").
static func dungeon_at(id: String, level: int) -> String:
	var list: Variant = data(id).get("dungeon", [])
	if not list is Array or (list as Array).is_empty():
		return ""
	var values: Array = list
	return String(values[clampi(level - 1, 0, values.size() - 1)])


static func next_dungeon(id: String) -> String:
	return dungeon_at(id, MetaState.skill_level(id) + 1)


static func min_level_at(id: String, level: int) -> int:
	return _per_level(id, "min_level", level)


## What the next level of `id` costs (-1 = fully learned).
static func next_gold(id: String) -> int:
	var level: int = MetaState.skill_level(id)
	return -1 if level >= max_level(id) else _per_level(id, "gold", level + 1)


static func next_points(id: String) -> int:
	var level: int = MetaState.skill_level(id)
	return -1 if level >= max_level(id) else _per_level(id, "points", level + 1)


## The player level the next level of `id` needs.
static func next_min_level(id: String) -> int:
	return _per_level(id, "min_level", MetaState.skill_level(id) + 1)


## Why the next level of `id` cannot be bought now ("" = it can). German keys, shown translated.
static func problem(id: String) -> String:
	if data(id).is_empty():
		return "Unbekannt"
	if MetaState.skill_level(id) >= max_level(id):
		return "Voll ausgebaut"
	var needed: String = String(data(id).get("requires", ""))
	if not needed.is_empty() and MetaState.skill_level(needed) <= 0:
		return "Erst den Skill davor lernen"
	var dungeon: String = next_dungeon(id)
	if not dungeon.is_empty() and not MetaState.is_dungeon_open(dungeon):
		return "Dungeon noch nicht offen"
	if MetaState.level() < next_min_level(id):
		return "Stufe zu niedrig"
	if MetaState.skill_points() < next_points(id):
		return "Zu wenig Skillpunkte"
	if MetaState.box() < next_gold(id):
		return "Zu wenig Gold"
	return ""


## The sum of effect `kind` over every bought level (e.g. "safe_slots", "shield_halves").
static func bonus(kind: String) -> float:
	var total: float = 0.0
	for id: String in all():
		var level: int = MetaState.skill_level(id)
		if level > 0:
			total += float((data(id).get("effect", {}) as Dictionary).get(kind, 0.0)) * level
	return total


## The backpacks the player owns: effect "backpack" of every learned skill (data/backpacks.json
## ids, in the order of the tree).
static func backpacks() -> Array[String]:
	var list: Array[String] = []
	for id: String in all():
		var backpack: String = String((data(id).get("effect", {}) as Dictionary).get("backpack", ""))
		if not backpack.is_empty() and MetaState.skill_level(id) > 0 and not list.has(backpack):
			list.append(backpack)
	return list


## The "rarity" effects of every bought level: {rarity: percent} that move from R1 to that
## rarity on Egon's table (ShopGoods.rarity_weights), times the level.
static func rarity_bonus() -> Dictionary:
	var result: Dictionary = {}
	for id: String in all():
		var level: int = MetaState.skill_level(id)
		if level <= 0:
			continue
		var rarity: Dictionary = (data(id).get("effect", {}) as Dictionary).get("rarity", {})
		for key: Variant in rarity:
			var tier: int = int(key)
			result[tier] = float(result.get(tier, 0.0)) + float(rarity[key]) * level
	return result


## The "stats" of every bought level, as one source for RunState (_mult values multiplied per
## level, the others added).
static func run_stats() -> Dictionary:
	var result: Dictionary = {}
	for id: String in all():
		var level: int = MetaState.skill_level(id)
		if level <= 0:
			continue
		var stats: Dictionary = (data(id).get("effect", {}) as Dictionary).get("stats", {})
		for key: String in stats:
			var value: float = float(stats[key])
			if key.ends_with("_mult"):
				result[key] = float(result.get(key, 1.0)) * pow(value, level)
			else:
				result[key] = float(result.get(key, 0.0)) + value * level
	return result


# --- Player levels (data/levels.json) ------------------------------------------------

static func levels() -> Dictionary:
	return Content.get_file("levels")


## EXP needed from `level` to the next one (0 at the highest level): the first ones from
## levels.json exp_table, then base_exp × growth^level, at least the last value of the table.
static func exp_to_next(level: int) -> int:
	var rules: Dictionary = levels()
	if level >= int(rules.get("max_level", 30)) or level < 0:
		return 0
	var table: Array = rules.get("exp_table", [30])
	if table.is_empty():
		return 0
	if level < table.size():
		return int(table[level])
	return maxi(int(table.back()), roundi(float(rules.get("base_exp", 30)) * pow(float(rules.get("growth", 1.25)), level)))


## EXP for one kill (a boss gives more).
static func kill_exp(boss: bool) -> int:
	return int(levels().get("exp_per_boss" if boss else "exp_per_kill", 1))
