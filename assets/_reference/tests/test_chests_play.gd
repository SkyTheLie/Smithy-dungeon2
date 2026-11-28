extends "res://assets/_reference/_lib/base_test.gd"
## Chests (data/chests.json, Chest, Dungeon.open_chest): the data is complete; in the real run
## scene a wooden chest opens when the player walks against it and loot falls out; a lock chest
## stays shut without a key, takes one key (any key) and opens; a bomb blows a lock chest open
## and bounces off a vault chest (it stays shut); a vault chest opens with a key. A stone chamber
## puts a chest in the middle with a ring of rocks around it; enemies never spawn inside; a bomb
## at the ring breaks rocks. Closed chests show on the map, open ones not.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object
var room: Node3D


func run() -> void:
	_data()
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
	player.set("invulnerable", 999.0)
	room = dungeon.call("get_room", dungeon.get("current_cell"))
	await _wood()
	await _lock_and_key()
	await _bombs()
	await _chamber()


func _data() -> void:
	var chests: Dictionary = script("res://scripts/core/content.gd").call("get_file", "chests")
	var kinds: Dictionary = chests.get("kinds", {})
	for id: String in ["wood", "lock", "vault"]:
		check(kinds.has(id), "chest kind %s" % id)
	for id: String in kinds:
		var data: Dictionary = kinds[id]
		check(ResourceLoader.exists(String(data.get("texture", ""))) and ResourceLoader.exists(String(data.get("open_texture", ""))), "%s: pictures" % id)
		check(String(data.get("bomb", "")) in ["break", "none"], "%s: known bomb effect" % id)
		var drops: Array = data.get("drops", [])
		check(drops.size() == 2 and int(drops[0]) >= 1 and int(drops[1]) >= int(drops[0]), "%s: drops [min, max]" % id)
		for entry: Variant in data.get("table", []):
			check(String((entry as Array)[0]) in ["coins", "heart", "bomb", "key"], "%s: known drop %s" % [id, (entry as Array)[0]])
	check(not bool((kinds["wood"] as Dictionary).get("key", true)), "wood needs no key")
	check(bool((kinds["lock"] as Dictionary).get("key", false)) and String((kinds["lock"] as Dictionary).get("bomb")) == "break", "lock: key or bomb")
	check(bool((kinds["vault"] as Dictionary).get("key", false)) and String((kinds["vault"] as Dictionary).get("bomb")) == "none", "vault: only a key")
	var rules: Dictionary = chests.get("room", {})
	check((rules.get("ring_radius", []) as Array).size() == (rules.get("ring_rocks", []) as Array).size(), "ring radius and rocks per ring")


func _loot_count() -> int:
	var count: int = 0
	for thing: Variant in room.get("loot"):
		if is_instance_valid(thing) and (thing as Node).get_class() != "StaticBody3D":
			count += 1
	return count


func _wood() -> void:
	var chest: Node3D = dungeon.call("add_chest", room, "wood", Vector3(4.0, 0, 3.0))
	await physics_frame
	check(chest.call("map_icon") != null, "a closed chest shows on the map")
	var before: int = _loot_count()
	player.global_position = chest.global_position + Vector3(-0.9, 0, 0)
	await physics_frame
	await physics_frame
	check(chest.get("opened"), "walking against a wooden chest opens it")
	check(_loot_count() > before, "loot falls out")
	check(chest.call("map_icon") == null, "an open chest is not on the map")
	player.global_position = room.global_position


func _lock_and_key() -> void:
	var chest: Node3D = dungeon.call("add_chest", room, "lock", Vector3(-4.0, 0, 3.0))
	await physics_frame
	player.global_position = chest.global_position + Vector3(0.9, 0, 0)
	await physics_frame
	await physics_frame
	check(not chest.get("opened"), "a lock chest stays shut without a key")
	player.global_position = room.global_position
	await physics_frame
	var bag: Object = run_state.get("bag")
	bag.call("add", "key", 1)
	var keys: int = int(bag.call("count_of", "key"))
	player.global_position = chest.global_position + Vector3(0.9, 0, 0)
	await physics_frame
	await physics_frame
	check(chest.get("opened"), "with a key it opens")
	check(int(bag.call("count_of", "key")) == keys - 1, "and the key is used up")
	player.global_position = room.global_position


func _bombs() -> void:
	var lock: Node3D = dungeon.call("add_chest", room, "lock", Vector3(4.0, 0, -3.0))
	var vault: Node3D = dungeon.call("add_chest", room, "vault", Vector3(-4.0, 0, -3.0))
	await physics_frame
	dungeon.call("explode", lock.global_position + Vector3(0, 0, 0.8), 2.3, 1.0, false)
	check(lock.get("opened"), "a bomb blows a lock chest open")
	dungeon.call("explode", vault.global_position + Vector3(0, 0, 0.8), 2.3, 1.0, false)
	check(not vault.get("opened"), "a bomb bounces off a vault chest")
	var bag: Object = run_state.get("bag")
	bag.call("add", "key", 1)
	player.global_position = vault.global_position + Vector3(0.9, 0, 0)
	await physics_frame
	await physics_frame
	check(vault.get("opened"), "a key opens the vault chest")
	player.global_position = room.global_position


func _chamber() -> void:
	# A fresh room far from the others is not needed: the chamber goes into the start room here.
	player.global_position = room.global_position + Vector3(5.5, 0, 0)
	await physics_frame
	var rocks_before: int = (room.get("rocks") as Array).size()
	var chest: Node3D = dungeon.call("add_chest_chamber", room, "wood", 1)
	await physics_frame
	check((room.get("rocks") as Array).size() - rocks_before == 12, "one ring of twelve rocks")
	check(chest.position.is_equal_approx(Vector3.ZERO), "the chest stands in the middle")
	check(float(room.get("chamber_radius")) > 2.2, "the room knows its chamber")
	for i in 20:
		var spot: Vector3 = dungeon.call("_free_spot", room, 1.2, false)
		if spot != Vector3.INF:
			check(spot.length() > float(room.get("chamber_radius")), "nothing is placed inside the chamber")
	var ring_rock: Node3D = (room.get("rocks") as Array)[rocks_before]
	var outside: Vector3 = ring_rock.global_position + (ring_rock.global_position - room.global_position).normalized() * 0.6
	var count_before: int = (room.get("rocks") as Array).size()
	dungeon.call("explode", outside, 2.3, 1.0, false)
	check((room.get("rocks") as Array).size() < count_before, "a bomb at the ring breaks rocks")
	check(not chest.get("opened"), "from outside the ring the chest is not hit")
