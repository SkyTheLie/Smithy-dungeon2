class_name SmithTournament
extends RefCounted
## The great smith tournament in Leonheim (arena at the end of the smith lane, settings:
## economy.json "smith_tournament"). Four rounds, each one smith against another: the judge names
## a task (e.g. "Eisenaxt": any weapon or armor piece of "pieces" in the metal of the round, see
## build_task), both forge it from the materials in the supply chest, and the better
## piece wins: score = rarity x 100 + quality of the piece, plus a bonus for speed, minus points for
## every recipe of the task the player did not know before. The opponent is simulated: his piece
## by SmithBot (the player's forging rules, his hit chances and skills from the round's "bot"
## profile), his time from the round's range; he works through a plan (opponent_plan: chest, smelter, forge,
## anvil, trough, workbench) that the arena shows (TournamentOpponent). Every tournament after the
## story one makes every opponent better (tournaments_played, economy.json "opponent_growth"): more
## quality, less time, and a smarter route (everything from the chest at once, then carving the
## shaft while the ore melts). Whoever loses a round is out.
## During the tournament the player only has what the tournament gives him: his inventory, the
## storage chest, smelter, water trough, forge fuel and recipes are put aside when it starts
## (`_snapshot`) and come back when it ends (no cheating). Saving is blocked meanwhile.
## The story tournament (part 3) is free and can be tried again until it is won; the victory gives
## "prize_gold" and the master gloves ("first_win_reward"). The result window shows place and prize
## (story_result). After the victory there are only league tournaments (2026-11-18: no monthly
## tournaments any more, is_league_only).
## Other venues are in "venues": their fields replace the ones of Leonheim; all of them are
## league grounds ("league_only").
## League tournaments (TournamentRanking, leagues.json): the tournament master of a tournament hall
## calls enter_league(index); the player is brought into the arena of the city and forges a
## knockout tournament of 8 smiths ("smith_rounds" rounds: quarterfinal, semifinal, final) in the
## metal of the league. The place reached gives rank points and prizes (TournamentRanking.finish);
## afterwards he goes back into the hall (league_hall). No story flag, no monthly limit.

## Something changed (round started, piece handed in, tournament over): windows update.
signal changed

enum State { IDLE, BETWEEN_ROUNDS, RUNNING, RESULT, OVER }

## Story flag while a tournament runs (doors of the arena stay shut, see Door.blocked_flag).
const RUNNING_FLAG: String = "tournament_running"
## Story flag while a league with "finishing" runs (leagues.json, from silver on): grindstone,
## polishing table and tanning rack of the arena can be used (Station.usable_flag), the supply
## chest gives fur instead of leather.
const FINISHING_FLAG: String = "tournament_finishing"
## Story flag after the first victory (part 3 goes on, from then on only leagues).
const WON_FLAG: String = "smith_tournament_won"
## Name of the story tournament in the result window (economy.json "title" can replace it).
const TEXT_STORY_TITLE: String = "Großes Schmiedeturnier"
## Task the herald's guess of the opponent's strength assumes (the real one is drawn at the start
## of the round): one forged part and a carved shaft, like an axe.
const TYPICAL_TASK: Dictionary = {"metal_parts": 1, "carved": 1, "leather": 0}

var state: State = State.IDLE
## Index of the current round (0-3).
var round_index: int = 0
## Task id of the current round: an id of economy.json "smith_tournament" "tasks", or
## "<piece>@<metal>" for a task built from "pieces" (e.g. "helmet@iron", see build_task).
var task_id: String = ""
## Seconds since the current round began.
var elapsed: float = 0.0
## Recipes of the current task the player did not know (each costs points).
var unknown_recipes: int = 0
## Planned time of the opponent in this round (seconds) and his score without the time bonus.
var opponent_time: float = 0.0
var opponent_quality: int = 0
## Result of the last round: {"won", "quality", "time_bonus", "penalty", "total",
## "opponent_quality", "opponent_bonus", "opponent_total", "piece"}.
var last_result: Dictionary = {}
## Round the player lost or gave up in (-1 = none yet / champion): his place in a league.
var lost_round: int = -1
## Lines about place, rank points and prizes of the last league tournament (TournamentRanking.finish).
var league_result: String = ""
## true = the whole tournament was won (after the last round).
var champion: bool = false
## Victories in the story tournament (0 or 1).
var wins: int = 0
## Place and prize of the story tournament that just ended, for the result window ({"name",
## "place", "gold", "items"}, set in finish).
var story_result: Dictionary = {}  # not saved on purpose (shown right after the tournament)
## League tournaments played (counted in finish):
## each one makes every opponent better (get_opponent_experience).
var tournaments_played: int = 0
## The opponent's work in the current round, step by step ({"stop", "text", "seconds", "walk"},
## see build_opponent_plan), stretched to opponent_time.
var opponent_plan: Array[Dictionary] = []  # not saved on purpose (a running tournament is never saved)
## Everything put aside at the start (GameState data, see _put_aside / _give_back).
var _snapshot: Dictionary = {}


## Where the tournament takes place ("" = Leonheim, otherwise a key of "venues"). The herald of
## each venue picks it before the tournament starts (select_venue); it stays while one runs.
static var venue: String = ""
## League of the running league tournament (index in leagues.json, -1 = the great tournament) and
## its rounds (opponents drawn when it started, see build_league_rounds).
static var league: int = -1
static var league_rounds: Array = []


## The settings of the current venue: those of Leonheim, with the fields of the venue on top (and
## the rounds of the league during a league tournament).
static func settings() -> Dictionary:
	var base: Dictionary = ContentDB.economy("smith_tournament")
	if venue.is_empty() and league < 0:
		return base
	var merged: Dictionary = base.duplicate()
	merged.merge((base.get("venues", {}) as Dictionary).get(venue, {}), true)
	if league >= 0:
		merged.merge({"rounds": league_rounds,
				"champion_text": Language.translate("Du hast das Turnier der %s gewonnen!") % TournamentRanking.league_name(league)}, true)
	return merged


static func is_league() -> bool:
	return league >= 0


## Rounds of a league tournament (leagues.json "smith_rounds", 3 = 8 smiths).
static func league_round_count() -> int:
	return maxi(1, int(TournamentRanking.data().get("smith_rounds", 3)))


## Knockout rounds in the league's metal ("smith_rounds", named by "smith_round_names"): the
## opponents are smiths drawn from leagues.json "smith_opponents" (the field of the tournament),
## each round a bit better and faster ("green_step" more green strikes, "time_step"). Every one
## forges with the league's bot profile ("smith.bot") plus "favorite" ranks of his own skill
## ("skill" of the smith, see SmithBot).
static func build_league_rounds(index: int) -> Array:
	var part: Dictionary = TournamentRanking.league_part("smith", index)
	var rules: Dictionary = TournamentRanking.data()
	var pool: Array = (rules.get("smith_opponents", []) as Array).duplicate()
	pool.shuffle()
	var bot: Dictionary = part.get("bot", {})
	var time: Array = part.get("time", [0.9, 1.2])
	var green_step: float = float(rules.get("green_step", 0.0))
	var time_step: float = float(rules.get("time_step", 0.03))
	var names: Array = rules.get("smith_round_names", [])
	var rounds: Array = []
	for round_number in league_round_count():
		var opponent: Dictionary = pool[round_number % pool.size()] if not pool.is_empty() else {}
		var favorite: String = str(opponent.get("skill", ""))
		var profile: Dictionary = SmithBot.with_green_step(bot, green_step * round_number)
		if not favorite.is_empty():
			profile = SmithBot.with_skills(profile, {favorite: int(bot.get("favorite", 0))})
		rounds.append({"opponent_name": str(opponent.get("name", Language.translate("Gegner"))),
				"name": str(names[round_number]) if round_number < names.size() else "",
				"opponent_look": opponent.get("look", {}), "metal": str(part.get("metal", "copper")),
				"leather": str(part.get("leather", "leather")), "ores": part.get("ores", {}),
				"bot": profile, "finishing": bool(part.get("finishing", false)),
				"opponent_time": [maxf(0.3, float(time[0]) - time_step * round_number), maxf(0.4, float(time[1]) - time_step * round_number)]})
	return rounds


## The herald of a venue opens his window: from now on the tournament is held there (only
## between tournaments).
func select_venue(venue_id: String) -> void:
	if state == State.IDLE:
		venue = venue_id


## Story flag set by the first victory at the current venue.
static func get_won_flag() -> String:
	return str(settings().get("won_flag", WON_FLAG))


static func get_rounds() -> Array:
	return settings().get("rounds", [])


## The task with this id: an own one from "tasks", or a built one ("<piece>@<metal>", round = the
## round whose metal it is, for its leather and ores).
static func get_task(id: String) -> Dictionary:
	var own: Dictionary = settings().get("tasks", {})
	if own.has(id):
		return own[id]
	if not "@" in id:
		return {}
	var metal: String = id.get_slice("@", 1)
	for round_data: Dictionary in get_rounds():
		if str(round_data.get("metal", "")) == metal:
			return build_task(id.get_slice("@", 0), round_data)
	return {}


## Task ids a round can pick from: its own "tasks", otherwise every piece of "pieces" that can be
## made from its metal ("<piece>@<metal>").
static func get_round_tasks(round_data: Dictionary) -> Array[String]:
	var tasks: Array[String] = []
	tasks.assign(round_data.get("tasks", []))
	if not tasks.is_empty() or not round_data.has("metal"):
		return tasks
	for piece_id: String in settings().get("pieces", []):
		if not build_task(piece_id, round_data).is_empty():
			tasks.append("%s@%s" % [piece_id, round_data["metal"]])
	return tasks


## A task for a piece of "pieces" (workbench item, e.g. "helmet") in the metal of a round: every
## part of its recipe in that metal (shafts from "shaft", leather from the round's "leather"), the
## mold, anvil and workbench recipes, and in the supply chest ore for the ingots + "spare_ingots"
## (round "ores": ore per ingot, bronze = copper + iron ore), coal (1 per 2 ores, alloys 1 more per
## 2 ingots), wood and leather. {} if a part does not exist in that metal.
static func build_task(piece_id: String, round_data: Dictionary) -> Dictionary:
	if not ContentDB.has_recipe(piece_id):
		return {}
	var metal: String = str(round_data.get("metal", ""))
	var finishing: bool = bool(round_data.get("finishing", false))
	var parts: Array[String] = []
	var recipes: Array[String] = []
	var ingots: int = 0
	var metal_parts: int = 0
	var carved: int = 0
	var leather: int = 0
	var chest: Dictionary = {}
	for ingredient: Ingredient in ContentDB.recipe(piece_id).ingredients:
		var part: ItemData = _task_part(ingredient, metal, round_data)
		if part == null:
			return {}
		for i in ingredient.amount:
			parts.append(String(part.id))
		if part.material_id == metal:
			for recipe_id: String in ["mold_" + String(part.id), String(part.id)]:
				if not recipes.has(recipe_id):
					recipes.append(recipe_id)
			ingots += _ingots_of(part) * ingredient.amount
			metal_parts += ingredient.amount
		elif part.part_type == ItemData.PartType.LEATHER:
			# Finishing rounds: the fur of that leather, tanned at the tanning rack.
			var fur: ItemData = fur_of(part) if finishing else null
			var supply: String = String(fur.id) if fur else String(part.id)
			chest[supply] = int(chest.get(supply, 0)) + ingredient.amount
			leather += ingredient.amount
		else:
			carved += ingredient.amount
			# A carved part (wooden shaft): its recipe and the wood for it, one spare.
			if not recipes.has(String(part.id)):
				recipes.append(String(part.id))
			var raw: String = str(ContentDB.material_info(part.material_id).get("raw", ""))
			if not raw.is_empty():
				chest[raw] = int(chest.get(raw, 0)) + ingredient.amount + 1
	recipes.append(piece_id)
	var needed_ingots: int = ingots
	ingots += int(settings().get("spare_ingots", 1))
	var ores: Dictionary = round_data.get("ores", {})
	var ore_total: int = 0
	var ore_chest: Dictionary = {}
	for ore_id: String in ores:
		ore_chest[ore_id] = ingots * int(ores[ore_id])
		ore_total += ore_chest[ore_id]
	var coal: int = ceili(ore_total / 2.0) + (ceili(ingots / 2.0) if ores.size() > 1 else 0)
	var chest_parts: Array[String] = []
	for item_id: String in ore_chest:
		chest_parts.append("%s*%d" % [item_id, ore_chest[item_id]])
	chest_parts.append("coal*%d" % coal)
	for item_id: String in chest:
		chest_parts.append("%s*%d" % [item_id, chest[item_id]])
	var piece: String = "%s:%s" % [piece_id, "+".join(parts)]
	var stack: InventorySlot = ContentDB.make_stack(piece)
	# Finishing: weapons on the grindstone, armor on the polishing table (Sharpening).
	var finish: String = ""
	if finishing and stack:
		finish = "sharpen" if stack.item.is_weapon() else ("polish" if stack.item.is_armor() else "")
	return {"name": stack.get_display_name() if stack else piece_id, "piece": piece, "recipes": recipes,
			"chest": ",".join(chest_parts), "ingots": needed_ingots, "metal_parts": metal_parts,
			"carved": carved, "leather": leather, "tan": leather if finishing else 0, "finish": finish}


## The fur that turns into `leather` at the tanning rack ("tan_to" in items.json), null = none.
static func fur_of(leather: ItemData) -> ItemData:
	for item: ItemData in ContentDB.get_all_items():
		if item.tan_result == leather:
			return item
	return null


## The part a task uses for one ingredient: leather of the round, the "shaft" for shafts, otherwise
## the part of that type in the metal (null = none).
static func _task_part(ingredient: Ingredient, metal: String, round_data: Dictionary) -> ItemData:
	var wanted_id: String = ""
	if ingredient.part_type == ItemData.PartType.LEATHER:
		wanted_id = str(round_data.get("leather", "leather"))
	elif ingredient.part_type == ItemData.PartType.SHAFT:
		wanted_id = str(settings().get("shaft", "wooden_shaft"))
	if not wanted_id.is_empty():
		return ContentDB.item(wanted_id) if ContentDB.has_item(wanted_id) else null
	if ingredient.part_type == ItemData.PartType.NONE:
		return null
	for item: ItemData in ContentDB.get_all_items():
		if item.part_type == ingredient.part_type and item.material_id == metal and ingredient.matches(item):
			return item
	return null


## Ingots one cast of this part needs (its mold recipe, e.g. 2 for a chest plate).
static func _ingots_of(part: ItemData) -> int:
	var mold_id: String = "mold_" + String(part.id)
	if not ContentDB.has_recipe(mold_id):
		return 1
	var total: int = 0
	for ingredient: Ingredient in ContentDB.recipe(mold_id).ingredients:
		total += ingredient.amount
	return maxi(1, total)


func is_active() -> bool:
	return state != State.IDLE


## true where only league tournaments are held: the league grounds of the cities ("league_only")
## and Leonheim once the story tournament is won.
func is_league_only() -> bool:
	return bool(settings().get("league_only", false)) or GameState.story.has_flag(get_won_flag())


## Why the player can't enter the story tournament now ("" = he can).
func get_entry_blocker() -> String:
	if not GameState.story.has_flag(str(settings().get("open_flag", "tournament_open"))):
		return Language.translate(str(settings().get("closed_text", "Das Turnier hat noch nicht begonnen.")))
	if is_league_only():
		return Language.translate("Hier gibt es nur noch die Ligen.")
	return ""


## Enters the story tournament (free) and puts the player's things aside.
func enter() -> bool:
	if is_active() or not get_entry_blocker().is_empty():
		return false
	_begin()
	return true


## Enters the league `index` at the current venue (TournamentRanking.enter pays the fee). The
## tournament master then brings the player into the arena (league_arena).
func enter_league(index: int) -> bool:
	if is_active() or not GameState.ranking.enter("smith", venue, index):
		return false
	league = index
	league_rounds = build_league_rounds(index)
	_begin()
	return true


func _begin() -> void:
	_put_aside()
	round_index = 0
	champion = false
	last_result = {}
	lost_round = -1
	league_result = ""
	story_result = {}
	state = State.BETWEEN_ROUNDS
	GameState.story.set_flag(RUNNING_FLAG)
	if is_finishing():
		GameState.story.set_flag(FINISHING_FLAG)
	changed.emit()


func get_round() -> Dictionary:
	var rounds: Array = get_rounds()
	return rounds[round_index] if round_index < rounds.size() else {}


func get_opponent_name() -> String:
	return str(get_round().get("opponent_name", Language.translate("Gegner")))


## Name of the current round ("Halbfinale"; "" = the round has none, e.g. the great tournament).
func get_round_name() -> String:
	var round_name: String = str(get_round().get("name", ""))
	return Language.translate(round_name) if not round_name.is_empty() else ""


## The league venue of the current venue (leagues.json "venues", {} = none).
static func league_venue_info() -> Dictionary:
	return TournamentRanking.venue_info(TournamentRanking.venue_key("smith", venue))


## Scene of the tournament hall of the current venue ("" = none).
static func league_hall() -> String:
	return str(league_venue_info().get("hall", ""))


## Scene of the arena of the current venue ("" = none).
static func league_arena() -> String:
	return str(league_venue_info().get("arena", ""))


## Starts the current round: empty bag and workshop, picks a task, fills the supply chest, the
## recipes of the task are known for this round, the clock runs.
func start_round() -> void:
	if state != State.BETWEEN_ROUNDS:
		return
	var round_data: Dictionary = get_round()
	var tasks: Array[String] = get_round_tasks(round_data)
	task_id = tasks.pick_random() if not tasks.is_empty() else ""
	var task: Dictionary = get_task(task_id)
	# Every round starts from nothing: leftovers of the last round don't help.
	GameState.inventory.load_save_data([])
	_clear_workshop()
	GameState.give_items_to(GameState.storage_chest, str(task.get("chest", "")))
	unknown_recipes = 0
	for recipe_id: String in task.get("recipes", []):
		if not ContentDB.has_recipe(recipe_id):
			push_error("SmithTournament: task '%s': unknown recipe '%s'." % [task_id, recipe_id])
			continue
		var recipe: RecipeData = ContentDB.recipe(recipe_id)
		if not GameState.is_recipe_unlocked(recipe):
			unknown_recipes += 1
			GameState.unlock_recipe_quietly(recipe)
	_plan_opponent(round_data, task)
	elapsed = 0.0
	state = State.RUNNING
	changed.emit()


## The opponent of this round: his score, his time and his plan. His piece is forged by SmithBot
## (profile of the round). His time comes from the round's range, shortened by his experience and
## by his route and his "Flinker Hammer" (the share of the plain route they save).
func _plan_opponent(round_data: Dictionary, task: Dictionary) -> void:
	var growth: Dictionary = settings().get("opponent_growth", {})
	var experience: int = get_opponent_experience()
	var par: float = float(settings().get("par_seconds", 300))
	var time_range: Array = round_data.get("opponent_time", [0.8, 1.2])
	var plan: Array[Dictionary] = build_opponent_plan(task, get_opponent_route(), get_opponent_bot())
	var plain: float = plan_seconds(build_opponent_plan(task, 0))
	var route_share: float = plan_seconds(plan) / plain if plain > 0.0 else 1.0
	var experience_share: float = maxf(0.5, 1.0 - float(growth.get("time", 0.0)) * experience)
	opponent_time = par * randf_range(float(time_range[0]), float(time_range[1])) * experience_share * route_share
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	opponent_quality = SmithBot.forge(get_opponent_bot(), task, rng) + int(growth.get("quality", 0)) * experience
	opponent_plan = stretch_plan(plan, opponent_time)


## true = the rounds of this tournament end with finishing (leagues.json "finishing", from silver
## on): weapons are sharpened, armor polished, fur tanned into leather.
static func is_finishing() -> bool:
	var rounds: Array = get_rounds()
	return not rounds.is_empty() and bool((rounds[0] as Dictionary).get("finishing", false))


## Profile of the opponent of the current round (SmithBot: hit chances and skills).
func get_opponent_bot() -> Dictionary:
	return get_round().get("bot", {})


## His workshop upgrades as text for the herald ("" = none), e.g. "Glutkammer, Meisteramboss".
func get_opponent_upgrades() -> String:
	return SmithBot.describe_upgrades(get_opponent_bot())


## His skills as text for the herald ("" = none), e.g. "Meisterhand 2, Härtekunst 1".
func get_opponent_skills() -> String:
	return SmithBot.describe_skills(get_opponent_bot())


## Tournaments of experience the opponents have: tournaments_played, at most "max_tournaments".
func get_opponent_experience() -> int:
	var growth: Dictionary = settings().get("opponent_growth", {})
	return clampi(tournaments_played, 0, int(growth.get("max_tournaments", 15)))


## What the herald says about the opponents between rounds ("" = they are as at the start): they
## train too, every league tournament the player has played makes them better (opponent_growth).
func get_opponent_news() -> String:
	var experience: int = get_opponent_experience()
	if experience <= 0:
		return ""
	var growth: Dictionary = settings().get("opponent_growth", {})
	var played: String = Language.translate("einem Liga-Turnier") if experience == 1 \
			else Language.translate("%s Liga-Turnieren") % DamageKinds.format_number(experience)
	var text: String = Language.translate("Die anderen Schmiede üben mit dir mit: Seit %s sind ihre Stücke %s Punkte besser und sie arbeiten %s %% schneller.") % [
			played, DamageKinds.format_number(int(growth.get("quality", 0)) * experience),
			DamageKinds.format_number(roundi(float(growth.get("time", 0.0)) * experience * 100.0))]
	match get_opponent_route():
		1:
			text += " " + Language.translate("Sie holen alles auf einmal aus der Truhe.")
		2:
			text += " " + Language.translate("Sie schnitzen den Stiel, während das Erz schmilzt.")
	return text


## Points the opponent of the current round usually reaches (x = low, y = high): what his piece
## usually scores (SmithBot.score_range, 8 in 10 pieces lie between) plus what he has learned
## (opponent_growth), plus the time bonus of his slowest / fastest time. Only a guide for the
## player: the task is not drawn yet, his real piece is forged when the round starts.
func get_opponent_score_range() -> Vector2i:
	var round_data: Dictionary = get_round()
	if round_data.is_empty():
		return Vector2i.ZERO
	var growth: Dictionary = settings().get("opponent_growth", {})
	var experience: int = get_opponent_experience()
	var learned: int = int(growth.get("quality", 0)) * experience
	var quality_range: Vector2i = SmithBot.score_range(get_opponent_bot(), TYPICAL_TASK)
	var time_range: Array = round_data.get("opponent_time", [0.8, 1.2])
	var par: float = float(settings().get("par_seconds", 300))
	var experience_share: float = maxf(0.5, 1.0 - float(growth.get("time", 0.0)) * experience)
	var slowest: float = par * float(time_range[1]) * experience_share
	var fastest: float = par * float(time_range[0]) * experience_share
	return Vector2i(quality_range.x + learned + get_time_bonus(slowest),
			quality_range.y + learned + get_time_bonus(fastest))


## How the opponents walk: 0 = to the chest twice (metal first, wood or leather later), 1 = all
## material at once, 2 = also carves the shaft while the ore melts ("opponent_growth" "route").
func get_opponent_route() -> int:
	var route: int = 0
	for needed in (settings().get("opponent_growth", {}) as Dictionary).get("route", []):
		if get_opponent_experience() >= int(needed):
			route += 1
	return route


## The opponent's work for `task` (build_task) on `route`: steps {"stop" (chest, smelter, forge,
## anvil, trough, workbench), "text" (German, shown above his head), "seconds", "walk"} from
## economy.json "opponent_plan"; walking to another station is a step of its own ("walk": true,
## with the text of what he goes there for). `bot`: his profile (SmithBot): "Flinker Hammer" makes
## the anvil step shorter, smelter upgrades the melting ({} = a plain smith).
static func build_opponent_plan(task: Dictionary, route: int, bot: Dictionary = {}) -> Array[Dictionary]:
	var cost: Dictionary = settings().get("opponent_plan", {})
	var plan: Array[Dictionary] = []
	var add: Callable = func(stop: String, text: String, key: String, factor: float = 1.0) -> void:
		if plan.is_empty() or str(plan[-1]["stop"]) != stop:
			plan.append({"stop": stop, "text": text, "seconds": float(cost.get("walk", 4)), "walk": true})
		plan.append({"stop": stop, "text": text, "seconds": float(cost.get(key, 10)) * factor, "walk": false})
	var parts: float = maxf(1.0, float(task.get("metal_parts", 1)))
	var anvil_share: float = SmithBot.anvil_time_share(bot)
	var melt: float = SmithBot.smelt_units(bot, int(task.get("ingots", 1)))
	var smelt: float = float(cost.get("smelt", 18))
	var carved: bool = int(task.get("carved", 0)) > 0
	var tanned: bool = int(task.get("tan", 0)) > 0
	var second_trip: String = "holt Holz" if carved else ("holt das Fell" if tanned else ("holt Leder" if int(task.get("leather", 0)) > 0 else ""))
	add.call("chest", "holt Material", "chest")
	add.call("smelter", "legt Erz ein", "load")
	if route >= 2 and carved:
		add.call("workbench", "schnitzt den Stiel", "carve")
		# What is left of the melting after carving and the two ways.
		var left: float = smelt * melt - float(cost.get("carve", 20)) - 2.0 * float(cost.get("walk", 4))
		add.call("smelter", "wartet auf die Schmelze", "smelt", maxf(1.0, left) / smelt)
	elif SmithBot.smelt_places(bot) > 1 and int(task.get("ingots", 1)) > 1:
		add.call("smelter", "schmilzt mehrere Barren gleichzeitig", "smelt", melt)
	else:
		add.call("smelter", "schmilzt Erz", "smelt", melt)
	add.call("smelter", "holt die Barren", "take")
	add.call("forge", "gießt", "cast", parts)
	add.call("anvil", "schmiedet", "forge", parts * anvil_share)
	add.call("trough", "kühlt ab", "quench")
	if route == 0 and not second_trip.is_empty():
		add.call("chest", second_trip, "chest")
	if tanned:
		add.call("tanning_rack", "gerbt das Fell", "tan")
	if carved and route < 2:
		add.call("workbench", "schnitzt den Stiel", "carve")
	add.call("workbench", "baut zusammen", "assemble")
	match str(task.get("finish", "")):
		"sharpen":
			add.call("grindstone", "schleift die Waffe", "sharpen")
		"polish":
			add.call("polishing_table", "poliert die Rüstung", "sharpen")
	return plan


static func plan_seconds(plan: Array[Dictionary]) -> float:
	var total: float = 0.0
	for step in plan:
		total += float(step["seconds"])
	return total


## The same plan, every step stretched so that all of them take `seconds`.
static func stretch_plan(plan: Array[Dictionary], seconds: float) -> Array[Dictionary]:
	var total: float = plan_seconds(plan)
	var stretched: Array[Dictionary] = []
	for step in plan:
		var copy: Dictionary = step.duplicate()
		copy["seconds"] = float(step["seconds"]) * seconds / total if total > 0.0 else 0.0
		stretched.append(copy)
	return stretched


## The step the opponent is at right now ({} = no round running, or he is done).
func get_opponent_step() -> Dictionary:
	if state != State.RUNNING:
		return {}
	var left: float = elapsed
	for step in opponent_plan:
		if left < float(step["seconds"]):
			return step
		left -= float(step["seconds"])
	return {}


func tick(delta: float) -> void:
	if state == State.RUNNING:
		elapsed += delta


## Time bonus for a piece finished after `seconds` (economy.json "time_bonus" at 0 s, 0 at "par_seconds").
static func get_time_bonus(seconds: float) -> int:
	var par: float = float(settings().get("par_seconds", 300))
	var share: float = clampf(1.0 - seconds / par, 0.0, 1.0)
	return roundi(float(settings().get("time_bonus", 40)) * share)


## Points one unknown recipe costs in the current round: the round's own "unknown_recipe_penalty"
## (e.g. 0 in the silver round of the story tournament: silver molds have only just come to the
## market, nobody can know them all), otherwise the one of the venue.
func get_unknown_recipe_penalty() -> int:
	return int(get_round().get("unknown_recipe_penalty", settings().get("unknown_recipe_penalty", 30)))


## Spec of the piece the current task wants (e.g. "sword:copper_blade+copper_handle").
func get_wanted_spec() -> String:
	return str(get_task(task_id).get("piece", ""))


func get_task_name() -> String:
	return str(get_task(task_id).get("name", task_id))


## The best finished piece for the task in the inventory (index), -1 = none.
func find_piece() -> int:
	if task_id.is_empty():
		return -1
	var wanted: InventorySlot = ContentDB.make_stack(get_wanted_spec())
	var best: int = -1
	for i in GameState.inventory.slots.size():
		var slot: InventorySlot = GameState.inventory.slots[i]
		if GameState.is_like(slot, wanted) and (best < 0 or ForgeQuality.get_total(slot) > ForgeQuality.get_total(GameState.inventory.slots[best])):
			best = i
	return best


## The opponent's work at this moment (for the arena): 0..1 of his planned time.
func get_opponent_progress() -> float:
	if state != State.RUNNING or opponent_time <= 0.0:
		return 1.0 if state == State.RESULT else 0.0
	return clampf(elapsed / opponent_time, 0.0, 1.0)


## Hands in the best piece for the task. false = there is none.
func hand_in() -> bool:
	if state != State.RUNNING:
		return false
	var index: int = find_piece()
	if index < 0:
		return false
	var piece: InventorySlot = GameState.inventory.slots[index].copy_with_amount(1)
	GameState.inventory.remove_from_slot(index, 1)
	var quality: int = ForgeQuality.get_total(piece)
	var time_bonus: int = get_time_bonus(elapsed)
	var penalty: int = unknown_recipes * get_unknown_recipe_penalty()
	var total: int = quality + time_bonus - penalty
	var opponent_bonus: int = get_time_bonus(opponent_time)
	var opponent_total: int = opponent_quality + opponent_bonus
	last_result = {"won": total >= opponent_total, "quality": quality, "time_bonus": time_bonus,
			"penalty": penalty, "total": total, "opponent_quality": opponent_quality,
			"opponent_bonus": opponent_bonus, "opponent_total": opponent_total, "piece": piece,
			"seconds": elapsed}
	state = State.RESULT
	changed.emit()
	return true


## After the result: next round, or the tournament is over (lost, or the last round won).
func continue_after_result() -> void:
	if state != State.RESULT:
		return
	if not last_result.get("won", false):
		lost_round = round_index
		state = State.OVER
	elif round_index + 1 >= get_rounds().size():
		champion = true
		state = State.OVER
	else:
		round_index += 1
		state = State.BETWEEN_ROUNDS
	changed.emit()


## Gives up: the tournament is lost.
func give_up() -> void:
	if state in [State.BETWEEN_ROUNDS, State.RUNNING]:
		last_result = {"won": false, "gave_up": true}
		lost_round = round_index
		state = State.OVER
		changed.emit()


## Ends the tournament: the player's things come back, the winner gets the prize. A story
## tournament leaves its place and prize in story_result (result window).
## Returns the lines about the prize ("" = nothing won).
func finish() -> String:
	if state != State.OVER:
		return ""
	# Every league tournament makes the opponents better (the story one may be tried again and
	# again: it stays as it is).
	if is_league():
		tournaments_played += 1
	_give_back()
	state = State.IDLE
	GameState.story.clear_flags([RUNNING_FLAG, FINISHING_FLAG])
	var text: String = ""
	if is_league():
		text = GameState.ranking.finish("smith", league, get_place(), venue)
		league_result = text
		league = -1
		league_rounds = []
		changed.emit()
		return text
	story_result = {"name": Language.translate(str(settings().get("title", TEXT_STORY_TITLE))), "place": get_place(),
			"gold": 0, "items": [] as Array[String]}
	if champion:
		var first: bool = not GameState.story.has_flag(get_won_flag())
		wins += 1
		var prize: int = int(settings().get("prize_gold", 1000))
		GameState.add_gold(prize)
		story_result["gold"] = prize
		text = Language.translate("Du bekommst %d Gold.") % prize
		var reward: String = str(settings().get("first_win_reward", ""))
		if first and not reward.is_empty():
			GameState.give_items(reward)
			(story_result["items"] as Array[String]).append(reward)
			var reward_stack: InventorySlot = ContentDB.make_stack(reward)
			if reward_stack:
				text += " " + Language.translate("Dazu: %s.") % reward_stack.item.display_name
		GameState.story.set_flag(get_won_flag())
	changed.emit()
	return text


## Place of the player in the running league tournament: 1 = champion, otherwise from the round he
## lost in (TournamentRanking.place_for; 3 rounds: final 2, semifinal 3, quarterfinal 5).
func get_place() -> int:
	return TournamentRanking.place_for(get_rounds().size(), -1 if champion else maxi(0, lost_round))


# --- Putting things aside ----------------------------------------------------------

## Everything the player could use in the arena goes aside: inventory, storage chest, smelter,
## alloy smelter, water trough, forge fuel and recipes. The forge is hot (tournament fire).
func _put_aside() -> void:
	_snapshot = {
		"inventory": GameState.inventory.to_save_data(),
		"storage_chest": GameState.storage_chest.to_save_data(),
		"smelter": GameState.smelter.to_save_data(),
		"extra_smelters": GameState.get_extra_smelters_save_data(),
		"alloy_smelter": GameState.alloy_smelter.to_save_data(),
		"quencher": GameState.quencher.to_save_data(),
		"forge_heat": GameState.forge_heat,
		"forge_heat_carry": GameState.forge_heat_carry,
		"forge_fuel": GameState.forge_fuel.to_save_data(),
		"unlocked_recipes": GameState.unlocked_recipes.duplicate(),
	}
	GameState.inventory.load_save_data([])
	_clear_workshop()


## Empty supply chest, smelters and trough; the forge gets the tournament fire.
func _clear_workshop() -> void:
	GameState.storage_chest.load_save_data([])
	GameState.smelter.load_save_data({})
	GameState.load_extra_smelters([])
	GameState.alloy_smelter.load_save_data({})
	GameState.quencher.load_save_data({})
	GameState.quencher_returns_when_cool = false
	GameState.forge_fuel = InventorySlot.new()
	GameState.forge_heat = int(settings().get("forge_heat", 99))
	GameState.forge_heat_carry = 0.0
	GameState.forge_heat_changed.emit(GameState.get_forge_heat())


func _give_back() -> void:
	if _snapshot.is_empty():
		return
	GameState.inventory.load_save_data(_snapshot["inventory"])
	GameState.update_inventory_size()
	GameState.storage_chest.load_save_data(_snapshot["storage_chest"])
	GameState.smelter.load_save_data(_snapshot["smelter"])
	GameState.load_extra_smelters(_snapshot.get("extra_smelters", []))
	GameState.alloy_smelter.load_save_data(_snapshot["alloy_smelter"])
	GameState.quencher.load_save_data(_snapshot["quencher"])
	GameState.forge_heat = int(_snapshot["forge_heat"])
	GameState.forge_heat_carry = float(_snapshot["forge_heat_carry"])
	GameState.forge_fuel = InventorySlot.from_save_data(_snapshot["forge_fuel"])
	GameState.forge_heat_changed.emit(GameState.get_forge_heat())
	GameState.unlocked_recipes.assign(_snapshot["unlocked_recipes"])
	GameState.recipes_changed.emit()
	_snapshot = {}


# --- Saving -----------------------------------------------------------------------

## Only what lasts: victories and the tournaments played (saving is blocked while one runs).
## Older saves also have "last_month" / "venue_months" (monthly tournaments until 2026-11-18): ignored.
func to_save_data() -> Dictionary:
	return {"wins": wins, "tournaments_played": tournaments_played}


func load_save_data(data: Dictionary) -> void:
	wins = int(data.get("wins", 0))
	story_result = {}
	tournaments_played = int(data.get("tournaments_played", 0))
	opponent_plan = []
	venue = ""
	league = -1
	league_rounds = []
	state = State.IDLE
	_snapshot = {}
