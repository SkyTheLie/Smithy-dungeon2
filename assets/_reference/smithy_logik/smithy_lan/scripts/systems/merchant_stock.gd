class_name MerchantStock
extends RefCounted
## What every merchant has in stock today, with amounts (lives in GameState.merchant_stock, saved).
## Rolled again on the first visit of a new day; what is bought out stays gone until the next day.
## Merchants with a stock_id get their range from economy.json "market_stock.<id>": items
## (with rank, story flag, chance, random pick, fixed / rare price, "always") and generated equipment
## (weapons/armor of the materials of the current reputation rank, plus their parts, sometimes R2).
## Other merchants (Leonheim, black market, traveller) keep their fixed offers; their items get
## an amount from "market_stock.default". Stations, recipes, molds and furniture have no amount.
## A stock entry: {"spec": item spec (ContentDB.make_stack, rarity fixed, e.g. "ruby@R2") or
## "station:" / "recipe:" / "mold:" / "furniture:" / "potion_recipe:" offer, "amount": pieces left (-1 = no limit),
## "price": fixed price per piece (0 = from the item value)}.

const UNLIMITED: int = -1
const NON_ITEM_PREFIXES: Array[String] = ["station:", "recipe:", "mold:", "furniture:", "potion_recipe:"]

## Merchant key -> {"day": int, "entries": Array[Dictionary]}.
var _stocks: Dictionary = {}


## Today's entries of a merchant (rolled if the day changed). `key` identifies the merchant
## (Merchant.get_stock_key), `offers` = its fixed offers, `stock_id` = its market_stock section
## (empty = fixed offers with default amounts). Entries are shared: change them via take().
func get_entries(key: String, offers: Array[String], stock_id: String = "") -> Array:
	var limit: Dictionary = get_active_limit()
	if not limit.is_empty():
		# A story phase limits what can be bought (own stock per phase, so the next phase and the
		# normal stock afterwards are rolled fresh, even on the same day).
		key = "limit:%s:%s" % [limit.get("from", ""), key]
	var day: int = GameState.day_cycle.day
	var stock: Dictionary = _stocks.get(key, {})
	if stock.is_empty() or int(stock.get("day", -1)) != day:
		var entries: Array = roll(offers, stock_id) if limit.is_empty() else _roll_limited(limit, offers, stock_id)
		stock = {"day": day, "entries": entries}
		_stocks[key] = stock
	elif limit.is_empty() and not _has_random_offers(stock_id):
		_add_missing_offers(stock["entries"], offers)
	elif limit.is_empty():
		_add_always_offers(stock["entries"], offers, stock_id)
	return stock["entries"]


## "always_offers" whose flag was set after today's stock was rolled (e.g. "Die Goblinburg" begins
## in the afternoon, or an old save) join right away instead of only after the next sleep.
## Bought ones (_can_buy_now false) are not added again.
static func _add_always_offers(entries: Array, offers: Array[String], stock_id: String) -> void:
	var always_offers: Dictionary = ContentDB.economy("market_stock").get(stock_id, {}).get("always_offers", {})
	if always_offers.is_empty():
		return
	var known: Dictionary = {}
	for entry: Dictionary in entries:
		known[entry["spec"]] = true
	for spec in offers:
		if always_offers.has(spec) and not known.has(spec) and GameState.story.has_flag(always_offers[spec]) 				and _can_buy_now(spec):
			entries.append({"spec": spec, "amount": UNLIMITED, "price": 0})


## Non-item offers (stations, furniture, recipes) have no amount, so they don't need a new roll:
## ones added to `offers` after today's stock was rolled (new content, old save) join right away.
static func _add_missing_offers(entries: Array, offers: Array[String]) -> void:
	var known: Dictionary = {}
	for entry: Dictionary in entries:
		known[entry["spec"]] = true
	for spec in offers:
		if not is_item_spec(spec) and not known.has(spec):
			entries.append({"spec": spec, "amount": UNLIMITED, "price": 0})


## The economy.json "market_stock.story_limits" entry that is active now ({} = none): from its
## "from" flag until its "until" flag the merchants only sell what is listed there, e.g. after
## Bruno's begging just the copper, coal and wood for his sword (else the gold is gone and the
## rat cellar can't be paid).
static func get_active_limit() -> Dictionary:
	for limit: Dictionary in ContentDB.economy("market_stock").get("story_limits", []):
		var story: Story = GameState.story
		if story.is_running() and story.flags.has(limit.get("from", "")) and not story.flags.has(limit.get("until", "")):
			return limit
	return {}


## Stock during a story limit: the "stocks" lines of this merchant's stock_id (same format as
## "items", nothing else), and of the fixed offers only those in "offers" (e.g. two molds).
static func _roll_limited(limit: Dictionary, offers: Array[String], stock_id: String) -> Array:
	var entries: Array = []
	for item_config: Dictionary in limit.get("stocks", {}).get(stock_id, []):
		var entry: Dictionary = _roll_item(item_config)
		if not entry.is_empty():
			entries.append(entry)
	var allowed: Array = limit.get("offers", [])
	for spec in offers:
		if allowed.has(spec):
			entries.append({"spec": spec, "amount": UNLIMITED, "price": 0} if not is_item_spec(spec) else _fixed_entry(spec))
	return entries


## One piece of an entry was bought: one less (unlimited ones stay).
static func take(entry: Dictionary, amount: int = 1) -> void:
	if int(entry["amount"]) != UNLIMITED:
		entry["amount"] = maxi(0, int(entry["amount"]) - amount)


## A new stock: the market_stock section, or the fixed offers with default amounts. Non-item
## offers of `offers` (furniture, molds ...) are always added, without amount - unless the section
## has "random_offers": then the ones the player can buy right now (molds unlocked and not owned yet)
## are drawn with the wares for "offer_count" (e.g. Krummfinger: 1-8 things a day, molds among them),
## those in "always_offers" are kept every day once their flag is set.
static func roll(offers: Array[String], stock_id: String = "") -> Array:
	var entries: Array = []
	var config: Dictionary = ContentDB.economy("market_stock").get(stock_id, {}) if not stock_id.is_empty() else {}
	var random_offers: bool = bool(config.get("random_offers", false))
	if not config.is_empty():
		var always: Array = []
		for item_config: Dictionary in config.get("items", []):
			var entry: Dictionary = _roll_item(item_config)
			if not entry.is_empty():
				entries.append(entry)
				if bool(item_config.get("always", false)):
					always.append(entry)
		if config.has("equipment"):
			entries.append_array(_roll_equipment(config["equipment"]))
		if random_offers:
			# "always_offers" {spec: story flag}: from that flag on this offer shows every day
			# (e.g. Krummfinger's bronze pickaxe and lumber axe molds from "Die Goblinburg" on).
			var always_offers: Dictionary = config.get("always_offers", {})
			for spec in offers:
				if not is_item_spec(spec) and _can_buy_now(spec):
					var entry: Dictionary = {"spec": spec, "amount": UNLIMITED, "price": 0}
					entries.append(entry)
					if always_offers.has(spec) and GameState.story.has_flag(always_offers[spec]):
						always.append(entry)
		if config.has("offer_count"):
			entries = _pick_offers(entries, always, _roll_range(config["offer_count"]))
	for spec in offers:
		if is_item_spec(spec):
			if config.is_empty():
				var entry: Dictionary = _fixed_entry(spec)
				if not entry.is_empty():
					entries.append(entry)
		elif not random_offers:
			entries.append({"spec": spec, "amount": UNLIMITED, "price": 0})
	return entries


static func _has_random_offers(stock_id: String) -> bool:
	return not stock_id.is_empty() and bool(ContentDB.economy("market_stock").get(stock_id, {}).get("random_offers", false))


## Whether a non-item offer would show in the shop today: a mold/recipe that is unlocked
## (unlock_flag, rank) and not owned yet. Other offers always.
static func _can_buy_now(spec: String) -> bool:
	if not spec.begins_with("recipe:"):
		return true
	var offer: Dictionary = Economy.get_recipe_offer(spec.get_slice(":", 1))
	if offer.is_empty() or not ShopDialog._is_unlocked(offer):
		return false
	for recipe_id: String in offer.get("unlock", []):
		if ContentDB.has_recipe(recipe_id) and not GameState.is_recipe_unlocked(ContentDB.recipe(recipe_id)):
			return true
	return false


## "offer_count" [from, to]: only this many of today's wares (random), plus the "always" lines
## (e.g. coal at the ore traders); the order of the list stays.
static func _pick_offers(entries: Array, always: Array, count: int) -> Array:
	# Indices, not the entries: two lines can be equal dictionaries (same ware and amount).
	var others: Array[int] = []
	var kept: Dictionary = {}
	for i in entries.size():
		if always.any(func(entry: Dictionary) -> bool: return is_same(entry, entries[i])):
			kept[i] = true
		else:
			others.append(i)
	others.shuffle()
	for i in others.slice(0, count):
		kept[i] = true
	var result: Array = []
	for i in entries.size():
		if kept.has(i):
			result.append(entries[i])
	return result


static func is_item_spec(spec: String) -> bool:
	for prefix in NON_ITEM_PREFIXES:
		if spec.begins_with(prefix):
			return false
	return true


## A fixed offer with a default amount; a rarity range ("@R3-R4") is rolled once for the day.
## "*<amount>" = this many instead of the default (e.g. "silver_ring_band*2@R2-R3").
## "=<price>" at the end: fixed price of an R1 piece, +economy.json prices "rarity_bonus_per_step"
## per tier above (e.g. the traveler's "ruby*3@R3-R4=680": R3 1020, R4 1190).
static func _fixed_entry(spec: String) -> Dictionary:
	var price_text: String = spec.get_slice("=", 1) if "=" in spec else ""
	var stack: InventorySlot = ContentDB.make_stack(spec.get_slice("=", 0))
	if stack == null:
		return {}
	var defaults: Dictionary = ContentDB.economy("market_stock").get("default", {})
	var range_key: String = "equipment" if stack.item.is_equipment() else "stackable"
	var price: int = 0
	if not price_text.is_empty():
		price = roundi(int(price_text) * (1.0 + Economy.price("rarity_bonus_per_step", 0.25) * stack.rarity))
	var amount: int = stack.amount if "*" in spec else _roll_range(defaults.get(range_key, [5, 15]))
	return {"spec": spec_of(stack), "amount": amount, "price": price}


## One "items" line: only with its rank and flag, maybe not today (chance), a random pick.
static func _roll_item(item_config: Dictionary) -> Dictionary:
	if not _is_available(item_config) or randf() >= float(item_config.get("chance", 1.0)):
		return {}
	var item_id: String = item_config.get("item", "")
	var pick: Array = item_config.get("pick", [])
	if not pick.is_empty():
		item_id = str(pick.pick_random())
	if not ContentDB.has_item(item_id):
		push_error("MerchantStock: unknown item '%s' (economy.json market_stock)." % item_id)
		return {}
	var amount: int = _roll_range(item_config.get("amount", 1))
	if randf() < float(item_config.get("extra_chance", 0.0)):
		amount += 1
	var spec: String = item_id
	var price: int = int(item_config.get("price", 0))
	if randf() < float(item_config.get("rare_chance", 0.0)):
		spec += "@" + str(item_config.get("rare_rarity", "R2"))
		price = int(item_config.get("rare_price", price))
	return {"spec": spec, "amount": amount, "price": price}


## Weapons or armor of today: `count` finished pieces and `part_count` single parts, in the
## materials of the current rank (a metal in "material_flags" only once its story flag is set,
## copper if none is left); with rare_chance 1-2 of them are of rare_rarity (dearer).
## "price" = fixed price of a finished piece (0 = from its material value), e.g. Krummfinger's
## bronze gear for 700 gold.
static func _roll_equipment(config: Dictionary) -> Array:
	var material_flags: Dictionary = config.get("material_flags", {})
	var materials: Array = _materials_for_rank(config.get("materials", {})).filter(
			func(material: String) -> bool: return GameState.story.has_flag(material_flags.get(material, "")))
	if materials.is_empty():
		materials = ["copper"]
	var pieces: Array[String] = []
	var parts: Array[String] = []
	for type_id: String in config.get("types", []):
		for material: String in materials:
			var spec: String = equipment_spec(type_id, material, config.get("part_materials", {}))
			if spec.is_empty():
				continue
			pieces.append(spec)
			for part_id in spec.get_slice(":", 1).split("+"):
				if not parts.has(part_id):
					parts.append(part_id)
	pieces.shuffle()
	parts.shuffle()
	var entries: Array = []
	for spec in pieces.slice(0, _roll_range(config.get("count", [3, 5]))):
		entries.append({"spec": spec, "amount": 1, "price": int(config.get("price", 0))})
	for part_id in parts.slice(0, _roll_range(config.get("part_count", [2, 4]))):
		entries.append({"spec": part_id, "amount": _roll_range([1, 2]), "price": 0})
	if not entries.is_empty() and randf() < float(config.get("rare_chance", 0.0)):
		var rare: Array = entries.duplicate()
		rare.shuffle()
		for entry: Dictionary in rare.slice(0, _roll_range(config.get("rare_count", [1, 2]))):
			var stack: InventorySlot = ContentDB.make_stack(entry["spec"])
			var base: int = int(entry["price"]) if int(entry["price"]) > 0 else Economy.get_buy_price(stack)
			entry["price"] = roundi(base * float(config.get("rare_price_factor", 2.0)))
			entry["spec"] += "@" + str(config.get("rare_rarity", "R2"))
	return entries


## "sword:copper_blade+copper_handle" for a composed item (its "parts" in items.json) of one
## material. The main (first) part must exist in that material; the others fall back to
## part_materials ({"leather": {"iron": "wolf_leather", "*": "leather"}}). "" = not possible.
static func equipment_spec(type_id: String, material: String, part_materials: Dictionary) -> String:
	var recipe: RecipeData = null
	for candidate in ContentDB.get_all_recipes():
		if candidate.result and String(candidate.result.id) == type_id and not candidate.ingredients.is_empty():
			recipe = candidate
			break
	if recipe == null:
		return ""
	var part_ids: Array[String] = []
	for i in recipe.ingredients.size():
		var ingredient: Ingredient = recipe.ingredients[i]
		if ingredient.part_type == ItemData.PartType.NONE:
			continue  # used up while building (the rope of a bow), not a part of the item
		for n in ingredient.amount:
			var part_id: String = _find_part(ingredient, material, part_materials, i == 0)
			if part_id.is_empty():
				return ""
			part_ids.append(part_id)
	return "%s:%s" % [type_id, "+".join(part_ids)]


static func _find_part(ingredient: Ingredient, material: String, part_materials: Dictionary, main: bool) -> String:
	var kind: String = ItemData.PartType.keys()[ingredient.part_type].to_lower()
	var fallback: Dictionary = part_materials.get(kind, {})
	if fallback.has(material) and ContentDB.has_item(fallback[material]):
		return fallback[material]
	for item: ItemData in ContentDB.get_all_items():
		if ingredient.matches(item) and item.material_id == material:
			return String(item.id)
	if main:
		return ""
	return fallback.get("*", "") if ContentDB.has_item(fallback.get("*", "")) else ""


## Materials of the highest rank reached that has a list ({"F": ["copper"], "E": [...]}).
static func _materials_for_rank(by_rank: Dictionary) -> Array:
	var result: Array = []
	var reached: int = GameState.reputation.get_rank_index()
	var ranks: Array = Reputation.get_ranks()
	for i in mini(reached + 1, ranks.size()):
		var rank_id: String = ranks[i].get("id", "")
		if by_rank.has(rank_id):
			result = by_rank[rank_id]
	return result


## "rank" (reputation rank id) and "flag" (story flag) of a config line.
static func _is_available(config: Dictionary) -> bool:
	var flag: String = config.get("flag", "")
	if not flag.is_empty() and not GameState.story.has_flag(flag):
		return false
	var rank_id: String = config.get("rank", "")
	return rank_id.is_empty() or GameState.reputation.get_rank_index() >= rank_index(rank_id)


static func rank_index(rank_id: String) -> int:
	var ranks: Array = Reputation.get_ranks()
	for i in ranks.size():
		if ranks[i].get("id", "") == rank_id:
			return i
	return ranks.size()


## [from, to] (both included) or a plain number.
static func _roll_range(value: Variant) -> int:
	if value is Array and (value as Array).size() >= 2:
		return randi_range(int(value[0]), int(value[1]))
	return int(value)


## Text spec of a stack with its fixed rarity: "sword:copper_blade+copper_handle@R2", a jewel
## with its crystal and effect: "jewel_ring:silver_ring_band#ruby.lifesteal@R3".
static func spec_of(stack: InventorySlot) -> String:
	var spec: String = String(stack.item.id)
	if not stack.components.is_empty():
		spec += ":" + "+".join(stack.components.map(func(part: ItemData) -> String: return String(part.id)))
	if stack.jewel_crystal:
		spec += "#%s.%s" % [stack.jewel_crystal.id, stack.jewel_effect]
	return spec + "@" + Rarity.get_short_name(stack.rarity)


# --- Saving -------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return _stocks.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_stocks = data.duplicate(true)
