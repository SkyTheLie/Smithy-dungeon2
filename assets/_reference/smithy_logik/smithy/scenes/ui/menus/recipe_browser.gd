class_name RecipeBrowser
extends RefCounted
## Recipe navigation shared by station menus (forge, anvil, workbench, enchanting table). Fills
## the given nodes either with one plain recipe list (recipes of a RecipeData.group as one entry), or structured: tabs on top (RecipeData.Tab,
## by default weapon, armor, jewelry, extra) -> categories of the tab (RecipeData.category, e.g.
## "Schwerter") -> after clicking a category its recipes. Emits recipe_selected (null = nothing
## selected). The weapon tab always lists the given weapon types as categories (also those
## without a recipe yet); other categories appear as soon as a recipe uses them.
## Only unlocked recipes are shown (GameState.is_recipe_unlocked); call refresh() when the
## window opens so newly unlocked recipes appear.
## Optional `filter` (Callable recipe -> bool, e.g. anvil: only what there is hot metal for):
## filtered recipes, and categories/tabs without any, are hidden; the first category with
## recipes opens by itself. refresh() keeps the chosen category and recipe when they still exist.
## Guide: a recipe the story guide points at ("recipe:<id>", Guide) glows with a golden frame
## (GuideFrame), and so do its tab and category until they are open; the station menu frames its
## craft button once such a recipe is selected (is_guide_target).
## Optional `supply` (Callable recipe -> Supply): a small block in front of every recipe and
## category shows what the player has for it: green = everything, yellow = some of it, dark = none.
## A category shows its best recipe; call update_supply() when the inventory changed.
## Usage: create it in _ready(), connect recipe_selected, then call start().

signal recipe_selected(recipe: RecipeData)

enum Supply { NONE, SOME, ALL }

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const FONT_SIZE: int = 11
const HINT_FONT_SIZE: int = 11
## Colours of the supply block (Supply order) and its size in pixels (with a 1 px dark rim).
const SUPPLY_COLORS: Array[Color] = [Color(0.3, 0.28, 0.26), Color(0.92, 0.78, 0.25), Color(0.45, 0.82, 0.35)]
const SUPPLY_RIM: Color = Color(0.1, 0.08, 0.07)
const SUPPLY_SIZE: int = 7
static var _supply_icons: Array[Texture2D] = []

var _recipes: Array[RecipeData]
var _uses_categories: bool
var _tab_bar: TabBar
var _category_column: Control
var _category_list: Container
var _recipe_list: Container
## Tabs shown, in this order (index in the TabBar -> RecipeData.Tab).
var _tabs: Array[RecipeData.Tab]
var _weapon_types: Array[WeaponType]
## Only recipes for which this returns true are listed (invalid = all unlocked recipes).
var filter: Callable = Callable()
## Shown when the filter leaves nothing in the current tab.
var empty_hint: String = Language.translate("Noch nichts vorhanden")
## Category and recipe chosen last (kept by refresh()).
var _category: String = ""
var _selected: RecipeData
## What the player has for a recipe (recipe -> Supply); invalid = no blocks.
var supply: Callable = Callable()
## Buttons with a supply block -> the recipes they stand for.
var _supply_buttons: Dictionary = {}
## _get_unlocked() of the frame _unlocked_frame (-1 = work it out again).
var _unlocked_cache: Array[RecipeData] = []
var _unlocked_frame: int = -1


func _init(recipes: Array[RecipeData], uses_categories: bool, tab_bar: TabBar,
		category_column: Control, category_list: Container, recipe_list: Container,
		tabs: Array[RecipeData.Tab] = RecipeData.DEFAULT_TABS, weapon_types: Array[WeaponType] = []) -> void:
	_recipes = recipes
	_uses_categories = uses_categories
	_tab_bar = tab_bar
	_category_column = category_column
	_category_list = category_list
	_recipe_list = recipe_list
	_tabs = tabs
	_weapon_types = weapon_types


func start() -> void:
	if _uses_categories:
		for i in _tabs.size():
			_tab_bar.add_tab(Language.translate(RecipeData.TAB_NAMES[_tabs[i]]))
			var tab: RecipeData.Tab = _tabs[i]
			GuideFrame.attach(_tab_bar, func() -> bool:
				return _tab_bar.current_tab != i and _has_guide_target(func(recipe: RecipeData) -> bool: return recipe.tab == tab),
				func() -> Rect2: return _tab_bar.get_tab_rect(i))
		_tab_bar.tab_changed.connect(_on_tab_changed)
		_on_tab_changed(_tab_bar.current_tab)
	else:
		_tab_bar.hide()
		_category_column.hide()
		_show_recipes(_get_unlocked())


## Rebuilds the lists (e.g. after a recipe was unlocked). With a filter an empty tab switches to
## the first tab that has something.
func refresh() -> void:
	_unlocked_frame = -1
	if _uses_categories:
		var tab_index: int = _tab_bar.current_tab
		if filter.is_valid() and tab_index >= 0 and tab_index < _tabs.size() and not _tab_has_recipes(_tabs[tab_index]):
			for i in _tabs.size():
				if _tab_has_recipes(_tabs[i]):
					tab_index = i
					break
		if tab_index != _tab_bar.current_tab:
			_tab_bar.current_tab = tab_index  # emits tab_changed
		else:
			_on_tab_changed(tab_index)
	else:
		_show_recipes(_get_unlocked(), empty_hint if filter.is_valid() else "")


## Worked out at most once per frame (refresh() asks again): the filter can be slow (e.g. the
## anvil looks through the inventory and every chest per recipe) and the lists and guide frames
## ask many times in a row.
func _get_unlocked() -> Array[RecipeData]:
	var frame: int = Engine.get_process_frames()
	if frame == _unlocked_frame:
		return _unlocked_cache
	var unlocked: Array[RecipeData] = []
	for recipe in _recipes:
		if GameState.is_recipe_unlocked(recipe) and (not filter.is_valid() or filter.call(recipe)):
			unlocked.append(recipe)
	_unlocked_cache = unlocked
	_unlocked_frame = frame
	return unlocked


func _tab_has_recipes(tab: RecipeData.Tab) -> bool:
	return _get_unlocked().any(func(recipe: RecipeData) -> bool: return recipe.tab == tab)


func _on_tab_changed(tab_index: int) -> void:
	# Tabs added by the menu itself (e.g. "Mörser" at the enchanting table) are not ours.
	if tab_index < 0 or tab_index >= _tabs.size():
		return
	var tab: RecipeData.Tab = _tabs[tab_index]
	_clear(_category_list)
	var categories: Array[String] = []
	if tab == RecipeData.Tab.WEAPON:
		for weapon_type in _weapon_types:
			categories.append(weapon_type.display_name)
	for recipe in _get_unlocked():
		if recipe.tab == tab and not categories.has(recipe.get_category()):
			categories.append(recipe.get_category())
	if categories.is_empty():
		_category_list.add_child(_create_hint(empty_hint))
	var group := ButtonGroup.new()
	for category in categories:
		var button: Button = _create_list_button(category, group)
		_add_supply(button, _get_unlocked().filter(func(recipe: RecipeData) -> bool:
				return recipe.tab == tab and recipe.get_category() == category))
		button.pressed.connect(_on_category_selected.bind(tab, category))
		GuideFrame.attach(button, func() -> bool:
			return not button.button_pressed and _has_guide_target(
					func(recipe: RecipeData) -> bool: return recipe.tab == tab and recipe.get_category() == category))
		_category_list.add_child(button)
	# Keep the chosen category; with a filter open the first one right away.
	var open: String = _category if categories.has(_category) else ""
	if open.is_empty() and filter.is_valid() and not categories.is_empty():
		open = categories[0]
	if open.is_empty():
		_show_recipes([], Language.translate("Kategorie wählen") if not categories.is_empty() else "")
		return
	(_category_list.get_child(categories.find(open)) as Button).button_pressed = true
	_on_category_selected(tab, open)


func _on_category_selected(tab: RecipeData.Tab, category: String) -> void:
	_category = category
	var filtered: Array[RecipeData] = []
	for recipe in _get_unlocked():
		if recipe.tab == tab and recipe.get_category() == category:
			filtered.append(recipe)
	var hint: String = Language.translate("Noch keine Rezepte")
	var weapon_type: WeaponType = _find_weapon_type(category) if tab == RecipeData.Tab.WEAPON else null
	if weapon_type:
		hint += "\n(%s)" % weapon_type.get_hands_name()
	_show_recipes(filtered, hint)


func _find_weapon_type(category: String) -> WeaponType:
	for weapon_type in _weapon_types:
		if weapon_type.display_name == category:
			return weapon_type
	return null


## Fills the recipe list and selects the first recipe (or shows `hint` if the list is empty).
## Recipes of a group (RecipeData.group) get one button: the first of them stands for all.
func _show_recipes(all: Array[RecipeData], hint: String = "") -> void:
	_clear(_recipe_list)
	var list: Array[RecipeData] = []
	var groups: Array[String] = []
	for recipe in sorted_by_material(all):
		if recipe.group != "":
			if groups.has(recipe.group):
				continue
			groups.append(recipe.group)
		list.append(recipe)
	var group := ButtonGroup.new()
	for recipe in list:
		var button: Button = _create_list_button(recipe.group if recipe.group != "" else recipe.get_display_name(), group)
		_add_supply(button, all.filter(func(other: RecipeData) -> bool:
				return other == recipe or (recipe.group != "" and other.group == recipe.group)))
		button.pressed.connect(_select.bind(recipe))
		GuideFrame.attach(button, func() -> bool: return not button.button_pressed and is_guide_target(recipe))
		_recipe_list.add_child(button)
	if list.is_empty():
		if hint != "":
			_recipe_list.add_child(_create_hint(hint))
		_select(null)
	else:
		# Keep the chosen recipe (or its group) if it is still there.
		var index: int = list.find(_selected)
		if index < 0 and _selected and _selected.group != "":
			index = list.find_custom(func(recipe: RecipeData) -> bool: return recipe.group == _selected.group)
		index = maxi(index, 0)
		(_recipe_list.get_child(index) as Button).button_pressed = true
		_select(list[index])


## Whether the story guide points at this recipe (or, for a group, at one of its recipes).
static func is_guide_target(recipe: RecipeData) -> bool:
	if recipe == null:
		return false
	if Guide.is_target("recipe:" + String(recipe.id)):
		return true
	if recipe.group.is_empty():
		return false
	for other in ContentDB.get_station_recipes(recipe.station):
		if other.group == recipe.group and Guide.is_target("recipe:" + String(other.id)):
			return true
	return false


## Whether an unlocked recipe that `matches` is a guide target (for its tab or category).
func _has_guide_target(matches: Callable) -> bool:
	if not Guide.has_targets():
		return false
	return _get_unlocked().any(func(recipe: RecipeData) -> bool: return matches.call(recipe) and is_guide_target(recipe))


## Copy of `recipes` sorted by the material of their result, highest first (... bronze, iron,
## copper as in materials.json "tier"). Metals of the same tier (silver and gold) follow their
## order in materials.json, the later one first (gold above silver); otherwise the list order stays.
static func sorted_by_material(recipes: Array[RecipeData]) -> Array[RecipeData]:
	var order: Dictionary = {}
	for i in recipes.size():
		order[recipes[i]] = i
	var metals: Array[String] = ContentDB.get_cast_metals()
	var metal_rank := func(recipe: RecipeData) -> int:
		return metals.find(recipe.result.material_id) if recipe.result else -1
	var sorted: Array[RecipeData] = recipes.duplicate()
	sorted.sort_custom(func(a: RecipeData, b: RecipeData) -> bool:
		return [-get_material_tier(a), -metal_rank.call(a), order[a]] \
				< [-get_material_tier(b), -metal_rank.call(b), order[b]])
	return sorted


## Material tier of a recipe's result (0 without a result).
static func get_material_tier(recipe: RecipeData) -> int:
	return recipe.result.material_tier if recipe.result else 0


func _select(recipe: RecipeData) -> void:
	_selected = recipe
	recipe_selected.emit(recipe)


func _create_list_button(text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _create_hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_HINT)
	return label


## Gives `button` a supply block for the best of `recipes` (nothing without `supply`).
func _add_supply(button: Button, recipes: Array) -> void:
	if not supply.is_valid():
		return
	_supply_buttons[button] = recipes
	_show_supply(button)


## Colours the blocks again (e.g. after the inventory changed), without rebuilding the lists.
func update_supply() -> void:
	for button: Variant in _supply_buttons.keys():
		if is_instance_valid(button):
			_show_supply(button)
		else:
			_supply_buttons.erase(button)


func _show_supply(button: Button) -> void:
	var best: Supply = Supply.NONE
	for recipe: RecipeData in _supply_buttons[button]:
		best = maxi(best, supply.call(recipe)) as Supply
	button.icon = _get_supply_icon(best)
	button.tooltip_text = Language.translate(["Dir fehlt alles dafür.", "Dir fehlt noch etwas.", "Du hast alles dafür."][best])


## How much of `recipe` the player has, counting `sources` (Inventory) and `extra_counter`
## (Callable ingredient -> int, e.g. what already lies in the slots of a window).
static func get_supply(recipe: RecipeData, sources: Array, extra_counter: Callable = Callable()) -> Supply:
	var complete: int = 0
	var some: bool = false
	for ingredient in recipe.ingredients:
		var owned: int = Crafting.count_available(ingredient, sources)
		if extra_counter.is_valid():
			owned += extra_counter.call(ingredient)
		if owned >= ingredient.amount:
			complete += 1
		some = some or owned > 0
	if complete == recipe.ingredients.size():
		return Supply.ALL
	return Supply.SOME if some else Supply.NONE


static func _get_supply_icon(supply_state: Supply) -> Texture2D:
	if _supply_icons.is_empty():
		for color in SUPPLY_COLORS:
			var image := Image.create(SUPPLY_SIZE, SUPPLY_SIZE, false, Image.FORMAT_RGBA8)
			image.fill(SUPPLY_RIM)
			image.fill_rect(Rect2i(1, 1, SUPPLY_SIZE - 2, SUPPLY_SIZE - 2), color)
			_supply_icons.append(ImageTexture.create_from_image(image))
	return _supply_icons[supply_state]


## Removes all children right away (queue_free alone would keep them until the end of the frame).
func _clear(container: Node) -> void:
	for child in container.get_children():
		_supply_buttons.erase(child)
		container.remove_child(child)
		child.queue_free()
