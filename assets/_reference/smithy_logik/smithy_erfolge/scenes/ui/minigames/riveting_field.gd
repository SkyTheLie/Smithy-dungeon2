class_name RivetingField
extends Control
## Drawing of the riveting minigame (RivetingMinigame): the plate (chest plate, helmet shell ...)
## lies big on its leather, with rivet holes along its edge. Above the hole to rivet next a hammer
## swings from side to side over a strip (green in the middle, yellow, pale yellow at the ends;
## the same widths as at the workbench, see Joining.grade). On a strike the hammer comes down and
## the rivet sits where it hit: shining in the hole, off to the side, or bent next to it.
## The holes lie a little inside the edge of the plate picture, spread all around it.
## The minigame sets the hammer and adds the rivets; this script only draws. Coordinates are for a
## 200 × 155 field.

const COLOR_METAL: Color = JoiningField.COLOR_METAL
const COLOR_METAL_DARK: Color = JoiningField.COLOR_METAL_DARK
const COLOR_GREEN: Color = JoiningField.COLOR_GREEN
const COLOR_YELLOW: Color = JoiningField.COLOR_YELLOW
const COLOR_OKAY: Color = Color(JoiningField.COLOR_YELLOW, 0.45)
const COLOR_TRACK: Color = Color(0.1, 0.07, 0.06, 0.6)
const COLOR_FAIL: Color = JoiningField.COLOR_FAIL
const COLOR_HOLE: Color = Color(0.08, 0.06, 0.05)
const COLOR_LEATHER: Color = Color(0.45, 0.28, 0.16)
const COLOR_HANDLE: Color = Color(0.5, 0.33, 0.18)
const COLOR_SHADOW: Color = Color(0, 0, 0, 0.55)
const PLATE_SHADOW: Vector2 = Vector2(3, 3)

const FIELD_SIZE: Vector2 = Vector2(200, 155)
## Middle of the plate; the plate fits into PLATE_BOX, the leather behind it into LEATHER_BOX.
const PIECE_CENTER: Vector2 = Vector2(100, 84)
const PLATE_BOX: Vector2 = Vector2(118, 112)
const LEATHER_BOX: Vector2 = Vector2(150, 136)
## How far the hammer swings to each side of the hole.
const SWING_HALF: float = 40.0
## Hole and rivet head radius, hammer head size, handle length, how high the hammer waits.
const HOLE_RADIUS: float = 2.0
const RIVET_RADIUS: float = 3.0
const HAMMER_HEAD: Vector2 = Vector2(12, 7)
const HANDLE_SIZE: Vector2 = Vector2(3, 22)
const HAMMER_LIFT: float = 12.0
## Holes: picture pixels a hole lies inside the edge of the plate (fewer for thin pictures).
const HOLE_INSET: int = 2

## Strip widths (set by the minigame from PlayerStats, like JoiningField).
var green_width: float = 6.0
var yellow_width: float = 5.0
## Hole the hammer is over (-1 = none) and its sideways offset from that hole.
var current: int = -1:
	set(value):
		current = value
		queue_redraw()
var hammer_offset: float = 0.0:
	set(value):
		hammer_offset = value
		queue_redraw()
## 0 = hammer up, 1 = on the rivet.
var strike: float = 0.0:
	set(value):
		strike = value
		queue_redraw()

## Hole positions in field coordinates, in riveting order (around the plate).
var holes: Array[Vector2] = []
## Set rivets: {"hole": int, "offset": float, "grade": Joining.Grade}.
var _rivets: Array[Dictionary] = []
var _plate: Texture2D
var _leather: Texture2D
var _plate_rect: Rect2 = Rect2()
var _leather_rect: Rect2 = Rect2()


## Shows `plate` on `leather` (null = drawn placeholder shapes) with `count` holes along the edge.
func set_parts(plate: Texture2D, leather: Texture2D, count: int) -> void:
	_plate = plate
	_leather = leather
	_rivets.clear()
	current = -1
	strike = 0.0
	_plate_rect = _fit(plate, PLATE_BOX)
	_leather_rect = _fit(leather, LEATHER_BOX)
	holes = _find_holes(plate, _plate_rect, count)
	queue_redraw()


## Puts a rivet into `hole`, `offset` away to the side, looking like `grade`.
func add_rivet(hole: int, offset: float, grade: Joining.Grade) -> void:
	_rivets.append({"hole": hole, "offset": offset, "grade": grade})
	queue_redraw()


## Where on screen (field coordinates) the hammer strikes now.
func get_strike_point() -> Vector2:
	if current < 0 or current >= holes.size():
		return Vector2.ZERO
	return holes[current] + Vector2(hammer_offset, 0)


## Rect of a picture scaled by a whole number (pixels stay square) to fit into `box`, centred.
static func _fit(texture: Texture2D, box: Vector2) -> Rect2:
	var picture: Vector2 = texture.get_size() if texture else box
	var factor: float = maxf(1.0, floorf(minf(box.x / picture.x, box.y / picture.y)))
	if texture == null:
		factor = 1.0
	var scaled: Vector2 = picture * factor
	return Rect2(PIECE_CENTER - scaled / 2.0, scaled)


## `count` holes HOLE_INSET picture pixels inside the edge of the plate, one per slice of a circle
## around its middle (starting top right, clockwise). Without a picture: around an oval.
static func _find_holes(texture: Texture2D, rect: Rect2, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var image: Image = HiResTexture.full_image(texture) if texture else null
	if image:
		image = image.duplicate()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
	var ring: Array[Vector2] = _edge_ring(image) if image else []
	if ring.is_empty():
		for i in count:
			var angle: float = -PI / 2.0 + TAU * (i + 0.5) / count
			result.append(PIECE_CENTER + Vector2(cos(angle) * PLATE_BOX.x * 0.38, sin(angle) * PLATE_BOX.y * 0.38))
		return result
	var pixel: Vector2 = rect.size / Vector2(image.get_size())
	var middle := Vector2.ZERO
	for point in ring:
		middle += point
	middle /= ring.size()
	var used: Array[Vector2] = []
	for i in count:
		var angle: float = -PI / 2.0 + TAU * (i + 0.5) / count
		var best: Vector2 = ring[0]
		var best_score: float = INF
		for point in ring:
			if used.has(point):
				continue
			var away: Vector2 = point - middle
			# closest to the slice's direction; among equal ones the farthest out
			var score: float = absf(angle_difference(away.angle(), angle)) - away.length() * 0.001
			if score < best_score:
				best_score = score
				best = point
		used.append(best)
		result.append(rect.position + best * pixel)
	return result


## Centres of the opaque picture pixels exactly HOLE_INSET pixels (Chebyshev) inside the edge; if
## the picture is too thin for that, the deepest ones there are.
static func _edge_ring(image: Image) -> Array[Vector2]:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var depth: Dictionary = {}
	var deepest: int = 0
	for y in height:
		for x in width:
			if image.get_pixel(x, y).a < 0.5:
				continue
			# d = 1 on the edge, HOLE_INSET + 1 exactly HOLE_INSET inside, HOLE_INSET + 2 deeper
			var d: int = 1
			while d <= HOLE_INSET + 1 and _square_is_opaque(image, x, y, d):
				d += 1
			depth[Vector2i(x, y)] = d
			deepest = maxi(deepest, d)
	var ring: Array[Vector2] = []
	var wanted: int = mini(HOLE_INSET + 1, deepest)
	for cell: Vector2i in depth:
		if depth[cell] == wanted:
			ring.append(Vector2(cell) + Vector2(0.5, 0.5))
	return ring


## True if every pixel up to `radius` around (x, y) is opaque (outside the picture counts as clear).
static func _square_is_opaque(image: Image, x: int, y: int, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px: int = x + dx
			var py: int = y + dy
			if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
				return false
			if image.get_pixel(px, py).a < 0.5:
				return false
	return true


func _draw() -> void:
	_draw_piece(_leather, _leather_rect, COLOR_LEATHER)
	# shadow, so a copper plate stands out from the brown leather
	if _plate:
		draw_texture_rect(_plate, Rect2(_plate_rect.position + PLATE_SHADOW, _plate_rect.size), false, COLOR_SHADOW)
	_draw_piece(_plate, _plate_rect, COLOR_METAL)
	for hole in holes:
		draw_circle(hole, HOLE_RADIUS, COLOR_HOLE)
	if current >= 0 and current < holes.size():
		_draw_strip(holes[current])
	for rivet in _rivets:
		_draw_rivet(rivet)
	if current >= 0 and current < holes.size():
		_draw_hammer(get_strike_point())


func _draw_piece(texture: Texture2D, rect: Rect2, color: Color) -> void:
	if texture:
		draw_texture_rect(texture, rect, false)
		return
	draw_rect(rect, color)
	draw_rect(rect, COLOR_METAL_DARK, false, 1.0)


## Strip under the hammer's path: pale yellow (okay), yellow (good), green (perfect) around the hole.
func _draw_strip(hole: Vector2) -> void:
	var y: float = hole.y + RIVET_RADIUS + 3.0
	draw_rect(Rect2(hole.x - SWING_HALF - 1.0, y - 1.0, SWING_HALF * 2.0 + 2.0, 5.0), COLOR_HOLE)
	draw_rect(Rect2(hole.x - SWING_HALF, y, SWING_HALF * 2.0, 3.0), COLOR_TRACK)
	var okay: float = green_width + yellow_width * 2.0
	var good: float = green_width + yellow_width
	draw_rect(Rect2(hole.x - okay, y, okay * 2.0, 3.0), COLOR_OKAY)
	draw_rect(Rect2(hole.x - good, y, good * 2.0, 3.0), COLOR_YELLOW)
	draw_rect(Rect2(hole.x - green_width, y, green_width * 2.0, 3.0), COLOR_GREEN)
	# the marker: where the hammer comes down
	draw_rect(Rect2(hole.x + hammer_offset - 0.5, y - 1.0, 1.0, 5.0), Color.WHITE)


func _draw_rivet(rivet: Dictionary) -> void:
	var at: Vector2 = holes[int(rivet["hole"])] + Vector2(float(rivet["offset"]), 0)
	var grade: Joining.Grade = rivet["grade"]
	if grade == Joining.Grade.FAIL:
		# bent rivet next to the hole
		draw_line(at + Vector2(-3, 2), at + Vector2(2, -1), COLOR_METAL_DARK, 2.0)
		draw_line(at + Vector2(-3, -2), at + Vector2(3, 2), COLOR_FAIL, 1.0)
		return
	draw_circle(at, RIVET_RADIUS, COLOR_METAL_DARK)
	draw_circle(at, RIVET_RADIUS - 1.0, COLOR_METAL)
	if grade == Joining.Grade.PERFECT:
		draw_rect(Rect2(at + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)


## Hammer straight above the strike point: head at the bottom, handle up; lifted until it strikes.
func _draw_hammer(at: Vector2) -> void:
	var lift: float = HAMMER_LIFT * (1.0 - strike)
	var head := Rect2(at.x - HAMMER_HEAD.x / 2.0, at.y - HAMMER_HEAD.y - lift, HAMMER_HEAD.x, HAMMER_HEAD.y)
	var handle := Rect2(at.x - HANDLE_SIZE.x / 2.0, head.position.y - HANDLE_SIZE.y, HANDLE_SIZE.x, HANDLE_SIZE.y)
	draw_rect(handle, COLOR_HANDLE)
	draw_rect(handle, COLOR_HANDLE.darkened(0.5), false, 1.0)
	draw_rect(head, COLOR_METAL)
	draw_rect(head, COLOR_METAL_DARK, false, 1.0)
