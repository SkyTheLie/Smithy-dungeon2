class_name Fireball
extends Node2D
## A fireball that flies to a target point and explodes there with area damage. There is no
## player health yet, so `damage` is 0: the explosion only reports who stood in it
## (signal `exploded`).

signal exploded(bodies: Array[Node2D])

## Pixels per second.
@export var speed: float = 150.0
## Radius of the explosion (area damage) in pixels.
@export var radius: float = 36.0
## Damage per hit; 0 until the player can take damage.
@export var damage: int = 0

const FLY_FPS: float = 12.0
const FLY_FRAMES: int = 8
const EXPLOSION_FPS: float = 14.0
const EXPLOSION_FRAMES: int = 12

var _target: Vector2
var _time: float = 0.0
var _exploding: bool = false

@onready var _ball: Sprite2D = $Ball
@onready var _explosion: Sprite2D = $Explosion


## Starts the flight from the current position to `target` (global position).
func launch(target: Vector2) -> void:
	_target = target


func _ready() -> void:
	_explosion.visible = false


func _process(delta: float) -> void:
	_time += delta
	if _exploding:
		var frame: int = int(_time * EXPLOSION_FPS)
		if frame >= EXPLOSION_FRAMES:
			queue_free()
			return
		_explosion.frame = frame
		return
	_ball.frame = int(_time * FLY_FPS) % FLY_FRAMES
	global_position = global_position.move_toward(_target, speed * delta)
	if global_position.distance_to(_target) < 1.0:
		_explode()


func _explode() -> void:
	_exploding = true
	_time = 0.0
	_ball.visible = false
	_explosion.visible = true
	var hit: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		var body := node as Node2D
		if body and body.global_position.distance_to(global_position) <= radius:
			hit.append(body)
	exploded.emit(hit)
