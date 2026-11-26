class_name DefenseUiFx
extends Control
## Small particle effects for the forge defense window, drawn over (or under) its content without
## taking any clicks: `embers` = glowing embers drifting up slowly (forge glow behind the content),
## `twinkle` = a few stars blinking on a card (expensive crystals), `confetti` = a burst of
## coloured bits (new best). Fixed-size arrays, nothing made while it runs (FEHLERKLASSEN 12);
## runs only while visible.

const MAX_BITS: int = 120
const EMBERS: int = 26
const TWINKLES: int = 4
const CONFETTI_COLORS: Array[Color] = [Color(1, 0.85, 0.3), Color(1, 0.45, 0.35), Color(0.55, 0.9, 1),
		Color(0.6, 1, 0.5), Color(0.8, 0.6, 1)]

var embers: bool = false
var twinkle: bool = false

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _time_total := PackedFloat32Array()
var _color := PackedColorArray()
var _next: int = 0
var _time: float = 0.0
var _phase := PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos.resize(MAX_BITS)
	_vel.resize(MAX_BITS)
	_life.resize(MAX_BITS)
	_time_total.resize(MAX_BITS)
	_color.resize(MAX_BITS)
	_phase.resize(TWINKLES * 3)
	for i in _phase.size():
		_phase[i] = randf()


## A burst of confetti from `at` (local position), flying up and falling down.
func confetti(at: Vector2, count: int = 50) -> void:
	for i in count:
		_add(at, Vector2(randf_range(-140, 140), randf_range(-220, -80)), CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()],
				randf_range(1.2, 2.0))


func _add(at: Vector2, velocity: Vector2, color: Color, life: float) -> void:
	var i: int = _next
	_next = (_next + 1) % MAX_BITS
	_pos[i] = at
	_vel[i] = velocity
	_color[i] = color
	_life[i] = life
	_time_total[i] = life


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	if embers and randf() < delta * EMBERS / 3.0:
		_add(Vector2(randf() * size.x, size.y + 2.0), Vector2(randf_range(-6, 6), randf_range(-28, -12)),
				Color(1.0, randf_range(0.35, 0.65), 0.15, 0.6), randf_range(3.0, 6.0))
	for i in MAX_BITS:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var velocity: Vector2 = _vel[i]
		if _color[i].a >= 0.99:
			velocity.y += 260.0 * delta
		velocity.x += sin(_time * 3.0 + float(i)) * 8.0 * delta
		_vel[i] = velocity
		_pos[i] += velocity * delta
	queue_redraw()


func _draw() -> void:
	for i in MAX_BITS:
		if _life[i] <= 0.0:
			continue
		var left: float = _life[i] / _time_total[i]
		var bit: Vector2 = Vector2(2, 2) if _color[i].a < 0.99 else Vector2(3, 2)
		draw_rect(Rect2(_pos[i], bit), Color(_color[i], _color[i].a * minf(left * 2.0, 1.0)))
	if twinkle:
		for i in TWINKLES:
			var blink: float = maxf(sin(_time * 2.5 + _phase[i * 3] * TAU), 0.0)
			if blink <= 0.0:
				continue
			var at := Vector2(_phase[i * 3 + 1] * size.x, _phase[i * 3 + 2] * size.y)
			var arm: float = 1.0 + blink * 3.0
			var color := Color(1, 1, 0.85, blink)
			draw_line(at - Vector2(arm, 0), at + Vector2(arm, 0), color, 1.0)
			draw_line(at - Vector2(0, arm), at + Vector2(0, arm), color, 1.0)
