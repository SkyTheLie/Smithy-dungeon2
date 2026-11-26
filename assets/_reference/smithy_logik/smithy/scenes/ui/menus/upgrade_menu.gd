class_name UpgradeMenu
extends StationMenu
## Upgrade table window: left slot = weapon, armor or arrows, right slot = material (e.g. a rat
## venom fang). Drag them in or right-click them in the inventory. Shows what the upgrade does;
## "Aufwerten" uses up one material (see Upgrading). Arrows: 10 of the stack are upgraded and go
## into the inventory, the rest stays on the table. Clicking a slot or closing the window puts
## its stack back into the inventory.

var _target: InventorySlot = InventorySlot.new()
var _material: InventorySlot = InventorySlot.new()

@onready var _target_ui: ItemSlotUI = %TargetSlot
@onready var _material_ui: ItemSlotUI = %MaterialSlot
@onready var _info_label: Label = %InfoLabel
@onready var _upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	super()
	_target_ui.gui_input.connect(_on_slot_gui_input.bind(true))
	_material_ui.gui_input.connect(_on_slot_gui_input.bind(false))
	_target_ui.drag_out = true
	_material_ui.drag_out = true
	_target_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(true), _drop_into.bind(true))
	_material_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(false), _drop_into.bind(false))
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _refresh() -> void:
	_target_ui.display(_target)
	_material_ui.display(_material)
	# Empty slots say what belongs into them.
	if _target.is_empty():
		_target_ui.tooltip_text = Language.translate("Waffe, Rüstung oder Pfeile")
	if _material.is_empty():
		_material_ui.tooltip_text = Language.translate("Material (z. B. ein Kristall)")
	var blocker: String = Upgrading.get_blocker(_target, _material)
	_upgrade_button.disabled = blocker != ""
	if blocker != "":
		_info_label.text = blocker
		return
	var amount: int = Upgrading.get_upgraded_amount(_target, _material)
	var what: String = "%d× %s" % [amount, _target.get_display_name()] if amount > 1 else _target.get_display_name()
	_info_label.text = "%s\n» %s\nVerbraucht 1× %s." % [what,
			_material.item.upgrade.describe(_material.rarity), _material.item.display_name]


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty():
		return false
	var into_target: bool = not Upgrading.is_material(source.item)
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not _can_drop_into(Vector2.ZERO, data, into_target):
		return false
	_drop_into(Vector2.ZERO, data, into_target)
	return true


## Left slot: something upgradeable; right slot: a material. Onto the same stack or an empty slot.
func _can_drop_into(_at_position: Vector2, data: Variant, into_target: bool) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	if source.is_empty():
		return false
	if into_target and not Upgrading.is_upgradeable(source.item):
		return false
	if not into_target and not Upgrading.is_material(source.item):
		return false
	var slot: InventorySlot = _target if into_target else _material
	return slot.is_empty() or (slot.can_stack_with(source) and slot.amount < slot.item.max_stack)


func _drop_into(_at_position: Vector2, data: Variant, into_target: bool) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var amount: int = get_move_amount(data, source)
	var slot: InventorySlot = _target if into_target else _material
	if slot.is_empty():
		slot = source.copy_with_amount(amount)
	else:
		amount = mini(amount, slot.item.max_stack - slot.amount)
		slot.add_from(source, amount)
	GameState.inventory.remove_from_slot(index, amount)
	if into_target:
		_target = slot
	else:
		_material = slot
	_refresh()


func _on_upgrade_pressed() -> void:
	var splits: bool = Upgrading.get_upgraded_amount(_target, _material) < _target.amount
	if splits:
		# The upgraded arrows go into the inventory: there must be room for them.
		var preview: InventorySlot = _target.copy_with_amount(Upgrading.get_upgraded_amount(_target, _material))
		preview.upgrade_item = _material.item
		preview.upgrade_rarity = _material.rarity
		if GameState.inventory.get_free_space(preview) < preview.amount:
			_info_label.text = Language.translate("Kein Platz im Inventar für die aufgewerteten Pfeile.")
			return
	var result: InventorySlot = Upgrading.upgrade(_target, _material)
	if result == null:
		return
	if result != _target:
		GameState.inventory.add_stack(result)
	_refresh()
	var text: String = Language.translate("Aufgewertet: %s%s.") % ["%d× " % result.amount if result.amount > 1 else "", result.get_display_name()]
	if result != _target:
		text += Language.translate(" (im Inventar)")
	_info_label.text = text


func _on_slot_gui_input(event: InputEvent, is_target: bool) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if is_target:
			_target = _return_stack(_target)
		else:
			_material = _return_stack(_material)
		_refresh()


func _on_visibility_changed() -> void:
	if not visible:
		_target = _return_stack(_target)
		_material = _return_stack(_material)
		_refresh()


## Puts as much of the stack back into the inventory as fits; returns what stays on the table.
func _return_stack(slot: InventorySlot) -> InventorySlot:
	if slot.is_empty():
		return InventorySlot.new()
	slot.amount = GameState.inventory.add_stack(slot)
	return slot if slot.amount > 0 else InventorySlot.new()
