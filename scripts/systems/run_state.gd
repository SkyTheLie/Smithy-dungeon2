class_name RunState
extends RefCounted
## One run from "Neues Spiel" to death or victory: life, coins, bombs, keys, collected items and
## the floor. All rules about these values live here (the HUD only shows them, the rooms only
## call these functions). A run is not saved on purpose (roguelike: dying ends it).
##
## Life counts in half hearts: health 5 of max_hearts 3 = two and a half of three hearts.
## Blue hearts (`blue`, also in halves) come on top: hits take them first, they cannot be healed.
## White shield hearts (`shield`, halves) come from the equipment (use_gear, gear.json
## shield_hearts): they go before the blue ones, cannot be healed and are not refilled.
## The equipment's other stats (e.g. the weapon's damage) count like an item for the whole run;
## the relic on the hero is added as its item.
## Picked-up items are remembered between runs (Progress: Lexikon, unlocks).
## Item flags handled here: damage_cap (a hit takes at most half a heart), extra_life (the item is
## used up instead of dying), desperate / fury (more damage at low life / after hits on this
## floor), regen, kill_heal, double_heal, blue_burst (signal blue_heart_lost).
## Pacts (Glutpakt room): items paid with heart containers; after one, no more shrines this run.

signal changed
signal item_added(id: String)
## All items were dropped (test room).
signal items_cleared
## A synergy became active (its name is shown).
signal synergy_found(id: String)
signal died
## An item became unlocked (Progress); it can appear from now on.
signal unlocked(id: String)
## An extra-life item was used up instead of dying.
signal revived(id: String)
## A whole blue heart was lost (blue_burst hurts all enemies then).
signal blue_heart_lost
## Loot an item gave ("give": "loot") did not fit into the bag; Dungeon drops it on the floor.
signal loot_overflow(id: String, count: int)

var health: int = 6
var max_hearts: int = 3
## Blue hearts in halves (on top of the red ones).
var blue: int = 0
## White shield hearts (halves) from the equipment and the skills.
var shield: int = 0
## EXP of this run (kills, Skills.kill_exp); MetaState.add_exp at the end of the run.
var exp_earned: int = 0
## Levels the player reached at the end of this run (for the end screen).
var levels_gained: int = 0
## Extra gold per piece of loot sold to the merchant in the dungeon shop (skill Goldnase).
var sell_bonus: int = 0
## The stats of the equipment worn at the start (one source per piece, without shield_hearts).
var gear_sources: Array[Dictionary] = []
## The gold of the run: what lies in the bag as "gold" (Bag.GOLD). Only counted here, so there is
## one source; change it with add_coins / spend / sell_from_bag. There is no gold to find in the
## dungeon: it only comes from selling loot in the dungeon shop (and the gold at home stays in
## the money box, MetaState).
var coins: int:
	get:
		return bag.count_of(Bag.GOLD)
var bombs: int = 0
var keys: int = 0
## Collected item ids in the order they were picked up (the same item can come twice).
var items: Array[String] = []
## Index into data/floors.json "floors".
var floor_index: int = 0
var kills: int = 0
## Synergy ids that are active.
var synergies: Array[String] = []
## Worked out by compute_stats after every change of the items.
var stats: ShotStats
## Seed of the run: each floor uses seed + floor_index, so the same seed gives the same dungeon.
var seed_value: int = 0
## Item ids that were offered already (item room, shop, boss), so they do not come again.
var seen_items: Array[String] = []
## Glutmantel ("mantle"): can still catch a hit in this room (Dungeon refreshes it per room).
var mantle_ready: bool = true
## false after the test room was used: then nothing of this run counts for the Lexikon/unlocks.
var record_progress: bool = true
## Seconds played in this run (pause not counted).
var time: float = 0.0
## Hits taken on this floor (fury) and whether red hearts were lost (special room chance).
var hits_this_floor: int = 0
var lost_red_this_floor: bool = false
## Floors in a row without any hit (unlocks).
var clean_floors: int = 0
## Pact items taken in this run; after the first one only pacts come after the boss.
var pacts: int = 0
## Chance of a special room after the next boss (rises 0.33 -> 0.66 -> 1.0 while none comes).
var special_chance: float = 1.0
## Bosses of this run so far (the next floor prefers one that did not come yet).
var fought_bosses: Array[String] = []
## The chosen character (data/characters.json): its values count like an item for the whole run.
var character: String = "magier"
## Loot from the dungeon (Tab). Lost on death except the safe places.
var bag: Bag = Bag.new()
## Potions taken along from the hero's potion places (use_gear): [{slot, id}, …]; Q drinks the
## first one (drink_potion).
var potions: Array[Dictionary] = []
var _regen_left: float = 0.0
var _kills_to_heal: int = 0

const MAX_HEARTS_LIMIT: int = 12
const MAX_COUNT: int = 99


func _init(run_seed: int = 0, character_id: String = "magier") -> void:
	seed_value = run_seed
	character = character_id if not Content.character(character_id).is_empty() else "magier"
	var base: Dictionary = Content.player()
	max_hearts = int(Content.character(character).get("hearts", base.get("hearts", 3)))
	health = max_hearts * 2
	# Gold in the bag changes the coins (Goldglut items count them).
	bag.changed.connect(_coins_changed)
	bombs = int(base.get("bombs", 1))
	keys = int(base.get("keys", 1))
	compute_stats()
	_add_start_items()


## The character's "start_items" (its main weapon: Glutstab, Jagdbogen, Kriegerschwert). They are
## normal items, so they combine with others (synergies) like any item.
func _add_start_items() -> void:
	for id: Variant in Content.character(character).get("start_items", []):
		add_item(String(id))


func is_dead() -> bool:
	return health <= 0


func has_item(id: String) -> bool:
	return items.has(id)


## A new room: the Glutmantel can catch a hit again.
func refresh_mantle() -> void:
	mantle_ready = true


## true if the Glutmantel catches this hit (then no damage); once per room.
func block_with_mantle() -> bool:
	if not stats.has("mantle") or not mantle_ready or is_dead():
		return false
	mantle_ready = false
	changed.emit()
	return true


## Takes `halves` half hearts. Returns true if it hit (alive and amount > 0).
func take_damage(halves: int) -> bool:
	if halves <= 0 or is_dead():
		return false
	if stats.has("damage_cap"):
		halves = 1
	hits_this_floor += 1
	var on_shield: int = mini(shield, halves)
	shield -= on_shield
	halves -= on_shield
	if halves <= 0:
		compute_stats()
		changed.emit()
		return true
	var blue_hearts_before: int = ceili(blue / 2.0)
	var on_blue: int = mini(blue, halves)
	blue -= on_blue
	if halves > on_blue:
		lost_red_this_floor = true
	health = maxi(0, health - (halves - on_blue))
	if ceili(blue / 2.0) < blue_hearts_before and stats.has("blue_burst"):
		blue_heart_lost.emit()
	if is_dead() and _use_extra_life():
		return true
	compute_stats()
	changed.emit()
	if is_dead():
		died.emit()
	return true


## An item with "extra_life" is used up: full red hearts again. false if there is none.
func _use_extra_life() -> bool:
	for id: String in items:
		if ((Content.item(id).get("flags", []) as Array)).has("extra_life"):
			items.erase(id)
			health = max_hearts * 2
			compute_stats()
			revived.emit(id)
			changed.emit()
			return true
	return false


## Half hearts a heart on the floor heals (double with double_heal).
func heart_value() -> int:
	return 4 if stats.has("double_heal") else 2


## Every physics frame of the run (Dungeon): time, regeneration.
func tick(delta: float) -> void:
	time += delta
	if not stats.has("regen"):
		return
	_regen_left -= delta
	if _regen_left <= 0.0:
		_regen_left = float((Content.player().get("effects", {}) as Dictionary).get("regen_time", 40.0))
		heal(1)


## An enemy died: kill_heal heals half a heart every few kills.
func on_kill() -> void:
	if not stats.has("kill_heal"):
		return
	_kills_to_heal += 1
	if _kills_to_heal >= int((Content.player().get("effects", {}) as Dictionary).get("kill_heal_every", 15)):
		_kills_to_heal = 0
		heal(1)


## Down the trapdoor: what counted per floor starts again; best values for unlocks.
func next_floor() -> void:
	clean_floors = clean_floors + 1 if hits_this_floor == 0 else 0
	note_best("clean_floors", clean_floors)
	hits_this_floor = 0
	lost_red_this_floor = false
	floor_index += 1
	note_best("floor", floor_index + 1)
	compute_stats()


## The special room after the boss: 0 = none, otherwise "pact" or "shrine". Red heart damage
## on this floor halves the chance; after a pact only pacts come.
func roll_special_room(rng: RandomNumberGenerator) -> String:
	var value: float = special_chance * (0.5 if lost_red_this_floor else 1.0)
	if rng.randf() >= value:
		special_chance = minf(1.0, special_chance + 0.33)
		return ""
	special_chance = 0.33
	if pacts > 0:
		return "pact"
	return "pact" if rng.randf() < 0.5 else "shrine"


## Takes a pact item: costs `hearts` heart containers (blue hearts if there are no red ones to
## spare). false if it would kill.
func take_pact(id: String, hearts: int) -> bool:
	if max_hearts > hearts:
		max_hearts -= hearts
		health = mini(health, max_hearts * 2)
	elif blue >= hearts * 2:
		blue -= hearts * 2
	else:
		return false
	pacts += 1
	note_best("pacts", pacts)
	add_item(id)
	return true


## For unlocks that look at the best value ever (Progress.note_best).
func note_best(key: String, value: int) -> void:
	if record_progress:
		announce(Progress.note_best(key, value))


## Heals `halves`; false if already full (pickups then stay on the floor).
func heal(halves: int) -> bool:
	if halves <= 0 or health >= max_hearts * 2:
		return false
	health = mini(max_hearts * 2, health + halves)
	compute_stats()
	changed.emit()
	return true


## Q in the dungeon: drinks the first potion (data/potions.json "heal" half hearts); it is gone
## from the hero's potion place at home too (MetaState.use_potion). false (nothing happens)
## without a potion, when dead or at full life.
func drink_potion() -> bool:
	if potions.is_empty() or is_dead() or health >= max_hearts * 2:
		return false
	var potion: Dictionary = potions.pop_front()
	heal(maxi(1, int(Content.potion(String(potion["id"])).get("heal", 4))))
	MetaState.use_potion(String(potion["slot"]))
	changed.emit()
	return true


## A kill: its EXP (a boss more, data/levels.json), times the dungeon's exp_mult.
func add_kill_exp(boss: bool, mult: float = 1.0) -> void:
	exp_earned += roundi(Skills.kill_exp(boss) * maxf(0.0, mult))


## The skills learned at home (Skills, MetaState): more places in the bag, shield hearts, red
## hearts, the stats (one source, like an item) and more gold for loot in the dungeon shop. Called once at the start.
func use_skills() -> void:
	bag.grow(int(Skills.bonus("bag_slots")), int(Skills.bonus("safe_slots")))
	shield += int(Skills.bonus("shield_halves"))
	var hearts: int = int(Skills.bonus("hearts"))
	if hearts > 0:
		max_hearts = mini(MAX_HEARTS_LIMIT, max_hearts + hearts)
		health = max_hearts * 2
	sell_bonus = int(Skills.bonus("sell_bonus"))
	var stats: Dictionary = Skills.run_stats()
	if not stats.is_empty():
		gear_sources.append({"stats": stats})
	compute_stats()
	changed.emit()


## Puts `amount` gold into the bag. Returns what did not fit (full bag).
func add_coins(amount: int) -> int:
	if amount <= 0:
		return 0
	var left: int = bag.add(Bag.GOLD, amount)
	note_best("coins", coins)
	return left


## What the merchant in the dungeon shop pays for bag place `index`: (loot.json value +
## sell_bonus) per piece. 0 for an empty place and for the gold itself.
func sell_price(index: int) -> int:
	var place: Dictionary = bag.get_place(index)
	if place.is_empty() or String(place["id"]) == Bag.GOLD:
		return 0
	var value: int = maxi(0, int(Content.material(String(place["id"])).get("value", 0)))
	return (value + sell_bonus) * int(place["count"])


## Sells bag place `index` (the whole stack) in the dungeon shop: its gold goes into the bag
## (onto the gold stack, else into the freed place). Returns the gold (0 = nothing sold: empty
## place, the gold itself, worth nothing, or the run is over).
func sell_from_bag(index: int) -> int:
	var gold: int = sell_price(index)
	if gold <= 0 or is_dead():
		return 0
	bag.take(index)
	var left: int = add_coins(gold)
	if left > 0:
		bag.put(index, Bag.GOLD, left)
	return gold


func add_bombs(amount: int) -> void:
	if amount <= 0:
		return
	bombs = mini(MAX_COUNT, bombs + amount)
	changed.emit()


func add_keys(amount: int) -> void:
	if amount <= 0:
		return
	keys = mini(MAX_COUNT, keys + amount)
	changed.emit()


## Pays `price` coins; false (and nothing paid) if there are not enough.
func spend(price: int) -> bool:
	if price < 0 or coins < price:
		return false
	if price > 0:
		bag.remove(Bag.GOLD, price)
	return true


func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	changed.emit()
	return true


func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	changed.emit()
	return true


## Takes an item: its values count at once; new synergies are announced.
func add_item(id: String) -> void:
	var data: Dictionary = Content.item(id)
	if data.is_empty():
		push_error("RunState: unknown item '%s'" % id)
		return
	items.append(id)
	if not seen_items.has(id):
		seen_items.append(id)
	var extra_hearts: int = int((data.get("stats", {}) as Dictionary).get("hearts", 0))
	if extra_hearts > 0:
		max_hearts = mini(MAX_HEARTS_LIMIT, max_hearts + extra_hearts)
		health = mini(max_hearts * 2, health + extra_hearts * 2)
	elif extra_hearts < 0:
		max_hearts = maxi(1, max_hearts + extra_hearts)
		health = mini(max_hearts * 2, health)
	add_blue_hearts(int((data.get("stats", {}) as Dictionary).get("blue_hearts", 0)))
	if bool(data.get("heal_full", false)):
		health = max_hearts * 2
	# "give": things that come with the item (Wanderbündel, Schmiedeschürze).
	var give: Dictionary = data.get("give", {})
	var give_loot: Dictionary = give.get("loot", {})
	for loot_id: String in give_loot:
		var count: int = int(give_loot[loot_id])
		var over: int = bag.add(loot_id, count) if count > 0 else 0
		if over > 0:
			loot_overflow.emit(loot_id, over)
	bombs = mini(MAX_COUNT, bombs + maxi(0, int(give.get("bombs", 0))))
	keys = mini(MAX_COUNT, keys + maxi(0, int(give.get("keys", 0))))
	var before: Array[String] = synergies.duplicate()
	compute_stats()
	note_best("hearts", max_hearts)
	item_added.emit(id)
	if record_progress:
		announce(Progress.discover(id))
	for synergy: String in synergies:
		if not before.has(synergy):
			synergy_found.emit(synergy)
	changed.emit()


## The run starts with `worn` (MetaState.equipment: slot -> {id, rarity}): every piece's
## shield_hearts become white shield hearts, its other stats count for the whole run.
func use_gear(worn: Dictionary) -> void:
	gear_sources.clear()
	potions.clear()
	shield = 0
	for slot: Variant in worn:
		var piece: Dictionary = worn[slot]
		# Potions do nothing by themselves: they are drunk with Q (drink_potion).
		if ShopGoods.is_potion(piece):
			potions.append({"slot": String(slot), "id": String(piece.get("id", ""))})
			continue
		# The relic works like the item itself (synergies too).
		if ShopGoods.is_relic(piece):
			add_item(String(piece.get("id", "")))
			continue
		var values: Dictionary = ShopGoods.stats(String(piece.get("id", "")), int(piece.get("rarity", 1)))
		shield += roundi(float(values.get("shield_hearts", 0.0)) * 2.0)
		values.erase("shield_hearts")
		if not values.is_empty():
			gear_sources.append({"stats": values})
	compute_stats()
	changed.emit()


## `amount` whole blue hearts; red and blue together stay within MAX_HEARTS_LIMIT.
func add_blue_hearts(amount: int) -> void:
	if amount <= 0:
		return
	var room_left: int = MAX_HEARTS_LIMIT * 2 - max_hearts * 2 - blue
	blue += clampi(amount * 2, 0, maxi(0, room_left))
	note_best("blue", ceili(blue / 2.0))
	changed.emit()


## Sends `unlocked` for items Progress just opened.
func announce(ids: Array[String]) -> void:
	for id: String in ids:
		unlocked.emit(id)


## Items with "per_coin" (Goldglut) depend on the coins, so the shot is worked out again.
func _coins_changed() -> void:
	compute_stats()
	changed.emit()


## Test room only: drops every item except the start items (the main weapon). Hearts go back to
## the start value (full), the shot to the start values. Coins, bombs and keys stay.
func clear_items() -> void:
	items.clear()
	blue = 0
	max_hearts = int(Content.character(character).get("hearts", Content.player().get("hearts", 3)))
	health = max_hearts * 2
	compute_stats()
	items_cleared.emit()
	# After items_cleared, so the HUD shows the weapon again.
	_add_start_items()
	changed.emit()


## Synergy ids whose every "requires" group has at least one item of the run.
func find_synergies() -> Array[String]:
	var found: Array[String] = []
	var all: Dictionary = Content.synergies()
	for id: String in all:
		var ok: bool = true
		for group: Array in all[id].get("requires", []):
			var any: bool = false
			for item_id: Variant in group:
				if items.has(String(item_id)):
					any = true
					break
			if not any:
				ok = false
				break
		if ok:
			found.append(id)
	return found


## Works out `stats` from the start values, every item and every active synergy (and the coins
## for "per_coin" items).
func compute_stats() -> ShotStats:
	var base: Dictionary = Content.player()
	var result := ShotStats.from_base(base.get("stats", {}))
	synergies = find_synergies()
	var sources: Array[Dictionary] = [Content.character(character)]
	sources.append_array(gear_sources)
	for id: String in items:
		sources.append(Content.item(id))
	for id: String in synergies:
		sources.append(Content.synergies()[id])
	var has_beam: bool = false
	var has_bomb: bool = false
	var has_melee: bool = false
	for source: Dictionary in sources:
		result.apply_adds(source.get("stats", {}))
		var per_coin: Dictionary = source.get("per_coin", {})
		for key: String in per_coin:
			# Counted up to 99 coins only, so the gold from home does not make it too strong.
			result.apply_adds({key: float(per_coin[key]) * mini(coins, MAX_COUNT)})
		for flag: Variant in source.get("flags", []):
			result.flags[String(flag)] = true
		result.apply_chances(source.get("chance", {}))
		for trap: Variant in source.get("traps", []):
			if trap is Dictionary:
				result.traps.append((trap as Dictionary).duplicate())
		var mode: String = String(source.get("mode", ""))
		has_beam = has_beam or mode == ShotStats.MODE_BEAM
		has_bomb = has_bomb or mode == ShotStats.MODE_BOMB
		has_melee = has_melee or mode == ShotStats.MODE_MELEE
	# Desperate (at most one heart left) and fury (hits on this floor) add damage.
	var effects: Dictionary = base.get("effects", {})
	if result.has("desperate") and health <= 2:
		result.damage += float(effects.get("desperate_damage", 1.5))
	if result.has("fury"):
		result.damage += float(effects.get("fury_damage", 0.25)) * mini(hits_this_floor, int(effects.get("fury_max", 6)))
	for source: Dictionary in sources:
		result.apply_mults(source.get("stats", {}))
	if has_beam:
		result.mode = ShotStats.MODE_BEAM
	elif has_bomb:
		result.mode = ShotStats.MODE_BOMB
	elif has_melee:
		result.mode = ShotStats.MODE_MELEE
	result.clamp_to(base.get("limits", {}))
	stats = result
	return result


## Picks an item id for an item room / shop / boss that the run has not seen yet ("" if none is
## left); marks it as seen. Locked items (Progress) never come.
func pick_item(pool_name: String, rng: RandomNumberGenerator) -> String:
	var choices: Array[String] = []
	for id: String in Content.pool(pool_name):
		if not seen_items.has(id) and Progress.is_unlocked(id):
			choices.append(id)
	if choices.is_empty():
		return ""
	var id: String = choices[rng.randi_range(0, choices.size() - 1)]
	seen_items.append(id)
	return id
