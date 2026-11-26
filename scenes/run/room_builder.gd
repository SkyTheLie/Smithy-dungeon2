class_name RoomBuilder
extends RefCounted
## Builds the 3D shell of a room in code: floor, four walls (open to the sky) (with a doorway where a
## neighbour room is), door frames and torches. The rooms of a floor sit side by side on a grid
## (FloorLayout cell (x, y) = world (x * ROOM_W, 0, y * ROOM_D)), so the player walks from room to
## room through the doorways. Textures are Smithy room tiles (32x32 floor, 32x48 wall), mapped by
## world position, so they line up across all pieces.

const ROOM_W: float = 15.0
const ROOM_D: float = 11.0
const WALL_H: float = 3.0
const WALL_T: float = 0.5
const DOOR_W: float = 2.0
const DOOR_H: float = 2.4

## Physics layers (bit values).
const LAYER_WORLD: int = 1
const LAYER_ROCKS: int = 2
const LAYER_PLAYER: int = 4
const LAYER_ENEMIES: int = 8

const TORCH_SHEET: String = "res://assets/sprites/props/torch_sheet.png"
const TORCH_FRAMES: int = 7

## Colours of the door frame by the kind of room behind it.
const FRAME_COLORS: Dictionary[String, Color] = {
	"boss": Color(0.75, 0.12, 0.1),
	"item": Color(0.95, 0.75, 0.2),
	"shop": Color(0.35, 0.7, 0.3),
}

## Texture path + scale -> material (read-only cache).
static var _materials: Dictionary[String, StandardMaterial3D] = {}


static func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * ROOM_W, 0.0, cell.y * ROOM_D)


static func cell_at(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / ROOM_W), roundi(pos.z / ROOM_D))


## Walkable area of a room (x/z), `margin` metres away from the walls.
static func inner_rect(cell: Vector2i, margin: float = 0.0) -> Rect2:
	var center := cell_center(cell)
	var half := Vector2(ROOM_W / 2.0 - WALL_T - margin, ROOM_D / 2.0 - WALL_T - margin)
	return Rect2(Vector2(center.x, center.z) - half, half * 2.0)


## Material with a texture repeated by world position (`tile` = metres per picture).
static func tiled_material(texture_path: String, tile: Vector3, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key: String = "%s|%s|%s" % [texture_path, tile, tint]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture_path) as Texture2D
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(1.0 / tile.x, 1.0 / tile.y, 1.0 / tile.z)
	material.roughness = 1.0
	_materials[key] = material
	return material


static func color_material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key: String = "color|%s|%s" % [color, glow]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	_materials[key] = material
	return material


## A box (mesh) at `pos` (world, relative to `parent`); with a StaticBody3D on `layer` if > 0.
static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, layer: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	if layer > 0:
		var body := StaticBody3D.new()
		body.collision_layer = layer
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		mesh_instance.add_child(body)
	return mesh_instance


## Floor, walls and torches of one room (no ceiling). `doors`: direction -> type of the room behind it.
static func build_shell(room: Node3D, floor_texture: String, wall_texture: String, doors: Dictionary[Vector2i, String], light_color: Color) -> void:
	var floor_material := tiled_material(floor_texture, Vector3(1.5, 1.5, 1.5))
	var wall_material := tiled_material(wall_texture, Vector3(2.0, 3.0, 2.0))
	box(room, Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), floor_material, LAYER_WORLD)
	for dir: Vector2i in FloorLayout.DIRECTIONS:
		_wall(room, dir, doors.has(dir), wall_material)
		if doors.has(dir):
			_door_frame(room, dir, String(doors[dir]))
	# Light: one warm light in the middle, two torches on the long walls.
	var light := OmniLight3D.new()
	light.light_color = light_color
	light.light_energy = 1.1
	light.omni_range = 11.0
	light.omni_attenuation = 1.2
	light.position = Vector3(0, WALL_H - 0.4, 0)
	room.add_child(light)
	_torch(room, Vector3(-3.5, 1.9, -ROOM_D / 2.0 + WALL_T + 0.12), light_color)
	_torch(room, Vector3(3.5, 1.9, ROOM_D / 2.0 - WALL_T - 0.12), light_color)


## One wall; with a doorway in the middle if `has_door`.
static func _wall(room: Node3D, dir: Vector2i, has_door: bool, material: Material) -> void:
	var along_x: bool = dir.y != 0
	var length: float = ROOM_W if along_x else ROOM_D
	var center := Vector3(dir.x * (ROOM_W / 2.0 - WALL_T / 2.0), 0.0, dir.y * (ROOM_D / 2.0 - WALL_T / 2.0))
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	if not has_door:
		box(room, _piece(along_x, length, WALL_H), center + Vector3(0, WALL_H / 2.0, 0), material, LAYER_WORLD)
		return
	var side: float = (length - DOOR_W) / 2.0
	for sign_value: float in [-1.0, 1.0]:
		var offset: Vector3 = axis * sign_value * (DOOR_W / 2.0 + side / 2.0)
		box(room, _piece(along_x, side, WALL_H), center + offset + Vector3(0, WALL_H / 2.0, 0), material, LAYER_WORLD)
	var lintel: float = WALL_H - DOOR_H
	box(room, _piece(along_x, DOOR_W, lintel), center + Vector3(0, DOOR_H + lintel / 2.0, 0), material, LAYER_WORLD)


static func _piece(along_x: bool, length: float, height: float) -> Vector3:
	return Vector3(length, height, WALL_T) if along_x else Vector3(WALL_T, height, length)


## Coloured frame around a doorway that leads to a special room (boss red, item gold, shop green).
static func _door_frame(room: Node3D, dir: Vector2i, type: String) -> void:
	if not FRAME_COLORS.has(type):
		return
	var material := color_material(FRAME_COLORS[type], 0.6)
	var along_x: bool = dir.y != 0
	var face := Vector3(dir.x * (ROOM_W / 2.0 - WALL_T - 0.05), 0.0, dir.y * (ROOM_D / 2.0 - WALL_T - 0.05))
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	for sign_value: float in [-1.0, 1.0]:
		var post: Vector3 = Vector3(0.2, DOOR_H + 0.2, 0.12) if along_x else Vector3(0.12, DOOR_H + 0.2, 0.2)
		box(room, post, face + axis * sign_value * (DOOR_W / 2.0 + 0.1) + Vector3(0, (DOOR_H + 0.2) / 2.0, 0), material, 0)
	var top: Vector3 = Vector3(DOOR_W + 0.4, 0.2, 0.12) if along_x else Vector3(0.12, 0.2, DOOR_W + 0.4)
	box(room, top, face + Vector3(0, DOOR_H + 0.1, 0), material, 0)


static func _torch(room: Node3D, pos: Vector3, color: Color) -> void:
	var sheet := load(TORCH_SHEET) as Texture2D
	var sprite := Fx.billboard(sheet, 1.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.hframes = TORCH_FRAMES
	sprite.pixel_size = 1.0 / 48.0
	sprite.position = pos
	sprite.set_script(preload("res://scenes/objects/torch.gd"))
	room.add_child(sprite)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.8
	light.omni_range = 5.0
	light.position = pos + Vector3(0, 0.4, 0) - Vector3(signf(pos.x) * 0.0, 0, signf(pos.z) * 0.4)
	room.add_child(light)
