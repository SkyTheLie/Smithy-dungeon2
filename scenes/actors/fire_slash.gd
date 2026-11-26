class_name FireSlash
extends Node3D
## Feuerhieb (sword + fire staff, flag "fire_slash"): every swing sends a curved band of fire
## forward. It flies through enemies and hurts each one once (with the shot's flags, e.g. burn),
## knocks enemy shots out of the air and goes out at a wall, a rock (not with "spectral") or at
## the end of its way. Built in code: the band is a small mesh, bright in the middle row.
## Numbers: data/player.json effects fire_slash_damage, fire_slash_speed.

## How wide the band is bent, its radius, and how high it flies.
const ARC_DEGREES: float = 110.0
const RADIUS: float = 1.1
const MIDDLE_Y: float = 1.05
const HALF_HEIGHT: float = 0.28
const SEGMENTS: int = 14
## How deep (front to back) the band hits, in metres.
const HIT_DEPTH: float = 0.5
const END_FADE: float = 0.12

var dungeon: Dungeon
var stats: ShotStats
var damage: float = 1.0
## Metres the band flies.
var distance: float = 3.0
var speed: float = 10.0

var _forward: Vector3 = Vector3.FORWARD
var _hit: Array[Node] = []
var _flags: Dictionary[String, bool] = {}
var _traveled: float = 0.0
var _material: StandardMaterial3D
var _light: OmniLight3D
var _done: bool = false


## `already_hit`: enemies the sword itself just hit (they are not hit a second time).
func setup(the_dungeon: Dungeon, the_stats: ShotStats, forward: Vector3, way: float, amount: float, already_hit: Array[Node]) -> void:
	dungeon = the_dungeon
	stats = the_stats
	_forward = (forward * Vector3(1, 0, 1)).normalized()
	distance = way
	damage = amount
	speed = float((Content.player().get("effects", {}) as Dictionary).get("fire_slash_speed", 10.0))
	_flags = stats.roll_flags()
	_hit = already_hit.duplicate()


func _ready() -> void:
	# -Z of this node looks along the flight direction.
	global_basis = Basis.looking_at(_forward, Vector3.UP)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_band()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = _material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	_light = OmniLight3D.new()
	_light.light_color = Color(1, 0.55, 0.2)
	_light.light_energy = 1.6
	_light.omni_range = 3.0
	_light.position = Vector3(0, MIDDLE_Y, -RADIUS)
	add_child(_light)


## The curved band: three rows (dark-orange edge, bright middle, dark-orange edge), thin at
## both ends like a cut.
func _build_band() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = deg_to_rad(ARC_DEGREES) / 2.0
	var edge := Color(1.0, 0.35, 0.08, 0.55)
	var middle := Color(1.0, 0.9, 0.55, 1.0)
	var rows: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	for i in SEGMENTS + 1:
		var angle: float = lerpf(-half, half, float(i) / SEGMENTS)
		var taper: float = cos(angle / half * PI / 2.0)
		var at := Vector3(sin(angle), 0, -cos(angle)) * RADIUS
		var height: float = lerpf(0.03, HALF_HEIGHT, taper)
		rows[0].append(at + Vector3(0, MIDDLE_Y - height, 0))
		rows[1].append(at + Vector3(0, MIDDLE_Y, 0))
		rows[2].append(at + Vector3(0, MIDDLE_Y + height, 0))
	var colors: Array[Color] = [edge, middle, edge]
	for row in 2:
		for i in SEGMENTS:
			var a: Vector3 = rows[row][i]
			var b: Vector3 = rows[row][i + 1]
			var c: Vector3 = rows[row + 1][i]
			var d: Vector3 = rows[row + 1][i + 1]
			for corner: Array in [[a, row], [b, row], [c, row + 1], [b, row], [d, row + 1], [c, row + 1]]:
				tool.set_color(colors[int(corner[1])])
				tool.add_vertex(corner[0])
	return tool.commit()


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step: float = speed * delta
	if _blocked(step):
		_go_out()
		return
	global_position += _forward * step
	_traveled += step
	_hurt_enemies()
	_pop_enemy_shots()
	# Fades towards the end of its way.
	_material.albedo_color.a = 1.0 - pow(clampf(_traveled / maxf(distance, 0.1), 0.0, 1.0), 2.0)
	if _traveled >= distance:
		_done = true
		queue_free()


## true if the middle of the band would run into a wall (or a rock) this frame.
func _blocked(step: float) -> bool:
	var from: Vector3 = global_position + Vector3(0, MIDDLE_Y, 0) + _forward * (RADIUS - 0.1)
	var mask: int = RoomBuilder.LAYER_WORLD if _flags.has("spectral") else RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS
	var query := PhysicsRayQueryParameters3D.create(from, from + _forward * (step + 0.1), mask)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## true if a body at `at` with `body_radius` is inside the band right now.
func _touches(at: Vector3, body_radius: float) -> bool:
	var offset: Vector3 = (at - global_position) * Vector3(1, 0, 1)
	var length: float = offset.length()
	if length > RADIUS + body_radius or length < RADIUS - HIT_DEPTH - body_radius or length < 0.001:
		return false
	return _forward.angle_to(offset / length) <= deg_to_rad(ARC_DEGREES) / 2.0 + body_radius / RADIUS


func _hurt_enemies() -> void:
	for enemy: Enemy in dungeon.get_enemies().duplicate():
		if _hit.has(enemy) or enemy.hidden_phase or not _touches(enemy.global_position, enemy.radius):
			continue
		_hit.append(enemy)
		enemy.take_damage(damage, _forward * stats.knockback, _flags.has("bread"))
		enemy.afflict(_flags, damage)


func _pop_enemy_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(EnemyShot.GROUP):
		if _touches((shot as Node3D).global_position, EnemyShot.RADIUS):
			(shot as EnemyShot).pop()


## Against a wall: goes out quickly.
func _go_out() -> void:
	_done = true
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color:a", 0.0, END_FADE)
	tween.parallel().tween_property(_light, "light_energy", 0.0, END_FADE)
	tween.tween_callback(queue_free)
