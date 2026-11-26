class_name GuildLevel
extends RefCounted
## How far Hedwig has expanded the adventurers' guild (side tasks after the rebuilding, part 2).
## The levels are in data/content/guild_heroes.json "guild_levels" (one entry per level, in order):
## "flag" (story flag of the level, set by Hedwig's dialogue), "hero_slots" (more hero places),
## "level" / "count" (level range and number of the heroes offered every day), "search_orders"
## (how many search orders can run at once), "search_max_rarity" (best rarity, e.g. "R3") and
## "stamina_rest_bonus" (heroes get this much more stamina back per hour and per night, 0.25 = +25 %).
## Without a level: base values of guild_heroes.json, no search orders, no stamina bonus.
## From which story point Hedwig offers a level stands in story/side.json (guild_upgrade_*_intro).

const DATA_PATH: String = "res://data/content/guild_heroes.json"
## Hedwig told about the guild expansion (first level, side.json "guild_upgrade_intro").
const UPGRADE_HEARD_FLAG: String = "guild_upgrade_heard"
## Hedwig offered level %d (from level 2 on; side.json "guild_upgrade_%d_intro").
const INTRO_FLAG: String = "guild_upgrade_%d_heard"

static var _levels: Array = []  # content cache, cleared with ContentDB.reload()
static var _levels_generation: int = -1


## All levels from guild_heroes.json (in order).
static func get_levels() -> Array:
	if _levels_generation != ContentDB.generation:
		_levels = []
		_levels_generation = ContentDB.generation
	if _levels.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_levels = (parsed as Dictionary).get("guild_levels", [])
	return _levels


## Reached level: 0 = not expanded, 1 = first level ... (the levels count in order).
static func get_level(story: Story) -> int:
	var level: int = 0
	for entry: Dictionary in get_levels():
		if not story.flags.has(str(entry.get("flag", ""))):
			break
		level += 1
	return level


## The entry of the reached level ({} = not expanded).
static func get_info(story: Story) -> Dictionary:
	var level: int = get_level(story)
	return get_levels()[level - 1] if level > 0 else {}


## Extra hero places of all reached levels.
static func get_hero_slots(story: Story) -> int:
	var slots: int = 0
	for i in get_level(story):
		slots += int(get_levels()[i].get("hero_slots", 0))
	return slots


## How many search orders can run at once (0 = none yet).
static func get_search_order_slots(story: Story) -> int:
	return int(get_info(story).get("search_orders", 0))


## Best rarity adventurers can search for (Rarity.Tier as int).
static func get_search_max_rarity(story: Story) -> int:
	var short_name: String = str(get_info(story).get("search_max_rarity", "R1"))
	return clampi(int(short_name.substr(1)) - 1, 0, Rarity.NAMES.size() - 1)


## Factor on the stamina heroes get back per hour and per night (1.0 = not expanded).
static func get_stamina_factor(story: Story) -> float:
	return 1.0 + float(get_info(story).get("stamina_rest_bonus", 0.0))


## Sets the guild to `level` (0 = not expanded): sets the flags of all levels up to it and removes
## the others, together with the flags that lead to them (Hedwig's offers). DEV-ONLY (admin panel).
static func set_level(story: Story, level: int) -> void:
	var levels: Array = get_levels()
	level = clampi(level, 0, levels.size())
	if level > 0:
		story.set_flag(UPGRADE_HEARD_FLAG)
	var removed: Array = []
	for i in levels.size():
		var flag: String = str(levels[i].get("flag", ""))
		var heard: String = INTRO_FLAG % (i + 1)
		if i < level:
			story.set_flag(flag)
			if i > 0:
				story.set_flag(heard)
		else:
			removed.append(flag)
			if i > 0:
				removed.append(heard)
	story.clear_flags(removed)
