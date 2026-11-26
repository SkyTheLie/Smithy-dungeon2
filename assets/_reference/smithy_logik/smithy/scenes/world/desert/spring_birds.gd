class_name SpringBirds
extends Node2D
## Colourful birds at the spring of Sahrim, only decoration (no bodies). Some fly wide loops over
## the water, the others sit on the grass around it and hop now and then. A sitting bird flies up
## when the player comes close and lands somewhere else a few seconds later.
## `sheet`: 3 frames per row (sitting, wings up, wings down), one row per colour, head to the right.

@export var sheet: Texture2D
@export var flying: int = 4
@export var sitting: int = 5
## Half axes of the loops the birds fly (around this node).
@export var loop_radius: Vector2 = Vector2(150, 90)
## Half axes of the ring where birds sit (between the water and the path).
@export var sit_inner: Vector2 = Vector2(118, 72)
@export var sit_outer: Vector2 = Vector2(180, 122)

const FRAME_SIZE: Vector2i = Vector2i(16, 16)
const COLOURS: int = 4
const FLAP_SPEED: float = 10.0
## A sitting bird flies up when the player is closer than this (pixels).
const SHY_DISTANCE: float = 36.0
## Seconds a startled bird flies before it lands again.
const FLIGHT_SECONDS: float = 6.0
const FLY_HEIGHT: Vector2 = Vector2(28, 56)

var _birds: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	for i in flying + sitting:
		var sprite := Sprite2D.new()
		sprite.texture = sheet
		sprite.region_enabled = true
		add_child(sprite)
		var bird: Dictionary = {
			"sprite": sprite, "row": i % COLOURS, "phase": randf() * 10.0,
			"angle": randf() * TAU, "speed": randf_range(0.35, 0.7) * (1.0 if randf() < 0.5 else -1.0),
			"size": randf_range(0.75, 1.1), "height": randf_range(FLY_HEIGHT.x, FLY_HEIGHT.y),
			"spot": _random_spot(), "flying_left": -1.0 if i >= flying else INF,
		}
		_birds.append(bird)


func _process(delta: float) -> void:
	_time += delta
	var player: Node2D = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	for bird: Dictionary in _birds:
		if bird.flying_left > 0.0:
			_fly(bird, delta)
			bird.flying_left -= delta
			if bird.flying_left <= 0.0:
				bird.spot = _random_spot()
		else:
			_sit(bird)
			if player and player.global_position.distance_to(to_global(bird.spot)) < SHY_DISTANCE:
				bird.flying_left = FLIGHT_SECONDS
				bird.angle = atan2(bird.spot.y / loop_radius.y, bird.spot.x / loop_radius.x)


func _fly(bird: Dictionary, delta: float) -> void:
	var sprite: Sprite2D = bird.sprite
	bird.angle += bird.speed * delta
	var radius: Vector2 = loop_radius * bird.size
	var bob: float = sin(_time * 2.0 + bird.phase) * 5.0
	sprite.position = Vector2(cos(bird.angle) * radius.x, sin(bird.angle) * radius.y - bird.height + bob)
	sprite.flip_h = -sin(bird.angle) * bird.speed < 0.0
	sprite.z_index = 10
	_show_frame(bird, 1 + int(_time * FLAP_SPEED + bird.phase) % 2)


func _sit(bird: Dictionary) -> void:
	var sprite: Sprite2D = bird.sprite
	# Every few seconds a little hop, sometimes turning round.
	var cycle: float = fmod(_time + bird.phase, 3.5)
	var hop: float = sin(cycle / 0.35 * PI) * 3.0 if cycle < 0.35 else 0.0
	sprite.position = bird.spot - Vector2(0, hop)
	sprite.flip_h = int((_time + bird.phase) / 7.0) % 2 == 0
	sprite.z_index = 0
	_show_frame(bird, 0)


func _show_frame(bird: Dictionary, frame: int) -> void:
	(bird.sprite as Sprite2D).region_rect = Rect2(Vector2(frame * FRAME_SIZE.x, int(bird.row) * FRAME_SIZE.y), FRAME_SIZE)


## A point on the grass ring between `sit_inner` and `sit_outer`.
func _random_spot() -> Vector2:
	var angle: float = randf() * TAU
	var direction := Vector2(cos(angle), sin(angle))
	return direction * sit_inner.lerp(sit_outer, randf_range(0.15, 0.85))
