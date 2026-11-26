class_name ArmoryMenu
extends StationMenu
## "Waffen für Sylvaris" (part 3): General Hadmar's armory on the forest floor of Sylvaris, opened by
## the story action "open_menu:armory" (his dialogue). Weapons and armor go into the slots (right
## click or drag from the inventory; a click on a slot takes the piece back), "Übergeben" hands
## them all in (ElfDefense.hand_in). The points stay hidden: the general only says roughly how far
## it is (economy.json "elf_defense.verdicts", one per ElfDefense.get_level).
## Closing the window puts pieces that were not handed in back into the inventory (or the loot chest).

const MENU_ID: String = "armory"
const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const SLOT_COUNT: int = 10
const COLUMNS: int = 5
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)
const COLOR_VERDICT: Color = Color(0.95, 0.85, 0.6)

var _slots: Array[InventorySlot] = []
var _slot_uis: Array[ItemSlotUI] = []

@onready var _grid: GridContainer = %Grid
@onready var _hand_in_button: Button = %HandInButton
@onready var _verdict_label: Label = %VerdictLabel


func _ready() -> void:
	opens_inventory = true
	super()
	Events.story_menu_requested.connect(func(menu: String) -> void:
		if menu == MENU_ID:
			open())
	_grid.columns = COLUMNS
	for i in SLOT_COUNT:
		_slots.append(InventorySlot.new())
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into, _drop_into)
		_slot_uis.append(slot_ui)
	_hand_in_button.pressed.connect(_hand_in)
	visibility_changed.connect(func() -> void:
		if not visible:
			_return_all())


func open() -> void:
	_show_verdict(false)
	_refresh()
	show()


func _refresh() -> void:
	var empty: bool = true
	for i in SLOT_COUNT:
		_slot_uis[i].display(_slots[i])
		empty = empty and _slots[i].is_empty()
	_hand_in_button.disabled = empty


## The general's words for the current level; `after_hand_in` = he just received something.
func _show_verdict(after_hand_in: bool) -> void:
	var verdicts: Array = ContentDB.economy(ElfDefense.TASK_ID).get("verdicts", [])
	var level: int = ElfDefense.get_level()
	var text: String = ""
	if not after_hand_in and ElfDefense.get_pieces() == 0:
		text = str(ContentDB.economy(ElfDefense.TASK_ID).get("verdict_start", ""))
	elif level < verdicts.size():
		text = str(verdicts[level])
	_verdict_label.remove_theme_color_override("font_color")
	_verdict_label.add_theme_color_override("font_color", COLOR_VERDICT)
	_verdict_label.text = Language.translate(text)


func _free_slot() -> int:
	for i in SLOT_COUNT:
		if _slots[i].is_empty():
			return i
	return -1


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not _can_drop_into(Vector2.ZERO, data):
		var source: InventorySlot = GameState.inventory.slots[inventory_index]
		if not source.is_empty() and not ElfDefense.can_hand_in(source):
			_show_error(Language.translate("Der General nimmt nur abgekühlte Waffen und Rüstungsteile."))
		return false
	_drop_into(Vector2.ZERO, data)
	return true


func _can_drop_into(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return ElfDefense.can_hand_in(source) and _free_slot() >= 0


func _drop_into(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var free: int = _free_slot()
	if free < 0:
		return
	# Equipment never stacks: one piece per slot.
	_slots[free] = source.copy_with_amount(1)
	GameState.inventory.remove_from_slot(index, 1)
	_refresh()


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_return_slot(index)
		_refresh()


## Puts the piece of a slot back into the inventory (the loot chest when it is full).
func _return_slot(index: int) -> void:
	var stack: InventorySlot = _slots[index]
	if stack.is_empty():
		return
	var leftover: int = GameState.inventory.add_stack(stack.copy_with_amount(stack.amount))
	if leftover > 0:
		GameState.put_stack_into_reward_chest(stack.copy_with_amount(leftover))
		GameState.show_message(Language.translate("Inventar voll: %s liegt in der Loot-Kiste.") % stack.get_display_name())
	_slots[index] = InventorySlot.new()


func _return_all() -> void:
	for i in SLOT_COUNT:
		_return_slot(i)
	_refresh()


func _hand_in() -> void:
	var given: Array[InventorySlot] = []
	for i in SLOT_COUNT:
		if not _slots[i].is_empty():
			given.append(_slots[i])
	if given.is_empty():
		return
	ElfDefense.hand_in(given)
	for i in SLOT_COUNT:
		_slots[i] = InventorySlot.new()
	AudioManager.play_sound("chest_open")
	GameState.show_message(Language.translate("%d Teile an General Hadmar übergeben.") % given.size())
	_show_verdict(true)
	_refresh()


func _show_error(text: String) -> void:
	_verdict_label.add_theme_color_override("font_color", COLOR_ERROR)
	_verdict_label.text = text
