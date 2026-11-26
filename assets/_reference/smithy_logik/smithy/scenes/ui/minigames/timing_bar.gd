class_name TimingBar
extends Control
## Timing scale of the forging minigame: green zone, yellow zone on both sides of it,
## and a marker that moves from left (0.0) to right (1.0).
## Size and position of the zones come from GameState.player_stats and the difficulty of the
## material (set via configure()).

enum Zone { MISS, YELLOW, GREEN }

const COLOR_BACKGROUND: Color = Color(0.15, 0.13, 0.12)
const COLOR_YELLOW: Color = Color(0.9, 0.8, 0.25)
const COLOR_GREEN: Color = Color(0.35, 0.8, 0.3)
const COLOR_BORDER: Color = Color(0.55, 0.45, 0.35)
const COLOR_MARKER: Color = Color(1, 1, 1)

## Width of the green zone as a fraction of the whole scale.
var green_width: float = 0.05
## Width of the yellow zone on EACH side of the green zone.
var yellow_width: float = 0.05
## Middle of the green zone (0.0 = left, 1.0 = right).
var center: float = 0.5

## Marker position from 0.0 (left) to 1.0 (right).
var marker: float = 0.0:
	set(value):
		marker = value
		queue_redraw()


## `difficulty`: ForgeQuality.get_difficulty entry, its "green" / "yellow" factors shrink the
## zones (0 = no green zone at all).
func configure(stats: PlayerStats, difficulty: Dictionary = {}) -> void:
	green_width = stats.get_green_zone_width() * float(difficulty.get("green", 1.0))
	yellow_width = stats.get_yellow_zone_width() * float(difficulty.get("yellow", 1.0))
	center = stats.zone_center
	queue_redraw()


func get_zone(marker_position: float) -> Zone:
	var distance: float = absf(marker_position - center)
	if green_width > 0.0 and distance <= green_width / 2.0:
		return Zone.GREEN
	if distance <= green_width / 2.0 + yellow_width:
		return Zone.YELLOW
	return Zone.MISS


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var yellow_half: float = green_width / 2.0 + yellow_width
	draw_rect(Rect2(0, 0, w, h), COLOR_BACKGROUND)
	draw_rect(Rect2(w * (center - yellow_half), 0, w * yellow_half * 2.0, h), COLOR_YELLOW)
	draw_rect(Rect2(w * (center - green_width / 2.0), 0, w * green_width, h), COLOR_GREEN)
	draw_rect(Rect2(0, 0, w, h), COLOR_BORDER, false, 1.0)
	draw_rect(Rect2(marker * w - 1.0, -2.0, 2.0, h + 4.0), COLOR_MARKER)
