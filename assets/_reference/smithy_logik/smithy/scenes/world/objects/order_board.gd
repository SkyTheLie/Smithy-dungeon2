class_name OrderBoard
extends Station
## Order board in front of the smithy. It only appears once `active_flag` is set (story: the
## first customer's order); before that it is hidden, has no collision and E does nothing.
## It shows up right away when the flag is set while the player is on the map.

## Story flag from which on the order board stands there.
@export var active_flag: String = "order_board_unlocked"

@onready var _menu: StationMenu = $OrderBoardMenu


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	player_left.connect(_menu.close)
	GameState.story.changed.connect(_update_shown)
	_update_shown()


func _update_shown() -> void:
	var shown: bool = GameState.story.has_flag(active_flag)
	visible = shown
	blocked = not shown
	$CollisionShape2D.set_deferred("disabled", not shown)


func _on_interacted() -> void:
	_menu.toggle()
