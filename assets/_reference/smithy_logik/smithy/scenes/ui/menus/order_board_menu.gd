class_name OrderBoardMenu
extends StationMenu
## Order board in front of the smithy: all accepted customer orders (soonest deadline first).
## Every order has a slot: drag the wanted item in (or right-click it in the inventory - it goes
## into the first empty slot of an order it matches). Only matching items are accepted
## (CustomerOrder.matches). "Abgeben" then pays gold and EXP and raises the reputation
## (GameState.complete_order). Clicking a slot or closing the window puts the item back.
## Guide target "order:slot": the empty slot of an order glows while a fitting item is in the
## inventory, then its "Abgeben" button.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_REWARD: Color = Color(0.55, 0.85, 0.45)
const COLOR_URGENT: Color = Color(0.9, 0.4, 0.35)
## Alpha of the wanted item's icon shown in an empty slot.
const GHOST_ALPHA: float = 0.3

## Items lying in the order slots: CustomerOrder -> InventorySlot (amount 1).
var _held: Dictionary = {}

@onready var _list: VBoxContainer = %OrderList
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	GameState.customers.changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _on_visibility_changed() -> void:
	if visible:
		_message_label.text = ""
		_refresh()
	else:
		_return_all()


func _refresh() -> void:
	if not visible:
		return
	_return_items_of_gone_orders()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var orders: Array[CustomerOrder] = _get_sorted_orders()
	if orders.is_empty():
		_list.add_child(_create_label(Language.translate("Keine offenen Aufträge. Kunden warten tagsüber vor der Schmiede."), COLOR_HINT))
	for order in orders:
		_list.add_child(_create_row(order))


func _get_sorted_orders() -> Array[CustomerOrder]:
	var orders: Array[CustomerOrder] = GameState.customers.orders.duplicate()
	orders.sort_custom(func(a: CustomerOrder, b: CustomerOrder) -> bool: return a.deadline_day < b.deadline_day)
	return orders


func _create_row(order: CustomerOrder) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_create_slot(order))
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(_create_label(order.get_title(), Rarity.get_color(order.rarity)))
	texts.add_child(_create_label(order.get_parts_text(), COLOR_HINT))
	var days: int = order.days_left(GameState.day_cycle.day)
	var deadline: String = Language.translate("%s · bis %s (%s)") % [order.customer_name, GameCalendar.get_short_text(order.deadline_day),
			CustomerOrder.get_days_left_text(days)]
	texts.add_child(_create_label(deadline, COLOR_URGENT if days <= 0 else COLOR_HINT))
	texts.add_child(_create_label(Language.translate("%d Gold, %d PEXP") % [order.gold, order.experience], COLOR_REWARD))
	row.add_child(texts)
	var button := Button.new()
	button.text = Language.translate("Abgeben")
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = not _held.has(order)
	button.tooltip_text = "" if not button.disabled else Language.translate("Lege den gewünschten Gegenstand in den Slot.")
	button.pressed.connect(_on_turn_in_pressed.bind(order))
	GuideFrame.attach(button, func() -> bool: return _held.has(order) and Guide.is_target("order:slot"))
	row.add_child(button)
	return row


## Slot of one order: shows the held item, or the wanted item faded when empty.
func _create_slot(order: CustomerOrder) -> ItemSlotUI:
	var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	slot_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(order), _drop_into.bind(order))
	slot_ui.gui_input.connect(_on_slot_gui_input.bind(order))
	# display() needs the slot's @onready nodes, so wait until it is in the tree.
	slot_ui.ready.connect(_display_slot.bind(slot_ui, order))
	GuideFrame.attach(slot_ui, func() -> bool:
		return not _held.has(order) and Guide.is_target("order:slot") and GameState.inventory.slots.any(order.matches))
	return slot_ui


func _display_slot(slot_ui: ItemSlotUI, order: CustomerOrder) -> void:
	if _held.has(order):
		slot_ui.display(_held[order])
		return
	var wanted := InventorySlot.new()
	wanted.item = order.item
	wanted.amount = 1
	wanted.components = order.parts.duplicate()
	var tooltip: String = Language.translate("[color=#%s]%s[/color]\n%s\nHier hineinziehen.") % [
			Rarity.get_color(order.rarity).to_html(false), order.get_title(), order.get_parts_text()]
	slot_ui.display_custom(wanted.get_icon(), tooltip)
	slot_ui.get_node("Icon").modulate.a = GHOST_ALPHA


func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index}
	for order in _get_sorted_orders():
		if _can_drop_into(Vector2.ZERO, data, order):
			_drop_into(Vector2.ZERO, data, order)
			return true
	return false


func _can_drop_into(_at_position: Vector2, data: Variant, order: CustomerOrder) -> bool:
	if not (data is Dictionary and data.has("inventory_index")) or _held.has(order):
		return false
	return order.matches(GameState.inventory.slots[data["inventory_index"]])


func _drop_into(_at_position: Vector2, data: Variant, order: CustomerOrder) -> void:
	var index: int = data["inventory_index"]
	_held[order] = GameState.inventory.slots[index].copy_with_amount(1)
	GameState.inventory.remove_from_slot(index, 1)
	_message_label.text = ""
	_refresh()


func _on_slot_gui_input(event: InputEvent, order: CustomerOrder) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if _return_item(order):
			_refresh()


func _on_turn_in_pressed(order: CustomerOrder) -> void:
	if not _held.has(order):
		return
	var order_title: String = order.get_title()
	# Out of the slot first: completing the order refreshes this window, which would give items of
	# finished orders back (_return_items_of_gone_orders).
	var item: InventorySlot = _held[order]
	_held.erase(order)
	if GameState.complete_order(order, item):
		_message_label.text = Language.translate("%s abgegeben: %d Gold, %d PEXP.") % [order_title, order.gold, order.experience]
		_message_label.add_theme_color_override("font_color", COLOR_REWARD)
	else:
		_held[order] = item
	_refresh()


## Puts the item of `order` back into the inventory. Returns false if there was none or the
## inventory is full (then it stays in the slot).
func _return_item(order: CustomerOrder) -> bool:
	if not _held.has(order):
		return false
	var item: InventorySlot = _held[order]
	if GameState.inventory.get_free_space(item) < item.amount:
		_message_label.text = Language.translate("Kein Platz im Inventar.")
		_message_label.add_theme_color_override("font_color", COLOR_URGENT)
		return false
	GameState.inventory.add_stack(item)
	_held.erase(order)
	return true


func _return_all() -> void:
	for order in _held.keys():
		_return_item(order)


## Orders can vanish while the window is open (e.g. expired): give their items back.
func _return_items_of_gone_orders() -> void:
	for order in _held.keys():
		if not GameState.customers.orders.has(order):
			_return_item(order)


func _create_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	return label
