extends "res://assets/_reference/_lib/base_test.gd"
## Storm eagle (enemies.json "storm_eagle", BossBrain sky_meteors / dive / gust): in the real run
## scene sky_meteors lifts it out of reach (cannot be hurt) and meteors hit the floor (embers lie
## there a moment), then it comes down again; dive lands on the marked spot and leaves it dazed
## (double damage); gust pushes the player away.

var scene: Node
var dungeon: Node
var player: Node3D
var room: Node3D


func run() -> void:
	var game: Node = root.get_node("Game")
	script("res://scripts/core/content.gd").set("active_dungeon", "")
	game.set("run", script("res://scripts/systems/run_state.gd").new(5))
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	player.set("invulnerable", 999.0)
	room = dungeon.call("get_room", dungeon.get("current_cell"))
	player.global_position = room.global_position + Vector3(-3.0, 0, 0)
	var eagle: Node3D = dungeon.call("spawn_enemy", "storm_eagle", room.global_position + Vector3(4.0, 0, 0))
	await physics_frame
	var brain: Object = eagle.get("_brain")
	brain.set("_wait", 99.0)
	# Meteors.
	var hazards_before: int = (room.get("hazards") as Array).size()
	brain.set("_attack", "sky_meteors")
	brain.call("_start", Vector3.LEFT)
	check(await wait_until(func() -> bool: return float(eagle.get("_jump_y")) > 3.0, 1.0), "it flies up")
	var hp: float = float(eagle.get("hp"))
	eagle.call("take_damage", 5.0, Vector3.ZERO, false)
	check(is_equal_approx(float(eagle.get("hp")), hp), "up there it cannot be hurt")
	check(await wait_until(func() -> bool: return (room.get("hazards") as Array).size() > hazards_before, 3.0), "meteors hit and leave embers")
	check(await wait_until(func() -> bool: return String(brain.get("_attack")).is_empty(), 5.0), "the attack ends")
	await physics_frame
	check(float(eagle.get("_jump_y")) < 0.1 and not eagle.get("hidden_phase"), "it is down again")
	# Dive.
	var marked: Vector3 = player.global_position
	brain.set("_attack", "dive")
	brain.call("_start", Vector3.LEFT)
	player.global_position += Vector3(0, 0, 3.0)
	check(await wait_until(func() -> bool: return float(brain.get("_step")) >= 1.0, 2.5), "it dives")
	check(Vector2(eagle.global_position.x - marked.x, eagle.global_position.z - marked.z).length() < 1.0, "onto the marked spot")
	check(float(eagle.get("stun_left")) > 0.0, "and lies dazed there")
	await wait_until(func() -> bool: return String(brain.get("_attack")).is_empty(), 3.0)
	# Gust.
	player.global_position = eagle.global_position + Vector3(-2.0, 0, 0)
	brain.set("_attack", "gust")
	brain.call("_start", Vector3.LEFT)
	var before: float = player.global_position.distance_to(eagle.global_position)
	await create_timer(0.9).timeout
	check(player.global_position.distance_to(eagle.global_position) > before + 0.5, "the wing beat pushes the player away")
	eagle.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame
	await physics_frame
