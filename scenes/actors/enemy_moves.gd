class_name EnemyMoves
extends RefCounted
## The newer kinds of enemies (data/enemies.json "ai"). Each has one clear pattern the player can
## learn, and every dangerous move is announced first (the enemy shakes, swells or shows a line):
##   charger  crawls along the room's axes. As soon as the player stands in line with it (same row
##            or column, within "sight" metres) it shakes for "windup" seconds and rushes straight
##            along that line until it hits something, then stands dazed. Stand diagonal to it!
##            With "laser": {aim, fire, width} it fires a beam along the line instead of rushing.
##   turret   stands still and is not pushed (or hops around slowly with "speed" > 0); shakes, then
##            shoots its "pattern" when the player is within "range" (Enemy.shoot_pattern).
##   wall     climbs around on the walls ("climb" metres up), cannot touch the player and shoots its
##            "pattern" from up there. Turns around now and then.
##   bouncer  flies diagonally through the room and bounces off walls and rocks, like a ball.
##   spawner  keeps away from the player (closer than "flee" metres: it runs) and lets out helpers
##            ("summon") every "spawn_every" seconds; it swells up before. Chase it!
##   shell    sits in its shell (hits bounce off) and creeps closer; then it opens for "open"
##            seconds (shakes first), shoots its "pattern" and can only be hurt while open.
## Enemy calls update() every physics frame (only while awake, not frozen, scared or dazed) and
## uses the returned velocity; "wall" places the enemy itself (places_itself, place).

const KINDS: Array[String] = ["charger", "turret", "wall", "bouncer", "spawner", "shell"]
const CHARGER_SIGHT: float = 9.0
const LINE_WIDTH: float = 0.6
const RUSH_TIME: float = 1.6
const DAZED_TIME: float = 0.9
const TELEGRAPH: float = 0.5
const SHELL_CLOSED: Array = [2.2, 3.4]
const SHELL_OPEN: float = 1.4
const WALL_GAP: float = 0.12

var enemy: Enemy
var kind: String = ""
## World position for "wall" (Enemy puts itself there).
var place: Vector3 = Vector3.ZERO

var _state: int = 0
var _left: float = 0.0
var _dir: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _shot_done: bool = false
## "wall": where along the walls (metres from the first corner) and which way it climbs.
var _along: float = -1.0
var _way: float = 1.0
var _turn_wait: float = 4.0


func _init(the_enemy: Enemy) -> void:
	enemy = the_enemy
	kind = String(enemy.data.get("ai", ""))
	_timer = enemy.rng.randf_range(0.8, interval())
	_left = enemy.rng.randf_range(0.5, 1.5)
	_dir = _random_axis()
	if kind == "bouncer":
		_dir = Vector3(1.0 if enemy.rng.randf() < 0.5 else -1.0, 0, 1.0 if enemy.rng.randf() < 0.5 else -1.0).normalized()
	if kind == "shell":
		enemy.armored = true
		_left = enemy.rng.randf_range(float(SHELL_CLOSED[0]), float(SHELL_CLOSED[1]))


## true for "wall": it moves along the walls by itself (no physics, no touching the player).
func places_itself() -> bool:
	return kind == "wall"


## true if it should not be pushed by hits (a turret that stands still).
func rooted() -> bool:
	return kind == "turret" and float(enemy.data.get("speed", 0.0)) <= 0.0


func interval() -> float:
	return float(enemy.data.get("fire_interval", 2.5))


## Velocity of this frame.
func update(delta: float, toward: Vector3, distance: float) -> Vector3:
	match kind:
		"charger":
			return _charger(delta)
		"turret":
			return _turret(delta, distance)
		"wall":
			_wall(delta, distance)
			return Vector3.ZERO
		"bouncer":
			return _dir * enemy.speed()
		"spawner":
			return _spawner(delta, toward, distance)
		"shell":
			return _shell(delta, toward)
	return Vector3.ZERO


## After move_and_slide: a bouncer bounces off the wall or rock it hit; a rushing charger stops
## at it. Touching the floor does not count.
func after_move() -> void:
	var normal: Vector3 = Vector3.ZERO
	for i in enemy.get_slide_collision_count():
		var flat: Vector3 = enemy.get_slide_collision(i).get_normal() * Vector3(1, 0, 1)
		if flat.length() > 0.5:
			normal = flat.normalized()
			break
	if normal == Vector3.ZERO:
		return
	if kind == "bouncer":
		if _dir.dot(normal) < 0.0:
			_dir = _dir.bounce(normal).normalized()
	elif kind == "charger" and _state == 2:
		_state = 3
		_left = DAZED_TIME
		enemy.shake(0.15)
	elif kind in ["charger", "spawner", "turret"] and _state == 0:
		_dir = _random_axis()


# --- charger ----------------------------------------------------------------------------

func _charger(delta: float) -> Vector3:
	_left -= delta
	_timer = maxf(0.0, _timer - delta)
	match _state:
		0:
			if _left <= 0.0:
				_left = enemy.rng.randf_range(1.2, 2.4)
				_dir = _random_axis()
			var line: Vector3 = _line_to_player()
			if line != Vector3.ZERO and _timer <= 0.0:
				_state = 1
				_dir = line
				_left = float(enemy.data.get("windup", 0.45))
				enemy.wobble(_left)
				enemy.cry("attack")
				var laser: Dictionary = enemy.data.get("laser", {})
				if not laser.is_empty():
					# The beam's own warning line is the wind-up.
					_left = float(laser.get("aim", 0.7))
					enemy.fire_beam(_dir, {"aim": _left, "fire": float(laser.get("fire", 0.5)), "width": float(laser.get("width", 0.45)), "damage": int(enemy.data.get("damage", 1))})
				return Vector3.ZERO
			return _dir * enemy.speed()
		1:
			if _left <= 0.0:
				var laser: Dictionary = enemy.data.get("laser", {})
				_state = 3 if not laser.is_empty() else 2
				_left = float(laser.get("fire", 0.5)) + 0.3 if not laser.is_empty() else RUSH_TIME
				if laser.is_empty():
					enemy.sound("dash", 0.8)
			return Vector3.ZERO
		2:
			if _left <= 0.0:
				_state = 3
				_left = DAZED_TIME
			return _dir * enemy.speed() * float(enemy.data.get("rush", 4.5))
		_:
			if _left <= 0.0:
				_state = 0
				_left = 0.6
				_timer = interval()
			return Vector3.ZERO


## The axis towards the player if they stand in its row or column (and not too far); else ZERO.
func _line_to_player() -> Vector3:
	var offset: Vector3 = (enemy.player.global_position - enemy.global_position) * Vector3(1, 0, 1)
	var sight: float = float(enemy.data.get("sight", CHARGER_SIGHT))
	if absf(offset.x) < LINE_WIDTH and absf(offset.z) < sight and absf(offset.z) > 0.5:
		return Vector3(0, 0, signf(offset.z))
	if absf(offset.z) < LINE_WIDTH and absf(offset.x) < sight and absf(offset.x) > 0.5:
		return Vector3(signf(offset.x), 0, 0)
	return Vector3.ZERO


func _random_axis() -> Vector3:
	var axes: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	return axes[enemy.rng.randi_range(0, 3)]


# --- turret -----------------------------------------------------------------------------

func _turret(delta: float, distance: float) -> Vector3:
	_fire_when_ready(delta, distance)
	if rooted():
		return Vector3.ZERO
	# Hops: a short move in a random direction, then a pause.
	_left -= delta
	if _left <= 0.0:
		_state = 1 - _state
		_left = 0.4 if _state == 1 else enemy.rng.randf_range(0.8, 1.6)
		_dir = Vector3.FORWARD.rotated(Vector3.UP, enemy.rng.randf() * TAU)
	return _dir * enemy.speed() if _state == 1 else Vector3.ZERO


## Counts down; shakes TELEGRAPH seconds before; then shoots its pattern if the player is in range.
func _fire_when_ready(delta: float, distance: float) -> void:
	_timer -= delta
	var in_range: bool = distance < float(enemy.data.get("range", 10.0))
	if not _shot_done and _timer <= TELEGRAPH and in_range:
		_shot_done = true
		enemy.wobble(TELEGRAPH)
		enemy.cry("attack")
	if _timer <= 0.0:
		_timer = interval() * enemy.rng.randf_range(0.9, 1.15)
		if _shot_done:
			enemy.shoot_pattern(String(enemy.data.get("pattern", "aimed")), {})
		_shot_done = false


# --- wall -------------------------------------------------------------------------------

func _wall(delta: float, distance: float) -> void:
	var rect: Rect2 = enemy.room_rect(WALL_GAP)
	var perimeter: float = 2.0 * (rect.size.x + rect.size.y)
	if _along < 0.0:
		_along = _nearest_along(rect, Vector2(enemy.global_position.x, enemy.global_position.z))
	_turn_wait -= delta
	if _turn_wait <= 0.0:
		_turn_wait = enemy.rng.randf_range(3.0, 6.0)
		_way = -_way
	_along = fposmod(_along + _way * enemy.speed() * delta, perimeter)
	var flat: Vector2 = _point_along(rect, _along)
	place = Vector3(flat.x, float(enemy.data.get("climb", 1.4)), flat.y)
	_fire_when_ready(delta, distance)


## The point `along` metres around the rectangle (clockwise from the top left corner).
static func _point_along(rect: Rect2, along: float) -> Vector2:
	var w: float = rect.size.x
	var h: float = rect.size.y
	if along < w:
		return rect.position + Vector2(along, 0)
	if along < w + h:
		return rect.position + Vector2(w, along - w)
	if along < 2.0 * w + h:
		return rect.position + Vector2(w - (along - w - h), h)
	return rect.position + Vector2(0, h - (along - 2.0 * w - h))


static func _nearest_along(rect: Rect2, at: Vector2) -> float:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var local: Vector2 = at - rect.position
	var choices: Array = [
		[absf(local.y), clampf(local.x, 0, w)],
		[absf(w - local.x), w + clampf(local.y, 0, h)],
		[absf(h - local.y), w + h + (w - clampf(local.x, 0, w))],
		[absf(local.x), 2.0 * w + h + (h - clampf(local.y, 0, h))],
	]
	var best: Array = choices[0]
	for choice: Array in choices:
		if float(choice[0]) < float(best[0]):
			best = choice
	return float(best[1])


# --- spawner ----------------------------------------------------------------------------

func _spawner(delta: float, toward: Vector3, distance: float) -> Vector3:
	_timer -= delta
	var every: float = float(enemy.data.get("spawn_every", 3.5))
	if not _shot_done and _timer <= TELEGRAPH:
		_shot_done = true
		enemy.swell(TELEGRAPH)
		enemy.cry("attack")
	if _timer <= 0.0:
		_timer = every * enemy.rng.randf_range(0.85, 1.2)
		_shot_done = false
		enemy.summon_near(Vector3(enemy.rng.randf_range(-0.6, 0.6), 0, enemy.rng.randf_range(-0.6, 0.6)))
	if distance < float(enemy.data.get("flee", 5.0)):
		# Away from the player, a bit sideways so it does not get stuck in a corner.
		var side: Vector3 = toward.cross(Vector3.UP) * (1.0 if sin(enemy.age() * 0.8) > 0.0 else -1.0)
		return (-toward + side * 0.7).normalized() * enemy.speed()
	_left -= delta
	if _left <= 0.0:
		_left = enemy.rng.randf_range(1.0, 2.0)
		_dir = Vector3.FORWARD.rotated(Vector3.UP, enemy.rng.randf() * TAU)
	return _dir * enemy.speed() * 0.4


# --- shell ------------------------------------------------------------------------------

func _shell(delta: float, toward: Vector3) -> Vector3:
	_left -= delta
	match _state:
		0:
			if _left <= 0.0:
				_state = 1
				_left = TELEGRAPH
				enemy.wobble(TELEGRAPH)
				enemy.cry("attack")
			return toward * enemy.speed()
		1:
			if _left <= 0.0:
				_state = 2
				_left = float(enemy.data.get("open", SHELL_OPEN))
				_shot_done = false
				enemy.armored = false
			return Vector3.ZERO
		_:
			if not _shot_done and _left < float(enemy.data.get("open", SHELL_OPEN)) - 0.25:
				_shot_done = true
				enemy.shoot_pattern(String(enemy.data.get("pattern", "fan3")), {})
			if _left <= 0.0:
				_state = 0
				_left = enemy.rng.randf_range(float(SHELL_CLOSED[0]), float(SHELL_CLOSED[1]))
				enemy.armored = true
			return Vector3.ZERO
