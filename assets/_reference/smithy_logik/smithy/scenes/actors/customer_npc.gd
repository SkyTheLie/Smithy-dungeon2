class_name CustomerNpc
extends Station
## A customer waiting in front of the smithy (spawned by CustomerSpawner for each waiting
## Customers.Visitor). Talk to him with E: the CustomerDialog shows his order.
## The "!" above his head shows that he has an order for you.

var visitor: Customers.Visitor

@onready var _dialog: CustomerDialog = $CustomerDialog
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	$NameLabel.text = visitor.order.customer_name
	var look: Appearance = visitor.order.appearance
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(visitor.order.resident)
	_sprite.texture = sheet if sheet else CharacterBaker.get_sheet(look)
	_sprite.region_rect = CharacterBaker.get_frame_rect("down")
	if sheet == null:
		_sprite.scale = Vector2.ONE * look.get_scale()
	_dialog.setup(visitor, CharacterBaker.get_sheet_portrait(sheet) if sheet else CharacterBaker.get_portrait(look))
	interacted.connect(_dialog.toggle)
	player_left.connect(_dialog.close)
