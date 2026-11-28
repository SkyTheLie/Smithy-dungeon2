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
##   stash  the stash at home (a grid, stash_grid): loot brought home, gear, relics, potions and
##          backpacks; every piece {id, count, x, y, rot} (ItemGrid).
##   table, pulls_today, equipment, tutorial_done  Egon's shop (see below).
##   backpacks  the backpacks attached to the bag (BagLayout placements, attach_backpack).
##   guide_done  the guide of the first run is over (DungeonGuide).
##   bag    the bag brought home ({id, count, x, y, rot}): loot stays in it between runs
##          (bag_places, Bag.restore at the start of a run); dragged into the stash in the shop.
##   day    one run = one day.
##   deaths, potions_unlocked  deaths in the dungeon; after the second one Egon shows the
##          potions (potion_tour_due), then potions come on the table and the potion place shows.
##          A potion on the hero lies in "potion_1" of the equipment (potion_slot_names).
##   rope_done, ruby_delivered  Egon's first errand (data/meta.json ruby_quest): the first boss
##          ends with a rope out of the dungeon (rope_due), then Egon takes the ruby (deliver_ruby).
## Rules about this gold live here (deposit / withdraw check the amounts); screens only call them.
## The chosen slot is a setting (user://settings.cfg, "save" / "slot"); the slot choice after the
## language choice sets it (SlotSelect).

const SLOTS: PackedStringArray = ["a", "b", "c"]
const SECTION: String = "meta"
const SETTINGS_SECTION: String = "save"
## From this rarity on a purchase at Egon's counts as rare (unlock "rare_buys").
const RARE_BUY: int = 3

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
	# A new backpack comes into the stash (attached in the shop, tab Inventar).
	var backpack: String = String((Skills.data(id).get("effect", {}) as Dictionary).get("backpack", ""))
	if not backpack.is_empty():
		_give_to_stash({"id": backpack, "count": 1, "backpack": true})
	_save()
	return true


# --- Backpacks (data/backpacks.json, BagLayout) --------------------------------------
# A backpack is a piece in the stash ({id, backpack: true}) until it is attached to the bag
# (Inventar tab in the shop); then it is a placement {"id", "x", "y", "rot"} in "backpacks" and
# not in the stash any more. Each backpack id can be attached once.

## The backpacks attached to the bag (an invalid save gives none).
static func backpacks() -> Array:
	var list: Array = []
	for entry: Variant in _read("backpacks", []):
		if entry is Dictionary:
			list.append((entry as Dictionary).duplicate())
	return list if BagLayout.is_valid(list) else []


## How many backpacks may be attached: meta.json bag.backpack_slots, one more per level of the
## skill Rucksack-Riemen (skills.json effect backpack_slots).
static func backpack_limit() -> int:
	return maxi(0, int(Content.meta("bag").get("backpack_slots", 1)) + int(Skills.bonus("backpack_slots")))


## true while one more backpack may be attached (backpack_limit not reached).
static func can_attach_backpack() -> bool:
	return backpacks().size() < backpack_limit()


## Attaches the backpack lying on stash place `index` with its top left on `at` (turned `rot`).
## false (nothing changes) for something else, at the backpack_limit, or if the bag would not be allowed
## (BagLayout.is_valid: touching, nothing covered, inside the board, not the same backpack twice).
static func attach_backpack(index: int, at: Vector2i, rot: bool) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size() or not ShopGoods.is_backpack(own[index]) or not can_attach_backpack():
		return false
	var id: String = String(own[index]["id"])
	var next: Array = backpacks()
	next.append({"id": id, "x": at.x, "y": at.y, "rot": rot})
	if not BagLayout.is_valid(next):
		return false
	own.remove_at(index)
	_write_stash(own)
	_write("backpacks", next)
	_save()
	return true


## Attaches stash place `index` where it fits first (BagLayout.first_spot). false if nowhere.
static func attach_backpack_anywhere(index: int) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size() or not ShopGoods.is_backpack(own[index]):
		return false
	var spot: Dictionary = BagLayout.first_spot(backpacks(), String(own[index]["id"]))
	return not spot.is_empty() and attach_backpack(index, Vector2i(int(spot["x"]), int(spot["y"])), bool(spot["rot"]))


## Moves attached backpack `id` to `at` (turned `rot`). false if it is not attached or the bag
## would not be allowed.
static func place_backpack(id: String, at: Vector2i, rot: bool) -> bool:
	if backpack_in_use(id):
		return false
	var before: Array = backpacks()
	if BagLayout.without(before, id).size() == before.size():
		return false
	var next: Array = BagLayout.with_moved(before, id, at, rot)
	if not BagLayout.is_valid(next):
		return false
	_write("backpacks", next)
	_save()
	return true


## Takes attached backpack `id` off into the stash: on `cell` (turned `rot`), or anywhere for
## cell (-1, -1). false if it is not attached, others hang only on it, or there is no room.
static func detach_backpack(id: String, cell: Vector2i = Vector2i(-1, -1), rot: bool = false) -> bool:
	if backpack_in_use(id):
		return false
	var before: Array = backpacks()
	var next: Array = BagLayout.without(before, id)
	if next.size() == before.size() or not BagLayout.is_valid(next):
		return false
	var own: Array[Dictionary] = stash()
	var piece: Dictionary = {"id": id, "count": 1, "backpack": true}
	if cell == Vector2i(-1, -1):
		var spot: Dictionary = ItemGrid.free_spot(own, stash_grid(), piece)
		if spot.is_empty():
			return false
		piece.merge(spot, true)
	elif ItemGrid.fits(own, stash_grid(), piece, cell, rot):
		piece.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	else:
		return false
	own.append(piece)
	_write_stash(own)
	_write("backpacks", next)
	_save()
	return true


## Puts `piece` into the stash (first free spot; no room: beside the grid).
static func _give_to_stash(piece: Dictionary) -> void:
	var own: Array[Dictionary] = stash()
	own.append(piece)
	_write_stash(own)


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


## A dungeons.json / shop.json "unlock" in this save slot: {"quest": id} = Egon's quest done,
## {"dungeon": id} = that dungeon won,
## {"level": n} = player level n; both may stand together, {} is always met.
static func meets(unlock: Dictionary) -> bool:
	if unlock.has("dungeon") and not has_won(String(unlock["dungeon"])):
		return false
	if unlock.has("quest") and not quest_done(String(unlock["quest"])):
		return false
	return level() >= int(unlock.get("level", 0))


## Dungeon `id` can be entered (its dungeons.json "unlock" is met).
static func is_dungeon_open(id: String) -> bool:
	return Content.dungeons().has(id) and meets((Content.dungeons()[id] as Dictionary).get("unlock", {}))


## The stash (Egon's shop, data/meta.json "stash"): a grid of pieces (ItemGrid), every piece
## {id, count, x, y, rot, …}; a piece without "x" has no room in the grid and lies beside it.
## Loot that older saves stacked ({id, count 5}) becomes single pieces. Always settled: every piece
## that can lie in the grid lies there.
static func stash() -> Array[Dictionary]:
	var list: Array = []
	for entry: Variant in _read("stash", []):
		if not entry is Dictionary:
			continue
		var piece: Dictionary = (entry as Dictionary).duplicate()
		var count: int = int(piece.get("count", 1))
		if _is_loot(piece) and count > 1:
			piece["count"] = 1
			for i in count:
				var single: Dictionary = piece.duplicate()
				if i > 0:
					single.erase("x")
					single.erase("y")
				list.append(single)
		else:
			list.append(piece)
	ItemGrid.settle(list, stash_grid())
	var typed: Array[Dictionary] = []
	for piece: Variant in list:
		typed.append(piece)
	return typed


## Width × height of the stash grid (data/meta.json stash, plus the columns from trades).
static func stash_grid() -> Vector2i:
	var rules: Dictionary = Content.meta("stash")
	return Vector2i(maxi(1, int(rules.get("columns", 5))) + stash_extra_columns(), maxi(1, int(rules.get("rows", 4))))


## Columns the stash gained by trades (data/trades.json get.stash_columns).
static func stash_extra_columns() -> int:
	return maxi(0, int(_read("stash_extra_columns", 0)))


## Ids of the once-only trades already done in this save.
static func trades_done() -> Array:
	return (_read("trades_done", []) as Array).duplicate()


static func trade_done(id: String) -> bool:
	return trades_done().has(id)


static func _is_loot(piece: Dictionary) -> bool:
	return not (piece.has("rarity") or ShopGoods.is_relic(piece) or ShopGoods.is_potion(piece) or ShopGoods.is_backpack(piece) or ShopGoods.is_container(piece))


static func _write_stash(list: Array) -> void:
	_write("stash", ItemGrid.settle(list, stash_grid()))


## Drag and drop in the stash: piece `index` goes with its top left onto `cell`, turned when
## `rot` (also a piece that had no room). On exactly one other piece the two swap if the other one
## fits where the dragged one was. false = nothing changed.
static func move_in_stash(index: int, cell: Vector2i, rot: bool) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var piece: Dictionary = own[index]
	var span: Vector2i = ShopGoods.piece_size(piece)
	if span.x == span.y:
		rot = false
	var grid: Vector2i = stash_grid()
	if ItemGrid.fits(own, grid, piece, cell, rot, [index]):
		piece["x"] = cell.x
		piece["y"] = cell.y
		piece["rot"] = rot
		_write_stash(own)
		_save()
		return true
	var under: Array[int] = []
	for c: Vector2i in ItemGrid.cells_of(piece, cell, rot):
		if not Rect2i(Vector2i.ZERO, grid).has_point(c):
			return false
		var other: int = ItemGrid.index_at(own, c)
		if other >= 0 and other != index and not under.has(other):
			under.append(other)
	if under.size() != 1 or not ItemGrid.is_placed(piece):
		return false
	var target: Dictionary = own[under[0]]
	var old := Vector2i(int(piece["x"]), int(piece["y"]))
	var old_rot: bool = bool(piece.get("rot", false))
	piece["x"] = cell.x
	piece["y"] = cell.y
	piece["rot"] = rot
	for turn: bool in [bool(target.get("rot", false)), not bool(target.get("rot", false))]:
		if ItemGrid.fits(own, grid, target, old, turn, [under[0]]):
			target["x"] = old.x
			target["y"] = old.y
			target["rot"] = turn
			_write_stash(own)
			_save()
			return true
	piece["x"] = old.x
	piece["y"] = old.y
	piece["rot"] = old_rot
	return false


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
	Progress.add_count("rerolls")
	return true


## Buys table place `index` into the stash (first free spot, or on `cell` turned `rot` when it
## was dragged there). `free` = Egon's gift (tutorial). false for an empty place, too little gold
## or no room on `cell`.
static func buy(index: int, free: bool = false, cell: Vector2i = Vector2i(-1, -1), rot: bool = false) -> bool:
	var list: Array[Dictionary] = table()
	if index < 0 or index >= list.size() or list[index].is_empty():
		return false
	var piece: Dictionary = list[index]
	var price: int = 0 if free else int(piece.get("price", 0))
	if price < 0 or price > box():
		return false
	var owned: Dictionary = _owned(piece)
	var own: Array[Dictionary] = stash()
	# Dragged onto the stash: it must fit where it was dropped.
	if cell != Vector2i(-1, -1):
		if not ItemGrid.fits(own, stash_grid(), owned, cell, rot):
			return false
		owned.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	list[index] = {}
	_write("table", list)
	own.append(owned)
	_write_stash(own)
	_write("box", box() - price)
	_save()
	if not free:
		Progress.add_count("egon_buys")
		var rarity: int = ShopGoods.relic_rarity(String(piece["id"])) if ShopGoods.is_relic(piece) else int(piece.get("rarity", 1))
		if rarity >= RARE_BUY:
			Progress.add_count("rare_buys")
	return true


## A piece as it lies in the inventory: gear {id, count 1, rarity}, relic {id, count 1, relic, left},
## potion {id, count 1, potion}, container {id, count 1, container, uid, items} (a new uid if it
## has none: the shop finds an open container by it).
static func _owned(piece: Dictionary) -> Dictionary:
	if ShopGoods.is_relic(piece):
		return {"id": String(piece["id"]), "count": 1, "relic": true, "left": int(piece.get("left", -1))}
	if ShopGoods.is_potion(piece):
		return {"id": String(piece["id"]), "count": 1, "potion": true}
	if ShopGoods.is_backpack(piece):
		return {"id": String(piece["id"]), "count": 1, "backpack": true}
	if ShopGoods.is_container(piece):
		var uid: int = int(piece.get("uid", 0))
		if uid <= 0:
			uid = int(_read("next_uid", 1))
			_write("next_uid", uid + 1)
		return {"id": String(piece["id"]), "count": 1, "container": true, "uid": uid, "items": (piece.get("items", []) as Array).duplicate(true)}
	var gear: Dictionary = {"id": String(piece["id"]), "count": 1, "rarity": int(piece.get("rarity", 1))}
	if not String(piece.get("type", "")).is_empty():
		gear["type"] = String(piece["type"])
	return gear


## As it is worn: the same without the count.
static func _worn(piece: Dictionary) -> Dictionary:
	var worn: Dictionary = _owned(piece)
	worn.erase("count")
	return worn


## The slot a piece goes into: the first free relic place for relics, the first free potion place
## for potions (all full: the first one), else gear.json "slot" ("" = cannot be worn).
static func slot_of(piece: Dictionary) -> String:
	if ShopGoods.is_relic(piece):
		return _first_free(relic_slot_names())
	if ShopGoods.is_potion(piece):
		return _first_free(potion_slot_names()) if potions_unlocked() else ""
	if ShopGoods.is_backpack(piece):
		return ""
	return String(Content.gear_item(String(piece.get("id", ""))).get("slot", ""))


static func _first_free(names: Array[String]) -> String:
	if names.is_empty():
		return ""
	var worn: Dictionary = equipment()
	for name: String in names:
		if not worn.has(name):
			return name
	return names[0]


# --- Potions (data/potions.json) -------------------------------------------------------

## The potion places on the hero: "potion_1" … (potions.json slots).
static func potion_slot_names() -> Array[String]:
	var names: Array[String] = []
	for i in maxi(0, int(Content.potions().get("slots", 1))):
		names.append("potion_%d" % (i + 1))
	return names


## Deaths in the dungeon in this save slot (fleeing does not count).
static func deaths() -> int:
	return int(_read("deaths", 0))


## A death in the dungeon: counted and saved.
static func add_death() -> void:
	_write("deaths", deaths() + 1)
	_save()


## true once Egon showed the potions (then potions come on the table and the potion place shows).
static func potions_unlocked() -> bool:
	return bool(_read("potions_unlocked", false))


## true if Egon's potion show is due: died often enough (potions.json unlock_deaths), not shown yet.
static func potion_tour_due() -> bool:
	return tutorial_done() and not potions_unlocked() and deaths() >= int(Content.potions().get("unlock_deaths", 2))


## Egon's potion show: he turns the table once (free, not a pull of the day): only the potion
## he gives away lies on it (ShopGoods.potion_table).
static func lay_potion_table() -> void:
	_write("table", ShopGoods.potion_table())
	_save()


static func unlock_potions() -> void:
	_write("potions_unlocked", true)
	_save()


## The potions on the hero: [{slot, id}, …] in place order.
static func worn_potions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var worn: Dictionary = equipment()
	for place: String in potion_slot_names():
		if worn.has(place) and ShopGoods.is_potion(worn[place]):
			list.append({"slot": place, "id": String((worn[place] as Dictionary).get("id", ""))})
	return list


## A potion was drunk in the dungeon: it is gone from potion place `place`. false if none was there.
static func use_potion(place: String) -> bool:
	var worn: Dictionary = equipment()
	if not potion_slot_names().has(place) or not worn.has(place) or not ShopGoods.is_potion(worn[place]):
		return false
	worn.erase(place)
	_write("equipment", worn)
	_save()
	return true


## Sells inventory place `index` (the whole stack) to Egon: ShopGoods.sell_price goes into the
## box. Returns the gold (0 = nothing sold).
static func sell(index: int) -> int:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size() or String(own[index].get("id", "")) == Bag.GOLD:
		return 0
	# Quest stones are not for sale (Egon wants them for his quest); locked pieces neither.
	if Quests.is_stone(String(own[index].get("id", ""))) or bool(own[index].get("locked", false)):
		return 0
	var gold: int = ShopGoods.sell_price(own[index])
	# A container with something in it is not for sale (sell_price 0).
	if gold <= 0 and ShopGoods.is_container(own[index]):
		return 0
	_remember_sold(own[index], gold)
	own.remove_at(index)
	_write_stash(own)
	_write("box", box() + gold)
	_save()
	return gold


# --- Equipment sets (save what is worn, put it on again with one click) -----------------

const GEAR_SETS: int = 3


## The gear of set `number` (1..GEAR_SETS): {slot: "id|rarity|type"}; {} = not saved yet.
static func gear_set(number: int) -> Dictionary:
	var sets: Variant = _read("gear_sets", {})
	if not sets is Dictionary:
		return {}
	return ((sets as Dictionary).get(str(number), {}) as Dictionary).duplicate()


## Saves the gear worn now (not relics and potions: they are used up) as set `number`.
static func save_gear_set(number: int) -> void:
	if number < 1 or number > GEAR_SETS:
		return
	var worn: Dictionary = equipment()
	var chosen: Dictionary = {}
	for slot: String in Content.gear_slots():
		if worn.has(slot):
			chosen[slot] = _piece_key(worn[slot])
	var sets: Variant = _read("gear_sets", {})
	var all: Dictionary = (sets as Dictionary).duplicate() if sets is Dictionary else {}
	all[str(number)] = chosen
	_write("gear_sets", all)
	_save()


## Puts on set `number`: every saved piece that lies in the stash goes onto its place (what was
## worn there goes into the stash). Returns how many pieces were changed (0 = nothing to do).
static func wear_gear_set(number: int) -> int:
	var chosen: Dictionary = gear_set(number)
	var changed: int = 0
	for slot: String in chosen:
		var worn: Dictionary = equipment()
		if worn.has(slot) and _piece_key(worn[slot]) == String(chosen[slot]):
			continue
		var own: Array[Dictionary] = stash()
		for i in own.size():
			if own[i].has("rarity") and _piece_key(own[i]) == String(chosen[slot]) and slot_of(own[i]) == slot:
				if equip(i, slot):
					changed += 1
				break
	return changed


static func _piece_key(piece: Dictionary) -> String:
	return "%s|%d|%s" % [String(piece.get("id", "")), int(piece.get("rarity", 1)), String(piece.get("type", ""))]


# --- Buying back (Egon's last sales of the day) ------------------------------------------

## How many sales Egon keeps for buying back (the newest first).
const BUY_BACK_PLACES: int = 3


## What was sold today and can be bought back: [{piece, gold}, …], newest first.
static func sold_today() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Variant in _read("sold_today", []):
		if entry is Dictionary:
			list.append((entry as Dictionary).duplicate(true))
	return list


static func _remember_sold(piece: Dictionary, gold: int) -> void:
	var clean: Dictionary = piece.duplicate(true)
	for key: String in ["x", "y", "rot", "locked"]:
		clean.erase(key)
	var list: Array[Dictionary] = sold_today()
	list.push_front({"piece": clean, "gold": gold})
	while list.size() > BUY_BACK_PLACES:
		list.pop_back()
	_write("sold_today", list)


## Buys back sale `index` of today for the same price: into the stash (beside it if no room).
## false if there is no such sale or the box has too little gold.
static func buy_back(index: int) -> bool:
	var list: Array[Dictionary] = sold_today()
	if index < 0 or index >= list.size():
		return false
	var gold: int = int(list[index].get("gold", 0))
	if gold < 0 or gold > box():
		return false
	_write("box", box() - gold)
	var own: Array[Dictionary] = stash()
	own.append(_owned(list[index]["piece"]))
	_write_stash(own)
	list.remove_at(index)
	_write("sold_today", list)
	_save()
	return true


# --- Comfort in the stash: lock, sort -----------------------------------------------------

## Strg+click: locks stash place `index` (never sold, never moved by sorting) or unlocks it.
## Returns the new state.
static func toggle_lock(index: int) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var locked: bool = not bool(own[index].get("locked", false))
	if locked:
		own[index]["locked"] = true
	else:
		own[index].erase("locked")
	_write_stash(own)
	_save()
	return locked


## How the stash is sorted next ("kind", "rarity", "value"), saved with the game.
const SORT_MODES: Array[String] = ["kind", "rarity", "value"]


static func sort_mode() -> String:
	var mode: String = String(_read("sort_mode", "kind"))
	return mode if SORT_MODES.has(mode) else "kind"


static func next_sort_mode() -> void:
	_write("sort_mode", SORT_MODES[(SORT_MODES.find(sort_mode()) + 1) % SORT_MODES.size()])
	_save()


## Packs the stash tightly: locked pieces stay where they are, the others are laid out again
## from the top left, sorted by `mode` (kind: gear, relics, potions, containers, backpacks, loot;
## rarity: rare first; value: what Egon pays, most first). What has no room stays beside it.
static func sort_stash(mode: String = "") -> void:
	if mode.is_empty():
		mode = sort_mode()
	var own: Array[Dictionary] = stash()
	var locked: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for piece: Dictionary in own:
		if bool(piece.get("locked", false)) and ItemGrid.is_placed(piece):
			locked.append(piece)
		else:
			piece.erase("x")
			piece.erase("y")
			piece.erase("rot")
			rest.append(piece)
	rest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _sort_before(a, b, mode))
	var list: Array = []
	list.append_array(locked)
	list.append_array(rest)
	_write_stash(list)
	_save()


static func _sort_before(a: Dictionary, b: Dictionary, mode: String) -> bool:
	var keys_a: Array = _sort_keys(a, mode)
	var keys_b: Array = _sort_keys(b, mode)
	for i in keys_a.size():
		if keys_a[i] != keys_b[i]:
			return keys_a[i] < keys_b[i]
	return false


## Smaller comes first. Bigger pieces first inside the same group (they pack better).
static func _sort_keys(piece: Dictionary, mode: String) -> Array:
	var kind: int = 5
	if ShopGoods.is_relic(piece):
		kind = 1
	elif ShopGoods.is_potion(piece):
		kind = 2
	elif ShopGoods.is_container(piece):
		kind = 3
	elif ShopGoods.is_backpack(piece):
		kind = 4
	elif piece.has("rarity"):
		kind = 0
	var span: Vector2i = ShopGoods.piece_size(piece)
	var rarity: int = -ShopSlot.rarity_of(piece)
	var value: int = -ShopGoods.sell_price(piece)
	var name_key: String = String(piece.get("id", ""))
	match mode:
		"rarity":
			return [rarity, kind, -span.x * span.y, name_key]
		"value":
			return [value, kind, -span.x * span.y, name_key]
	return [kind, -span.x * span.y, rarity, name_key]


# --- Containers in the stash (data/containers.json, rules in ShopGoods) -----------------

## Stash place of the container with `uid`, -1 if there is none.
static func container_index(uid: int) -> int:
	var own: Array[Dictionary] = stash()
	for i in own.size():
		if ShopGoods.is_container(own[i]) and int(own[i].get("uid", 0)) == uid:
			return i
	return -1


## What lies in container `uid` (one piece per place; loot with its count).
static func container_items(uid: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var index: int = container_index(uid)
	if index < 0:
		return list
	for entry: Variant in (stash()[index].get("items", []) as Array):
		if entry is Dictionary:
			list.append((entry as Dictionary).duplicate())
	return list


## true if stash piece `index` may go into container `uid` (its kind, a free place or a stack of
## the same loot with room).
static func container_fits(uid: int, index: int) -> bool:
	var own: Array[Dictionary] = stash()
	var at: int = container_index(uid)
	if at < 0 or index < 0 or index >= own.size() or index == at:
		return false
	return _container_room(own[at], own[index]) != -2


## Where `piece` goes in `box`: the index of a stack of the same loot with room, -1 = a new
## place, -2 = no room or the wrong kind.
static func _container_room(box: Dictionary, piece: Dictionary) -> int:
	var id: String = String(box.get("id", ""))
	if not ShopGoods.container_accepts(id, piece):
		return -2
	var items: Array = box.get("items", [])
	if ShopGoods.kind_of(piece) == "loot":
		for i in items.size():
			var other: Dictionary = items[i]
			if String(other.get("id", "")) == String(piece.get("id", "")) and int(other.get("count", 1)) < ShopGoods.container_stack(id):
				return i
	return -1 if items.size() < ShopGoods.container_slots(id) else -2


## Stash piece `index` into container `uid`. false = nothing changed.
static func container_put(uid: int, index: int) -> bool:
	if not container_fits(uid, index):
		return false
	var own: Array[Dictionary] = stash()
	var box: Dictionary = own[container_index(uid)]
	var piece: Dictionary = own[index]
	var items: Array = (box.get("items", []) as Array).duplicate(true)
	var room: int = _container_room(box, piece)
	if room >= 0:
		items[room]["count"] = int(items[room].get("count", 1)) + 1
	else:
		var stored: Dictionary = _owned(piece)
		for key: String in ["x", "y", "rot"]:
			stored.erase(key)
		items.append(stored)
	box["items"] = items
	own.remove_at(index)
	_write_stash(own)
	_save()
	return true


## One piece of place `slot` of container `uid` back into the stash, on `cell` turned `rot`
## (cell (-1, -1) = anywhere, also under "Kein Platz"). Loot comes out one at a time. false = no
## such piece, or no room on `cell`.
static func container_take(uid: int, slot: int, cell: Vector2i = Vector2i(-1, -1), rot: bool = false) -> bool:
	var own: Array[Dictionary] = stash()
	var at: int = container_index(uid)
	if at < 0:
		return false
	var box: Dictionary = own[at]
	var items: Array = (box.get("items", []) as Array).duplicate(true)
	if slot < 0 or slot >= items.size():
		return false
	var stored: Dictionary = items[slot]
	var piece: Dictionary = stored.duplicate()
	piece["count"] = 1
	if cell != Vector2i(-1, -1):
		if not ItemGrid.fits(own, stash_grid(), piece, cell, rot):
			return false
		piece.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	if int(stored.get("count", 1)) > 1:
		stored["count"] = int(stored["count"]) - 1
	else:
		items.remove_at(slot)
	box["items"] = items
	own.append(piece)
	_write_stash(own)
	_save()
	return true


# --- Egon's exchange (data/trades.json, rules in Trades) -------------------------------

## How much loot `id` is at home: stash (also "Kein Platz"), the bag at home, the containers.
static func home_count(id: String) -> int:
	var total: int = 0
	for piece: Dictionary in stash():
		if ShopGoods.is_container(piece):
			for stored: Variant in piece.get("items", []):
				if stored is Dictionary and String((stored as Dictionary).get("id", "")) == id and _is_loot(stored):
					total += int((stored as Dictionary).get("count", 1))
		elif _is_loot(piece) and String(piece.get("id", "")) == id:
			total += int(piece.get("count", 1))
	return total + _bag_model().count_of(id)


## true when offer `id` is open, its piece exists and everything it costs is at home.
static func can_trade(id: String) -> bool:
	var offer: Dictionary = Trades.find(id)
	if offer.is_empty() or not Trades.is_open(offer) or Trades.is_used_up(offer) or not Trades.gives_something(offer):
		return false
	for cost: Array in Trades.costs(offer):
		if home_count(String(cost[0])) < int(cost[1]):
			return false
	return true


## Exchange offer `id`: its loot goes (first from "Kein Platz", then the stash, the bag, the
## containers), its piece comes into the stash. false = nothing changed.
static func trade(id: String) -> bool:
	if not can_trade(id):
		return false
	var offer: Dictionary = Trades.find(id)
	var own: Array[Dictionary] = stash()
	var bag: Bag = _bag_model()
	for cost: Array in Trades.costs(offer):
		var loot: String = String(cost[0])
		var left: int = int(cost[1])
		# Stash: pieces without room first, then those in the grid.
		for placed: bool in [false, true]:
			for i in range(own.size() - 1, -1, -1):
				if left <= 0:
					break
				var piece: Dictionary = own[i]
				if ItemGrid.is_placed(piece) != placed or not _is_loot(piece) or String(piece.get("id", "")) != loot:
					continue
				var taken: int = mini(left, int(piece.get("count", 1)))
				left -= taken
				piece["count"] = int(piece.get("count", 1)) - taken
				if int(piece["count"]) <= 0:
					own.remove_at(i)
		var from_bag: int = mini(left, bag.count_of(loot))
		if from_bag > 0 and bag.remove(loot, from_bag):
			left -= from_bag
		for piece: Dictionary in own:
			if left <= 0:
				break
			if not ShopGoods.is_container(piece):
				continue
			var items: Array = (piece.get("items", []) as Array).duplicate(true)
			for i in range(items.size() - 1, -1, -1):
				if left <= 0:
					break
				var stored: Dictionary = items[i]
				if String(stored.get("id", "")) != loot or not _is_loot(stored):
					continue
				var taken: int = mini(left, int(stored.get("count", 1)))
				left -= taken
				stored["count"] = int(stored.get("count", 1)) - taken
				if int(stored["count"]) <= 0:
					items.remove_at(i)
			piece["items"] = items
	if Trades.is_once(offer):
		var done: Array = trades_done()
		done.append(id)
		_write("trades_done", done)
	var wider: int = Trades.stash_columns(offer)
	if wider > 0:
		# The grid grows before the stash is written, so pieces without room find a place.
		_write("stash_extra_columns", stash_extra_columns() + wider)
	else:
		var gained: Dictionary = Trades.piece_of(offer)
		own.append(gained if _is_loot(gained) else _owned(gained))
	_write_stash(own)
	_save_bag(bag)
	_save()
	Progress.add_count("trades")
	return true


# --- Egon's quests (data/quests.json, rules in Quests) ---------------------------------

static func quests_done() -> Array:
	return _read("quests_done", [])


static func quest_done(id: String) -> bool:
	return quests_done().has(id)


## Where Egon's shop stands now (data/quests.json locations): where the last quest sent him.
static func location() -> String:
	return String(_read("location", Quests.start()))


## Quests Egon has told about already (he tells each once).
static func quest_announced(id: String) -> bool:
	return (_read("quests_announced", []) as Array).has(id)


static func announce_quest(id: String) -> void:
	var list: Array = (_read("quests_announced", []) as Array).duplicate()
	if not list.has(id):
		list.append(id)
	_write("quests_announced", list)
	_save()


## Hands in the stone on stash place `index`: the quest is done (opens its dungeons), Egon moves
## on (moves_to) and pays its gold into the box. Returns the quest id ("" = nothing handed in:
## not a stone of an open quest).
static func deliver_quest(index: int) -> String:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return ""
	var id: String = Quests.quest_of_stone(String(own[index].get("id", "")))
	if id.is_empty():
		return ""
	own.remove_at(index)
	_write_stash(own)
	var done: Array = quests_done().duplicate()
	done.append(id)
	_write("quests_done", done)
	var target: String = String(Quests.data(id).get("moves_to", ""))
	if not target.is_empty():
		_write("location", target)
	_write("box", box() + maxi(0, int(Quests.data(id).get("gold", 0))))
	_save()
	return id


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


## Puts stash place `index` on; what was in that slot goes back into the stash. `target` = a
## chosen place (dragged onto it): a relic place for relics, a potion place for potions, else
## the gear's own slot. false for loot, an empty place, unknown gear or a wrong place.
static func equip(index: int, target: String = "") -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var entry: Dictionary = own[index]
	var slot: String = slot_of(entry)
	if not target.is_empty():
		var allowed: bool = relic_slot_names().has(target) if ShopGoods.is_relic(entry) 				else (potion_slot_names().has(target) and potions_unlocked()) if ShopGoods.is_potion(entry) 				else target == slot
		if not allowed:
			return false
		slot = target
	if slot.is_empty() or not (Content.gear_slots().has(slot) or relic_slot_names().has(slot) or potion_slot_names().has(slot)):
		return false
	var worn: Dictionary = equipment()
	own.remove_at(index)
	if worn.has(slot):
		# What was worn takes the place of the new piece (if it fits there; else somewhere).
		var back: Dictionary = _owned(worn[slot])
		if ItemGrid.is_placed(entry):
			back["x"] = int(entry["x"])
			back["y"] = int(entry["y"])
			back["rot"] = bool(entry.get("rot", false))
		own.insert(index, back)
	worn[slot] = _worn(entry)
	_write_stash(own)
	_write("equipment", worn)
	_save()
	return true


## Takes `slot` off into the inventory. false if nothing is worn there.
static func unequip(slot: String, cell: Vector2i = Vector2i(-1, -1), rot: bool = false) -> bool:
	var worn: Dictionary = equipment()
	if not worn.has(slot):
		return false
	var old: Dictionary = worn[slot]
	var back: Dictionary = _owned(old)
	var own: Array[Dictionary] = stash()
	# Dragged onto the stash: it must fit there.
	if cell != Vector2i(-1, -1):
		if not ItemGrid.fits(own, stash_grid(), back, cell, rot):
			return false
		back.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	worn.erase(slot)
	own.append(back)
	_write_stash(own)
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


## Admin menu (debug builds): `piece` (ShopGoods.make_piece / make_relic / make_potion) straight
## into the inventory, free. Returns its place (for equip), -1 for an empty piece.
static func give_piece(piece: Dictionary) -> int:
	if String(piece.get("id", "")).is_empty():
		return -1
	var own: Array[Dictionary] = stash()
	own.append(_owned(piece))
	_write_stash(own)
	_save()
	return own.size() - 1


# --- Admin menus (debug builds only: AdminMenu, ShopAdminMenu) -------------------------

## A loot piece {id, count 1} straight into the stash. false for an unknown id.
static func admin_give_loot(id: String) -> bool:
	if Content.material(id).is_empty():
		return false
	_give_to_stash({"id": id, "count": 1})
	_save()
	return true


## The stash is emptied (the bag at home stays).
static func admin_clear_stash() -> void:
	_write("stash", [])
	_save()


## The box holds exactly `amount` gold (negative = 0).
static func admin_set_box(amount: int) -> void:
	_write("box", maxi(0, amount))
	_save()


static func admin_add_skill_points(amount: int) -> void:
	if amount <= 0:
		return
	_write("skill_points", skill_points() + amount)
	_save()


## New goods on the table without paying and without counting a pull.
static func admin_roll_table(rng: RandomNumberGenerator) -> void:
	_write("table", ShopGoods.roll(rng, pulls_today()))
	_save()


## Egon's table without goods.
static func admin_clear_table() -> void:
	_write("table", ShopGoods.empty_table())
	_save()


## The lever is free again (no pulls today).
static func admin_reset_lever() -> void:
	_write("pulls_today", 0)
	_save()


## A new day without a run: day + 1, the lever free again (no theft, the bag stays).
static func admin_next_day() -> void:
	_write("day", day() + 1)
	_write("pulls_today", 0)
	_write("sold_today", [])
	_save()


## Quest `id` counts as done without its stone (opens its dungeons, Egon moves on, pays).
static func admin_finish_quest(id: String) -> bool:
	if Quests.data(id).is_empty() or quest_done(id):
		return false
	var done: Array = quests_done().duplicate()
	done.append(id)
	_write("quests_done", done)
	var target: String = String(Quests.data(id).get("moves_to", ""))
	if not target.is_empty():
		_write("location", target)
	_write("box", box() + maxi(0, int(Quests.data(id).get("gold", 0))))
	_save()
	return true


## Egon's potion show is due at the next visit (died often enough, not shown yet).
static func admin_potion_tour_due() -> void:
	_write("potions_unlocked", false)
	_write("deaths", maxi(deaths(), int(Content.potions().get("unlock_deaths", 2))))
	_write("tutorial_done", true)
	_save()


## Egon has his ruby (the errand is over).
static func admin_ruby_delivered() -> void:
	_write("ruby_delivered", true)
	_write("rope_done", true)
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


## true once the player went through the guide of the very first run (DungeonGuide: walking,
## aiming, shooting, the practice rat, the bag and the safe place).
static func guide_done() -> bool:
	return bool(_read("guide_done", false))


static func finish_guide() -> void:
	_write("guide_done", true)
	_save()


# --- Egon's first errand: the ruby (data/meta.json ruby_quest) ----------------------

## true while the first boss still ends with the rope: not climbed out yet in this save slot,
## and floor `floor_index` of dungeon `dungeon_id` is the one of ruby_quest.
static func rope_due(dungeon_id: String, floor_index: int) -> bool:
	var quest: Dictionary = Content.meta("ruby_quest")
	if quest.is_empty() or rope_done():
		return false
	return dungeon_id == String(quest.get("dungeon", "")) and floor_index == int(quest.get("floor", 0))


## true once the player climbed out at the rope (from then on the boss room is a normal one).
static func rope_done() -> bool:
	return bool(_read("rope_done", false))


static func finish_rope() -> void:
	_write("rope_done", true)
	_save()


## true once Egon has his ruby.
static func ruby_delivered() -> bool:
	return bool(_read("ruby_delivered", false))


## Egon waits for his ruby: not given yet, and the player climbed out at the rope or brought a
## ruby home some other way (e.g. down the trapdoor and out through a ladder).
static func ruby_due() -> bool:
	return not ruby_delivered() and (rope_done() or ruby_index() >= 0)


## Index of the first ruby (ruby_quest "item") in the inventory, -1 if there is none.
static func ruby_index() -> int:
	var wanted: String = String(Content.meta("ruby_quest").get("item", ""))
	var own: Array[Dictionary] = stash()
	for i in own.size():
		if String(own[i].get("id", "")) == wanted and not own[i].has("rarity") and int(own[i].get("count", 0)) > 0:
			return i
	return -1


## Egon takes one ruby out of the inventory and gives ruby_reward() into the stash. false (nothing changes) without one or if he has it.
static func deliver_ruby() -> bool:
	if ruby_delivered():
		return false
	var index: int = ruby_index()
	if index < 0:
		return false
	var own: Array[Dictionary] = stash()
	own[index]["count"] = int(own[index]["count"]) - 1
	if int(own[index]["count"]) <= 0:
		own.remove_at(index)
	var gift: Dictionary = ruby_reward()
	if not gift.is_empty():
		own.append(_owned(gift))
	_write_stash(own)
	_write("ruby_delivered", true)
	_save()
	return true


## Egon's thanks for the ruby (meta.json ruby_quest reward_relic / reward_runs): a relic that holds
## that many runs. {} without one.
static func ruby_reward() -> Dictionary:
	var rules: Dictionary = Content.meta("ruby_quest")
	var id: String = String(rules.get("reward_relic", ""))
	if id.is_empty() or Content.item(id).is_empty():
		return {}
	return {"id": id, "relic": true, "left": maxi(1, int(rules.get("reward_runs", 1)))}


## A run is over (a new day begins): `coins` go into the box, `kept` (bag places
## {id, count}) into the stash (its gold into the box), then the merchant may help himself from
## the box.
## Death: coins 0 and only the safe places. Returns the gold stolen from the box.
static func end_run(coins: int, kept: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	var gold_home: int = maxi(0, coins)
	var list: Array[Dictionary] = stash()
	# What comes home stays in the bag (on its cells); only what has no room there goes into the
	# stash. Egon's errand ruby goes into the stash (he takes it from there).
	var bag: Bag = _empty_bag()
	for entry: Dictionary in kept:
		var id: String = String(entry.get("id", ""))
		var count: int = int(entry.get("count", 0))
		if id.is_empty() or count <= 0:
			continue
		# Fragile keys break when the dungeon is left (loot.json "fragile").
		if RunState.is_fragile(id):
			continue
		# Gear, relics and potions carried along: back onto their cells, else into the stash.
		if Bag.is_piece(entry):
			if not bag.put_place(entry) and not bag.add_piece(entry):
				list.append(_owned(entry))
			continue
		# The gold of the bag goes into the box, not into the inventory.
		if id == Bag.GOLD:
			gold_home += count
			continue
		if ruby_due_for(id):
			for i in count:
				list.append({"id": id, "count": 1})
			continue
		if entry.has("x") and bag.put_at(Vector2i(int(entry["x"]), int(entry["y"])), id, count, bool(entry.get("rot", false))):
			continue
		var over: int = bag.add(id, count)
		for i in over:
			list.append({"id": id, "count": 1})
	_write("bag", bag.contents())
	_write_stash(list)
	if gold_home > 0:
		_write("box", box() + gold_home)
	_wear_relic()
	_write("day", day() + 1)
	_write("pulls_today", 0)
	_write("sold_today", [])
	var stolen: int = roll_theft(rng)
	_write("box", box() - stolen)
	_write("last_theft", stolen)
	_save()
	return stolen


# --- The bag at home (what comes back from the dungeon stays in it) --------------------

## The places of the bag brought home ({id, count, x, y, rot}, Bag cells; the safe place at
## Bag.SAFE_ORIGIN). The next run starts with them (Bag.restore).
static func bag_places() -> Array[Dictionary]:
	return _bag_model().contents()


## An empty bag as the next run gets it: the base bag, the attached backpacks, the safe place
## with Geheimtasche.
static func _empty_bag() -> Bag:
	var bag := Bag.new()
	bag.add_backpacks(backpacks())
	bag.grow_safe(int(Skills.bonus("safe_slots")))
	return bag


## The saved bag as a Bag (places that do not fit any more are left out; they stay saved).
static func _bag_model() -> Bag:
	var bag: Bag = _empty_bag()
	for entry: Variant in _read("bag", []):
		if entry is Dictionary:
			bag.put_place(entry)
	return bag


static func _save_bag(bag: Bag) -> void:
	_write("bag", bag.contents())
	_save()


## true if bag place `index` would fit with its top left on `cell` (turned `rot`).
static func bag_fits(index: int, cell: Vector2i, rot: bool) -> bool:
	var bag: Bag = _bag_model()
	var place: Dictionary = bag.get_place(index)
	return not place.is_empty() and bag.fits_piece(place, cell, rot, [index])


## Moves bag place `index` (Bag.move_to: also stacks or swaps). false = nothing changed.
static func move_in_bag(index: int, cell: Vector2i, rot: bool) -> bool:
	var bag: Bag = _bag_model()
	if not bag.move_to(index, cell, rot):
		return false
	_save_bag(bag)
	return true


## Stash piece `piece` as the bag holds it: loot {id, count}, gear / relic / potion with its fields
## ({} for a backpack: it is attached, not carried).
static func _bag_piece(piece: Dictionary) -> Dictionary:
	if ShopGoods.is_backpack(piece):
		return {}
	if _is_loot(piece):
		return {"id": String(piece.get("id", "")), "count": maxi(1, int(piece.get("count", 1)))}
	return _owned(piece)


## true if stash piece `index` (loot, gear, a relic or a potion; not a backpack) may go into the
## bag on `cell`.
static func stash_fits_bag(index: int, cell: Vector2i, rot: bool) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var piece: Dictionary = _bag_piece(own[index])
	if piece.is_empty() or not Bag.is_known(piece):
		return false
	return _bag_model().fits_piece(piece, cell, rot)


## Stash piece `index` into the bag on `cell` (stash_fits_bag). false = nothing changed.
static func stash_to_bag(index: int, cell: Vector2i, rot: bool) -> bool:
	if not stash_fits_bag(index, cell, rot):
		return false
	var own: Array[Dictionary] = stash()
	var bag: Bag = _bag_model()
	var piece: Dictionary = _bag_piece(own[index])
	piece.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	if not bag.put_place(piece):
		return false
	own.remove_at(index)
	_write_stash(own)
	_save_bag(bag)
	return true


## Shift+click in the shop: stash place `index` into the bag wherever it fits first.
static func stash_to_bag_anywhere(index: int) -> bool:
	var own: Array[Dictionary] = stash()
	if index < 0 or index >= own.size():
		return false
	var spot: Dictionary = _bag_model().free_spot_for(_bag_piece(own[index]), Bag.MAIN)
	if spot.is_empty():
		return false
	return stash_to_bag(index, Vector2i(int(spot["x"]), int(spot["y"])), bool(spot["rot"]))


## Bag place `index` into the stash on `cell` (turned `rot`); cell (-1, -1) = anywhere. false if
## there is no room.
static func bag_to_stash(index: int, cell: Vector2i = Vector2i(-1, -1), rot: bool = false) -> bool:
	var bag: Bag = _bag_model()
	var place: Dictionary = bag.get_place(index)
	if place.is_empty():
		return false
	var own: Array[Dictionary] = stash()
	var pieces: Array[Dictionary] = []
	if Bag.is_piece(place):
		pieces.append(_owned(place))
	else:
		for i in maxi(1, int(place.get("count", 1))):
			pieces.append({"id": String(place["id"]), "count": 1})
	if cell != Vector2i(-1, -1):
		if pieces.size() != 1 or not ItemGrid.fits(own, stash_grid(), pieces[0], cell, rot):
			return false
		pieces[0].merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	elif ItemGrid.free_spot(own, stash_grid(), pieces[0]).is_empty():
		return false
	own.append_array(pieces)
	bag.take(index)
	_write_stash(own)
	_save_bag(bag)
	return true


## Egon buys bag place `index` (like MetaState.sell). Returns the gold (0 = nothing sold).
static func sell_from_bag(index: int) -> int:
	var bag: Bag = _bag_model()
	var place: Dictionary = bag.get_place(index)
	if place.is_empty() or String(place["id"]) == Bag.GOLD or Quests.is_stone(String(place["id"])):
		return 0
	var gold: int = ShopGoods.sell_price(place)
	_remember_sold(place, gold)
	bag.take(index)
	_write("box", box() + gold)
	_save_bag(bag)
	return gold


## Hands in the quest stone lying on bag place `index` (like deliver_quest). Returns the quest id.
static func deliver_quest_from_bag(index: int) -> String:
	var bag: Bag = _bag_model()
	var place: Dictionary = bag.get_place(index)
	if place.is_empty() or Quests.quest_of_stone(String(place["id"])).is_empty():
		return ""
	var own: Array[Dictionary] = stash()
	own.append({"id": String(place["id"]), "count": 1})
	_write_stash(own)
	bag.take(index)
	_save_bag(bag)
	return deliver_quest(_last_index_of(String(place["id"])))


static func _last_index_of(id: String) -> int:
	var own: Array[Dictionary] = stash()
	for i in range(own.size() - 1, -1, -1):
		if String(own[i].get("id", "")) == id:
			return i
	return -1


## true while the cells of attached backpack `id` hold something of the bag at home.
static func backpack_in_use(id: String) -> bool:
	var bag: Bag = _bag_model()
	for i in bag.size():
		var place: Dictionary = bag.get_place(i)
		for cell: Vector2i in Bag.cells_of_place(place):
			if bag.cells.get(cell, "") == id:
				return true
	return false


## true if `id` is the ruby of Egon's first errand while he still waits for it (it goes into the
## stash, where he takes it from).
static func ruby_due_for(id: String) -> bool:
	return id == String(Content.meta("ruby_quest").get("item", "")) and not ruby_delivered()


## A run with the relic on: one run less; at 0 it is broken and gone (broken_relic = its id, for
## Egon's comment). Relics for ever (left -1) and those Reliktschutz protects stay.
static func _wear_relic() -> void:
	var worn: Dictionary = equipment()
	_write("broken_relic", "")
	for slot: String in worn.keys():
		var relic: Dictionary = worn[slot]
		if not ShopGoods.is_relic(relic) or ShopGoods.relic_forever(relic):
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
