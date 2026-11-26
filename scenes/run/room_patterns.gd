class_name RoomPatterns
extends RefCounted
## Rock layouts for normal rooms (local positions, metres from the middle; the room is 15 x 11 m).
## Dungeon._add_rocks leaves out every spot on the paths between the doors (|x| or |z| < 1.5).
## A rock is about 1.1 m wide, so rocks 1 m apart form a wall.


static func spots(pattern: String, rng: RandomNumberGenerator) -> Array[Vector3]:
	var list: Array[Vector3] = []
	match pattern:
		"walls":
			# Two walls across the room, one door path open in each.
			for z: float in [-2.5, 2.5]:
				for x in range(-6, 7):
					list.append(Vector3(x, 0, z))
		"pillars":
			# Four thick pillars of 2 x 2 rocks.
			for corner: Vector2 in [Vector2(-4, -3), Vector2(3, -3), Vector2(-4, 2), Vector2(3, 2)]:
				for dx in 2:
					for dz in 2:
						list.append(Vector3(corner.x + dx, 0, corner.y + dz))
		"ring":
			for i in 20:
				var angle: float = TAU * i / 20.0
				list.append(Vector3(cos(angle) * 4.5, 0, sin(angle) * 3.2))
		"corners":
			# An L in every corner.
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					for i in 3:
						list.append(Vector3(sx * (5.5 - i), 0, sz * 3.5))
					list.append(Vector3(sx * 5.5, 0, sz * 2.5))
		"columns":
			# Two lines along the room, open at the door path.
			for x: float in [-3.5, 3.5]:
				for z in range(-4, 5):
					list.append(Vector3(x, 0, z))
		"checker":
			for x: float in [-5.5, -3.5, 3.5, 5.5]:
				for z: float in [-3.5, -2.0, 2.0, 3.5]:
					if int(x + z) % 2 == 0 or rng.randf() < 0.3:
						list.append(Vector3(x, 0, z))
	return list
