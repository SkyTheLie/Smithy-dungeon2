class_name EnemyShot
extends Node3D
## A shot of an enemy (orb). Flies straight, ends at walls and rocks, hurts the player by
## `damage` half hearts. Its colour, size and sound come from its damage (enemies.json
## shot_colors, EnemyShot.look_for): green = ½, red = 1, violet = 1½, black = 2, gold = more. A Glutmond circling the player (and the Funkenfänger) destroys it.
## Options for bosses (set before adding it): homing (turn rate), slows (a hit slows the player),
## returns_to (flies back to that node after half its life, like an axe), burst (bursts into
## that many shots when it ends), size, lifetime, arrow (looks like an arrow), damage.

const RADIUS: float = 0.2
const LIFETIME: float = 6.0
const GROUP: StringName = &"enemy_shots"
const ARROW_LENGTH: float = 0.7

var velocity: Vector3 = Vector3.ZERO
var player: Player
var damage: int = 1
var homing: float = 0.0
var slows: bool = false
var returns_to: Node3D = null
var burst: int = 0
var size: float = 1.0
var lifetime: float = LIFETIME
## Looks like an arrow (a boss with a bow) instead of an orb.
var arrow: bool = false
## For Player.take_hit: "trap" for arrows of arrow walls, "" = an enemy.
var cause: String = ""
## > 0: it also hurts enemies it flies through (arrow traps in the walls), then ends.
var enemy_damage: float = 0.0
var dungeon: Dungeon = null

var _age: float = 0.0
var _returning: bool = false
var _look: Dictionary = {}
var _halo: MeshInstance3D
var _light: OmniLight3D
var _trail_left: float = 0.0

const TRAIL_EVERY: float = 0.06
const SMOKE_CORE := Color(0.45, 0.42, 0.48)
const SMOKE_COLOR := Color(0.15, 0.13, 0.17)


func _ready() -> void:
	add_to_group(GROUP)
	_look = EnemyShot.look_for(damage)
	if arrow:
		_build_arrow()
		return
	var scale_factor: float = size * float(_look.get("size", 1.0))
	var sprite := Fx.billboard(EnemyShot.ball_for(damage), 0.45 * scale_factor)
	add_child(sprite)
	_halo = Fx.halo(EnemyShot.glow_color(damage) * Color(1, 1, 1, 0.55), 0.45 * scale_factor * 1.9)
	add_child(_halo)
	_light = OmniLight3D.new()
	_light.light_color = EnemyShot.glow_color(damage)
	_light.light_energy = 0.6
	_light.omni_range = 1.8
	add_child(_light)


## The step of enemies.json shot_colors for `half_hearts` damage: the one with the largest
## "damage" that is not above it (the first step for anything smaller).
static func look_for(half_hearts: int) -> Dictionary:
	var steps: Array = (Content.get_file("enemies").get("shot_colors", {}) as Dictionary).get("steps", [])
	var found: Dictionary = {}
	for step: Variant in steps:
		var entry: Dictionary = step
		if found.is_empty() or int(entry.get("damage", 1)) <= half_hearts:
			found = entry
	return found


## Main colour of a shot with that damage (also for arrow tips and lasers).
static func color_for(half_hearts: int) -> Color:
	return _color(look_for(half_hearts).get("color", [0.95, 0.2, 0.15]))


## The colour its light and halo have: the main colour, or the core for very dark shots
## (black light would be invisible).
static func glow_color(half_hearts: int) -> Color:
	var look: Dictionary = look_for(half_hearts)
	var main: Color = _color(look.get("color", [0.95, 0.2, 0.15]))
	if main.get_luminance() < 0.2:
		return _color(look.get("core", [1, 1, 1])).darkened(0.3)
	return main


## The pixel ball of a shot with that damage (made once per step).
static func ball_for(half_hearts: int) -> Texture2D:
	var look: Dictionary = look_for(half_hearts)
	var kind: String = "shot_%d" % int(look.get("damage", 1))
	return Fx.colored_ball(kind, _color(look.get("core", [1, 1, 1])), _color(look.get("color", [0.95, 0.2, 0.15])))


## Pitch of the shooting sound for that damage (heavier shots sound deeper).
static func pitch_for(half_hearts: int) -> float:
	return float(look_for(half_hearts).get("pitch", 1.3))


static func _color(value: Variant) -> Color:
	var list: Array = value
	return Color(float(list[0]), float(list[1]), float(list[2]))


## An arrow: a thin wooden shaft with a grey tip and a light feather end, pointing where it flies.
func _build_arrow() -> void:
	var holder := Node3D.new()
	add_child(holder)
	if velocity.length() > 0.01:
		holder.basis = Basis.looking_at(velocity.normalized(), Vector3.UP)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.04, 0.04, ARROW_LENGTH)
	shaft.mesh = shaft_mesh
	shaft.material_override = RoomBuilder.color_material(Color(0.55, 0.38, 0.2))
	holder.add_child(shaft)
	var tip := MeshInstance3D.new()
	var tip_mesh := BoxMesh.new()
	tip_mesh.size = Vector3(0.08, 0.08, 0.12)
	tip.mesh = tip_mesh
	tip.material_override = RoomBuilder.color_material(EnemyShot.color_for(damage), 0.4)
	tip.position.z = -ARROW_LENGTH / 2.0
	holder.add_child(tip)
	var feather := MeshInstance3D.new()
	var feather_mesh := BoxMesh.new()
	feather_mesh.size = Vector3(0.12, 0.02, 0.14)
	feather.mesh = feather_mesh
	feather.material_override = RoomBuilder.color_material(Color(0.9, 0.9, 0.85).lerp(EnemyShot.color_for(damage), 0.35))
	feather.position.z = ARROW_LENGTH / 2.0 - 0.07
	holder.add_child(feather)


func radius() -> float:
	return RADIUS * size


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		pop()
		return
	_steer(delta)
	_shimmer(delta)
	var from: Vector3 = global_position
	var to: Vector3 = from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to + velocity.normalized() * radius(), RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty() and not _returning:
		pop()
		return
	global_position = to
	if enemy_damage > 0.0 and dungeon and _hit_enemy():
		pop()
		return
	if player and player.is_hit_by(global_position, radius()):
		player.take_hit(damage, cause)
		if slows:
			player.slow_down(2.0)
		pop()
		return
	if _returning and returns_to and is_instance_valid(returns_to) and global_position.distance_to(returns_to.global_position + Vector3(0, 0.8, 0)) < 0.6:
		queue_free()


## Flickering halo (violet, gold) and a trail of smoke (black) or sparks (gold).
func _shimmer(delta: float) -> void:
	if _halo and bool(_look.get("flicker", false)):
		_halo.scale = Vector3.ONE * (1.0 + 0.18 * sin(_age * 30.0))
		_light.light_energy = 0.6 + 0.25 * sin(_age * 30.0)
	var trail: String = String(_look.get("trail", ""))
	if trail.is_empty() or not get_parent() is Node3D:
		return
	_trail_left -= delta
	if _trail_left > 0.0:
		return
	_trail_left = TRAIL_EVERY
	var kind: String = "spark"
	if trail == "smoke":
		kind = "shot_smoke"
		Fx.colored_ball(kind, SMOKE_CORE, SMOKE_COLOR)
	Fx.puff(get_parent() as Node3D, global_position, kind, 0.22 * size)


## Arrow traps: the first enemy it touches takes enemy_damage. true if one was hit.
func _hit_enemy() -> bool:
	for enemy: Enemy in dungeon.get_enemies():
		if not enemy.alive or enemy.hidden_phase:
			continue
		var offset: Vector3 = enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() < enemy.radius + radius():
			enemy.take_damage(enemy_damage, velocity.normalized() * 2.0, false)
			return true
	return false


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
	EnemyShot.ball_for(damage)
	Fx.puff(parent, global_position, "shot_%d" % int(EnemyShot.look_for(damage).get("damage", 1)), 0.4 * size)
	if burst > 0 and parent:
		for i in burst:
			var shot := EnemyShot.new()
			shot.velocity = Vector3.FORWARD.rotated(Vector3.UP, TAU * i / burst) * maxf(3.5, velocity.length() * 1.6)
			shot.player = player
			parent.add_child(shot)
			shot.global_position = Vector3(global_position.x, 0.9, global_position.z)
	queue_free()
