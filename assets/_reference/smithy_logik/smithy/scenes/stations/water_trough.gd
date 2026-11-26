extends Station
## Water trough in the world: steam rises from the water while a glowing part cools (the sound
## comes from the QuenchMenu).

@onready var _steam: Node2D = $Steam


func _process(_delta: float) -> void:
	_steam.visible = GameState.quencher.is_cooling()
