extends "res://assets/_reference/_lib/base_test.gd"
## Egon's shop with backpacks from the skill tree: the button "Rucksäcke" shows how many are not
## attached, the window attaches one by drag and drop (BackpackBoard, MetaState.place_backpack),
## a backpack that would not touch the bag is refused, the list takes one off again.


func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	var path: String = meta.call("path_of", meta.call("slot"))
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("meta", "skills", {"rucksack": 1, "kupferrucksack": 1})
	config.save(path)
	meta.call("reload")

	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var button: Button = shop.find_child("BackpacksButton", true, false)
	check(button != null and button.visible, "the button shows once backpacks are owned")
	if button == null:
		return
	check(button.text.contains("(2)"), "two wait to be attached (%s)" % button.text)
	button.pressed.emit()
	var window: Control = shop.call("get_backpack_window")
	check(window.visible, "the backpack window opens")
	var board: Control = window.get("board")
	await process_frame
	var area: Rect2i = script("res://scripts/systems/bag_layout.gd").call("board_rect")
	var px: float = board.get("cell_px")
	var drag: Dictionary = {"backpack": "kupferrucksack", "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(3, 3)}
	var far: Vector2 = (Vector2(Vector2i(area.end.x - 3, area.end.y - 3) - area.position) + Vector2(0.5, 0.5)) * px
	board.call("_drop_data", far, drag)
	check((meta.call("backpacks") as Array).is_empty(), "a backpack far from the bag is refused")
	var beside: Vector2 = (Vector2(Vector2i(8, 0) - area.position) + Vector2(0.5, 0.5)) * px
	check(board.call("_can_drop_data", beside, drag), "the board takes backpacks")
	board.call("_drop_data", beside, drag)
	check_eq((meta.call("backpacks") as Array).size(), 1, "attached right of the bag")
	check_eq(board.call("backpack_at", Vector2i(10, 2)), "kupferrucksack", "covering 3 x 3 cells")
	window.call("_drop_on_list", Vector2.ZERO, drag)
	check((meta.call("backpacks") as Array).is_empty(), "dropped on the list: taken off again")
	window.call("hide")
	await process_frame
	check(button.text.contains("(2)"), "both loose again")
	shop.queue_free()
	await process_frame
