class_name SharpenMenu
extends StationMenu
## Grindstone window: one slot for a weapon or a crystal (drag it in or right-click it in the
## inventory). Weapons: rarity and quality now and at best, "Schärfen" starts the minigame
## (SharpeningMinigame); the result is shown big (GameState.item_revealed). Crystals: the gem it
## becomes, "Schleifen" grinds it (see Sharpening).
## Clicking the slot or closing the window puts the piece back into the inventory (closed during the
## minigame: unsharpened).

## The weapon lying on the grindstone (empty = nothing).
var _slot: InventorySlot = InventorySlot.new()

@onready var _panel: Control = $Panel
@onready var _slot_ui: ItemSlotUI = %WeaponSlot
@onready var _info_label: Label = %InfoLabel
@onready var _sharpen_button: Button = %SharpenButton
@onready var _minigame: SharpeningMinigame = %SharpeningMinigame


func _ready() -> void:
	super()
	_minigame.hide()
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.close_requested.connect(close)
	_slot_ui.gui_input.connect(_on_slot_gui_input)
	_slot_ui.drag_out = true
	_slot_ui.set_drag_forwarding(Callable(), _can_drop_into, _drop_into)
	_sharpen_button.pressed.connect(_on_sharpen_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _refresh() -> void:
	_slot_ui.display(_slot)
	var blocker: String = Sharpening.get_blocker(_slot)
	_sharpen_button.disabled = blocker != ""
	_sharpen_button.text = Language.translate("Schleifen") if Sharpening.is_grindable(_slot) else Language.translate("Schärfen")
	if blocker != "":
		_info_label.text = blocker
		return
	if Sharpening.is_grindable(_slot):
		var gem: InventorySlot = Sharpening.get_ground(_slot)
		_info_label.text = "%s\n» %s (%s)" % [_slot.item.display_name, gem.item.display_name, Rarity.get_display_name(gem.rarity)]
		return
	var best: Dictionary = Sharpening.get_sharpened(_slot)
	_info_label.text = "%s\nbestenfalls » %s" % [ForgeQuality.describe(_slot.rarity, _slot.quality),
			ForgeQuality.describe(best["rarity"], best["quality"])]


func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index}
	if not _can_drop_into(Vector2.ZERO, data):
		return false
	_drop_into(Vector2.ZERO, data)
	return true


func _can_drop_into(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_index")) or not _slot.is_empty():
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return not source.is_empty() and Sharpening.accepts(source.item)


func _drop_into(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	_slot = GameState.inventory.slots[index].copy_with_amount(1)
	GameState.inventory.remove_from_slot(index, 1)
	_refresh()


func _on_sharpen_pressed() -> void:
	if Sharpening.is_grindable(_slot):
		if Sharpening.grind(_slot):
			_refresh()
			_info_label.text = Language.translate("Geschliffen! %s (%s).") % [_slot.item.display_name, Rarity.get_display_name(_slot.rarity)]
		return
	if Sharpening.get_blocker(_slot) == "":
		_panel.hide()
		_minigame.start(_slot)


func _on_minigame_finished(share: float) -> void:
	_minigame.hide()
	_panel.show()
	var rarity_before: Rarity.Tier = _slot.rarity
	if Sharpening.sharpen(_slot, share):
		_refresh()
		_info_label.text = Language.translate("Geschärft! %s.") % ForgeQuality.describe(_slot.rarity, _slot.quality)
		GameState.item_revealed.emit(_slot, _slot.rarity > rarity_before)


func _on_slot_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_return_weapon()


func _on_visibility_changed() -> void:
	if not visible:
		if _minigame.is_running():
			_minigame.stop()
			_panel.show()
		_return_weapon()


func _return_weapon() -> void:
	if _slot.is_empty() or GameState.inventory.get_free_space(_slot) < _slot.amount:
		return
	GameState.inventory.add_stack(_slot)
	_slot = InventorySlot.new()
	_refresh()
