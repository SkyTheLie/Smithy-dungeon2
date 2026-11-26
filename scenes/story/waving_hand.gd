class_name WavingHand
extends Control
## Egon's raised arm, drawn on top of his sprite (npcs/black_market_dealer.png, 48x48), waving
## back and forth. A child of the sprite's TextureRect, so it scales with him; all numbers are
## sprite pixels. It also paints over the hand that hangs down in the picture.

## Where the arm turns: the shoulder on the right side of the picture, in sprite pixels.
const SHOULDER := Vector2(30, 23)
## The hanging hand of the picture, painted over in coat colour.
const OLD_HAND := Rect2(28, 29, 3, 3)
const COAT_COLOR := Color(0.13, 0.13, 0.17)
const SKIN_COLOR := Color(0.94, 0.72, 0.6)
const OUTLINE_COLOR := Color(0.05, 0.04, 0.06)
## The arm's angle from straight up (degrees), swinging between these two.
const ANGLE_FROM: float = 20.0
const ANGLE_TO: float = 60.0
## Seconds for one swing (there or back).
const SWING_TIME: float = 0.28

var _arm: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(48, 48)
	_arm = Control.new()
	_arm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arm.position = SHOULDER
	_arm.rotation_degrees = ANGLE_FROM
	_arm.draw.connect(_draw_arm)
	add_child(_arm)
	var swing := create_tween().set_loops()
	swing.tween_property(_arm, "rotation_degrees", ANGLE_TO, SWING_TIME).set_trans(Tween.TRANS_SINE)
	swing.tween_property(_arm, "rotation_degrees", ANGLE_FROM, SWING_TIME).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	draw_rect(OLD_HAND, COAT_COLOR)


## Sleeve from the shoulder straight up (the arm node turns it), the open hand on top.
func _draw_arm() -> void:
	_arm.draw_rect(Rect2(-2.5, -10, 5, 11), OUTLINE_COLOR)
	_arm.draw_rect(Rect2(-1.5, -9, 3, 9), COAT_COLOR)
	_arm.draw_rect(Rect2(-2.5, -14, 5, 5), OUTLINE_COLOR)
	_arm.draw_rect(Rect2(-1.5, -13, 3, 3), SKIN_COLOR)
