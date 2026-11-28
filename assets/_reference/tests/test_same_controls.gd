extends "res://assets/_reference/_lib/base_test.gd"
## The same controls at home and in the dungeon: Shift+click in the shop puts a stash piece into
## the inventory (MetaState.stash_to_bag_anywhere); in the bag window (Tab) it moves a piece into
## the safe place and back (BagWindow.shift_move). The key help can be switched off (setting
## "ui" / "key_help"); the shop's line follows it.

func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("admin_give_loot", "rat_fur")
	var before: int = (meta.call("bag_places") as Array).size()
	var fur: int = (meta.call("stash") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")
	check(meta.call("stash_to_bag_anywhere", fur), "Shift+click: stash piece into the inventory")
	check_eq((meta.call("bag_places") as Array).size(), before + 1, "it lies in the inventory now")
	check(not (meta.call("stash") as Array).any(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur"), "and not in the stash any more")
	# Tab in the dungeon.
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(5)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var bag: Object = run_state.get("bag")
	bag.call("add", "rat_fur", 1)
	var window: Node = scene.get("bag_window")
	window.call("open")
	await process_frame
	var index: int = -1
	for i in int(bag.call("size")):
		if String((bag.call("get_place", i) as Dictionary).get("id", "")) == "rat_fur":
			index = i
	var place: Dictionary = bag.call("get_place", index)
	check_eq(bag.call("section_of", Vector2i(int(place["x"]), int(place["y"]))), "main", "the fur lies in the bag")
	check(window.call("shift_move", index), "Shift+click moves it")
	place = bag.call("get_place", index)
	check_eq(bag.call("section_of", Vector2i(int(place["x"]), int(place["y"]))), "safe", "into the safe place")
	check(window.call("shift_move", index), "and back")
	place = bag.call("get_place", index)
	check_eq(bag.call("section_of", Vector2i(int(place["x"]), int(place["y"]))), "main", "into the bag again")
	window.call("close")
	scene.queue_free()
	await process_frame
	# Key help off.
	script("res://scripts/core/window_layout.gd").call("set_setting", "ui", "key_help", false)
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	check(not (shop.get("_key_help") as Label).visible, "key help off: no line in the shop")
	shop.queue_free()
	await process_frame
	script("res://scripts/core/window_layout.gd").call("set_setting", "ui", "key_help", true)
