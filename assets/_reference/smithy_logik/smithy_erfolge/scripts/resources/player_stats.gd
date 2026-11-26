class_name PlayerStats
extends Resource
## The player's (blacksmith's) values. Lives in GameState.player_stats so it survives
## scene changes and can later be saved.
## The exported values are the BASE values. What the game uses are the get_...() functions:
## base value + learned skills (PlayerSkillData) + equipped tools (pickaxe for ore, axe for trees).
## Level: experience from forging, smelting, assembling and mining; 1 skill point per level.

signal experience_changed
signal leveled_up(level: int)
## A skill was learned or a tool changed: the effective values may be different now.
signal stats_changed

## Values skills can change. New values only at the end (the skill files store the number).
## FORGING_ZONES widens the green and the yellow zones of the anvil together; GREEN_ZONE and
## YELLOW_ZONE alone are no longer used by a skill. MINING_DAMAGE counts for ore and trees.
## QUALITY_GAIN: quality points gained when forging, joining and sharpening (0.15 = +15 %).
## MATERIAL_MASTERY: makes hard materials one difficulty stage easier per point (ForgeQuality).
## RARE_FIND: extra chance for rare finds when mining (crystals, rarer ore; 0.03 = +3 %).
## FUEL_DURATION: fuel lasts longer in the smelter and the forge (0.25 = +25 % per point).
## PLANT_RARITY: chance that a harvested plant is one rarity tier better (0.1 = 10 % per rank).
## CAST_EXTRA: chance that a cast in the forge gives one blank more (0.05 = 5 %).
## SMELT_EXTRA: chance that a smelted ore gives one ingot more (0.15 = 15 %).
## QUENCH_QUALITY: quality points a piece gains when it cools in the water trough.
## ORDER_PAY: more gold for customer orders (0.05 = +5 %).
## HERO_HEALTH: extra health of heroes who wear only gear the player made.
## TAN_RARITY: tiers leather from the tanning rack is rarer than its fur.
## LOTTE_SALE: more of the sell price Lotte brings back from the loot chest (0.05 = +5 %-points).
## SOCKET_CHANCE: more chance for a masterwork socket at the workbench (0.1 = +10 %-points).
enum Stat { FORGING_STRIKES, GREEN_ZONE, YELLOW_ZONE, MINING_DAMAGE, FORGING_ZONES, JOINING_GREEN_ZONE,
		PARALLEL_DUNGEONS, SELL_PRICE, QUALITY_GAIN, MATERIAL_MASTERY, RARE_FIND, FUEL_DURATION, PLANT_RARITY,
		CAST_EXTRA, SMELT_EXTRA, QUENCH_QUALITY, ORDER_PAY, HERO_HEALTH, TAN_RARITY, LOTTE_SALE,
		SOCKET_CHANCE }

const SKILL_POINTS_PER_LEVEL: int = 1

## The player's tool slots (character window).
enum ToolSlot { PICKAXE, GLOVES, BACKPACK, AXE, SHOES, BOOK }
const TOOL_NAMES: Array[String] = ["Spitzhacke", "Handschuhe", "Rucksack", "Axt", "Schuhe", "Rezeptbuch"]
## Names in save files.
const TOOL_KEYS: Array[String] = ["pickaxe", "gloves", "backpack", "axe", "shoes", "book"]
## Books for the book slot: item id -> tab of the recipe book they open (e.g. Aurelius' notes).
const BOOK_TABS: Dictionary = {&"enchanting_book": "Mörser"}

@export_group("Forging minigame")
## How often the anvil has to be hit per forging.
@export var forging_strikes: int = 4
## Width of the green zone on the timing bar (fraction of the bar, 0.05 = 5 %).
@export var green_zone_width: float = 0.05
## Width of the yellow zone on EACH side of the green zone (fraction of the bar).
@export var yellow_zone_width: float = 0.05
## Position of the middle of the green zone on the bar (0.0 = left, 0.5 = middle, 1.0 = right).
@export var zone_center: float = 0.5

@export_group("Workbench")
## Workbench minigame (Joining): width of the green strip on each part (fraction of the field).
@export var joining_green_zone_width: float = 0.03
## Width of the yellow strip on EACH side of the green strip (fraction of the field).
@export var joining_yellow_zone_width: float = 0.025

@export_group("Mining")
## Damage per hit on ore rocks without skills and pickaxe.
@export var mining_damage: int = 5
## Damage per hit on trees without an axe.
@export var chopping_damage: int = 5
## Tools of a loaded save that did not fit their slot any more (see take_misplaced_tools).
var misplaced_tools: Array[InventorySlot] = []
## Seconds between two hits.
@export var mining_cooldown: float = 1.0


@export_group("Experience")
## Forging at the anvil: base + 1 per 10 quality points (quality 100 = +10).
@export var experience_forging: int = 5
@export var experience_per_ingot: int = 2
@export var experience_assembling: int = 5
## Workbench crafts that are no weapon, armor or tool (planks, nails, rope, shafts ...).
@export var experience_simple_craft: int = 1
@export var experience_per_rock: int = 1

## Loaded at runtime (not preloaded): the skill files refer back to PlayerStats.Stat.
var level_table: LevelTable = load("res://data/player_level_table.tres")
var skill_tree: PlayerSkillTree = load("res://data/player_skills/skill_tree.tres")
var level: int = 1
## Experience inside the current level (resets to the rest on level up).
var experience: int = 0
## Learned skills: PlayerSkillData -> rank.
var learned_skills: Dictionary = {}
## Level of an achievement (set by GameState): the rank of skills with an `achievement`.
var achievement_level: Callable = func(_id: String) -> int: return 0
## Race id of the player's look (set by GameState): appearance.json "races.<id>.player_bonus"
## adds to the skill values, e.g. {"FORGING_ZONES": 0.01} (names of Stat).
var race_of: Callable = func() -> String: return ""
## Effects of the workshop upgrades (set by GameState: House.get_upgrade_value), e.g.
## "forge_quality" in percent.
var workshop_bonus: Callable = func(_key: String) -> float: return 0.0
## Whether a story flag is set (set by GameState: Story.has_flag), for skills with `required_flag`.
## No autoload here, so test scripts can load this class.
var has_story_flag: Callable = func(_flag: String) -> bool: return false

## How the race bonuses read in the character creator: Stat name -> [text, factor on the value].
const RACE_BONUS_TEXTS: Dictionary = {
	"FORGING_ZONES": ["Amboss: grüne und gelbe Zone +%s %%-Punkte", 100.0],
	"JOINING_GREEN_ZONE": ["Werkbank: grüner Streifen +%s %%-Punkte", 100.0],
	"SELL_PRICE": ["Verkauf in Läden +%s %% Gold", 100.0],
	"QUALITY_GAIN": ["Qualitätspunkte +%s %%", 100.0],
	"MINING_DAMAGE": ["Erz abbauen und Holz fällen +%s Schaden", 1.0],
	"RARE_FIND": ["Seltene Funde beim Erzabbau +%s %%", 100.0],
	"FUEL_DURATION": ["Brennstoff hält +%s %% länger", 100.0],
	"PLANT_RARITY": ["Gewächshaus: +%s %% Chance auf seltenere Ernte", 100.0],
}
## Equipped tools: ToolSlot -> InventorySlot (amount 1). Gloves have no effect yet; the backpack
## makes the inventory bigger (GameState.update_inventory_size).
var tools: Dictionary = {}


# --- Effective values -------------------------------------------------------------

func get_forging_strikes() -> int:
	return maxi(1, forging_strikes + roundi(get_skill_bonus(Stat.FORGING_STRIKES)))


func get_green_zone_width() -> float:
	return green_zone_width + get_skill_bonus(Stat.GREEN_ZONE) + get_skill_bonus(Stat.FORGING_ZONES)


func get_yellow_zone_width() -> float:
	return yellow_zone_width + get_skill_bonus(Stat.YELLOW_ZONE) + get_skill_bonus(Stat.FORGING_ZONES)


func get_joining_green_zone_width() -> float:
	return joining_green_zone_width + get_skill_bonus(Stat.JOINING_GREEN_ZONE)


func get_joining_yellow_zone_width() -> float:
	return joining_yellow_zone_width


## Extra dungeons that may run at the same time (skill "Gefolgschaft", see GameState.get_max_parallel_dungeons).
func get_extra_parallel_dungeons() -> int:
	return roundi(get_skill_bonus(Stat.PARALLEL_DUNGEONS))


## Extra price on items sold in a shop (Nina's or the own one), 0.05 = +5 %.
func get_sell_price_bonus() -> float:
	return get_skill_bonus(Stat.SELL_PRICE)


func get_mining_damage() -> int:
	return mining_damage + roundi(get_skill_bonus(Stat.MINING_DAMAGE)) + get_pickaxe_damage()


func get_pickaxe_damage() -> int:
	var pickaxe: InventorySlot = get_tool(ToolSlot.PICKAXE)
	return pickaxe.get_mining_damage() if pickaxe else 0


## Damage per hit on trees: base + skill "Kräftiger Schlag" + the lumber axe (its chopping damage,
## like the pickaxe on ore).
func get_chopping_damage() -> int:
	return chopping_damage + roundi(get_skill_bonus(Stat.MINING_DAMAGE)) + get_axe_damage()


func get_axe_damage() -> int:
	var axe: InventorySlot = get_tool(ToolSlot.AXE)
	return axe.get_chopping_damage() if axe else 0


## Hits per second when mining / chopping.
func get_hits_per_second() -> float:
	return 1.0 / mining_cooldown


## Factor on what one piece of fuel gives (smelter: ores, forge: castings), skill "Glutwächter".
func get_fuel_factor() -> float:
	return 1.0 + get_skill_bonus(Stat.FUEL_DURATION)


## Sum of all learned skill ranks that change `stat`, plus the bonus of the player's race.
func get_skill_bonus(stat: Stat) -> float:
	var total: float = float(get_race_bonuses(race_of.call()).get(Stat.keys()[stat], 0.0))
	for skill in learned_skills:
		if skill.stat == stat:
			total += _skill_value(skill, learned_skills[skill])
	for skill in skill_tree.skills:
		if skill.stat == stat and not skill.achievement.is_empty():
			total += _skill_value(skill, get_skill_rank(skill))
	return total


## Value of a skill at this rank: base_value (from rank 1 on) + value_per_rank per rank.
static func _skill_value(skill: PlayerSkillData, rank: int) -> float:
	if rank <= 0:
		return 0.0
	return skill.base_value + skill.value_per_rank * rank


## Bonuses of a race for the player: Stat name -> value (appearance.json "player_bonus").
static func get_race_bonuses(race_id: String) -> Dictionary:
	return ContentDB.appearance_section("races").get(race_id, {}).get("player_bonus", {})


## e.g. "Amboss: grüne und gelbe Zone +1 %-Punkte" (character creator), "" without a bonus.
static func get_race_bonus_text(race_id: String) -> String:
	var parts: Array[String] = []
	var bonuses: Dictionary = get_race_bonuses(race_id)
	for stat: String in bonuses:
		var text: Array = RACE_BONUS_TEXTS.get(stat, [stat + " %s", 1.0])
		parts.append(Language.translate(text[0]) % DamageKinds.format_number(float(bonuses[stat]) * float(text[1])))
	return " · ".join(parts)


## Extra quality points when forging, joining and sharpening (0.2 = +20 %): the skill
## "Meisterhand" plus gloves in the gloves slot (ItemData.forge_quality, e.g. the master gloves).
func get_quality_gain() -> float:
	var gloves: InventorySlot = get_tool(ToolSlot.GLOVES)
	var from_gloves: float = gloves.item.forge_quality / 100.0 if gloves and not gloves.is_empty() else 0.0
	return get_skill_bonus(Stat.QUALITY_GAIN) + from_gloves \
			+ (float(workshop_bonus.call("forge_quality")) / 100.0 if workshop_bonus.is_valid() else 0.0)


## Percent the forging and workbench minigames run slower: gloves with "minigame_calm" in the
## gloves slot (ForgeQuality.get_difficulty).
func get_minigame_calm() -> int:
	var gloves: InventorySlot = get_tool(ToolSlot.GLOVES)
	return gloves.item.minigame_calm if gloves and not gloves.is_empty() else 0


## Chance (0-1) that a cast in the forge gives one blank more, skill "Formenbauer".
func get_cast_extra_chance() -> float:
	return get_skill_bonus(Stat.CAST_EXTRA)


## Chance (0-1) that one smelted ore gives one ingot more, skill "Feuerprobe".
func get_smelt_extra_chance() -> float:
	return get_skill_bonus(Stat.SMELT_EXTRA)


## Quality points a piece gains when it cools in the water trough, skill "Härtekunst".
func get_quench_quality() -> int:
	return roundi(get_skill_bonus(Stat.QUENCH_QUALITY))


## More gold for customer orders (0.05 = +5 %), skill "Goldene Zunge".
func get_order_pay_bonus() -> float:
	return get_skill_bonus(Stat.ORDER_PAY)


## Extra health of heroes who wear only gear the player made, skill "Feldschmied".
func get_crafted_gear_health() -> int:
	return roundi(get_skill_bonus(Stat.HERO_HEALTH))


## Rarity tiers leather is better than its fur at the tanning rack, skill "Gerber".
func get_tan_rarity_bonus() -> int:
	return roundi(get_skill_bonus(Stat.TAN_RARITY))


## Extra share of the sell price Lotte brings back, skill "Wie die Oma, so die Nichte" (Assistant).
func get_lotte_sale_bonus() -> float:
	return get_skill_bonus(Stat.LOTTE_SALE)


## Extra chance (0-1) for a masterwork socket at the workbench, skill "Meisterwerk" (Socket).
func get_socket_chance_bonus() -> float:
	return get_skill_bonus(Stat.SOCKET_CHANCE)


## Chance (0-1) that a harvested plant is one rarity tier better, skill "Pflanzen pflücken".
func get_plant_rarity_chance() -> float:
	return get_skill_bonus(Stat.PLANT_RARITY)


# --- Level ------------------------------------------------------------------------

func add_experience(amount: int) -> void:
	if amount <= 0 or level >= get_max_level():
		return
	experience += amount
	while level < get_max_level() and experience >= get_experience_to_next_level():
		experience -= get_experience_to_next_level()
		level += 1
		leveled_up.emit(level)
	if level >= get_max_level():
		experience = 0
	experience_changed.emit()


func get_max_level() -> int:
	return level_table.get_max_level()


func get_experience_to_next_level() -> int:
	return level_table.get_experience_to_next(level)


## Experience for one forging with the quality points it earned (0-100).
func get_forging_experience(quality: int) -> int:
	return experience_forging + floori(quality / 10.0)


# --- Skills -----------------------------------------------------------------------

func get_skill_rank(skill: PlayerSkillData) -> int:
	if not skill.achievement.is_empty():
		return mini(achievement_level.call(skill.achievement), skill.max_rank)
	return learned_skills.get(skill, 0)


func get_free_skill_points() -> int:
	return (level - 1) * SKILL_POINTS_PER_LEVEL - get_spent_skill_points()


## Why the next rank can't be learned ("" = it can).
func get_learn_blocker(skill: PlayerSkillData) -> String:
	if not skill.achievement.is_empty():
		return Language.translate("Steigt von selbst mit dem Erfolg „%s“") % Achievements.get_data(skill.achievement).get("name", skill.achievement)
	if get_skill_rank(skill) >= skill.max_rank:
		return Language.translate("Höchste Stufe erreicht")
	var needed_level: int = skill.get_required_level(get_skill_rank(skill))
	if level < needed_level:
		return Language.translate("Ab Level %d") % needed_level
	if not skill.required_flag.is_empty() and not has_story_flag.call(skill.required_flag):
		return skill.flag_hint
	if get_free_skill_points() <= 0:
		return Language.translate("Keine Skillpunkte frei")
	return ""


func learn_skill(skill: PlayerSkillData) -> bool:
	if get_learn_blocker(skill) != "":
		return false
	learned_skills[skill] = get_skill_rank(skill) + 1
	stats_changed.emit()
	return true


## Skill points spent on learned skills (not the ones that grow with achievements).
func get_spent_skill_points() -> int:
	var spent: int = 0
	for skill in learned_skills:
		spent += learned_skills[skill]
	return spent


## Gold for forgetting all learned skills (economy.json "skill_reset" "gold_per_point").
func get_skill_reset_cost() -> int:
	var per_point: int = int(ContentDB.economy("skill_reset").get("gold_per_point", 50))
	return get_spent_skill_points() * per_point


## Forgets all learned skills, the points are free again. Gold is paid by the caller.
func reset_skills() -> void:
	learned_skills.clear()
	stats_changed.emit()


# --- Pickaxe ----------------------------------------------------------------------

## Walking speed factor from the shoes (1.1 = 10 % faster).
func get_move_speed_factor() -> float:
	var shoes: InventorySlot = get_tool(ToolSlot.SHOES)
	return 1.0 + (shoes.get_move_speed() / 100.0 if shoes else 0.0)


func get_tool(slot: ToolSlot) -> InventorySlot:
	return tools.get(slot)


## Which items fit into a tool slot: pickaxes, gloves, backpacks, shoes (not boots, those are for
## heroes), for the axe slot only lumber axes (weapon axes are for heroes), books (BOOK_TABS).
func can_equip_tool(slot: ToolSlot, item: ItemData) -> bool:
	if item == null:
		return false
	match slot:
		ToolSlot.PICKAXE:
			return item.type == ItemData.ItemType.PICKAXE
		ToolSlot.GLOVES:
			return item.type == ItemData.ItemType.GLOVES
		ToolSlot.BACKPACK:
			return item.type == ItemData.ItemType.BACKPACK
		ToolSlot.AXE:
			return item.type == ItemData.ItemType.LUMBER_AXE
		ToolSlot.SHOES:
			return item.type == ItemData.ItemType.SHOES
		ToolSlot.BOOK:
			return BOOK_TABS.has(item.id)
	return false


## Equips a tool and returns the one that was there before (or null).
func equip_tool(slot: ToolSlot, stack: InventorySlot) -> InventorySlot:
	var previous: InventorySlot = get_tool(slot)
	if stack:
		tools[slot] = stack
	else:
		tools.erase(slot)
	stats_changed.emit()
	return previous


func unequip_tool(slot: ToolSlot) -> InventorySlot:
	return equip_tool(slot, null)


# --- Saving -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	var skills: Dictionary = {}
	for skill in learned_skills:
		skills[skill.resource_path] = learned_skills[skill]
	return {
		"level": level,
		"experience": experience,
		"skills": skills,
		"tools": _tools_to_save_data(),
	}


func load_save_data(data: Dictionary) -> void:
	level = clampi(int(data.get("level", 1)), 1, get_max_level())
	experience = int(data.get("experience", 0))
	learned_skills = {}
	var skills: Dictionary = data.get("skills", {})
	for path: String in skills:
		var skill := SaveSystem.load_resource(path) as PlayerSkillData
		if skill:
			learned_skills[skill] = clampi(int(skills[path]), 0, skill.max_rank)
	tools = {}
	var saved_tools: Dictionary = data.get("tools", {})
	# Older saves only had a pickaxe.
	if data.has("pickaxe"):
		saved_tools["pickaxe"] = data["pickaxe"]
	for key: String in saved_tools:
		var stack := InventorySlot.from_save_data(saved_tools[key])
		var slot: int = TOOL_KEYS.find(key)
		if slot >= 0 and not stack.is_empty():
			if can_equip_tool(slot, stack.item):
				tools[slot] = stack
			else:
				# E.g. a weapon axe from an older save in the axe slot: back to the player.
				misplaced_tools.append(stack)
	experience_changed.emit()
	stats_changed.emit()


## Takes the tools that no longer fit their slot after loading (GameState puts them back into the
## inventory).
func take_misplaced_tools() -> Array[InventorySlot]:
	var list: Array[InventorySlot] = misplaced_tools.duplicate()
	misplaced_tools.clear()
	return list


func _tools_to_save_data() -> Dictionary:
	var saved: Dictionary = {}
	for slot in tools:
		saved[TOOL_KEYS[slot]] = (tools[slot] as InventorySlot).to_save_data()
	return saved
