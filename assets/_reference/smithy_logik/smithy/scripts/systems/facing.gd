class_name Facing
extends RefCounted
## The four straight directions a station or table in the player's house can face (HouseEditor: R
## turns it; never diagonal). SOUTH is the picture the thing was drawn with. The other views lie
## next to it as "<name>_east.png", "<name>_north.png" and optionally "<name>_west.png" (without
## one the east view is mirrored). Only directions with a view can be chosen.
## apply() swaps the picture of the node's Sprite2D so the new view stands on the same spot
## (bottom middle of the drawn pixels) and turns its collision: sideways the footprint gets as
## narrow as the picture and as deep as the picture grew. The facing is kept in the node's meta
## "facing"; a node with get_facing_base() names its south picture itself (the smelter shows
## other pictures while it works). Furniture of the FurnitureLayer turns with get_view and
## turn_footprint (its pictures are drawn by the layer, not by apply).

enum {SOUTH, EAST, NORTH, WEST}
const SUFFIXES: Array[String] = ["", "_east", "_north", "_west"]

## Drawn pixels of a picture by path (get_used_rect is slow enough to keep).
static var _used_rects: Dictionary = {}


## [texture, mirrored] for `facing`, [null, false] = no view in that direction.
static func get_view(base: Texture2D, facing: int) -> Array:
	if base == null or facing == SOUTH:
		return [base, false]
	var path: String = base.resource_path.get_basename() + SUFFIXES[facing] + ".png"
	if ResourceLoader.exists(path):
		return [load(path), false]
	if facing == WEST:
		var east: Array = get_view(base, EAST)
		if east[0] != null:
			return [east[0], true]
	return [null, false]


## Current facing of a node (SOUTH = never turned).
static func get_facing(node: Node) -> int:
	return int(node.get_meta("facing", SOUTH))


## The direction after the current one (clockwise, skipping directions without a view). The
## current one again = the node can't be turned.
static func get_next(node: Node2D) -> int:
	var base: Texture2D = _base_texture(node)
	var facing: int = get_facing(node)
	for step in range(1, 4):
		var next: int = (facing + step) % 4
		if get_view(base, next)[0] != null:
			return next
	return facing


## Shows the node facing `facing` (its picture and collision). false = no view that way.
static func apply(node: Node2D, facing: int) -> bool:
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	var base: Texture2D = _base_texture(node)
	var view: Array = get_view(base, facing)
	if sprite == null or view[0] == null:
		return false
	if not node.has_meta("facing_anchor"):
		_remember_base(node, sprite, base)
	var texture: Texture2D = view[0]
	var mirrored: bool = view[1]
	var used: Rect2 = _used_rect(texture, mirrored)
	var anchor: Vector2 = node.get_meta("facing_anchor")
	var top_left: Vector2 = anchor - Vector2(used.get_center().x, used.end.y)
	sprite.texture = texture
	sprite.flip_h = mirrored
	sprite.offset = top_left + (texture.get_size() / 2.0 if sprite.centered else Vector2.ZERO)
	_turn_shapes(node, used, facing)
	node.set_meta("facing", facing)
	return true


static func _base_texture(node: Node2D) -> Texture2D:
	if node.has_method("get_facing_base"):
		return node.get_facing_base()
	if node.has_meta("facing_base"):
		return node.get_meta("facing_base")
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	return sprite.texture if sprite else null


## Before the first turn: the south picture, the spot it stands on and the collision sizes.
static func _remember_base(node: Node2D, sprite: Sprite2D, base: Texture2D) -> void:
	sprite.texture = base
	sprite.flip_h = false
	var used: Rect2 = _used_rect(base, false)
	var rect: Rect2 = sprite.get_rect()
	node.set_meta("facing_base", base)
	node.set_meta("facing_base_used", used)
	node.set_meta("facing_anchor", rect.position + Vector2(used.get_center().x, used.end.y))
	for child in node.get_children():
		var shape := child as CollisionShape2D
		if shape and shape.shape is RectangleShape2D:
			# The shape resource is shared by all copies of the scene: each node turns its own.
			shape.shape = shape.shape.duplicate()
			shape.set_meta("facing_size", (shape.shape as RectangleShape2D).size)
			shape.set_meta("facing_position", shape.position)


static func _turn_shapes(node: Node2D, used: Rect2, facing: int) -> void:
	var base_used: Rect2 = node.get_meta("facing_base_used")
	for child in node.get_children():
		var shape := child as CollisionShape2D
		if shape == null or not shape.has_meta("facing_size"):
			continue
		var size: Vector2 = shape.get_meta("facing_size")
		var at: Vector2 = shape.get_meta("facing_position")
		if facing == EAST or facing == WEST:
			var turned: Vector2 = turn_footprint(size, base_used, used)
			at = Vector2(roundf(at.x * turned.x / size.x), at.y - (turned.y - size.y) / 2.0)
			size = turned
		(shape.shape as RectangleShape2D).size = size
		shape.position = at


## Footprint of a thing turned sideways: as much narrower as its picture (`used` against the south
## picture's `base_used`), and deeper by as much as the picture grew.
static func turn_footprint(size: Vector2, base_used: Rect2, used: Rect2) -> Vector2:
	var ratio: float = used.size.x / maxf(base_used.size.x, 1.0)
	return Vector2(maxf(6.0, roundf(size.x * ratio)), size.y + maxf(0.0, used.size.y - base_used.size.y))


## Drawn pixels of a picture (mirrored: as shown with flip_h).
static func get_used_rect(texture: Texture2D, mirrored: bool = false) -> Rect2:
	return _used_rect(texture, mirrored)


static func _used_rect(texture: Texture2D, mirrored: bool) -> Rect2:
	var key: String = texture.resource_path
	if not _used_rects.has(key):
		var image: Image = texture.get_image()
		_used_rects[key] = Rect2(image.get_used_rect()) if image else Rect2(Vector2.ZERO, texture.get_size())
	var used: Rect2 = _used_rects[key]
	if mirrored:
		used.position.x = texture.get_width() - used.end.x
	return used
