class_name MetaState
extends RefCounted
## What the player owns between runs (user://save.cfg), saved after every change:
##   purse  gold the player carries. It goes into the dungeon with the next run (start coins) and
##          is lost there on death.
##   box    the small money box (Dose) outside the dungeon. Safe up to data/meta.json
##          money_box.limit; above it the merchant may steal on every new day (roll_theft).
##   stash  loot brought home (from the bag), to sell to the merchant later.
##   day    one run = one day.
## Rules about this gold live here (deposit / withdraw check the amounts); screens only call them.

const PATH: String = "user://save.cfg"
const SECTION: String = "meta"

static var _config: ConfigFile


static func purse() -> int:
	return int(_read("purse", 0))


static func box() -> int:
	return int(_read("box", 0))


static func day() -> int:
	return int(_read("day", 1))


## Gold the merchant took on the last new day (0 = nothing), for his excuse in the shop.
static func last_theft() -> int:
	return int(_read("last_theft", 0))


static func box_limit() -> int:
	return int(Content.meta("money_box").get("limit", 200))


static func stash() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Variant in _read("stash", []):
		if entry is Dictionary:
			list.append((entry as Dictionary).duplicate())
	return list


## Purse -> box. false (and nothing changes) for amounts <= 0 or more than in the purse.
static func deposit(amount: int) -> bool:
	if amount <= 0 or amount > purse():
		return false
	_write("purse", purse() - amount)
	_write("box", box() + amount)
	_save()
	return true


## Box -> purse. false for amounts <= 0 or more than in the box.
static func withdraw(amount: int) -> bool:
	if amount <= 0 or amount > box():
		return false
	_write("box", box() - amount)
	_write("purse", purse() + amount)
	_save()
	return true


## The purse goes into the dungeon: returns it and empties it.
static func take_purse_for_run() -> int:
	var gold: int = purse()
	if gold > 0:
		_write("purse", 0)
		_save()
	return gold


## A run is over (a new day begins): `coins` go into the purse, `kept` (bag places
## {id, count}) into the stash, then the merchant may help himself from the box.
## Death: coins 0 and only the safe places. Returns the gold stolen from the box.
static func end_run(coins: int, kept: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	if coins > 0:
		_write("purse", purse() + coins)
	var list: Array[Dictionary] = stash()
	for entry: Dictionary in kept:
		var id: String = String(entry.get("id", ""))
		var count: int = int(entry.get("count", 0))
		if id.is_empty() or count <= 0:
			continue
		var merged: bool = false
		for own: Dictionary in list:
			if String(own["id"]) == id:
				own["count"] = int(own["count"]) + count
				merged = true
				break
		if not merged:
			list.append({"id": id, "count": count})
	_write("stash", list)
	_write("day", day() + 1)
	var stolen: int = roll_theft(rng)
	_write("box", box() - stolen)
	_write("last_theft", stolen)
	_save()
	return stolen


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
	_load().save(PATH)


static func _load() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(PATH)
	return _config


## Forgets the loaded file; the next call reads it again (tests).
static func reload() -> void:
	_config = null
