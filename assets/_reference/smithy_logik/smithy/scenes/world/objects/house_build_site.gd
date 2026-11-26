extends Node2D
## Building site in front of the player's house on the day after buying the next level
## (House.is_upgrading): stacks of material and barriers beside the door, the door stays free.
## Stands around the main door of the current level (`door_offsets`, index 0 = level 1).

@export var door_offsets: Array[float] = []


func _ready() -> void:
	if not GameState.house.is_upgrading():
		hide()
		queue_free()
		return
	position.x = door_offsets[clampi(GameState.house.level, 1, door_offsets.size()) - 1]
