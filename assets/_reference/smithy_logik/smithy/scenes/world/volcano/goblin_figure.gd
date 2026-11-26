class_name GoblinFigure
extends Node2D
## A figure that only stands around (no talking), a PixelLab resident or an Appearance,
## e.g. the goblins in the crowd before the goblin king's throne. It can walk to a point
## (walk_to, with walk frames) and hop (hop) - used by GoblinThroneCutscene and GoblinCrowd.

@export var appearance: Appearance
## PixelLab sheet (assets/sprites/residents/<resident>.png), wins over `appearance`.
@export var resident: String = ""
@export_enum("down", "up", "left", "right") var facing: String = "down"
## Gone (queue_free) once this story flag is set, e.g. the goblin that was thrown into the mine.
@export var hidden_when_flag: String = ""
## Once `aside_flag` is set the figure walks to `aside_position` (parent coordinates) and stays
## there looking towards `aside_facing`; loaded with the flag set it stands there already (e.g. the
## crowd making way for the player). ZERO = not used.
@export var aside_position: Vector2 = Vector2.ZERO
@export var aside_flag: String = ""
@export_enum("down", "up", "left", "right") var aside_facing: String = "up"
## Colour the sprite is multiplied with (a crowd of few sheets looks less alike).
@export var tint: Color = Color.WHITE

const ASIDE_SPEED: float = 40.0
const HOP_HEIGHT: float = 5.0
const HOP_TIME: float = 0.22

var _sprite: Sprite2D
var _walk_time: float = 0.0
var _target: Vector2
var _speed: float = 0.0
var _on_arrived: Callable
var _hopping: bool = false
## Kept at its place (hold_at): does not step aside when `aside_flag` comes.
var _held: bool = false


func _ready() -> void:
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag):
		queue_free()
		return
	_sprite = Sprite2D.new()
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident)
	_sprite.texture = sheet if sheet else CharacterBaker.get_sheet(appearance)
	_sprite.region_enabled = true
	_sprite.offset = Vector2(0, -20)
	_sprite.modulate = tint
	if sheet == null:
		_sprite.scale = Vector2.ONE * appearance.get_scale()
	add_child(_sprite)
	if _is_aside_flag_set():
		position = aside_position
		facing = aside_facing
	face(facing)
	if aside_position != Vector2.ZERO and not aside_flag.is_empty():
		GameState.story.changed.connect(_on_story_changed)


func _is_aside_flag_set() -> bool:
	return aside_position != Vector2.ZERO and not aside_flag.is_empty() and GameState.story.has_flag(aside_flag)


## The flag came while the player watches: walk aside (once).
func _on_story_changed() -> void:
	if not _held and _is_aside_flag_set() and _target != aside_position:
		walk_to(aside_position, ASIDE_SPEED * randf_range(0.8, 1.2), face.bind(aside_facing))


## Stands at `point` (parent coordinates) and stays there, also once `aside_flag` is set (e.g. the
## crowd shuts the lane while the king sleeps).
func hold_at(point: Vector2, direction: String) -> void:
	_held = true
	_speed = 0.0
	position = point
	face(direction)


## Turns to "down", "up", "left" or "right" (standing).
func face(direction: String) -> void:
	facing = direction
	if _sprite:
		_sprite.region_rect = CharacterBaker.get_frame_rect(direction)


## true while walking (walk_to).
func is_walking() -> bool:
	return _speed > 0.0


## Walks to `point` (parent coordinates) at `speed` pixels per second, then calls `on_arrived`.
func walk_to(point: Vector2, speed: float = 60.0, on_arrived: Callable = Callable()) -> void:
	_target = point
	_speed = speed
	_on_arrived = on_arrived


## A little jump on the spot (cheering, being shoved); `delay` seconds from now.
func hop(delay: float = 0.0) -> void:
	if _sprite == null or _hopping:
		return
	_hopping = true
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(_sprite, "position:y", -HOP_HEIGHT, HOP_TIME * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "position:y", 0.0, HOP_TIME * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _hopping = false)


func _process(delta: float) -> void:
	if _speed <= 0.0 or _sprite == null:
		return
	var offset: Vector2 = _target - position
	if offset.length() <= 1.0:
		position = _target
		_speed = 0.0
		face(facing)
		if _on_arrived.is_valid():
			_on_arrived.call()
		return
	position += offset.limit_length(_speed * delta)
	_walk_time += delta
	var frame: int = 1 + int(_walk_time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1)
	var direction: String = ("right" if offset.x > 0.0 else "left") if absf(offset.x) > absf(offset.y) else ("down" if offset.y > 0.0 else "up")
	facing = direction
	_sprite.region_rect = CharacterBaker.get_frame_rect(direction, frame)
