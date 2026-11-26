class_name DisplaySettings
extends RefCounted
## Display settings (tab "Grafik" in the settings, like in Smithy), saved in user://settings.cfg
## section "display" (WindowLayout): window mode (Fenster / Rahmenlos / Vollbild), window size
## (only in window mode), VSync and the field of view of the dungeon camera. apply() sets the window
## at the start (Game._ready) and after every change. Headless (tests) nothing touches the window.

const SECTION: String = "display"
const MODES: Array[String] = ["window", "borderless", "fullscreen"]
const SIZES: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const DEFAULT_SIZE: int = 1
const FOV_MIN: float = 60.0
const FOV_MAX: float = 100.0
const FOV_DEFAULT: float = 80.0


static func get_mode() -> String:
	var mode: String = String(WindowLayout.get_setting(SECTION, "mode", ""))
	if not MODES.has(mode):
		# Older settings only knew "fullscreen" on / off.
		mode = "fullscreen" if bool(WindowLayout.get_setting(SECTION, "fullscreen", false)) else "window"
	return mode


static func set_mode(mode: String) -> void:
	if MODES.has(mode):
		WindowLayout.set_setting(SECTION, "mode", mode)
		apply()


static func get_size_index() -> int:
	return clampi(int(WindowLayout.get_setting(SECTION, "size", DEFAULT_SIZE)), 0, SIZES.size() - 1)


static func set_size_index(index: int) -> void:
	WindowLayout.set_setting(SECTION, "size", clampi(index, 0, SIZES.size() - 1))
	apply()


static func is_vsync() -> bool:
	return bool(WindowLayout.get_setting(SECTION, "vsync", true))


static func set_vsync(on: bool) -> void:
	WindowLayout.set_setting(SECTION, "vsync", on)
	apply()


## Field of view of the dungeon camera in degrees (the player reads it, Game.fov_changed).
static func get_fov() -> float:
	return clampf(float(WindowLayout.get_setting(SECTION, "fov", FOV_DEFAULT)), FOV_MIN, FOV_MAX)


static func set_fov(degrees: float) -> void:
	WindowLayout.set_setting(SECTION, "fov", clampf(degrees, FOV_MIN, FOV_MAX))
	Game.fov_changed.emit(get_fov())


static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if is_vsync() else DisplayServer.VSYNC_DISABLED)
	match get_mode():
		"fullscreen":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			# A window without frame that covers the whole screen.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen: int = DisplayServer.window_get_current_screen()
			DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
			DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var window_size: Vector2i = SIZES[get_size_index()]
			var screen: int = DisplayServer.window_get_current_screen()
			var area: Rect2i = DisplayServer.screen_get_usable_rect(screen)
			window_size = window_size.min(area.size)
			DisplayServer.window_set_size(window_size)
			DisplayServer.window_set_position(area.position + (area.size - window_size) / 2)
