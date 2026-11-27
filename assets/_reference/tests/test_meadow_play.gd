extends "res://assets/_reference/_lib/base_test.gd"
## The Wispernde Wiese in the real run scene: tall grass in the rooms, every enemy of the three
## areas moves for a moment without errors, and the new patterns do what they promise:
## snares hold the player, a closed shell shrugs off hits, the Strohmann collapses before it
## dies, the Teilschleim splits, the Knallkäfer explodes, the Wandspinne stays up on the wall,
## the Grasotter rushes along its line, the Funkelstein fires a beam, and the Wildhüter shoots at
## once when the player is caught. Fixed seeds.

var game: Node
var content: Script
var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object


func run() -> void:
	game = root.get_node("Game")
	content = script("res://scripts/core/content.gd")
	for index: int in [0, 2, 4]:
		await _open_floor(index)
		await _every_enemy(index)
		_close()
		await process_frame
	await _open_floor(0)
	await _snare()
	await _shell()
	await _scarecrow()
	await _split_and_blast()
	await _wall_spider()
	await _charger()
	await _laser()
	await _warden()
	_close()
	content.set("active_dungeon", "")


func _open_floor(index: int) -> void:
	content.set("active_dungeon", "wiese")
	run_state = script("res://scripts/systems/run_state.gd").new(77 + index)
	run_state.set("floor_index", index)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D


func _close() -> void:
	if scene:
		scene.queue_free()
		scene = null


func _life() -> int:
	return int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))


func _wait(frames: int) -> void:
	for i in frames:
		player.set("invulnerable", 10.0)
		await physics_frame


func _clear_enemies() -> void:
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame


## A spot `offset` away from the player, in the start room.
func _near(offset: Vector3) -> Vector3:
	return player.global_position + offset


func _every_enemy(index: int) -> void:
	var data: Dictionary = dungeon.get("floor_data")
	var name: String = "wiese floor %d (%s)" % [index + 1, data.get("name", "?")]
	var grass: int = 0
	for room: Node in (dungeon.get("rooms") as Dictionary).values():
		if room.has_node("Grass"):
			grass += 1
	check(grass >= 5, "%s: tall grass in the rooms (%d)" % [name, grass])
	for entry: Array in data.get("enemies", []):
		dungeon.call("spawn_enemy", String(entry[0]), _near(Vector3(2.5, 0, -2.5)))
		await _wait(60)
		check(not (dungeon.call("get_enemies") as Array).is_empty(), "%s: %s is there" % [name, entry[0]])
		await _clear_enemies()
	for boss: Variant in data.get("bosses", []):
		dungeon.call("spawn_enemy", String(boss), _near(Vector3(3.0, 0, -3.0)))
		await _wait(150)
		check(not (dungeon.call("get_enemies") as Array).is_empty(), "%s: boss %s fights without errors" % [name, boss])
		await _clear_enemies()


func _snare() -> void:
	player.set("invulnerable", 0.0)
	var before: int = _life()
	var trap: Node3D = dungeon.call("add_hazard", "snare_thrown", player.global_position, 5.0)
	check(trap != null and trap.call("holds"), "a thrown snare is a snare")
	dungeon.call("_check_hazards")
	check(player.call("is_held"), "stepping in holds the player")
	check_eq(before - _life(), 1, "and hurts half a heart")
	var at: Vector3 = player.global_position
	player.set("velocity", Vector3(5, 0, 0))
	await physics_frame
	await physics_frame
	check(player.global_position.distance_to(at) < 0.05, "held: the player cannot walk away")
	check(not trap.call("is_dangerous"), "it snaps only once")
	check(await wait_until(func() -> bool: return not player.call("is_held"), 2.0), "after a moment the player is free again")


func _shell() -> void:
	var shell: Node = dungeon.call("spawn_enemy", "crystal_shell", _near(Vector3(3, 0, -3)))
	await physics_frame
	check(shell.get("armored"), "the Kristallbrocken starts in its shell")
	var hp: float = shell.get("hp")
	shell.call("take_damage", 3.0, Vector3.ZERO, false)
	check_eq(shell.get("hp"), hp, "hits bounce off the closed shell")
	check(await wait_until(func() -> bool: return not shell.get("armored"), 5.0), "it opens after a while")
	shell.call("take_damage", 3.0, Vector3.ZERO, false)
	check(float(shell.get("hp")) < hp, "open, it can be hurt")
	await _clear_enemies()


func _scarecrow() -> void:
	var straw: Node = dungeon.call("spawn_enemy", "scarecrow", _near(Vector3(3, 0, -3)))
	await physics_frame
	straw.call("take_damage", float(straw.get("max_hp")) + 1.0, Vector3.ZERO, false)
	check(straw.get("alive") and straw.call("is_downed"), "the Strohmann collapses instead of dying")
	straw.call("take_damage", float(straw.get("max_hp")), Vector3.ZERO, false)
	check(not straw.get("alive"), "hit again while it lies there: gone")
	var other: Node = dungeon.call("spawn_enemy", "scarecrow", _near(Vector3(3, 0, -3)))
	await physics_frame
	other.call("take_damage", float(other.get("max_hp")) + 1.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not other.call("is_downed"), 4.0) and other.get("alive"), "left alone it stands up again")
	await _clear_enemies()


func _split_and_blast() -> void:
	var slime: Node = dungeon.call("spawn_enemy", "split_slime", _near(Vector3(3, 0, -3)))
	await physics_frame
	slime.call("take_damage", 500.0, Vector3.ZERO, false)
	await physics_frame
	var ids: Array = (dungeon.call("get_enemies") as Array).map(func(enemy: Node) -> String: return String(enemy.get("id")))
	check_eq(ids, ["slimelet", "slimelet"], "the Teilschleim splits into two")
	await _clear_enemies()
	var beetle: Node = dungeon.call("spawn_enemy", "boom_beetle", _near(Vector3(0.8, 0, 0)))
	await physics_frame
	player.set("invulnerable", 0.0)
	var before: int = _life()
	beetle.call("take_damage", 500.0, Vector3.ZERO, false)
	check(_life() < before, "the Knallkäfer explodes next to the player")
	await _clear_enemies()


func _wall_spider() -> void:
	var spider: Node3D = dungeon.call("spawn_enemy", "wall_spider", _near(Vector3(0, 0, -2)))
	await _wait(30)
	var climb: float = float((content.call("enemy", "wall_spider") as Dictionary).get("climb", 1.5))
	check(is_equal_approx(spider.global_position.y, climb), "the Wandspinne is up on the wall (%s)" % spider.global_position.y)
	var rect: Rect2 = script("res://scenes/run/room_builder.gd").call("inner_rect", dungeon.get("current_cell"), 0.0)
	var flat := Vector2(spider.global_position.x, spider.global_position.z)
	var to_edge: float = minf(minf(flat.x - rect.position.x, rect.end.x - flat.x), minf(flat.y - rect.position.y, rect.end.y - flat.y))
	check(to_edge < 0.3, "and right at a wall (%.2f m)" % to_edge)
	await _clear_enemies()


func _charger() -> void:
	# In the player's row, 5 m to the side: it rushes along x and stays in the row.
	var start: Vector3 = _near(Vector3(5, 0, 0))
	var viper: Node3D = dungeon.call("spawn_enemy", "grass_viper", start)
	viper.get("_moves").set("_timer", 0.0)
	await _wait(50)
	check(viper.global_position.distance_to(player.global_position) < 4.0, "the Grasotter rushes at the player in its row (%.1f m)" % viper.global_position.distance_to(player.global_position))
	check(absf(viper.global_position.z - start.z) < 0.4, "straight along the line")
	await _clear_enemies()


func _laser() -> void:
	var eye: Node3D = dungeon.call("spawn_enemy", "crystal_eye", _near(Vector3(0, 0, -4)))
	eye.get("_moves").set("_timer", 0.0)
	await physics_frame
	await physics_frame
	var beam_script: Script = script("res://scenes/actors/enemy_beam.gd")
	var beams: Array = dungeon.get("effects").get_children().filter(func(node: Node) -> bool: return node.get_script() == beam_script)
	check(not beams.is_empty(), "the Funkelstein fires a beam along its line")
	player.set("invulnerable", 0.0)
	var before: int = _life()
	check(await wait_until(func() -> bool: return _life() < before, 1.5), "standing in the beam hurts")
	await _clear_enemies()


func _warden() -> void:
	var warden: Node3D = dungeon.call("spawn_enemy", "wild_warden", _near(Vector3(0, 0, -5)))
	await physics_frame
	var brain: Object = warden.get("_brain")
	player.call("hold", 1.4)
	await _wait(2)
	check_eq(brain.get("_attack"), "aimed_shot", "caught in a snare: the Wildhüter draws his bow at once")
	await _clear_enemies()
