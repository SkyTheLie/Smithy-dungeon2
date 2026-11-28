class_name RoomAir
extends RefCounted
## Things floating in the air of a room: dust, embers, snow, fireflies, spores. One CPUParticles3D
## per room (works in GL Compatibility), filling the whole room up to the wall tops.
## Which kind: the theme's `air` in floors.json (an id of `air_types`); how it looks and moves:
## the entry in `air_types` (color, amount, size, glow, gravity, speed, lifetime).
## Every particle fades in and out, so nothing pops up or vanishes suddenly.

## Kind settings (data) -> material (read-only cache, one per look).
static var _materials: Dictionary[String, StandardMaterial3D] = {}


## Adds the particles of `kind` (an `air_types` entry) to `room`; returns them (null if `kind` is empty).
static func add_air(room: Node3D, kind: Dictionary, rng_seed: int) -> CPUParticles3D:
	if kind.is_empty():
		return null
	var color_values: Array = kind.get("color", [1.0, 1.0, 1.0, 0.5])
	var color := Color(float(color_values[0]), float(color_values[1]), float(color_values[2]), float(color_values[3]))
	var glow: bool = bool(kind.get("glow", false))
	var size: float = float(kind.get("size", 0.05))
	var particles := CPUParticles3D.new()
	particles.name = "Air"
	particles.seed = rng_seed
	particles.use_fixed_seed = true
	particles.amount = maxi(1, int(kind.get("amount", 20)))
	particles.lifetime = float(kind.get("lifetime", 6.0))
	# Already full when the player walks in.
	particles.preprocess = particles.lifetime
	particles.randomness = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	particles.mesh = quad
	particles.material_override = _material(glow)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var half := Vector3(RoomBuilder.ROOM_W / 2.0 - RoomBuilder.WALL_T, RoomBuilder.WALL_H / 2.0, RoomBuilder.ROOM_D / 2.0 - RoomBuilder.WALL_T)
	particles.emission_box_extents = half
	particles.position = Vector3(0.0, half.y, 0.0)
	particles.direction = Vector3.UP
	particles.spread = 180.0
	var speed: Array = kind.get("speed", [0.05, 0.2])
	particles.initial_velocity_min = float(speed[0])
	particles.initial_velocity_max = float(speed[1])
	var gravity: Array = kind.get("gravity", [0.0, 0.0, 0.0])
	particles.gravity = Vector3(float(gravity[0]), float(gravity[1]), float(gravity[2]))
	particles.damping_min = float(kind.get("damping", 0.0))
	particles.damping_max = float(kind.get("damping", 0.0))
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.3
	particles.color = color
	particles.color_ramp = _fade()
	particles.local_coords = true
	room.add_child(particles)
	return particles


## Transparent at birth and death, full colour in between.
static func _fade() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	return gradient


## Square pixel (dust, snow) or soft glowing dot added on top (embers, fireflies), coloured by the
## particle colour, always facing the camera.
static func _material(glow: bool) -> StandardMaterial3D:
	var key: String = "glow" if glow else "plain"
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if glow:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		material.disable_fog = true
		material.albedo_texture = Fx.soft_dot()
	_materials[key] = material
	return material
