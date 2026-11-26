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
	GameState.story.hint_added.connect(_on_hint_added)
	_show_next.call_deferred()
	# Leaving the scene (load, main menu) must not leave a button glowing.
	tree_exiting.connect(func() -> void: Guide.hint_targets = [])


func _on_hint_added() -> void:
	if not visible:
		_show_next()


func _show_next() -> void:
	var hint: Dictionary = GameState.story.take_pending_hint()
	Guide.hint_targets = hint.get("glow", [])
	if hint.is_empty():
		hide()
		return
	_title_label.text = hint.get("prefix", Language.translate("Tipp: ")) + GameState.format_story_text(hint.get("title", ""))
	_text_label.text = GameState.format_story_text(hint.get("text", ""))
	show()
