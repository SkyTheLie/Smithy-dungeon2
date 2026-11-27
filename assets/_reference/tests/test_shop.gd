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
	_relics()
	_selling()
	_admin()


func _data() -> void:
	var shop: Dictionary = script("res://scripts/core/content.gd").call("shop")
	var gear: Dictionary = script("res://scripts/core/content.gd").call("gear")
	var slots: Dictionary = script("res://scripts/core/content.gd").call("gear_slots")
	# Every material has every piece of the pool (gear.json <material>_<piece>).
	for material: String in (shop.get("materials", {}) as Dictionary):
		for entry: Array in shop.get("pool", []):
			check(gear.has("%s_%s" % [material, entry[0]]), "%s_%s is in gear.json" % [material, entry[0]])
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
	check_eq(meta.call("box"), 15, "it cost 10")


func _buy_and_equip() -> void:
	# A known table: the tutorial goods.
	meta.call("lay_tutorial_table")
	var table: Array = meta.call("table")
	var staff: int = table.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_staff")
	var boots: int = table.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_boots")
	check(not meta.call("buy", staff), "the staff (30) is too dear for 15 gold")
	check(meta.call("buy", boots), "the boots (15) can be bought")
	check_eq(meta.call("box"), 0, "they cost 15")
	check((meta.call("table") as Array)[boots].is_empty(), "the place on the table is empty now")
	check(not meta.call("buy", boots), "an empty place cannot be bought")
	check(meta.call("buy", staff, true), "Egon's gift costs nothing")
	var own: Array = meta.call("stash")
	check_eq(own.size(), 2, "both lie in the inventory")
	check(own[0].get("id") == "copper_boots" and int(own[0].get("rarity", 0)) == 1, "gear in the inventory has its rarity")
	check_eq(Vector2i(int(own[0].get("x", -1)), int(own[0].get("y", -1))), Vector2i(0, 0), "it lies top left in the stash grid")
	check_eq(Vector2i(int(own[1].get("x", -1)), int(own[1].get("y", -1))), Vector2i(2, 0), "the staff (2 x 2) beside it")
	check(meta.call("equip", 0), "the boots go on")
	check_eq((meta.call("equipment") as Dictionary).get("feet"), {"id": "copper_boots", "rarity": 1}, "on the feet")
	check_eq((meta.call("stash") as Array).size(), 1, "and out of the inventory")
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 2}] as Array[Dictionary], RandomNumberGenerator.new())
	check(meta.call("bag_to_stash", 0), "a fur from the bag into the stash")
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
		"legs": {"id": "copper_legs", "rarity": 2}})
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


## Relics (data/relics.json): only found items come on the table; bought they go into the relic
## slot, work in the run like the item, weak ones hold for ever, strong ones break after their runs.
func _relics() -> void:
	var progress: Script = script("res://scripts/systems/progress.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	check_eq(goods.call("pick_relic", rng), "", "nothing found yet: no relics")
	check(goods.call("relic_tier", "moorherz") == 1 and goods.call("relic_runs", "moorherz") == 5, "Moorherz (+1 heart) is weak and holds 5 dungeons")
	check(goods.call("relic_tier", "dreizack") == 4 and goods.call("relic_runs", "dreizack") == 1, "Dreifachschuss is strong and holds one dungeon")
	check_eq(goods.call("relic_tier", "glutstab"), 0, "the start weapons are no relics")
	progress.call("discover", "dreizack")
	check_eq(goods.call("pick_relic", rng), "", "level 0: only relic tier R1 can come, the Dreifachschuss is R4")
	progress.call("discover", "moorherz")
	check_eq(goods.call("pick_relic", rng), "moorherz", "a found R1 item can come as a relic")
	check_eq(goods.call("rarity_chances"), [[1, 100.0]], "level 0: only R1 on the table")
	meta.call("add_exp", 100000)
	check(int(meta.call("level")) >= 20, "level 20 or more (%d)" % meta.call("level"))
	var chances: Array = goods.call("rarity_chances")
	check(chances.size() >= 5 and is_equal_approx(chances.reduce(func(sum: float, part: Array) -> float: return sum + float(part[1]), 0.0), 100.0),
			"higher level: more rarities, together 100 %")
	check_eq(goods.call("open_relic_tiers"), [1, 2, 3, 4] as Array[int], "from level 20: every relic tier")
	var found: bool = false
	for i in 60:
		var table: Array = goods.call("roll", rng)
		if table.any(func(place: Dictionary) -> bool: return place.get("relic", false)):
			found = true
			break
	check(found, "now and then a relic lies on the table")
	meta.call("start_new")
	meta.call("gift_gold", 500)
	meta.call("_write", "table", [goods.call("make_relic", "dreizack")])
	check(meta.call("buy", 0), "a relic can be bought")
	check_eq(meta.call("box"), 250, "tier 4 costs 250")
	var own: Array = meta.call("stash")
	check(own[0].get("relic") and own[0].get("left") == 1, "it lies in the inventory, one dungeon left")
	check(meta.call("equip", 0), "it goes into the relic slot")
	check((meta.call("equipment") as Dictionary).has("relic_1"), "on the hero")
	var run: Object = script("res://scripts/systems/run_state.gd").new(4)
	run.call("use_gear", meta.call("equipment"))
	check((run.get("items") as Array).has("dreizack"), "in the run it works like the item")
	meta.call("end_run", 0, [] as Array[Dictionary], RandomNumberGenerator.new())
	check(not (meta.call("equipment") as Dictionary).has("relic_1"), "after its dungeon it is broken")
	check_eq(meta.call("broken_relic"), "dreizack", "Egon knows which one")
	meta.call("_write", "table", [goods.call("make_relic", "moorherz")])
	meta.call("buy", 0)
	meta.call("equip", (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "moorherz"))
	for i in 4:
		meta.call("end_run", 0, [] as Array[Dictionary], RandomNumberGenerator.new())
	check_eq(String((meta.call("equipment") as Dictionary).get("relic_1", {}).get("id", "")), "moorherz", "a weak relic holds 5 dungeons: still there after 4")
	meta.call("end_run", 0, [] as Array[Dictionary], RandomNumberGenerator.new())
	check(not (meta.call("equipment") as Dictionary).has("relic_1"), "and broken after the 5th (without Reliktschutz)")


## Selling to Egon: loot for its loot.json value (the whole stack), gear and relics for
## shop.json sell_share of their price; the gold goes into the box.
func _selling() -> void:
	meta.call("start_new")
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 3}] as Array[Dictionary], RandomNumberGenerator.new())
	for i in 3:
		meta.call("bag_to_stash", 0)
	meta.call("lay_tutorial_table")
	var table: Array = meta.call("table")
	meta.call("buy", table.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_staff"), true)
	var own: Array = meta.call("stash")
	check_eq(own.size(), 4, "3 rat furs (each on its own) and the staff")
	check_eq(goods.call("sell_price", own[0]), 2, "a rat fur: 2 gold")
	check_eq(goods.call("sell_price", own[3]), 9, "the copper staff (30): 30 % = 9 gold")
	check_eq(meta.call("sell", 0), 2, "sold")
	check_eq(meta.call("box"), 2, "the gold is in the box")
	check_eq((meta.call("stash") as Array).filter(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur").size(), 2, "one fur is gone")
	check(not (meta.call("stash") as Array).any(func(place: Dictionary) -> bool: return place.get("id") == "gold"), "no coin bag in the inventory")
	check_eq(meta.call("sell", 5), 0, "a place that does not exist sells nothing")


## The admin menu of the shop (ShopAdminMenu) only calls these.
func _admin() -> void:
	meta.call("start_new")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	meta.call("admin_set_box", 500)
	check_eq(meta.call("box"), 500, "admin: box set")
	meta.call("admin_set_box", -3)
	check_eq(meta.call("box"), 0, "admin: box never below 0")
	check(meta.call("admin_give_loot", "rat_fur"), "admin: loot into the stash")
	check(not meta.call("admin_give_loot", "no_such_loot"), "admin: unknown loot refused")
	check_eq((meta.call("stash") as Array).size(), 1, "admin: one piece in the stash")
	meta.call("admin_clear_stash")
	check((meta.call("stash") as Array).is_empty(), "admin: stash empty")
	meta.call("admin_roll_table", rng)
	check_eq(meta.call("pulls_today"), 0, "admin: free goods are no pull")
	meta.call("pull_lever", rng)
	meta.call("admin_reset_lever")
	check_eq(meta.call("lever_price"), 0, "admin: lever free again")
	var day: int = meta.call("day")
	meta.call("admin_next_day")
	check_eq(meta.call("day"), day + 1, "admin: a new day")
	var points: int = meta.call("skill_points")
	meta.call("admin_add_skill_points", 5)
	check_eq(meta.call("skill_points"), points + 5, "admin: skill points")
