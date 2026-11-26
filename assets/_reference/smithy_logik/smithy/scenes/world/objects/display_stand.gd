extends Station
## A display table in Nina's shop or the player's own shop. Shows the item on display place
## `index` of the shop `shop` (GameState.get_consignment_shop); interacting opens the display
## window (connected in the scene). Tables of the own shop only exist while the house level has
## that many (House.shop.active_slots); the others remove themselves. With `dummy` it is the armor
## stand of the shop (all dummy places, ConsignmentShop.get_dummy_slots) and shows the first piece on it.

## Display place of the shop this table shows.
@export var index: int = 0
## Which shop: "nina" (Nina's shop at the market) or "house" (the player's own shop).
@export_enum("nina", "house") var shop: String = "nina"
## Picture of the table (bottom centre on the node). Empty = the simple coloured placeholder.
@export var table_texture: Texture2D
## true = armor stand: stands for all dummy places of the shop (`index` is not used).
@export var dummy: bool = false

## Armor stand: where each piece sits on the stand picture (pixel of the 28x47 picture, from its
## top left), how much its item icon is shrunk, its layer (`z`: shoulders over the chest armor,
## boots over the leg armor ...) and whether it hangs behind the stand (cloak). `mirror_at`: a
## second, mirrored copy there (gloves on both arms, boots on both feet).
const DUMMY_PLACES: Dictionary = {
	"cloak": {"at": Vector2(14, 19), "scale": 0.8, "behind": true},
	"legs": {"z": 1, "at": Vector2(14, 33), "scale": 0.55},
	"boots": {"z": 2, "at": Vector2(9, 42), "mirror_at": Vector2(19, 42), "scale": 0.45},  # icon toe points left
	"armor": {"z": 1, "at": Vector2(14, 20), "scale": 0.7},
	"shoulders": {"z": 2, "at": Vector2(14, 13), "scale": 0.6},
	"gloves": {"z": 3, "at": Vector2(25, 16), "mirror_at": Vector2(3, 16), "scale": 0.45},
	"helmet": {"z": 3, "at": Vector2(14, 5), "scale": 0.55},
	"shield": {"z": 4, "at": Vector2(5, 26), "scale": 0.55},
}
## Size of the stand picture the places above are measured on.
const DUMMY_PICTURE := Vector2(28, 47)

@onready var _item: Sprite2D = $Item
## Armor stand: the sprites of each dummy place (slot index -> Array of Sprite2D; two for gloves).
var _pieces: Dictionary = {}


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	var consignment: ConsignmentShop = GameState.get_consignment_shop(shop)
	if dummy:
		var dummy_slots: Array[int] = consignment.get_dummy_slots()
		index = dummy_slots[0] if not dummy_slots.is_empty() else -1
	if not consignment.is_active(index):
		queue_free()
		return
	if table_texture:
		_use_table_texture()
	consignment.changed.connect(_update)
	_update()


func _update() -> void:
	var consignment: ConsignmentShop = GameState.get_consignment_shop(shop)
	var slots: Array[InventorySlot] = consignment.slots
	if dummy:
		_update_pieces(consignment)
		return
	var stack: InventorySlot = slots[index] if index < slots.size() else null
	_item.texture = stack.get_icon() if stack and not stack.is_empty() else null


## Armor stand: every piece on its own place of the stand (helmet on the head, boots at the
## foot ...), shrunk to fit; the cloak hangs behind the stand.
func _update_pieces(consignment: ConsignmentShop) -> void:
	_item.texture = null
	var picture_size: Vector2 = table_texture.get_size() if table_texture else DUMMY_PICTURE
	var top_left := Vector2(-picture_size.x / 2.0, -picture_size.y)
	for i: int in consignment.get_dummy_slots():
		var type_key: String = consignment.slot_types[i]
		var place: Dictionary = DUMMY_PLACES.get(type_key, {"at": Vector2(14, 20), "scale": 0.6})
		var spots: Array = [place["at"]]
		if place.has("mirror_at"):
			spots.append(place["mirror_at"])
		if not _pieces.has(i):
			var sprites: Array[Sprite2D] = []
			for n in spots.size():
				var piece := Sprite2D.new()
				piece.name = "Piece_%s_%d" % [type_key, n]
				piece.flip_h = n == 1
				add_child(piece)
				if place.get("behind", false):
					move_child(piece, 0)  # before the stand picture: drawn behind it
				else:
					piece.z_index = int(place.get("z", 1))
				sprites.append(piece)
			_pieces[i] = sprites
		var stack: InventorySlot = consignment.slots[i]
		var sprites: Array = _pieces[i]
		for n in sprites.size():
			var piece: Sprite2D = sprites[n]
			piece.position = top_left + Vector2(spots[n]) * picture_size / DUMMY_PICTURE
			piece.scale = Vector2.ONE * float(place["scale"])
			piece.texture = stack.get_icon() if not stack.is_empty() else null


## Shows the table picture instead of the placeholder; the item lies on its top.
func _use_table_texture() -> void:
	$Top.hide()
	$Front.hide()
	var table := Sprite2D.new()
	table.texture = table_texture
	table.centered = false
	table.offset = Vector2(-table_texture.get_width() / 2.0, -table_texture.get_height())
	add_child(table)
	move_child(table, 0)
	_item.position.y = -table_texture.get_height() + 9.0
	_item.z_index = 1
