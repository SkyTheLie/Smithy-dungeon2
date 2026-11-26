extends "res://assets/_reference/_lib/base_test.gd"
## Save slots A, B, C (MetaState), "Neues Spiel" -> intro -> Egon's shop (skipped with Escape and
## clicked through), Egon's tour (gifts bought and put on, board forced open), the dungeon board
## in the shop, and "Betreten" goes straight into the dungeon as the character of the weapon.

var meta: Script
var game: Node


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	game = root.get_node("Game")
	_slots()
	await _intro_skipped()
	await _intro_and_tour()
	await _board()
	await _money_box()


func _slots() -> void:
	check_eq(meta.call("slot"), "a", "slot A at the first start")
	check(not meta.call("has_save"), "no game in a fresh slot")
	meta.call("set_slot", "b")
	meta.call("start_new")
	check(meta.call("has_save", "b"), "Neues Spiel saves slot B at once")
	check(not meta.call("has_save", "a"), "slot A stays empty")
	check_eq(meta.call("peek", "b"), {"day": 1, "gold": 0}, "slot B: day 1, no gold")
	check_eq(meta.call("peek", "c"), {}, "slot C is empty")
	meta.call("end_run", 30, [] as Array[Dictionary], RandomNumberGenerator.new())
	check_eq(meta.call("peek", "b"), {"day": 2, "gold": 30}, "the end of a day is saved in the slot")
	meta.call("set_slot", "x")
	check_eq(meta.call("slot"), "b", "unknown slots are ignored")
	meta.call("reload")
	check_eq(meta.call("slot"), "b", "the slot is remembered in the settings")
	var text: String = script("res://scenes/ui/main_menu/slot_select.gd").call("describe", "b")
	check_eq(text, "Spielstand B\nTag 2 · 30 Gold", "the slot button shows day and gold")
	meta.call("start_new")
	check_eq(meta.call("day"), 1, "Neues Spiel starts the slot over")


## Presses Space (Egon's next line) until `condition` holds or `max_seconds` passed.
func _click_until(condition: Callable, max_seconds: float) -> bool:
	var waited: float = 0.0
	while not condition.call():
		if waited >= max_seconds:
			return false
		var press := InputEventAction.new()
		press.action = "ui_accept"
		press.pressed = true
		Input.parse_input_event(press)
		var release := InputEventAction.new()
		release.action = "ui_accept"
		Input.parse_input_event(release)
		for i in 12:
			await physics_frame
		waited += 12.0 / 60.0
	return true


func _in_scene(scene_name: String) -> bool:
	return current_scene != null and current_scene.name == scene_name


func _intro_skipped() -> void:
	game.call("start_intro")
	check(await wait_until(_in_scene.bind("Intro"), 2.0), "Neues Spiel opens the intro")
	await process_frame
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	check(await wait_until(_in_scene.bind("Shop"), 2.0), "Escape skips to the shop")


## The whole intro by Space, then Egon's tour in the shop.
func _intro_and_tour() -> void:
	game.call("start_intro")
	check(await wait_until(_in_scene.bind("Intro"), 2.0), "intro again (the slot started over)")
	check(await _click_until(_in_scene.bind("Shop"), 40.0), "Egon calls, you walk to him, he talks, then the shop")
	await process_frame
	var shop: Node = current_scene
	var board: Control = shop.call("get_board")
	check(await _click_until(func() -> bool: return board.visible, 60.0), "after his tour Egon opens the dungeon board")
	check(meta.call("tutorial_done"), "the tour is remembered")
	var worn: Dictionary = meta.call("equipment")
	check_eq([String(worn.get("weapon", {}).get("id")), String(worn.get("head", {}).get("id")), String(worn.get("chest", {}).get("id"))],
			["copper_staff", "copper_helmet", "copper_chest"], "Egon put his three gifts on you")
	check((meta.call("stash") as Array).is_empty(), "nothing left in the inventory")
	check_eq(meta.call("purse"), 0, "the gifts were free")
	check(board.get("forced"), "the board cannot be closed: off into the dungeon")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	await process_frame
	check(board.visible, "Escape does not close it")


func _board() -> void:
	game.call("to_shop")
	check(await wait_until(func() -> bool: return _in_scene("Shop") and current_scene.is_node_ready(), 2.0), "back in the shop (Weiter)")
	await process_frame
	var shop: Node = current_scene
	var board: Control = shop.call("get_board")
	check(not board.visible, "the board is closed at first (no tour the second time)")
	(shop.find_child("DungeonsButton", true, false) as Button).pressed.emit()
	check(board.visible and not board.get("forced"), "the button at the bottom right opens the dungeon board")
	check_eq(board.call("get_selected"), "glut", "the first dungeon is chosen")
	board.emit_signal("entered", "glut")
	check(await wait_until(_in_scene.bind("Run"), 3.0), "Betreten goes straight into the dungeon (no character window)")
	check_eq(String((game.get("run") as Object).get("character")), "magier", "as the Magier (Egon's staff)")


## The money box (Dose) in the shop: "Dose 0/200" green, over the limit red with Egon's warning;
## the coin bag dragged onto it = all in, dragged back = all out, +10 / −10.
func _money_box() -> void:
	meta.call("end_run", 250, [] as Array[Dictionary], RandomNumberGenerator.new())
	game.call("to_shop")
	check(await wait_until(func() -> bool: return _in_scene("Shop") and current_scene.is_node_ready(), 2.0), "the shop again")
	await process_frame
	var shop: Node = current_scene
	var label: Label = shop.get("_box_label")
	var warning: Label = shop.get("_box_warning")
	check(label.text.ends_with("0/200"), "an empty box: 0/200 (%s)" % label.text)
	check(not warning.visible, "no warning")
	var own: Array = meta.call("stash")
	var bag_index: int = own.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "gold")
	check(bag_index >= 0, "the gold at home is a coin bag in the inventory")
	var data: Variant = shop.call("_drag_from_inventory", Vector2.ZERO, bag_index)
	check(shop.call("_can_drop_on_box", Vector2.ZERO, data), "the coin bag can be dragged onto the box")
	shop.call("_drop_on_box", Vector2.ZERO, data)
	check_eq(meta.call("box"), 250, "all gold in the box")
	check(label.text.ends_with("250/200"), "250/200")
	check(warning.visible and label.get_theme_color("font_color").r > 0.9 and label.get_theme_color("font_color").g < 0.5, "over the limit: red with Egon's warning")
	(shop.find_child("BoxOut", true, false) as Button).pressed.emit()
	check_eq(meta.call("box"), 240, "−10")
	shop.call("_drop_on_inventory", Vector2.ZERO, shop.call("_drag_from_box", Vector2.ZERO))
	check_eq(meta.call("box"), 0, "dragged back: all out")
	(shop.find_child("BoxIn", true, false) as Button).pressed.emit()
	check_eq(meta.call("box"), 10, "+10")
	check(not warning.visible and label.get_theme_color("font_color").g > 0.8, "up to the limit: green")
