class_name ColorWheel
extends Control
## Small colour picker: a wheel for hue (angle) and saturation (distance from the middle) and a bar
## to its right for the brightness. Click or drag in either. While dragging, color_changed comes at
## most every DRAG_INTERVAL seconds (listeners may bake sprites), and once more on release.

signal color_changed(color: Color)

const WHEEL_SIZE: int = 56
const BAR_WIDTH: int = 8
const GAP: int = 4
const DRAG_INTERVAL: float = 0.08
const MARKER_COLOR: Color = Color(1, 1, 1)
const MARKER_SHADOW: Color = Color(0.08, 0.04, 0.08)

var hue: float = 0.0
var saturation: float = 0.0
var value: float = 1.0

static var _wheel_texture: Texture2D
## "wheel" or "bar" while the mouse button is held, else "".
var _dragging: String = ""
var _last_emit: float = 0.0
var _pending: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(WHEEL_SIZE + GAP + BAR_WIDTH, WHEEL_SIZE)
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	if _wheel_texture == null:
		_wheel_texture = _make_wheel()


func get_color() -> Color:
	return Color.from_hsv(hue, saturation, value)


## Shows a colour without sending color_changed.
func set_color(color: Color) -> void:
	hue = color.h
	saturation = color.s
	value = color.v
	queue_redraw()


func _process(_delta: float) -> void:
	if _pending and Time.get_ticks_msec() / 1000.0 - _last_emit >= DRAG_INTERVAL:
		_emit()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_dragging = "bar" if button.position.x >= WHEEL_SIZE + GAP / 2.0 else "wheel"
			_pick(button.position)
		elif not _dragging.is_empty():
			_dragging = ""
			_emit()
		accept_event()
	elif event is InputEventMouseMotion and not _dragging.is_empty():
		_pick((event as InputEventMouseMotion).position)
		accept_event()


func _pick(at: Vector2) -> void:
	if _dragging == "bar":
		value = clampf(1.0 - at.y / WHEEL_SIZE, 0.0, 1.0)
	else:
		var offset: Vector2 = at - Vector2.ONE * WHEEL_SIZE / 2.0
		hue = fposmod(offset.angle() / TAU, 1.0)
		saturation = clampf(offset.length() / (WHEEL_SIZE / 2.0), 0.0, 1.0)
	_pending = true
	queue_redraw()


func _emit() -> void:
	_pending = false
	_last_emit = Time.get_ticks_msec() / 1000.0
	color_changed.emit(get_color())


func _draw() -> void:
	# Multiplying by the brightness is the same as lowering the HSV value of every pixel.
	draw_texture(_wheel_texture, Vector2.ZERO, Color(value, value, value))
	var bar_x: float = WHEEL_SIZE + GAP
	for y in WHEEL_SIZE:
		draw_rect(Rect2(bar_x, y, BAR_WIDTH, 1), Color.from_hsv(hue, saturation, 1.0 - float(y) / WHEEL_SIZE))
	var center: Vector2 = Vector2.ONE * WHEEL_SIZE / 2.0
	var point: Vector2 = center + Vector2.from_angle(hue * TAU) * saturation * WHEEL_SIZE / 2.0
	draw_rect(Rect2(point.floor() - Vector2(2, 2), Vector2(5, 5)), MARKER_SHADOW, false, 1.0)
	draw_rect(Rect2(point.floor() - Vector2(1, 1), Vector2(3, 3)), MARKER_COLOR, false, 1.0)
	var marker_y: float = floorf((1.0 - value) * (WHEEL_SIZE - 1))
	draw_rect(Rect2(bar_x - 1, marker_y - 1, BAR_WIDTH + 2, 3), MARKER_SHADOW, false, 1.0)
	draw_rect(Rect2(bar_x, marker_y, BAR_WIDTH, 1), MARKER_COLOR)


## Hue around, saturation outwards, full brightness; outside the circle transparent.
static func _make_wheel() -> Texture2D:
	var image := Image.create(WHEEL_SIZE, WHEEL_SIZE, false, Image.FORMAT_RGBA8)
	var radius: float = WHEEL_SIZE / 2.0
	for y in WHEEL_SIZE:
		for x in WHEEL_SIZE:
			var offset := Vector2(x + 0.5, y + 0.5) - Vector2.ONE * radius
			if offset.length() <= radius:
				image.set_pixel(x, y, Color.from_hsv(fposmod(offset.angle() / TAU, 1.0), offset.length() / radius, 1.0))
	return ImageTexture.create_from_image(image)
