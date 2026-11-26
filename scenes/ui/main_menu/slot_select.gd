class_name SlotSelect
extends Control
## Save slot choice, once per program start after the language choice (MainMenu): three buttons
## A, B, C, each with its day and gold, or "Leer". A click uses that slot (MetaState.set_slot);
## the main menu then shows "Weiter" if the slot holds a game. The slot in use has the focus.
## Built in code.

signal chosen(id: String)

const BUTTON_SIZE := Vector2(120, 64)


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
		var button := Button.new()
		button.name = "Slot_" + id
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.text = describe(id)
		button.custom_minimum_size = BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(chosen.emit.bind(id))
		row.add_child(button)
		if id == MetaState.slot():
			button.grab_focus.call_deferred()


## "Spielstand A" and below "Tag 3 · 120 Gold" (or "Leer").
static func describe(id: String) -> String:
	var info: Dictionary = MetaState.peek(id)
	var line: String = Language.translate("Leer") if info.is_empty() \
			else Language.translate("Tag %d · %d Gold") % [int(info["day"]), int(info["gold"])]
	return Language.translate("Spielstand %s") % id.to_upper() + "\n" + line
