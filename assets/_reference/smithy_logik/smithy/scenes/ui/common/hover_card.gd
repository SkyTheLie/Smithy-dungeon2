class_name HoverCard
extends PanelContainer
## A tooltip the mouse can move into: it opens a moment after the mouse rests on a control, and
## stays open while the mouse is over that control or over the card itself (so links in it can be
## clicked, e.g. a status effect in a skill tooltip). Leaving both closes it after a short delay.
## While Shift is held it shows the details text (like RichTooltip).
## Links ([url=effect:poison]...[/url], enemy:..., item:..., skill:...) open their lexicon page.
## Use: HoverCard.attach(control, normal_bbcode, details_bbcode) instead of tooltip_text.
## There is one card for the whole game, on its own CanvasLayer above all windows.

const LAYER: int = 127
const NODE_NAME: String = "HoverCardLayer"
const OPEN_DELAY: float = 0.35
## Moving from one control with a card to the next while one is open: faster.
const SWITCH_DELAY: float = 0.1
const CLOSE_DELAY: float = 0.3
const OFFSET: Vector2 = Vector2(10, 8)
const WIDTH: float = 170.0
const FONT_SIZE: int = 11
## Meta on a control: [normal, details, width].
const META: StringName = &"hover_card"
const META_CONNECTED: StringName = &"hover_card_connected"

## Tests only (headless has no mouse): the mouse position on screen to use instead; null = real mouse.
static var test_mouse: Variant = null

var _label: RichTextLabel
## The control the card belongs to (null = closed) and the one waiting to open it.
var _owner_control: Control
var _pending: Control
var _open_timer: float = 0.0
var _close_timer: float = 0.0
var _normal: String = ""
var _details: String = ""
var _showing_details: bool = false


## Gives `control` a card with this text (BBCode); calling it again only changes the text.
static func attach(control: Control, normal: String, details: String = "", width: float = WIDTH) -> void:
	control.set_meta(META, [normal, details, width])
	control.tooltip_text = ""
	if control.has_meta(META_CONNECTED):
		return
	control.set_meta(META_CONNECTED, true)
	control.mouse_entered.connect(func() -> void:
		if control.is_inside_tree():
			get_card(control.get_tree()).request(control))


## The card of the game (made on first use).
static func get_card(tree: SceneTree) -> HoverCard:
	var layer: CanvasLayer = tree.root.get_node_or_null(NODE_NAME)
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = NODE_NAME
		layer.layer = LAYER
		tree.root.add_child(layer)
		layer.add_child(HoverCard.new())
	return layer.get_child(0)


## true while a card is open (tests).
static func is_open(tree: SceneTree) -> bool:
	var layer: Node = tree.root.get_node_or_null(NODE_NAME)
	return layer != null and layer.get_child_count() > 0 and (layer.get_child(0) as HoverCard).visible


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.meta_underlined = true
	for font_size in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_label.add_theme_font_size_override(font_size, FONT_SIZE)
	_label.meta_clicked.connect(_on_meta_clicked)
	_label.meta_hover_started.connect(func(_meta: Variant) -> void:
		_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND)
	_label.meta_hover_ended.connect(func(_meta: Variant) -> void:
		_label.mouse_default_cursor_shape = Control.CURSOR_ARROW)
	add_child(_label)


func _ready() -> void:
	add_theme_stylebox_override("panel", get_theme_stylebox("panel", "TooltipPanel"))


## The mouse came onto `control`: open its card after a moment.
func request(control: Control) -> void:
	if control == _owner_control and visible:
		_close_timer = 0.0
		return
	_pending = control
	_open_timer = SWITCH_DELAY if visible else OPEN_DELAY


func close() -> void:
	hide()
	_owner_control = null
	_close_timer = 0.0


func _process(delta: float) -> void:
	_update_pending(delta)
	if not visible:
		return
	# The text gets its height a frame after it was set.
	var wanted: Vector2 = get_combined_minimum_size()
	if size != wanted:
		size = wanted
		_keep_on_screen()
	if not is_instance_valid(_owner_control) or not _owner_control.is_visible_in_tree():
		close()
		return
	if _is_mouse_over(self) or _is_mouse_over(_owner_control):
		_close_timer = 0.0
	else:
		_close_timer += delta
		if _close_timer >= CLOSE_DELAY:
			close()
			return
	var want_details: bool = Input.is_key_pressed(KEY_SHIFT) and not _details.is_empty()
	if want_details != _showing_details:
		_showing_details = want_details
		_set_text(_details if want_details else _normal)


func _update_pending(delta: float) -> void:
	if _pending == null:
		return
	if not is_instance_valid(_pending) or not _pending.is_visible_in_tree() or not _is_mouse_over(_pending):
		_pending = null
		return
	# Inside the open card the mouse may cross other controls: they don't take the card away.
	if visible and _is_mouse_over(self):
		_pending = null
		return
	_open_timer -= delta
	if _open_timer > 0.0:
		return
	var control: Control = _pending
	_pending = null
	_open_for(control)


func _open_for(control: Control) -> void:
	var data: Array = control.get_meta(META, ["", "", WIDTH])
	_normal = data[0]
	_details = data[1]
	if _normal.is_empty():
		return
	_owner_control = control
	_close_timer = 0.0
	_label.custom_minimum_size = Vector2(float(data[2]), 0)
	_showing_details = Input.is_key_pressed(KEY_SHIFT) and not _details.is_empty()
	_set_text(_details if _showing_details else _normal)
	# Window layers keep growing (WindowTitleBar.bring_to_front): stay above the topmost one,
	# else the card ends up behind the window it belongs to.
	var layer := get_parent() as CanvasLayer
	if layer:
		layer.layer = maxi(LAYER, WindowTitleBar.get_top_layer() + 1)
	show()
	_place(_mouse_on_screen(self))


func _set_text(text: String) -> void:
	_label.text = text
	_label.reset_size()
	reset_size()
	size = get_combined_minimum_size()
	if visible:
		_keep_on_screen()


## Right below the mouse; where there is no room, on the other side.
func _place(mouse: Vector2) -> void:
	var screen: Vector2 = get_viewport_rect().size
	var spot: Vector2 = mouse + OFFSET
	if spot.x + size.x > screen.x:
		spot.x = mouse.x - OFFSET.x - size.x
	if spot.y + size.y > screen.y:
		spot.y = mouse.y - OFFSET.y - size.y
	position = spot
	_keep_on_screen()


func _keep_on_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	position = Vector2(clampf(position.x, 0.0, maxf(screen.x - size.x, 0.0)), clampf(position.y, 0.0, maxf(screen.y - size.y, 0.0)))


## In the control's own coordinates, so scaled windows (UiScale) count right.
static func _is_mouse_over(control: Control) -> bool:
	var local: Vector2 = control.get_local_mouse_position()
	if test_mouse != null:
		local = control.get_global_transform_with_canvas().affine_inverse() * (test_mouse as Vector2)
	return Rect2(Vector2.ZERO, control.size).has_point(local)


static func _mouse_on_screen(control: Control) -> Vector2:
	return test_mouse as Vector2 if test_mouse != null else control.get_global_mouse_position()


func _on_meta_clicked(meta: Variant) -> void:
	close()
	GameState.open_lexicon(str(meta))
