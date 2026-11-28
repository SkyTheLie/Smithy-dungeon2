extends "res://assets/_reference/_lib/base_test.gd"
## Comfort in the bag window (Tab): it shows what the bag is worth (Bag.total_value) and updates
## it; holding X over a piece of loot throws it on the floor; the run values end with the number
## of active synergies.

var scene: Node
var run_state: Object


func run() -> void:
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	run_state = script("res://scripts/systems/run_state.gd").new(5)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var bag: Object = run_state.get("bag")
	bag.call("add", "rat_fur", 2)
	var window: Node = scene.get("bag_window")
	window.call("open")
	await process_frame
	var worth: Label = window.get("_worth")
	var total: int = int(bag.call("total_value"))
	check(total > 0, "the furs are worth something")
	check(worth.text.contains(str(total)), "the window shows the worth of the bag")
	check((window.get("_stats") as Label).text.contains("Synergien"), "the values show the synergies")
	# Quick drop: hover the fur, hold X.
	var index: int = -1
	for i in int(bag.call("size")):
		if String((bag.call("get_place", i) as Dictionary).get("id", "")) == "rat_fur":
			index = i
	check(index >= 0, "the fur is in the bag")
	var furs: int = int(bag.call("count_of", "rat_fur"))
	window.call("_show_info", index)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_X
	key.pressed = true
	Input.parse_input_event(key)
	check(await wait_until(func() -> bool: return int(bag.call("count_of", "rat_fur")) < furs, 2.0), "holding X throws it on the floor")
	key.pressed = false
	Input.parse_input_event(key)
	check(not worth.text.contains(str(total)), "the worth goes down")
	window.call("close")
	await process_frame
