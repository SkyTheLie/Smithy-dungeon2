class_name DenBarMenu
extends StationMenu
## Window of Vex, the bartender of the gambling den (DenBartender): buy gaming coins with gold (no
## way back: the den never changes coins into gold) or open his black-market goods
## (`shop_requested`). The games are at the tables and machines (HigherLowerMenu, PokerMenu,
## SlotMachine). Rules and coins: GamblingDen. The window only shows and calls.

signal shop_requested

const BUY_AMOUNTS: Array[int] = [1, 10, 50]

var greeting: String = ""

@onready var _greeting: Label = %Greeting
@onready var _coins_label: Label = %CoinsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _rate_label: Label = %RateLabel
@onready var _buy_buttons: Array[Button] = [%Buy1, %Buy10, %Buy50]
@onready var _result: Label = %ResultLabel
@onready var _shop: Button = %ShopButton


func _ready() -> void:
	super()
	for i in _buy_buttons.size():
		_buy_buttons[i].pressed.connect(buy.bind(BUY_AMOUNTS[i]))
	_shop.pressed.connect(func() -> void:
		close()
		shop_requested.emit())
	GameState.gambling_den.coins_changed.connect(_queue_refresh)
	GameState.gold_changed.connect(_queue_refresh)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_greeting.text = greeting
		_result.text = ""
		_refresh()


## Buys `amount` coins (a button).
func buy(amount: int) -> void:
	if GameState.gambling_den.buy_coins(amount):
		_result.text = Language.translate("Vex schiebt dir %d Münzen über den Tresen.") % amount
	else:
		_result.text = Language.translate("Nicht genug Gold.")
	_refresh()


func _refresh() -> void:
	_refresh_done()
	_coins_label.text = Language.translate("Münzen: %d") % GameState.gambling_den.coins
	_gold_label.text = Language.translate("Gold: %d") % GameState.gold
	_rate_label.text = Language.translate("1 Münze kostet %d Gold. Zurück tauscht Vex nicht.") % GamblingDen.get_coin_price()
	for i in _buy_buttons.size():
		_buy_buttons[i].tooltip_text = Language.translate("%d Münzen für %d Gold") % [BUY_AMOUNTS[i], BUY_AMOUNTS[i] * GamblingDen.get_coin_price()]
		_buy_buttons[i].disabled = GameState.gold < BUY_AMOUNTS[i] * GamblingDen.get_coin_price()
