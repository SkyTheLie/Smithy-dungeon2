class_name CalendarMenu
extends StationMenu
## Calendar window (Nina's gift, hangs in the bedroom): one month (season) as a grid of weeks,
## today highlighted, days with notes (GameState.get_calendar_notes: rent, order deadlines, the
## traveller) marked with "*" (the pixel font has no dot symbol), a tooltip and listed below.
## "<" / ">" leaf through the months (not before the current one).

const COLOR_TODAY: Color = Color(0.95, 0.8, 0.5)
const COLOR_PAST: Color = Color(0.45, 0.43, 0.4)
const COLOR_NOTE: Color = Color(0.55, 0.85, 0.45)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const CELL_SIZE: Vector2 = Vector2(22, 16)

## Month shown right now (GameCalendar month index).
var _month: int = 0

@onready var _month_label: Label = %MonthLabel
@onready var _grid: GridContainer = %Grid
@onready var _notes: VBoxContainer = %Notes
@onready var _previous: Button = %PreviousButton


func _ready() -> void:
	super()
	_previous.pressed.connect(func() -> void: _show_month(_month - 1))
	%NextButton.pressed.connect(func() -> void: _show_month(_month + 1))
	visibility_changed.connect(func() -> void:
		if visible:
			_show_month(GameCalendar.get_month_index(GameState.day_cycle.day)))


func _show_month(month: int) -> void:
	var today: int = GameState.day_cycle.day
	_month = maxi(month, 0)
	_previous.disabled = _month <= 0
	_month_label.text = GameCalendar.get_month_title(_month)
	for container: Node in [_grid, _notes]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	var weekdays: Array = GameCalendar.get_weekday_short_names()
	_grid.columns = weekdays.size()
	for name: String in weekdays:
		_grid.add_child(_create_label(name, COLOR_HINT))
	var first: int = GameCalendar.get_first_day_of_month(_month)
	# Empty cells before the first day (months may start on any weekday).
	for i in GameCalendar.get_weekday(first):
		_grid.add_child(_create_label(""))
	for day in range(first, first + GameCalendar.get_days_per_month()):
		var notes: Array[String] = GameState.get_calendar_notes(day)
		var text: String = str(GameCalendar.get_day_of_month(day)) + ("*" if not notes.is_empty() else "")
		var color: Color = COLOR_TODAY if day == today else (COLOR_PAST if day < today else (COLOR_NOTE if not notes.is_empty() else Color.WHITE))
		var cell: Label = _create_label(text, color)
		cell.tooltip_text = "\n".join(notes)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		_grid.add_child(cell)
		for note in notes:
			var line: Label = _create_label("%s: %s" % [GameCalendar.get_short_text(day), note], COLOR_NOTE)
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_notes.add_child(line)
	if _notes.get_child_count() == 0:
		_notes.add_child(_create_label(Language.translate("Keine Vermerke in diesem Monat."), COLOR_HINT))


func _create_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = CELL_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	return label
