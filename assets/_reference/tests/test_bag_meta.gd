extends "res://assets/_reference/_lib/base_test.gd"
## Bag (loot of a run) and MetaState (gold and loot between runs: all gold at home lies in the
## money box, the merchant steals from it). Selling loot in the dungeon shop (the only gold of a
## run). Fixed seeds; the theft chances are checked over many days.


func run() -> void:
	_bag()
	_backpacks()
	_box()
	_old_save()
	_end_of_run()
	_theft()
	_gold_in_bag()
	_sell_in_dungeon()


func _bag() -> void:
	var bag: Object = script("res://scripts/systems/bag.gd").new()
	var safe_origin: Vector2i = bag.get("SAFE_ORIGIN")
	check_eq((bag.call("section_cells", "main") as Array).size(), 24, "the bag: 8 x 3 cells (data/meta.json)")
	check_eq((bag.call("section_cells", "safe") as Array).size(), 4, "the safe place: 2 x 2 cells")
	check_eq(bag.call("add", "rat_fur", 2), 0, "2 rat furs fit")
	check_eq(bag.call("size"), 2, "loot does not stack: one place each")
	check_eq(bag.call("footprint", bag.call("get_place", 0)), Vector2i(2, 2), "a rat fur covers 2 x 2 cells")
	check_eq(_at(bag, 1), Vector2i(2, 0), "the second one lies beside the first")
	check_eq(bag.call("add", "ruby", 1), 0, "a ruby (3 x 3) fits into the 3 rows")
	check_eq(bag.call("add", "rotten_staff", 1), 0, "a staff (4 x 1) fits below the furs")
	var staff: int = _index_of(bag, "rotten_staff")
	check_eq(_at(bag, staff), Vector2i(0, 2), "lying in the bottom row")
	check_eq(bag.call("room_for", "amber"), 0, "no room for a 2 x 2 any more")
	check_eq(bag.call("add", "amber", 1), 1, "a full bag refuses new loot")
	check_eq(bag.call("room_for", "coal"), 3, "but the last column takes 3 small things")
	check_eq(bag.call("add", "nonsense", 1), 1, "unknown loot is refused")
	check_eq(bag.call("add", "rat_fur", 0), 0, "nothing to add: nothing happens")
	check_eq(bag.call("add", "rat_fur", -4), 0, "negative amounts are refused")
	check_eq(bag.call("count_of", "rat_fur"), 2, "still 2 after refused adds")
	check_eq(bag.call("add", "gold", 50), 0, "gold fits")
	check_eq(bag.call("add", "gold", 30), 0, "more gold")
	check_eq((bag.call("get_place", _index_of(bag, "gold")) as Dictionary).get("count"), 80, "only gold stacks")
	for i: int in bag.call("size"):
		check(not bag.call("is_safe", i), "the safe place is only filled by hand (%d)" % i)

	# Drag and drop: into the safe place, swapping, turning.
	check(bag.call("move_to", 0, safe_origin, false), "a rat fur fits into the safe place")
	check(bag.call("is_safe", 0), "it lies there")
	check(bag.call("move_to", 1, safe_origin, false), "a second fur onto it: the two swap")
	check(bag.call("is_safe", 1) and not bag.call("is_safe", 0), "now the other one is safe")
	check(not bag.call("move_to", _index_of(bag, "ruby"), safe_origin, false), "a ruby (3 x 3) does not fit into the safe place")
	staff = _index_of(bag, "rotten_staff")
	check(not bag.call("move_to", staff, Vector2i(7, 0), true), "turned (1 x 4) it is too long for 3 rows")
	check(not bag.call("move_to", staff, Vector2i(6, 0), false), "it cannot reach out of the bag")
	var taken: Dictionary = bag.call("take", staff)
	check_eq(taken.get("id"), "rotten_staff", "take gives the whole place (drop on the floor)")
	check_eq(bag.call("count_of", "rotten_staff"), 0, "and empties it")
	check(bag.call("take", 99).is_empty(), "taking a place that does not exist gives nothing")
	check(bag.call("put_at", Vector2i(0, 2), "rotten_staff", 1, false), "put back by hand")
	check(not bag.call("put_at", Vector2i(0, 2), "coal", 1, false), "a taken cell is refused")

	# Backpacks attached at home add cells.
	bag.call("add_backpacks", [{"id": "kraeutertasche", "x": 8, "y": 0, "rot": false}])
	check_eq((bag.call("section_cells", "main") as Array).size(), 28, "a herb pouch: 4 cells more")
	check_eq(bag.call("add", "amber", 1), 0, "now the amber fits")
	bag.call("add_backpacks", [{"id": "kupferrucksack", "x": 20, "y": 20, "rot": false}])
	check_eq((bag.call("section_cells", "main") as Array).size(), 28, "a backpack that is not joined to the bag is refused")
	bag.call("grow_safe", 1)
	check_eq((bag.call("section_cells", "safe") as Array).size(), 6, "Geheimtasche: one column more")

	var value_before: int = bag.call("total_value")
	check(value_before > 0, "loot has a value for the merchant")
	var kept: Array = bag.call("lose_unsafe")
	check_eq(kept.size(), 1, "death: only the safe place is left")
	check_eq((kept[0] as Dictionary).get("id"), "rat_fur", "with its loot")
	check_eq((bag.call("contents") as Array).size(), 1, "the bag holds nothing else")


func _index_of(bag: Object, id: String) -> int:
	for i: int in bag.call("size"):
		if (bag.call("get_place", i) as Dictionary).get("id") == id:
			return i
	return -1


func _at(bag: Object, index: int) -> Vector2i:
	var place: Dictionary = bag.call("get_place", index)
	return Vector2i(int(place.get("x", -1)), int(place.get("y", -1)))


## Backpack placements (BagLayout) and where MetaState keeps them.
func _backpacks() -> void:
	var layout: Script = script("res://scripts/systems/bag_layout.gd")
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	check(layout.call("is_valid", []), "no backpacks: fine")
	check(layout.call("is_valid", [{"id": "kupferrucksack", "x": 8, "y": 0, "rot": false}]), "right of the bag")
	check(layout.call("is_valid", [{"id": "eisenrucksack", "x": 0, "y": 3, "rot": false}]), "below the bag")
	check(not layout.call("is_valid", [{"id": "kupferrucksack", "x": 6, "y": 0, "rot": false}]), "not over the bag")
	check(not layout.call("is_valid", [{"id": "kupferrucksack", "x": 9, "y": 0, "rot": false}]), "not with a gap")
	check(not layout.call("is_valid", [{"id": "kupferrucksack", "x": 8, "y": 3, "rot": false}]), "a corner is not enough")
	check(layout.call("is_valid", [{"id": "kupferrucksack", "x": 8, "y": 0, "rot": false}, {"id": "kraeutertasche", "x": 8, "y": 3, "rot": false}]), "a backpack may hang on another one")
	check(not layout.call("is_valid", [{"id": "nope", "x": 8, "y": 0, "rot": false}]), "unknown backpacks are refused")
	check(not layout.call("is_valid", [{"id": "eisenrucksack", "x": 30, "y": 0, "rot": false}]), "not outside the board")
	check_eq((layout.call("cells_of", {"id": "eisenrucksack", "x": 8, "y": 0, "rot": true}) as Array).size(), 8, "turned: still 8 cells")
	check(layout.call("is_valid", [{"id": "eisenrucksack", "x": 8, "y": 0, "rot": true}]), "turned (2 x 4) beside the bag")

	meta.call("start_new")
	# Two backpacks may be attached: level 3, the pouch and Rucksack-Riemen learned (the pouch of
	# the skill is cleared away again).
	while int(meta.call("level")) < 3:
		meta.call("add_exp", 1000)
	meta.call("gift_gold", 1000)
	check(meta.call("buy_skill", "rucksack") and meta.call("buy_skill", "rucksack_riemen"), "Rucksack-Riemen learned")
	meta.call("admin_clear_stash")
	check_eq(meta.call("backpack_limit"), 2, "two backpacks allowed")
	check(not meta.call("place_backpack", "kupferrucksack", Vector2i(8, 0), false), "only attached backpacks can be moved")
	meta.call("give_piece", {"id": "kupferrucksack", "backpack": true})
	meta.call("give_piece", {"id": "kraeutertasche", "backpack": true})
	meta.call("give_piece", {"id": "kraeutertasche", "backpack": true})
	check_eq((meta.call("stash") as Array).size(), 3, "the backpacks lie in the stash")
	check(not meta.call("attach_backpack", 0, Vector2i(9, 0), false), "not with a gap")
	check(meta.call("attach_backpack", 0, Vector2i(8, 0), false), "the copper backpack right of the bag")
	check_eq((meta.call("stash") as Array).size(), 2, "it left the stash")
	check(meta.call("attach_backpack", 0, Vector2i(8, 3), false), "the pouch on the copper backpack")
	check(not meta.call("attach_backpack", 0, Vector2i(0, 3), false), "the same backpack only once")
	check(not meta.call("detach_backpack", "kupferrucksack"), "the copper one holds the pouch: it stays")
	check(meta.call("place_backpack", "kraeutertasche", Vector2i(0, 3), false), "the pouch moves below the bag")
	check(meta.call("detach_backpack", "kraeutertasche"), "the pouch comes off into the stash")
	check_eq((meta.call("stash") as Array).size(), 2, "back in the stash")
	check_eq((meta.call("backpacks") as Array).size(), 1, "one attached")
	meta.call("reload")
	check_eq((meta.call("backpacks") as Array).size(), 1, "saved")
	var wallet: Object = script("res://scripts/systems/run_state.gd").new(8)
	# This test wants an empty bag (player.json could give start bombs).
	(wallet.get("bag") as Object).call("clear")
	wallet.call("use_skills")
	check_eq(((wallet.get("bag") as Object).call("section_cells", "main") as Array).size(), 33, "in the run: 24 + 9 cells")
	meta.call("start_new")


func _box() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	check_eq(meta.call("box"), 0, "no gold at first")
	check_eq(meta.call("day"), 1, "day 1 at first")
	check(not meta.has_method("take_purse_for_run"), "no gold goes into the dungeon")
	meta.call("end_run", 150, [] as Array[Dictionary], _rng(1))
	check_eq(meta.call("box"), 150, "a won run brings its gold home into the box")
	check(not (meta.call("stash") as Array).any(func(place: Dictionary) -> bool: return place.get("id") == "gold"), "no coin bag in the inventory at home")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(5)
	# This test wants an empty bag (player.json could give start bombs).
	(run_state.get("bag") as Object).call("clear")
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
	var home: Array = meta.call("bag_places")
	# The bag of the second run (it took the first one along) is what is home now: 3 furs.
	check_eq(home.size(), 3, "the loot stays in the bag")
	check((meta.call("stash") as Array).is_empty(), "nothing goes into the stash by itself")
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 5}, {"id": "amber", "count": 1}] as Array[Dictionary], _rng(4))
	check_eq((meta.call("bag_places") as Array).size(), 4, "a full bag: four 2 x 2 fit into 8 x 3")
	check_eq((meta.call("stash") as Array).size(), 2, "what has no room in the bag goes into the stash")
	meta.call("reload")
	check_eq((meta.call("bag_places") as Array).size(), 4, "the bag is saved")
	# Bag and stash: moving, selling.
	check(meta.call("move_in_bag", 0, Vector2i(0, 0), false), "moving in the bag (onto itself)")
	check(meta.call("bag_to_stash", 0), "a fur from the bag into the stash")
	check_eq((meta.call("bag_places") as Array).size(), 3, "one less in the bag")
	var stash_fur: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur" and place.has("x"))
	check(not meta.call("stash_fits_bag", stash_fur, Vector2i(7, 0), false), "half outside the bag: no")
	var free: Dictionary = (meta.call("_bag_model") as Object).call("free_spot", "rat_fur")
	check(meta.call("stash_to_bag", stash_fur, Vector2i(int(free["x"]), int(free["y"])), false), "and back from the stash into the bag")
	var box: int = meta.call("box")
	check_eq(meta.call("sell_from_bag", 0), 2, "Egon buys a fur from the bag")
	check_eq(int(meta.call("box")), box + 2, "into the box")
	# A run starts with the bag brought home.
	var next_run: Object = script("res://scripts/systems/run_state.gd").new(3)
	# This test wants an empty bag (player.json could give start bombs).
	(next_run.get("bag") as Object).call("clear")
	(next_run.get("bag") as Object).call("restore", meta.call("bag_places"))
	check_eq(((next_run.get("bag") as Object).call("contents") as Array).size(), (meta.call("bag_places") as Array).size(), "the next run starts with it")


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
	# This test wants an empty bag (player.json could give start bombs).
	(wallet.get("bag") as Object).call("clear")
	var bag: Object = wallet.get("bag")
	check_eq(wallet.call("add_coins", 30), 0, "30 gold fit")
	check_eq(wallet.get("coins"), 30, "coins = gold in the bag")
	check_eq((bag.call("get_place", 0) as Dictionary).get("id"), "gold", "the gold lies on a place of the bag")
	wallet.call("add_coins", 990)
	check_eq((bag.call("get_place", 0) as Dictionary).get("count"), 999, "gold stacks to 999 on one place")
	check(wallet.call("spend", 20), "paying works")
	check_eq(wallet.get("coins"), 1000, "and takes the gold out of the bag")
	check(not wallet.call("spend", 5000), "not more than there is")
	check(bag.call("move_to", 0, bag.get("SAFE_ORIGIN"), false), "the gold into the safe place")
	var kept: Array[Dictionary] = bag.call("lose_unsafe")
	check_eq(wallet.get("coins"), 979, "death: the gold in the safe place stays")
	meta.call("end_run", 0, kept, RandomNumberGenerator.new())
	check(int(meta.call("box")) + int(meta.call("last_theft")) == 979, "and goes into the box at home")
	check((meta.call("stash") as Array).is_empty(), "not into the inventory")


## The merchant in the dungeon shop buys loot at its loot.json value (+ Goldnase per piece);
## the gold lands in the bag. The gold itself and places that do not exist cannot be sold.
func _sell_in_dungeon() -> void:
	var wallet: Object = script("res://scripts/systems/run_state.gd").new(4)
	# This test wants an empty bag (player.json could give start bombs).
	(wallet.get("bag") as Object).call("clear")
	var bag: Object = wallet.get("bag")
	bag.call("add", "ruby", 1)
	bag.call("add", "rat_fur", 1)
	check_eq(wallet.call("sell_price", 0), 25, "a ruby: 25 gold")
	check_eq(wallet.call("sell_from_bag", 0), 25, "sold")
	check_eq(wallet.get("coins"), 25, "the gold is in the bag")
	var gold: int = _index_of(bag, "gold")
	check_eq(_at(bag, gold), Vector2i(0, 0), "in the first free cell")
	check_eq(wallet.call("sell_from_bag", gold), 0, "the gold itself cannot be sold")
	check_eq(wallet.call("sell_from_bag", 9), 0, "a place that does not exist gives nothing")
	wallet.set("sell_bonus", 2)
	check_eq(wallet.call("sell_from_bag", _index_of(bag, "rat_fur")), 4, "Goldnase: rat fur 2 + 2")
	check_eq(wallet.get("coins"), 29, "onto the gold stack")
	check_eq(bag.call("count_of", "rat_fur"), 0, "the fur is gone")
	# Amber in the safe place: its gold goes onto the gold stack.
	check(bag.call("put_at", bag.get("SAFE_ORIGIN"), "amber", 1, false), "amber into the safe place")
	check_eq(wallet.call("sell_from_bag", _index_of(bag, "amber")), 14, "amber from the safe place: 12 + 2")
	check_eq(wallet.get("coins"), 43, "gold stacks")
	# Without a gold stack and no room: the gold lies where the sold loot lay.
	var full: Object = script("res://scripts/systems/run_state.gd").new(6)
	# This test wants an empty bag (player.json could give start bombs).
	(full.get("bag") as Object).call("clear")
	var full_bag: Object = full.get("bag")
	full_bag.call("add", "coal", 24)
	check_eq(full_bag.call("room_for", "coal"), 0, "the bag is full of coal")
	check(full_bag.call("put_at", full_bag.get("SAFE_ORIGIN"), "rat_fur", 1, false), "a fur in the safe place")
	check_eq(full.call("sell_from_bag", _index_of(full_bag, "rat_fur")), 2, "fur from the safe place")
	check(full_bag.call("is_safe", _index_of(full_bag, "gold")), "the gold lies in the safe place then")
	check_eq(full.get("coins"), 2, "nothing is lost")
