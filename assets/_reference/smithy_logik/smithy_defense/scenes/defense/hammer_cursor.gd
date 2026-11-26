class_name HammerCursor
extends Node2D
## The round area around the mouse in the forge defense: everything inside it takes the hammer
## blow. The ring fills up again while the hammer is not ready (`ready_part` 0..1). `strike`
## swings the hammer sprite down.

const RING_COLOR := Color(1.0, 0.86, 0.55, 0.9)
const FILL_COLOR := Color(1.0, 0.86, 0.55, 0.12)
const WAIT_COLOR := Color(0.6, 0.6, 0.6, 0.7)
## Hammer raised (its head points left, the node sits at the handle end).
const REST_ANGLE: float = 0.9

var radius: float = 18.0:
	set(value):
		if not is_equal_approx(value, radius):
			radius = value
			queue_redraw()
## 1 = the hammer can strike, below that it is still lifting.
var ready_part: float = 1.0:
	set(value):
		if not is_equal_approx(value, ready_part):
			ready_part = value
			queue_redraw()

@onready var _hammer: Sprite2D = $Hammer


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, FILL_COLOR)
	if ready_part >= 1.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, RING_COLOR, 1.0)
	else:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, WAIT_COLOR, 1.0)
		draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * ready_part, 32, RING_COLOR, 1.0)


## Hammer comes down on the middle of the circle and goes up again.
func strike() -> void:
	_hammer.rotation = REST_ANGLE
	var swing := create_tween()
	swing.tween_property(_hammer, "rotation", 0.0, 0.07)
	swing.tween_property(_hammer, "rotation", REST_ANGLE, 0.25).set_delay(0.08)
