extends StationMenu
## Assembly window (workbench, enchanting table): choose a type (with uses_categories via tabs and categories,
## see RecipeBrowser, e.g. Waffe -> Schwerter -> Schwert), then drag the
## required components from the inventory into the slots and press "Zusammenbauen".
## Right click on an inventory item puts it into the first matching slot.
## A slot accepts every item the ingredient matches (e.g. any blade). An ingredient needed more
## than once gets one slot per piece (cloak: 3 leather slots). The result remembers its parts
## (InventorySlot.components) for name, icon and stats. Rarity and quality come from the placed
## pieces (ForgeQuality.inherit: 50/50 rule for mixed rarities, average quality; wood and rope
## don't count next to metal or leather).
## Components still lying in the slots go back to the inventory when the window closes.
## Left click on any slot (parts, crystal, mortar, vial, enchanting) opens a list of everything that
## fits (ItemPicker: inventory and, at home, the chests, best first); right click empties the slot.
## Choosing a recipe, opening the window and building fill the slots from the inventory by
## themselves (best rarity and quality first); a slot nothing fits stays empty and shows an
## example part faded (e.g. a copper hammer head for "any hammer head"), the preview the item made
## of the examples. "Zusammenbauen" with empty slots tries again; if something is missing, nothing
## is taken and the status says what. A block in front of every recipe and category shows what the
## player has for it (RecipeBrowser.supply: green = all, yellow = some).
## Recipes of a group (RecipeData.group, e.g. the iron staffs) are one entry: the slot that differs
## between them takes any of their items (e.g. any crystal with a known staff recipe), and the
## placed item decides which recipe is built (_get_recipe).
## With has_mortar_tab (enchanting table) an extra tab "Mörser" (3 ingredient slots + a vial slot)
## crushes one ingredient into dust or brews an enchanting potion (Enchanting, mortar.json); a mix
## with a vial that is no recipe gives ash. Every mix with a vial is stirred first (StirringMinigame,
## the grade moves the rarity, see Enchanting.grind); secret potions (Enchanting.is_known) show as
## "???" until brewed once ("Neue Mischung entdeckt!"). The tab "Verzaubern" (RecipeData.Tab.ENCHANT)
## puts a potion's enchantment on a weapon or armor piece.
## With uses_minigame (workbench, bow table, enchanting table) weapons and armor made of two or more
## pieces are joined in the WorkbenchMinigame first (at the enchanting table: crystal into staff):
## a good joining adds quality points, a failed one costs every part points (see Joining) and
## nothing is built; the parts stay in the slots for the next try. How hard the joining is
## depends on the hardest material and the reputation (ForgeQuality.get_difficulty).
## Armor (plate on leather, not shields) is riveted instead (RivetingMinigame), with the same grades.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
## Item type -> name in the achievement counter "made:<type>:<material>".
const SET_TYPES: Dictionary = {
	ItemData.ItemType.WEAPON: "weapon", ItemData.ItemType.HELMET: "helmet", ItemData.ItemType.SHOULDERS: "shoulders",
	ItemData.ItemType.ARMOR: "armor", ItemData.ItemType.GLOVES: "gloves", ItemData.ItemType.BOOTS: "boots",
	ItemData.ItemType.SHIELD: "shield", ItemData.ItemType.CLOAK: "cloak", ItemData.ItemType.LEGS: "legs",
}
const COLOR_DONE: Color = Color(0.55, 0.85, 0.45)
const COLOR_OPEN: Color = Color(0.85, 0.8, 0.7)
## Transparency of the hint icon shown in an empty component slot.
const EMPTY_SLOT_ALPHA: float = 0.35
const FONT_SIZE: int = 11

## Station whose recipes are offered ("workbench", "enchanting_table"). The recipe's
## ingredients become the slots. Its weapon types (weapon_types.json) are always listed.
@export var station: StringName = &"workbench"
## true = tabs + categories, false = one plain list of types.
@export var uses_categories: bool = false
## Tabs shown with uses_categories, in this order. Empty = weapon, armor, jewelry, extra.
@export var tabs: Array[RecipeData.Tab] = []
## true = weapons and armor go through the joining minigame (workbench).
@export var uses_minigame: bool = false
## true = extra tab "Mörser" and the "Verzaubern" tab works (enchanting table).
@export var has_mortar_tab: bool = false

var _selected: RecipeData
## Unlocked recipes of the selected group (empty = the selected recipe has no group).
var _variants: Array[RecipeData] = []
## One entry per slot: the ingredient (amount 1) and the index of its recipe ingredient.
var _slot_ingredients: Array[Ingredient] = []
var _slot_groups: Array[int] = []
## Components placed into the slots, same order as _slot_ingredients.
var _placed: Array[InventorySlot] = []
var _slot_uis: Array[ItemSlotUI] = []
var _slot_labels: Array[Label] = []
var _browser: RecipeBrowser
## Index of the "Mörser" tab (-1 = none), the ingredients lying in its slots and its vial.
var _dust_tab: int = -1
var _dust_placed: Array[InventorySlot] = []
var _dust_slot_uis: Array[ItemSlotUI] = []
var _vial: InventorySlot = InventorySlot.new()
## Index of the "Verzaubern" tab (-1 = none), the item and the potion lying in its slots.
var _enchant_tab: int = -1
var _enchant_target: InventorySlot = InventorySlot.new()
var _enchant_potion: InventorySlot = InventorySlot.new()
## Ingredient -> the item shown for it while its slot is empty (see _get_example).
var _examples: Dictionary = {}

@onready var _tab_bar: TabBar = %TabBar
@onready var _category_column: Control = %CategoryColumn
@onready var _category_list: VBoxContainer = %CategoryList
@onready var _type_list: VBoxContainer = %TypeList
@onready var _component_list: VBoxContainer = %ComponentList
@onready var _result_slot: ItemSlotUI = %ResultSlot
@onready var _result_name: Label = %ResultName
@onready var _assemble_button: Button = %AssembleButton
@onready var _status_label: Label = %StatusLabel
@onready var _panel: Control = $Panel
@onready var _minigame: WorkbenchMinigame = %WorkbenchMinigame
@onready var _riveting: RivetingMinigame = %RivetingMinigame
@onready var _stirring: StirringMinigame = %StirringMinigame
@onready var _columns: Control = %Columns
@onready var _dust_panel: Control = %DustPanel
@onready var _dust_result_slot: ItemSlotUI = %DustResultSlot
@onready var _dust_result_name: Label = %DustResultName
@onready var _mix_button: Button = %MixButton
@onready var _dust_recipes: Label = %DustRecipes
@onready var _vial_slot: ItemSlotUI = %VialSlot
@onready var _enchant_panel: Control = %EnchantPanel
@onready var _target_slot: ItemSlotUI = %TargetSlot
@onready var _potion_slot: ItemSlotUI = %PotionSlot
@onready var _enchant_preview: Label = %EnchantPreview
@onready var _enchant_button: Button = %EnchantButton


func _ready() -> void:
	super()
	_assemble_button.pressed.connect(_on_assemble_pressed)
	# Guide: the recipe the story points at is selected, now the button.
	GuideFrame.attach(_assemble_button, func() -> bool:
		return not _assemble_button.disabled and RecipeBrowser.is_guide_target(_selected))
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.close_requested.connect(close)
	_riveting.finished.connect(_on_minigame_finished)
	_riveting.close_requested.connect(close)
	_stirring.finished.connect(_on_stirring_finished)
	_stirring.close_requested.connect(close)
	visibility_changed.connect(_on_visibility_changed)
	var shown_tabs: Array[RecipeData.Tab] = tabs if not tabs.is_empty() else RecipeData.DEFAULT_TABS
	_browser = RecipeBrowser.new(ContentDB.get_station_recipes(station), uses_categories, _tab_bar,
			_category_column, _category_list, _type_list, shown_tabs, ContentDB.get_weapon_types(station))
	_browser.recipe_selected.connect(_select)
	_browser.supply = _get_supply
	_browser.start()
	GameState.recipes_changed.connect(_browser.refresh)
	GameState.inventory.changed.connect(func() -> void:
		if visible:
			_browser.update_supply())
	_dust_panel.hide()
	_enchant_panel.hide()
	if has_mortar_tab:
		_setup_dust_tab()
		_setup_enchant_tab()


func _exit_tree() -> void:
	# Scene change while the window is open: don't lose the components.
	_return_all_components()
	_return_dust_ingredients()
	_return_enchant_items()


func _on_visibility_changed() -> void:
	if not visible:
		# Closed during the minigame: abort, the parts go back unharmed.
		if _is_minigame_running():
			_minigame.stop()
			_riveting.stop()
			_stirring.stop()
			_panel.show()
		_return_all_components()
		_return_dust_ingredients()
		_return_enchant_items()
		_status_label.text = ""
		_refresh()
	else:
		_browser.update_supply()
		if _columns.visible:
			_prefill()
		if has_mortar_tab:
			_refresh_dust()
			_refresh_enchant()


func _select(assembly: RecipeData) -> void:
	_return_all_components()
	_status_label.text = ""
	_selected = assembly
	_variants.clear()
	if assembly and assembly.group != "":
		for recipe in ContentDB.get_station_recipes(station):
			if recipe.group == assembly.group and GameState.is_recipe_unlocked(recipe):
				_variants.append(recipe)
	_build_component_slots()
	if visible:
		_prefill()
	_refresh()


## Lays the best parts of the inventory into the empty slots; what is missing stays empty.
func _prefill() -> void:
	if _selected == null or _is_minigame_running():
		return
	_fill_from_inventory()
	_refresh()


## How much of `recipe` the player has: inventory plus what already lies in the slots (glowing
## parts don't count, they can't be joined yet).
func _get_supply(recipe: RecipeData) -> RecipeBrowser.Supply:
	return RecipeBrowser.get_supply(recipe, [], _count_usable)


func _count_usable(ingredient: Ingredient) -> int:
	var total: int = 0
	for slot: InventorySlot in GameState.inventory.slots + _placed:
		if not slot.is_empty() and not slot.hot and ingredient.matches(slot.item) \
				and (ingredient.min_rarity < 0 or int(slot.rarity) >= ingredient.min_rarity):
			total += slot.amount
	return total


## An item that fits `ingredient`, to show while its slot is empty: the item itself, the first
## choice of a group, or the matching part of the lowest material (e.g. the copper hammer head).
func _get_example(ingredient: Ingredient) -> ItemData:
	if ingredient.part_type == ItemData.PartType.NONE and ingredient.alternatives.is_empty():
		return ingredient.item
	if not ingredient.alternatives.is_empty():
		return ingredient.alternatives[0]
	if not _examples.has(ingredient):
		var best: ItemData = null
		for item: ItemData in ContentDB.get_all_items():
			if ingredient.matches(item) and item.icon and (best == null or item.material_tier < best.material_tier):
				best = item
		_examples[ingredient] = best
	return _examples[ingredient]


func _build_component_slots() -> void:
	for child in _component_list.get_children():
		child.queue_free()
	_placed.clear()
	_slot_uis.clear()
	_slot_labels.clear()
	_slot_ingredients.clear()
	_slot_groups.clear()
	if _selected == null:
		return
	for group in _selected.ingredients.size():
		var source: Ingredient = _selected.ingredients[group]
		var alternatives: Array[ItemData] = _get_alternatives(group)
		for piece in source.amount:
			var single := Ingredient.new()
			single.item = source.item
			single.part_type = source.part_type
			single.alternatives = alternatives
			single.alternatives_name = _selected.group_slot_name
			_slot_ingredients.append(single)
			_slot_groups.append(group)
	for i in _slot_ingredients.size():
		var row := HBoxContainer.new()
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		var label := Label.new()
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slot_ui)
		row.add_child(label)
		_component_list.add_child(row)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(i), _drop_into.bind(i))
		_placed.append(InventorySlot.new())
		_slot_uis.append(slot_ui)
		_slot_labels.append(label)


## Items of the recipe group that differ at this ingredient (e.g. the crystals), else [].
func _get_alternatives(ingredient_index: int) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for recipe in _variants:
		if ingredient_index < recipe.ingredients.size():
			var item: ItemData = recipe.ingredients[ingredient_index].item
			if item and not items.has(item):
				items.append(item)
	if items.size() <= 1:
		items.clear()
	return items


## The recipe that gets built: the selected one, or in a group the one the placed items fit
## (null while the deciding slot is still empty).
func _get_recipe() -> RecipeData:
	if _variants.size() <= 1:
		return _selected
	for recipe in _variants:
		var fits: bool = true
		for i in _placed.size():
			if _placed[i].is_empty() and _slot_ingredients[i].alternatives.is_empty():
				continue  # the same for every recipe of the group
			var needed: Ingredient = recipe.ingredients[_slot_groups[i]]
			if _placed[i].is_empty() or not needed.matches(_placed[i].item):
				fits = false
				break
		if fits:
			return recipe
	return null


func _refresh() -> void:
	if _selected == null:
		_result_name.text = ""
		_result_slot.display(InventorySlot.new())
		_assemble_button.disabled = true
		return
	for i in _placed.size():
		var ingredient: Ingredient = _slot_ingredients[i]
		var placed: InventorySlot = _placed[i]
		if placed.is_empty():
			# Show the required item faded as a hint (for "any blade" the blade of the lowest material).
			var hint := InventorySlot.new()
			hint.item = _get_example(ingredient)
			hint.amount = 1 if hint.item else 0
			_slot_uis[i].hint_only = true
			_slot_uis[i].display(hint)
			_slot_uis[i].modulate.a = EMPTY_SLOT_ALPHA
		else:
			_slot_uis[i].hint_only = false
			_slot_uis[i].display(placed)
			_slot_uis[i].modulate.a = 1.0
		var done: bool = placed.amount >= ingredient.amount
		var slot_name: String = ingredient.get_display_name()
		if not placed.is_empty():
			slot_name = placed.get_display_name()
		_slot_labels[i].text = "%s  %d/%d" % [slot_name, placed.amount, ingredient.amount]
		_slot_labels[i].add_theme_color_override("font_color", COLOR_DONE if done else COLOR_OPEN)
	# Once all parts are in, the preview shows the composed icon and name (e.g. "Eisenschwert");
	# before that the icon is made of the examples of the missing parts, the name stays general.
	# A group shows its name until the deciding item (e.g. the crystal) is in.
	var recipe: RecipeData = _get_recipe()
	var preview := InventorySlot.new()
	if recipe:
		preview.item = recipe.result
		preview.amount = recipe.result_amount
	if _all_components_placed():
		preview.components = _get_components()
	_result_name.text = preview.get_display_name() if recipe else _selected.group
	if recipe and not _all_components_placed():
		preview.components = _get_components(true)
	_result_slot.display(preview)
	if _all_components_placed():
		_result_name.text += "\n" + _get_chances_text()
	# Empty slots are filled from the inventory when the button is pressed.
	_assemble_button.disabled = false


func _all_components_placed() -> bool:
	for i in _placed.size():
		if _placed[i].amount < _slot_ingredients[i].amount:
			return false
	return true


func _can_drop_into(_at_position: Vector2, data: Variant, index: int) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	var ingredient: Ingredient = _slot_ingredients[index]
	# Glowing parts must be cooled in the water trough first.
	return ingredient.matches(source.item) and not source.hot and _placed[index].amount < ingredient.amount


func _drop_into(_at_position: Vector2, data: Variant, index: int) -> void:
	var inventory_index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var ingredient: Ingredient = _slot_ingredients[index]
	var amount: int = mini(get_move_amount(data, source), ingredient.amount - _placed[index].amount)
	_placed[index].copy_properties_from(source)
	_placed[index].amount += amount
	GameState.inventory.remove_from_slot(inventory_index, amount)
	_refresh()


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed) or _is_minigame_running():
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		open_component_picker(index)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_return_component(index)
		_refresh()


## Everything that fits component slot `index` (ItemPicker entries).
func get_component_entries(index: int) -> Array[Dictionary]:
	var ingredient: Ingredient = _slot_ingredients[index]
	return ItemPicker.collect(func(slot: InventorySlot) -> bool:
		return ingredient.matches(slot.item) and (ingredient.min_rarity < 0 or int(slot.rarity) >= ingredient.min_rarity))


func open_component_picker(index: int) -> void:
	var ingredient: Ingredient = _slot_ingredients[index]
	ItemPicker.open(self, _slot_uis[index], Language.translate("%s wählen") % ingredient.get_display_name(),
			get_component_entries(index), not _placed[index].is_empty(), pick_component.bind(index),
			func() -> void:
				_return_component(index)
				_refresh())


## Lays the entry into component slot `index` (what lay there goes back into the inventory first).
func pick_component(entry: Dictionary, index: int) -> void:
	_pick_into(_placed[index], entry, _slot_ingredients[index].amount)
	_refresh()


## Puts `amount` pieces of a picker entry into `placed`; another item lying there goes back first
## (if the inventory is full it stays and nothing is picked).
func _pick_into(placed: InventorySlot, entry: Dictionary, amount: int) -> void:
	if not placed.is_empty() and not placed.can_stack_with(entry["slot"]):
		_return_stack(placed)
		if not placed.is_empty():
			_status_label.text = Language.translate("Kein Platz im Inventar.")
			return
	ItemPicker.take(entry, amount - placed.amount, placed)
	_status_label.text = ""


## Moves a slot's component back to the inventory. Whatever does not fit stays in the slot.
func _return_component(index: int) -> void:
	var placed: InventorySlot = _placed[index]
	if placed.is_empty():
		return
	var leftover: int = GameState.inventory.add_stack(placed)
	if leftover == 0:
		placed.clear()
	else:
		placed.amount = leftover


func _return_all_components() -> void:
	for i in _placed.size():
		_return_component(i)


func _on_assemble_pressed() -> void:
	if _selected == null:
		return
	if not _all_components_placed() and not _auto_fill():
		_refresh()
		return
	if not _result_fits():
		_status_label.text = Language.translate("Kein Platz im Inventar.")
		return
	if _needs_minigame():
		_panel.hide()
		var difficulty: Dictionary = ForgeQuality.get_difficulty(ForgeQuality.get_hardest_tier(_placed))
		var crystal: InventorySlot = _get_placed_crystal()
		var leather: InventorySlot = _get_placed_leather()
		if _needs_riveting() and leather:
			# Armor: the plate (or the first other piece) is riveted onto the leather.
			var plate: InventorySlot = _placed[0] if _placed[0] != leather else _placed[_placed.size() - 1]
			_riveting.start(plate.get_display_name(), leather.get_display_name(), difficulty,
					plate.get_icon(), leather.get_icon())
		elif crystal:
			# Enchanting table: the crystal comes down from above into the staff.
			var staff: InventorySlot = _placed[0] if _placed[0] != crystal else _placed[_placed.size() - 1]
			_minigame.start(crystal.get_display_name(), staff.get_display_name(), difficulty, _get_crystal_color(),
					null, null, staff.item.material_id)
		else:
			var upper: InventorySlot = _placed[0]
			var lower: InventorySlot = _placed[_placed.size() - 1]
			_minigame.start(upper.get_display_name(), lower.get_display_name(), difficulty, Color.TRANSPARENT,
					upper.get_icon(), lower.get_icon())
	else:
		_assemble(Joining.Grade.OKAY)


func _on_minigame_finished(grade: Joining.Grade) -> void:
	_minigame.hide()
	_riveting.hide()
	_panel.show()
	if grade == Joining.Grade.FAIL:
		Joining.damage_parts(_placed)
		_status_label.text = Language.translate("Fehlgeschlagen – die Teile haben gelitten. Versuch es noch einmal.")
		_refresh()
		return
	_assemble(grade)


## Fills the slots that are not full yet with the best matching items of the inventory.
## If one can't be filled, the pieces taken here go back and the status names what is missing.
func _auto_fill() -> bool:
	var result: Dictionary = _fill_from_inventory()
	var missing: Array[String] = result["missing"]
	if missing.is_empty():
		return true
	for i: int in result["filled"]:
		_return_component(i)
	_status_label.text = Language.translate("Es fehlt: %s.") % ", ".join(missing)
	return false


## Fills every slot that is not full with the best matching items of the inventory, as far as they
## go. Returns {"filled": slot indices that got something, "missing": names of what is still missing}.
func _fill_from_inventory() -> Dictionary:
	var filled: Array[int] = []
	var missing: Array[String] = []
	for i in _placed.size():
		if _placed[i].amount >= _slot_ingredients[i].amount:
			continue
		for index in _get_best_first_indices():
			var data: Dictionary = {"inventory_index": index, "amount": _slot_ingredients[i].amount - _placed[i].amount}
			if _can_drop_into(Vector2.ZERO, data, i):
				_drop_into(Vector2.ZERO, data, i)
				if not filled.has(i):
					filled.append(i)
				if _placed[i].amount >= _slot_ingredients[i].amount:
					break
		if _placed[i].amount < _slot_ingredients[i].amount:
			var slot_name: String = _slot_ingredients[i].get_display_name()
			if not missing.has(slot_name):
				missing.append(slot_name)
	return {"filled": filled, "missing": missing}


## Inventory indices sorted by rarity, then quality (highest first); equal ones keep their order.
func _get_best_first_indices() -> Array[int]:
	var slots: Array[InventorySlot] = GameState.inventory.slots
	var indices: Array[int] = []
	for index in slots.size():
		indices.append(index)
	indices.sort_custom(func(a: int, b: int) -> bool:
		var first: InventorySlot = slots[a]
		var second: InventorySlot = slots[b]
		if first.rarity != second.rarity:
			return first.rarity > second.rarity
		if first.quality != second.quality:
			return first.quality > second.quality
		return a < b)
	return indices


## Builds the item from the placed parts: rarity and quality from the parts (ForgeQuality.inherit),
## plus the points of the joining grade (only with the minigame).
func _assemble(grade: Joining.Grade) -> void:
	var recipe: RecipeData = _get_recipe()
	var start: Dictionary = ForgeQuality.inherit(_get_placed_groups())
	var quality: int = start["quality"]
	var rarity: Rarity.Tier = start["rarity"]
	var result: InventorySlot = Crafting.create_result(
			recipe.result, recipe.result_amount, quality, rarity, _get_components())
	result.crafted = true
	if result.item.is_weapon():
		result.start_history(GameState.day_cycle.day)
	var points: int = ForgeQuality.joining_points(grade) if _needs_minigame() else 0
	if points != 0:
		ForgeQuality.add(result, points)
	if GameState.inventory.get_free_space(result) < result.amount:
		# Inventory full: keep the components in the slots.
		_status_label.text = Language.translate("Kein Platz im Inventar.")
		return
	Socket.try_masterwork(result, GameState.player_stats.get_socket_chance_bonus())
	GameState.inventory.add_stack(result)
	if result.item.is_equipment():
		GameState.item_revealed.emit(result, result.rarity > rarity)
	# Weapons, armor and tools teach more than simple materials (planks, nails, rope ...).
	var stats: PlayerStats = GameState.player_stats
	stats.add_experience(stats.experience_assembling if result.item.is_equipment() else stats.experience_simple_craft)
	_count_achievements(result)
	for placed in _placed:
		placed.clear()
	_status_label.text = Language.translate("%s gebaut (%s)") % [result.get_display_name(), ForgeQuality.describe(result.rarity, result.quality)]
	if points != 0:
		_status_label.text += Language.translate(", Qualität %+d") % points
	if _needs_minigame():
		_status_label.text = "%s! %s" % [Joining.get_display_name(grade).trim_suffix("!"), _status_label.text]
	# ready for the next one
	_fill_from_inventory()
	_browser.update_supply()
	_refresh()


## Weapons and armor made of at least two pieces are joined in the minigame (workbench only).
## The placed crystal (an item whose upgrade gives a resistance, e.g. a ruby), or null.
func _get_placed_crystal() -> InventorySlot:
	for placed in _placed:
		if not placed.is_empty() and placed.item.upgrade and not placed.item.upgrade.resistance_kind.is_empty():
			return placed
	return null


## Colour of the element the result strikes with (iron fire staff: fire red), for the minigame.
func _get_crystal_color() -> Color:
	for kind: String in _get_recipe().result.damage_split:
		if kind != DamageKinds.MAGIC:
			return DamageKinds.get_color(kind)
	return Color(0.4, 0.8, 1.0)


func _needs_minigame() -> bool:
	return (uses_minigame and _selected != null and _placed.size() >= 2
			and (_selected.result.is_weapon() or _selected.result.is_armor()))


## Armor is riveted (RivetingMinigame) instead of joined; a shield (plate + grip) is still joined.
func _needs_riveting() -> bool:
	return _needs_minigame() and _selected.result.is_armor() and _selected.result.type != ItemData.ItemType.SHIELD


## The placed leather (what armor plates are riveted onto), or null.
func _get_placed_leather() -> InventorySlot:
	for placed in _placed:
		if not placed.is_empty() and placed.item.part_type == ItemData.PartType.LEATHER:
			return placed
	return null


func _is_minigame_running() -> bool:
	return _minigame.is_running() or _riveting.is_running() or _stirring.is_running()


func _result_fits() -> bool:
	var recipe: RecipeData = _get_recipe()
	var preview := InventorySlot.new()
	preview.item = recipe.result
	preview.amount = recipe.result_amount
	return GameState.inventory.get_free_space(preview) >= preview.amount



## The placed pieces per recipe ingredient, e.g. [[blade], [handle]] or [[leather, leather, leather]].
func _get_placed_groups() -> Array:
	var groups: Array = []
	groups.resize(_selected.ingredients.size())
	for group in groups.size():
		groups[group] = []
	for i in _placed.size():
		if not _placed[i].is_empty():
			groups[_slot_groups[i]].append(_placed[i])
	return groups


## Rarities of the pieces that count, per ingredient, e.g. [[R2], [R1]] (see ForgeQuality).
func _get_rarity_groups() -> Array:
	return ForgeQuality.get_rarity_groups(ForgeQuality.get_counted_groups(_get_placed_groups()))


## "R1 50 % · R2 50 %"
func _get_chances_text() -> String:
	var chances: Dictionary = Crafting.get_mixed_rarity_chances(_get_rarity_groups())
	var tiers: Array = chances.keys()
	tiers.sort()
	var texts: Array[String] = []
	for tier: int in tiers:
		texts.append("%s %d %%" % [Rarity.get_display_name(tier as Rarity.Tier), roundi(chances[tier] * 100.0)])
	return " · ".join(texts)


## The placed parts in recipe order (e.g. [blade, handle]).
## Parts stored in the result: only weapons, armor and jewelry are composed items (a wooden shaft
## made of wood is a normal part, not a "wood item"), plus tools like the pickaxe, lumber axe and
## watering can (its can body decides how much water it holds).
## `with_examples`: an empty slot counts with its example part (preview icon, see _get_example).
func _get_components(with_examples: bool = false) -> Array[ItemData]:
	var parts: Array[ItemData] = []
	var recipe: RecipeData = _get_recipe()
	if not (recipe and (recipe.result.is_weapon() or recipe.result.is_armor() or recipe.result.is_jewelry()
			or recipe.result.type in [ItemData.ItemType.PICKAXE, ItemData.ItemType.LUMBER_AXE, ItemData.ItemType.WATERING_CAN,
				ItemData.ItemType.BACKPACK])):
		return parts
	for i in _placed.size():
		var item: ItemData = _placed[i].item if not _placed[i].is_empty() else null
		if item == null and with_examples:
			item = _get_example(_slot_ingredients[i])
		# Only real parts (blade, chest plate, leather ...), not extra materials like rope.
		if item and item.part_type != ItemData.PartType.NONE:
			parts.append(item)
	return parts


func try_quick_move(inventory_index: int, amount: int = -1) -> bool:
	if _is_minigame_running():
		return false
	var data: Dictionary = {"inventory_index": inventory_index, "amount": amount}
	if _is_dust_tab_open():
		if _can_drop_vial(Vector2.ZERO, data):
			_drop_vial(Vector2.ZERO, data)
			return true
		for target in _dust_placed.size():
			if _can_drop_dust(Vector2.ZERO, data, target):
				_drop_dust(Vector2.ZERO, data, target)
				return true
		return false
	if _is_enchant_tab_open():
		for into_potion: bool in [false, true]:
			if _can_drop_enchant(Vector2.ZERO, data, into_potion):
				_drop_enchant(Vector2.ZERO, data, into_potion)
				return true
		return false
	for target in range(_placed.size()):
		if _can_drop_into(Vector2.ZERO, data, target):
			_drop_into(Vector2.ZERO, data, target)
			return true
	return false


# --- Mortar (enchanting table) -------------------------------------------------------

func _setup_dust_tab() -> void:
	_tab_bar.add_tab(Language.translate("Mörser"))
	_dust_tab = _tab_bar.tab_count - 1
	_tab_bar.tab_changed.connect(_on_tab_switched)
	_mix_button.pressed.connect(_on_mix_pressed)
	for child in %DustSlots.get_children():
		var slot_ui := child as ItemSlotUI
		var index: int = _dust_slot_uis.size()
		slot_ui.gui_input.connect(_on_dust_slot_gui_input.bind(index))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop_dust.bind(index), _drop_dust.bind(index))
		_dust_slot_uis.append(slot_ui)
		_dust_placed.append(InventorySlot.new())
	# Empty: the vial faded, so it's clear what goes in.
	_vial_slot.placeholder = ContentDB.mortar_item("vial").icon if ContentDB.mortar_item("vial") else null
	_vial_slot.placeholder_tooltip = Language.translate("Phiole hineinlegen")
	_vial_slot.gui_input.connect(_on_vial_slot_gui_input)
	_vial_slot.drag_out = true
	_vial_slot.set_drag_forwarding(Callable(), _can_drop_vial, _drop_vial)
	_refresh_dust()


func _is_dust_tab_open() -> bool:
	return _dust_tab >= 0 and _tab_bar.current_tab == _dust_tab


func _on_tab_switched(tab: int) -> void:
	var dust: bool = tab == _dust_tab
	var enchant: bool = tab == _enchant_tab
	_columns.visible = not dust and not enchant
	_dust_panel.visible = dust
	_enchant_panel.visible = enchant
	_status_label.text = ""
	if dust or enchant:
		_return_all_components()
	if not dust:
		_return_dust_ingredients()
	if not enchant:
		_return_enchant_items()
	_refresh()
	_refresh_dust()
	_refresh_enchant()


## The inventory stack being dragged / right-clicked (null = none, or glowing).
func _source_of(data: Variant) -> InventorySlot:
	if not (data is Dictionary and data.has("inventory_index")):
		return null
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return null if source.is_empty() or source.hot else source


func _is_vial(item: ItemData) -> bool:
	return item == ContentDB.mortar_item("vial")


func _can_drop_dust(_at_position: Vector2, data: Variant, index: int) -> bool:
	var source: InventorySlot = _source_of(data)
	return source != null and not source.item.is_equipment() and not _is_vial(source.item) and _dust_placed[index].is_empty()


## One piece per slot (the same item twice = two slots).
func _drop_dust(_at_position: Vector2, data: Variant, index: int) -> void:
	_take_one(data["inventory_index"], _dust_placed[index])
	_status_label.text = ""
	_refresh_dust()


func _can_drop_vial(_at_position: Vector2, data: Variant) -> bool:
	var source: InventorySlot = _source_of(data)
	return source != null and _is_vial(source.item) and _vial.is_empty()


func _drop_vial(_at_position: Vector2, data: Variant) -> void:
	_take_one(data["inventory_index"], _vial)
	_status_label.text = ""
	_refresh_dust()


## Moves one piece of an inventory stack into `into`.
func _take_one(inventory_index: int, into: InventorySlot) -> void:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	into.copy_properties_from(source)
	into.amount = 1
	GameState.inventory.remove_from_slot(inventory_index, 1)


func _on_dust_slot_gui_input(event: InputEvent, index: int) -> void:
	if _is_left_click(event):
		var placed: InventorySlot = _dust_placed[index]
		_open_slot_picker(_dust_slot_uis[index], Language.translate("Zutat wählen"), placed,
				_fits_mortar_list,
				_refresh_dust)
	elif _is_click(event):
		_return_stack(_dust_placed[index])
		_refresh_dust()


func _on_vial_slot_gui_input(event: InputEvent) -> void:
	if _is_left_click(event):
		_open_slot_picker(_vial_slot, Language.translate("Phiole wählen"), _vial,
				func(slot: InventorySlot) -> bool: return _is_vial(slot.item), _refresh_dust)
	elif _is_click(event):
		_return_stack(_vial)
		_refresh_dust()


## Picker for a one-piece slot (mortar, vial, enchanting): `accepts` decides what is listed.
func _open_slot_picker(anchor: Control, title: String, placed: InventorySlot, accepts: Callable, refresh: Callable) -> void:
	if _is_minigame_running():
		return
	ItemPicker.open(self, anchor, title, ItemPicker.collect(accepts), not placed.is_empty(),
			func(entry: Dictionary) -> void:
				_pick_into(placed, entry, 1)
				refresh.call(),
			func() -> void:
				_return_stack(placed)
				refresh.call())


## What the mortar slots list: things that do something in the mortar (no equipment, no vial).
func _fits_mortar_list(slot: InventorySlot) -> bool:
	return not slot.item.is_equipment() and not _is_vial(slot.item) and Enchanting.is_mortar_ingredient(slot.item)


func _is_left_click(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT


func _is_click(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]


func _return_stack(placed: InventorySlot) -> void:
	if placed.is_empty():
		return
	if GameState.inventory.add_stack(placed) == 0:
		placed.clear()


func _return_dust_ingredients() -> void:
	for placed in _dust_placed:
		_return_stack(placed)
	_return_stack(_vial)


## The item the mortar would make (null = nothing).
func _get_mortar_result(plan: Dictionary) -> ItemData:
	match plan["kind"]:
		"dust":
			return (plan["dust"] as DustData).item
		"potion":
			return (plan["potion"] as PotionData).item
		"brew":
			return (plan["brew"] as BrewData).item
		"fail":
			return ContentDB.mortar_item("failed")
	return null


func _refresh_dust() -> void:
	if _dust_tab < 0:
		return
	for i in _dust_placed.size():
		_dust_slot_uis[i].display(_dust_placed[i])
	_vial_slot.display(_vial)
	var plan: Dictionary = Enchanting.get_mortar_plan(_dust_placed, _vial)
	var preview := InventorySlot.new()
	if plan["kind"] in ["dust", "potion", "brew"] and _is_plan_known(plan):
		preview.item = _get_mortar_result(plan)
		preview.amount = 1
		_dust_result_name.text = preview.item.display_name
		if plan.get("strong", false):
			_dust_result_name.text += " (stark)"
	else:
		_dust_result_name.text = "???" if plan["kind"] in ["fail", "potion"] else plan.get("text", "")
	_dust_result_slot.display(preview)
	_mix_button.disabled = plan["kind"] == ""
	_mix_button.text = Language.translate("Zerkleinern") if plan["kind"] == "dust" else Language.translate("Rühren")
	_dust_recipes.text = "\n".join(_get_mortar_lines())


## A secret potion shows only once it was brewed (Enchanting.is_known).
func _is_plan_known(plan: Dictionary) -> bool:
	return plan["kind"] != "potion" or Enchanting.is_known(plan["potion"], GameState.story)


## The short hint below the mortar: how crushing works, the moon, and where the recipes are (the
## full list of potions stands in the recipe book, not here).
func _get_mortar_lines() -> Array[String]:
	var lines: Array[String] = [Language.translate("Zerkleinern: ein Kristall oder eine Pflanze allein ergibt Staub (gleiche Seltenheit).")]
	if not GameState.story.has_flag(Enchanting.BOOK_FLAG):
		return lines
	var day: int = GameState.day_cycle.day
	if GameCalendar.is_full_moon(day):
		lines.append(Language.translate("Heute ist Vollmond: Verzauberungstränke werden eine Seltenheit besser."))
	else:
		lines.append(Language.translate("Nächster Vollmond in %d Tagen (Tränke dann eine Seltenheit besser).") % GameCalendar.get_days_to_full_moon(day))
	lines.append(Language.translate("Alle Trank-Rezepte stehen im Rezeptbuch."))
	return lines


## Dust is crushed at once; everything with a vial is stirred first (StirringMinigame).
func _on_mix_pressed() -> void:
	var plan: Dictionary = Enchanting.get_mortar_plan(_dust_placed, _vial)
	var preview := InventorySlot.new()
	preview.item = _get_mortar_result(plan)
	if preview.item == null:
		return
	preview.amount = 1
	if GameState.inventory.get_free_space(preview) < 1:
		_status_label.text = Language.translate("Kein Platz im Inventar.")
		return
	if plan["kind"] == "dust":
		_brew(Enchanting.Stir.GOOD)
		return
	_panel.hide()
	_stirring.start(preview.item.display_name if plan["kind"] != "fail" and _is_plan_known(plan) else Language.translate("Die Mischung"))


func _on_stirring_finished(grade: Enchanting.Stir) -> void:
	_stirring.hide()
	_panel.show()
	_brew(grade)


## Makes what lies in the mortar (`stir` = grade of the stirring) and tells what came out.
func _brew(stir: Enchanting.Stir) -> void:
	var plan: Dictionary = Enchanting.get_mortar_plan(_dust_placed, _vial)
	var result: InventorySlot = Enchanting.grind(_dust_placed, _vial, stir, GameState.day_cycle.day)
	if result == null:
		return
	GameState.inventory.add_stack(result)
	var made: String = "%s (%s)" % [result.item.display_name, Rarity.get_display_name(result.rarity)]
	var notes: Array[String] = []
	if plan["kind"] in ["potion", "brew"] and stir != Enchanting.Stir.GOOD:
		notes.append(Language.translate(Enchanting.STIR_NAMES[stir]))
	match plan["kind"]:
		"dust":
			_status_label.text = Language.translate("%s zerkleinert.") % made
		"potion":
			var potion: PotionData = plan["potion"]
			if plan.get("strong", false):
				notes.append(Language.translate("doppelter Kristall"))
			if GameCalendar.is_full_moon(GameState.day_cycle.day):
				notes.append(Language.translate("Vollmond"))
			var discovered: bool = not Enchanting.is_known(potion, GameState.story)
			GameState.story.set_flag(Enchanting.FOUND_FLAG % potion.id)
			GameState.story.set_flag("potion_made")
			GameState.achievements.count("potion")
			_status_label.text = Language.translate("%s gebraut.") % made
			if discovered:
				_status_label.text = Language.translate("Neue Mischung entdeckt: %s! Steht jetzt im Rezeptbuch.") % made
				GameState.show_message(Language.translate("Neue Mischung entdeckt: %s") % potion.display_name)
		"brew":
			if result.item.hero_potion == "iq":
				GameState.story.set_flag("iq_potion_made")
			GameState.achievements.count("potion")
			_status_label.text = Language.translate("%s gebraut.") % made
		_:
			_status_label.text = Language.translate("Misslungen – übrig bleibt nur Asche.")
	if not notes.is_empty() and plan["kind"] != "fail":
		_status_label.text += " (%s)" % ", ".join(notes)
	_refresh_dust()


# --- Enchanting (tab "Verzaubern") -----------------------------------------------------

func _setup_enchant_tab() -> void:
	var shown_tabs: Array[RecipeData.Tab] = tabs if not tabs.is_empty() else RecipeData.DEFAULT_TABS
	_enchant_tab = shown_tabs.find(RecipeData.Tab.ENCHANT)
	if _enchant_tab < 0:
		return
	_enchant_button.pressed.connect(_on_enchant_pressed)
	for entry: Array in [[_target_slot, false], [_potion_slot, true]]:
		var slot_ui: ItemSlotUI = entry[0]
		slot_ui.gui_input.connect(_on_enchant_slot_gui_input.bind(entry[1]))
		slot_ui.drag_out = true
		slot_ui.set_drag_forwarding(Callable(), _can_drop_enchant.bind(entry[1]), _drop_enchant.bind(entry[1]))
	_on_tab_switched(_tab_bar.current_tab)


func _is_enchant_tab_open() -> bool:
	return _enchant_tab >= 0 and _tab_bar.current_tab == _enchant_tab


func _can_drop_enchant(_at_position: Vector2, data: Variant, into_potion: bool) -> bool:
	var source: InventorySlot = _source_of(data)
	if source == null:
		return false
	if into_potion:
		return _enchant_potion.is_empty() and Enchanting.is_potion(source.item)
	return _enchant_target.is_empty() and (source.item.is_weapon() or source.item.is_armor())


func _drop_enchant(_at_position: Vector2, data: Variant, into_potion: bool) -> void:
	_take_one(data["inventory_index"], _enchant_potion if into_potion else _enchant_target)
	_status_label.text = ""
	_refresh_enchant()


func _on_enchant_slot_gui_input(event: InputEvent, into_potion: bool) -> void:
	if _is_left_click(event):
		if into_potion:
			_open_slot_picker(_potion_slot, Language.translate("Trank wählen"), _enchant_potion,
					func(slot: InventorySlot) -> bool: return Enchanting.is_potion(slot.item), _refresh_enchant)
		else:
			_open_slot_picker(_target_slot, Language.translate("Waffe oder Rüstung wählen"), _enchant_target,
					func(slot: InventorySlot) -> bool: return slot.item.is_weapon() or slot.item.is_armor(), _refresh_enchant)
	elif _is_click(event):
		_return_stack(_enchant_potion if into_potion else _enchant_target)
		_refresh_enchant()


func _return_enchant_items() -> void:
	_return_stack(_enchant_target)
	_return_stack(_enchant_potion)


func _refresh_enchant() -> void:
	if _enchant_tab < 0:
		return
	_target_slot.display(_enchant_target)
	_potion_slot.display(_enchant_potion)
	var blocker: String = Enchanting.get_blocker(_enchant_target, _enchant_potion)
	_enchant_button.disabled = blocker != ""
	if blocker != "":
		_enchant_preview.text = blocker
		return
	_enchant_preview.text = Enchanting.get_preview_text(_enchant_target, _enchant_potion)


func _on_enchant_pressed() -> void:
	var rarity: Rarity.Tier = _enchant_potion.rarity
	var quality_potion: bool = Enchanting.is_quality_potion(_enchant_potion.item)
	var reroll_potion: bool = Enchanting.is_reroll_potion(_enchant_potion.item)
	var rarity_before: Rarity.Tier = _enchant_target.rarity
	var text: String = Enchanting.use_potion(_enchant_target, _enchant_potion)
	if text.is_empty():
		return
	if reroll_potion:
		# The piece stays on the table, so the next potion can roll it again right away.
		_status_label.text = text
		_refresh_enchant()
		return
	if quality_potion:
		GameState.item_revealed.emit(_enchant_target, _enchant_target.rarity > rarity_before)
	else:
		for counter in Enchanting.get_counters(rarity):
			GameState.achievements.count(counter)
		GameState.story.set_flag("item_enchanted")
	_status_label.text = text
	# The enchanted item goes straight back into the inventory.
	_return_stack(_enchant_target)
	_refresh_enchant()


## Achievement counters: "craft", "craft:<item>" and for equipment "made:<type>:<material>"
## (sets, see achievements.json).
func _count_achievements(result: InventorySlot) -> void:
	GameState.achievements.count("craft")
	GameState.achievements.count("craft:" + String(result.item.id))
	var type: String = SET_TYPES.get(result.item.type, "")
	if not type.is_empty():
		GameState.achievements.count("made:%s:%s" % [type, Hero.get_gear_material(result, true)])
