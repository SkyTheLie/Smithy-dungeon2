class_name GambaRun
extends RefCounted
## Rules of the lucky forge (scenes/gamba/gamba_game.gd shows them). Numbers: gamba.json.
##
## A run lasts up to `contract_days` days. Each day new swords arrive (3 copper at the start).
## A sword is heated, laid on the anvil and struck; every strike draws one of five outcomes by
## lottery tickets: break (sword gone) | damage (rarity -1) | hold | success (+1) | great (+2).
## A new sword has many success tickets and almost no break tickets; with every strike the tickets
## drift (randomly, but clearly towards break). After `frenzy.strikes` strikes on one sword a frenzy
## runs for a few seconds: nothing can break. In the evening the bell is rung: the swords on the
## table must be worth the day's demand. Enough: all of it is paid out as gold. Too little: one
## failure, the swords come back. `max_failures` failures end the run.
## Relics (lasting bonuses, `relic_slots` at most) are never free: at the relic shrine a sword of at
## least `coin_min_level` is given up for one guild mark, marks buy one of the shrine's offers
## (new offers after every bell). After every `merchant_every`-th day a merchant sells better swords
## and consumables for gold.
## The run is saved after each day (GambaSaves); a running day is not saved.

signal gold_changed(gold: int)

const OUTCOMES: Array[String] = ["break", "damage", "hold", "success", "great"]
## Highest rarity tier with an own name and colour (Rarity.Tier.MYTHIC).
const TOP_TIER: int = 7

var day: int = 1
var gold: int = 0
var failures: int = 0
var swords: Array[GambaSword] = []
var relics: Array[String] = []
## Consumable id -> how many.
var consumables: Dictionary[String, int] = {}
## Guild marks (one per sword given up at the shrine), they buy relics.
var coins: int = 0
## Relic ids the shrine offers today (new ones after every bell).
var relic_offers: Array[String] = []
## The merchant's goods today: {kind: "sword"/"consumable", id, price, sold}; empty = no merchant.
var shop: Array[Dictionary] = []
var next_id: int = 1
var ended: bool = false
var won: bool = false
## Statistics for the result.
var best_value: int = 0
var total_gold: int = 0
var swords_broken: int = 0
var rng := RandomNumberGenerator.new()

## The sword on the anvil (null = none). Not saved on purpose: saved only between days.
var anvil: GambaSword = null
## Seconds of frenzy left. Not saved on purpose (mid-day).
var frenzy_left: float = 0.0
## The next strike cannot break (rune). Not saved on purpose (mid-day).
var ward_active: bool = false
## The sword and gold before the last strike (hourglass). Not saved on purpose (mid-day).
var _undo_sword: GambaSword = null
var _undo_gold: int = 0
var _undo_broken: bool = false


static func data() -> Dictionary:
	return ContentDB.gamba()


func start_new(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	day = 1
	gold = 0
	failures = 0
	swords.clear()
	relics.clear()
	consumables.clear()
	coins = 0
	shop.clear()
	next_id = 1
	ended = false
	won = false
	best_value = 0
	total_gold = 0
	swords_broken = 0
	anvil = null
	frenzy_left = 0.0
	ward_active = false
	_undo_sword = null
	for i in int(data().get("start_swords", 3)):
		add_sword(String(data().get("start_material", "copper")))
	_roll_relic_offers()


# --- Swords and their value -------------------------------------------------------------------

func add_sword(material: String) -> GambaSword:
	var sword := GambaSword.new()
	sword.id = next_id
	next_id += 1
	sword.material = material
	var start: Dictionary = data().get("start_tickets", {})
	for outcome: String in OUTCOMES:
		sword.tickets[outcome] = float(start.get(outcome, 0.0))
	swords.append(sword)
	return sword


func find_sword(id: int) -> GambaSword:
	for sword: GambaSword in swords:
		if sword.id == id:
			return sword
	return null


static func material_data(material: String) -> Dictionary:
	return (data().get("materials", {}) as Dictionary).get(material, {})


## Gold the sword is worth (0 when broken).
func sword_value(sword: GambaSword) -> int:
	if sword.broken:
		return 0
	return value_at(sword.material, sword.level)


func value_at(material: String, level: int) -> int:
	var base: float = float(material_data(material).get("value", 0))
	var growth: float = float(data().get("value_growth", 1.7))
	return roundi(base * pow(growth, level) * (1.0 + relic_sum("value")))


## Gold for texts: 1234567 -> "1.234.567" (German), "1,234,567" in the other languages;
## from a billion on "1,2 Mrd." / "1.2 B".
static func format_gold(amount: int) -> String:
	var german: bool = Language.is_base()
	if absi(amount) >= 1000000000:
		var short: String = DamageKinds.format_number(amount / 1.0e9)
		return (short + " Mrd.") if german else (short.replace(",", ".") + " B")
	var digits: String = str(absi(amount))
	var groups: Array[String] = []
	while digits.length() > 3:
		groups.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.push_front(digits)
	return ("-" if amount < 0 else "") + (".".join(groups) if german else ",".join(groups))


## "R3", above R8 "R8+2".
static func level_short(level: int) -> String:
	if level <= TOP_TIER:
		return "R%d" % (level + 1)
	return "R%d+%d" % [TOP_TIER + 1, level - TOP_TIER]


static func level_color(level: int) -> Color:
	return Rarity.COLORS[clampi(level, 0, TOP_TIER)]


## "Kupferschwert", translated.
static func sword_name(sword: GambaSword) -> String:
	return Language.translate(String(material_data(sword.material).get("name", sword.material)))


## Name of the rarity: "Fein", above Mythisch "Mythisch +2".
static func level_name(level: int) -> String:
	var tier_name: String = Rarity.get_display_name(clampi(level, 0, TOP_TIER) as Rarity.Tier)
	return tier_name if level <= TOP_TIER else "%s +%d" % [tier_name, level - TOP_TIER]


## Translated name of a bucket ("Verbessert ++").
static func outcome_name(outcome: String) -> String:
	var style: Dictionary = (data().get("outcome_style", {}) as Dictionary).get(outcome, {})
	return Language.translate(String(style.get("name", outcome)))


static func outcome_color(outcome: String) -> Color:
	var style: Dictionary = (data().get("outcome_style", {}) as Dictionary).get(outcome, {})
	return Color.from_string(String(style.get("color", "#ffffff")), Color.WHITE)


# --- Relics -------------------------------------------------------------------------------------

static func relic_data(id: String) -> Dictionary:
	return (data().get("relics", {}) as Dictionary).get(id, {})


static func consumable_data(id: String) -> Dictionary:
	return (data().get("consumables", {}) as Dictionary).get(id, {})


## Sum of a number effect over all owned relics.
func relic_sum(effect: String) -> float:
	var total: float = 0.0
	for id: String in relics:
		total += float((relic_data(id).get("effects", {}) as Dictionary).get(effect, 0.0))
	return total


## Product of a factor effect over all owned relics (1 without one).
func relic_product(effect: String) -> float:
	var total: float = 1.0
	for id: String in relics:
		var effects: Dictionary = relic_data(id).get("effects", {})
		if effects.has(effect):
			total *= float(effects[effect])
	return total


func relic_tickets(outcome: String) -> float:
	var total: float = 0.0
	for id: String in relics:
		var tickets: Dictionary = (relic_data(id).get("effects", {}) as Dictionary).get("tickets", {})
		total += float(tickets.get(outcome, 0.0))
	return total


func relic_slots() -> int:
	return int(data().get("relic_slots", 6))


func _roll_relic_offers() -> void:
	var pool: Array[String] = []
	for id: String in data().get("relics", {}):
		if not id in relics:
			pool.append(id)
	relic_offers.clear()
	for i in mini(int(data().get("relic_offers", 3)), pool.size()):
		var pick: int = rng.randi_range(0, pool.size() - 1)
		relic_offers.append(pool[pick])
		pool.remove_at(pick)


## Marks a relic costs at the shrine.
static func relic_cost(id: String) -> int:
	return maxi(1, int(relic_data(id).get("coins", 1)))


## Lowest level (0 = R1) a sword needs to be given up for a mark.
static func coin_min_level() -> int:
	return int(data().get("coin_min_level", 0))


## A sword on the bench or the table that is good enough for a mark (not the one on the anvil).
func can_deposit(sword: GambaSword) -> bool:
	return sword != null and not sword.broken and sword in swords and sword != anvil \
			and sword.level >= coin_min_level() and not ended


## Gives the sword up at the shrine for one mark. false if not possible.
func deposit_sword(sword: GambaSword) -> bool:
	if not can_deposit(sword):
		return false
	swords.erase(sword)
	coins += 1
	return true


func can_buy_relic(id: String) -> bool:
	return id in relic_offers and not id in relics and coins >= relic_cost(id) and not ended


## Buys a relic of the shrine for marks; with all slots full `drop` (an owned relic) goes for it.
## false if that is not possible.
func buy_relic(id: String, drop: String = "") -> bool:
	if not can_buy_relic(id):
		return false
	if relics.size() >= relic_slots():
		if not drop in relics:
			return false
		relics.erase(drop)
	coins -= relic_cost(id)
	relics.append(id)
	relic_offers.erase(id)
	return true


# --- Chances ------------------------------------------------------------------------------------

## Tickets of the sword per outcome after relics, frenzy and rune (never below 0).
func effective_tickets(sword: GambaSword) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for outcome: String in OUTCOMES:
		result[outcome] = maxf(0.0, float(sword.tickets.get(outcome, 0.0)) + relic_tickets(outcome))
	var cut: float = minf(relic_sum("damage_cut") * sword.damages, relic_sum("damage_cut_max"))
	result["break"] *= relic_product("break_mult") * (1.0 - cut)
	if frenzy_left > 0.0 or ward_active:
		result["break"] = 0.0
	return result


## Outcome -> chance 0..1.
func chances(sword: GambaSword) -> Dictionary[String, float]:
	var tickets: Dictionary[String, float] = effective_tickets(sword)
	var total: float = 0.0
	for outcome: String in OUTCOMES:
		total += tickets[outcome]
	var result: Dictionary[String, float] = {}
	for outcome: String in OUTCOMES:
		result[outcome] = tickets[outcome] / total if total > 0.0 else 0.0
	return result


func _draw_outcome(sword: GambaSword) -> String:
	var tickets: Dictionary[String, float] = effective_tickets(sword)
	var total: float = 0.0
	for outcome: String in OUTCOMES:
		total += tickets[outcome]
	var roll: float = rng.randf() * total
	for outcome: String in OUTCOMES:
		roll -= tickets[outcome]
		if roll < 0.0:
			return outcome
	return "hold"


## The tickets move after a strike: clearly towards break, by a random amount.
func _drift(sword: GambaSword) -> void:
	var drift: Dictionary = data().get("drift", {})
	var growth: float = 1.0 + float(data().get("drift_growth", 0.3)) * sword.strikes
	var span: Array = data().get("drift_random", [1.0, 1.0])
	var minimum: Dictionary = data().get("min_tickets", {})
	for outcome: String in OUTCOMES:
		var step: float = float(drift.get(outcome, 0.0)) * growth * rng.randf_range(float(span[0]), float(span[1]))
		sword.tickets[outcome] = maxf(float(minimum.get(outcome, 0.0)), float(sword.tickets.get(outcome, 0.0)) + step)


# --- Forge --------------------------------------------------------------------------------------

## Heats the sword and lays it on the anvil (the one there goes back to the bench).
func put_on_anvil(sword: GambaSword) -> bool:
	if sword == null or sword.broken or not sword in swords or ended:
		return false
	take_off_anvil()
	sword.offered = false
	sword.hot = true
	anvil = sword
	return true


## The sword goes back to the bench and cools; no more undo for it.
func take_off_anvil() -> void:
	if anvil != null:
		anvil.hot = false
	anvil = null
	frenzy_left = 0.0
	ward_active = false
	_undo_sword = null


## Highest level a sword can reach (keeps the value inside 64-bit numbers).
func max_level() -> int:
	return int(data().get("max_level", 60))


func frenzy_limit() -> int:
	var frenzy: Dictionary = data().get("frenzy", {})
	return maxi(1, int(frenzy.get("strikes", 10)) + int(relic_sum("frenzy_strikes")))


func frenzy_seconds() -> float:
	var frenzy: Dictionary = data().get("frenzy", {})
	return float(frenzy.get("seconds", 3.0)) + relic_sum("frenzy_seconds")


func in_frenzy() -> bool:
	return frenzy_left > 0.0


## Counts the frenzy down (real seconds of play).
func tick(delta: float) -> void:
	if frenzy_left > 0.0:
		frenzy_left = maxf(0.0, frenzy_left - delta)


## One hammer strike on the sword on the anvil. Returns {outcome, shielded (a break became damage),
## level_before, level, value, frenzy_started, gold_back (from a break)} or {} without a sword.
func strike() -> Dictionary:
	var sword: GambaSword = anvil
	if sword == null or ended:
		return {}
	_undo_sword = sword.copy()
	_undo_gold = gold
	_undo_broken = false
	var level_before: int = sword.level
	var value_before: int = sword_value(sword)
	var was_frenzy: bool = frenzy_left > 0.0
	var outcome: String = _draw_outcome(sword)
	var shielded: bool = false
	if outcome == "break" and rng.randf() < relic_sum("break_save"):
		outcome = "damage"
		shielded = true
	ward_active = false
	var gold_back: int = 0
	match outcome:
		"break":
			sword.broken = true
			swords_broken += 1
			gold_back = roundi(value_before * relic_sum("break_gold"))
			_add_gold(gold_back)
			swords.erase(sword)
			anvil = null
			frenzy_left = 0.0
			_undo_broken = true
		"damage":
			sword.level = maxi(0, sword.level - 1)
			sword.damages += 1
		"success":
			sword.level += 1
		"great":
			sword.level += 2
	sword.level = mini(sword.level, max_level())
	sword.strikes += 1
	sword.peak_level = maxi(sword.peak_level, sword.level)
	# In a frenzy the tickets stand still (the frenzy is the reward for the risky strikes before).
	if not sword.broken and not was_frenzy:
		_drift(sword)
		best_value = maxi(best_value, sword_value(sword))
	var frenzy_started: bool = false
	if not sword.broken and frenzy_left <= 0.0:
		sword.frenzy_strikes += 1
		if sword.frenzy_strikes >= frenzy_limit():
			sword.frenzy_strikes = 0
			frenzy_left = frenzy_seconds()
			frenzy_started = true
	return {
		"outcome": outcome, "shielded": shielded, "level_before": level_before, "level": sword.level,
		"value": sword_value(sword), "frenzy_started": frenzy_started, "gold_back": gold_back,
	}


func can_undo() -> bool:
	return _undo_sword != null and consumables.get("hourglass", 0) > 0


## Hourglass: the last strike never happened (a broken sword comes back onto the anvil).
func undo_strike() -> bool:
	if not can_undo():
		return false
	_use_consumable("hourglass")
	var old: GambaSword = _undo_sword
	_undo_sword = null
	if _undo_broken:
		swords_broken -= 1
	gold = _undo_gold
	gold_changed.emit(gold)
	var sword: GambaSword = find_sword(old.id)
	if sword == null:
		sword = old
		swords.append(sword)
	else:
		sword.level = old.level
		sword.peak_level = old.peak_level
		sword.strikes = old.strikes
		sword.frenzy_strikes = old.frenzy_strikes
		sword.tickets = old.tickets.duplicate()
		sword.damages = old.damages
		sword.broken = false
	sword.hot = true
	anvil = sword
	return true


func can_use_ward() -> bool:
	return anvil != null and not ward_active and consumables.get("ward", 0) > 0


## Rune: the next strike cannot break.
func use_ward() -> bool:
	if not can_use_ward():
		return false
	_use_consumable("ward")
	ward_active = true
	return true


func _use_consumable(id: String) -> void:
	consumables[id] = consumables.get(id, 0) - 1
	if consumables[id] <= 0:
		consumables.erase(id)


# --- Tribute and days ---------------------------------------------------------------------------

func demand(for_day: int = -1) -> int:
	var settings: Dictionary = data().get("demand", {})
	var d: int = day if for_day < 0 else for_day
	var raw: float = float(settings.get("first", 500)) * pow(float(settings.get("growth", 1.25)), d - 1) \
			* relic_product("demand_mult")
	var step: float = maxf(1.0, float(settings.get("round", 50)))
	return int(roundf(raw / step) * step)


func set_offered(sword: GambaSword, offered: bool) -> void:
	if sword == null or sword.broken or not sword in swords:
		return
	if offered and sword == anvil:
		take_off_anvil()
	sword.offered = offered


func offered_value() -> int:
	var total: int = 0
	for sword: GambaSword in swords:
		if sword.offered:
			total += sword_value(sword)
	return total


func daily_swords() -> int:
	return int(data().get("daily_swords", 3)) + int(relic_sum("daily_swords"))


func contract_days() -> int:
	return int(data().get("contract_days", 21))


func max_failures() -> int:
	return int(data().get("max_failures", 3)) + int(relic_sum("max_failures"))


## End of the day: the guild takes the table. Returns {paid, amount, demand, ended, won, merchant}.
func ring_bell() -> Dictionary:
	take_off_anvil()
	var wanted: int = demand()
	var amount: int = offered_value()
	var paid: bool = amount >= wanted
	if paid:
		var kept: Array[GambaSword] = []
		for sword: GambaSword in swords:
			if not sword.offered:
				kept.append(sword)
		swords = kept
		_add_gold(amount)
	else:
		failures += 1
		for sword: GambaSword in swords:
			sword.offered = false
	var result: Dictionary = {"paid": paid, "amount": amount, "demand": wanted, "ended": false, "won": false, "merchant": false}
	if failures >= max_failures():
		ended = true
	elif paid and day >= contract_days():
		ended = true
		won = true
	result.ended = ended
	result.won = won
	if ended:
		return result
	day += 1
	for i in daily_swords():
		add_sword(String(data().get("start_material", "copper")))
	_roll_relic_offers()
	if (day - 1) % maxi(1, int(data().get("merchant_every", 3))) == 0:
		_roll_shop()
		result.merchant = true
	return result


func _add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	total_gold += amount
	gold_changed.emit(gold)


# --- Merchant -----------------------------------------------------------------------------------

## Price of relics and consumables grows with the days.
func _day_price(base: int) -> int:
	var per_day: float = float((data().get("shop", {}) as Dictionary).get("price_per_day", 0.2))
	return int(roundf(base * (1.0 + per_day * (day - 1)) / 10.0) * 10.0)


func _roll_shop() -> void:
	shop.clear()
	var settings: Dictionary = data().get("shop", {})
	var sword_prices: Dictionary = settings.get("swords", {})
	var materials: Array = sword_prices.keys()
	# The higher the day, the better the swords on offer (a window of three materials).
	var top: int = clampi(1 + floori((day - 1) / 3.0), 1, materials.size() - 1)
	for i in int(settings.get("sword_offers", 3)):
		var material: String = materials[clampi(top - 2 + rng.randi_range(0, 2), 0, materials.size() - 1)]
		shop.append({"kind": "sword", "id": material, "price": int(sword_prices[material]), "sold": false})
	var goods: Array = (data().get("consumables", {}) as Dictionary).keys()
	for i in int(settings.get("consumable_offers", 2)):
		var pick: String = goods[rng.randi_range(0, goods.size() - 1)]
		shop.append({"kind": "consumable", "id": pick, "price": _day_price(int(consumable_data(pick).get("price", 500))), "sold": false})


## Buys shop entry `index`. false if not possible.
func buy(index: int) -> bool:
	if index < 0 or index >= shop.size():
		return false
	var entry: Dictionary = shop[index]
	var price: int = int(entry.price)
	if bool(entry.sold) or price <= 0 or gold < price:
		return false
	match String(entry.kind):
		"sword":
			add_sword(String(entry.id))
		"consumable":
			consumables[String(entry.id)] = consumables.get(String(entry.id), 0) + 1
	gold -= price
	entry.sold = true
	gold_changed.emit(gold)
	return true


func close_shop() -> void:
	shop.clear()


# --- Save ---------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	var saved_swords: Array = []
	for sword: GambaSword in swords:
		saved_swords.append(sword.to_dict())
	return {
		"day": day, "gold": gold, "failures": failures, "swords": saved_swords, "relics": relics.duplicate(),
		"consumables": consumables.duplicate(), "coins": coins, "relic_offers": relic_offers.duplicate(),
		"shop": shop.duplicate(true), "next_id": next_id, "ended": ended, "won": won, "best_value": best_value,
		"total_gold": total_gold, "swords_broken": swords_broken, # 64-bit numbers as text: JSON numbers would lose digits.
		"rng_seed": str(rng.seed), "rng_state": str(rng.state),
	}


func load_save(saved: Dictionary) -> void:
	start_new(0)
	relic_offers.clear()
	swords.clear()
	day = int(saved.get("day", 1))
	gold = int(saved.get("gold", 0))
	failures = int(saved.get("failures", 0))
	for entry: Variant in saved.get("swords", []):
		if entry is Dictionary:
			var sword: GambaSword = GambaSword.from_dict(entry)
			if not material_data(sword.material).is_empty():
				swords.append(sword)
	for id: Variant in saved.get("relics", []):
		if not relic_data(String(id)).is_empty():
			relics.append(String(id))
	var saved_goods: Dictionary = saved.get("consumables", {})
	for id: String in saved_goods:
		if not consumable_data(id).is_empty():
			consumables[id] = int(saved_goods[id])
	coins = maxi(0, int(saved.get("coins", 0)))
	for id: Variant in saved.get("relic_offers", []):
		if not relic_data(String(id)).is_empty() and not String(id) in relics:
			relic_offers.append(String(id))
	for entry: Variant in saved.get("shop", []):
		# Saves from before the shrine: the merchant sold relics too.
		if entry is Dictionary and String((entry as Dictionary).get("kind", "")) in ["sword", "consumable"]:
			var good: Dictionary = entry
			shop.append({"kind": String(good.get("kind", "")), "id": String(good.get("id", "")),
					"price": int(good.get("price", 0)), "sold": bool(good.get("sold", false))})
	next_id = int(saved.get("next_id", 1))
	for sword: GambaSword in swords:
		next_id = maxi(next_id, sword.id + 1)
	ended = bool(saved.get("ended", false))
	won = bool(saved.get("won", false))
	best_value = int(saved.get("best_value", 0))
	total_gold = int(saved.get("total_gold", 0))
	swords_broken = int(saved.get("swords_broken", 0))
	rng.seed = String(saved.get("rng_seed", "0")).to_int()
	if saved.has("rng_state"):
		rng.state = String(saved.rng_state).to_int()
