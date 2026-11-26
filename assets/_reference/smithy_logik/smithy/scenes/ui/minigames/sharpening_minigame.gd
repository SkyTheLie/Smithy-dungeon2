class_name SharpeningMinigame
extends PanelContainer
## Grindstone minigame (sharpening): a ball sits in a vertical track. Holding the left mouse button
## pushes it up, letting go lets it fall. A green zone wanders up and down the track; the longer the
## ball stays inside it, the better the edge (share 0-1 of the time, Sharpening.sharpen turns it
## into quality points). Every weapon plays the same game, so no weapon type is ahead.
## Numbers: economy.json "crafting_quality.grindstone_game" (ForgeQuality.grindstone_game); the
## skill "Meisterhand" makes the zone bigger and slower. Sparks fly from the weapon while green.

signal finished(share: float)
## The X of the title bar was clicked (the grindstone window closes, the weapon stays as it was).
signal close_requested

enum Phase { READY, RUN, RESULT }

const COLOR_TRACK: Color = Color(0.13, 0.1, 0.12)
const COLOR_FRAME: Color = Color(0.45, 0.4, 0.36)
const COLOR_ZONE: Color = Color(0.3, 0.62, 0.3)
const COLOR_ZONE_HIT: Color = Color(0.45, 0.9, 0.4)
const COLOR_BALL: Color = Color(0.95, 0.92, 0.85)
const COLOR_METER: Color = Color(0.45, 0.85, 0.4)
const COLOR_TIME: Color = Color(0.85, 0.7, 0.35)
const COLOR_SPARK: Color = Color(1.0, 0.8, 0.35)
const COLOR_RESULT: Color = Color(0.55, 0.85, 0.45)
## Layout of the field (pixels): track on the left, weapon in the middle, meter on the right.
const TRACK_RECT: Rect2 = Rect2(10, 4, 16, 128)
const METER_RECT: Rect2 = Rect2(130, 4, 8, 128)
const TIME_RECT: Rect2 = Rect2(10, 138, 128, 4)
const ICON_CENTER: Vector2 = Vector2(78, 60)
const ICON_SIZE: float = 48.0
const BALL_RADIUS: float = 5.0
## Fastest the ball moves (track heights per second).
const MAX_BALL_SPEED: float = 1.6
## Seconds before the ball starts moving, and how long the result stays.
const READY_SECONDS: float = 1.0
const RESULT_SECONDS: float = 1.3
## The zone picks a new place to wander to after this many seconds (random in between).
const ZONE_TURN_MIN: float = 0.5
const ZONE_TURN_MAX: float = 1.3
## Sparks per second while the ball is green, and how long one lives.
const SPARKS_PER_SECOND: float = 40.0
const SPARK_LIFE: float = 0.35

var _running: bool = false
var _phase: Phase = Phase.READY
var _time: float = 0.0
var _game: Dictionary = {}
## Ball and zone centre in track heights (0 = bottom, 1 = top), ball speed.
var _ball: float = 0.5
var _ball_speed: float = 0.0
var _zone: float = 0.5
var _zone_target: float = 0.5
var _zone_turn_in: float = 0.0
var _green_time: float = 0.0
var _in_zone: bool = false
var _icon: Texture2D
## Flying sparks: {"pos": Vector2, "vel": Vector2, "life": float}.
var _sparks: Array[Dictionary] = []
var _spark_debt: float = 0.0

@onready var _info_label: Label = %InfoLabel
@onready var _field: Control = %Field
@onready var _feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	%TitleBar.close_requested.connect(close_requested.emit)
	_field.draw.connect(_draw_field)


## Starts the game for the weapon in `slot`.
func start(slot: InventorySlot) -> void:
	_game = ForgeQuality.grindstone_game()
	_icon = slot.get_icon()
	_info_label.text = Language.translate("%s schärfen") % slot.get_display_name()
	_feedback_label.text = Language.translate("Bereit ...")
	_feedback_label.remove_theme_color_override("font_color")
	_ball = 0.5
	_ball_speed = 0.0
	_zone = 0.5
	_zone_target = 0.5
	_zone_turn_in = 0.0
	_green_time = 0.0
	_in_zone = true
	_sparks.clear()
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


## Share of the time the ball has been green so far (0-1).
func get_share() -> float:
	return clampf(_green_time / maxf(0.1, float(_game.get("seconds", 6.0))), 0.0, 1.0)


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	match _phase:
		Phase.READY:
			if _time >= READY_SECONDS:
				_phase = Phase.RUN
				_time = 0.0
				_feedback_label.text = Language.translate("Linksklick halten: Ball im Grünen halten")
		Phase.RUN:
			_step(delta, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
			if _time >= float(_game["seconds"]):
				_show_result()
		Phase.RESULT:
			if _time >= RESULT_SECONDS:
				_running = false
				finished.emit(get_share())
	_update_sparks(delta)
	_field.queue_redraw()


## One frame of the game: the ball rises while `held`, otherwise it falls; the zone wanders.
func _step(delta: float, held: bool) -> void:
	var accel: float = float(_game["lift"]) if held else -float(_game["gravity"])
	_ball_speed = clampf(_ball_speed + accel * delta, -MAX_BALL_SPEED, MAX_BALL_SPEED)
	_ball += _ball_speed * delta
	if _ball <= 0.0 or _ball >= 1.0:
		_ball = clampf(_ball, 0.0, 1.0)
		_ball_speed = 0.0
	var half: float = float(_game["zone"]) / 2.0
	_zone_turn_in -= delta
	if _zone_turn_in <= 0.0:
		_zone_turn_in = randf_range(ZONE_TURN_MIN, ZONE_TURN_MAX)
		_zone_target = randf_range(half, 1.0 - half)
	_zone = clampf(move_toward(_zone, _zone_target, float(_game["zone_speed"]) * delta), half, 1.0 - half)
	_in_zone = absf(_ball - _zone) <= half
	if _in_zone:
		_green_time += delta
		_spark_debt += SPARKS_PER_SECOND * delta
	_feedback_label.text = Language.translate("Im Grünen: %d %%") % roundi(get_share() * 100.0)


func _show_result() -> void:
	_phase = Phase.RESULT
	_time = 0.0
	_in_zone = false
	var share: float = get_share()
	_feedback_label.text = Language.translate("Im Grünen: %d %% » +%d Qualität") % [roundi(share * 100.0), ForgeQuality.grindstone_points(share)]
	_feedback_label.add_theme_color_override("font_color", COLOR_RESULT)


func _update_sparks(delta: float) -> void:
	while _spark_debt >= 1.0:
		_spark_debt -= 1.0
		var origin: Vector2 = ICON_CENTER + Vector2(randf_range(-ICON_SIZE, ICON_SIZE) * 0.3, ICON_SIZE * 0.25)
		_sparks.append({"pos": origin,"vel": Vector2(randf_range(-40.0, 40.0), randf_range(-70.0, -20.0)),
				"life": SPARK_LIFE})
	for spark: Dictionary in _sparks:
		spark["vel"] += Vector2(0, 220.0) * delta
		spark["pos"] += spark["vel"] * delta
		spark["life"] -= delta
	_sparks = _sparks.filter(func(spark: Dictionary) -> bool: return spark["life"] > 0.0)


func _draw_field() -> void:
	# Track with the zone and the ball.
	_field.draw_rect(TRACK_RECT, COLOR_TRACK)
	var half: float = float(_game.get("zone", 0.3)) / 2.0
	var zone_rect := Rect2(TRACK_RECT.position.x, _to_track_y(_zone + half), TRACK_RECT.size.x,
			TRACK_RECT.size.y * half * 2.0)
	_field.draw_rect(zone_rect, COLOR_ZONE_HIT if _in_zone and _phase == Phase.RUN else COLOR_ZONE)
	_field.draw_rect(TRACK_RECT, COLOR_FRAME, false, 1.0)
	var ball_pos := Vector2(TRACK_RECT.get_center().x, _to_track_y(_ball))
	_field.draw_circle(ball_pos, BALL_RADIUS, COLOR_BALL)
	_field.draw_circle(ball_pos, BALL_RADIUS, COLOR_FRAME, false, 1.0)
	# The weapon on the stone, with sparks while green.
	if _icon:
		var icon_size := Vector2(ICON_SIZE, ICON_SIZE)
		_field.draw_texture_rect(_icon, Rect2(ICON_CENTER - icon_size / 2.0, icon_size), false)
	for spark: Dictionary in _sparks:
		_field.draw_rect(Rect2(spark["pos"], Vector2(1, 1)), Color(COLOR_SPARK, spark["life"] / SPARK_LIFE))
	# Meter: share green so far. Time bar: time left.
	_field.draw_rect(METER_RECT, COLOR_TRACK)
	var filled: float = METER_RECT.size.y * get_share() if not _game.is_empty() else 0.0
	_field.draw_rect(Rect2(METER_RECT.position.x, METER_RECT.end.y - filled, METER_RECT.size.x, filled), COLOR_METER)
	_field.draw_rect(METER_RECT, COLOR_FRAME, false, 1.0)
	var left: float = 1.0
	if _phase == Phase.RUN:
		left = 1.0 - _time / maxf(0.1, float(_game["seconds"]))
	elif _phase == Phase.RESULT:
		left = 0.0
	_field.draw_rect(TIME_RECT, COLOR_TRACK)
	_field.draw_rect(Rect2(TIME_RECT.position, Vector2(TIME_RECT.size.x * left, TIME_RECT.size.y)), COLOR_TIME)


## Height in the track (0 = bottom, 1 = top) to a y in the field.
func _to_track_y(height: float) -> float:
	return TRACK_RECT.end.y - TRACK_RECT.size.y * height
