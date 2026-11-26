extends "res://assets/_reference/_lib/base_test.gd"
## FloorLayout: every floor has exactly one start, item room, shop and boss room, all rooms are
## connected, special rooms are dead ends, the boss is at least 3 rooms from the start, and the
## same seed gives the same floor.


func run() -> void:
	var layout_script: Script = script("res://scripts/systems/floor_layout.gd")
	for floor_data: Dictionary in script("res://scripts/core/content.gd").call("floors"):
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
	var a := RandomNumberGenerator.new()
	a.seed = 42
	var b := RandomNumberGenerator.new()
	b.seed = 42
	check_eq(layout_script.call("generate", a, 7).get("rooms"), layout_script.call("generate", b, 7).get("rooms"), "same seed, same floor")
