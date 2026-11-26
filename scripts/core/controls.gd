class_name Controls
extends RefCounted
## The key bindings of the game, registered once at the start (Game._ready), so they are in one
## place and work in tests too:
##   W A S D / arrow keys  walk          left mouse button  shoot (hold: beam / charge)
##   E / right mouse button  bomb        Tab  bag (inventory)     M  big map      Esc  pause
##   P  test room (only in debug builds: started from the editor)
##   Shift  dash / blink (with the right item)

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const SHOOT: StringName = &"shoot"
const BOMB: StringName = &"bomb"
const MAP: StringName = &"map"
## Tab: the bag window (loot, drag and drop).
const BAG: StringName = &"bag"
const PAUSE: StringName = &"pause"
const TEST_ROOM: StringName = &"test_room"
## Shift: dash / blink (only with an item that has "dash" or "blink").
const DASH: StringName = &"dash"


static func register() -> void:
	_add_keys(MOVE_FORWARD, [KEY_W, KEY_UP])
	_add_keys(MOVE_BACK, [KEY_S, KEY_DOWN])
	_add_keys(MOVE_LEFT, [KEY_A, KEY_LEFT])
	_add_keys(MOVE_RIGHT, [KEY_D, KEY_RIGHT])
	_add_keys(BOMB, [KEY_E])
	_add_keys(MAP, [KEY_M])
	_add_keys(BAG, [KEY_TAB])
	_add_keys(PAUSE, [KEY_ESCAPE])
	_add_keys(TEST_ROOM, [KEY_P])
	_add_keys(DASH, [KEY_SHIFT])
	_add_mouse(SHOOT, MOUSE_BUTTON_LEFT)
	_add_mouse(BOMB, MOUSE_BUTTON_RIGHT)


static func _add_keys(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


static func _add_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
