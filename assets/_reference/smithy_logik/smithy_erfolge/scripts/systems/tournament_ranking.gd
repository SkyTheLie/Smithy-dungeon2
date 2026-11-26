class_name TournamentRanking
extends RefCounted
## League tournaments and the ranks (data/content/leagues.json). Smiths register at the tournament
## master in a tournament hall (TournamentDeskMenu) and are brought into the arena of the city
## (SmithTournament); heroes are entered at the crier of an arena (HeroTournament). Every league
## tournament is a knockout bracket, always one against one (smiths: 8, heroes: 16 entrants).
## Two scores, "smith" and "hero", count rank points (RP): the place reached gives RP
## ("place_points"; a league below the own rank only "lower_league_factor" of them). The leagues
## are the ranks: from a league's "points" on the player has that rank and may enter its league
## and every one below. RP are never lost.
## Rewards per tournament: places 1-3 get "places" (gold, items); the winner also picks one prize
## of the league's "prize_pool" (tournament molds, forge themes, ingots, gold) at a tournament
## master or crier (pending until then, see get_pending / claim_prize). The first victory in a
## league gives its title, trophy (furniture) and gear; at the end of a season the highest league
## won in it pays its "season_reward" into the loot chest.
## Leagues are saved by id (never by their place in the list).

signal changed

const TYPES: Array[String] = ["smith", "hero"]
const TYPE_NAMES: Dictionary = {"smith": "Schmiede-Rang", "hero": "Helden-Rang"}
## Order of the leagues in saves from before the ranks (2026-11-13, Elo rating, leagues by index).
const OLD_LEAGUE_ORDER: Array[String] = ["copper", "iron", "bronze", "silver", "gold", "platinum", "palladium"]

## Rank points per type ("smith", "hero").
var points: Dictionary = {}
## League ids won at least once per type (titles, trophies, first-win gear).
var won_leagues: Dictionary = {}
## Highest league id won in the running season per type, and that season's month index.
var season_best: Dictionary = {}
var season: int = -1
## Day of the last league tournament per venue key (one per day).
var played: Dictionary = {}
## Tournaments entered and won per type: {"smith": [entered, won], ...}.
var counts: Dictionary = {}
## Prizes the winner still has to pick: [{"type", "league" (id), "choices": [pool entries]}].
var pending: Array[Dictionary] = []


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


## Index of the league with this id (-1 = none).
static func league_index(id: String) -> int:
	var list: Array = leagues()
	for index in list.size():
		if str(list[index].get("id", "")) == id:
			return index
	return -1


static func league_id(index: int) -> String:
	return str(league(index).get("id", ""))


## The part of a league for one type ("smith" or "hero").
static func league_part(type: String, index: int) -> Dictionary:
	return league(index).get(type, {})


static func league_name(index: int) -> String:
	return str(league(index).get("name", "?"))


## Name of the rank of a league (leagues.json "rank", e.g. "Kupfer"; already translated by ContentDB).
static func league_short_name(index: int) -> String:
	return str(league(index).get("rank", league_name(index).get_slice("-", 0)))


## Rank points from which the player has the rank of this league.
static func league_points(index: int) -> int:
	return int(league(index).get("points", 0))


## RP for a place (1, 2, 3, 5, 9 ...; leagues.json "place_points", missing = 0).
static func place_points(place: int) -> int:
	return int((data().get("place_points", {}) as Dictionary).get(str(place), 0))


## Place of an entrant who lost in round `lost_round` (0 = first round) of a knockout bracket with
## `rounds` rounds; -1 = he won everything (place 1). E.g. 3 rounds: final 2, semifinal 3, first 5.
static func place_for(rounds: int, lost_round: int) -> int:
	if lost_round < 0:
		return 1
	return int(pow(2, maxi(0, rounds - 1 - lost_round))) + 1


## Key of leagues.json "venues" for a tournament type and venue ("" = Leonheim / Eisquell).
static func venue_key(type: String, venue: String) -> String:
	var venues: Dictionary = data().get("venues", {})
	for key: String in venues:
		if str(venues[key].get("type", "")) == type and str(venues[key].get("venue", "")) == venue:
			return key
	return ""


static func venue_info(key: String) -> Dictionary:
	return (data().get("venues", {}) as Dictionary).get(key, {})


static func open_hours() -> Array:
	return data().get("open_hours", [8, 18])


static func get_entry_fee(type: String, index: int) -> int:
	return int(league_part(type, index).get("entry_fee", 0))


## Prize of a place (1-3) in a league: {"gold", "items"} ({} = none).
static func get_place_prize(type: String, index: int, place: int) -> Dictionary:
	var places: Array = league_part(type, index).get("places", [])
	return places[place - 1] if place >= 1 and place <= places.size() else {}


# --- Rank -------------------------------------------------------------------------

func get_points(type: String) -> int:
	return int(points.get(type, 0))


## Index of the highest league whose "points" the player has reached (his rank).
func get_rank(type: String) -> int:
	var rank: int = 0
	for index in league_count():
		if get_points(type) >= league_points(index):
			rank = index
	return rank


## Name of the rank (e.g. "Kupfer").
func get_rank_name(type: String) -> String:
	return league_short_name(get_rank(type))


func is_league_open(type: String, index: int) -> bool:
	return index >= 0 and index <= get_rank(type) and index < league_count()


## RP for `place` in a league: the place's points, less in a league below the own rank.
func points_for(type: String, index: int, place: int) -> int:
	var gain: int = place_points(place)
	if index < get_rank(type):
		gain = floori(gain * float(data().get("lower_league_factor", 0.5)))
	return gain


## Adds rank points; a reached rank is announced. Returns the lines for the player.
func add_points(type: String, amount: int) -> String:
	if amount <= 0:
		return ""
	var rank: int = get_rank(type)
	points[type] = get_points(type) + amount
	var lines: Array[String] = []
	while rank + 1 < league_count() and get_points(type) >= league_points(rank + 1):
		rank += 1
		lines.append(Language.translate("Neuer %s: %s. Ab jetzt darfst du in der %s antreten.") % [
				Language.translate(TYPE_NAMES[type]), league_short_name(rank), league_name(rank)])
	changed.emit()
	return " ".join(lines)


# --- Entering ---------------------------------------------------------------------

## Why the player can't enter the league `index` at this venue now ("" = he can).
func get_blocker(type: String, venue: String, index: int) -> String:
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
	if int(played.get(key, -1)) == game_state.day_cycle.day:
		return Language.translate("Hier bist du heute schon angetreten. Morgen wieder.")
	if index < 0 or index >= league_count():
		return Language.translate("Diese Liga gibt es nicht.")
	if not is_league_open(type, index):
		return Language.translate("Für die %s brauchst du den Rang %s (%d RP, du hast %d).") % [league_name(index),
				league_short_name(index), league_points(index), get_points(type)]
	if game_state.gold < get_entry_fee(type, index):
		return Language.translate("Das Startgeld beträgt %d Gold.") % get_entry_fee(type, index)
	return ""


## The player enters the league `index` at this venue: pays the fee, the day counts as played.
func enter(type: String, venue: String, index: int) -> bool:
	if not get_blocker(type, venue, index).is_empty():
		return false
	var game_state: Node = _game_state()
	var fee: int = get_entry_fee(type, index)
	if fee > 0 and not game_state.spend_gold(fee):
		return false
	played[venue_key(type, venue)] = game_state.day_cycle.day
	_count(type, 0)
	changed.emit()
	return true


func _count(type: String, slot: int) -> void:
	var entry: Array = counts.get(type, [0, 0])
	entry[slot] = int(entry[slot]) + 1
	counts[type] = entry


func get_counts(type: String) -> Array:
	return counts.get(type, [0, 0])


## Lines for the tournament master / crier: rank, RP, next rank, hours ("" = no leagues here).
func describe(type: String, venue: String) -> String:
	if venue_key(type, venue).is_empty():
		return ""
	var rank: int = get_rank(type)
	var hours: Array = open_hours()
	var lines: Array[String] = [Language.translate("%s: %s (%d RP)") % [Language.translate(TYPE_NAMES[type]),
			league_short_name(rank), get_points(type)]]
	if rank + 1 < league_count():
		lines.append(Language.translate("Nächster Rang: %s ab %d RP") % [league_short_name(rank + 1), league_points(rank + 1)])
	lines.append(Language.translate("Anmeldung %d–%d Uhr, ein Turnier pro Tag und Ort.") % [int(hours[0]), int(hours[1])])
	return "\n".join(lines)


## One line about a league: name, entry fee, prizes of places 1-3.
func describe_league(type: String, index: int) -> String:
	var prizes: Array[String] = []
	for place in [1, 2, 3]:
		prizes.append(Language.translate("%d. %d Gold") % [place, int(get_place_prize(type, index, place).get("gold", 0))])
	return Language.translate("%s: Startgeld %d Gold · %s") % [league_name(index), get_entry_fee(type, index), " · ".join(prizes)]


# --- Result and prizes ------------------------------------------------------------

## A league tournament is over: the player reached `place`. Gives the RP, the prize of places 1-3,
## and for the winner the first-win rewards and a prize to pick (pending). Returns the lines.
func finish(type: String, index: int, place: int) -> String:
	var game_state: Node = _game_state()
	var lines: Array[String] = [Language.translate("Platz %d in der %s.") % [place, league_name(index)]]
	var gain: int = points_for(type, index, place)
	if gain > 0:
		var text: String = Language.translate("+%d RP (jetzt %d).") % [gain, get_points(type) + gain]
		if index < get_rank(type):
			text += " " + Language.translate("Unter deinem Rang zählt nur die Hälfte.")
		lines.append(text)
	var rank_text: String = add_points(type, gain)
	var prize: Dictionary = get_place_prize(type, index, place)
	var gold: int = int(prize.get("gold", 0))
	if gold > 0:
		game_state.add_gold(gold)
		lines.append(Language.translate("Du bekommst %d Gold.") % gold)
	var items: String = str(prize.get("items", ""))
	if not items.is_empty():
		game_state.give_items(items)
		lines.append(Language.translate("Dazu: %s.") % _item_names(items))
	if place == 1:
		lines.append(_record_win(type, index))
	if not rank_text.is_empty():
		lines.append(rank_text)
	changed.emit()
	return " ".join(lines.filter(func(line: String) -> bool: return not line.is_empty()))


## First victory in a league: title, trophy, gear. Every victory: season best, a prize to pick.
func _record_win(type: String, index: int) -> String:
	var game_state: Node = _game_state()
	var part: Dictionary = league_part(type, index)
	var id: String = league_id(index)
	var lines: Array[String] = []
	_count(type, 1)
	_update_season(game_state.day_cycle.day)
	if league_index(str(season_best.get(type, ""))) < index:
		season_best[type] = id
	var won: Array = won_leagues.get(type, [])
	if not won.has(id):
		won.append(id)
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
			lines.append(Language.translate("Dazu: %s.") % _item_names(gear))
	var choices: Array[String] = build_choices(type, index)
	if not choices.is_empty():
		pending.append({"type": type, "league": id, "choices": choices})
		lines.append(Language.translate("Deinen Siegerpreis wählst du beim Turnierleiter (Turnierhalle) oder beim Ausrufer."))
	return " ".join(lines)


## Prizes of the pool a winner may pick from (leagues.json "prize_choices" of them): tournament
## molds and themes he does not have yet come first, then the rest in random order.
func build_choices(type: String, index: int) -> Array[String]:
	var special: Array[String] = []
	var plain: Array[String] = []
	for entry: String in league_part(type, index).get("prize_pool", []):
		var kind: String = entry.get_slice(":", 0)
		if kind == "mold" or kind == "theme":
			if not is_prize_owned(entry):
				special.append(entry)
		elif not describe_prize(entry).is_empty():
			plain.append(entry)
	special.shuffle()
	plain.shuffle()
	var choices: Array[String] = special + plain
	return choices.slice(0, int(data().get("prize_choices", 3)))


## true if the player has this mold / theme already (gold and items never count as owned).
func is_prize_owned(entry: String) -> bool:
	var value: String = entry.get_slice(":", 1)
	match entry.get_slice(":", 0):
		"mold":
			return not ContentDB.has_recipe(value) or _game_state().is_recipe_unlocked(ContentDB.recipe(value))
		"theme":
			return _theme_styles(value).is_empty() or _game_state().house.owns_theme(value)
	return false


## Shown text of a pool entry ("" = unknown entry).
static func describe_prize(entry: String) -> String:
	var value: String = entry.get_slice(":", 1)
	match entry.get_slice(":", 0):
		"mold":
			if ContentDB.has_recipe(value):
				var part: ItemData = ContentDB.recipe(value).get_mold_part()
				return Language.translate("Gussform: %s") % (part.display_name if part else value)
		"theme":
			if not _theme_styles(value).is_empty():
				return Language.translate("Schmiede-Thema: %s") % _theme_name(value)
		"items":
			var names: String = _item_names(value)
			return names
		"gold":
			return Language.translate("%d Gold") % int(value)
	return ""


## Prizes still to pick (the winner of a league tournament picks at a tournament master or crier).
func get_pending() -> Array[Dictionary]:
	return pending


## Picks choice `choice` of pending prize `index`. Returns the line for the player ("" = nothing).
func claim_prize(index: int, choice: int) -> String:
	if index < 0 or index >= pending.size():
		return ""
	var choices: Array = pending[index].get("choices", [])
	if choice < 0 or choice >= choices.size():
		return ""
	var entry: String = str(choices[choice])
	pending.remove_at(index)
	var text: String = give_prize(entry)
	changed.emit()
	return text


## Gives one prize of a pool. Returns the line for the player.
func give_prize(entry: String) -> String:
	var game_state: Node = _game_state()
	var value: String = entry.get_slice(":", 1)
	match entry.get_slice(":", 0):
		"mold":
			if ContentDB.has_recipe(value):
				game_state.unlock_mold(ContentDB.recipe(value))
		"theme":
			game_state.house.grant_theme(value)
			return KeyBindings.fill(Language.translate("Neues Schmiede-Thema: %s. Zu Hause {key_build} drücken » Wände & Böden.")) % _theme_name(value)
		"items":
			game_state.give_items(value)
		"gold":
			game_state.add_gold(int(value))
	return Language.translate("Du nimmst: %s.") % describe_prize(entry)


static func _item_names(spec_list: String) -> String:
	var names: Array[String] = []
	for spec in spec_list.split(",", false):
		var stack: InventorySlot = ContentDB.make_stack(spec)
		if stack:
			names.append("%d× %s" % [stack.amount, stack.get_display_name()] if stack.amount > 1 else stack.get_display_name())
	return ", ".join(names)


## Title of the best league won (type "" = the better of both). "" = none yet.
func get_title(type: String = "") -> String:
	var best_type: String = type
	var best: int = -1
	for each: String in ([type] if not type.is_empty() else TYPES):
		for id: String in won_leagues.get(each, []):
			var index: int = league_index(id)
			if index > best and not str(league_part(each, index).get("title", "")).is_empty():
				best = index
				best_type = each
	return Language.translate(str(league_part(best_type, best).get("title", ""))) if best >= 0 else ""


## Every title won: [{"type", "league" (index), "title"}].
func get_titles() -> Array[Dictionary]:
	var titles: Array[Dictionary] = []
	for type: String in TYPES:
		var won: Array[int] = []
		for id: String in won_leagues.get(type, []):
			if league_index(id) >= 0:
				won.append(league_index(id))
		won.sort()
		for index: int in won:
			var title: String = str(league_part(type, index).get("title", ""))
			if not title.is_empty():
				titles.append({"type": type, "league": index, "title": Language.translate(title)})
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
		var index: int = league_index(str(season_best.get(type, "")))
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
	return {"points": points.duplicate(), "won_leagues": won_leagues.duplicate(true), "season_best": season_best.duplicate(),
			"season": season, "played": played.duplicate(), "counts": counts.duplicate(true), "pending": pending.duplicate(true)}


func load_save_data(saved: Dictionary) -> void:
	points.clear()
	won_leagues.clear()
	season_best.clear()
	played.clear()
	counts.clear()
	pending.clear()
	if saved.has("best_league") and not saved.has("points"):
		saved = _convert_old_save(saved)
	for type: String in saved.get("points", {}):
		points[type] = int(saved["points"][type])
	for type: String in saved.get("won_leagues", {}):
		var list: Array = []
		for id: Variant in saved["won_leagues"][type]:
			list.append(str(id))
		won_leagues[type] = list
	for type: String in saved.get("season_best", {}):
		season_best[type] = str(saved["season_best"][type])
	season = int(saved.get("season", -1))
	for key: String in saved.get("played", {}):
		played[key] = int(saved["played"][key])
	for type: String in saved.get("counts", {}):
		counts[type] = [int(saved["counts"][type][0]), int(saved["counts"][type][1])]
	for entry: Dictionary in saved.get("pending", []):
		var choices: Array[String] = []
		for choice: Variant in entry.get("choices", []):
			choices.append(str(choice))
		pending.append({"type": str(entry.get("type", "smith")), "league": str(entry.get("league", "")), "choices": choices})
	changed.emit()


## Saves from before the ranks (Elo "ratings", leagues by index of OLD_LEAGUE_ORDER): the best
## league reached gives the RP of its rank, won leagues and season bests become ids. The played
## days are dropped (their keys were per weekday plan).
static func _convert_old_save(saved: Dictionary) -> Dictionary:
	var converted: Dictionary = {"points": {}, "won_leagues": {}, "season_best": {}, "season": saved.get("season", -1),
			"counts": saved.get("counts", {})}
	for type: String in saved.get("best_league", {}):
		var id: String = _old_league_id(int(saved["best_league"][type]))
		converted["points"][type] = league_points(maxi(0, league_index(id)))
	for type: String in saved.get("won_leagues", {}):
		var ids: Array = []
		for old_index: Variant in saved["won_leagues"][type]:
			ids.append(_old_league_id(int(old_index)))
		converted["won_leagues"][type] = ids
	for type: String in saved.get("season_best", {}):
		if int(saved["season_best"][type]) >= 0:
			converted["season_best"][type] = _old_league_id(int(saved["season_best"][type]))
	return converted


static func _old_league_id(old_index: int) -> String:
	return OLD_LEAGUE_ORDER[clampi(old_index, 0, OLD_LEAGUE_ORDER.size() - 1)]


## Styles of a forge theme (house.json room_styles "set"), like House.get_theme_styles (see _furniture).
static func _theme_styles(theme: String) -> Array[String]:
	var ids: Array[String] = []
	var styles: Dictionary = ContentDB.house("room_styles")
	for id: String in styles:
		if str(styles[id].get("set", "")) == theme:
			ids.append(id)
	return ids


static func _theme_name(theme: String) -> String:
	for id: String in _theme_styles(theme):
		return str(ContentDB.house("room_styles")[id].get("theme_name", theme))
	return theme


## A piece of house.json "furniture" ({} = none). Not House.get_furniture: this class must compile
## without the GameState autoload (headless tests load HeroTournament before it exists).
static func _furniture(id: String) -> Dictionary:
	return ContentDB.house("furniture").get(id, {})


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
