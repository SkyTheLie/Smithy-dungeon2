class_name ShopGoods
extends RefCounted
## Egon's goods (data/shop.json, data/gear.json): what lies on the table after the lever, what a
## piece costs and what it gives. Only rules, no screen; MetaState keeps the table, the shop shows it.
## A piece of gear (on the table, in the inventory, on the hero) is {id, rarity} (+ price on the
## table, + count 1 in the inventory).
## A relic (data/relics.json) is {id (an item of items.json), relic: true, left} (+ price on the
## table): left = runs it still holds (-1 = for ever). Only items picked up once (Progress) come.


## A new table: data/shop.json table_slots places, goods_count pieces on random places, the rest {}.
static func roll(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rules: Dictionary = Content.shop()
	var table: Array[Dictionary] = empty_table()
	var range_count: Array = rules.get("goods_count", [1, 3])
	var count: int = mini(rng.randi_range(int(range_count[0]), int(range_count[1])), table.size())
	var cells: Array[int] = []
	for i in table.size():
		cells.append(i)
	for n in count:
		var cell: int = cells.pop_at(rng.randi_range(0, cells.size() - 1))
		var id: String = Content.pick_weighted(rules.get("pool", []), rng)
		table[cell] = make_piece(id, _pick_rarity(rules.get("rarity_weights", [[1, 1]]), rng))
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
		if tier > 0:
			choices.append([String(id), float(_tier(tier).get("weight", 1))])
	return Content.pick_weighted(choices, rng) if not choices.is_empty() else ""


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
