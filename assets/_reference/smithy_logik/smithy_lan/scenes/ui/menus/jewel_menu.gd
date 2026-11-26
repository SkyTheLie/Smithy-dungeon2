class_name JewelMenu
extends StationMenu
## Jewel table window: left slot = ring or amulet band (silver ring / silver amulet), right slot =
## crystal (e.g. a ruby). Drag them in or right-click them in the inventory. Shows the possible
## rarities and the effects the jewel can get (one of them at random, see Jewelry); "Fassen" uses
## one band and one crystal, the jewel goes into the inventory and is shown big (ItemReveal).
## Left click on a slot opens a list of every fitting band / crystal (ItemPicker, best first);
## right click or closing the window puts its stack back into the inventory.

var _band: InventorySlot = InventorySlot.new()
var _crystal: InventorySlot = InventorySlot.new()

@onready var _band_ui: ItemSlotUI = %BandSlot
@onready var _crystal_ui: ItemSlotUI = %CrystalSlot
@onready var _info_label: Label = %InfoLabel
@onready var _join_button: Button = %JoinButton


func _ready() -> void:
	super()
	_band_ui.gui_input.connect(_on_slot_gui_input.bind(true))
	_crystal_ui.gui_input.connect(_on_slot_gui_input.bind(false))
	_band_ui.drag_out = true
	_crystal_ui.drag_out = true
	_band_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(true), _drop_into.bind(true))
	_crystal_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(false), _drop_into.bind(false))
	_join_button.pressed.connect(_on_join_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()


func _refresh() -> void:
	_band_ui.display(_band)
	_crystal_ui.display(_crystal)
	# Empty slots say what belongs into them.
	if _band.is_empty():
		_band_ui.tooltip_text = Language.translate("Ring- oder Amulettfassung")
	if _crystal.is_empty():
		_crystal_ui.tooltip_text = Language.translate("Kristall (z. B. Rubin)")
	var blocker: String = Jewelry.get_blocker(_band, _crystal)
	_join_button.disabled = blocker != ""
	if blocker != "":
		_info_label.text = blocker
		return
	var chances: Dictionary = Jewelry.get_rarity_chances(_band, _crystal)
	var tiers: Array = chances.keys()
	tiers.sort()
	var rarity_parts: Array[String] = []
	for tier: int in tiers:
		rarity_parts.append("%s %d %%" % [Rarity.get_display_name(tier as Rarity.Tier), roundi(chances[tier] * 100.0)])
	var lines: Array[String] = [Language.translate("Seltenheit: ") + " · ".join(rarity_parts),
			Language.translate("Eine Eigenschaft (zufällig, %s):") % (Language.translate("Angriff") if Jewelry.get_kind(_band.item) == "ring" else Language.translate("Schutz"))]
	lines.append_array(Jewelry.describe_options(_band, _crystal))
	_info_label.text = "\n".join(lines)


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty():
		return false
	var into_band: bool = Jewelry.is_band(source.item)
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not _can_drop_into(Vector2.ZERO, data, into_band):
		return false
	_drop_into(Vector2.ZERO, data, into_band)
	return true


## Left slot: a ring or amulet band; right slot: a crystal. Onto the same stack or an empty slot.
func _can_drop_into(_at_position: Vector2, data: Variant, into_band: bool) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	if source.is_empty():
		return false
	if into_band and not Jewelry.is_band(source.item):
		return false
	if not into_band and not Jewelry.is_crystal(source.item):
		return false
	var slot: InventorySlot = _band if into_band else _crystal
	return slot.is_empty() or (slot.can_stack_with(source) and slot.amount < slot.item.max_stack)


func _drop_into(_at_position: Vector2, data: Variant, into_band: bool) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var amount: int = get_move_amount(data, source)
	var slot: InventorySlot = _band if into_band else _crystal
	if slot.is_empty():
		slot = source.copy_with_amount(amount)
	else:
		amount = mini(amount, slot.item.max_stack - slot.amount)
		slot.add_from(source, amount)
	GameState.inventory.remove_from_slot(index, amount)
	if into_band:
		_band = slot
	else:
		_crystal = slot
	_refresh()


func _on_join_pressed() -> void:
	if Jewelry.get_blocker(_band, _crystal) != "":
		return
	# The jewel goes into the inventory: there must be room for it.
	var preview: InventorySlot = Crafting.create_result(Jewelry.get_result_item(Jewelry.get_kind(_band.item)), 1, 0, Rarity.Tier.COMMON)
	if GameState.inventory.get_free_space(preview) < 1:
		_info_label.text = Language.translate("Kein Platz im Inventar.")
		return
	var lowest: Rarity.Tier = mini(_band.rarity, _crystal.rarity) as Rarity.Tier
	var jewel: InventorySlot = Jewelry.make(_band, _crystal)
	if jewel == null:
		return
	GameState.inventory.add_stack(jewel)
	GameState.item_revealed.emit(jewel, jewel.rarity > lowest)
	var stats: PlayerStats = GameState.player_stats
	stats.add_experience(stats.experience_assembling)
	GameState.achievements.count("craft")
	GameState.achievements.count("craft:" + String(jewel.item.id))
	_refresh()
	_info_label.text = Language.translate("%s gefasst: %s.") % [jewel.get_display_name(), Jewelry.format(jewel.jewel_effect, jewel.get_jewel_value())]


func _on_slot_gui_input(event: InputEvent, is_band: bool) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		open_picker(is_band)
	elif mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if is_band:
			_band = _return_stack(_band)
		else:
			_crystal = _return_stack(_crystal)
		_refresh()


## Every band (left) or crystal (right) the player has (ItemPicker entries).
func get_picker_entries(is_band: bool) -> Array[Dictionary]:
	return ItemPicker.collect(func(slot: InventorySlot) -> bool:
		return Jewelry.is_band(slot.item) if is_band else Jewelry.is_crystal(slot.item))


func open_picker(is_band: bool) -> void:
	var placed: InventorySlot = _band if is_band else _crystal
	ItemPicker.open(self, _band_ui if is_band else _crystal_ui,
			Language.translate("Fassung wählen") if is_band else Language.translate("Kristall wählen"),
			get_picker_entries(is_band), not placed.is_empty(), pick_entry.bind(is_band),
			func() -> void:
				if is_band:
					_band = _return_stack(_band)
				else:
					_crystal = _return_stack(_crystal)
				_refresh())


## Lays the whole entry (up to a full stack) into the slot; something else lying there goes back.
func pick_entry(entry: Dictionary, is_band: bool) -> void:
	var placed: InventorySlot = _band if is_band else _crystal
	if not placed.is_empty() and not placed.can_stack_with(entry["slot"]):
		placed = _return_stack(placed)
		if not placed.is_empty():
			_info_label.text = Language.translate("Kein Platz im Inventar.")
			return
	var sample: InventorySlot = entry["slot"]
	ItemPicker.take(entry, mini(sample.amount, sample.item.max_stack - placed.amount), placed)
	if is_band:
		_band = placed
	else:
		_crystal = placed
	_refresh()


func _on_visibility_changed() -> void:
	if not visible:
		_band = _return_stack(_band)
		_crystal = _return_stack(_crystal)
		_refresh()


## Puts as much of the stack back into the inventory as fits; returns what stays on the table.
func _return_stack(slot: InventorySlot) -> InventorySlot:
	if slot.is_empty():
		return InventorySlot.new()
	slot.amount = GameState.inventory.add_stack(slot)
	return slot if slot.amount > 0 else InventorySlot.new()
