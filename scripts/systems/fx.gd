class_name Fx
extends RefCounted
## Small pictures and effects made in code: the round pixel fireball, the enemy orb, a flash of
## light, the explosion and the "puff" when something appears. Textures are made once and kept
## (read-only cache, not game state).

const FIRE_SIZE: int = 12
## Width of the body rings on the floor (Fx.ring), in metres.
const RING_WIDTH: float = 0.04

static var _textures: Dictionary[String, Texture2D] = {}
## Colour -> halo material (read-only cache).
static var _halo_materials: Dictionary[String, StandardMaterial3D] = {}


## Round pixel ball: white-yellow core, orange, red rim. `kind` "fire", "enemy" (purple),
## "spark" (small yellow), "heal" (green, a potion), "grass" (blades flying up).
static func ball_texture(kind: String) -> Texture2D:
	if _textures.has(kind):
		return _textures[kind]
	var colors: Array[Color] = [Color(1, 0.97, 0.75), Color(1, 0.75, 0.25), Color(0.95, 0.38, 0.12), Color(0.6, 0.12, 0.08)]
	if kind == "enemy":
		colors = [Color(0.95, 0.85, 1), Color(0.75, 0.45, 1), Color(0.5, 0.2, 0.8), Color(0.25, 0.08, 0.4)]
	elif kind == "spark":
		colors = [Color(1, 1, 0.9), Color(1, 0.9, 0.4), Color(1, 0.65, 0.2), Color(0.8, 0.35, 0.1)]
	elif kind == "heal":
		colors = [Color(0.9, 1, 0.9), Color(0.5, 1, 0.55), Color(0.2, 0.8, 0.35), Color(0.1, 0.45, 0.2)]
	elif kind == "grass":
		colors = [Color(0.75, 0.9, 0.45), Color(0.45, 0.7, 0.25), Color(0.3, 0.5, 0.15), Color(0.2, 0.35, 0.1)]
	var image := Image.create(FIRE_SIZE, FIRE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(FIRE_SIZE, FIRE_SIZE) / 2.0 - Vector2(0.5, 0.5)
	for y in FIRE_SIZE:
		for x in FIRE_SIZE:
			var d: float = Vector2(x, y).distance_to(center) / (FIRE_SIZE / 2.0)
			if d > 1.0:
				continue
			var index: int = clampi(int(d * 4.0), 0, 3)
			image.set_pixel(x, y, colors[index])
	var texture := ImageTexture.create_from_image(image)
	_textures[kind] = texture
	return texture


## A billboard sprite (always faces the camera) with sharp pixels.
static func billboard(texture: Texture2D, world_height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.pixel_size = world_height / float(maxi(1, texture.get_height()))
	return sprite


## Soft glow around something bright (fireball, torch flame): a camera-facing square with a round,
## stepped (pixel-look) light spot, added on top of what is behind it. `size` in metres.
## (Real glow of the WorldEnvironment is almost invisible in GL Compatibility for unshaded sprites.)
static func halo(color: Color, size: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	mesh_instance.mesh = quad
	mesh_instance.material_override = _halo_material(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


static func _halo_material(color: Color) -> StandardMaterial3D:
	var key: String = "halo|%s" % color
	if _halo_materials.has(key):
		return _halo_materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.disable_fog = true
	material.albedo_texture = _halo_texture()
	material.albedo_color = color
	_halo_materials[key] = material
	return material


## White round spot, 32 x 32, brightness in 6 steps towards the rim.
static func _halo_texture() -> Texture2D:
	if _textures.has("halo"):
		return _textures["halo"]
	const SIZE: int = 32
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SIZE, SIZE) / 2.0 - Vector2(0.5, 0.5)
	for y in SIZE:
		for x in SIZE:
			var d: float = Vector2(x, y).distance_to(center) / (SIZE / 2.0)
			if d >= 1.0:
				continue
			var strength: float = ceilf((1.0 - d) * (1.0 - d) * 6.0) / 6.0
			image.set_pixel(x, y, Color(1, 1, 1, strength))
	var texture := ImageTexture.create_from_image(image)
	_textures["halo"] = texture
	return texture


## A short flash of light (fades out and removes itself).
static func flash(parent: Node3D, at: Vector3, color: Color, energy: float, light_range: float, time: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	parent.add_child(light)
	light.global_position = at
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, time)
	tween.tween_callback(light.queue_free)


## Fireball explosion: a growing, fading ball and a flash.
static func explosion(parent: Node3D, at: Vector3, radius: float) -> void:
	var sprite := billboard(ball_texture("fire"), radius * 0.6)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	parent.add_child(sprite)
	sprite.global_position = at + Vector3(0, radius * 0.4, 0)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector3.ONE * 4.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
	tween.tween_callback(sprite.queue_free)
	flash(parent, at + Vector3(0, 0.8, 0), Color(1, 0.6, 0.25), 5.0, radius * 3.0, 0.4)


## Small puff where a fireball ends or an enemy appears.
static func puff(parent: Node3D, at: Vector3, kind: String, size: float) -> void:
	var sprite := billboard(ball_texture(kind), size)
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	parent.add_child(sprite)
	sprite.global_position = at
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector3.ONE * 2.0, 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(sprite.queue_free)


## Colours of the confetti when an enemy dies (and of the level-up burst).
const CONFETTI_COLORS: Array[Color] = [Color(1.0, 0.35, 0.3), Color(1.0, 0.8, 0.25), Color(0.4, 0.95, 0.45), Color(0.35, 0.75, 1.0), Color(0.85, 0.45, 1.0)]


## A number that pops up at `at`, rises and fades: the damage of a hit. `big` (a strong hit) is
## bigger and golden, `killed` red-orange. Always readable (in front of walls, same size near
## and far).
static func damage_number(parent: Node3D, at: Vector3, amount: float, big: bool, killed: bool) -> void:
	var label := Label3D.new()
	label.text = str(roundi(amount)) if amount >= 10.0 or is_equal_approx(amount, roundf(amount)) else String.num(amount, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.003
	label.font_size = 44 if big else 32
	label.outline_size = 10
	label.outline_modulate = Color(0.1, 0.03, 0.02)
	label.modulate = Color(1.0, 0.85, 0.2) if big else (Color(1.0, 0.45, 0.25) if killed else Color(1.0, 1.0, 1.0))
	label.render_priority = 10
	label.outline_render_priority = 9
	parent.add_child(label)
	var side: float = randf_range(-0.25, 0.25)
	label.global_position = at + Vector3(side, 0.2, side * 0.5)
	label.scale = Vector3.ONE * 0.4
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE * (1.25 if big else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "global_position:y", label.global_position.y + 0.9, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.tween_callback(label.queue_free)


## A short burst of coloured sparks at `at` (an enemy dies): small squares fly out and fall.
static func confetti(parent: Node3D, at: Vector3, amount: int = 14) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = 0.7
	particles.explosiveness = 0.95
	particles.direction = Vector3.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.gravity = Vector3(0, -9.0, 0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.07, 0.07)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = material
	particles.mesh = mesh
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0])
	ramp.colors = PackedColorArray([CONFETTI_COLORS[0]])
	for i in range(1, CONFETTI_COLORS.size()):
		ramp.add_point(float(i) / float(CONFETTI_COLORS.size() - 1), CONFETTI_COLORS[i])
	particles.color_initial_ramp = ramp
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## A red disc on the floor for `time` seconds (where a boss will land).
static func marker(parent: Node3D, at: Vector3, radius: float, time: float) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	disc.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.15, 0.1, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = material
	parent.add_child(disc)
	disc.global_position = Vector3(at.x, 0.03, at.z)
	var tween := disc.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.8, time)
	tween.tween_callback(disc.queue_free)


## A thin ring lying on the floor (child of `parent`, centred under it): shows how big the
## body of an enemy or the player is. `radius` in metres.
static func ring(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var ring_node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.outer_radius = radius
	mesh.inner_radius = maxf(0.01, radius - RING_WIDTH)
	mesh.rings = 32
	mesh.ring_segments = 4
	ring_node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_node.material_override = material
	ring_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring_node.position.y = 0.03
	parent.add_child(ring_node)
	return ring_node


## A filled quarter of a disc on the floor (90 degrees around local -Z), for where an enemy
## looks (Enemy: turned with rotation.y). Built once per enemy, not every frame.
static func facing_wedge(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var steps: int = 8
	var inner: float = radius * 0.25
	for i in steps:
		var a0: float = -PI / 4.0 + PI / 2.0 * float(i) / float(steps)
		var a1: float = -PI / 4.0 + PI / 2.0 * float(i + 1) / float(steps)
		var p0 := Vector3(sin(a0), 0, -cos(a0))
		var p1 := Vector3(sin(a1), 0, -cos(a1))
		# Two triangles per step: from the inner edge out to the ring (a quarter of a ring, so the
		# middle under the sprite stays free).
		vertices.append_array([p0 * inner, p1 * inner, p1 * radius, p0 * inner, p1 * radius, p0 * radius])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = "FacingWedge"
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position.y = 0.025
	parent.add_child(node)
	return node


## A small grey four-pointed throwing star.
static func star_texture() -> Texture2D:
	if _textures.has("star"):
		return _textures["star"]
	var size: int = 13
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var middle: int = size / 2
	for y in size:
		for x in size:
			var dx: int = absi(x - middle)
			var dy: int = absi(y - middle)
			# Four points along the axes, thinner towards the tips; a hole in the middle.
			var on_arm: bool = (dx <= 1 and dy <= middle - dx * 2) or (dy <= 1 and dx <= middle - dy * 2) or (dx <= 2 and dy <= 2)
			if on_arm and not (dx == 0 and dy == 0):
				var light: float = 0.55 + 0.4 * (1.0 - float(dx + dy) / size)
				image.set_pixel(x, y, Color(light, light, light * 1.05))
	var texture := ImageTexture.create_from_image(image)
	_textures["star"] = texture
	return texture
