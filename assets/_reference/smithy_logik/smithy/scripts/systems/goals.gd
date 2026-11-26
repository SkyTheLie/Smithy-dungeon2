class_name Goals
extends RefCounted
## Goals on three levels for the quest tracker (section "Ziele", QuestTracker), so the player never
## has to ask what to do next:
##   today:     the most urgent customer order, waiting customers, or customers still to come
##   this week: rent, the traveler and the builder Konrad (next visit days)
##   long term: next house level, next reputation rank, next metal
## Every list holds {"text": String, "done": bool}; an empty list = nothing to say on that level.
## Only reads the game (GameState is passed in as `state`), never changes it.

const BUILDER_ID: String = "builder"
## How many days ahead "this week" looks for rent, traveler and builder.
const WEEK_DAYS: int = 7


## [{"title": "Heute", "goals": [...]}, ...] without the empty levels.
static func get_levels(state: Node) -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for level: Array in [["Heute", get_today(state)], ["Diese Woche", get_week(state)], ["Langfristig", get_long_term(state)]]:
		if not (level[1] as Array).is_empty():
			levels.append({"title": Language.translate(level[0]), "goals": level[1]})
	return levels


static func get_today(state: Node) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	var today: int = state.day_cycle.day
	var customers: Customers = state.customers
	var orders: Array[CustomerOrder] = customers.orders.duplicate()
	orders.sort_custom(func(a: CustomerOrder, b: CustomerOrder) -> bool: return a.deadline_day < b.deadline_day)
	if not orders.is_empty():
		var order: CustomerOrder = orders[0]
		var have: bool = state.find_order_item(order) >= 0
		var text: String = Language.translate("%s abgeben") % order.get_item_name() if have \
				else Language.translate("%s schmieden") % order.get_item_name()
		goals.append(_goal("%s (%s)" % [text, CustomerOrder.get_days_left_text(order.days_left(today))], false))
	if not state.story.has_flag(state.CUSTOMERS_FLAG):
		return goals
	var waiting: int = customers.get_waiting().size()
	if waiting > 0:
		goals.append(_goal(Language.translate("1 Kunde wartet vor der Schmiede") if waiting == 1
				else Language.translate("%d Kunden warten vor der Schmiede") % waiting, false))
	elif customers.visitors.size() > 0:
		goals.append(_goal(Language.translate("Heute kommen noch Kunden"), false))
	return goals


static func get_week(state: Node) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	var today: int = state.day_cycle.day
	var rent: Rent = state.rent
	if rent.active and rent.due_day >= today and rent.due_day > rent.free_until_day and rent.due_day - today <= WEEK_DAYS:
		var days: int = rent.due_day - today
		var when: String = Language.translate("heute") if days == 0 else (Language.translate("morgen") if days == 1
				else GameCalendar.get_weekday_name(rent.due_day))
		var enough: bool = state.gold >= rent.get_amount()
		goals.append(_goal(Language.translate("Miete %s: %d Gold") % [when, rent.get_amount()], enough))
	var traveler: Dictionary = ContentDB.economy("traveler")
	var traveler_day: int = _next_weekday(today, [int(traveler.get("weekday", 6))])
	goals.append(_goal(Language.translate("%s: %s am Dorftor") % [_day_word(today, traveler_day),
			str(traveler.get("name", Language.translate("Der Reisende")))], false))
	var builder: NpcInfo = ContentDB.npc_info(BUILDER_ID)
	if builder.visits and state.story.has_flag(builder.visits.flag) and not builder.visits.weekdays.is_empty():
		var builder_day: int = _next_weekday(today, builder.visits.weekdays)
		var builder_name: String = builder.display_name if not builder.display_name.is_empty() else Language.translate("Der Baumeister")
		goals.append(_goal(Language.translate("%s: %s am Markt") % [_day_word(today, builder_day), builder_name], false))
	return goals


static func get_long_term(state: Node) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	var house: String = get_house_goal(state)
	if not house.is_empty():
		goals.append(_goal(house, state.house.get_next_price() > 0 and state.gold >= state.house.get_next_price()))
	var rank: String = get_rank_goal(state)
	if not rank.is_empty():
		goals.append(_goal(rank, false))
	var metal: String = get_metal_goal(state)
	if not metal.is_empty():
		goals.append(_goal(metal, false))
	return goals


## The next house level (once the builder comes): "Hausausbau: noch 340 Gold" / "... genug Gold".
static func get_house_goal(state: Node) -> String:
	var visits: NpcInfo.Visits = ContentDB.npc_info(BUILDER_ID).visits
	var price: int = state.house.get_next_price()
	if visits == null or not state.story.has_flag(visits.flag) or price <= 0:
		return ""
	if state.gold >= price:
		return Language.translate("Hausausbau: genug Gold (%d)") % price
	return Language.translate("Hausausbau: noch %d Gold") % (price - state.gold)


## The next reputation rank: "Ruf-Rang D: noch 120 Ruf" ("" at the top or while the story holds it).
static func get_rank_goal(state: Node) -> String:
	var reputation: Reputation = state.reputation
	var next: Dictionary = reputation.get_next_rank()
	if next.is_empty() or reputation.is_next_locked():
		return ""
	return Language.translate("Ruf-Rang %s: noch %d Ruf") % [next.get("id", ""), maxi(1, int(next.get("from", 0)) - reputation.points)]


## The next metal: the first cast metal the story has not reached ("Nächstes Metall: Silber")
## or one reached whose molds the player does not have yet ("Gussformen für Silber besorgen").
static func get_metal_goal(state: Node) -> String:
	for metal: String in ContentDB.get_cast_metals():
		if not state.is_metal_unlocked(metal):
			return Language.translate("Nächstes Metall: %s") % ContentDB.material_name(metal)
		var molds: Array[RecipeData] = ContentDB.get_mold_recipes(metal)
		if not molds.is_empty() and state.get_unknown_molds(metal).size() == molds.size():
			return Language.translate("Gussformen für %s besorgen") % ContentDB.material_name(metal)
	return ""


## First day from `today` on (today included) that falls on one of `weekdays` (0 = Monday).
static func _next_weekday(today: int, weekdays: Array) -> int:
	for offset in WEEK_DAYS:
		if weekdays.has(GameCalendar.get_weekday(today + offset)):
			return today + offset
	return today


## "Heute", "Morgen" or the weekday name.
static func _day_word(today: int, day: int) -> String:
	if day == today:
		return Language.translate("Heute")
	if day == today + 1:
		return Language.translate("Morgen")
	return GameCalendar.get_weekday_name(day)


static func _goal(text: String, done: bool) -> Dictionary:
	return {"text": text, "done": done}
