class_name ArrivalCutscene
extends Node2D
## Cut scene at the start of a new game (after the intro): out of black the player walks from the
## bottom of the village square up to its middle, the camera following him, with black bars at the
## top and bottom and the HUD hidden. There he turns to the camera and says the lines of story.json
## dialogue `dialogue` in a speech bubble above his head (E, Space, Enter or a click: the line at
## once / the next line; Esc skips the rest). Plays once, while the story is at `step` and
## `seen_flag` is not set; the flag is set at the end. Tips of the step wait until it is over
## (they are in the hidden HUD).
## Positions are scene coordinates of the map (the parent of this node).

@export var step: String = "find_smithy"
@export var seen_flag: String = "intro_arrival_seen"
@export var dialogue: String = "intro_arrival"
## Where the player appears (bottom of the map, above the south exit) and where he stops.
@export var from: Vector2 = Vector2(0, 334)
@export var to: Vector2 = Vector2(0, 100)
@export var hud: CanvasLayer

## Height of the black bars, and the seconds they and the black screen take to come / go.
const BAR_HEIGHT: float = 30.0
const BAR_TIME: float = 0.6
const FADE_IN_TIME: float = 1.2
## Seconds of standing still before he talks, and letters per second of a line.
const PAUSE_BEFORE_TALK: float = 0.4
const LETTERS_PER_SECOND: float = 40.0
## Speech bubble: width of the text, gap between head and bubble (screen pixels).
const BUBBLE_WIDTH: float = 170.0
const BUBBLE_HEAD_OFFSET: float = 40.0
const COLOR_BUBBLE: Color = Color(0.13, 0.075, 0.12, 0.88)
const COLOR_BUBBLE_BORDER: Color = Color(0.95, 0.8, 0.5)
const COLOR_TEXT: Color = Color(0.93, 0.87, 0.78)
const COLOR_HINT: Color = Color(0.7, 0.62, 0.55)
const CANVAS_LAYER: int = 50

var _player: Player
var _layer: CanvasLayer
var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _bubble: PanelContainer
var _text: Label
var _lines: Array = []
var _line: int = -1
var _talking: bool = false
var _typing: Tween
var _finished: bool = false
var _hud_process_mode: ProcessMode = PROCESS_MODE_INHERIT


func _ready() -> void:
	var story: Story = GameState.story
	if story.step != step or story.has_flag(seen_flag):
		return
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _player == null:
		return
	_lines = story.get_dialogue(dialogue).get("lines", [])
	_build_overlay()
	if hud:
		hud.hide()
		_hud_process_mode = hud.process_mode
		hud.process_mode = Node.PROCESS_MODE_DISABLED
	_player.global_position = _map().to_global(from)
	_play()


func _play() -> void:
	var curtain := ColorRect.new()
	curtain.color = Color.BLACK
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(curtain)
	_player.auto_walk(PackedVector2Array([_map().to_global(to)]), "down")
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 0.0, FADE_IN_TIME)
	tween.tween_callback(curtain.queue_free)
	await _player.auto_walk_finished
	if _finished:
		return
	# Standing still while he talks: the keys must not move him.
	_player.set_physics_process(false)
	await get_tree().create_timer(PAUSE_BEFORE_TALK, false).timeout
	if _finished:
		return
	_talking = true
	_next_line()


func _process(_delta: float) -> void:
	if _bubble and _bubble.visible and is_instance_valid(_player):
		var head: Vector2 = _player.get_global_transform_with_canvas().origin
		_bubble.position = (head - Vector2(_bubble.size.x / 2.0, BUBBLE_HEAD_OFFSET + _bubble.size.y)).round()


func _unhandled_input(event: InputEvent) -> void:
	if _finished or _layer == null:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_end()
		return
	var mouse := event as InputEventMouseButton
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or (mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not _talking:
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
	else:
		_next_line()


func _next_line() -> void:
	_line += 1
	if _line >= _lines.size():
		_end()
		return
	_text.text = GameState.format_story_text(str((_lines[_line] as Dictionary).get("text", "")))
	_text.visible_ratio = 0.0
	# The bubble gets its height for the new text before it is placed (_process).
	_bubble.reset_size()
	_bubble.show()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / LETTERS_PER_SECOND)


## Bars out, HUD back, the player can walk; remembered in the save.
func _end() -> void:
	if _finished:
		return
	_finished = true
	_talking = false
	GameState.story.set_flag(seen_flag)
	if is_instance_valid(_player):
		_player.set_physics_process(true)
	_bubble.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(_top_bar, "offset_bottom", 0.0, BAR_TIME)
	tween.tween_property(_bottom_bar, "offset_top", 0.0, BAR_TIME)
	await tween.finished
	if hud:
		hud.process_mode = _hud_process_mode
		hud.show()
	_layer.queue_free()
	_layer = null


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = CANVAS_LAYER
	add_child(_layer)
	_top_bar = _make_bar(Control.PRESET_TOP_WIDE)
	_bottom_bar = _make_bar(Control.PRESET_BOTTOM_WIDE)
	var tween := create_tween().set_parallel()
	tween.tween_property(_top_bar, "offset_bottom", BAR_HEIGHT, BAR_TIME)
	tween.tween_property(_bottom_bar, "offset_top", -BAR_HEIGHT, BAR_TIME)
	var hint := Label.new()
	hint.text = KeyBindings.fill(Language.translate("Weiter: {key_interact} / Leertaste    Überspringen: Esc"))
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", COLOR_HINT)
	_bottom_bar.add_child(hint)
	_bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BUBBLE
	style.border_color = COLOR_BUBBLE_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	_bubble.add_theme_stylebox_override("panel", style)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.hide()
	_text = Label.new()
	_text.custom_minimum_size.x = BUBBLE_WIDTH
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The bubble has its full size from the first letter on (no jumping lines while typing).
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_color", COLOR_TEXT)
	_bubble.add_child(_text)
	_layer.add_child(_bubble)


func _make_bar(preset: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.clip_contents = true
	bar.set_anchors_preset(preset)
	# Starts with no height; the tween pulls it into the screen.
	bar.offset_top = 0.0
	bar.offset_bottom = 0.0
	_layer.add_child(bar)
	return bar


func _map() -> Node2D:
	return get_parent() as Node2D
