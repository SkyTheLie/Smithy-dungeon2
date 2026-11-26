class_name StorageMenu
extends StationMenu
## Window of the storage chest next to the bed (GameState.storage_chest, 6x5) or of a storage box
## (StorageBox sets `chest` and `box_uid` before adding it, 8 per row).
## Putting in: drag an inventory item onto the chest, or right click it in the inventory
## (Ctrl = 1 piece, Shift = half the stack). Taking out: click a chest slot (Ctrl = 1 piece,
## Shift = half), "Alles nehmen" takes as much as fits.
## A box has a sign row: "Schild anbringen" uses a box sign (item chest_sign) from the inventory,
## then a name can be typed in; "Abnehmen" gives the sign back (House.box_signs).

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const COLUMNS: int = 6
const BOX_COLUMNS: int = 8
const HINT: String = "Rechtsklick im Inventar legt hinein."

## What the window shows (null = the storage chest next to the bed).
var chest: Inventory
## uid of the storage box in GameState.house.boxes ("" = the storage chest, no sign row).
var box_uid: String = ""

var _slot_uis: Array[ItemSlotUI] = []
var _chest: Inventory
var _sign_row: HBoxContainer
var _attach_button: Button
var _name_edit: LineEdit
var _remove_button: Button
## Name of the window without the sign (the box's furniture name).
var _base_title: String = ""

@onready var _grid: GridContainer = %Grid
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	super()
	_chest = chest if chest else GameState.storage_chest
	_grid.columns = BOX_COLUMNS if not box_uid.is_empty() else COLUMNS
	for i in _chest.slots.size():
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop, _drop)
		_slot_uis.append(slot_ui)
	%TakeAllButton.pressed.connect(_take_all)
	# "Sortieren" next to "Alles nehmen": merges and orders the whole chest (Inventory.sort).
	var sort_button := Button.new()
	sort_button.text = Language.translate("Sortieren")
	sort_button.focus_mode = Control.FOCUS_NONE
	sort_button.pressed.connect(_chest.sort.bind(0))
	%TakeAllButton.add_sibling(sort_button)
	if not box_uid.is_empty():
		_base_title = title
		_add_sign_row()
		GameState.house.box_sign_changed.connect(func(changed_uid: String) -> void:
			if changed_uid == box_uid:
				_refresh_sign_row())
	_chest.changed.connect(_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _add_sign_row() -> void:
	_sign_row = HBoxContainer.new()
	_sign_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_label.add_sibling(_sign_row)
	_status_label.get_parent().move_child(_sign_row, _status_label.get_index())
	_attach_button = Button.new()
	_attach_button.text = Language.translate("Schild anbringen")
	_attach_button.focus_mode = Control.FOCUS_NONE
	_attach_button.pressed.connect(_attach_sign)
	_sign_row.add_child(_attach_button)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = Language.translate("Name der Kiste")
	_name_edit.max_length = House.SIGN_MAX_LENGTH
	_name_edit.custom_minimum_size = Vector2(110, 0)
	_name_edit.text_changed.connect(func(text: String) -> void: GameState.house.set_sign_name(box_uid, text))
	_name_edit.text_submitted.connect(func(_text: String) -> void: _name_edit.release_focus())
	_sign_row.add_child(_name_edit)
	_remove_button = Button.new()
	_remove_button.text = Language.translate("Abnehmen")
	_remove_button.focus_mode = Control.FOCUS_NONE
	_remove_button.tooltip_text = Language.translate("Das Schild kommt zurück ins Inventar.")
	_remove_button.pressed.connect(GameState.house.remove_sign.bind(box_uid))
	_sign_row.add_child(_remove_button)
	_refresh_sign_row()


func _refresh_sign_row() -> void:
	var house: House = GameState.house
	var has_sign: bool = house.has_sign(box_uid)
	_attach_button.visible = not has_sign
	_attach_button.tooltip_text = Language.translate("Braucht ein Kistenschild im Inventar (gibt es bei der Möbelhändlerin).")
	_name_edit.visible = has_sign
	_remove_button.visible = has_sign
	# Not while typing: the saved name has no spaces at the end, the field may have them.
	if not _name_edit.has_focus() and _name_edit.text != house.get_sign_name(box_uid):
		_name_edit.text = house.get_sign_name(box_uid)
	var sign_name: String = house.get_sign_name(box_uid)
	_title_bar.title = _base_title if sign_name.is_empty() else "%s: %s" % [_base_title, sign_name]


func _attach_sign() -> void:
	if not GameState.house.attach_sign(box_uid):
		_status_label.text = Language.translate("Du hast kein Kistenschild. Die Möbelhändlerin verkauft welche.")
		return
	_status_label.text = Language.translate("Schild angebracht. Gib der Kiste einen Namen.")
	_name_edit.grab_focus.call_deferred()


func _on_visibility_changed() -> void:
	_status_label.text = Language.translate(HINT)
	if _name_edit and not visible:
		_name_edit.release_focus()
	_refresh()


func _refresh() -> void:
	for i in _slot_uis.size():
		_slot_uis[i].display(_chest.slots[i])


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	return _store(inventory_index, amount)


func _can_drop(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inventory_index")


func _drop(_at_position: Vector2, data: Variant) -> void:
	_store(int(data["inventory_index"]), int(data.get("amount", -1)))


## Moves up to `amount` pieces (-1 = all) of an inventory slot into the chest.
func _store(inventory_index: int, amount: int) -> bool:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty():
		return false
	var count: int = source.amount if amount < 0 else mini(amount, source.amount)
	var leftover: int = _chest.add_stack(source.copy_with_amount(count))
	GameState.inventory.remove_from_slot(inventory_index, count - leftover)
	_status_label.text = Language.translate("Die Truhe ist voll.") if leftover > 0 else Language.translate(HINT)
	return leftover < count


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]):
		return
	var stack: InventorySlot = _chest.slots[index]
	var amount: int = stack.amount
	if mouse_event.ctrl_pressed:
		amount = 1
	elif mouse_event.shift_pressed:
		amount = ceili(stack.amount / 2.0)
	if not _take(index, amount):
		_status_label.text = Language.translate("Kein Platz im Inventar.")


func _take_all() -> void:
	var everything_taken: bool = true
	for i in _chest.slots.size():
		if not _take(i, _chest.slots[i].amount):
			everything_taken = false
	if not everything_taken:
		_status_label.text = Language.translate("Nicht alles passt ins Inventar.")


## Moves up to `amount` pieces of a chest slot into the inventory. Returns true if all of them moved.
func _take(index: int, amount: int) -> bool:
	var stack: InventorySlot = _chest.slots[index]
	if stack.is_empty() or amount <= 0:
		return true
	var leftover: int = GameState.inventory.add_stack(stack.copy_with_amount(amount))
	_chest.remove_from_slot(index, amount - leftover)
	return leftover == 0
