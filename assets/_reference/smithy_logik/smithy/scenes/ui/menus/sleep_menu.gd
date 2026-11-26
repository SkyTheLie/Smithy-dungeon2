class_name SleepMenu
extends StationMenu
## Question at the bed: "Schlafen gehen?" Yes ends the day (GameState.sleep), no closes.
## Below it a power nap of 2, 4 or 6 hours (GameState.nap) for waiting on smelters, heroes or
## customers; a button is greyed out with the reason as tooltip if that nap is not possible.

const TEXT_NIGHT: String = "Es ist spät. Schlafen gehen und den Tag beenden?"
const TEXT_DAY: String = "Es ist noch %s. Trotzdem schlafen gehen und den Tag beenden?"
const TEXT_BLOCKED: String = "Jetzt schlafen? Draußen brennt das Dorf!"

@onready var _text_label: Label = %TextLabel


func _ready() -> void:
	super()
	%SleepButton.pressed.connect(_on_sleep_pressed)
	%StayButton.pressed.connect(close)
	visibility_changed.connect(_update_text)
	for hours: int in GameState.NAP_HOURS:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.text = Language.translate("%d h") % hours
		button.pressed.connect(_on_nap_pressed.bind(hours))
		%NapButtons.add_child(button)


func _update_text() -> void:
	# Story steps with "no_sleep": the bed stays closed (e.g. during the raid).
	var blocked: bool = GameState.story.get_step().get("no_sleep", false)
	%SleepButton.visible = not blocked
	if blocked:
		_text_label.text = Language.translate(TEXT_BLOCKED)
		return
	_update_nap_buttons()
	var cycle: DayCycle = GameState.day_cycle
	if cycle.get_phase() == DayCycle.Phase.NIGHT:
		_text_label.text = Language.translate(TEXT_NIGHT)
	else:
		_text_label.text = Language.translate(TEXT_DAY) % cycle.get_phase_name()


func _on_sleep_pressed() -> void:
	close()
	GameState.sleep()


func _update_nap_buttons() -> void:
	var buttons: Array[Node] = %NapButtons.get_children()
	for i in buttons.size():
		var problem: String = GameState.get_nap_problem(GameState.NAP_HOURS[i])
		(buttons[i] as Button).disabled = not problem.is_empty()
		(buttons[i] as Button).tooltip_text = problem if not problem.is_empty() 				else Language.translate("%d Stunden schlafen, danach geht der Tag weiter.") % GameState.NAP_HOURS[i]


func _on_nap_pressed(hours: int) -> void:
	close()
	GameState.nap(hours)
