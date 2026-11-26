class_name GuildLevel
extends RefCounted
## How far Hedwig has expanded the adventurers' guild (side tasks after the rebuilding, part 2).
## The levels are in data/content/guild_heroes.json "guild_levels" (one entry per level, in order):
## "flag" (story flag of the level, set by Hedwig's dialogue), "hero_slots" (more hero places),
## "level" / "count" (level range and number of the heroes offered every day), "search_orders"
## (how many search orders can run at once) and "search_max_rarity" (best rarity, e.g. "R3").
## Without a level: base values of guild_heroes.json, no search orders.

const DATA_PATH: String = "res://data/content/guild_heroes.json"

static var _levels: Array = []


## All levels from guild_heroes.json (in order).
static func get_levels() -> Array:
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
