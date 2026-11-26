class_name LevelUpGlow
extends Node2D
## Short light effect on the player when he reaches a new level: a golden ring spreads out and
## fades, small sparks rise around the figure. Removes itself when done (Player._on_leveled_up).

const DURATION: float = 1.3
const RING_COLOR: Color = Color(1.0, 0.86, 0.4)
const SPARK_COLORS: Array[Color] = [Color(1.0, 0.95, 0.6), Color(1.0, 0.8, 0.35), Color(1.0, 1.0, 1.0)]
const SPARK_COUNT: int = 10
const RING_MAX_RADIUS: float = 26.0

var _time: float = 0.0
## Per spark: start offset (x), rising speed, size, colour index, delay.
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	z_index = 10
	for i in SPARK_COUNT:
		_sparks.append({
			"x": randf_range(-12.0, 12.0),
			"y": randf_range(-4.0, 10.0),
			"speed": randf_range(18.0, 34.0),
			"size": 1.0 if randf() < 0.6 else 2.0,
			"color": SPARK_COLORS[i % SPARK_COLORS.size()],
			"delay": randf_range(0.0, 0.4),
		})


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = _time / DURATION
	# Ring: grows quickly, then fades.
	var ring: float = minf(progress * 2.0, 1.0)
	var ring_color := RING_COLOR
	ring_color.a = (1.0 - ring) * 0.9
	draw_arc(Vector2.ZERO, 4.0 + ring * RING_MAX_RADIUS, 0.0, TAU, 32, ring_color, 2.0)
	# Soft glow behind the figure.
	var glow := RING_COLOR
	glow.a = 0.25 * (1.0 - progress)
	draw_circle(Vector2.ZERO, 14.0, glow)
	# Sparks: rise and fade, pixel squares.
	for spark in _sparks:
		var t: float = _time - float(spark["delay"])
		if t <= 0.0:
			continue
		var color: Color = spark["color"]
		color.a = clampf(1.0 - t / (DURATION - float(spark["delay"])), 0.0, 1.0)
		var size: float = spark["size"]
		var pos := Vector2(float(spark["x"]), float(spark["y"]) - t * float(spark["speed"])).round()
		draw_rect(Rect2(pos, Vector2(size, size)), color)
