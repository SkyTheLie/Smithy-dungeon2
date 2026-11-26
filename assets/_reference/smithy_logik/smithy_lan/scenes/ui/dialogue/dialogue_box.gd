class_name DialogueBox
extends StationMenu
## Shows a story dialogue (story.json "dialogues") line by line: portrait and name of the
## speaker ("player" = the player, "" = narrator/sign, else a story figure), the text, and
## "Weiter" (or E). A line can run a story action when it appears ("action", e.g. a cave-in
## during the conversation) and hold the buttons back for "wait" seconds (something happens in
## the scene meanwhile, e.g. the flying pumpkin at the spring festival). A line with "hide_for"
## (seconds) runs its action with the box out of sight first (the player stays frozen), e.g. the
## shadow torn out of Lake at the Altar of the Nine, and shows its text afterwards. After the last line: the choices (each can run a story action and then
## continue with another dialogue; "if_flag"/"unless_flag" hide it), or "Schließen" which runs the
## dialogue's "on_end" action. A line with "if_flag" / "unless_flag" is left out unless that flag is
## set / not set when the dialogue starts (e.g. Lake remembers that the player vouched for him).
## A choice that hands something in (take_items / hand_in_set) gets hand-in slots above the buttons
## (HandInSlots, the inventory opens): only what the player lays in there is handed in. Closing the
## box puts it back into the inventory.

signal finished

var _dialogue: Dictionary = {}
var _line: int = 0
## Speaker id -> [name, portrait] of the figure this box belongs to.
var _speakers: Dictionary = {}
## Slots for the choice that hands something in, and that choice (empty = none).
var _hand_in: HandInSlots
var _hand_in_choice: Dictionary = {}
## true while a line's "wait" runs (buttons and E do nothing).
var _waiting: bool = false

@onready var _panel: Control = $Panel
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _text_label: Label = %TextLabel
## Wraps into a second row when there are many choices (e.g. Lotte's talk menu).
@onready var _buttons: HFlowContainer = %Buttons


## All dialogue boxes of the scene.
const GROUP: StringName = &"dialogue_boxes"
## Gap between the box and the bottom edge of the screen (as laid out in dialogue_box.tscn).
const BOTTOM_GAP: float = 34.0
## Size of a figure's picture above its feet (world pixels; tall figures included), for
## _place_away_from_figures.
const FIGURE_HEIGHT: float = 50.0
const FIGURE_HALF_WIDTH: float = 14.0


## true while a dialogue box is open in the scene.
static func is_any_open(tree: SceneTree) -> bool:
	return tree.get_nodes_in_group(GROUP).any(func(box: Node) -> bool: return box.get("visible") == true)


## Speaker of the line shown right now ("" = box closed or narrator), e.g. for a figure's talk animation.
func current_speaker() -> String:
	var lines: Array = _dialogue.get("lines", [])
	if not visible or _line >= lines.size():
		return ""
	return lines[_line].get("speaker", "")


func _ready() -> void:
	super()
	closes_on_interact = false
	# The X of the title bar follows the same rule as Escape (can_be_cancelled).
	_title_bar.close_requested.disconnect(close)
	_title_bar.close_requested.connect(func() -> void:
		if can_be_cancelled():
			close())
	add_to_group(GROUP)
	_hand_in = HandInSlots.new()
	_buttons.add_sibling(_hand_in)
	_buttons.get_parent().move_child(_hand_in, _buttons.get_index())
	visibility_changed.connect(func() -> void:
		if not visible:
			_set_hand_in({})
			finished.emit())


func _exit_tree() -> void:
	# Scene change while the box is open: don't lose what lies in the slots.
	_hand_in.return_all()


## true while a dialogue box that holds the player in place is open (a conversation or a cutscene
## runs; no saving then, GameState.is_cutscene_running).
static func is_any_blocking(tree: SceneTree) -> bool:
	for node in tree.get_nodes_in_group(GROUP):
		var box := node as DialogueBox
		if box and box.visible and box.freezes_player:
			return true
	return false


## Escape closes a dialogue only if nothing gets lost by it. While a beat runs ("wait", "hide_for":
## something happens in the scene) or while the dialogue still has to run something (an "action" of
## a later line, "on_end", "then"), Escape does nothing: closing would skip those actions and leave
## the story half done. A dialogue with choices on its last line may be left (= no choice taken).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not can_be_cancelled():
		get_viewport().set_input_as_handled()
		return
	super(event)


func can_be_cancelled() -> bool:
	if _waiting:
		return false
	var lines: Array = _dialogue.get("lines", [])
	for index in range(_line + 1, lines.size()):
		if not str(lines[index].get("action", "")).is_empty():
			return false
	if _dialogue.get("choices", []).is_empty():
		return str(_dialogue.get("on_end", "")).is_empty() and str(_dialogue.get("then", "")).is_empty()
	return true


## Right click on an inventory item: into a hand-in slot.
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	return _hand_in.try_quick_move(inventory_index, amount)


## Starts a dialogue. `npc_id` / `npc_portrait` = the figure the player talks to.
func play(dialogue: Dictionary, npc_id: String = "", npc_portrait: Texture2D = null) -> void:
	dialogue = _with_shown_lines(dialogue)
	if dialogue.get("lines", []).is_empty():
		return
	_speakers[npc_id] = [GameState.story.get_npc_name(npc_id), npc_portrait]
	# The player stands still while someone talks, except in story steps with "move_in_dialogue"
	# (Oma Hilde follows the player around until the first rent is paid).
	freezes_player = not GameState.story.get_step().get("move_in_dialogue", false)
	_dialogue = dialogue
	_line = 0
	_title_bar.title = GameState.story.get_npc_name(npc_id) if npc_id != "" else Language.translate("Hinweis")
	_show_line()
	show()


## true while the open dialogue still has a line of `npc_id` from the current line on (the figure is
## still part of the conversation and stays).
func speaks_later(npc_id: String) -> bool:
	if not visible:
		return false
	var lines: Array = _dialogue.get("lines", [])
	for index in range(_line, lines.size()):
		if lines[index].get("speaker", "") == npc_id:
			return true
	return false


## Next line (button "Weiter" or E). After the last line without choices it closes.
func advance() -> void:
	if _waiting:
		return
	var lines: Array = _dialogue.get("lines", [])
	if _line < lines.size() - 1:
		_line += 1
		_show_line()
	elif _dialogue.get("choices", []).is_empty():
		if not _follow_then():
			_finish(_dialogue.get("on_end", ""))


## A dialogue with "then" (and no choices) goes on with that dialogue after its last line, e.g. the
## hammer thrown at the Lich » the player steps before the crystal. False if there is none.
func _follow_then() -> bool:
	var next: Dictionary = _with_shown_lines(GameState.story.get_dialogue(str(_dialogue.get("then", ""))))
	if next.get("lines", []).is_empty():
		return false
	GameState.run_story_action(_dialogue.get("on_end", ""))
	_dialogue = next
	_line = 0
	_show_line()
	return true


func _show_line() -> void:
	var lines: Array = _dialogue.get("lines", [])
	var entry: Dictionary = lines[_line]
	var hide_for: float = float(entry.get("hide_for", 0.0))
	if hide_for > 0.0:
		# the animation plays with the box out of sight, then the line tells what happened
		_waiting = true
		_panel.hide()
		GameState.run_story_action(entry.get("action", ""))
		var shown_dialogue: Dictionary = _dialogue
		var shown_line: int = _line
		await get_tree().create_timer(hide_for, false).timeout
		if shown_dialogue != _dialogue or shown_line != _line or not visible:
			_panel.show()
			return
		_panel.show()
	var speaker: String = entry.get("speaker", "")
	if speaker == "player":
		_name_label.text = GameState.get_player_name()
		_portrait.texture = CharacterBaker.get_portrait(GameState.player_appearance)
	elif _speakers.has(speaker):
		_name_label.text = _speakers[speaker][0]
		_portrait.texture = _speakers[speaker][1]
	elif speaker != "":
		# Another story figure takes part (e.g. Oma Hilde joins a customer's conversation).
		_name_label.text = GameState.story.get_npc_name(speaker)
		_portrait.texture = _find_portrait(speaker)
	else:
		_name_label.text = ""
		_portrait.texture = null
	_portrait.visible = _portrait.texture != null
	_text_label.text = Voice.apply(GameState.format_story_text(entry.get("text", "")), GameState.story.get_npc_voice(speaker))
	_build_buttons(_line == lines.size() - 1)
	_waiting = float(entry.get("wait", 0.0)) > 0.0
	if _waiting:
		_set_buttons_disabled(true)
		get_tree().create_timer(float(entry["wait"]), false).timeout.connect(_end_wait.bind(_dialogue, _line))
	if hide_for <= 0.0:
		GameState.run_story_action(entry.get("action", ""))
	_place_away_from_figures.call_deferred()


## The box stands at the bottom of the screen; when it would cover the player or a figure of the
## conversation it goes to the top (below the time compass) instead, whichever covers fewer of
## them. Checked with every line (the figures walk). A box the player pinned or dragged stays.
func _place_away_from_figures() -> void:
	await get_tree().process_frame  # the box gets its size for the new text first
	var bar := get_node_or_null("%TitleBar") as WindowTitleBar
	if not visible or not _panel.visible or bar == null or bar.is_pinned() or bar.moved_by_player:
		return
	var figures: Array[Rect2] = _figure_rects()
	var screen: Vector2 = _panel.get_viewport_rect().size
	var size: Vector2 = UiScale.get_visual_rect(_panel).size
	var bottom := Vector2(roundf((screen.x - size.x) / 2.0), screen.y - BOTTOM_GAP - size.y)
	var covered_bottom: int = _count_covered(Rect2(bottom, size), figures)
	if covered_bottom > 0:
		UiScale.set_visual_position(_panel, Vector2(bottom.x, 0.0))
		bar.keep_on_screen()  # below the time compass
		if _count_covered(UiScale.get_visual_rect(_panel), figures) < covered_bottom:
			return
	UiScale.set_visual_position(_panel, bottom)


func _count_covered(box: Rect2, figures: Array[Rect2]) -> int:
	return figures.filter(func(figure: Rect2) -> bool: return box.intersects(figure)).size()


## Where the player and the figures of this conversation are on screen (their whole picture).
func _figure_rects() -> Array[Rect2]:
	var ids: Dictionary = {}
	for line: Dictionary in _dialogue.get("lines", []):
		ids[str(line.get("speaker", ""))] = true
	ids.merge(_speakers)
	var nodes: Array[Node2D] = []
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player:
		nodes.append(player)
	for npc in get_tree().get_nodes_in_group(StoryNpc.GROUP):
		if npc is Node2D and ids.has(str(npc.get("npc_id"))) and (npc as Node2D).is_visible_in_tree() \
				and not npc.get("narrator"):
			nodes.append(npc)
	var rects: Array[Rect2] = []
	for node in nodes:
		var on_screen: Transform2D = node.get_global_transform_with_canvas()
		var top_left: Vector2 = on_screen * Vector2(-FIGURE_HALF_WIDTH, -FIGURE_HEIGHT)
		var bottom_right: Vector2 = on_screen * Vector2(FIGURE_HALF_WIDTH, 4.0)
		rects.append(Rect2(top_left, bottom_right - top_left).abs())
	return rects


## The "wait" of a line is over (if the box still shows that line).
func _end_wait(dialogue: Dictionary, line: int) -> void:
	if dialogue != _dialogue or line != _line:
		return
	_waiting = false
	_set_buttons_disabled(false)


func _set_buttons_disabled(disabled: bool) -> void:
	for button: Button in _buttons.get_children():
		button.disabled = disabled


## Portrait of a story figure in the current scene, null if it is not here.
func _find_portrait(npc_id: String) -> Texture2D:
	for node in get_tree().get_nodes_in_group(StoryNpc.GROUP):
		if node.npc_id == npc_id:
			return node.get_portrait()
	return null


func _build_buttons(last_line: bool) -> void:
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	var choices: Array = _dialogue.get("choices", [])
	var hand_in_choice: Dictionary = {}
	if last_line:
		for choice: Dictionary in choices:
			if _is_choice_available(choice) and not GameState.get_hand_in_requests(choice.get("action", "")).is_empty():
				hand_in_choice = choice
				break
	_set_hand_in(hand_in_choice)
	if not last_line:
		_add_button(Language.translate("Weiter"), advance)
	elif choices.is_empty():
		_add_button(Language.translate("Weiter" if _dialogue.has("then") else "Schließen"), advance)
	else:
		for choice: Dictionary in choices:
			if _is_choice_available(choice):
				_add_button(GameState.format_story_text(choice.get("text", "")), _on_choice.bind(choice))


## A choice with "if_flag" only shows while that story flag is set, one with "unless_flag" only
## while it is not (e.g. the builder offers the greenhouse until it is built).
func _is_choice_available(choice: Dictionary) -> bool:
	var story: Story = GameState.story
	var unless_flag: String = choice.get("unless_flag", "")
	return story.has_flag(choice.get("if_flag", "")) and (unless_flag.is_empty() or not story.has_flag(unless_flag))


## A copy of the dialogue without the lines whose "if_flag" / "unless_flag" rule them out now.
func _with_shown_lines(dialogue: Dictionary) -> Dictionary:
	var result: Dictionary = dialogue.duplicate()
	result["lines"] = dialogue.get("lines", []).filter(_is_choice_available)
	return result


## Shows the hand-in slots for `choice` (empty = hides them, items go back).
func _set_hand_in(choice: Dictionary) -> void:
	if choice == _hand_in_choice and not choice.is_empty():
		return
	var had_hand_in: bool = not _hand_in_choice.is_empty()
	_hand_in_choice = choice
	var requests: Array[Dictionary] = []
	if not choice.is_empty():
		requests = GameState.get_hand_in_requests(choice.get("action", ""))
	_hand_in.setup(requests)
	if not choice.is_empty():
		Events.inventory_open_requested.emit()
	elif had_hand_in:
		# The hand-in is over: the inventory it opened closes again (unless the player had it open
		# already or pinned it), so it doesn't cover what happens next (e.g. the rod in the temple).
		Events.inventory_close_requested.emit()


func _on_choice(choice: Dictionary) -> void:
	var action: String = choice.get("action", "")
	var success: bool
	if not _hand_in_choice.is_empty() and choice == _hand_in_choice:
		success = GameState.run_with_hand_in(_hand_in.get_stacks(), GameState.run_story_action.bind(action))
		_hand_in.return_all()
		_set_hand_in({})
	else:
		success = GameState.run_story_action(action)
	var next_id: String = choice.get("then", "") if success else choice.get("else", "")
	var next: Dictionary = _with_shown_lines(GameState.story.get_dialogue(next_id))
	if next.get("lines", []).is_empty():
		hide()
		return
	_dialogue = next
	_line = 0
	_show_line()


func _finish(action: String) -> void:
	hide()
	GameState.run_story_action(action)


func _add_button(text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	_buttons.add_child(button)
