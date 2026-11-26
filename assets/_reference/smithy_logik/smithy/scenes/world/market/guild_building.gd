extends StaticBody2D
## The adventurers' guild on the market: it grows with every guild level (GuildLevel), from a small
## wooden cabin to the big guild house with the tower. Every level is its own picture; the front
## door stays where it is (DoorToGuild), so each picture is placed with its door on this node's x
## (minus `door_offset`) and its bottom edge on the node. The collision follows the picture width.
## Lists are per guild level (index 0 = not expanded).

## Picture per level.
@export var textures: Array[Texture2D] = []
## x of the door's middle inside each picture (pixels from the left edge).
@export var door_x: Array[float] = []
## Where the door is, relative to this node (DoorToGuild in the market scene).
@export var door_offset: float = -2.0
## Wall collision: the picture width minus this much on each side (roof overhang, barrels).
@export var collision_inset: float = 8.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	GameState.story.changed.connect(_update)
	_update()


func _update() -> void:
	if textures.is_empty():
		return
	var index: int = clampi(GuildLevel.get_level(GameState.story), 0, textures.size() - 1)
	var texture: Texture2D = textures[index]
	if _sprite.texture == texture:
		return
	var size: Vector2 = texture.get_size()
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.offset = Vector2(0, -size.y / 2.0)
	_sprite.position.x = door_offset - door_x[index] + size.x / 2.0
	var shape := (_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
	shape.size.x = size.x - 2.0 * collision_inset
	_shape.shape = shape
	_shape.position.x = _sprite.position.x
