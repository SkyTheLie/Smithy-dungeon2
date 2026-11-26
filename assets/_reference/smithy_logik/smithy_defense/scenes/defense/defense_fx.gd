class_name DefenseFx
extends Node2D
## All small world effects of the forge defense in one node, cheap for many at once: pixel
## particles (splinters, dust, sparks, smoke, embers, shards), rings, light columns, lightning
## chains and jumping numbers, plus the camera shake. Particles and numbers live in fixed-size
## arrays (the oldest is reused when full) and are drawn in one `_draw`; nothing is created per
## frame (FEHLERKLASSEN 12). Only pictures: no rules, no damage here.

const MAX_PARTICLES: int = 700
const MAX_NUMBERS: int = 60
const NUMBER_FONT_SIZE: int = 22
const BIG_FONT_SIZE: int = 34
## Numbers jump up, then fall back a little.
const NUMBER_JUMP: float = 70.0
const NUMBER_GRAVITY: float = 150.0
const NUMBER_TIME: float = 0.9
## A number is this much bigger right after it appears.
const NUMBER_POP: float = 1.6
const OUTLINE := Color(0.13, 0.075, 0.12)
const DUST := Color(0.72, 0.6, 0.45)

enum Shape { RING, BEAM, CHAIN }

## The camera that `shake` moves (set by the game).
var camera: Camera2D = null

var _p_pos := PackedVector2Array()
var _p_vel := PackedVector2Array()
var _p_life := PackedFloat32Array()
var _p_time := PackedFloat32Array()
var _p_size := PackedFloat32Array()
var _p_gravity := PackedFloat32Array()
var _p_color := PackedColorArray()
var _p_next: int = 0

var _n_pos := PackedVector2Array()
var _n_vel := PackedVector2Array()
var _n_life := PackedFloat32Array()
var _n_size := PackedInt32Array()
var _n_color := PackedColorArray()
var _n_text := PackedStringArray()
var _n_next: int = 0

## Rings, beams and chains: few at a time, one small dictionary each (made when it starts).
var _shapes: Array[Dictionary] = []
var _font: Font = null
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.0
## Something was on screen last frame: draw once more after it all ended (clears the picture).
var _drawn: bool = false


func _ready() -> void:
	z_index = 7
	_p_pos.resize(MAX_PARTICLES)
	_p_vel.resize(MAX_PARTICLES)
	_p_life.resize(MAX_PARTICLES)
	_p_time.resize(MAX_PARTICLES)
	_p_size.resize(MAX_PARTICLES)
	_p_gravity.resize(MAX_PARTICLES)
	_p_color.resize(MAX_PARTICLES)
	_n_pos.resize(MAX_NUMBERS)
	_n_vel.resize(MAX_NUMBERS)
	_n_life.resize(MAX_NUMBERS)
	_n_size.resize(MAX_NUMBERS)
	_n_color.resize(MAX_NUMBERS)
	_n_text.resize(MAX_NUMBERS)
	var theme: Theme = ThemeDB.get_project_theme()
	_font = theme.default_font if theme != null and theme.default_font != null else ThemeDB.fallback_font


# --- Starting effects ----------------------------------------------------------------

## One square particle: flies with `velocity`, falls with `gravity` (negative = rises), shrinks
## and fades over `life` seconds.
func particle(at: Vector2, velocity: Vector2, color: Color, life: float, size: float, gravity: float = 0.0) -> void:
	var i: int = _p_next
	_p_next = (_p_next + 1) % MAX_PARTICLES
	_p_pos[i] = at
	_p_vel[i] = velocity
	_p_color[i] = color
	_p_life[i] = life
	_p_time[i] = life
	_p_size[i] = size
	_p_gravity[i] = gravity


## `count` particles in all directions (speed varies 30–100 %), `up` lifts them all a bit.
func burst(at: Vector2, color: Color, count: int, speed: float, life: float, size: float,
		gravity: float = 200.0, up: float = 0.0) -> void:
	for i in count:
		var velocity: Vector2 = Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0) + Vector2(0, -up)
		particle(at, velocity, color.lightened(randf_range(-0.15, 0.15)), life * randf_range(0.7, 1.1), size, gravity)


## An enemy bursts into pixel splinters of its colour.
func splinters(at: Vector2, color: Color, big: bool = false) -> void:
	burst(at + Vector2(0, -14), color, 10 if big else 6, 110.0 if big else 80.0, 0.55, 4.0 if big else 3.0, 320.0, 70.0)


## Dust thrown out flat along the ground (hammer, landing, collapse).
func dust(at: Vector2, radius: float, count: int = 10) -> void:
	for i in count:
		var direction: Vector2 = Vector2.from_angle(randf() * TAU)
		particle(at + direction * radius * 0.4, Vector2(direction.x, direction.y * 0.45) * randf_range(40.0, 90.0),
				Color(DUST, 0.8), randf_range(0.35, 0.6), randf_range(3.0, 5.0), -15.0)


## A ring that grows to `radius` and fades; `rise` lifts it while it grows (level up).
func ring(at: Vector2, radius: float, color: Color, time: float = 0.4, width: float = 2.0, rise: float = 0.0) -> void:
	_shapes.append({"kind": Shape.RING, "at": at, "radius": radius, "color": color, "time": time, "life": time,
			"width": width, "rise": rise})


## A column of light from `at` upwards (crystal breaks, relic falls).
func beam(at: Vector2, color: Color, height: float = 220.0, time: float = 0.8, width: float = 22.0) -> void:
	_shapes.append({"kind": Shape.BEAM, "at": at, "radius": height, "color": color, "time": time, "life": time,
			"width": width, "rise": 0.0})


## A jagged lightning line through `points` (from the sky to the target, then on to the others).
func chain(points: PackedVector2Array, color: Color, time: float = 0.3) -> void:
	var jagged := PackedVector2Array()
	for i in points.size() - 1:
		var from: Vector2 = points[i]
		var to: Vector2 = points[i + 1]
		var side: Vector2 = (to - from).orthogonal().normalized()
		jagged.append(from)
		for step in range(1, 5):
			jagged.append(from.lerp(to, step / 5.0) + side * randf_range(-7.0, 7.0))
	jagged.append(points[points.size() - 1])
	_shapes.append({"kind": Shape.CHAIN, "points": jagged, "color": color, "time": time, "life": time,
			"width": 2.0, "rise": 0.0, "at": Vector2.ZERO, "radius": 0.0})


## A number (damage, combo) that pops up, jumps and falls; `big` for crits and combos.
func number(at: Vector2, text: String, color: Color, big: bool = false) -> void:
	var i: int = _n_next
	_n_next = (_n_next + 1) % MAX_NUMBERS
	_n_pos[i] = at + Vector2(randf_range(-6.0, 6.0), 0)
	_n_vel[i] = Vector2(randf_range(-18.0, 18.0), -NUMBER_JUMP * (1.3 if big else 1.0))
	_n_life[i] = NUMBER_TIME * (1.4 if big else 1.0)
	_n_size[i] = BIG_FONT_SIZE if big else NUMBER_FONT_SIZE
	_n_color[i] = color
	_n_text[i] = text


## The camera shakes `strength` px, calming down over `time` seconds. A weaker shake never
## cuts a stronger one short.
func shake(strength: float, time: float) -> void:
	if _shake_time > 0.0 and strength < _shake_strength * (_shake_time / _shake_total):
		return
	_shake_strength = strength
	_shake_time = time
	_shake_total = time


## Effects still running (for tests).
func is_busy() -> bool:
	return _drawn


# --- Running ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	var busy: bool = false
	for i in MAX_PARTICLES:
		if _p_life[i] <= 0.0:
			continue
		_p_life[i] -= delta
		var velocity: Vector2 = _p_vel[i] + Vector2(0, _p_gravity[i] * delta)
		_p_vel[i] = velocity
		_p_pos[i] += velocity * delta
		busy = true
	for i in MAX_NUMBERS:
		if _n_life[i] <= 0.0:
			continue
		_n_life[i] -= delta
		var jump: Vector2 = _n_vel[i] + Vector2(0, NUMBER_GRAVITY * delta)
		_n_vel[i] = jump
		_n_pos[i] += jump * delta
		busy = true
	for i in range(_shapes.size() - 1, -1, -1):
		_shapes[i].life = float(_shapes[i].life) - delta
		if float(_shapes[i].life) <= 0.0:
			_shapes.remove_at(i)
	busy = busy or not _shapes.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy
	_update_shake(delta)


func _update_shake(delta: float) -> void:
	if camera == null:
		return
	# Standing still (new unit, opened chest: time 0) the shake would never calm down and jump every
	# frame: the camera rests until time runs again.
	if _shake_time <= 0.0 or Engine.time_scale <= 0.0:
		if camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO
		return
	_shake_time -= delta
	var strength: float = _shake_strength * maxf(_shake_time / _shake_total, 0.0)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength


func _draw() -> void:
	for shape: Dictionary in _shapes:
		var part: float = 1.0 - float(shape.life) / float(shape.time)
		var color: Color = shape.color
		match int(shape.kind):
			Shape.RING:
				var at: Vector2 = Vector2(shape.at) + Vector2(0, -float(shape.rise) * part)
				draw_arc(at, float(shape.radius) * (0.25 + 0.75 * part), 0.0, TAU, 28, Color(color, color.a * (1.0 - part)), float(shape.width))
			Shape.BEAM:
				var width: float = float(shape.width) * (1.0 - part * 0.7)
				var height: float = float(shape.radius)
				var at: Vector2 = shape.at
				draw_rect(Rect2(at.x - width / 2.0, at.y - height, width, height), Color(color, 0.35 * (1.0 - part)))
				draw_rect(Rect2(at.x - width / 6.0, at.y - height, width / 3.0, height), Color(Color.WHITE, 0.6 * (1.0 - part)))
			Shape.CHAIN:
				draw_polyline(shape.points, Color(color, 0.5 * (1.0 - part)), float(shape.width) + 3.0)
				draw_polyline(shape.points, Color(Color.WHITE, 1.0 - part), float(shape.width))
	for i in MAX_PARTICLES:
		if _p_life[i] <= 0.0:
			continue
		var left: float = _p_life[i] / _p_time[i]
		var size: float = _p_size[i] * (0.4 + 0.6 * left)
		var color: Color = _p_color[i]
		draw_rect(Rect2(_p_pos[i] - Vector2(size, size) / 2.0, Vector2(size, size)), Color(color, color.a * minf(left * 1.5, 1.0)))
	if _font == null:
		return
	for i in MAX_NUMBERS:
		if _n_life[i] <= 0.0:
			continue
		var age: float = NUMBER_TIME - _n_life[i]
		var size: int = int(float(_n_size[i]) * lerpf(NUMBER_POP, 1.0, clampf(age / 0.15, 0.0, 1.0)))
		var width: float = _font.get_string_size(_n_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at: Vector2 = _n_pos[i] - Vector2(width / 2.0, 0)
		var alpha: float = clampf(_n_life[i] / 0.3, 0.0, 1.0)
		draw_string_outline(_font, at, _n_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(OUTLINE, alpha))
		draw_string(_font, at, _n_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_n_color[i], alpha))
