class_name DefenseUnit
extends Node2D
## A unit on the player's side (called by a crystal): flies/walks from its crystal to its guard
## post around the smithy. The game gives it a `target` enemy. Melee units (range < 30) run to it
## and hit; ranged units stay and shoot (signal `shot`, the game makes the bolt). Every
## `level_kills` × level kills it levels up (stronger, not healed, signal `leveled_up`). Enemies close
## by fight it (`hit`); at 0 life it dies (signal `died`). A small life bar shows once hurt.
## Giants are bigger, shiny ones glow gold. Sheets face left like the enemies; a unit of the player
## looks right (FEHLERKLASSEN 24) and turns to what it fights.
## Looks: a soft shadow under its feet; from R3 a glow in its rarity colour under it, R5 also
## sparks rising; a hit flashes it white (DefenseFlash material); out of a crystal it drops in
## from above (`drop_in`). `element` (its crystal's) colours the trail of its bolts.

signal shot(unit: DefenseUnit, enemy: DefenseEnemy)
## Its skill (stats.skill) is ready; the game picks the target and calls `use_skill` or `delay_skill`.
signal skill_ready(unit: DefenseUnit)
signal leveled_up(unit: DefenseUnit)
signal died(unit: DefenseUnit)

enum State { MOVE, GUARD, DEAD }

const CORPSE_TIME: float = 0.6
const SHOT_OFFSET := Vector2(0, -18)
const MELEE_RANGE: float = 30.0
const REACH_SLACK: float = 4.0
const GIANT_SCALE: float = 1.35
const SHINY_TINT := Color(1.5, 1.25, 0.45)
const BAR_WIDTH: float = 20.0
const BAR_Y: float = -38.0
const FLASH_MATERIAL: Material = preload("res://scenes/defense/defense_flash_material.tres")
const SHADOW := Color(0, 0, 0, 0.28)
const SHADOW_SIZE := Vector2(9.0, 3.5)
## From this rarity on (R3) it glows under its feet; from SPARK_RANK (R5) sparks rise.
const GLOW_RANK: int = 3
const SPARK_RANK: int = 5
const SPARKS: int = 5

## DefenseRun.unit_stats (id, name, hp, damage, attack_interval, range, speed, bolt, giant, shiny ...).
var stats: Dictionary = {}
var hp: int = 1
var max_hp: int = 1
var damage: int = 1
var attack_interval: float = 1.0
var attack_range: float = 80.0
var speed: float = 40.0
var post: Vector2 = Vector2.ZERO
var target: DefenseEnemy = null
var state: State = State.MOVE
var level: int = 1
var kills: int = 0
## Set by the game from DefenseRun (kills per level, factor, cap).
var level_kills: int = 3
var level_factor: float = 1.3
var max_level: int = 5
## Element of its crystal (fire, ice ...), set by the game; only for the look of its bolts.
var element: String = ""
## Rarity as a number (R1 = 1 … R5 = 5), set by the game; only for the glow.
var rarity_rank: int = 1

var _attack_timer: float = 0.0
## Seconds until the skill is ready again (only units with stats.skill).
var _skill_timer: float = 0.0
var _tint: Color = Color.WHITE
var _glow_time: float = 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func setup(frames: SpriteFrames, numbers: Dictionary, guard_post: Vector2) -> void:
	stats = numbers
	max_hp = maxi(int(numbers.get("hp", 1)), 1)
	hp = max_hp
	damage = maxi(int(numbers.get("damage", 1)), 1)
	attack_interval = maxf(float(numbers.get("attack_interval", 1.0)), 0.05)
	attack_range = float(numbers.get("range", 80.0))
	speed = float(numbers.get("speed", 40.0))
	post = guard_post
	$Sprite.sprite_frames = frames
	$Sprite.material = FLASH_MATERIAL
	# The first use comes a bit after it appears, not at once.
	_skill_timer = float((numbers.get("skill", {}) as Dictionary).get("interval", 0.0)) * 0.5
	if bool(numbers.get("giant", false)):
		scale = Vector2(GIANT_SCALE, GIANT_SCALE)
	if bool(numbers.get("shiny", false)):
		_tint = SHINY_TINT
	$Sprite.modulate = _tint


func _ready() -> void:
	_sprite.play(&"walk")
	_face(true)
	_sprite.animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	if is_alive():
		_sprite.play(&"walk")


## Out of a crystal: the picture falls from `height` px above and bounces on the ground.
## Returns how long the fall takes (the game puts dust there when it lands).
func drop_in(height: float) -> float:
	var time: float = 0.35
	_sprite.position.y = -height
	var fall := create_tween()
	fall.tween_property(_sprite, "position:y", 0.0, time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(_sprite, "scale", Vector2(1.2, 0.8), 0.06)
	fall.tween_property(_sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	return time


func has_skill() -> bool:
	return not (stats.get("skill", {}) as Dictionary).is_empty()


func skill() -> Dictionary:
	return stats.get("skill", {})


## The skill's damage: the unit's damage (with level, rarity, upgrades) × the skill's factor.
func skill_damage() -> int:
	return maxi(int(round(float(damage) * float(skill().get("damage", 1.0)))), 1)


## The game used the skill: swing, and wait the skill's interval.
func use_skill() -> void:
	_skill_timer = float(skill().get("interval", 5.0))
	_sprite.frame = 0
	_sprite.play(&"attack")


## Nothing to hit yet: ask again a little later.
func delay_skill(seconds: float) -> void:
	_skill_timer = seconds


func is_melee() -> bool:
	return attack_range < MELEE_RANGE


## Looks right or left; most sheets look left, `faces_right` ones the other way (FEHLERKLASSEN 24).
func _face(right: bool) -> void:
	_sprite.flip_h = right != bool(stats.get("faces_right", false))


func is_alive() -> bool:
	return state != State.DEAD


func shot_origin() -> Vector2:
	return global_position + SHOT_OFFSET * scale.y


func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if rarity_rank >= GLOW_RANK:
		_glow_time += delta
		queue_redraw()
	if target != null and not target.is_visible_to_units():
		target = null
	if has_skill():
		_skill_timer -= delta
		if _skill_timer <= 0.0:
			skill_ready.emit(self)
	_attack_timer = minf(_attack_timer + delta, attack_interval)
	if target == null:
		_move_to(post, delta)
		return
	var to_target: Vector2 = target.global_position - global_position
	var reach: float = attack_range * scale.x
	if to_target.length() > reach + (REACH_SLACK if is_melee() else 0.0):
		# Out of reach: walk towards it (melee to hit, ranged until it is in range).
		_move_to(target.global_position, delta)
		return
	if _attack_timer < attack_interval:
		return
	_attack_timer = 0.0
	_face(to_target.x > 0.0)
	_sprite.frame = 0
	_sprite.play(&"attack")
	if is_melee():
		if target.hit(damage):
			credit_kill()
	else:
		shot.emit(self, target)


func _move_to(goal: Vector2, delta: float) -> void:
	var to_goal: Vector2 = goal - global_position
	var step: float = speed * delta
	if to_goal.length() <= step:
		global_position = goal
		if goal == post:
			state = State.GUARD
		return
	state = State.MOVE
	global_position += to_goal.normalized() * step
	_face(to_goal.x > 0.0)


## It killed an enemy (melee hit or its bolt): count, maybe level up.
func credit_kill() -> void:
	if not is_alive():
		return
	kills += 1
	if level < max_level and kills >= level_kills * level:
		level += 1
		# Stronger, but not healed: it only gains the extra life (units are meant to die fast).
		var gained: int = maxi(int(round(float(max_hp) * level_factor)) - max_hp, 1)
		max_hp += gained
		hp += gained
		damage = maxi(damage + 1, int(round(float(damage) * level_factor)))
		queue_redraw()
		leveled_up.emit(self)


## Full life again (after a cleared wave).
func heal() -> void:
	if is_alive():
		hp = max_hp
		queue_redraw()


func hit(amount: int) -> bool:
	if not is_alive() or amount <= 0:
		return false
	hp -= amount
	_sprite.modulate = Color(2.0, 2.0, 2.0)
	create_tween().tween_property(_sprite, "modulate", _tint, 0.15)
	queue_redraw()
	if hp > 0:
		return false
	state = State.DEAD
	target = null
	_sprite.play(&"death")
	died.emit(self)
	var fade := create_tween()
	fade.tween_interval(CORPSE_TIME)
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(queue_free)
	return true


## Shadow, rarity glow and sparks under/around it, the life bar above the head once hurt
## (redrawn on change; every frame only from R3, for the glow).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SHADOW_SIZE.y / SHADOW_SIZE.x))
	if rarity_rank >= GLOW_RANK and is_alive():
		var glow: Color = stats.get("rarity_color", Color.WHITE)
		var pulse: float = 0.5 + 0.5 * sin(_glow_time * 4.0)
		draw_circle(Vector2.ZERO, SHADOW_SIZE.x * (1.5 + 0.25 * pulse), Color(glow, 0.18 + 0.2 * pulse))
	draw_circle(Vector2.ZERO, SHADOW_SIZE.x, SHADOW)
	draw_set_transform(Vector2.ZERO)
	if rarity_rank >= SPARK_RANK and is_alive():
		var spark: Color = stats.get("rarity_color", Color.WHITE)
		for i in SPARKS:
			var rise: float = fposmod(_glow_time * 0.7 + float(i) / SPARKS, 1.0)
			var at := Vector2(sin(float(i) * 2.3 + _glow_time * 2.0) * 9.0, -4.0 - rise * 34.0)
			draw_rect(Rect2(at, Vector2(1.5, 1.5)), Color(spark.lightened(0.4), 1.0 - rise))
	if hp >= max_hp or not is_alive():
		return
	var part: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(-BAR_WIDTH / 2.0, BAR_Y, BAR_WIDTH, 3.0), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-BAR_WIDTH / 2.0, BAR_Y, BAR_WIDTH * part, 3.0), Color(0.4, 0.9, 0.3))
