class_name QuestWindow
extends PanelContainer
## Egon's quests in the shop (button "Quests", or a click on the quest place): every quest of
## data/quests.json whose dungeon is open, with the stone it wants, what to do and whether it is
## done. "Abgeben" hands in a stone lying in the stash (signal deliver_requested; the shop plays
## Egon's scene). Esc / "Schließen". The rules are in Quests / MetaState.

signal deliver_requested(index: int)

const COLOR_TITLE := Color(1, 0.86, 0.55)
const COLOR_DONE := Color(0.45, 0.9, 0.45)
const COLOR_OPEN := Color(1.0, 0.86, 0.35)

var _list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme_type_variation = &"HudPanel"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Quests")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	column.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.custom_minimum_size = Vector2(380, 0)
	column.add_child(_list)
	var hint := Label.new()
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.text = Language.translate("Den Stein aus dem Lager auf den Quest-Platz oben rechts ziehen oder hier abgeben.")
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.7, 0.65, 0.6)
	column.add_child(hint)
	var close_button := Button.new()
	close_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	close_button.text = Language.translate("Schließen")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(hide)
	column.add_child(close_button)


func open() -> void:
	refresh()
	show()


## The quests whose dungeon is open (open ones and done ones), newest first.
func refresh() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var shown: Array[String] = []
	for id: String in Quests.all():
		if MetaState.quest_done(id) or Quests.open_quests().has(id):
			shown.append(id)
	shown.reverse()
	for id: String in shown:
		_list.add_child(_row(id))
	if shown.is_empty():
		var none := Label.new()
		none.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		none.text = Language.translate("Egon hat gerade keinen Auftrag.")
		none.add_theme_font_size_override("font_size", 11)
		_list.add_child(none)


func _row(id: String) -> Control:
	var data: Dictionary = Quests.data(id)
	var stone: String = String(data.get("item", ""))
	var done: bool = MetaState.quest_done(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var place := ShopSlot.new()
	place.show_entry({"id": stone, "count": 1})
	place.modulate.a = 0.5 if done else 1.0
	row.add_child(place)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label := Label.new()
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	name_label.text = Language.translate(String(data.get("name", id)))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", COLOR_DONE if done else COLOR_OPEN)
	text.add_child(name_label)
	var desc := Label.new()
	desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	desc.text = Language.translate(String(data.get("desc", "")))
	desc.add_theme_font_size_override("font_size", 9)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(250, 0)
	text.add_child(desc)
	var status := Label.new()
	status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	status.add_theme_font_size_override("font_size", 9)
	text.add_child(status)
	var index: int = _stone_index(stone)
	if done:
		status.text = Language.translate("Erledigt")
		status.modulate = COLOR_DONE
	elif index >= 0:
		status.text = Language.translate("Der Stein liegt in deinem Lager!")
		status.modulate = COLOR_OPEN
		var give := Button.new()
		give.name = "Deliver_" + id
		give.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		give.text = Language.translate("Abgeben")
		give.focus_mode = Control.FOCUS_NONE
		give.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		give.pressed.connect(func() -> void: deliver_requested.emit(index))
		row.add_child(give)
	else:
		status.text = Language.translate("Belohnung: der nächste Dungeon und %d Gold") % int(data.get("gold", 0))
		status.modulate = Color(0.75, 0.7, 0.65)
	return row


static func _stone_index(stone: String) -> int:
	var own: Array[Dictionary] = MetaState.stash()
	for i in own.size():
		if String(own[i].get("id", "")) == stone:
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()
