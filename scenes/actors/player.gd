class_name Player
extends CharacterBody3D
## The player in first person: W A S D walk (relative to where the camera looks), the mouse turns
## the camera (Run passes the mouse movement to look()), E / right mouse button drops a bomb.
## Shooting is done by the child Weapon. After a hit the player cannot be hurt for a moment
## (longer with "guard_time"). Item flags here: dodge (chance to dodge a hit), still_guard
## (standing still without shooting = safe), small (smaller body).

signal hurt

const RADIUS: float = 0.35
const EYE_HEIGHT: float = 1.5
const BODY_HEIGHT: float = 1.8
const ACCELERATION: float = 40.0
const INVULNERABLE_TIME: float = 1.0
const PITCH_LIMIT: float = 1.35
## Radians per pixel of mouse movement at sensitivity 1.0.
const MAX_LOOK_SPEED: float = 0.006
const BOB_SPEED: float = 9.0
const BOB_AMOUNT: float = 0.045
const BOMB_DISTANCE: float = 1.6
## Thin white ring on the floor under the player: how big the body is (hit radius).
const RING_COLOR := Color(1.0, 1.0, 1.0, 0.7)

var run: RunState
var dungeon: Dungeon
## Time left in which hits do nothing.
var invulnerable: float = 0.0
## false during pause, death screen, floor change.
var controls_enabled: bool = true

var _bob_time: float = 0.0
## Seconds standing still without shooting (still_guard).
var _still_time: float = 0.0
## Sticky web of a boss: slower for a while. Screen shake left.
var _slow_left: float = 0.0
var _shake_left: float = 0.0
## Dash (Shift with "dash"): direction and time left; cooldown of dash and blink.
var _dash_left: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _dash_wait: float = 0.0
var _ring: MeshInstance3D

@onready var camera: Camera3D = $Camera
@onready var weapon: Weapon = $Weapon


func setup(run_state: RunState, the_dungeon: Dungeon) -> void:
	run = run_state
	dungeon = the_dungeon
	weapon.setup(self, run_state, the_dungeon)


func _ready() -> void:
	_ring = Fx.ring(self, RADIUS, RING_COLOR)
	# Field of view from the settings, also when it is changed in the pause menu.
	camera.fov = DisplaySettings.get_fov()
	Game.fov_changed.connect(_on_fov_changed)


func _on_fov_changed(degrees: float) -> void:
	camera.fov = degrees


## Turns the view by a mouse movement (pixels).
func look(relative: Vector2) -> void:
	if not controls_enabled:
		return
	var speed: float = MAX_LOOK_SPEED * lerpf(0.15, 1.6, Game.get_mouse_sensitivity())
	rotation.y -= relative.x * speed
	camera.rotation.x = clampf(camera.rotation.x - relative.y * speed, -PITCH_LIMIT, PITCH_LIMIT)


## Direction the crosshair points to.
func aim_direction() -> Vector3:
	return -camera.global_basis.z


func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector(Controls.MOVE_LEFT, Controls.MOVE_RIGHT, Controls.MOVE_FORWARD, Controls.MOVE_BACK)
	var speed: float = run.stats.move_speed if run else 5.0
	_slow_left = maxf(0.0, _slow_left - delta)
	if _slow_left > 0.0:
		speed *= 0.5
	_shake_left = maxf(0.0, _shake_left - delta)
	camera.h_offset = randf_range(-0.06, 0.06) * minf(1.0, _shake_left * 3.0)
	camera.v_offset = randf_range(-0.06, 0.06) * minf(1.0, _shake_left * 3.0)
	var wanted: Vector3 = (global_basis * Vector3(input.x, 0, input.y)) * speed
	velocity = velocity.move_toward(wanted, ACCELERATION * delta)
	_update_dash(delta, wanted)
	if input.length() > 0.1 or Input.is_action_pressed(Controls.SHOOT):
		_still_time = 0.0
	else:
		_still_time += delta
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	# Head bob while walking.
	if input.length() > 0.1:
		_bob_time += delta * BOB_SPEED
	else:
		_bob_time = lerpf(_bob_time, roundf(_bob_time / PI) * PI, 10.0 * delta)
	var body: float = run.stats.body if run else 1.0
	camera.position.y = EYE_HEIGHT * body + absf(sin(_bob_time)) * BOB_AMOUNT
	# The ring grows and shrinks with the body (size items).
	var ring_scale: float = hit_radius() / RADIUS
	_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
	if controls_enabled and Input.is_action_just_pressed(Controls.BOMB):
		_drop_bomb()


func _drop_bomb() -> void:
	if run == null or dungeon == null or not run.use_bomb():
		return
	var bomb := PlacedBomb.new()
	bomb.dungeon = dungeon
	dungeon.effects.add_child(bomb)
	# 1.6 m ahead: close enough to drop it at an enemy, far enough to be in view (not below the
	# bottom edge of the screen); kept inside the room.
	var forward: Vector3 = -global_basis.z
	var at: Vector3 = global_position + forward * BOMB_DISTANCE
	var rect: Rect2 = RoomBuilder.inner_rect(dungeon.current_cell, 0.4)
	bomb.global_position = Vector3(clampf(at.x, rect.position.x, rect.end.x), 0.0, clampf(at.z, rect.position.y, rect.end.y))


## Radius of the body that can be hit: times the body size ("body"), smaller with "small".
func hit_radius() -> float:
	var result: float = RADIUS * (run.stats.body if run else 1.0)
	if run and run.stats.has("small"):
		result *= float((Content.player().get("effects", {}) as Dictionary).get("small_radius", 0.65))
	return result


## true while standing still long enough with "still_guard".
func is_guarded() -> bool:
	return run != null and run.stats.has("still_guard") and _still_time >= float((Content.player().get("effects", {}) as Dictionary).get("still_time", 1.0))


## true if a ball at `point` touches the player's body.
func is_hit_by(point: Vector3, ball_radius: float) -> bool:
	var offset := Vector2(point.x - global_position.x, point.z - global_position.z)
	var top: float = BODY_HEIGHT * (run.stats.body if run else 1.0)
	return offset.length() < hit_radius() + ball_radius and point.y < top + ball_radius and point.y > -ball_radius


## Takes `halves` half hearts unless just hit.
func take_hit(halves: int) -> void:
	if invulnerable > 0.0 or run == null or run.is_dead() or is_guarded():
		return
	if run.stats.roll("dodge"):
		invulnerable = 0.4
		if dungeon:
			Fx.puff(dungeon.effects, global_position + Vector3(0, 1.0, 0), "spark", 0.8)
		return
	if run.block_with_mantle():
		invulnerable = INVULNERABLE_TIME + run.stats.guard_time
		AudioManager.play_sound("unlock", 0.7)
		if dungeon:
			Fx.puff(dungeon.effects, global_position + Vector3(0, 1.0, 0), "fire", 1.6)
		return
	if run.take_damage(halves):
		invulnerable = INVULNERABLE_TIME + run.stats.guard_time
		AudioManager.play_sound("player_hurt")
		AudioManager.play_stream(SoundSynth.make(Content.player().get("voice", {}), "hit"), randf_range(0.95, 1.05))
		hurt.emit()


## A boss web: slower for `time` seconds.
func slow_down(time: float) -> void:
	_slow_left = maxf(_slow_left, time)


## Shakes the camera for `time` seconds (a boss lands).
func shake(time: float) -> void:
	_shake_left = maxf(_shake_left, time)


# --- Dash and blink (Shift) ------------------------------------------------------------

func _update_dash(delta: float, wanted: Vector3) -> void:
	_dash_wait = maxf(0.0, _dash_wait - delta)
	var effects: Dictionary = Content.player().get("effects", {})
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * float(effects.get("dash_speed", 16.0))
		return
	if not controls_enabled or run == null or _dash_wait > 0.0 or not Input.is_action_just_pressed(Controls.DASH):
		return
	if run.stats.has("blink"):
		_blink()
		_dash_wait = float(effects.get("blink_cooldown", 2.5))
	elif run.stats.has("dash"):
		_dash_dir = wanted.normalized() if wanted.length() > 0.1 else -global_basis.z
		_dash_left = float(effects.get("dash_time", 0.18))
		invulnerable = maxf(invulnerable, _dash_left + 0.1)
		_dash_wait = float(effects.get("dash_cooldown", 0.9))
		AudioManager.play_sound("dash")


## Teleport to the point under the crosshair (inside the room, not into a rock).
func _blink() -> void:
	var from: Vector3 = camera.global_position
	var direction: Vector3 = aim_direction()
	var reach: float = float((Content.player().get("effects", {}) as Dictionary).get("blink_range", 9.0))
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * reach, RoomBuilder.LAYER_WORLD | RoomBuilder.LAYER_ROCKS)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = (Vector3(hit["position"]) - direction * 0.7) if not hit.is_empty() else from + direction * reach
	var rect: Rect2 = RoomBuilder.inner_rect(dungeon.current_cell, RADIUS + 0.1)
	target = Vector3(clampf(target.x, rect.position.x, rect.end.x), 0.0, clampf(target.z, rect.position.y, rect.end.y))
	Fx.puff(dungeon.effects, global_position + Vector3(0, 1.0, 0), "spark", 1.2)
	global_position = target
	Fx.puff(dungeon.effects, global_position + Vector3(0, 1.0, 0), "spark", 1.2)
	invulnerable = maxf(invulnerable, 0.3)
	AudioManager.play_sound("boss_teleport", 1.4)
