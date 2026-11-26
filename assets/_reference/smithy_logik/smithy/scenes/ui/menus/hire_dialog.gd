class_name HireDialog
extends StationMenu
## Small dialog with a hireable NPC: portrait, name, class, what he says, and the buttons
## "Anheuern (X Gold)" and "Tschüss". Emits `hired` after a successful hire.

signal hired

const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

var _hero: Hero

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _class_label: Label = %ClassLabel
@onready var _text_label: Label = %TextLabel
@onready var _message_label: Label = %MessageLabel
@onready var _hire_button: Button = %HireButton


func _ready() -> void:
	super()
	_hire_button.pressed.connect(_on_hire_pressed)
	%ByeButton.pressed.connect(close)
	visibility_changed.connect(func() -> void: _message_label.text = "")


func setup(hero: Hero, greeting: String) -> void:
	_hero = hero
	_title_bar.title = hero.display_name
	_portrait.texture = hero.get_portrait()
	_name_label.text = hero.display_name
	_class_label.text = Language.translate("%s · Lv %d") % [hero.hero_class.display_name, hero.level]
	_class_label.add_theme_color_override("font_color", hero.hero_class.color)
	_text_label.text = "%s\n\n%s" % [greeting, hero.get_race_line()]
	_hire_button.text = Language.translate("Anheuern (%d Gold)") % hero.hire_cost


func _on_hire_pressed() -> void:
	var blocker: String = GameState.get_hire_blocker(_hero)
	if GameState.hire_hero(_hero):
		close()
		hired.emit()
	else:
		_message_label.text = blocker
		_message_label.add_theme_color_override("font_color", COLOR_ERROR)
