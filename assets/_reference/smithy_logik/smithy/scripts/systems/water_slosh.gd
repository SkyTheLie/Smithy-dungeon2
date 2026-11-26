class_name WaterSlosh
extends RefCounted
## The water in the holy water crystal sloshes against the player's movement: walking left pushes it
## to the right, walking up pushes it down, walking down pushes it up. Its icon (items.json
## "icon_slosh") is a strip of 5x5 frames: row = water pushed up .. down, column = pushed left ..
## right, the middle frame is the water at rest (assets/_reference/holy_crystals/make_holy_crystals.py).
## A damped spring moves the water, so it swings back a little when the player stops.
## The player calls step() every physics frame.

const STEPS: int = 5
## How hard the water is pulled towards where the movement pushes it, and how fast it calms down.
const STIFFNESS: float = 60.0
const DAMPING: float = 6.5

static var _textures: Array[AnimatedTexture] = []
## -1..1 per axis: where the water is pushed to (x > 0 = right, y > 0 = down).
static var _tilt: Vector2 = Vector2.ZERO
static var _tilt_speed: Vector2 = Vector2.ZERO
static var _frame: int = -1


## Icon whose frame follows the water (ContentDB calls this for "icon_slosh" items).
static func register(texture: AnimatedTexture) -> void:
	texture.pause = true
	_textures.append(texture)
	_frame = -1
	_apply()


## `motion`: how the player moved this frame, 1 = walking speed.
static func step(motion: Vector2, delta: float) -> void:
	if _textures.is_empty():
		return
	var target: Vector2 = (-motion).limit_length(1.0)
	_tilt_speed += (STIFFNESS * (target - _tilt) - DAMPING * _tilt_speed) * delta
	_tilt = (_tilt + _tilt_speed * delta).clamp(-Vector2.ONE, Vector2.ONE)
	_apply()


## Frame of the strip for the current tilt.
static func frame() -> int:
	var half: int = STEPS / 2
	var column: int = clampi(roundi(_tilt.x * half) + half, 0, STEPS - 1)
	var row: int = clampi(roundi(_tilt.y * half) + half, 0, STEPS - 1)
	return row * STEPS + column


static func _apply() -> void:
	var current: int = frame()
	if current == _frame:
		return
	_frame = current
	for texture: AnimatedTexture in _textures:
		texture.current_frame = current
