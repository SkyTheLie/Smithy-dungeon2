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
## Forge sign (ForgeSignWall, child "ForgeSign"): x = the corner of the house it hangs on, y = height
## of its arm above the ground; sign_sides = where the arm points (-1 left, 1 right).
@export var sign_positions: Array[Vector2] = []
@export var sign_sides: Array[int] = []
## Where the forge sign may hang (ForgeSignPlacer): per level a list of Rect2 of house wall below
## the roof, in the node's coordinates. The whole board has to lie on them.
@export var wall_rects: Array = []
## Level 1 before the furnace is lit (`lit_flag`): dark window, no fire, no smoke from the
## chimney. The smithy has stood empty for years (story step "clean_smithy" lights it).
@export var cold_texture: Texture2D
@export var lit_flag: String = "cobweb_forge"


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
	var forge_sign := get_node_or_null("ForgeSign") as ForgeSignWall
	if forge_sign and index < sign_positions.size():
		forge_sign.position.x = sign_positions[index].x
		forge_sign.hang_height = sign_positions[index].y
		if index < sign_sides.size():
			forge_sign.side = sign_sides[index]
	_update_fire()
	if not is_lit():
		GameState.story.changed.connect(_update_fire)


## Wall areas of the current house level (see wall_rects).
func get_wall_rects() -> Array:
	var index: int = clampi(GameState.house.level, 1, door_x.size()) - 1
	return wall_rects[index] if index < wall_rects.size() else []


## Does the smithy burn (smoke, lit window)? False only while it is still the empty old smithy.
func is_lit() -> bool:
	return cold_texture == null or lit_flag.is_empty() or GameState.story.has_flag(lit_flag)


func _update_fire() -> void:
	var lit: bool = is_lit()
	$ChimneySmoke.visible = lit
	if not lit and GameState.house.level <= 1:
		$Sprite2D.texture = cold_texture
	elif $Sprite2D.texture == cold_texture:
		$Sprite2D.texture = ($Sprite2D as Sprite2D).get("textures")[0]
	if lit and GameState.story.changed.is_connected(_update_fire):
		GameState.story.changed.disconnect(_update_fire)
