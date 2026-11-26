extends Station
## Calendar on the bedroom wall (Nina's gift, appears with the story flag `required_flag`).
## E next to it or a click on it opens the calendar window (CalendarMenu).

@onready var _menu: CalendarMenu = $CalendarMenu


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	interacted.connect(_menu.toggle)
	player_left.connect(_menu.close)
	$Paper.gui_input.connect(_on_paper_gui_input)


func _on_paper_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_menu.show()
