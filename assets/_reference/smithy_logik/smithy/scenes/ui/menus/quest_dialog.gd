class_name QuestDialog
extends StationMenu
## Dialog with a quest giver (QuestNpc). The text and buttons depend on the quest state:
## offered ("Annehmen" / "Später"), running (reminder, or "Ist das ... meine X?" when the player
## has it), done (thank-you text). While it runs there is always a hand-in slot (HandInSlots, the
## inventory opens): the player lays the item in, "Abgeben" hands it in. Closing puts it back.
## Hidden rewards are revealed after handing in.

const COLOR_REWARD: Color = Color(0.55, 0.85, 0.45)

var _quest: QuestData
## What the NPC says when he has no (more) quest.
var _greeting: String = ""

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _text_label: Label = %TextLabel
@onready var _message_label: Label = %MessageLabel
@onready var _accept_button: Button = %AcceptButton
@onready var _turn_in_button: Button = %TurnInButton
@onready var _bye_button: Button = %ByeButton

var _hand_in: HandInSlots


func _ready() -> void:
	super()
	_accept_button.pressed.connect(_on_accept_pressed)
	_turn_in_button.pressed.connect(_on_turn_in_pressed)
	_bye_button.pressed.connect(close)
	_hand_in = HandInSlots.new()
	var buttons: Control = _accept_button.get_parent()
	buttons.add_sibling(_hand_in)
	buttons.get_parent().move_child(_hand_in, buttons.get_index())
	_hand_in.changed.connect(_update_turn_in_button)
	visibility_changed.connect(_on_visibility_changed)
	GameState.quest_completed.connect(_on_quest_completed)


func setup(npc_name: String, portrait: Texture2D, greeting: String, quest: QuestData) -> void:
	_title_bar.title = npc_name
	_name_label.text = npc_name
	_portrait.texture = portrait
	_greeting = greeting
	_quest = quest


func _on_visibility_changed() -> void:
	if visible:
		_message_label.text = ""
		_refresh()
	else:
		_hand_in.setup(_no_requests())


func _exit_tree() -> void:
	_hand_in.return_all()


## Right click on an inventory item: into the hand-in slot.
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	return _hand_in.try_quick_move(inventory_index, amount)


func _refresh() -> void:
	_accept_button.hide()
	_turn_in_button.hide()
	var active: bool = _quest != null and GameState.get_quest_state(_quest) == QuestData.State.ACTIVE
	if not active:
		_hand_in.setup(_no_requests())
	_bye_button.text = Language.translate("Tschüss")
	if _quest == null:
		_text_label.text = _greeting
		return
	match GameState.get_quest_state(_quest):
		QuestData.State.AVAILABLE:
			_text_label.text = _quest.offer_text
			_accept_button.show()
			_bye_button.text = Language.translate("Später")
		QuestData.State.ACTIVE:
			var has_item: bool = GameState.can_complete_quest(_quest) or _hand_in.is_complete()
			_text_label.text = Language.translate("Ist das ... meine %s?") % _quest.requirement_name if has_item else _quest.reminder_text
			if not _hand_in.visible:
				_hand_in.setup(GameState.get_quest_hand_in(_quest))
				Events.inventory_open_requested.emit()
			_turn_in_button.text = Language.translate("%s abgeben") % _quest.requirement_name
			_turn_in_button.show()
			_update_turn_in_button()
		QuestData.State.COMPLETED:
			_text_label.text = _quest.after_text


func _on_accept_pressed() -> void:
	GameState.accept_quest(_quest)
	_message_label.text = Language.translate("Auftrag angenommen – steht im Auftragsbuch.")
	_message_label.remove_theme_color_override("font_color")
	_refresh()


func _on_turn_in_pressed() -> void:
	if not _hand_in.is_complete():
		return
	var quest: QuestData = _quest
	GameState.run_with_hand_in(_hand_in.get_stacks(), func() -> bool: return GameState.complete_quest(quest))
	_hand_in.return_all()


func _update_turn_in_button() -> void:
	_turn_in_button.disabled = not _hand_in.is_complete()
	var wanted: String = _quest.requirement_name if _quest else ""
	_turn_in_button.tooltip_text = Language.translate("Lege %s in den Slot.") % wanted if _turn_in_button.disabled else ""


func _no_requests() -> Array[Dictionary]:
	return []


func _on_quest_completed(quest: QuestData, rewards_text: String) -> void:
	if quest != _quest:
		return
	_refresh()
	_text_label.text = _quest.done_text
	_message_label.text = Language.translate("Belohnung: %s") % rewards_text
	_message_label.add_theme_color_override("font_color", COLOR_REWARD)
