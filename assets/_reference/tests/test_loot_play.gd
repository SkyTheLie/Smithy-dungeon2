extends "res://assets/_reference/_lib/base_test.gd"
## Loot in the real run scene: walking over loot puts it into the bag, enemies drop their loot
## (data/loot.json), Tab opens the bag window (game paused), dragging a place out of the window
## drops it on the floor and it is only picked up again after walking away, a full bag says so,
## and on death only the safe place comes home (MetaState).

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var bag: Object
var messages: Array[String] = []


func run() -> void:
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(9)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	bag = run_state.get("bag")
	dungeon.connect("message", func(text: String) -> void: messages.append(text))

	await _pick_up()
	await _enemy_loot()
	await _bag_window()
	await _full_bag()
	await _death()


func _room() -> Node3D:
	return (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")]


func _pick_up() -> void:
	var pickup: Node3D = dungeon.call("_drop_loot", _room(), player.global_position, "bat_skin", 2, false)
	check(pickup != null, "loot lies on the floor")
	check(await wait_until(func() -> bool: return bag.call("count_of", "bat_skin") > 0, 2.0), "walking over it puts it into the bag")
	check_eq(bag.call("count_of", "bat_skin"), 2, "both pieces")
	check_eq((bag.call("get_place", 1) as Dictionary).get("id"), "bat_skin", "loot does not stack: one place each")


func _enemy_loot() -> void:
	var spot: Vector3 = player.global_position + Vector3(3.5, 0, 0)
	var spider: Node = dungeon.call("spawn_enemy", "giant_spider", spot)
	spider.call("take_damage", 99999.0, Vector3.ZERO, false)
	var found: bool = await wait_until(func() -> bool:
		for node: Variant in _room().get("loot"):
			if is_instance_valid(node) and (node as Node).get("material_id") == "rat_venom_fang":
				return true
		return false, 3.0)
	check(found, "the Spinnenmutter drops her poison fangs (chance 1.0 in loot.json)")


func _bag_window() -> void:
	var window: CanvasLayer = scene.get("bag_window")
	var tab := InputEventAction.new()
	tab.action = &"bag"
	tab.pressed = true
	Input.parse_input_event(tab)
	check(await wait_until(func() -> bool: return window.visible, 1.0), "Tab opens the bag")
	check(paused, "the game stops while the bag is open")
	check_eq((window.get("_slots") as Array).size(), 5, "a small backpack: 4 places and the safe place")
	# Drag the bat skin out of the window = onto the floor.
	window.call("_drop_on_floor", Vector2.ZERO, {"bag_index": 0})
	check((bag.call("get_place", 0) as Dictionary).is_empty(), "dropped out of the bag")
	var dropped: Node3D = null
	for node: Variant in _room().get("loot"):
		if is_instance_valid(node) and (node as Node).get("material_id") == "bat_skin":
			dropped = node
	check(dropped != null, "it lies on the floor now")
	window.call("close")
	check(not paused, "closing goes on with the game")
	# Standing on it: not taken back at once.
	player.global_position = Vector3(dropped.global_position.x, player.global_position.y, dropped.global_position.z)
	for i in 20:
		await physics_frame
	check(is_instance_valid(dropped), "dropped loot waits until you walked away")
	player.global_position += Vector3(2.5, 0, 0)
	await physics_frame
	await physics_frame
	player.global_position = Vector3(dropped.global_position.x, player.global_position.y, dropped.global_position.z)
	var dropped_ref: WeakRef = weakref(dropped)
	check(await wait_until(func() -> bool: return dropped_ref.get_ref() == null, 2.0), "after walking away it can be picked up again")


func _full_bag() -> void:
	for i in int(bag.get("normal_count")):
		bag.call("add", "coal", 1)
	messages.clear()
	var stone: Node3D = dungeon.call("_drop_loot", _room(), player.global_position, "ruby", 1, false)
	check(await wait_until(func() -> bool: return messages.has("Inventar voll!"), 2.0), "a full bag says so")
	check(is_instance_valid(stone), "and the loot stays on the floor")


func _death() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	var day: int = meta.call("day")
	var saved_id: String = String((bag.call("get_place", 0) as Dictionary).get("id", ""))
	bag.call("move", 0, int(bag.get("normal_count")))
	player.set("invulnerable", 0.0)
	run_state.call("take_damage", 99)
	var end_screen: CanvasLayer = scene.get_node("EndScreen")
	check(await wait_until(func() -> bool: return end_screen.visible, 3.0), "end screen after death")
	check_eq((bag.call("contents") as Array).size(), 1, "death: only the safe place is left in the bag")
	var stash: Array = meta.call("stash")
	check(stash.size() == 1 and (stash[0] as Dictionary).get("id") == saved_id, "the safe place comes home (%s)" % saved_id)
	check_eq(meta.call("box"), 0, "the gold of the run is lost")
	check_eq(meta.call("day"), day + 1, "a new day")
	paused = false
