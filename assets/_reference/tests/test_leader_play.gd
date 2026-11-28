extends "res://assets/_reference/_lib/base_test.gd"
## The leader (mini boss) of a floor (floors.json "mini_boss", theme "mini_bosses"): none on the
## first floor (tutorial), one per later floor in a normal room about halfway to the boss; it is
## bigger, golden, has more life, the HUD shows its bar, and beaten it drops its reward.

var game: Node
var content: Script


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	_check_data()
	check_eq(await _leader_rooms(0, 4), 0, "no leader on the first floor")
	check_eq(await _leader_rooms(1, 4), 1, "one leader on floor 2")
	await _check_fight(1, 4)


func _check_data() -> void:
	var floors: Dictionary = content.call("get_file", "floors")
	var rules: Dictionary = floors.get("mini_boss", {})
	check(float(rules.get("hp_mult", 0.0)) > 1.0 and float(rules.get("size", 0.0)) >= 1.0, "mini_boss rules set")
	var enemies: Dictionary = (content.call("get_file", "enemies") as Dictionary).get("enemies", {})
	for theme_id: String in (floors.get("themes", {}) as Dictionary):
		var table: Array = (floors["themes"] as Dictionary)[theme_id].get("mini_bosses", [])
		check(not table.is_empty(), "theme %s has mini_bosses" % theme_id)
		for entry: Array in table:
			check(enemies.has(String(entry[0])), "%s: leader %s is an enemy" % [theme_id, entry[0]])
			check(String((enemies.get(String(entry[0]), {}) as Dictionary).get("ai", "")) != "boss", "%s: leader is no boss" % theme_id)


func _start(index: int, seed_value: int) -> Node:
	content.set("active_dungeon", "")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(seed_value)
	run_state.set("floor_index", index)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	return scene


## How many rooms of the floor have a leader.
func _leader_rooms(index: int, seed_value: int) -> int:
	var scene: Node = await _start(index, seed_value)
	var dungeon: Node = scene.get_node("%Dungeon")
	var count: int = 0
	for room: Node in (dungeon.get("rooms") as Dictionary).values():
		if not String(room.get("leader")).is_empty():
			count += 1
			check_eq(String(room.get("type")), "normal", "leader in a normal room")
	scene.queue_free()
	await process_frame
	return count


func _check_fight(index: int, seed_value: int) -> void:
	var scene: Node = await _start(index, seed_value)
	var dungeon: Node = scene.get_node("%Dungeon")
	var hud: Node = scene.find_child("HUD", true, false)
	check(hud != null, "run scene has a HUD")
	var cell := Vector2i(-99, -99)
	for room_cell: Vector2i in (dungeon.get("rooms") as Dictionary):
		if not String((dungeon.get("rooms") as Dictionary)[room_cell].get("leader")).is_empty():
			cell = room_cell
	dungeon.call("teleport_to_cell", cell)
	await physics_frame
	var leader: Node = null
	for enemy: Node in dungeon.call("get_enemies"):
		if bool(enemy.get("is_leader")):
			leader = enemy
	check(leader != null, "the leader comes when the player enters")
	if leader == null:
		scene.queue_free()
		return
	var plain: Dictionary = content.call("enemy", String(leader.get("id")))
	check(float(leader.get("max_hp")) > float(plain.get("hp", 1)) * 2.0, "leader has more life")
	check(float(leader.get("height")) > float(plain.get("height", 1.2)), "leader is bigger")
	if hud:
		var box: Control = hud.get_node("%BossBox")
		check(box.visible, "HUD shows the leader's bar")
		check(String((hud.get_node("%BossName") as Label).text).contains("Anführer"), "bar named as leader")
	var exp_before: int = int((game.get("run") as Object).get("exp_earned"))
	leader.call("take_damage", 99999.0, Vector3.ZERO, false)
	await wait_until(func() -> bool: return not (dungeon.call("get_enemies") as Array).has(leader), 3.0)
	check(int((game.get("run") as Object).get("exp_earned")) > exp_before, "leader gives EXP")
	if hud:
		check(not (hud.get_node("%BossBox") as Control).visible, "bar gone after the leader")
	var loot: Array = (dungeon.get("rooms") as Dictionary)[cell].get("loot")
	check(loot.size() >= 1, "leader leaves its reward (%d)" % loot.size())
	scene.queue_free()
	await process_frame
