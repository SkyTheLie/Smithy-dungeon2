class_name UiScalePreview
extends CanvasLayer
## Yellow frame that shows where a HUD part is and how big it is, while the player changes its
## size in the settings (tab "Oberfläche", UiScale.show_preview). Also for closed windows: the
## frame stands where the window would open, at the size it would have. Under the frame its name
## and size ("Inventar 80 %"). Fades out a moment after the last change.
## Lives on its own CanvasLayer one layer above the highest window (like ItemPicker), so the
## settings window never covers it. Built by the HUD.

const COLOR_FRAME: Color = Color(1.0, 0.85, 0.2)
const COLOR_FILL: Color = Color(1.0, 0.85, 0.2, 0.08)
const COLOR_TEXT_BACK: Color = Color(0.1, 0.08, 0.05, 0.85)
const FRAME_WIDTH: float = 2.0
const FONT_SIZE: int = 11
## Seconds the frame stays fully visible after the last change, then the fade-out.
const HOLD_TIME: float = 1.5
const FADE_TIME: float = 0.4

var _canvas: Control
var _rect: Rect2 = Rect2()
var _caption: String = ""
## Seconds since the last show_frame (the frame fades out after HOLD_TIME).
var _age: float = 0.0


func _ready() -> void:
	# The game is paused while the settings window is open.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_frame)
	add_child(_canvas)
	visible = false
	set_process(false)


## Shows the frame around `control` (also if it is closed) with `caption` below it.
func show_frame(control: Control, caption: String) -> void:
	_rect = get_screen_rect(control)
	_caption = caption
	_age = 0.0
	layer = WindowTitleBar.get_top_layer() + 1
	_canvas.modulate.a = 1.0
	visible = true
	set_process(true)
	_canvas.queue_redraw()


func hide_frame() -> void:
	visible = false
	set_process(false)


## The frame that show_frame drew last (screen pixels; tests).
func get_frame_rect() -> Rect2:
	return _rect


func is_shown() -> bool:
	return visible


## Where `control` is (or would be, if it is closed) on screen, at its current UI size: its own
## size (at least what its content needs) through its transform (position, scale, pivot), kept
## on screen like WindowTitleBar.keep_on_screen does when the window opens.
static func get_screen_rect(control: Control) -> Rect2:
	var size: Vector2 = control.size.max(control.get_combined_minimum_size())
	var xform: Transform2D = control.get_global_transform_with_canvas()
	var rect := Rect2(xform * Vector2.ZERO, Vector2.ZERO).expand(xform * size)
	var screen: Vector2 = control.get_viewport_rect().size
	if rect.size.x <= screen.x:
		rect.position.x = clampf(rect.position.x, 0.0, screen.x - rect.size.x)
	if rect.size.y <= screen.y:
		rect.position.y = clampf(rect.position.y, 0.0, screen.y - rect.size.y)
	return rect


func _process(delta: float) -> void:
	_age += delta
	if _age < HOLD_TIME:
		return
	var fade: float = 1.0 - (_age - HOLD_TIME) / FADE_TIME
	if fade <= 0.0:
		hide_frame()
		return
	_canvas.modulate.a = fade


func _draw_frame() -> void:
	_canvas.draw_rect(_rect, COLOR_FILL)
	_canvas.draw_rect(_rect.grow(-FRAME_WIDTH / 2.0), COLOR_FRAME, false, FRAME_WIDTH)
	if _caption.is_empty():
		return
	var font: Font = _canvas.get_theme_default_font()
	var text_size: Vector2 = font.get_string_size(_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var screen: Vector2 = _canvas.get_viewport_rect().size
	# Below the frame; at the bottom of the screen inside it.
	var top_left := Vector2(_rect.position.x, _rect.end.y + 2.0)
	if top_left.y + text_size.y + 2.0 > screen.y:
		top_left.y = _rect.end.y - text_size.y - 4.0
	top_left.x = clampf(top_left.x, 0.0, maxf(0.0, screen.x - text_size.x - 4.0))
	_canvas.draw_rect(Rect2(top_left, text_size + Vector2(4, 2)), COLOR_TEXT_BACK)
	_canvas.draw_string(font, top_left + Vector2(2, font.get_ascent(FONT_SIZE) + 1.0), _caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_FRAME)
