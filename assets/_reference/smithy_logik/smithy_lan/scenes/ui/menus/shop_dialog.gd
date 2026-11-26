class_name ShopDialog
extends StationMenu
## Shop of a merchant, laid out like the player's inventory (but bigger): his whole range
## (Merchant.offers) as slots; a click buys one piece at a fixed price from the item value
## (Economy.get_buy_price, shown in the tooltip). Stations ("station:<id>") are offered until
## the player owns them, molds/recipes ("recipe:<id>", economy.json "recipes") until unlocked,
## and single molds ("mold:<part id>=<price>", e.g. from the traveller) until unlocked; furniture
## ("furniture:<id>", house.json) can be bought any number of times and goes into the house storage.
## Stations, furniture and recipes can be locked (economy.json "stations.<id>.unlock_flag" / "house_level",
## economy.json "recipes.<id>.unlock_flag", house.json "furniture.<id>.house_level"): they are not offered until unlocked.
## `price_factor` raises the item prices (e.g. the traveller: × 2).
## Selling: right click on an inventory item (Ctrl: one piece, Shift: half the stack) or drag it
## onto the merchant's slots; he pays Economy.get_sell_price per piece (raw goods 60 % of their
## value, own work only material cost + 10 %).
## The last sold stack waits in the buyback slot and can be bought back for the same price
## (click: all, Ctrl: one, Shift: half). Kept while the window exists (not saved).
## Purchases are reported to the story (GameState.record_purchase).
## Items have a daily amount (MerchantStock, GameState.merchant_stock, shown on the slot); bought
## out = gone until the next day. Stations, recipes, molds and furniture have none.
## Guide: a ware the story wants bought (Guide, "buy:<spec>") has a golden frame.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_OK: Color = Color(0.55, 0.85, 0.45)
const COLOR_PRICE: String = "#f2cc80"
const COLOR_HINT: String = "#9e9a8f"
const COLUMNS: int = 8
## More rows than this scroll (e.g. Quentin with the single molds of every metal).
const MAX_ROWS: int = 6
const MIN_SLOTS: int = 32

## Offer specs (ContentDB.make_stack, "station:<id>", "recipe:<id>" or "mold:<part id>=<price>").
var _offers: Array[String] = []
## Factor on the item prices (Economy.get_buy_price).
var _price_factor: float = 1.0
## Whose stock this is (MerchantStock key; empty = no amounts) and its economy.json
## "market_stock" section (empty = the fixed offers).
var _stock_key: String = ""
var _stock_id: String = ""
var _slot_uis: Array[ItemSlotUI] = []
## What a click on each slot buys (Callable, empty = nothing), in slot order.
var _slot_actions: Array[Callable] = []
## Offer spec shown in each slot ("" = empty), for the guide frame.
var _slot_specs: Array[String] = []

@onready var _name_label: Label = %NameLabel
@onready var _text_label: Label = %TextLabel
@onready var _grid: GridContainer = %Grid
@onready var _grid_scroll: ScrollContainer = %GridScroll
@onready var _buyback_slot: ItemSlotUI = %BuybackSlot
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	# Buying, selling and laying out need the inventory next to the window.
	opens_inventory = true
	super()
	%ByeButton.pressed.connect(close)
	_grid.columns = COLUMNS
	_buyback_slot.gui_input.connect(_on_buyback_gui_input)
	_buyback_slot.set_drag_forwarding(Callable(), _can_drop_sell, _drop_sell)
	visibility_changed.connect(func() -> void:
		_message_label.text = ""
		_refresh())
	GameState.gold_changed.connect(func(_gold: int) -> void: _refresh())
	GameState.recipes_changed.connect(_refresh)


func setup(merchant_name: String, greeting: String, offers: Array[String], price_factor: float = 1.0,
		stock_key: String = "", stock_id: String = "") -> void:
	_offers = offers
	_price_factor = price_factor
	_stock_key = stock_key
	_stock_id = stock_id
	_title_bar.title = merchant_name
	_name_label.text = merchant_name
	_text_label.text = greeting
	_refresh()


func _refresh() -> void:
	if not is_node_ready() or not visible:
		return
	var entries: Array[Dictionary] = _get_entries()
	_ensure_slots(maxi(MIN_SLOTS, ceili(entries.size() / float(COLUMNS)) * COLUMNS))
	for i in _slot_uis.size():
		var slot_ui: ItemSlotUI = _slot_uis[i]
		slot_ui.modulate = Color.WHITE
		if i >= entries.size():
			slot_ui.extra_tooltip = ""
			slot_ui.display(InventorySlot.new())
			_slot_actions[i] = Callable()
			_slot_specs[i] = ""
			continue
		var entry: Dictionary = entries[i]
		var price_line: String = _price_line(Language.translate("Kaufen"), entry["price"])
		if entry.has("stack"):
			slot_ui.extra_tooltip = price_line
			if int(entry.get("left", MerchantStock.UNLIMITED)) > 0:
				slot_ui.extra_tooltip += Language.translate("\n[color=%s]Noch %d Stück heute[/color]") % [COLOR_HINT, entry["left"]]
			slot_ui.display(entry["stack"])
		else:
			var text: String = "[b]%s[/b]" % entry["name"]
			if not str(entry["description"]).is_empty():
				text += "\n[color=%s]%s[/color]" % [COLOR_HINT, entry["description"]]
			slot_ui.display_custom(entry["icon"], text + "\n" + price_line)
		_slot_actions[i] = entry["action"]
		_slot_specs[i] = entry["spec"]
	_fit_scroll()
	_buyback_slot.extra_tooltip = _price_line(Language.translate("Zurückkaufen"), GameState.buyback_price * GameState.buyback.amount)
	_buyback_slot.display(GameState.buyback)


## The grid shows at most MAX_ROWS rows, the rest scrolls (the scroll bar sits next to the grid).
func _fit_scroll() -> void:
	if _slot_uis.is_empty():
		return
	var rows: int = ceili(_slot_uis.size() / float(COLUMNS))
	var slot_size: Vector2 = _slot_uis[0].get_combined_minimum_size()
	var bar: float = _grid_scroll.get_v_scroll_bar().get_combined_minimum_size().x if rows > MAX_ROWS else 0.0
	_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if rows > MAX_ROWS else ScrollContainer.SCROLL_MODE_DISABLED
	_grid_scroll.custom_minimum_size = Vector2(slot_size.x * COLUMNS + bar, slot_size.y * mini(rows, MAX_ROWS))


## Today's stock entries (MerchantStock): {"spec", "amount" (-1 = no limit), "price" (0 = from value)}.
func _get_stock() -> Array:
	if _stock_key.is_empty():
		return _offers.map(func(spec: String) -> Dictionary: return {"spec": spec, "amount": MerchantStock.UNLIMITED, "price": 0})
	return GameState.merchant_stock.get_entries(_stock_key, _offers, _stock_id)


## The offers that are for sale right now: {"price", "action"} plus "stack" (items) or
## "icon", "name", "description" (stations, recipes).
func _get_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for stock_entry: Dictionary in _get_stock():
		var spec: String = stock_entry["spec"]
		if spec.begins_with("station:"):
			# Copy: the entry of economy.json gets its id for the purchase report.
			var station: Dictionary = Economy.get_station_offer(spec.get_slice(":", 1)).duplicate()
			if station.is_empty() or GameState.story.has_flag(station.get("flag", "")):
				continue
			station["id"] = spec.get_slice(":", 1)
			if not _is_unlocked(station):
				continue
			entries.append({"spec": spec, "icon": _load_icon(station.get("icon", "")), "name": station.get("name", spec),
					"description": station.get("description", ""), "price": int(station.get("price", 0)),
					"action": _buy_station.bind(station)})
		elif spec.begins_with("recipe:"):
			var recipe_offer: Dictionary = Economy.get_recipe_offer(spec.get_slice(":", 1))
			if recipe_offer.is_empty() or _owns_recipes(recipe_offer) or not _is_unlocked(recipe_offer):
				continue
			# A story phase can sell an offer cheaper (story_limits "prices"), e.g. the copper
			# sword molds while the player has little gold after Bruno's begging.
			var limit_prices: Dictionary = MerchantStock.get_active_limit().get("prices", {})
			if limit_prices.has(spec):
				recipe_offer = recipe_offer.duplicate()
				recipe_offer["price"] = int(limit_prices[spec])
			entries.append({"spec": spec, "icon": _get_recipe_offer_icon(recipe_offer), "name": recipe_offer.get("name", spec),
					"description": recipe_offer.get("description", ""), "price": int(recipe_offer.get("price", 0)),
					"action": _buy_recipe.bind(spec, recipe_offer)})
		elif spec.begins_with("potion_recipe:"):
			# Secret potion recipes (combos, curses, blessings): only the name shows, what goes in
			# is in the recipe book after buying (Enchanting.is_known).
			var potion_offer: Dictionary = Economy.get_potion_recipe_offer(spec.get_slice(":", 1))
			if potion_offer.is_empty() or _knows_potions(potion_offer) or not _is_unlocked(potion_offer):
				continue
			entries.append({"spec": spec, "icon": _get_potion_recipe_icon(potion_offer), "name": potion_offer.get("name", spec),
					"description": Language.translate("Was hineingehört, steht erst nach dem Kauf im Rezeptbuch."),
					"price": int(potion_offer.get("price", 0)), "action": _buy_potion_recipe.bind(spec, potion_offer)})
		elif spec.begins_with("furniture:"):
			var furniture_id: String = spec.get_slice(":", 1)
			var furniture: Dictionary = House.get_furniture(furniture_id)
			if furniture.is_empty() or not _is_unlocked(furniture) or GameState.house.is_furniture_maxed(furniture_id):
				continue
			var owned: int = GameState.house.get_owned(furniture_id)
			var description: String = furniture.get("description", "")
			# Pieces without a bonus (plant pots) don't mention the shop.
			if float(furniture.get("bonus", 0.0)) > 0.0:
				description += Language.translate("\nPreise im eigenen Laden +%s %%") % String.num(float(furniture.get("bonus", 0.0)) * 100.0, 1).trim_suffix(".0")
			if owned > 0:
				description += Language.translate("\nIm Lager: %d") % owned
			entries.append({"spec": spec, "icon": _load_icon(furniture.get("texture", "")), "name": furniture.get("name", furniture_id),
					"description": description, "price": int(furniture.get("price", 0)),
					"action": _buy_furniture.bind(furniture_id)})
		elif spec.begins_with("mold:"):
			var part_id: String = spec.get_slice(":", 1).get_slice("=", 0)
			if not ContentDB.has_item(part_id) or not ContentDB.has_recipe("mold_" + part_id) or _owns_recipes({"unlock": [part_id, "mold_" + part_id]}):
				continue
			var part: ItemData = ContentDB.item(part_id)
			var mold_offer: Dictionary = {"name": Language.translate("Gussform: ") + part.display_name, "price": int(spec.get_slice("=", 1)),
					"unlock": ["mold_" + part_id, part_id]}
			entries.append({"spec": spec, "icon": ItemIcons.mold(part), "name": mold_offer["name"],
					"description": Language.translate("Gussform und Amboss-Rezept (%s)") % Rarity.get_display_name(part.base_rarity),
					"price": mold_offer["price"], "action": _buy_recipe.bind(spec.get_slice("=", 0), mold_offer)})
		else:
			var left: int = int(stock_entry["amount"])
			var stack: InventorySlot = ContentDB.make_stack(spec)
			if stack == null or left == 0:
				continue
			var offer: InventorySlot = stack.copy_with_amount(1)
			var price: int = int(stock_entry["price"]) if int(stock_entry["price"]) > 0 else _get_item_price(offer)
			# The slot shows how many are left.
			var shown: InventorySlot = stack.copy_with_amount(left if left > 0 else 1)
			entries.append({"spec": spec, "stack": shown, "price": price, "left": left, "action": _buy_item.bind(offer, price, stock_entry)})
	return entries


## Creates slot UIs until there are `count`.
func _ensure_slots(count: int) -> void:
	while _slot_uis.size() < count:
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_offer_gui_input.bind(_slot_uis.size()))
		slot_ui.set_drag_forwarding(Callable(), _can_drop_sell, _drop_sell)
		var index: int = _slot_uis.size()
		GuideFrame.attach(slot_ui, func() -> bool: return Guide.is_target("buy:" + _slot_specs[index]))
		_slot_uis.append(slot_ui)
		_slot_actions.append(Callable())
		_slot_specs.append("")


func _price_line(action: String, price: int) -> String:
	var color: String = COLOR_PRICE if action != Language.translate("Kaufen") or GameState.gold >= price else "#" + COLOR_ERROR.to_html(false)
	return Language.translate("[color=%s]%s: %d Gold (Klick)[/color]") % [color, action, price]


## A recipe offer that unlocks a mold shows the mold icon, otherwise its "icon".
func _get_recipe_offer_icon(recipe_offer: Dictionary) -> Texture2D:
	for recipe_id: String in recipe_offer.get("unlock", []):
		if recipe_id.begins_with("mold_") and ContentDB.has_recipe(recipe_id):
			var icon: Texture2D = ContentDB.recipe(recipe_id).get_icon()
			if icon:
				return icon
	return _load_icon(recipe_offer.get("icon", ""))


func _load_icon(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


# --- Buying -------------------------------------------------------------------------

func _on_offer_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if _slot_actions[index].is_valid():
			_slot_actions[index].call()


func _get_item_price(offer: InventorySlot) -> int:
	return maxi(1, roundi(Economy.get_buy_price(offer) * _price_factor))


## Buys one piece for `price`; one less in `stock_entry` (MerchantStock).
func _buy_item(offer: InventorySlot, price: int, stock_entry: Dictionary) -> void:
	if int(stock_entry["amount"]) == 0:
		_show_message(Language.translate("Ausverkauft – morgen gibt es neue Ware."), COLOR_ERROR)
		return
	var bought: InventorySlot = offer.copy_with_amount(1)
	# Check the room first, so nothing is paid when the inventory is full.
	if GameState.inventory.get_free_space(bought) < 1:
		_show_message(Language.translate("Dein Inventar ist voll."), COLOR_ERROR)
		return
	if not GameState.spend_gold(price):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	GameState.inventory.add_stack(bought)
	MerchantStock.take(stock_entry)
	GameState.record_purchase(String(bought.item.id))
	_show_message(Language.translate("%s gekauft.") % bought.get_display_name(), COLOR_OK)
	_refresh()


func _owns_recipes(recipe_offer: Dictionary) -> bool:
	for recipe_id: String in recipe_offer.get("unlock", []):
		if ContentDB.has_recipe(recipe_id) and not GameState.is_recipe_unlocked(ContentDB.recipe(recipe_id)):
			return false
	return true


func _buy_recipe(spec: String, recipe_offer: Dictionary) -> void:
	if not GameState.spend_gold(int(recipe_offer.get("price", 0))):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	for recipe_id: String in recipe_offer.get("unlock", []):
		if ContentDB.has_recipe(recipe_id):
			GameState.unlock_recipe(ContentDB.recipe(recipe_id))
	GameState.record_purchase(spec)
	_show_message(Language.translate("%s gekauft: das Rezept kennst du jetzt.") % recipe_offer.get("name", ""), COLOR_OK)
	_refresh()


## Whether the player knows every potion of a "potion_recipe:" offer already.
static func _knows_potions(potion_offer: Dictionary) -> bool:
	for potion_id: String in potion_offer.get("potions", []):
		if not GameState.story.has_flag(Enchanting.FOUND_FLAG % potion_id):
			return false
	return true


## The icon of the first potion of the offer (its tinted bottle).
func _get_potion_recipe_icon(potion_offer: Dictionary) -> Texture2D:
	var potions: Array = potion_offer.get("potions", [])
	if not potions.is_empty() and ContentDB.has_item(potions[0]):
		return ContentDB.item(potions[0]).icon
	return null


func _buy_potion_recipe(spec: String, potion_offer: Dictionary) -> void:
	if not GameState.spend_gold(int(potion_offer.get("price", 0))):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	for potion_id: String in potion_offer.get("potions", []):
		GameState.story.set_flag(Enchanting.FOUND_FLAG % potion_id)
	GameState.record_purchase(spec)
	GameState.recipes_changed.emit()
	_show_message(Language.translate("%s gekauft: es steht jetzt im Rezeptbuch.") % potion_offer.get("name", ""), COLOR_OK)
	_refresh()


## Whether a station, piece of furniture or recipe is for sale yet: `house_level` = the player's
## house must have this level, `unlock_flag` = this story flag must be set, `rank` = the player
## needs at least this reputation rank (e.g. "E").
static func _is_unlocked(offer: Dictionary) -> bool:
	if GameState.house.level < int(offer.get("house_level", 1)):
		return false
	var rank: String = offer.get("rank", "")
	if not rank.is_empty() and GameState.reputation.get_rank_index() < Reputation.get_rank_index_of(rank):
		return false
	var flag: String = offer.get("unlock_flag", "")
	return flag.is_empty() or GameState.story.has_flag(flag)


## Furniture goes into the storage of the house (GameState.house.owned), placed in the shop.
func _buy_furniture(furniture_id: String) -> void:
	var furniture: Dictionary = House.get_furniture(furniture_id)
	if GameState.house.is_furniture_maxed(furniture_id):
		return
	if not GameState.spend_gold(int(furniture.get("price", 0))):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	GameState.house.add_owned(furniture_id)
	GameState.record_purchase("furniture:" + furniture_id)
	_show_message(KeyBindings.fill(Language.translate("%s gekauft: liegt in deinem Lager. Aufstellen: zu Hause {key_build} drücken.")) % furniture.get("name", ""), COLOR_OK)
	_refresh()


func _buy_station(station: Dictionary) -> void:
	if not GameState.spend_gold(int(station.get("price", 0))):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	GameState.story.set_flag(station.get("flag", ""))
	GameState.record_purchase("station:" + str(station.get("id", "")))
	_show_message(Language.translate("%s gekauft: steht jetzt in deiner Schmiede.") % station.get("name", ""), COLOR_OK)
	_refresh()


# --- Selling and buyback --------------------------------------------------------------

## Sells `amount` pieces of an inventory slot (at most the whole stack); they go into the
## buyback slot (stacked onto what is there if it is the same item for the same price).
func _sell(index: int, amount: int) -> void:
	var stack: InventorySlot = GameState.inventory.slots[index]
	var price: int = Economy.get_sell_price(stack)
	amount = mini(amount, stack.amount)
	if price <= 0 or amount <= 0:
		_show_message(Language.translate("Das kauft der Händler nicht."), COLOR_ERROR)
		return
	if stack.is_quiver() and not _empty_quiver(stack):
		_show_message(Language.translate("Im Inventar ist kein Platz für die Pfeile aus dem Köcher."), COLOR_ERROR)
		_refresh()
		return
	var sold: InventorySlot = stack.copy_with_amount(amount)
	if not GameState.buyback.is_empty() and GameState.buyback.can_stack_with(sold) and GameState.buyback_price == price:
		GameState.buyback.add_from(sold, amount)
	else:
		GameState.buyback = sold
		GameState.buyback_price = price
	GameState.inventory.remove_from_slot(index, amount)
	GameState.add_gold(price * amount)
	var name: String = sold.get_display_name() if amount == 1 else "%dx %s" % [amount, sold.get_display_name()]
	_show_message(Language.translate("%s verkauft: +%d Gold.") % [name, price * amount], COLOR_OK)
	_refresh()


## Puts the arrows of a quiver into the inventory (the dealer buys only the quiver). false if some
## did not fit; those stay in the quiver.
func _empty_quiver(quiver: InventorySlot) -> bool:
	var everything_fit: bool = true
	for place: InventorySlot in quiver.get_quiver_slots():
		if place.is_empty():
			continue
		place.amount = GameState.inventory.add_stack(place)
		if place.is_empty():
			place.clear()
		else:
			everything_fit = false
	return everything_fit


## Right click on an inventory item: sell it (whole stack, Ctrl: one piece, Shift: half).
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var stack: InventorySlot = GameState.inventory.slots[inventory_index]
	if stack.is_empty():
		return false
	_sell(inventory_index, stack.amount if amount < 0 else amount)
	return true


func _can_drop_sell(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_index")


func _drop_sell(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	_sell(index, GameState.inventory.slots[index].amount)


## Click on the buyback slot: buy the last sold stack back for what the merchant paid
## (Ctrl: one piece, Shift: half).
func _on_buyback_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]):
		return
	if GameState.buyback.is_empty():
		return
	var amount: int = GameState.buyback.amount
	if mouse_event.ctrl_pressed:
		amount = 1
	elif mouse_event.shift_pressed:
		amount = ceili(GameState.buyback.amount / 2.0)
	_buy_back(amount)


func _buy_back(amount: int) -> void:
	var piece: InventorySlot = GameState.buyback.copy_with_amount(amount)
	if GameState.inventory.get_free_space(piece) < amount:
		_show_message(Language.translate("Dein Inventar ist voll."), COLOR_ERROR)
		return
	if not GameState.spend_gold(GameState.buyback_price * amount):
		_show_message(Language.translate("Du hast nicht genug Gold."), COLOR_ERROR)
		return
	GameState.inventory.add_stack(piece)
	GameState.buyback.amount -= amount
	if GameState.buyback.amount <= 0:
		GameState.buyback.clear()
		GameState.buyback_price = 0
	_show_message(Language.translate("%s zurückgekauft.") % piece.get_display_name(), COLOR_OK)
	_refresh()


func _show_message(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
