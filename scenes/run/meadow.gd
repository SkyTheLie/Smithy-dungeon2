class_name Meadow
extends RefCounted
## Tall grass on the floor of a room (floors.json theme / floor "grass"): many small 2D grass tufts
## (a pixel picture made in code), each two crossed pictures, so they look the same from every
## side. All tufts of a room are one MultiMeshInstance3D (cheap to draw). The grass is a few
## dozen centimetres high: low enemies (snakes, small beasts) and traps on the floor are hard to
## see in it. It does not block anything (no collision). Values of "grass":
##   height    metres (about 0.3-0.6)          per_m2  tufts per square metre
##   color     [r, g, b] tint of the tufts     spread  how much height and colour vary (0..1)

const TEXTURE_SIZE := Vector2i(16, 16)
const BLADES: int = 9
const SEED: int = 4242

## The tuft picture, made once (read-only cache).
static var _texture: Texture2D
static var _mesh: ArrayMesh


## Adds grass to `room` (its local floor, from wall to wall). Own random numbers from `rng_seed`,
## so the same room always looks the same.
static func add_grass(room: Node3D, settings: Dictionary, rng_seed: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var height: float = float(settings.get("height", 0.45))
	var spread: float = clampf(float(settings.get("spread", 0.35)), 0.0, 1.0)
	var color_values: Array = settings.get("color", [0.5, 0.75, 0.35])
	var tint := Color(float(color_values[0]), float(color_values[1]), float(color_values[2]))
	var half := Vector2(RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T, RoomBuilder.ROOM_D / 2.0 - RoomBuilder.WALL_T)
	var count: int = maxi(0, roundi(half.x * 2.0 * half.y * 2.0 * float(settings.get("per_m2", 3.0))))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = _tuft_mesh()
	multimesh.instance_count = count
	for i in count:
		var at := Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		var size: float = height * rng.randf_range(1.0 - spread * 0.6, 1.0 + spread * 0.4)
		var basis := Basis(Vector3.UP, rng.randf() * PI).scaled(Vector3(size, size, size))
		multimesh.set_instance_transform(i, Transform3D(basis, at))
		var shade: float = rng.randf_range(1.0 - spread * 0.5, 1.0 + spread * 0.3)
		multimesh.set_instance_color(i, Color(tint.r * shade, tint.g * shade, tint.b * shade))
	var node := MultiMeshInstance3D.new()
	node.name = "Grass"
	node.multimesh = multimesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room.add_child(node)
	return node


## Two crossed squares (1 x 1 m, standing on the floor) with the tuft picture; the colour comes
## from each tuft (vertex colour as albedo).
static func _tuft_mesh() -> ArrayMesh:
	if _mesh:
		return _mesh
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for side: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var start: int = vertices.size()
		var left: Vector3 = -side * 0.5
		var right: Vector3 = side * 0.5
		for corner: Vector3 in [left, right, right + Vector3.UP, left + Vector3.UP]:
			vertices.append(corner)
			# Lit like the floor: the normals point up.
			normals.append(Vector3.UP)
		for uv: Vector2 in [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]:
			uvs.append(uv)
		for index: int in [0, 1, 2, 0, 2, 3]:
			indices.append(start + index)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_texture = tuft_texture()
	material.vertex_color_use_as_albedo = true
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	_mesh.surface_set_material(0, material)
	return _mesh


## A 16 x 16 pixel tuft: thin blades of different heights, a little bent, dark at the bottom and
## light at the tips (white-ish, so the tuft colour tints it).
static func tuft_texture() -> Texture2D:
	if _texture:
		return _texture
	var image := Image.create(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for blade in BLADES:
		var x: float = rng.randf_range(1.0, TEXTURE_SIZE.x - 2.0)
		var tall: int = rng.randi_range(6, TEXTURE_SIZE.y - 1)
		var lean: float = rng.randf_range(-0.35, 0.35)
		for step in tall:
			var y: int = TEXTURE_SIZE.y - 1 - step
			var px: int = clampi(roundi(x + lean * step), 0, TEXTURE_SIZE.x - 1)
			var light: float = lerpf(0.45, 1.0, float(step) / tall)
			image.set_pixel(px, y, Color(light, light, light * 0.9))
	_texture = ImageTexture.create_from_image(image)
	return _texture
