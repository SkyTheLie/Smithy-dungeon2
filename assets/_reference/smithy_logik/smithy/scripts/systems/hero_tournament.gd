class_name HeroTournament
extends RefCounted
## Kahn's hero tournament in the tide arena of Eisquell (data/content/arena.json). The player
## enters one of his heroes; 16 heroes in a knockout bracket, always one against one, 4 rounds.
## The player's hero stands in slot 0, Kahn's son (arena.json "champions") so that they meet in
## the semifinal; the other 14 are built by HeroBuilder, as strong as the player's hero (their level
## depends on the round in which they would meet him). The player's fights run as ArenaDuel in the
## battle window, all other fights of a round are decided by chance (the higher level wins more
## often; a champion wins until his "wins_until" round). Lost = out, entering again is free and
## builds a new bracket. Whoever loses a semifinal is not out yet: the two semifinal losers fight
## for place 3 (2026-11-21, third_place; won = place 3, lost = place 4, the final is decided by
## chance afterwards). Winning the final sets WON_FLAG (the story goes on) and counts
## "hero_tournament_wins". Nothing of a running tournament is saved: after loading it starts over.
## Other venues (e.g. the duel ring of Sylvaris) are in arena.json "venues": their fields replace
## those of Eisquell (own names, champions, round names, `won_flag`, `wins_flag_prefix`,
## `prize_gold` for every victory there).
## League tournaments (TournamentRanking, leagues.json): register_league() builds the same bracket
## with opponents of the chosen league (fixed levels, the league's metal, from silver up sometimes
## rings and an amulet: HeroBuilder.add_jewelry), no champions; the place
## reached gives hero rank points and prizes (TournamentRanking.finish, no story flags).
## Venues with an arena hall (leagues.json "venues" "hall"/"arena", ArenaHall): before every fight
## the player is brought from the hall into the ring (request_arena_fight), where both heroes walk in
## (ArenaFightStage, which starts the fight), and back into the hall afterwards.

signal changed
## A fight of the player's hero ended; `text` says what that means (next round, out, won).
signal fight_finished(victory: bool, text: String)

enum State { IDLE, READY, FIGHTING, WON, LOST }

const WON_FLAG: String = "hero_tournament_won"
const WINS_FLAG_PREFIX: String = "hero_tournament_win_"
## Name of the great tournament in the result window.
const TEXT_STORY_TITLE: String = "Großes Heldenturnier"
const TEXT_THIRD_PLACE_ROUND: String = "Spiel um Platz 3"

var state: State = State.IDLE
## 0 = first round ... last = final.
var round_index: int = 0
## All 16: {"hero": Hero, "player": bool, "champion": Dictionary (empty for random ones)}.
var entrants: Array[Dictionary] = []
## rounds[r] = entrant indexes still in at the start of round r, in bracket order (pairs 0-1, 2-3 ...).
## One more list after the final: the winner.
var rounds: Array = []
## true after the player's hero lost the semifinal: his next fight is the one for place 3 against
## the other semifinal loser (third_place_opponent, entrant index).
var third_place: bool = false  # not saved on purpose (a running tournament is never saved)
var third_place_opponent: int = -1  # not saved on purpose
## Place of the player's hero once he is out or has won (0 = still running).
var final_place: int = 0  # not saved on purpose
var duel: ArenaDuel
var player_hero: Hero
## The hall asked for the next fight in the ring: the ring (ArenaFightStage) lets the heroes walk in
## and starts it. A running tournament is not saved at all.
var walk_in_pending: bool = false  # not saved on purpose
## The ring sends the player back into the hall: the arena keeper's window opens there by itself
## (ArenaHall, take_reopen_desk).
var reopen_desk: bool = false  # not saved on purpose
## Place and prize of the great tournament that just ended, for the result window in the ring
## ({"name", "place", "gold", "items"}, set when the player's hero wins the final or is out).
var story_result: Dictionary = {}  # not saved on purpose (shown right after the tournament)
## Where the tournament runs ("" = Eisquell, otherwise a key of arena.json "venues"). Set by the
## window of the venue (HeroTournamentMenu.venue).
static var venue: String = ""
## League of the running league tournament (index in leagues.json, -1 = the great tournament).
static var league: int = -1


## The settings of the current venue: those of Eisquell, with the fields of the venue on top (and
## the opponents of the league during a league tournament).
static func data() -> Dictionary:
	var base: Dictionary = ContentDB.arena()
	if venue.is_empty() and league < 0:
		return base
	var merged: Dictionary = base.duplicate()
	merged.merge((base.get("venues", {}) as Dictionary).get(venue, {}), true)
	if league >= 0:
		var part: Dictionary = TournamentRanking.league_part("hero", league)
		var opponents: Dictionary = (merged.get("opponents", {}) as Dictionary).duplicate()
		var levels: Array = part.get("levels", [5, 8])
		var step: int = int(TournamentRanking.data().get("level_step", 2))
		var per_round: Array = []
		for round_number in maxi(1, (merged.get("round_names", []) as Array).size()):
			per_round.append([int(levels[0]) + step * round_number, int(levels[1]) + step * round_number])
		opponents["levels"] = per_round
		opponents["metals"] = [[0, str(part.get("metal", "copper"))]]
		opponents["rarity"] = part.get("rarity", [0, 1])
		opponents["jewelry"] = float(part.get("jewelry", 0.0))
		merged.merge({"opponents": opponents, "champions": [], "prize_gold": 0, "won_flag": "", "wins_flag_prefix": ""}, true)
	return merged


static func is_league() -> bool:
	return league >= 0


## true where only league tournaments are held: the rings of the cities ("league_only") and
## Eisquell once Kahn's great tournament is won (2026-11-18).
static func is_league_only() -> bool:
	var base: Dictionary = ContentDB.arena()
	var info: Dictionary = base.duplicate()
	info.merge((base.get("venues", {}) as Dictionary).get(venue, {}), true)
	return bool(info.get("league_only", false)) or _game_state().story.has_flag(str(info.get("won_flag", WON_FLAG)))


static func round_count() -> int:
	return (data().get("round_names", []) as Array).size()


static func round_name(index: int) -> String:
	var names: Array = data().get("round_names", [])
	return str(names[index]) if index >= 0 and index < names.size() else Language.translate("Runde %d") % (index + 1)


func is_running() -> bool:
	return state == State.READY or state == State.FIGHTING


## Enters `hero` and builds a new bracket. false if the hero is busy (in a dungeon).
func register(hero: Hero) -> bool:
	if hero == null or _game_state().is_hero_busy(hero) or state == State.FIGHTING:
		return false
	# The great tournament only until it is won, never at the league rings.
	if not is_league() and is_league_only():
		return false
	story_result = {}
	player_hero = hero
	entrants.clear()
	var size: int = int(data().get("participants", 16))
	entrants.resize(size)
	entrants[0] = {"hero": hero, "player": true, "champion": {}}
	for champion: Dictionary in data().get("champions", []):
		var slot: int = clampi(int(champion.get("slot", 1)), 1, size - 1)
		entrants[slot] = {"hero": _make_champion(champion, hero.level), "player": false, "champion": champion}
	var names: Array = (data().get("opponents", {}) as Dictionary).get("names", []).duplicate()
	names.shuffle()
	for slot in size:
		if entrants[slot].is_empty():
			var entrant_name: String = str(names.pop_back()) if not names.is_empty() else Language.translate("Kämpfer %d") % slot
			entrants[slot] = {"hero": _make_opponent(slot, entrant_name, hero.level), "player": false, "champion": {}}
	rounds = [bracket_order(size, randi())]
	round_index = 0
	third_place = false
	third_place_opponent = -1
	final_place = 0
	state = State.READY
	changed.emit()
	return true


## Gives up / clears the bracket (e.g. after a loss, before entering again). Not while a duel runs,
## except with `force` (loading a save: the duel of the old game is gone, it is not saved).
func reset(force: bool = false) -> void:
	if not force and duel and duel.state == Adventure.State.RUNNING:
		return
	state = State.IDLE
	entrants.clear()
	rounds.clear()
	round_index = 0
	third_place = false
	third_place_opponent = -1
	final_place = 0
	duel = null
	player_hero = null
	walk_in_pending = false
	league = -1
	changed.emit()


## Enters `hero` in the league `index` at the current venue (TournamentRanking.enter pays the
## fee). false if the hero is busy or the league is closed.
func register_league(hero: Hero, index: int) -> bool:
	if hero == null or _game_state().is_hero_busy(hero) or state == State.FIGHTING:
		return false
	if not _game_state().ranking.enter("hero", venue, index):
		return false
	league = index
	return register(hero)


## Scene of the arena hall of the current venue ("" = none, the crier in the ring handles it all).
static func hall_scene() -> String:
	return str(TournamentRanking.venue_info(TournamentRanking.venue_key("hero", venue)).get("hall", ""))


## Scene of the ring the hall of the current venue sends its fighters into ("" = none).
static func arena_scene() -> String:
	return str(TournamentRanking.venue_info(TournamentRanking.venue_key("hero", venue)).get("arena", ""))


## Spawn point in the hall when coming back from the ring (leagues.json "hall_spawn", standard
## TournamentHall.FROM_ARENA; Sylvaris: in front of the crier in the canopy, not at the smith league).
static func hall_spawn() -> StringName:
	var info: Dictionary = TournamentRanking.venue_info(TournamentRanking.venue_key("hero", venue))
	return StringName(str(info.get("hall_spawn", TournamentHall.FROM_ARENA)))


## The next fight should run in the ring of the venue: marks it for the ring (walk_in_pending).
## Returns the ring scene to travel to, "" if there is no fight to start or no ring.
func request_arena_fight() -> String:
	var arena: String = arena_scene()
	if state != State.READY or get_opponent().is_empty() or arena.is_empty():
		return ""
	walk_in_pending = true
	return arena


## The ring takes the marked fight (true once, then the mark is gone).
func take_walk_in() -> bool:
	var pending: bool = walk_in_pending and state == State.READY
	walk_in_pending = false
	return pending


## The hall takes the wish to open the arena keeper's window (true once).
func take_reopen_desk() -> bool:
	var reopen: bool = reopen_desk
	reopen_desk = false
	return reopen


## true once the tournament is over (won or out).
func is_over() -> bool:
	return state == State.WON or state == State.LOST


## Pairs of round `index`: [[entrant index, entrant index], ...].
func get_pairs(index: int) -> Array:
	var pairs: Array = []
	if index < 0 or index >= rounds.size():
		return pairs
	var list: Array = rounds[index]
	for i in range(0, list.size() - 1, 2):
		pairs.append([list[i], list[i + 1]])
	return pairs


## Name of the player's next (or current) fight: the round, or "Spiel um Platz 3".
func get_round_title() -> String:
	if third_place:
		return Language.translate(TEXT_THIRD_PLACE_ROUND)
	return round_name(mini(round_index, round_count() - 1))


## Who the player's hero fights in the current round ({} = none).
func get_opponent() -> Dictionary:
	if third_place:
		return entrants[third_place_opponent] if third_place_opponent >= 0 else {}
	for pair: Array in get_pairs(round_index):
		if pair[0] == 0:
			return entrants[pair[1]]
		if pair[1] == 0:
			return entrants[pair[0]]
	return {}


## Winner index of a finished pair (-1 = not fought yet).
func get_winner(index: int, pair: Array) -> int:
	if index + 1 >= rounds.size():
		return -1
	var next: Array = rounds[index + 1]
	for entrant: int in pair:
		if next.has(entrant):
			return entrant
	return -1


## Starts the player's fight of this round (the battle window opens). null if that's not possible.
func start_fight() -> ArenaDuel:
	if state != State.READY:
		return null
	var opponent: Dictionary = get_opponent()
	if opponent.is_empty():
		return null
	duel = _game_state().start_duel(player_hero, opponent["hero"])
	if duel == null:
		return null
	duel.finished.connect(_on_duel_finished)
	state = State.FIGHTING
	changed.emit()
	return duel


func _on_duel_finished(victory: bool) -> void:
	var opponent_name: String = (get_opponent().get("hero") as Hero).display_name
	var text: String
	var rating_text: String = ""
	if third_place:
		_finish_third_place(victory, opponent_name)
		return
	if not victory and round_count() >= 2 and round_index == round_count() - 2:
		# Lost the semifinal: the other semifinal is decided, its loser waits for the fight for place 3.
		_finish_round(false)
		third_place = true
		third_place_opponent = _other_semifinal_loser()
		state = State.READY
		text = Language.translate("%s verliert gegen %s. Im Spiel um Platz 3 wartet %s.") \
				% [player_hero.display_name, opponent_name, (get_opponent().get("hero") as Hero).display_name]
	elif not victory:
		_end(TournamentRanking.place_for(round_count(), round_index))
		text = Language.translate("%s verliert gegen %s und scheidet aus. Melde dich beim Ausrufer neu an, wenn du es noch einmal versuchen willst.") \
				% [player_hero.display_name, opponent_name]
		rating_text = _rate()
	else:
		_finish_round()
		if round_index >= round_count() - 1:
			state = State.WON
			final_place = 1
			if is_league():
				text = Language.translate("%s besiegt %s und gewinnt das Turnier der %s.") % [player_hero.display_name, opponent_name,
						TournamentRanking.league_name(league)]
				player_hero.note_league_win(TournamentRanking.league_id(league))
				var reward: String = _game_state().ranking.finish("hero", league, 1, venue)
				if not reward.is_empty():
					text += " " + reward
				duel = null
				changed.emit()
				fight_finished.emit(victory, text + rating_text)
				return
			var story: Story = _game_state().story
			var prefix: String = str(data().get("wins_flag_prefix", WINS_FLAG_PREFIX))
			var wins: int = 1
			while story.has_flag(prefix + str(wins)):
				wins += 1
			story.set_flag(prefix + str(wins))
			story.set_flag(str(data().get("won_flag", WON_FLAG)))
			text = Language.translate("%s besiegt %s und gewinnt das Turnier.") % [player_hero.display_name, opponent_name]
			var prize: int = int(data().get("prize_gold", 0))
			if prize > 0:
				_game_state().add_gold(prize)
				text += " " + Language.translate("Du bekommst %d Gold.") % prize
			story_result = {"name": Language.translate(TEXT_STORY_TITLE), "place": 1, "gold": maxi(0, prize), "items": [] as Array[String]}
		else:
			round_index += 1
			state = State.READY
			text = Language.translate("%s besiegt %s. Als Nächstes: %s gegen %s.") % [player_hero.display_name, opponent_name,
					round_name(round_index), (get_opponent().get("hero") as Hero).display_name]
	duel = null
	changed.emit()
	fight_finished.emit(victory, text + rating_text)


## The fight for place 3 is over: won = place 3, lost = place 4. The final is decided by chance
## afterwards (the bracket shows its winner).
func _finish_third_place(victory: bool, opponent_name: String) -> void:
	round_index = round_count() - 1
	_finish_round(false)
	_end(3 if victory else 4)
	var text: String
	if victory:
		text = Language.translate("%s besiegt %s und holt Platz 3.") % [player_hero.display_name, opponent_name]
	else:
		text = Language.translate("%s verliert gegen %s und wird Vierter.") % [player_hero.display_name, opponent_name]
	text += _rate()
	duel = null
	changed.emit()
	fight_finished.emit(victory, text)


## The tournament is over for the player's hero (out) with this place; the league rating comes
## with _rate.
func _end(place: int) -> void:
	state = State.LOST
	third_place = false
	final_place = place
	if not is_league():
		story_result = {"name": Language.translate(TEXT_STORY_TITLE), "place": place, "gold": 0, "items": [] as Array[String]}


## League: " " + rank points and prizes of final_place (TournamentRanking.finish), "" otherwise.
func _rate() -> String:
	if not is_league():
		return ""
	return " " + _game_state().ranking.finish("hero", league, final_place, venue)


## The other semifinal (the one without the player's hero) is over: its loser (entrant index).
func _other_semifinal_loser() -> int:
	var semifinal: int = round_count() - 2
	for pair: Array in get_pairs(semifinal):
		if not pair.has(0):
			var winner: int = get_winner(semifinal, pair)
			return pair[1] if winner == pair[0] else pair[0]
	return -1


## Every other fight of this round is decided and the next list built. The player's hero goes on
## if `player_won`; otherwise his opponent goes on (and in the final, where the player is not, the
## pair is decided like the others).
func _finish_round(player_won: bool = true) -> void:
	var next: Array = []
	for pair: Array in get_pairs(round_index):
		if pair.has(0):
			next.append(0 if player_won else (pair[1] if pair[0] == 0 else pair[0]))
		else:
			next.append(_decide(pair[0], pair[1]))
	rounds.append(next)


## A fight without the player: a champion wins until his round, otherwise the higher level wins
## more often.
func _decide(a: int, b: int) -> int:
	for side: Array in [[a, b], [b, a]]:
		var champion: Dictionary = entrants[side[0]]["champion"]
		if not champion.is_empty() and round_index <= int(champion.get("wins_until", 0)):
			return side[0]
	var level_a: int = (entrants[a]["hero"] as Hero).level
	var level_b: int = (entrants[b]["hero"] as Hero).level
	var chance_a: float = clampf(0.5 + 0.08 * (level_a - level_b), 0.15, 0.85)
	return a if randf() < chance_a else b


## First-round order of the bracket: place p holds entrant p XOR mask (mask = `roll` % size), so the
## player's hero (entrant 0) gets a random place instead of always the top one. XOR keeps who meets
## whom in which round (meeting_round), so champions still meet the player when planned. Sizes that
## are no power of two keep the plain order.
static func bracket_order(size: int, roll: int) -> Array:
	var mask: int = absi(roll) % size if size > 0 and (size & (size - 1)) == 0 else 0
	var order: Array = []
	for place in size:
		order.append(place ^ mask)
	return order


## Round in which the hero in `slot` would meet the player's hero (slot 0): 1 -> 0, 2-3 -> 1,
## 4-7 -> 2, 8-15 -> 3.
static func meeting_round(slot: int) -> int:
	var round_number: int = 0
	var size: int = 1
	while slot >= size * 2:
		size *= 2
		round_number += 1
	return round_number


func _make_opponent(slot: int, entrant_name: String, hero_level: int) -> Hero:
	var rules: Dictionary = data().get("opponents", {})
	var level: int
	if rules.has("levels"):
		# League: fixed levels per round in which they would meet the player's hero.
		var levels: Array = rules["levels"]
		var span: Array = levels[mini(meeting_round(slot), levels.size() - 1)]
		level = randi_range(int(span[0]), int(span[1]))
	else:
		var offsets: Array = rules.get("level_offset", [[0, 0]])
		var offset: Array = offsets[mini(meeting_round(slot), offsets.size() - 1)]
		level = maxi(int(rules.get("level_min", 1)), hero_level + randi_range(int(offset[0]), int(offset[1])))
	var rarity_range: Array = rules.get("rarity", [0, 0])
	var builds: Array = rules.get("builds", ["warrior"])
	var races: Array = rules.get("races", ["human"])
	var seed_text: String = "%s_%d_%d" % [entrant_name, slot, randi()]
	var metal: String = metal_for_level(level)
	var rarity: int = randi_range(int(rarity_range[0]), int(rarity_range[1]))
	var hero: Hero = HeroBuilder.make(str(builds.pick_random()), entrant_name, level, metal, rarity,
			str(races.pick_random()), seed_text)
	# Leagues from silver up (leagues.json "jewelry"): some opponents wear rings and an amulet.
	HeroBuilder.add_jewelry(hero, metal, rarity, float(rules.get("jewelry", 0.0)))
	return hero


func _make_champion(champion: Dictionary, hero_level: int) -> Hero:
	var level: int = maxi(int(champion.get("level_min", 1)), hero_level + int(champion.get("level_over_hero", 0)))
	var race: String = str(champion.get("race", "human"))
	var seed_text: String = str(champion.get("seed", "champion"))
	var look: Appearance = Appearance.from_seed(seed_text, race)
	var fields: Dictionary = champion.get("appearance", {})
	for field: String in fields:
		look.set(field, fields[field])
	return HeroBuilder.make(str(champion.get("build", "warrior")), str(champion.get("name", Language.translate("Champion"))), level,
			str(champion.get("metal", metal_for_level(level))), int(champion.get("rarity", 0)), race, seed_text,
			look, champion.get("attributes", {}))


## Metal of the gear for this level (arena.json "opponents" "metals": the last entry that fits).
static func metal_for_level(level: int) -> String:
	var metal: String = "copper"
	for entry: Array in (data().get("opponents", {}) as Dictionary).get("metals", []):
		if level >= int(entry[0]):
			metal = str(entry[1])
	return metal


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
