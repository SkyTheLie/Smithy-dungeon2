class_name HeartBar
extends Control
## The hearts at the top left: full, half and empty (dark) red hearts of RunState, then the blue
## hearts (full or half).

const HEART: Texture2D = preload("res://assets/sprites/items/arena_heart.png")
const SIZE: float = 18.0
const STEP: float = 17.0
const BLUE := Color(0.45, 0.7, 1.0)
const EMPTY := Color(0.18, 0.12, 0.14, 0.9)

var run: RunState


func setup(run_state: RunState) -> void:
	run = run_state
	run.changed.connect(_on_changed)
	_on_changed()


func _blue_count() -> int:
	return ceili(run.blue / 2.0)


func _on_changed() -> void:
	custom_minimum_size = Vector2(STEP * (run.max_hearts + _blue_count()) + 2.0, SIZE)
	queue_redraw()


func _draw() -> void:
	if run == null:
		return
	for i in run.max_hearts:
		var rect := Rect2(Vector2(i * STEP, 0), Vector2(SIZE, SIZE))
		# empty heart first (dark), the filled part (half = left half) over it
		draw_texture_rect(HEART, rect, false, EMPTY)
		_draw_part(rect, clampi(run.health - i * 2, 0, 2), Color.WHITE)
	for i in _blue_count():
		var rect := Rect2(Vector2((run.max_hearts + i) * STEP, 0), Vector2(SIZE, SIZE))
		_draw_part(rect, clampi(run.blue - i * 2, 0, 2), BLUE)


## `filled`: 2 = whole heart, 1 = left half.
func _draw_part(rect: Rect2, filled: int, tint: Color) -> void:
	var texture_size: Vector2 = HEART.get_size()
	if filled == 2:
		draw_texture_rect(HEART, rect, false, tint)
	elif filled == 1:
		var half := Rect2(rect.position, Vector2(SIZE / 2.0, SIZE))
		draw_texture_rect_region(HEART, half, Rect2(Vector2.ZERO, Vector2(texture_size.x / 2.0, texture_size.y)), tint)
