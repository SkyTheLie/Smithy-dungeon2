class_name TouchWalk
extends RefCounted
## Phone, "Tippen" mode: the way from the player to a tapped point around walls, houses, water and
## everything else the player bumps into. The map has no grid of its own (floors are baked
## pictures), so for every tap a grid of CELL px is laid over the area around the player and the
## target, and each cell is tested with the player's own collision shape (same physics as walking).
## AStarGrid2D finds the way on it; the corners are then cut where the straight line is free.
## Only the screen around both points is looked at (taps are always on screen).

## Cell size of the grid in world pixels.
const CELL: float = 8.0
## Room around the player and the target that is searched (pixels).
const MARGIN: float = 96.0
## Grid never larger than this many cells per side (keeps a tap fast on huge maps).
const MAX_CELLS: int = 160
## A target inside something solid: the nearest free cell within this many cells is taken.
const FREE_SEARCH_CELLS: int = 8


## World points from `player` to `target` (without the start, ending at the target or the free
## spot nearest to it). Empty = no way.
static func find_path(player: CharacterBody2D, target: Vector2) -> PackedVector2Array:
	var start: Vector2 = player.global_position
	var area := Rect2(start, Vector2.ZERO).expand(target).grow(MARGIN)
	var max_size := Vector2.ONE * CELL * MAX_CELLS
	if area.size.x > max_size.x or area.size.y > max_size.y:
		var center: Vector2 = (start + target) / 2.0
		area = Rect2(center - max_size / 2.0, max_size).intersection(area)
	var cells := Vector2i(ceili(area.size.x / CELL), ceili(area.size.y / CELL))
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, cells)
	grid.cell_size = Vector2.ONE * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	_mark_solid(grid, player, area.position, cells)
	var from_cell: Vector2i = _cell_of(start, area.position, cells)
	grid.set_point_solid(from_cell, false)
	var to_cell: Vector2i = _nearest_free(grid, _cell_of(target, area.position, cells), cells)
	if to_cell.x < 0:
		return PackedVector2Array()
	var ids: Array[Vector2i] = grid.get_id_path(from_cell, to_cell)
	if ids.is_empty():
		return PackedVector2Array()
	var points := PackedVector2Array()
	for id: Vector2i in ids:
		points.append(_center(id, area.position))
	points.remove_at(0)
	# The exact tapped point if it is free, else the middle of the free cell next to it.
	if to_cell == _cell_of(target, area.position, cells):
		if points.is_empty():
			points.append(target)
		else:
			points[points.size() - 1] = target
	return _smooth(grid, start, points, area.position, cells)


## Every cell where the player's collision shape would touch something solid.
static func _mark_solid(grid: AStarGrid2D, player: CharacterBody2D, origin: Vector2, cells: Vector2i) -> void:
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _player_shape(player)
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for y in cells.y:
		for x in cells.x:
			query.transform = Transform2D(0.0, _center(Vector2i(x, y), origin))
			if not space.intersect_shape(query, 1).is_empty():
				grid.set_point_solid(Vector2i(x, y), true)


static func _player_shape(player: CharacterBody2D) -> Shape2D:
	for child: Node in player.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape != null:
			return (child as CollisionShape2D).shape
	var fallback := RectangleShape2D.new()
	fallback.size = Vector2(12, 6)
	return fallback


static func _center(cell: Vector2i, origin: Vector2) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL


static func _cell_of(point: Vector2, origin: Vector2, cells: Vector2i) -> Vector2i:
	var cell := Vector2i(((point - origin) / CELL).floor())
	return cell.clamp(Vector2i.ZERO, cells - Vector2i.ONE)


## `cell` if it is free, else the nearest free cell around it; (-1, -1) = none near.
static func _nearest_free(grid: AStarGrid2D, cell: Vector2i, cells: Vector2i) -> Vector2i:
	if not grid.is_point_solid(cell):
		return cell
	var best := Vector2i(-1, -1)
	var best_distance: float = INF
	for ring in range(1, FREE_SEARCH_CELLS + 1):
		for y in range(cell.y - ring, cell.y + ring + 1):
			for x in range(cell.x - ring, cell.x + ring + 1):
				if maxi(absi(x - cell.x), absi(y - cell.y)) != ring:
					continue
				var other := Vector2i(x, y)
				if not grid.is_in_boundsv(other) or grid.is_point_solid(other):
					continue
				var distance: float = Vector2(other - cell).length()
				if distance < best_distance:
					best = other
					best_distance = distance
		if best.x >= 0:
			return best
	return best


## Leaves out every point that can be skipped on a straight, free line (no zigzag over the grid).
static func _smooth(grid: AStarGrid2D, start: Vector2, points: PackedVector2Array, origin: Vector2, cells: Vector2i) -> PackedVector2Array:
	var result := PackedVector2Array()
	var from: Vector2 = start
	var index: int = 0
	while index < points.size():
		var farthest: int = index
		for ahead in range(points.size() - 1, index, -1):
			if _line_free(grid, from, points[ahead], origin, cells):
				farthest = ahead
				break
		result.append(points[farthest])
		from = points[farthest]
		index = farthest + 1
	return result


static func _line_free(grid: AStarGrid2D, from: Vector2, to: Vector2, origin: Vector2, cells: Vector2i) -> bool:
	var steps: int = maxi(1, ceili(from.distance_to(to) / (CELL / 2.0)))
	for i in range(steps + 1):
		var point: Vector2 = from.lerp(to, float(i) / steps)
		if grid.is_point_solid(_cell_of(point, origin, cells)):
			return false
	return true
