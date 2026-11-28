class_name SettingsWindow
extends PanelContainer
## Settings (main menu and pause menu), with tabs like in Smithy:
##   Grafik:    Anzeige (Fenster / Rahmenlos / Vollbild), Fenstergröße (only in window mode),
##              VSync, Sichtfeld (field of view in the dungeon), Sprache (main menu only: flags)
##   Audio:     Lautstärke, Musik, Effekte
##   Fadenkreuz: the crosshair like in CS2 (Crosshair), with a preview;
##   Steuerung: mouse sensitivity as in CS2 (slider and number field) and the changeable keys (Controls.REBINDABLE): click a key,
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
	var names: Array[String] = [Language.translate("Grafik"), Language.translate("Audio"), Language.translate("Steuerung"), Language.translate("Fadenkreuz")]
	var builders: Array[Callable] = [_build_graphics, _build_audio, _build_controls, _build_crosshair]
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
	grid.add_child(_label(Language.translate("Tastenhilfe anzeigen")))
	var key_help := CheckBox.new()
	key_help.name = "KeyHelp"
	key_help.focus_mode = Control.FOCUS_NONE
	key_help.button_pressed = BagWindow.key_help_on()
	key_help.toggled.connect(func(on: bool) -> void: WindowLayout.set_setting("ui", "key_help", on))
	grid.add_child(key_help)
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


# --- Fadenkreuz ---------------------------------------------------------------------

## Like the crosshair settings of CS2 (Crosshair): a preview on top, below style, colour,
## opacity, length, thickness, gap, dot, outline, T shape and "Standard wiederherstellen".
## Scrolls, the page has more rows than room.
func _build_crosshair() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 4)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	var preview := Panel.new()
	preview.name = "CrosshairPreview"
	preview.custom_minimum_size = Vector2(0, 54)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.32, 0.36, 0.4)
	back.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", back)
	preview.draw.connect(func() -> void: Crosshair.draw_at(preview, preview.size / 2.0, 3.0))
	Game.crosshair_changed.connect(preview.queue_redraw)
	page.add_child(preview)
	var grid := _grid()
	page.add_child(grid)
	grid.add_child(_label(Language.translate("Stil")))
	var styles: Array[String] = [Language.translate("Kreuz"), Language.translate("Nur Punkt"), Language.translate("Aus")]
	grid.add_child(_choice("CrosshairStyle", styles, Crosshair.STYLES.find(String(Crosshair.get_value("style"))),
			func(index: int) -> void: Crosshair.set_value("style", Crosshair.STYLES[index])))
	grid.add_child(_label(Language.translate("Farbe")))
	var colors := HBoxContainer.new()
	var picker := ColorPickerButton.new()
	picker.name = "CrosshairCustomColor"
	picker.custom_minimum_size = Vector2(28, 0)
	picker.edit_alpha = false
	picker.focus_mode = Control.FOCUS_NONE
	picker.color = Crosshair.get_value("custom_color") as Color
	picker.visible = String(Crosshair.get_value("color")) == "custom"
	picker.color_changed.connect(func(value: Color) -> void: Crosshair.set_value("custom_color", value))
	var names: Array[String] = [Language.translate("Rot"), Language.translate("Grün"), Language.translate("Gelb"),
			Language.translate("Blau"), Language.translate("Cyan"), Language.translate("Eigene")]
	colors.add_child(_choice("CrosshairColor", names, Crosshair.COLORS.find(String(Crosshair.get_value("color"))),
			func(index: int) -> void:
				Crosshair.set_value("color", Crosshair.COLORS[index])
				picker.visible = Crosshair.COLORS[index] == "custom"))
	colors.add_child(picker)
	grid.add_child(colors)
	for row: Array in [["Deckkraft", "alpha", 0, 255], ["Länge", "length", 0, 40], ["Dicke", "thickness", 1, 12],
			["Abstand", "gap", -10, 30], ["Umriss-Dicke", "outline_thickness", 1, 6]]:
		grid.add_child(_label(_crosshair_label(String(row[0]))))
		var key: String = row[1]
		var slider_row: Control = _slider(float(row[2]), float(row[3]), float(Crosshair.get_value(key)),
				func(v: float) -> void: Crosshair.set_value(key, roundi(v)), "%d")
		slider_row.name = "Crosshair_" + key
		grid.add_child(slider_row)
	for row: Array in [["Punkt in der Mitte", "dot"], ["Umriss", "outline"], ["T-Form (oben offen)", "t_style"]]:
		grid.add_child(_label(_crosshair_label(String(row[0]))))
		var key: String = row[1]
		var box := CheckBox.new()
		box.name = "Crosshair_" + key
		box.focus_mode = Control.FOCUS_NONE
		box.button_pressed = bool(Crosshair.get_value(key))
		box.toggled.connect(func(on: bool) -> void: Crosshair.set_value(key, on))
		grid.add_child(box)
	var reset := _button(Language.translate("Standard wiederherstellen"))
	reset.pressed.connect(_reset_crosshair.bind(scroll))
	page.add_child(reset)
	return scroll


## "Standard wiederherstellen": every value back, the page built again with them.
func _reset_crosshair(old_page: Control) -> void:
	Crosshair.reset()
	var at: int = _pages.find(old_page)
	if at < 0:
		return
	var page: Control = _build_crosshair()
	page.custom_minimum_size = PAGE_SIZE
	old_page.get_parent().add_child(page)
	old_page.get_parent().move_child(page, old_page.get_index())
	_pages[at] = page
	old_page.queue_free()
	_show_page(at)


## Written out so the translation script finds every text.
func _crosshair_label(text: String) -> String:
	match text:
		"Deckkraft": return Language.translate("Deckkraft")
		"Länge": return Language.translate("Länge")
		"Dicke": return Language.translate("Dicke")
		"Abstand": return Language.translate("Abstand")
		"Umriss-Dicke": return Language.translate("Umriss-Dicke")
		"Punkt in der Mitte": return Language.translate("Punkt in der Mitte")
		"Umriss": return Language.translate("Umriss")
	return Language.translate("T-Form (oben offen)")


## A drop-down with `items` (already translated), `selected` chosen, `on_select(index)`.
func _choice(node_name: String, items: Array[String], selected: int, on_select: Callable) -> OptionButton:
	var button := OptionButton.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	for text: String in items:
		button.add_item(text)
	button.select(maxi(0, selected))
	button.item_selected.connect(on_select)
	return button


# --- Steuerung ----------------------------------------------------------------------

func _build_controls() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 4)
	var grid := _grid()
	page.add_child(grid)
	grid.add_child(_label(Language.translate("Maus-Empfindlichkeit")))
	grid.add_child(_sensitivity_row())
	page.add_child(_label(Language.translate("Wie in Counter-Strike 2: dieselbe Zahl dreht genauso weit."), COLOR_HINT, 10))
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
		Controls.TALK: return Language.translate("Reden")
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


## Mouse sensitivity: a slider (0.1 … 10) and right of it a field for the exact number (also
## with a comma, 0.01 … 20, like the CS2 value). Both show the same value.
func _sensitivity_row() -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.name = "SensitivitySlider"
	slider.min_value = 0.1
	slider.max_value = 10.0
	slider.step = 0.01
	slider.value = Game.get_mouse_sensitivity()
	slider.focus_mode = Control.FOCUS_NONE
	slider.custom_minimum_size = Vector2(120, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var field := LineEdit.new()
	field.name = "SensitivityField"
	field.text = _sensitivity_text(Game.get_mouse_sensitivity())
	field.custom_minimum_size = Vector2(56, 0)
	field.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field.add_theme_font_size_override("font_size", FONT_SIZE)
	field.select_all_on_focus = true
	row.add_child(field)
	slider.value_changed.connect(func(v: float) -> void:
			Game.set_mouse_sensitivity(v)
			field.text = _sensitivity_text(Game.get_mouse_sensitivity()))
	var take := func(text: String) -> void:
		var number: float = parse_sensitivity(text)
		if number > 0.0:
			Game.set_mouse_sensitivity(number)
		field.text = _sensitivity_text(Game.get_mouse_sensitivity())
		slider.set_value_no_signal(Game.get_mouse_sensitivity())
	field.text_submitted.connect(take)
	field.focus_exited.connect(func() -> void: take.call(field.text))
	return row


## "1,25" or "1.25" -> 1.25; 0 for text that is no number.
static func parse_sensitivity(text: String) -> float:
	var clean: String = text.strip_edges().replace(",", ".")
	return clean.to_float() if clean.is_valid_float() else 0.0


static func _sensitivity_text(value: float) -> String:
	return String.num(value, 3)


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
