class_name SleepMenu
extends StationMenu
## Question at the bed: "Schlafen gehen?" Yes ends the day (GameState.sleep), no closes.

const TEXT_NIGHT: String = "Es ist spät. Schlafen gehen und den Tag beenden?"
const TEXT_DAY: String = "Es ist noch %s. Trotzdem schlafen gehen und den Tag beenden?"
const TEXT_BLOCKED: String = "Jetzt schlafen? Draußen brennt das Dorf!"

@onready var _text_label: Label = %TextLabel


func _ready() -> void:
	super()
	%SleepButton.pressed.connect(_on_sleep_pressed)
	%StayButton.pressed.connect(close)
	visibility_changed.connect(_update_text)


func _update_text() -> void:
	# Story steps with "no_sleep": the bed stays closed (e.g. during the raid).
	var blocked: bool = GameState.story.get_step().get("no_sleep", false)
	%SleepButton.visible = not blocked
	if blocked:
		_text_label.text = Language.translate(TEXT_BLOCKED)
		return
	var cycle: DayCycle = GameState.day_cycle
	if cycle.get_phase() == DayCycle.Phase.NIGHT:
		_text_label.text = Language.translate(TEXT_NIGHT)
	else:
		_text_label.text = Language.translate(TEXT_DAY) % cycle.get_phase_name()


func _on_sleep_pressed() -> void:
	close()
	GameState.sleep()
