class_name ResizeGrip
extends Control
## Small corner handle (bottom right of a window): drag it with the left mouse button to make the
## window bigger or smaller. The window is the top-level Control that contains the grip (the
## direct child of the CanvasLayer, like WindowTitleBar). The size is stored in
## user://settings.cfg (WindowLayout, section SECTION) and comes back on the next opening,
## after scene changes and restarts. It never gets smaller than the window's content needs and
## never reaches past the screen.

const SECTION: String = "window_sizes"
const DOT_SIZE: float = 1.0

## Name under which the size is stored. Empty = "<CanvasLayer>/<window>".
@export var window_id: String = ""

var _dragging: bool = false


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(8, 8))
	mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	_restore_size()


func _restore_size() -> void:
	# Wait one frame: the window gets its own size (and pinned position) first.
	await get_tree().process_frame
	if not is_inside_tree():  # the scene changed in that frame
		return
	if WindowLayout.has_setting(SECTION, _get_window_id()):
		_apply_size(WindowLayout.get_setting(SECTION, _get_window_id(), Vector2.ZERO))


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		if not _dragging:
			WindowLayout.set_setting(SECTION, _get_window_id(), _get_window().size)
		accept_event()
	elif _dragging and event is InputEventMouseMotion:
		# the event comes in the window's own (unscaled) coordinates, like its size
		_apply_size(_get_window().size + (event as InputEventMouseMotion).relative)
		accept_event()


## Sets the window size, at least what its content needs, at most up to the screen edge.
func _apply_size(new_size: Vector2) -> void:
	var window: Control = _get_window()
	var visual: Rect2 = UiScale.get_visual_rect(window)
	var largest: Vector2 = (get_viewport_rect().size - visual.position) / window.scale
	var smallest: Vector2 = window.get_combined_minimum_size()
	window.size = new_size.min(largest).max(smallest)


func _draw() -> void:
	# Three short diagonal rows of dots, like the grip of a desktop window.
	var color: Color = get_theme_color(&"font_color", &"Label")
	color.a = 0.7
	for row in 3:
		for i in row + 1:
			var x: float = size.x - 2.0 - (row - i) * 2.0 - DOT_SIZE
			var y: float = size.y - 2.0 - i * 2.0 - DOT_SIZE
			draw_rect(Rect2(x, y, DOT_SIZE, DOT_SIZE), color)


func _get_window_id() -> String:
	if not window_id.is_empty():
		return window_id
	var window: Control = _get_window()
	return "%s/%s" % [window.get_parent().name, window.name]


func _get_window() -> Control:
	var node: Node = self
	while node.get_parent() and not node.get_parent() is CanvasLayer:
		node = node.get_parent()
	return node as Control
