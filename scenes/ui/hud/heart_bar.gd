class_name HeartBar
extends Control
## The life at the top left (inside still called "hearts"): glowing coal pieces of RunState (full, half,
## empty = cold and dark), then the mud layers (the old blue hearts), then the iron coal from the
## equipment (the old white shield hearts), each full or half.

const COAL: Texture2D = preload("res://assets/sprites/ui/life/coal.png")
const MUD: Texture2D = preload("res://assets/sprites/ui/life/mud.png")
const IRON: Texture2D = preload("res://assets/sprites/ui/life/iron.png")
const SIZE: float = 30.0
const STEP: float = 28.0
## Burnt-out coal: the coal picture made dark and grey.
const EMPTY := Color(0.2, 0.18, 0.18, 0.9)

var run: RunState


func setup(run_state: RunState) -> void:
	run = run_state
	run.changed.connect(_on_changed)
	_on_changed()


func _shield_count() -> int:
	return ceili(run.shield / 2.0)


func _blue_count() -> int:
	return ceili(run.blue / 2.0)


func _on_changed() -> void:
	custom_minimum_size = Vector2(STEP * (run.max_hearts + _blue_count() + _shield_count()) + 2.0, SIZE)
	queue_redraw()


func _draw() -> void:
	if run == null:
		return
	for i in run.max_hearts:
		var rect := Rect2(Vector2(i * STEP, 0), Vector2(SIZE, SIZE))
		# cold coal first (dark), the glowing part (half = left half) over it
		draw_texture_rect(COAL, rect, false, EMPTY)
		_draw_part(rect, clampi(run.health - i * 2, 0, 2), COAL)
	for i in _blue_count():
		var rect := Rect2(Vector2((run.max_hearts + i) * STEP, 0), Vector2(SIZE, SIZE))
		_draw_part(rect, clampi(run.blue - i * 2, 0, 2), MUD)
	for i in _shield_count():
		var rect := Rect2(Vector2((run.max_hearts + _blue_count() + i) * STEP, 0), Vector2(SIZE, SIZE))
		_draw_part(rect, clampi(run.shield - i * 2, 0, 2), IRON)


## `filled`: 2 = whole piece, 1 = left half.
func _draw_part(rect: Rect2, filled: int, picture: Texture2D) -> void:
	var texture_size: Vector2 = picture.get_size()
	if filled == 2:
		draw_texture_rect(picture, rect, false)
	elif filled == 1:
		var half := Rect2(rect.position, Vector2(SIZE / 2.0, SIZE))
		draw_texture_rect_region(picture, half, Rect2(Vector2.ZERO, Vector2(texture_size.x / 2.0, texture_size.y)))
