extends "res://assets/_reference/_lib/base_test.gd"
## Egon's dungeon board shows only open dungeons, with their enemies (beaten ones by name, the
## others as silhouettes); the lexicon has a tab "Gegner": every enemy grouped by dungeon, known
## after the first kill (Progress.meet_enemy) with life, damage, loot and where it lives.

var meta: Script
var content: Script
var progress: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	content = script("res://scripts/core/content.gd")
	progress = script("res://scripts/systems/progress.gd")
	meta.call("start_new")
	_data()
	await _board()
	await _lexicon()


func _data() -> void:
	var glut: Array = content.call("dungeon_enemies", "glut")
	check(glut.has("rat") and glut.has("rat_king"), "the first dungeon has rats and the rat king")
	check(glut.has(String(content.call("end_boss", "glut"))), "and its end boss")
	check_eq(glut.size(), glut.filter(func(id: String) -> bool: return glut.count(id) == 1).size(), "each enemy once")
	check(content.call("enemy_icon", "rat") is Texture2D, "an enemy has a picture for menus")
	check(not progress.call("has_met", "rat"), "nothing beaten yet")
	check_eq(progress.call("meet_enemy", "nobody"), [], "unknown enemies are not noted")


func _board() -> void:
	var board: Control = script("res://scenes/shop/dungeon_board.gd").new()
	root.add_child(board)
	await process_frame
	board.call("open")
	await process_frame
	check(board.find_child("Dungeon_glut", true, false) != null, "the open dungeon is on the board")
	check(board.find_child("Dungeon_moor", true, false) == null, "a locked one is not")
	check_eq(board.call("get_selected"), "glut", "the open one is chosen")
	var rat: TextureRect = board.find_child("Enemy_rat", true, false)
	check(rat != null and rat.tooltip_text == "???", "its enemies: a silhouette before the first kill")
	progress.call("meet_enemy", "rat")
	board.call("open")
	await process_frame
	rat = board.find_child("Enemy_rat", true, false)
	check(rat != null and rat.tooltip_text == "Ratte", "after it: the rat by name")
	meta.call("win_dungeon", "glut")
	board.call("open")
	await process_frame
	check(board.find_child("Dungeon_moor", true, false) != null, "winning opens the next dungeon on the board")
	board.queue_free()
	await process_frame


func _lexicon() -> void:
	var window: Control = (load("res://scenes/ui/menus/lexicon_window.tscn") as PackedScene).instantiate()
	root.add_child(window)
	await process_frame
	window.call("open")
	window.call("show_tab", 1)
	await process_frame
	check(window.find_child("Enemy_rat", true, false) != null, "the Gegner tab lists the rat")
	check(window.find_child("Enemy_rat_king", true, false) != null, "and the bosses")
	window.call("_show_enemy", "rat")
	check_eq((window.get_node("%DetailName") as Label).text, "Ratte", "a beaten enemy: its name")
	check((window.get_node("%DetailDesc") as Label).text.contains("Leben"), "its life and damage")
	check((window.get_node("%DetailExtra") as Label).text.contains("Dungeon der Glut"), "where it lives")
	window.call("_show_enemy", "rat_king")
	check_eq((window.get_node("%DetailName") as Label).text, "???", "not beaten yet: ???")
	check((window.get_node("%Count") as Label).text.begins_with("Besiegt: 1 /"), "the count of beaten enemies")
	window.call("show_tab", 0)
	await process_frame
	check((window.get_node("%Count") as Label).text.begins_with("Entdeckt:"), "the Items tab as before")
	window.queue_free()
	await process_frame
