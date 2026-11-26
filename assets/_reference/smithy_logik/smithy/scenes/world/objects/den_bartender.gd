class_name DenBartender
extends Station
## Vex, the shadow dealer, behind the bar of the gambling den above the black market. E opens his
## window (DenBarMenu: buying gaming coins); from there his black-market goods open in the usual
## ShopDialog, for coins only (`offers` plus the daily single pieces of `stock_id`).

@export var merchant_name: String = "Schattenhändler Vex":
	get:
		return Language.translate(merchant_name)
@export_multiline var greeting: String = "":
	get:
		return Language.translate(greeting)
## Black-market offers besides the daily stock (recipes, item specs like a Merchant's `offers`).
@export var offers: Array[String] = []
## Daily stock: economy.json market_stock.<stock_id> (single pieces, rolled each day).
@export var stock_id: String = ""

@onready var _menu: DenBarMenu = $DenBarMenu
@onready var _shop: ShopDialog = $ShopDialog


func _ready() -> void:
	super()
	($NameLabel as Label).text = merchant_name
	_menu.greeting = greeting
	# Vex sells for gaming coins only (ShopDialog.pays_in_coins, prices GamblingDen.get_prize_price).
	_shop.pays_in_coins = true
	_shop.setup(merchant_name, greeting, offers, 1.0, get_stock_key(), stock_id)
	interacted.connect(_on_interacted)
	player_left.connect(_menu.close)
	player_left.connect(_shop.close)
	_menu.shop_requested.connect(_shop.toggle)


func _on_interacted() -> void:
	if _shop.visible:
		_shop.close()
	else:
		_menu.toggle()


## Key of Vex's stock (MerchantStock), like Merchant.get_stock_key.
func get_stock_key() -> String:
	var scene_root: Node = owner if owner else get_tree().current_scene
	return "%s:%s" % [scene_root.scene_file_path, scene_root.get_path_to(self)]
