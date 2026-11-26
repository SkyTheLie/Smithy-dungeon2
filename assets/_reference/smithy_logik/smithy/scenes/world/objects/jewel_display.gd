class_name JewelDisplay
extends Station
## The jewel case of the own shop (house.json furniture with "jewel_slots", placed by
## FurnitureLayer). E opens the display window with the shop's jewel places (ShopDisplayMenu with
## `jewelry`): rings and amulets on it are sold like the weapons on the tables, all gold goes into
## the cash box. While it stands in the shop annex (from house level 4) the places are in use
## (House.has_jewel_display). The jewels on display lie small on the velvet of the picture.
## The picture of the case is the Sprite2D FurnitureLayer adds as first child.

const MENU_SCENE: PackedScene = preload("res://scenes/ui/menus/shop_display_menu.tscn")
## Where the jewels lie on the velvet: pixel of the picture (from its top left) of each place, in
## the order of the shop's jewel places; more places than spots share the last ones.
const SPOTS: Array[Vector2] = [Vector2(6, 4), Vector2(12, 4), Vector2(18, 4), Vector2(24, 4),
		Vector2(6, 8), Vector2(12, 8), Vector2(18, 8), Vector2(24, 8)]
## Size of a jewel icon on the case (item icons are 24 px).
const JEWEL_SCALE: float = 0.3

## house.json furniture id (e.g. jewel_display).
var furniture_id: String = ""

var _menu: ShopDisplayMenu
var _picture_size: Vector2 = Vector2(30, 22)
var _jewels: Array[Sprite2D] = []


## Called by FurnitureLayer before the case enters the tree.
func setup(id: String) -> void:
	furniture_id = id


func _ready() -> void:
	super()
	var path: String = House.get_furniture(furniture_id).get("texture", "")
	if ResourceLoader.exists(path):
		_picture_size = (load(path) as Texture2D).get_size()
	_add_interaction_area()
	interacted.connect(_open_menu)
	player_left.connect(func() -> void:
		if _menu and _menu.visible:
			_menu.close())
	GameState.house.shop.changed.connect(_update_jewels)
	_update_jewels()


func _add_interaction_area() -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _picture_size + Vector2(24, 24)
	shape.shape = rect
	shape.position = Vector2(0, -_picture_size.y / 2.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_interaction_area_body_entered)
	area.body_exited.connect(_on_interaction_area_body_exited)


## The jewels on display, small on the velvet.
func _update_jewels() -> void:
	var shop: ConsignmentShop = GameState.house.shop
	var places: Array[int] = shop.get_jewel_slots()
	while _jewels.size() < places.size():
		var sprite := Sprite2D.new()
		sprite.scale = Vector2.ONE * JEWEL_SCALE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var spot: Vector2 = SPOTS[mini(_jewels.size(), SPOTS.size() - 1)]
		sprite.position = spot - Vector2(_picture_size.x / 2.0, _picture_size.y)
		add_child(sprite)
		_jewels.append(sprite)
	for n in places.size():
		var stack: InventorySlot = shop.slots[places[n]]
		_jewels[n].texture = null if stack.is_empty() or not shop.is_active(places[n]) else stack.get_icon()


func _open_menu() -> void:
	if _menu == null:
		_menu = MENU_SCENE.instantiate()
		_menu.shop = "house"
		_menu.jewelry = true
		_menu.title = House.get_furniture(furniture_id).get("name", "")
		add_child(_menu)
	_menu.toggle()
