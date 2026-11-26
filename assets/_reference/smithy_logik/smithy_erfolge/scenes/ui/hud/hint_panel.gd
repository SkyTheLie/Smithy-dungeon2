class_name HintPanel
extends PanelContainer
## Tip window of the HUD ("Tipp: Steuerung ..."). Shows the tips the story queues
## (GameState.story.pending_hints) one after the other; "Verstanden" shows the next one.
## While a tip is shown, its "glow" targets glow golden (Guide.hint_targets).

@onready var _title_label: Label = %HintTitle
@onready var _text_label: Label = %HintText


func _ready() -> void:
	hide()
	%HintOkButton.pressed.connect(_show_next)
	# Deferred: a travel in the same action chain ("advance:...;travel_fade:...") comes after the
	# advance that queued the tip; it must mark the scene change first.
	GameState.story.hint_added.connect(_on_hint_added, CONNECT_DEFERRED)
	_on_hint_added.call_deferred()
	# Tips held back during a scene change (GameState.scene_changing) come now.
	get_tree().scene_changed.connect(_on_hint_added)
	# Leaving the scene (load, main menu) must not leave a button glowing.
	tree_exiting.connect(func() -> void: Guide.hint_targets = [])


func _on_hint_added() -> void:
	if not visible:
		_show_next()


func _show_next() -> void:
	# A scene change is under way (e.g. waking up in Kahn's hall, then outside in Eisquell): the
	# tip stays queued and the HUD of the new scene shows it.
	# (The old HUD hears scene_changed too, after it left the tree: it must not take the tip.)
	if GameState.scene_changing or not is_inside_tree():
		hide()
		return
	# A conversation is open (e.g. Hilde still talks after "Mieten" while the rent tip comes): the
	# tip waits until the box closes, it doesn't pop up behind it (playtest chapter 1, A3).
	if DialogueBox.is_any_open(get_tree()):
		hide()
		Guide.hint_targets = []
		for box: Node in get_tree().get_nodes_in_group(DialogueBox.GROUP):
			if not box.finished.is_connected(_on_hint_added):
				box.finished.connect(_on_hint_added, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
		return
	var hint: Dictionary = GameState.story.take_pending_hint()
	Guide.hint_targets = hint.get("glow", [])
	if hint.is_empty():
		hide()
		return
	_title_label.text = hint.get("prefix", Language.translate("Tipp: ")) + GameState.format_story_text(hint.get("title", ""))
	_text_label.text = GameState.format_story_text(hint.get("text", ""))
	show()
