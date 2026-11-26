class_name SearchOrderPanel
extends VBoxContainer
## Page "Suchaufträge" of the guild window (GuildMenu): pick an item, its rarity and how many,
## see the price and send the adventurers off (GameState.search_orders, SearchOrders). Above the
## form the running orders and how many search parties the guild has (GuildLevel). Built in code.

const FONT_SIZE: int = 11
const ICON_SIZE: int = 16
const COLOR_GOLD: Color = Color(1, 0.85, 0.35)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

var _status_label: Label
var _running_list: VBoxContainer
var _form: VBoxContainer
var _item_button: OptionButton
var _rarity_button: OptionButton
var _amount_box: SpinBox
var _send_button: Button
var _message_label: Label
## Items of _item_button in order: [{"item": ItemData, "rarity": bool}].
var _items: Array[Dictionary] = []


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	add_child(_label(Language.translate("Sag den Abenteurern, was sie suchen sollen. Nach 1 bis 2 Tagen liegt es morgens in deiner Loot-Kiste."), COLOR_HINT))
	_status_label = _label("")
	add_child(_status_label)
	_running_list = VBoxContainer.new()
	_running_list.add_theme_constant_override("separation", 0)
	add_child(_running_list)
	_form = VBoxContainer.new()
	_form.add_theme_constant_override("separation", 4)
	add_child(_form)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_form.add_child(row)
	_item_button = _option_button()
	_item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_button.item_selected.connect(func(_index: int) -> void: _refresh_rarities())
	row.add_child(_item_button)
	_rarity_button = _option_button()
	_rarity_button.item_selected.connect(func(_index: int) -> void: _refresh_price())
	row.add_child(_rarity_button)
	_amount_box = SpinBox.new()
	_amount_box.min_value = 1
	_amount_box.max_value = SearchOrders.get_max_amount()
	_amount_box.value = 1
	_amount_box.suffix = "×"
	_amount_box.get_line_edit().add_theme_font_size_override("font_size", FONT_SIZE)
	_amount_box.value_changed.connect(func(_value: float) -> void: _refresh_price())
	row.add_child(_amount_box)
	_send_button = Button.new()
	_send_button.focus_mode = Control.FOCUS_NONE
	_send_button.add_theme_font_size_override("font_size", FONT_SIZE)
	_send_button.pressed.connect(_send)
	_form.add_child(_send_button)
	_message_label = _label("")
	add_child(_message_label)
	GameState.search_orders.changed.connect(refresh)
	GameState.gold_changed.connect(func(_gold: int) -> void: _refresh_price())
	refresh()


## Rebuilds status, running orders and the item list (keeps the chosen item if it is still there).
func refresh() -> void:
	if _status_label == null:
		return
	var story: Story = GameState.story
	var orders: SearchOrders = GameState.search_orders
	var slots: int = GuildLevel.get_search_order_slots(story)
	_status_label.text = Language.translate("Suchtrupps unterwegs: %d/%d · bis %s") % [orders.orders.size(), slots,
			Rarity.get_display_name(GuildLevel.get_search_max_rarity(story) as Rarity.Tier)]
	for child in _running_list.get_children():
		child.queue_free()
	for order in orders.orders:
		var days: int = maxi(1, int(order["due_day"]) - GameState.day_cycle.day)
		_running_list.add_child(_label("%s · %s" % [SearchOrders.describe(order),
				Language.translate("morgen früh") if days <= 1 else Language.translate("in %d Tagen") % days], COLOR_HINT))
	var chosen: ItemData = _get_item()
	_items = SearchOrders.get_searchable(story)
	_item_button.clear()
	for i in _items.size():
		var item: ItemData = _items[i]["item"]
		_item_button.add_icon_item(_small_icon(item), item.display_name, i)
		if item == chosen:
			_item_button.select(i)
	_refresh_rarities()


func _refresh_rarities() -> void:
	var previous: int = maxi(0, _rarity_button.selected)
	_rarity_button.clear()
	var max_rarity: int = GuildLevel.get_search_max_rarity(GameState.story)
	var with_rarity: bool = _item_button.selected >= 0 and bool(_items[_item_button.selected]["rarity"])
	for tier in (max_rarity + 1 if with_rarity else 1):
		_rarity_button.add_item(Rarity.get_display_name(tier as Rarity.Tier), tier)
	_rarity_button.select(mini(previous, _rarity_button.item_count - 1))
	_rarity_button.disabled = not with_rarity
	_refresh_price()


func _refresh_price() -> void:
	if _send_button == null:
		return
	var item: ItemData = _get_item()
	if item == null:
		_send_button.text = Language.translate("Nichts zu suchen")
		_send_button.disabled = true
		return
	var price: int = SearchOrders.get_price(item, _get_rarity(), int(_amount_box.value))
	_send_button.text = Language.translate("Suchtrupp losschicken (%d Gold)") % price
	var blocker: String = GameState.search_orders.get_blocker(GameState.story, GameState.gold, price)
	_send_button.disabled = not blocker.is_empty()
	_send_button.tooltip_text = blocker


func _send() -> void:
	var item: ItemData = _get_item()
	if item == null:
		return
	var rarity: int = _get_rarity()
	var amount: int = int(_amount_box.value)
	var price: int = SearchOrders.get_price(item, rarity, amount)
	var blocker: String = GameState.search_orders.get_blocker(GameState.story, GameState.gold, price)
	if not blocker.is_empty() or not GameState.spend_gold(price):
		_show_message(blocker if not blocker.is_empty() else Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	GameState.search_orders.add(item, rarity, amount, price, GameState.day_cycle.day)
	_show_message(Language.translate("Die Abenteurer suchen: %d× %s.") % [amount, item.display_name], COLOR_GOLD)


func _get_item() -> ItemData:
	if _item_button == null or _item_button.selected < 0 or _item_button.selected >= _items.size():
		return null
	return _items[_item_button.selected]["item"]


func _get_rarity() -> int:
	return maxi(0, _rarity_button.get_selected_id())


func _show_message(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)


func _small_icon(item: ItemData) -> Texture2D:
	var texture: Texture2D = item.icon
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return texture
	image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _option_button() -> OptionButton:
	var button := OptionButton.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.get_popup().add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 240
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
