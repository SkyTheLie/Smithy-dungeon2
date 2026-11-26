class_name CharacterSelect
extends PanelContainer
## "Neues Spiel": pick a character (data/characters.json). Locked ones are dark and say what
## unlocks them (Progress, same conditions as items). Choosing one starts the run.

signal closed

@onready var _cards: HBoxContainer = %Cards


func _ready() -> void:
	%Close.pressed.connect(close)


func open() -> void:
	for child: Node in _cards.get_children():
		child.queue_free()
	for id: String in Content.characters():
		_cards.add_child(_card(id))
	show()


func close() -> void:
	hide()
	closed.emit()


## One card: picture, name, what it does, and a button (or the unlock condition).
func _card(id: String) -> Control:
	var data: Dictionary = Content.characters()[id]
	var open_to_play: bool = Progress.meets(data.get("unlock", {}))
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(130, 0)
	box.add_theme_constant_override("separation", 4)
	var icon := TextureRect.new()
	icon.texture = load(String(data.get("icon", ""))) as Texture2D
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if open_to_play else Color(0.15, 0.1, 0.1)
	box.add_child(icon)
	box.add_child(_label(Language.translate(String(data.get("name", id))), 18, Color(1, 0.86, 0.55)))
	var text: String = Language.translate(String(data.get("desc", "")))
	if not open_to_play:
		text = Language.translate("Gesperrt") + "\n" + LexiconWindow.unlock_text(data.get("unlock", {}))
	box.add_child(_label(text, 12, Color(0.9, 0.85, 0.8)))
	var button := Button.new()
	button.text = Language.translate("Wählen")
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not open_to_play
	button.pressed.connect(func() -> void: Game.start_new_run(id))
	box.add_child(button)
	return box


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(130, 0)
	return label
