class_name WindowTitleBar
extends PanelContainer
## Title bar of a window: shows the title, a pin and an X button (emits close_requested), and
## lets the player drag the whole window with the left mouse button. The window is the
## top-level Control that contains this bar (the direct child of the CanvasLayer). It always
## stays on screen.
## Pin: a pinned window can't be dragged and keeps its position across closing, scene changes
## and restarts (stored by WindowLayout). Unpinned windows keep their position only until the
## next scene change.
## Order: the window opened (or clicked) last is always in front. No window may lie under a
## Control in FREE_ZONE_GROUP (e.g. the time compass); it is pushed below it.

signal close_requested

const PIN_ICON: Texture2D = preload("res://assets/ui/icon_pin.png")
const PIN_ICON_ACTIVE: Texture2D = preload("res://assets/ui/icon_pin_active.png")
## Controls in this group must never be covered by a window (HUD time compass).
const FREE_ZONE_GROUP: StringName = &"window_free_zone"
## Gap between a window and a free zone above it.
const FREE_ZONE_GAP: float = 2.0

## Highest CanvasLayer.layer given out so far; the newest window's layer gets the next one.
static var _top_layer: int = 1
## All title bars in the tree (to find which window lies on top under a click).
static var _bars: Array[WindowTitleBar] = []

@export var title: String = "":
	set(value):
		title = value
		if is_node_ready():
			_title_label.text = value
## Short extra text right of the pin (e.g. "1/2" in the hero list). Empty = hidden.
@export var info: String = "":
	set(value):
		info = value
		if is_node_ready():
			_update_info()
## Name under which the pinned position is stored. Empty = "<CanvasLayer>/<window>".
@export var window_id: String = ""

var _dragging: bool = false
## true once the player dragged the window himself (a window that places itself, e.g. the
## DialogueBox avoiding the figures, then leaves it where he put it).
var moved_by_player: bool = false

@onready var _title_label: Label = $HBox/Title
@onready var _pin_button: Button = $HBox/PinButton
@onready var _info_label: Label = $HBox/Info
@onready var _close_button: Button = $HBox/CloseButton


func _ready() -> void:
	_title_label.text = title
	_update_info()
	_close_button.pressed.connect(close_requested.emit)
	_pin_button.toggled.connect(_on_pin_toggled)
	var window: Control = _get_window()
	window.visibility_changed.connect(_on_window_visibility_changed)
	var layer := window.get_parent() as CanvasLayer
	if layer:
		layer.visibility_changed.connect(_on_window_visibility_changed)
	_restore_pinned_position()


## Highest CanvasLayer.layer of a window so far (overlays like ItemReveal stay above it).
static func get_top_layer() -> int:
	return _top_layer


## Makes every window invisible (true) or shows it again (false), e.g. while ItemReveal shows a
## piece. Only the look changes: the windows stay open, so nothing closes or gives items back.
static func set_windows_hidden(hidden: bool) -> void:
	for bar: WindowTitleBar in _bars:
		bar._get_window().modulate.a = 0.0 if hidden else 1.0


## Title bar of the window drawn on top that can be closed right now (X shown, not hidden by
## set_windows_hidden), null = none. For the X button of the touch controls (MobileUi).
static func top_closable() -> WindowTitleBar:
	var best: WindowTitleBar = null
	for bar: WindowTitleBar in _bars:
		if not bar._close_button.visible or not bar._is_window_shown() \
				or bar._get_window().modulate.a <= 0.0:
			continue
		if best == null or bar._draws_above(best):
			best = bar
	return best


## Closes the window like a click on its X.
func request_close() -> void:
	close_requested.emit()


## false = no X (a window that can't be closed right now, e.g. HeroTournamentMenu during a tournament).
func set_closable(closable: bool) -> void:
	_close_button.visible = closable


func _update_info() -> void:
	_info_label.text = info
	_info_label.visible = not info.is_empty()


func is_pinned() -> bool:
	return _pin_button.button_pressed


func _enter_tree() -> void:
	_bars.append(self)


func _exit_tree() -> void:
	_bars.erase(self)


## A click anywhere in the window (also on its buttons and slots, which take the click
## themselves) brings it to the front. Runs before the GUI. Where windows overlap, only the
## one drawn on top reacts.
func _input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or not _is_window_shown():
		return
	if button.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		return
	if not UiScale.get_visual_rect(_get_window()).has_point(button.position):
		return
	for other: WindowTitleBar in _bars:
		if other != self and other._is_window_shown() and other._draws_above(self) \
				and UiScale.get_visual_rect(other._get_window()).has_point(button.position):
			return
	# Deferred: reorder after the click has reached its Control.
	bring_to_front.call_deferred()


## True if this bar's window is drawn above the window of `other` (higher CanvasLayer, or the
## same layer and a later child).
func _draws_above(other: WindowTitleBar) -> bool:
	var mine: Control = _get_window()
	var theirs: Control = other._get_window()
	var my_layer := mine.get_parent() as CanvasLayer
	var their_layer := theirs.get_parent() as CanvasLayer
	var my_z: int = my_layer.layer if my_layer else 0
	var their_z: int = their_layer.layer if their_layer else 0
	if my_z != their_z:
		return my_z > their_z
	if mine.get_parent() == theirs.get_parent():
		return mine.get_index() > theirs.get_index()
	return false


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if is_pinned():
		return
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		accept_event()
	elif _dragging and event is InputEventMouseMotion:
		var window: Control = _get_window()
		# the event comes in the window's own (scaled) coordinates (UiScale)
		window.position += (event as InputEventMouseMotion).relative * window.scale
		moved_by_player = true
		_keep_on_screen(window)
		accept_event()


## Draws the window above all other windows: last child of its CanvasLayer, and the
## CanvasLayer above all other window layers (HUD and station menus each have their own).
func bring_to_front() -> void:
	var window: Control = _get_window()
	window.move_to_front()
	var layer := window.get_parent() as CanvasLayer
	# All window layers start at 1, so 1 never counts as "already on top".
	if layer and (layer.layer != _top_layer or _top_layer == 1):
		_top_layer += 1
		layer.layer = _top_layer


func _is_window_shown() -> bool:
	var window: Control = _get_window()
	var layer := window.get_parent() as CanvasLayer
	return window.visible and (layer == null or layer.visible)


func _on_window_visibility_changed() -> void:
	if not _is_window_shown():
		return
	# Deferred: this runs while Godot passes the visibility on to the layer's children;
	# reordering them in the middle of that skips some, which then stay invisible for good.
	bring_to_front.call_deferred()
	# Deferred: the window gets its size for the new content first.
	_keep_on_screen.call_deferred(_get_window())


func _restore_pinned_position() -> void:
	# Wait one frame: the window gets its final size first (it grows to both sides from the centre).
	await get_tree().process_frame
	if not is_inside_tree():  # the scene changed in that frame
		return
	var saved: Vector2 = WindowLayout.get_pinned_position(_get_window_id())
	if saved == Vector2.INF:
		_update_pin_look()
		return
	var window: Control = _get_window()
	window.position = saved
	_keep_on_screen(window)
	_pin_button.set_pressed_no_signal(true)
	_update_pin_look()


func _on_pin_toggled(pinned: bool) -> void:
	_dragging = false
	if pinned:
		WindowLayout.pin(_get_window_id(), _get_window().position)
	else:
		WindowLayout.unpin(_get_window_id())
	_update_pin_look()


func _update_pin_look() -> void:
	var pinned: bool = is_pinned()
	_pin_button.icon = PIN_ICON_ACTIVE if pinned else PIN_ICON
	_pin_button.tooltip_text = Language.translate("Lösen (Fenster wieder verschiebbar)") if pinned else Language.translate("Anpinnen (Position merken)")
	mouse_default_cursor_shape = Control.CURSOR_ARROW if pinned else Control.CURSOR_MOVE


func _get_window_id() -> String:
	if not window_id.is_empty():
		return window_id
	var window: Control = _get_window()
	return "%s/%s" % [window.get_parent().name, window.name]


func _get_window() -> Control:
	var node: Node = self
	# Up to the node right under the CanvasLayer (or under the root, e.g. a window in a test).
	while node.get_parent() and not node.get_parent() is CanvasLayer and not node.get_parent() is Viewport:
		node = node.get_parent()
	return node as Control


## Keeps the window inside the screen (e.g. after it was made bigger in the settings).
func keep_on_screen() -> void:
	_keep_on_screen(_get_window())


## Keeps the window inside the screen and out of the free zones (pushed below them). Works with
## the window's scaled picture (UiScale), not its unscaled size.
func _keep_on_screen(window: Control) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	var rect: Rect2 = UiScale.get_visual_rect(window)
	rect.position = rect.position.clamp(Vector2.ZERO, (screen_size - rect.size).max(Vector2.ZERO))
	for zone: Node in get_tree().get_nodes_in_group(FREE_ZONE_GROUP):
		var zone_control := zone as Control
		if zone_control == null or not zone_control.is_visible_in_tree():
			continue
		var zone_rect: Rect2 = UiScale.get_visual_rect(zone_control) if zone_control.get_parent() is CanvasLayer \
				else zone_control.get_global_rect()
		if rect.intersects(zone_rect):
			rect.position.y = zone_rect.end.y + FREE_ZONE_GAP
	UiScale.set_visual_position(window, rect.position)
