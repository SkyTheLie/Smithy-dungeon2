extends "res://assets/_reference/_lib/base_test.gd"
## Equipment sets (MetaState.save_gear_set / wear_gear_set): what is worn is saved as a set; after
## putting on other gear the set puts the saved pieces back on from the stash; an empty set does
## nothing. In the shop the set buttons sit right under the hero.

func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("give_piece", {"id": "copper_helmet", "rarity": 1})
	meta.call("give_piece", {"id": "copper_helmet", "rarity": 3})
	var own: Array = meta.call("stash")
	var plain: int = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet" and int(p.get("rarity")) == 1)
	check(meta.call("equip", plain, "head"), "wear the plain helmet")
	meta.call("save_gear_set", 1)
	check(not (meta.call("gear_set", 1) as Dictionary).is_empty(), "set 1 saved")
	own = meta.call("stash")
	var rare: int = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet" and int(p.get("rarity")) == 3)
	meta.call("equip", rare, "head")
	check_eq(int(((meta.call("equipment") as Dictionary)["head"] as Dictionary).get("rarity")), 3, "now the rare one is worn")
	check_eq(int(meta.call("wear_gear_set", 1)), 1, "set 1 changes one piece")
	check_eq(int(((meta.call("equipment") as Dictionary)["head"] as Dictionary).get("rarity")), 1, "the plain helmet is back on")
	check_eq(int(meta.call("wear_gear_set", 1)), 0, "again: nothing to do")
	check_eq(int(meta.call("wear_gear_set", 2)), 0, "an empty set does nothing")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	await process_frame
	var row: Control = shop.get("_gear_sets")
	var hero: Control = shop.get("_hero")
	check(row.position.y >= hero.position.y + hero.size.y, "the set buttons are under the hero")
	check(row.get_child_count() == int(meta.get("GEAR_SETS")), "one button per set")
	shop.queue_free()
	await process_frame
