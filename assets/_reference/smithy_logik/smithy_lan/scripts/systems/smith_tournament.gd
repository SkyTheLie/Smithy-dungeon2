class_name SmithTournament
extends RefCounted
## The great smith tournament in Leonheim (arena at the end of the smith lane, settings:
## economy.json "smith_tournament"). Four rounds, each one smith against another: the judge names
## a task (e.g. "Eisenaxt": any weapon or armor piece of "pieces" in the metal of the round, see
## build_task), both forge it from the materials in the supply chest, and the better
## piece wins: score = rarity x 100 + quality of the piece, plus a bonus for speed, minus points for
## every recipe of the task the player did not know before. The opponent is simulated (score and
## time from the round's ranges). Whoever loses a round is out.
## During the tournament the player only has what the tournament gives him: his inventory, the
## storage chest, smelter, water trough, forge fuel and recipes are put aside when it starts
## (`_snapshot`) and come back when it ends (no cheating). Saving is blocked meanwhile.
## The story tournament (part 3) is free and can be tried again until it is won; after that there
## is one tournament per calendar month with an entry fee. The first victory gives the master
## gloves ("first_win_reward"), every victory "prize_gold".
## Other venues (e.g. Sylvaris) are in "venues": their fields replace the ones of Leonheim (own
## smiths, prize, reward, `won_flag`); with "monthly" every tournament there costs the entry fee.
## League tournaments (TournamentRanking, leagues.json): enter_league() runs the same four rounds
## in the metal of today's league against smiths of the league; every round changes the rating,
## a victory pays the league's prize (no story flag, no monthly limit).

## Something changed (round started, piece handed in, tournament over): windows update.
signal changed

enum State { IDLE, BETWEEN_ROUNDS, RUNNING, RESULT, OVER }

## Story flag while a tournament runs (doors of the arena stay shut, see Door.blocked_flag).
const RUNNING_FLAG: String = "tournament_running"
## Story flag after the first victory (part 3 goes on, the monthly tournaments begin).
const WON_FLAG: String = "smith_tournament_won"

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
## true = the whole tournament was won (after the last round).
var champion: bool = false
## Victories so far and the month index of the last monthly tournament (-1 = none).
var wins: int = 0
var last_month: int = -1
## Month index of the last tournament at the other venues (venue id -> month).
var venue_months: Dictionary = {}
## Everything put aside at the start (GameState data, see _put_aside / _give_back).
var _snapshot: Dictionary = {}


## Where the tournament takes place ("" = Leonheim, otherwise a key of "venues"). The herald of
## each venue picks it before the tournament starts (select_venue); it stays while one runs.
static var venue: String = ""
## League of the running league tournament (index in leagues.json, -1 = the great tournament) and
## its rounds (opponents drawn when it started, see build_league_rounds).
static var league: int = -1
static var league_rounds: Array = []

const LEAGUE_ROUNDS: int = 4


## The settings of the current venue: those of Leonheim, with the fields of the venue on top (and
## the rounds of the league during a league tournament).
static func settings() -> Dictionary:
	var base: Dictionary = ContentDB.economy("smith_tournament")
	if venue.is_empty() and league < 0:
		return base
	var merged: Dictionary = base.duplicate()
	merged.merge((base.get("venues", {}) as Dictionary).get(venue, {}), true)
	if league >= 0:
		merged.merge({"rounds": league_rounds, "monthly": false, "entry_fee": 0,
				"champion_text": Language.translate("Du hast das Turnier der %s gewonnen!") % TournamentRanking.league_name(league)}, true)
	return merged


static func is_league() -> bool:
	return league >= 0


## Four rounds in the league's metal: smiths drawn from leagues.json "smith_opponents", each round a
## bit better and faster ("quality_step", "time_step").
static func build_league_rounds(index: int) -> Array:
	var part: Dictionary = TournamentRanking.league_part("smith", index)
	var rules: Dictionary = TournamentRanking.data()
	var pool: Array = (rules.get("smith_opponents", []) as Array).duplicate()
	pool.shuffle()
	var quality: Array = part.get("quality", [40, 80])
	var time: Array = part.get("time", [0.9, 1.2])
	var quality_step: int = int(rules.get("quality_step", 10))
	var time_step: float = float(rules.get("time_step", 0.03))
	var rounds: Array = []
	for round_number in LEAGUE_ROUNDS:
		var opponent: Dictionary = pool[round_number % pool.size()] if not pool.is_empty() else {}
		rounds.append({"opponent_name": str(opponent.get("name", Language.translate("Gegner"))),
				"opponent_look": opponent.get("look", {}), "metal": str(part.get("metal", "copper")),
				"leather": str(part.get("leather", "leather")), "ores": part.get("ores", {}),
				"opponent_quality": [int(quality[0]) + quality_step * round_number, int(quality[1]) + quality_step * round_number],
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
	var parts: Array[String] = []
	var recipes: Array[String] = []
	var ingots: int = 0
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
		elif part.part_type == ItemData.PartType.LEATHER:
			chest[String(part.id)] = int(chest.get(String(part.id), 0)) + ingredient.amount
		else:
			# A carved part (wooden shaft): its recipe and the wood for it, one spare.
			if not recipes.has(String(part.id)):
				recipes.append(String(part.id))
			var raw: String = str(ContentDB.material_info(part.material_id).get("raw", ""))
			if not raw.is_empty():
				chest[raw] = int(chest.get(raw, 0)) + ingredient.amount + 1
	recipes.append(piece_id)
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
	return {"name": stack.get_display_name() if stack else piece_id, "piece": piece, "recipes": recipes,
			"chest": ",".join(chest_parts)}


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


## true once the story tournament is won: from then on one tournament per month with entry fee.
func is_monthly() -> bool:
	return bool(settings().get("monthly", false)) or GameState.story.has_flag(WON_FLAG)


## Month index of the last tournament at the current venue (-1 = none).
func get_last_month() -> int:
	return last_month if venue.is_empty() else int(venue_months.get(venue, -1))


func _set_last_month(month: int) -> void:
	if venue.is_empty():
		last_month = month
	else:
		venue_months[venue] = month


func get_entry_fee() -> int:
	return int(settings().get("entry_fee", 500)) if is_monthly() else 0


## Why the player can't enter now ("" = he can).
func get_entry_blocker() -> String:
	if not GameState.story.has_flag(str(settings().get("open_flag", "tournament_open"))):
		return Language.translate(str(settings().get("closed_text", "Das Turnier hat noch nicht begonnen.")))
	if is_monthly() and get_last_month() == GameCalendar.get_month_index(GameState.day_cycle.day):
		return Language.translate("Das Turnier dieses Monats ist vorbei. Nächsten Monat wieder.")
	if GameState.gold < get_entry_fee():
		return Language.translate("Das Startgeld beträgt %d Gold.") % get_entry_fee()
	return ""


## Enters the tournament: pays the entry fee and puts the player's things aside.
func enter() -> bool:
	if is_active() or not get_entry_blocker().is_empty():
		return false
	if get_entry_fee() > 0 and not GameState.spend_gold(get_entry_fee()):
		return false
	if is_monthly():
		_set_last_month(GameCalendar.get_month_index(GameState.day_cycle.day))
	_begin()
	return true


## Enters today's league tournament at the current venue (TournamentRanking.enter pays the fee).
func enter_league() -> bool:
	if is_active():
		return false
	var index: int = GameState.ranking.enter("smith", venue)
	if index < 0:
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
	state = State.BETWEEN_ROUNDS
	GameState.story.set_flag(RUNNING_FLAG)
	changed.emit()


func get_round() -> Dictionary:
	var rounds: Array = get_rounds()
	return rounds[round_index] if round_index < rounds.size() else {}


func get_opponent_name() -> String:
	return str(get_round().get("opponent_name", Language.translate("Gegner")))


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
	var par: float = float(settings().get("par_seconds", 300))
	var time_range: Array = round_data.get("opponent_time", [0.8, 1.2])
	opponent_time = par * randf_range(float(time_range[0]), float(time_range[1]))
	var quality_range: Array = round_data.get("opponent_quality", [40, 80])
	opponent_quality = randi_range(int(quality_range[0]), int(quality_range[1]))
	elapsed = 0.0
	state = State.RUNNING
	changed.emit()


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
	if is_league():
		last_result["rating_change"] = GameState.ranking.apply_round("smith", league, round_index, last_result["won"])
	state = State.RESULT
	changed.emit()
	return true


## After the result: next round, or the tournament is over (lost, or the last round won).
func continue_after_result() -> void:
	if state != State.RESULT:
		return
	if not last_result.get("won", false):
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
		if is_league():
			last_result["rating_change"] = GameState.ranking.apply_round("smith", league, round_index, false)
		state = State.OVER
		changed.emit()


## Ends the tournament: the player's things come back, the winner gets the prize.
## Returns the lines about the prize ("" = nothing won).
func finish() -> String:
	if state != State.OVER:
		return ""
	_give_back()
	state = State.IDLE
	GameState.story.clear_flags([RUNNING_FLAG])
	var text: String = ""
	if is_league():
		if champion:
			text = GameState.ranking.record_win("smith", league)
		league = -1
		league_rounds = []
		changed.emit()
		return text
	if champion:
		var first: bool = not GameState.story.has_flag(get_won_flag())
		wins += 1
		var prize: int = int(settings().get("prize_gold", 1000))
		GameState.add_gold(prize)
		text = Language.translate("Du bekommst %d Gold.") % prize
		var reward: String = str(settings().get("first_win_reward", ""))
		if first and not reward.is_empty():
			GameState.give_items(reward)
			var reward_stack: InventorySlot = ContentDB.make_stack(reward)
			if reward_stack:
				text += " Dazu: %s." % reward_stack.item.display_name
		GameState.story.set_flag(get_won_flag())
	changed.emit()
	return text


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

## Only what lasts: victories and the month of the last tournament (saving is blocked while one runs).
func to_save_data() -> Dictionary:
	return {"wins": wins, "last_month": last_month, "venue_months": venue_months}


func load_save_data(data: Dictionary) -> void:
	wins = int(data.get("wins", 0))
	last_month = int(data.get("last_month", -1))
	venue_months = (data.get("venue_months", {}) as Dictionary).duplicate()
	venue = ""
	league = -1
	league_rounds = []
	state = State.IDLE
	_snapshot = {}
