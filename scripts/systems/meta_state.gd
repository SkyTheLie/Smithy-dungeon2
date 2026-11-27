class_name MetaState
extends RefCounted
## What the player owns between runs, in one save per slot (A, B, C: user://save_<slot>.cfg).
## There is only this one save per slot, no saving by hand: it is written at the end of every day
## (end_run, after the night the merchant may steal), and after every buy and sale in the shop.
##   box    ALL gold at home lies in the small money box (Dose). It never goes into the dungeon
##          (there gold only comes from selling loot in the dungeon shop; what is left of it comes
##          home into the box). Buying, the lever and skills pay from it, selling to Egon fills it.
##          Safe up to data/meta.json money_box.limit; above it the merchant may steal on every
##          new day (roll_theft): spend it or risk it.
##   stash  the inventory at home: loot brought home (from the bag) and gear bought from Egon.
##   table, pulls_today, equipment, tutorial_done  Egon's shop (see below).
##   day    one run = one day.
## Rules about this gold live here (deposit / withdraw check the amounts); screens only call them.
## The chosen slot is a setting (user://settings.cfg, "save" / "slot"); the slot choice after the
## language choice sets it (SlotSelect).

const SLOTS: PackedStringArray = ["a", "b", "c"]
const SECTION: String = "meta"
const SETTINGS_SECTION: String = "save"

static var _config: ConfigFile
## The slot in use ("" = not read from the settings yet).
static var _slot: String = ""


static func slot() -> String:
	if _slot.is_empty():
		_slot = String(WindowLayout.get_setting(SETTINGS_SECTION, "slot", SLOTS[0]))
		if not SLOTS.has(_slot):
			_slot = SLOTS[0]
	return _slot


## Uses slot `id` from now on (unknown ids are ignored) and remembers it in the settings.
static func set_slot(id: String) -> void:
	if not SLOTS.has(id):
		return
	_slot = id
	_config = null
	WindowLayout.set_setting(SETTINGS_SECTION, "slot", id)


static func path_of(id: String) -> String:
	return "user://save_%s.cfg" % id


## true if slot `id` (default: the slot in use) holds a game ("Weiter" in the main menu).
static func has_save(id: String = "") -> bool:
	return FileAccess.file_exists(path_of(slot() if id.is_empty() else id))


## {day, gold} of slot `id` without switching to it (the slot choice shows it); {} = empty.
static func peek(id: String) -> Dictionary:
	if not has_save(id):
		return {}
	var config := ConfigFile.new()
	config.load(path_of(id))
	var gold: int = int(config.get_value(SECTION, "purse", 0)) + int(config.get_value(SECTION, "box", 0))
	for entry: Variant in config.get_value(SECTION, "stash", []):
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) == Bag.GOLD:
			gold += int((entry as Dictionary).get("count", 0))
	return {"day": int(config.get_value(SECTION, "day", 1)), "gold": gold}


## Deletes the save of slot `id` for good (the slot choice asks first). false if it had none.
static func delete_slot(id: String) -> bool:
	if not SLOTS.has(id) or not has_save(id):
		return false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path_of(id)))
	if id == slot():
		_config = null
	return true


## "Neues Spiel": the slot in use starts over (day 1, nothing owned) and is saved at once.
static func start_new() -> void:
	_config = ConfigFile.new()
	_write("day", 1)
	_write("level", 0)
	_write("skill_points", int(Skills.levels().get("start_points", 0)))
	_save()


# --- Player level, EXP, skills (Skills, data/levels.json, data/skills.json) ----------

## The player level: a new game starts at 0, level 1 brings the first skill point.
static func level() -> int:
	return int(_read("level", 0))


## EXP collected towards the next level.
static func exp_points() -> int:
	return int(_read("exp", 0))


static func skill_points() -> int:
	return int(_read("skill_points", int(Skills.levels().get("start_points", 0))))


## Adds the EXP of a run; every level reached gives skill points. Returns the levels gained.
static func add_exp(amount: int) -> int:
	if amount <= 0:
		return 0
	var current: int = exp_points() + amount
	var lvl: int = level()
	var gained: int = 0
	while Skills.exp_to_next(lvl) > 0 and current >= Skills.exp_to_next(lvl):
		current -= Skills.exp_to_next(lvl)
		lvl += 1
		gained += 1
	if Skills.exp_to_next(lvl) == 0:
		current = 0
	_write("level", lvl)
	_write("exp", current)
	_write("skill_points", skill_points() + gained * int(Skills.levels().get("points_per_level", 1)))
	_save()
	return gained


static func skill_level(id: String) -> int:
	return int((_read("skills", {}) as Dictionary).get(id, 0))


## Learns the next level of skill `id`: pays gold (box) and skill points. false (nothing
## changes) if Skills.problem says why not.
static func buy_skill(id: String) -> bool:
	if not Skills.problem(id).is_empty():
		return false
	var gold: int = Skills.next_gold(id)
	var points: int = Skills.next_points(id)
	_write("box", box() - gold)
	_write("skill_points", skill_points() - points)
	var learned: Dictionary = (_read("skills", {}) as Dictionary).duplicate()
	learned[id] = skill_level(id) + 1
	_write("skills", learned)
	_save()
	return true


## The relic places on the hero now: "relic_1" and one more per skill level (data/skills.json
## relic_slots, at most relic_slots_max).
static func relic_slot_names() -> Array[String]:
	var count: int = clampi(1 + int(Skills.bonus("relic_slots")), 1, int(Content.get_file("skills").get("relic_slots_max", 3)))
	var names: Array[String] = []
	for i in count:
		names.append("relic_%d" % (i + 1))
	return names


## All gold at home (one source). Callers check amounts before taking from it.
static func box() -> int:
	return int(_read("box", 0))


## Older saves kept gold outside the box (a number "purse", a coin bag "gold" in the inventory):
## it goes into the box once, when the save is read.
static func _move_old_gold() -> void:
	var gold: int = int(_config.get_value(SECTION, "purse", 0))
	var own: Array = []
	for entry: Variant in _config.get_value(SECTION, "stash", []):
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) == Bag.GOLD and not ShopGoods.is_relic(entry):
			gold += int((entry as Dictionary).get("count", 0))
		else:
			own.append(entry)
	if gold <= 0 and not _config.has_section_key(SECTION, "purse"):
		return
	_config.set_value(SECTION, "stash", own)
	_config.set_value(SECTION, "box", int(_config.get_value(SECTION, "box", 0)) + maxi(0, gold))
	_config.erase_section_key(SECTION, "purse")


static func day() -> int:
	return int(_read("day", 1))


## Gold the merchant took on the last new day (0 = nothing), for his excuse in the shop.
static func last_theft() -> int:
	return int(_read("last_theft", 0))


## Safe in the box: data/meta.json money_box.limit, plus the skill Größere Dose (box_limit).
static func box_limit() -> int:
	return int(Content.meta("money_box").get("limit", 200)) + int(Skills.bonus("box_limit"))


# --- Dungeons (data/dungeons.json) -------------------------------------------------

## Dungeons won in this save slot (ids, each once).
static func won_dungeons() -> Array:
	return _read("won_dungeons", [])


static func has_won(id: String) -> bool:
	return won_dungeons().has(id)


## Dungeon `id` was won: remembered (opens what needs it: dungeons, materials) and saved.
static func win_dungeon(id: String) -> void:
	if id.is_empty() or has_won(id):
		return
	var list: Array = won_dungeons().duplicate()
	list.append(id)
	_write("won_dungeons", list)
	_save()


## A dungeons.json / shop.json "unlock" in this save slot: {"dungeon": id} = that dungeon won,
## {"level": n} = player level n; both may stand together, {} is always met.
static func meets(unlock: Dictionary) -> bool:
	if unlock.has("dungeon") and not has_won(String(unlock["dungeon"])):
		return false
	return level() >= int(unlock.get("level", 0))


## Dungeon `id` can be entered (its dungeons.json "unlock" is met).
static func is_dungeon_open(id: String) -> bool:
	return Content.dungeons().has(id) and meets((Content.dungeons()[id] as Dictionary).get("unlock", {}))


static func stash() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Variant in _read("stash", []):
		if entry is Dictionary:
			list.append((entry as Dictionary).duplicate())
	return list


# --- Egon's shop: table, inventory (stash), equipment -----------------------------
# The inventory is the stash: loot {id, count} and gear {id, count 1, rarity} in one list.
# Rules about prices and goods: ShopGoods. Every change is saved at once (gold moves).

## Egon's table: ShopGoods.empty_table() places, each {} or {id, rarity, price}. Empty before the
## first pull of the lever.
static func table() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Variant in _read("table", []):
		list.append((entry as Dictionary).duplicate() if entry is Dictionary else {})
	return list


## Pulls of the lever today (the price grows with them, a new day starts at 0).
static func pulls_today() -> int:
	return int(_read("pulls_today", 0))


static func lever_price() -> int:
	return ShopGoods.roll_price(pulls_today())


## The lever: pays lever_price() from the box and lays new goods on the table. false (nothing
## changes) without enough gold.
static func pull_lever(rng: RandomNumberGenerator) -> bool:
	var price: int = lever_price()
	if price > box():
		return false
	_write("box", box() - price)
	_write("table", ShopGoods.roll(rng, pulls_today()))
	_write("pulls_today", pulls_today() + 1)
	_save()
	return true


## Buys table place `index` into the inventory. `free` = Egon's gift (tutorial). false for an
## empty place or too little gold.
static func buy(index: int, free: bool = false) -> bool:
	var list: Array[Dictionary] = table()
	if index < 0 or index >= list.size() or list[index].is_empty():
		return false
	var piece: Dictionary = list[index]
	var price: int = 0 if free else int(piece.get("price", 0))
	if price < 0 or price > box():
		return false
	list[index] = {}
	_write("table", list)
	var own: Array[Dictionary] = stash()
	own.append(_owned(piece))
	_write("stash", own)
	_write("box", box() - price)
	_save()
	return true


## A piece as it lies in the inventory: gear {id, count 1, rarity}, relic {id, count 1, relic, left}.
static func _owned(piece: Dictionary) -> Dictionary:
	if ShopGoods.is_relic(piece):
		return {"id": String(piece["id"]), "count": 1, "relic": true, "left": int(piece.get("left", -1))}
	return {"id": String(piece["id"]), "count": 1, "rarity": int(piece.get("rarity", 1))}


## As it is worn: the same without the count.
static func _worn(piece: Dictionary) -> Dictionary:
	var worn: Dictionary = _owned(piece)
	worn.erase("count")
	return worn


## The slot a piece goes into: the first free relic place for relics (all full: the first one),
## else gear.json "slot" ("" = cannot be worn).
static func slot_of(piece: Dictionary) -> String:
	if ShopGoods.is_relic(piece):
		var worn: Dictionary = equipment()
		for name: String in relic_slot_names():
			if not worn.has(name):
				return name
		return relic_slot_names()[0]
	return String(Content.gear_item(String(piece.get("id", ""))).get("slot", ""))


## Sells inventory place `index` (the whole stack) to Egon: ShopGoods.sell_price goes into the
## box. Returns the gold (0 = nothing sold).
static func sell(index: int) -> int:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size() or String(own[index].get("id", "")) == Bag.GOLD:
		return 0
	var gold: int = ShopGoods.sell_price(own[index])
	own.remove_at(index)
	_write("stash", own)
	_write("box", box() + gold)
	_save()
	return gold


## The hero's equipment: slot (data/gear.json slots) -> {id, rarity}.
static func equipment() -> Dictionary:
	var result: Dictionary = {}
	var saved: Variant = _read("equipment", {})
	if saved is Dictionary:
		for slot: String in saved:
			if saved[slot] is Dictionary and not (saved[slot] as Dictionary).is_empty():
				# Older saves had one place "relic".
				result["relic_1" if slot == "relic" else slot] = (saved[slot] as Dictionary).duplicate()
	return result


## Puts inventory place `index` on (gear only); what was in that slot goes back into the
## inventory. false for loot, an empty place or unknown gear.
static func equip(index: int) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var entry: Dictionary = own[index]
	var slot: String = slot_of(entry)
	if slot.is_empty() or not (Content.gear_slots().has(slot) or relic_slot_names().has(slot)):
		return false
	var worn: Dictionary = equipment()
	own.remove_at(index)
	if worn.has(slot):
		own.insert(index, _owned(worn[slot]))
	worn[slot] = _worn(entry)
	_write("stash", own)
	_write("equipment", worn)
	_save()
	return true


## Takes `slot` off into the inventory. false if nothing is worn there.
static func unequip(slot: String) -> bool:
	var worn: Dictionary = equipment()
	if not worn.has(slot):
		return false
	var old: Dictionary = worn[slot]
	worn.erase(slot)
	var own: Array[Dictionary] = stash()
	own.append(_owned(old))
	_write("stash", own)
	_write("equipment", worn)
	_save()
	return true


## The character of the next run (data/characters.json id): the class of the weapon on the hero
## (gear.json "class"); without a weapon, or while that character is still locked (Progress),
## the first character (Magier).
static func run_character() -> String:
	var weapon: Dictionary = equipment().get("weapon", {})
	var id: String = String(Content.gear_item(String(weapon.get("id", ""))).get("class", ""))
	var characters: Dictionary = Content.characters()
	if characters.has(id) and Progress.meets((characters[id] as Dictionary).get("unlock", {})):
		return id
	return String(characters.keys().front()) if not characters.is_empty() else ""


## Egon's start money in his tour (shop.json tutorial.gold) into the box. Amounts <= 0: nothing.
static func gift_gold(amount: int) -> void:
	if amount <= 0:
		return
	_write("box", box() + amount)
	_save()


## true once Egon showed the shop (first visit after the intro).
static func tutorial_done() -> bool:
	return bool(_read("tutorial_done", false))


## The first visit: Egon pulls the lever for free (the tutorial goods, data/shop.json tutorial).
static func lay_tutorial_table() -> void:
	_write("table", ShopGoods.tutorial_table())
	_write("pulls_today", pulls_today() + 1)
	_save()


static func finish_tutorial() -> void:
	_write("tutorial_done", true)
	_save()


## A run is over (a new day begins): `coins` go into the box, `kept` (bag places
## {id, count}) into the stash (its gold into the box), then the merchant may help himself from
## the box.
## Death: coins 0 and only the safe places. Returns the gold stolen from the box.
static func end_run(coins: int, kept: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	var gold_home: int = maxi(0, coins)
	var list: Array[Dictionary] = stash()
	for entry: Dictionary in kept:
		var id: String = String(entry.get("id", ""))
		var count: int = int(entry.get("count", 0))
		if id.is_empty() or count <= 0:
			continue
		# The gold of the bag goes into the box, not into the inventory.
		if id == Bag.GOLD:
			gold_home += count
			continue
		var merged: bool = false
		for own: Dictionary in list:
			if String(own["id"]) == id and not own.has("rarity"):
				own["count"] = int(own["count"]) + count
				merged = true
				break
		if not merged:
			list.append({"id": id, "count": count})
	_write("stash", list)
	if gold_home > 0:
		_write("box", box() + gold_home)
	_wear_relic()
	_write("day", day() + 1)
	_write("pulls_today", 0)
	var stolen: int = roll_theft(rng)
	_write("box", box() - stolen)
	_write("last_theft", stolen)
	_save()
	return stolen


## A run with the relic on: one run less; at 0 it is broken and gone (broken_relic = its id, for
## Egon's comment). Relics for ever (left -1) stay.
static func _wear_relic() -> void:
	var worn: Dictionary = equipment()
	_write("broken_relic", "")
	for slot: String in worn.keys():
		var relic: Dictionary = worn[slot]
		if not ShopGoods.is_relic(relic) or int(relic.get("left", -1)) < 0:
			continue
		relic["left"] = int(relic["left"]) - 1
		if int(relic["left"]) <= 0:
			worn.erase(slot)
			_write("broken_relic", String(relic["id"]))
		else:
			worn[slot] = relic
	_write("equipment", worn)


## The relic that broke at the end of the last run ("" = none).
static func broken_relic() -> String:
	return String(_read("broken_relic", ""))


## Egon said it: no more comment about it.
static func clear_broken_relic() -> void:
	if not broken_relic().is_empty():
		_write("broken_relic", "")
		_save()


## How much the merchant steals from the box today (does not take it; end_run does).
## Nothing up to the limit. Above it: steal_all_chance = everything, steal_part_chance = part of
## the gold above the limit (steal_part_share of it), else nothing.
static func roll_theft(rng: RandomNumberGenerator) -> int:
	var gold: int = box()
	var excess: int = gold - box_limit()
	if excess <= 0:
		return 0
	var rules: Dictionary = Content.meta("money_box")
	var roll: float = rng.randf()
	var all_chance: float = float(rules.get("steal_all_chance", 0.01))
	if roll < all_chance:
		return gold
	if roll < all_chance + float(rules.get("steal_part_chance", 0.2)):
		var share: Array = rules.get("steal_part_share", [0.3, 1.0])
		var part: float = rng.randf_range(float(share[0]), float(share[1]))
		return clampi(ceili(excess * part), 1, excess)
	return 0


static func _read(key: String, default: Variant) -> Variant:
	return _load().get_value(SECTION, key, default)


static func _write(key: String, value: Variant) -> void:
	_load().set_value(SECTION, key, value)


static func _save() -> void:
	_load().save(path_of(slot()))


static func _load() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(path_of(slot()))
		_move_old_gold()
	return _config


## Forgets the loaded file; the next call reads it again (tests).
static func reload() -> void:
	_config = null
	_slot = ""
