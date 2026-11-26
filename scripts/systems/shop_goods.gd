class_name ShopGoods
extends RefCounted
## Egon's goods (data/shop.json, data/gear.json): what lies on the table after the lever, what a
## piece costs and what it gives. Only rules, no screen; MetaState keeps the table, the shop shows it.
## A piece of gear (on the table, in the inventory, on the hero) is {id, rarity} (+ price on the
## table, + count 1 in the inventory).
## A relic (data/relics.json) is {id (an item of items.json), relic: true, left} (+ price on the
## table): left = runs it still holds (-1 = for ever). Only items picked up once (Progress) come.


## A new table: data/shop.json table_slots places, goods_count pieces (+ skill Mehr Ware,
## effect goods_extra) on random places, the rest {}. The rarities use the chances of pull number
## `pulls_today` (0 = the first pull today; every further pull is better, rarity_weights).
static func roll(rng: RandomNumberGenerator, pulls_today: int = 0) -> Array[Dictionary]:
	var rules: Dictionary = Content.shop()
	var table: Array[Dictionary] = empty_table()
	var range_count: Array = rules.get("goods_count", [1, 3])
	var extra: int = goods_extra()
	var count: int = mini(rng.randi_range(int(range_count[0]) + extra, int(range_count[1]) + extra), table.size())
	var weights: Array = rarity_weights(pulls_today)
	var cells: Array[int] = []
	for i in table.size():
		cells.append(i)
	for n in count:
		var cell: int = cells.pop_at(rng.randi_range(0, cells.size() - 1))
		var id: String = Content.pick_weighted(rules.get("pool", []), rng)
		table[cell] = make_piece(id, _pick_rarity(weights, rng))
	# Sometimes a relic: an item the player has found, on a free place.
	var relic: String = pick_relic(rng)
	cells = []
	for i in table.size():
		if table[i].is_empty():
			cells.append(i)
	if not relic.is_empty() and not cells.is_empty() and rng.randf() < float(Content.relics().get("table_chance", 0.0)):
		table[cells[rng.randi_range(0, cells.size() - 1)]] = make_relic(relic)
	return table


## A random relic among the items found so far (stronger tiers rarer, relics.json weight); "" if
## none was found yet.
static func pick_relic(rng: RandomNumberGenerator) -> String:
	var choices: Array = []
	for id: Variant in Progress.discovered():
		var tier: int = relic_tier(String(id))
		if tier > 0 and is_tier_open(tier):
			choices.append([String(id), float(_tier(tier).get("weight", 1))])
	return Content.pick_weighted(choices, rng) if not choices.is_empty() else ""


## More goods on the table from the skills (skills.json effect goods_extra).
static func goods_extra() -> int:
	return maxi(0, int(Skills.bonus("goods_extra")))


## [rarity, weight] pairs for the player level (shop.json rarity_by_level: the last entry whose
## level is reached), without skills and pulls.
static func base_weights() -> Array:
	var weights: Array = [[1, 1]]
	for entry: Dictionary in Content.shop().get("rarity_by_level", []):
		if MetaState.level() >= int(entry.get("level", 0)):
			weights = entry.get("weights", weights)
	return weights


## How many percent the pull number `pulls_today` (0 = the first today) moves from R1 to the
## higher rarities: shop.json reroll_shift per earlier pull today, at most reroll_shift_max.
static func reroll_shift(pulls_today: int) -> float:
	var rules: Dictionary = Content.shop()
	return clampf(float(rules.get("reroll_shift", 0.0)) * maxi(0, pulls_today), 0.0, float(rules.get("reroll_shift_max", 0.0)))


## [rarity, percent] pairs for pull number `pulls_today` (0 = the first today; -1 = the next pull,
## MetaState.pulls_today). Starts from base_weights (in percent), then:
##   - skills (effect "rarity": {"2": 5}): that many percent per level from R1 to that rarity;
##   - every earlier pull today: reroll_shift percent from R1 to the higher rarities there are,
##     shared out like their chances (nothing to share at a level with only R1).
## R1 never drops below shop.json r1_min percent.
static func rarity_weights(pulls_today: int = -1) -> Array:
	if pulls_today < 0:
		pulls_today = MetaState.pulls_today()
	var percent: Dictionary = {}
	var total: float = 0.0
	for entry: Array in base_weights():
		total += float(entry[1])
	for entry: Array in base_weights():
		percent[int(entry[0])] = float(entry[1]) / total * 100.0 if total > 0.0 else 0.0
	if not percent.has(1):
		percent[1] = 0.0
	var r1_min: float = float(Content.shop().get("r1_min", 0.0))
	var bonus: Dictionary = Skills.rarity_bonus()
	for tier: int in bonus:
		var moved: float = minf(float(bonus[tier]), maxf(0.0, percent[1] - r1_min))
		if tier <= 1 or moved <= 0.0:
			continue
		percent[1] -= moved
		percent[tier] = float(percent.get(tier, 0.0)) + moved
	var higher: float = 0.0
	for tier: int in percent:
		if tier > 1:
			higher += percent[tier]
	var shift: float = minf(reroll_shift(pulls_today), maxf(0.0, percent[1] - r1_min))
	if higher > 0.0 and shift > 0.0:
		for tier: int in percent.keys():
			if tier > 1:
				percent[tier] += shift * percent[tier] / higher
		percent[1] -= shift
	var tiers: Array = percent.keys()
	tiers.sort()
	var result: Array = []
	for tier: int in tiers:
		if percent[tier] > 0.0:
			result.append([tier, percent[tier]])
	return result


## The chance of every rarity on the next pull, in percent: [[rarity, percent], …] (the bar over
## the lever shows it).
static func rarity_chances() -> Array:
	var weights: Array = rarity_weights()
	var total: float = 0.0
	for entry: Array in weights:
		total += float(entry[1])
	var result: Array = []
	for entry: Array in weights:
		result.append([int(entry[0]), float(entry[1]) / total * 100.0 if total > 0.0 else 0.0])
	return result


## A relic tier can come on the table from its player level on (relics.json tiers level).
static func is_tier_open(tier: int) -> bool:
	return MetaState.level() >= int(_tier(tier).get("level", 0))


## The relic tiers that can come now (1, 2 …).
static func open_relic_tiers() -> Array[int]:
	var tiers: Array[int] = []
	for key: String in (Content.relics().get("tiers", {}) as Dictionary):
		if is_tier_open(int(key)):
			tiers.append(int(key))
	tiers.sort()
	return tiers


## 0 = this item cannot be a relic.
static func relic_tier(id: String) -> int:
	return int((Content.relics().get("items", {}) as Dictionary).get(id, 0))


static func _tier(tier: int) -> Dictionary:
	return (Content.relics().get("tiers", {}) as Dictionary).get(str(tier), {})


## Runs a new relic holds: tier "dungeons" (0 = for ever, then -1).
static func relic_runs(id: String) -> int:
	var runs: int = int(_tier(relic_tier(id)).get("dungeons", 0))
	return -1 if runs <= 0 else runs


static func relic_rarity(id: String) -> int:
	return int(_tier(relic_tier(id)).get("rarity", 1))


## A relic for the table; the skill Reliktpflege (relic_runs) makes new ones hold longer.
static func make_relic(id: String) -> Dictionary:
	var runs: int = relic_runs(id)
	if runs > 0:
		runs += int(Skills.bonus("relic_runs"))
	return {"id": id, "relic": true, "left": runs, "price": int(_tier(relic_tier(id)).get("price", 0))}


## What Egon pays for a piece of the inventory: loot = loot.json value × count; gear and relics =
## shop.json sell_share of their price (at least 1).
static func sell_price(piece: Dictionary) -> int:
	var id: String = String(piece.get("id", ""))
	var count: int = maxi(1, int(piece.get("count", 1)))
	var share: float = float(Content.shop().get("sell_share", 0.3))
	if is_relic(piece):
		return maxi(1, roundi(float(_tier(relic_tier(id)).get("price", 0)) * share))
	if is_gear(id):
		return maxi(1, roundi(price(id, int(piece.get("rarity", 1))) * share))
	return int(Content.material(id).get("value", 0)) * count


static func is_relic(piece: Dictionary) -> bool:
	return bool(piece.get("relic", false))


## [rarity, weight] pairs; JSON numbers are floats, so they become "1", "2" … before picking.
static func _pick_rarity(weights: Array, rng: RandomNumberGenerator) -> int:
	var table: Array = []
	for entry: Array in weights:
		table.append([str(int(entry[0])), entry[1]])
	return maxi(1, int(Content.pick_weighted(table, rng)))


## The table of the first visit (data/shop.json tutorial.goods).
static func tutorial_table() -> Array[Dictionary]:
	var table: Array[Dictionary] = empty_table()
	for entry: Dictionary in (Content.shop().get("tutorial", {}) as Dictionary).get("goods", []):
		var cell: int = int(entry.get("cell", 0))
		if cell >= 0 and cell < table.size():
			table[cell] = make_piece(String(entry["id"]), int(entry.get("rarity", 1)))
	return table


static func empty_table() -> Array[Dictionary]:
	var table: Array[Dictionary] = []
	for i in int(Content.shop().get("table_slots", 10)):
		table.append({})
	return table


static func make_piece(id: String, rarity: int) -> Dictionary:
	return {"id": id, "rarity": rarity, "price": price(id, rarity)}


## Base price (gear.json) times shop.json rarity_price of the rarity.
static func price(id: String, rarity: int) -> int:
	var factors: Array = Content.shop().get("rarity_price", [1.0])
	var factor: float = float(factors[clampi(rarity, 1, factors.size()) - 1])
	return roundi(float(Content.gear_item(id).get("price", 0)) * factor)


## The stats of a piece: gear.json stats times rarity_stats of its rarity.
static func stats(id: String, rarity: int) -> Dictionary:
	var factors: Array = Content.get_file("gear").get("rarity_stats", [1.0])
	var factor: float = float(factors[clampi(rarity, 1, factors.size()) - 1])
	var result: Dictionary = {}
	var base: Dictionary = Content.gear_item(id).get("stats", {})
	for key: String in base:
		result[key] = float(base[key]) * factor
	return result


static func is_gear(id: String) -> bool:
	return Content.gear().has(id)


## The price of the lever today: shop.json roll_prices[number of pulls today] (the last value for
## every pull after). The first pull of a day is free.
static func roll_price(pulls_today: int) -> int:
	var prices: Array = Content.shop().get("roll_prices", [0])
	return int(prices[clampi(pulls_today, 0, prices.size() - 1)])
