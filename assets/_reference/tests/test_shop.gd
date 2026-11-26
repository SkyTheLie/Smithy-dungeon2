extends "res://assets/_reference/_lib/base_test.gd"
## Egon's shop rules (MetaState, ShopGoods, data/shop.json, data/gear.json): the lever (first pull
## of a day free, then dearer, not without gold), the goods on the table, buying, putting gear on
## and taking it off, the tutorial table and a new day. Fixed seeds.

var meta: Script
var goods: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	goods = script("res://scripts/systems/shop_goods.gd")
	meta.call("start_new")
	_data()
	_lever()
	_buy_and_equip()
	_tutorial_and_new_day()
	_gear_in_run()


func _data() -> void:
	var shop: Dictionary = script("res://scripts/core/content.gd").call("shop")
	var gear: Dictionary = script("res://scripts/core/content.gd").call("gear")
	var slots: Dictionary = script("res://scripts/core/content.gd").call("gear_slots")
	for entry: Array in shop.get("pool", []):
		check(gear.has(String(entry[0])), "pool item %s is in gear.json" % entry[0])
	for id: String in gear:
		check(slots.has(String(gear[id].get("slot", ""))), "%s has a known slot" % id)
		check(ResourceLoader.exists(String(gear[id].get("icon", ""))), "%s has a picture" % id)
	var tutorial: Dictionary = shop.get("tutorial", {})
	var on_table: Array = (tutorial.get("goods", []) as Array).map(func(entry: Dictionary) -> String: return String(entry["id"]))
	for id: Variant in tutorial.get("gifts", []):
		check(on_table.has(id), "gift %s lies on the tutorial table" % id)
	check_eq(goods.call("price", "copper_staff", 1), 30, "price R1 = base price")
	check_eq(goods.call("price", "copper_staff", 2), 60, "price R2 = base price x 2")
	check_eq(goods.call("roll_price", 0), 0, "the first pull of a day is free")
	check_eq(goods.call("roll_price", 1), 10, "the second costs 10")
	check_eq(goods.call("roll_price", 99), 80, "later pulls cost the last price")


func _lever() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	check((meta.call("table") as Array).is_empty(), "no goods before the first pull")
	check(meta.call("pull_lever", rng), "the free pull works without gold")
	var table: Array = meta.call("table")
	check_eq(table.size(), 10, "10 places on the table")
	var pieces: int = table.filter(func(place: Dictionary) -> bool: return not place.is_empty()).size()
	check(pieces >= 1 and pieces <= 3, "1 to 3 goods (%d)" % pieces)
	check_eq(meta.call("lever_price"), 10, "now the lever costs 10")
	check(not meta.call("pull_lever", rng), "no second pull without gold")
	check_eq(meta.call("table"), table, "a refused pull changes nothing")
	meta.call("end_run", 25, [] as Array[Dictionary], rng)
	check_eq(meta.call("lever_price"), 0, "a new day: the lever is free again")
	meta.call("pull_lever", rng)
	check(meta.call("pull_lever", rng), "with 25 gold the second pull works")
	check_eq(meta.call("purse"), 15, "it cost 10")


func _buy_and_equip() -> void:
	# A known table: the tutorial goods.
	meta.call("lay_tutorial_table")
	var table: Array = meta.call("table")
	var staff: int = table.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_staff")
	var boots: int = table.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_boots")
	check(not meta.call("buy", staff), "the staff (30) is too dear for 15 gold")
	check(meta.call("buy", boots), "the boots (15) can be bought")
	check_eq(meta.call("purse"), 0, "they cost 15")
	check((meta.call("table") as Array)[boots].is_empty(), "the place on the table is empty now")
	check(not meta.call("buy", boots), "an empty place cannot be bought")
	check(meta.call("buy", staff, true), "Egon's gift costs nothing")
	var own: Array = meta.call("stash")
	check_eq(own.size(), 2, "both lie in the inventory")
	check_eq(own[0], {"id": "copper_boots", "count": 1, "rarity": 1}, "gear in the inventory has its rarity")
	check(meta.call("equip", 0), "the boots go on")
	check_eq((meta.call("equipment") as Dictionary).get("feet"), {"id": "copper_boots", "rarity": 1}, "on the feet")
	check_eq((meta.call("stash") as Array).size(), 1, "and out of the inventory")
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 2}] as Array[Dictionary], RandomNumberGenerator.new())
	var fur: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur")
	check(not meta.call("equip", fur), "loot cannot be put on")
	check(meta.call("unequip", "feet"), "the boots come off")
	check(not (meta.call("equipment") as Dictionary).has("feet"), "the feet are bare")
	check(not meta.call("unequip", "feet"), "nothing to take off")
	var boots_again: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_boots")
	meta.call("equip", boots_again)
	var staff_index: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_staff")
	check(meta.call("equip", staff_index), "the staff goes on")
	check_eq((meta.call("equipment") as Dictionary).get("weapon", {}).get("id"), "copper_staff", "in the weapon slot")
	meta.call("reload")
	check_eq((meta.call("equipment") as Dictionary).get("weapon", {}).get("id"), "copper_staff", "equipment is saved")


func _tutorial_and_new_day() -> void:
	check_eq(meta.call("run_character"), "magier", "with the staff on you play the Magier")
	meta.call("lay_tutorial_table")
	var bow: int = (meta.call("table") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_bow")
	meta.call("buy", bow, true)
	var bow_index: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_bow")
	meta.call("equip", bow_index)
	check_eq(meta.call("run_character"), "magier", "a bow while the Bogenschütze is locked: still the Magier")
	meta.call("unequip", "weapon")
	check_eq(meta.call("run_character"), "magier", "no weapon: the Magier")

	check(not meta.call("tutorial_done"), "Egon's tour has not happened yet")
	meta.call("finish_tutorial")
	meta.call("reload")
	check(meta.call("tutorial_done"), "after it, it is remembered")
	meta.call("start_new")
	check(not meta.call("tutorial_done"), "Neues Spiel: the tour comes again")
	check((meta.call("equipment") as Dictionary).is_empty(), "Neues Spiel: no equipment")


## What the hero wears counts in the run: armor = white shield hearts (taken first), the weapon's
## damage like an item.
func _gear_in_run() -> void:
	var run_script: Script = script("res://scripts/systems/run_state.gd")
	var bare: Object = run_script.new(5)
	var damage: float = (bare.get("stats") as Object).get("damage")
	var dressed: Object = run_script.new(5)
	dressed.call("use_gear", {
		"weapon": {"id": "copper_staff", "rarity": 1},
		"head": {"id": "copper_helmet", "rarity": 1},
		"chest": {"id": "copper_chest", "rarity": 1},
		"feet": {"id": "copper_boots", "rarity": 2}})
	check_eq(dressed.get("shield"), 3, "three armor pieces: 3 half shield hearts (R2 rounds to one half)")
	check(is_equal_approx((dressed.get("stats") as Object).get("damage"), damage + 0.2), "the copper staff adds 0.2 damage")
	var health: int = dressed.get("health")
	dressed.call("take_damage", 2)
	check_eq(dressed.get("shield"), 1, "a hit takes the shield hearts first")
	check_eq(dressed.get("health"), health, "red hearts untouched")
	dressed.call("take_damage", 2)
	check_eq(dressed.get("shield"), 0, "the last half shield heart is gone")
	check_eq(dressed.get("health"), health - 1, "the rest of the hit goes to the red hearts")
	check(not dressed.call("heal", 0) and dressed.get("shield") == 0, "shield hearts are not healed")
