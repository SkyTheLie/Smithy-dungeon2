class_name TimeCompass
extends Control
## Time strip like a compass: the hours scroll past a fixed needle in the middle.
## One tick per hour, the sun marks noon, the moon midnight, 6 and 18 are written out.

const PIXELS_PER_HOUR: float = 12.0
## Native size of the pixel font (sharp only at multiples of it).
const FONT_SIZE: int = 11
const SUN: Texture2D = preload("res://assets/ui/icon_sun.png")
const MOON: Texture2D = preload("res://assets/ui/icon_moon.png")
const COLOR_BACKGROUND: Color = Color(0.13, 0.075, 0.12, 0.85)
const COLOR_TICK: Color = Color(0.55, 0.42, 0.36)
const COLOR_NEEDLE: Color = Color(1.0, 0.91, 0.63)
const LABELED_HOURS: Dictionary = {6: "6", 18: "18"}


func _ready() -> void:
	clip_contents = true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	var now: float = GameState.day_cycle.get_hour()
	var middle: float = size.x / 2.0
	var half_range: int = ceili(middle / PIXELS_PER_HOUR) + 1
	var font: Font = get_theme_default_font()
	for hour in range(floori(now) - half_range, ceili(now) + half_range + 1):
		var x: float = roundf(middle + (hour - now) * PIXELS_PER_HOUR)
		var clock_hour: int = posmod(hour, 24)
		if clock_hour == 12:
			draw_texture(SUN, Vector2(x - SUN.get_width() / 2.0, roundf((size.y - SUN.get_height()) / 2.0)))
		elif clock_hour == 0:
			draw_texture(MOON, Vector2(x - MOON.get_width() / 2.0, roundf((size.y - MOON.get_height()) / 2.0)))
		elif LABELED_HOURS.has(clock_hour):
			var text: String = LABELED_HOURS[clock_hour]
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
			draw_string(font, Vector2(x - width / 2.0, size.y - 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_TICK)
		else:
			draw_line(Vector2(x, size.y - 4.0), Vector2(x, size.y), COLOR_TICK)
	# needle: small triangles at the top and bottom edge
	draw_colored_polygon(PackedVector2Array([Vector2(middle - 3, 0), Vector2(middle + 3, 0), Vector2(middle, 3)]), COLOR_NEEDLE)
	draw_colored_polygon(PackedVector2Array([Vector2(middle - 3, size.y), Vector2(middle + 3, size.y), Vector2(middle, size.y - 3)]), COLOR_NEEDLE)
