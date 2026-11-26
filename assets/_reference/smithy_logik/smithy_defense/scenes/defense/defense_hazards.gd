class_name DefenseHazards
extends Node2D
## The region rules that happen on the field (defense.json themes[].rules), one node on the ground
## under the figures: poison puddles (`poison`: units standing in one lose part of their life every
## half second) and strikes from the sky (`strikes`: a red ring warns, then everything in it is hit,
## enemies and units; fire, lightning, meteor or dark only look different). The game calls `begin`
## at the first wave of every part, `step` every frame while fighting and `clear` when the run ends.
## Puddles and warning rings are drawn here in one _draw; bursts and beams go to DefenseFx.

## How often units in a puddle are hurt (seconds).
const POISON_TICK: float = 0.5
const POISON_COLOR := Color(0.45, 0.85, 0.25, 0.42)
const POISON_EDGE := Color(0.7, 1.0, 0.4, 0.6)
const WARN_COLOR := Color(1.0, 0.25, 0.15)
## Puddles and strikes land this far from the smithy (a strike without an enemy to aim at, too).
const NEAR := Vector2(40.0, 170.0)
## A strike aims at an enemy this often (else somewhere near the smithy).
const AIM_AT_ENEMY: float = 0.6
const KIND_COLORS: Dictionary[String, Color] = {"fire": Color(1.0, 0.55, 0.15), "lightning": Color(1.0, 0.95, 0.5),
		"meteor": Color(0.85, 0.9, 1.0), "dark": Color(0.7, 0.4, 1.0)}

## Particles, shake (set by the game).
var fx: DefenseFx

var _poison: Dictionary = {}
var _strikes: Dictionary = {}
## Hammer damage now: a strike hits enemies with a multiple of it.
var _hammer: int = 1
var _poison_timer: float = 0.0
var _strike_timer: float = 0.0
var _tick: float = 0.0
var _time: float = 0.0
## Each puddle: [position, seconds left, radius, dps]; each warning: [position, seconds left, warn time,
## radius, kind, hammer factor on enemies (0 = enemies safe), unit_part].
var _puddles: Array[Array] = []
var _warnings: Array[Array] = []
## Something was drawn last frame (one more redraw clears it).
var _drawn: bool = false


## A new part starts: its rules (themes[].rules) and the hammer's damage there.
func begin(rules: Dictionary, hammer_damage: int) -> void:
	_poison = rules.get("poison", {})
	_strikes = rules.get("strikes", {})
	_hammer = maxi(hammer_damage, 1)
	_poison_timer = float(_poison.get("every", 0.0)) * 0.5
	_strike_timer = float(_strikes.get("every", 0.0))


## The run is over: nothing lies on the field any more.
func clear() -> void:
	_poison = {}
	_hammer = 1
	_strikes = {}
	_puddles.clear()
	_warnings.clear()
	queue_redraw()


## Living puddles and warning rings (for tests).
func puddle_count() -> int:
	return _puddles.size()


func warning_count() -> int:
	return _warnings.size()


## One frame of the fight: new puddles and strikes, poison hurts, warnings run out and strike.
func step(delta: float, enemies: Array[DefenseEnemy], units: Array[DefenseUnit], smithy: Vector2, view: Rect2) -> void:
	_time += delta
	if not _poison.is_empty():
		_poison_timer -= delta
		if _poison_timer <= 0.0:
			_poison_timer = float(_poison.get("every", 5.0))
			add_puddle(_near_point(smithy, view), float(_poison.get("time", 6.0)), float(_poison.get("radius", 24.0)),
					float(_poison.get("dps", 0.1)))
	if not _strikes.is_empty():
		_strike_timer -= delta
		if _strike_timer <= 0.0:
			_strike_timer = float(_strikes.get("every", 4.0))
			var at: Vector2 = _near_point(smithy, view)
			if not enemies.is_empty() and randf() < AIM_AT_ENEMY:
				at = enemies[randi() % enemies.size()].global_position
			add_strike(at, float(_strikes.get("warn", 1.0)), float(_strikes.get("radius", 30.0)), String(_strikes.get("kind", "fire")),
					float(_strikes.get("hammer", 1.0)), float(_strikes.get("unit_part", 0.3)))
	for i in range(_puddles.size() - 1, -1, -1):
		_puddles[i][1] -= delta
		if _puddles[i][1] <= 0.0:
			_puddles.remove_at(i)
	_tick -= delta
	if _tick <= 0.0:
		_tick = POISON_TICK
		_hurt_in_puddles(units)
	for i in range(_warnings.size() - 1, -1, -1):
		_warnings[i][1] -= delta
		if _warnings[i][1] <= 0.0:
			var warning: Array = _warnings[i]
			_warnings.remove_at(i)
			_strike(warning, enemies, units)
	# Redraw while something lies there, and once more when the last one went.
	var showing: bool = not _puddles.is_empty() or not _warnings.is_empty()
	if showing or _drawn:
		queue_redraw()
	_drawn = showing


## A poison puddle at `at` for `seconds` (region rule or boss skill): units in it lose dps × life/s.
func add_puddle(at: Vector2, seconds: float, radius: float, dps: float) -> void:
	_puddles.append([at, seconds, radius, dps])


## A strike at `at` after `warn` seconds (region rule or boss skill): enemies in the circle take
## `hammer` × the hammer's damage (0 = enemies are safe, a boss's strike), units `unit_part` of their life.
func add_strike(at: Vector2, warn: float, radius: float, kind: String, hammer: float, unit_part: float) -> void:
	_warnings.append([at, warn, warn, radius, kind, hammer, unit_part])


## Units standing in a puddle lose its dps × their life per second (at least 1 a tick).
func _hurt_in_puddles(units: Array[DefenseUnit]) -> void:
	if _puddles.is_empty():
		return
	for unit: DefenseUnit in units.duplicate():
		if not unit.is_alive():
			continue
		for puddle: Array in _puddles:
			if unit.global_position.distance_to(puddle[0]) <= float(puddle[2]):
				unit.hit(maxi(int(round(float(unit.max_hp) * float(puddle[3]) * POISON_TICK)), 1))
				break


## A strike lands: every enemy in the circle takes its hammer factor × the hammer's damage, every
## unit its unit_part of its life; light, burst and shake by kind.
func _strike(warning: Array, enemies: Array[DefenseEnemy], units: Array[DefenseUnit]) -> void:
	var at: Vector2 = warning[0]
	var radius: float = float(warning[3])
	var kind: String = String(warning[4])
	var color: Color = KIND_COLORS.get(kind, Color.WHITE)
	if float(warning[5]) > 0.0:
		var damage: int = maxi(int(round(float(_hammer) * float(warning[5]))), 1)
		for enemy: DefenseEnemy in enemies.duplicate():
			if enemy.is_alive() and enemy.global_position.distance_to(at) <= radius:
				enemy.hit(damage)
	for unit: DefenseUnit in units.duplicate():
		if unit.is_alive() and unit.global_position.distance_to(at) <= radius:
			unit.hit(maxi(int(round(float(unit.max_hp) * float(warning[6]))), 1))
	if fx == null:
		return
	match kind:
		"lightning":
			fx.chain(PackedVector2Array([at + Vector2(randf_range(-25, 25), -200), at + Vector2(randf_range(-8, 8), -90), at]), color)
			AudioManager.play_sound("lightning_strike")
		_:
			fx.beam(at, color, 240.0, 0.5, radius * 0.8)
			AudioManager.play_sound("rock_break")
	fx.burst(at, color, 16, 130.0, 0.6, 3.0, 200.0, 50.0)
	fx.ring(at, radius, color, 0.35, 2.5)
	fx.dust(at, radius * 0.7, 8)
	fx.shake(2.5 if kind == "meteor" else 1.5, 0.2)


## A random point around the smithy inside the view.
func _near_point(smithy: Vector2, view: Rect2) -> Vector2:
	var point: Vector2 = smithy + Vector2.from_angle(randf() * TAU) * randf_range(NEAR.x, NEAR.y)
	return point.clamp(view.position, view.end) if view.has_area() else point


## Puddles (green, bubbling, fading at the end) and warning rings (red, filling up until they strike).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	for puddle: Array in _puddles:
		var at := Vector2(puddle[0].x, puddle[0].y / 0.55)
		var fade: float = clampf(float(puddle[1]), 0.0, 1.0)
		var radius: float = float(puddle[2])
		draw_circle(at, radius, Color(POISON_COLOR, POISON_COLOR.a * fade))
		draw_arc(at, radius, 0.0, TAU, 24, Color(POISON_EDGE, POISON_EDGE.a * fade), 1.5)
		for b in 3:
			var bubble: float = fposmod(_time * 0.8 + float(b) * 0.33, 1.0)
			draw_circle(at + Vector2(sin(float(b) * 2.1 + at.x) * radius * 0.5, cos(float(b) * 1.7) * radius * 0.4),
					1.5 + bubble * 1.5, Color(POISON_EDGE, (1.0 - bubble) * fade))
	for warning: Array in _warnings:
		var strike_radius: float = float(warning[3])
		var at := Vector2(warning[0].x, warning[0].y / 0.55)
		var done: float = 1.0 - clampf(float(warning[1]) / maxf(float(warning[2]), 0.01), 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_time * 18.0)
		draw_circle(at, strike_radius * done, Color(WARN_COLOR, 0.18 + 0.12 * done))
		draw_arc(at, strike_radius, 0.0, TAU, 24, Color(WARN_COLOR, 0.5 + 0.4 * pulse), 2.0)
	draw_set_transform(Vector2.ZERO)
