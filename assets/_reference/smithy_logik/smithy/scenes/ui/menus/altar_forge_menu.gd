extends StationMenu
## Window of the first smith's anvil in the altar of the nine (2026-11-19): it forges only one thing,
## the recipe `recipe_id` (the true setting). One slot per piece the recipe needs (three starsteel
## ingots: [ ] [ ] [ ] = [true setting]), no tabs, no recipe list.
## A left click on a slot opens the selection list (ItemPicker), a right click puts the piece back;
## pieces can also be dragged in or right-clicked in the inventory (first empty slot). Once every
## slot holds a piece, "Schmieden" starts the anvil minigame; when it is over the pieces are used
## (Crafting.craft, like the normal anvil) and the result goes into the inventory.
## Closing the window (or aborting the minigame) puts the pieces back into the inventory.

const TEXT_LAY: String = "Lege drei Sternenstahl-Barren auf den Amboss."
const TEXT_READY: String = "Alles liegt bereit."
const TEXT_DONE: String = "%s geschmiedet."

## The one recipe this anvil forges (recipes.json).
@export var recipe_id: StringName = &"true_setting"

## One piece per slot.
var _pieces: Array[InventorySlot] = []

@onready var _slot_uis: Array[ItemSlotUI] = [%Slot1, %Slot2, %Slot3]
@onready var _result_ui: ItemSlotUI = %ResultSlot
@onready var _info_label: Label = %InfoLabel
@onready var _forge_button: Button = %ForgeButton
@onready var _panel: Control = $Panel
@onready var _minigame: ForgingMinigame = %ForgingMinigame


func _ready() -> void:
	super()
	for index in _slot_uis.size():
		_pieces.append(InventorySlot.new())
		var slot_ui: ItemSlotUI = _slot_uis[index]
		slot_ui.drag_out = true
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(index))
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(index), _drop_into.bind(index))
	_forge_button.pressed.connect(_on_forge_pressed)
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.close_requested.connect(close)
	visibility_changed.connect(_on_visibility_changed)
	_minigame.hide()
	_refresh()


func get_recipe() -> RecipeData:
	return ContentDB.recipe(String(recipe_id)) if ContentDB.has_recipe(String(recipe_id)) else null


## The item every slot takes (the first ingredient of the recipe).
func _ingredient() -> Ingredient:
	var recipe: RecipeData = get_recipe()
	return recipe.ingredients[0] if recipe and not recipe.ingredients.is_empty() else null


func _refresh() -> void:
	var recipe: RecipeData = get_recipe()
	var ingredient: Ingredient = _ingredient()
	for index in _slot_uis.size():
		var slot_ui: ItemSlotUI = _slot_uis[index]
		if ingredient:
			slot_ui.placeholder = ingredient.get_icon()
			slot_ui.placeholder_tooltip = Language.translate("Klicken: %s auswählen") % ingredient.get_display_name()
		slot_ui.display(_pieces[index])
	if recipe and recipe.result:
		_result_ui.placeholder = recipe.result.icon
		_result_ui.placeholder_tooltip = recipe.result.display_name
	_result_ui.display(InventorySlot.new())
	var full: bool = is_full()
	_forge_button.disabled = not full
	_info_label.text = Language.translate(TEXT_READY if full else TEXT_LAY)


## true once every slot holds a piece.
func is_full() -> bool:
	return _pieces.all(func(piece: InventorySlot) -> bool: return not piece.is_empty())


## What lies in slot `index` (tests).
func get_piece(index: int) -> InventorySlot:
	return _pieces[index]


func _fits(item: ItemData) -> bool:
	var ingredient: Ingredient = _ingredient()
	return ingredient != null and item != null and ingredient.matches(item)


# --- Slots -------------------------------------------------------------------------

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed) or _minigame.is_running():
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		open_picker(index)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_take_out(index)


## Every fitting stack of the inventory (and the chests at home) for slot `index`.
func get_picker_entries() -> Array[Dictionary]:
	return ItemPicker.collect(func(stack: InventorySlot) -> bool: return _fits(stack.item))


func open_picker(index: int) -> void:
	var ingredient: Ingredient = _ingredient()
	if ingredient == null:
		return
	ItemPicker.open(self, _slot_uis[index], Language.translate("%s wählen") % ingredient.get_display_name(),
			get_picker_entries(), not _pieces[index].is_empty(),
			# bind() would append the index after the entry, so the order is wrong.
			func(entry: Dictionary) -> void: pick_entry(index, entry),
			func() -> void: _take_out(index))


## Lays one piece of the entry into slot `index`; what lay there goes back first.
func pick_entry(index: int, entry: Dictionary) -> void:
	if not _pieces[index].is_empty():
		_take_out(index)
		if not _pieces[index].is_empty():
			_info_label.text = Language.translate("Kein Platz im Inventar.")
			return
	ItemPicker.take(entry, 1, _pieces[index])
	_refresh()


func _take_out(index: int) -> void:
	var piece: InventorySlot = _pieces[index]
	if piece.is_empty():
		return
	var leftover: int = GameState.inventory.add_stack(piece)
	if leftover <= 0:
		piece.clear()
	else:
		piece.amount = leftover
	_refresh()


func _can_drop_into(_at_position: Vector2, data: Variant, index: int) -> bool:
	if not (data is Dictionary and data.has("inventory_index")) or _minigame.is_running():
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return not source.is_empty() and not source.hot and _fits(source.item) and _pieces[index].is_empty()


func _drop_into(_at_position: Vector2, data: Variant, index: int) -> void:
	var inventory_index: int = data["inventory_index"]
	_place_from_inventory(inventory_index, index)


func _place_from_inventory(inventory_index: int, index: int) -> void:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	_pieces[index] = source.copy_with_amount(1)
	GameState.inventory.remove_from_slot(inventory_index, 1)
	_refresh()


## Right click in the inventory: one piece into the first empty slot.
func try_quick_move(inventory_index: int, _amount: int = -1) -> bool:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty() or source.hot or not _fits(source.item) or _minigame.is_running():
		return false
	for index in _pieces.size():
		if _pieces[index].is_empty():
			_place_from_inventory(inventory_index, index)
			return true
	return false


# --- Forging -----------------------------------------------------------------------

func _on_forge_pressed() -> void:
	var recipe: RecipeData = get_recipe()
	if recipe == null or not is_full():
		return
	ItemPicker.close_current()
	_panel.hide()
	_minigame.start(_pieces[0], recipe.result, 0, true)


func _on_minigame_finished(points: int, perfect: bool) -> void:
	_minigame.hide()
	_panel.show()
	var recipe: RecipeData = get_recipe()
	# The pieces on the anvil are what gets used: they go back into the inventory, from where
	# Crafting takes them like at every anvil.
	_return_all()
	var result: InventorySlot = Crafting.craft(recipe, GameState.inventory, points, GameState.get_crafting_extras())
	if result == null:
		_refresh()
		return
	GameState.player_stats.add_experience(GameState.player_stats.get_forging_experience(maxi(points, 0)))
	GameState.achievements.count("forge")
	GameState.achievements.count("forge:" + String(result.item.id))
	if perfect:
		GameState.achievements.count("forge_perfect")
	_refresh()
	_info_label.text = Language.translate(TEXT_DONE) % result.get_display_name()


func _return_all() -> void:
	for index in _pieces.size():
		_take_out(index)


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
		return
	# Window closed during the minigame: abort, nothing is used.
	if _minigame.is_running():
		_minigame.stop()
	_minigame.hide()
	_panel.show()
	if ItemPicker.is_open() and ItemPicker._current.get_parent() == self:
		ItemPicker.close_current()
	_return_all()


func _exit_tree() -> void:
	# Scene change while the window is open: the pieces go back.
	_return_all()
