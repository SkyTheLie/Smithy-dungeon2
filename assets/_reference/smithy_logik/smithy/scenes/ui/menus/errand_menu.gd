class_name ErrandMenu
extends StationMenu
## "Einkauf für Lotte" (story action "open_menu:errand", from her morning dialogue in the workshop):
## pick one ware of today's market stock and how many, see the price with her wage and send her
## off (GameState.assistant, Assistant.send). The list is built when the window opens.

const MENU_ID: String = "errand"
const ICON_SIZE: int = 16
const COLOR_GOLD: Color = Color(1, 0.85, 0.35)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

## Wares of _item_button in order (Assistant.get_offers).
var _offers: Array[Dictionary] = []

@onready var _item_button: OptionButton = %ItemButton
@onready var _amount_box: SpinBox = %AmountBox
@onready var _price_label: Label = %PriceLabel
@onready var _send_button: Button = %SendButton
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	Events.story_menu_requested.connect(func(menu: String) -> void:
		if menu == MENU_ID:
			open())
	_item_button.get_popup().max_size = Vector2i(0, 200)
	_item_button.item_selected.connect(func(_index: int) -> void: _refresh_amount())
	_amount_box.value_changed.connect(func(_value: float) -> void: _refresh_price())
	_send_button.pressed.connect(_send)
	GameState.gold_changed.connect(func(_gold: int) -> void: _refresh_price())


func open() -> void:
	_message_label.text = ""
	_offers = Assistant.get_offers()
	_item_button.clear()
	for i in _offers.size():
		var offer: Dictionary = _offers[i]
		var stack: InventorySlot = offer["stack"]
		var left: String = "" if int(offer["left"]) < 0 else Language.translate(", %d da") % int(offer["left"])
		_item_button.add_icon_item(_small_icon(stack), "%s (%s%s, %d Gold)" % [stack.get_display_name(), offer["name"], left, offer["price"]], i)
	if not _offers.is_empty():
		_item_button.select(0)
	_refresh_amount()
	show()


func _get_offer() -> Dictionary:
	var index: int = _item_button.selected
	return _offers[index] if index >= 0 and index < _offers.size() else {}


func _refresh_amount() -> void:
	var offer: Dictionary = _get_offer()
	_amount_box.max_value = Assistant.get_max_amount(offer) if not offer.is_empty() else 1
	_amount_box.value = clampf(_amount_box.value, 1, _amount_box.max_value)
	_refresh_price()


func _get_total() -> Array[int]:
	var offer: Dictionary = _get_offer()
	var cost: int = int(offer.get("price", 0)) * int(_amount_box.value)
	return [cost, Assistant.get_wage(cost)]


func _refresh_price() -> void:
	if _send_button == null:
		return
	var offer: Dictionary = _get_offer()
	if offer.is_empty():
		_price_label.text = Language.translate("Auf dem Markt gibt es heute nichts.")
		_send_button.disabled = true
		return
	var price: Array[int] = _get_total()
	_price_label.text = Language.translate("Ware: %d Gold · Lohn für Lotte: %d Gold") % [price[0], price[1]]
	_send_button.text = Language.translate("Lotte losschicken (%d Gold)") % (price[0] + price[1])
	var blocker: String = GameState.assistant.get_blocker(GameState.gold, price[0] + price[1])
	_send_button.disabled = not blocker.is_empty()
	_send_button.tooltip_text = blocker


func _send() -> void:
	var offer: Dictionary = _get_offer()
	if offer.is_empty():
		return
	var price: Array[int] = _get_total()
	var blocker: String = GameState.assistant.get_blocker(GameState.gold, price[0] + price[1])
	if not blocker.is_empty() or not GameState.assistant.send(offer, int(_amount_box.value)):
		_message_label.text = blocker if not blocker.is_empty() else Language.translate("Du hast nicht genug Gold.")
		_message_label.add_theme_color_override("font_color", COLOR_ERROR)
		return
	var stack: InventorySlot = offer["stack"]
	GameState.show_message(Language.translate("Lotte läuft zum Markt: %d× %s.") % [int(_amount_box.value), stack.get_display_name()])
	close()


func _small_icon(stack: InventorySlot) -> Texture2D:
	var texture: Texture2D = stack.get_icon()
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return texture
	image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
