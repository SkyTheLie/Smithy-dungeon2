extends "res://assets/_reference/_lib/base_test.gd"
## Bag (loot of a run) and MetaState (gold and loot between runs: all gold at home lies in the
## money box, the merchant steals from it). Selling loot in the dungeon shop (the only gold of a
## run). Fixed seeds; the theft chances are checked over many days.


func run() -> void:
	_bag()
	_box()
	_old_save()
	_end_of_run()
	_theft()
	_gold_in_bag()
	_sell_in_dungeon()


func _bag() -> void:
	var bag: Object = script("res://scripts/systems/bag.gd").new()
	var normal: int = bag.get("normal_count")
	check_eq(normal, 4, "a small backpack: 4 places (data/meta.json)")
	check_eq(bag.call("size"), 5, "plus one safe place")
	check(bag.call("is_safe", 4) and not bag.call("is_safe", 3), "the last place is the safe one")
	check_eq(bag.call("add", "rat_fur", 2), 0, "2 rat furs fit")
	check_eq((bag.call("get_place", 0) as Dictionary).get("count"), 1, "loot does not stack")
	check_eq((bag.call("get_place", 1) as Dictionary).get("id"), "rat_fur", "the second one takes its own place")
	check_eq(bag.call("add", "nonsense", 1), 1, "unknown loot is refused")
	check_eq(bag.call("add", "rat_fur", 0), 0, "nothing to add: nothing happens")
	check_eq(bag.call("add", "rat_fur", -4), 0, "negative amounts are refused")
	check_eq(bag.call("count_of", "rat_fur"), 2, "still 2 after refused adds")
	check_eq(bag.call("add", "gold", 50), 0, "gold fits")
	check_eq(bag.call("add", "gold", 30), 0, "more gold")
	check_eq((bag.call("get_place", 2) as Dictionary).get("count"), 80, "only gold stacks")
	check_eq(bag.call("add", "copper_ore", 3), 2, "one place left: one ore fits, two do not")
	check_eq(bag.call("room_for", "amber"), 0, "no room for new loot")
	check_eq(bag.call("add", "amber", 1), 1, "a full bag refuses new loot")
	check_eq(bag.call("add", "gold", 5), 0, "but gold still goes onto its stack")
	check((bag.call("get_place", 4) as Dictionary).is_empty(), "the safe place is only filled by hand")

	# Drag and drop: swap; the same loot does not stack.
	bag.call("move", 0, 4)
	check_eq((bag.call("get_place", 4) as Dictionary).get("id"), "rat_fur", "dragged into the safe place")
	check((bag.call("get_place", 0) as Dictionary).is_empty(), "the old place is empty (swapped with nothing)")
	bag.call("move", 1, 4)
	check_eq((bag.call("get_place", 4) as Dictionary).get("count"), 1, "two rat furs do not stack")
	check_eq((bag.call("get_place", 1) as Dictionary).get("id"), "rat_fur", "the dragged one stays")
	bag.call("move", 3, 1)
	check_eq((bag.call("get_place", 1) as Dictionary).get("id"), "copper_ore", "different loot swaps")
	check_eq((bag.call("get_place", 3) as Dictionary).get("id"), "rat_fur", "both ways")
	var taken: Dictionary = bag.call("take", 3)
	check_eq(taken.get("id"), "rat_fur", "take gives the whole place (drop on the floor)")
	check((bag.call("get_place", 3) as Dictionary).is_empty(), "and empties it")
	check(bag.call("take", 99).is_empty(), "taking a place that does not exist gives nothing")

	var value_before: int = bag.call("total_value")
	check(value_before > 0, "loot has a value for the merchant")
	var kept: Array = bag.call("lose_unsafe")
	check_eq(kept.size(), 1, "death: only the safe place is left")
	check_eq((kept[0] as Dictionary).get("id"), "rat_fur", "with its loot")
	check_eq((bag.call("contents") as Array).size(), 1, "the bag holds nothing else")


func _box() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	check_eq(meta.call("box"), 0, "no gold at first")
	check_eq(meta.call("day"), 1, "day 1 at first")
	check(not meta.has_method("take_purse_for_run"), "no gold goes into the dungeon")
	meta.call("end_run", 150, [] as Array[Dictionary], _rng(1))
	check_eq(meta.call("box"), 150, "a won run brings its gold home into the box")
	check(not (meta.call("stash") as Array).any(func(place: Dictionary) -> bool: return place.get("id") == "gold"), "no coin bag in the inventory at home")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(5)
	check_eq(run_state.get("coins"), 0, "a run starts without gold")
	meta.call("reload")
	check_eq(meta.call("box"), 150, "the box is saved")


## An old save with a purse and a coin bag: both go into the box once.
func _old_save() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	var path: String = meta.call("path_of", meta.call("slot"))
	var config := ConfigFile.new()
	config.load(path)
	var before: int = int(config.get_value("meta", "box", 0))
	config.set_value("meta", "purse", 7)
	config.set_value("meta", "stash", [{"id": "rat_fur", "count": 1}, {"id": "gold", "count": 13}])
	config.save(path)
	meta.call("reload")
	check_eq(meta.call("box"), before + 20, "old purse and coin bag go into the box")
	check_eq((meta.call("stash") as Array).size(), 1, "the coin bag left the inventory")
	meta.call("end_run", 0, [] as Array[Dictionary], _rng(9))
	meta.call("reload")
	check_eq(meta.call("box"), before + 20, "and only once")
	meta.call("start_new")


func _end_of_run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	var day: int = meta.call("day")
	var kept: Array[Dictionary] = [{"id": "rat_fur", "count": 2}, {"id": "amber", "count": 1}]
	meta.call("end_run", 0, kept, _rng(2))
	var more: Array[Dictionary] = [{"id": "rat_fur", "count": 3}]
	meta.call("end_run", 0, more, _rng(3))
	check_eq(meta.call("day"), day + 2, "every run is a new day")
	var stash: Array = meta.call("stash")
	check_eq(stash.size(), 2, "the stash merges the same loot")
	check_eq((stash[0] as Dictionary).get("count"), 5, "2 + 3 rat furs")
	meta.call("reload")
	check_eq((meta.call("stash") as Array).size(), 2, "the stash is saved")


func _theft() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	# Up to the limit (200) the merchant never steals.
	meta.call("start_new")
	meta.call("end_run", 200, [] as Array[Dictionary], _rng(4))
	check_eq(meta.call("box"), 200, "exactly the limit")
	var rng: RandomNumberGenerator = _rng(5)
	var stolen_any: int = 0
	for i in 500:
		stolen_any += int(meta.call("roll_theft", rng))
	check_eq(stolen_any, 0, "nothing is stolen at the limit")

	# Above the limit: about 1 % all, about 20 % a part of what is above it.
	var night: RandomNumberGenerator = _rng(6)
	while int(meta.call("box")) <= 200:
		meta.call("end_run", 100, [] as Array[Dictionary], night)
	var box: int = meta.call("box")
	var excess: int = box - 200
	check(excess > 0, "above the limit")
	var all: int = 0
	var part: int = 0
	var part_too_big: bool = false
	var tries: int = 4000
	for i in tries:
		var stolen: int = meta.call("roll_theft", rng)
		if stolen == box:
			all += 1
		elif stolen > 0:
			part += 1
			part_too_big = part_too_big or stolen > excess
	check(not part_too_big, "a part never takes more than what is above the limit")
	check(all > tries * 0.003 and all < tries * 0.025, "about 1 %% steals everything (%d of %d)" % [all, tries])
	check(part > tries * 0.16 and part < tries * 0.24, "about 20 %% steals a part (%d of %d)" % [part, tries])
	check_eq(meta.call("box"), box, "roll_theft only rolls, it does not take")

	# end_run takes it and remembers it for the merchant's excuse.
	var before: int = meta.call("box")
	var took: int = 0
	for i in 60:
		took = meta.call("end_run", 0, [] as Array[Dictionary], rng)
		if took > 0:
			break
	check(took > 0, "within 60 days the merchant steals once")
	check_eq(meta.call("last_theft"), took, "the theft is remembered")
	check_eq(meta.call("box"), before - took, "and taken from the box")


func _rng(value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	return rng


## The gold of a run lies in the bag (material "gold"): coins count it, paying takes it out, it
## stacks to 999, the safe place keeps it on death and it goes into the box at home.
func _gold_in_bag() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	var wallet: Object = script("res://scripts/systems/run_state.gd").new(3)
	var bag: Object = wallet.get("bag")
	check_eq(wallet.call("add_coins", 30), 0, "30 gold fit")
	check_eq(wallet.get("coins"), 30, "coins = gold in the bag")
	check_eq((bag.call("get_place", 0) as Dictionary).get("id"), "gold", "the gold lies on a place of the bag")
	wallet.call("add_coins", 990)
	check_eq((bag.call("get_place", 0) as Dictionary).get("count"), 999, "gold stacks to 999 on one place")
	check(wallet.call("spend", 20), "paying works")
	check_eq(wallet.get("coins"), 1000, "and takes the gold out of the bag")
	check(not wallet.call("spend", 5000), "not more than there is")
	bag.call("move", 0, int(bag.get("normal_count")))
	var kept: Array[Dictionary] = bag.call("lose_unsafe")
	check_eq(wallet.get("coins"), 979, "death: the gold in the safe place stays")
	meta.call("end_run", 0, kept, RandomNumberGenerator.new())
	check(int(meta.call("box")) + int(meta.call("last_theft")) == 979, "and goes into the box at home")
	check((meta.call("stash") as Array).is_empty(), "not into the inventory")


## The merchant in the dungeon shop buys loot at its loot.json value (+ Goldnase per piece);
## the gold lands in the bag. The gold itself and empty places cannot be sold.
func _sell_in_dungeon() -> void:
	var wallet: Object = script("res://scripts/systems/run_state.gd").new(4)
	var bag: Object = wallet.get("bag")
	bag.call("add", "ruby", 1)
	bag.call("add", "rat_fur", 1)
	check_eq(wallet.call("sell_price", 0), 25, "a ruby: 25 gold")
	check_eq(wallet.call("sell_from_bag", 0), 25, "sold")
	check_eq(wallet.get("coins"), 25, "the gold is in the bag")
	check_eq((bag.call("get_place", 0) as Dictionary).get("id"), "gold", "on the freed place")
	check_eq(wallet.call("sell_from_bag", 0), 0, "the gold itself cannot be sold")
	check_eq(wallet.call("sell_from_bag", 3), 0, "an empty place gives nothing")
	wallet.set("sell_bonus", 2)
	check_eq(wallet.call("sell_from_bag", 1), 4, "Goldnase: rat fur 2 + 2")
	check_eq(wallet.get("coins"), 29, "onto the gold stack")
	check(bag.call("get_place", 1).is_empty(), "the fur's place is free")
	# Fill the normal places, the ruby in the safe place: its gold goes onto the gold stack.
	bag.call("add", "coal", 3)
	bag.call("put", int(bag.get("normal_count")), "amber", 1)
	check_eq(wallet.call("sell_from_bag", int(bag.get("normal_count"))), 14, "amber from the safe place: 12 + 2")
	check_eq(wallet.get("coins"), 43, "gold stacks even with a full bag")
	# Without a gold stack and no room: the gold stays in the sold place.
	var full: Object = script("res://scripts/systems/run_state.gd").new(6)
	var full_bag: Object = full.get("bag")
	full_bag.call("add", "coal", 4)
	full_bag.call("put", int(full_bag.get("normal_count")), "ruby", 1)
	check_eq(full.call("sell_from_bag", int(full_bag.get("normal_count"))), 25, "ruby from the safe place")
	check_eq((full_bag.call("get_place", int(full_bag.get("normal_count"))) as Dictionary).get("id"), "gold", "the gold lies in the safe place then")
	check_eq(full.get("coins"), 25, "nothing is lost")
