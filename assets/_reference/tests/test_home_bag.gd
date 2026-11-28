extends "res://assets/_reference/_lib/base_test.gd"
## The bag at home (MetaState.bag_places) in Egon's shop, tab Inventar: the loot brought home lies
## in it on its cells, can be moved, dragged into the stash and back, into the safe place, onto the
## table (sold); a backpack with loot in it stays attached; the board is big enough to see.
## Gear (with its rarity) goes from the stash into the bag too, comes along into the run, is lost
## on death outside the safe place and goes back into the stash with its rarity.


func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("announce_quest", "glutrubin")
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 1, "x": 0, "y": 0, "rot": false}, {"id": "copper_ore", "count": 1, "x": 5, "y": 1, "rot": false}] as Array[Dictionary], RandomNumberGenerator.new())
	check_eq((meta.call("bag_places") as Array).size(), 2, "the loot came home in the bag")

	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	(shop.find_child("InventoryTab", true, false) as Button).pressed.emit()
	var board: Control = shop.call("get_backpack_board")
	var px: float = board.get("cell_px")
	check(px >= 14.0, "the bag is big enough to see (%d px per cell)" % int(px))
	check_eq(board.call("place_at", Vector2i(1, 1)), 0, "the fur lies on its cells (2 x 2)")
	check_eq(board.call("place_at", Vector2i(5, 1)), 1, "the ore on its cell")
	var area: Rect2i = script("res://scripts/systems/bag_layout.gd").call("board_rect")

	# Moving in the bag.
	var drag: Variant = board.call("_get_drag_data", (Vector2(Vector2i(0, 0) - area.position) + Vector2(0.5, 0.5)) * px)
	check(drag is Dictionary and (drag as Dictionary).get("from") == "bag", "the fur can be dragged")
	board.call("_drop_data", (Vector2(Vector2i(2, 1) - area.position) + Vector2(0.5, 0.5)) * px, drag)
	var fur: Dictionary = (meta.call("bag_places") as Array).filter(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")[0]
	check_eq(Vector2i(int(fur["x"]), int(fur["y"])), Vector2i(2, 1), "moved in the bag")

	# Into the safe place.
	var safe: Control = shop.get("_safe_board")
	var fur_index: int = (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")
	var fur_drag: Dictionary = {"from": "bag", "index": fur_index, "piece": fur, "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check(safe.call("_can_drop_data", Vector2(1, 1), fur_drag), "the safe place takes loot")
	safe.call("_drop_data", Vector2(1, 1), fur_drag)
	fur = (meta.call("bag_places") as Array).filter(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")[0]
	check(int(fur["x"]) >= 1000, "the fur lies in the safe place now")

	# From the bag into the stash and back.
	var stash: Control = shop.call("get_stash_board")
	var ore_index: int = (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_ore")
	var ore: Dictionary = (meta.call("bag_places") as Array)[ore_index]
	var ore_drag: Dictionary = {"from": "bag", "index": ore_index, "piece": ore, "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	check_eq(shop.call("_stash_judge", ore_drag, Vector2i(4, 3), false), 1, "the ore over a free stash cell: green")
	stash.call("_drop_data", (Vector2(4, 3) + Vector2(0.5, 0.5)) * float(stash.get("cell_px")), ore_drag)
	var own: Array = meta.call("stash")
	check(own.size() == 1 and own[0].get("id") == "copper_ore", "into the stash")
	check_eq(Vector2i(int(own[0].get("x", -1)), int(own[0].get("y", -1))), Vector2i(4, 3), "onto that cell")
	var back: Dictionary = {"from": "stash", "index": 0, "piece": own[0], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	check(board.call("_can_drop_data", (Vector2(Vector2i(7, 2) - area.position) + Vector2(0.5, 0.5)) * px, back), "the bag takes loot from the stash")
	board.call("_drop_data", (Vector2(Vector2i(7, 2) - area.position) + Vector2(0.5, 0.5)) * px, back)
	check((meta.call("stash") as Array).is_empty(), "the stash is empty again")
	check((meta.call("bag_places") as Array).any(func(p: Dictionary) -> bool: return p.get("id") == "copper_ore" and int(p["x"]) == 7 and int(p["y"]) == 2), "the ore lies in the bag at 7,2")
	_gear_in_bag(meta, board, area, px)

	# Selling from the bag: onto the table.
	var table: Control = shop.call("get_table_board")
	ore_index = (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_ore")
	var sell: Dictionary = {"from": "bag", "index": ore_index, "piece": (meta.call("bag_places") as Array)[ore_index], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	var box: int = meta.call("box")
	check(table.call("_can_drop_data", Vector2(5, 5), sell), "the table takes loot from the bag")
	table.call("_drop_data", Vector2(5, 5), sell)
	check_eq(int(meta.call("box")), box + 3, "sold for its value")

	# A backpack with loot in it stays.
	meta.call("give_piece", {"id": "kraeutertasche", "backpack": true})
	var pouch: int = (meta.call("stash") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "kraeutertasche")
	check(meta.call("attach_backpack", pouch, Vector2i(8, 0), false), "a pouch right of the bag")
	var bag: Object = meta.call("_bag_model")
	check(meta.call("move_in_bag", (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur"), Vector2i(8, 0), false), "the fur goes into the pouch")
	check(not meta.call("detach_backpack", "kraeutertasche"), "the pouch holds the fur: it stays")
	check(not meta.call("place_backpack", "kraeutertasche", Vector2i(0, 3), false), "and does not move")
	check(bag != null, "(bag model)")
	shop.queue_free()
	await process_frame
	_keys_home(meta)


func _gear_in_bag(meta: Script, board: Control, area: Rect2i, px: float) -> void:
	meta.call("give_piece", {"id": "copper_helmet", "rarity": 3})
	var helmet: Dictionary = {"from": "stash", "index": 0, "piece": (meta.call("stash") as Array)[0], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	var at: Vector2 = (Vector2(Vector2i(0, 0) - area.position) + Vector2(0.5, 0.5)) * px
	check(board.call("_can_drop_data", at, helmet), "the bag takes gear from the stash")
	check(meta.call("stash_fits_bag", 0, Vector2i(0, 0), false), "gear fits into the bag")
	board.call("_drop_data", at, helmet)
	check((meta.call("stash") as Array).is_empty(), "the helmet left the stash")
	var index: int = (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	check(index >= 0, "the helmet lies in the bag")
	var place: Dictionary = (meta.call("bag_places") as Array)[index]
	check_eq(int(place.get("rarity", 0)), 3, "it keeps its rarity")
	check_eq(Vector2i(int(place["x"]), int(place["y"])), Vector2i(0, 0), "on the cell it was dropped on")
	# Into the run: the bag of the run has it; dying without the safe place loses it.
	var bag: Object = script("res://scripts/systems/bag.gd").new()
	bag.call("restore", meta.call("bag_places"))
	check_eq(bag.call("count_of", "copper_helmet"), 1, "the run starts with the helmet")
	check(bag.call("move_to", (bag.get("places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet"), Vector2i(6, 0), false), "gear moves in the bag of the run")
	bag.call("lose_unsafe")
	check_eq(bag.call("count_of", "copper_helmet"), 0, "death: the helmet is gone (not in the safe place)")
	# A run that ends well brings it home in the bag, still rarity 3.
	meta.call("end_run", 0, meta.call("bag_places"), RandomNumberGenerator.new())
	index = (meta.call("bag_places") as Array).find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	check(index >= 0 and int((meta.call("bag_places") as Array)[index].get("rarity", 0)) == 3, "home again in the bag with its rarity")
	# Back into the stash, still rarity 3.
	check(meta.call("bag_to_stash", index), "back into the stash")
	var own: Array = meta.call("stash")
	check(own.size() == 1 and own[0].get("id") == "copper_helmet" and int(own[0].get("rarity", 0)) == 3, "in the stash with its rarity")


## Leaving the dungeon: fragile keys break, iron keys and bombs come home in the bag; the next
## run only tops the start bombs up (no free pile).
func _keys_home(meta: Script) -> void:
	meta.call("start_new")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var kept: Array[Dictionary] = [{"id": "key", "count": 1, "x": 0, "y": 0}, {"id": "iron_key", "count": 1, "x": 1, "y": 0}, {"id": "bomb", "count": 3, "x": 2, "y": 0}]
	meta.call("end_run", 0, kept, rng)
	var ids: Array[String] = []
	for place: Dictionary in meta.call("bag_places"):
		ids.append(String(place["id"]))
	check(not ids.has("key"), "the fragile key broke")
	check(ids.has("iron_key"), "the iron key came home")
	check(ids.has("bomb"), "the bombs came home")
	var run: Object = script("res://scripts/systems/run_state.gd").new(1)
	run.get("bag").call("remove", "bomb", run.get("bombs"))
	run.get("bag").call("restore", meta.call("bag_places"))
	run.call("top_up_start")
	check_eq(run.get("bombs"), 3, "three bombs from home, no extra start bomb on top")
	check_eq(run.get("keys"), 1, "the iron key goes into the dungeon again")

