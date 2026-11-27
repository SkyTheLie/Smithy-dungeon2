class_name FloorLayout
extends RefCounted
## Which rooms a floor has and where they are, on a grid (like the map). Made by generate():
## a start room in the middle, normal rooms grown outwards, and three special rooms at dead ends
## (rooms with one neighbour): the boss room as far from the start as possible, the item room and
## the shop at two others. Grid x = east, grid y = south (map up = north).
## add_extras() then adds rooms that are not reached through normal doors: a secret room (next to
## at least two rooms, not the boss; its wall has to be blown up), sometimes a sacrifice room (a
## dead end at a normal room) and the special room behind the boss room (opens after the boss).

const GRID_SIZE := Vector2i(9, 8)
const START := Vector2i(4, 4)
const DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

const START_ROOM: String = "start"
const NORMAL: String = "normal"
const ITEM: String = "item"
const SHOP: String = "shop"
const BOSS: String = "boss"
const SECRET: String = "secret"
const SACRIFICE: String = "sacrifice"
const SPECIAL: String = "special"
## Rooms whose doorway is a wall at first (blown up / opened after the boss).
const HIDDEN_TYPES: Array[String] = [SECRET, SPECIAL]

## Cell -> room type.
var rooms: Dictionary[Vector2i, String] = {}
## Cell -> number of steps from the start room.
var distance: Dictionary[Vector2i, int] = {}


func get_type(cell: Vector2i) -> String:
	return rooms.get(cell, "")


func cell_of(type: String) -> Vector2i:
	for cell: Vector2i in rooms:
		if rooms[cell] == type:
			return cell
	return Vector2i(-1, -1)


func neighbours(cell: Vector2i) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for dir: Vector2i in DIRECTIONS:
		if rooms.has(cell + dir):
			list.append(cell + dir)
	return list


## A new layout with `normal_rooms` normal rooms plus start, boss and the rooms in `dead_ends`
## (each at its own dead end; a floor without a shop leaves SHOP out, floors.json "shop_room").
static func generate(rng: RandomNumberGenerator, normal_rooms: int, dead_ends: Array[String] = [ITEM, SHOP]) -> FloorLayout:
	for attempt in 500:
		var layout: FloorLayout = _try(rng, normal_rooms + 2 + dead_ends.size(), dead_ends)
		if layout != null:
			return layout
	push_error("FloorLayout: no layout found, using a straight line")
	return _fallback(normal_rooms, dead_ends)


## Grows `total` rooms from the start (each new room touches only one room, so there are dead ends),
## then turns dead ends into the boss room and the rooms of `special`. null if that did not work out.
static func _try(rng: RandomNumberGenerator, total: int, special: Array[String]) -> FloorLayout:
	var layout := FloorLayout.new()
	layout.rooms[START] = NORMAL
	var queue: Array[Vector2i] = [START]
	while not queue.is_empty() and layout.rooms.size() < total:
		var cell: Vector2i = queue.pop_front()
		var dirs: Array[Vector2i] = DIRECTIONS.duplicate()
		_shuffle(dirs, rng)
		for dir: Vector2i in dirs:
			if layout.rooms.size() >= total:
				break
			var next: Vector2i = cell + dir
			if not _inside(next) or layout.rooms.has(next) or rng.randf() < 0.5:
				continue
			if layout.neighbours(next).size() > 1:
				continue
			layout.rooms[next] = NORMAL
			queue.append(next)
	if layout.rooms.size() < total:
		return null
	layout._measure()
	var dead_ends: Array[Vector2i] = []
	for cell: Vector2i in layout.rooms:
		if cell != START and layout.neighbours(cell).size() == 1:
			dead_ends.append(cell)
	if dead_ends.size() < 1 + special.size():
		return null
	dead_ends.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return layout.distance[a] > layout.distance[b])
	# The boss room must not sit right next to the start.
	if layout.distance[dead_ends[0]] < 3:
		return null
	layout.rooms[dead_ends[0]] = BOSS
	var rest: Array[Vector2i] = dead_ends.slice(1)
	_shuffle(rest, rng)
	for i in special.size():
		layout.rooms[rest[i]] = special[i]
	layout.rooms[START] = START_ROOM
	return layout


## Floors without an item room (floors.json "item_room": false): it becomes a normal room.
func remove_item_room() -> void:
	for cell: Vector2i in rooms:
		if rooms[cell] == ITEM:
			rooms[cell] = NORMAL


static func _fallback(normal_rooms: int, special: Array[String]) -> FloorLayout:
	var layout := FloorLayout.new()
	layout.rooms[START] = START_ROOM
	var cell: Vector2i = START
	for i in normal_rooms:
		cell += Vector2i(1, 0) if i % 2 == 0 else Vector2i(0, 1)
		layout.rooms[cell] = NORMAL
	var spots: Array[Vector2i] = [START + Vector2i(-1, 0), START + Vector2i(0, -1)]
	for i in mini(special.size(), spots.size()):
		layout.rooms[spots[i]] = special[i]
	layout.rooms[cell + Vector2i(1, 0)] = BOSS
	layout._measure()
	return layout


## Adds the secret room, the special room behind the boss (each only if asked for) and (with
## `sacrifice_chance`) a sacrifice room on free cells. Uses its own `rng`, so the other rooms
## stay the same.
func add_extras(rng: RandomNumberGenerator, sacrifice_chance: float, secret: bool = true, special: bool = true) -> void:
	var free: Array[Vector2i] = []
	for cell: Vector2i in rooms:
		for dir: Vector2i in DIRECTIONS:
			var next: Vector2i = cell + dir
			if _inside(next) and not rooms.has(next) and not free.has(next):
				free.append(next)
	_shuffle(free, rng)
	var boss: Vector2i = cell_of(BOSS)
	# Behind the boss: a free cell that touches only the boss room.
	for cell: Vector2i in free:
		var around: Array[Vector2i] = neighbours(cell)
		if special and around.size() == 1 and around[0] == boss:
			rooms[cell] = SPECIAL
			free.erase(cell)
			break
	# Secret room: touches two or more rooms, none of them boss or special.
	for cell: Vector2i in free:
		var around: Array[Vector2i] = neighbours(cell)
		if secret and around.size() >= 2 and around.all(func(c: Vector2i) -> bool: return rooms[c] in [NORMAL, START_ROOM, ITEM, SHOP]):
			rooms[cell] = SECRET
			free.erase(cell)
			break
	if rng.randf() < sacrifice_chance:
		# A dead end at a normal room; if there is none, at the start room.
		for allowed: String in [NORMAL, START_ROOM]:
			var placed: bool = false
			for cell: Vector2i in free:
				var around: Array[Vector2i] = neighbours(cell)
				if around.size() == 1 and rooms[around[0]] == allowed:
					rooms[cell] = SACRIFICE
					placed = true
					break
			if placed:
				break
	_measure()


## Steps from the start to every room (breadth-first).
func _measure() -> void:
	distance.clear()
	distance[START] = 0
	var queue: Array[Vector2i] = [START]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for next: Vector2i in neighbours(cell):
			if not distance.has(next):
				distance[next] = distance[cell] + 1
				queue.append(next)


static func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y


static func _shuffle(list: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Vector2i = list[i]
		list[i] = list[j]
		list[j] = swap
