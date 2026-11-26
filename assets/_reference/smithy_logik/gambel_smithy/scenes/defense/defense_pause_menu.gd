class_name DefensePauseMenu
extends Control
## Esc in the forge defense: the game pauses (SceneTree.paused; this menu runs anyway,
## PROCESS_MODE_ALWAYS) and shows "Weiterspielen", "Einstellungen" (the same SettingsPanel as in the
## main menu), "Run aufgeben" (only during a run: the run is lost at once), "Zum Hauptmenü" and
## "Spiel beenden". Esc again closes the settings, then the menu. The game listens to `closed`
## (mouse pointer back to the hammer), `give_up_requested` and `main_menu_requested`.

signal closed
signal main_menu_requested
signal give_up_requested

@onready var _menu: Control = %Menu
@onready var _settings: Control = %SettingsWindow
@onready var _continue: Button = %ContinueButton


func _ready() -> void:
	hide()
	_settings.hide()
	_continue.pressed.connect(close)
	%SettingsButton.pressed.connect(_open_settings)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%GiveUpButton.pressed.connect(_on_give_up_pressed)
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())
	(%SettingsTitleBar as WindowTitleBar).close_requested.connect(_settings.hide)
	%SettingsTitleBar.add_sibling(SettingsPanel.new())


func is_open() -> bool:
	return visible


## Pauses the game and shows the menu with the mouse pointer. `in_run`: "Run aufgeben" shows.
func open(in_run: bool = false) -> void:
	%GiveUpButton.visible = in_run
	show()
	_menu.show()
	_settings.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_continue.grab_focus()


## Back to the game (it runs again).
func close() -> void:
	if not visible:
		return
	hide()
	_settings.hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _settings.visible:
		_settings.hide()
		_continue.grab_focus()
	else:
		close()


func _open_settings() -> void:
	_settings.show()


func _on_give_up_pressed() -> void:
	close()
	give_up_requested.emit()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	main_menu_requested.emit()
