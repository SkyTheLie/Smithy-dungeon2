class_name SearchOrders
extends RefCounted
## Search orders at the adventurers' guild (counter, page "Suchaufträge"): the player pays gold,
## picks an item, its rarity and how many; adventurers bring it after 1-2 days, it lies in the
## reward chest in the morning. What can be searched for, prices and days: economy.json
## "search_orders"; how many orders run at once and the best rarity: the guild level
## (GuildLevel, guild_heroes.json "guild_levels"). In GameState.search_orders, saved.

signal changed

## Running orders: {"item": id, "rarity": int, "amount": int, "due_day": int, "price": int}.
var orders: Array[Dictionary] = []


static func get_settings() -> Dictionary:
	return ContentDB.economy("search_orders")


## Items that can be searched for now: [{"item": ItemData, "rarity": bool (rarity can be chosen)}],
## only those whose "flag" is set.
static func get_searchable(story: Story) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in get_settings().get("items", []):
		var item_id: String = str(entry.get("item", ""))
		if ContentDB.has_item(item_id) and story.has_flag(str(entry.get("flag", ""))):
			result.append({"item": ContentDB.item(item_id), "rarity": bool(entry.get("rarity", true))})
	return result


## Gold for `amount` pieces: merchant price of one piece in this rarity × price_factor ×
## rarity_factor per tier above R1, plus the fee per order.
static func get_price(item: ItemData, rarity: int, amount: int) -> int:
	var settings: Dictionary = get_settings()
	var stack := InventorySlot.new()
	stack.item = item
	stack.amount = 1
	stack.rarity = rarity as Rarity.Tier
	var piece: float = Economy.get_buy_price(stack) * float(settings.get("price_factor", 1.5)) \
			* pow(float(settings.get("rarity_factor", 1.6)), rarity)
	return int(settings.get("fee", 20)) + ceili(piece * amount)


static func get_max_amount() -> int:
	return int(get_settings().get("max_amount", 10))


## Why no order can be placed right now ("" = it can): guild not expanded, all places taken,
## not enough gold.
func get_blocker(story: Story, gold: int, price: int) -> String:
	var slots: int = GuildLevel.get_search_order_slots(story)
	if slots <= 0:
		return Language.translate("Erst wenn Hedwig die Gilde ausgebaut hat.")
	if orders.size() >= slots:
		return Language.translate("Alle Suchtrupps sind unterwegs (%d/%d).") % [orders.size(), slots]
	if gold < price:
		return Language.translate("Du hast nicht genug Gold.")
	return ""


## Adds an order (the caller has paid). The adventurers need settings "days" [from, to] days.
func add(item: ItemData, rarity: int, amount: int, price: int, today: int) -> void:
	var days: Array = get_settings().get("days", [1, 2])
	orders.append({"item": String(item.id), "rarity": rarity, "amount": amount, "price": price,
			"due_day": today + randi_range(int(days[0]), int(days[days.size() - 1]))})
	changed.emit()


## Orders that are done on `day` (removed from the list), for the reward chest.
func take_due(day: int) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	for order in orders.duplicate():
		if int(order["due_day"]) <= day:
			due.append(order)
			orders.erase(order)
	if not due.is_empty():
		changed.emit()
	return due


## "3× Eisenbarren (Fein)" for an order.
static func describe(order: Dictionary) -> String:
	var item_id: String = str(order.get("item", ""))
	var item_name: String = ContentDB.item(item_id).display_name if ContentDB.has_item(item_id) else item_id
	return "%d× %s (%s)" % [int(order.get("amount", 1)), item_name, Rarity.get_display_name(int(order.get("rarity", 0)) as Rarity.Tier)]


func to_save_data() -> Array:
	return orders.duplicate(true)


func load_save_data(data: Array) -> void:
	orders.clear()
	for order: Dictionary in data:
		orders.append({"item": str(order.get("item", "")), "rarity": int(order.get("rarity", 0)),
				"amount": int(order.get("amount", 1)), "price": int(order.get("price", 0)),
				"due_day": int(order.get("due_day", 0))})
	changed.emit()
