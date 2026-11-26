class_name CaveWalls
extends StaticBody2D
## Rock walls of a cave, built from a mask image when the scene starts.
## `mask`: same size as the cave background, opaque = walkable passage, transparent = rock.
## The outline of the passages becomes the collision, so the player stays inside them.
## The mask and the background are made by assets/_reference/mine/bake_mine.py.

@export var mask: Texture2D
## Simplification of the collision outline in pixels (higher = fewer points, less exact).
@export var outline_precision: float = 1.5

## Group of all cave walls (the player checks a loaded position against them).
const GROUP: StringName = &"cave_walls"
## How far (in pixels) the wall may be from a spot to count as "at the wall".
const WALL_REACH: int = 14
## Free floor needed left and right of a spot (half the width of a rock).
const SPOT_HALF_WIDTH: int = 12

var _bitmap: BitMap


func _ready() -> void:
	add_to_group(GROUP)
	_bitmap = BitMap.new()
	_bitmap.create_from_image_alpha(mask.get_image())
	var full_rect := Rect2i(Vector2i.ZERO, _bitmap.get_size())
	# opaque_to_polygons only gives outer outlines, never holes: a wall standing free inside the
	# floor (not touching the edge of the map) would have no collision. So the outlines of the
	# walls (the transparent part of the mask) are added as well.
	var outlines: Array[PackedVector2Array] = _bitmap.opaque_to_polygons(full_rect, outline_precision)
	outlines.append_array(_get_wall_bitmap().opaque_to_polygons(full_rect, outline_precision))
	for outline in outlines:
		var shape := CollisionPolygon2D.new()
		# Segments instead of a filled polygon: the collision is the outline, the inside stays walkable.
		shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		shape.polygon = outline
		add_child(shape)


## Bitmap of the walls: set where the mask is transparent (copied natively, no pixel loop).
func _get_wall_bitmap() -> BitMap:
	var floor_image: Image = mask.get_image()
	if floor_image.is_compressed():
		floor_image.decompress()
	floor_image.convert(Image.FORMAT_RGBA8)
	var size: Vector2i = floor_image.get_size()
	var walls := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	walls.fill(Color.WHITE)
	var clear := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	# where the mask is floor, copy the transparent pixels: only the walls stay opaque
	walls.blit_rect_mask(clear, floor_image, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(walls)
	return bitmap


## True if `point` (relative to this node) is walkable.
func is_floor(point: Vector2) -> bool:
	var pixel := Vector2i(point)
	var size: Vector2i = _bitmap.get_size()
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= size.x or pixel.y >= size.y:
		return false
	return _bitmap.get_bitv(pixel)


## True if a rock can stand at `point`: enough free floor around it and a wall right
## behind it (above) or next to it (left/right).
func is_wall_spot(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(-SPOT_HALF_WIDTH, 0), Vector2(SPOT_HALF_WIDTH, 0), Vector2(0, 6)]:
		if not is_floor(point + offset):
			return false
	if not is_floor(point + Vector2(0, -WALL_REACH)):
		return true
	return not is_floor(point + Vector2(-SPOT_HALF_WIDTH - WALL_REACH, -4)) \
		or not is_floor(point + Vector2(SPOT_HALF_WIDTH + WALL_REACH, -4))
