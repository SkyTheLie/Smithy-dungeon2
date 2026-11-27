extends "res://assets/_reference/_lib/base_test.gd"
## Plays one floor in the real run scene: start room, a fight room closes its doors and lets
## enemies appear, a real shot (left mouse button) hurts an enemy, killing all opens the doors,
## a dropped bomb costs one bomb, the beam hurts, the boss room spawns the boss and after it the
## trapdoor and the boss item appear, the test room (P) has every item and drops them again,
## death opens the end screen.

var scene: Node
var dungeon: Node
var player: Node
var run_state: Object


func run() -> void:
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(77)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player")
	var layout: Object = dungeon.get("layout")
	check(layout != null, "floor built")
	check_eq(dungeon.get("current_cell"), Vector2i(4, 4), "player starts in the start room")
	check_eq((dungeon.get("rooms") as Dictionary).size(), (layout.get("rooms") as Dictionary).size(), "every room built")
	var distance_map: Dictionary = layout.get("distance")
	for c: Vector2i in layout.get("rooms"):
		var room_node: Node3D = (dungeon.get("rooms") as Dictionary)[c]
		check_eq(room_node.visible, int(distance_map[c]) <= 1, "only the start room and its neighbours are drawn (%s)" % c)
	# Map fog: at the start only the start room and its neighbours are known (the boss room too).
	var known: Array = dungeon.call("known_cells")
	var boss_cell: Vector2i = layout.call("cell_of", "boss")
	check_eq(known.has(boss_cell), int(distance_map[boss_cell]) <= 1, "the boss room is only on the map when it is near")
	for c: Vector2i in known:
		check(int(distance_map[c]) <= 1, "map shows only rooms next to visited ones (%s)" % c)
	check(not known.has(layout.call("cell_of", "secret")), "the secret room is not on the map")
	var floor_bosses: Array = (dungeon.get("floor_data") as Dictionary).get("bosses", [])
	check(floor_bosses.has(dungeon.get("boss_id")), "the boss is one of the theme")

	await _fight_room(layout)
	await _bomb()
	await _beam()
	await _burn_and_slow()
	await _guards()
	await _sword()
	_secret_wall(layout)
	await _boss(layout)
	await _every_boss(layout)
	await _test_room()
	await _pause_items()
	await _death()


func _fight_room(layout: Object) -> void:
	var cell: Vector2i = Vector2i(-1, -1)
	var distance: Dictionary = layout.get("distance")
	for c: Vector2i in layout.get("rooms"):
		if layout.call("get_type", c) == "normal" and int(distance[c]) == 1:
			cell = c
	check(cell != Vector2i(-1, -1), "a fight room next to the start")
	_teleport(cell, Vector3(0, 0, 3.5))
	check(await wait_until(func() -> bool: return (dungeon.call("get_enemies") as Array).size() > 0, 2.0), "enemies appear")
	check(dungeon.call("is_fighting"), "fight started")
	for door: Node in dungeon.call("doors_of", cell):
		check(door.get("closed"), "door closed during the fight")
	# Real shot: stand in front of an enemy, look at it, hold the left mouse button.
	var enemy: Node3D = (dungeon.call("get_enemies") as Array)[0]
	var hp_before: float = enemy.get("hp")
	_face(enemy, 1.8)
	Input.action_press("shoot")
	var hit: bool = await wait_until(func() -> bool: return not is_instance_valid(enemy) or float(enemy.get("hp")) < hp_before, 3.0)
	Input.action_release("shoot")
	check(hit, "a fireball hurts the enemy")
	for other: Node in (dungeon.call("get_enemies") as Array).duplicate():
		other.call("take_damage", 999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "room cleared")
	for door: Node in dungeon.call("doors_of", cell):
		check(not door.get("closed"), "door open after the fight")
	check(run_state.get("kills") > 0, "kills counted")


func _bomb() -> void:
	var bombs: int = run_state.get("bombs")
	run_state.call("add_bombs", 1)
	Input.action_press("bomb")
	await physics_frame
	await physics_frame
	Input.action_release("bomb")
	check_eq(run_state.get("bombs"), bombs, "dropping a bomb costs one")


func _beam() -> void:
	run_state.call("add_item", "feuerlanze")
	var room_center: Vector3 = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].global_position
	var enemy: Node3D = dungeon.call("spawn_enemy", "giant_rat", room_center + Vector3(0, 0, -2.0))
	await physics_frame
	var hp_before: float = enemy.get("hp")
	_face(enemy, 3.0)
	Input.action_press("shoot")
	var hit: bool = await wait_until(func() -> bool: return not is_instance_valid(enemy) or float(enemy.get("hp")) < hp_before, 2.0)
	Input.action_release("shoot")
	check(hit, "the fire beam hurts the enemy")
	if is_instance_valid(enemy):
		enemy.call("take_damage", 999.0, Vector3.ZERO, false)
	await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0)


func _burn_and_slow() -> void:
	run_state.call("add_item", "brandoel")
	run_state.call("add_item", "frostflechte")
	var room_center: Vector3 = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].global_position
	var enemy: Node3D = dungeon.call("spawn_enemy", "giant_rat", room_center + Vector3(3.0, 0, -2.0))
	await physics_frame
	var hp_before: float = enemy.get("hp")
	enemy.call("afflict", run_state.get("stats").get("flags"), 1.0)
	check(enemy.call("is_burning"), "Brandöl sets the enemy on fire")
	check(enemy.call("is_slowed"), "Frostflechte slows the enemy")
	check(await wait_until(func() -> bool: return not is_instance_valid(enemy) or float(enemy.get("hp")) < hp_before, 2.0), "burning hurts over time")
	if is_instance_valid(enemy):
		enemy.call("take_damage", 999.0, Vector3.ZERO, false)
	await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0)


## A bomb next to the hidden wall of the secret room blows it open.
func _secret_wall(layout: Object) -> void:
	var secret: Vector2i = layout.call("cell_of", "secret")
	check(secret != Vector2i(-1, -1), "the floor has a secret room")
	for door: Node3D in dungeon.call("doors_of", secret):
		check(door.get("hidden"), "secret room: the doorway looks like a wall")
		check(not (door.get("_bars") as Node3D).visible, "secret wall: no bars to see")
		dungeon.call("explode", door.global_position + Vector3(0, 0, 0.5), 1.5, 1.0, false)
		check(not door.get("hidden"), "a bomb blows the wall open")


## A Schildwache takes no damage from the front, but from behind; a zombie digs in.
func _guards() -> void:
	var room_center: Vector3 = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].global_position
	var guard: Node3D = dungeon.call("spawn_enemy", "shield_guard", room_center + Vector3(0, 0, -2.0))
	(player as Node3D).global_position = room_center + Vector3(0, 0, 2.0)
	for i in 30:
		await physics_frame
	var hp_before: float = guard.get("hp")
	guard.call("take_damage", 1.0, Vector3(0, 0, -1.0), false)
	check_eq(guard.get("hp"), hp_before, "Schildwache: a hit from the front bounces off")
	guard.call("take_damage", 1.0, Vector3(0, 0, 1.0), false)
	check(float(guard.get("hp")) < hp_before, "Schildwache: a hit from behind hurts")
	# After the ram it stands still with its back open: a hit from behind the ram hurts.
	guard.set("_guard_step", 1)
	guard.set("_guard_left", 0.0)
	check(await wait_until(func() -> bool: return int(guard.get("_guard_step")) == 3, 3.0), "Schildwache: rams and then stands still")
	var facing: Vector3 = guard.get("_facing")
	for i in 20:
		await physics_frame
	check(facing.is_equal_approx(guard.get("_facing")), "Schildwache: does not turn after the ram")
	guard.call("take_damage", 999.0, Vector3(0, 0, 1.0), false)
	await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0)


## Glutschwert: holding the button swings; two enemies in front are both hit.
func _sword() -> void:
	run_state.call("clear_items")
	run_state.call("add_item", "glutschwert")
	check_eq(run_state.get("stats").get("mode"), "melee", "Glutschwert: sword instead of fireballs")
	var room_center: Vector3 = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].global_position
	var left: Node3D = dungeon.call("spawn_enemy", "giant_rat", room_center + Vector3(-0.6, 0, -1.2))
	var right: Node3D = dungeon.call("spawn_enemy", "giant_rat", room_center + Vector3(0.6, 0, -1.2))
	(player as Node3D).global_position = room_center
	(player as Node3D).rotation.y = 0.0
	(player.get("camera") as Camera3D).rotation.x = 0.0
	await physics_frame
	var left_hp: float = left.get("hp")
	var right_hp: float = right.get("hp")
	Input.action_press("shoot")
	var both: bool = await wait_until(func() -> bool:
		return (not is_instance_valid(left) or float(left.get("hp")) < left_hp) and (not is_instance_valid(right) or float(right.get("hp")) < right_hp), 2.0)
	Input.action_release("shoot")
	check(both, "one swing hits two enemies")
	for other: Node in (dungeon.call("get_enemies") as Array).duplicate():
		other.call("take_damage", 999.0, Vector3.ZERO, false)
	await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0)
	# The Magier keeps his Glutstab, so Glutstab + Glutschwert = Feuerhieb: the band of fire
	# reaches an enemy far beyond the sword.
	check(run_state.get("stats").call("has", "fire_slash"), "Glutstab + Glutschwert = Feuerhieb")
	var far: Node3D = dungeon.call("spawn_enemy", "rat", room_center + Vector3(0, 0, -3.3))
	await physics_frame
	var far_hp: float = far.get("hp")
	Input.action_press("shoot")
	var reached: bool = await wait_until(func() -> bool: return not is_instance_valid(far) or float(far.get("hp")) < far_hp, 2.0)
	Input.action_release("shoot")
	check(reached, "Feuerhieb: the band of fire hits an enemy 3 m away")
	for other: Node in (dungeon.call("get_enemies") as Array).duplicate():
		other.call("take_damage", 999.0, Vector3.ZERO, false)
	await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0)


func _boss(layout: Object) -> void:
	var cell: Vector2i = layout.call("cell_of", "boss")
	run_state.set("special_chance", 1.0)
	# 100 % only if no red heart was lost on this floor (a hit earlier in the test halves it).
	run_state.set("lost_red_this_floor", false)
	# Egon's rope comes only once per save (test_rope_portal_play): here the boss room is normal.
	script("res://scripts/systems/meta_state.gd").call("finish_rope")
	_teleport(cell, Vector3(0, 0, 3.0))
	check(await wait_until(func() -> bool: return dungeon.get("current_cell") == cell, 1.0), "into the boss room")
	check(await wait_until(func() -> bool: return dungeon.get("boss") != null, 2.0), "boss appears in the boss room")
	check(dungeon.call("is_fighting"), "the doors close for the boss")
	var boss: Node = dungeon.get("boss")
	check(boss.get("is_boss"), "boss is a boss")
	await physics_frame
	# Helpers: at most data/enemies.json summon_max (5) alive at once, however often it calls.
	var helpers_max: int = dungeon.call("summon_max")
	check_eq(helpers_max, 5, "a boss calls at most 5 helpers")
	for i in 12:
		dungeon.call("summon", "rat", (boss as Node3D).global_position + Vector3(1.0, 0, 0))
	check(int(dungeon.call("helper_count")) <= helpers_max, "never more than 5 helpers (%d)" % int(dungeon.call("helper_count")))
	boss.call("take_damage", 9999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "boss room cleared")
	var room: Node = (dungeon.get("rooms") as Dictionary)[cell]
	var has_trapdoor: bool = false
	var has_pedestal: bool = false
	for child: Node in room.get_children():
		var path: String = child.get_script().resource_path if child.get_script() else ""
		has_trapdoor = has_trapdoor or path.ends_with("trapdoor.gd")
		has_pedestal = has_pedestal or path.ends_with("pedestal.gd")
	check(has_trapdoor, "trapdoor after the boss")
	var special: Vector2i = layout.call("cell_of", "special")
	if special != Vector2i(-1, -1):
		for door: Node in dungeon.call("doors_of", special):
			check(not door.get("hidden"), "the special room behind the boss opens (chance 100 %)")
	check(has_pedestal, "boss item after the boss")
	check(dungeon.call("get_portal") == null and dungeon.call("get_rope") == null, "no portal and no rope on the first floor (after the rope)")


func _test_room() -> void:
	var back_cell: Vector2i = dungeon.get("current_cell")
	dungeon.call("toggle_test_room")
	check(dungeon.call("in_test_room"), "P goes into the test room")
	var pedestals: Array = dungeon.get("_test_pedestals")
	var constants: Dictionary = (dungeon.get_script() as Script).get_script_constant_map()
	var per_page: int = int(constants["TEST_COLUMNS"]) * int(constants["TEST_ROWS"])
	check_eq(pedestals.size(), per_page + 2, "a page of item pedestals, drop and next page")
	check(not run_state.get("record_progress"), "the test room does not count for the Lexikon")
	var before: int = (run_state.get("items") as Array).size()
	var first: Node3D = pedestals[0]
	(player as Node3D).global_position = first.global_position + Vector3(0, 0, 0.5)
	check(await wait_until(func() -> bool: return (run_state.get("items") as Array).size() == before + 1, 2.0), "walking to a pedestal takes its item")
	var reset: Node3D = pedestals[per_page]
	(player as Node3D).global_position = reset.global_position + Vector3(0, 0, 0.5)
	check(await wait_until(func() -> bool: return (run_state.get("items") as Array).size() == 1, 2.0), "red pedestal drops every item but the main weapon")
	check(not first.call("is_empty"), "pedestals are full again")
	var first_item: String = first.get("item_id")
	var next_page: Node3D = pedestals[per_page + 1]
	(player as Node3D).global_position = next_page.global_position + Vector3(0, 0, 0.5)
	check(await wait_until(func() -> bool: return String(first.get("item_id")) != first_item, 2.0), "next page shows other items")
	dungeon.call("toggle_test_room")
	check_eq(dungeon.get("current_cell"), back_cell, "P again goes back")


## Every boss fights a few seconds in the boss room without errors (the player cannot die).
func _every_boss(layout: Object) -> void:
	var cell: Vector2i = layout.call("cell_of", "boss")
	var center: Vector3 = (dungeon.get("rooms") as Dictionary)[cell].global_position
	(player as Node3D).global_position = center + Vector3(0, 0, 3.0)
	var enemies: Dictionary = script("res://scripts/core/content.gd").call("enemies")
	for id: String in enemies:
		if enemies[id].get("ai", "") != "boss":
			continue
		var boss: Node3D = dungeon.call("spawn_enemy", id, center + Vector3(0, 0, -3.0))
		for i in 240:
			player.set("invulnerable", 10.0)
			await physics_frame
		check(is_instance_valid(boss), "boss %s fought for 4 seconds" % id)
		for other: Node in (dungeon.call("get_enemies") as Array).duplicate():
			other.set("hidden_phase", false)
			other.call("take_damage", 99999.0, Vector3.ZERO, false)
		await physics_frame
	player.set("invulnerable", 0.0)


## Esc: the items are listed on the left, hovering one shows its effect.
func _pause_items() -> void:
	run_state.call("add_item", "glutkern")
	run_state.call("add_item", "glutkern")
	run_state.call("add_item", "giftzahn")
	var pause: CanvasLayer = scene.get_node("PauseMenu")
	pause.call("open", run_state)
	await process_frame
	var unique: Dictionary = {}
	for id: String in run_state.get("items"):
		unique[id] = true
	var grid: GridContainer = pause.get_node("%ItemGrid")
	check_eq(grid.get_child_count(), unique.size(), "pause menu: one picture per item")
	pause.call("_show_item", "giftzahn")
	check(String((pause.get_node("%ItemText") as Label).text).contains("vergiftet"), "pause menu: hovering shows the effect")
	pause.call("resume")


func _death() -> void:
	player.set("invulnerable", 0.0)
	run_state.call("take_damage", 99)
	var end_screen: CanvasLayer = scene.get_node("EndScreen")
	check(await wait_until(func() -> bool: return end_screen.visible, 3.0), "end screen after death")
	paused = false


## Puts the player into `cell` at `offset` from the middle.
func _teleport(cell: Vector2i, offset: Vector3) -> void:
	var center: Vector3 = (dungeon.get("rooms") as Dictionary)[cell].global_position
	(player as Node3D).global_position = center + offset


## Stands `distance` in front of `target` and looks at it.
func _face(target: Node3D, distance: float) -> void:
	var p := player as Node3D
	var from: Vector3 = target.global_position + Vector3(0, 0, distance)
	p.global_position = from
	p.look_at(Vector3(target.global_position.x, 0, target.global_position.z), Vector3.UP)
	var camera: Camera3D = player.get("camera")
	var eye: Vector3 = camera.global_position
	var aim: Vector3 = target.call("aim_point")
	camera.rotation.x = atan2(aim.y - eye.y, Vector2(aim.x - eye.x, aim.z - eye.z).length())
