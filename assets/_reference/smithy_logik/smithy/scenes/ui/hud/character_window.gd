class_name CharacterWindow
extends PanelContainer
## Character window of the player (key C), built like the hero window (HeroWindow):
## top player name | level, below the switch "Ausrüstung" / "Fähigkeiten" / "Gussformen" / "Rezepte" / "Erfolge" / "Ruhm" with sliding
## pages. Equipment: 6 slots around the silhouette (pickaxe, gloves, backpack, axe, shoes, recipe book;
## drag in from the inventory, click to take off; a left click on the book opens it), on the right the work values (mining, chopping,
## forging; bonuses in green), the reputation (crest with the rank, points, bar; details on hover)
## and the experience bar. Skills: the smith's tree (hover for details,
## click to learn) and the free skill points. Molds: all known molds (forge recipes "mold_<part>"). Recipes: the known
## potions (mortar.json), a click opens their recipe page (potion_recipe_selected). Achievements: one block per
## category (achievements.json) with a tile per achievement (AchievementTile, hover for details).
## Fame: the famous weapons (most kills, with nickname and who carries them) and the masterpieces
## (best piece of every type ever finished, Fame).

## A potion of the tab "Rezepte" was clicked (the HUD opens its PotionRecipeWindow).
signal potion_recipe_selected(potion_item: ItemData)

const COLOR_BONUS: Color = Color(0.55, 0.85, 0.45)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.5)
const COLOR_EXPERIENCE: Color = Color(0.62, 0.38, 0.78)
const COLOR_BAR_BACK: Color = Color(0.13, 0.075, 0.12)
const COLOR_REPUTATION: Color = Color(0.85, 0.65, 0.3)
const COLOR_LOCKED: Color = Color(0.62, 0.6, 0.56)
const SKILL_BACKGROUND: Texture2D = preload("res://assets/sprites/ui/skill_trees/smith.png")
const ACTIVE_TAB_RATIO: float = 3.0
## Achievement tiles per row.
const ACHIEVEMENT_COLUMNS: int = 7
## A smaller backpack would leave items without a place.
const BACKPACK_FULL_TEXT: String = "Im Rucksack liegt zu viel. Räum erst Plätze im Inventar frei."
## Slot centres around the silhouette, same order as PlayerStats.ToolSlot.
const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(16, 74),   # pickaxe (right hand)
	Vector2(16, 44),   # gloves
	Vector2(104, 44),  # backpack
	Vector2(104, 74),  # axe (left hand)
	Vector2(60, 122),  # shoes
	Vector2(104, 122), # book (click opens the recipe book)
]

var _slot_uis: Array[ItemSlotUI] = []
var _crest: ReputationCrest
var _reputation_label: Label
var _reputation_bar: ProgressBar

@onready var _stats: PlayerStats = GameState.player_stats
@onready var _class_label: Label = %ClassLabel
@onready var _tabs: Array[Button] = [%EquipmentTab, %SkillsTab, %RecipesTab, %KnownRecipesTab, %AchievementsTab, %FameTab]
@onready var _pages: SlidingPages = %Pages
@onready var _doll: EquipmentDoll = %Doll
@onready var _stats_label: RichTextLabel = %StatsLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _experience_bar: ProgressBar = %ExperienceBar
@onready var _skill_tree: SkillTreeView = %SkillTree
@onready var _skill_points_label: Label = %SkillPointsLabel
@onready var _recipes_label: Label = %RecipesLabel
@onready var _known_recipes_list: VBoxContainer = %KnownRecipesList
@onready var _achievement_list: VBoxContainer = %AchievementList
@onready var _fame_label: RichTextLabel = %FameLabel


func _ready() -> void:
	add_to_group(EquipmentDoll.QUICK_EQUIP_GROUP)
	var group := ButtonGroup.new()
	for i in _tabs.size():
		_tabs[i].button_group = group
		_tabs[i].pressed.connect(_select_tab.bind(i))
	_select_tab(0)
	for slot in PlayerStats.ToolSlot.values():
		var hint: String = String(PlayerStats.ToolSlot.keys()[slot]).to_lower()
		var slot_ui: ItemSlotUI = _doll.add_slot(SLOT_POSITIONS[slot], Language.translate(PlayerStats.TOOL_NAMES[slot]), hint)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(slot))
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(slot), _drop_into.bind(slot))
		_slot_uis.append(slot_ui)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_EXPERIENCE
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BAR_BACK
	_experience_bar.add_theme_stylebox_override("fill", fill)
	_experience_bar.add_theme_stylebox_override("background", back)
	_stats.experience_changed.connect(_refresh_if_visible)
	_stats.stats_changed.connect(_refresh_if_visible)
	GameState.recipes_changed.connect(_refresh_if_visible)
	GameState.reputation.changed.connect(_refresh_if_visible)
	_build_reputation_box()
	GameState.achievements.changed.connect(_refresh_if_visible)
	GameState.ranking.changed.connect(_refresh_if_visible)
	visibility_changed.connect(_refresh_if_visible)
	# Text size of the values (settings » "Textgröße: Werte"); the page grows when they need more room.
	var equipment_page := _pages.get_node("EquipmentPage") as Control
	TextSize.attach(equipment_page.get_node("Stats"), "stats", [], func() -> void: reset_size.call_deferred())
	TextSize.fit_pages(_pages, equipment_page)


func refresh() -> void:
	$VBox/Header/NamePanel/NameLabel.text = GameState.get_player_name()
	_class_label.text = Language.translate("Lv %d / %d") % [_stats.level, _stats.get_max_level()]
	for slot in PlayerStats.ToolSlot.values():
		EquipmentDoll.show_stack(_slot_uis[slot], _stats.get_tool(slot))
	_stats_label.text = _build_stats_text()
	_refresh_reputation()
	if _stats.level >= _stats.get_max_level():
		_experience_bar.value = 1.0
		_experience_label.text = "PEXP: MAX"
	else:
		var needed: int = _stats.get_experience_to_next_level()
		_experience_bar.value = float(_stats.experience) / needed
		_experience_label.text = "PEXP %d / %d" % [_stats.experience, needed]
	_skill_points_label.text = Language.translate("Skillpunkte: %d  (1 pro Level)") % _stats.get_free_skill_points()
	_recipes_label.text = _build_recipes_text()
	_build_known_recipes()
	_fame_label.text = _build_fame_text()
	_build_achievements()
	# Deferred: a skill click triggers the rebuild while its own signal is still running.
	_build_skill_tree.call_deferred()


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


## The chosen tab is wide, the others narrow (their text is cut off).
func _select_tab(index: int) -> void:
	for i in _tabs.size():
		_tabs[i].button_pressed = i == index
		_tabs[i].size_flags_stretch_ratio = ACTIVE_TAB_RATIO if i == index else 1.0
	_pages.show_page(index)


# --- Values -----------------------------------------------------------------------

func _build_stats_text() -> String:
	var lines: Array[String] = [
		_header(Language.translate("Abbau")),
		Language.translate("Schaden an Erz: %d%s") % [_stats.get_mining_damage(), _bonus(_stats.get_mining_damage() - _stats.mining_damage)],
		Language.translate("Schaden an Bäumen: %d%s") % [_stats.get_chopping_damage(), _bonus(_stats.get_chopping_damage() - _stats.chopping_damage)],
		Language.translate("Schläge pro Sekunde: %s") % str(snappedf(_stats.get_hits_per_second(), 0.1)).replace(".", ","),
		Language.translate("Lauftempo: %d %%%s") % [roundi(_stats.get_move_speed_factor() * 100.0),
				_bonus(roundi(_stats.get_move_speed_factor() * 100.0) - 100, " %")],
		_header(Language.translate("Schmieden")),
		Language.translate("Schläge: %d%s") % [_stats.get_forging_strikes(), _bonus(_stats.get_forging_strikes() - _stats.forging_strikes)],
		Language.translate("Grüne Zone: %d %%%s") % [_percent(_stats.get_green_zone_width()),
				_bonus(_percent(_stats.get_green_zone_width()) - _percent(_stats.green_zone_width), " %")],
		Language.translate("Gelbe Zone: je %d %%%s") % [_percent(_stats.get_yellow_zone_width()),
				_bonus(_percent(_stats.get_yellow_zone_width()) - _percent(_stats.yellow_zone_width), " %")],
	]
	return "\n".join(lines)


# --- Reputation -------------------------------------------------------------------------

## Below the values: [crest] "Ruf: Rang D" / points / bar towards the next rank.
func _build_reputation_box() -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_crest = ReputationCrest.new()
	_crest.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(_crest)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 1)
	_reputation_label = Label.new()
	texts.add_child(_reputation_label)
	_reputation_bar = ProgressBar.new()
	_reputation_bar.custom_minimum_size = Vector2(0, 4)
	_reputation_bar.max_value = 1.0
	_reputation_bar.step = 0.0
	_reputation_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_REPUTATION
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BAR_BACK
	_reputation_bar.add_theme_stylebox_override("fill", fill)
	_reputation_bar.add_theme_stylebox_override("background", back)
	texts.add_child(_reputation_bar)
	box.add_child(texts)
	_stats_label.get_parent().add_child(box)
	_stats_label.get_parent().move_child(box, _stats_label.get_index() + 1)


func _refresh_reputation() -> void:
	var reputation: Reputation = GameState.reputation
	_crest.show_rank(reputation.get_rank())
	_crest.tooltip_text = _build_reputation_tooltip()
	var next: Dictionary = reputation.get_next_rank()
	var lines: Array[String] = [Language.translate("Ruf: Rang %s") % reputation.get_rank_id()]
	if next.is_empty():
		lines.append(Language.translate("%d Punkte (höchster Rang)") % reputation.points)
	elif reputation.is_next_locked():
		lines.append(Language.translate("%d / %d, %s gesperrt") % [reputation.points, int(next.get("from", 0)), next.get("id", "")])
	else:
		lines.append(Language.translate("%d / %d bis %s") % [reputation.points, int(next.get("from", 0)), next.get("id", "")])
	_reputation_label.text = "\n".join(lines)
	_reputation_label.add_theme_color_override("font_color", COLOR_LOCKED if reputation.is_next_locked() else Color.WHITE)
	_reputation_bar.value = reputation.get_fraction()


## Metals listed in the crest tooltip with their forging difficulty.
const DIFFICULTY_MATERIALS: Array[String] = ["copper", "iron", "bronze", "silver", "platinum", "palladium"]


## What the rank brings and how to get more (tooltip of the crest).
func _build_reputation_tooltip() -> String:
	var reputation: Reputation = GameState.reputation
	var count: Array = reputation.get_customer_range()
	# How hard forging is per metal at this rank (ForgeQuality.get_difficulty).
	var difficulties: Array[String] = []
	for material: String in DIFFICULTY_MATERIALS:
		var tier: int = int(ContentDB.material_info(material).get("tier", 0))
		difficulties.append("%s %s" % [ContentDB.material_name(material), ForgeQuality.get_difficulty(tier).get("name", "")])
	var lines: Array[String] = [
		Language.translate("Rang %s (%d Punkte)") % [reputation.get_rank_id(), reputation.points],
		Language.translate("Kunden pro Tag: %d-%d") % [int(count[0]), int(count[count.size() - 1])],
		Language.translate("Bezahlung für Aufträge: %+d %%") % roundi(reputation.get_pay_bonus() * 100.0),
		Language.translate("Preise in den Läden: %+d %%") % roundi(reputation.get_price_bonus() * 100.0),
		Language.translate("Hausausbau bis Stufe %d") % reputation.get_max_house_level(),
		Language.translate("Schmieden: %s") % ", ".join(difficulties),
	]
	if reputation.is_next_locked():
		lines.append(Language.translate("Der nächste Rang öffnet sich erst später in der Geschichte. Deine Punkte zählen trotzdem."))
	lines.append(Language.translate("Ruf gibt es für Aufträge, Verkäufe in den Läden und die Geschichte."))
	return "\n".join(lines)


func _header(text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLOR_HEADER.to_html(false), text]


## " (+2)" in green, or "" for no bonus.
func _bonus(amount: int, unit: String = "") -> String:
	if amount == 0:
		return ""
	return " [color=#%s](%+d%s)[/color]" % [COLOR_BONUS.to_html(false), amount, unit]


func _percent(fraction: float) -> int:
	return roundi(fraction * 100.0)


## Tab "Gussformen": the names of all known molds (without the "Gussform: " in front), grouped
## by metal, highest first (palladium on top, copper at the bottom), quest molds (items.json
## "quest_part", e.g. the compass) below copper; an empty line between the groups. Within a group
## by category (Schwerter, Griffe ...).
func _build_recipes_text() -> String:
	var groups: Array[String] = ContentDB.get_cast_metals()
	groups.reverse()
	groups.append("quest")
	var molds: Dictionary = {}
	for recipe in ContentDB.get_all_recipes():
		if String(recipe.id).begins_with("mold_") and GameState.is_recipe_unlocked(recipe):
			var group: String = _mold_group(recipe)
			if group not in groups:
				groups.insert(groups.size() - 1, group)
			if not molds.has(group):
				molds[group] = [] as Array[RecipeData]
			(molds[group] as Array[RecipeData]).append(recipe)
	var blocks: Array[String] = []
	for group in groups:
		if not molds.has(group):
			continue
		var list: Array[RecipeData] = molds[group]
		var categories: Array[String] = []
		for recipe in list:
			if recipe.get_category() not in categories:
				categories.append(recipe.get_category())
		var lines: Array[String] = []
		for category in categories:
			for recipe in list:
				if recipe.get_category() == category:
					lines.append(recipe.get_display_name().trim_prefix(Language.translate("Gussform: ")))
		blocks.append("\n".join(lines))
	return "\n\n".join(blocks) if not blocks.is_empty() else Language.translate("Noch keine Gussformen.")


## Group of a mold in the tab "Gussformen": "quest" for quest parts, else the metal of its ingot.
static func _mold_group(recipe: RecipeData) -> String:
	var part: ItemData = ContentDB.item(String(recipe.id).trim_prefix("mold_"))
	if part and part.quest_part:
		return "quest"
	var ingot: ItemData = recipe.ingredients[0].item if not recipe.ingredients.is_empty() else null
	return ContentDB.metal_of(ingot)


## Tab "Rezepte": the potion recipes (from Aurelius' notes, Enchanting.BOOK_FLAG), enchanting
## potions first, then the other brews; one button each that opens the recipe page.
func _build_known_recipes() -> void:
	for child in _known_recipes_list.get_children():
		_known_recipes_list.remove_child(child)
		child.queue_free()
	if not GameState.story.has_flag(Enchanting.BOOK_FLAG):
		var hint := Label.new()
		hint.text = Language.translate("Noch keine Trank-Rezepte. Vielleicht weiß Meister Aurelius mehr.")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", COLOR_LOCKED)
		_known_recipes_list.add_child(hint)
		return
	var potions: Array[ItemData] = []
	for potion in ContentDB.get_potions():
		# Secret potions (other plants, combos) only once brewed.
		if Enchanting.is_known(potion, GameState.story):
			potions.append(potion.item)
	var brews: Array[ItemData] = []
	for brew in ContentDB.get_brews():
		if brew.is_known():
			brews.append(brew.item)
	for block: Array in [[Language.translate("Verzauberungstränke"), potions], [Language.translate("Weitere Tränke"), brews]]:
		if (block[1] as Array).is_empty():
			continue
		var header := Label.new()
		header.text = block[0]
		header.add_theme_color_override("font_color", COLOR_HEADER)
		_known_recipes_list.add_child(header)
		for item: ItemData in block[1]:
			var button := Button.new()
			button.text = item.display_name
			button.icon = item.icon
			button.focus_mode = Control.FOCUS_NONE
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_constant_override("icon_max_width", 12)
			button.pressed.connect(potion_recipe_selected.emit.bind(item))
			_known_recipes_list.add_child(button)


## Tab "Ruhm": famous weapons (kills, carried by) and masterpieces (rarest first).
func _build_fame_text() -> String:
	var lines: Array[String] = _build_ranking_lines()
	lines.append(_header(Language.translate("Berühmte Waffen")))
	var famous: Array[Dictionary] = Fame.get_famous_weapons(GameState)
	if famous.is_empty():
		lines.append(Language.translate("Noch keine. Deine Waffen zählen, was die Helden mit ihnen besiegen."))
	for entry in famous:
		var weapon: InventorySlot = entry["slot"]
		var owner: String = " (%s)" % entry["owner"] if not String(entry["owner"]).is_empty() else ""
		lines.append(Language.translate("[color=#%s]%s[/color]: %d Monster%s") % [Rarity.get_color(weapon.rarity).to_html(false),
				weapon.get_display_name(), weapon.get_kills(), owner])
	lines.append("")
	lines.append(_header(Language.translate("Meisterstücke")))
	var masterpieces: Array[Dictionary] = GameState.fame.get_masterpieces()
	if masterpieces.is_empty():
		lines.append(Language.translate("Noch keine. Das beste Stück jeder Art landet hier."))
	for piece in masterpieces:
		var rarity: Rarity.Tier = int(piece["rarity"]) as Rarity.Tier
		lines.append("[color=#%s]%s[/color] – %s, %s" % [Rarity.get_color(rarity).to_html(false), piece["name"],
				ForgeQuality.describe(rarity, int(piece["quality"])), GameCalendar.get_short_text(int(piece["day"]))])
	return "\n".join(lines)


## Above the famous weapons: title, both ratings with their league and the titles won
## (TournamentRanking). Empty before the first league tournament.
func _build_ranking_lines() -> Array[String]:
	var ranking: TournamentRanking = GameState.ranking
	var played: bool = TournamentRanking.TYPES.any(func(type: String) -> bool: return int(ranking.get_counts(type)[0]) > 0)
	if not played:
		return []
	var lines: Array[String] = [_header(Language.translate("Turniere"))]
	var title: String = ranking.get_title()
	if not title.is_empty():
		lines.append(Language.translate("Titel: [color=#ffd75a]%s[/color]") % title)
	for type: String in TournamentRanking.TYPES:
		var counts: Array = ranking.get_counts(type)
		lines.append(Language.translate("%s: %s, %d RP (%d Turniere, %d Siege)") % [Language.translate(TournamentRanking.TYPE_NAMES[type]),
				ranking.get_rank_name(type), ranking.get_points(type), int(counts[0]), int(counts[1])])
	var titles: Array[String] = []
	for entry: Dictionary in ranking.get_titles():
		titles.append(str(entry["title"]))
	if not titles.is_empty():
		lines.append(Language.translate("Alle Titel: %s") % ", ".join(titles))
	lines.append("")
	return lines


# --- Skills -----------------------------------------------------------------------

## Player skills have no tree links: the row (tier) follows the required level, lowest at the bottom.
func _build_skill_tree() -> void:
	var levels: Array[int] = []
	for skill in _stats.skill_tree.skills:
		if skill.required_level not in levels:
			levels.append(skill.required_level)
	levels.sort()
	var entries: Array[Dictionary] = []
	for skill in _stats.skill_tree.skills:
		var rank: int = _stats.get_skill_rank(skill)
		var blocker: String = _stats.get_learn_blocker(skill)
		var tooltip: String = Language.translate("%s  (Stufe %d/%d)\n%s") % [skill.display_name, rank, skill.max_rank, skill.description]
		if skill.required_level > 1:
			tooltip += Language.translate("\nAb Level %d") % skill.required_level
		if skill.level_per_rank > 0:
			tooltip += Language.translate(" (jede weitere Stufe %d Level später)") % skill.level_per_rank
		if blocker == "":
			tooltip += "\n\nKlicken: %s (1 Skillpunkt)" % (Language.translate("Stufe erhöhen") if rank > 0 else Language.translate("Lernen"))
		elif rank < skill.max_rank:
			tooltip += "\n\n" + blocker
		entries.append({
			"icon": skill.icon,
			"tier": levels.find(skill.required_level),
			"level": rank,
			"max_level": skill.max_rank,
			"tooltip": tooltip,
			"can_learn": blocker == "",
			"requires": -1,
			"on_learn": func() -> void: _stats.learn_skill(skill),
		})
	_skill_tree.setup(SKILL_BACKGROUND, entries)


# --- Tool slots -------------------------------------------------------------------

func _can_drop_into(_at_position: Vector2, data: Variant, slot: PlayerStats.ToolSlot) -> bool:
	if not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return not source.is_empty() and not source.hot and _stats.can_equip_tool(slot, source.item)


func _drop_into(_at_position: Vector2, data: Variant, slot: PlayerStats.ToolSlot) -> void:
	_equip_from_inventory(data["inventory_index"], slot)


## Right click in the inventory: puts a pickaxe, axe, gloves, backpack or book into its slot and
## swaps out the old one.
func try_quick_equip(inventory_index: int) -> bool:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty() or source.hot:
		return false
	for slot in PlayerStats.ToolSlot.values():
		if _stats.can_equip_tool(slot, source.item):
			_equip_from_inventory(inventory_index, slot)
			return true
	return false


## Takes one piece out of the inventory slot, equips it and puts the old one back.
## A smaller backpack only goes on when the items in the lost places still fit.
func _equip_from_inventory(inventory_index: int, slot: PlayerStats.ToolSlot) -> void:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if slot == PlayerStats.ToolSlot.BACKPACK and not GameState.can_change_backpack(source, inventory_index):
		GameState.show_message(Language.translate(BACKPACK_FULL_TEXT))
		return
	var piece: InventorySlot = source.copy_with_amount(1)
	GameState.inventory.remove_from_slot(inventory_index, 1)
	var previous: InventorySlot = _stats.equip_tool(slot, piece)
	if previous:
		GameState.inventory.add_stack(previous)


func _on_slot_gui_input(event: InputEvent, slot: PlayerStats.ToolSlot) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed):
		return
	if mouse_event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return
	var equipped: InventorySlot = _stats.get_tool(slot)
	if equipped and slot == PlayerStats.ToolSlot.BOOK and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		# Read it: the recipe book opens at the book's tab; a right click takes it off.
		Events.recipe_book_requested.emit(Language.translate(PlayerStats.BOOK_TABS.get(equipped.item.id, "")))
	elif equipped and slot == PlayerStats.ToolSlot.BACKPACK:
		# The bag gets smaller first; the backpack then needs a place in what is left.
		if not GameState.can_change_backpack(null):
			GameState.show_message(Language.translate(BACKPACK_FULL_TEXT))
			return
		GameState.inventory.add_stack(_stats.unequip_tool(slot))
	elif equipped and GameState.inventory.get_free_space(equipped) >= equipped.amount:
		GameState.inventory.add_stack(_stats.unequip_tool(slot))


# --- Achievements ---------------------------------------------------------------------

## A header "Geschichte (2/8)" and a grid of tiles per category.
func _build_achievements() -> void:
	for child in _achievement_list.get_children():
		_achievement_list.remove_child(child)
		child.queue_free()
	var achievements: Achievements = GameState.achievements
	for category: Dictionary in Achievements.get_categories():
		var ids: Array[String] = Achievements.get_in_category(category["id"])
		if ids.is_empty():
			continue
		var done: int = 0
		for id in ids:
			if achievements.get_level(id) > 0:
				done += 1
		var header := Label.new()
		header.text = "%s (%d/%d)" % [category["name"], done, ids.size()]
		header.add_theme_color_override("font_color", COLOR_HEADER)
		_achievement_list.add_child(header)
		var grid := GridContainer.new()
		grid.columns = ACHIEVEMENT_COLUMNS
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		for id in ids:
			var tile := AchievementTile.new()
			tile.setup(id)
			grid.add_child(tile)
		_achievement_list.add_child(grid)
