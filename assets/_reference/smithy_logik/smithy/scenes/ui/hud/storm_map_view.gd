class_name StormMapView
extends Control
## The drawing on Fürst Ssarok's map of the storm paths (StormMapWindow): old papyrus, an invisible
## grid of 20×20 cells. Every step of a desert route is one cell drawn as an empty square (only
## the border, as brackets), every place an ink pictogram (16×16) that bobs while the mouse is over it; its
## route is then drawn darker and the tooltip names the way.
## Look after the developer's sketch (2026-11-06): steps and places stand in hand-drawn square
## brackets "[ ]" (open at the top and bottom), light brown wavy strokes (wind over the dunes) lie
## on the paper.
## Which routes: the ones in desert.json "storm_map" "routes" (sign » Sahrim » temple, drawn by
## Ssarok), later every other route once the player stood at its end or the chest there is open.
## The desert is no real grid (routes cross), so the layout walks each route from the place it
## starts at; a cell used by several routes gets smaller brackets inside the first. A little tube
## (two parallel strokes) joins neighbouring boxes so the path is easy to follow.

## One grid cell; the pictograms are 16×16 in its middle, a step's brackets are STEP_SIZE wide.
const CELL: int = 20
const ICON: int = 16
const STEP_SIZE: int = 12
## Distance between the two strokes of the tube that joins two boxes.
const TUBE_WIDTH: float = 4.0
const MARGIN: int = 14
## Seconds of one bob of a hovered pictogram.
const BOB_SECONDS: float = 0.6
const DIRECTIONS: Dictionary = {"N": Vector2i(0, -1), "S": Vector2i(0, 1), "O": Vector2i(1, 0), "W": Vector2i(-1, 0)}
const DIRECTION_NAMES: Dictionary = {"N": "Norden", "O": "Osten", "S": "Süden", "W": "Westen"}

const COLOR_PAPER: Color = Color(0.86, 0.75, 0.53)
const COLOR_FIBER: Color = Color(0.78, 0.66, 0.44)
const COLOR_FIBER_LIGHT: Color = Color(0.91, 0.82, 0.6)
const COLOR_EDGE: Color = Color(0.62, 0.48, 0.3)
const COLOR_INK: Color = Color(0.22, 0.13, 0.07)
const COLOR_FAINT: Color = Color(0.22, 0.13, 0.07, 0.35)
## Egyptian scribes wrote in black and red: the storm paths are red.
const COLOR_RED: Color = Color(0.62, 0.18, 0.1)
const COLOR_GOLD: Color = Color(0.6, 0.42, 0.12)
## The wavy strokes of wind and dunes.
const COLOR_DUNE: Color = Color(0.72, 0.47, 0.32, 0.8)

## Laid out routes: [{"from", "to", "moves", "cells": Array[Vector2i] (from, steps ..., to),
## "color"}], and place field -> cell.
var _routes: Array[Dictionary] = []
var _places: Dictionary = {}
var _origin: Vector2i = Vector2i.ZERO
var _hovered: String = ""
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visibility_changed.connect(refresh)
	refresh()


## Lays out the routes the player may see and sets the size.
func refresh() -> void:
	_routes = get_shown_routes()
	_places.clear()
	var low := Vector2i.ZERO
	var high := Vector2i.ZERO
	for route in _routes:
		for cell: Vector2i in route["cells"]:
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
		_places[route["from"]] = route["cells"][0]
		_places[route["to"]] = route["cells"][-1]
	_origin = low
	custom_minimum_size = Vector2((high - low + Vector2i.ONE) * CELL + Vector2i(MARGIN, MARGIN) * 2)
	queue_redraw()


## The routes on the map with their cells. A route starts where an earlier one put its first place.
static func get_shown_routes() -> Array[Dictionary]:
	var maze: DesertMaze = GameState.desert
	var main: Array = DesertMaze.data().get("storm_map", {}).get("routes", [])
	var placed: Dictionary = {DesertMaze.start_field(): Vector2i.ZERO}
	var shown: Array[Dictionary] = []
	# Walk until no more route can be placed (a route needs its start placed first).
	var left: Array[Dictionary] = DesertMaze.routes().duplicate()
	var progress: bool = true
	while progress and not left.is_empty():
		progress = false
		for route in left.duplicate():
			var from: String = route["from"]
			if not placed.has(from):
				continue
			left.erase(route)
			progress = true
			var cells: Array[Vector2i] = [placed[from]]
			for move: String in route["moves"]:
				cells.append(cells[-1] + DIRECTIONS[move])
			if not placed.has(route["to"]):
				placed[route["to"]] = cells[-1]
			var is_main: bool = main.any(func(pair: Array) -> bool: return pair[0] == from and pair[1] == route["to"])
			if not is_main and not _is_known(maze, route):
				continue
			var color: Color = COLOR_INK
			if is_main and DesertMaze.place(route["to"]).has("scene") and route["to"] != DesertMaze.data().get("town", "town"):
				color = COLOR_RED
			elif not is_main:
				color = COLOR_GOLD
			shown.append({"from": from, "to": route["to"], "moves": route["moves"], "cells": cells, "color": color})
	return shown


## A route that is not drawn by Ssarok: once the player stood at its end, or the chest there is
## open; one that needs a story flag (e.g. Zahir's dune) once that flag is set.
static func _is_known(maze: DesertMaze, route: Dictionary) -> bool:
	var to: String = route["to"]
	if maze.visited.has(to):
		return true
	var chest: String = str(DesertMaze.place(to).get("chest", ""))
	if not chest.is_empty() and maze.is_chest_open(chest):
		return true
	var flag: String = str(route.get("required_flag", ""))
	return not flag.is_empty() and int(route.get("required_compass", -1)) < 0 and GameState.story.has_flag(flag)


func _process(delta: float) -> void:
	if not _hovered.is_empty() and is_visible_in_tree():
		_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var over: String = _place_at(event.position)
		if over != _hovered:
			_hovered = over
			_time = 0.0
			tooltip_text = _tooltip_for(over)
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _hovered.is_empty():
		_hovered = ""
		tooltip_text = ""
		queue_redraw()


func _place_at(at: Vector2) -> String:
	for field: String in _places:
		if Rect2(_cell_position(_places[field]), Vector2(CELL, CELL)).has_point(at):
			return field
	return ""


func _cell_center(cell: Vector2i) -> Vector2:
	return _cell_position(cell) + Vector2(CELL, CELL) / 2.0


## Hand-drawn square brackets "[ ]" around `rect`: the sides, short ends at the corners, open in
## the middle of the top and bottom; the corners wobble a little (`wobble_seed` keeps them still).
func _draw_brackets(rect: Rect2, color: Color, width: float, wobble_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = wobble_seed
	var wob := func() -> Vector2: return Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
	var tick: float = maxf(2.0, rect.size.x * 0.28)
	var tl: Vector2 = rect.position + wob.call()
	var bl: Vector2 = rect.position + Vector2(0, rect.size.y) + wob.call()
	var tr: Vector2 = rect.position + Vector2(rect.size.x, 0) + wob.call()
	var br: Vector2 = rect.end + wob.call()
	draw_polyline(PackedVector2Array([tl + Vector2(tick, 0), tl, bl, bl + Vector2(tick, 0)]), color, width)
	draw_polyline(PackedVector2Array([tr - Vector2(tick, 0), tr, br, br - Vector2(tick, 0)]), color, width)


## Tube from the box of cell `a` to the box of its neighbour `b`: two parallel strokes in the gap
## between the brackets (a place's brackets are bigger than a step's).
func _draw_tube(a: Vector2i, b: Vector2i, color: Color, hot: bool) -> void:
	var direction := Vector2(b - a)
	if direction.length() != 1.0:
		return
	var a_place: bool = _places.values().has(a)
	var b_place: bool = _places.values().has(b)
	var start: Vector2 = _cell_center(a) + direction * ((CELL / 2.0 + 1.0) if a_place else STEP_SIZE / 2.0)
	var end: Vector2 = _cell_center(b) - direction * ((CELL / 2.0 + 1.0) if b_place else STEP_SIZE / 2.0)
	if start.distance_to(end) < 1.0:
		return
	var side: Vector2 = direction.orthogonal() * TUBE_WIDTH / 2.0
	draw_line(start + side, end + side, color, 1.0)
	draw_line(start - side, end - side, color, 1.0)
	if hot:
		draw_line(start, end, Color(color, 0.5), 1.0)


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2((cell - _origin) * CELL + Vector2i(MARGIN, MARGIN))


## "Sahrim\nVom Skelett: Süden, Osten …" (names of the ways that end there).
func _tooltip_for(field: String) -> String:
	if field.is_empty():
		return ""
	var lines: Array[String] = [Language.translate(str(DesertMaze.place(field).get("name", field)))]
	for route in _routes:
		if route["to"] != field:
			continue
		var steps: Array[String] = []
		for move: String in route["moves"]:
			steps.append(Language.translate(DIRECTION_NAMES[move]))
		var from_name: String = Language.translate(str(DesertMaze.place(route["from"]).get("name", route["from"])))
		lines.append(Language.translate("Ab „%s“: %s") % [from_name, ", ".join(steps)])
	return "\n".join(lines)


# --- Drawing --------------------------------------------------------------------------------

func _draw() -> void:
	_draw_papyrus()
	if _routes.is_empty():
		return
	var used: Dictionary = {}
	for route in _routes:
		var hot: bool = route["to"] == _hovered or route["from"] == _hovered
		var color: Color = route["color"]
		if not _hovered.is_empty() and not hot:
			color.a = 0.45
		var cells: Array = route["cells"]
		# A little tube between two neighbouring boxes shows the way from step to step.
		for i in range(cells.size() - 1):
			_draw_tube(cells[i], cells[i + 1], color, hot)
		for i in range(1, cells.size() - 1):
			var cell: Vector2i = cells[i]
			if _places.values().has(cell):
				continue
			var count: int = int(used.get(cell, 0))
			used[cell] = count + 1
			var box: float = STEP_SIZE - count * 4.0
			if box < 4.0:
				continue
			_draw_brackets(Rect2(_cell_center(cell) - Vector2(box, box) / 2.0, Vector2(box, box)), color, 2.0 if hot else 1.0,
					cell.x * 31 + cell.y * 17 + count)
	for field: String in _places:
		var cell: Vector2i = _places[field]
		var hot_place: bool = field == _hovered
		_draw_brackets(Rect2(_cell_position(cell), Vector2(CELL, CELL)).grow(1.0), COLOR_INK, 2.0 if hot_place else 1.0, cell.x * 13 + cell.y * 7)
		var at: Vector2 = _cell_center(cell) - Vector2(CELL, CELL) / 2.0
		var scale_factor: float = 1.0
		if field == _hovered:
			var wave: float = sin(_time / BOB_SECONDS * TAU)
			at.y -= 1.5 + 1.5 * wave
			scale_factor = 1.15 + 0.05 * wave
		draw_set_transform(at + Vector2(CELL, CELL) / 2.0, sin(_time * 5.0) * 0.08 if field == _hovered else 0.0, Vector2.ONE * scale_factor)
		_draw_pictogram(field, Vector2(-ICON, -ICON) / 2.0)
		draw_set_transform(Vector2.ZERO)


## Papyrus: crossed strips of reed fibres, darker towards the frayed edge.
func _draw_papyrus() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_PAPER)
	var y: float = 0.0
	while y < size.y:
		var height: float = rng.randf_range(2.0, 5.0)
		draw_rect(Rect2(0, y, size.x, 1), COLOR_FIBER if rng.randf() < 0.6 else COLOR_FIBER_LIGHT)
		y += height
	var x: float = 0.0
	while x < size.x:
		draw_rect(Rect2(x, 0, 1, size.y), Color(COLOR_FIBER, 0.35))
		x += rng.randf_range(5.0, 11.0)
	for i in 40:
		draw_rect(Rect2(rng.randf_range(0, size.x), rng.randf_range(0, size.y), rng.randf_range(2, 6), 1), Color(COLOR_EDGE, 0.25))
	# Frayed, darker rim.
	for side in 4:
		var length: float = size.x if side < 2 else size.y
		var step: float = 0.0
		while step < length:
			var depth: float = rng.randf_range(1.0, 4.0)
			var piece: float = rng.randf_range(2.0, 6.0)
			match side:
				0: draw_rect(Rect2(step, 0, piece, depth), COLOR_EDGE)
				1: draw_rect(Rect2(step, size.y - depth, piece, depth), COLOR_EDGE)
				2: draw_rect(Rect2(0, step, depth, piece), COLOR_EDGE)
				3: draw_rect(Rect2(size.x - depth, step, depth, piece), COLOR_EDGE)
			step += piece
	# Wavy strokes like wind over the dunes, under the drawing.
	var strokes: int = maxi(3, int(size.x * size.y / 3500.0))
	for i in strokes:
		var start := Vector2(rng.randf_range(4.0, size.x - 40.0), rng.randf_range(10.0, size.y - 14.0))
		var length: float = rng.randf_range(28.0, 60.0)
		var points := PackedVector2Array()
		var phase: float = rng.randf_range(0.0, TAU)
		var slope: float = rng.randf_range(0.15, 0.5)
		for step in int(length / 2.0) + 1:
			var px: float = step * 2.0
			points.append(start + Vector2(px, px * slope + sin(phase + px * 0.22) * 2.5))
		draw_polyline(points, COLOR_DUNE, 1.0)


## Ink pictogram of a place (16×16 at `at`): what it is from desert.json (town, temple, pyramids,
## sign, bones, ruins, chest).
func _draw_pictogram(field: String, at: Vector2) -> void:
	var info: Dictionary = DesertMaze.place(field)
	var kind: String = str(info.get("mark", ""))
	if field == str(DesertMaze.data().get("town", "town")):
		kind = "town"
	elif info.has("scene"):
		kind = "pyramids" if "pyramid" in str(info.get("scene", "")) else "temple"
	var ink: Color = COLOR_INK
	var p := func(x: float, y: float) -> Vector2: return at + Vector2(x, y)
	match kind:
		"town":
			# The glass dome of Sahrim: a half circle with hexagon lines.
			draw_arc(p.call(8, 12), 6.0, PI, TAU, 10, ink, 1.0)
			draw_line(p.call(1, 12), p.call(15, 12), ink, 1.0)
			draw_line(p.call(8, 6), p.call(8, 12), Color(ink, 0.6), 1.0)
			draw_line(p.call(4, 8), p.call(6, 12), Color(ink, 0.6), 1.0)
			draw_line(p.call(12, 8), p.call(10, 12), Color(ink, 0.6), 1.0)
			draw_rect(Rect2(p.call(7, 3), Vector2(2, 2)), COLOR_RED)
		"temple":
			# Pillars under a roof with a lightning bolt.
			draw_colored_polygon(PackedVector2Array([p.call(1, 6), p.call(8, 2), p.call(15, 6)]), ink)
			for column in [3, 7, 11]:
				draw_rect(Rect2(p.call(column, 7), Vector2(2, 7)), ink)
			draw_rect(Rect2(p.call(1, 14), Vector2(14, 1)), ink)
			draw_polyline(PackedVector2Array([p.call(9, 0), p.call(7, 3), p.call(9, 3), p.call(7, 6)]), COLOR_RED, 1.0)
		"pyramids":
			draw_colored_polygon(PackedVector2Array([p.call(1, 14), p.call(6, 6), p.call(11, 14)]), Color(ink, 0.7))
			draw_colored_polygon(PackedVector2Array([p.call(5, 14), p.call(11, 3), p.call(15, 14)]), ink)
			draw_line(p.call(11, 3), p.call(13, 14), COLOR_GOLD, 1.0)
		"sign":
			draw_rect(Rect2(p.call(7, 6), Vector2(2, 9)), ink)
			draw_rect(Rect2(p.call(2, 2), Vector2(12, 5)), ink)
			draw_rect(Rect2(p.call(3, 3), Vector2(10, 3)), COLOR_PAPER)
			draw_rect(Rect2(p.call(7, 3), Vector2(2, 2)), COLOR_RED)
		"bones":
			# A skull with crossed bones.
			draw_line(p.call(2, 14), p.call(14, 9), ink, 1.0)
			draw_line(p.call(2, 9), p.call(14, 14), ink, 1.0)
			draw_circle(p.call(8, 6), 4.5, ink)
			draw_rect(Rect2(p.call(5, 5), Vector2(2, 2)), COLOR_PAPER)
			draw_rect(Rect2(p.call(9, 5), Vector2(2, 2)), COLOR_PAPER)
		"ruins":
			draw_rect(Rect2(p.call(2, 4), Vector2(3, 10)), ink)
			draw_rect(Rect2(p.call(7, 8), Vector2(3, 6)), ink)
			draw_rect(Rect2(p.call(12, 6), Vector2(2, 8)), ink)
			draw_rect(Rect2(p.call(1, 14), Vector2(14, 1)), ink)
			draw_rect(Rect2(p.call(1, 3), Vector2(5, 1)), ink)
		"chest":
			var open: bool = GameState.desert.is_chest_open(str(info.get("chest", "")))
			draw_rect(Rect2(p.call(2, 7), Vector2(12, 7)), ink)
			draw_rect(Rect2(p.call(3, 8), Vector2(10, 5)), COLOR_GOLD if not open else COLOR_FIBER)
			if open:
				draw_colored_polygon(PackedVector2Array([p.call(2, 7), p.call(4, 2), p.call(14, 2), p.call(14, 7)]), Color(ink, 0.6))
			else:
				draw_rect(Rect2(p.call(2, 4), Vector2(12, 3)), ink)
				draw_rect(Rect2(p.call(7, 7), Vector2(2, 3)), COLOR_PAPER)
		_:
			draw_circle(p.call(8, 8), 2.0, ink)
