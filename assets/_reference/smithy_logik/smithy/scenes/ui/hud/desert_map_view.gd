class_name DesertMapView
extends Control
## The drawing on the sand map (DesertMapWindow): one row per route of the desert maze whose
## start the player has seen (DesertMaze.get_map_routes). A row shows the place it starts at, one
## arrow per step the player has walked (a dot for a step he has not walked yet) and the place it
## ends at ("?" while unknown). The desert is no grid (the same dune comes back on other ways), so
## the map shows the ways, not a picture of the land.

const ROW_HEIGHT: float = 20.0
const NAME_WIDTH: float = 64.0
const STEP_WIDTH: float = 13.0
const FONT_SIZE: int = 11
const ANGLES: Dictionary = {"N": -PI / 2.0, "O": 0.0, "S": PI / 2.0, "W": PI}

const COLOR_PAPER: Color = Color(0.86, 0.76, 0.56)
const COLOR_PAPER_DARK: Color = Color(0.72, 0.6, 0.4)
const COLOR_INK: Color = Color(0.32, 0.2, 0.12)
const COLOR_FAINT: Color = Color(0.32, 0.2, 0.12, 0.35)
const COLOR_MARK: Dictionary = {
	"sign": Color(0.55, 0.36, 0.18), "bones": Color(0.95, 0.93, 0.85), "ruins": Color(0.7, 0.62, 0.5),
	"chest": Color(0.85, 0.6, 0.15), "open": Color(0.5, 0.45, 0.38), "town": Color(0.75, 0.25, 0.2),
}


func get_rows() -> Array[Dictionary]:
	return GameState.desert.get_map_routes()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_PAPER)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_PAPER_DARK, false, 2.0)
	var font: Font = get_theme_default_font()
	var rows: Array[Dictionary] = get_rows()
	if rows.is_empty():
		draw_string(font, Vector2(8, 18), Language.translate("Noch leer. Lauf los, die Karte zeichnet mit."), HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 16.0, FONT_SIZE, COLOR_FAINT)
		return
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y: float = 6.0 + i * ROW_HEIGHT + ROW_HEIGHT / 2.0
		_draw_place(font, Vector2(6, y), row["from"], row["from_mark"])
		var moves: Array = row["moves"]
		var known: Array = row["known"]
		for step in moves.size():
			var center := Vector2(6.0 + NAME_WIDTH + step * STEP_WIDTH + STEP_WIDTH / 2.0, y)
			if known[step]:
				_draw_arrow(center, ANGLES[moves[step]])
			else:
				draw_circle(center, 1.5, COLOR_FAINT)
		_draw_place(font, Vector2(6.0 + NAME_WIDTH + moves.size() * STEP_WIDTH + 4.0, y), row["to"], row["to_mark"])


## A small coloured mark (what stands there) and the place's name.
func _draw_place(font: Font, at: Vector2, place_name: String, mark: String) -> void:
	if COLOR_MARK.has(mark):
		draw_rect(Rect2(at + Vector2(0, -3), Vector2(6, 6)), COLOR_INK)
		draw_rect(Rect2(at + Vector2(1, -2), Vector2(4, 4)), COLOR_MARK[mark])
	draw_string(font, at + Vector2(9, 4), place_name, HORIZONTAL_ALIGNMENT_LEFT, NAME_WIDTH - 12.0, FONT_SIZE,
			COLOR_INK if place_name != "?" else COLOR_FAINT)


func _draw_arrow(center: Vector2, angle: float) -> void:
	var forward := Vector2.from_angle(angle)
	var side: Vector2 = forward.orthogonal()
	draw_line(center - forward * 4.0, center + forward * 1.0, COLOR_INK, 2.0)
	draw_colored_polygon(PackedVector2Array([center + forward * 5.0, center + forward * 1.0 + side * 3.0,
			center + forward * 1.0 - side * 3.0]), COLOR_INK)
