class_name UiJuice
extends RefCounted
## A little life for every button of the game (Game hooks it on every new button): the mouse
## over it makes it a bit bigger and brighter, pressing squashes it, letting go springs back.
## Only the look; what the button does stays the same. Disabled buttons stay still.

const HOVER_SCALE: float = 1.06
const PRESS_SCALE: float = 0.93
const HOVER_TINT := Color(1.12, 1.08, 1.0)
const TIME: float = 0.09


static func attach(button: BaseButton) -> void:
	if button.has_meta("juice"):
		return
	button.set_meta("juice", true)
	button.mouse_entered.connect(_to.bind(button, HOVER_SCALE, HOVER_TINT))
	button.mouse_exited.connect(_to.bind(button, 1.0, Color.WHITE))
	button.button_down.connect(_to.bind(button, PRESS_SCALE, HOVER_TINT))
	button.button_up.connect(func() -> void:
			var inside: bool = button.is_inside_tree() and button.get_global_rect().has_point(button.get_global_mouse_position())
			_to(button, HOVER_SCALE if inside else 1.0, HOVER_TINT if inside else Color.WHITE))


static func _to(button: BaseButton, target: float, tint: Color) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	if button.disabled:
		target = 1.0
		tint = Color.WHITE
	button.pivot_offset = button.size / 2.0
	var tween: Tween = button.create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE * target, TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "self_modulate", tint, TIME)
