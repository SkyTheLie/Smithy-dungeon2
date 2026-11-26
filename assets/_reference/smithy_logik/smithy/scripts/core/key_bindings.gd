class_name KeyBindings
extends RefCounted
## Changeable keys: each action in ACTIONS has up to KEYS_PER_ACTION keys (e.g. inventory I and
## Tab). Defaults come from the project settings (Input Map); the player's changes are saved in
## user://settings.cfg (section "keys": action -> [physical keycodes]) and put into the InputMap at
## the start (load_saved, GameState). Mouse/gamepad events of an action stay untouched.

const SECTION: String = "keys"
const KEYS_PER_ACTION: int = 2
## [input action, name in the settings]. Actions not listed here keep their project keys.
const ACTIONS: Array[Array] = [
	["move_up", "Hoch"],
	["move_down", "Runter"],
	["move_left", "Links"],
	["move_right", "Rechts"],
	["sprint", "Sprinten"],
	["interact", "Benutzen / Schließen"],
	["inventory", "Inventar"],
	["character", "Charakter"],
	["lexicon", "Lexikon"],
	["house_edit", "Möbel umstellen"],
	["house_rotate", "Möbel drehen"],
]
## Keys that can't be taken (Escape opens the settings and cancels a change).
const RESERVED: Array[Key] = [KEY_ESCAPE]


## Puts the saved keys into the InputMap (actions without saved keys keep the project ones).
static func load_saved() -> void:
	for entry in ACTIONS:
		var action: String = entry[0]
		if not WindowLayout.has_setting(SECTION, action) or not InputMap.has_action(action):
			continue
		var saved: Variant = WindowLayout.get_setting(SECTION, action, [])
		if saved is Array:
			_set_keys(action, saved)


## Physical keycodes of an action, KEYS_PER_ACTION entries (KEY_NONE = free place).
static func get_keys(action: String) -> Array[Key]:
	var keys: Array[Key] = []
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			var key := event as InputEventKey
			if key and keys.size() < KEYS_PER_ACTION:
				keys.append(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	while keys.size() < KEYS_PER_ACTION:
		keys.append(KEY_NONE)
	return keys


## Sets place `index` of `action` to `key` (KEY_NONE = clear it). A key that another action in
## ACTIONS uses is taken away from it there (the other action gets this place's old key), so no
## key does two things. Saved at once.
static func set_key(action: String, index: int, key: Key) -> void:
	var keys: Array[Key] = get_keys(action)
	var old_key: Key = keys[index]
	if key != KEY_NONE:
		for entry in ACTIONS:
			var other: String = entry[0]
			var other_keys: Array[Key] = get_keys(other)
			var found: int = other_keys.find(key)
			if found >= 0 and not (other == action and found == index):
				other_keys[found] = old_key if other != action else KEY_NONE
				_set_keys(other, other_keys)
				_save(other)
				if other == action:
					keys = other_keys
	keys[index] = key
	_set_keys(action, keys)
	_save(action)


## Back to the keys from the project settings (all actions).
static func reset_all() -> void:
	for entry in ACTIONS:
		var action: String = entry[0]
		if WindowLayout.has_setting(SECTION, action):
			WindowLayout.set_setting(SECTION, action, null)
		var defaults: Array = []
		for event in ProjectSettings.get_setting("input/" + action, {}).get("events", []):
			var key := event as InputEventKey
			if key:
				defaults.append(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
		_set_keys(action, defaults)


## "W", "Tab", "" for KEY_NONE.
static func get_key_name(key: Key) -> String:
	return OS.get_keycode_string(key) if key != KEY_NONE else ""


## Puts the current keys into a text: {key_interact}, {key_build}, {key_rotate}, {key_inventory},
## {key_character}, {key_sprint}, {key_move} (all four directions).
static func fill(text: String) -> String:
	if not "{key_" in text:
		return text
	var move: Array[String] = []
	for action: String in ["move_up", "move_left", "move_down", "move_right"]:
		move.append(get_action_text(action).get_slice("/", 0))
	return text.format({"key_interact": get_action_text("interact"), "key_build": get_action_text("house_edit"),
			"key_rotate": get_action_text("house_rotate"), "key_inventory": get_action_text("inventory"),
			"key_character": get_action_text("character"), "key_sprint": get_action_text("sprint"),
			"key_move": " ".join(move)})


## All keys of an action as text, e.g. "I/Tab" (for hints).
static func get_action_text(action: String) -> String:
	var names: Array[String] = []
	for key in get_keys(action):
		if key != KEY_NONE:
			names.append(get_key_name(key))
	return "/".join(names)


## Replaces the keyboard events of `action` with `keys` (physical keycodes), keeps the others.
static func _set_keys(action: String, keys: Array) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for code: Variant in keys:
		if int(code) == KEY_NONE:
			continue
		var event := InputEventKey.new()
		event.physical_keycode = int(code) as Key
		InputMap.action_add_event(action, event)


static func _save(action: String) -> void:
	var codes: Array = []
	for key in get_keys(action):
		if key != KEY_NONE:
			codes.append(int(key))
	WindowLayout.set_setting(SECTION, action, codes)
