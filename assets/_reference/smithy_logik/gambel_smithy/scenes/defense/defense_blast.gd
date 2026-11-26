class_name DefenseBlast
extends Node2D
## The look of an area hit in the forge defense (fireball impact, quake, lightning): a filled
## circle that flashes and a ring that grows to the hit radius, then everything fades.
## Only a picture: the damage is done by the game.

const TIME: float = 0.45

var radius: float = 30.0
var color: Color = Color.ORANGE
## 0 → 1 while it plays.
var part: float = 0.0:
	set(value):
		part = value
		queue_redraw()


func play(at: Vector2, hit_radius: float, tint: Color) -> void:
	position = at
	radius = hit_radius
	color = tint
	z_index = 6
	var grow := create_tween()
	grow.tween_property(self, "part", 1.0, TIME).set_ease(Tween.EASE_OUT)
	grow.tween_callback(queue_free)


func _draw() -> void:
	var fade: float = 1.0 - part
	draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * part), Color(color, 0.35 * fade))
	draw_arc(Vector2.ZERO, radius * part, 0.0, TAU, 32, Color(color, fade), 2.0)
