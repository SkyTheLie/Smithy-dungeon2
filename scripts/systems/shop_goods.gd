class_name ShopGoods
extends RefCounted
## Egon's goods (data/shop.json, data/gear.json): what lies on the table after the lever, what a
## piece costs and what it gives. Only rules, no screen; MetaState keeps the table, the shop shows it.
## A piece of gear (on the table, in the inventory, on the hero) is {id, rarity} (+ price on the
## table, + count 1 in the inventory).


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
	return table


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
