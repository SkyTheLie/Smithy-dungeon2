class_name DefenseWindBall
extends Node2D
## The bolt of a ranged unit (a small glowing ball in the unit's colour): flies to its enemy and
## hits it on arrival; a kill counts for the shooter. If the enemy dies on the way, it flies on to
## the last place it saw and puffs out there.
## With `fx` set it leaves a trail by its shooter's element: fire embers, ice frost, poison
## bubbles, lightning sparks, otherwise small dots in its colour.

## A fireball (area > 0) lands: the game hits everything in `area` around `at`.
signal landed(ball: DefenseWindBall, at: Vector2)

const HIT_DISTANCE: float = 4.0
const RADIUS: float = 3.0
## Seconds between two trail particles (a skill ball leaves twice as many).
const TRAIL_EVERY: float = 0.035

var damage: int = 1
var speed: float = 140.0
var color: Color = Color.WHITE
var enemy: DefenseEnemy = null
var shooter: DefenseUnit = null
var _last_seen: Vector2 = Vector2.ZERO
## > 0: a skill ball (fireball): bigger, and on landing an area hit instead of one hit.
var area: float = 0.0
var skill_name: String = ""
## Where the trail goes (set by the game; null = no trail).
var fx: DefenseFx = null
var element: String = ""
var _trail_timer: float = 0.0


func launch(from: DefenseUnit, at: DefenseEnemy, fly_speed: float) -> void:
	shooter = from
	position = from.shot_origin()
	enemy = at
	damage = from.damage
	speed = fly_speed
	color = Color.from_string(String(from.stats.get("bolt", "#ffffff")), Color.WHITE)
	element = from.element
	_last_seen = at.global_position + DefenseUnit.SHOT_OFFSET / 2.0


## Turns the bolt into a skill ball (call after launch).
func make_skill(hit_radius: float, tint: Color, damage_amount: int, label: String) -> void:
	area = hit_radius
	color = tint
	damage = damage_amount
	skill_name = label
	scale = Vector2(2.2, 2.2)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 1.5, Color(color, 0.35))
	draw_circle(Vector2.ZERO, RADIUS, color)


func _process(delta: float) -> void:
	if enemy != null and enemy.is_alive():
		_last_seen = enemy.global_position + DefenseUnit.SHOT_OFFSET / 2.0
	_trail(delta)
	var to_goal: Vector2 = _last_seen - position
	var step: float = speed * delta
	if to_goal.length() > maxf(step, HIT_DISTANCE):
		position += to_goal.normalized() * step
		return
	if area > 0.0:
		landed.emit(self, position)
	elif enemy != null and enemy.is_alive() and enemy.hit(damage) and is_instance_valid(shooter):
		shooter.credit_kill()
	queue_free()


func _trail(delta: float) -> void:
	if fx == null:
		return
	_trail_timer -= delta * (2.0 if area > 0.0 else 1.0)
	if _trail_timer > 0.0:
		return
	_trail_timer = TRAIL_EVERY
	var size: float = 2.0 * scale.x
	match element:
		"fire":
			fx.particle(position, Vector2(randf_range(-12, 12), randf_range(-25, -5)), Color(1.0, randf_range(0.4, 0.75), 0.15), 0.4, size, 40.0)
		"ice", "wind":
			fx.particle(position, Vector2(randf_range(-8, 8), randf_range(2, 10)), Color(0.85, 0.95, 1.0, 0.9), 0.5, size * 0.8, 15.0)
		"poison":
			fx.particle(position, Vector2(randf_range(-6, 6), -12), Color(0.55, 1.0, 0.35, 0.8), 0.6, size, -20.0)
		"lightning":
			fx.particle(position, Vector2.from_angle(randf() * TAU) * 45.0, Color(1.0, 0.95, 0.5), 0.15, size * 0.7, 0.0)
		_:
			fx.particle(position, Vector2.ZERO, Color(color, 0.7), 0.25, size * 0.8, 0.0)
