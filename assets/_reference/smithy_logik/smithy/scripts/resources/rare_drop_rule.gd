class_name RareDropRule
extends RefCounted
## One entry of combat.json "rare_drops": an item that no monster drops by chance, but every
## monster of some regions counts towards (RareDrops). After about `mean_kills` kills one drops;
## the number of kills is drawn from a normal distribution (mean_kills, spread), kept between
## min_kills and max_kills.

var item: ItemData = null
## Dungeon regions (dungeons.json "region") whose monsters count.
var regions: PackedStringArray = []
var mean_kills: float = 50.0
var spread: float = 15.0
var min_kills: float = 1.0
var max_kills: float = 100.0


## Builds the rule for item `id`; reports bad values with push_error. null when the item is unknown.
static func from_json(id: String, data: Dictionary, items: Dictionary, known_regions: PackedStringArray) -> RareDropRule:
	if not items.has(id):
		push_error("ContentDB: combat.json, rare_drops: unknown item '%s'." % id)
		return null
	var rule := RareDropRule.new()
	rule.item = items[id]
	for region: String in data.get("regions", []):
		if known_regions.has(region):
			rule.regions.append(region)
		else:
			push_error("ContentDB: combat.json, rare_drops '%s': unknown region '%s'." % [id, region])
	rule.mean_kills = float(data.get("mean_kills", rule.mean_kills))
	rule.spread = float(data.get("spread", rule.spread))
	rule.min_kills = maxf(1.0, float(data.get("min_kills", rule.min_kills)))
	rule.max_kills = float(data.get("max_kills", rule.max_kills))
	if rule.regions.is_empty() or rule.mean_kills < rule.min_kills or rule.max_kills < rule.mean_kills or rule.spread < 0.0:
		push_error("ContentDB: combat.json, rare_drops '%s': needs regions and min_kills <= mean_kills <= max_kills, spread >= 0." % id)
	return rule


## Kills until the next drop: normally distributed, clamped to [min_kills, max_kills].
func roll_target() -> float:
	return clampf(randfn(mean_kills, spread), min_kills, max_kills)


func covers(dungeon: DungeonData) -> bool:
	return dungeon != null and regions.has(dungeon.region)
