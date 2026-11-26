extends "res://assets/_reference/_lib/base_test.gd"
## In the real run scene: a coin on the floor is worth 8-12 (data/player.json coin_pickup), Tab
## shows the bag with the hero (equipment, values) left, the whole floor right and the items of the
## run below (with their description), and the ladder in the start room asks whether to
## flee: "Weiterkämpfen" goes on (asks again only after walking away), "Flüchten" ends the run and
## brings the coins and the whole bag home (MetaState), like a win.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var meta: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(11)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D

	await _coin()
	await _bag_map()
	await _flee()


func _coin() -> void:
	var before: int = run_state.get("coins")
	var room: Node3D = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")]
	dungeon.call("_drop", room, player.global_position, "coin")
	check(await wait_until(func() -> bool: return int(run_state.get("coins")) > before, 2.0), "walking over a coin picks it up")
	var gained: int = int(run_state.get("coins")) - before
	check(gained >= 8 and gained <= 12, "one coin is worth 8 to 12 (%d)" % gained)


func _bag_map() -> void:
	var window: CanvasLayer = scene.get("bag_window")
	var tab := InputEventAction.new()
	tab.action = &"bag"
	tab.pressed = true
	Input.parse_input_event(tab)
	check(await wait_until(func() -> bool: return window.visible, 1.0), "Tab opens the bag")
	var map: Control = window.get("map")
	check(map != null and map.is_visible_in_tree(), "the floor map is beside the bag")
	check(map.get("always_big"), "showing the whole floor")
	check((window.get("_hero") as Control).is_visible_in_tree(), "left: the hero with his equipment")
	var stats: String = (window.get("_stats") as Label).text
	check(stats.contains("Schaden") and stats.contains("Angriffstempo") and stats.contains("Tempo") and stats.contains("Glück"),
			"below it: damage, attack speed, speed, luck")
	var items: Array = (window.get("_items") as Node).get_children().filter(func(node: Node) -> bool: return node is TextureRect)
	check_eq(items.size(), (run_state.get("items") as Array).size(), "one big picture per item of the run")
	var glutstab: Dictionary = script("res://scripts/core/content.gd").call("item", "glutstab")
	check(items.size() > 0 and (items[0] as Control).tooltip_text.contains(String(glutstab.get("desc", "?"))), "hovering shows the description")
	window.call("close")


func _flee() -> void:
	var way_out: Node3D = dungeon.find_child("Exit", true, false)
	check(way_out != null, "the start room has a way out")
	run_state.call("add_coins", 40)
	(run_state.get("bag") as Object).call("add", "rat_fur", 3)
	var coins: int = run_state.get("coins")
	var day: int = meta.call("day")
	# Onto the ladder: the question, the game stops.
	player.global_position = Vector3(way_out.global_position.x, player.global_position.y, way_out.global_position.z)
	check(await wait_until(func() -> bool: return scene.call("get_flee_question") != null and (scene.call("get_flee_question") as Window).visible, 2.0),
			"stepping on the ladder asks whether to flee")
	check(paused, "the game stops while it asks")
	var question: ConfirmationDialog = scene.call("get_flee_question")
	question.get_cancel_button().pressed.emit()
	# The dialog hides itself one frame later.
	await process_frame
	check(not paused and not question.visible, "Weiterkämpfen: the game goes on")
	for i in 20:
		await physics_frame
	check(not question.visible, "standing on it does not ask again at once")
	player.global_position += Vector3(3.0, 0, 3.0)
	await physics_frame
	await physics_frame
	player.global_position = Vector3(way_out.global_position.x, player.global_position.y, way_out.global_position.z)
	check(await wait_until(func() -> bool: return question.visible, 2.0), "after walking away it asks again")
	question.get_ok_button().pressed.emit()
	var end_screen: CanvasLayer = scene.get_node("EndScreen")
	check(await wait_until(func() -> bool: return end_screen.visible, 2.0), "Flüchten: the end screen")
	check_eq((end_screen.get_node("%Title") as Label).text, "Geflüchtet!", "it says Geflüchtet!")
	check_eq(meta.call("purse"), coins, "the coins come home")
	var stash: Array = meta.call("stash")
	check(stash.any(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur" and int(place.get("count")) == 3), "the whole bag comes home")
	check_eq(meta.call("day"), day + 1, "a new day")
	paused = false
