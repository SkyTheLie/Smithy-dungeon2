class_name QuestNpc
extends Station
## NPC that gives a quest. Talk to him with E (opens the QuestDialog).
## Above his head: "!" = has a quest for you, "?" = you carry what he wants.
## Name, look, greeting and quest are set per instance, so new quest givers need no code.

@export var npc_name: String = ""
## Figure in the world (48x48, feet at the bottom) and portrait in the dialog.
## Empty = a generated look (Appearance from the name, optionally with `race`).
@export var sprite: Texture2D
## Race of the generated look (id from appearance.json); empty = random. Only used without sprite.
@export var race: String = ""
## What he says when he has no quest (or no more).
@export_multiline var greeting: String = "":
	get:
		return Language.translate(greeting)
@export var quest: QuestData
## Further quests after `quest`, in this order: the next one is offered once the one before is
## done and its QuestData.required_flag is set (e.g. Holger's iron lumber axe).
@export var follow_up_quests: Array[QuestData] = []

var _portrait: Texture2D

@onready var _dialog: QuestDialog = $QuestDialog
@onready var _marker: Label = $Marker


func _ready() -> void:
	# Story: e.g. the woodcutter only waits at his hut after he asked for the axe on the market.
	if not GameState.story.has_flag(required_flag):
		queue_free()
		return
	_portrait = sprite
	if sprite and sprite.get_width() == CharacterBaker.FRAME * CharacterBaker.COLUMNS:
		# a resident's walk sheet (e.g. Holger): the standing frame and its portrait
		var sheet_figure: Sprite2D = $Sprite2D
		sheet_figure.texture = sprite
		sheet_figure.region_enabled = true
		sheet_figure.region_rect = CharacterBaker.get_frame_rect("down")
		_portrait = CharacterBaker.get_sheet_portrait(sprite)
	elif sprite:
		$Sprite2D.texture = sprite
	else:
		var look: Appearance = Appearance.from_seed(npc_name, race)
		var figure: Sprite2D = $Sprite2D
		figure.texture = CharacterBaker.get_sheet(look)
		figure.region_enabled = true
		figure.region_rect = CharacterBaker.get_frame_rect("down")
		_portrait = CharacterBaker.get_portrait(look)
	$NameLabel.text = npc_name
	_dialog.setup(npc_name, _portrait, greeting, get_current_quest())
	interacted.connect(_on_interacted)
	player_left.connect(_dialog.close)
	GameState.quests_changed.connect(_update_marker)
	GameState.inventory.changed.connect(_update_marker)
	_update_marker()


func _on_interacted() -> void:
	if not _dialog.visible:
		_dialog.setup(npc_name, _portrait, greeting, get_current_quest())
	_dialog.toggle()


## The quest the NPC talks about: the first one not done yet (a follow-up only once its
## required_flag is set), otherwise the last one done.
func get_current_quest() -> QuestData:
	var current: QuestData = quest
	for next in follow_up_quests:
		if current != null and GameState.get_quest_state(current) != QuestData.State.COMPLETED:
			break
		if next.required_flag.is_empty() or GameState.story.has_flag(next.required_flag):
			current = next
		else:
			break
	return current


func _update_marker() -> void:
	_marker.hide()
	var current: QuestData = get_current_quest()
	if current == null:
		return
	match GameState.get_quest_state(current):
		QuestData.State.AVAILABLE:
			_marker.text = "!"
			_marker.show()
		QuestData.State.ACTIVE:
			if GameState.can_complete_quest(current):
				_marker.text = "?"
				_marker.show()
