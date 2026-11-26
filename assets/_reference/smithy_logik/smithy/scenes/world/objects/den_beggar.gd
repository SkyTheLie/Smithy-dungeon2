class_name DenBeggar
extends Station
## The beggar of the village square on his days off: he lounges in the gambling den (only when
## GamblingDen.is_beggar_in_den_today, otherwise he sits with his cups in the village, see
## ShellGameBeggar). No game here; E gets one of his lines.

## Seated frames of beggar_sit.png, as in the village: he breathes slowly.
const SEATED_FRAMES: Array[int] = [7, 8]
const BREATH_SECONDS: float = 0.9
const LINES: Array[String] = [
	"Heute keine Hütchen. Heute bin ich Gast.",
	"Psst. Am Automaten links kommen die Kronen öfter. Sagt man.",
	"Was ich im Dorf verdiene, verliert sich hier ganz von allein.",
	"Vex gewinnt immer. Aber manchmal lässt er dich glauben, du gewinnst.",
	"Ein paar Tage Dorf, ein paar Tage hier. Irgendwer muss die Münzen ja zurückbringen.",
]

var _next_line: int = 0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	var timer := Timer.new()
	timer.wait_time = BREATH_SECONDS
	timer.autostart = true
	timer.timeout.connect(_breathe)
	add_child(timer)
	interacted.connect(_say_line)
	GameState.story.changed.connect(_update_presence)
	GameState.day_cycle.day_started.connect(_on_day_started)
	_next_line = randi() % LINES.size()
	_update_presence()


func _breathe() -> void:
	_sprite.frame = SEATED_FRAMES[(SEATED_FRAMES.find(_sprite.frame) + 1) % SEATED_FRAMES.size()]


func _say_line() -> void:
	GameState.show_message(Language.translate("Bettler: „%s“") % Language.translate(LINES[_next_line]))
	_next_line = (_next_line + 1) % LINES.size()


func _on_day_started(_day: int) -> void:
	_update_presence()


func _update_presence() -> void:
	var here: bool = GamblingDen.is_beggar_in_den_today()
	visible = here
	blocked = not here
	$CollisionShape2D.set_deferred("disabled", not here)
