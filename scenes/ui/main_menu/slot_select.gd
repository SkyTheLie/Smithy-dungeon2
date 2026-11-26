class_name SlotSelect
extends Control
## Save slot choice, once per program start after the language choice (MainMenu): three buttons
## A, B, C, each with its day and gold, or "Leer". A click uses that slot (MetaState.set_slot);
## the main menu then shows "Weiter" if the slot holds a game. The slot in use has the focus.
## Under every slot with a game a "Löschen" button: after a question the save is gone for good
## (MetaState.delete_slot). Built in code.

signal chosen(id: String)

const BUTTON_SIZE := Vector2(120, 64)
const DELETE_COLOR := Color(1.0, 0.55, 0.5)

## slot id -> its button / its delete button.
var _slot_buttons: Dictionary = {}
var _delete_buttons: Dictionary = {}
var _question: ConfirmationDialog
## The slot the question is about.
var _deleting: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.05, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HudPanel"
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var heading := Label.new()
	heading.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	heading.text = Language.translate("Spielstand wählen")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	heading.add_theme_constant_override("outline_size", 6)
	box.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for id: String in MetaState.SLOTS:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		row.add_child(column)
		var button := Button.new()
		button.name = "Slot_" + id
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.custom_minimum_size = BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(chosen.emit.bind(id))
		column.add_child(button)
		_slot_buttons[id] = button
		var delete := Button.new()
		delete.name = "Delete_" + id
		delete.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		delete.text = Language.translate("Löschen")
		delete.focus_mode = Control.FOCUS_NONE
		delete.add_theme_font_size_override("font_size", 11)
		delete.add_theme_color_override("font_color", DELETE_COLOR)
		delete.pressed.connect(_ask_delete.bind(id))
		column.add_child(delete)
		_delete_buttons[id] = delete
		if id == MetaState.slot():
			button.grab_focus.call_deferred()
	_question = ConfirmationDialog.new()
	_question.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_question.title = Language.translate("Löschen")
	_question.ok_button_text = Language.translate("Löschen")
	_question.cancel_button_text = Language.translate("Abbrechen")
	_question.confirmed.connect(_delete)
	add_child(_question)
	_refresh()


func _refresh() -> void:
	for id: String in _slot_buttons:
		(_slot_buttons[id] as Button).text = describe(id)
		# Kept in the layout (invisible), so the slots do not jump.
		(_delete_buttons[id] as Button).modulate.a = 1.0 if MetaState.has_save(id) else 0.0
		(_delete_buttons[id] as Button).disabled = not MetaState.has_save(id)


func _ask_delete(id: String) -> void:
	if not MetaState.has_save(id):
		return
	_deleting = id
	_question.dialog_text = Language.translate("Spielstand %s löschen? Das kann man nicht rückgängig machen.") % id.to_upper()
	_question.popup_centered()


func _delete() -> void:
	MetaState.delete_slot(_deleting)
	_deleting = ""
	_refresh()


func get_question() -> ConfirmationDialog:
	return _question


## "Spielstand A" and below "Tag 3 · 120 Gold" (or "Leer").
static func describe(id: String) -> String:
	var info: Dictionary = MetaState.peek(id)
	var line: String = Language.translate("Leer") if info.is_empty() \
			else Language.translate("Tag %d · %d Gold") % [int(info["day"]), int(info["gold"])]
	return Language.translate("Spielstand %s") % id.to_upper() + "\n" + line
