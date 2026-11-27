class_name ItemGrid
extends RefCounted
## A grid of columns × rows cells where pieces lie (Egon's stash, the table). Only rules, no
## state: a piece is a Dictionary with "x", "y" (its top left cell) and "rot" (turned by 90
## degrees); a piece without "x" has no place in the grid (it lies beside it). How many cells a
## piece covers: ShopGoods.piece_size (turned when "rot").


static func footprint(piece: Dictionary) -> Vector2i:
	return BagLayout.turned(ShopGoods.piece_size(piece), bool(piece.get("rot", false)))


static func is_placed(piece: Dictionary) -> bool:
	return piece.has("x") and piece.has("y")


static func cells_of(piece: Dictionary, at: Vector2i, rot: bool) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var span: Vector2i = BagLayout.turned(ShopGoods.piece_size(piece), rot)
	for y in span.y:
		for x in span.x:
			cells.append(at + Vector2i(x, y))
	return cells


## true if `piece` (turned `rot`) fits with its top left on `at`: inside the grid and on no cell
## of the other placed pieces of `list` (those in `ignore` do not count).
static func fits(list: Array, grid: Vector2i, piece: Dictionary, at: Vector2i, rot: bool, ignore: Array[int] = []) -> bool:
	var mine: Array[Vector2i] = cells_of(piece, at, rot)
	var area := Rect2i(Vector2i.ZERO, grid)
	for cell: Vector2i in mine:
		if not area.has_point(cell):
			return false
	for i in list.size():
		if ignore.has(i) or not list[i] is Dictionary or not is_placed(list[i]):
			continue
		var other: Dictionary = list[i]
		for cell: Vector2i in cells_of(other, Vector2i(int(other["x"]), int(other["y"])), bool(other.get("rot", false))):
			if mine.has(cell):
				return false
	return true


## The first free spot for `piece` (rows from the top, then turned): {"x", "y", "rot"} or {}.
static func free_spot(list: Array, grid: Vector2i, piece: Dictionary, ignore: Array[int] = []) -> Dictionary:
	var span: Vector2i = ShopGoods.piece_size(piece)
	var turns: Array[bool] = [false]
	if span.x != span.y:
		turns.append(true)
	for rot: bool in turns:
		for y in grid.y:
			for x in grid.x:
				if fits(list, grid, piece, Vector2i(x, y), rot, ignore):
					return {"x": x, "y": y, "rot": rot}
	return {}


## The index of the placed piece of `list` lying on `cell` (-1 = none).
static func index_at(list: Array, cell: Vector2i) -> int:
	for i in list.size():
		if not list[i] is Dictionary or not is_placed(list[i]):
			continue
		var piece: Dictionary = list[i]
		if cells_of(piece, Vector2i(int(piece["x"]), int(piece["y"])), bool(piece.get("rot", false))).has(cell):
			return i
	return -1


## Gives every piece a valid place, keeping the list order: pieces that lie well stay, the others
## (no place, outside, on another one) get the first free spot or lose their place ("x" removed:
## no room). Returns the same list (changed).
static func settle(list: Array, grid: Vector2i) -> Array:
	var bad: Array[int] = []
	for i in list.size():
		var piece: Dictionary = list[i]
		var ignore: Array[int] = bad.duplicate()
		for j in range(i, list.size()):
			ignore.append(j)
		if not is_placed(piece) or not fits(list, grid, piece, Vector2i(int(piece["x"]), int(piece["y"])), bool(piece.get("rot", false)), ignore):
			bad.append(i)
	for i: int in bad:
		var piece: Dictionary = list[i]
		piece.erase("x")
		piece.erase("y")
	for i: int in bad:
		var piece: Dictionary = list[i]
		var spot: Dictionary = free_spot(list, grid, piece)
		if not spot.is_empty():
			piece["x"] = int(spot["x"])
			piece["y"] = int(spot["y"])
			piece["rot"] = bool(spot["rot"])
	return list
