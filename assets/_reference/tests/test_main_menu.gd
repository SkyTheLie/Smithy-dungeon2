extends "res://assets/_reference/_lib/base_test.gd"
## The title page ("Hier klicken") comes only once per program start: after the player got past
## it, the main menu (e.g. "Hauptmenü" from Egon's shop) starts right at the anvil.

var menu_script: Script


func run() -> void:
	menu_script = script("res://scenes/ui/main_menu/main_menu.gd")
	menu_script.set("slot_chosen", true)
	# The language question would come first on a fresh user://.
	script("res://scripts/core/language.gd").call("set_current", "de")
	var first: Node = await _open()
	check((first.get_node("%TitlePage") as Control).visible, "first start: the title page")
	check(not (first.get_node("%MenuPage") as Control).visible, "the menu waits behind the door")
	(first.get_node("Backdrop") as Node).call("skip")
	check((first.get_node("%MenuPage") as Control).visible, "past the door: the menu")
	check(menu_script.get("title_seen"), "the title page was seen")
	first.queue_free()
	await process_frame
	var again: Node = await _open()
	check(not (again.get_node("%TitlePage") as Control).visible, "back in the main menu: no title page")
	check(not (again.get_node("%DoorHint") as Control).visible, "no \"Hier klicken\"")
	check((again.get_node("%MenuPage") as Control).visible, "right at the anvil")
	again.queue_free()
	await process_frame


func _open() -> Node:
	var menu: Node = (load("res://scenes/ui/main_menu/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	return menu
