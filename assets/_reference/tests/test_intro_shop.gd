extends "res://assets/_reference/_lib/base_test.gd"
## Save slots A, B, C (MetaState), "Neues Spiel" -> intro -> Egon's shop (played through and
## skipped with Escape), the dungeon board in the shop and the character choice after "Betreten".

var meta: Script
var game: Node


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	game = root.get_node("Game")
	_slots()
	await _intro_played()
	await _intro_skipped()
	await _board()


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


func _intro_played() -> void:
	game.call("start_intro")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Intro", 2.0), "Neues Spiel opens the intro")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Shop", 20.0),
			"the intro walks to Egon by itself and ends in the shop")


func _intro_skipped() -> void:
	game.call("start_intro")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Intro", 2.0), "intro again")
	await process_frame
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Shop", 2.0), "Escape skips to the shop")


func _board() -> void:
	await process_frame
	var shop: Node = current_scene
	var board: Control = shop.call("get_board")
	var characters: Control = shop.call("get_character_select")
	check(not board.visible, "the board is closed at first")
	(shop.get_node("DungeonsButton") as Button).pressed.emit()
	check(board.visible, "the button at the bottom right opens the dungeon board")
	check_eq(board.call("get_selected"), "glut", "the first dungeon is chosen")
	board.emit_signal("entered", "glut")
	check(not board.visible and characters.visible, "Betreten asks for the character")
