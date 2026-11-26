class_name LichWanderer
extends CharacterBody2D
## The Lich next to the smithy: wanders around its starting point a step at a time. Now and then,
## when the player is close, it turns to the player, shouts `taunt` in a speech bubble and casts
## a fireball at the player's position (area damage, currently 0). It does not attack otherwise.

## Speech bubble text before each fireball.
@export var taunt: String = "Grrrr ich grill dich mit einem Feuerball"
## How far (pixels) it may wander from where it was placed.
@export var wander_radius: float = 48.0
## Only casts when the player is closer than this.
@export var cast_range: float = 220.0
## Seconds between two fireballs (random in this range).
@export var cast_interval: Vector2 = Vector2(9.0, 15.0)

const FIREBALL_SCENE: PackedScene = preload("res://scenes/world/objects/fireball.tscn")
const WALK_SPEED: float = 28.0
const STEP_LENGTH: Vector2 = Vector2(12.0, 28.0)
const PAUSE: Vector2 = Vector2(1.2, 3.5)
const WALK_FPS: float = 8.0
const CAST_FPS: float = 8.0
const FRAMES: int = 6
## Cast frame at which the fireball leaves the hand.
const RELEASE_FRAME: int = 3
const TAUNT_TIME: float = 2.2
## Where the fireball starts, relative to the feet (about chest height).
const HAND_OFFSET: Vector2 = Vector2(0.0, -24.0)
## Sheet rows (lich_walk.png / lich_cast.png).
const ROWS: Dictionary = {"down": 0, "left": 1, "right": 2, "up": 3}

enum State { IDLE, WALK, TAUNT, CAST }

var _state: State = State.IDLE
var _home: Vector2
var _facing: String = "down"
var _state_time: float = 0.0
var _pause: float = 1.0
var _step_target: Vector2
var _cast_timer: float = 0.0
var _released: bool = false
var _cast_target: Vector2

@onready var _walk_sprite: Sprite2D = $Walk
@onready var _cast_sprite: Sprite2D = $Cast
@onready var _bubble: Control = $Bubble
@onready var _bubble_label: Label = $Bubble/Label


func _ready() -> void:
	# top-down: everything it bumps into is a wall (grounded mode took the player for a floor and
	# rode along on him)
	motion_mode = MOTION_MODE_FLOATING
	_home = global_position
	_bubble_label.text = taunt
	_bubble.visible = false
	_pause = randf_range(PAUSE.x, PAUSE.y)
	_cast_timer = randf_range(cast_interval.x, cast_interval.y)
	_show_frame()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cast_timer -= delta
	match _state:
		State.IDLE:
			if _cast_timer <= 0.0 and _player_in_range():
				_start_taunt()
			elif _state_time >= _pause:
				_start_step()
		State.WALK:
			_walk_step()
		State.TAUNT:
			if _state_time >= TAUNT_TIME:
				_set_state(State.CAST)
		State.CAST:
			_cast()
	_show_frame()


func _start_step() -> void:
	var direction: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
	var target: Vector2 = global_position + direction * randf_range(STEP_LENGTH.x, STEP_LENGTH.y)
	if target.distance_to(_home) > wander_radius:
		# Too far away: step back towards home instead.
		direction = _main_direction(_home - global_position)
		target = global_position + direction * randf_range(STEP_LENGTH.x, STEP_LENGTH.y)
	_step_target = target
	_facing = _direction_name(direction)
	_set_state(State.WALK)


func _walk_step() -> void:
	var to_target: Vector2 = _step_target - global_position
	velocity = to_target.normalized() * WALK_SPEED
	var moved_from: Vector2 = global_position
	move_and_slide()
	# Stop at the target, or when something (a fence, a tree) blocks the way.
	if to_target.length() < 2.0 or global_position.distance_to(moved_from) < 0.05:
		velocity = Vector2.ZERO
		_pause = randf_range(PAUSE.x, PAUSE.y)
		_set_state(State.IDLE)


func _start_taunt() -> void:
	var player := _player()
	_cast_target = player.global_position
	_facing = _direction_name(_main_direction(_cast_target - global_position))
	_bubble.visible = true
	_set_state(State.TAUNT)


func _cast() -> void:
	var frame: int = int(_state_time * CAST_FPS)
	if frame >= RELEASE_FRAME and not _released:
		_released = true
		_bubble.visible = false
		var player := _player()
		if player:
			_cast_target = player.global_position
		var fireball: Fireball = FIREBALL_SCENE.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = global_position + HAND_OFFSET
		fireball.launch(_cast_target)
	if frame >= FRAMES:
		_released = false
		_cast_timer = randf_range(cast_interval.x, cast_interval.y)
		_pause = randf_range(PAUSE.x, PAUSE.y)
		_set_state(State.IDLE)


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0


func _show_frame() -> void:
	var casting: bool = _state == State.CAST
	_walk_sprite.visible = not casting
	_cast_sprite.visible = casting
	var row: int = ROWS[_facing] * FRAMES
	if casting:
		_cast_sprite.frame = row + mini(int(_state_time * CAST_FPS), FRAMES - 1)
	elif _state == State.WALK:
		_walk_sprite.frame = row + int(_state_time * WALK_FPS) % FRAMES
	else:
		_walk_sprite.frame = row


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(Player.GROUP) as Node2D


func _player_in_range() -> bool:
	var player := _player()
	return player != null and player.global_position.distance_to(global_position) <= cast_range


static func _main_direction(vector: Vector2) -> Vector2:
	if absf(vector.x) >= absf(vector.y):
		return Vector2.RIGHT if vector.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if vector.y >= 0.0 else Vector2.UP


static func _direction_name(direction: Vector2) -> String:
	if direction == Vector2.LEFT:
		return "left"
	if direction == Vector2.RIGHT:
		return "right"
	return "up" if direction == Vector2.UP else "down"
