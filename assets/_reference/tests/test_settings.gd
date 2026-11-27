extends "res://assets/_reference/_lib/base_test.gd"
## Settings and save slots: deleting a slot (MetaState and the "Löschen" button of SlotSelect),
## changeable keys (Controls: change, swap away from another action, reset, saved), display
## settings (mode, window size, field of view) and the settings window with its three tabs.


func run() -> void:
	await _delete_slots()
	_keys()
	_display()
	await _window()


func _delete_slots() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("set_slot", "b")
	meta.call("start_new")
	meta.call("set_slot", "a")
	meta.call("start_new")
	check(meta.call("has_save", "a") and meta.call("has_save", "b"), "two saves")
	check(meta.call("delete_slot", "b"), "slot B is deleted")
	check(not meta.call("has_save", "b"), "slot B is empty now")
	check(not meta.call("delete_slot", "b"), "an empty slot cannot be deleted")
	check(meta.call("has_save", "a"), "slot A stays")
	# The button under the slot (with its question).
	var select: Control = script("res://scenes/ui/main_menu/slot_select.gd").new()
	root.add_child(select)
	await process_frame
	var delete_a: Button = select.find_child("Delete_a", true, false)
	var delete_c: Button = select.find_child("Delete_c", true, false)
	check(not delete_a.disabled and delete_c.disabled, "only slots with a game can be deleted")
	delete_a.pressed.emit()
	var question: ConfirmationDialog = select.call("get_question")
	check(question.visible, "Löschen asks first")
	question.get_ok_button().pressed.emit()
	await process_frame
	check(not meta.call("has_save", "a"), "after yes slot A is gone")
	check_eq((select.find_child("Slot_a", true, false) as Button).text, "Spielstand A\nLeer", "the button says Leer")
	select.queue_free()


func _keys() -> void:
	var controls: Script = script("res://scripts/core/controls.gd")
	check_eq(controls.call("get_key", &"bag"), KEY_TAB, "Tab opens the bag at first")
	controls.call("set_key", &"bag", KEY_I)
	check_eq(controls.call("get_key", &"bag"), KEY_I, "the bag is on I now")
	check(_has_key(&"bag", KEY_I) and not _has_key(&"bag", KEY_TAB), "the input map follows")
	controls.call("set_key", &"map", KEY_I)
	check_eq(controls.call("get_key", &"map"), KEY_I, "the map takes I")
	check_eq(controls.call("get_key", &"bag"), KEY_TAB, "the bag gets its default back (no key does two things)")
	controls.call("set_key", &"move_forward", KEY_Z)
	check(_has_key(&"move_forward", KEY_Z) and _has_key(&"move_forward", KEY_UP), "the arrow key stays as second key")
	controls.call("register")
	check_eq(controls.call("get_key", &"move_forward"), KEY_Z, "the keys are saved")
	check(_has_key(&"bomb", KEY_E) and _mouse_count(&"bomb") == 1, "registering again keeps one mouse button")
	controls.call("reset_keys")
	check_eq(controls.call("get_key", &"move_forward"), KEY_W, "Standard: W again")
	check_eq(controls.call("get_key", &"map"), KEY_M, "Standard: M again")


func _has_key(action: StringName, key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == key:
			return true
	return false


func _mouse_count(action: StringName) -> int:
	return InputMap.action_get_events(action).filter(func(event: InputEvent) -> bool: return event is InputEventMouseButton).size()


func _display() -> void:
	var display: Script = script("res://scripts/core/display_settings.gd")
	check_eq(display.call("get_mode"), "window", "window mode at first")
	display.call("set_mode", "borderless")
	check_eq(display.call("get_mode"), "borderless", "borderless is remembered")
	display.call("set_mode", "nonsense")
	check_eq(display.call("get_mode"), "borderless", "unknown modes are ignored")
	display.call("set_size_index", 99)
	check_eq(display.call("get_size_index"), 3, "the window size stays in the list")
	var told: Array = [0.0]
	root.get_node("Game").connect("fov_changed", func(degrees: float) -> void: told[0] = degrees)
	display.call("set_fov", 200.0)
	check_eq(display.call("get_fov"), 100.0, "the field of view stays at most 100")
	check_eq(told[0], 100.0, "the player is told about it")
	display.call("set_mode", "window")


func _window() -> void:
	var window: Control = (load("res://scenes/ui/menus/settings_window.tscn") as PackedScene).instantiate()
	root.add_child(window)
	await process_frame
	window.call("open", false)
	var tabs: Array = window.get("_tab_buttons")
	check_eq(tabs.size(), 4, "four tabs: Grafik, Audio, Steuerung, Fadenkreuz")
	var pages: Array = window.get("_pages")
	check((pages[0] as Control).visible and not (pages[2] as Control).visible, "Grafik first")
	(tabs[2] as Button).pressed.emit()
	check((pages[2] as Control).visible, "the Steuerung tab opens")
	var buttons: Dictionary = window.get("_key_buttons")
	check_eq((buttons[&"bag"] as Button).text, "Tab", "the bag key is shown")
	(buttons[&"bag"] as Button).pressed.emit()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_J
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	await process_frame
	check_eq(script("res://scripts/core/controls.gd").call("get_key", &"bag"), KEY_J, "clicking the key, then pressing J changes it")
	check_eq((buttons[&"bag"] as Button).text, "J", "the button shows J")
	script("res://scripts/core/controls.gd").call("reset_keys")
	await _sensitivity(pages[2] as Control)
	await _crosshair(window, tabs[3] as Button)
	window.queue_free()


## Mouse sensitivity as in CS2: sensitivity × 0.022 degrees per count; a number field takes
## "1,25" and "1.25", the slider follows; nonsense keeps the old value.
func _sensitivity(page: Control) -> void:
	var game: Node = root.get_node("Game")
	check(is_equal_approx(float(game.call("get_mouse_sensitivity")), 2.5), "default 2.5")
	var field: LineEdit = page.find_child("SensitivityField", true, false)
	var slider: HSlider = page.find_child("SensitivitySlider", true, false)
	check(field != null and slider != null, "a slider and a number field")
	field.text = "1,25"
	field.text_submitted.emit(field.text)
	check(is_equal_approx(float(game.call("get_mouse_sensitivity")), 1.25), "the field takes 1,25")
	check(is_equal_approx(slider.value, 1.25), "the slider follows")
	check(is_equal_approx(float(game.call("look_radians_per_count")), deg_to_rad(1.25 * 0.022)), "1.25 x 0.022 degrees per count, like CS2")
	field.text = "abc"
	field.text_submitted.emit(field.text)
	check(is_equal_approx(float(game.call("get_mouse_sensitivity")), 1.25), "nonsense keeps the value")
	check_eq(field.text, "1.25", "and shows it again")
	slider.value = 3.0
	check_eq(field.text, "3.0", "the slider changes the field")
	field.text = "500"
	field.text_submitted.emit(field.text)
	check(is_equal_approx(float(game.call("get_mouse_sensitivity")), 20.0), "at most 20")
	game.call("set_mouse_sensitivity", 2.5)
	await process_frame


## The crosshair tab: style, colour, sizes change the settings (and the preview); off hides it;
## "Standard wiederherstellen" brings the old look back.
func _crosshair(window: Control, tab: Button) -> void:
	var crosshair: Script = script("res://scenes/ui/hud/crosshair.gd")
	tab.pressed.emit()
	var page: Control = (window.get("_pages") as Array)[3]
	check(page.visible, "the Fadenkreuz tab opens")
	check(page.find_child("CrosshairPreview", true, false) != null, "with a preview")
	var style: OptionButton = page.find_child("CrosshairStyle", true, false)
	style.select(2)
	style.item_selected.emit(2)
	check_eq(crosshair.call("get_value", "style"), "off", "style: off")
	var colour: OptionButton = page.find_child("CrosshairColor", true, false)
	colour.item_selected.emit(1)
	check_eq(crosshair.call("get_value", "color"), "green", "colour: green (CS2 colour 1)")
	check((crosshair.call("color") as Color).is_equal_approx(Color8(50, 250, 50)), "the CS2 green")
	check(not (page.find_child("CrosshairCustomColor", true, false) as Control).visible, "no colour picker for a CS2 colour")
	colour.item_selected.emit(5)
	check((page.find_child("CrosshairCustomColor", true, false) as Control).visible, "own colour: the picker shows")
	var gap: HSlider = (page.find_child("Crosshair_gap", true, false) as Control).get_child(0)
	gap.value = -4
	check_eq(int(crosshair.call("get_value", "gap")), -4, "the gap can be negative")
	var t_box: CheckBox = page.find_child("Crosshair_t_style", true, false)
	t_box.toggled.emit(true)
	check(crosshair.call("get_value", "t_style"), "T shape")
	crosshair.call("reset")
	check_eq(crosshair.call("get_value", "style"), "cross", "reset: the cross again")
	check_eq(int(crosshair.call("get_value", "gap")), 9, "and its old gap")
	await process_frame
