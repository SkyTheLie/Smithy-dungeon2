class_name Garden
extends RefCounted
## Plant pots in the greenhouse (Planter, house.json furniture with "planter"), in GameState.garden.
## A pot (id = its House.placed "uid") has size × size fields; a field is a bed with the id
## "<pot>:<field>". A pot needs soil first (an item with items.json "soil": true); the soil stays
## in the pot for good and can only be swapped for another soil. A seed (items.json "plant":
## {"grows": <item id>, "days": 3, "amount": 2}) is planted into a free field and is ready after
## that many days (counted with DayCycle.day, so sleeping makes it grow). Ash (from a failed magic
## dust) on a growing plant raises the rarity of the harvest by one tier and halves its growing
## time (ASH_GROW_FACTOR, rounded up), once per planting. Plants with "full_moon" (the moon lily)
## harvested on a full moon (GameCalendar.is_full_moon) are one tier better.
## Watering (a watering can filled at the water tap, see WaterTap): a growing plant can be watered
## once a day; every watering counts as WATER_BONUS_DAYS more days of growth from the next day on
## (watered today = grows 2 days tonight). Plants grow without water too, only slower.
## The harvest: `amount` of the grown item, rarity = its base rarity + fertilizer, and with the
## player skill "Pflanzen pflücken" a chance for one more tier. The seed comes back (SEED_RETURN),
## with SEED_BONUS_CHANCE one more.
## Greenhouse decoration (house.json furniture "garden") helps the pots within its "radius" every
## night (night()): "grow" = extra days of growth (all pieces together at most MAX_NIGHT_GROW),
## "water" = waters a growing plant that was not watered the day before, "harvest" = chance for
## one more crop (the best piece counts, kept in the bed as "harvest_bonus").

## Stage of a field (also the picture Planter shows).
enum Stage { EMPTY, SPROUT, GROWING, READY }

const ASH_ID: String = "ash"
## Growing time of a plant with ash, as a share of its days (0.5 = half, rounded up).
const ASH_GROW_FACTOR: float = 0.5
## Seeds back from every harvest, and the chance for one more.
const SEED_RETURN: int = 1
const SEED_BONUS_CHANCE: float = 0.2
## Extra days of growth per watering.
const WATER_BONUS_DAYS: int = 1
## Extra growth from decoration per night, at most.
const MAX_NIGHT_GROW: float = 1.0
## Room of the plant pots (House.GREENHOUSE_ROOM).
const ROOM: String = "greenhouse"

## bed id -> {"seed": item id, "day": day planted, "fertilized": bool, "water": times watered,
## "watered_day": day of the last watering (-1 = never), "boost": extra days from decoration,
## "harvest_bonus": chance for one more crop}
var beds: Dictionary = {}
## pot id -> item id of the soil in it (pots without soil are missing).
var soil: Dictionary = {}
## Seeds from the old fixed beds of saves before the pots (GameState gives them back after loading).
var legacy_seeds: Array[String] = []


static func get_bed_id(pot: String, field: int) -> String:
	return "%s:%d" % [pot, field]


static func is_soil(item: ItemData) -> bool:
	return item != null and item.is_soil


func has_soil(pot: String) -> bool:
	return soil.has(pot)


func get_soil(pot: String) -> ItemData:
	return ContentDB.item(soil[pot]) if soil.has(pot) and ContentDB.has_item(soil[pot]) else null


## Puts `soil_item` into the pot; returns the soil that was in it before (null = none).
func fill_soil(pot: String, soil_item: ItemData) -> ItemData:
	var old: ItemData = get_soil(pot)
	soil[pot] = String(soil_item.id)
	return old


## Something grows in one of the fields of the pot.
func has_plants(pot: String) -> bool:
	var prefix: String = pot + ":"
	return beds.keys().any(func(bed: String) -> bool: return bed.begins_with(prefix))


## Forgets a pot that went into storage; returns its soil (null = none), plants must be gone.
func clear_pot(pot: String) -> ItemData:
	var old: ItemData = get_soil(pot)
	soil.erase(pot)
	return old


func get_stage(bed: String, today: int) -> Stage:
	if not beds.has(bed):
		return Stage.EMPTY
	var progress: float = get_progress(bed, today)
	if progress >= 1.0:
		return Stage.READY
	return Stage.SPROUT if progress < 0.5 else Stage.GROWING


## 0.0 (just planted) to 1.0 (ready).
func get_progress(bed: String, today: int) -> float:
	var seed_item: ItemData = get_seed(bed)
	if seed_item == null:
		return 0.0
	return clampf((today - int(beds[bed]["day"]) + get_water_bonus(bed, today) + get_boost(bed)) / float(get_grow_days(bed)),
			0.0, 1.0)


## Days until ready; a watering of today already counts (it is sure to work tonight).
func get_days_left(bed: String, today: int) -> int:
	if get_seed(bed) == null:
		return 0
	return maxi(1 if get_stage(bed, today) != Stage.READY else 0,
			ceili(int(beds[bed]["day"]) + get_grow_days(bed) - today - get_water_bonus(bed, today + 1) - get_boost(bed)))


## Extra days of growth the decoration gave so far.
func get_boost(bed: String) -> float:
	return float(beds[bed].get("boost", 0.0)) if beds.has(bed) else 0.0


# --- Decoration (house.json furniture "garden") -------------------------------------------

## The night before `today`: every growing plant gets what the decoration near its pot gives.
## `placed`: House.placed (pots have "uid", decoration "garden" in house.json).
func night(placed: Array[Dictionary], today: int) -> void:
	var helpers: Array[Dictionary] = []
	for entry in placed:
		if entry.get("room", "") == ROOM and not House.get_furniture(entry["id"]).get("garden", {}).is_empty():
			helpers.append(entry)
	if helpers.is_empty():
		return
	for pot in placed:
		var uid: String = str(pot.get("uid", ""))
		if uid.is_empty() or pot.get("room", "") != ROOM:
			continue
		var effect: Dictionary = get_effect_at(helpers, Vector2(pot["x"], pot["y"]))
		for field in House.get_planter_size(pot["id"]) ** 2:
			var bed: String = get_bed_id(uid, field)
			if not beds.has(bed) or get_stage(bed, today - 1) == Stage.READY or int(beds[bed]["day"]) >= today:
				continue
			if effect["water"] and int(beds[bed].get("watered_day", -1)) != today - 1:
				beds[bed]["water"] = int(beds[bed].get("water", 0)) + 1
			beds[bed]["boost"] = get_boost(bed) + effect["grow"]
			beds[bed]["harvest_bonus"] = maxf(float(beds[bed].get("harvest_bonus", 0.0)), effect["harvest"])


## What the decoration in `helpers` (House.placed entries) gives a pot standing at `at`:
## {"grow": days, "water": bool, "harvest": chance}.
static func get_effect_at(helpers: Array[Dictionary], at: Vector2) -> Dictionary:
	var effect: Dictionary = {"grow": 0.0, "water": false, "harvest": 0.0}
	for entry in helpers:
		var garden: Dictionary = House.get_furniture(entry["id"]).get("garden", {})
		if Vector2(entry["x"], entry["y"]).distance_to(at) > float(garden.get("radius", 64)):
			continue
		effect["grow"] = minf(MAX_NIGHT_GROW, effect["grow"] + float(garden.get("grow", 0.0)))
		effect["water"] = effect["water"] or bool(garden.get("water", false))
		effect["harvest"] = maxf(effect["harvest"], float(garden.get("harvest", 0.0)))
	return effect


## Days the plant in `bed` needs in all (with ash: ASH_GROW_FACTOR of them). At least 1.
func get_grow_days(bed: String) -> int:
	var seed_item: ItemData = get_seed(bed)
	if seed_item == null:
		return 1
	var days: int = seed_item.grow_days
	if is_fertilized(bed):
		days = ceili(days * ASH_GROW_FACTOR)
	return maxi(1, days)


func get_seed(bed: String) -> ItemData:
	if not beds.has(bed) or not ContentDB.has_item(beds[bed]["seed"]):
		return null
	return ContentDB.item(beds[bed]["seed"])


func is_fertilized(bed: String) -> bool:
	return beds.has(bed) and bool(beds[bed].get("fertilized", false))


static func is_seed(item: ItemData) -> bool:
	return item != null and item.grows_into != null


func plant(bed: String, seed_item: ItemData, today: int) -> bool:
	if beds.has(bed) or not is_seed(seed_item):
		return false
	beds[bed] = {"seed": String(seed_item.id), "day": today, "fertilized": false, "water": 0, "watered_day": -1}
	return true


## Extra days of growth from watering; a watering of today only counts from tomorrow on.
func get_water_bonus(bed: String, today: int) -> int:
	if not beds.has(bed):
		return 0
	var times: int = int(beds[bed].get("water", 0))
	if is_watered_today(bed, today):
		times -= 1
	return maxi(0, times) * WATER_BONUS_DAYS


func is_watered_today(bed: String, today: int) -> bool:
	return beds.has(bed) and int(beds[bed].get("watered_day", -1)) == today


## Whether the plant in `bed` can be watered now: growing (not ready) and not watered today.
func can_water(bed: String, today: int) -> bool:
	return get_stage(bed, today) in [Stage.SPROUT, Stage.GROWING] and not is_watered_today(bed, today)


func water(bed: String, today: int) -> bool:
	if not can_water(bed, today):
		return false
	beds[bed]["water"] = int(beds[bed].get("water", 0)) + 1
	beds[bed]["watered_day"] = today
	return true


## Ash on a growing plant (not when it is ready or already fertilized).
func fertilize(bed: String, today: int) -> bool:
	if get_stage(bed, today) in [Stage.EMPTY, Stage.READY] or is_fertilized(bed):
		return false
	beds[bed]["fertilized"] = true
	return true


## Empties a ready bed and returns the harvest (null if not ready). `upgrade_chance` (0-1): chance
## for one more rarity tier (skill "Pflanzen pflücken").
func harvest(bed: String, today: int, upgrade_chance: float = 0.0) -> InventorySlot:
	if get_stage(bed, today) != Stage.READY:
		return null
	var seed_item: ItemData = get_seed(bed)
	var crop := InventorySlot.new()
	crop.item = seed_item.grows_into
	crop.amount = seed_item.harvest_amount + (1 if randf() < float(beds[bed].get("harvest_bonus", 0.0)) else 0)
	var tiers: int = (1 if is_fertilized(bed) else 0) + (1 if randf() < upgrade_chance else 0)
	if seed_item.full_moon_bonus and GameCalendar.is_full_moon(today):
		tiers += 1
	tiers += get_soil_tiers(get_soil(bed.get_slice(":", 0)))
	crop.rarity = Rarity.raise(crop.item.base_rarity, tiers)
	beds.erase(bed)
	return crop


## Rarity tiers a harvest gets from better soil (ItemData.soil_bonus): the whole part always,
## the rest as a chance. `roll` (0-1) is the random number, given in tests.
static func get_soil_tiers(soil_item: ItemData, roll: float = -1.0) -> int:
	if soil_item == null or soil_item.soil_bonus <= 0.0:
		return 0
	var whole: int = floori(soil_item.soil_bonus)
	var chance: float = soil_item.soil_bonus - whole
	if roll < 0.0:
		roll = randf()
	return whole + (1 if roll < chance else 0)


## Seeds the harvest of `seed_item` gives back (SEED_RETURN, with SEED_BONUS_CHANCE one more).
static func roll_seeds(seed_item: ItemData) -> InventorySlot:
	var seeds := InventorySlot.new()
	seeds.item = seed_item
	seeds.rarity = seed_item.base_rarity
	seeds.amount = SEED_RETURN + (1 if randf() < SEED_BONUS_CHANCE else 0)
	return seeds


# --- Watering cans (items.json type "watering_can", water in InventorySlot.water) ----------

static func is_watering_can(stack: InventorySlot) -> bool:
	return not stack.is_empty() and stack.item.type == ItemData.ItemType.WATERING_CAN


## Water left in all watering cans of the inventory.
static func count_water(inventory: Inventory) -> int:
	var total: int = 0
	for stack in inventory.slots:
		if is_watering_can(stack):
			total += stack.water
	return total


static func has_watering_can(inventory: Inventory) -> bool:
	for stack in inventory.slots:
		if is_watering_can(stack):
			return true
	return false


## Takes one charge from the first watering can with water; false = all are empty.
static func use_water(inventory: Inventory) -> bool:
	for stack in inventory.slots:
		if is_watering_can(stack) and stack.water > 0:
			stack.water -= 1
			inventory.emit_changed()
			return true
	return false


## Fills every watering can of the inventory; returns how many charges went in.
static func fill_watering_cans(inventory: Inventory) -> int:
	var added: int = 0
	for stack in inventory.slots:
		if is_watering_can(stack):
			var capacity: int = stack.get_water_capacity()
			added += maxi(0, capacity - stack.water)
			stack.water = maxi(stack.water, capacity)
	if added > 0:
		inventory.emit_changed()
	return added


func to_save_data() -> Dictionary:
	return {"beds": beds.duplicate(true), "soil": soil.duplicate()}


## Old saves: the data was only the beds, with the fixed greenhouse beds (ids without ":");
## their seeds go to legacy_seeds.
func load_save_data(data: Dictionary) -> void:
	beds = {}
	soil = {}
	legacy_seeds.clear()
	var saved_beds: Dictionary = data.get("beds", {}) if data.has("beds") or data.has("soil") else data
	for bed: String in saved_beds:
		var entry: Dictionary = saved_beds[bed]
		if not ContentDB.has_item(entry.get("seed", "")):
			continue
		if not bed.contains(":"):
			legacy_seeds.append(String(entry["seed"]))
			continue
		beds[bed] = {"seed": String(entry["seed"]), "day": int(entry.get("day", 0)),
				"fertilized": bool(entry.get("fertilized", false)), "water": int(entry.get("water", 0)),
				"watered_day": int(entry.get("watered_day", -1)), "boost": float(entry.get("boost", 0.0)),
				"harvest_bonus": float(entry.get("harvest_bonus", 0.0))}
	var saved_soil: Dictionary = data.get("soil", {})
	for pot: String in saved_soil:
		if ContentDB.has_item(saved_soil[pot]):
			soil[pot] = String(saved_soil[pot])
