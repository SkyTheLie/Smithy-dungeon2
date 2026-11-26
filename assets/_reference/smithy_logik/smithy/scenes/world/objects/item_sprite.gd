class_name ItemSprite
extends Sprite2D
## Shows the icon of an item in the world, animated if the item's icon is (e.g. the holy fire crystal
## on the dragon's gold). Same size as in an inventory slot.

@export var item_id: String = ""


func _ready() -> void:
	if ContentDB.has_item(item_id):
		texture = ContentDB.item(item_id).icon
