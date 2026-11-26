class_name DefenseEnemy
extends Node2D
## One enemy of the forge defense: walks from the edge to the smithy and hits it every
## `attack_interval` seconds (signal `attacked`). If the game gives it a `target_unit` (a unit
## close by) it fights that unit instead until the unit is dead. Sneaky enemies (half see-through)
## ignore units until the hammer strikes them (`reveal`), then they are normal enemies; elites are bigger, shiny ones glow gold and pay more.
## Life is never shown, except an elite's bar in the HUD. Hits come in through `hit`; at 0 it plays
## its death animation (signal `died`). Sheets face left (FEHLERKLASSEN 24); walking right flips.
## A hit flashes it pure white (shared material DefenseFlash: modulate above 1 = white), the hammer
## knocks it back (`knock`); a soft shadow lies under its feet (drawn once).
## Kept cheap for 20–40 at once: no physics, no searching; the game does the targeting.

signal attacked(enemy: DefenseEnemy)
signal died(enemy: DefenseEnemy)

enum State { WALK, ATTACK, DEAD }

const CORPSE_TIME: float = 0.6
## Reach without a range in the numbers; the smithy's reach grows by what a range adds to it.
const BASE_REACH: float = 14.0
## It only walks again once the goal is this much further than its reach (no jitter).
const REACH_SLACK: float = 4.0
const ELITE_SCALE: float = 1.5
const SNEAKY_ALPHA: float = 0.35
const SHINY_TINT := Color(1.5, 1.25, 0.45)
const FLASH_MATERIAL: Material = preload("res://scenes/defense/defense_flash_material.tres")
## Modulate of a hit: all channels above 1 = pure white (defense_flash.gdshader).
const FLASH_TINT := Color(2.0, 2.0, 2.0)
const FLASH_TIME: float = 0.12
## Knock-back slows down by this many px/s each second; bosses take none (else steady hammering
## kept them from ever reaching a unit).
const KNOCK_FRICTION: float = 600.0
const ELITE_KNOCK: float = 0.0
const SHADOW := Color(0, 0, 0, 0.28)
const SHADOW_SIZE := Vector2(9.0, 3.5)

## The numbers of DefenseRun.enemy_stats (id, name, hp, damage, coins, sneaky, elite, shiny ...).
var stats: Dictionary = {}
var hp: int = 1
var max_hp: int = 1
var damage: int = 1
var speed: float = 20.0
var attack_interval: float = 1.0
var sneaky: bool = false
var elite: bool = false
var target: Vector2 = Vector2.ZERO
var reach: float = 40.0
## How close it must be to hit a unit (enemy range: it hits from a few pixels away).
var unit_reach: float = BASE_REACH
## A unit it fights instead of the smithy (set by the game), null = the smithy.
var target_unit: DefenseUnit = null
var state: State = State.WALK

var _attack_timer: float = 0.0
## Its own side around its target (set when it appears, from where it came, a bit random):
## enemies surround a unit or the smithy instead of all walking onto one spot.
var _side: Vector2 = Vector2.RIGHT
## How much of the reach it stands off its target on its side.
const STAND_PART: float = 0.8
var _tint: Color = Color.WHITE
## The hammer may knock it only inside this rectangle (the field the camera shows, set by the game);
## empty = anywhere. Outside it (just come in) a knock does not push it further out.
var field: Rect2 = Rect2()
## Knock-back speed (px/s), fades with KNOCK_FRICTION.
var _knock: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $Sprite


func setup(frames: SpriteFrames, numbers: Dictionary, goal: Vector2, goal_reach: float) -> void:
	stats = numbers
	max_hp = maxi(int(numbers.get("hp", 1)), 1)
	hp = max_hp
	damage = int(numbers.get("damage", 1))
	speed = float(numbers.get("speed", 20.0))
	attack_interval = maxf(float(numbers.get("attack_interval", 1.0)), 0.05)
	sneaky = bool(numbers.get("sneaky", false))
	elite = bool(numbers.get("elite", false))
	target = goal
	unit_reach = float(numbers.get("range", BASE_REACH))
	reach = (goal_reach + unit_reach - BASE_REACH) * (1.3 if elite else 1.0)
	$Sprite.sprite_frames = frames
	$Sprite.material = FLASH_MATERIAL
	if elite:
		scale = Vector2(ELITE_SCALE, ELITE_SCALE)
	_tint = Color.from_string(String(numbers.get("tint", "#ffffff")), Color.WHITE)
	if bool(numbers.get("shiny", false)):
		_tint = SHINY_TINT
	if sneaky:
		_tint.a = SNEAKY_ALPHA
	$Sprite.modulate = _tint


func _ready() -> void:
	var from_target: Vector2 = global_position - target
	_side = (from_target.normalized() if from_target.length() > 1.0 else Vector2.RIGHT).rotated(randf_range(-0.7, 0.7))
	_sprite.play(&"walk")
	_face(target.x > global_position.x)


func _process(delta: float) -> void:
	if _knock != Vector2.ZERO:
		if field.has_area() and not field.has_point(global_position):
			_knock = Vector2.ZERO
		else:
			global_position += _knock * delta
			if field.has_area():
				global_position = global_position.clamp(field.position, field.end)
			_knock = _knock.move_toward(Vector2.ZERO, KNOCK_FRICTION * delta)
	if state == State.DEAD:
		return
	if target_unit != null and not target_unit.is_alive():
		target_unit = null
	var goal: Vector2 = target_unit.global_position if target_unit else target
	var goal_reach: float = unit_reach if target_unit else reach
	var to_goal: Vector2 = goal - global_position
	var distance: float = to_goal.length()
	if state == State.WALK:
		if distance <= goal_reach:
			# The timer keeps what it had: a hammer knock that pushes it out of reach for a moment
			# must not start its attack over again (else steady hammering means it never hits).
			state = State.ATTACK
			_sprite.play(&"attack")
			return
		# Walk to its own spot on its side of the target, not onto the target itself.
		var to_spot: Vector2 = goal + _side * goal_reach * STAND_PART - global_position
		var step: Vector2 = to_spot.normalized() * speed * delta if to_spot.length() > 1.0 else to_goal.normalized() * speed * delta
		global_position += step
		_face(to_goal.x > 0.0)
		return
	if distance > goal_reach + REACH_SLACK:
		state = State.WALK
		_sprite.play(&"walk")
		return
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer -= attack_interval
		_face(to_goal.x > 0.0)
		_sprite.frame = 0
		_sprite.play(&"attack")
		if target_unit:
			target_unit.hit(damage)
		else:
			attacked.emit(self)


## A push (hammer): it slides `speed` px/s along `direction` and slows down; bosses stand firm.
func knock(direction: Vector2, speed: float) -> void:
	if not is_alive():
		return
	_knock = direction.normalized() * speed * (ELITE_KNOCK if elite else 1.0)


## Soft shadow under the feet (drawn once, under the sprite).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SHADOW_SIZE.y / SHADOW_SIZE.x))
	draw_circle(Vector2.ZERO, SHADOW_SIZE.x, SHADOW)
	draw_set_transform(Vector2.ZERO)


## Looks right or left; most sheets look left, `faces_right` ones the other way (FEHLERKLASSEN 24).
func _face(right: bool) -> void:
	_sprite.flip_h = right != bool(stats.get("faces_right", false))


func is_alive() -> bool:
	return state != State.DEAD


## Units may target it (not sneaky, alive).
func is_visible_to_units() -> bool:
	return is_alive() and not sneaky


## The hammer struck it: a sneaky enemy is seen from now on (fully visible, units fight it, and it
## goes for the units first like everyone else instead of only the smithy).
func reveal() -> void:
	if not sneaky or not is_alive():
		return
	sneaky = false
	_tint.a = 1.0
	_sprite.modulate.a = 1.0


## A hit (hammer or unit). Returns true if this hit killed it.
func hit(amount: int) -> bool:
	if not is_alive() or amount <= 0:
		return false
	hp -= amount
	_sprite.modulate = Color(FLASH_TINT, _tint.a)
	create_tween().tween_property(_sprite, "modulate", _tint, FLASH_TIME)
	if hp > 0:
		return false
	state = State.DEAD
	target_unit = null
	_sprite.play(&"death")
	died.emit(self)
	var fade := create_tween()
	fade.tween_interval(CORPSE_TIME)
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(queue_free)
	return true
