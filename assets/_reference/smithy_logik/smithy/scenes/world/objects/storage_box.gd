class_name StorageBox
extends Station
## A storage box in the house (house.json furniture with "storage", placed by FurnitureLayer).
## E opens its window (StorageMenu with the box's Inventory); the contents live in
## GameState.house.boxes under the box's `uid` (House), also when the box is moved.
## With a box sign (House.box_signs) its name shows above the box all the time; the sign itself
## is not drawn on the box.
## The picture of the box is the Sprite2D FurnitureLayer adds as first child.

const MENU_SCENE: PackedScene = preload("res://scenes/ui/menus/storage_menu.tscn")

## Key of this box in GameState.house.boxes (House.placed "uid").
var uid: String = ""
## house.json furniture id (e.g. storage_small).
var furniture_id: String = ""

var _menu: StorageMenu
var _name_label: Label


## Called by FurnitureLayer before the box enters the tree.
func setup(box_uid: String, id: String) -> void:
	uid = box_uid
	furniture_id = id


func _ready() -> void:
	super()
	var path: String = House.get_furniture(furniture_id).get("texture", "")
	var picture_size: Vector2 = (load(path) as Texture2D).get_size() if ResourceLoader.exists(path) else Vector2(20, 16)
	_add_interaction_area(picture_size)
	_add_name_label(picture_size)
	interacted.connect(_open_menu)
	player_left.connect(func() -> void:
		if _menu and _menu.visible:
			_menu.close())
	GameState.house.box_sign_changed.connect(func(changed_uid: String) -> void:
		if changed_uid == uid:
			_refresh_sign())
	var box: Inventory = GameState.house.get_box(uid)
	if box:
		box.changed.connect(_refresh_sign)
	_refresh_sign()


func _add_interaction_area(picture_size: Vector2) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = picture_size + Vector2(24, 24)
	shape.shape = rect
	shape.position = Vector2(0, -picture_size.y / 2.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_interaction_area_body_entered)
	area.body_exited.connect(_on_interaction_area_body_exited)


## The name of the box sign, just above the box picture.
func _add_name_label(picture_size: Vector2) -> void:
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.size = Vector2(96, 14)
	_name_label.position = Vector2(-48, -picture_size.y - 15)
	_name_label.add_theme_color_override("font_color", Color(1, 0.92, 0.7))
	_name_label.add_theme_color_override("font_outline_color", Color(0.13, 0.075, 0.12))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)


func _refresh_sign() -> void:
	var house: House = GameState.house
	_name_label.text = house.get_sign_name(uid)
	_name_label.visible = house.has_sign(uid) and not _name_label.text.is_empty()


func _open_menu() -> void:
	if _menu == null:
		_menu = MENU_SCENE.instantiate()
		_menu.chest = GameState.house.get_box(uid)
		_menu.box_uid = uid
		_menu.title = House.get_furniture(furniture_id).get("name", "")
		add_child(_menu)
	_menu.toggle()
