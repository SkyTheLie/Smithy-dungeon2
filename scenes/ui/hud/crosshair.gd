class_name Crosshair
extends Control
## The crosshair in the middle of the screen, set up in the settings (tab "Fadenkreuz") like in
## Counter-Strike 2: style (cross, dot only, off), colour (the five CS2 colours or an own one),
## opacity, length, thickness, gap (also negative), a dot in the middle, a dark outline and its
## thickness, T shape (no line on top). Sizes are pixels of a 1080p screen (the HUD is 360 high,
## so a third of that in HUD units; on bigger screens it grows like the rest of the HUD).
## Saved in user://settings.cfg section "crosshair" (WindowLayout). The same class draws the
## preview in the settings. Redraws when the settings change (Game.crosshair_changed).
## Hit marker (show_hit): a short white X around the middle when a shot hits, red for a kill.

const SECTION: String = "crosshair"
## Pixels of a 1080p screen per HUD unit.
const PIXELS_PER_UNIT: float = 3.0
const STYLES: Array[String] = ["cross", "dot", "off"]
## CS2 cl_crosshaircolor 0..4, then "custom" (custom_color).
const COLORS: Array[String] = ["red", "green", "yellow", "blue", "cyan", "custom"]
const PRESET_COLORS: Dictionary[String, Color] = {
	"red": Color8(250, 50, 50),
	"green": Color8(50, 250, 50),
	"yellow": Color8(250, 250, 50),
	"blue": Color8(50, 50, 250),
	"cyan": Color8(50, 250, 250),
}
const OUTLINE_COLOR := Color(0, 0, 0)
## The look of the game before it could be set (warm white cross with a dot and outline).
const DEFAULTS: Dictionary[String, Variant] = {
	"style": "cross",
	"color": "custom",
	"custom_color": Color(1.0, 0.95, 0.85),
	"alpha": 255,
	"length": 12,
	"thickness": 3,
	"gap": 9,
	"dot": true,
	"outline": true,
	"outline_thickness": 2,
	"t_style": false,
}


## Seconds a hit marker shows.
const HIT_TIME: float = 0.18
const HIT_COLOR := Color(1, 1, 1)
const KILL_COLOR := Color(1.0, 0.25, 0.2)

var _hit_left: float = 0.0
var _hit_killed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.crosshair_changed.connect(queue_redraw)
	set_process(false)


func _draw() -> void:
	draw_at(self, size / 2.0, 1.0)
	if _hit_left > 0.0:
		var center: Vector2 = size / 2.0
		var grow: float = 1.0 + (1.0 - _hit_left / HIT_TIME) * 0.4
		var color: Color = KILL_COLOR if _hit_killed else HIT_COLOR
		color.a = clampf(_hit_left / HIT_TIME * 1.5, 0.0, 1.0)
		for dir: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var from: Vector2 = center + dir.normalized() * 4.0 * grow
			var to: Vector2 = center + dir.normalized() * 8.0 * grow
			draw_line(from, to, Color(0, 0, 0, color.a * 0.7), 2.4)
			draw_line(from, to, color, 1.2)


## A shot hit (killed: it was the last hit): the X flashes around the middle.
func show_hit(killed: bool) -> void:
	_hit_left = HIT_TIME
	_hit_killed = killed or (_hit_killed and _hit_left > 0.0)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_hit_left -= delta
	if _hit_left <= 0.0:
		_hit_left = 0.0
		_hit_killed = false
		set_process(false)
	queue_redraw()


## A value of the settings (DEFAULTS if not set).
static func get_value(key: String) -> Variant:
	return WindowLayout.get_setting(SECTION, key, DEFAULTS.get(key))


static func set_value(key: String, value: Variant) -> void:
	WindowLayout.set_setting(SECTION, key, value)
	Game.crosshair_changed.emit()


## Every value back to DEFAULTS.
static func reset() -> void:
	for key: String in DEFAULTS:
		WindowLayout.set_setting(SECTION, key, null)
	Game.crosshair_changed.emit()


## The colour with its opacity.
static func color() -> Color:
	var preset: String = String(get_value("color"))
	var base: Color = PRESET_COLORS[preset] if PRESET_COLORS.has(preset) else get_value("custom_color") as Color
	base.a = clampf(float(get_value("alpha")) / 255.0, 0.0, 1.0)
	return base


## Draws the crosshair on `item` around `center`; `zoom` makes it bigger (the preview).
static func draw_at(item: CanvasItem, center: Vector2, zoom: float) -> void:
	var style: String = String(get_value("style"))
	if style == "off":
		return
	var unit: float = zoom / PIXELS_PER_UNIT
	var thick: float = maxf(1.0, float(get_value("thickness"))) * unit
	var length: float = maxf(0.0, float(get_value("length"))) * unit
	var gap: float = float(get_value("gap")) * unit
	var outline: float = float(get_value("outline_thickness")) * unit if bool(get_value("outline")) else 0.0
	var fill: Color = color()
	var shadow := Color(OUTLINE_COLOR, fill.a)
	var rects: Array[Rect2] = []
	if style == "cross" and length > 0.0:
		var dirs: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]
		if not bool(get_value("t_style")):
			dirs.append(Vector2.UP)
		for dir: Vector2 in dirs:
			var start: Vector2 = center + dir * (thick / 2.0 + gap)
			var end: Vector2 = start + dir * length
			var across: Vector2 = Vector2(dir.y, dir.x).abs() * thick
			rects.append(Rect2(start.min(end) - across / 2.0, (end - start).abs() + across))
	if style == "dot" or bool(get_value("dot")):
		rects.append(Rect2(center - Vector2(thick, thick) / 2.0, Vector2(thick, thick)))
	if outline > 0.0:
		for rect: Rect2 in rects:
			item.draw_rect(rect.grow(outline), shadow)
	for rect: Rect2 in rects:
		item.draw_rect(rect, fill)
