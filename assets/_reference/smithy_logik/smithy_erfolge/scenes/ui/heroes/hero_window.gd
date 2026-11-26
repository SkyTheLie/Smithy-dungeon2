class_name HeroWindow
extends PanelContainer
## Window of one hero (layout: assets/_reference/concept/helden_ansicht.png).
## Top: portrait, name (double click = rename, Enter keeps it, Esc cancels), class and race (in the
## class colour), level and a stamina bar. Below: the switch "Ausrüstung" / "Fähigkeiten";
## the chosen one is wide, and the pages slide left/right (SlidingPages).
## Equipment: 12 slots around a silhouette (drag items in from the inventory, click to take them
## off; with a quiver in the left hand its places for arrows appear below it); on the right HP, MP and the attributes with a "+" while attribute points are free,
## the free points, the experience bar and "Mehr anzeigen" (opens HeroStatsWindow via the HUD).
## Skills: one tab per skill tree of the class (with the points spent in it), the chosen tree
## (SkillTreeView) - hover for details, click to learn / raise a level; below the free skill points
## and the hero's role (HeroRole, a click picks the next one his IQ allows).

## Wants the window with all values for this hero.
signal more_stats_requested(hero: Hero)
## Right click on a learned skill: open its command (SkillCommandWindow via the HUD).
signal skill_command_requested(hero: Hero, skill: SkillData)

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_BONUS: Color = Color(0.55, 0.85, 0.45)
const COLOR_EXPERIENCE: Color = Color(0.62, 0.38, 0.78)
const COLOR_BAR_BACK: Color = Color(0.13, 0.075, 0.12)
## Tab widths: the chosen tab gets this much more room than the other one.
const ACTIVE_TAB_RATIO: float = 3.0
## Stamina bar: green from this share up, yellow down to STAMINA_LOW, red below.
const STAMINA_HIGH: float = 0.5
const STAMINA_LOW: float = 0.2
const COLOR_STAMINA_HIGH: Color = Color(0.55, 0.85, 0.45)
const COLOR_STAMINA_MID: Color = Color(0.9, 0.75, 0.3)
const COLOR_STAMINA_LOW: Color = Color(0.9, 0.42, 0.35)
## Slot centres around the silhouette (EquipmentDoll coordinates), same order as EquipmentSlot.
## Three columns (28x28 slots): left shoulders/right hand/gloves/ring 1, middle helmet to boots,
## right cloak/left hand/necklace/ring 2.
const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(60, 16),   # helmet
	Vector2(18, 18),   # shoulders
	Vector2(102, 18),  # cloak
	Vector2(60, 50),   # armor
	Vector2(102, 52),  # left hand
	Vector2(18, 52),   # right hand
	Vector2(60, 84),   # legs
	Vector2(60, 118),  # boots
	Vector2(102, 86),  # necklace
	Vector2(18, 120),  # ring 1
	Vector2(102, 120), # ring 2
	Vector2(18, 86),   # gloves
]
## Places of a quiver in the left hand (a row below the silhouette, as many as the quiver has):
## left, right, 3rd, 4th. Shot order: InventorySlot.QUIVER_SHOT_ORDER (right first).
const QUIVER_SLOT_POSITIONS: Array[Vector2] = [Vector2(15, 154), Vector2(45, 154), Vector2(75, 154), Vector2(105, 154)]

var _hero: Hero
## The hero changed while the window was closed (see _on_hero_changed).
var _stale: bool = false
## Index of the skill tree shown (HeroClass.get_trees).
var _tree_index: int = 0
## ItemSlotUI per Hero.EquipmentSlot.
var _slot_uis: Array[ItemSlotUI] = []
## ItemSlotUI per quiver place.
var _quiver_uis: Array[ItemSlotUI] = []
## Below the skill points: the hero's role in the fight (click = next role).
var _role_button: Button
## Small style for the "+" of the attributes (the theme's button is taller than a text row).
var _plus_styles: Dictionary = {}
## true while the name field is open (guards against finishing twice: Enter, then focus lost).
var _renaming: bool = false

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _class_label: Label = %ClassLabel
@onready var _level_label: Label = %LevelLabel
@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _stamina_label: Label = %StaminaLabel
@onready var _equipment_tab: Button = %EquipmentTab
@onready var _skills_tab: Button = %SkillsTab
@onready var _pages: SlidingPages = %Pages
@onready var _doll: EquipmentDoll = %Doll
@onready var _values_grid: GridContainer = %ValuesGrid
@onready var _attribute_grid: GridContainer = %AttributeGrid
@onready var _points_label: Label = %PointsLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _experience_bar: ProgressBar = %ExperienceBar
@onready var _tree_tabs: HBoxContainer = %TreeTabs
@onready var _skill_tree: SkillTreeView = %SkillTree
@onready var _skill_points_label: Label = %SkillPointsLabel


func _ready() -> void:
	add_to_group(EquipmentDoll.QUICK_EQUIP_GROUP)
	var group := ButtonGroup.new()
	_equipment_tab.button_group = group
	_skills_tab.button_group = group
	_equipment_tab.pressed.connect(_select_tab.bind(0))
	_skills_tab.pressed.connect(_select_tab.bind(1))
	_select_tab(0)
	%MoreButton.pressed.connect(func() -> void: more_stats_requested.emit(_hero))
	for slot in Hero.EquipmentSlot.values():
		var hint: String = Hero.SLOT_KEYS[slot].trim_suffix("_1").trim_suffix("_2")  # ring_1/ring_2 -> ring
		var slot_ui: ItemSlotUI = _doll.add_slot(SLOT_POSITIONS[slot], Language.translate(Hero.SLOT_NAMES[slot]), hint)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(slot))
		slot_ui.set_drag_forwarding(Callable(), _can_drop_into.bind(slot), _drop_into.bind(slot))
		_slot_uis.append(slot_ui)
	for index in QUIVER_SLOT_POSITIONS.size():
		var slot_name: String = Language.translate("Köcher %s (%s verschossen)") % [InventorySlot.QUIVER_PLACE_NAMES[index],
				[Language.translate("als Zweites"), "zuerst", Language.translate("zum Schluss"), Language.translate("zum Schluss")][index]]
		var quiver_ui: ItemSlotUI = _doll.add_slot(QUIVER_SLOT_POSITIONS[index], slot_name, "quiver")
		quiver_ui.gui_input.connect(_on_quiver_slot_gui_input.bind(index))
		quiver_ui.set_drag_forwarding(Callable(), _can_drop_into_quiver.bind(index), _drop_into_quiver.bind(index))
		quiver_ui.hide()
		_quiver_uis.append(quiver_ui)
	style_bar(_experience_bar, COLOR_EXPERIENCE)
	style_bar(_stamina_bar, COLOR_STAMINA_HIGH)
	_name_label.tooltip_text = Language.translate("Doppelklick: umbenennen")
	_name_label.gui_input.connect(_on_name_gui_input)
	_name_edit.max_length = Hero.NAME_MAX_LENGTH
	_name_edit.text_submitted.connect(func(_text: String) -> void: _finish_rename(true))
	_name_edit.focus_exited.connect(_finish_rename.bind(true))
	_name_edit.gui_input.connect(_on_name_edit_gui_input)
	visibility_changed.connect(func() -> void:
		if not visible:
			_finish_rename(true)
		elif _stale and is_visible_in_tree():
			_refresh())
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := get_theme_stylebox(state, "Button").duplicate() as StyleBox
		style.content_margin_left = 2.0
		style.content_margin_right = 2.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
		_plus_styles[state] = style
	_role_button = Button.new()
	_role_button.focus_mode = Control.FOCUS_NONE
	_role_button.add_theme_font_size_override("font_size", 11)
	_role_button.pressed.connect(_next_role)
	_skill_points_label.add_sibling(_role_button)


func show_hero(hero: Hero) -> void:
	_finish_rename(true)
	if _hero and _hero.changed.is_connected(_on_hero_changed):
		_hero.changed.disconnect(_on_hero_changed)
	if hero != _hero:
		_tree_index = 0
	_hero = hero
	_hero.changed.connect(_on_hero_changed)
	_refresh()


## The hero changed (every shot arrow and every kill in a dungeon does that): the window is
## rebuilt only while it is open; a closed one remembers it and rebuilds when it shows again.
func _on_hero_changed() -> void:
	if is_visible_in_tree():
		_refresh()
	else:
		_stale = true


## The chosen tab is wide, the other one narrow (its text is cut off).
func _select_tab(index: int) -> void:
	_equipment_tab.button_pressed = index == 0
	_skills_tab.button_pressed = index == 1
	_equipment_tab.size_flags_stretch_ratio = ACTIVE_TAB_RATIO if index == 0 else 1.0
	_skills_tab.size_flags_stretch_ratio = ACTIVE_TAB_RATIO if index == 1 else 1.0
	_pages.show_page(index)


func _refresh() -> void:
	if _hero == null:
		return
	_stale = false
	_title_bar.title = _hero.display_name
	_portrait.texture = _hero.get_portrait()
	_name_label.text = _hero.display_name
	_class_label.text = "%s · %s" % [_hero.hero_class.display_name, _hero.get_race_data().get("name", "")]
	_class_label.add_theme_color_override("font_color", _hero.hero_class.color)
	# The race bonus as tooltip (the line has no room for it).
	var instinct_line: String = _hero.get_class_instinct_line()
	_class_label.tooltip_text = _hero.get_race_line() + ("\n" + instinct_line if not instinct_line.is_empty() else "")
	_level_label.text = Language.translate("Lv %d") % _hero.level
	show_stamina(_stamina_bar, _hero)
	_stamina_label.text = Language.translate("Ausdauer %d/%d") % [floori(_hero.stamina), roundi(Hero.get_max_stamina())]
	_stamina_label.tooltip_text = Language.translate("Jeder Dungeon kostet Ausdauer, sie kommt mit der Zeit und über Nacht zurück.")
	_stamina_bar.tooltip_text = _stamina_label.tooltip_text
	for slot in Hero.EquipmentSlot.values():
		EquipmentDoll.show_stack(_slot_uis[slot], _hero.get_equipped(slot))
		_slot_uis[slot].extra_tooltip = _get_set_tooltip(slot)
	var quiver: InventorySlot = _hero.get_quiver()
	# Typed empty array: a plain [] in the ternary would be untyped and fail at runtime.
	var places: Array[InventorySlot] = []
	if quiver:
		places = quiver.get_quiver_slots()
	for index in _quiver_uis.size():
		_quiver_uis[index].visible = index < places.size()
		if index < places.size():
			EquipmentDoll.show_stack(_quiver_uis[index], places[index])
	_build_values()
	# Deferred: a "+" or skill click rebuilds the rows while its own signal is still running.
	_build_attributes.call_deferred()
	var free: int = _hero.get_free_attribute_points()
	_points_label.text = Language.translate("Attributpunkte: %d") % free
	_points_label.add_theme_color_override("font_color", COLOR_BONUS if free > 0 else COLOR_HINT)
	if _hero.level >= _hero.get_max_level():
		_experience_label.text = "EXP: MAX"
		_experience_bar.value = 1.0
	else:
		var needed: int = _hero.get_experience_to_next_level()
		_experience_label.text = "EXP %d / %d" % [_hero.experience, needed]
		_experience_bar.value = float(_hero.experience) / needed
	_skill_points_label.text = Language.translate("Skillpunkte: %d  (1 pro %d Level)") % [_hero.get_free_skill_points(), Hero.LEVELS_PER_SKILL_POINT]
	_refresh_role()
	_build_tree_tabs.call_deferred()
	_build_skill_tree.call_deferred()


## "Rolle: Bossjäger (IQ 92)"; the tooltip lists every role with the IQ it needs.
## Set lines under the tooltip of a worn set piece: every worn set, the piece's own one highlighted.
func _get_set_tooltip(slot: Hero.EquipmentSlot) -> String:
	var stack: InventorySlot = _hero.get_equipped(slot)
	if stack == null or not Hero.SET_SLOTS.has(slot):
		return ""
	if slot == Hero.EquipmentSlot.LEFT_HAND and stack.item.type != ItemData.ItemType.SHIELD:
		return ""
	var own: String = Hero.get_set_metal(stack)
	var own_name: String = ContentDB.material_name(own) if not own.is_empty() else ""
	var lines := PackedStringArray()
	for line in _hero.get_set_lines():
		var color: Color = COLOR_BONUS if not own_name.is_empty() and line.begins_with(own_name) else COLOR_HINT
		lines.append("[color=#%s]%s[/color]" % [color.to_html(false), line])
	return "\n".join(lines)


func _refresh_role() -> void:
	_role_button.text = Language.translate("Rolle: %s (IQ %d)") % [HeroRole.get_display_name(_hero.get_role()), _hero.get_iq()]
	var lines: Array[String] = [Language.translate("Klick: nächste Rolle. Höherer IQ (Klarkopf-Trank, Mondweisheits-Elixier) schaltet mehr frei.")]
	lines.append(Language.translate("Ab IQ %d folgt der Held deinem Fokus (Gegner im Kampf anklicken).") % HeroRole.focus_iq())
	for id in HeroRole.get_ids():
		var needed: int = HeroRole.required_iq(id)
		lines.append("%s%s: %s" % [HeroRole.get_display_name(id), Language.translate(" (ab IQ %d)") % needed if needed > 0 else "", HeroRole.get_text(id)])
	_role_button.tooltip_text = "\n".join(lines)


## Picks the next role the hero is clever enough for (after the last: none again).
func _next_role() -> void:
	var ids: Array[String] = HeroRole.get_ids()
	var index: int = ids.find(_hero.get_role())
	for step in range(1, ids.size() + 1):
		var next: String = ids[(index + step) % ids.size()]
		if _hero.get_iq() >= HeroRole.required_iq(next):
			_hero.set_role(next)
			return


## One button per tree: its name and the points spent in it; the chosen one is pressed.
func _build_tree_tabs() -> void:
	for child in _tree_tabs.get_children():
		_tree_tabs.remove_child(child)
		child.queue_free()
	var trees: Array = _hero.hero_class.get_trees()
	_tree_index = clampi(_tree_index, 0, maxi(trees.size() - 1, 0))
	var group := ButtonGroup.new()
	for i in trees.size():
		var button := Button.new()
		button.text = "%s %d" % [trees[i]["name"], _hero.get_points_in_tree(i)]
		button.tooltip_text = Language.translate("%s: %d Punkte im Baum") % [trees[i]["name"], _hero.get_points_in_tree(i)]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == _tree_index
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(func() -> void:
			_tree_index = i
			_build_skill_tree())
		_tree_tabs.add_child(button)


## HP, MP, armor and crit in two rows: name (grey) and value.
func _build_values() -> void:
	for child in _values_grid.get_children():
		_values_grid.remove_child(child)
		child.queue_free()
	var values: Array = [["HP", str(_hero.get_max_health())], ["MP", str(_hero.get_max_mana())],
			[Language.translate("Rüstung"), str(_hero.get_armor())],
			[Language.translate("Krit"), "%d %%" % roundi(_hero.get_crit_chance() * 100.0)]]
	for pair: Array in values:
		var name_label := Label.new()
		name_label.text = pair[0]
		name_label.add_theme_color_override("font_color", COLOR_HINT)
		_values_grid.add_child(name_label)
		var value_label := Label.new()
		value_label.text = pair[1]
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_values_grid.add_child(value_label)


## One row per attribute: name, value (equipment bonus in green) and "+" while points are free
## (without free points an empty place, so the rows stay as low as the text).
func _build_attributes() -> void:
	for child in _attribute_grid.get_children():
		_attribute_grid.remove_child(child)
		child.queue_free()
	var can_raise: bool = _hero.get_free_attribute_points() > 0
	for type in ItemAttribute.Type.values():
		var name_label := Label.new()
		name_label.text = Language.translate(ItemAttribute.NAMES[type])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.tooltip_text = Language.translate(ItemAttribute.EFFECTS[type])
		_attribute_grid.add_child(name_label)
		var value := Label.new()
		var bonus: int = _hero.get_equipment_attribute(type)
		value.text = str(_hero.get_attribute(type)) + (" (+%d)" % bonus if bonus > 0 else "")
		if bonus > 0:
			value.add_theme_color_override("font_color", COLOR_BONUS)
		_attribute_grid.add_child(value)
		if not can_raise:
			_attribute_grid.add_child(Control.new())
			continue
		var plus := Button.new()
		plus.text = "+"
		plus.focus_mode = Control.FOCUS_NONE
		for state: String in _plus_styles:
			plus.add_theme_stylebox_override(state, _plus_styles[state])
		plus.tooltip_text = Language.translate("%s dauerhaft um 1 erhöhen") % Language.translate(ItemAttribute.NAMES[type])
		plus.pressed.connect(func() -> void: _hero.raise_attribute(type))
		_attribute_grid.add_child(plus)


# --- Bars, renaming ------------------------------------------------------------------

## Flat bar in the window colours (experience, stamina); also used by the hero list.
static func style_bar(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BAR_BACK
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)


## Fills a stamina bar (styled with style_bar): green when rested, yellow, red when nearly empty.
static func show_stamina(bar: ProgressBar, hero: Hero) -> void:
	var share: float = hero.stamina / maxf(Hero.get_max_stamina(), 1.0)
	bar.value = share
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = COLOR_STAMINA_HIGH if share >= STAMINA_HIGH else (COLOR_STAMINA_MID if share >= STAMINA_LOW else COLOR_STAMINA_LOW)


## Double click on the name: the name turns into a text field.
func _on_name_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if _hero == null or mouse_event == null or not mouse_event.pressed or not mouse_event.double_click \
			or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_renaming = true
	_name_edit.text = _hero.display_name
	_name_edit.placeholder_text = _hero.get_original_name()
	_name_label.hide()
	_name_edit.show()
	_name_edit.grab_focus()
	_name_edit.select_all()
	_name_label.accept_event()


## Esc in the name field: back without renaming (and the window stays open).
func _on_name_edit_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_name_edit.accept_event()
		_finish_rename(false)


## Closes the name field; keep = take the typed name (empty = the hero's own name again).
func _finish_rename(keep: bool) -> void:
	if not _renaming:
		return
	_renaming = false
	if keep and _hero:
		_hero.set_custom_name(_name_edit.text)
	_name_edit.hide()
	_name_label.show()
	if _name_edit.has_focus():
		_name_edit.release_focus()


func _build_skill_tree() -> void:
	var trees: Array = _hero.hero_class.get_trees()
	if trees.is_empty():
		return
	var skills: Array[SkillData] = []
	skills.assign(trees[clampi(_tree_index, 0, trees.size() - 1)]["skills"])
	# The hero as he goes into the dungeon: the tooltips show his real damage and cooldowns.
	var fighter: Combatant = Combatant.from_hero(_hero)
	var entries: Array[Dictionary] = []
	for skill in skills:
		var level: int = _hero.get_skill_rank(skill)
		var blocker: String = _hero.get_learn_blocker(skill)
		var hint: String = ""
		if blocker == "":
			hint = "\n\nKlicken: %s (1 Skillpunkt)" % (Language.translate("Stufe erhöhen") if level > 0 else Language.translate("Lernen"))
		elif level < skill.max_level:
			hint = "\n\n" + blocker
		if level > 0 and not _hero.is_skill_enabled(skill):
			hint += Language.translate("\n[color=#e66a59]Ausgeschaltet: wird im Dungeon nicht benutzt.[/color]")
		if level > 0 and not skill.is_passive():
			hint += Language.translate("\nRechtsklick: Ein/Aus und Befehl (%s)") % SkillCommand.describe(_hero.get_skill_command(skill))
		if level > 0 and not _hero.can_use_skill(skill):
			hint += Language.translate("\n[color=#e66a59]Gerade nicht einsetzbar: braucht %s.[/color]") % skill.get_required_weapons_text()
		var tooltip: String = skill.get_tooltip(level, false, fighter) + hint
		var tooltip_details: String = skill.get_tooltip(level, true, fighter) + hint
		var entry: Dictionary = {
			"icon": skill.icon,
			"tier": skill.tier,
			"level": level,
			"max_level": skill.max_level,
			"tooltip": tooltip,
			"tooltip_details": tooltip_details,
			"can_learn": blocker == "",
			"passive": skill.is_passive(),
			"requires": skills.find(skill.get_required_skill()) if skill.get_required_skill() else -1,
			"requires_also": skills.find(skill.get_extra_required_skill()) if skill.get_extra_required_skill() else -1,
			"on_learn": func() -> void: _hero.learn_skill(skill),
		}
		if level > 0 and not skill.is_passive():
			entry["on_right_click"] = func() -> void: skill_command_requested.emit(_hero, skill)
		entries.append(entry)
	_skill_tree.setup(_hero.hero_class.skill_background, entries)


# --- Equip / unequip ----------------------------------------------------------------

func _can_drop_into(_at_position: Vector2, data: Variant, slot: Hero.EquipmentSlot) -> bool:
	if _hero == null or not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	return _hero.can_equip(slot, source.item) and not source.hot


func _drop_into(_at_position: Vector2, data: Variant, slot: Hero.EquipmentSlot) -> void:
	_equip_from_inventory(data["inventory_index"], slot)


## Right click in the inventory: puts the item into its slot and swaps out the old piece.
## Weapons go into the right hand, shields into the left; rings into the first free ring slot.
func try_quick_equip(inventory_index: int) -> bool:
	if _hero == null:
		return false
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.is_empty() or source.hot:
		return false
	if not source.item.hero_potion.is_empty():
		_drink_potion(inventory_index)
		return true
	var slot: int = _pick_slot(source.item)
	if slot < 0:
		return false
	_equip_from_inventory(inventory_index, slot as Hero.EquipmentSlot)
	return true


## A hero potion from the inventory for the hero shown (Hero.use_potion); one is used up. After
## forgetting the skills, weapons the hero may no longer hold (e.g. a rogue's sword without
## "Schwertkunst") go back into the inventory.
func _drink_potion(inventory_index: int) -> void:
	var item: ItemData = GameState.inventory.slots[inventory_index].item
	var amount: int = item.get_hero_potion_amount(GameState.inventory.slots[inventory_index].rarity)
	var blocker: String = _hero.get_potion_blocker(item.hero_potion)
	if blocker != "":
		GameState.show_message(blocker)
		return
	GameState.inventory.remove_from_slot(inventory_index, 1)
	var iq_before: int = _hero.get_iq()
	_hero.use_potion(item.hero_potion, amount)
	for slot: Hero.EquipmentSlot in [Hero.EquipmentSlot.RIGHT_HAND, Hero.EquipmentSlot.LEFT_HAND]:
		var held: InventorySlot = _hero.get_equipped(slot)
		if held and not _hero.can_equip(slot, held.item) and GameState.inventory.get_free_space(held) >= held.amount:
			GameState.inventory.add_stack(_hero.unequip(slot))
	var text: String = Language.translate("%s trinkt: %s") % [_hero.display_name, item.display_name]
	if item.hero_potion == "iq":
		text += " (IQ %d » %d)" % [iq_before, _hero.get_iq()]
		GameState.story.set_flag("iq_potion_used")
	GameState.show_message(text)


## The slots made for this item type (a weapon fits the left hand too, but belongs in the right);
## an empty one first, otherwise the first one (swap). -1 = fits nowhere.
func _pick_slot(item: ItemData) -> int:
	var candidates: Array[int] = []
	for slot in Hero.EquipmentSlot.values():
		if (Hero.SLOT_ITEM_TYPES[slot] as Array)[0] == item.type:
			candidates.append(slot)
	if candidates.is_empty():
		for slot in Hero.EquipmentSlot.values():
			if _hero.can_equip(slot, item):
				candidates.append(slot)
	for slot in candidates:
		if _hero.get_equipped(slot) == null:
			return slot
	return candidates[0] if not candidates.is_empty() else -1


## Takes one piece out of the inventory slot, equips it and puts the old piece back.
## A two-handed weapon also puts the item of the left hand (e.g. the shield) back, but a bow keeps
## its arrows. Arrows go in as a whole stack and are added to the same arrows in the hand.
func _equip_from_inventory(inventory_index: int, slot: Hero.EquipmentSlot) -> void:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	if source.item.type == ItemData.ItemType.ARROWS:
		_equip_arrows(inventory_index, slot)
		return
	var off_hand: InventorySlot = _hero.get_equipped(Hero.EquipmentSlot.LEFT_HAND)
	var keeps_arrows: bool = off_hand != null and source.item.uses_arrows() 			and (off_hand.item.type == ItemData.ItemType.ARROWS or off_hand.is_quiver())
	var frees_off_hand: bool = slot == Hero.EquipmentSlot.RIGHT_HAND and source.item.is_two_handed() and off_hand != null \
			and not keeps_arrows
	if frees_off_hand and GameState.inventory.get_free_space(off_hand) < 1:
		return
	var piece: InventorySlot = source.copy_with_amount(1)
	GameState.inventory.remove_from_slot(inventory_index, 1)
	if frees_off_hand:
		GameState.inventory.add_stack(_hero.unequip(Hero.EquipmentSlot.LEFT_HAND))
	var previous: InventorySlot = _hero.equip(slot, piece)
	# A new quiver takes the arrows that were in the hand.
	if previous and piece.is_quiver() and previous.item.type == ItemData.ItemType.ARROWS:
		piece.add_to_quiver(previous)
		_hero.emit_changed()
	if previous and not previous.is_empty():
		GameState.inventory.add_stack(previous)


## Arrows: the whole stack goes into the hand (onto the same arrows, up to a full stack); with a
## quiver in the hand into the quiver (onto the same arrows, otherwise into a free place).
func _equip_arrows(inventory_index: int, slot: Hero.EquipmentSlot) -> void:
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var quiver: InventorySlot = _hero.get_quiver()
	if quiver and slot == Hero.EquipmentSlot.LEFT_HAND:
		var stack: InventorySlot = source.copy_with_amount(source.amount)
		var moved: int = quiver.add_to_quiver(stack)
		if moved > 0:
			GameState.inventory.remove_from_slot(inventory_index, moved)
			_hero.emit_changed()
		return
	var equipped: InventorySlot = _hero.get_equipped(slot)
	if equipped and equipped.can_stack_with(source):
		var moved: int = mini(source.amount, source.item.max_stack - equipped.amount)
		if moved > 0:
			equipped.add_from(source, moved)
			GameState.inventory.remove_from_slot(inventory_index, moved)
			_hero.emit_changed()
		return
	var stack: InventorySlot = source.copy_with_amount(source.amount)
	GameState.inventory.remove_from_slot(inventory_index, source.amount)
	var previous: InventorySlot = _hero.equip(slot, stack)
	if previous:
		GameState.inventory.add_stack(previous)


func _on_slot_gui_input(event: InputEvent, slot: Hero.EquipmentSlot) -> void:
	var mouse_event := event as InputEventMouseButton
	if _hero == null or not (mouse_event and mouse_event.pressed):
		return
	if mouse_event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return
	var equipped: InventorySlot = _hero.get_equipped(slot)
	if equipped and GameState.inventory.get_free_space(equipped) >= equipped.amount:
		GameState.inventory.add_stack(_hero.unequip(slot))


# --- Quiver -------------------------------------------------------------------------

func _can_drop_into_quiver(_at_position: Vector2, data: Variant, index: int) -> bool:
	if _hero == null or _hero.get_quiver() == null or not (data is Dictionary and data.has("inventory_index")):
		return false
	var source: InventorySlot = GameState.inventory.slots[data["inventory_index"]]
	if source.is_empty() or source.item.type != ItemData.ItemType.ARROWS:
		return false
	var place: InventorySlot = _hero.get_quiver().get_quiver_slots()[index]
	if place.can_stack_with(source):
		return place.amount < place.item.max_stack
	# Other arrows there: they are swapped back into the inventory.
	return place.is_empty() or GameState.inventory.get_free_space(place) >= place.amount


## Arrows dragged onto one place of the quiver: into it, onto the same arrows there, or swapped
## with the other arrows that were there (those go back into the inventory).
func _drop_into_quiver(_at_position: Vector2, data: Variant, index: int) -> void:
	var inventory_index: int = data["inventory_index"]
	var source: InventorySlot = GameState.inventory.slots[inventory_index]
	var places: Array[InventorySlot] = _hero.get_quiver().get_quiver_slots()
	var amount: int = source.amount
	if not places[index].is_empty() and not places[index].can_stack_with(source):
		var old: InventorySlot = places[index]
		places[index] = source.copy_with_amount(amount)
		GameState.inventory.remove_from_slot(inventory_index, amount)
		GameState.inventory.add_stack(old)
		_hero.emit_changed()
		return
	if places[index].is_empty():
		places[index] = source.copy_with_amount(amount)
	else:
		amount = mini(amount, places[index].item.max_stack - places[index].amount)
		places[index].add_from(source, amount)
	GameState.inventory.remove_from_slot(inventory_index, amount)
	_hero.emit_changed()


## Click on a place of the quiver: its arrows go back into the inventory (as many as fit).
func _on_quiver_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if _hero == null or _hero.get_quiver() == null or not (mouse_event and mouse_event.pressed):
		return
	if mouse_event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return
	var place: InventorySlot = _hero.get_quiver().get_quiver_slots()[index]
	if place.is_empty():
		return
	place.amount = GameState.inventory.add_stack(place)
	if place.amount <= 0:
		place.clear()
	_hero.emit_changed()
