extends StaticBody2D
## The player's smithy on the yard: every house level is its own picture with its own size, so the
## place of the picture, chimney smoke, collision and main door differ per level. All lists are
## per level (index 0 = level 1), in the node's own coordinates. Above the Player in the scene:
## `from_door` moves before the player looks for his spawn point.

@export var picture_positions: Array[Vector2] = []
@export var smoke_positions: Array[Vector2] = []
## Left and right end of the walls.
@export var wall_ends: Array[Vector2] = []
## Middle of the main door.
@export var door_x: Array[float] = []
## Where the player stands after leaving through the door (x follows door_x).
@export var from_door: Marker2D


func _ready() -> void:
	var index: int = clampi(GameState.house.level, 1, door_x.size()) - 1
	$Sprite2D.position = picture_positions[index]
	$ChimneySmoke.position = smoke_positions[index]
	var wall: Vector2 = wall_ends[index]
	var shape := $CollisionShape2D as CollisionShape2D
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	shape.shape = shape.shape.duplicate()
	(shape.shape as RectangleShape2D).size = Vector2(wall.y - wall.x, size.y)
	shape.position.x = (wall.x + wall.y) / 2.0
	$DoorToSmithy.position.x = door_x[index]
	if from_door:
		from_door.position.x = door_x[index]
