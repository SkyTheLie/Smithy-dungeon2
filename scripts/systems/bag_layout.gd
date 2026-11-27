class_name BagLayout
extends RefCounted
## The shapes of the inventory (only rules, no state): the base bag (data/meta.json "bag":
## columns × rows cells, top left at 0,0), the sizes of loot (data/loot.json "size",
## "default_size") and the backpacks that are attached to the bag (data/backpacks.json, like the
## bags of a backpack game). A backpack placement is {"id", "x", "y", "rot"}: its top left cell
## and whether it is turned by 90 degrees. Placements are valid when every backpack lies inside the
## board (meta.json bag.board), covers nothing (not the bag, not another backpack) and is joined
## to the bag through edges (directly or through other backpacks).
## MetaState keeps the placements (backpacks, place_backpack); Bag turns them into cells.


static func settings() -> Dictionary:
	return Content.meta("bag")


## The cells of the base bag (columns × rows from 0,0).
static func base_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var columns: int = maxi(1, int(settings().get("columns", 8)))
	var rows: int = maxi(1, int(settings().get("rows", 3)))
	for y in rows:
		for x in columns:
			cells.append(Vector2i(x, y))
	return cells


## The part of the grid where backpacks may lie: meta.json bag.board [left, top, right, bottom]
## (inclusive cells).
static func board_rect() -> Rect2i:
	var board: Array = settings().get("board", [-5, -4, 12, 6])
	var from := Vector2i(int(board[0]), int(board[1]))
	return Rect2i(from, Vector2i(int(board[2]), int(board[3])) - from + Vector2i.ONE)


## Width × height of `size` turned by 90 degrees when `rot`.
static func turned(size: Vector2i, rot: bool) -> Vector2i:
	return Vector2i(size.y, size.x) if rot else size


static func _vector(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Array and (value as Array).size() >= 2:
		return Vector2i(maxi(1, int(value[0])), maxi(1, int(value[1])))
	return fallback


## How many cells loot `id` takes, not turned (loot.json "size", else "default_size").
static func loot_size(id: String) -> Vector2i:
	var fallback: Vector2i = _vector(Content.get_file("loot").get("default_size", [1, 1]), Vector2i.ONE)
	return _vector(Content.material(id).get("size", null), fallback)


# --- Backpacks ----------------------------------------------------------------------

static func backpacks() -> Dictionary:
	return Content.get_file("backpacks").get("backpacks", {})


static func backpack(id: String) -> Dictionary:
	return backpacks().get(id, {})


static func backpack_size(id: String) -> Vector2i:
	return _vector(backpack(id).get("size", null), Vector2i.ONE)


## The cells a backpack covers at placement `placement` ({"id", "x", "y", "rot"}).
static func cells_of(placement: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var size: Vector2i = turned(backpack_size(String(placement.get("id", ""))), bool(placement.get("rot", false)))
	var at := Vector2i(int(placement.get("x", 0)), int(placement.get("y", 0)))
	for y in size.y:
		for x in size.x:
			cells.append(at + Vector2i(x, y))
	return cells


## true if the bag with these backpacks is allowed: known backpacks, each once, inside the board,
## nothing covered, all joined to the bag.
static func is_valid(placements: Array) -> bool:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in base_cells():
		taken[cell] = true
	var board: Rect2i = board_rect()
	var seen: Array[String] = []
	var pieces: Array = []
	for entry: Variant in placements:
		if not entry is Dictionary:
			return false
		var id: String = String((entry as Dictionary).get("id", ""))
		if backpack(id).is_empty() or seen.has(id):
			return false
		seen.append(id)
		var cells: Array[Vector2i] = cells_of(entry)
		for cell: Vector2i in cells:
			if not board.has_point(cell) or taken.has(cell):
				return false
			taken[cell] = true
		pieces.append(cells)
	# Joined: grow from the bag over every backpack that touches what is joined already.
	var joined: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in base_cells():
		joined[cell] = true
	var left: Array = pieces.duplicate()
	var grew: bool = true
	while grew and not left.is_empty():
		grew = false
		for piece: Array in left.duplicate():
			if _touches(piece, joined):
				for cell: Vector2i in piece:
					joined[cell] = true
				left.erase(piece)
				grew = true
	return left.is_empty()


static func _touches(piece: Array, joined: Dictionary[Vector2i, bool]) -> bool:
	for cell: Vector2i in piece:
		for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if joined.has(cell + dir):
				return true
	return false


## `placements` with backpack `id` at `at` (turned when `rot`) instead of where it was.
static func with_moved(placements: Array, id: String, at: Vector2i, rot: bool) -> Array:
	var result: Array = without(placements, id)
	result.append({"id": id, "x": at.x, "y": at.y, "rot": rot})
	return result


static func without(placements: Array, id: String) -> Array:
	var result: Array = []
	for entry: Variant in placements:
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) != id:
			result.append((entry as Dictionary).duplicate())
	return result


## The first allowed place for backpack `id` (rows from the top, both turns), or {} if none.
## Prefers places right of / below the bag, so a new backpack lands somewhere sensible.
static func first_spot(placements: Array, id: String) -> Dictionary:
	var board: Rect2i = board_rect()
	var spots: Array[Vector2i] = []
	for y in range(board.position.y, board.end.y):
		for x in range(board.position.x, board.end.x):
			spots.append(Vector2i(x, y))
	spots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da: int = absi(a.y) + absi(a.x - 4)
		var db: int = absi(b.y) + absi(b.x - 4)
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	for spot: Vector2i in spots:
		for rot: bool in [false, true]:
			if is_valid(with_moved(placements, id, spot, rot)):
				return {"id": id, "x": spot.x, "y": spot.y, "rot": rot}
	return {}
