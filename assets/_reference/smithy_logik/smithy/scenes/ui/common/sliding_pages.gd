class_name SlidingPages
extends Control
## Shows one of its child pages at a time. Switching slides: the new page comes in from the
## right if it is further right in the tab order (else from the left) and pushes the old one out.
## Children are plain Controls; they always get the size of this node.

const SLIDE_TIME: float = 0.25

var current: int = 0

var _tween: Tween


func _ready() -> void:
	clip_contents = true
	resized.connect(_layout)
	for i in get_child_count():
		(get_child(i) as Control).visible = i == current
	_layout()


func _layout() -> void:
	for child in get_children():
		var page := child as Control
		page.size = size
		if page.visible and page == get_child(current):
			page.position = Vector2.ZERO


func show_page(index: int) -> void:
	if index == current or index < 0 or index >= get_child_count():
		return
	if _tween:
		_tween.kill()
	var old_page := get_child(current) as Control
	var new_page := get_child(index) as Control
	var direction: float = 1.0 if index > current else -1.0
	for child in get_children():
		if child != old_page and child != new_page:
			(child as Control).hide()
	new_page.size = size
	new_page.position = Vector2(direction * size.x, 0)
	new_page.show()
	current = index
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(old_page, "position:x", -direction * size.x, SLIDE_TIME)
	_tween.tween_property(new_page, "position:x", 0.0, SLIDE_TIME)
	_tween.chain().tween_callback(old_page.hide)
