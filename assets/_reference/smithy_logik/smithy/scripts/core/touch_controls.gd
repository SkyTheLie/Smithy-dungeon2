extends CanvasLayer
## Touch controls for the Android build ONLY. On PC this node frees itself at once, so the
## PC game stays exactly as it is.
## Walking, two modes (MobileUi.get_move_mode, Einstellungen » Steuerung » Laufen):
##   "tap":   tap the ground » the player walks there around everything in the way (TouchWalk),
##            a small ring marks the goal; hold the finger » he walks towards it while it is down;
##            tap an object out of reach » he walks there and uses it.
##   "stick": a finger on the left half of the screen makes a stick appear under the thumb
##            (with strength, like a gamepad); the right half taps objects. A short tap (not held,
##            hardly moved) anywhere is E instead: on a far object » walk there and use it, else
##            E for the nearest thing (like the key).
## In both modes: tapping an object in reach uses exactly that object, like E
## (MobileUi.find_tap_target); holding the finger on an ore rock or a tree mines it like holding E.
## A tap beside everything turns the page of an open conversation.
## Right bottom: an E button (for what has no picture to tap, e.g. the seated heroes in the guild)
## and a sprint button; in tester builds (DevTools) above them "A" for the admin panel.
## In the rooms of the player's house a "B" button beside them switches furnishing on and off
## (HouseEditor, key B). While furnishing, E and sprint give way to "R" (turn, key R) and a box
## button (store, right click on PC); the taps in the room go to the HouseEditor as mouse clicks
## (Godot makes a click out of every touch), only the ones on our round buttons are held back.
## Top right: an X button while a window or a tip is open; it closes the window on top (like its
## own X, which may lie off screen when a window is too big) or else the tip (like "Verstanden").
## The Android back button / back gesture sends ui_cancel (Escape) instead of quitting the game.
## Everything else (inventory, character, save ...) already has buttons in the HUD that work
## by tapping, because touches also act as mouse clicks.
## The look is drawn in code (circles + letters) - placeholder, see docs/PIXELLAB_TODO.md.

const STICK_RADIUS: float = 34.0
const STICK_DEAD_ZONE: float = 0.2
const BUTTON_RADIUS_BIG: float = 24.0
const BUTTON_RADIUS_SMALL: float = 17.0
## Not an input action: the X button closes the top window / tip itself (close_top).
const CLOSE_BUTTON: StringName = &"touch_close_window"
## A finger that stays down this long or moves this far (screen px) is "held", not a tap.
const HOLD_SECONDS: float = 0.22
const HOLD_MOVE: float = 12.0
## Holding: the player stops when the finger is this close to his feet (world px).
const FOLLOW_STOP: float = 6.0
## Walking a way: a point counts as reached this close (world px); no progress for STUCK_SECONDS
## (pushing against something that moved in the way) ends the walk.
const POINT_REACHED: float = 3.0
const STUCK_SECONDS: float = 0.5
const STUCK_DISTANCE: float = 4.0
## A use after walking to an object holds E this long (ore needs it held for a hit).
const ARRIVE_PRESS_SECONDS: float = 0.15
const COLOR_BASE: Color = Color(0.1, 0.07, 0.09, 0.35)
const COLOR_RING: Color = Color(0.92, 0.88, 0.78, 0.55)
const COLOR_KNOB: Color = Color(0.92, 0.88, 0.78, 0.6)
const COLOR_PRESSED: Color = Color(0.95, 0.75, 0.3, 0.7)
const COLOR_GOAL: Color = Color(0.95, 0.85, 0.45, 0.8)

var _draw_node: Control
## Stick ("stick" mode): finger, centre where the thumb came down, current vector.
var _stick_touch: int = -1
var _stick_center: Vector2 = Vector2.ZERO
var _stick_vector: Vector2 = Vector2.ZERO
## Where the stick's finger came down, how long it is down, whether it moved (a short still touch
## is a tap = E, not the stick).
var _stick_start: Vector2 = Vector2.ZERO
var _stick_time: float = 0.0
var _stick_moved: bool = false
## touch index -> action name of the button held by it
var _button_touches: Dictionary = {}
## Finger that holds "interact" after a tap on an object in reach, -1 = none.
var _world_touch: int = -1
## Seconds left of the short E press after walking to an object (0 = none).
var _arrive_press_left: float = 0.0
## "tap" mode: finger on the ground [index, start screen pos, seconds down], -1 = none.
var _ground_touch: int = -1
var _ground_start: Vector2 = Vector2.ZERO
var _ground_time: float = 0.0
var _following: bool = false
var _follow_screen: Vector2 = Vector2.ZERO
## Way being walked (world points), the object to use at the end (null = none).
var _path: PackedVector2Array = PackedVector2Array()
var _path_goal: Vector2 = Vector2.ZERO
var _walk_target: Node = null
var _stuck_time: float = 0.0
var _stuck_from: Vector2 = Vector2.ZERO
## Direction last sent to the move actions (so it is only released when it was set by us).
var _move_vector: Vector2 = Vector2.ZERO
## The mouse click made out of a touch on one of our buttons is being held back until its release.
var _mouse_on_button: bool = false


static func is_wanted() -> bool:
	return MobileUi.active()


func _ready() -> void:
	if not is_wanted():
		# queue_free only happens at the end of the frame; input arriving
		# before that would reach _input with no _draw_node (PC crash).
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		queue_free()
		return
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_quit_on_go_back(false)
	_draw_node = Control.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_wanted():
		_send_action(&"ui_cancel", true)
		_send_action(&"ui_cancel", false)


## true while the player walks a way from a tap (tests, the goal ring).
func is_walking() -> bool:
	return not _path.is_empty()


func _process(delta: float) -> void:
	var show: bool = not GameState.in_main_menu
	if _draw_node.visible != show:
		_draw_node.visible = show
		if not show:
			_release_all()
	if _arrive_press_left > 0.0:
		_arrive_press_left -= delta
		if _arrive_press_left <= 0.0:
			_send_action(&"interact", false)
	if _stick_touch != -1:
		_stick_time += delta
	if _ground_touch != -1:
		_ground_time += delta
		if not _following and _ground_time >= HOLD_SECONDS:
			_start_following()
	_steer(delta)
	_draw_node.queue_redraw()


func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _stick_mode() -> bool:
	return MobileUi.get_move_mode() == MobileUi.MOVE_STICK


## Where the idle stick is shown in "stick" mode (a hint; it moves to the thumb).
func _stick_home() -> Vector2:
	return Vector2(62.0, _screen_size().y - 78.0)


## [action, centre, radius, letter]
func _buttons() -> Array:
	var size: Vector2 = _screen_size()
	var main_at := Vector2(size.x - 62.0, size.y - 52.0)
	var side_at := Vector2(size.x - 112.0, size.y - 30.0)
	var list: Array = []
	var building: bool = MobileUi.build_mode_active(get_tree())
	if building:
		# Furnishing: turn and store instead of E and sprint (the box is drawn, no letter).
		list.append([&"house_rotate", main_at, BUTTON_RADIUS_BIG, "R"])
		list.append([&"house_store", side_at, BUTTON_RADIUS_SMALL, ""])
	else:
		list.append([&"interact", main_at, BUTTON_RADIUS_BIG, "E"])
		list.append([&"sprint", side_at, BUTTON_RADIUS_SMALL, ">>"])
	if building or MobileUi.build_mode_offered(get_tree()):
		list.append([&"house_edit", Vector2(size.x - 116.0, size.y - 78.0), BUTTON_RADIUS_SMALL, "B"])
	if can_close_something():
		list.append([CLOSE_BUTTON, Vector2(size.x - 24.0, 24.0), BUTTON_RADIUS_SMALL, "X"])
	# DEV-ONLY: the admin panel (key P) for tester builds (DevTools.TESTER_FEATURE).
	if DevTools.enabled():
		list.append([&"admin_panel", Vector2(size.x - 62.0, size.y - 108.0), BUTTON_RADIUS_SMALL, "A"])
	return list


## true while the X button is shown: a window that can be closed or a tip is open.
func can_close_something() -> bool:
	return WindowTitleBar.top_closable() != null or HintPanel.shown_panel(get_tree()) != null


## X button: closes the window drawn on top; with no window open, the tip.
func close_top() -> void:
	var bar: WindowTitleBar = WindowTitleBar.top_closable()
	if bar != null:
		bar.request_close()
		return
	var hint: HintPanel = HintPanel.shown_panel(get_tree())
	if hint != null:
		hint.dismiss()


func _input(event: InputEvent) -> void:
	# The aimed tap is over once its "interact" release went through the game.
	if event is InputEventAction and (event as InputEventAction).action == &"interact" \
			and not event.is_pressed() and _world_touch == -1 and _arrive_press_left <= 0.0:
		MobileUi.touch_target = null
	if not _draw_node.visible:
		return
	if event is InputEventMouse:
		if _hold_back_mouse(event as InputEventMouse):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _try_button(touch.index, touch.position):
				get_viewport().set_input_as_handled()
		elif _release_touch(touch.index, touch.position):
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _stick_touch:
			if drag.position.distance_to(_stick_start) > HOLD_MOVE:
				_stick_moved = true
			_update_stick(drag.position)
			get_viewport().set_input_as_handled()
		elif drag.index == _ground_touch:
			_follow_screen = drag.position
			if not _following and drag.position.distance_to(_ground_start) > HOLD_MOVE:
				_start_following()
			get_viewport().set_input_as_handled()


## Touches that no window or button took: into the world.
func _unhandled_input(event: InputEvent) -> void:
	if not _draw_node.visible:
		return
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	if _touch_world(touch.index, touch.position):
		get_viewport().set_input_as_handled()


## A finger came down in the world. true if it does something.
func _touch_world(index: int, screen_pos: Vector2) -> bool:
	var tree: SceneTree = get_tree()
	if MobileUi.build_mode_active(tree):
		return false
	var world_pos: Vector2 = _to_world(screen_pos)
	# An object in reach (or an open conversation): use it at once, like E.
	var target: Node = MobileUi.find_tap_target(tree, world_pos)
	if target != null or (_world_touch == -1 and MobileUi.conversation_open(tree)):
		if _world_touch != -1:
			return false
		_stop_walking()
		_world_touch = index
		MobileUi.touch_target = target
		_send_action(&"interact", true)
		return true
	var stick: bool = _stick_mode()
	if stick and _stick_touch == -1 and screen_pos.x < _screen_size().x / 2.0:
		_stop_walking()
		_stick_touch = index
		_stick_center = screen_pos
		_stick_start = screen_pos
		_stick_time = 0.0
		_stick_moved = false
		_update_stick(screen_pos)
		return true
	# An object out of reach: walk there and use it.
	var far: Node = MobileUi.find_tap_target(tree, world_pos, false)
	if far != null:
		_walk_to(_feet_spot(far), far)
		return true
	if stick:
		# Joystick mode, right half: a tap on the ground is E for the nearest thing.
		_press_e(null)
		return true
	if _ground_touch != -1:
		return false
	# The ground ("tap" mode): tap = walk there, hold = follow the finger.
	_stop_walking()
	_ground_touch = index
	_ground_start = screen_pos
	_follow_screen = screen_pos
	_ground_time = 0.0
	_following = false
	return true


## The button under `pos` ([action, centre, radius, letter]), empty = none.
func _button_at(pos: Vector2) -> Array:
	for button: Array in _buttons():
		if pos.distance_to(button[1]) <= button[2] * 1.3:
			return button
	return []


func _try_button(index: int, pos: Vector2) -> bool:
	var button: Array = _button_at(pos)
	if button.is_empty():
		return false
	_button_touches[index] = button[0]
	if button[0] == CLOSE_BUTTON:
		close_top()
	else:
		_send_action(button[0], true)
	return true


## Godot makes a mouse click out of every touch, and it arrives before the touch itself. While
## furnishing the room takes those clicks (HouseEditor), so the ones on our buttons are held back
## (true): else "R" would also put the carried thing down under the button. Every other click or
## drag is where the player points (MobileUi.pointer).
func _hold_back_mouse(mouse: InputEventMouse) -> bool:
	var click := mouse as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			var button: Array = _button_at(click.position)
			# The X lies over windows: the click must not reach the window under it either.
			_mouse_on_button = not button.is_empty() and (button[0] == &"house_edit" \
					or button[0] == CLOSE_BUTTON or MobileUi.build_mode_active(get_tree()))
		elif _mouse_on_button:
			_mouse_on_button = false
			return true
	if _mouse_on_button:
		return true
	if click != null or (mouse.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		MobileUi.pointer_screen = mouse.position
	return false


func _release_touch(index: int, pos: Vector2) -> bool:
	if index == _stick_touch:
		_stick_touch = -1
		_stick_vector = Vector2.ZERO
		_set_move(Vector2.ZERO)
		if not _stick_moved and _stick_time < HOLD_SECONDS:
			_stick_tap(_stick_start)
		return true
	if _button_touches.has(index):
		if _button_touches[index] != CLOSE_BUTTON:
			_send_action(_button_touches[index], false)
		_button_touches.erase(index)
		return true
	if index == _world_touch:
		_world_touch = -1
		_send_action(&"interact", false)
		return true
	if index == _ground_touch:
		_ground_touch = -1
		if _following:
			_following = false
			_set_move(Vector2.ZERO)
		else:
			_walk_to(_to_world(pos), null)
		return true
	return false


func _release_all() -> void:
	for index: int in _button_touches.keys():
		_release_touch(index, Vector2.ZERO)
	if _world_touch != -1:
		_release_touch(_world_touch, Vector2.ZERO)
	if _stick_touch != -1:
		_release_touch(_stick_touch, Vector2.ZERO)
	_ground_touch = -1
	_following = false
	_stop_walking()


func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _to_screen(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group(Player.GROUP) as CharacterBody2D


## Where to walk to use `node`: its foot point (the way ends at the free spot nearest to it).
func _feet_spot(node: Node) -> Vector2:
	return (node as Node2D).global_position


## A short tap on the stick half: a far object under the finger » walk there and use it, else E.
func _stick_tap(screen_pos: Vector2) -> void:
	var far: Node = MobileUi.find_tap_target(get_tree(), _to_world(screen_pos), false)
	if far != null:
		_walk_to(_feet_spot(far), far)
	else:
		_press_e(null)


## A short E press (held ARRIVE_PRESS_SECONDS), for `target` only, or like the key if null.
func _press_e(target: Node) -> void:
	if _arrive_press_left > 0.0 or _world_touch != -1:
		return
	MobileUi.touch_target = target
	_send_action(&"interact", true)
	_arrive_press_left = ARRIVE_PRESS_SECONDS


# --- Walking ---------------------------------------------------------------------------

func _start_following() -> void:
	_following = true
	_stop_walking()


func _walk_to(goal: Vector2, target: Node) -> void:
	_stop_walking()
	var player: CharacterBody2D = _player()
	if player == null:
		return
	_path = TouchWalk.find_path(player, goal)
	if _path.is_empty():
		return
	_path_goal = _path[_path.size() - 1]
	_walk_target = target
	_stuck_time = 0.0
	_stuck_from = player.global_position


func _stop_walking() -> void:
	# Also when the last point was just reached (the list is empty already, the keys still down).
	_set_move(Vector2.ZERO)
	_path.clear()
	_walk_target = null


## Every frame: drives the move actions for holding, walking a way (the stick drives itself).
func _steer(delta: float) -> void:
	if _stick_touch != -1:
		return
	var player: CharacterBody2D = _player()
	if player == null or (player as Player).is_locked() or StationMenu.is_player_frozen(get_tree()):
		if not _path.is_empty():
			_stop_walking()
		return
	if _following:
		var to_finger: Vector2 = _to_world(_follow_screen) - player.global_position
		_set_move(to_finger.normalized() if to_finger.length() > FOLLOW_STOP else Vector2.ZERO)
		return
	if _path.is_empty():
		return
	# The object to use is in reach: stop and use it.
	if _walk_target != null and MobileUi.wants_now(_walk_target):
		var target: Node = _walk_target
		_stop_walking()
		_press_e(target)
		return
	while not _path.is_empty() and player.global_position.distance_to(_path[0]) <= POINT_REACHED:
		_path.remove_at(0)
	if _path.is_empty():
		_stop_walking()
		return
	_stuck_time += delta
	if _stuck_time >= STUCK_SECONDS:
		if player.global_position.distance_to(_stuck_from) < STUCK_DISTANCE:
			_stop_walking()
			return
		_stuck_time = 0.0
		_stuck_from = player.global_position
	_set_move((_path[0] - player.global_position).normalized())


func _update_stick(pos: Vector2) -> void:
	var knob: Vector2 = (pos - _stick_center) / STICK_RADIUS
	if knob.length() > 1.0:
		# The stick follows a thumb that slides past its edge.
		_stick_center = pos - knob.normalized() * STICK_RADIUS
		knob = knob.normalized()
	_stick_vector = knob
	_set_move(knob if knob.length() >= STICK_DEAD_ZONE else Vector2.ZERO)


func _set_move(vector: Vector2) -> void:
	if vector == _move_vector:
		return
	_move_vector = vector
	_set_axis(&"move_left", -vector.x)
	_set_axis(&"move_right", vector.x)
	_set_axis(&"move_up", -vector.y)
	_set_axis(&"move_down", vector.y)


func _set_axis(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	elif Input.is_action_pressed(action):
		Input.action_release(action)


## A real input event, so the _input/_unhandled_input handlers of the game see it like a key.
func _send_action(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _on_draw() -> void:
	if _stick_mode():
		var centre: Vector2 = _stick_center if _stick_touch != -1 else _stick_home()
		var alpha: float = 1.0 if _stick_touch != -1 else 0.5
		_draw_node.draw_circle(centre, STICK_RADIUS, Color(COLOR_BASE, COLOR_BASE.a * alpha))
		_draw_node.draw_arc(centre, STICK_RADIUS, 0.0, TAU, 32, Color(COLOR_RING, COLOR_RING.a * alpha), 1.5)
		_draw_node.draw_circle(centre + _stick_vector * STICK_RADIUS, 13.0,
			COLOR_PRESSED if _stick_touch != -1 else Color(COLOR_KNOB, COLOR_KNOB.a * alpha))
	if not _path.is_empty():
		var goal: Vector2 = _to_screen(_path_goal)
		var pulse: float = 4.0 + sin(Time.get_ticks_msec() / 120.0) * 1.0
		_draw_node.draw_arc(goal, pulse, 0.0, TAU, 16, COLOR_GOAL, 1.5)
	var font: Font = ThemeDB.fallback_font
	var held: Array = _button_touches.values()
	var building: bool = MobileUi.build_mode_active(get_tree())
	for button: Array in _buttons():
		var pos: Vector2 = button[1]
		var radius: float = button[2]
		# "B" stays lit while furnishing.
		var lit: bool = held.has(button[0]) or (building and button[0] == &"house_edit")
		_draw_node.draw_circle(pos, radius, COLOR_PRESSED if lit else COLOR_BASE)
		_draw_node.draw_arc(pos, radius, 0.0, TAU, 32, COLOR_RING, 1.5)
		if button[0] == &"house_store":
			# Store: an arrow down into an open box.
			_draw_node.draw_polyline(PackedVector2Array([pos + Vector2(-7, 0), pos + Vector2(-7, 7),
					pos + Vector2(7, 7), pos + Vector2(7, 0)]), COLOR_RING, 1.5)
			_draw_node.draw_line(pos + Vector2(0, -9), pos + Vector2(0, 3), COLOR_RING, 1.5)
			_draw_node.draw_polyline(PackedVector2Array([pos + Vector2(-4, -1), pos + Vector2(0, 3),
					pos + Vector2(4, -1)]), COLOR_RING, 1.5)
			continue
		var font_size: int = 14 if radius >= BUTTON_RADIUS_BIG else 10
		var text_size: Vector2 = font.get_string_size(button[3], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		_draw_node.draw_string(font, pos + Vector2(-text_size.x / 2.0, font_size * 0.35), button[3],
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_RING)
