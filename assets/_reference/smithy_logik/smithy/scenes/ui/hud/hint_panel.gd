class_name HintPanel
extends PanelContainer
## Tip window of the HUD ("Tipp: Steuerung ..."). Shows the tips the story queues
## (GameState.story.pending_hints) one after the other; "Verstanden" shows the next one.
## While a tip is shown, its "glow" targets glow golden (Guide.hint_targets).
## The text area grows with the text up to MAX_TEXT_HEIGHT; a longer text scrolls (wheel, drag).
## Text size: settings » Oberfläche » "Textgröße: Tipps" (TextSize "hints"), width and height grow with it.

## Highest the text area gets (base resolution 640x360, about 9 lines); more text scrolls.
const MAX_TEXT_HEIGHT: float = 100.0
## The tip window of the HUD (the X button of the touch controls finds it here).
const GROUP: StringName = &"hint_panel"

@onready var _title_label: Label = %HintTitle
@onready var _text_label: Label = %HintText
@onready var _text_scroll: ScrollContainer = %HintScroll


func _ready() -> void:
	add_to_group(GROUP)
	hide()
	# The panel is anchored at the top centre and grows to both sides by itself (no reset_size:
	# that would keep the left edge and push the panel to the right).
	TextSize.attach(self, "hints", [_text_label], _fit_text)
	%HintOkButton.pressed.connect(_show_next)
	# the wrapped height is known once the label has its width: fit the text area then
	_text_label.minimum_size_changed.connect(_fit_text)
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
	_text_scroll.scroll_vertical = 0
	_fit_text()
	show()


## The tip that is shown right now, null = none (X button of the touch controls).
static func shown_panel(tree: SceneTree) -> HintPanel:
	var panel := tree.get_first_node_in_group(GROUP) as HintPanel
	return panel if panel != null and panel.is_visible_in_tree() else null


## Like "Verstanden": the next queued tip, or the window closes.
func dismiss() -> void:
	_show_next()


## Text area as high as the wrapped text, at most MAX_TEXT_HEIGHT (then the rest scrolls).
func _fit_text() -> void:
	_text_scroll.custom_minimum_size.y = minf(_text_label.get_minimum_size().y, _max_text_height())


func _max_text_height() -> float:
	return TextSize.grown("hints", MAX_TEXT_HEIGHT, TextSize.MAX_HEIGHT)


## true if the text is longer than the text area (it scrolls).
func is_text_scrolling() -> bool:
	return _text_label.get_minimum_size().y > _text_scroll.custom_minimum_size.y + 0.5
