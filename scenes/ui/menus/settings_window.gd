class_name SettingsWindow
extends PanelContainer
## Settings (main menu and pause menu): volume (all, music, effects), mouse sensitivity,
## full screen and, in the main menu only, the language choice. Values are saved at once in
## user://settings.cfg (AudioManager, Game, WindowLayout).

signal closed
## The "Sprache" button (the main menu shows the flags).
signal language_requested

@onready var _master: HSlider = %Master
@onready var _music: HSlider = %Music
@onready var _sounds: HSlider = %Sounds
@onready var _mouse: HSlider = %Mouse
@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _language: Button = %Language


func _ready() -> void:
	_master.value = AudioManager.get_volume(AudioManager.MASTER) * 100.0
	_music.value = AudioManager.get_volume(AudioManager.MUSIC) * 100.0
	_sounds.value = AudioManager.get_volume(AudioManager.SOUNDS) * 100.0
	_mouse.value = Game.get_mouse_sensitivity() * 100.0
	_fullscreen.button_pressed = Game.is_fullscreen()
	_master.value_changed.connect(func(v: float) -> void: AudioManager.set_volume(AudioManager.MASTER, v / 100.0))
	_music.value_changed.connect(func(v: float) -> void: AudioManager.set_volume(AudioManager.MUSIC, v / 100.0))
	_sounds.value_changed.connect(func(v: float) -> void:
		AudioManager.set_volume(AudioManager.SOUNDS, v / 100.0)
		AudioManager.set_volume(AudioManager.INTERFACE, v / 100.0))
	_mouse.value_changed.connect(func(v: float) -> void: Game.set_mouse_sensitivity(v / 100.0))
	_fullscreen.toggled.connect(Game.set_fullscreen)
	_language.pressed.connect(language_requested.emit)
	%Close.pressed.connect(close)


## `with_language`: show the language button (only where the menu can show the flags).
func open(with_language: bool) -> void:
	_language.visible = with_language
	show()


func close() -> void:
	hide()
	closed.emit()
