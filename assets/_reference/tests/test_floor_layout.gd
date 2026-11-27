extends "res://assets/_reference/_lib/base_test.gd"
## FloorLayout: every floor has exactly one start, item room, shop and boss room, all rooms are
## connected, special rooms are dead ends, the boss is at least 3 rooms from the start, and the
## same seed gives the same floor.


func run() -> void:
	var layout_script: Script = script("res://scripts/systems/floor_layout.gd")
	_item_rooms(layout_script)
	for floor_data: Dictionary in script("res://scripts/core/content.gd").call("floors"):
		if not bool(floor_data.get("shop_room", true)):
			continue
		var normal: int = int(floor_data["rooms"])
		for i in 150:
			var rng := RandomNumberGenerator.new()
			rng.seed = i * 31 + normal
			var layout: Object = layout_script.call("generate", rng, normal)
			var rooms: Dictionary = layout.get("rooms")
			var counts: Dictionary = {}
			for cell: Vector2i in rooms:
				counts[rooms[cell]] = int(counts.get(rooms[cell], 0)) + 1
			check_eq(rooms.size(), normal + 4, "room count, seed %d" % i)
			for type: String in ["start", "item", "shop", "boss"]:
				check_eq(int(counts.get(type, 0)), 1, "%s rooms, seed %d" % [type, i])
			var distance: Dictionary = layout.get("distance")
			check_eq(distance.size(), rooms.size(), "all rooms reachable, seed %d" % i)
			for type: String in ["item", "shop", "boss"]:
				var cell: Vector2i = layout.call("cell_of", type)
				check_eq((layout.call("neighbours", cell) as Array).size(), 1, "%s is a dead end, seed %d" % [type, i])
			check(int(distance[layout.call("cell_of", "boss")]) >= 3, "boss far from start, seed %d" % i)
	_first_floor(layout_script)
	var a := RandomNumberGenerator.new()
	a.seed = 42
	var b := RandomNumberGenerator.new()
	b.seed = 42
	check_eq(layout_script.call("generate", a, 7).get("rooms"), layout_script.call("generate", b, 7).get("rooms"), "same seed, same floor")


## Floor 1 has no item room (floors.json item_room false); from floor 2 on it is behind a key door.
func _item_rooms(layout_script: Script) -> void:
	var content: Script = script("res://scripts/core/content.gd")
	var first: Dictionary = content.call("floor_data", 0)
	check_eq(first.get("item_room", true), false, "floor 1: no item room")
	for index in range(1, (content.call("floors") as Array).size()):
		check((content.call("floor_data", index).get("key_doors", []) as Array).has("item"), "floor %d: the item room needs a key" % (index + 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var layout: Object = layout_script.call("generate", rng, 7)
	var rooms: Dictionary = layout.get("rooms")
	check(rooms.values().has("item"), "a new floor has an item room")
	var count: int = rooms.size()
	layout.call("remove_item_room")
	check(not (layout.get("rooms") as Dictionary).values().has("item"), "remove_item_room: none left")
	check_eq((layout.get("rooms") as Dictionary).size(), count, "it became a normal room (same number of rooms)")


## The first floor (floors.json): at most 6 rooms, among them the boss room and a sure sacrifice
## room; no shop, no item room, no secret room, no special room; built like Dungeon.build does.
func _first_floor(layout_script: Script) -> void:
	var first: Dictionary = script("res://scripts/core/content.gd").call("floor_data", 0)
	check_eq(first.get("shop_room", true), false, "floor 1: no shop")
	for i in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 7 + 1
		var dead_ends: Array[String] = ["item"]
		var layout: Object = layout_script.call("generate", rng, int(first["rooms"]), dead_ends)
		layout.call("remove_item_room")
		var extra := RandomNumberGenerator.new()
		extra.seed = i * 13 + 5
		layout.call("add_extras", extra, float(first["sacrifice_chance"]), bool(first["secret_room"]), bool(first["special_room"]))
		var types: Array = (layout.get("rooms") as Dictionary).values()
		check(types.size() <= 6, "floor 1: at most 6 rooms, seed %d (%d)" % [i, types.size()])
		check_eq(types.count("boss"), 1, "floor 1: a boss room, seed %d" % i)
		check_eq(types.count("sacrifice"), 1, "floor 1: a sacrifice room, seed %d" % i)
		for type: String in ["shop", "item", "secret", "special"]:
			check(not types.has(type), "floor 1: no %s room, seed %d" % [type, i])
		check(int((layout.get("distance") as Dictionary)[layout.call("cell_of", "boss")]) >= 3, "floor 1: boss far from start, seed %d" % i)
