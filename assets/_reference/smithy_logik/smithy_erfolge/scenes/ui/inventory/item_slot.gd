class_name ItemSlotUI
extends Panel
## Displays one InventorySlot (icon + amount). Hover shows an ItemTooltip. The inner line of the
## frame has the rarity colour (Rarity.COLORS), forged things show their quality top left.
## If inventory_index is set, the slot can be dragged onto drop targets (e.g. the smelter)
## and onto other inventory slots (hotbar <-> bag) to move, stack or swap items.
## A right click puts the item into the matching slot of the open station window
## (Ctrl + right click: only one piece, Shift + right click: half the stack).
## Inventory slots get a golden frame (GuideFrame) while the story guide points at their item
## ("inv:<item id>", Guide), e.g. the copper ore for the first smelting.

## Tint of the icon for glowing (hot) items.
const COLOR_HOT: Color = Color(1.0, 0.55, 0.3)

## Index in GameState.inventory this UI shows. -1 = not an inventory slot (no dragging).
var inventory_index: int = -1
## Slots of station windows (smelter, trough, chests ...): the item can be dragged onto the
## inventory; dropping it there acts like a click on this slot, so the window's own click
## handler takes it back (same rules as clicking).
var drag_out: bool = false

## Lines (BBCode) added at the end of the item tooltip, e.g. a price in a shop.
var extra_tooltip: String = ""
## Faint picture while the slot is empty, showing what goes in (e.g. a flame on fuel slots).
var placeholder: Texture2D
## Tooltip of the empty slot (e.g. "Brennstoff: Holz oder Kohle").
var placeholder_tooltip: String = ""
## The shown stack is only a faded hint of what goes in (workbench): no rarity frame, no quality.
var hint_only: bool = false

## Tint of the placeholder picture.
const COLOR_PLACEHOLDER: Color = Color(1.0, 1.0, 1.0, 0.35)
## Frame of the 28x28 slot: inside it the icon area is 24x24 (a 24x24 icon fills it, smaller
## ones like 12x12 or 16x16 sit in its middle).
const ICON_INSET: Vector2 = Vector2(2, 2)
## A right click on this item opens the crystal map window.
const CRYSTAL_MAP_ITEM: StringName = &"crystal_map"
## A right click on this item shows or hides the desert compass (CompassOverlay).
const COMPASS_ITEM: StringName = &"desert_compass"
## A right click on this item opens the sand map of the desert (DesertMapWindow).
const DESERT_MAP_ITEM: StringName = &"desert_map"
## A right click on this item opens the map of the storm paths (StormMapWindow).
const STORM_MAP_ITEM: StringName = &"storm_map"

## Slot currently shown (for the tooltip).
var _slot: InventorySlot
## Tooltip (BBCode) of something that is not an item (display_custom, e.g. a station offer).
var _custom_tooltip: String = ""

@onready var _icon: TextureRect = $Icon
@onready var _amount_label: Label = $AmountLabel
@onready var _quality_label: Label = $QualityLabel


func _ready() -> void:
	GuideFrame.attach(self, func() -> bool:
		return inventory_index >= 0 and _slot != null and not _slot.is_empty() and Guide.is_target("inv:" + String(_slot.item.id)))


func display(slot: InventorySlot) -> void:
	_slot = slot
	_custom_tooltip = ""
	_icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	if slot.is_empty():
		_icon.texture = placeholder
		_center_icon()
		_icon.modulate = COLOR_PLACEHOLDER
		_amount_label.text = ""
		_quality_label.text = ""
		tooltip_text = placeholder_tooltip
		queue_redraw()
		return
	_icon.texture = slot.get_icon()
	_center_icon()
	_icon.modulate = COLOR_HOT if slot.hot else Color.WHITE
	_amount_label.text = str(slot.amount) if slot.amount > 1 else ""
	_quality_label.text = str(slot.quality) if slot.has_quality() and not hint_only else ""
	queue_redraw()
	# Any non-empty text enables the tooltip; its content comes from _make_custom_tooltip().
	tooltip_text = slot.get_display_name()


## Rarity frame: the inner pixel line of the 2 px slot frame (slot.png), drawn as four 1 px
## rects so it stays sharp.
func _draw() -> void:
	if _slot == null or _slot.is_empty() or hint_only:
		return
	var color: Color = Rarity.get_color(_slot.rarity)
	var inner: Rect2 = Rect2(Vector2.ONE, size - Vector2(2, 2))
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), color)
	draw_rect(Rect2(inner.position + Vector2(0, inner.size.y - 1), Vector2(inner.size.x, 1)), color)
	draw_rect(Rect2(inner.position, Vector2(1, inner.size.y)), color)
	draw_rect(Rect2(inner.position + Vector2(inner.size.x - 1, 0), Vector2(1, inner.size.y)), color)


## Icon in its own size, centred in the slot (24x24 icon: 2 px margin, 16x16: 6 px, 12x12: 8 px).
func _center_icon() -> void:
	# Before the first layout the slot has no size yet.
	var slot_size: Vector2 = size if size != Vector2.ZERO else custom_minimum_size
	var icon_size: Vector2 = _icon.texture.get_size() if _icon.texture else slot_size - ICON_INSET * 2.0
	_icon.size = icon_size
	_icon.position = ((slot_size - icon_size) / 2.0).floor()


## Shows something that is not an item (e.g. a station or recipe in a shop): icon scaled
## into the slot and a tooltip with `tooltip_bbcode`; `amount_text` in the corner like an amount.
func display_custom(icon: Texture2D, tooltip_bbcode: String, amount_text: String = "") -> void:
	_slot = null
	_custom_tooltip = tooltip_bbcode
	_icon.texture = icon
	_icon.modulate = Color.WHITE
	# Before the first layout the slot has no size yet.
	var slot_size: Vector2 = size if size != Vector2.ZERO else custom_minimum_size
	var area: Vector2 = slot_size - ICON_INSET * 2.0
	if icon == null or (icon.get_width() <= area.x and icon.get_height() <= area.y):
		# Fits the icon area: in its own size and centred, like an item.
		_icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_SCALE
		_center_icon()
	else:
		# Bigger pictures (furniture, stations) shrink into the icon area. Expand mode first: with
		# EXPAND_KEEP_SIZE the icon can't get smaller than its picture and would stick out.
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.position = ICON_INSET
		_icon.size = area
	_amount_label.text = amount_text
	_quality_label.text = ""
	tooltip_text = tooltip_bbcode
	queue_redraw()


func _make_custom_tooltip(_for_text: String) -> Object:
	if not _custom_tooltip.is_empty():
		return RichTooltip.create(_custom_tooltip, "", ItemTooltip.WIDTH)
	if _slot == null or _slot.is_empty():
		return null
	return ItemTooltip.create(_slot, extra_tooltip)


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	var right_click: bool = mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT
	if inventory_index >= 0 and right_click:
		_quick_move(_get_quick_move_amount(mouse_event))
		accept_event()


## How many pieces a right click moves: Ctrl = 1, Shift = half (rounded up),
## -1 = no modifier (the menu decides, usually the whole stack).
func _get_quick_move_amount(mouse_event: InputEventMouseButton) -> int:
	var slot: InventorySlot = GameState.inventory.slots[inventory_index]
	if mouse_event.ctrl_pressed:
		return 1
	if mouse_event.shift_pressed:
		return ceili(slot.amount / 2.0)
	return -1


## Offers the item to every open station menu until one takes it, then to the open
## equipment windows (they put it on and swap out the old piece).
func _quick_move(amount: int) -> void:
	for node in get_tree().get_nodes_in_group(StationMenu.QUICK_MOVE_GROUP):
		var menu := node as StationMenu
		if menu and menu.visible and menu.try_quick_move(inventory_index, amount):
			return
	for node in get_tree().get_nodes_in_group(EquipmentDoll.QUICK_EQUIP_GROUP):
		var window := node as Control
		if window and window.is_visible_in_tree() and window.call("try_quick_equip", inventory_index):
			return
	# Nobody took it: a book opens the recipe book (e.g. Aurelius' book at "Mörser"), the crystal
	# map, the desert compass and the sand map their windows.
	var item: ItemData = GameState.inventory.slots[inventory_index].item
	if item and PlayerStats.BOOK_TABS.has(item.id):
		Events.recipe_book_requested.emit(Language.translate(PlayerStats.BOOK_TABS[item.id]))
	elif item and item.id == CRYSTAL_MAP_ITEM:
		Events.crystal_map_requested.emit()
	elif item and item.id == COMPASS_ITEM:
		Events.compass_requested.emit()
	elif item and item.id == DESERT_MAP_ITEM:
		Events.desert_map_requested.emit()
	elif item and item.id == STORM_MAP_ITEM:
		Events.storm_map_requested.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory_index < 0:
		if not drag_out or _slot == null or _slot.is_empty():
			return null
		_set_preview(_slot)
		return {"take_back_from": self}
	var slot: InventorySlot = GameState.inventory.slots[inventory_index]
	if slot.is_empty():
		return null
	_set_preview(slot)
	return {"inventory_index": inventory_index}


func _set_preview(slot: InventorySlot) -> void:
	var preview := TextureRect.new()
	preview.texture = slot.get_icon()
	set_drag_preview(preview)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if inventory_index < 0 or not data is Dictionary:
		return false
	if data.has("take_back_from"):
		return is_instance_valid(data["take_back_from"])
	return data.has("inventory_index") and data["inventory_index"] != inventory_index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.has("take_back_from"):
		(data["take_back_from"] as ItemSlotUI).take_back()
		return
	GameState.inventory.move_slot(data["inventory_index"], inventory_index)


## A station slot was dragged onto the inventory: a click on it takes the item back.
func take_back() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	gui_input.emit(click)
