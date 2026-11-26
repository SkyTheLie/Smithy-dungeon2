extends Control
## Small crosshair in the middle of the screen (a dot with four short lines, dark outline).

const GAP: float = 3.0
const LENGTH: float = 4.0


func _draw() -> void:
	var c: Vector2 = size / 2.0
	for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(c + dir * GAP, c + dir * (GAP + LENGTH), Color(0, 0, 0, 0.7), 3.0)
	for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(c + dir * GAP, c + dir * (GAP + LENGTH), Color(1, 0.95, 0.85), 1.0)
	draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.6, 0.3))
