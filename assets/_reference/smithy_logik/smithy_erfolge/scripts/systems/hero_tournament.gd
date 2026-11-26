class_name HeroTournament
extends RefCounted
## Kahn's hero tournament in the tide arena of Eisquell (data/content/arena.json). The player
## enters one of his heroes; 16 heroes in a knockout bracket, always one against one, 4 rounds.
## The player's hero stands in slot 0, Kahn's son (arena.json "champions") so that they meet in
## the semifinal; the other 14 are built by HeroBuilder, as strong as the player's hero (their level
## depends on the round in which they would meet him). The player's fights run as ArenaDuel in the
## battle window, all other fights of a round are decided by chance (the higher level wins more
## often; a champion wins until his "wins_until" round). Lost = out, entering again is free and
## builds a new bracket. Winning the final sets WON_FLAG (the story goes on) and counts
## "hero_tournament_wins". Nothing of a running tournament is saved: after loading it starts over.
## Other venues (e.g. the duel ring of Sylvaris) are in arena.json "venues": their fields replace
## those of Eisquell (own names, champions, round names, `won_flag`, `wins_flag_prefix`,
## `prize_gold` for every victory there).
## League tournaments (TournamentRanking, leagues.json): register_league() builds the same bracket
## with opponents of the chosen league (fixed levels, the league's metal), no champions; the place
## reached gives hero rank points and prizes (TournamentRanking.finish, no story flags).

signal changed
## A fight of the player's hero ended; `text` says what that means (next round, out, won).
signal fight_finished(victory: bool, text: String)

enum State { IDLE, READY, FIGHTING, WON, LOST }

const WON_FLAG: String = "hero_tournament_won"
const WINS_FLAG_PREFIX: String = "hero_tournament_win_"

var state: State = State.IDLE
## 0 = first round ... last = final.
var round_index: int = 0
## All 16: {"hero": Hero, "player": bool, "champion": Dictionary (empty for random ones)}.
var entrants: Array[Dictionary] = []
## rounds[r] = entrant indexes still in at the start of round r, in bracket order (pairs 0-1, 2-3 ...).
## One more list after the final: the winner.
var rounds: Array = []
var duel: ArenaDuel
var player_hero: Hero
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
		merged.merge({"opponents": opponents, "champions": [], "prize_gold": 0, "won_flag": "", "wins_flag_prefix": ""}, true)
	return merged


static func is_league() -> bool:
	return league >= 0


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
	rounds = [range(size)]
	round_index = 0
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
	duel = null
	player_hero = null
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


## Pairs of round `index`: [[entrant index, entrant index], ...].
func get_pairs(index: int) -> Array:
	var pairs: Array = []
	if index < 0 or index >= rounds.size():
		return pairs
	var list: Array = rounds[index]
	for i in range(0, list.size() - 1, 2):
		pairs.append([list[i], list[i + 1]])
	return pairs


## Who the player's hero fights in the current round ({} = none).
func get_opponent() -> Dictionary:
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
	if not victory:
		state = State.LOST
		text = Language.translate("%s verliert gegen %s und scheidet aus. Melde dich beim Ausrufer neu an, wenn du es noch einmal versuchen willst.") \
				% [player_hero.display_name, opponent_name]
		if is_league():
			rating_text = " " + _game_state().ranking.finish("hero", league, TournamentRanking.place_for(round_count(), round_index))
	else:
		_finish_round()
		if round_index >= round_count() - 1:
			state = State.WON
			if is_league():
				text = Language.translate("%s besiegt %s und gewinnt das Turnier der %s.") % [player_hero.display_name, opponent_name,
						TournamentRanking.league_name(league)]
				var reward: String = _game_state().ranking.finish("hero", league, 1)
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
		else:
			round_index += 1
			state = State.READY
			text = Language.translate("%s besiegt %s. Als Nächstes: %s gegen %s.") % [player_hero.display_name, opponent_name,
					round_name(round_index), (get_opponent().get("hero") as Hero).display_name]
	duel = null
	changed.emit()
	fight_finished.emit(victory, text + rating_text)


## The player won his fight: every other fight of this round is decided, the next list built.
func _finish_round() -> void:
	var next: Array = []
	for pair: Array in get_pairs(round_index):
		if pair.has(0):
			next.append(0)
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
	return HeroBuilder.make(str(builds.pick_random()), entrant_name, level, metal_for_level(level),
			randi_range(int(rarity_range[0]), int(rarity_range[1])), str(races.pick_random()), seed_text)


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
