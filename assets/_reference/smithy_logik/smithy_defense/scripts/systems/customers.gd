class_name Customers
extends RefCounted
## Customers of the smithy. Lives in GameState.customers and is ticked there.
## Every morning 0-2 customers are rolled (more with a better reputation, see Reputation), but at
## least "min_per_day" (so no day is empty); with "rush_chance" the first one brings a rush order
## (deadline "rush_days", gold × "rush_pay").
## each arrives at a random time between 09:00 and 18:00 and waits in front of the smithy
## (village, CustomerSpawner) until 20:00. Talking to one shows his order (CustomerOrder): a
## weapon the player can already make (all molds / recipes unlocked) in a rarity (create_order:
## 30 % big, 40 % normal, 30 % small orders, rarity up to the best piece he built). Accepted
## orders are handed in at the order board until their deadline; an expired order costs reputation.
## All numbers are in economy.json "customers" and "reputation" (format: docs/CONTENT.md).
## Praise (economy.json "praise"): a customer who got a fine piece (min_rarity) comes back some
## days later in the morning, tells about it (wake-up text), brings reputation and sends one more
## customer that day (schedule_praise / take_praise).

## Waiting customers or accepted orders changed.
signal changed
## A customer has just arrived in front of the smithy.
signal customer_arrived(visitor: Visitor)
## The player took a customer's order (it is in the quest log now).
signal order_accepted(order: CustomerOrder)

## A customer of today: comes at `arrive_minute`, then waits until the leave hour.
class Visitor:
	var order: CustomerOrder
	## In-game minutes since midnight (see DayCycle.minutes).
	var arrive_minute: float = 0.0
	var waiting: bool = false


## The smith's reputation (set by GameState): customers per day, pay bonus, points for orders.
var reputation: Reputation = Reputation.new()
## More gold for orders from the player's skill "Goldene Zunge" (set by GameState, 0.05 = +5 %).
var skill_pay_bonus: Callable = func() -> float: return 0.0
## Karma of saves from before the reputation (GameState converts it once), 0 otherwise.
var legacy_karma: int = 0
## Checks whether a recipe is unlocked (set by GameState: GameState.is_recipe_unlocked). Passed in
## because this class is loaded while GameState itself is still being loaded.
var is_recipe_unlocked: Callable = func(_recipe: RecipeData) -> bool: return true
## Best rarity (tier) the player has built of an item in a metal (set by GameState:
## GameState.get_best_rarity), e.g. ("sword", "iron") -> 4 after an R5 iron sword.
var best_rarity: Callable = func(_item_id: String, _material_id: String) -> int: return 0
## Checks a story flag (set by GameState: story.has_flag): bought stations (bow table, enchanting
## table) and raw parts without a recipe (leather, "customers.raw_parts").
var has_flag: Callable = func(_flag: String) -> bool: return true
## Accepted orders that are not handed in yet.
var orders: Array[CustomerOrder] = []
## Today's customers that are on their way or waiting (not yet talked to).
var visitors: Array[Visitor] = []
## Customers who will come back to praise their piece: [{"day", "name", "item"}].
var praises: Array[Dictionary] = []
var _next_id: int = 1


func tick(minutes: float) -> void:
	var leave_minute: float = _customer_value("leave_hour", 20) * 60.0
	for visitor in visitors.duplicate():
		if minutes >= leave_minute:
			visitors.erase(visitor)
			changed.emit()
		elif not visitor.waiting and minutes >= visitor.arrive_minute:
			visitor.waiting = true
			changed.emit()
			customer_arrived.emit(visitor)


## Customers waiting in front of the smithy right now.
func get_waiting() -> Array[Visitor]:
	var list: Array[Visitor] = []
	for visitor in visitors:
		if visitor.waiting:
			list.append(visitor)
	return list


## New day: orders past their deadline expire (reputation penalty), today's customers are rolled.
## Returns the expired orders (for the wake-up text). `with_visitors` = false: nobody comes
## (e.g. before the player has a smithy). `knight_comes`: the knight of the city guard brings an
## order too (after Hagen's quests, see create_knight_order), unless one of his is still open.
func start_day(day: int, with_visitors: bool = true, knight_comes: bool = false) -> Array[CustomerOrder]:
	var expired: Array[CustomerOrder] = []
	for order in orders.duplicate():
		# Story orders stay open (they show up as overdue).
		if order.deadline_day < day and order.story_tag.is_empty():
			orders.erase(order)
			expired.append(order)
			reputation.add_gain("order_expired")
	visitors.clear()
	if not with_visitors:
		changed.emit()
		return expired
	var count_range: Array = reputation.get_customer_range()
	var count: int = randi_range(int(count_range[0]), int(count_range[count_range.size() - 1]))
	count = maxi(count, int(_customer_value("min_per_day", 0)))
	var rush: bool = randf() < _customer_value("rush_chance", 0.0)
	var from_minute: float = _customer_value("arrive_from_hour", 9) * 60.0
	var until_minute: float = _customer_value("arrive_until_hour", 18) * 60.0
	for i in count:
		var order: CustomerOrder = create_order(day, rush and i == 0)
		if order == null:
			break
		var visitor := Visitor.new()
		visitor.order = order
		visitor.arrive_minute = randf_range(from_minute, until_minute)
		visitors.append(visitor)
	if knight_comes and not has_knight_order():
		_add_knight_visit(day)
	visitors.sort_custom(func(a: Visitor, b: Visitor) -> bool: return a.arrive_minute < b.arrive_minute)
	changed.emit()
	return expired


func accept(visitor: Visitor) -> void:
	visitors.erase(visitor)
	orders.append(visitor.order)
	changed.emit()
	order_accepted.emit(visitor.order)


## An order the story gives the player directly (e.g. the first customer in chapter 5).
func add_story_order(order: CustomerOrder) -> void:
	order.id = _next_id
	_next_id += 1
	orders.append(order)
	changed.emit()
	order_accepted.emit(order)


## The customer leaves without an order (no reputation change).
func decline(visitor: Visitor) -> void:
	visitors.erase(visitor)
	changed.emit()


## Called by GameState.complete_order after the item was taken and paid.
func finish(order: CustomerOrder) -> void:
	orders.erase(order)
	reputation.add_gain("order_completed")
	changed.emit()


## A handed-in order: with a fine enough piece the customer comes back in some days.
func schedule_praise(order: CustomerOrder, piece: InventorySlot, today: int) -> void:
	var settings: Dictionary = ContentDB.economy("praise")
	if not order.story_tag.is_empty() or piece.rarity < int(settings.get("min_rarity", 2)):
		return
	var days: Array = settings.get("days", [2, 4])
	praises.append({"day": today + randi_range(int(days[0]), int(days[days.size() - 1])),
			"name": order.customer_name, "item": order.get_item_name()})


## Morning of `day`: the praises due now. Each gives reputation and one more customer today.
## Returns the lines for the wake-up text.
func take_praise(day: int) -> Array[String]:
	var settings: Dictionary = ContentDB.economy("praise")
	var texts: Array = settings.get("texts", [Language.translate("{name} lobt dein {item}.")])
	var lines: Array[String] = []
	for praise in praises.duplicate():
		if int(praise["day"]) > day:
			continue
		praises.erase(praise)
		var points: int = int(settings.get("reputation", 5))
		reputation.add(points)
		lines.append("%s (Ruf %+d)" % [str(texts.pick_random()).format({"name": praise["name"], "item": praise["item"]}), points])
		var order: CustomerOrder = create_order(day)
		if order:
			var visitor := Visitor.new()
			visitor.order = order
			visitor.arrive_minute = randf_range(_customer_value("arrive_from_hour", 9) * 60.0,
					_customer_value("arrive_until_hour", 18) * 60.0)
			visitors.append(visitor)
	if not lines.is_empty():
		visitors.sort_custom(func(a: Visitor, b: Visitor) -> bool: return a.arrive_minute < b.arrive_minute)
		changed.emit()
	return lines


## Extra pay from the reputation (0.1 = +10 %).
func get_pay_bonus() -> float:
	return reputation.get_pay_bonus() + float(skill_pay_bonus.call())


# --- Orders -----------------------------------------------------------------------

## A random order the player can make right now (null if he can't make any weapon yet).
## `rush` = rush order: shorter deadline, more gold (economy.json "customers").
## First the kind is rolled (economy.json "customers.order_kinds": big, normal, small), then the
## weapon and its parts. The rarity follows the best piece the player has built of that weapon and
## metal (best_rarity, e.g. an R5 iron sword): a bell over R1..best (R3 most often, R1 and R5
## least); big orders take the upper half of it, small ones always R1.
func create_order(day: int, rush: bool = false) -> CustomerOrder:
	var candidates: Array = _get_candidates()
	if candidates.is_empty():
		return null
	var kind: String = _roll_order_kind()
	var chosen: Array = _pick_candidate(candidates)
	var order := CustomerOrder.new()
	order.id = _next_id
	_next_id += 1
	order.kind = kind
	order.item = (chosen[0] as RecipeData).result
	order.parts = _pick_parts(chosen[1], kind)
	var base: Rarity.Tier = order.parts[0].base_rarity
	var best: int = maxi(int(best_rarity.call(String(order.item.id), order.parts[0].material_id)), base)
	order.rarity = mini(roll_bell_rarity(base, best, kind), Rarity.Tier.MYTHIC) as Rarity.Tier
	var steps: int = order.rarity - base
	order.gold = roundi(Economy.get_order_gold(order.parts, steps, get_pay_bonus(), _get_extra_value(chosen[0])) * _kind_value(kind, "pay", 1.0))
	order.gold = maxi(order.gold, 1)
	order.experience = Economy.get_order_experience(order.gold)
	var days: Array = _customer_value_array("order_days", [2, 4])
	order.deadline_day = day + randi_range(int(days[0]), int(days[days.size() - 1]))
	if rush:
		order.rush = true
		order.deadline_day = day + int(_customer_value("rush_days", 2))
		order.gold = roundi(order.gold * _customer_value("rush_pay", 1.5))
		order.experience = Economy.get_order_experience(order.gold)
	order.customer_name = _pick_name()
	order.appearance = Appearance.create_random()
	return order


## A rarity between `low` and `high` (tiers): "normal" = a bell over the whole range (R1..R5:
## weights 1, 2, 3, 2, 1), "big" = the same bell over its upper half, "small" = always `low`.
static func roll_bell_rarity(low: int, high: int, kind: String = "normal") -> int:
	if kind == "small" or high <= low:
		return low
	var from: int = low + ceili((high - low) / 2.0) if kind == "big" else low
	var count: int = high - from + 1
	var weights: Array = []
	for i in count:
		weights.append(mini(i + 1, count - i))
	return from + _roll_weighted(weights)


## "big", "normal" or "small" by their "chance" in economy.json "customers.order_kinds".
func _roll_order_kind() -> String:
	var kinds: Dictionary = ContentDB.economy("customers").get("order_kinds", {})
	if kinds.is_empty():
		return "normal"
	var weights: Array = kinds.keys().map(func(key: String) -> float: return float(kinds[key].get("chance", 0.0)))
	return kinds.keys()[_roll_weighted(weights)]


## A value of an order kind (economy.json "customers.order_kinds.<kind>").
static func _kind_value(kind: String, key: String, default: Variant) -> Variant:
	return ContentDB.economy("customers").get("order_kinds", {}).get(kind, {}).get(key, default)


## Title prefix of an order kind, e.g. "Großauftrag" ("" = none); the knight's kinds are in
## economy.json "knight_orders.kinds".
static func get_kind_title(kind: String, knight: bool = false) -> String:
	if knight:
		return str(ContentDB.economy("knight_orders").get("kinds", {}).get(kind, {}).get("title", Language.translate("Stadtwache")))
	return str(_kind_value(kind, "title", ""))


## [recipe, part options] of everything a customer can order: weapons, armor, shields, bows and
## staffs of the stations in economy.json "customers.order_stations" the player owns.
func _get_candidates() -> Array:
	var candidates: Array = []
	for station: String in _customer_value_array("order_stations", ["workbench"]):
		if not _owns_station(station):
			continue
		for recipe in ContentDB.get_station_recipes(StringName(station)):
			var options: Array = _get_part_options(recipe)
			if not options.is_empty():
				candidates.append([recipe, options])
	return candidates


## Every kind of piece is as likely as any other: one recipe per group of recipes (recipes.json
## "group", e.g. the nine iron staffs, one per crystal) and the staffs of all metals together, like
## the sword, whose one recipe takes every metal.
static func _pick_candidate(candidates: Array) -> Array:
	var groups: Dictionary = {}
	for candidate: Array in candidates:
		var recipe: RecipeData = candidate[0]
		var key: String = recipe.category if not recipe.group.is_empty() else String(recipe.result.id)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(candidate)
	return (groups[groups.keys().pick_random()] as Array).pick_random()


## A station from economy.json "stations" (bought, e.g. the bow table) only once its flag is set;
## the others (workbench) always.
func _owns_station(station: String) -> bool:
	var flag: String = str(ContentDB.economy("stations").get(station, {}).get("flag", ""))
	return flag.is_empty() or has_flag.call(flag)


## Worth of the plain materials of a recipe that are no parts (rope of a bow, crystal of a staff):
## the customer pays for them too.
static func _get_extra_value(recipe: RecipeData) -> float:
	return Economy.get_recipe_extra_value(recipe)


## For an unlocked recipe (weapon, armor, shield, bow, staff): per part ingredient the parts the
## player can make. Plain materials (rope, crystal) are fixed and not part of the order. Empty if
## the recipe is locked, has no part at all (wooden staff), or a part can't be made yet.
func _get_part_options(recipe: RecipeData) -> Array:
	var result: ItemData = recipe.result
	if not (result.is_weapon() or result.is_armor() or result.type == ItemData.ItemType.SHIELD):
		return []
	if recipe.ingredients.is_empty() or not is_recipe_unlocked.call(recipe):
		return []
	var options: Array = []
	for ingredient in recipe.ingredients:
		if ingredient.part_type == ItemData.PartType.NONE:
			continue
		var parts: Array[ItemData] = []
		for item: ItemData in ingredient.get_candidates():
			if ingredient.matches(item) and _can_make(item):
				parts.append(item)
		if parts.is_empty():
			return []
		options.append(parts)
	return options


## A part can be made if its recipe (anvil / workbench) and its mold (forge, cast parts) are unlocked.
## Raw parts without a recipe (leather from the tanning rack or the merchants) count from their
## flag in economy.json "customers.raw_parts" ("" = always).
func _can_make(part: ItemData) -> bool:
	var id: String = String(part.id)
	var raw_parts: Dictionary = ContentDB.economy("customers").get("raw_parts", {})
	if raw_parts.has(id):
		var flag: String = str(raw_parts[id])
		return flag.is_empty() or has_flag.call(flag)
	if not ContentDB.has_recipe(id) or not is_recipe_unlocked.call(ContentDB.recipe(id)):
		return false
	return not ContentDB.has_recipe("mold_" + id) or is_recipe_unlocked.call(ContentDB.recipe("mold_" + id))


## One part per slot. Often all parts are of the same material (if possible). Big orders want the
## best metal the player can make, small ones the cheapest (all parts of it, if possible).
func _pick_parts(options: Array, kind: String = "normal") -> Array[ItemData]:
	var parts: Array[ItemData] = []
	var firsts: Array = options[0]
	if kind != "normal":
		var tiers: Array = firsts.map(func(part: ItemData) -> int: return part.material_tier)
		var wanted: int = tiers.max() if kind == "big" else tiers.min()
		firsts = firsts.filter(func(part: ItemData) -> bool: return part.material_tier == wanted)
	var first: ItemData = firsts.pick_random()
	parts.append(first)
	var same_material: bool = kind != "normal" or randf() < _customer_value("same_material_chance", 0.7)
	for i in range(1, options.size()):
		var choices: Array = options[i]
		var matching: Array = choices.filter(func(part: ItemData) -> bool: return part.material_name == first.material_name)
		parts.append(matching.pick_random() if same_material and not matching.is_empty() else choices.pick_random())
	return parts


## Index into `weights`, picked by chance (the weights don't need to add up to 1).
static func _roll_weighted(weights: Array) -> int:
	var total: float = 0.0
	for weight in weights:
		total += float(weight)
	var roll: float = randf() * total
	for i in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			return i
	return 0


## A name that no other customer of today or open order has (if possible).
func _pick_name() -> String:
	var names: Array = _customer_value_array("names", [Language.translate("Kunde")])
	var used: Array[String] = []
	for order in orders:
		used.append(order.customer_name)
	for visitor in visitors:
		used.append(visitor.order.customer_name)
	var free: Array = names.filter(func(name: String) -> bool: return not used.has(name))
	return free.pick_random() if not free.is_empty() else names.pick_random()


func _customer_value(key: String, default: float) -> float:
	return float(ContentDB.economy("customers").get(key, default))


func _customer_value_array(key: String, default: Array) -> Array:
	var value: Variant = ContentDB.economy("customers").get(key, default)
	return value if value is Array and not (value as Array).is_empty() else default


# --- Knight of the city guard -----------------------------------------------------

## Whether an order of the knight is still open (he only brings a new one after that).
func has_knight_order() -> bool:
	return orders.any(func(order: CustomerOrder) -> bool: return order.knight) \
			or visitors.any(func(visitor: Visitor) -> bool: return visitor.order.knight)


func _add_knight_visit(day: int) -> void:
	var order: CustomerOrder = create_knight_order(day)
	if order == null:
		return
	var visitor := Visitor.new()
	visitor.order = order
	visitor.arrive_minute = _knight_value("arrive_hour", 10) * 60.0
	visitors.append(visitor)


## An order of the knight (economy.json "knight_orders"): kind "easy" (30 %, little gold), "good"
## (40 %) or "hard" (30 %, R4-R5 and much gold) with its rarity range [from, to] (bell, see
## roll_bell_rarity), in the best metal the player can make. Good and hard orders may want an
## extra (a random attribute like on R4+ pieces, an enchantment) for bonus_gold more. null if the
## player can't make any weapon.
func create_knight_order(day: int) -> CustomerOrder:
	var settings: Dictionary = ContentDB.economy("knight_orders")
	var kinds: Dictionary = settings.get("kinds", {})
	var candidates: Array = _get_candidates()
	if candidates.is_empty() or kinds.is_empty():
		return null
	var kind: String = kinds.keys()[_roll_weighted(kinds.keys().map(func(key: String) -> float:
			return float(kinds[key].get("chance", 0.0))))]
	var data: Dictionary = kinds[kind]
	var chosen: Array = _pick_candidate(candidates)
	var order := CustomerOrder.new()
	order.id = _next_id
	_next_id += 1
	order.knight = true
	order.kind = kind
	order.item = (chosen[0] as RecipeData).result
	order.parts = _pick_parts(chosen[1], "big")
	var tiers: Array = data.get("rarity", ["R2", "R3"])
	order.rarity = clampi(roll_bell_rarity(_tier(tiers[0]), _tier(tiers[tiers.size() - 1])), 0, Rarity.Tier.MYTHIC) as Rarity.Tier
	var steps: int = maxi(0, order.rarity - order.parts[0].base_rarity)
	order.gold = maxi(1, roundi(Economy.get_order_gold(order.parts, steps, get_pay_bonus(), _get_extra_value(chosen[0])) * float(data.get("pay", 1.0))))
	if randf() < float(data.get("extra_chance", 0.0)):
		_add_knight_extras(order, float(data.get("enchant_chance", 0.0)))
	if order.has_extras():
		order.bonus_gold = roundi(order.gold * float(data.get("extra_bonus", 1.0)))
	order.experience = Economy.get_order_experience(order.gold)
	var days: Array = settings.get("order_days", [4, 6])
	order.deadline_day = day + randi_range(int(days[0]), int(days[days.size() - 1]))
	order.customer_name = str(settings.get("name", Language.translate("Ritter")))
	order.appearance = Appearance.from_seed(str(settings.get("appearance_seed", "knight")))
	order.resident = str(settings.get("resident", ""))
	return order


## A wanted attribute (only from R4 on, where pieces get random attributes: its first value) and,
## with `enchant_chance` (or if there is no attribute), a wanted enchantment of a potion.
func _add_knight_extras(order: CustomerOrder, enchant_chance: float) -> void:
	var values: Array[int] = Rarity.get_attribute_values(order.rarity)
	if not values.is_empty():
		order.wanted_attribute = ItemAttribute.Type.values().pick_random()
		order.wanted_attribute_value = values[0]
	if order.wanted_attribute < 0 or randf() < enchant_chance:
		var enchants: Array[String] = []
		for potion in ContentDB.get_potions():
			# Only the ordinary potions, not the secret ones (other plants, combos).
			if potion.is_secret():
				continue
			var bonus: SocketBonus = potion.get_bonus_for(order.item)
			if bonus:
				enchants.append(String(bonus.id))
		if not enchants.is_empty():
			order.wanted_enchant = enchants.pick_random()


func _knight_value(key: String, default: float) -> float:
	return float(ContentDB.economy("knight_orders").get(key, default))


## "R4" -> 3.
static func _tier(value: Variant) -> int:
	return int(str(value).trim_prefix("R")) - 1


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	var visitor_data: Array = []
	for visitor in visitors:
		visitor_data.append({"order": visitor.order.to_save_data(), "arrive": visitor.arrive_minute, "waiting": visitor.waiting})
	return {
		"next_id": _next_id,
		"orders": orders.map(func(order: CustomerOrder) -> Dictionary: return order.to_save_data()),
		"visitors": visitor_data,
		"praises": praises.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	legacy_karma = int(data.get("karma", 0))
	_next_id = int(data.get("next_id", 1))
	orders.clear()
	for saved: Dictionary in data.get("orders", []):
		var order: CustomerOrder = CustomerOrder.from_save_data(saved)
		if order:
			orders.append(order)
	praises.clear()
	for praise: Dictionary in data.get("praises", []):
		praises.append(praise.duplicate())
	visitors.clear()
	for saved: Dictionary in data.get("visitors", []):
		var order: CustomerOrder = CustomerOrder.from_save_data(saved.get("order", {}))
		if order:
			var visitor := Visitor.new()
			visitor.order = order
			visitor.arrive_minute = float(saved.get("arrive", 0.0))
			visitor.waiting = bool(saved.get("waiting", false))
			visitors.append(visitor)
	changed.emit()
