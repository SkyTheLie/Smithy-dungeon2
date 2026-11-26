class_name TournamentRewards
extends RefCounted
## Rewards of the league tournaments, smiths and heroes (data/content/tournament_rewards.json).
## Prize to pick: the winner chooses one of "mold_choices" (3) molds of the league's metal he does
## not know yet (GameState.get_unknown_molds plus "extra_molds"). With fewer left, gifts
## ("surprise:<league>:<type>") fill the free places (2026-11-19); with none left, 3 gifts. Opening
## one shows what was in the others too (TournamentRanking.claim_prize, roll_surprise with
## `exclude`: the gifts differ if the list allows it). A win below the own rank gives no gift (only molds). The gift draws one entry from the league's own list for
## smiths or heroes ("gifts" "smith" / "hero", weights): items, or gold ("gold:<amount>").
## The first win of a league also gives its forge theme ("theme", see theme_for). Places 1-3 give
## tournament marks ("marks", marks_for), traded at the tournament shop ("shop", TournamentRanking.buy).
## Leagues without an entry give nothing; one without "metal" (Holz) only the gift.
## TournamentRanking puts the offer into its pending prizes and gives the pick.

const SURPRISE: String = "surprise"
## A drawn gift of gold: "gold:<amount>" instead of a give_items spec.
const GOLD_PREFIX: String = "gold:"
const TYPES: Array[String] = ["smith", "hero"]


## The entry of a league ({} = nothing to pick).
static func rule(league_id: String) -> Dictionary:
	return (ContentDB.tournament_rewards().get("leagues", {}) as Dictionary).get(league_id, {})


## What the winner of `league_id` (type "smith" or "hero") may pick: up to "mold_choices"
## "mold:<recipe>" entries (random, only unknown ones); if there are fewer molds and `with_gift`,
## "surprise:<league>:<type>" gifts fill up to "mold_choices". With enough molds the last one is a
## gift instead now and then (gift_chance, 2026-11-19). [] = nothing.
static func offer(league_id: String, type: String = "smith", with_gift: bool = true) -> Array[String]:
	var league_rule: Dictionary = rule(league_id)
	if league_rule.is_empty():
		return []
	var game_state: Node = _game_state()
	var molds: Array[String] = []
	var metal: String = str(league_rule.get("metal", ""))
	# Without a metal (Holz): only the gift.
	for mold: RecipeData in (game_state.get_unknown_molds(metal) if not metal.is_empty() else [] as Array[RecipeData]):
		molds.append("mold:" + String(mold.id))
	for mold_id: String in league_rule.get("extra_molds", []):
		if ContentDB.has_recipe(mold_id) and not game_state.is_recipe_unlocked(ContentDB.recipe(mold_id)):
			molds.append("mold:" + mold_id)
	molds.shuffle()
	var count: int = int(ContentDB.tournament_rewards().get("mold_choices", 3))
	var choices: Array[String] = molds.slice(0, count)
	if with_gift and not surprise_list(league_id, type).is_empty():
		if count > 0 and choices.size() == count and randf() < gift_chance():
			choices[count - 1] = gift_entry(league_id, type)
		while choices.size() < count:
			choices.append(gift_entry(league_id, type))
	return choices


## How often a gift replaces the last mold although there are enough unknown molds (0-1,
## tournament_rewards.json "gift_chance").
static func gift_chance() -> float:
	return float(ContentDB.tournament_rewards().get("gift_chance", 0.0))


## The prize entry of a gift: "surprise:<league>:<type>".
static func gift_entry(league_id: String, type: String) -> String:
	return "%s:%s:%s" % [SURPRISE, league_id, type]


## The forge theme (house.json room_styles "set") the first win of a league gives ("" = none).
static func theme_for(league_id: String) -> String:
	return str(rule(league_id).get("theme", ""))


## Tournament marks for `place` (1-3) in a league ("marks"), before halving below the own rank.
static func marks_for(league_id: String, place: int) -> int:
	var marks: Array = rule(league_id).get("marks", [])
	return int(marks[place - 1]) if place >= 1 and place <= marks.size() else 0


## The gift list of a league for smiths or heroes ("gifts" "smith" / "hero"):
## [{"items": String, "chance": float}]; a gold entry has "items" = "gold:<amount>".
static func surprise_list(league_id: String, type: String = "smith") -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in (rule(league_id).get("gifts", {}) as Dictionary).get(type, []):
		var spec: String = str(entry.get("items", ""))
		if entry.has("gold"):
			spec = GOLD_PREFIX + str(int(entry["gold"]))
		list.append({"items": spec, "chance": float(entry.get("chance", 0))})
	return list


## Gold of a drawn gift ("gold:<amount>"), 0 = it is items.
static func gold_of(spec: String) -> int:
	return int(spec.trim_prefix(GOLD_PREFIX)) if spec.begins_with(GOLD_PREFIX) else 0


## Draws a gift: give_items spec or "gold:<amount>" ("" = the league has no list). Entries in
## `exclude` are left out (several gifts at once differ), unless that leaves nothing.
static func roll_surprise(league_id: String, type: String = "smith", exclude: Array[String] = []) -> String:
	var list: Array[Dictionary] = surprise_list(league_id, type)
	var rest: Array[Dictionary] = list.filter(func(entry: Dictionary) -> bool: return entry["chance"] > 0.0 and not exclude.has(entry["items"]))
	if not rest.is_empty():
		list = rest
	var total: float = 0.0
	for entry: Dictionary in list:
		total += maxf(0.0, entry["chance"])
	if total <= 0.0:
		return ""
	var pick: float = randf() * total
	for entry: Dictionary in list:
		pick -= maxf(0.0, entry["chance"])
		if pick < 0.0:
			return entry["items"]
	return list[list.size() - 1]["items"]


## The wares of the tournament shop: [{"give" (prize entry), "cost" (marks), "rank" (league id)}].
static func shop() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in ContentDB.tournament_rewards().get("shop", []):
		list.append({"give": str(entry.get("give", "")), "cost": int(entry.get("cost", 0)), "rank": str(entry.get("rank", ""))})
	return list


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
