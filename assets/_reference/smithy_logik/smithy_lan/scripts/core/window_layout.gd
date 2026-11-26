class_name WindowLayout
extends RefCounted
## Remembers the positions of pinned windows (pin in the title bar, see WindowTitleBar).
## Stored in user://settings.cfg, so they stay the same across scene changes, saves and
## restarts of the game. A window is identified by "<CanvasLayer name>/<window name>",
## e.g. "HUD/InventoryWindow" or "ForgeMenu/Panel".
## The same file also holds other settings (get_setting / set_setting, e.g. the volume), so
## everything that writes it shares one ConfigFile and nothing overwrites the rest.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "pinned_windows"

static var _config: ConfigFile


## Saved position of a pinned window, or Vector2.INF if it is not pinned.
static func get_pinned_position(window_id: String) -> Vector2:
	return _get_config().get_value(SECTION, window_id, Vector2.INF)


static func pin(window_id: String, position: Vector2) -> void:
	_get_config().set_value(SECTION, window_id, position)
	_config.save(SETTINGS_PATH)


static func unpin(window_id: String) -> void:
	var config: ConfigFile = _get_config()
	if config.has_section_key(SECTION, window_id):
		config.erase_section_key(SECTION, window_id)
		config.save(SETTINGS_PATH)


## Any other setting from user://settings.cfg (e.g. section "audio"), `default` if not set yet.
static func get_setting(section: String, key: String, default: Variant) -> Variant:
	return _get_config().get_value(section, key, default)


static func has_setting(section: String, key: String) -> bool:
	return _get_config().has_section_key(section, key)


## `value` null removes the setting.
static func set_setting(section: String, key: String, value: Variant) -> void:
	_get_config().set_value(section, key, value)
	_config.save(SETTINGS_PATH)


static func _get_config() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(SETTINGS_PATH)  # missing file = nothing pinned yet
	return _config
