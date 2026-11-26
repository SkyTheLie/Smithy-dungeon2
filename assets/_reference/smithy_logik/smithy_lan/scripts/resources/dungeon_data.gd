class_name DungeonData
extends Resource
## A dungeon heroes can be sent to (dungeon board). Created by ContentDB from
## data/content/dungeons.json (format: docs/CONTENT.md).
## Every stage spawns a wave: the "fixed" enemies (e.g. a boss) plus a random number of enemies
## drawn from a pool by chance. Stages can have their own wave (mini boss, boss).
## The rewards are only paid if the party clears all stages in time. Each reward has a chance,
## so a run can bring nothing, only EXP, or gold, EXP and items.

enum StageType { NORMAL, MINI_BOSS, BOSS }

const STAGE_TYPE_NAMES: Array[String] = ["", "Mini-Boss", "Boss"]
## Tab on the dungeon board for dungeons without "region".
const DEFAULT_REGION: String = "Stadt"
## Seconds for all stages if dungeons.json sets no "time_limit" (5 minutes).
const DEFAULT_TIME_LIMIT: float = 300.0

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
@export_multiline var description: String = "":
	get:
		return Language.translate(description)
## Tab on the dungeon board where the dungeon is listed (e.g. "Stadt").
@export var region: String = DEFAULT_REGION
## Suggested hero level (only shown on the board).
@export var level: int = 1
## Story flag the dungeon needs to be on the board (e.g. "rat_nest_unlocked"). Empty = always.
@export var required_flag: String = ""
## Not on the board: only the story starts it (e.g. the rats in the mine, chapter 6). Once won
## it is on the board after all (is_on_board).
@export var hidden: bool = false
## Gone from the board once this story flag is set, unless it was won (a quest dungeon, e.g. the
## Krähennest; won dungeons stay, see is_on_board). Empty = stays.
@export var gone_flag: String = ""
## Another dungeon the heroes must have won once before this one is on the board (dungeons of a
## tab one after another, e.g. the catacombs after the sewers). Empty = none.
@export var required_dungeon: String = ""


## Whether the dungeon is on the board now (its flag set, not hidden, not gone, the dungeon before
## it won once). `wins` = achievement counters ("dungeon:<id>" = how often it was won).
## A dungeon won once stays on the board for good, story dungeons too (hidden or gone ones):
## replays give their normal rewards, story items only drop on the first win (GameState.is_loot_unlocked).
func is_on_board(story: Story, wins: Dictionary = {}) -> bool:
	if was_won(wins):
		return true
	return not hidden and story.has_flag(required_flag) and (gone_flag.is_empty() or not story.flags.has(gone_flag)) \
			and (required_dungeon.is_empty() or int(wins.get("dungeon:" + required_dungeon, 0)) > 0)


## Whether the dungeon was won at least once (normal mode). `wins` = achievement counters.
func was_won(wins: Dictionary) -> bool:
	return int(wins.get("dungeon:" + String(id), 0)) > 0


## Gold for the next run: `cost`, or nothing while `free_until_won` and the dungeon was never won.
## `wins` = achievement counters, as in is_on_board.
func get_cost(wins: Dictionary = {}) -> int:
	return 0 if free_until_won and int(wins.get("dungeon:" + String(id), 0)) == 0 else cost
## Gold the player pays the party for a run (dungeon board, once per run).
@export var cost: int = 0
## Runs cost nothing until the dungeon was won once (the first dungeon of the story).
@export var free_until_won: bool = false
## Stamina every hero of the party needs and uses for a run.
@export var stamina_cost: int = 20
@export var stage_count: int = 10
## Seconds the party has for all stages; 0 = no limit. Running out = defeat.
@export var time_limit: float = 0.0
## How much stronger the monsters are here than in enemies.json (health and damage, incl. spells
## and boss phases), so the same monsters can fill an easier and a harder dungeon: 1.0 = as written.
@export var enemy_health_factor: float = 1.0
@export var enemy_damage_factor: float = 1.0
## Side view behind the fight (tiles horizontally, scrolls while the heroes walk).
@export var battle_background: Texture2D
## Tile the background mirrored (every second copy flipped) for pictures that do not tile.
@export var background_mirror: bool = false

@export_group("Rewards")
## Gold and EXP (every hero): {"min": int, "max": int, "chance": 0..1}.
@export var reward_gold: Dictionary = {"min": 0, "max": 0, "chance": 1.0}
@export var reward_experience: Dictionary = {"min": 0, "max": 0, "chance": 1.0}
## Items on victory: {"item": ItemData, "min": int, "max": int, "chance": float}.
@export var reward_items: Array[Dictionary] = []
## Recipes unlocked on victory (recipe ids, e.g. "mold_copper_blade").
@export var reward_recipe_ids: Array[String] = []
## Material id (e.g. "copper"): on victory, by chance, one random mold of this metal the player
## does not know yet (nothing once all are known). Empty = none.
@export var random_mold_material: String = ""
@export var random_mold_chance: float = 1.0
## Metals (material ids) whose ore and ingots this dungeon gives even before the story reaches
## them (dungeons.json "rewards.early_metals"), e.g. gold from the forgotten foundry before the desert.
@export var early_metals: Array[String] = []
## Ingot a boss of this dungeon may drop (chance and rarity: combat.json "dungeon_loot"), the metal
## of its part of the story. null = none.
@export var boss_ingot: ItemData
## Factor on the drop chances of the ordinary monsters here (dungeons.json "rewards.drop_factor",
## 0.5 = half as often); bosses and mini-bosses keep theirs.
@export var drop_factor: float = 1.0

## Wave of every stage without its own: {"type": StageType, "fixed": Array[EnemyData],
## "count": [min, max], "pool": [{"enemy": EnemyData, "chance": float, "from": int, "to": int}]}.
var default_wave: Dictionary = {}
## Stage number -> its own wave (same format).
var special_waves: Dictionary = {}


func get_wave(stage: int) -> Dictionary:
	return special_waves.get(stage, default_wave)


func get_stage_type(stage: int) -> StageType:
	return get_wave(stage).get("type", StageType.NORMAL)


## "Mini-Boss", "Boss" or "" for a normal stage.
func get_stage_label(stage: int) -> String:
	return Language.translate(STAGE_TYPE_NAMES[get_stage_type(stage)])


## The monsters of one stage: the fixed ones, then `count` random ones from the pool (only
## entries allowed on this stage, weighted by their chance).
func roll_enemies(stage: int) -> Array[EnemyData]:
	var wave: Dictionary = get_wave(stage)
	var list: Array[EnemyData] = []
	list.append_array(wave.get("fixed", []))
	var candidates: Array = (wave.get("pool", []) as Array).filter(
			func(entry: Dictionary) -> bool: return stage >= entry["from"] and (entry["to"] <= 0 or stage <= entry["to"]))
	var total: float = 0.0
	for entry: Dictionary in candidates:
		total += entry["chance"]
	var count: Array = wave.get("count", [0, 0])
	for i in randi_range(count[0], count[1]):
		if total <= 0.0:
			break
		var roll: float = randf() * total
		for entry: Dictionary in candidates:
			roll -= entry["chance"]
			if roll <= 0.0:
				list.append(entry["enemy"])
				break
	return list


## Every kind of monster that can appear (for the board), in order of first appearance.
func get_enemies() -> Array[EnemyData]:
	var list: Array[EnemyData] = []
	for wave: Dictionary in [default_wave] + special_waves.values():
		for enemy: EnemyData in wave.get("fixed", []):
			if not list.has(enemy):
				list.append(enemy)
		for entry: Dictionary in wave.get("pool", []):
			if not list.has(entry["enemy"]):
				list.append(entry["enemy"])
	return list


## Stage numbers with their own wave, sorted.
func get_special_stages() -> Array[int]:
	var stages: Array[int] = []
	stages.assign(special_waves.keys())
	stages.sort()
	return stages


## Rolls the item rewards (chance and amount): ItemData -> amount.
## `amount_factor` > 1 (hard mode): more of every item that comes (rounded, at least as many).
func roll_reward_items(amount_factor: float = 1.0) -> Dictionary:
	var result: Dictionary = {}
	for reward in reward_items:
		if randf() < reward["chance"]:
			var amount: int = roundi(randi_range(reward["min"], reward["max"]) * amount_factor)
			if amount > 0:
				result[reward["item"]] = result.get(reward["item"], 0) + amount
	return result


## Rolls a gold/EXP reward (0 if the chance fails).
static func roll_amount(reward: Dictionary) -> int:
	if randf() >= reward.get("chance", 1.0):
		return 0
	return randi_range(reward.get("min", 0), reward.get("max", 0))


## "30", "20-40" (for tooltips).
static func format_amount(reward: Dictionary) -> String:
	if reward.get("min", 0) == reward.get("max", 0):
		return str(reward.get("min", 0))
	return "%d-%d" % [reward.get("min", 0), reward.get("max", 0)]


func get_reward_recipes() -> Array[RecipeData]:
	var list: Array[RecipeData] = []
	for recipe_id in reward_recipe_ids:
		var recipe: RecipeData = ContentDB.recipe(recipe_id)
		if recipe:
			list.append(recipe)
	return list


## "5:00" for the board and the battle window.
static func format_time(seconds: float) -> String:
	var total: int = ceili(maxf(seconds, 0.0))
	return "%d:%02d" % [total / 60, total % 60]


# --- Hard modes -------------------------------------------------------------------------

## Settings of a hard mode (combat.json "hard_modes", entry with this "power"): monsters `power`
## times as strong, "drop_factor" (monster drops more often, dungeon reward items more), "rarity_factor"
## (rarer drops), "extra_ingots" (the boss ingot always drops, plus these), "gold_factor",
## "exp_factor", "rarity_shift" (every drop this many tiers rarer: 1 = R1 becomes R2, a rolled R2
## becomes R3). Power 1 (normal) or an unknown power: all factors 1, no shift.
static func hard_mode(power: int) -> Dictionary:
	var result: Dictionary = {"power": 1, "drop_factor": 1.0, "rarity_factor": 1.0, "extra_ingots": 0,
			"gold_factor": 1.0, "exp_factor": 1.0, "rarity_shift": 0}
	if power <= 1:
		return result
	for entry: Variant in ContentDB.combat_list("hard_modes"):
		if entry is Dictionary and int(entry.get("power", 0)) == power:
			for key: String in result:
				result[key] = entry.get(key, result[key])
			result["power"] = power
			result["extra_ingots"] = int(result["extra_ingots"])
			result["rarity_shift"] = int(result["rarity_shift"])
			return result
	return result


## Rarity of a drop in a hard mode: `shift` tiers above what was rolled (at most Mythic).
## Coin purses and items with a fixed rarity above Common (e.g. a legendary compass) keep theirs.
static func shift_rarity(item: ItemData, rarity: int, shift: int) -> int:
	if shift <= 0 or item == null or not item.purse_gold.is_empty() or item.base_rarity > Rarity.Tier.COMMON:
		return rarity
	return mini(rarity + shift, Rarity.Tier.MYTHIC)


## All powers a dungeon can be run with: [1, 2, 3, 4, 5] (1 = normal, from combat.json "hard_modes").
static func get_hard_mode_powers() -> Array[int]:
	var powers: Array[int] = [1]
	for entry: Variant in ContentDB.combat_list("hard_modes"):
		if entry is Dictionary and int(entry.get("power", 0)) > 1:
			powers.append(int(entry["power"]))
	powers.sort()
	return powers


## Achievement counter of a won run with this power: "dungeon:<id>" (normal), "dungeon:<id>:x3".
func get_win_counter(power: int = 1) -> String:
	return "dungeon:" + String(id) + ("" if power <= 1 else ":x%d" % power)


## The highest power the player may choose: a mode opens once the mode below it was won
## (won normally » ×2, won ×2 » ×3 ...). 1 = only normal.
func get_max_power(wins: Dictionary) -> int:
	var best: int = 1
	for power in get_hard_mode_powers():
		if power <= 1:
			continue
		var below: int = best
		if int(wins.get(get_win_counter(below), 0)) <= 0:
			break
		best = power
	return best
