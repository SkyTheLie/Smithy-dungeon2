class_name DisplaySettings
extends RefCounted
## Graphics settings: window mode (window / borderless / fullscreen) and the window size in
## window mode. Saved in user://settings.cfg (section "display", WindowLayout) and applied at the
## start (GameState, apply_saved) and whenever they change (SettingsPanel, tab "Grafik").
##   "window"     = normal window with frame, size from RESOLUTIONS
##   "borderless" = window without frame that covers the whole screen (fast alt-tab)
##   "fullscreen" = exclusive fullscreen
## The game always renders at 640×360 and is scaled up (stretch mode canvas_items), so a
## bigger size only makes the picture bigger, not the world.

const SECTION: String = "display"
const MODES: Array[Dictionary] = [
	{"id": "window", "name": "Fenster"},
	{"id": "borderless", "name": "Rahmenlos"},
	{"id": "fullscreen", "name": "Vollbild"},
]
## Window sizes to choose from (multiples of 640×360 look sharpest).
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160),
]
const DEFAULT_MODE: String = "window"
const DEFAULT_RESOLUTION: Vector2i = Vector2i(1280, 720)


static func get_mode() -> String:
	return String(WindowLayout.get_setting(SECTION, "mode", DEFAULT_MODE))


static func get_resolution() -> Vector2i:
	return WindowLayout.get_setting(SECTION, "resolution", DEFAULT_RESOLUTION)


static func set_mode(mode: String) -> void:
	WindowLayout.set_setting(SECTION, "mode", mode)
	apply()


static func set_resolution(resolution: Vector2i) -> void:
	WindowLayout.set_setting(SECTION, "resolution", resolution)
	apply()


## Sizes that fit on the current screen (always at least the smallest one).
static func get_available_resolutions() -> Array[Vector2i]:
	var screen: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var list: Array[Vector2i] = []
	for resolution in RESOLUTIONS:
		if resolution.x <= screen.x and resolution.y <= screen.y:
			list.append(resolution)
	if list.is_empty():
		list.append(RESOLUTIONS[0])
	return list


## At the start: the saved settings, if the player ever changed them (else the project's window).
static func apply_saved() -> void:
	if WindowLayout.has_setting(SECTION, "mode"):
		apply()


## Puts the saved settings into effect. Does nothing headless or in the editor's embedded game view.
static func apply() -> void:
	if DisplayServer.get_name() == "headless" or Engine.is_embedded_in_editor():
		return
	match get_mode():
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			# Godot's "fullscreen" is a frameless window as big as the screen.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_apply_window_size()


## Window mode: the saved size (shrunk to fit the screen), centred on the screen.
static func _apply_window_size() -> void:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var size: Vector2i = get_resolution()
	size = Vector2i(mini(size.x, screen_rect.size.x), mini(size.y, screen_rect.size.y))
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - size) / 2)
