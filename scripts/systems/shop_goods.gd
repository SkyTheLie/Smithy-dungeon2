class_name ShopGoods
extends RefCounted
## Egon's goods (data/shop.json, data/gear.json): what lies on the table after the lever, what a
## piece costs and what it gives. Only rules, no screen; MetaState keeps the table, the shop shows it.
## A piece of gear (on the table, in the inventory, on the hero) is {id, rarity} (+ type, its
## Bauart, gear.json types; missing = normal) (+ price on the table, + count 1 in the inventory).
## A relic (data/relics.json) is {id (an item of items.json), relic: true, left} (+ price on the
## table): left = runs it still holds (-1 = for ever). Only items picked up once (Progress) come.
## A potion (data/potions.json) is {id, potion: true} (+ price on the table). Potions only come
## after Egon showed them (MetaState.potions_unlocked).
## A backpack (data/backpacks.json) is {id, backpack: true} (+ price on the table).
## A container (data/containers.json) is {id, container: true, items: [pieces]} (+ price on the
## table): it stays in the stash at home and holds pieces of its kind (container_accepts).
## Every piece covers piece_size cells in the stash and on the table (grid, ItemGrid).


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
	var materials: Array = open_materials()
	for n in count:
		var cell: int = cells.pop_at(rng.randi_range(0, cells.size() - 1))
		var material: String = Content.pick_weighted(materials, rng) if not materials.is_empty() else "copper"
		var id: String = "%s_%s" % [material, Content.pick_weighted(rules.get("pool", []), rng)]
		if not is_gear(id):
			continue
		table[cell] = make_piece(id, _pick_rarity(weights, rng), pick_type(id, rng))
	# Sometimes a relic: an item the player has found, on a free place.
	var relic: String = pick_relic(rng)
	cells = []
	for i in table.size():
		if table[i].is_empty():
			cells.append(i)
	if not relic.is_empty() and not cells.is_empty() and rng.randf() < float(Content.relics().get("table_chance", 0.0)):
		var cell: int = cells[rng.randi_range(0, cells.size() - 1)]
		cells.erase(cell)
		table[cell] = make_relic(relic)
	# After Egon showed them: sometimes a potion.
	var potion: String = pick_potion(rng)
	if not potion.is_empty() and not cells.is_empty() and rng.randf() < float(Content.potions().get("table_chance", 0.0)):
		var potion_cell: int = cells[rng.randi_range(0, cells.size() - 1)]
		cells.erase(potion_cell)
		table[potion_cell] = make_potion(potion)
	# Sometimes a backpack (backpacks.json "unlock", shop.json backpack_chance).
	var backpack: String = pick_backpack(rng)
	if not backpack.is_empty() and not cells.is_empty() and rng.randf() < float(Content.shop().get("backpack_chance", 0.0)):
		var backpack_cell: int = cells[rng.randi_range(0, cells.size() - 1)]
		cells.erase(backpack_cell)
		table[backpack_cell] = make_backpack(backpack)
	# Sometimes a container (containers.json "unlock", shop.json container_chance).
	var container: String = pick_container(rng)
	if not container.is_empty() and not cells.is_empty() and rng.randf() < float(Content.shop().get("container_chance", 0.0)):
		table[cells[rng.randi_range(0, cells.size() - 1)]] = make_container(container)
	return table


# --- Containers (data/containers.json) -------------------------------------------------

static func containers() -> Dictionary:
	return Content.get_file("containers").get("containers", {})


static func container_data(id: String) -> Dictionary:
	return containers().get(id, {})


static func is_container(piece: Dictionary) -> bool:
	return bool(piece.get("container", false))


## A container on the table: {id, container: true, price}.
static func make_container(id: String) -> Dictionary:
	return {"id": id, "container": true, "price": maxi(0, int(container_data(id).get("price", 0)))}


## A random container whose "unlock" is met ("" = none open).
static func pick_container(rng: RandomNumberGenerator) -> String:
	var open: Array[String] = []
	for id: String in containers():
		if MetaState.meets((container_data(id)).get("unlock", {})):
			open.append(id)
	return "" if open.is_empty() else open[rng.randi_range(0, open.size() - 1)]


## Places of container `id` (at least 1).
static func container_slots(id: String) -> int:
	return maxi(1, int(container_data(id).get("slots", 1)))


## How many of one loot fit on one place of container `id`.
static func container_stack(id: String) -> int:
	return maxi(1, int(container_data(id).get("stack", 1)))


## The kind of a piece for containers: relic, weapon, gear, loot ("" = none: backpacks,
## containers, potions, coins, quest stones).
static func kind_of(piece: Dictionary) -> String:
	var id: String = String(piece.get("id", ""))
	if is_relic(piece):
		return "relic"
	if is_potion(piece) or is_backpack(piece) or is_container(piece):
		return ""
	if is_gear(id):
		return "weapon" if String(Content.gear_item(id).get("slot", "")) == "weapon" else "gear"
	if id == Bag.GOLD or Quests.is_stone(id) or Content.material(id).is_empty():
		return ""
	return "loot"


## true if container `id` takes `piece` (its kind).
static func container_accepts(id: String, piece: Dictionary) -> bool:
	var kind: String = kind_of(piece)
	return not kind.is_empty() and kind == String(container_data(id).get("kind", ""))


# --- Backpacks (data/backpacks.json) ---------------------------------------------------

static func is_backpack(piece: Dictionary) -> bool:
	return bool(piece.get("backpack", false))


## A backpack on the table: {id, backpack: true, price}.
static func make_backpack(id: String) -> Dictionary:
	return {"id": id, "backpack": true, "price": maxi(0, int(BagLayout.backpack(id).get("price", 0)))}


## A random backpack whose "unlock" is met ("" = none open).
static func pick_backpack(rng: RandomNumberGenerator) -> String:
	var open: Array[String] = []
	for id: String in BagLayout.backpacks():
		if MetaState.meets((BagLayout.backpack(id) as Dictionary).get("unlock", {})):
			open.append(id)
	return "" if open.is_empty() else open[rng.randi_range(0, open.size() - 1)]


## Width × height in cells of a piece (not turned): backpacks their size, relics and potions 1×1,
## gear the size of its gear.json slot, loot loot.json size.
static func piece_size(piece: Dictionary) -> Vector2i:
	var id: String = String(piece.get("id", ""))
	if is_backpack(piece):
		return BagLayout.backpack_size(id)
	if is_relic(piece) or is_potion(piece):
		return Vector2i.ONE
	if is_container(piece):
		var span: Array = container_data(id).get("size", [1, 1])
		return Vector2i(maxi(1, int(span[0])), maxi(1, int(span[1])))
	if is_gear(id):
		var slot: Dictionary = Content.gear_slots().get(String(Content.gear_item(id).get("slot", "")), {})
		var cells: Array = slot.get("size", [1, 1])
		return Vector2i(maxi(1, int(cells[0])), maxi(1, int(cells[1])))
	return BagLayout.loot_size(id)


# --- Potions (data/potions.json) -------------------------------------------------------

static func is_potion(piece: Dictionary) -> bool:
	return bool(piece.get("potion", false))


## A potion on the table: {id, potion: true, price}.
static func make_potion(id: String) -> Dictionary:
	return {"id": id, "potion": true, "price": maxi(0, int(Content.potion(id).get("price", 0)))}


## A random potion that may come on the table now (only after Egon showed them, only open ones
## by their "unlock"); "" = none.
static func pick_potion(rng: RandomNumberGenerator) -> String:
	if not MetaState.potions_unlocked():
		return ""
	var choices: Array = []
	for id: String in (Content.potions().get("potions", {}) as Dictionary):
		if MetaState.meets((Content.potion(id)).get("unlock", {})):
			choices.append([id, 1.0])
	return Content.pick_weighted(choices, rng) if not choices.is_empty() else ""


## The table of Egon's potion show: only the potion he gives away (potions.json tour_potion),
## in the middle of the table.
static func potion_table() -> Array[Dictionary]:
	var table: Array[Dictionary] = empty_table()
	var id: String = String(Content.potions().get("tour_potion", ""))
	if not Content.potion(id).is_empty() and not table.is_empty():
		table[mini(2, table.size() - 1)] = make_potion(id)
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


## The materials that can come on the table now: [[id, weight], …] in shop.json order. Only open
## ones (unlock: MetaState.meets); those two or more steps below the best open one are
## old_material_mult times as likely (old copper gets rare once iron is open).
static func open_materials() -> Array:
	var rules: Dictionary = Content.shop()
	var all: Dictionary = rules.get("materials", {})
	var open: Array[String] = []
	for id: String in all:
		if MetaState.meets((all[id] as Dictionary).get("unlock", {})):
			open.append(id)
	var best: int = -1
	var order: Array = all.keys()
	for id: String in open:
		best = maxi(best, order.find(id))
	var result: Array = []
	for id: String in open:
		var weight: float = float((all[id] as Dictionary).get("weight", 1))
		if best - order.find(id) >= 2:
			weight *= float(rules.get("old_material_mult", 1.0))
		result.append([id, weight])
	return result


## The chance of every open material, in percent: [[id, percent], …] (the bar's tooltip).
static func material_chances() -> Array:
	var materials: Array = open_materials()
	var total: float = 0.0
	for entry: Array in materials:
		total += float(entry[1])
	var result: Array = []
	for entry: Array in materials:
		result.append([String(entry[0]), float(entry[1]) / total * 100.0 if total > 0.0 else 0.0])
	return result


## The German name of material `id` (shop.json materials, a translation key).
static func material_name(id: String) -> String:
	return String(((Content.shop().get("materials", {}) as Dictionary).get(id, {}) as Dictionary).get("name", id))


## The first material that is still closed and what opens it ({} = all open): {id, unlock}.
static func next_material() -> Dictionary:
	var all: Dictionary = Content.shop().get("materials", {})
	for id: String in all:
		var unlock: Dictionary = (all[id] as Dictionary).get("unlock", {})
		if not MetaState.meets(unlock):
			return {"id": id, "unlock": unlock}
	return {}


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


## true when `piece` (a relic) never breaks: it holds for ever (left -1), or the skill
## Reliktschutz (relic_keep_tier) protects its tier.
static func relic_forever(piece: Dictionary) -> bool:
	return int(piece.get("left", -1)) < 0 or relic_tier(String(piece.get("id", ""))) <= int(Skills.bonus("relic_keep_tier"))


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
	if is_potion(piece):
		return maxi(1, roundi(float(Content.potion(id).get("price", 0)) * share))
	if is_backpack(piece):
		return maxi(1, roundi(float(BagLayout.backpack(id).get("price", 0)) * share))
	# A container is only sold empty.
	if is_container(piece):
		return 0 if not (piece.get("items", []) as Array).is_empty() else maxi(1, roundi(float(container_data(id).get("price", 0)) * share))
	if Quests.is_stone(id):
		return 0
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


## A piece of gear on the table; `type` = its Bauart (gear.json types, "" / "normal" = none).
static func make_piece(id: String, rarity: int, type: String = "") -> Dictionary:
	var piece: Dictionary = {"id": id, "rarity": rarity, "price": price(id, rarity)}
	if not type_data(id, type).is_empty() and type != NORMAL:
		piece["type"] = type
	return piece


# --- Bauarten (data/gear.json types) ---------------------------------------------------

const NORMAL: String = "normal"


## The Bauarten of gear `id` (by its slot): type -> {name, weight, mult, stats}.
static func types_of(id: String) -> Dictionary:
	var slot: String = String(Content.gear_item(id).get("slot", ""))
	return (Content.get_file("gear").get("types", {}) as Dictionary).get(slot, {})


## Bauart `type` of gear `id` ({} = unknown; "" counts as normal).
static func type_data(id: String, type: String) -> Dictionary:
	return types_of(id).get(NORMAL if type.is_empty() else type, {})


## A random Bauart for gear `id` by the weights (NORMAL when the slot has none).
static func pick_type(id: String, rng: RandomNumberGenerator) -> String:
	var table: Array = []
	var all: Dictionary = types_of(id)
	for type: String in all:
		table.append([type, float((all[type] as Dictionary).get("weight", 1.0))])
	return Content.pick_weighted(table, rng) if not table.is_empty() else NORMAL


## The name of the Bauart of `piece` (German key; "" for normal).
static func type_name(piece: Dictionary) -> String:
	return String(type_data(String(piece.get("id", "")), String(piece.get("type", ""))).get("name", ""))


## Base price (gear.json) times shop.json rarity_price of the rarity.
static func price(id: String, rarity: int) -> int:
	var factors: Array = Content.shop().get("rarity_price", [1.0])
	var factor: float = float(factors[clampi(rarity, 1, factors.size()) - 1])
	return roundi(float(Content.gear_item(id).get("price", 0)) * factor)


## The stats of a piece: gear.json stats times the mult of its Bauart `type`, times rarity_stats
## of its rarity; then the stats of the Bauart (its pros and cons, not grown by the rarity).
static func stats(id: String, rarity: int, type: String = "") -> Dictionary:
	var factors: Array = Content.get_file("gear").get("rarity_stats", [1.0])
	var factor: float = float(factors[clampi(rarity, 1, factors.size()) - 1])
	var kind: Dictionary = type_data(id, type)
	var mult: Dictionary = kind.get("mult", {})
	var result: Dictionary = {}
	var base: Dictionary = Content.gear_item(id).get("stats", {})
	for key: String in base:
		result[key] = float(base[key]) * float(mult.get(key, 1.0)) * factor
	var extra: Dictionary = kind.get("stats", {})
	for key: String in extra:
		if key.ends_with("_mult"):
			result[key] = float(result.get(key, 1.0)) * float(extra[key])
		else:
			result[key] = float(result.get(key, 0.0)) + float(extra[key])
	return result


## stats of a worn / owned piece {id, rarity, type}.
static func piece_stats(piece: Dictionary) -> Dictionary:
	return stats(String(piece.get("id", "")), int(piece.get("rarity", 1)), String(piece.get("type", "")))


static func is_gear(id: String) -> bool:
	return Content.gear().has(id)


## The price of the lever today: shop.json roll_prices[number of pulls today] (the last value for
## every pull after), times lever_mult of the best open material (iron goods: a dearer lever).
## The first pull of a day is free.
static func roll_price(pulls_today: int) -> int:
	var prices: Array = Content.shop().get("roll_prices", [0])
	return roundi(float(prices[clampi(pulls_today, 0, prices.size() - 1)]) * lever_mult())


## lever_mult of the best open material (shop.json materials; 1 without).
static func lever_mult() -> float:
	var all: Dictionary = Content.shop().get("materials", {})
	var mult: float = 1.0
	for entry: Array in open_materials():
		mult = float((all[String(entry[0])] as Dictionary).get("lever_mult", mult))
	return mult
