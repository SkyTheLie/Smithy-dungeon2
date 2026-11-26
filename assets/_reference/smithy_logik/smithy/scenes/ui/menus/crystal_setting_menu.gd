class_name CrystalSettingMenu
extends StationMenu
## Window of the true setting on the Altar of the Nine (after the story, AltarCrystals): one slot
## per holy crystal, laid out around the setting like the pillars stand around the altar (each slot
## in the direction of its pillar, from AltarElements.get_pillar_layout). A click on a full slot
## takes the crystal into the inventory, on an empty one puts it back from the inventory; a right
## click on a crystal in the inventory puts it back as well (try_quick_move).

## AltarElements of the altar scene (elements and where their pillars stand).
@export var elements_path: NodePath

const SLOT_SIZE := Vector2(26, 26)
## How far the slots lie from the middle of the ring at most (x, y), like the pillars around the altar.
const RADIUS := Vector2(66, 48)
const EMPTY_ICON: Color = Color(1, 1, 1, 0.22)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_OK: Color = Color(0.55, 0.85, 0.5)

## Element of each slot button (same order as the buttons in the ring).
var _elements: PackedStringArray = []
var _slots: Array[Button] = []

@onready var _ring: Control = %Ring
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	GameState.inventory.changed.connect(_queue_refresh)
	GameState.story.changed.connect(_queue_refresh)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if _slots.is_empty():
		_build_slots()
	_message_label.text = ""
	show()
	_refresh()


## Element of each slot in order (for tests).
func get_slot_elements() -> PackedStringArray:
	return _elements


## Middle of a slot, seen from the middle of the ring (for tests).
func get_slot_offset(element: String) -> Vector2:
	var index: int = _elements.find(element)
	if index < 0:
		return Vector2.ZERO
	return _slots[index].position + SLOT_SIZE / 2.0 - _ring.custom_minimum_size / 2.0


## Clicks a slot (also for tests).
func press_slot(element: String) -> void:
	var item: ItemData = AltarCrystals.item_of(element)
	var crystal_name: String = item.display_name if item else element
	if AltarCrystals.is_in_setting(element):
		var error: String = AltarCrystals.take_out(element)
		if error.is_empty():
			_show(Language.translate(AltarCrystals.TEXT_TAKEN) % crystal_name, COLOR_OK)
		else:
			_show(Language.translate(error), COLOR_ERROR)
	else:
		var error: String = AltarCrystals.put_back(element)
		if error.is_empty():
			_show(Language.translate(AltarCrystals.TEXT_PUT_BACK) % crystal_name, COLOR_OK)
		else:
			_show(Language.translate(error), COLOR_ERROR)
	_refresh()


func _build_slots() -> void:
	var elements := get_node_or_null(elements_path) as AltarElements
	if elements == null:
		return
	var layout: Array[Dictionary] = elements.get_pillar_layout()
	# the slots lie like the pillars: the farthest pillar sideways / up or down sits on the radius
	var reach := Vector2(1, 1)
	for entry in layout:
		var offset: Vector2 = entry["offset"]
		reach = Vector2(maxf(reach.x, absf(offset.x)), maxf(reach.y, absf(offset.y)))
	var middle: Vector2 = _ring.custom_minimum_size / 2.0
	for entry in layout:
		var element: String = entry["element"]
		var offset: Vector2 = entry["offset"]
		var button := Button.new()
		button.custom_minimum_size = SLOT_SIZE
		button.size = SLOT_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.position = middle + Vector2(offset.x / reach.x * RADIUS.x, offset.y / reach.y * RADIUS.y) - SLOT_SIZE / 2.0
		_style_slot(button, AltarElements.COLORS.get(element, Color.WHITE))
		var item: ItemData = AltarCrystals.item_of(element)
		button.icon = item.icon if item else null
		button.pressed.connect(press_slot.bind(element))
		_ring.add_child(button)
		_slots.append(button)
		_elements.append(element)


## A dark slot with a frame in the colour of the element.
func _style_slot(button: Button, color: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.08, 0.07, 0.1, 0.9) if state != "hover" else Color(0.16, 0.14, 0.2, 0.95)
		box.border_color = color if state != "disabled" else color.darkened(0.5)
		box.set_border_width_all(1)
		box.set_corner_radius_all(2)
		box.set_content_margin_all(1)
		button.add_theme_stylebox_override(state, box)


func _refresh() -> void:
	_refresh_done()
	if not AltarCrystals.is_open():
		close()
		return
	for index in _slots.size():
		var element: String = _elements[index]
		var button: Button = _slots[index]
		var item: ItemData = AltarCrystals.item_of(element)
		var crystal_name: String = item.display_name if item else element
		var inside: bool = AltarCrystals.is_in_setting(element)
		var carried: bool = item != null and GameState.inventory.count_item(item) > 0
		var tint: Color = Color.WHITE if inside else EMPTY_ICON
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_disabled_color"]:
			button.add_theme_color_override(state, tint)
		if inside:
			button.tooltip_text = crystal_name + "\n" + Language.translate("Klicken: ins Inventar nehmen")
		elif carried:
			button.tooltip_text = crystal_name + "\n" + Language.translate("Klicken: zurück in die Fassung setzen")
		else:
			button.tooltip_text = crystal_name + "\n" + Language.translate("Der Kristall ist nicht in der Fassung und nicht in deinem Inventar.")


func _show(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)


## Right click on a holy crystal in the inventory: back into its place in the setting.
func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	if not visible:
		return false
	var stack: InventorySlot = GameState.inventory.slots[inventory_index]
	if stack.is_empty():
		return false
	var element: String = AltarCrystals.element_of(stack.item, _elements)
	if element.is_empty() or AltarCrystals.is_in_setting(element):
		return false
	press_slot(element)
	return true
