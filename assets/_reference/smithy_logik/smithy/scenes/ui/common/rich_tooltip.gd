class_name RichTooltip
extends RichTextLabel
## Tooltip with coloured text (BBCode) and a detail view: while Shift is held it shows
## `detail_text` instead of `normal_text`, also when Shift is pressed after the tooltip opened.
## Use it from _make_custom_tooltip(): return RichTooltip.create(normal, details).

const WIDTH: float = 150.0
const FONT_SIZE: int = 11

var normal_text: String = ""
var detail_text: String = ""

var _showing_details: bool = false
var _placed: bool = false


static func create(normal: String, details: String = "", width: float = WIDTH) -> RichTooltip:
	var label := RichTooltip.new()
	label.normal_text = normal
	label.detail_text = details
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(width, 0)
	for font_size in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		label.add_theme_font_size_override(font_size, FONT_SIZE)
	label._showing_details = _is_shift_held() and not details.is_empty()
	label.text = details if label._showing_details else normal
	return label


static func _is_shift_held() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)


## Opens high enough for the details, so that the tooltip does not jump up when Shift is pressed.
func _leave_room_for_details() -> void:
	_placed = true
	var window := get_window()
	if _showing_details or window == null or window == get_tree().root:
		return
	text = detail_text
	var height: int = get_content_height() + 8
	text = normal_text
	var screen: Vector2i = Vector2i(get_tree().root.get_visible_rect().size)
	window.position.y = mini(window.position.y, maxi(screen.y - height, 0))


func _process(_delta: float) -> void:
	if detail_text.is_empty():
		return
	if not _placed:
		_leave_room_for_details()
	var want_details: bool = _is_shift_held()
	if want_details == _showing_details:
		return
	_showing_details = want_details
	text = detail_text if want_details else normal_text
	# The tooltip window does not shrink/grow by itself: fit it to the new text.
	var window := get_window()
	if window and window != get_tree().root:
		reset_size()
		window.size = Vector2i(get_combined_minimum_size()) + Vector2i(8, 8)
		window.reset_size()
		# Keep it on screen (it grows downwards).
		var screen: Vector2i = Vector2i(get_tree().root.get_visible_rect().size)
		window.position = Vector2i(clampi(window.position.x, 0, maxi(screen.x - window.size.x, 0)),
				clampi(window.position.y, 0, maxi(screen.y - window.size.y, 0)))
