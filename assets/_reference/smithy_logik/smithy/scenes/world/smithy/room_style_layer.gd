class_name RoomStyleLayer
extends Node2D
## Room designer: draws the floor, wall and door styles the player chose for this `room`
## (GameState.house.room_design, house.json "room_styles") over the room's picture. Child of the
## room's Background sprite (not centered): all rects are pixels of that picture.
## The picture itself stays; a style covers its part with a tiled texture. With a new wall, the
## `keep_rects` of the picture (windows, tool racks, the door) are copied back on top, and the
## doors get the chosen door style (or keep their old look).

## Room key (as in HouseEditor.room, e.g. "smithy_small"; both shops share "shop").
@export var room: String = ""
## Floor and wall band of the picture.
@export var floor_rect: Rect2 = Rect2()
@export var wall_rect: Rect2 = Rect2()
## Doors in the wall (they get the door style).
@export var door_rects: Array[Rect2] = []
## Parts of the picture that stay visible on a new wall (windows, racks, shields).
@export var keep_rects: Array[Rect2] = []


func _ready() -> void:
	GameState.house.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var house: House = GameState.house
	var floor_id: String = house.get_room_style(room, "floor")
	var wall_id: String = house.get_room_style(room, "wall")
	var door_id: String = house.get_room_style(room, "door")
	if not floor_id.is_empty():
		_add_tiled(floor_id, floor_rect)
	if not wall_id.is_empty():
		_add_tiled(wall_id, wall_rect)
		for rect: Rect2 in keep_rects:
			_add_crop(rect)
	for rect: Rect2 in door_rects:
		if not door_id.is_empty():
			_add_door(door_id, rect)
		elif not wall_id.is_empty():
			_add_crop(rect)


func _texture(style_id: String) -> Texture2D:
	var path: String = str(House.get_style(style_id).get("texture", ""))
	return load(path) if ResourceLoader.exists(path) else null


## The style's texture repeated over `rect`.
func _add_tiled(style_id: String, rect: Rect2) -> void:
	var texture: Texture2D = _texture(style_id)
	if texture == null or rect.size == Vector2.ZERO:
		return
	var tiles := TextureRect.new()
	tiles.texture = texture
	tiles.stretch_mode = TextureRect.STRETCH_TILE
	tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tiles.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tiles.position = rect.position
	tiles.size = rect.size
	tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tiles)


## A part of the room's own picture, copied back on top of a new wall.
func _add_crop(rect: Rect2) -> void:
	var background := get_parent() as Sprite2D
	if background == null or background.texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = background.texture
	atlas.region = rect
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.position = rect.position
	add_child(sprite)


## The door style, standing on the bottom of the door rect, centered.
func _add_door(style_id: String, rect: Rect2) -> void:
	var texture: Texture2D = _texture(style_id)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(roundf(rect.get_center().x - texture.get_width() / 2.0), rect.end.y - texture.get_height())
	add_child(sprite)
