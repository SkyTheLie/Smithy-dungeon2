class_name MarketWalker
extends Node2D
## A merchant on his way between his stall and the edge of the market (Merchant: walks off when
## the market closes, comes back when it opens). Follows a fixed path (VillageRoads.plan_through,
## around the stalls) with the walk animation of a CharacterBaker-style sheet (7 frames x 4 rows
## of 48x48: frame 0 standing, 1-6 walking; rows down/up/left/right) and frees itself at the end.
## Not a physics body: nobody can block it, it walks through the player instead of getting stuck.
## Walks only straight (left / right / up / down), see straighten().

signal arrived

## Pixels per second (like the villagers).
const WALK_SPEED: float = 34.0
## Feet of a 48x48 frame, measured from its centre.
const FEET_FROM_CENTRE: float = 17.0
## straighten(): slants smaller than this (pixels) are not turned into a corner.
const STRAIGHT_TOLERANCE: float = 1.5

var _path: PackedVector2Array = PackedVector2Array()
var _sprite: AnimatedSprite2D


## Starts at `from` (global) and walks through `path` (global points). `blocked`: rects (global)
## the corners of the way should not cut through (the other stalls' counters).
func setup(sheet: Texture2D, from: Vector2, path: PackedVector2Array, blocked: Array[Rect2] = []) -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = CharacterBaker.make_frames(sheet)
	_sprite.offset = Vector2(0.0, -FEET_FROM_CENTRE)
	add_child(_sprite)
	global_position = from
	_path = straighten(from, path, blocked)
	_sprite.play("idle_down")


## Nothing walks at a slant: every slanted piece of the way becomes a corner, first sideways and
## then up / down, or the other way round if that one would cut through a rect of `blocked`.
## Tiny slants (rounding of the road points) are just walked.
static func straighten(from: Vector2, path: PackedVector2Array, blocked: Array[Rect2] = []) -> PackedVector2Array:
	var result := PackedVector2Array()
	var at: Vector2 = from
	for point in path:
		if absf(point.x - at.x) > STRAIGHT_TOLERANCE and absf(point.y - at.y) > STRAIGHT_TOLERANCE:
			var corner := Vector2(point.x, at.y)
			if _cuts(at, corner, point, blocked) and not _cuts(at, Vector2(at.x, point.y), point, blocked):
				corner = Vector2(at.x, point.y)
			result.append(corner)
		result.append(point)
		at = point
	return result


## True if the way a -> corner -> b runs through one of the rects.
static func _cuts(a: Vector2, corner: Vector2, b: Vector2, blocked: Array[Rect2]) -> bool:
	# straight pieces: each one is the thin box between its two ends
	var first := Rect2(a, Vector2.ZERO).expand(corner).grow(0.5)
	var second := Rect2(corner, Vector2.ZERO).expand(b).grow(0.5)
	for rect in blocked:
		if first.intersects(rect) or second.intersects(rect):
			return true
	return false


func _process(delta: float) -> void:
	if _path.is_empty():
		return
	var to: Vector2 = _path[0] - global_position
	var step: float = WALK_SPEED * delta
	if to.length() <= step:
		global_position = _path[0]
		_path.remove_at(0)
		if _path.is_empty():
			arrived.emit()
			queue_free()
		return
	global_position += to.normalized() * step
	_sprite.play("walk_" + _direction_name(to))


static func _direction_name(motion: Vector2) -> String:
	if absf(motion.x) > absf(motion.y):
		return "right" if motion.x > 0.0 else "left"
	return "down" if motion.y > 0.0 else "up"
