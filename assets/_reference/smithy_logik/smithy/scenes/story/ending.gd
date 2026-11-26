extends CanvasLayer
## The end of the story (story action "show_ending"): the screen goes dark and the pages of
## story.json "ending" follow one by one like the intro. E, Space, Enter or a click shows the next
## page. The page "{stats}" shows the player's numbers ("stats_title", "stats"). After the last
## page the "then" actions run (e.g. waking up in the own bed) and the screen lights up again over
## the new scene. Lives under the root, so it survives that scene change.

const FADE_TIME: float = 0.4
const DARKEN_TIME: float = 1.5
## Time for the new scene to load before the screen lights up again.
const WAKE_DELAY: float = 0.8
const STATS_PAGE: String = "{stats}"
## The ending's music (audio.json "music") while the pages are shown.
const MUSIC: String = "ending"

var _page: int = -1
var _pages: Array[String] = []
var _busy: bool = true

@onready var _background: ColorRect = %Background
@onready var _text: Label = %StoryText
@onready var _hint: Label = %ContinueHint


func _ready() -> void:
	AudioManager.set_music_override(MUSIC, MUSIC)
	var ending: Dictionary = GameState.story.get_data("ending")
	for page: String in ending.get("pages", []):
		_pages.append(_get_stats_text(ending) if page == STATS_PAGE else GameState.format_story_text(page))
	_text.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_background.color.a = 0.0
	await create_tween().tween_property(_background, "color:a", 1.0, DARKEN_TIME).finished
	_hint.modulate.a = 1.0
	_busy = false
	_next_page()


## While the end is shown nothing reaches the game (no walking, no menus).
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if pressed:
		_next_page()


func _next_page() -> void:
	if _busy:
		return
	_busy = true
	if _page >= 0:
		await create_tween().tween_property(_text, "modulate:a", 0.0, FADE_TIME).finished
	_page += 1
	if _page >= _pages.size():
		_finish()
		return
	_text.text = _pages[_page]
	_hint.text = KeyBindings.fill(Language.translate("Weiter: {key_interact} / Leertaste")) if _page < _pages.size() - 1 else KeyBindings.fill(Language.translate("Aufwachen: {key_interact} / Leertaste"))
	await create_tween().tween_property(_text, "modulate:a", 1.0, FADE_TIME).finished
	_busy = false


func _finish() -> void:
	_hint.visible = false
	AudioManager.set_music_override(MUSIC, "")
	GameState.run_story_action(str(GameState.story.get_data("ending").get("then", "")))
	await get_tree().create_timer(WAKE_DELAY).timeout
	await create_tween().tween_property(_background, "color:a", 0.0, DARKEN_TIME).finished
	queue_free()


func _exit_tree() -> void:
	AudioManager.set_music_override(MUSIC, "")


## "Die Geschichte von {name}" and one line per number, e.g. "Geschmiedet: 128".
func _get_stats_text(ending: Dictionary) -> String:
	var lines: Array[String] = [GameState.format_story_text(str(ending.get("stats_title", ""))), ""]
	for entry: Dictionary in ending.get("stats", []):
		lines.append(str(entry.get("text", "")).format({"value": _get_stat(str(entry.get("value", "")))}))
	return "\n".join(lines)


## "days", "gold", "heroes" or an achievement counter (e.g. "forge", "order", "dungeon").
static func _get_stat(value: String) -> int:
	match value:
		"days":
			return GameState.day_cycle.day
		"gold":
			return GameState.gold
		"heroes":
			return GameState.heroes.size()
	return GameState.achievements.get_value(value)
