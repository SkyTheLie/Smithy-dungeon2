extends "res://assets/_reference/_lib/base_test.gd"
## Traps in the real run scene: pigeons sit on a visible trap (hazard_types decor) and fly off
## when the player steps in; the player's own traps (owner "player") hurt enemies on the ground,
## not flying ones and never the player; an own snare stuns; a shot with "traps" from an item or
## relic (ShotStats.traps) lays its trap where it ends; at most PLAYER_TRAPS_MAX in a room.

var scene: Node
var dungeon: Node
var player: Node3D
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
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	await _pigeons()
	await _own_traps()
	await _shot_lays_trap()


func _pigeons() -> void:
	var at: Vector3 = player.global_position + Vector3(3.0, 0, 0)
	var lava: Node3D = dungeon.call("add_hazard", "lava", at, 0.0)
	await process_frame
	var birds: Array = lava.get("_decor_sprites")
	check_eq(birds.size(), 1, "pigeons sit on the lava")
	var first: int = (birds[0] as Sprite3D).frame
	check(await wait_until(func() -> bool: return (birds[0] as Sprite3D).frame != first, 1.0), "they peck (the picture changes)")
	var snare: Node3D = dungeon.call("add_hazard", "snare", at + Vector3(0, 0, 3.0), 0.0)
	await process_frame
	check((snare.get("_decor_sprites") as Array).is_empty(), "no pigeons on a hidden snare")
	(dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].get("hazards").erase(snare)
	snare.queue_free()
	player.set("invulnerable", 0.0)
	var before: int = int(run_state.get("health")) + int(run_state.get("shield"))
	player.global_position = Vector3(lava.global_position.x, player.global_position.y, lava.global_position.z)
	dungeon.call("_check_hazards")
	check(lava.call("is_scared"), "stepping in scares them off")
	check(int(run_state.get("health")) + int(run_state.get("shield")) < before, "and the lava hurts")
	# Off the lava again (standing on it would burn the player down while the pigeons are away).
	player.global_position += Vector3(0, 0, 3.0)
	check(await wait_until(func() -> bool: return not lava.call("is_scared"), 7.0), "they come back after a while")
	(dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].get("hazards").erase(lava)
	lava.queue_free()
	player.global_position = Vector3(0, player.global_position.y, 0) + (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")].global_position


func _own_traps() -> void:
	var base: Vector3 = player.global_position
	var rat: Node3D = dungeon.call("spawn_enemy", "giant_rat", base + Vector3(3.0, 0, -2.0))
	var bat: Node3D = dungeon.call("spawn_enemy", "bat", base + Vector3(-3.0, 0, -2.0))
	await physics_frame
	# Hold them in place for the test (stunned enemies do not move).
	rat.set("stun_left", 0.0)
	var rat_hp: float = rat.get("hp")
	var spikes: Node3D = dungeon.call("place_player_trap", "player_spikes", rat.global_position, 2.0)
	check(spikes != null and spikes.get("from_player"), "an own trap lies there")
	var bat_hp: float = bat.get("hp")
	dungeon.call("place_player_trap", "player_fire", bat.global_position, 2.0)
	check(await wait_until(func() -> bool: return float(rat.get("hp")) < rat_hp, 1.0), "the own trap hurts the rat")
	var mult: float = float(script("res://scripts/core/content.gd").call("floors_extra", "hazard_types")["player_spikes"]["damage_mult"])
	check(is_equal_approx(rat_hp - float(rat.get("hp")), 2.0 * mult), "damage_mult x the shot's damage")
	check_eq(float(bat.get("hp")), bat_hp, "flying enemies are not caught")
	# The player on their own trap: nothing (the enemies go first, so nothing else can hit).
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	for i in 5:
		await physics_frame
	player.set("invulnerable", 0.0)
	var life: int = int(run_state.get("health")) + int(run_state.get("shield"))
	player.global_position = Vector3(spikes.global_position.x, player.global_position.y, spikes.global_position.z)
	for i in 10:
		await physics_frame
	check_eq(int(run_state.get("health")) + int(run_state.get("shield")), life, "own traps never hurt the player")
	# An own snare stuns.
	var other: Node3D = dungeon.call("spawn_enemy", "giant_rat", base + Vector3(0, 0, -3.5))
	await physics_frame
	dungeon.call("place_player_trap", "player_snare", other.global_position, 2.0)
	check(await wait_until(func() -> bool: return float(other.get("stun_left")) > 0.0, 1.0), "the own snare holds the enemy")
	# A world kind cannot be laid as an own trap.
	check(dungeon.call("place_player_trap", "lava", base, 2.0) == null, "only owner player kinds")
	for enemy: Node in (dungeon.call("get_enemies") as Array).duplicate():
		enemy.call("take_damage", 99999.0, Vector3.ZERO, false)
	await physics_frame


## An item/relic with "traps": the shot lays its trap where it ends; at most PLAYER_TRAPS_MAX.
func _shot_lays_trap() -> void:
	var room: Node = (dungeon.get("rooms") as Dictionary)[dungeon.get("current_cell")]
	var stats: Object = run_state.get("stats")
	stats.set("traps", [{"kind": "player_fire", "chance": 1.0}] as Array[Dictionary])
	var count_own := func() -> int: return (room.get("hazards") as Array).filter(func(h: Node) -> bool: return h.get("from_player") and h.visible).size()
	var before: int = count_own.call()
	dungeon.call("spawn_projectile", player.global_position + Vector3(0, 1.0, 0), Vector3.FORWARD, stats, 0.0, false, [])
	check(await wait_until(func() -> bool: return int(count_own.call()) > before, 3.0), "the shot lays a glow patch where it ends")
	for i in 10:
		dungeon.call("shot_ended", player.global_position + Vector3(float(i) * 0.3 - 1.5, 0, 2.0), stats)
	check_eq(count_own.call(), int(dungeon.get("PLAYER_TRAPS_MAX")), "at most %d own traps in a room" % int(dungeon.get("PLAYER_TRAPS_MAX")))
	stats.set("traps", [] as Array[Dictionary])
