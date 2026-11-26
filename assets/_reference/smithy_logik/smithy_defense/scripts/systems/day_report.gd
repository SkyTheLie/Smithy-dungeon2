class_name DayReport
extends RefCounted
## Day summary shown when waking up (HUD wake-up screen, docs/BINDUNG.md Paket 2). Lives in
## GameState.day_report.
## "Gestern": what the player did during the day that just ended – gold earned (every add_gold),
## achievement counters since the morning (forged, built, orders, sold, monsters, dungeons) and the
## rarest piece of equipment he made (ItemReveal).
## "Heute": what the new day holds – rent soon, the traveler, the builder, ripe plants, customers
## (and a rush order), and the next long goal (house level, reputation rank).
## The counters are snapshots of Achievements, so no system needs to report to it.

## Achievement counter -> [text for 1, text for more].
const COUNTERS: Dictionary = {
	"forge": ["1 Teil geschmiedet", "%d Teile geschmiedet"],
	"craft": ["1 Stück gebaut", "%d Stück gebaut"],
	"order": ["1 Auftrag abgegeben", "%d Aufträge abgegeben"],
	"sold": ["1 Stück im Laden verkauft", "%d Stück im Laden verkauft"],
	"kill": ["1 Monster besiegt", "%d Monster besiegt"],
	"dungeon": ["1 Dungeon geschafft", "%d Dungeons geschafft"],
}
## Rent is announced this many days before it is due.
const RENT_WARN_DAYS: int = 3
const BUILDER_ID: String = "builder"

## Gold earned since the morning.
var gold_earned: int = 0
## Rarest piece made today: {"name", "rarity"} ({} = none).
var best: Dictionary = {}
## Counter values in the morning.
var _start_counts: Dictionary = {}


## Morning: starts counting a new day.
func start(achievements: Achievements) -> void:
	gold_earned = 0
	best = {}
	_start_counts.clear()
	for counter: String in COUNTERS:
		_start_counts[counter] = achievements.get_value(counter)


func add_gold(amount: int) -> void:
	if amount > 0:
		gold_earned += amount


## A finished piece (GameState.item_revealed): kept if it is the rarest of the day.
func note_item(slot: InventorySlot, _rarity_up: bool = false) -> void:
	if best.is_empty() or slot.rarity > int(best["rarity"]):
		best = {"name": slot.get_display_name(), "rarity": int(slot.rarity)}


## Lines for "Gestern" (empty if nothing happened).
func get_summary_lines(achievements: Achievements) -> Array[String]:
	var lines: Array[String] = []
	if gold_earned > 0:
		lines.append(Language.translate("%d Gold verdient") % gold_earned)
	for counter: String in COUNTERS:
		var done: int = achievements.get_value(counter) - int(_start_counts.get(counter, achievements.get_value(counter)))
		if done > 0:
			var texts: Array = COUNTERS[counter]
			lines.append(Language.translate(texts[0]) if done == 1 else Language.translate(texts[1]) % done)
	if not best.is_empty():
		lines.append(Language.translate("Bestes Stück: %s (%s)") % [best["name"], Rarity.get_display_name(int(best["rarity"]) as Rarity.Tier)])
	return lines


## Lines for "Heute" on `day` (call after the new day has started).
static func get_preview_lines(state: Node, day: int) -> Array[String]:
	var lines: Array[String] = []
	var story: Story = state.story
	var rent: Rent = state.rent
	if rent.active and day < rent.due_day and rent.due_day > rent.free_until_day:
		var days: int = rent.due_day - day
		if days <= RENT_WARN_DAYS:
			var line: String = Language.translate("Miete %s fällig (%d Gold)") % ["morgen" if days == 1 else Language.translate("in %d Tagen") % days, rent.get_amount()]
			if state.gold < rent.get_amount():
				line += Language.translate(", dir fehlen noch %d Gold") % (rent.get_amount() - state.gold)
			lines.append(line)
	var traveler: Dictionary = ContentDB.economy("traveler")
	var weekday: int = GameCalendar.get_weekday(day)
	var traveler_day: int = int(traveler.get("weekday", 6))
	var traveler_name: String = str(traveler.get("name", Language.translate("Der Reisende")))
	if weekday == traveler_day:
		lines.append(Language.translate("%s steht heute vor dem Dorftor") % traveler_name)
	elif (weekday + 1) % 7 == traveler_day:
		lines.append(Language.translate("Morgen kommt %s ans Dorftor") % traveler_name)
	var builder: NpcInfo = ContentDB.npc_info(BUILDER_ID)
	if builder.visits and story.has_flag(builder.visits.flag) and builder.visits.weekdays.has(weekday):
		var builder_name: String = builder.display_name if not builder.display_name.is_empty() else Language.translate("Der Baumeister")
		lines.append(Language.translate("%s ist heute am Markt") % builder_name)
	var garden_line: String = _garden_line(state.garden, day)
	if not garden_line.is_empty():
		lines.append(garden_line)
	if story.has_flag(GameState.CUSTOMERS_FLAG):
		var visitors: Array = state.customers.visitors
		if not visitors.is_empty():
			var line: String = Language.translate("Heute kommt 1 Kunde") if visitors.size() == 1 else Language.translate("Heute kommen %d Kunden") % visitors.size()
			if visitors.any(func(visitor: Customers.Visitor) -> bool: return visitor.order.rush):
				line += Language.translate(", einer mit Eilauftrag")
			lines.append(line)
	var goal: String = _goal_line(state)
	if not goal.is_empty():
		lines.append(goal)
	return lines


## Ripe plants, or how long the next one still needs.
static func _garden_line(garden: Garden, day: int) -> String:
	var ripe: int = 0
	var next: int = -1
	for bed: String in garden.beds:
		if garden.get_seed(bed) == null:
			continue
		var left: int = garden.get_days_left(bed, day)
		if left <= 0:
			ripe += 1
		elif next < 0 or left < next:
			next = left
	if ripe > 0:
		return Language.translate("1 Pflanze ist erntereif") if ripe == 1 else Language.translate("%d Pflanzen sind erntereif") % ripe
	if next > 0:
		return Language.translate("Nächste Ernte %s") % ("morgen" if next == 1 else Language.translate("in %d Tagen") % next)
	return ""


## The next big goal: the next house level (once the builder comes), otherwise the next rank.
static func _goal_line(state: Node) -> String:
	var visits: NpcInfo.Visits = ContentDB.npc_info(BUILDER_ID).visits
	var price: int = state.house.get_next_price()
	if visits and state.story.has_flag(visits.flag) and price > 0:
		if state.gold >= price:
			return Language.translate("Ziel: genug Gold für den nächsten Hausausbau (%d Gold)") % price
		return Language.translate("Ziel: noch %d Gold bis zum nächsten Hausausbau") % (price - state.gold)
	var reputation: Reputation = state.reputation
	var next: Dictionary = reputation.get_next_rank()
	if not next.is_empty() and not reputation.is_next_locked():
		return Language.translate("Ziel: noch %d Ruf bis Rang %s") % [maxi(1, int(next.get("from", 0)) - reputation.points), next.get("id", "")]
	return ""


func to_save_data() -> Dictionary:
	return {"gold": gold_earned, "best": best.duplicate(), "start": _start_counts.duplicate()}


func load_save_data(data: Dictionary) -> void:
	gold_earned = int(data.get("gold", 0))
	best = data.get("best", {})
	_start_counts = data.get("start", {})
