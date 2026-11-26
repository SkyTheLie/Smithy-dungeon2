class_name EnemyShot
extends Node3D
## A shot of an enemy (purple orb). Flies straight, ends at walls and rocks, hurts the player by
## half a heart. A Glutmond circling the player (and the Funkenfänger) destroys it.
## Options for bosses (set before adding it): homing (turn rate), slows (a hit slows the player),
## returns_to (flies back to that node after half its life, like an axe), burst (bursts into
## that many shots when it ends), size, lifetime.

const RADIUS: float = 0.2
const LIFETIME: float = 6.0
const GROUP: StringName = &"enemy_shots"

var velocity: Vector3 = Vector3.ZERO
var player: Player
var damage: int = 1
var homing: float = 0.0
var slows: bool = false
var returns_to: Node3D = null
var burst: int = 0
var size: float = 1.0
var lifetime: float = LIFETIME

var _age: float = 0.0
var _returning: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	var kind: String = "enemy"
	var sprite := Fx.billboard(Fx.ball_texture(kind), 0.45 * size)
	if slows:
		sprite.modulate = Color(0.85, 0.95, 1.0)
	elif returns_to:
		sprite.modulate = Color(1.0, 0.7, 0.4)
	elif homing > 0.0:
		sprite.modulate = Color(0.6, 1.0, 0.6)
	add_child(sprite)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.4, 1.0)
	light.light_energy = 0.6
	light.omni_range = 1.8
	add_child(light)


func radius() -> float:
	return RADIUS * size


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		pop()
		return
	_steer(delta)
	var from: Vector3 = global_position
	var to: Vector3 = from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to + velocity.normalized() * radius(), RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty() and not _returning:
		pop()
		return
	global_position = to
	if player and player.is_hit_by(global_position, radius()):
		player.take_hit(damage)
		if slows:
			player.slow_down(2.0)
		pop()
		return
	if _returning and returns_to and is_instance_valid(returns_to) and global_position.distance_to(returns_to.global_position + Vector3(0, 0.8, 0)) < 0.6:
		queue_free()


func _steer(delta: float) -> void:
	if homing > 0.0 and player:
		var want: Vector3 = ((player.global_position + Vector3(0, 1.0, 0)) - global_position).normalized() * velocity.length()
		want.y = 0.0
		velocity = velocity.lerp(want, clampf(homing * delta, 0.0, 1.0))
	if returns_to and is_instance_valid(returns_to) and _age > lifetime * 0.4:
		_returning = true
		var home: Vector3 = returns_to.global_position + Vector3(0, 0.8, 0)
		velocity = velocity.lerp((home - global_position).normalized() * velocity.length(), clampf(4.0 * delta, 0.0, 1.0))


## Ends with a small puff (and bursts into shots with `burst`).
func pop() -> void:
	if not is_inside_tree():
		return
	var parent := get_parent() as Node3D
	Fx.puff(parent, global_position, "enemy", 0.4 * size)
	if burst > 0 and parent:
		for i in burst:
			var shot := EnemyShot.new()
			shot.velocity = Vector3.FORWARD.rotated(Vector3.UP, TAU * i / burst) * maxf(3.5, velocity.length() * 1.6)
			shot.player = player
			parent.add_child(shot)
			shot.global_position = Vector3(global_position.x, 0.9, global_position.z)
	queue_free()
