class_name DefenseRun
extends RefCounted
## Rules of the forge defense (scenes/defense/). All numbers: data/content/defense.json
## (ContentDB.defense()). The scene moves things and calls in here; nothing here knows nodes.
##
## Roguelite: a run is an endless chain of waves and ends only when the smithy falls. The waves
## come from `parts` (part 1: 15, 25, 40 rats, then the boss with more rats; part 2: goblins ...);
## after the last part it starts over, stronger (`loop_factor`). Every enemy pays coins; a boss also
## gives a relic. Between runs (window) the coins buy crystals (random offers at fixed prices) and
## lasting upgrades; mastery buys the mastery tree and collection upgrades. The crystals bought lie
## near the smithy when the next run starts; the hammer breaks them and they call units of their
## element (`roll_unit`, `unit_stats`). Enemies fight the units first, the smithy only when no unit
## is left (the scene does that).
##
## Everything lasting is saved in the file `save_path` (DefenseSaves; `save_meta` / `load_meta`): coins, upgrades, bought
## crystals, crystal filter, mastery, relics, collection, quests. The run itself (wave, smithy life, units) is not
## saved on purpose: it lives only as long as the scene.

signal coins_changed(coins: int)
## Crystal coins (only for crystals) changed.
signal crystal_coins_changed(amount: int)
signal castle_changed(hp: int, max_hp: int)
## A quest is done (its JSON entry): income and mastery already added.
signal quest_completed(quest: Dictionary)
## A boss dropped this relic (already owned, in a slot if one was free).
signal relic_found(id: String)
## The boss of part `index` (0 = first) fell for the first time: new crystals and upgrades.
signal part_beaten(index: int)

## Relic fields and how they add up: factors multiply, the others add.
const RELIC_FACTORS: Array[String] = ["damage", "hp", "attack_speed", "hammer_third"]
const RELIC_ADDS: Array[String] = ["count", "giant_chance", "coins", "rarity_luck"]
## Save format: 2 = crystal path and crystal coins ×10 (2026-11-23); 3 = boss_best by dungeon id,
## parts sorted by theme (2026-11-25).
const META_VERSION: int = 3
## Version 1: crystal id » beaten parts that opened it in the shop (for old saves only).
const OLD_CRYSTAL_PARTS: Dictionary[String, int] = {"holy_poison_crystal": 2, "holy_ice_crystal": 5,
		"holy_dark_crystal": 10, "holy_wind_crystal": 20}
## Renamed unit ids (old » new) for old saves (FEHLERKLASSEN 6): the fire crystal's harpy became
## a fire salamander (2026-11-24).
const RENAMED_UNITS: Dictionary[String, String] = {"harpy": "fire_salamander"}

# --- Lasting progress (saved) ---
var coins: int = 0
## Crystal coins: the only way to buy crystals. A supply with a maximum (`crystal_coin_max`),
## full again after every run (what is left does not pile up).
var crystal_coins: int = 0
## Coin upgrades: id -> level.
var upgrade_levels: Dictionary[String, int] = {}
## Crystal ids bought, waiting for the next run.
var crystal_stock: Array[String] = []
var mastery: int = 0
var mastery_levels: Dictionary[String, int] = {}
var owned_relics: Array[String] = []
## Relic id per slot, "" = empty.
var relic_slots: Array[String] = []
var best_wave: int = 0
## Unit ids seen at least once (collection).
var discovered: Array[String] = []
## Collection upgrades: unit id -> level.
var unit_levels: Dictionary[String, int] = {}
## Quest id -> progress; done quests are in quests_done.
var quest_progress: Dictionary[String, int] = {}
var quests_done: Array[String] = []
## How many parts (dungeons) have been beaten at least once; unlocks crystals and upgrades.
var parts_beaten: int = 0
## Dungeon id of a part -> least life (percent) its boss ever had left when a run ended at it
## (by id, not by place: the order of the parts may change, FEHLERKLASSEN 2).
var boss_best: Dictionary[String, int] = {}

# --- The run (not saved on purpose) ---
## Current wave of the run, 1 = first; 0 = not started.
var wave: int = 0
var castle_hp: int = 0
## Crystal ids on offer, "" = sold.
var offers: Array[String] = []
## Same index as offers: true = special offer (discount).
var offer_discounts: Array[bool] = []
## Same index as offers: true = a pack (bundle_size crystals for the price of bundle_price).
var offer_bundles: Array[bool] = []
## not saved on purpose (rolled again on load, like the offers): the crystals of each offer, one id
## or bundle_size ids for a pack (a mixed pack has different ones).
var offer_contents: Array[Array] = []
## not saved on purpose (rolled with the offers): a relic for coins in the shop, "" = none this time.
var relic_offer: String = ""
## Crystals the player keeps out of the shop (and the tavern); at least shop.min_crystals stay.
var crystal_filter: Array[String] = []
## Rerolls since the last run (the first ones may be free).
var rerolls_this_phase: int = 0
var run_kills: int = 0
## Coins and mastery earned in this run (for the result).
var run_coins: int = 0
var run_mastery: int = 0
## Relics bosses dropped in this run.
var run_relics: Array[String] = []
## What this run brought (shown after it): units seen for the first time, quests done, parts
## beaten, whether it reached a new best wave.
var run_new_units: Array[String] = []
var run_quests: Array[String] = []
var run_parts: Array[int] = []
var run_best: bool = false
## The boss the run ended at: name, life left (percent), whether that is a new best; percent -1 = none.
var run_boss_name: String = ""
var run_boss_percent: int = -1
var run_boss_record: bool = false
## Unused since relics drop directly; kept for a choice later.
var relic_choice: Array[String] = []

## The save file this run reads and writes (the game sets it from DefenseSaves.path).
var save_path: String = DefenseSaves.PATH

var _data: Dictionary
## Mastery fractions from mastery_gain, not yet a whole point.
var _mastery_rest: float = 0.0


func _init() -> void:
	_data = ContentDB.defense()
	_fit_relic_slots()
	coins = int(_data.get("start_coins", 0))
	crystal_coins = crystal_coin_max()
	castle_hp = castle_max_hp()
	roll_offers()


# --- Run flow ----------------------------------------------------------------------

## A new run: it starts at the first part not beaten yet (so a run is short and ends at a boss
## the player still has to beat), full smithy. Coins, upgrades and crystals stay.
func start_run() -> void:
	wave = waves_before_part(start_part())
	run_new_units.clear()
	run_quests.clear()
	run_parts.clear()
	run_best = false
	run_boss_name = ""
	run_boss_percent = -1
	run_boss_record = false
	run_kills = 0
	run_coins = 0
	run_mastery = 0
	run_relics.clear()
	castle_hp = castle_max_hp()
	castle_changed.emit(castle_hp, castle_max_hp())


## The part a run starts in: the first one not beaten yet (the last one when all are beaten).
func start_part() -> int:
	return mini(parts_beaten, maxi(part_count() - 1, 0))


## How many waves the parts before `index` have together.
func waves_before_part(index: int) -> int:
	var total: int = 0
	var parts: Array[Dictionary] = _list("parts")
	for i in mini(index, parts.size()):
		total += (parts[i].get("waves", []) as Array).size()
	return total


## Next wave: returns its enemy ids (all come at once; the boss, if any, last).
func next_wave() -> Array[String]:
	wave += 1
	if wave > best_wave:
		run_best = true
	quest_event("day", "", wave)
	return wave_enemies()


## The enemies of the current wave from `parts` (id » count).
func wave_enemies() -> Array[String]:
	var result: Array[String] = []
	var bosses: Array[String] = []
	var entry: Dictionary = _wave_entry()
	for id: String in entry:
		if id.begins_with("_") or not _enemies().has(id):
			continue
		for i in int(entry[id]):
			if bool(_enemies()[id].get("elite", false)):
				bosses.append(id)
			else:
				result.append(id)
	result.shuffle()
	result.append_array(bosses)
	return result


## The next wave comes as soon as only this many enemies (and no boss) are left.
func early_next() -> int:
	return int(_waves().get("early_next", 0))


## Part (0 = part 1), wave in that part (0 = first) and loop (0 = first time) of `at_wave`.
func wave_place(at_wave: int = -1) -> Vector3i:
	var index: int = maxi((wave if at_wave < 0 else at_wave) - 1, 0)
	var parts: Array[Dictionary] = _list("parts")
	var total: int = 0
	for part: Dictionary in parts:
		total += (part.get("waves", []) as Array).size()
	if total == 0:
		return Vector3i.ZERO
	var loop: int = int(float(index) / float(total))
	index -= loop * total
	for part_index in parts.size():
		var count: int = (parts[part_index].get("waves", []) as Array).size()
		if index < count:
			return Vector3i(part_index, index, loop)
		index -= count
	return Vector3i.ZERO


## Name of the current part = its dungeon's name (already translated).
func part_name() -> String:
	return part_dungeon_name(wave_place().x)


## The dungeon name of part `index` (translated), "" if unknown.
func part_dungeon_name(index: int) -> String:
	var parts: Array[Dictionary] = _list("parts")
	if index < 0 or index >= parts.size():
		return ""
	var dungeon: DungeonData = ContentDB.dungeon(String(parts[index].get("dungeon", "")))
	return dungeon.display_name if dungeon else ""


## Ground picture of the current part.
func part_ground() -> String:
	return part_ground_at(wave_place().x)


func part_ground_at(index: int) -> String:
	var parts: Array[Dictionary] = _list("parts")
	return String(parts[index].get("ground", "")) if index >= 0 and index < parts.size() else ""


## Music of part `index` (audio.json music id), "" if it has none.
func part_music(index: int) -> String:
	var parts: Array[Dictionary] = _list("parts")
	return String(parts[index].get("music", "")) if index >= 0 and index < parts.size() else ""


# --- Looks (effects.*, only for the pictures) --------------------------------------

## Weather on the field for a ground picture: ash, snow, leaves, spores, sand, rain, dust or none.
func weather_for(ground: String) -> String:
	var effects: Dictionary = _data.get("effects", {})
	return String((effects.get("weather", {}) as Dictionary).get(ground.get_file().get_basename(),
			effects.get("weather_default", "none")))


## How dark the current wave is (0 = day, 1 = night): effects.night by wave of the part, the
## boss wave always the last value.
func night_amount() -> float:
	var night: Array = (_data.get("effects", {}) as Dictionary).get("night", [])
	if night.is_empty():
		return 0.0
	var at: Vector2i = wave_in_part()
	var index: int = night.size() - 1 if at.x >= at.y else mini(at.x - 1, night.size() - 2)
	return clampf(float(night[maxi(index, 0)]), 0.0, 1.0)


## Colour of a crystal's element (effects.element_colors), white if it has none.
func crystal_color(id: String) -> Color:
	return element_color(String(crystal(id).get("element", "")))


func element_color(element: String) -> Color:
	var colors: Dictionary = (_data.get("effects", {}) as Dictionary).get("element_colors", {})
	return Color.from_string(String(colors.get(element, "#ffffff")), Color.WHITE)


## Element of the crystal that calls `unit_id` ("" if none does).
func unit_element(unit_id: String) -> String:
	for entry: Dictionary in crystals():
		for pick: Variant in entry.get("units", []):
			if pick is Dictionary and String((pick as Dictionary).get("unit", "")) == unit_id:
				return String(entry.get("element", ""))
	return ""


## R1 = 1 … R5 = 5.
func rarity_rank(rarity: String) -> int:
	return maxi(rarity.trim_prefix("r").to_int(), 1)


## Music while a boss is on the field.
func boss_music() -> String:
	return String(_waves().get("boss_music", ""))


func part_count() -> int:
	return _list("parts").size()


## Wave number inside its part (1 = first) and how many the part has.
func wave_in_part() -> Vector2i:
	var parts: Array[Dictionary] = _list("parts")
	if parts.is_empty():
		return Vector2i.ONE
	var place: Vector3i = wave_place()
	return Vector2i(place.y + 1, (parts[place.x].get("waves", []) as Array).size())


func is_boss_wave() -> bool:
	var at: Vector2i = wave_in_part()
	return wave > 0 and at.x == at.y


func _wave_entry() -> Dictionary:
	var parts: Array[Dictionary] = _list("parts")
	if parts.is_empty() or wave <= 0:
		return {}
	var place: Vector3i = wave_place()
	var waves: Array = parts[place.x].get("waves", [])
	return waves[place.y] if place.y < waves.size() and waves[place.y] is Dictionary else {}


## The enemy's numbers in the current wave: base values × part_*_growth^part (part 0 = first)
## × loop_factor^loop (coins × reward_loop_factor^loop, + relics). `shiny`: shiny_coins times the coins.
func enemy_stats(type_id: String, shiny: bool = false) -> Dictionary:
	var stats: Dictionary = (_enemies().get(type_id, {}) as Dictionary).duplicate()
	var place: Vector3i = wave_place()
	var loop: float = float(place.z)
	var part: float = float(place.x)
	var waves: Dictionary = _waves()
	var strength: float = pow(float(waves.get("loop_factor", 1)), loop)
	stats.id = type_id
	stats.hp = maxi(int(round(float(stats.get("hp", 1)) * strength * pow(float(waves.get("part_hp_growth", 1)), part))), 1)
	stats.damage = maxi(int(round(float(stats.get("damage", 1)) * strength * pow(float(waves.get("part_damage_growth", 1)), part))), 0)
	var reward: float = float(stats.get("coins", 1)) * pow(float(waves.get("reward_loop_factor", 1)), loop) \
			* pow(float(waves.get("part_coin_growth", 1)), part)
	stats.coins = maxi(int(round(reward)), 1) + int(_relic_sum("coins", ""))
	if shiny:
		stats.coins *= int(_waves().get("shiny_coins", 5))
	stats.shiny = shiny
	stats.range = float(stats.get("range", _waves().get("enemy_range", 14.0)))
	return stats


func roll_shiny_enemy() -> bool:
	return randf() < float(_waves().get("shiny_chance", 0.0))


func damage_castle(amount: int) -> bool:
	if amount <= 0 or is_castle_down():
		return false
	castle_hp = maxi(castle_hp - amount, 0)
	castle_changed.emit(castle_hp, castle_max_hp())
	return is_castle_down()


func is_castle_down() -> bool:
	return castle_hp <= 0


## An enemy died: coins, mastery, quests; a boss also drops a relic.
func enemy_killed(stats: Dictionary) -> void:
	run_kills += 1
	add_mastery(_scaled_mastery("per_kill"))
	var amount: int = int(stats.get("coins", 0))
	run_coins += amount
	add_coins(amount)
	quest_event("kill", String(stats.get("kind", stats.get("id", ""))))
	if bool(stats.get("elite", false)):
		quest_event("kill", "elite")
		var place: Vector3i = wave_place()
		if place.x + 1 > parts_beaten:
			parts_beaten = place.x + 1
			run_parts.append(place.x)
			save_meta()
			part_beaten.emit(place.x)
		var id: String = grant_relic()
		if not id.is_empty():
			relic_found.emit(id)


## The boss's chest relic (chest_relic) goes into the collection (and a free slot) at once, so it
## is never lost; the game shows it when the chest is opened. "" = none left for chests.
func grant_relic() -> String:
	var id: String = chest_relic()
	if id.is_empty():
		return ""
	owned_relics.append(id)
	run_relics.append(id)
	equip_relic(id)
	save_meta()
	return id


## A crystal was broken open.
func crystal_opened() -> void:
	add_mastery(_scaled_mastery("per_open"))
	quest_event("open", "")


## A unit appeared (with its rarity). Returns true if it is new in the collection (gives mastery).
func unit_summoned(unit_id: String, rarity: String = "r1") -> bool:
	quest_event("summon", rarity)
	if discovered.has(unit_id) or not _units().has(unit_id):
		return false
	discovered.append(unit_id)
	run_new_units.append(unit_id)
	add_mastery(int(_mastery_data().get("per_discovery", 0)))
	return true


## A wave is beaten (the next comes after `pause`): mastery; saved.
func wave_cleared() -> void:
	add_mastery(_scaled_mastery("per_wave"))
	save_meta()


## Coins after every run: base + upgrades + finished quests.
func income() -> int:
	return int(_waves().get("income", 0)) + int(_bonus_add("income"))


## Most crystal coins one can have: the base, + crystal_coins per finished quest, + the mastery
## "Kristallbeutel". After every run the supply is full again.
func crystal_coin_max() -> int:
	var from_quests: int = 0
	for quest: Dictionary in quests():
		if quests_done.has(String(quest.get("id", ""))):
			from_quests += int(quest.get("crystal_coins", 0))
	var shop: Dictionary = _data.get("shop", {})
	return int(shop.get("crystal_coins_max", 1)) + from_quests + int(_bonus_add("crystal_coin_max")) \
			+ int(shop.get("crystal_coins_per_part", 0)) * parts_beaten


## How much more mastery kills, waves and crystals give in the current part: 1 + part_growth per part
## (and per part of every loop), so later parts are worth it (costs grow x2 per level).
func mastery_part_factor() -> float:
	if wave <= 0:
		return 1.0
	var place: Vector3i = wave_place()
	return 1.0 + float(_mastery_data().get("part_growth", 0.0)) * float(place.x + place.z * part_count())


func _scaled_mastery(key: String) -> int:
	return int(round(float(_mastery_data().get(key, 0)) * mastery_part_factor()))


## Mastery comes at once (× mastery_gain, fractions add up); run_mastery counts this run's.
func add_mastery(amount: int) -> void:
	if amount <= 0:
		return
	_mastery_rest += float(amount) * _bonus_factor("mastery_gain")
	var whole: int = int(_mastery_rest)
	_mastery_rest -= float(whole)
	mastery += whole
	run_mastery += whole


## The run ended at a boss with `left` (0..1) of its life: remembered as progress against it.
func note_boss(name: String, left: float) -> void:
	var part: String = String(_list("parts")[wave_place().x].get("dungeon", "")) if part_count() > 0 else ""
	run_boss_name = name
	run_boss_percent = clampi(int(ceil(left * 100.0)), 1, 100)
	run_boss_record = run_boss_percent < int(boss_best.get(part, 101))
	if run_boss_record:
		boss_best[part] = run_boss_percent


## The smithy fell: income paid, best wave, new offers, saved. Returns the run's mastery.
func end_run() -> int:
	best_wave = maxi(best_wave, wave)
	add_coins(income())
	crystal_coins = crystal_coin_max()
	crystal_coins_changed.emit(crystal_coins)
	rerolls_this_phase = 0
	roll_offers()
	save_meta()
	return run_mastery


# --- Quests ------------------------------------------------------------------------

func quests() -> Array[Dictionary]:
	return _list("quests")


func quest_count(id: String) -> int:
	return quest_progress.get(id, 0)


func is_quest_done(id: String) -> bool:
	return quests_done.has(id)


## Something happened (`kind`: kill/open/summon/day, `target`: enemy id, "elite", rarity ...).
## `reached`: for "day" the value reached, otherwise +1. Finished quests pay at once.
func quest_event(kind: String, target: String, reached: int = -1) -> void:
	for quest: Dictionary in quests():
		var id: String = String(quest.get("id", ""))
		if quests_done.has(id) or String(quest.get("kind", "")) != kind:
			continue
		var wanted: String = String(quest.get("target", ""))
		if not wanted.is_empty() and wanted != target:
			continue
		quest_progress[id] = maxi(quest_count(id), reached) if reached >= 0 else quest_count(id) + 1
		if quest_count(id) >= int(quest.get("count", 1)):
			quests_done.append(id)
			run_quests.append(id)
			add_mastery(int(quest.get("mastery", 0)))
			quest_completed.emit(quest)


# --- Collection --------------------------------------------------------------------

## All units of the JSON (id -> entry), in file order.
func all_units() -> Dictionary:
	return _units()


func unit_level(unit_id: String) -> int:
	return unit_levels.get(unit_id, 0)


func unit_upgrade_cost(unit_id: String) -> int:
	var data: Dictionary = _data.get("unit_upgrade", {})
	if not discovered.has(unit_id) or unit_level(unit_id) >= int(data.get("max_level", 0)):
		return -1
	return int(round(float(data.get("cost", 1)) * pow(float(data.get("cost_factor", 1)), float(unit_level(unit_id)))))


func buy_unit_upgrade(unit_id: String) -> bool:
	var cost: int = unit_upgrade_cost(unit_id)
	if cost < 0 or mastery < cost:
		return false
	mastery -= cost
	unit_levels[unit_id] = unit_level(unit_id) + 1
	save_meta()
	return true


func unit_max_level() -> int:
	return int((_data.get("unit_upgrade", {}) as Dictionary).get("max_level", 0))


# --- Buildings ---------------------------------------------------------------------

## Seconds between two tavern crystals, -1 = no tavern.
func tavern_interval() -> float:
	var level: int = int(_bonus_add("tavern"))
	if level <= 0:
		return -1.0
	var tavern: Dictionary = _data.get("tavern", {})
	return maxf(float(tavern.get("interval", 20)) - float(tavern.get("step", 0)) * float(level - 1), 3.0)


## A random crystal id among the ones in the shop (unlocked, not filtered out; shop, tavern).
func random_crystal() -> String:
	var open: Array[String] = shop_crystals()
	return open[randi() % open.size()] if not open.is_empty() else ""


## The unlocked crystals the shop and the tavern hand out: all but the filtered ones. If the filter
## left fewer than shop.min_crystals, it is ignored.
func shop_crystals() -> Array[String]:
	var open: Array[String] = []
	var kept: Array[String] = []
	for entry: Dictionary in crystals():
		var id: String = String(entry.get("id", ""))
		if is_crystal_unlocked(id):
			open.append(id)
			if not crystal_filter.has(id):
				kept.append(id)
	return kept if kept.size() >= mini(min_shop_crystals(), open.size()) else open


## At least this many different crystals stay in the shop (filter).
func min_shop_crystals() -> int:
	return int((_data.get("shop", {}) as Dictionary).get("min_crystals", 4))


func is_crystal_filtered(id: String) -> bool:
	return crystal_filter.has(id)


## The filter may only take a crystal out while more than min_shop_crystals stay.
func can_filter_crystal(id: String) -> bool:
	return is_crystal_unlocked(id) and not crystal_filter.has(id) and shop_crystals().size() > min_shop_crystals()


## Takes `id` out of the shop (`filtered`) or lets it back in. Returns false if not allowed.
func set_crystal_filtered(id: String, filtered: bool) -> bool:
	if filtered == crystal_filter.has(id):
		return false
	if filtered:
		if not can_filter_crystal(id):
			return false
		crystal_filter.append(id)
	else:
		crystal_filter.erase(id)
	save_meta()
	return true


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


# --- Smithy and hammer -------------------------------------------------------------

func castle_max_hp() -> int:
	return maxi(int(round((float(_data.get("castle_hp", 1)) + _bonus_add("castle_hp")) * _bonus_factor("castle_hp"))), 1)


## Base + adds, × upgrade factors, × hammer_part_growth^part of the part being played (between runs:
## the part the next run starts in) and × loop_factor^loop like the enemies: the hammer keeps up.
func hammer_damage() -> int:
	var base: float = float((_data.get("hammer", {}) as Dictionary).get("damage", 1)) + _bonus_add("hammer_damage")
	var place: Vector3i = wave_place() if wave > 0 else Vector3i(start_part(), 0, 0)
	var growth: float = pow(float(_waves().get("hammer_part_growth", 1.0)), float(place.x)) \
			* pow(float(_waves().get("loop_factor", 1)), float(place.z))
	return maxi(int(round(base * _bonus_factor("hammer_damage") * growth)), 1)


func hammer_radius() -> float:
	return float((_data.get("hammer", {}) as Dictionary).get("radius", 18)) * _bonus_factor("hammer_radius")


func hammer_interval() -> float:
	return maxf(float((_data.get("hammer", {}) as Dictionary).get("interval", 1.0)) / _bonus_factor("hammer_speed"), 0.1)


## Damage factor of every third blow (relic), 1 = none.
func hammer_third_factor() -> float:
	return _relic_product("hammer_third", "")


# --- Shop --------------------------------------------------------------------------

func crystals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in _data.get("crystals", []):
		if entry is Dictionary:
			result.append(entry)
	return result


func crystal(id: String) -> Dictionary:
	for entry: Dictionary in crystals():
		if String(entry.get("id", "")) == id:
			return entry
	return {}


func crystal_price(id: String) -> int:
	return int(crystal(id).get("price", 0))


## The coin-tree node of the crystal path that unlocks `id` ("" = open from the start).
func crystal_unlock_upgrade(id: String) -> String:
	for entry: Dictionary in upgrades():
		if String(entry.get("stat", "")) == "crystal" and String(entry.get("crystal", "")) == id:
			return String(entry.get("id", ""))
	return ""


## In the shop: no node on the crystal path, or that node is bought.
func is_crystal_unlocked(id: String) -> bool:
	if crystal(id).is_empty():
		return false
	var node: String = crystal_unlock_upgrade(id)
	return node.is_empty() or upgrade_level(node) >= 1


## Life and damage factor of the crystal's units (×2 per step on the ladder).
func crystal_power(id: String) -> float:
	return float(crystal(id).get("power", 1.0))


## The power of the crystal that calls `unit_id` (1 if none does).
func unit_power(unit_id: String) -> float:
	for entry: Dictionary in crystals():
		for member: Variant in entry.get("units", []):
			if member is Dictionary and String(member.get("unit", "")) == unit_id:
				return float(entry.get("power", 1.0))
	return 1.0


func offer_count() -> int:
	return int((_data.get("shop", {}) as Dictionary).get("offers", 4)) + int(_bonus_add("offers"))


## New random offers (crystals may repeat); the first is always a pack, the others sometimes; a pack
## is mixed (bundle_size different crystals) with mixed_chance once that many are in the shop; some
## are special offers (discount). Rarely a relic for coins (relic_offer).
func roll_offers() -> void:
	offers.clear()
	offer_discounts.clear()
	offer_bundles.clear()
	offer_contents.clear()
	var shop: Dictionary = _data.get("shop", {})
	var size: int = maxi(int(shop.get("bundle_size", 1)), 1)
	var pool: Array[String] = shop_crystals()
	for i in offer_count():
		var id: String = random_crystal()
		if id.is_empty():
			break
		var bundle: bool = i == 0 or randf() < float(shop.get("bundle_chance", 0.0))
		var contents: Array[String] = [id]
		if bundle:
			contents.clear()
			if pool.size() >= size and randf() < float(shop.get("mixed_chance", 0.0)):
				var mixed: Array[String] = pool.duplicate()
				mixed.shuffle()
				contents = mixed.slice(0, size)
			else:
				for n in size:
					contents.append(id)
		set_offer(i, contents, randf() < float(shop.get("discount_chance", 0.0)))
	relic_offer = ""
	if randf() < float(shop.get("relic_chance", 0.0)):
		var buyable: Array[String] = shop_relics()
		if not buyable.is_empty():
			relic_offer = buyable[randi() % buyable.size()]


## Puts offer `index` (one crystal id, or several for a pack) into the shop (also tests).
func set_offer(index: int, contents: Array, discount: bool = false) -> void:
	while offers.size() <= index:
		offers.append("")
		offer_discounts.append(false)
		offer_bundles.append(false)
		offer_contents.append([])
	offers[index] = String(contents[0]) if not contents.is_empty() else ""
	offer_contents[index] = contents.map(func(id: Variant) -> String: return String(id))
	offer_bundles[index] = contents.size() > 1
	offer_discounts[index] = discount


## A pack costs this many single crystals (of bundle_size).
func bundle_price() -> float:
	return float((_data.get("shop", {}) as Dictionary).get("bundle_price", 1.0))


## How many crystals the offer gives (a pack: bundle_size).
func offer_amount(index: int) -> int:
	return maxi(offer_crystals(index).size(), 1)


## The crystal ids of the offer (one, or a pack), [] when sold.
func offer_crystals(index: int) -> Array[String]:
	var result: Array[String] = []
	if index < 0 or index >= offers.size() or offers[index].is_empty():
		return result
	for id: Variant in offer_contents[index]:
		result.append(String(id))
	return result


## A pack of different crystals.
func is_offer_mixed(index: int) -> bool:
	var ids: Array[String] = offer_crystals(index)
	return ids.size() > 1 and ids.any(func(id: String) -> bool: return id != ids[0])


## What the offer costs now: the crystals' fixed prices (a pack: bundle_price of bundle_size, rounded
## down, so it is always cheaper than the crystals one by one, even on special offer), less the
## discount on a special offer.
func offer_price(index: int) -> int:
	var ids: Array[String] = offer_crystals(index)
	if ids.is_empty():
		return -1
	var price: int = 0
	for id: String in ids:
		price += crystal_price(id)
	if offer_bundles[index]:
		price = maxi(int(floor(float(price) * bundle_price() / float(ids.size()))), 1)
	if offer_discounts[index]:
		price = maxi(int(round(float(price) * (1.0 - float((_data.get("shop", {}) as Dictionary).get("discount", 0.0))))), 1)
	return price


## Hammer hits to break the crystal (crystal hp, less the "Kristallbrecher" mastery).
func crystal_hits(id: String) -> int:
	return maxi(int(crystal(id).get("hp", 1)) + int(_bonus_add("crystal_hits")), 1)


func reroll_cost() -> int:
	var free: int = int(_bonus_add("free_reroll"))
	if rerolls_this_phase < free:
		return 0
	var shop: Dictionary = _data.get("shop", {})
	return int(shop.get("reroll_cost", 1)) + int(shop.get("reroll_step", 0)) * (rerolls_this_phase - free)


func reroll() -> bool:
	var cost: int = reroll_cost()
	if coins < cost:
		return false
	coins -= cost
	rerolls_this_phase += 1
	roll_offers()
	coins_changed.emit(coins)
	return true


func can_buy_offer(index: int) -> bool:
	return offer_price(index) > 0 and crystal_coins >= offer_price(index)


## Buys the offer: the crystal waits for the next wave, the offer is sold out.
func buy_offer(index: int) -> bool:
	if not can_buy_offer(index):
		return false
	crystal_coins -= offer_price(index)
	crystal_stock.append_array(offer_crystals(index))
	offers[index] = ""
	crystal_coins_changed.emit(crystal_coins)
	save_meta()
	return true


## The wave starts: the bought crystals go onto the field.
func take_crystal_stock() -> Array[String]:
	var taken: Array[String] = crystal_stock.duplicate()
	crystal_stock.clear()
	save_meta()
	return taken


# --- Units -------------------------------------------------------------------------

## How many units a crystal calls: min, then each further one up to max with extra_chance (1 unit,
## with 30 % a second), + relics of its element.
func roll_unit_count(crystal_id: String) -> int:
	var entry: Dictionary = crystal(crystal_id)
	var count: int = int(entry.get("min", 1))
	for i in maxi(int(entry.get("max", 1)) - count, 0):
		if randf() < float(entry.get("extra_chance", 1.0)):
			count += 1
	return count + int(_relic_sum("count", String(entry.get("element", ""))))


## A random unit of the crystal by its chances (crystals[].units, e.g. 80 / 19 / 1 %).
func roll_unit(crystal_id: String) -> String:
	var ids: Array[String] = []
	var weights: Array[float] = []
	for entry: Variant in crystal(crystal_id).get("units", []):
		if entry is Dictionary:
			ids.append(String(entry.get("unit", "")))
			weights.append(float(entry.get("chance", 0)))
	return _weighted(ids, weights)


## Chance (percent) of each unit of the crystal: [[unit id, chance], ...].
func crystal_unit_chances(crystal_id: String) -> Array:
	var result: Array = []
	for entry: Variant in crystal(crystal_id).get("units", []):
		if entry is Dictionary:
			result.append([String(entry.get("unit", "")), float(entry.get("chance", 0))])
	return result


## Luck level for rarities: mastery "Glückskristalle" + relics, at most the last rarity_odds row.
func rarity_luck() -> int:
	var rows: int = (_data.get("rarity_odds", [[100]]) as Array).size()
	return clampi(int(_bonus_add("rarity_luck") + _relic_sum("rarity_luck", "")), 0, rows - 1)


## Chances (percent) of r1, r2 ... at the current luck.
func rarity_chances() -> Array:
	var rows: Array = _data.get("rarity_odds", [[100]])
	return rows[rarity_luck()] if not rows.is_empty() else [100]


## A random rarity id ("r1" ...) at the current luck.
func roll_rarity() -> String:
	var ids: Array[String] = []
	var weights: Array[float] = []
	var chances: Array = rarity_chances()
	for i in chances.size():
		ids.append("r%d" % (i + 1))
		weights.append(float(chances[i]))
	return _weighted(ids, weights) if not ids.is_empty() else "r1"


func roll_giant() -> bool:
	return randf() < float(_data.get("giant_chance", 0.0)) + _relic_sum("giant_chance", "")


func roll_shiny_unit() -> bool:
	return randf() < float(_data.get("shiny_unit_chance", 0.0))


## The unit's numbers with rarity ("r1" ...), giant, shiny, relics, upgrades and mastery applied.
func unit_stats(unit_id: String, rarity: String = "r1", giant: bool = false, shiny: bool = false) -> Dictionary:
	var stats: Dictionary = (_units().get(unit_id, {}) as Dictionary).duplicate()
	if stats.is_empty():
		return stats
	var element: String = String(stats.get("element", ""))
	var power: float = float(_rarity(rarity).get("factor", 1.0)) \
			* unit_power(unit_id) \
			* _bonus_factor("unit_all") \
			* pow(float((_data.get("unit_upgrade", {}) as Dictionary).get("factor", 1.0)), float(unit_level(unit_id)))
	if giant:
		power *= float(_data.get("giant_factor", 1.0))
	if shiny:
		power *= float(_data.get("shiny_unit_factor", 1.0))
	stats.id = unit_id
	stats.hp = maxi(int(round(float(stats.get("hp", 1)) * power * _bonus_factor("unit_hp") * _relic_product("hp", element))), 1)
	stats.damage = maxi(int(round(float(stats.get("damage", 1)) * power * _bonus_factor("unit_damage") * _relic_product("damage", element))), 1)
	stats.attack_interval = maxf(float(stats.get("attack_interval", 1.0)) / _bonus_factor("unit_speed")
			/ _relic_product("attack_speed", element), 0.1)
	stats.giant = giant
	stats.shiny = shiny
	stats.rarity = rarity
	stats.rarity_color = Color.from_string(String(_rarity(rarity).get("color", "#ffffff")), Color.WHITE)
	return stats


func level_kills() -> int:
	return maxi(int(_data.get("level_kills", 3)), 1)


func level_factor() -> float:
	return float(_data.get("level_factor", 1.0))


func max_level() -> int:
	return int(_data.get("max_level", 1))


func rarity_name(rarity: String) -> String:
	return String(_rarity(rarity).get("name", rarity))


# --- Run upgrades (coins) and mastery upgrades -------------------------------------

func upgrades() -> Array[Dictionary]:
	return _list("upgrades")


func mastery_upgrades() -> Array[Dictionary]:
	return _list("mastery_upgrades")


func upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0) if not _find(upgrades(), id).is_empty() else mastery_levels.get(id, 0)


## Price of the next level, -1 = maxed or unknown. Run upgrades cost coins, mastery ones mastery.
func upgrade_cost(id: String) -> int:
	var entry: Dictionary = _find(upgrades(), id)
	if entry.is_empty():
		entry = _find(mastery_upgrades(), id)
	if entry.is_empty() or upgrade_level(id) >= int(entry.get("max_level", 1)):
		return -1
	return int(round(float(entry.get("cost", 1)) * pow(float(entry.get("cost_factor", 1)), float(upgrade_level(id)))))


## The JSON entry of a coin or mastery upgrade.
func upgrade_entry(id: String) -> Dictionary:
	var entry: Dictionary = _find(upgrades(), id)
	return entry if not entry.is_empty() else _find(mastery_upgrades(), id)


## Shown in the tree: no `requires`, or that upgrade has at least one level.
func is_upgrade_visible(id: String) -> bool:
	var needed: String = String(upgrade_entry(id).get("requires", ""))
	return needed.is_empty() or upgrade_level(needed) >= 1


## Can be bought once enough parts are beaten (`unlock_part`).
func is_upgrade_unlocked(id: String) -> bool:
	return int(upgrade_entry(id).get("unlock_part", 0)) <= parts_beaten


func is_mastery_upgrade(id: String) -> bool:
	return not _find(mastery_upgrades(), id).is_empty()


func can_buy_upgrade(id: String) -> bool:
	var cost: int = upgrade_cost(id)
	return cost > 0 and is_upgrade_visible(id) and is_upgrade_unlocked(id) \
			and (mastery if is_mastery_upgrade(id) else coins) >= cost


func buy_upgrade(id: String) -> bool:
	if not can_buy_upgrade(id):
		return false
	var cost: int = upgrade_cost(id)
	var old_max: int = castle_max_hp()
	if is_mastery_upgrade(id):
		mastery -= cost
		mastery_levels[id] = upgrade_level(id) + 1
		_fit_relic_slots()
		save_meta()
	else:
		coins -= cost
		upgrade_levels[id] = upgrade_level(id) + 1
		coins_changed.emit(coins)
		save_meta()
	# More life: the smithy gains what was added.
	castle_hp = mini(castle_hp + maxi(castle_max_hp() - old_max, 0), castle_max_hp())
	castle_changed.emit(castle_hp, castle_max_hp())
	return true


# --- Relics ------------------------------------------------------------------------

func relics() -> Array[Dictionary]:
	return _list("relics")


func relic(id: String) -> Dictionary:
	return _find(relics(), id) if not id.is_empty() else {}


func relic_slot_count() -> int:
	return maxi(int(_data.get("relic_slots", 1)) + int(_bonus_add("relic_slots")), 1)


func has_relic(id: String) -> bool:
	return owned_relics.has(id)


func is_relic_equipped(id: String) -> bool:
	return not id.is_empty() and relic_slots.has(id)


## The relic's tier (relics[].tier, 1 if none).
func relic_tier(id: String) -> int:
	return maxi(int(relic(id).get("tier", 1)), 1)


## The relic_tiers entry of `tier` (1 = first): from_part, chest, price.
func relic_tier_entry(tier: int) -> Dictionary:
	var tiers: Array = _data.get("relic_tiers", [])
	return tiers[tier - 1] if tier >= 1 and tier <= tiers.size() and tiers[tier - 1] is Dictionary else {}


## A tier is open from its part on (from_part, 1 = first part).
func is_relic_tier_open(tier: int, part_number: int) -> bool:
	var entry: Dictionary = relic_tier_entry(tier)
	return not entry.is_empty() and int(entry.get("from_part", 1)) <= part_number


func _owned_in_tier(tier: int) -> int:
	return owned_relics.filter(func(id: String) -> bool: return relic_tier(id) == tier).size()


## The relic in a boss's chest: a random one not owned yet of the highest tier open in this part
## whose chest share (`chest`) is not used up; the rest of a tier only comes from the shop. "" = none.
func chest_relic() -> String:
	var part_number: int = wave_place().x + 1 if wave > 0 else 1
	var tiers: Array = _data.get("relic_tiers", [])
	for tier in range(tiers.size(), 0, -1):
		if not is_relic_tier_open(tier, part_number) or _owned_in_tier(tier) >= int(relic_tier_entry(tier).get("chest", 0)):
			continue
		var free: Array[String] = []
		for entry: Dictionary in relics():
			var id: String = String(entry.get("id", ""))
			if relic_tier(id) == tier and not has_relic(id):
				free.append(id)
		if not free.is_empty():
			return free[randi() % free.size()]
	return ""


## Relics the shop may offer: not owned yet, of a tier open by the parts beaten so far.
func shop_relics() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in relics():
		var id: String = String(entry.get("id", ""))
		if not has_relic(id) and is_relic_tier_open(relic_tier(id), parts_beaten + 1):
			result.append(id)
	return result


## Coins for a relic in the shop (its tier's price).
func relic_price(id: String) -> int:
	return int(relic_tier_entry(relic_tier(id)).get("price", 0))


func can_buy_relic_offer() -> bool:
	return not relic_offer.is_empty() and relic_price(relic_offer) > 0 and coins >= relic_price(relic_offer)


## Buys the relic of the shop: it is owned (in a free slot if there is one), the offer is gone.
func buy_relic_offer() -> bool:
	if not can_buy_relic_offer():
		return false
	coins -= relic_price(relic_offer)
	owned_relics.append(relic_offer)
	equip_relic(relic_offer)
	relic_offer = ""
	coins_changed.emit(coins)
	save_meta()
	return true


## Up to 3 relics not owned yet.
func roll_relic_choice() -> Array[String]:
	var free: Array[String] = []
	for entry: Dictionary in relics():
		if not has_relic(String(entry.id)):
			free.append(String(entry.id))
	free.shuffle()
	return free.slice(0, 3)


## Takes one relic of the current choice; it goes into a free slot if there is one.
func choose_relic(id: String) -> bool:
	if not relic_choice.has(id):
		return false
	relic_choice.clear()
	owned_relics.append(id)
	equip_relic(id)
	save_meta()
	return true


func equip_relic(id: String) -> bool:
	if not has_relic(id) or is_relic_equipped(id):
		return false
	var free: int = relic_slots.find("")
	if free < 0:
		return false
	relic_slots[free] = id
	save_meta()
	return true


func unequip_slot(index: int) -> void:
	if index >= 0 and index < relic_slots.size():
		relic_slots[index] = ""
		save_meta()


# --- Meta save ---------------------------------------------------------------------

func to_meta() -> Dictionary:
	return {"mastery": mastery, "mastery_levels": mastery_levels.duplicate(), "owned_relics": owned_relics.duplicate(),
			"relic_slots": relic_slots.duplicate(), "best_wave": best_wave, "discovered": discovered.duplicate(),
			"unit_levels": unit_levels.duplicate(), "quest_progress": quest_progress.duplicate(),
			"quests_done": quests_done.duplicate(), "coins": coins, "upgrade_levels": upgrade_levels.duplicate(),
			"crystal_stock": crystal_stock.duplicate(), "parts_beaten": parts_beaten, "crystal_coins": crystal_coins,
			"boss_best": boss_best.duplicate(), "crystal_filter": crystal_filter.duplicate(), "version": META_VERSION}


func apply_meta(data: Dictionary) -> void:
	mastery = int(data.get("mastery", 0))
	coins = maxi(int(data.get("coins", _data.get("start_coins", 0))), 0)
	parts_beaten = clampi(int(data.get("parts_beaten", 0)), 0, part_count())
	boss_best.clear()
	# Before version 3 the keys were places in the old order of the parts: those records are dropped
	# (only the "so weit wie nie" note, nothing to play).
	if int(data.get("version", 1)) >= 3:
		var bests: Dictionary = data.get("boss_best", {})
		for key: Variant in bests:
			boss_best[String(key)] = int(bests[key])
	upgrade_levels.clear()
	var coin_levels: Dictionary = data.get("upgrade_levels", {})
	for id: String in coin_levels:
		if not _find(upgrades(), id).is_empty():
			upgrade_levels[id] = int(coin_levels[id])
	crystal_stock.clear()
	for id: Variant in data.get("crystal_stock", []):
		if not crystal(String(id)).is_empty():
			crystal_stock.append(String(id))
	mastery_levels.clear()
	var levels: Dictionary = data.get("mastery_levels", {})
	for id: String in levels:
		if not _find(mastery_upgrades(), id).is_empty():
			mastery_levels[id] = int(levels[id])
	owned_relics.clear()
	for id: Variant in data.get("owned_relics", []):
		if not relic(String(id)).is_empty():
			owned_relics.append(String(id))
	relic_slots.clear()
	for id: Variant in data.get("relic_slots", []):
		relic_slots.append(String(id) if owned_relics.has(String(id)) else "")
	best_wave = int(data.get("best_wave", 0))
	discovered.clear()
	for id: Variant in data.get("discovered", []):
		var unit_id: String = RENAMED_UNITS.get(String(id), String(id))
		if _units().has(unit_id) and not discovered.has(unit_id):
			discovered.append(unit_id)
	unit_levels.clear()
	var levels_of_units: Dictionary = data.get("unit_levels", {})
	for id: String in levels_of_units:
		var unit_id: String = RENAMED_UNITS.get(id, id)
		if _units().has(unit_id):
			unit_levels[unit_id] = maxi(int(levels_of_units[id]), unit_levels.get(unit_id, 0))
	quest_progress.clear()
	var progress: Dictionary = data.get("quest_progress", {})
	for id: String in progress:
		quest_progress[id] = int(progress[id])
	quests_done.clear()
	for id: Variant in data.get("quests_done", []):
		if not _find(quests(), String(id)).is_empty():
			quests_done.append(String(id))
	_fit_relic_slots()
	crystal_filter.clear()
	for id: Variant in data.get("crystal_filter", []):
		if not crystal(String(id)).is_empty() and not crystal_filter.has(String(id)):
			crystal_filter.append(String(id))
	var saved_coins: int = int(data.get("crystal_coins", 1))
	if int(data.get("version", 1)) < 2:
		saved_coins *= 10
		_grant_old_crystals()
	# Last: the maximum needs the quests, mastery levels and parts loaded above.
	crystal_coins = clampi(saved_coins, 0, crystal_coin_max())


## Saves from before the crystal path (version 1): crystals came by beaten parts (poison 2, ice 5,
## dark 10, wind 20). Whoever had one gets the path up to it; crystal coins were ×10 smaller.
func _grant_old_crystals() -> void:
	var last: int = -1
	var path: Array[Dictionary] = upgrades().filter(func(e: Dictionary) -> bool: return String(e.get("stat", "")) == "crystal")
	for i in path.size():
		var old_part: int = int(OLD_CRYSTAL_PARTS.get(String(path[i].get("crystal", "")), -1))
		if old_part >= 0 and old_part <= parts_beaten:
			last = i
	for i in last + 1:
		upgrade_levels[String(path[i].id)] = 1


func save_meta() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_meta(), "\t"))


func load_meta() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		apply_meta(parsed)
		castle_hp = castle_max_hp()
		roll_offers()


# --- Helpers -----------------------------------------------------------------------

func _fit_relic_slots() -> void:
	var count: int = relic_slot_count()
	while relic_slots.size() < count:
		relic_slots.append("")
	if relic_slots.size() > count:
		relic_slots.resize(count)


## Product of `factor`^level over run and mastery upgrades with this stat.
func _bonus_factor(stat: String) -> float:
	var result: float = 1.0
	for entry: Dictionary in upgrades() + mastery_upgrades():
		if String(entry.get("stat", "")) == stat:
			result *= pow(float(entry.get("factor", 1.0)), float(upgrade_level(String(entry.id))))
	return result


func _bonus_add(stat: String) -> float:
	var result: float = 0.0
	for entry: Dictionary in upgrades() + mastery_upgrades():
		if String(entry.get("stat", "")) == stat:
			result += float(entry.get("add", 0)) * float(upgrade_level(String(entry.id)))
	return result


## Equipped relics that act on `element` ("" = only relics without element).
func _active_relics(element: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in relic_slots:
		var entry: Dictionary = relic(id)
		var relic_element: String = String(entry.get("element", ""))
		if not entry.is_empty() and (relic_element.is_empty() or relic_element == element):
			result.append(entry)
	return result


func _relic_product(field: String, element: String) -> float:
	var result: float = 1.0
	for entry: Dictionary in _active_relics(element):
		result *= float(entry.get(field, 1.0))
	return result


func _relic_sum(field: String, element: String) -> float:
	var result: float = 0.0
	for entry: Dictionary in _active_relics(element):
		result += float(entry.get(field, 0.0))
	return result


func _weighted(ids: Array[String], weights: Array[float]) -> String:
	if ids.is_empty():
		return ""
	var total: float = 0.0
	for weight in weights:
		total += weight
	var roll: float = randf() * total
	for i in ids.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ids[i]
	return ids[ids.size() - 1]


func _list(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in _data.get(key, []):
		if entry is Dictionary:
			result.append(entry)
	return result


func _find(entries: Array[Dictionary], id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			return entry
	return {}


func _waves() -> Dictionary:
	return _data.get("waves", {})


func _enemies() -> Dictionary:
	return _without_comment(_data.get("enemies", {}))


func _units() -> Dictionary:
	return _without_comment(_data.get("units", {}))


func _rarity(id: String) -> Dictionary:
	return (_data.get("rarities", {}) as Dictionary).get(id, {})


func _mastery_data() -> Dictionary:
	return _data.get("mastery", {})


## The JSON maps carry a "_comment" string; only the entries.
func _without_comment(map: Dictionary) -> Dictionary:
	if not map.has("_comment"):
		return map
	var result: Dictionary = map.duplicate()
	result.erase("_comment")
	return result
