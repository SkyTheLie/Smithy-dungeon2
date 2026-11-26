class_name TournamentRanking
extends RefCounted
## League tournaments and the ranking (data/content/leagues.json). Besides the great tournament of
## each venue there is a league tournament every day: smith against smith (SmithTournament) or hero
## against hero (HeroTournament). Two ratings, "smith" and "hero" (one for all heroes), work like
## Elo: every round won against a stronger opponent brings much, every round lost costs points.
## Reaching a league's "rating" opens it for good: the rating never falls below the limit of the
## best league reached (the floor). Which league a venue holds rotates: one league per weekday,
## shifted every season (calendar month = season). Rewards: prize gold per tournament won; the first
## victory in a league gives its title, a trophy (furniture) and exclusive gear; at the end of a
## season the highest league won in it pays its "season_reward" into the loot chest.

signal changed

const TYPES: Array[String] = ["smith", "hero"]
const TYPE_NAMES: Dictionary = {"smith": "Schmiede-Wertung", "hero": "Helden-Wertung"}

## Rating per type ("smith", "hero").
var ratings: Dictionary = {}
## Index of the best league reached per type (opens it and is the floor of the rating).
var best_league: Dictionary = {}
## League indexes won at least once per type (titles, trophies, first-win gear).
var won_leagues: Dictionary = {}
## Highest league won in the running season per type (-1 = none), and that season's month index.
var season_best: Dictionary = {}
var season: int = -1
## Day of the last league tournament per venue key (one per day).
var played: Dictionary = {}
## Tournaments entered and won per type: {"smith": [entered, won], ...}.
var counts: Dictionary = {}


# --- Data -------------------------------------------------------------------------

static func data() -> Dictionary:
	return ContentDB.leagues()


static func leagues() -> Array:
	return data().get("leagues", [])


static func league_count() -> int:
	return leagues().size()


static func league(index: int) -> Dictionary:
	var list: Array = leagues()
	return list[index] if index >= 0 and index < list.size() else {}


## The part of a league for one type ("smith" or "hero").
static func league_part(type: String, index: int) -> Dictionary:
	return league(index).get(type, {})


static func league_name(index: int) -> String:
	return str(league(index).get("name", "?"))


## Rating a league starts at.
static func league_limit(index: int) -> int:
	return int(league(index).get("rating", 0))


static func start_rating() -> int:
	return int((data().get("rating", {}) as Dictionary).get("start", 1000))


## Rating of the opponent in round `round_index` of a league.
static func opponent_rating(index: int, round_index: int) -> int:
	var rules: Dictionary = data().get("rating", {})
	return league_limit(index) + int(rules.get("opponent_over_league", 40)) + int(rules.get("round_step", 30)) * round_index


## Expected share of points against `opponent` (Elo).
static func expected(rating: int, opponent: int) -> float:
	return 1.0 / (1.0 + pow(10.0, (opponent - rating) / 400.0))


## Key of leagues.json "venues" for a tournament type and venue ("" = Leonheim / Eisquell).
static func venue_key(type: String, venue: String) -> String:
	var venues: Dictionary = data().get("venues", {})
	for key: String in venues:
		if str(venues[key].get("type", "")) == type and str(venues[key].get("venue", "")) == venue:
			return key
	return ""


static func venue_info(key: String) -> Dictionary:
	return (data().get("venues", {}) as Dictionary).get(key, {})


## League held at a venue on `day`: every weekday another one, shifted each season.
static func league_on_day(key: String, day: int) -> int:
	var count: int = league_count()
	if count == 0 or key.is_empty():
		return -1
	var shift: int = int(data().get("season_shift", 2)) * GameCalendar.get_month_index(day)
	return posmod(GameCalendar.get_weekday(day) + int(venue_info(key).get("offset", 0)) + shift, count)


## The coming 7 days at a venue: [{"day", "weekday", "league"}], starting today.
static func week_plan(key: String, day: int) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for offset in 7:
		plan.append({"day": day + offset, "weekday": GameCalendar.get_weekday_short(day + offset),
				"league": league_on_day(key, day + offset)})
	return plan


static func open_hours() -> Array:
	return data().get("open_hours", [8, 18])


# --- Rating -----------------------------------------------------------------------

func get_rating(type: String) -> int:
	return int(ratings.get(type, start_rating()))


func get_best_league(type: String) -> int:
	return int(best_league.get(type, 0))


## The rating never falls below the limit of the best league reached.
func get_floor(type: String) -> int:
	return league_limit(get_best_league(type))


func is_league_open(type: String, index: int) -> bool:
	return index >= 0 and index <= get_best_league(type)


## A round of a league tournament ended: the rating changes (Elo), not below the floor. A new
## league opens once the rating reaches its limit. Returns the change.
func apply_round(type: String, index: int, round_index: int, won: bool) -> int:
	var rating: int = get_rating(type)
	var k: float = float((data().get("rating", {}) as Dictionary).get("k", 32))
	var change: int = roundi(k * ((1.0 if won else 0.0) - expected(rating, opponent_rating(index, round_index))))
	var new_rating: int = maxi(get_floor(type), rating + change)
	ratings[type] = new_rating
	var best: int = get_best_league(type)
	while best + 1 < league_count() and new_rating >= league_limit(best + 1):
		best += 1
		_game_state().show_message(Language.translate("%s erreicht: Ab jetzt darfst du in der %s antreten.") %
				[Language.translate(TYPE_NAMES[type]), league_name(best)])
	best_league[type] = best
	changed.emit()
	return new_rating - rating


# --- Entering ---------------------------------------------------------------------

## Why the player can't enter today's league tournament at this venue ("" = he can).
func get_blocker(type: String, venue: String) -> String:
	var key: String = venue_key(type, venue)
	if key.is_empty():
		return Language.translate("Hier gibt es keine Liga-Turniere.")
	var game_state: Node = _game_state()
	var flag: String = str(venue_info(key).get("open_flag", ""))
	if not flag.is_empty() and not game_state.story.has_flag(flag):
		return Language.translate("Liga-Turniere gibt es erst, wenn du das große Turnier gewonnen hast.")
	var hours: Array = open_hours()
	var hour: float = game_state.day_cycle.get_hour()
	if hour < float(hours[0]) or hour >= float(hours[1]):
		return Language.translate("Anmeldung zum Liga-Turnier von %d bis %d Uhr.") % [int(hours[0]), int(hours[1])]
	var day: int = game_state.day_cycle.day
	if int(played.get(key, -1)) == day:
		return Language.translate("Das Liga-Turnier von heute ist vorbei. Morgen wieder.")
	var index: int = league_on_day(key, day)
	if not is_league_open(type, index):
		return Language.translate("Heute: %s. Dafür brauchst du eine Wertung von %d (du hast %d).") % [league_name(index),
				league_limit(index), get_rating(type)]
	if game_state.gold < get_entry_fee(type, index):
		return Language.translate("Das Startgeld beträgt %d Gold.") % get_entry_fee(type, index)
	return ""


static func get_entry_fee(type: String, index: int) -> int:
	return int(league_part(type, index).get("entry_fee", 0))


static func get_prize(type: String, index: int) -> int:
	return int(league_part(type, index).get("prize_gold", 0))


## Today's league at the venue (index, -1 = none).
func get_today(type: String, venue: String) -> int:
	return league_on_day(venue_key(type, venue), _game_state().day_cycle.day)


## Short name of a league for the week plan (e.g. "Kupfer" of "Kupfer-Liga").
static func league_short_name(index: int) -> String:
	return league_name(index).get_slice("-", 0)


## Lines for the herald / crier: rating, today's league, the week, why one can't enter ("" = no
## league tournaments at this venue).
func describe(type: String, venue: String) -> String:
	var key: String = venue_key(type, venue)
	if key.is_empty():
		return ""
	var day: int = _game_state().day_cycle.day
	var best: int = get_best_league(type)
	var today: int = league_on_day(key, day)
	var hours: Array = open_hours()
	var lines: Array[String] = [
		Language.translate("%s: %d (%s, fällt nie unter %d)") % [Language.translate(TYPE_NAMES[type]), get_rating(type),
				league_name(best), get_floor(type)],
		Language.translate("Liga-Turnier heute: %s (Anmeldung %d–%d Uhr, Startgeld %d, Preis %d Gold)") % [league_name(today),
				int(hours[0]), int(hours[1]), get_entry_fee(type, today), get_prize(type, today)],
	]
	var week: Array[String] = []
	for entry: Dictionary in week_plan(key, day):
		week.append("%s %s" % [entry["weekday"], league_short_name(int(entry["league"]))])
	lines.append(Language.translate("Diese Woche: %s") % " · ".join(week))
	if best + 1 < league_count():
		lines.append(Language.translate("Nächste Liga: %s ab %d") % [league_name(best + 1), league_limit(best + 1)])
	var blocker: String = get_blocker(type, venue)
	if not blocker.is_empty():
		lines.append(blocker)
	return "\n".join(lines)


## The player enters today's league tournament: pays the fee, the day counts as played. Returns the
## league index, -1 if he can't.
func enter(type: String, venue: String) -> int:
	if not get_blocker(type, venue).is_empty():
		return -1
	var game_state: Node = _game_state()
	var index: int = get_today(type, venue)
	var fee: int = get_entry_fee(type, index)
	if fee > 0 and not game_state.spend_gold(fee):
		return -1
	played[venue_key(type, venue)] = game_state.day_cycle.day
	_count(type, 0)
	changed.emit()
	return index


func _count(type: String, slot: int) -> void:
	var entry: Array = counts.get(type, [0, 0])
	entry[slot] = int(entry[slot]) + 1
	counts[type] = entry


func get_counts(type: String) -> Array:
	return counts.get(type, [0, 0])


# --- Rewards ----------------------------------------------------------------------

## A league tournament was won: prize gold; the first victory in this league gives its title,
## trophy and gear. Returns the lines for the player.
func record_win(type: String, index: int) -> String:
	var game_state: Node = _game_state()
	var part: Dictionary = league_part(type, index)
	var lines: Array[String] = []
	_count(type, 1)
	var prize: int = get_prize(type, index)
	if prize > 0:
		game_state.add_gold(prize)
		lines.append(Language.translate("Du bekommst %d Gold.") % prize)
	_update_season(game_state.day_cycle.day)
	season_best[type] = maxi(int(season_best.get(type, -1)), index)
	var won: Array = won_leagues.get(type, [])
	if not won.has(index):
		won.append(index)
		won_leagues[type] = won
		var title: String = str(part.get("title", ""))
		if not title.is_empty():
			lines.append(Language.translate("Neuer Titel: %s.") % Language.translate(title))
		var trophy: String = str(part.get("trophy", ""))
		if not trophy.is_empty() and not _furniture(trophy).is_empty():
			game_state.house.add_owned(trophy)
			lines.append(KeyBindings.fill(Language.translate("%s liegt in deinem Lager (zu Hause {key_build} drücken).")) % _furniture(trophy).get("name", trophy))
		var gear: String = str(part.get("first_win", ""))
		if not gear.is_empty():
			game_state.give_items(gear)
			var names: Array[String] = []
			for spec in gear.split(",", false):
				var stack: InventorySlot = ContentDB.make_stack(spec)
				if stack:
					names.append(stack.get_display_name())
			lines.append(Language.translate("Dazu: %s.") % ", ".join(names))
	changed.emit()
	return " ".join(lines)


## Title of the best league won (type "" = the better of both). "" = none yet.
func get_title(type: String = "") -> String:
	var best_type: String = type
	var best: int = -1
	for each: String in ([type] if not type.is_empty() else TYPES):
		for index: int in won_leagues.get(each, []):
			if index > best:
				best = index
				best_type = each
	return Language.translate(str(league_part(best_type, best).get("title", ""))) if best >= 0 else ""


## Every title won: [{"type", "league", "title"}].
func get_titles() -> Array[Dictionary]:
	var titles: Array[Dictionary] = []
	for type: String in TYPES:
		var won: Array = won_leagues.get(type, []).duplicate()
		won.sort()
		for index: int in won:
			titles.append({"type": type, "league": index, "title": Language.translate(str(league_part(type, index).get("title", "")))})
	return titles


## A new morning: when the season (calendar month) changed, the highest league won in the old one
## pays its season reward into the loot chest. Returns the lines for the wake-up text.
func on_new_day(day: int) -> String:
	if season < 0:
		season = GameCalendar.get_month_index(day)
		return ""
	if GameCalendar.get_month_index(day) == season:
		return ""
	var news: String = ""
	var game_state: Node = _game_state()
	for type: String in TYPES:
		var index: int = int(season_best.get(type, -1))
		if index < 0:
			continue
		var reward: Dictionary = league_part(type, index).get("season_reward", {})
		var gold: int = int(reward.get("gold", 0))
		if gold > 0:
			game_state.put_gold_into_reward_chest(gold)
		for spec in str(reward.get("items", "")).split(",", false):
			var stack: InventorySlot = ContentDB.make_stack(spec)
			if stack:
				game_state.put_into_reward_chest(stack.item, stack.amount, stack.rarity)
		news += Language.translate("\nDie Jahreszeit ist vorbei. %s: bester Sieg in der %s, die Belohnung liegt in der Loot-Kiste.") % [
				Language.translate(TYPE_NAMES[type]), league_name(index)]
	season = GameCalendar.get_month_index(day)
	season_best.clear()
	changed.emit()
	return news


## Starts counting a new season if the calendar moved on without a morning (e.g. a test).
func _update_season(day: int) -> void:
	if season < 0:
		season = GameCalendar.get_month_index(day)


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"ratings": ratings.duplicate(), "best_league": best_league.duplicate(), "won_leagues": won_leagues.duplicate(true),
			"season_best": season_best.duplicate(), "season": season, "played": played.duplicate(), "counts": counts.duplicate(true)}


func load_save_data(saved: Dictionary) -> void:
	ratings.clear()
	best_league.clear()
	won_leagues.clear()
	season_best.clear()
	played.clear()
	counts.clear()
	for type: String in saved.get("ratings", {}):
		ratings[type] = int(saved["ratings"][type])
	for type: String in saved.get("best_league", {}):
		best_league[type] = int(saved["best_league"][type])
	for type: String in saved.get("won_leagues", {}):
		var list: Array = []
		for index: Variant in saved["won_leagues"][type]:
			list.append(int(index))
		won_leagues[type] = list
	for type: String in saved.get("season_best", {}):
		season_best[type] = int(saved["season_best"][type])
	season = int(saved.get("season", -1))
	for key: String in saved.get("played", {}):
		played[key] = int(saved["played"][key])
	for type: String in saved.get("counts", {}):
		counts[type] = [int(saved["counts"][type][0]), int(saved["counts"][type][1])]
	changed.emit()


## A piece of house.json "furniture" ({} = none). Not House.get_furniture: this class must compile
## without the GameState autoload (headless tests load HeroTournament before it exists).
static func _furniture(id: String) -> Dictionary:
	return ContentDB.house("furniture").get(id, {})


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
