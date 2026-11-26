extends Sprite2D
## A picture that changes with the level of the player's house (GameState.house.level):
## `textures[level - 1]`; levels without their own picture use the last one before them.

@export var textures: Array[Texture2D] = []


func _ready() -> void:
	var index: int = mini(GameState.house.level, textures.size()) - 1
	while index > 0 and textures[index] == null:
		index -= 1
	if index >= 0:
		texture = textures[index]
