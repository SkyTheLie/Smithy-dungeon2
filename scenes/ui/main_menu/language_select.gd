class_name LanguageSelect
extends Control
## Language choice (taken over from Smithy): one flag per language (Language.get_available(),
## pictures res://assets/ui/flags/<code>.png). Shown before the title page on the first start
## (no language chosen yet) and from the settings ("Sprache"). A click chooses the language; the
## main menu then saves it and starts again in it (MainMenu._on_language_chosen).
## The language the game would pick by itself has the focus, so Enter takes it at once.

signal chosen(code: String)

const FLAG_DIR: String = "res://assets/ui/flags/"
## German key of the heading; shown in every language at once ("Sprache · Language · …").
const HEADING_KEY: String = "Sprache"
const BUTTON_SIZE := Vector2(64, 54)

@onready var _heading: Label = %Heading
@onready var _flags: HBoxContainer = %Flags


## true if the main menu shows the choice by itself: nobody chose a language yet.
static func should_ask() -> bool:
	return not Language.has_choice()


func _ready() -> void:
	_heading.text = _heading_text()
	var suggested: Button = null
	for code: String in Language.get_available():
		var button := Button.new()
		button.name = code
		# the name of each language in that language, never translated
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.text = Language.get_language_name(code)
		var flag := load(FLAG_DIR + code + ".png") as Texture2D
		if flag:
			button.icon = flag
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = BUTTON_SIZE
		button.pressed.connect(chosen.emit.bind(code))
		_flags.add_child(button)
		if code == Language.get_current():
			suggested = button
	if suggested:
		suggested.grab_focus.call_deferred()


## "Sprache" in every language there is, each once.
func _heading_text() -> String:
	var words: Array[String] = []
	for code: String in Language.get_available():
		var word: String = HEADING_KEY
		var translation: Translation = TranslationServer.get_translation_object(code)
		if code != Language.BASE and translation:
			var message: String = String(translation.get_message(HEADING_KEY))
			if not message.is_empty():
				word = message
		if not words.has(word):
			words.append(word)
	return " · ".join(words)
