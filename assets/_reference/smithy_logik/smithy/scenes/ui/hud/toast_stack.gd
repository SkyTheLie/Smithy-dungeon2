class_name ToastStack
extends VBoxContainer
## Messages at the bottom of the screen, just above the action bar (HUD): each one in its own box,
## the newest at the bottom, gone after SECONDS. A shade runs through the box from left to right
## while its time runs out. While the mouse is on any of the boxes, all of them wait.
## More than MAX_SHOWN messages wait in a queue; the same text is never shown twice at once.

const SECONDS: float = 3.0
const MAX_SHOWN: int = 4
## Width of the text in a box (longer messages wrap).
const TEXT_WIDTH: float = 290.0
const FONT_SIZE: int = 11
const SHADE: Color = Color(0, 0, 0, 0.35)

var _queue: Array[String] = []


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)


func show_message(text: String) -> void:
	if text.is_empty() or _queue.has(text) or has_message(text):
		return
	_queue.append(text)
	_fill()


## Whether a box with this text is on screen.
func has_message(text: String) -> bool:
	return get_children().any(func(box: Node) -> bool: return box is ToastBox and (box as ToastBox).text == text)


## Removes every box and the queue (e.g. when the HUD appears in a new scene).
func clear() -> void:
	_queue.clear()
	for box in get_children():
		remove_child(box)
		box.queue_free()


func _process(delta: float) -> void:
	var boxes: Array[Node] = get_children()
	if boxes.any(func(box: Node) -> bool: return box is ToastBox and (box as ToastBox).hovered):
		return
	for node in boxes:
		var box := node as ToastBox
		if box == null:
			continue
		box.elapsed += delta
		box.queue_redraw()
		if box.elapsed >= SECONDS:
			remove_child(box)
			box.queue_free()
	_fill()


## Shows queued messages while there is room.
func _fill() -> void:
	while not _queue.is_empty() and get_child_count() < MAX_SHOWN:
		add_child(ToastBox.new(_queue.pop_front()))


## One message: text in a HUD panel; the shade covers the part of its time that is over.
class ToastBox:
	extends PanelContainer

	var text: String
	var elapsed: float = 0.0
	var hovered: bool = false

	func _init(message: String) -> void:
		text = message
		theme_type_variation = &"HudPanel"
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_STOP
		var label := Label.new()
		label.text = message
		label.custom_minimum_size.x = TEXT_WIDTH
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		mouse_entered.connect(func() -> void: hovered = true)
		mouse_exited.connect(func() -> void: hovered = false)

	func _draw() -> void:
		var share: float = clampf(elapsed / SECONDS, 0.0, 1.0)
		draw_rect(Rect2(0, 0, size.x * share, size.y), SHADE)
