extends "res://assets/_reference/_lib/base_test.gd"
## Comfort in Egon's shop: Strg+click locks a stash piece (MetaState.toggle_lock): it is not sold
## and stays where it is when sorting; sorting (T, MetaState.sort_stash) packs the rest from the top
## left; the stash tooltip says what Egon pays; before a run Egon names what is missing (empty
## potion place).

var meta: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("admin_give_loot", "rat_fur")
	meta.call("admin_give_loot", "rat_fur")
	meta.call("give_piece", {"id": "copper_helmet", "rarity": 1})
	var own: Array = meta.call("stash")
	check(own.size() == 3, "three pieces in the stash")
	# Lock the helmet.
	var helmet: int = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	check(meta.call("toggle_lock", helmet), "Strg+click locks it")
	check(int(meta.call("sell", helmet)) == 0, "a locked piece is not sold")
	own = meta.call("stash")
	helmet = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	var where := Vector2i(int(own[helmet]["x"]), int(own[helmet]["y"]))
	# Move a fur far away, then sort: the furs come back to the top left, the helmet stays.
	var fur: int = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")
	var grid: Vector2i = meta.call("stash_grid")
	meta.call("move_in_stash", fur, Vector2i(grid.x - 2, grid.y - 2), false)
	meta.call("sort_stash", "kind")
	own = meta.call("stash")
	helmet = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	check(Vector2i(int(own[helmet]["x"]), int(own[helmet]["y"])) == where, "the locked helmet stays where it was")
	var lowest: int = 99
	for piece: Dictionary in own:
		if piece.get("id") == "rat_fur":
			lowest = mini(lowest, int(piece.get("y", 99)))
	check(lowest <= 2, "sorting packs the furs from the top")
	meta.call("next_sort_mode")
	check_eq(meta.call("sort_mode"), "rarity", "right click: next way of sorting")
	# Tooltip: what Egon pays.
	var board: Object = script("res://scenes/shop/item_board.gd").new()
	board.set("show_sell_value", true)
	board.set("pieces", own)
	fur = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur")
	check(String(board.call("_tooltip", fur)).contains("Egon zahlt"), "the tooltip says what Egon pays")
	helmet = own.find_custom(func(p: Dictionary) -> bool: return p.get("id") == "copper_helmet")
	check(String(board.call("_tooltip", helmet)).contains("Gesperrt"), "and that a piece is locked")
	board.free()
	# Readiness: potions open, none on the hero.
	meta.call("unlock_potions")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	check(String(shop.call("readiness_warning")).contains("Trank"), "Egon names the empty potion place")
	shop.queue_free()
	await process_frame
