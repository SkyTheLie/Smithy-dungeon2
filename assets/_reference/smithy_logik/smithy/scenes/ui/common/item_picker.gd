class_name ItemPicker
extends CanvasLayer
## Selection list for an item slot of a station window (forge ingots, workbench parts, crystals at
## the enchanting table, mortar, jeweler ...): a click on the slot opens a list of every matching
## stack the player has (inventory, and at home the chests: GameState.get_crafting_extras), equal
## stacks merged with their total amount, highest rarity first, then quality (leather: highest armor
## value first, then rarity and quality). A click on an entry
## hands it to the window (`on_pick`), "Herausnehmen" empties the slot (`on_remove`), a click beside
## the list closes it. Only one picker is open at a time. It lives on its own CanvasLayer, one layer
## above the highest window (WindowTitleBar._top_layer), so it is never covered.
##
## Use:
##   var entries := ItemPicker.collect(func(slot: InventorySlot) -> bool: return <fits>)
##   ItemPicker.open(self, slot_ui, "Kristall wählen", entries, not placed.is_empty(),
##       func(entry: Dictionary) -> void: ItemPicker.take(entry, 1, placed); _refresh(),
##       func() -> void: _return_stack(placed); _refresh())

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const FONT_SIZE: int = 11
const COLOR_MISSING: Color = Color(0.9, 0.45, 0.4)

static var _current: ItemPicker

var _panel: PanelContainer


## Every stack `accepts` takes (not glowing, not empty), merged when they stack:
## [{"slot": InventorySlot (a copy with the total amount), "sources": [[Inventory, index], ...],
## "in_chest": bool}], highest rarity first, then highest quality, then name; leather by its armor
## value first.
static func collect(accepts: Callable, with_chests: bool = true) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var sources: Array[Inventory] = [GameState.inventory]
	if with_chests:
		sources.append_array(GameState.get_crafting_extras())
	for source in sources:
		for i in source.slots.size():
			var slot: InventorySlot = source.slots[i]
			if slot.is_empty() or slot.hot or not accepts.call(slot):
				continue
			var entry: Dictionary = {}
			for existing in entries:
				if (existing["slot"] as InventorySlot).can_stack_with(slot):
					entry = existing
					break
			if entry.is_empty():
				entry = {"slot": slot.copy_with_amount(0), "sources": [], "in_chest": false}
				entries.append(entry)
			(entry["slot"] as InventorySlot).amount += slot.amount
			entry["sources"].append([source, i])
			if source != GameState.inventory:
				entry["in_chest"] = true
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var slot_a: InventorySlot = a["slot"]
		var slot_b: InventorySlot = b["slot"]
		# Leather: the highest armor value first (lichen before seal before wolf), then as usual.
		if _is_leather(slot_a) and _is_leather(slot_b) and slot_a.item.armor != slot_b.item.armor:
			return slot_a.item.armor > slot_b.item.armor
		if slot_a.rarity != slot_b.rarity:
			return slot_a.rarity > slot_b.rarity
		if slot_a.quality != slot_b.quality:
			return slot_a.quality > slot_b.quality
		return slot_a.get_display_name() < slot_b.get_display_name())
	return entries


static func _is_leather(slot: InventorySlot) -> bool:
	return slot.item != null and slot.item.part_type == ItemData.PartType.LEATHER


## Moves up to `amount` pieces of the entry into `into` (from the inventory first, then the
## chests); `into` must be empty or stack with the entry. Returns how many were moved.
static func take(entry: Dictionary, amount: int, into: InventorySlot) -> int:
	var sample: InventorySlot = entry["slot"]
	var moved: int = 0
	for source_entry: Array in entry["sources"]:
		if moved >= amount:
			break
		var source: Inventory = source_entry[0]
		var slot_index: int = source_entry[1]
		var slot: InventorySlot = source.slots[slot_index]
		if slot.is_empty() or not slot.can_stack_with(sample):
			continue
		var count: int = mini(slot.amount, amount - moved)
		if into.is_empty():
			into.copy_properties_from(slot)
			into.amount = count
		else:
			into.amount += count
		source.remove_from_slot(slot_index, count)
		moved += count
	return moved


## Opens the list next to `anchor` (a slot; null = screen centre). `has_content`: the slot holds
## something, so "Herausnehmen" is offered.
static func open(host: Node, anchor: Control, title: String, entries: Array[Dictionary], has_content: bool,
		on_pick: Callable, on_remove: Callable = Callable(),
		empty_text: String = "") -> ItemPicker:
	close_current()
	var picker := ItemPicker.new()
	host.add_child(picker)
	_current = picker
	picker._build(anchor, title, entries, has_content, on_pick, on_remove,
			empty_text if not empty_text.is_empty() else Language.translate("Nichts Passendes dabei."))
	return picker


static func close_current() -> void:
	if is_instance_valid(_current):
		_current.close()
	_current = null


static func is_open() -> bool:
	return is_instance_valid(_current)


func close() -> void:
	if _current == self:
		_current = null
	if get_tree() and get_tree().process_frame.is_connected(_keep_on_top):
		get_tree().process_frame.disconnect(_keep_on_top)
	queue_free()


func _exit_tree() -> void:
	if _current == self:
		_current = null
	if get_tree() and get_tree().process_frame.is_connected(_keep_on_top):
		get_tree().process_frame.disconnect(_keep_on_top)


## The host window got hidden (closed): the list goes with it.
func _process(_delta: float) -> void:
	var host := get_parent() as CanvasItem
	if host and not host.is_visible_in_tree():
		close()


func _build(anchor: Control, title: String, entries: Array[Dictionary], has_content: bool,
		on_pick: Callable, on_remove: Callable, empty_text: String) -> void:
	_keep_on_top()
	get_tree().process_frame.connect(_keep_on_top)
	var backdrop := Control.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed:
			close())
	add_child(backdrop)
	_panel = PanelContainer.new()
	backdrop.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_panel.add_child(column)
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", FONT_SIZE)
	column.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = empty_text
		empty.add_theme_font_size_override("font_size", FONT_SIZE)
		empty.add_theme_color_override("font_color", COLOR_MISSING)
		list.add_child(empty)
	for entry in entries:
		var row_button: Button = _create_row(entry, on_pick)
		list.add_child(row_button)
		# Sized once in the tree (the theme's font decides the label size).
		row_button.custom_minimum_size = (row_button.get_child(0) as Control).get_combined_minimum_size() + Vector2(6, 2)
	if has_content and on_remove.is_valid():
		var back := Button.new()
		back.focus_mode = Control.FOCUS_NONE
		back.text = Language.translate("Herausnehmen")
		back.add_theme_font_size_override("font_size", FONT_SIZE)
		back.pressed.connect(func() -> void:
			close()
			on_remove.call())
		column.add_child(back)
	# Size it (the list scrolls above 60 % of the screen) and place it right of the slot, on screen.
	var screen: Vector2 = backdrop.get_viewport_rect().size
	var list_size: Vector2 = list.get_combined_minimum_size()
	scroll.custom_minimum_size = Vector2(list_size.x + 8, minf(list_size.y, screen.y * 0.6))
	var panel_size: Vector2 = _panel.get_combined_minimum_size()
	var at: Vector2 = screen / 2.0 - panel_size / 2.0
	if anchor:
		at = anchor.get_global_rect().position + Vector2(anchor.size.x + 4, 0)
	at.x = clampf(at.x, 0.0, maxf(screen.x - panel_size.x, 0.0))
	at.y = clampf(at.y, 0.0, maxf(screen.y - panel_size.y, 0.0))
	_panel.position = at


## One row: the stack (slot with rarity frame, amount, quality), name and rarity in its colour.
func _create_row(entry: Dictionary, on_pick: Callable) -> Button:
	var slot: InventorySlot = entry["slot"]
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = Vector2(2, 1)
	button.add_child(row)
	var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	slot_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_ui.ready.connect(func() -> void: slot_ui.display(slot), CONNECT_ONE_SHOT)
	slot_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slot_ui)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Rarity.get_color(slot.rarity))
	label.text = "%s  ×%d\n%s" % [slot.get_display_name(), slot.amount, ForgeQuality.describe(slot.rarity, slot.quality)]
	if entry["in_chest"]:
		label.text += Language.translate(" (Truhe)")
	row.add_child(label)
	button.pressed.connect(func() -> void:
		close()
		on_pick.call(entry))
	return button


## Every window click raises that window's layer (WindowTitleBar.bring_to_front, also the click
## that opened the picker): the picker stays one layer above the highest window.
func _keep_on_top() -> void:
	layer = WindowTitleBar._top_layer + 1
