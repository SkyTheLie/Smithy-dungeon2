class_name SpikeStone
extends Node3D
## A stone with spikes that moves through a room on a fixed path (floors.json "spike_stones"), so
## the player can learn it: back and forth on a line, or round a loop. Touching it hurts (and
## pushes the player away). It cannot be destroyed and does not stop shots; flying players are
## safe. It rumbles while it moves (3D sound, louder when near) and sparks when it turns at a wall.
## The Dungeon calls tick() for the room the player is in.

## Points (local to the room) it moves along; `loop` = back to the first after the last, else it
## turns round at both ends.
var points: Array[Vector3] = []
var loop: bool = false
var speed: float = 2.2
var damage: int = 1
var push: float = 4.0
var texture_path: String = ""
var player: Player
var dungeon: Dungeon

var _target: int = 1
var _step: int = 1
var _rumble_wait: float = 0.0
var _body: Node3D
var _time: float = 0.0

const RADIUS: float = 0.55
const HEIGHT: float = 1.1
const SPIKES: int = 8
const RUMBLE_EVERY: float = 0.55


func _ready() -> void:
	if not points.is_empty():
		position = points[0]
	_body = Node3D.new()
	add_child(_body)
	var texture := load(texture_path) as Texture2D
	if texture:
		var sprite := Fx.billboard(texture, HEIGHT)
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.shaded = true
		sprite.modulate = Color(0.85, 0.7, 0.65)
		sprite.position.y = HEIGHT / 2.0
		_body.add_child(sprite)
	# Iron spikes all round (small cones pointing out).
	for i in SPIKES:
		var angle: float = TAU * i / SPIKES
		var spike := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.09
		cone.height = 0.4
		spike.mesh = cone
		spike.material_override = RoomBuilder.color_material(Color(0.6, 0.6, 0.65), 0.2)
		var out := Vector3(cos(angle), 0, sin(angle))
		spike.position = out * (RADIUS + 0.12) + Vector3(0, HEIGHT * (0.35 if i % 2 == 0 else 0.65), 0)
		spike.basis = Basis(Quaternion(Vector3.UP, out))
		_body.add_child(spike)


func tick(delta: float) -> void:
	if points.size() < 2:
		return
	_time += delta
	var goal: Vector3 = points[_target]
	var to_goal: Vector3 = goal - position
	var move: float = speed * delta
	if to_goal.length() <= move:
		position = goal
		_next_point()
	else:
		position += to_goal.normalized() * move
	_body.rotation.y += delta * 2.5
	_rumble_wait -= delta
	if _rumble_wait <= 0.0:
		_rumble_wait = RUMBLE_EVERY
		AudioManager.play_sound_at("spike_rumble", global_position, get_parent() as Node3D, randf_range(0.7, 0.85))
	_hurt_player()


func _next_point() -> void:
	if dungeon:
		Fx.puff(dungeon.effects, global_position + Vector3(0, 0.4, 0), "spark", 0.6)
	if loop:
		_target = (_target + 1) % points.size()
		return
	if _target + _step >= points.size() or _target + _step < 0:
		_step = -_step
	_target += _step


func _hurt_player() -> void:
	if player == null or player.flying():
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() < RADIUS + player.hit_radius():
		var away: Vector3 = offset.normalized() if offset.length() > 0.01 else Vector3.BACK
		player.take_hit(damage, "trap")
		player.knock(away * push)
