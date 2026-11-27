class_name SettingsWindow
extends PanelContainer
## Settings (main menu and pause menu), with tabs like in Smithy:
##   Grafik:    Anzeige (Fenster / Rahmenlos / Vollbild), Fenstergröße (only in window mode),
##              VSync, Sichtfeld (field of view in the dungeon), Sprache (main menu only: flags)
##   Audio:     Lautstärke, Musik, Effekte
##   Steuerung: Maus (sensitivity) and the changeable keys (Controls.REBINDABLE): click a key,
##              then press the new one (Esc = cancel); "Standard wiederherstellen".
## Values are saved at once in user://settings.cfg (DisplaySettings, AudioManager, Game, Controls).
## Built in code; the .tscn is only the window.

signal closed
## The "Sprache" button (the main menu shows the flags).
signal language_requested

const FONT_SIZE: int = 12
const PAGE_SIZE := Vector2(320, 190)
const COLOR_TITLE := Color(1, 0.86, 0.55)
const COLOR_HINT := Color(0.62, 0.6, 0.56)
const KEY_BUTTON_WIDTH: float = 80.0

var _pages: Array[Control] = []
var _tab_buttons: Array[Button] = []
var _mode_button: OptionButton
var _size_button: OptionButton
var _size_hint: Label
var _language: Button
## action -> its key button (tab Steuerung).
var _key_buttons: Dictionary = {}
## The action waiting for a new key ("" = none).
var _waiting: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := _label(Language.translate("Einstellungen"), COLOR_TITLE, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	column.add_child(tabs)
	var group := ButtonGroup.new()
	var names: Array[String] = [Language.translate("Grafik"), Language.translate("Audio"), Language.translate("Steuerung")]
	var builders: Array[Callable] = [_build_graphics, _build_audio, _build_controls]
	for i in names.size():
		var tab := _button(names[i])
		tab.toggle_mode = true
		tab.button_group = group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_show_page.bind(i))
		tabs.add_child(tab)
		_tab_buttons.append(tab)
		var page: Control = builders[i].call()
		page.custom_minimum_size = PAGE_SIZE
		column.add_child(page)
		_pages.append(page)
	var close_button := _button(Language.translate("Schließen"))
	close_button.pressed.connect(close)
	column.add_child(close_button)
	_show_page(0)


## `with_language`: show the language button (only where the menu can show the flags).
func open(with_language: bool) -> void:
	_language.visible = with_language
	_refresh()
	show()


func close() -> void:
	_cancel_waiting()
	hide()
	closed.emit()


func _show_page(index: int) -> void:
	_cancel_waiting()
	for i in _pages.size():
		_pages[i].visible = i == index
		_tab_buttons[i].set_pressed_no_signal(i == index)


# --- Grafik -------------------------------------------------------------------------

func _build_graphics() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 4)
	var grid := _grid()
	page.add_child(grid)
	grid.add_child(_label(Language.translate("Anzeige")))
	_mode_button = OptionButton.new()
	_mode_button.focus_mode = Control.FOCUS_NONE
	_mode_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for text: String in [Language.translate("Fenster"), Language.translate("Rahmenlos"), Language.translate("Vollbild")]:
		_mode_button.add_item(text)
	_mode_button.item_selected.connect(func(index: int) -> void:
			DisplaySettings.set_mode(DisplaySettings.MODES[index])
			_refresh())
	grid.add_child(_mode_button)
	grid.add_child(_label(Language.translate("Fenstergröße")))
	_size_button = OptionButton.new()
	_size_button.focus_mode = Control.FOCUS_NONE
	_size_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for window_size: Vector2i in DisplaySettings.SIZES:
		_size_button.add_item("%d × %d" % [window_size.x, window_size.y])
	_size_button.item_selected.connect(DisplaySettings.set_size_index)
	grid.add_child(_size_button)
	grid.add_child(_label("VSync"))
	var vsync := CheckBox.new()
	vsync.focus_mode = Control.FOCUS_NONE
	vsync.button_pressed = DisplaySettings.is_vsync()
	vsync.toggled.connect(DisplaySettings.set_vsync)
	grid.add_child(vsync)
	grid.add_child(_label(Language.translate("Sichtfeld")))
	grid.add_child(_slider(DisplaySettings.FOV_MIN, DisplaySettings.FOV_MAX, DisplaySettings.get_fov(), DisplaySettings.set_fov, "%d°"))
	_size_hint = _label(Language.translate("Die Fenstergröße gilt nur im Fenster-Modus."), COLOR_HINT, 10)
	page.add_child(_size_hint)
	_language = _button(Language.translate("Sprache"))
	_language.pressed.connect(language_requested.emit)
	page.add_child(_language)
	return page


func _refresh() -> void:
	_mode_button.select(DisplaySettings.MODES.find(DisplaySettings.get_mode()))
	_size_button.select(DisplaySettings.get_size_index())
	var windowed: bool = DisplaySettings.get_mode() == "window"
	_size_button.disabled = not windowed
	_size_hint.visible = not windowed
	_refresh_keys()


# --- Audio --------------------------------------------------------------------------

func _build_audio() -> Control:
	var grid := _grid()
	grid.add_child(_label(Language.translate("Lautstärke")))
	grid.add_child(_slider(0, 100, AudioManager.get_volume(AudioManager.MASTER) * 100.0,
			func(v: float) -> void: AudioManager.set_volume(AudioManager.MASTER, v / 100.0), "%d %%"))
	grid.add_child(_label(Language.translate("Musik")))
	grid.add_child(_slider(0, 100, AudioManager.get_volume(AudioManager.MUSIC) * 100.0,
			func(v: float) -> void: AudioManager.set_volume(AudioManager.MUSIC, v / 100.0), "%d %%"))
	grid.add_child(_label(Language.translate("Effekte")))
	grid.add_child(_slider(0, 100, AudioManager.get_volume(AudioManager.SOUNDS) * 100.0,
			func(v: float) -> void:
				AudioManager.set_volume(AudioManager.SOUNDS, v / 100.0)
				AudioManager.set_volume(AudioManager.INTERFACE, v / 100.0), "%d %%"))
	return grid


# --- Steuerung ----------------------------------------------------------------------

func _build_controls() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 4)
	var grid := _grid()
	page.add_child(grid)
	grid.add_child(_label(Language.translate("Maus")))
	grid.add_child(_slider(0, 100, Game.get_mouse_sensitivity() * 100.0,
			func(v: float) -> void: Game.set_mouse_sensitivity(v / 100.0), "%d %%"))
	page.add_child(_label(Language.translate("Klick auf eine Taste, dann die neue drücken. Esc = abbrechen."), COLOR_HINT, 10))
	var keys := GridContainer.new()
	keys.columns = 4
	keys.add_theme_constant_override("h_separation", 6)
	keys.add_theme_constant_override("v_separation", 2)
	page.add_child(keys)
	for action: StringName in Controls.REBINDABLE:
		keys.add_child(_label(_action_name(action)))
		var key_button := _button("")
		key_button.custom_minimum_size = Vector2(KEY_BUTTON_WIDTH, 0)
		key_button.pressed.connect(_start_waiting.bind(action))
		keys.add_child(key_button)
		_key_buttons[action] = key_button
	var reset := _button(Language.translate("Standard wiederherstellen"))
	reset.pressed.connect(func() -> void:
			_cancel_waiting()
			Controls.reset_keys()
			_refresh_keys())
	page.add_child(reset)
	return page


## The name of an action on the Steuerung tab (written out for the translation script).
func _action_name(action: StringName) -> String:
	match action:
		Controls.MOVE_FORWARD: return Language.translate("Vorwärts")
		Controls.MOVE_BACK: return Language.translate("Rückwärts")
		Controls.MOVE_LEFT: return Language.translate("Links")
		Controls.MOVE_RIGHT: return Language.translate("Rechts")
		Controls.BOMB: return Language.translate("Bombe")
		Controls.BAG: return Language.translate("Inventar")
		Controls.MAP: return Language.translate("Karte")
		Controls.DASH: return Language.translate("Ausweichen")
		Controls.POTION: return Language.translate("Trank trinken")
	return String(action)


func _refresh_keys() -> void:
	for action: StringName in _key_buttons:
		(_key_buttons[action] as Button).text = Language.translate("Taste …") if action == _waiting \
				else Controls.key_name(Controls.get_key(action))


func _start_waiting(action: StringName) -> void:
	_waiting = action
	_refresh_keys()


func _cancel_waiting() -> void:
	if _waiting != &"":
		_waiting = &""
		_refresh_keys()


## While a key button waits: the next key becomes the new one (Esc cancels).
func _input(event: InputEvent) -> void:
	if _waiting == &"" or not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.physical_keycode == KEY_ESCAPE:
		_cancel_waiting()
		return
	Controls.set_key(_waiting, key.physical_keycode)
	_waiting = &""
	_refresh_keys()


# --- Helpers ------------------------------------------------------------------------

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	return grid


## A slider with its value as text beside it (`format` e.g. "%d %%").
func _slider(low: float, high: float, value: float, on_change: Callable, format: String) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 1.0
	slider.value = value
	slider.focus_mode = Control.FOCUS_NONE
	slider.custom_minimum_size = Vector2(140, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var shown := _label(format % roundi(value), COLOR_HINT, 10)
	shown.custom_minimum_size = Vector2(36, 0)
	row.add_child(shown)
	slider.value_changed.connect(func(v: float) -> void:
			shown.text = format % roundi(v)
			on_change.call(v))
	return row


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color = Color.WHITE, font_size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if font_size <= 10 else TextServer.AUTOWRAP_OFF
	if font_size <= 10:
		label.custom_minimum_size = Vector2(PAGE_SIZE.x, 0)
	return label
