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

## Seconds after a changed setting until the file is written (set_setting): a slider that is
## dragged changes its value many times a second.
const SAVE_DELAY: float = 0.5

static var _config: ConfigFile
## A changed setting waits to be written (flush).
static var _save_pending: bool = false


## Saved position of a pinned window, or Vector2.INF if it is not pinned.
static func get_pinned_position(window_id: String) -> Vector2:
	return _get_config().get_value(SECTION, window_id, Vector2.INF)


static func pin(window_id: String, position: Vector2) -> void:
	_get_config().set_value(SECTION, window_id, position)
	_save_pending = false
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
## The value counts at once (get_setting); the file is written shortly after, once for all changes
## of that time, and at the latest when the game closes.
static func set_setting(section: String, key: String, value: Variant) -> void:
	_get_config().set_value(section, key, value)
	_save_soon()


static func _save_soon() -> void:
	if _save_pending:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_config.save(SETTINGS_PATH)
		return
	_save_pending = true
	# Runs while the game is paused too: the settings window pauses the game.
	tree.create_timer(SAVE_DELAY).timeout.connect(flush)
	if not tree.root.tree_exiting.is_connected(flush):
		tree.root.tree_exiting.connect(flush)


## Writes waiting settings to the file now.
static func flush() -> void:
	if _save_pending and _config:
		_save_pending = false
		_config.save(SETTINGS_PATH)


static func _get_config() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(SETTINGS_PATH)  # missing file = nothing pinned yet
	return _config
