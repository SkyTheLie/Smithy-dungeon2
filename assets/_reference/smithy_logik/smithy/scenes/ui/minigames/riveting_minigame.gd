class_name RivetingMinigame
extends PanelContainer
## Riveting minigame (armor at the workbench: chest plate, helmet shell ... onto leather): the
## plate lies on the leather with RIVET_COUNT holes along its edge. Above one hole after the other
## a hammer swings from side to side; a left click strikes. How far from the hole it hits gives
## that rivet's grade (Joining.grade, the same green/yellow widths as joining). All rivets together
## give the grade of the piece (Joining.combine): perfect, good, okay or failed. The AssemblyMenu
## then builds the item or damages the parts, as after joining (WorkbenchMinigame).
## Strip widths come from GameState.player_stats (skill "Passgenau"); harder materials
## (ForgeQuality.get_difficulty) make the hammer swing faster and the strips smaller.
## Each swing starts at a random place and in a random direction.
## Shields (start_grip): the grip is riveted onto the shield plate at its GRIP_RIVET_COUNT tips.

signal finished(grade: Joining.Grade)
## The X of the title bar was clicked (the assembly menu aborts the riveting).
signal close_requested

enum Phase { AIM, STRIKE, PAUSE, RESULT }

## Rivets per armor piece, and per shield grip (both guard ends and the pommel).
@export var rivet_count: int = 4
@export var grip_rivet_count: int = 3
## Seconds the hammer needs from one side to the other (lower = harder).
@export var swing_duration: float = 0.75
## Seconds the hammer needs to come down, and the pause before the next hole.
@export var strike_duration: float = 0.07
@export var pause_duration: float = 0.3
## Seconds the result is shown before the window goes back to the workbench.
@export var result_duration: float = 1.2

var _running: bool = false
var _phase: Phase = Phase.AIM
var _time: float = 0.0
var _speed: float = 1.0
var _swing_start: float = 0.0
## Grade of every rivet set so far.
var _grades: Array[Joining.Grade] = []
var _grade: Joining.Grade = Joining.Grade.FAIL
## Rivets of the running piece (rivet_count or grip_rivet_count).
var _count: int = 4

@onready var _info_label: Label = %InfoLabel
@onready var _field: RivetingField = %Field
@onready var _feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	%TitleBar.close_requested.connect(close_requested.emit)


## `plate_name` / `leather_name`: names of the two parts (shown above the field).
## `difficulty`: ForgeQuality.get_difficulty entry ("speed", "green", "yellow").
## `plate_icon` / `leather_icon`: item icons of the parts (null = drawn placeholder shapes).
func start(plate_name: String, leather_name: String, difficulty: Dictionary = {},
		plate_icon: Texture2D = null, leather_icon: Texture2D = null) -> void:
	_count = rivet_count
	_field.set_parts(plate_icon, leather_icon, _count)
	_begin(plate_name, leather_name, difficulty)


## Shield: the grip is riveted onto the shield plate (see RivetingField.set_grip).
func start_grip(grip_name: String, plate_name: String, difficulty: Dictionary = {},
		grip_icon: Texture2D = null, plate_icon: Texture2D = null) -> void:
	_count = grip_rivet_count
	_field.set_grip(grip_icon, plate_icon, _count)
	_count = mini(_count, _field.holes.size())
	_begin(grip_name, plate_name, difficulty)


## Rivets of the running piece.
func get_rivet_count() -> int:
	return _count


func _begin(upper_name: String, lower_name: String, difficulty: Dictionary) -> void:
	var stats: PlayerStats = GameState.player_stats
	_speed = maxf(0.1, float(difficulty.get("speed", 1.0)))
	_field.green_width = stats.get_joining_green_zone_width() * JoiningField.FIELD_WIDTH * float(difficulty.get("green", 1.0))
	_field.yellow_width = stats.get_joining_yellow_zone_width() * JoiningField.FIELD_WIDTH * float(difficulty.get("yellow", 1.0))
	_info_label.text = Language.translate("%s auf %s nieten") % [upper_name, lower_name]
	_feedback_label.remove_theme_color_override("font_color")
	_grades.clear()
	_running = true
	_aim_at(0)
	show()


## Aborts the minigame without result.
func stop() -> void:
	_running = false
	hide()


func is_running() -> bool:
	return _running


func _aim_at(hole: int) -> void:
	_phase = Phase.AIM
	_time = 0.0
	_swing_start = randf() * 2.0
	_field.strike = 0.0
	_field.current = hole
	_field.hammer_offset = _swing_offset(_swing_start)
	_feedback_label.text = Language.translate("Klick: Niet einschlagen (%d/%d)") % [hole + 1, _count]
	_feedback_label.remove_theme_color_override("font_color")


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	match _phase:
		Phase.AIM:
			_field.hammer_offset = _swing_offset(_swing_start + _time * _speed / swing_duration)
		Phase.STRIKE:
			_field.strike = minf(_time / strike_duration, 1.0)
			if _field.strike >= 1.0:
				_set_rivet()
		Phase.PAUSE:
			if _time >= pause_duration:
				_aim_at(_grades.size())
		Phase.RESULT:
			if _time >= result_duration:
				_running = false
				finished.emit(_grade)


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (_running and mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if _phase != Phase.AIM:
		return
	_phase = Phase.STRIKE
	_time = 0.0


## The hammer is down: the rivet goes in where it hit.
func _set_rivet() -> void:
	var grade: Joining.Grade = Joining.grade(_field.hammer_offset, _field.green_width, _field.yellow_width)
	_grades.append(grade)
	_field.add_rivet(_field.current, _field.hammer_offset, grade)
	AudioManager.play_sound(["anvil_miss", "anvil_good", "anvil_good", "anvil_perfect"][grade])
	_feedback_label.text = Joining.get_display_name(grade)
	_feedback_label.add_theme_color_override("font_color", WorkbenchMinigame.COLOR_GRADES[grade])
	_time = 0.0
	if _grades.size() < _count:
		_phase = Phase.PAUSE
		return
	_phase = Phase.RESULT
	_field.current = -1
	_grade = Joining.combine(_grades)
	_feedback_label.text = Language.translate("Gesamt: ") + Joining.get_display_name(_grade)
	if _grade == Joining.Grade.FAIL:
		_feedback_label.text = Language.translate("Die Nieten halten nicht – die Teile leiden")
	_feedback_label.add_theme_color_override("font_color", WorkbenchMinigame.COLOR_GRADES[_grade])


## Hammer offset at `at` of its swing (pingpong: 0 = left end, 1 = right end).
func _swing_offset(at: float) -> float:
	return lerpf(-RivetingField.SWING_HALF, RivetingField.SWING_HALF, pingpong(at, 1.0))
