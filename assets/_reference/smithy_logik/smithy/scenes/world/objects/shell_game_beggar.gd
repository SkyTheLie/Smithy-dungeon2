class_name ShellGameBeggar
extends Station
## The beggar who sits on the village square with three cups and a marble. E opens his shell
## game (ShellGame window). Some days he sits in the gambling den above the black market instead
## (GamblingDen.is_beggar_in_den_today: in turns, and while the villagers are away: spring festival,
## raid at night), then he is gone from here (DenBeggar sits there).

## Seated frames of beggar_sit.png (the animation "sit_down" ends seated): he breathes slowly.
const SEATED_FRAMES: Array[int] = [7, 8]
const BREATH_SECONDS: float = 0.9

@onready var _game: ShellGame = $ShellGame
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	var timer := Timer.new()
	timer.wait_time = BREATH_SECONDS
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		_sprite.frame = SEATED_FRAMES[(SEATED_FRAMES.find(_sprite.frame) + 1) % SEATED_FRAMES.size()])
	add_child(timer)
	interacted.connect(_game.toggle)
	player_left.connect(_game.close)
	GameState.story.changed.connect(_update_presence)
	GameState.day_cycle.day_started.connect(_on_day_started)
	_update_presence()


func _on_day_started(_day: int) -> void:
	_update_presence()


func _update_presence() -> void:
	var away: bool = GamblingDen.is_beggar_in_den_today()
	visible = not away
	blocked = away
	$CollisionShape2D.set_deferred("disabled", away)
	if away:
		_game.close()
