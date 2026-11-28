extends "res://assets/_reference/_lib/base_test.gd"
## The Räderkluft in the real run scene: a hall bigger than a room with a fixed center, four door
## platforms and two rings of four platforms; the outer ring turns clockwise, the inner one
## counter-clockwise; every quarter lap a way from each door to the center lines up; a platform
## carries the player; stepping into the chasm costs half a heart and puts the player back on
## fixed ground; leaving through the admin teleport works. The end boss stands still on the dais
## (only the player is blocked by it), helpers stay on the platforms, after the boss the golden
## light is on the center; the Moor ends in the Räderkluft (dungeons.json end_room).

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object


func run() -> void:
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(123)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	_rails()
	dungeon.call("enter_gear_chasm")
	var hall: Node3D = dungeon.get("chasm")
	check(dungeon.call("in_gear_chasm"), "in the Räderkluft")
	var rect: Rect2 = dungeon.call("room_rect", 0.0)
	check(rect.size.x > 25.0 and rect.size.y > 25.0, "the hall is bigger than a room (%s)" % str(rect.size))
	check_eq((hall.get("platforms") as Array).size(), 13, "center, 4 doors, 4 inner, 4 outer")
	await _boss(hall)
	await _turning(hall)
	await _carry(hall)
	await _fall(hall)
	await _ways(hall)
	# Out again (admin menu: to the start room).
	dungeon.call("teleport_to_cell", Vector2i(4, 4))
	check(not dungeon.call("in_gear_chasm"), "back on the floor")


## The rail goes round clockwise from the middle of the north side.
func _rails() -> void:
	var chasm: GDScript = script("res://scenes/run/gear_chasm.gd")
	var path := Vector2(4.0, 2.0)
	check((chasm.call("path_point", path, 0.0) as Vector2).is_equal_approx(Vector2(0, -2)), "lap 0: middle of the north side")
	check((chasm.call("path_point", path, 0.25) as Vector2).is_equal_approx(Vector2(4, 0)), "a quarter: middle of the east side")
	check((chasm.call("path_point", path, 0.5) as Vector2).is_equal_approx(Vector2(0, 2)), "a half: south")
	check((chasm.call("path_point", path, 0.75) as Vector2).is_equal_approx(Vector2(-4, 0)), "three quarters: west")
	check((chasm.call("path_point", path, 1.0) as Vector2).is_equal_approx(Vector2(0, -2)), "round again")


## North platform of a ring (start 0).
func _north(hall: Node3D, ring: int) -> Object:
	for piece: Object in hall.call("platforms_of", ring):
		if is_zero_approx(float(piece.get("start"))):
			return piece
	return null


func _turning(hall: Node3D) -> void:
	check(not hall.get("falling"), "the player arrives on solid ground")
	var outer: Object = _north(hall, 1)
	var inner: Object = _north(hall, 2)
	var outer_x: float = (outer.get("at") as Vector2).x
	var inner_x: float = (inner.get("at") as Vector2).x
	for i in 20:
		await physics_frame
	check((outer.get("at") as Vector2).x > outer_x, "the outer ring turns clockwise (north platform goes east)")
	check((inner.get("at") as Vector2).x < inner_x, "the inner ring turns counter-clockwise (north platform goes west)")
	check(not hall.get("falling"), "standing on the door platform: no fall")


func _carry(hall: Node3D) -> void:
	var outer: Object = _north(hall, 1)
	var at: Vector2 = outer.get("at")
	player.global_position = hall.global_position + Vector3(at.x, 0, at.y)
	await physics_frame
	var start: Vector3 = player.global_position
	for i in 30:
		await physics_frame
	var platform_at: Vector2 = outer.get("at")
	var expected: Vector3 = hall.global_position + Vector3(platform_at.x, 0, platform_at.y)
	check(player.global_position.distance_to(start) > 0.3, "the platform carries the player")
	check(player.global_position.distance_to(expected) < 0.2, "the player stays on the platform (%s / %s)" % [player.global_position, expected])
	check(not hall.get("falling"), "no fall while carried")


func _fall(hall: Node3D) -> void:
	# Back to the center (fixed ground), then into a corner of the hall: nothing there.
	player.global_position = hall.global_position + Vector3(0, 0, 3.0)
	await physics_frame
	await physics_frame
	var health: int = run_state.get("health")
	var half: Vector2 = hall.get("half")
	player.global_position = hall.global_position + Vector3(half.x - 0.6, 0, half.y - 0.6)
	check(await wait_until(func() -> bool: return hall.get("falling"), 0.5), "off the platforms the player falls")
	check(not player.get("controls_enabled"), "no walking while falling")
	check(await wait_until(func() -> bool: return not hall.get("falling"), 2.0), "the fall ends")
	check_eq(int(run_state.get("health")), health - 1, "the fall costs half a heart")
	check(player.get("controls_enabled"), "the player may walk again")
	var back: Vector3 = player.global_position - hall.global_position
	check(absf(back.x) < 5.0 and absf(back.z) < 4.0, "back on the center (%s)" % back)


## At a full quarter lap the north door, both north platforms and the center line up.
func _ways(hall: Node3D) -> void:
	var period: float = float(hall.get("_period"))
	hall.set("_time", period / 4.0 - 1.0 / 60.0)
	await physics_frame
	var reach: float = float(hall.get("_reach"))
	# A quarter lap on: the platforms that started in the west (outer) and east (inner) are north now.
	for ring: int in [1, 2]:
		var north: bool = (hall.call("platforms_of", ring) as Array).any(func(piece: Object) -> bool:
			var at: Vector2 = piece.get("at")
			return absf(at.x) < 0.1 and at.y < 0.0)
		check(north, "ring %d has a platform in the middle of the north side" % ring)
	# Walk the line from the north door to the center: always on a platform.
	var half: Vector2 = hall.get("half")
	var ok: bool = true
	var z: float = -half.y + 0.5
	while z < 0.0:
		if hall.call("platform_at", Vector2(0, z)) == null:
			ok = false
		z += reach
	check(ok, "a way from the north door to the center")


func _boss(hall: Node3D) -> void:
	var moor: Dictionary = script("res://scripts/core/content.gd").call("dungeon", "moor")
	check_eq(String(moor.get("end_room", "")), "gear_chasm", "the Moor ends in the Räderkluft")
	player.set("invulnerable", 999.0)
	var boss: Node3D = dungeon.get("boss")
	check(boss != null, "the end boss is there")
	if boss == null:
		return
	check(boss.get("pinned"), "it may not walk")
	check(int(player.get("collision_mask")) & int(hall.get("DAIS_LAYER")) != 0, "the dais blocks the player")
	# A helper on the north outer platform rides along and never steps into the chasm.
	var outer: Object = _north(hall, 1)
	var at: Vector2 = outer.get("at")
	var helper: Node3D = dungeon.call("spawn_enemy", "tutorial_rat", hall.global_position + Vector3(at.x, 0, at.y))
	for i in 90:
		await physics_frame
	var spot: Vector3 = boss.global_position - (hall.call("boss_spot") as Vector3)
	check(spot.length() < 0.05, "the boss is still on the dais (%s)" % spot)
	check(is_instance_valid(helper) and helper.get("alive"), "the helper is alive")
	var feet := Vector2(helper.global_position.x - hall.global_position.x, helper.global_position.z - hall.global_position.z)
	check(hall.call("platform_at", feet) != null, "the helper stands on a platform (%s)" % feet)
	boss.call("take_damage", 99999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "boss beaten")
	check(int(player.get("collision_mask")) & int(hall.get("DAIS_LAYER")) == 0, "the dais is free")
	var golden: bool = hall.get_children().any(func(node: Node) -> bool: return node.get("final") != null)
	check(golden, "the way out (golden light) stands in the hall")
	player.set("invulnerable", 0.0)
	player.global_position = hall.call("arrival_point")
	await physics_frame
	await physics_frame
