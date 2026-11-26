class_name GoblinWorker
extends Node2D
## A goblin working far below in the canyon (Lavaberg), only to look at: plays a work loop on the
## spot, or walks back and forth between its start and `walk_to` (straight north/south/west/east
## only), resting a moment at each end. It can push something in front of it (the mine cart).

## Frames side by side. With `rows` 4 the rows are south, north, west, east.
@export var sheet: Texture2D
@export var frames: int = 4
@export var rows: int = 1
@export var fps: float = 6.0
## Second end of the walk, relative to the start. Zero = works on the spot.
@export var walk_to: Vector2 = Vector2.ZERO
@export var speed: float = 12.0
## Seconds of rest at each end of the walk.
@export var rest: float = 2.0
## With a single row (facing east): mirrored when walking west.
@export var mirror_west: bool = true
## Mirrors the picture while working on the spot (e.g. a west-facing goblin that should look east).
@export var mirror: bool = false
## Pushed in front of the goblin (e.g. the mine cart): kept `push_distance` px ahead.
@export var pushed: Node2D
@export var push_distance: float = 15.0

var _sprite: Sprite2D
var _start: Vector2
var _going_out: bool = true
var _rest_left: float = 0.0
var _frame_time: float = 0.0


func _ready() -> void:
	_start = position
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = frames
	_sprite.vframes = rows
	_sprite.flip_h = mirror
	# feet on the node position
	_sprite.offset = Vector2(0, -sheet.get_height() / (2.0 * rows) + 3.0)
	add_child(_sprite)
	# not all goblins in step
	_frame_time = randf() * frames / fps
	_update_pushed(Vector2.RIGHT)


func _process(delta: float) -> void:
	var moving: bool = walk_to != Vector2.ZERO and _rest_left <= 0.0
	if walk_to != Vector2.ZERO:
		if _rest_left > 0.0:
			_rest_left -= delta
		else:
			var target: Vector2 = _start + (walk_to if _going_out else Vector2.ZERO)
			var direction: Vector2 = (target - position).normalized()
			position = position.move_toward(target, speed * delta)
			_face(direction)
			_update_pushed(direction)
			if position.is_equal_approx(target):
				_going_out = not _going_out
				_rest_left = rest
	if moving or walk_to == Vector2.ZERO:
		_frame_time += delta
		_sprite.frame_coords.x = int(_frame_time * fps) % frames
	else:
		_sprite.frame_coords.x = 0


func _face(direction: Vector2) -> void:
	if rows == 4:
		var row: int = 0  # south
		if absf(direction.x) > absf(direction.y):
			row = 3 if direction.x > 0.0 else 2
		elif direction.y < 0.0:
			row = 1
		_sprite.frame_coords.y = row
	elif mirror_west:
		_sprite.flip_h = direction.x < 0.0


func _update_pushed(direction: Vector2) -> void:
	if pushed == null:
		return
	pushed.position = position + direction * push_distance
	if pushed is Sprite2D and absf(direction.x) > 0.0:
		(pushed as Sprite2D).flip_h = direction.x < 0.0
