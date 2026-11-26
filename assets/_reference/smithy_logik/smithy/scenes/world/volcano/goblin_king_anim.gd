class_name GoblinKingAnim
extends Node
## Plays the lying goblin king's PixelLab animations on the Figure sprite of its parent StoryNpc:
## idle, now and then wiping his nose. While a dialogue box shows one of his lines he lies still and
## only his lips move (`lips`: mouth shapes picked at random, like syllables). Once crowned
## (`crowned_flag`) the crowned idle and lips, and while he talks the crown now and then slips aside
## and he pushes it back with his hand. On his sleep days (npcs.json "goblin_king.sleeps", see
## is_sleep_day) he only sleeps, with little "z"s rising. Sheets are strips of FRAME_SIZE frames, left
## to right (assets/_reference/goblin/throne_bed/pack.py).

@export var figure: Sprite2D
## Lines of this speaker make him talk.
@export var speaker_id: String = "goblin_king"
@export var crowned_flag: String = "goblin_king_crowned"
@export var idle: Texture2D
@export var wipe_nose: Texture2D
@export var lips: Texture2D
@export var idle_crowned: Texture2D
@export var lips_crowned: Texture2D
@export var crown_slip: Texture2D
@export var crown_push: Texture2D
@export var sleep: Texture2D
@export var fps: float = 8.0
## Seconds a mouth shape is held while talking, random in this range.
@export var syllable_time: Vector2 = Vector2(0.08, 0.17)
## Seconds between two nose wipes (idle, no crown) and two crown slips (talking, crowned), random.
@export var wipe_every: Vector2 = Vector2(5, 10)
@export var slip_every: Vector2 = Vector2(3, 6)

const FRAME_SIZE: Vector2i = Vector2i(160, 96)
## Where the "z"s rise from (figure coordinates, at his head) and how often.
const SNORE_FROM: Vector2 = Vector2(22, -16)
const SNORE_EVERY: float = 1.1
const SNORE_COLOR: Color = Color(0.85, 0.9, 1.0)

var _sheet: Texture2D
var _time: float = 0.0
## One-shot animations still to play before the loop goes on (e.g. crown_slip, crown_push).
var _queue: Array[Texture2D] = []
var _playing_once: bool = false
var _until_extra: float = 0.0
var _mouth: int = 0
var _until_syllable: float = 0.0
var _until_snore: float = 0.0


func _ready() -> void:
	_until_extra = randf_range(wipe_every.x, wipe_every.y)


## true on the days the goblin king sleeps and nobody may see him: npcs.json "goblin_king.sleeps"
## {"weekday": 2 (0 = Monday), "every_weeks": 2, "week": 0}: that weekday in every `every_weeks`-th
## week (counted from the first week of the game), starting with week `week`.
static func is_sleep_day(day: int) -> bool:
	var sleeps: NpcInfo.Sleeps = ContentDB.npc_info("goblin_king").sleeps
	if sleeps == null or GameCalendar.get_weekday(day) != sleeps.weekday:
		return false
	var week: int = floori(float(day - 1 + int(ContentDB.calendar_value("start_weekday", 0))) / GameCalendar.get_weekday_names().size())
	return posmod(week - sleeps.week, sleeps.every_weeks) == 0


## The sheet shown right now (for tests).
func get_sheet() -> Texture2D:
	return _sheet


func is_crowned() -> bool:
	return GameState.story.has_flag(crowned_flag)


func is_sleeping() -> bool:
	return sleep != null and is_sleep_day(GameState.day_cycle.day)


func is_talking() -> bool:
	for box in get_tree().get_nodes_in_group(DialogueBox.GROUP):
		if box.has_method("current_speaker") and box.current_speaker() == speaker_id:
			return true
	return false


func _loop_sheet(talking: bool) -> Texture2D:
	if is_sleeping():
		return sleep
	if is_crowned():
		return lips_crowned if talking else idle_crowned
	return lips if talking else idle


func _process(delta: float) -> void:
	if figure == null:
		return
	var talking: bool = is_talking() and not is_sleeping()
	if not _playing_once:
		_until_extra -= delta
		if _until_extra <= 0.0:
			_queue_extra(talking)
		if not _queue.is_empty():
			_start(_queue.pop_front(), true)
		elif _sheet != _loop_sheet(talking):
			_start(_loop_sheet(talking), false)
	if _sheet == sleep:
		_snore(delta)
	if _sheet == lips or _sheet == lips_crowned:
		_talk(delta)
		return
	_time += delta
	var count: int = _count(_sheet)
	var frame: int = int(_time * fps)
	if _playing_once and frame >= count:
		_playing_once = false
		if not _queue.is_empty():
			_start(_queue.pop_front(), true)
		else:
			_start(_loop_sheet(talking), false)
		frame = 0
	_show(frame % _count(_sheet))


## Lips only: a new mouth shape every few hundredths of a second, never the same twice.
func _talk(delta: float) -> void:
	_until_syllable -= delta
	if _until_syllable <= 0.0:
		_until_syllable = randf_range(syllable_time.x, syllable_time.y)
		var count: int = _count(_sheet)
		_mouth = (_mouth + 1 + randi() % maxi(1, count - 1)) % count
	_show(_mouth)


## Now and then: wiping his nose while idle (no crown, it would vanish in that animation), the crown
## slipping while he talks. Not while he sleeps.
func _queue_extra(talking: bool) -> void:
	if is_sleeping():
		_until_extra = randf_range(wipe_every.x, wipe_every.y)
	elif is_crowned():
		_until_extra = randf_range(slip_every.x, slip_every.y)
		if talking and crown_slip and crown_push:
			_queue = [crown_slip, crown_push]
	else:
		_until_extra = randf_range(wipe_every.x, wipe_every.y)
		if not talking and wipe_nose:
			_queue = [wipe_nose]


## A little "z" rises from his head and fades.
func _snore(delta: float) -> void:
	_until_snore -= delta
	if _until_snore > 0.0:
		return
	_until_snore = SNORE_EVERY
	var z := Label.new()
	z.text = "z" if randf() < 0.5 else "Z"
	z.add_theme_font_size_override("font_size", 11)
	z.add_theme_color_override("font_color", SNORE_COLOR)
	z.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2))
	z.add_theme_constant_override("outline_size", 3)
	z.position = figure.position + SNORE_FROM
	figure.get_parent().add_child(z)
	var tween := z.create_tween().set_parallel()
	tween.tween_property(z, "position", z.position + Vector2(randf_range(4, 10), -18), 1.8)
	tween.tween_property(z, "modulate:a", 0.0, 1.8).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(z.queue_free)


func _count(sheet: Texture2D) -> int:
	return maxi(1, floori(float(sheet.get_width()) / FRAME_SIZE.x))


func _start(sheet: Texture2D, once: bool) -> void:
	_sheet = sheet
	_playing_once = once
	_time = 0.0


func _show(frame: int) -> void:
	figure.texture = _sheet
	figure.region_enabled = true
	figure.region_rect = Rect2(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
