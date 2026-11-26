class_name HandInSlots
extends HBoxContainer
## Slots for handing things in (story dialogues with take_items / hand_in_set, quests): one slot per
## wanted thing (GameState.get_hand_in_requests / get_quest_hand_in). The player drags items from
## the inventory in (or right-clicks them there, see try_quick_move); an empty slot shows the
## wanted item faded, the label under it "have/need". Clicking a slot puts its items back,
## return_all() (window closed) puts everything back. The stacks are handed in with
## GameState.run_with_hand_in(get_stacks(), ...).

signal changed

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
## Alpha of the wanted item's icon in an empty slot.
const GHOST_ALPHA: float = 0.3
const FONT_SIZE: int = 11
const COLOR_MISSING: Color = Color(0.62, 0.6, 0.56)
const COLOR_ENOUGH: Color = Color(0.55, 0.85, 0.45)

## {"name", "amount", "icon", "accepts"} per slot.
var _requests: Array[Dictionary] = []
## Per slot: the stacks lying in it (several if they don't stack, e.g. two rarities).
var _held: Array[Array] = []
var _slot_uis: Array[ItemSlotUI] = []
var _labels: Array[Label] = []


func _init() -> void:
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER
	hide()


## New slots for `requests` (empty = no slots, hidden). Items still lying in the old ones go back.
func setup(requests: Array[Dictionary]) -> void:
	return_all()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_requests = requests
	_held.clear()
	_slot_uis.clear()
	_labels.clear()
	for i in requests.size():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		slot_ui.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(i), _drop_into.bind(i))
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		# display() needs the slot's @onready nodes: refresh once it is ready.
		slot_ui.ready.connect(_refresh_slot.bind(i), CONNECT_ONE_SHOT)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(slot_ui)
		box.add_child(label)
		add_child(box)
		_held.append([])
		_slot_uis.append(slot_ui)
		_labels.append(label)
	visible = not requests.is_empty()
	_refresh()


## true when every slot holds as many pieces as wanted.
func is_complete() -> bool:
	for i in _requests.size():
		if _get_amount(i) < int(_requests[i]["amount"]):
			return false
	return true


## The stacks lying in the slots (the same objects: what the hand-in takes is gone from the slots).
func get_stacks() -> Array[InventorySlot]:
	var stacks: Array[InventorySlot] = []
	for held in _held:
		for stack: InventorySlot in held:
			stacks.append(stack)
	return stacks


## Puts everything back into the inventory (what does not fit stays in its slot).
func return_all() -> void:
	for i in _held.size():
		_return(i)
	_refresh()


## Right click on an inventory item: into the first slot that wants it.
func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	if not visible:
		return false
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	for i in _requests.size():
		if _can_drop_into(Vector2.ZERO, data, i):
			_drop_into(Vector2.ZERO, data, i)
			return true
	return false


func _can_drop_into(_at_position: Vector2, data: Variant, index: int) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	var accepts: Callable = _requests[index]["accepts"]
	return not source.is_empty() and _get_amount(index) < int(_requests[index]["amount"]) and accepts.call(source)


func _drop_into(_at_position: Vector2, data: Variant, index: int) -> void:
	var inventory_index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var amount: int = mini(StationMenu.get_move_amount(data, source), int(_requests[index]["amount"]) - _get_amount(index))
	var moved: InventorySlot = source.copy_with_amount(amount)
	var merged: bool = false
	for stack: InventorySlot in _held[index]:
		if stack.can_stack_with(moved):
			stack.add_from(moved, amount)
			merged = true
			break
	if not merged:
		_held[index].append(moved)
	GameState.inventory.remove_from_slot(inventory_index, amount)
	_refresh()


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_return(index)
		_refresh()


## Puts the stacks of one slot back into the inventory; what does not fit stays.
func _return(index: int) -> void:
	var kept: Array[InventorySlot] = []
	for stack: InventorySlot in _held[index]:
		if stack.is_empty():
			continue
		var leftover: int = GameState.inventory.add_stack(stack)
		if leftover > 0:
			stack.amount = leftover
			kept.append(stack)
	_held[index] = kept


func _get_amount(index: int) -> int:
	var amount: int = 0
	for stack: InventorySlot in _held[index]:
		if not stack.is_empty():
			amount += stack.amount
	return amount


func _refresh() -> void:
	for i in _requests.size():
		_refresh_slot(i)
	changed.emit()


func _refresh_slot(index: int) -> void:
	if index >= _slot_uis.size() or not _slot_uis[index].is_node_ready():
		return
	var slot_ui: ItemSlotUI = _slot_uis[index]
	var request: Dictionary = _requests[index]
	var have: int = _get_amount(index)
	var need: int = int(request["amount"])
	var first: InventorySlot = null
	for stack: InventorySlot in _held[index]:
		if not stack.is_empty():
			first = stack
			break
	if first:
		slot_ui.display(first.copy_with_amount(have))
	else:
		slot_ui.display_custom(request["icon"], Language.translate("%s\nHier hineinziehen.") % request["name"])
		slot_ui.get_node("Icon").modulate.a = GHOST_ALPHA
	_labels[index].text = "%d/%d" % [have, need]
	_labels[index].add_theme_color_override("font_color", COLOR_ENOUGH if have >= need else COLOR_MISSING)
