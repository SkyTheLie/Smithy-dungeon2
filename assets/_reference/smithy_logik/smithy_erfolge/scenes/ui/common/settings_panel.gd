class_name SettingsPanel
extends VBoxContainer
## Content of both settings windows (HUD and main menu): tabs "Grafik", "Oberfläche", "Audio",
## "Steuerung" and "Einleitung". Builds its own children, so it can simply be added with SettingsPanel.new().
##   Grafik:     window mode (Fenster / Rahmenlos / Vollbild), window size (DisplaySettings) and
##               language (Language)
##   Oberfläche: size of each HUD part on its own (UiScale)
##   Audio:      music and sounds (AudioSettings)
##   Steuerung:  every changeable key with two places (KeyBindings): click a place, then press
##               the new key (Esc = cancel, Entf = clear); "Standard" resets all; below the
##               mouse controls that can't be changed
##   Einleitung: the tips (IntroHelp)

const FONT_SIZE: int = 11
## Size of the area below the tabs (all tabs the same, so the window does not jump).
const PAGE_SIZE: Vector2 = Vector2(230, 150)
const KEY_BUTTON_WIDTH: float = 52.0
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_KEY: Color = Color(0.95, 0.82, 0.5)
const TEXT_WAITING: String = "Taste ..."
## Controls that can't be changed: [what you press, what it does].
const FIXED_CONTROLS: Array[Array] = [
	["Esc", "Fenster schließen, Einstellungen"],
	["Rechtsklick", "Item in Station legen / ausrüsten"],
	["Strg+Rechtsklick", "nur 1 Stück"],
	["Shift+Rechtsklick", "halber Stapel"],
	["Ziehen", "Item verschieben, auch aus Stationen zurück"],
	["Shift", "Details im Tooltip"],
	["Rechtsklick", "im Skillbaum: Befehl für den Skill"],
]

var _pages: Array[Control] = []
var _mode_button: OptionButton
var _resolution_button: OptionButton
var _resolution_hint: Label
var _language_button: OptionButton
## Says that items and story change only after a restart.
var _language_hint: Label
## One size slider per HUD part (tab "Oberfläche").
var _scale_sliders: Array[HSlider] = []
## "action:place" -> Button.
var _key_buttons: Dictionary = {}
## The place waiting for a new key: [action, index], empty = none.
var _waiting: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 4)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	add_child(tabs)
	var group := ButtonGroup.new()
	var pages: Array[Control] = [_build_graphics(), _build_interface(), _build_audio(), _build_controls(), _build_intro()]
	var names: Array[String] = [Language.translate("Grafik"), Language.translate("Oberfläche"), Language.translate("Audio"), Language.translate("Steuerung"), Language.translate("Einleitung")]
	for i in pages.size():
		var tab := _create_button(names[i])
		tab.toggle_mode = true
		tab.button_group = group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_show_page.bind(i))
		tabs.add_child(tab)
		var page: Control = pages[i]
		page.custom_minimum_size = PAGE_SIZE
		add_child(page)
		_pages.append(page)
	(tabs.get_child(0) as Button).button_pressed = true
	_show_page(0)
	visibility_changed.connect(_on_visibility_changed)


func _show_page(index: int) -> void:
	_cancel_waiting()
	for i in _pages.size():
		_pages[i].visible = i == index


func _on_visibility_changed() -> void:
	_cancel_waiting()
	if is_visible_in_tree():
		_refresh_graphics()
		_refresh_interface()
		_refresh_keys()


# --- Grafik -----------------------------------------------------------------------------

func _build_graphics() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 3)
	page.add_child(_create_label(Language.translate("Anzeige")))
	_mode_button = _create_option_button()
	for mode in DisplaySettings.MODES:
		_mode_button.add_item(mode["name"])
	_mode_button.item_selected.connect(func(index: int) -> void:
		DisplaySettings.set_mode(DisplaySettings.MODES[index]["id"])
		_refresh_graphics())
	page.add_child(_mode_button)
	page.add_child(_create_label(Language.translate("Fenstergröße")))
	_resolution_button = _create_option_button()
	_resolution_button.item_selected.connect(func(index: int) -> void:
		DisplaySettings.set_resolution(DisplaySettings.get_available_resolutions()[index]))
	page.add_child(_resolution_button)
	_resolution_hint = _create_label("", COLOR_HINT)
	_resolution_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_resolution_hint)
	page.add_child(_create_label(Language.translate("Sprache")))
	_language_button = _create_option_button()
	for code in Language.get_available():
		_language_button.add_item(Language.get_language_name(code))
	# Language names stay in their own language.
	_language_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_language_button.item_selected.connect(func(index: int) -> void:
		Language.set_current(Language.get_available()[index])
		# In the main menu no game runs: load the content in the new language and rebuild the menu.
		if get_tree().current_scene is MainMenu:
			Language.reload_content()
			MainMenu.skip_title_page = true
			get_tree().reload_current_scene.call_deferred()
			return
		_refresh_graphics())
	page.add_child(_language_button)
	_language_hint = _create_label("", COLOR_HINT)
	_language_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_language_hint)
	return page


func _refresh_graphics() -> void:
	var mode: String = DisplaySettings.get_mode()
	for i in DisplaySettings.MODES.size():
		if DisplaySettings.MODES[i]["id"] == mode:
			_mode_button.select(i)
	_resolution_button.clear()
	var resolutions: Array[Vector2i] = DisplaySettings.get_available_resolutions()
	var current: Vector2i = DisplaySettings.get_resolution()
	for i in resolutions.size():
		_resolution_button.add_item("%d × %d" % [resolutions[i].x, resolutions[i].y])
		if resolutions[i] == current:
			_resolution_button.select(i)
	var windowed: bool = mode == "window"
	_resolution_button.disabled = not windowed
	_resolution_hint.text = "" if windowed else Language.translate("Die Fenstergröße gilt nur im Fenster-Modus; sonst füllt das Spiel den Bildschirm.")
	_language_button.select(Language.get_available().find(Language.get_current()))
	_language_hint.text = Language.translate("Neu starten, damit auch Gegenstände und Geschichte die neue Sprache zeigen.") if Language.needs_restart() else ""


# --- Oberfläche -------------------------------------------------------------------------

## One size slider per part of the HUD (UiScale.ELEMENTS, 100 % = its default), applied at once.
func _build_interface() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	scroll.add_child(box)
	var hint := _create_label(Language.translate("Größe jedes Teils der Oberfläche, 100 % = Standard. Ziehen zum Ändern."), COLOR_HINT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 1)
	box.add_child(grid)
	for element in UiScale.ELEMENTS:
		var id: String = element[0]
		var label := _create_label(element[1])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(label)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var slider := HSlider.new()
		slider.focus_mode = Control.FOCUS_NONE
		slider.min_value = UiScale.PERCENT_MIN
		slider.max_value = UiScale.PERCENT_MAX
		slider.step = UiScale.PERCENT_STEP
		slider.custom_minimum_size = Vector2(100, 0)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.set_meta(&"ui_scale_id", id)
		row.add_child(slider)
		var percent := _create_label("")
		percent.custom_minimum_size = Vector2(34, 0)
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percent)
		slider.set_meta(&"percent_label", percent)
		slider.value_changed.connect(func(value: float) -> void:
			percent.text = "%d %%" % roundi(value)
			UiScale.set_percent(id, value))
		grid.add_child(row)
		_scale_sliders.append(slider)
	var reset := _create_button(Language.translate("Standard wiederherstellen"))
	reset.pressed.connect(func() -> void:
		UiScale.reset_all()
		_refresh_interface())
	box.add_child(reset)
	return scroll


func _refresh_interface() -> void:
	for slider in _scale_sliders:
		var value: float = UiScale.get_percent(String(slider.get_meta(&"ui_scale_id")))
		# No signal: setting the slider here must not save the value again.
		slider.set_value_no_signal(value)
		(slider.get_meta(&"percent_label") as Label).text = "%d %%" % roundi(slider.value)


# --- Audio ------------------------------------------------------------------------------

func _build_audio() -> Control:
	# Five sliders can be taller than the page: scroll like the other pages.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var sliders := AudioSettings.new()
	sliders.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sliders)
	return scroll


# --- Steuerung --------------------------------------------------------------------------

func _build_controls() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	scroll.add_child(box)
	var hint := _create_label(Language.translate("Klick auf eine Taste, dann die neue drücken. Esc = abbrechen, Entf = leeren."), COLOR_HINT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 1 + KeyBindings.KEYS_PER_ACTION
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 1)
	box.add_child(grid)
	for entry in KeyBindings.ACTIONS:
		var action: String = entry[0]
		var label := _create_label(entry[1])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(label)
		for index in KeyBindings.KEYS_PER_ACTION:
			var button := _create_button("")
			button.custom_minimum_size = Vector2(KEY_BUTTON_WIDTH, 0)
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.pressed.connect(_start_waiting.bind(action, index))
			grid.add_child(button)
			_key_buttons["%s:%d" % [action, index]] = button
	var reset := _create_button(Language.translate("Standard wiederherstellen"))
	reset.pressed.connect(func() -> void:
		_cancel_waiting()
		KeyBindings.reset_all()
		_refresh_keys())
	box.add_child(reset)
	box.add_child(_create_label(Language.translate("Maus und feste Tasten"), COLOR_HINT))
	var fixed := GridContainer.new()
	fixed.columns = 2
	fixed.add_theme_constant_override("h_separation", 6)
	fixed.add_theme_constant_override("v_separation", 0)
	for entry in FIXED_CONTROLS:
		fixed.add_child(_create_label(entry[0], COLOR_KEY))
		var text := _create_label(entry[1])
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fixed.add_child(text)
	box.add_child(fixed)
	return scroll


func _refresh_keys() -> void:
	for place: String in _key_buttons:
		var key: Key = KeyBindings.get_keys(place.get_slice(":", 0))[int(place.get_slice(":", 1))]
		var text: String = KeyBindings.get_key_name(key)
		(_key_buttons[place] as Button).text = text if not text.is_empty() else "–"


func _start_waiting(action: String, index: int) -> void:
	_cancel_waiting()
	_waiting = [action, index]
	(_key_buttons["%s:%d" % [action, index]] as Button).text = Language.translate(TEXT_WAITING)


func _cancel_waiting() -> void:
	if _waiting.is_empty():
		return
	_waiting = []
	_refresh_keys()


## While a place waits: the next key becomes its key (before anything else sees it).
func _input(event: InputEvent) -> void:
	if _waiting.is_empty():
		return
	if event is InputEventMouseButton and event.pressed:
		_cancel_waiting()
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	var code: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if KeyBindings.RESERVED.has(code):
		_cancel_waiting()
		return
	var place: Array = _waiting
	_waiting = []
	KeyBindings.set_key(place[0], place[1], KEY_NONE if code == KEY_DELETE else code)
	_refresh_keys()


# --- Einleitung -------------------------------------------------------------------------

func _build_intro() -> Control:
	var intro := IntroHelp.new()
	intro.collapsible = false
	return intro


# --- Helpers ----------------------------------------------------------------------------

func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _create_option_button() -> OptionButton:
	var button := OptionButton.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.get_popup().add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _create_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	return label
