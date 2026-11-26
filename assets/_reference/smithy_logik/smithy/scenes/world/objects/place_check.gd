class_name PlaceCheck
extends Node2D
## Phone only: the small round check mark over a thing that is being moved in the house
## (HouseEditor: stations and decoration, FurnitureLayer: furniture). The player pushes the thing
## around with the finger and taps the check mark to put it down. Green = it fits there, grey =
## no room (a tap then only says so). Drawn in code - placeholder, see docs/PIXELLAB_TODO.md.

const RADIUS: float = 8.0
## A tap counts this far around the centre (world px; fingers are not exact).
const HIT_RADIUS: float = 14.0
## The check mark floats this far above the picture of the thing.
const GAP: float = 12.0
const COLOR_FREE := Color(0.2, 0.62, 0.25, 0.95)
const COLOR_BLOCKED := Color(0.4, 0.4, 0.4, 0.9)
const COLOR_MARK := Color(1.0, 1.0, 1.0)
const COLOR_RIM := Color(0.08, 0.2, 0.1)

var _free: bool = true


func _ready() -> void:
	z_index = 50
	hide()


## Shows the check mark above `top_centre` (global: the middle of the picture's top edge).
func show_over(top_centre: Vector2, free: bool) -> void:
	global_position = top_centre - Vector2(0.0, GAP)
	if free != _free or not visible:
		_free = free
		queue_redraw()
	show()


## true if a tap at `world_pos` (global) is on the visible check mark.
func is_hit(world_pos: Vector2) -> bool:
	return visible and global_position.distance_to(world_pos) <= HIT_RADIUS


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR_FREE if _free else COLOR_BLOCKED)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR_RIM, 1.0)
	draw_polyline(PackedVector2Array([Vector2(-4, 0), Vector2(-1, 3), Vector2(4, -3)]), COLOR_MARK, 2.0)
