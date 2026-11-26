class_name FogGhost
extends Node2D
## A ghost drifting through the fog of the dark city: decoration only, it never touches anybody.
## It fades in somewhere in `area`, floats straight (left, right, up or down, never at a slant)
## for a while with its walk frames (a strip of 48 px frames looking left, mirrored to go right),
## bobbing by whole pixels, and fades out again; then it waits and appears somewhere else.
## Burning lanterns (StreetLantern) and the player scare it: it turns away and fades out.
## Drawn above the fog (z_index), half see-through.

const FRAME: int = 48
const FRAMES_PER_SECOND: float = 6.0
const FADE_TIME: float = 1.6
## Feet of a frame, measured from its centre (ghosts float, so a little higher than a figure).
const FEET_FROM_CENTRE: float = 20.0
const BOB_HEIGHT: float = 2.0
const BOB_SPEED: float = 1.7
## Lit lanterns and the player closer than this make it flee.
const SCARE_DISTANCE: float = 64.0
const CHECK_INTERVAL: float = 0.4

## Walk strip (frames side by side, looking left).
@export var strip: Texture2D
## Where it may appear and float (world).
@export var area: Rect2 = Rect2(-200, -100, 400, 200)
@export var speed: float = 12.0
## Seconds floating before it fades out (random in this range).
@export var float_time: Vector2 = Vector2(8.0, 16.0)
## Seconds invisible between two appearances (random in this range).
@export var hide_time: Vector2 = Vector2(4.0, 12.0)
## Full opacity while visible.
@export var max_alpha: float = 0.6

enum State { HIDDEN, FLOATING, LEAVING }

var _state: State = State.HIDDEN
var _left: float = 0.0
var _direction: Vector2 = Vector2.LEFT
var _time: float = 0.0
var _check_left: float = 0.0
var _base: Vector2 = Vector2.ZERO
var _sprite: Sprite2D
var _fade: Tween
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(name) + int(Time.get_ticks_msec())
	_sprite = Sprite2D.new()
	_sprite.texture = strip
	_sprite.hframes = maxi(1, strip.get_width() / FRAME) if strip else 1
	_sprite.offset = Vector2(0, -FEET_FROM_CENTRE)
	add_child(_sprite)
	modulate.a = 0.0
	_left = _rng.randf_range(0.0, hide_time.y)


func is_visible_ghost() -> bool:
	return _state != State.HIDDEN


func _process(delta: float) -> void:
	_time += delta
	_left -= delta
	match _state:
		State.HIDDEN:
			if _left <= 0.0:
				_appear()
			return
		State.FLOATING:
			_check_left -= delta
			if _check_left <= 0.0:
				_check_left = CHECK_INTERVAL
				_flee_if_scared()
			if _left <= 0.0 or not area.grow(24.0).has_point(_base):
				_leave()
	_base += _direction * speed * delta
	_sprite.frame = int(_time * FRAMES_PER_SECOND) % _sprite.hframes
	position = Vector2(roundf(_base.x), roundf(_base.y + sin(_time * BOB_SPEED) * BOB_HEIGHT))


func _appear() -> void:
	for attempt in 6:
		_base = Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		if _scare_source() == Vector2.INF:
			break
	var ways: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	_set_direction(ways[_rng.randi() % ways.size()])
	position = _base.round()
	_state = State.FLOATING
	_left = _rng.randf_range(float_time.x, float_time.y)
	_fade_to(max_alpha)


func _leave() -> void:
	_state = State.LEAVING
	_fade_to(0.0)
	_fade.finished.connect(_hide, CONNECT_ONE_SHOT)


func _hide() -> void:
	_state = State.HIDDEN
	_left = _rng.randf_range(hide_time.x, hide_time.y)


func _fade_to(alpha: float) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, FADE_TIME)


## Turns away from a burning lantern or the player and fades out.
func _flee_if_scared() -> void:
	var source: Vector2 = _scare_source()
	if source == Vector2.INF:
		return
	var away: Vector2 = _base - source
	_set_direction(Vector2(signf(away.x), 0.0) if absf(away.x) >= absf(away.y) else Vector2(0.0, signf(away.y)))
	_leave()


## Position of the nearest thing that scares it within SCARE_DISTANCE, INF if none.
func _scare_source() -> Vector2:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player and player.global_position.distance_to(_base) < SCARE_DISTANCE:
		return player.global_position
	for node: Node in get_tree().get_nodes_in_group(StreetLantern.GROUP):
		var lantern := node as StreetLantern
		if lantern.lit and lantern.global_position.distance_to(_base) < SCARE_DISTANCE:
			return lantern.global_position
	return Vector2.INF


func _set_direction(way: Vector2) -> void:
	if way == Vector2.ZERO:
		way = Vector2.LEFT
	_direction = way
	if way.x != 0.0:
		_sprite.flip_h = way.x > 0.0
