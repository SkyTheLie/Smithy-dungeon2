class_name CrystalArcs
extends Node2D
## Crackling lightning from a floating crystal: every few hundredths of a second new jagged bolts
## leap from this node (the crystal's middle) in an outward bulge down to `targets` (floor points,
## local), with a spark where they hit. Drawn in pixel steps (dark blue rim, light blue, white
## core). `redirect_to` bends them all over to one point (the sanctum: the copper rod draws the
## lightning away), `fade_out` lets them flicker out. The crystal keeps floating either way.

## Where the bolts end (local coordinates, e.g. the floor left and right of the altar).
@export var targets: PackedVector2Array = PackedVector2Array([Vector2(-44, 96), Vector2(44, 96)])
## How far the bolts bow outwards (pixels, away from the middle).
@export var bulge: float = 36.0
## Seconds between new shapes (random in between).
@export var min_interval: float = 0.06
@export var max_interval: float = 0.14
## The floating crystal sprite; it bobs gently and the bolts start where it is.
@export var crystal_sprite: NodePath
## How far the crystal bobs (pixels) and how long one up and down takes (seconds).
@export var bob_height: float = 2.0
@export var bob_period: float = 2.4
## Story flag from which there is no lightning any more (when the map is entered); while the
## player watches, the cutscene redirects and fades the bolts instead.
@export var off_flag: String = ""

const RIM: Color = Color(0.1, 0.16, 0.5)
const MID: Color = Color(0.25, 0.68, 1.0)
const CORE: Color = Color(0.92, 0.98, 1.0)
## Points per bolt (more = more zigzag).
const STEPS: int = 8
## Sideways jitter of the zigzag (pixels).
const JITTER: float = 6.0

var _bolts: Array[PackedVector2Array] = []
var _sparks: Array[Vector2] = []
var _timer: float = 0.0
var _time: float = 0.0
var _crystal: Node2D
var _crystal_home: Vector2
## Gone out: only the crystal still floats.
var _off: bool = false
## Bent over to one point (no side rests then).
var _redirected: bool = false


func _ready() -> void:
	_crystal = get_node_or_null(crystal_sprite) as Node2D
	if _crystal:
		_crystal_home = _crystal.position
	_time = randf() * bob_period
	_off = not off_flag.is_empty() and GameState.story.has_flag(off_flag)
	_reshape()


func _process(delta: float) -> void:
	_time += delta
	if _crystal:
		_crystal.position = _crystal_home + Vector2(0, roundf(sin(_time * TAU / bob_period) * bob_height))
	_timer -= delta
	if _timer <= 0.0 and not _off:
		_timer = randf_range(min_interval, max_interval)
		_reshape()
		queue_redraw()


## Whether bolts are crackling right now.
func is_crackling() -> bool:
	return not _off


## Bends all bolts over to `point` (global) within `seconds`: their ends sweep across to it.
func redirect_to(point: Vector2, seconds: float = 0.5) -> void:
	_redirected = true
	var from: PackedVector2Array = targets.duplicate()
	var to: Vector2 = to_local(point)
	var start_bulge: float = bulge
	var sweep := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sweep.tween_method(func(t: float) -> void:
		for i in from.size():
			targets[i] = from[i].lerp(to, t)
		bulge = lerpf(start_bulge, start_bulge * 0.5, t)
		_reshape()
		queue_redraw(), 0.0, 1.0, seconds)
	await sweep.finished


## Flickers a few times and goes out; the crystal keeps floating.
func fade_out(seconds: float = 0.6) -> void:
	var fade := create_tween()
	for i in 3:
		fade.tween_property(self, "modulate:a", 0.25, seconds / 8.0)
		fade.tween_property(self, "modulate:a", 1.0, seconds / 8.0)
	fade.tween_property(self, "modulate:a", 0.0, seconds / 4.0)
	fade.tween_callback(func() -> void:
		_off = true
		modulate.a = 1.0
		queue_redraw())
	await fade.finished


func _start() -> Vector2:
	return (_crystal.position - _crystal_home) if _crystal else Vector2.ZERO


func _reshape() -> void:
	_bolts.clear()
	_sparks.clear()
	var start: Vector2 = _start()
	for target in targets:
		# Now and then one side rests for a moment, so it crackles instead of humming.
		if not _redirected and randf() < 0.15:
			continue
		var end: Vector2 = target + Vector2(randf_range(-4, 4), randf_range(-2, 2))
		var side: float = signf(end.x) if end.x != 0.0 else 1.0
		var control: Vector2 = (start + end) / 2.0 + Vector2(side * bulge * randf_range(0.7, 1.2), -bulge * 0.6)
		var points := PackedVector2Array()
		for i in STEPS + 1:
			var t: float = float(i) / STEPS
			var p: Vector2 = start.lerp(control, t).lerp(control.lerp(end, t), t)
			if i > 0 and i < STEPS:
				p += Vector2(randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER) * 0.5)
			points.append(p.round())
		_bolts.append(points)
		_sparks.append(end.round())
		# A short side branch from somewhere in the middle.
		if randf() < 0.6:
			var from: Vector2 = points[randi_range(3, STEPS - 3)]
			var branch := PackedVector2Array([from])
			var dir := Vector2(side * randf_range(4, 9), randf_range(2, 7))
			for k in 2:
				branch.append((branch[-1] + dir + Vector2(randf_range(-2, 2), randf_range(-2, 2))).round())
			_bolts.append(branch)


func _draw() -> void:
	if _off:
		return
	for bolt in _bolts:
		draw_polyline(bolt, RIM, 6.0)
	for bolt in _bolts:
		draw_polyline(bolt, MID, 4.0)
	for bolt in _bolts:
		draw_polyline(bolt, CORE, 2.0)
	for spark in _sparks:
		draw_rect(Rect2(spark - Vector2(2, 1), Vector2(5, 3)), MID)
		draw_rect(Rect2(spark - Vector2(1, 1), Vector2(3, 2)), CORE)
		for k in 3:
			var dot: Vector2 = spark + Vector2(randf_range(-7, 7), randf_range(-5, 1)).round()
			draw_rect(Rect2(dot, Vector2(1, 1)), CORE if k == 0 else MID)
	# The glow right at the crystal.
	draw_circle(_start(), 3.0, Color(MID, 0.5))
