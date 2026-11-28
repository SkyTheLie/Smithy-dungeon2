class_name RoomProps
extends RefCounted
## Decoration of a room: a few standing pictures (crates, barrels, bones, mushrooms, stones …) along
## the walls, like the torches. Mostly looks: no collision, nothing to pick up. Pictures listed in
## props "break" (crates, barrels, sacks …) become a BreakableProp that shots and bombs smash.
## Which pictures: the theme's `props` list in floors.json ([texture, weight, height in metres]);
## how many and how far apart: the top-level `props` settings in floors.json.
## Uses its own random numbers (seeded per room), so the dungeon's random order stays the same.

## Space kept free on both sides of a doorway (metres, measured from the door's middle).
const DOOR_CLEAR: float = RoomBuilder.DOOR_W / 2.0 + 0.9


## Places the decoration in a child node "Props" of `room` (positions local to the room). `doors`: directions with a doorway.
## Returns the placed sprites (for tests).
static func add_props(room: Node3D, table: Array, settings: Dictionary, doors: Array[Vector2i], rng_seed: int) -> Array[Sprite3D]:
	var placed: Array[Sprite3D] = []
	if table.is_empty():
		return placed
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var count_range: Array = settings.get("count", [2, 5])
	var count: int = rng.randi_range(int(count_range[0]), int(count_range[1]))
	var min_gap: float = float(settings.get("min_gap", 1.2))
	var inset: Array = settings.get("inset", [0.25, 0.7])
	var breakable: Dictionary = (settings.get("break", {}) as Dictionary).get("textures", {})
	var spots: Array[Vector3] = []
	var holder := Node3D.new()
	holder.name = "Props"
	room.add_child(holder)
	# A few tries per prop; a spot too close to a door or another prop is skipped.
	for i in count * 6:
		if spots.size() >= count:
			break
		var spot: Vector3 = _wall_spot(rng, doors, inset)
		if spot == Vector3.INF or _too_close(spot, spots, min_gap):
			continue
		spots.append(spot)
		var entry: Array = _pick(table, rng)
		var sprite := _make(entry, rng)
		if sprite == null:
			continue
		placed.append(sprite)
		# Crates, barrels, sacks … (props "break" textures) get a body and can be smashed.
		var sound: String = String(breakable.get(String(entry[0]), ""))
		if sound.is_empty():
			sprite.position = spot
			holder.add_child(sprite)
			continue
		var body := BreakableProp.new()
		body.name = "Breakable"
		body.position = spot
		body.setup(sprite, sprite.pixel_size * float(sprite.texture.get_height()), sound)
		holder.add_child(body)
		if room is DungeonRoom:
			(room as DungeonRoom).breakables.append(body)
	return placed


## A random spot on the floor next to one of the four walls (Vector3.INF if it lies in a doorway).
static func _wall_spot(rng: RandomNumberGenerator, doors: Array[Vector2i], inset: Array) -> Vector3:
	var dir: Vector2i = FloorLayout.DIRECTIONS[rng.randi() % FloorLayout.DIRECTIONS.size()]
	var gap: float = rng.randf_range(float(inset[0]), float(inset[1]))
	var half_w: float = RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T
	var half_d: float = RoomBuilder.ROOM_D / 2.0 - RoomBuilder.WALL_T
	var along: float
	var spot: Vector3
	if dir.y != 0:
		along = rng.randf_range(-half_w + 0.4, half_w - 0.4)
		spot = Vector3(along, 0.0, dir.y * (half_d - gap))
	else:
		along = rng.randf_range(-half_d + 0.4, half_d - 0.4)
		spot = Vector3(dir.x * (half_w - gap), 0.0, along)
	if dir in doors and absf(along) < DOOR_CLEAR:
		return Vector3.INF
	return spot


static func _too_close(spot: Vector3, spots: Array[Vector3], min_gap: float) -> bool:
	for other: Vector3 in spots:
		if spot.distance_to(other) < min_gap:
			return true
	return false


## One entry of the table by weight ([texture, weight, height]).
static func _pick(table: Array, rng: RandomNumberGenerator) -> Array:
	var total: float = 0.0
	for entry: Array in table:
		total += float(entry[1])
	var roll: float = rng.randf() * total
	for entry: Array in table:
		roll -= float(entry[1])
		if roll <= 0.0:
			return entry
	return table.back()


## Upright picture standing on the floor (turns with the camera only around the up axis).
static func _make(entry: Array, rng: RandomNumberGenerator) -> Sprite3D:
	var texture := load(String(entry[0])) as Texture2D
	if texture == null:
		return null
	var height: float = float(entry[2]) * rng.randf_range(0.9, 1.1)
	var sprite := Fx.billboard(texture, height)
	sprite.name = "Prop"
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = true
	# Feet on the floor: the picture's centre sits half its height above the ground.
	sprite.offset = Vector2(0.0, texture.get_height() / 2.0)
	sprite.flip_h = rng.randf() < 0.5
	return sprite
