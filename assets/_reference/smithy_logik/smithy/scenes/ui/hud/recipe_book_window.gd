class_name RecipeBookWindow
extends PanelContainer
## The player's recipe book (E at the nightstand in the bedroom, see RecipeBookStand, or right
## click on Aurelius' book): every recipe the player has found so far, sorted by station (one tab each), with "x / y gefunden". Left the
## list (grouped by category), right what the selected recipe needs and makes. The tab
## "Mörser" lists the enchanting potions once the player has Aurelius' notes (Enchanting.BOOK_FLAG).

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.45)
const FONT_SIZE: int = 11
const ICON_SIZE: int = 12
## Tab "Mörser" (after the station tabs).
const DUST_TAB: String = "Mörser"
## Station tabs: station id -> tab name (order = order of the tabs).
const STATIONS: Dictionary = {
	&"forge": "Gussofen",
	&"anvil": "Amboss",
	&"workbench": "Werkbank",
	&"bow_table": "Bogentisch",
	&"enchanting_table": "Zaubertisch",
}

@onready var _tab_bar: TabBar = %TabBar
@onready var _count_label: Label = %CountLabel
@onready var _list: VBoxContainer = %RecipeList
@onready var _details: VBoxContainer = %Details

var _tab_names: Array[String] = []


func _ready() -> void:
	for station: StringName in STATIONS:
		_tab_names.append(Language.translate(STATIONS[station]))
	_tab_names.append(Language.translate(DUST_TAB))
	for tab_name in _tab_names:
		_tab_bar.add_tab(tab_name)
	_tab_bar.tab_changed.connect(func(_index: int) -> void: _refresh())
	visibility_changed.connect(_refresh)
	GameState.recipes_changed.connect(_refresh)


## Opens the book at a tab (e.g. "Mörser" for Aurelius' book).
func open_tab(tab_name: String) -> void:
	var index: int = _tab_names.find(tab_name)
	if index >= 0:
		_tab_bar.current_tab = index
	show()
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	_clear(_list)
	_clear(_details)
	var tab_name: String = _tab_names[_tab_bar.current_tab]
	if tab_name == DUST_TAB:
		_show_dusts()
	else:
		_show_station(STATIONS.keys()[_tab_bar.current_tab])


func _show_station(station: StringName) -> void:
	var all: Array[RecipeData] = ContentDB.get_station_recipes(station)
	var known: Array[RecipeData] = all.filter(func(recipe: RecipeData) -> bool: return GameState.is_recipe_unlocked(recipe))
	# A group (e.g. the nine iron staffs, one per crystal) is one entry, like rings and amulets.
	all = RecipeData.collapse_groups(all)
	known = RecipeData.collapse_groups(known)
	known.sort_custom(func(a: RecipeData, b: RecipeData) -> bool:
		return [a.tab, a.get_category(), RecipeBrowser.get_material_tier(a), a.get_list_name()] 				< [b.tab, b.get_category(), RecipeBrowser.get_material_tier(b), b.get_list_name()])
	_count_label.text = Language.translate("%d / %d gefunden") % [known.size(), all.size()]
	if known.is_empty():
		_list.add_child(_make_label(Language.translate("Noch keine Rezepte."), COLOR_HINT))
		return
	var group := ButtonGroup.new()
	var header: String = ""
	var first: Button = null
	for recipe in known:
		var category: String = "%s » %s" % [Language.translate(RecipeData.TAB_NAMES[recipe.tab]), recipe.get_category()]
		if category != header:
			header = category
			_list.add_child(_make_label(category, COLOR_HEADER))
		var button: Button = _make_button(recipe.get_list_name(), recipe.get_icon(), group)
		button.pressed.connect(_show_recipe.bind(recipe))
		_list.add_child(button)
		if first == null:
			first = button
	first.button_pressed = true
	_show_recipe(known[0])


func _show_recipe(recipe: RecipeData) -> void:
	_clear(_details)
	var result_name: String = recipe.get_list_name()
	if recipe.result_amount > 1:
		result_name += Language.translate(" (%d Stück)") % recipe.result_amount
	_details.add_child(_make_row(result_name, recipe.get_icon(), COLOR_HEADER))
	_details.add_child(_make_label("Wo: %s" % Language.translate(STATIONS.get(recipe.station, String(recipe.station))), COLOR_HINT))
	_details.add_child(_make_label("Du brauchst:"))
	var choices: Dictionary = _group_choices(recipe)
	for i in recipe.ingredients.size():
		var ingredient: Ingredient = recipe.ingredients[i]
		if choices.has(i):
			# The slot that differs within the group: "1× Kristall (Rubin, Saphir ...)".
			_details.add_child(_make_row("%d× %s (%s)" % [ingredient.amount, recipe.group_slot_name, ", ".join(choices[i])],
					ingredient.get_icon()))
		else:
			_details.add_child(_make_row("%d× %s" % [ingredient.amount, ingredient.get_display_name()], ingredient.get_icon()))
	if recipe.result_is_hot:
		_details.add_child(_make_label(Language.translate("Kommt glühend heraus: im Wassertrog abkühlen."), COLOR_HINT))
	if recipe.result and not recipe.result.description.is_empty() and recipe.group.is_empty():
		_details.add_child(_make_label(recipe.result.description, COLOR_HINT))


## Ingredient index -> names of the known items that differ at it within the recipe's group (e.g.
## the crystals of the iron staffs), {} without a group.
func _group_choices(recipe: RecipeData) -> Dictionary:
	var choices: Dictionary = {}
	if recipe.group.is_empty():
		return choices
	var members: Array[RecipeData] = ContentDB.get_station_recipes(recipe.station).filter(func(other: RecipeData) -> bool:
		return other.group == recipe.group and GameState.is_recipe_unlocked(other))
	for i in recipe.ingredients.size():
		var names: Array[String] = []
		for other in members:
			if i < other.ingredients.size() and other.ingredients[i].item:
				var item_name: String = other.ingredients[i].item.display_name
				if not names.has(item_name):
					names.append(item_name)
		if names.size() > 1:
			choices[i] = names
	return choices


func _show_dusts() -> void:
	var all: Array[PotionData] = ContentDB.get_potions()
	var known: bool = GameState.story.has_flag(Enchanting.BOOK_FLAG)
	# Secret potions (other plants, combos) only once brewed (Enchanting.is_known).
	var shown: Array[PotionData] = []
	shown.assign(all.filter(func(potion: PotionData) -> bool: return Enchanting.is_known(potion, GameState.story)))
	_count_label.text = Language.translate("%d / %d gefunden") % [shown.size() if known else 0, all.size()]
	# The other brews of the mortar (Hexentrank, Sternentau ...), known ones only.
	var brews: Array[BrewData] = []
	brews.assign(ContentDB.get_brews().filter(func(brew: BrewData) -> bool: return brew.is_known() and brew.item != null))
	if not known and brews.is_empty():
		_list.add_child(_make_label(Language.translate("Noch keine Trank-Rezepte. Vielleicht weiß Meister Aurelius mehr."), COLOR_HINT))
		return
	var group := ButtonGroup.new()
	var first: Button = null
	if known:
		for potion in shown:
			var button: Button = _make_button(potion.display_name, potion.item.icon if potion.item else null, group)
			button.pressed.connect(_show_potion.bind(potion))
			_list.add_child(button)
			if first == null:
				first = button
	if not brews.is_empty():
		_list.add_child(_make_label(Language.translate("Weitere Tränke"), COLOR_HEADER))
		for brew in brews:
			var button: Button = _make_button(brew.item.display_name, brew.item.icon, group)
			button.pressed.connect(_show_brew.bind(brew))
			_list.add_child(button)
			if first == null:
				first = button
	if first:
		first.button_pressed = true
		first.pressed.emit()


func _show_brew(brew: BrewData) -> void:
	_clear(_details)
	_details.add_child(_make_row(brew.item.display_name, brew.item.icon, COLOR_HEADER))
	_details.add_child(_make_label(Language.translate("Wo: Zaubertisch, Reiter Mörser"), COLOR_HINT))
	_details.add_child(_make_label("Du brauchst:"))
	for ingredient: ItemData in brew.ingredients + [ContentDB.mortar_item("vial")]:
		if ingredient:
			_details.add_child(_make_row(ingredient.display_name, ingredient.icon))
	_details.add_child(_make_label(Language.translate("Statt Kristall und Pflanze geht auch ihr Staub (im Mörser zerkleinert)."), COLOR_HINT))
	if not brew.item.description.is_empty():
		_details.add_child(_make_label(brew.item.description, COLOR_HINT))


func _show_potion(potion: PotionData) -> void:
	_clear(_details)
	var vial: ItemData = ContentDB.mortar_item("vial")
	_details.add_child(_make_row(potion.display_name, potion.item.icon if potion.item else null, COLOR_HEADER))
	_details.add_child(_make_label(Language.translate("Wo: Zaubertisch, Reiter Mörser"), COLOR_HINT))
	_details.add_child(_make_label("Du brauchst:"))
	for ingredient: ItemData in potion.get_ingredients() + [vial]:
		if ingredient:
			_details.add_child(_make_row(ingredient.display_name, ingredient.icon))
	_details.add_child(_make_label(Language.translate("Statt Kristall und Pflanze geht auch ihr Staub (im Mörser zerkleinert)."), COLOR_HINT))
	_details.add_child(_make_label(Language.translate("Wirkung (Stufe = Seltenheit des Tranks), z. B. Gewöhnlich:\n") + potion.describe(Rarity.Tier.COMMON), COLOR_HINT))


func _make_button(text: String, icon: Texture2D, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = icon
	button.expand_icon = false
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	return button


func _make_row(text: String, icon: Texture2D, color: Color = Color.WHITE) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	if icon:
		var picture := TextureRect.new()
		picture.texture = icon
		picture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(picture)
	var label: Label = _make_label(text, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	return label


## Removes all children right away (queue_free alone would keep them until the end of the frame).
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
