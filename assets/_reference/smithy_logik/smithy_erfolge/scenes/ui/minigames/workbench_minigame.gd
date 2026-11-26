class_name WorkbenchMinigame
extends PanelContainer
## Workbench minigame (joining): first the lower part (handle, shaft, leather ...) swings from
## side to side along a lower curve; a left click stops it. Then the upper part (blade, head, plate ...)
## swings along a curve above; a left click sets it down onto the lower part. At the
## enchanting table the same way a crystal goes into the top of an iron staff.
## How well the middles of both parts meet gives the grade (Joining.grade, green/yellow widths):
## perfect, good, okay or failed. The AssemblyMenu then builds the item or damages the parts.
## Strip widths come from GameState.player_stats (skill "Passgenau"); harder materials (for the
## reputation, ForgeQuality.get_difficulty) make the parts swing faster and the strips smaller.
## Each part starts its swing at a random place and in a random direction (spamming the mouse
## button can't line both parts up any more).

signal finished(grade: Joining.Grade)
## The X of the title bar was clicked (the assembly menu aborts the joining).
signal close_requested

enum Phase { LOWER, UPPER, DROP, RESULT }

const COLOR_GRADES: Array[Color] = [Color(0.9, 0.4, 0.35), Color(0.9, 0.8, 0.25), Color(0.55, 0.85, 0.45),
		Color(0.35, 0.95, 0.35)]

## Seconds the lower part needs from one side to the other (lower = harder).
@export var lower_duration: float = 0.85
## Seconds the upper part needs from one side to the other.
@export var upper_duration: float = 1.0
## Seconds the upper part needs to come down.
@export var drop_duration: float = 0.3
## Seconds the result is shown before the window goes back to the workbench.
@export var result_duration: float = 1.2

var _running: bool = false
var _phase: Phase = Phase.LOWER
var _time: float = 0.0
var _grade: Joining.Grade = Joining.Grade.FAIL
## How much faster the parts swing (difficulty "speed").
var _speed: float = 1.0
## Where in its swing the moving part started (0..2 for pingpong: 0 = left end going right,
## 1 = right end going left), rolled for every moving phase.
var _swing_start: float = 0.0

@onready var _info_label: Label = %InfoLabel
@onready var _field: JoiningField = %Field
@onready var _feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	%TitleBar.close_requested.connect(close_requested.emit)


## `upper_name` / `lower_name`: names of the two parts (shown above the field).
## `difficulty`: ForgeQuality.get_difficulty entry ("speed", "green", "yellow").
## `crystal_color`: set (alpha > 0) = a crystal goes into a staff (enchanting table) in this colour.
## `upper_icon` / `lower_icon`: item icons of the parts, drawn instead of the placeholder shapes.
## `staff_material`: metal of the staff a crystal goes into (materials.json id, colour of its head).
func start(upper_name: String, lower_name: String, difficulty: Dictionary = {},
		crystal_color: Color = Color.TRANSPARENT, upper_icon: Texture2D = null, lower_icon: Texture2D = null,
		staff_material: String = "iron") -> void:
	var stats: PlayerStats = GameState.player_stats
	_field.set_part_icons(upper_icon, lower_icon)
	_field.crystal_style = crystal_color.a > 0.0
	if _field.crystal_style:
		_field.crystal_color = crystal_color
		_field.staff_material = staff_material if not staff_material.is_empty() else "iron"
	_speed = maxf(0.1, float(difficulty.get("speed", 1.0)))
	_field.green_width = stats.get_joining_green_zone_width() * JoiningField.FIELD_WIDTH * float(difficulty.get("green", 1.0))
	_field.yellow_width = stats.get_joining_yellow_zone_width() * JoiningField.FIELD_WIDTH * float(difficulty.get("yellow", 1.0))
	_field.failed = false
	_field.drop = 0.0
	_swing_start = randf() * 2.0
	_field.upper_angle = _swing_angle(JoiningField.UPPER_SWING_HALF_ANGLE, randf() * 2.0)
	_field.lower_angle = _swing_angle(JoiningField.LOWER_SWING_HALF_ANGLE, _swing_start)
	_info_label.text = Language.translate("%s auf %s setzen") % [upper_name, lower_name]
	_feedback_label.text = Language.translate("Klick: unteres Teil anhalten")
	_feedback_label.remove_theme_color_override("font_color")
	_phase = Phase.LOWER
	_time = 0.0
	_running = true
	show()


## Aborts the minigame without result.
func stop() -> void:
	_running = false
	hide()


func is_running() -> bool:
	return _running


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	match _phase:
		Phase.LOWER:
			_field.lower_angle = _swing_angle(JoiningField.LOWER_SWING_HALF_ANGLE,
					_swing_start + _time * _speed / lower_duration)
		Phase.UPPER:
			_field.upper_angle = _swing_angle(JoiningField.UPPER_SWING_HALF_ANGLE,
					_swing_start + _time * _speed / upper_duration)
		Phase.DROP:
			_field.drop = minf(_time / drop_duration, 1.0)
			if _field.drop >= 1.0:
				_show_result()
		Phase.RESULT:
			if _time >= result_duration:
				_running = false
				finished.emit(_grade)


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (_running and mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	match _phase:
		Phase.LOWER:
			_phase = Phase.UPPER
			_feedback_label.text = Language.translate("Klick: oberes Teil aufsetzen")
		Phase.UPPER:
			_grade = Joining.grade(_field.get_joint_offset(), _field.green_width, _field.yellow_width)
			_phase = Phase.DROP
			_feedback_label.text = ""
		_:
			return
	# The next moving phase starts at a random place of its swing.
	_time = 0.0
	_swing_start = randf() * 2.0
	if _phase == Phase.UPPER:
		_field.upper_angle = _swing_angle(JoiningField.UPPER_SWING_HALF_ANGLE, _swing_start)


## Angle of a swinging part at `at` of its swing (pingpong: 0 = left end, 1 = right end).
func _swing_angle(half_angle: float, at: float) -> float:
	return lerpf(-half_angle, half_angle, pingpong(at, 1.0))


func _show_result() -> void:
	_phase = Phase.RESULT
	_time = 0.0
	_field.failed = _grade == Joining.Grade.FAIL
	_feedback_label.text = Joining.get_display_name(_grade)
	if _field.failed:
		_feedback_label.text = Language.translate("Passt nicht – die Teile leiden")
	_feedback_label.add_theme_color_override("font_color", COLOR_GRADES[_grade])
