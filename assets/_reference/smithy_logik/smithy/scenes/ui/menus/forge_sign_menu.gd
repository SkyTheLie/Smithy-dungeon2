class_name ForgeSignMenu
extends StationMenu
## The name window of the forge sign (GameState.house.forge_sign, ForgeSign): opens right after
## the sign was hung up the first time (ForgeSignPlacer) and with E at the sign outside
## (ForgeSignWall). A name field, one button per theme (locked ones grey, why in the tooltip),
## a preview of the board, "Abnehmen" (the sign comes down, B in front of the house hangs it up
## again) and "Fertig".

@onready var _preview: ForgeSignBoard = %Preview
@onready var _name_edit: LineEdit = %NameEdit
@onready var _themes: GridContainer = %Themes
@onready var _status_label: Label = %StatusLabel

## Theme id per button in _themes (same order).
var _theme_ids: Array[String] = []


func _ready() -> void:
	super()
	var forge_sign: ForgeSign = GameState.house.forge_sign
	_name_edit.max_length = ForgeSign.max_length()
	_name_edit.placeholder_text = str(ForgeSign.data().get("default_name", ""))
	_name_edit.text_changed.connect(func(text: String) -> void: GameState.house.forge_sign.set_sign_name(text))
	_name_edit.text_submitted.connect(func(_text: String) -> void: _name_edit.release_focus())
	%RemoveButton.pressed.connect(_on_remove_pressed)
	%DoneButton.pressed.connect(close)
	for entry: Dictionary in ForgeSign.themes():
		var id: String = str(entry.get("id", ""))
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.text = str(entry.get("name", id))
		var path: String = str(entry.get("texture", ""))
		button.icon = load(path) if ResourceLoader.exists(path) else null
		button.pressed.connect(_on_theme_pressed.bind(id))
		_themes.add_child(button)
		_theme_ids.append(id)
	forge_sign.changed.connect(_queue_refresh)
	GameState.ranking.changed.connect(_queue_refresh)
	visibility_changed.connect(_on_visibility_changed)


## Opens the window. The name field gets the focus if `focus_name` (right after hanging the sign
## up) or the sign has no name yet.
func open(focus_name: bool = false) -> void:
	visible = true
	if focus_name or GameState.house.forge_sign.sign_name.is_empty():
		_name_edit.grab_focus.call_deferred()


func _on_visibility_changed() -> void:
	if visible:
		_status_label.text = Language.translate("Der Name steht außen auf dem Schild.")
		_refresh()
	else:
		_name_edit.release_focus()


func _refresh() -> void:
	_refresh_done()
	var forge_sign: ForgeSign = GameState.house.forge_sign
	# Not while typing: the saved name has no spaces at the end, the field may have them.
	if not _name_edit.has_focus() and _name_edit.text != forge_sign.sign_name:
		_name_edit.text = forge_sign.sign_name
	_preview.show_sign(forge_sign.get_display_name(), forge_sign.theme)
	for i in _theme_ids.size():
		var button := _themes.get_child(i) as Button
		var blocker: String = forge_sign.get_theme_blocker(_theme_ids[i])
		button.disabled = not blocker.is_empty()
		button.tooltip_text = blocker
		button.set_pressed_no_signal(_theme_ids[i] == forge_sign.theme)
	%RemoveButton.disabled = not forge_sign.attached


func _on_theme_pressed(id: String) -> void:
	if not GameState.house.forge_sign.set_theme(id):
		_status_label.text = GameState.house.forge_sign.get_theme_blocker(id)
	_refresh()


func _on_remove_pressed() -> void:
	GameState.house.forge_sign.remove()
	GameState.show_message(KeyBindings.fill(Language.translate("Das Schild ist abgenommen. Vor dem Haus {key_build} drücken, um es wieder aufzuhängen.")))
	close()
