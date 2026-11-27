extends "res://assets/_reference/_lib/base_test.gd"
## Egon's shop with the grid stash and the tabs: the stash is 5 x 4 (meta.json), pieces move by
## drag and drop (also turned), what has no room lies under "Kein Platz"; a backpack goes from the
## stash onto the Inventar tab (attached) and back into the stash; a click on a backpack attaches
## it; the buttons lie along the bottom edge; backpacks can come on Egon's table.


func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("announce_quest", "glutrubin")
	meta.call("give_piece", {"id": "kupferrucksack", "backpack": true})
	meta.call("give_piece", {"id": "kraeutertasche", "backpack": true})

	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var stash: Control = shop.call("get_stash_board")
	check_eq(stash.get("grid"), Vector2i(5, 4), "the stash: 5 wide, 4 high")
	for name: String in ["SkillsButton", "DungeonsButton"]:
		var button: Control = shop.find_child(name, true, false)
		check(button != null and button.position.y + button.size.y >= 350.0, "%s lies at the bottom edge" % name)
	check(shop.find_child("BackpacksButton", true, false) == null, "no extra backpack window any more")

	# Moving in the stash: the copper backpack (3 x 3) at 0,0, the pouch (2 x 2) beside it.
	var own: Array = meta.call("stash")
	check_eq(Vector2i(int(own[1]["x"]), int(own[1]["y"])), Vector2i(3, 0), "the pouch lies beside the copper backpack")
	var px: float = stash.get("cell_px")
	var drag: Dictionary = {"from": "stash", "index": 1, "piece": own[1], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check_eq(shop.call("_stash_judge", drag, Vector2i(3, 2), false), 1, "free below: fits")
	check_eq(shop.call("_stash_judge", drag, Vector2i(4, 2), false), 0, "out of the grid: no")
	stash.call("_drop_data", (Vector2(3, 2) + Vector2(0.5, 0.5)) * px, drag)
	own = meta.call("stash")
	check_eq(Vector2i(int(own[1]["x"]), int(own[1]["y"])), Vector2i(3, 2), "moved by drag and drop")

	# Inventar tab: the copper backpack from the stash onto the bag.
	var tab: Button = shop.find_child("InventoryTab", true, false)
	tab.pressed.emit()
	check((shop.call("get_inventory_tab") as Control).visible, "the Inventar tab shows the bag")
	var board: Control = shop.call("get_backpack_board")
	var area: Rect2i = script("res://scripts/systems/bag_layout.gd").call("board_rect")
	var bag_px: float = board.get("cell_px")
	var copper: Dictionary = {"from": "stash", "index": 0, "piece": own[0], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(3, 3)}
	var far: Vector2 = (Vector2(Vector2i(area.end.x - 3, area.end.y - 3) - area.position) + Vector2(0.5, 0.5)) * bag_px
	board.call("_drop_data", far, copper)
	check((meta.call("backpacks") as Array).is_empty(), "far from the bag: refused")
	var beside: Vector2 = (Vector2(Vector2i(8, 0) - area.position) + Vector2(0.5, 0.5)) * bag_px
	check(board.call("_can_drop_data", beside, copper), "the bag takes backpacks from the stash")
	board.call("_drop_data", beside, copper)
	check_eq((meta.call("backpacks") as Array).size(), 1, "attached right of the bag")
	check_eq((meta.call("stash") as Array).size(), 1, "and gone from the stash")
	# Back into the stash.
	var back: Dictionary = {"backpack": "kupferrucksack", "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(3, 3)}
	check(stash.call("_can_drop_data", Vector2(0.5, 0.5) * px, back), "the stash takes an attached backpack")
	stash.call("_drop_data", Vector2(0.5, 0.5) * px, back)
	check((meta.call("backpacks") as Array).is_empty(), "taken off again")
	check_eq((meta.call("stash") as Array).size(), 2, "into the stash")
	# A click on a backpack attaches it where it fits.
	var pouch: int = (meta.call("stash") as Array).find_custom(func(place: Dictionary) -> bool: return place.get("id") == "kraeutertasche")
	stash.emit_signal("clicked", pouch)
	await process_frame
	check_eq((meta.call("backpacks") as Array).size(), 1, "a click attaches the pouch")

	# No room: pieces lie under "Kein Platz", still in the stash list.
	for i in 6:
		meta.call("give_piece", {"id": "copper_helmet", "rarity": 1})
	shop.call("_refresh")
	own = meta.call("stash")
	var without: int = own.filter(func(place: Dictionary) -> bool: return not place.has("x")).size()
	check(without > 0, "a full stash: %d have no room" % without)
	check_eq((shop.get("_overflow_slots") as Dictionary).size(), without, "they show under Kein Platz")

	# Backpacks on Egon's table.
	var goods: Script = script("res://scripts/systems/shop_goods.gd")
	var piece: Dictionary = goods.call("make_backpack", "kraeutertasche")
	check(int(piece.get("price", 0)) > 0 and goods.call("is_backpack", piece), "a backpack has a price on the table")
	check_eq(goods.call("piece_size", piece), Vector2i(2, 2), "and covers its size")
	check_eq(goods.call("piece_size", {"id": "copper_gloves", "rarity": 1}), Vector2i(1, 1), "gloves: 1 cell")
	check_eq(goods.call("piece_size", {"id": "copper_helmet", "rarity": 1}), Vector2i(2, 2), "a helmet: 4 cells")
	shop.queue_free()
	await process_frame
