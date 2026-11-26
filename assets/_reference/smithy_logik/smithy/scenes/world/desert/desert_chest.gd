class_name DesertChest
extends Station
## A chest in the desert maze (desert.json "chests"). E opens it once: its item goes into the
## inventory (DesertMaze.open_chest); afterwards it stays open and empty. The desert screen
## (desert.gd) tells it which chest it is.

const CLOSED_TEXTURE: Texture2D = preload("res://assets/sprites/props/chest.png")
const OPEN_TEXTURE: Texture2D = preload("res://assets/sprites/desert/chest_open.png")

## desert.json "chests" id ("" = an empty chest).
var chest_id: String = ""

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	_update_look()


func setup(id: String) -> void:
	chest_id = id
	if is_node_ready():
		_update_look()


func _on_interacted() -> void:
	GameState.show_message(GameState.desert.open_chest(chest_id))
	_update_look()


func _update_look() -> void:
	var texture: Texture2D = OPEN_TEXTURE if GameState.desert.is_chest_open(chest_id) else CLOSED_TEXTURE
	_sprite.texture = texture
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0)
