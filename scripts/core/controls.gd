class_name Controls
extends RefCounted
## The key bindings of the game, registered once at the start (Game._ready), so they are in one
## place and work in tests too:
##   W A S D / arrow keys  walk          left mouse button  shoot (hold: beam / charge)
##   E / right mouse button  bomb        Tab  bag (inventory)     M  big map      Esc  pause
##   P  admin menu (only in debug builds: started from the editor): travel, items, gear, cheats
##   Shift  dash / blink (with the right item)          Q  drink a potion
## The first key of every action in REBINDABLE can be changed in the settings (tab "Steuerung",
## like in Smithy); it is saved in user://settings.cfg section "keys" (action -> physical key).
## The other keys (arrow keys) and the mouse buttons stay.

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
## Q: drinks the potion of the potion place (RunState.drink_potion).
const POTION: StringName = &"potion"

const SETTINGS_SECTION: String = "keys"
## The keys of every action at the start; the first one can be changed (REBINDABLE).
const DEFAULT_KEYS: Dictionary = {
	MOVE_FORWARD: [KEY_W, KEY_UP],
	MOVE_BACK: [KEY_S, KEY_DOWN],
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	BOMB: [KEY_E],
	MAP: [KEY_M],
	BAG: [KEY_TAB],
	PAUSE: [KEY_ESCAPE],
	TEST_ROOM: [KEY_P],
	DASH: [KEY_SHIFT],
	POTION: [KEY_Q],
}
## Actions whose first key can be changed in the settings, in the order shown there.
const REBINDABLE: Array[StringName] = [MOVE_FORWARD, MOVE_BACK, MOVE_LEFT, MOVE_RIGHT, BOMB, BAG, MAP, DASH, POTION]


static func register() -> void:
	for action: StringName in DEFAULT_KEYS:
		_set_keys(action, _keys_of(action))
	_add_mouse(SHOOT, MOUSE_BUTTON_LEFT)
	_add_mouse(BOMB, MOUSE_BUTTON_RIGHT)


## The changeable (first) key of `action` now.
static func get_key(action: StringName) -> Key:
	return _keys_of(action)[0]


## Changes the first key of `action` and saves it. A key that another action already uses as its
## first key is taken from there (that one gets its default back), so no key does two things.
static func set_key(action: StringName, key: Key) -> void:
	if not REBINDABLE.has(action) or key == KEY_NONE:
		return
	for other: StringName in REBINDABLE:
		if other != action and get_key(other) == key:
			WindowLayout.set_setting(SETTINGS_SECTION, String(other), null)
			_set_keys(other, _keys_of(other))
	WindowLayout.set_setting(SETTINGS_SECTION, String(action), int(key))
	_set_keys(action, _keys_of(action))


## "Standard wiederherstellen": every key as at the start.
static func reset_keys() -> void:
	for action: StringName in REBINDABLE:
		WindowLayout.set_setting(SETTINGS_SECTION, String(action), null)
		_set_keys(action, _keys_of(action))


## The keys of `action`: the saved first key (if any), then the other default keys.
static func _keys_of(action: StringName) -> Array[Key]:
	var keys: Array[Key] = []
	for key: Variant in DEFAULT_KEYS.get(action, []):
		keys.append(key as Key)
	var saved: int = int(WindowLayout.get_setting(SETTINGS_SECTION, String(action), 0))
	if saved != 0 and REBINDABLE.has(action) and not keys.is_empty():
		keys[0] = saved as Key
	return keys


## Replaces the keyboard keys of `action` (mouse buttons stay).
static func _set_keys(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


static func _add_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == button:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


## The name of a key as shown on the button ("W", "Tab", "Shift").
static func key_name(key: Key) -> String:
	return OS.get_keycode_string(key)
