class_name MainMenu
extends Control
## First scene (taken over from Smithy), in front of the moving smithy (TitleBackdrop):
## 1. Title page: the smithy door shut, "Hier klicken / oder Leertaste" on the door. A click, a key
##    or a gamepad button opens the door and pulls the camera inside; another one cuts it short.
## 2. Main menu beside the anvil: Neues Spiel (starts a run), Lexikon (all items found so far),
##    Einstellungen, Beenden. The chosen
##    word flies onto the anvil and glows, the sledgehammer comes down on it, then the choice happens.
## 0. Before the title page on the first start: the language choice (LanguageSelect, flags); also
##    from the settings ("Sprache"). The menu then starts again in the chosen language.
## Back from a run it starts at the anvil.

## How fast the door hint blinks (seconds per half cycle).
const BLINK_TIME: float = 0.6
## Colour of the word on the anvil: hot iron, white hot at the hit.
const HOT_COLOR := Color(1.0, 0.55, 0.2)
const WHITE_HOT := Color(1.0, 0.95, 0.8)
## Seconds the chosen word needs to the anvil.
const WORD_FLIGHT: float = 0.3

## true = start at the anvil (back from a run or after a language change). A menu flag of this
## program start, not game state.
static var skip_title_page: bool = false

var _busy: bool = false

@onready var _backdrop: TitleBackdrop = $Backdrop
@onready var _background: TextureRect = $Background
@onready var _title_page: Control = %TitlePage
@onready var _menu_page: Control = %MenuPage
@onready var _door_hint: Control = %DoorHint
@onready var _settings_window: SettingsWindow = %SettingsWindow
@onready var _lexicon_window: LexiconWindow = %LexiconWindow
@onready var _character_select: CharacterSelect = %CharacterSelect
@onready var _language_select: LanguageSelect = %LanguageSelect


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_background.texture = _backdrop.get_texture()
	AudioManager.play_music("title")
	_menu_page.hide()
	_settings_window.hide()
	_lexicon_window.hide()
	_character_select.hide()
	_backdrop.entered.connect(_on_entered)
	if skip_title_page or Game.run != null:
		_title_page.hide()
		_door_hint.hide()
		_backdrop.skip()
	skip_title_page = false
	_language_select.visible = LanguageSelect.should_ask()
	if _language_select.visible:
		_title_page.hide()
		_door_hint.hide()
	_language_select.chosen.connect(_on_language_chosen)
	_settings_window.language_requested.connect(_show_language_select)
	%NewGameButton.pressed.connect(_choose.bind(%NewGameButton, _open_characters))
	%LexiconButton.pressed.connect(_choose.bind(%LexiconButton, _toggle_lexicon))
	%SettingsButton.pressed.connect(_choose.bind(%SettingsButton, _toggle_settings))
	%ExitButton.pressed.connect(_choose.bind(%ExitButton, get_tree().quit))
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
## goes straight to the anvil. Main menu: Escape closes the settings.
func _input(event: InputEvent) -> void:
	if _language_select.visible:
		return
	if _title_page.visible:
		if _is_any_key(event):
			get_viewport().set_input_as_handled()
			if _backdrop.stage == TitleBackdrop.Stage.DOOR:
				_step_in()
			else:
				_backdrop.skip()
	elif event.is_action_pressed("ui_cancel") and (_settings_window.visible or _lexicon_window.visible or _character_select.visible):
		_settings_window.hide()
		_lexicon_window.hide()
		_character_select.hide()
		get_viewport().set_input_as_handled()


func _is_any_key(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.is_pressed() and not event.is_echo()
	return false


func _show_language_select() -> void:
	_settings_window.hide()
	_language_select.show()


## A flag was clicked: save the language and start the menu again in it.
func _on_language_chosen(code: String) -> void:
	Language.set_current(code)
	skip_title_page = _menu_page.visible
	get_tree().reload_current_scene.call_deferred()


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


func _toggle_settings() -> void:
	if _settings_window.visible:
		_settings_window.hide()
	else:
		_lexicon_window.hide()
		_settings_window.open(true)


func _toggle_lexicon() -> void:
	if _lexicon_window.visible:
		_lexicon_window.hide()
		return
	_settings_window.hide()
	_lexicon_window.open()


## Neues Spiel: first the character.
func _open_characters() -> void:
	_settings_window.hide()
	_lexicon_window.hide()
	_character_select.open()
