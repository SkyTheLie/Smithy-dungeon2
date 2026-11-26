class_name PanZoomView
extends Control
## A window onto a big picture (the skill trees of the forge defense), like a map: press anywhere
## inside (also on a button) with the left, middle or right button, pull more than DRAG_THRESHOLD px,
## and the picture follows the mouse, in every direction; the mouse wheel zooms in and out around the
## pointer. The picture is the first Control child (any size, its `custom_minimum_size` counts); it
## is moved and scaled, never cut to the view. At least KEEP px of it always stay in view.
## A press that turned into a drag must not buy anything: buttons inside ask `just_dragged()` in
## their `pressed` handler (the release that ends a drag and the button's `pressed` come in the same
## frame). Works on the phone too (touch is turned into mouse events). `backdrop` is drawn behind.

const DRAG_THRESHOLD: float = 6.0
const DRAG_BUTTONS: Array[MouseButton] = [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 2.5
const ZOOM_STEP: float = 1.15
const KEEP: float = 40.0
## Space above the picture when it is placed the first time.
const TOP_GAP: float = 6.0

@export var backdrop: StyleBox

## not saved on purpose: where the picture lies and how big, only while the window lives.
var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var _placed: bool = false
var _pressing: bool = false
var _dragging: bool = false
var _press_mouse := Vector2.ZERO
var _press_pan := Vector2.ZERO
## Frame in which the last drag ended (-1 = none yet).
var _drag_end_frame: int = -1


func _ready() -> void:
	clip_contents = true
	resized.connect(_apply)
	var picture: Control = content()
	if picture != null:
		picture.minimum_size_changed.connect(_apply)
	_apply.call_deferred()


## The picture (first Control child), or null.
func content() -> Control:
	for child in get_children():
		if child is Control:
			return child
	return null


## True in the frame a drag ended: a button's `pressed` in that frame is no click.
func just_dragged() -> bool:
	return _dragging or _drag_end_frame == Engine.get_process_frames()


## The PanZoomView `node` sits in, or null.
static func around(node: Node) -> PanZoomView:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is PanZoomView:
			return parent
		parent = parent.get_parent()
	return null


## Zooms to `new_zoom` (clamped) keeping the picture point under `at` (local position) in place.
func zoom_at(new_zoom: float, at: Vector2) -> void:
	new_zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	var point: Vector2 = (at - pan) / zoom
	zoom = new_zoom
	pan = at - point * zoom
	_apply()


## The picture centred across, its top near the top of the view, at zoom 1.
func reset_view() -> void:
	var picture: Control = content()
	if picture == null or size.x <= 0.0:
		return
	zoom = 1.0
	pan = Vector2((size.x - picture.get_combined_minimum_size().x) / 2.0, TOP_GAP)
	_placed = true
	_apply()


func _draw() -> void:
	if backdrop != null:
		draw_style_box(backdrop, Rect2(Vector2.ZERO, size))


## Puts the picture at `pan` with `zoom`, kept (partly) in view.
func _apply() -> void:
	var picture: Control = content()
	if picture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	if not _placed:
		reset_view()
		return
	var picture_size: Vector2 = picture.get_combined_minimum_size()
	picture.size = picture_size
	var shown: Vector2 = picture_size * zoom
	var keep: Vector2 = Vector2(minf(KEEP, shown.x), minf(KEEP, shown.y))
	pan.x = clampf(pan.x, keep.x - shown.x, size.x - keep.x)
	pan.y = clampf(pan.y, keep.y - shown.y, size.y - keep.y)
	picture.position = pan
	picture.scale = Vector2(zoom, zoom)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_pressing = false
		_dragging = false
		return
	var press := event as InputEventMouseButton
	if press != null and press.pressed and (press.button_index == MOUSE_BUTTON_WHEEL_UP or press.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if _mouse_inside():
			zoom_at(zoom * (ZOOM_STEP if press.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP), get_local_mouse_position())
			get_viewport().set_input_as_handled()
		return
	if press != null and DRAG_BUTTONS.has(press.button_index):
		if press.pressed:
			if not _pressing and _mouse_inside():
				_pressing = true
				_press_mouse = get_global_mouse_position()
				_press_pan = pan
		elif _pressing:
			_pressing = false
			if _dragging:
				_dragging = false
				_drag_end_frame = Engine.get_process_frames()
				mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	if event is InputEventMouseMotion and _pressing:
		var moved: Vector2 = (get_global_mouse_position() - _press_mouse) / get_global_transform().get_scale()
		if not _dragging and moved.length() >= DRAG_THRESHOLD:
			_dragging = true
			mouse_default_cursor_shape = Control.CURSOR_DRAG
		if _dragging:
			pan = _press_pan + moved
			_apply()


## The mouse is over this view (not over another window lying on top of it).
func _mouse_inside() -> bool:
	if not get_global_rect().has_point(get_global_mouse_position()):
		return false
	var hovered: Control = get_viewport().gui_get_hovered_control()
	return hovered != null and (hovered == self or is_ancestor_of(hovered))
