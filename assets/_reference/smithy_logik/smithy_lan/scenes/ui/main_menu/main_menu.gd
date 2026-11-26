class_name MainMenu
extends Control
## First scene of the game, in front of the moving smithy (TitleBackdrop):
## 1. Title page: "Smithy – Crystal of the Nine", the smithy door shut, "Hier klicken / oder
##    Leertaste" on the door. A click, a key or a gamepad button opens the door and pulls the
##    camera inside (TitleBackdrop.enter); another one cuts that short.
## 2. Main menu beside the anvil (continue = newest save, only if there is one; new game =
##    character creator, load, settings, exit). The chosen word flies onto the anvil and glows,
##    the sledgehammer comes down on it (TitleBackdrop.strike), then the choice happens.
## Back from the game, the character creator or a language change it starts at the anvil.
## GameState.SKIP_TITLE_SCREEN = true skips all of it and starts directly in the smithy.

## How fast the door hint blinks (seconds per half cycle).
const BLINK_TIME: float = 0.6
const CHARACTER_CREATOR: String = "res://scenes/ui/main_menu/character_creator.tscn"
## Colour of the word on the anvil: hot iron, white hot at the hit.
const HOT_COLOR := Color(1.0, 0.55, 0.2)
const WHITE_HOT := Color(1.0, 0.95, 0.8)
## Seconds the chosen word needs to the anvil.
const WORD_FLIGHT: float = 0.3

## true = start at the anvil (coming back from the character creator or a running game).
static var skip_title_page: bool = false

var _busy: bool = false

@onready var _backdrop: TitleBackdrop = $Backdrop
@onready var _background: TextureRect = $Background
@onready var _title_page: Control = %TitlePage
@onready var _menu_page: Control = %MenuPage
@onready var _door_hint: Control = %DoorHint
@onready var _save_window: SaveWindow = %SaveWindow
@onready var _settings_window: Control = %SettingsWindow
@onready var _lan_window: LanWindow = %LanWindow
@onready var _windows: Array[Control] = [_save_window, _settings_window, _lan_window]


func _ready() -> void:
	# Back in the main menu, a LAN game is over (the host stops hosting, the guest leaves).
	Net.leave()
	if GameState.SKIP_TITLE_SCREEN:
		GameState.travel_to(GameState.START_SCENE, &"")
		return
	_background.texture = _backdrop.get_texture()
	AudioManager.update_ambience()
	_menu_page.hide()
	_backdrop.entered.connect(_on_entered)
	var from_game: bool = skip_title_page
	if skip_title_page:
		_title_page.hide()
		_door_hint.hide()
		_backdrop.skip()
	skip_title_page = false
	for window in _windows:
		window.hide()
		(window.get_node("VBox/TitleBar") as WindowTitleBar).close_requested.connect(window.hide)
	_update_continue_button()
	_save_window.visibility_changed.connect(_update_continue_button)
	%ContinueButton.pressed.connect(_choose.bind(%ContinueButton, _continue_game))
	%NewGameButton.pressed.connect(_choose.bind(%NewGameButton, _start_new_game))
	%LoadButton.pressed.connect(_choose.bind(%LoadButton, _toggle_load_window))
	%LanButton.pressed.connect(_choose.bind(%LanButton, _toggle_window.bind(_lan_window)))
	%SettingsButton.pressed.connect(_choose.bind(%SettingsButton, _toggle_window.bind(_settings_window)))
	%ExitButton.pressed.connect(_choose.bind(%ExitButton, get_tree().quit))
	# Tabs Grafik / Audio / Steuerung / Einleitung (same block as in the HUD).
	_settings_window.get_node("VBox/TitleBar").add_sibling(SettingsPanel.new())
	# Thrown out of a LAN game (host gone): straight to the anvil with the LAN window and the reason.
	if not Net.last_error.is_empty() and from_game:
		_lan_window.show()
	var blink := create_tween().set_loops()
	blink.tween_property(_door_hint, "modulate:a", 0.35, BLINK_TIME)
	blink.tween_property(_door_hint, "modulate:a", 1.0, BLINK_TIME)


func _process(_delta: float) -> void:
	if _door_hint.visible:
		# On the door, whatever size the window has.
		_door_hint.reset_size()
		var at: Vector2 = _to_screen(TitleBackdrop.DOOR_CENTER)
		_door_hint.position = at - _door_hint.size / 2.0


## Title page: any key, mouse button or gamepad button opens the door; while it opens, another one
## goes straight to the anvil. Main menu: Escape closes the open window.
func _input(event: InputEvent) -> void:
	if _title_page.visible:
		if _is_any_key(event):
			get_viewport().set_input_as_handled()
			if _backdrop.stage == TitleBackdrop.Stage.DOOR:
				_step_in()
			else:
				_backdrop.skip()
	elif event.is_action_pressed("ui_cancel"):
		for window in _windows:
			window.hide()
		get_viewport().set_input_as_handled()


func _is_any_key(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.is_pressed() and not event.is_echo()
	return false


func _step_in() -> void:
	var fade := create_tween()
	fade.tween_property(_title_page, "modulate:a", 0.0, 0.3)
	fade.parallel().tween_property(_door_hint, "modulate:a", 0.0, 0.15)
	fade.tween_callback(_door_hint.hide)
	_backdrop.enter()


## At the anvil: the menu fades in (at once when we started there).
func _on_entered() -> void:
	var fade_in: bool = _title_page.visible
	_title_page.hide()
	_door_hint.hide()
	_menu_page.show()
	_menu_page.modulate.a = 0.0 if fade_in else 1.0
	if fade_in:
		create_tween().tween_property(_menu_page, "modulate:a", 1.0, 0.25)


## A point of the 640x360 backdrop on this control (the picture covers it, see Background).
func _to_screen(point: Vector2) -> Vector2:
	var picture := Vector2(_backdrop.size)
	var scale_by: float = maxf(_background.size.x / picture.x, _background.size.y / picture.y)
	return _background.position + (_background.size - picture * scale_by) / 2.0 + point * scale_by


## The chosen word flies onto the anvil and glows, the hammer comes down on it, then `action`.
func _choose(button: Button, action: Callable) -> void:
	if _busy:
		return
	_busy = true
	var word := Label.new()
	word.text = button.text
	word.add_theme_font_size_override("font_size", 22)
	word.add_theme_constant_override("outline_size", 6)
	word.add_theme_color_override("font_color", Color.WHITE)
	word.modulate = button.get_theme_color("font_color")
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(word)
	word.reset_size()
	word.pivot_offset = word.size / 2.0
	word.global_position = button.global_position + (button.size - word.size) / 2.0
	var target: Vector2 = _to_screen(_backdrop.get_anvil_point()) - Vector2(word.size.x / 2.0, word.size.y - 2.0)
	var fly := create_tween()
	fly.tween_property(word, "position", target, WORD_FLIGHT).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	fly.parallel().tween_property(word, "modulate", HOT_COLOR, WORD_FLIGHT)
	await fly.finished
	_backdrop.struck.connect(_on_word_struck.bind(word), CONNECT_ONE_SHOT)
	await _backdrop.strike()
	_busy = false
	action.call()


## The hit: the word goes white hot, jumps and fades.
func _on_word_struck(word: Label) -> void:
	word.modulate = WHITE_HOT
	word.scale = Vector2(1.25, 0.8)
	var cool := create_tween()
	cool.tween_property(word, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	cool.parallel().tween_property(word, "modulate", Color(HOT_COLOR, 0.0), 0.6).set_delay(0.15)
	cool.tween_callback(word.queue_free)


## "Weiterspielen" is only shown when there is a save; it also updates after deleting one
## in the load window. The tooltip says which save will be loaded.
func _update_continue_button() -> void:
	var slot: int = SaveSystem.get_newest_slot()
	%ContinueButton.visible = slot != -1
	if slot != -1:
		%ContinueButton.tooltip_text = "%s\n%s" % [SaveSystem.get_slot_name(slot), SaveSystem.get_saved_at_text(slot)]


func _continue_game() -> void:
	var slot: int = SaveSystem.get_newest_slot()
	if slot == -1 or not GameState.load_game(slot):
		_update_continue_button()
		_save_window.open(SaveWindow.Mode.LOAD)


## A new game starts with the character creator, then in the smithy (story start comes later).
func _start_new_game() -> void:
	# Back from a running game: start from scratch.
	if GameState.in_main_menu:
		GameState.reset_for_new_game()
	get_tree().change_scene_to_file.call_deferred(CHARACTER_CREATOR)


func _toggle_load_window() -> void:
	var was_open: bool = _save_window.visible
	_settings_window.hide()
	if was_open:
		_save_window.hide()
	else:
		_save_window.open(SaveWindow.Mode.LOAD)


func _toggle_window(window: Control) -> void:
	var open: bool = not window.visible
	for other in _windows:
		other.hide()
	window.visible = open
