class_name EnemyBeam
extends Node3D
## A laser of an enemy (Enemy.fire_beam): first a thin see-through line for `aim_time` seconds
## (the warning: this is where it will fire), then a thick bright beam for `fire_time` seconds that
## hurts the player (`damage` half hearts, the usual invulnerable time after a hit counts) while
## they stand in it. It starts at the enemy (and follows it) and ends at the first wall or rock.
## `sweep` (radians per second, + = turning left): the beam turns while it fires.
## fire_time 0 = only the warning line (a boss drawing its bow shows where it aims).
## Ends by itself; also when the enemy dies. Built in code, no scene.

const HEIGHT: float = 0.9
const MAX_LENGTH: float = 30.0
const AIM_WIDTH: float = 0.05

var source: Enemy
var player: Player
var direction: Vector3 = Vector3.FORWARD
var aim_time: float = 0.8
var fire_time: float = 0.6
var sweep: float = 0.0
var width: float = 0.5
var damage: int = 1
var color: Color = Color(1.0, 0.25, 0.2)
## true while the aim line follows the player (a drawn bow); it stops when the beam fires.
var track: bool = false

var _time: float = 0.0
var _mesh: MeshInstance3D
var _box: BoxMesh
var _material: StandardMaterial3D
var _from: Vector3 = Vector3.ZERO
var _length: float = 1.0
var _fired: bool = false


func _ready() -> void:
	_box = BoxMesh.new()
	_mesh = MeshInstance3D.new()
	_mesh.mesh = _box
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	_mesh.material_override = _material
	add_child(_mesh)
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	if direction.length() < 0.01:
		direction = Vector3.FORWARD
	_update_shape()


func firing() -> bool:
	return _time >= aim_time


func _physics_process(delta: float) -> void:
	_time += delta
	if source == null or not is_instance_valid(source) or not source.alive or _time >= aim_time + fire_time:
		queue_free()
		return
	if track and not firing() and player:
		var to_player: Vector3 = (player.global_position - source.global_position) * Vector3(1, 0, 1)
		if to_player.length() > 0.1:
			direction = to_player.normalized()
	if firing():
		if not _fired:
			_fired = true
			if is_instance_valid(source):
				source.sound("enemy_shoot", 0.55)
			else:
				AudioManager.play_sound("enemy_shoot", 0.55)
		if sweep != 0.0:
			direction = direction.rotated(Vector3.UP, sweep * delta)
	_update_shape()
	if firing() and player and _touches(player.global_position, player.hit_radius()):
		player.take_hit(damage)


## Lays the box from the enemy to the first wall / rock: thin and faint while aiming, thick and
## bright (flickering a little) while firing.
func _update_shape() -> void:
	_from = Vector3(source.global_position.x, HEIGHT, source.global_position.z)
	var start: Vector3 = _from + direction * source.radius
	var query := PhysicsRayQueryParameters3D.create(start, start + direction * MAX_LENGTH, RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	_length = maxf(0.2, (Vector3(hit["position"]).distance_to(_from) if not hit.is_empty() else MAX_LENGTH))
	var thickness: float = AIM_WIDTH
	if firing():
		thickness = width * (0.85 + 0.15 * sin(_time * 60.0))
		_material.albedo_color = Color(lerpf(color.r, 1.0, 0.4), lerpf(color.g, 1.0, 0.4), lerpf(color.b, 1.0, 0.4), 0.85)
	else:
		# The warning line blinks faster just before it fires.
		var speed: float = 10.0 if aim_time - _time > 0.3 else 30.0
		_material.albedo_color = Color(color.r, color.g, color.b, 0.25 + 0.2 * absf(sin(_time * speed)))
	_box.size = Vector3(thickness, thickness, _length)
	global_position = _from + direction * _length / 2.0
	global_basis = Basis.looking_at(direction, Vector3.UP)


## true if a body at `at` (radius `body`) stands in the beam.
func _touches(at: Vector3, body: float) -> bool:
	var flat_from := Vector3(_from.x, 0.0, _from.z)
	var flat_to: Vector3 = flat_from + direction * _length
	var point := Vector3(at.x, 0.0, at.z)
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(point, flat_from, flat_to)
	return closest.distance_to(point) < width / 2.0 + body
