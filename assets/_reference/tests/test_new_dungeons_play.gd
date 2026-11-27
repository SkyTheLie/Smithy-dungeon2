extends "res://assets/_reference/_lib/base_test.gd"
## In the real run scene, one floor of every area of the new dungeons (Moor, Frostgipfel,
## Glutschlund): the floor is built in its area, every enemy of the area moves for a moment
## without errors, the normal rooms have their traps, and standing on a trap hurts (once, then
## the player is invulnerable for a moment like after every hit).

var game: Node
## Floors where the player stepped on a trap (lava and poison are always dangerous).
var stepped: int = 0


func run() -> void:
	game = root.get_node("Game")
	var content: Script = script("res://scripts/core/content.gd")
	for id: String in ["moor", "frost", "vulkan"]:
		for index: int in [0, 2, 4]:
			await _floor(content, id, index)
	check(stepped >= 5, "stepped on traps in several floors (%d)" % stepped)
	await _dragon(content)
	content.set("active_dungeon", "")


## The last floor of the Glutschlund: the big Vulkandrache (128 x 96 pictures, 4.4 m) in its
## arena (lava along the walls, red light), breathing fire with its own picture.
func _dragon(content: Script) -> void:
	content.set("active_dungeon", "vulkan")
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(9)
	run_state.set("floor_index", 5)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	check_eq(dungeon.get("end_boss_id"), "volcano_dragon", "the Vulkandrache waits at the end (Boss-Altar)")
	check(dungeon.get("boss_id") != "volcano_dragon", "and is not the boss of the floor")
	var layout: Object = dungeon.get("layout")
	check(layout != null, "floor built")
	# Its arena is the Boss-Altar behind the portal.
	dungeon.call("enter_boss_altar")
	var room: Node3D = dungeon.get("altar")
	var lava: Array = (room.get("hazards") as Array).filter(func(h: Node) -> bool: return h.get("kind") == "lava")
	check(lava.size() >= 4, "its arena has lava (%d)" % lava.size())
	check(room.get_children().any(func(n: Node) -> bool: return n is OmniLight3D and (n as OmniLight3D).light_color.g < 0.5), "and a red light")
	var dragon: Node3D = dungeon.call("spawn_enemy", "volcano_dragon", room.global_position + Vector3(0, 0, -2.0))
	await physics_frame
	var sprite: Sprite3D = dragon.get("_sprite")
	check_eq(sprite.hframes, 6, "128-px pictures: 6 walk frames")
	check(is_equal_approx(sprite.pixel_size * 96.0, 4.4), "4.4 m tall")
	dragon.call("show_attack", "spray")
	check(sprite.texture.resource_path.ends_with("volcano_dragon_breath.png") and sprite.hframes == 18, "breathes fire with its own picture")
	dragon.call("end_attack")
	check(sprite.texture.resource_path.ends_with("volcano_dragon_walk.png"), "and walks on afterwards")
	for i in 120:
		player.set("invulnerable", 10.0)
		await physics_frame
	check(is_instance_valid(dragon) and dragon.get("alive"), "fights for two seconds")
	dragon.call("take_damage", 99999.0, Vector3.ZERO, false)
	var death: int = 0
	for i in 5:
		await physics_frame
	death = sprite.hframes
	check_eq(death, 9, "its death has 9 pictures")
	scene.queue_free()
	await process_frame


func _floor(content: Script, id: String, index: int) -> void:
	content.set("active_dungeon", id)
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(31 + index)
	run_state.set("floor_index", index)
	game.set("run", run_state)
	var scene: Node = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	var dungeon: Node = scene.get_node("%Dungeon")
	var player: Node3D = scene.get_node("%Player") as Node3D
	var data: Dictionary = dungeon.get("floor_data")
	var expected: Dictionary = content.call("floor_data", index, id)
	var name: String = "%s floor %d (%s)" % [id, index + 1, data.get("name", "?")]
	check_eq(data.get("theme"), expected.get("theme"), "%s: built in its area" % name)
	# Every enemy of the area, next to the player, for half a second.
	var start: Vector3 = player.global_position
	for entry: Array in data.get("enemies", []):
		dungeon.call("spawn_enemy", String(entry[0]), start + Vector3(2.0, 0, -2.0))
		for i in 30:
			player.set("invulnerable", 10.0)
			await physics_frame
		var alive: Array = dungeon.call("get_enemies")
		check(not alive.is_empty(), "%s: %s is there" % [name, entry[0]])
		for enemy: Node in alive.duplicate():
			enemy.set("hidden_phase", false)
			enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
		await physics_frame
	# Traps in the normal rooms.
	var traps: Array = []
	for room: Node in (dungeon.get("rooms") as Dictionary).values():
		traps.append_array(room.get("hazards"))
	if not (data.get("hazards", []) as Array).is_empty():
		check(not traps.is_empty(), "%s: the rooms have traps" % name)
	for trap: Node3D in traps:
		check(absf(trap.position.x) > 1.4 and absf(trap.position.z) > 1.4, "%s: traps keep the door paths free" % name)
	# Onto a trap that is dangerous now: one hit, then a moment of safety.
	var lava: Node3D = null
	for trap: Node3D in traps:
		if trap.call("is_dangerous"):
			lava = trap
			break
	if lava:
		var cell: Vector2i = script("res://scenes/run/room_builder.gd").call("cell_at", lava.global_position)
		dungeon.set("current_cell", cell)
		player.set("invulnerable", 0.0)
		var before: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
		player.global_position = Vector3(lava.global_position.x, player.global_position.y, lava.global_position.z)
		dungeon.call("_check_hazards")
		var after: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
		check_eq(before - after, int(lava.get("damage")), "%s: stepping on the %s hurts" % [name, lava.get("kind")])
		dungeon.call("_check_hazards")
		var again: int = int(run_state.get("health")) + int(run_state.get("shield")) + int(run_state.get("blue"))
		check_eq(again, after, "%s: not again at once (invulnerable)" % name)
		stepped += 1
	scene.queue_free()
	await process_frame
	await process_frame
