extends "res://assets/_reference/_lib/base_test.gd"
## Egon's errand and the way to the end boss, in the real run scene (data/meta.json ruby_quest,
## dungeons.json end_boss):
##   - the very first boss (new save, first floor): it leaves a ruby, then a rope falls from the
##     sky, no trapdoor, no boss item; at the rope the player climbs out, the achievement comes,
##     the end screen says "Hinausgeklettert!", the ruby is at home; from then on no more rope;
##   - Egon's shop: he takes the ruby (once);
##   - the last floor: after its boss a portal rises instead of the trapdoor; walking into it
##     leads to the Boss-Altar, the end boss lands there, after it the golden light.
## Fixed seeds.

var meta: Script
var content: Script
var progress: Script
var game: Node


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	content = script("res://scripts/core/content.gd")
	progress = script("res://scripts/systems/progress.gd")
	game = root.get_node("Game")
	_data()
	await _rope()
	await _ruby_in_shop()
	await _portal()


func _data() -> void:
	var quest: Dictionary = content.call("meta", "ruby_quest")
	check(content.call("dungeons").has(String(quest.get("dungeon", ""))), "the errand is in a known dungeon")
	check(not (content.call("get_file", "loot").get("materials", {}) as Dictionary).get(String(quest.get("item", "")), {}).is_empty(), "Egon wants known loot (ruby)")
	check(not (content.call("achievement", String(quest.get("achievement", ""))) as Dictionary).is_empty(), "its achievement exists")
	for id: String in content.call("achievements"):
		var data: Dictionary = content.call("achievement", id)
		check(not String(data.get("name", "")).is_empty() and not String(data.get("desc", "")).is_empty(), "achievement %s has a name and a text" % id)
		check(ResourceLoader.exists(String(data.get("icon", ""))), "achievement %s has a picture" % id)
	for id: String in content.call("dungeons"):
		var boss: String = String(content.call("end_boss", id))
		check(not boss.is_empty(), "dungeon %s has an end boss" % id)
		check_eq(String((content.call("enemy", boss) as Dictionary).get("ai", "")), "boss", "the end boss of %s is a boss" % id)
	for key: String in ["ruby_found", "ruby_taken", "ruby_missing"]:
		check(not (content.call("story", key) as Array).is_empty(), "Egon has lines for %s" % key)
	meta.call("start_new")
	check(meta.call("rope_due", "glut", 0), "a new game: the first boss ends with the rope")
	check(not meta.call("rope_due", "glut", 1) and not meta.call("rope_due", "moor", 0), "only on its floor")
	check(not meta.call("ruby_due"), "Egon waits for the ruby only after the rope")
	check(not meta.call("deliver_ruby"), "nothing to give before")


## The scene of floor `index` of dungeon `id` with a fresh run.
func _start(id: String, index: int, seed_value: int) -> Node:
	content.set("active_dungeon", id)
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(seed_value)
	run_state.set("floor_index", index)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	return scene


## Into the boss room; kills the boss. Returns the room.
func _beat_boss(dungeon: Node, player: Node3D) -> Node3D:
	var cell: Vector2i = (dungeon.get("layout") as Object).call("cell_of", "boss")
	var room: Node3D = (dungeon.get("rooms") as Dictionary)[cell]
	player.global_position = room.global_position + Vector3(0, 0, 3.0)
	check(await wait_until(func() -> bool: return dungeon.get("boss") != null, 2.0), "the boss fights in the boss room")
	(dungeon.get("boss") as Node).call("take_damage", 99999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "boss beaten")
	return room


func _children_with(room: Node, ending: String) -> Array:
	return room.get_children().filter(func(n: Node) -> bool: return n.get_script() != null and (n.get_script() as Script).resource_path.ends_with(ending))


func _rope() -> void:
	meta.call("start_new")
	var scene: Node = await _start("glut", 0, 5)
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	var run_state: Object = game.get("run")
	var room: Node3D = await _beat_boss(dungeon, player)
	var rubies: Array = room.get_children().filter(func(n: Node) -> bool: return n.get("material_id") == "ruby")
	check(not rubies.is_empty(), "the first boss leaves a ruby")
	check(_children_with(room, "trapdoor.gd").is_empty(), "no trapdoor after the first boss")
	check(_children_with(room, "pedestal.gd").is_empty(), "no boss item after the first boss")
	var rope: Node3D = dungeon.call("get_rope")
	check(rope != null, "a rope falls from the sky")
	if rope == null:
		return
	check(await wait_until(func() -> bool: return rope.call("is_hanging"), 3.0), "and hangs down")
	# Take the ruby along, then go to the rope.
	if not rubies.is_empty():
		# The boss loot around the player may fill the bag (one item per place): only the ruby stays.
		var bag: Object = run_state.get("bag")
		for i: int in bag.call("size"):
			bag.call("take", i)
		for n: Node in room.get_children():
			if n.get("material_id") != null and n.get("material_id") != "ruby" and n.get("material_id") != "":
				n.free()
		player.global_position = (rubies[0] as Node3D).global_position
		check(await wait_until(func() -> bool: return int((run_state.get("bag") as Object).call("count_of", "ruby")) > 0, 2.0), "the ruby goes into the bag")
	player.global_position = rope.global_position + Vector3(0, 0, 0.5)
	check(await wait_until(func() -> bool: return not player.get("controls_enabled"), 1.0), "at the rope the player stops and climbs")
	check(progress.call("has_achievement", "first_boss"), "the achievement is reached")
	var start_y: float = player.global_position.y
	var end_screen: CanvasLayer = scene.get_node("EndScreen")
	check(await wait_until(func() -> bool: return end_screen.visible, 8.0), "after the climb the end screen comes")
	check(player.global_position.y > start_y + 5.0, "the player climbed up")
	check_eq((end_screen.get_node("%Title") as Label).text, "Hinausgeklettert!", "\"Hinausgeklettert!\"")
	check(meta.call("rope_done") and not meta.call("rope_due", "glut", 0), "no more rope from now on")
	check(int(meta.call("ruby_index")) >= 0, "the ruby came home")
	check(meta.call("ruby_due"), "Egon waits for it")
	check_eq(meta.call("day"), 2, "the day is over")
	paused = false
	scene.queue_free()
	await process_frame


## Egon takes the ruby in his shop (the ruby comes from _rope).
func _ruby_in_shop() -> void:
	meta.call("finish_tutorial")
	var before: int = (meta.call("stash") as Array).size()
	game.call("to_shop")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Shop" and current_scene.is_node_ready(), 3.0), "the shop opens")
	var shop: Node = current_scene
	check(await _click_until(func() -> bool: return not meta.call("ruby_due") and not shop.get("_locked"), 20.0), "Egon takes the ruby and the shop is free again")
	check(meta.call("ruby_delivered"), "Egon has his ruby")
	check_eq(int(meta.call("ruby_index")), -1, "it is gone from the inventory")
	check((meta.call("stash") as Array).size() <= before, "nothing else came or went")
	check(not meta.call("deliver_ruby"), "only once")
	game.call("to_main_menu")
	await process_frame
	await process_frame


func _portal() -> void:
	var last: int = (content.call("floors", "glut") as Array).size() - 1
	var scene: Node = await _start("glut", last, 11)
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	var end_boss: String = String(content.call("end_boss", "glut"))
	check_eq(dungeon.get("end_boss_id"), end_boss, "the last floor knows the end boss")
	check(dungeon.get("boss_id") != end_boss, "it is not the boss of the floor")
	var room: Node3D = await _beat_boss(dungeon, player)
	check(_children_with(room, "trapdoor.gd").is_empty(), "no trapdoor after the boss of the last floor")
	check(not _children_with(room, "pedestal.gd").is_empty(), "but the boss item")
	var portal: Node3D = dungeon.call("get_portal")
	check(portal != null, "a portal rises")
	if portal == null:
		return
	check(await wait_until(func() -> bool: return portal.call("is_open"), 3.0), "and opens")
	player.global_position = Vector3(portal.global_position.x, 0, portal.global_position.z)
	check(await wait_until(func() -> bool: return dungeon.call("in_boss_altar"), 1.0), "the portal leads into the Boss-Altar")
	var altar: Node3D = dungeon.get("altar")
	altar.call("skip_intro")
	check(await wait_until(func() -> bool: return dungeon.get("boss") != null, 2.0), "the end boss lands")
	check_eq(String((dungeon.get("boss") as Node).get("id")), end_boss, "it is the end boss")
	(dungeon.get("boss") as Node).call("take_damage", 99999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "end boss beaten")
	var lights: Array = _children_with(altar, "trapdoor.gd")
	check_eq(lights.size(), 1, "the way out in the Boss-Altar")
	if not lights.is_empty():
		check((lights[0] as Node).get("final"), "it is the golden light (victory)")
	# Back through the gate: in front of the portal, not into it again.
	altar.set("exit_open", true)
	player.global_position = altar.global_position + Vector3(0, 0, float((altar.get("half") as Vector2).y) - 0.6)
	var boss_cell: Vector2i = (dungeon.get("layout") as Object).call("cell_of", "boss")
	check(await wait_until(func() -> bool: return dungeon.get("current_cell") == boss_cell, 1.0), "the gate leads back into the boss room")
	for i in 10:
		await physics_frame
	check(not dungeon.call("in_boss_altar"), "and the portal does not pull the player in again at once")
	content.set("active_dungeon", "")
	scene.queue_free()
	await process_frame


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
