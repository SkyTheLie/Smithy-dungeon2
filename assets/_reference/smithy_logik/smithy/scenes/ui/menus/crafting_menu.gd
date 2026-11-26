extends StationMenu
## Crafting window (anvil, forge): recipe list, and on the right the result and required
## ingredients of the selected recipe.
## With uses_categories (forge) the recipes are structured in tabs and categories (see RecipeBrowser).
## With uses_minigame the button starts the forging minigame; its quality points go onto what the
## part inherits from its hot blank (ForgeQuality).
## Ingredients are only consumed when the minigame is finished (closing the window aborts it).
## With uses_heat (forge) every craft needs one heat charge (GameState.get_forge_heat()); fuel
## (wood 1, coal 5 castings) is dragged or right-clicked into the heat slot and burned piece by
## piece; a click on the heat slot takes the unburned fuel back. Is the forge cold, one piece of
## fuel from the inventory or the storage chest is put in by itself when casting.
## Ingredients also come from the storage chest next to the bed (GameState.get_crafting_extras).
## An ingredient that is there in several rarities gets a button that picks which one is used
## ("Alle" = any, the last stack first).
## Forge (uses_heat): every ingredient row starts with a slot. The player can lay exactly the ingots
## he wants in there (drag, or right click in the inventory); they are used first, the rest comes
## from the inventory / chest as before. A left click on the slot opens a list of every matching
## ingot the player has (inventory and chests, highest rarity first, ingot picker); a pick lays it in.
## A right click, another recipe or closing the window puts them back into the inventory.
## A chosen kind of ingot (e.g. iron ingots R2) stays chosen (GameState.ingot_choice): after every
## casting, on another mould and when the window opens again, the same kind is laid back in, until
## those ingots are used up or the player takes them out (right click / "Herausnehmen").
## A block in front of every recipe and category shows what the player has for it (inventory, chests
## and slots; RecipeBrowser.supply: green = all, yellow = some).

const COLOR_ENOUGH: Color = Color(0.55, 0.85, 0.45)
const COLOR_MISSING: Color = Color(0.9, 0.4, 0.35)
const FONT_SIZE: int = 11
const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")

## Station whose recipes are offered ("forge" or "anvil", see ContentDB / RecipeData.station).
@export var station: StringName = &""
## true = "Schmieden" starts the forging minigame (anvil), false = craft instantly.
@export var uses_minigame: bool = false
## true = tabs + categories (forge), false = one plain recipe list (anvil).
@export var uses_categories: bool = false
## true = crafting needs heat from fuel (forge).
@export var uses_heat: bool = false
## true = only recipes whose first ingredient is in the inventory (anvil: only what there is a
## hot blank for); the list updates when the inventory changes.
@export var only_with_ingredients: bool = false

var _selected: RecipeData
## Ingredient index -> rarity chosen with the rarity button (missing = any).
var _rarities: Dictionary = {}
## Recipe being forged while the minigame runs.
var _forging_recipe: RecipeData
var _browser: RecipeBrowser
## Forge: what lies in the ingredient slots, slot i = ingredient i of the selected recipe.
var _placed: Inventory = Inventory.new(0)
## Ingot picker of this window (ItemPicker), null while closed.
var _picker: ItemPicker:
	get:
		return ItemPicker._current if ItemPicker.is_open() and ItemPicker._current.get_parent() == self else null
var _picker_layer: CanvasLayer:
	get:
		return _picker

@onready var _tab_bar: TabBar = %TabBar
@onready var _category_column: Control = %CategoryColumn
@onready var _category_list: VBoxContainer = %CategoryList
@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _result_slot: ItemSlotUI = %ResultSlot
@onready var _result_name: Label = %ResultName
@onready var _ingredient_list: VBoxContainer = %IngredientList
@onready var _craft_button: Button = %CraftButton
@onready var _status_label: Label = %StatusLabel
@onready var _panel: Control = $Panel
@onready var _minigame: ForgingMinigame = %ForgingMinigame
@onready var _heat_row: Control = %HeatRow
@onready var _heat_slot: ItemSlotUI = %HeatSlot
@onready var _heat_label: Label = %HeatLabel
## _get_items_on_hand() of the frame _items_on_hand_frame (-1 = look again).
var _items_on_hand: Array = []
var _items_on_hand_frame: int = -1
## Supplies or heat changed while the window was closed (see _on_supplies_changed).
var _details_stale: bool = false


func _ready() -> void:
	super()
	_craft_button.pressed.connect(_on_craft_pressed)
	# Guide: the recipe the story points at is selected, now the button.
	GuideFrame.attach(_craft_button, func() -> bool:
		return not _craft_button.disabled and RecipeBrowser.is_guide_target(_selected))
	if uses_minigame:
		_craft_button.text = Language.translate("Schmieden")
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.close_requested.connect(close)
	visibility_changed.connect(_on_visibility_changed)
	GameState.inventory.changed.connect(_on_supplies_changed)
	_browser = RecipeBrowser.new(ContentDB.get_station_recipes(station), uses_categories, _tab_bar, _category_column, _category_list, _recipe_list)
	_browser.recipe_selected.connect(_select)
	if only_with_ingredients:
		_browser.filter = _has_first_ingredient
		_browser.empty_hint = Language.translate("Kein glühendes Metall dabei – erst am Gussofen gießen.")
		GameState.inventory.changed.connect(_refresh_list)
		GameState.storage_chest.changed.connect(_refresh_list)
	# Green / yellow block at every recipe: everything there for it / some of it.
	_browser.supply = func(recipe: RecipeData) -> RecipeBrowser.Supply:
		return RecipeBrowser.get_supply(recipe, [GameState.inventory] + GameState.get_crafting_extras(),
				func(ingredient: Ingredient) -> int: return _placed.count_matching(ingredient.matches, -1, ingredient.min_rarity))
	for source: Resource in [GameState.inventory, GameState.storage_chest]:
		source.changed.connect(func() -> void:
			if visible:
				_browser.update_supply())
	_browser.start()
	_heat_row.visible = uses_heat
	if uses_heat:
		# Faint flame while empty: fuel goes here.
		_heat_slot.placeholder = preload("res://assets/sprites/ui/slot_hints/fire.png")
		_heat_slot.placeholder_tooltip = Language.translate("Brennstoff hineinziehen (Holz = 1, Kohle = 5 Schmiedevorgänge)")
		_heat_slot.set_drag_forwarding(Callable(), _can_drop_fuel, _drop_fuel)
		_heat_slot.gui_input.connect(_on_heat_slot_gui_input)
		_heat_slot.drag_out = true
		GameState.forge_heat_changed.connect(_on_supplies_changed.unbind(1))
	GameState.storage_chest.changed.connect(_on_supplies_changed)
	GameState.recipes_changed.connect(_browser.refresh)


func _select(recipe: RecipeData) -> void:
	if recipe != _selected:
		_close_picker()
		_status_label.text = ""
		_rarities.clear()
		_return_placed()
		_placed = Inventory.new(recipe.ingredients.size() if recipe else 0)
	_selected = recipe
	_fill_from_choices()
	_refresh_details()


## Shows `recipe` as if the player had clicked it in the list.
func select_recipe(recipe: RecipeData) -> void:
	_select(recipe)


## Forge: what lies in the slot of ingredient `index` of the selected recipe (empty slot if none).
func get_placed_slot(index: int) -> InventorySlot:
	return _placed.slots[index] if index < _placed.slots.size() else InventorySlot.new()


## Same answer as _find_first_ingredient(recipe) != null, but asks the kinds of items on hand
## (worked out once per frame) instead of every slot of every chest for each recipe.
func _has_first_ingredient(recipe: RecipeData) -> bool:
	if recipe.ingredients.is_empty():
		return false
	var first: Ingredient = recipe.ingredients[0]
	for item: ItemData in _get_items_on_hand():
		if first.matches(item):
			return true
	return false


## Every kind of item in the inventory and the crafting extras (chests), once per frame.
func _get_items_on_hand() -> Array:
	var frame: int = Engine.get_process_frames()
	if frame != _items_on_hand_frame:
		var items: Dictionary = {}
		for source: Inventory in [GameState.inventory] + GameState.get_crafting_extras():
			for slot in source.slots:
				if not slot.is_empty():
					items[slot.item] = true
		_items_on_hand = items.keys()
		_items_on_hand_frame = frame
	return _items_on_hand


## Filtered list (only_with_ingredients): rebuilt while the window is open, and when it opens.
func _refresh_list() -> void:
	_items_on_hand_frame = -1
	if visible and not _minigame.is_running():
		_browser.refresh()


# --- Details ------------------------------------------------------------------

func _refresh_details() -> void:
	_clear(_ingredient_list)
	if uses_heat:
		var heat: int = GameState.get_forge_heat()
		_heat_slot.display(GameState.forge_fuel)
		_heat_label.text = Language.translate("Hitze: %d Schmiedevorgänge") % heat
		_heat_label.add_theme_color_override("font_color", COLOR_ENOUGH if heat > 0 else COLOR_MISSING)
	if _selected == null:
		_result_name.text = ""
		_result_slot.display(InventorySlot.new())
		_craft_button.disabled = true
		return
	var preview := InventorySlot.new()
	preview.item = _selected.result
	preview.amount = _selected.result_amount
	_result_slot.display(preview)
	_result_name.text = _selected.result.display_name
	for i in _selected.ingredients.size():
		_ingredient_list.add_child(_create_ingredient_row(i))
	_craft_button.disabled = not _can_craft(_selected)
	if uses_heat:
		_craft_button.disabled = _craft_button.disabled or not _has_heat()


func _can_craft(recipe: RecipeData) -> bool:
	return Crafting.can_craft(recipe, GameState.inventory, GameState.get_crafting_extras(), _rarities, _get_placed(recipe))


## The ingredient slots count only for the recipe they were filled for.
func _get_placed(recipe: RecipeData) -> Inventory:
	return _placed if uses_heat and recipe == _selected else null


## Heat left, or fuel the forge can take by itself (inventory / storage chest).
func _has_heat() -> bool:
	return GameState.get_forge_heat() > 0 or GameState.find_forge_fuel() != null


## e.g. "Kupferbarren  3/2 (2 in der Truhe)" and, with several rarities, a button "Alle" / "R2".
func _create_ingredient_row(index: int) -> HBoxContainer:
	var ingredient: Ingredient = _selected.ingredients[index]
	var rarity: int = _rarities.get(index, -1)
	var in_chest: int = Crafting.count_available(ingredient, GameState.get_crafting_extras(), rarity)
	var placed: InventorySlot = _placed.slots[index] if uses_heat and index < _placed.slots.size() else InventorySlot.new()
	var owned: int = GameState.inventory.count_matching(ingredient.matches, rarity, ingredient.min_rarity) + in_chest + placed.amount
	var row := HBoxContainer.new()
	if uses_heat:
		row.add_child(_create_ingredient_slot(index))
	else:
		var icon := TextureRect.new()
		icon.texture = ingredient.get_icon()
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.custom_minimum_size = Vector2(12, 12)
		row.add_child(icon)
	var label := Label.new()
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.text = "%s  %d/%d" % [ingredient.get_display_name(), owned, ingredient.amount]
	if in_chest > 0:
		label.text += Language.translate(" (%d in der Truhe)") % in_chest
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", _ingredient_color(owned >= ingredient.amount, placed, rarity))
	row.add_child(label)
	var rarities: Array[int] = _get_rarities(ingredient)
	if rarities.size() > 1 or rarity >= 0:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.text = Language.translate("Alle") if rarity < 0 else Rarity.get_display_name(rarity as Rarity.Tier)
		if rarity >= 0:
			button.add_theme_color_override("font_color", Rarity.get_color(rarity as Rarity.Tier))
		button.tooltip_text = Language.translate("Welche Seltenheit verbraucht wird (Klick wechselt)")
		button.pressed.connect(_cycle_rarity.bind(index, rarities))
		row.add_child(button)
	return row


## Missing: red. Otherwise the color of the chosen rarity (the bar in the slot, else the
## rarity button), green while "Alle" is chosen and the slot is empty.
func _ingredient_color(enough: bool, placed: InventorySlot, rarity: int) -> Color:
	if not enough:
		return COLOR_MISSING
	if not placed.is_empty():
		return Rarity.get_color(placed.rarity)
	if rarity >= 0:
		return Rarity.get_color(rarity as Rarity.Tier)
	return COLOR_ENOUGH


## Rarities of an ingredient in the inventory and the storage chest, lowest first.
func _get_rarities(ingredient: Ingredient) -> Array[int]:
	var result: Array[int] = []
	for source: Inventory in [GameState.inventory] + GameState.get_crafting_extras():
		for rarity in source.get_matching_rarities(ingredient.matches):
			if not result.has(rarity) and rarity >= ingredient.min_rarity:
				result.append(rarity)
	result.sort()
	return result


## "Alle" -> lowest rarity -> ... -> highest -> "Alle".
func _cycle_rarity(index: int, rarities: Array[int]) -> void:
	var position: int = rarities.find(_rarities.get(index, -1))
	if position + 1 < rarities.size():
		_rarities[index] = rarities[position + 1]
	else:
		_rarities.erase(index)
	_refresh_details()


# --- Crafting / minigame ----------------------------------------------------------

func _on_craft_pressed() -> void:
	if _selected == null or not _can_craft(_selected):
		return
	if uses_minigame:
		_forging_recipe = _selected
		_panel.hide()
		_minigame.start(_find_first_ingredient(_forging_recipe), _forging_recipe.result, 0, true)
	elif uses_heat and not GameState.refuel_forge():
		_status_label.text = Language.translate("Der Gussofen ist kalt – Brennstoff einlegen.")
	else:
		var result: InventorySlot = Crafting.craft(_selected, GameState.inventory, 0, GameState.get_crafting_extras(), _rarities,
				_get_placed(_selected))
		if result:
			if uses_heat:
				GameState.use_forge_heat()
				AudioManager.play_sound("cast_pour")
				_fill_from_choices()
				_refresh_details()
			GameState.achievements.count_material(result)
			_status_label.text = Language.translate("%s hergestellt (%s)") % [
					result.get_display_name(), ForgeQuality.describe(result.rarity, result.quality)]


func _on_minigame_finished(points: int, perfect: bool) -> void:
	_minigame.hide()
	_panel.show()
	var result: InventorySlot = Crafting.craft(_forging_recipe, GameState.inventory, points, GameState.get_crafting_extras(), _rarities,
			_get_placed(_forging_recipe))
	if result:
		GameState.player_stats.add_experience(GameState.player_stats.get_forging_experience(maxi(points, 0)))
		GameState.achievements.count("forge")
		GameState.achievements.count("forge:" + String(result.item.id))
		GameState.achievements.count_material(result)
		if perfect:
			GameState.achievements.count("forge_perfect")
			if not result.item.material_id.is_empty():
				GameState.achievements.count("perfect:" + result.item.material_id)
		_status_label.text = Language.translate("%s geschmiedet (Qualität %+d » %s)") % [
				result.get_display_name(), points, ForgeQuality.describe(result.rarity, result.quality)]
		if result.hot:
			_status_label.text += Language.translate(" – glüht noch, im Wassertrog abkühlen")
	_forging_recipe = null


## Inventory, chest or forge heat changed: the details (ingredient rows, heat) are rebuilt only
## while the window is open; a closed one just remembers it and rebuilds when it opens (every
## anvil and forge of a scene has its own window, all of them heard every change).
func _on_supplies_changed() -> void:
	if visible:
		_refresh_details()
	else:
		_details_stale = true


func _on_visibility_changed() -> void:
	_items_on_hand_frame = -1
	if visible and _fill_from_choices():
		_details_stale = true
	if visible and _details_stale:
		_details_stale = false
		_refresh_details()
	if visible and only_with_ingredients:
		_browser.refresh()
	elif visible:
		_browser.update_supply()
	# Window closed during the minigame: abort, nothing is consumed.
	if not visible and _minigame.is_running():
		_minigame.stop()
		_panel.show()
		_forging_recipe = null
	if not visible:
		_close_picker()
		_return_placed()
		_refresh_details()


func _exit_tree() -> void:
	# Scene change while the window is open: the ingots in the slots go back.
	_return_placed()


# --- Ingredient slots (forge) -----------------------------------------------------

## Slot at the start of an ingredient row: the laid-in stack, or the ingredient faded when empty.
func _create_ingredient_slot(index: int) -> ItemSlotUI:
	var ingredient: Ingredient = _selected.ingredients[index]
	var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	slot_ui.placeholder = ingredient.get_icon()
	slot_ui.placeholder_tooltip = Language.translate("Klicken: %s auswählen (sonst wird einer aus dem Inventar genommen)") % ingredient.get_display_name()
	slot_ui.set_drag_forwarding(Callable(), _can_drop_ingredient.bind(index), _drop_ingredient.bind(index))
	slot_ui.gui_input.connect(_on_ingredient_slot_gui_input.bind(index))
	# display() needs the slot's @onready nodes, so wait until it is in the tree.
	slot_ui.ready.connect(func() -> void: slot_ui.display(_placed.slots[index]), CONNECT_ONE_SHOT)
	return slot_ui


func _can_drop_ingredient(_at_position: Vector2, data: Variant, index: int) -> bool:
	if not uses_heat or _selected == null or index >= _placed.slots.size():
		return false
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	var placed: InventorySlot = _placed.slots[index]
	var ingredient: Ingredient = _selected.ingredients[index]
	if source.is_empty() or source.hot or not ingredient.matches(source.item):
		return false
	# One stack per slot: a second rarity does not fit in.
	return placed.amount < ingredient.amount and (placed.is_empty() or placed.can_stack_with(source))


func _drop_ingredient(_at_position: Vector2, data: Variant, index: int) -> void:
	var inventory_index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var placed: InventorySlot = _placed.slots[index]
	var amount: int = mini(get_move_amount(data, source), _selected.ingredients[index].amount - placed.amount)
	if placed.is_empty():
		placed.copy_properties_from(source)
		placed.amount = amount
	else:
		placed.amount += amount
	GameState.ingot_choice.choose(_selected.ingredients[index], placed)
	GameState.inventory.remove_from_slot(inventory_index, amount)
	_refresh_details()


## Left click: ingot picker; right click: what lies in the slot goes back into the inventory.
func _on_ingredient_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed):
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and not _minigame.is_running():
		var row: Node = _ingredient_list.get_child(index) if index < _ingredient_list.get_child_count() else null
		_open_picker(index, row.get_child(0) as Control if row else null)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_take_out(index)


# --- Ingot picker (forge) -----------------------------------------------------------

## Every stack the ingredient could take, merged when they stack (ItemPicker.collect):
## [{"slot": InventorySlot (a copy with the total amount), "sources": [[Inventory, index], ...],
## "in_chest": bool}], highest rarity first, then highest quality.
func get_picker_entries(index: int) -> Array[Dictionary]:
	var ingredient: Ingredient = _selected.ingredients[index]
	return ItemPicker.collect(func(slot: InventorySlot) -> bool:
		return ingredient.matches(slot.item) and (ingredient.min_rarity < 0 or int(slot.rarity) >= ingredient.min_rarity))


## Lays as many pieces of the entry as the ingredient still needs into its slot (from the
## inventory first, then the chests). Something else in the slot goes back first.
func pick_entry(index: int, entry: Dictionary) -> void:
	var placed: InventorySlot = _placed.slots[index]
	if not placed.is_empty() and not placed.can_stack_with(entry["slot"]):
		_return_placed_slot(index)
		if not placed.is_empty():
			_status_label.text = Language.translate("Kein Platz im Inventar für die Barren im Slot.")
			_refresh_details()
			return
	ItemPicker.take(entry, _selected.ingredients[index].amount - placed.amount, placed)
	GameState.ingot_choice.choose(_selected.ingredients[index], entry["slot"])
	_refresh_details()


func _open_picker(index: int, anchor: Control) -> void:
	_close_picker()
	if _selected == null or index >= _placed.slots.size():
		return
	ItemPicker.open(self, anchor, Language.translate("%s wählen") % _selected.ingredients[index].get_display_name(),
			get_picker_entries(index), not _placed.slots[index].is_empty(),
			# bind() would append the index after the entry, so the order is wrong.
			func(entry: Dictionary) -> void: pick_entry(index, entry),
			func() -> void: _take_out(index),
			Language.translate("Keine passenden Barren dabei."))


func _close_picker() -> void:
	if _picker:
		_picker.close()


## Puts what lies in an ingredient slot back into the inventory (what does not fit stays).
func _return_placed_slot(index: int) -> void:
	var placed: InventorySlot = _placed.slots[index]
	if placed.is_empty():
		return
	var leftover: int = GameState.inventory.add_stack(placed)
	if leftover == 0:
		placed.clear()
	else:
		placed.amount = leftover


func _return_placed() -> void:
	for i in _placed.slots.size():
		_return_placed_slot(i)


## The player takes the ingots out of a slot: they go back and are no longer chosen.
func _take_out(index: int) -> void:
	_return_placed_slot(index)
	GameState.ingot_choice.forget(_selected.ingredients[index])
	_refresh_details()


## Lays the chosen ingots (GameState.ingot_choice) into every slot that still needs some; a chosen
## kind that is nowhere left any more (used up) is forgotten. Returns whether anything moved.
func _fill_from_choices() -> bool:
	if not uses_heat or _selected == null or not visible:
		return false
	var moved: bool = false
	for index in mini(_placed.slots.size(), _selected.ingredients.size()):
		var ingredient: Ingredient = _selected.ingredients[index]
		var sample: InventorySlot = GameState.ingot_choice.find(ingredient)
		var placed: InventorySlot = _placed.slots[index]
		if sample == null or (not placed.is_empty() and not IngotChoice.is_same_kind(placed, sample)):
			continue
		var needed: int = ingredient.amount - placed.amount
		if needed <= 0:
			continue
		var entry: Dictionary = _find_choice_entry(index, sample, placed, needed)
		if not entry.is_empty():
			moved = ItemPicker.take(entry, needed, placed) > 0 or moved
		elif placed.is_empty():
			GameState.ingot_choice.forget_kind(sample)
	return moved


## Picker entry of the chosen kind to fill a slot from: one that stacks with what lies there
## already; into an empty slot the chosen stack itself if there are enough, else the best quality
## of the kind there are enough of, else whatever of the kind is left. {} = none left.
func _find_choice_entry(index: int, sample: InventorySlot, placed: InventorySlot, needed: int) -> Dictionary:
	var kind: Array[Dictionary] = []
	for entry in get_picker_entries(index):
		if IngotChoice.is_same_kind(entry["slot"], sample):
			kind.append(entry)
	if not placed.is_empty():
		for entry in kind:
			if (entry["slot"] as InventorySlot).can_stack_with(placed):
				return entry
		return {}
	for entry in kind:
		if (entry["slot"] as InventorySlot).can_stack_with(sample) and entry["slot"].amount >= needed:
			return entry
	for entry in kind:
		if entry["slot"].amount >= needed:
			return entry
	return kind[0] if not kind.is_empty() else {}


# --- Helpers ------------------------------------------------------------------

## The stack the recipe's first ingredient would be taken from (e.g. the hot blank; inventory
## first, then the storage chest), or null.
func _find_first_ingredient(recipe: RecipeData) -> InventorySlot:
	if recipe.ingredients.is_empty():
		return null
	for source: Inventory in [GameState.inventory] + GameState.get_crafting_extras():
		for slot in source.slots:
			if not slot.is_empty() and recipe.ingredients[0].matches(slot.item):
				return slot
	return null

## Removes all children right away (queue_free alone would keep them until the end of the frame).
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


# --- Forge heat -------------------------------------------------------------------

func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if not uses_heat:
		return false
	if _can_drop_fuel(Vector2.ZERO, data):
		_drop_fuel(Vector2.ZERO, data)
		return true
	for i in _placed.slots.size():
		if _can_drop_ingredient(Vector2.ZERO, data, i):
			_drop_ingredient(Vector2.ZERO, data, i)
			return true
	return false


func _can_drop_fuel(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return not source.is_empty() and GameState.can_add_forge_fuel(source.item)


## Puts the fuel into the heat slot (burned one piece at a time while casting).
func _drop_fuel(_at_position: Vector2, data: Variant) -> void:
	var index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[index]
	var added: int = GameState.add_forge_fuel(source, get_move_amount(data, source))
	GameState.inventory.remove_from_slot(index, added)


## Click on the heat slot: take the unburned fuel back.
func _on_heat_slot_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		GameState.take_forge_fuel()
