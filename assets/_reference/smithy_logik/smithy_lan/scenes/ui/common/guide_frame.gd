class_name GuideFrame
extends Control
## Pulsing golden frame over a Control of a window (Guide: "this is the next thing to click").
## Lies over its target as the last child, catches no mouse. Shown while `condition` returns
## true (asked a few times a second). `rect_getter` (optional) gives the framed area in the
## target's coordinates, e.g. one tab of a TabBar; without it the whole target is framed.
## Usage: GuideFrame.attach(button, func() -> bool: return Guide.is_target("recipe:x")).

const COLOR: Color = Color(1.0, 0.82, 0.3)
const CHECK_MSEC: int = 200
## Pulses per second (times TAU).
const PULSE_SPEED: float = 5.0

var condition: Callable
var rect_getter: Callable
var _next_check: int = 0


static func attach(target: Control, show_when: Callable, area: Callable = Callable()) -> GuideFrame:
	var frame := GuideFrame.new()
	frame.condition = show_when
	frame.rect_getter = area
	target.add_child(frame)
	return frame


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Runs while hidden too, so the frame appears by itself. While its target is not on screen
## (closed window, other page) nothing is checked; it asks again right when the target shows.
func _process(_delta: float) -> void:
	var target := get_parent() as CanvasItem
	if target and not target.is_visible_in_tree():
		_next_check = 0
		return
	var now: int = Time.get_ticks_msec()
	if now >= _next_check:
		# The first check right away, then spread: hundreds of frames (one per recipe button)
		# asking in the same frame made the game stutter every CHECK_MSEC.
		_next_check = now + (CHECK_MSEC if _next_check > 0 else 1 + randi() % CHECK_MSEC)
		var shown: bool = condition.is_valid() and bool(condition.call())
		if shown != visible:
			visible = shown
	if visible:
		queue_redraw()


func _draw() -> void:
	var area: Rect2 = rect_getter.call() if rect_getter.is_valid() else Rect2(Vector2.ZERO, size)
	var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
	draw_rect(area.grow(1.0), Color(COLOR, pulse), false, 1.0)
	draw_rect(area, Color(COLOR, pulse * 0.45), false, 1.0)
