class_name StirringMinigame
extends PanelContainer
## Mortar minigame (stirring a potion, see Enchanting): the pestle circles around the bowl, a
## green arc lies somewhere on the rim. A left click while the pestle is inside the arc is a hit
## (in the middle of it: a clean hit). After every click the arc jumps to another place, the pestle
## turns round and gets faster. If the pestle runs around the bowl twice without a click, the round
## is lost. ROUNDS rounds; the points (clean hit 2, hit 1) give the grade (Enchanting.Stir):
## PERFECT_POINTS or more = perfect (+1 rarity tier), GOOD_POINTS or more = good, less = lumpy (-1).

signal finished(grade: Enchanting.Stir)
## The X of the title bar was clicked (the window closes, the ingredients stay in the mortar).
signal close_requested

enum Phase { READY, RUN, RESULT }

const ROUNDS: int = 4
const PERFECT_POINTS: int = 6
const GOOD_POINTS: int = 3
## Start speed of the pestle (degrees per second), factor per round, size of the arc (degrees)
## and the share of it that counts as a clean hit.
const START_SPEED: float = 160.0
const SPEED_FACTOR: float = 1.18
const ZONE_DEGREES: float = 54.0
const CLEAN_SHARE: float = 0.35
## The new arc is at least this far (degrees) from the pestle.
const MIN_JUMP: float = 100.0
const READY_SECONDS: float = 0.8
const RESULT_SECONDS: float = 1.3
const CENTER: Vector2 = Vector2(74, 70)
const RADIUS: float = 52.0
const COLOR_BOWL: Color = Color(0.36, 0.3, 0.27)
const COLOR_RIM: Color = Color(0.58, 0.52, 0.46)
const COLOR_ZONE: Color = Color(0.3, 0.62, 0.3)
const COLOR_CLEAN: Color = Color(0.45, 0.9, 0.4)
const COLOR_PESTLE: Color = Color(0.95, 0.92, 0.85)
const COLOR_OUTLINE: Color = Color(0.13, 0.08, 0.12)
const COLOR_GOOD: Color = Color(0.55, 0.85, 0.45)
const COLOR_BAD: Color = Color(0.9, 0.4, 0.35)

var _running: bool = false
var _phase: Phase = Phase.READY
var _time: float = 0.0
var _round: int = 0
var _points: int = 0
## Pestle angle (degrees), its speed (negative = counter-clockwise) and how far it ran this round.
var _angle: float = 0.0
var _speed: float = START_SPEED
var _travelled: float = 0.0
## Centre of the green arc (degrees).
var _zone: float = 0.0
var _liquid: Color = Color(0.6, 0.45, 0.85)
## Marks of the clicks so far: [angle, points] (shown on the rim).
var _marks: Array = []

@onready var _info_label: Label = %InfoLabel
@onready var _field: Control = %Field
@onready var _feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	%TitleBar.close_requested.connect(close_requested.emit)
	_field.draw.connect(_draw_field)


## Starts stirring `what` (e.g. "Feuertrank"); `liquid` = colour of the potion in the bowl.
func start(what: String, liquid: Color = Color(0.6, 0.45, 0.85)) -> void:
	_info_label.text = Language.translate("%s rühren") % what
	_feedback_label.text = Language.translate("Bereit ...")
	_feedback_label.remove_theme_color_override("font_color")
	_liquid = liquid
	_round = 0
	_points = 0
	_marks.clear()
	_angle = randf() * 360.0
	_speed = START_SPEED
	_travelled = 0.0
	_place_zone()
	_phase = Phase.READY
	_time = 0.0
	_running = true
	show()
	_field.queue_redraw()


## Aborts the game without result.
func stop() -> void:
	_running = false
	hide()


func is_running() -> bool:
	return _running


## The grade of `points` (Enchanting.Stir).
static func grade_of(points: int) -> Enchanting.Stir:
	if points >= PERFECT_POINTS:
		return Enchanting.Stir.PERFECT
	return Enchanting.Stir.GOOD if points >= GOOD_POINTS else Enchanting.Stir.BAD


## Points of a click at `angle` with the arc at `zone`: 2 = clean, 1 = hit, 0 = miss.
static func points_at(angle: float, zone: float) -> int:
	var off: float = absf(angle_difference(deg_to_rad(angle), deg_to_rad(zone)))
	var half: float = deg_to_rad(ZONE_DEGREES / 2.0)
	if off <= half * CLEAN_SHARE:
		return 2
	return 1 if off <= half else 0


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	match _phase:
		Phase.READY:
			if _time >= READY_SECONDS:
				_phase = Phase.RUN
				_feedback_label.text = Language.translate("Klick, wenn der Stößel im Grünen ist (%d/%d)") % [_round + 1, ROUNDS]
		Phase.RUN:
			var step: float = _speed * delta
			_angle = fposmod(_angle + step, 360.0)
			_travelled += absf(step)
			if _travelled >= 720.0:
				_score(0)
		Phase.RESULT:
			if _time >= RESULT_SECONDS:
				_running = false
				finished.emit(grade_of(_points))
	_field.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (_running and mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if _phase == Phase.RUN:
		_score(points_at(_angle, _zone))


## Ends the round with `points`; the next arc, a faster pestle the other way round, or the result.
func _score(points: int) -> void:
	_points += points
	_marks.append([_angle, points])
	_round += 1
	if _round >= ROUNDS:
		_show_result()
		return
	_speed = -_speed * SPEED_FACTOR
	_travelled = 0.0
	_place_zone()
	var text: String = [Language.translate("Daneben!"), Language.translate("Getroffen!"), Language.translate("Sauber!")][points]
	_feedback_label.text = Language.translate("%s Weiter (%d/%d)") % [text, _round + 1, ROUNDS]


func _place_zone() -> void:
	_zone = fposmod(_angle + randf_range(MIN_JUMP, 360.0 - MIN_JUMP), 360.0)


func _show_result() -> void:
	_phase = Phase.RESULT
	_time = 0.0
	var grade: Enchanting.Stir = grade_of(_points)
	var tiers: int = Enchanting.STIR_TIERS[grade]
	_feedback_label.text = "%s: %s" % [Language.translate(Enchanting.STIR_NAMES[grade]),
			Language.translate("eine Seltenheit besser") if tiers > 0 else (Language.translate("eine Seltenheit schlechter") if tiers < 0 else Language.translate("wie die Zutaten"))]
	_feedback_label.add_theme_color_override("font_color", COLOR_BAD if tiers < 0 else COLOR_GOOD)


func _draw_field() -> void:
	_field.draw_circle(CENTER, RADIUS + 6.0, COLOR_OUTLINE)
	_field.draw_circle(CENTER, RADIUS + 5.0, COLOR_RIM)
	_field.draw_circle(CENTER, RADIUS - 3.0, COLOR_BOWL)
	_field.draw_circle(CENTER, RADIUS - 9.0, _liquid.darkened(0.15))
	# Swirl in the potion, turning with the pestle.
	for i in 3:
		var swirl: float = deg_to_rad(_angle + i * 120.0)
		_field.draw_arc(CENTER, RADIUS * (0.3 + i * 0.15), swirl, swirl + 1.6, 12, _liquid.lightened(0.25), 1.0)
	if _phase != Phase.RESULT:
		var half: float = deg_to_rad(ZONE_DEGREES / 2.0)
		var zone: float = deg_to_rad(_zone)
		_field.draw_arc(CENTER, RADIUS + 1.0, zone - half, zone + half, 16, COLOR_ZONE, 6.0)
		_field.draw_arc(CENTER, RADIUS + 1.0, zone - half * CLEAN_SHARE, zone + half * CLEAN_SHARE, 8, COLOR_CLEAN, 6.0)
	for mark: Array in _marks:
		var at: Vector2 = CENTER + Vector2.from_angle(deg_to_rad(mark[0])) * (RADIUS + 9.0)
		_field.draw_circle(at, 2.0, [COLOR_BAD, COLOR_ZONE, COLOR_CLEAN][mark[1]])
	# The pestle: a stick from the middle to the rim with a round head.
	var tip: Vector2 = CENTER + Vector2.from_angle(deg_to_rad(_angle)) * (RADIUS - 4.0)
	_field.draw_line(CENTER, tip, COLOR_OUTLINE, 5.0)
	_field.draw_line(CENTER, tip, COLOR_PESTLE, 3.0)
	_field.draw_circle(tip, 4.0, COLOR_OUTLINE)
	_field.draw_circle(tip, 3.0, COLOR_PESTLE)
