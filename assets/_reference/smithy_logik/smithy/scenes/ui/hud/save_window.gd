class_name SaveWindow
extends PanelContainer
## Save / load window (side menu). One row per slot with what is in it
## ("Mi, 3. Frühling · Lv 4 · 250 Gold · Schmiede" and the date).
## Both modes list slot 0 (autosave, written when the player sleeps) and slots 1-3.
## Save mode: slots 1-3 can be saved, saving over a used slot needs a second click
## ("Überschreiben?"); slot 0 can't be saved by hand, only loaded.
## Load mode: all slots, "Löschen" (not for slot 0) also needs a second click.

enum Mode { SAVE, LOAD }

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_EMPTY: Color = Color(0.45, 0.42, 0.42)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

var _mode: Mode = Mode.SAVE
## Slot whose button was clicked once and waits for the confirming second click (-1 = none).
var _confirm_slot: int = -1
## What the second click confirms ("save" or "delete").
var _confirm_action: String = ""

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	visibility_changed.connect(func() -> void: _status_label.text = "")


func get_mode() -> Mode:
	return _mode


func open(mode: Mode) -> void:
	_mode = mode
	_title_bar.title = Language.translate("Speichern") if mode == Mode.SAVE else Language.translate("Laden")
	_status_label.text = ""
	_reset_confirm()
	show()


func _reset_confirm() -> void:
	_confirm_slot = -1
	_confirm_action = ""
	_rebuild()


func _rebuild() -> void:
	for child in _slot_list.get_children():
		_slot_list.remove_child(child)
		child.queue_free()
	for slot in SaveSystem.get_all_slots():
		_slot_list.add_child(_create_row(slot))


func _create_row(slot: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(_create_label(SaveSystem.get_slot_name(slot)))
	var summary: String = SaveSystem.get_summary(slot)
	if summary.is_empty():
		texts.add_child(_create_label("– leer –", COLOR_EMPTY))
	else:
		texts.add_child(_create_label(summary, COLOR_HINT))
		texts.add_child(_create_label(SaveSystem.get_saved_at_text(slot), COLOR_HINT))
	row.add_child(texts)
	var used: bool = not summary.is_empty()
	if slot in [SaveSystem.AUTOSAVE_SLOT, SaveSystem.QUICKSAVE_SLOT] and _mode == Mode.SAVE:
		# The autosave is only written when sleeping, the quicksave with F5; here they can only be loaded.
		var load_button := _create_button(Language.translate("Laden"), _on_load_pressed.bind(slot))
		load_button.disabled = not used
		load_button.tooltip_text = Language.translate("Wird beim Schlafen automatisch gespeichert und kann nicht überschrieben werden.") 				if slot == SaveSystem.AUTOSAVE_SLOT else Language.translate("F5 speichert hierhin, F7 lädt.")
		row.add_child(load_button)
	elif _mode == Mode.SAVE:
		var waiting: bool = _confirm_slot == slot and _confirm_action == "save"
		row.add_child(_create_button(Language.translate("Überschreiben?") if waiting else Language.translate("Speichern"), _on_save_pressed.bind(slot)))
	else:
		var load_button := _create_button(Language.translate("Laden"), _on_load_pressed.bind(slot))
		load_button.disabled = not used
		row.add_child(load_button)
		if slot != SaveSystem.AUTOSAVE_SLOT:
			var waiting: bool = _confirm_slot == slot and _confirm_action == "delete"
			var delete_button := _create_button(Language.translate("Sicher?") if waiting else Language.translate("Löschen"), _on_delete_pressed.bind(slot))
			delete_button.disabled = not used
			row.add_child(delete_button)
	return row


func _on_save_pressed(slot: int) -> void:
	var needs_confirm: bool = SaveSystem.exists(slot) and not (_confirm_slot == slot and _confirm_action == "save")
	if needs_confirm:
		_confirm_slot = slot
		_confirm_action = "save"
		_rebuild.call_deferred()
		return
	if GameState.save_game(slot):
		_status_label.text = Language.translate("%s gespeichert.") % SaveSystem.get_slot_name(slot)
		_status_label.remove_theme_color_override("font_color")
	else:
		_status_label.text = Language.translate("Speichern fehlgeschlagen.")
		_status_label.add_theme_color_override("font_color", COLOR_ERROR)
	_confirm_slot = -1
	_rebuild.call_deferred()


func _on_load_pressed(slot: int) -> void:
	if not GameState.load_game(slot):
		_status_label.text = Language.translate("Dieser Spielstand kann nicht geladen werden.")
		_status_label.add_theme_color_override("font_color", COLOR_ERROR)


func _on_delete_pressed(slot: int) -> void:
	if not (_confirm_slot == slot and _confirm_action == "delete"):
		_confirm_slot = slot
		_confirm_action = "delete"
		_rebuild.call_deferred()
		return
	SaveSystem.delete(slot)
	_status_label.text = Language.translate("%s gelöscht.") % SaveSystem.get_slot_name(slot)
	_status_label.remove_theme_color_override("font_color")
	_confirm_slot = -1
	_rebuild.call_deferred()


func _create_label(text: String, color: Color = Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = text
	if color != Color.TRANSPARENT:
		label.add_theme_color_override("font_color", color)
	return label


func _create_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(on_pressed)
	return button
