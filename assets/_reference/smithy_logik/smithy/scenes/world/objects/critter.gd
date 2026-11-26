class_name Critter
extends Sprite2D
## A small animal in the world: it stands around, then wanders off in a straight line (never
## diagonal), turns back at walls and stays near its spot. Only decoration, no collision, so it
## never blocks the player. Its walk lies next to the picture as "<name>_walk.png": frames in one
## row, looking left, drawn from the same bottom middle as the picture. Without one it hops.
## Birds that peck (the hen) also have "<name>_peck.png" (frame 0 = standing with the head up, then
## head down and up again) and "<name>_walk_low.png" (walking with the head down): they walk with
## the head up, stop, peck two or three times and walk on, now and then with the head down.
## While walking (or standing in a walk/peck frame) a soft shadow lies under the feet; the
## standing picture has its own shadow painted in.

const PAUSE_MIN: float = 1.5
const PAUSE_MAX: float = 6.0
const HOP_TIME: float = 0.35
const HOP_HEIGHT: float = 2.0
const WALK_FPS: float = 8.0
## Walks along the row more often than up or down (it is drawn from the side).
const SIDEWAYS_CHANCE: float = 0.75
## Stops this far before a wall.
const WALL_GAP: float = 8.0
## The row of a walk's frames where the feet of the standing picture are.
const FEET: float = 58.0
## Standing pictures that look right (the walks all look left).
const STILL_LOOKS_RIGHT: Array[String] = ["village_20", "alley_5"]
## Pecking birds: frames per second of one peck, how often in a row, pauses around it.
const PECK_FPS: float = 12.0
const PECKS_MIN: int = 2
const PECKS_MAX: int = 3
const PECK_GAP: float = 0.25
const LOOK_MIN: float = 0.3
const LOOK_MAX: float = 1.2
## How often a pecking bird walks with its head down, and how much slower it is then.
const LOW_WALK_CHANCE: float = 0.25
const LOW_WALK_SPEED: float = 0.6
## Shadow under the feet: width as part of the standing picture, colour.
const SHADOW_WIDTH: float = 0.55
const SHADOW_COLOR: Color = Color(0, 0, 0, 0.28)
## No shadow: the swan swims, the doves are a flock (one ellipse would look wrong).
const NO_SHADOW: Array[String] = ["swan", "city_7"]

## How far it wanders from where it was placed.
@export var reach: float = 48.0
## Longest single walk (or hop, without a walk).
@export var hop: float = 40.0
## Pixels per second.
@export var speed: float = 16.0

var _home: Vector2
var _still: Texture2D
var _still_offset: Vector2
var _walk: Texture2D
var _walk_low: Texture2D
var _peck: Texture2D
var _sheet: Texture2D
var _still_looks_right: bool = false
var _looks_right: bool = false
var _walk_time: float = 0.0
var _shadow: Node2D


func _ready() -> void:
	_home = position
	_still = texture
	_still_offset = offset
	if texture != null:
		var base: String = texture.resource_path.get_basename()
		_walk = _load_if_there(base + "_walk.png")
		_walk_low = _load_if_there(base + "_walk_low.png")
		_peck = _load_if_there(base + "_peck.png")
		_still_looks_right = STILL_LOOKS_RIGHT.has(texture.resource_path.get_file().get_basename())
		_add_shadow()
		_shadow.set_meta("never", NO_SHADOW.has(texture.resource_path.get_file().get_basename()))
	set_process(false)
	if _peck != null:
		_show_frame(_peck, 0)
	_wait()


func _process(delta: float) -> void:
	_walk_time += delta
	_show_frame(_sheet, int(_walk_time * WALK_FPS) % _frame_count(_sheet))


func _load_if_there(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _wait(time: float = -1.0) -> void:
	if time < 0.0:
		time = randf_range(PAUSE_MIN, PAUSE_MAX)
	get_tree().create_timer(time, false).timeout.connect(_move)


func _move() -> void:
	if not is_inside_tree():
		return
	if _walk == null:
		_hop()
		return
	var target: Vector2 = _pick_target()
	if target.is_equal_approx(position):
		_after_walk()
		return
	var sheet: Texture2D = _walk
	var pace: float = speed
	if _walk_low != null and randf() < LOW_WALK_CHANCE:
		sheet = _walk_low
		pace *= LOW_WALK_SPEED
	_look_towards(target)
	_start_walk(sheet)
	var tween := create_tween()
	tween.tween_property(self, "position", target, position.distance_to(target) / pace)
	tween.finished.connect(func() -> void:
		_stop_walk()
		_after_walk())


## Pecking birds look around a moment and peck a few times, the others just wait.
func _after_walk() -> void:
	if _peck == null:
		_wait()
		return
	var tween := create_tween()
	tween.tween_interval(randf_range(LOOK_MIN, LOOK_MAX))
	var frames: int = _frame_count(_peck)
	for i in randi_range(PECKS_MIN, PECKS_MAX):
		for index in range(1, frames):
			tween.tween_callback(_show_frame.bind(_peck, index))
			tween.tween_interval(1.0 / PECK_FPS)
		tween.tween_callback(_show_frame.bind(_peck, 0))
		tween.tween_interval(PECK_GAP)
	tween.finished.connect(func() -> void: _wait(randf_range(LOOK_MIN, PAUSE_MIN)))


## A spot straight along one axis, inside its reach, before the next wall.
func _pick_target() -> Vector2:
	var direction := Vector2(1, 0) if randf() < SIDEWAYS_CHANCE else Vector2(0, 0.5)
	if randf() < 0.5:
		direction = -direction
	var target: Vector2 = (position + direction * randf_range(hop * 0.4, hop)).clamp(_home - Vector2.ONE * reach, _home + Vector2.ONE * reach)
	var from: Vector2 = global_position
	var to: Vector2 = from + (target - position) * global_scale
	var query := PhysicsRayQueryParameters2D.create(from, to + (to - from).normalized() * WALL_GAP)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return target
	return position + (target - position).normalized() * maxf(from.distance_to(hit["position"]) - WALL_GAP, 0.0)


func _start_walk(sheet: Texture2D) -> void:
	_sheet = sheet
	_walk_time = 0.0
	_show_frame(sheet, 0)
	set_process(true)


## Back to standing: the first peck frame for pecking birds, else the standing picture.
func _stop_walk() -> void:
	set_process(false)
	if _peck != null:
		_show_frame(_peck, 0)
		return
	region_enabled = false
	texture = _still
	offset = _still_offset
	_shadow.visible = false
	_apply_look()


func _frame_count(sheet: Texture2D) -> int:
	return maxi(1, floori(float(sheet.get_width()) / sheet.get_height()))


## One frame of a walk or peck sheet; the feet stay where those of the standing picture are.
func _show_frame(sheet: Texture2D, index: int) -> void:
	var cell: float = sheet.get_height()
	if texture != sheet:
		texture = sheet
		region_enabled = true
		offset = _still_offset + Vector2(0, _still.get_height() / 2.0 - FEET + cell / 2.0)
		_shadow.visible = not _shadow.get_meta("never")
		_apply_look()
	region_rect = Rect2(index * cell, 0, cell, cell)


func _look_towards(target: Vector2) -> void:
	if not is_zero_approx(target.x - position.x):
		_looks_right = target.x > position.x
		_apply_look()


func _apply_look() -> void:
	flip_h = _looks_right if texture != _still else _looks_right != _still_looks_right


## A flat ellipse behind the animal at the bottom of the standing picture.
func _add_shadow() -> void:
	_shadow = Node2D.new()
	_shadow.name = "Shadow"
	_shadow.show_behind_parent = true
	_shadow.visible = false
	var radius := Vector2(maxf(2.0, _still.get_width() * SHADOW_WIDTH / 2.0), 0.0)
	radius.y = maxf(1.5, radius.x * 0.35)
	var feet_y: float = _still_offset.y + _still.get_height() / 2.0 - radius.y
	if centered == false:
		feet_y += _still.get_height() / 2.0
	_shadow.position = Vector2(_still_offset.x + (0.0 if centered else _still.get_width() / 2.0), feet_y)
	_shadow.draw.connect(func() -> void:
		var points := PackedVector2Array()
		for i in 16:
			var angle: float = TAU * i / 16.0
			points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		_shadow.draw_colored_polygon(points, SHADOW_COLOR))
	add_child(_shadow)


func _hop() -> void:
	var target: Vector2 = (position + Vector2(randf_range(-hop, hop), randf_range(-hop, hop) * 0.5)).clamp(_home - Vector2.ONE * reach, _home + Vector2.ONE * reach)
	_look_towards(target)
	var tween := create_tween()
	tween.tween_property(self, "position", target, HOP_TIME)
	tween.parallel().tween_property(self, "offset:y", offset.y - HOP_HEIGHT, HOP_TIME * 0.5)
	tween.chain().tween_property(self, "offset:y", offset.y, HOP_TIME * 0.5)
	tween.finished.connect(_wait)
