class_name GoblinCrowd
extends Node2D
## The crowd of goblins standing in a half ring before the goblin king's throne: two rows on the
## half ellipse below `center` (the throne), all looking at the king. The ring blocks the way
## (StaticBody2D along the band); once `part_flag` is set the goblins at the bottom of the ring step
## aside and leave a lane open to the throne (also when the scene is loaded with the flag set).
## The figures are made in _ready as GoblinFigure children of this node (plus any GoblinFigure
## placed by hand below it, e.g. the hungry goblin; the ring leaves its place free), so
## GoblinThroneCutscene can use all children as the crowd.

## Middle of the ring (the king) and the half axes of the inner and outer row.
@export var center: Vector2 = Vector2(640, 92)
@export var inner_radii: Vector2 = Vector2(155, 76)
@export var outer_radii: Vector2 = Vector2(185, 100)
## Figures in the inner and outer row.
@export var inner_count: int = 14
@export var outer_count: int = 17
## Angles (degrees, 0 = east, 90 = straight down) the rows run between; the blocking band runs a bit
## further (`band_extra`) so it reaches into the wall behind the throne.
@export var from_angle: float = 4.0
@export var to_angle: float = 176.0
@export var band_extra: float = 14.0
## Half the angle of the lane at the bottom of the ring (degrees) once it is open.
@export var lane_angle: float = 9.0
@export var part_flag: String = "goblin_crowd_parted"
## Sheets the figures are drawn with (assets/sprites/residents/<id>.png), picked in turn.
@export var residents: PackedStringArray = []
## Seed for the order of looks, the tints and the little offsets (the crowd looks the same each time).
@export var look_seed: int = 7

## How far apart a figure may stand from its exact place on the ring (pixels).
const JITTER: float = 3.0
## Colour variations of the few sheets (multiplied).
const TINTS: Array[Color] = [
	Color(1, 1, 1), Color(0.92, 1.0, 0.88), Color(1.0, 0.94, 0.86), Color(0.88, 0.94, 1.0),
	Color(0.95, 0.9, 0.95), Color(1.0, 1.0, 0.9),
]
## A hand-placed figure this close to a ring place takes it (no ring figure there).
const TAKEN_DISTANCE: float = 14.0
## Thickness the band reaches past the rows (pixels, at the feet).
const BAND_MARGIN: float = 6.0
const BAND_STEPS: int = 24

var _lane_body: StaticBody2D
## true while the lane is shut again for the day (the king sleeps, close_lane).
var _closed: bool = false


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var placed: Array[Vector2] = []
	for child in get_children():
		if child is Node2D:
			placed.append((child as Node2D).position)
	var look: int = 0
	for row in 2:
		var radii: Vector2 = inner_radii if row == 0 else outer_radii
		var count: int = inner_count if row == 0 else outer_count
		for i in count:
			# the rows are shifted half a place against each other (no goblin right behind another)
			var t: float = (i + (0.5 if row == 0 else 0.0)) / float(count - (0 if row == 0 else 1))
			var angle: float = lerpf(from_angle, to_angle, clampf(t, 0.0, 1.0))
			var spot: Vector2 = _on_ring(radii, angle) + Vector2(rng.randf_range(-JITTER, JITTER), rng.randf_range(-JITTER, JITTER))
			if placed.any(func(p: Vector2) -> bool: return p.distance_to(spot) < TAKEN_DISTANCE):
				continue
			var figure := GoblinFigure.new()
			figure.name = "Ring%d_%d" % [row, i]
			figure.position = spot
			if not residents.is_empty():
				figure.resident = residents[look % residents.size()]
			look += 1
			figure.tint = TINTS[rng.randi() % TINTS.size()]
			figure.facing = _facing_to_center(spot)
			if absf(angle - 90.0) < lane_angle + 6.0:
				figure.set_meta("ring_spot", spot)
				figure.aside_position = _aside_spot(radii, angle, rng)
				figure.aside_flag = part_flag
				figure.aside_facing = _facing_to_center(figure.aside_position)
			add_child(figure)
	_make_band(from_angle - band_extra, 90.0 - lane_angle)
	_make_band(90.0 + lane_angle, to_angle + band_extra)
	_lane_body = _make_band(90.0 - lane_angle, 90.0 + lane_angle)
	GameState.story.changed.connect(_update_lane)
	_update_lane()


## Point on the half ellipse with `radii` at `angle` degrees (coordinates of this node).
func _on_ring(radii: Vector2, angle: float) -> Vector2:
	var a: float = deg_to_rad(angle)
	return center + Vector2(cos(a) * radii.x, sin(a) * radii.y)


## Where a goblin from the lane squeezes in: past the edge of the lane on its side, a little
## further out (into the crowd).
func _aside_spot(radii: Vector2, angle: float, rng: RandomNumberGenerator) -> Vector2:
	var side: float = -1.0 if angle < 90.0 else 1.0
	var pushed: float = 90.0 + side * (lane_angle + 5.0 + absf(angle - 90.0) * 0.7 + rng.randf_range(0.0, 3.0))
	return _on_ring(radii + Vector2(8, 8), pushed)


func _facing_to_center(spot: Vector2) -> String:
	var to_king: Vector2 = center - spot
	if absf(to_king.x) > absf(to_king.y) * 1.6:
		return "right" if to_king.x > 0.0 else "left"
	return "up"


## A StaticBody2D along the band between the two rows from `from` to `to` degrees.
func _make_band(from: float, to: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionPolygon2D.new()
	var points := PackedVector2Array()
	for i in BAND_STEPS + 1:
		points.append(_on_ring(outer_radii + Vector2.ONE * BAND_MARGIN, lerpf(from, to, i / float(BAND_STEPS))))
	for i in range(BAND_STEPS, -1, -1):
		points.append(_on_ring(inner_radii - Vector2.ONE * BAND_MARGIN, lerpf(from, to, i / float(BAND_STEPS))))
	shape.polygon = points
	body.add_child(shape)
	add_child(body)
	return body


## Shuts the lane for this visit (the king sleeps): the goblins of the lane stand in it again (also when
## they had made way before) and the band there blocks again.
func close_lane() -> void:
	_closed = true
	for figure in get_children():
		if figure is GoblinFigure and figure.has_meta("ring_spot"):
			figure.hold_at(figure.get_meta("ring_spot"), _facing_to_center(figure.get_meta("ring_spot")))
	_update_lane()


func _update_lane() -> void:
	var open: bool = GameState.story.has_flag(part_flag) and not _closed
	for shape in _lane_body.get_children():
		(shape as CollisionPolygon2D).set_deferred("disabled", open)
