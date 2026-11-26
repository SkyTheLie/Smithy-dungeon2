extends Control
## Intro of a new game (after the character creator): the backstory from story.json "intro",
## one page at a time on a dark screen. E, Space, Enter or a click shows the next page (with a
## short fade); after the last page the game starts at story.json "start" (the village square).

const FADE_TIME: float = 0.4

var _page: int = -1
var _pages: Array = []
var _busy: bool = false

@onready var _text: Label = %StoryText
@onready var _hint: Label = %ContinueHint


func _ready() -> void:
	_pages = GameState.story.get_data("intro")
	_text.modulate.a = 0.0
	_next_page()


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if pressed:
		get_viewport().set_input_as_handled()
		_next_page()


func _next_page() -> void:
	if _busy:
		return
	_busy = true
	if _page >= 0:
		await create_tween().tween_property(_text, "modulate:a", 0.0, FADE_TIME).finished
	_page += 1
	if _page >= _pages.size():
		var start: Array = GameState.get_story_start()
		if start[2] != &"":
			GameState.next_auto_walk_point = start[1]
			GameState.travel_to(start[0], start[2])
		else:
			GameState.travel_to(start[0], start[1])
		return
	_text.text = GameState.format_story_text(_pages[_page])
	_hint.text = KeyBindings.fill(Language.translate("Weiter: {key_interact} / Leertaste")) if _page < _pages.size() - 1 else KeyBindings.fill(Language.translate("Los geht's: {key_interact} / Leertaste"))
	await create_tween().tween_property(_text, "modulate:a", 1.0, FADE_TIME).finished
	_busy = false
