extends StationMenu
## Dungeon board. Left: one tab per region ("Stadt" ...; dungeons.json "region"), a click opens
## or closes the list of its dungeons. Right, for the chosen dungeon: description (level,
## stages, time limit, monsters, boss stages), the possible rewards as icons with tooltips
## (gold, EXP, items, recipes / a random unknown mold), three hero slots (a click opens a small
## list to choose a hero, with their stamina) and "Losschicken": the run costs gold
## (DungeonData.cost) and every hero stamina (DungeonData.stamina_cost), see GameState.send_party.
## Below: running adventures with "Verfolgen" (closes the board and opens the battle window in
## the HUD via Events.adventure_view_requested; its "« Brett" brings the board back).
## Guide (golden frames): a "dungeon:<id>" target glows as its region tab, then its button; with
## that dungeon chosen a "hero:<id>" target glows as the first free hero slot, then in the picker,
## then "Losschicken".
## Hard modes: a dungeon won once gets a row "Normal ×2 ×3 ×4 ×5" above the rewards; each mode opens
## after a win in the one before it (DungeonData.get_max_power). Monsters ×N as strong, more and
## rarer loot (combat.json "hard_modes").
## The monsters in the description are links: a click opens their page in the lexicon (Lexicon),
## monsters not beaten yet show their silhouette there.

const FONT_SIZE: int = 11
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_GOLD: Color = Color(1, 0.85, 0.35)
const COLOR_EXPERIENCE: Color = Color(0.55, 0.75, 1)
const COLOR_RECIPE: Color = Color(0.85, 0.65, 1.0)
const ICON_GOLD: Texture2D = preload("res://assets/ui/icon_coin.png")
const ICON_EXPERIENCE: Texture2D = preload("res://assets/ui/icon_exp.png")
const ICON_MOLD: Texture2D = preload("res://assets/sprites/items/hot_blank.png")
const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
const HERO_SLOT_SIZE: Vector2 = Vector2(32, 32)
const HERO_SLOT_WIDTH: float = 64.0
const COLOR_HARD: Color = Color(1.0, 0.5, 0.35)

## Only these dungeons (ids), hidden ones too, and the first is chosen right away, e.g. the dragon
## in the goblins' treasure chamber (talk to him = choose the heroes for the fight). Empty = the
## whole board.
@export var only_dungeons: PackedStringArray = []

var _selected: DungeonData
## The party: one entry per hero slot (Hero or null).
var _party: Array = []
## Region name -> its dungeon list (VBoxContainer, hidden while the tab is closed).
var _region_lists: Dictionary = {}
## Index of the hero slot the picker is open for (-1 = closed).
var _picking_slot: int = -1
## Running adventure -> its label in the list (updated every frame while open).
var _running_labels: Dictionary = {}
var _dungeon_group := ButtonGroup.new()
## Chosen mode of the selected dungeon: 1 = normal, 2-5 = hard mode (monsters ×N).
var _power: int = 1
## Row with the mode buttons (built in _ready, above the rewards).
var _mode_row: HBoxContainer

@onready var _region_list: VBoxContainer = %RegionList
@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _reward_row: HBoxContainer = %RewardRow
@onready var _hero_row: HBoxContainer = %HeroRow
@onready var _send_button: Button = %SendButton
@onready var _message_label: Label = %MessageLabel
@onready var _running_list: VBoxContainer = %RunningList
@onready var _hero_picker: PanelContainer = %HeroPicker
@onready var _picker_list: VBoxContainer = %PickerList


func _ready() -> void:
	super()
	add_to_group(BattleWindow.DUNGEON_BOARD_GROUP)
	_party.resize(Adventure.MAX_HEROES)
	_mode_row = HBoxContainer.new()
	_mode_row.add_theme_constant_override("separation", 2)
	var details: Node = _reward_row.get_parent()
	details.add_child(_mode_row)
	details.move_child(_mode_row, details.get_node("RewardTitle").get_index())
	_build_regions()
	Lexicon.connect_links(_description_label)
	_send_button.pressed.connect(_on_send_pressed)
	GuideFrame.attach(_send_button, func() -> bool:
			return not _send_button.disabled and _is_guide_dungeon(_selected) and _party.any(_is_guide_hero))
	visibility_changed.connect(_on_visibility_changed)
	# Moving the board (title bar) would leave the picker behind at its old place.
	$Panel.item_rect_changed.connect(_close_picker)
	# Only while the board is open; opening it refreshes anyway (_on_visibility_changed).
	# heroes_changed comes every game hour (stamina).
	GameState.adventure_started.connect(_refresh_if_open.unbind(1))
	GameState.adventure_finished.connect(_refresh_if_open.unbind(1))
	GameState.heroes_changed.connect(_refresh_if_open)
	GameState.recipes_changed.connect(_on_recipes_changed)
	_show_dungeon()


func _process(_delta: float) -> void:
	if not visible:
		return
	for adventure: Adventure in _running_labels:
		(_running_labels[adventure] as Label).text = _running_text(adventure)


func _on_visibility_changed() -> void:
	_close_picker()
	if visible:
		_build_regions()
	_refresh()


func _refresh_if_open() -> void:
	if visible:
		_refresh()


func _on_recipes_changed() -> void:
	if _selected:
		_show_dungeon()


# --- Regions and dungeons -------------------------------------------------------------

## One tab button per region (in order of the easiest dungeon), each with its dungeon list.
## Open tabs and the selected dungeon stay as they were.
func _build_regions() -> void:
	var open_regions: Array = _region_lists.keys().filter(func(region: String) -> bool:
			return (_region_lists[region] as Control).visible)
	_clear(_region_list)
	_region_lists.clear()
	for dungeon in _get_dungeons():
		if not only_dungeons.is_empty() and _selected == null:
			_selected = dungeon
			open_regions.append(dungeon.region)
			_show_dungeon.call_deferred()
		if not _region_lists.has(dungeon.region):
			var tab := _create_button(dungeon.region)
			_region_list.add_child(tab)
			var list := VBoxContainer.new()
			list.add_theme_constant_override("separation", 1)
			list.visible = open_regions.has(dungeon.region)
			_region_list.add_child(list)
			tab.pressed.connect(func() -> void: list.visible = not list.visible)
			_region_lists[dungeon.region] = list
			var region: String = dungeon.region
			GuideFrame.attach(tab, func() -> bool:
					return not list.visible and _get_dungeons().any(func(other: DungeonData) -> bool:
							return other.region == region and _is_guide_dungeon(other)))
		var button := _create_button(dungeon.display_name)
		button.toggle_mode = true
		button.button_group = _dungeon_group
		button.tooltip_text = Language.translate("Empfohlen ab Level %d") % dungeon.level
		button.button_pressed = _selected != null and _selected.id == dungeon.id
		button.pressed.connect(_select.bind(dungeon))
		GuideFrame.attach(button, func() -> bool: return not button.button_pressed and _is_guide_dungeon(dungeon))
		# Indented under its tab.
		var row := MarginContainer.new()
		row.add_theme_constant_override("margin_left", 6)
		row.add_child(button)
		(_region_lists[dungeon.region] as VBoxContainer).add_child(row)


## The dungeons this board lists: those on the board now, or only `only_dungeons` (while their
## story flag is set and they are not gone).
func _get_dungeons() -> Array[DungeonData]:
	var result: Array[DungeonData] = []
	if only_dungeons.is_empty():
		result.assign(ContentDB.get_all_dungeons().filter(func(dungeon: DungeonData) -> bool:
				return (GameState.admin_all_dungeons and not dungeon.hidden) 						or dungeon.is_on_board(GameState.story, GameState.achievements.counters)))
		return result
	for id in only_dungeons:
		var dungeon: DungeonData = ContentDB.dungeon(id)
		if dungeon and GameState.story.has_flag(dungeon.required_flag) \
				and (dungeon.gone_flag.is_empty() or not GameState.story.flags.has(dungeon.gone_flag)):
			result.append(dungeon)
	return result


func _select(dungeon: DungeonData) -> void:
	if _selected != dungeon:
		_power = 1
	_selected = dungeon
	_show_dungeon()


## Description and rewards of the selected dungeon (or a hint without one).
func _show_dungeon() -> void:
	_clear(_reward_row)
	if _selected == null:
		_build_mode_row()
		_description_label.text = Language.translate("Wähle links eine Gegend und einen Dungeon.")
		_description_label.add_theme_color_override("default_color", COLOR_HINT)
		_refresh()
		return
	_description_label.remove_theme_color_override("default_color")
	_power = clampi(_power, 1, GameState.get_max_dungeon_power(_selected))
	_build_mode_row()
	_description_label.text = _describe(_selected)
	for slot in _create_reward_slots(_selected):
		_reward_row.add_child(slot)
	_refresh()


func _describe(dungeon: DungeonData) -> String:
	var facts: Array[String] = [Language.translate("Lv %d") % dungeon.level, Language.translate("%d Stufen") % dungeon.stage_count]
	if dungeon.time_limit > 0.0:
		facts.append(Language.translate("Zeitlimit ") + DungeonData.format_time(dungeon.time_limit))
	var cost: int = dungeon.get_cost(GameState.achievements.counters)
	facts.append(Language.translate("Kosten %d Gold") % cost if cost > 0 else Language.translate("Kostenlos"))
	facts.append(Language.translate("%d Ausdauer je Held") % dungeon.stamina_cost)
	var enemy_links: Array[String] = []
	for enemy in dungeon.get_enemies():
		enemy_links.append(Lexicon.enemy_link(enemy, _escape(enemy.display_name)))
	var lines: Array[String] = [_escape(dungeon.display_name + " · " + " · ".join(facts)), _escape(dungeon.description),
			Language.translate("Gegner: ") + ", ".join(enemy_links)]
	var stages: Array[String] = []
	for stage in dungeon.get_special_stages():
		var label: String = dungeon.get_stage_label(stage)
		if not label.is_empty():
			stages.append(Language.translate("Stufe %d: %s") % [stage, label])
	if not stages.is_empty():
		lines.append(_escape(" · ".join(stages)))
	if _power > 1:
		lines.append(_escape(_describe_hard_mode(_power)))
	return "\n".join(lines)


## Plain text for the RichTextLabel: "[" would start a tag.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


## "Schwer ×3: Gegner 3× so stark · Beute ×1,8 und seltener · Boss-Barren sicher, +1 · Gold ×2 · PEXP ×2".
func _describe_hard_mode(power: int) -> String:
	var hard: Dictionary = DungeonData.hard_mode(power)
	return Language.translate("Schwer ×%d: Gegner %d× so stark · Beute ×%s und seltener · Boss-Barren sicher, +%d · Gold ×%s · PEXP ×%s") % [
			power, power, _factor_text(hard["drop_factor"]), hard["extra_ingots"],
			_factor_text(hard["gold_factor"]), _factor_text(hard["exp_factor"])] 			+ ("" if int(hard["rarity_shift"]) <= 0 else Language.translate(" · Beute mindestens %s") 					% Rarity.get_display_name(mini(int(hard["rarity_shift"]), Rarity.Tier.MYTHIC) as Rarity.Tier))


## 1.5 » "1,5", 2.0 » "2".
func _factor_text(value: float) -> String:
	var text: String = ("%d" % roundi(value)) if is_equal_approx(value, roundf(value)) else ("%.1f" % value)
	return text.replace(".", ",")


## Mode buttons of the selected dungeon, only once it was won: normal and every power, those not
## opened yet greyed out with a hint. Hidden for a dungeon never won.
func _build_mode_row() -> void:
	_clear(_mode_row)
	var max_power: int = GameState.get_max_dungeon_power(_selected) if _selected else 1
	_mode_row.visible = max_power > 1
	if not _mode_row.visible:
		return
	_mode_row.add_child(_create_label(Language.translate("Modus:")))
	var group := ButtonGroup.new()
	for power in DungeonData.get_hard_mode_powers():
		var button := _create_button(Language.translate("Normal") if power == 1 else "×%d" % power)
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = power == _power
		if power > 1:
			button.add_theme_color_override("font_color", COLOR_HARD)
		if power > max_power:
			button.disabled = true
			button.tooltip_text = Language.translate("Erst ×%d schaffen.") % (power - 1) if power > 2 \
					else Language.translate("Erst normal schaffen.")
		else:
			button.tooltip_text = Language.translate("Normaler Dungeon.") if power == 1 else _describe_hard_mode(power)
		button.pressed.connect(func() -> void:
				_power = power
				_show_dungeon())
		_mode_row.add_child(button)


## Icons of everything the dungeon can give; the tooltip names it with amount and chance.
func _create_reward_slots(dungeon: DungeonData) -> Array[Control]:
	var slots: Array[Control] = []
	if dungeon.reward_gold["max"] > 0:
		slots.append(_create_reward_slot(ICON_GOLD, _colored(Language.translate("%s Gold") % DungeonData.format_amount(dungeon.reward_gold), COLOR_GOLD)
				+ _chance_text(dungeon.reward_gold["chance"])))
	if dungeon.reward_experience["max"] > 0:
		slots.append(_create_reward_slot(ICON_EXPERIENCE, _colored(Language.translate("%s PEXP für den Schmied") % DungeonData.format_amount(dungeon.reward_experience), COLOR_EXPERIENCE)
				+ _chance_text(dungeon.reward_experience["chance"])))
	for reward: Dictionary in dungeon.reward_items:
		var item: ItemData = reward["item"]
		if not GameState.is_loot_unlocked(item, dungeon):
			continue  # ore of a metal the story has not reached yet: never given
		var amount: String = DungeonData.format_amount(reward)
		slots.append(_create_reward_slot(item.icon, Language.translate("%s x%s%s") % [item.display_name, amount, _chance_text(reward["chance"])]))
	for recipe in dungeon.get_reward_recipes():
		var known: bool = GameState.is_recipe_unlocked(recipe)
		var text: String = _colored(Language.translate("Rezept: ") + recipe.get_display_name(), COLOR_RECIPE)
		slots.append(_create_reward_slot(recipe.get_icon() if recipe.get_icon() else ICON_MOLD,
				text + ("\n" + _colored(Language.translate("Schon bekannt."), COLOR_HINT) if known else ""), known))
	if not dungeon.random_mold_material.is_empty() and GameState.is_metal_unlocked(dungeon.random_mold_material):
		slots.append(_create_mold_slot(dungeon))
	if slots.is_empty():
		slots.append(_create_label(Language.translate("Keine"), COLOR_HINT))
	return slots


## [R]: a random mold of the dungeon's metal the player does not know yet.
func _create_mold_slot(dungeon: DungeonData) -> Control:
	var metal: String = ContentDB.material_name(dungeon.random_mold_material)
	var unknown: int = GameState.get_unknown_molds(dungeon.random_mold_material).size()
	var total: int = ContentDB.get_mold_recipes(dungeon.random_mold_material).size()
	var text: String = _colored(Language.translate("Zufällige %s-Gussform") % metal, COLOR_RECIPE) + _chance_text(dungeon.random_mold_chance)
	text += "\n" + _colored(Language.translate("Eine, die du noch nicht kennst (mit Amboss-Rezept)."), COLOR_HINT)
	if unknown == 0:
		text += "\n" + _colored(Language.translate("Du kennst schon alle %s-Gussformen – hier gibt es keine mehr.") % metal, COLOR_HINT)
	else:
		text += "\n" + _colored(Language.translate("Noch %d von %d unbekannt.") % [unknown, total], COLOR_HINT)
	return _create_reward_slot(ItemIcons.mold_of("unknown", dungeon.random_mold_material), text, unknown == 0)


func _create_reward_slot(icon: Texture2D, tooltip_bbcode: String, faded: bool = false) -> Control:
	var slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	_reward_row.add_child(slot)
	slot.display_custom(icon, tooltip_bbcode)
	_reward_row.remove_child(slot)
	if faded:
		slot.modulate = Color(1, 1, 1, 0.4)
	return slot


func _chance_text(chance: float) -> String:
	return "" if chance >= 1.0 else _colored("  (%d %%)" % roundi(chance * 100.0), COLOR_HINT)


# --- Hero slots -----------------------------------------------------------------------

## Drops heroes that are gone or busy now, rebuilds the slots and the running list.
func _refresh() -> void:
	for i in _party.size():
		var hero: Hero = _party[i]
		if hero and (not GameState.heroes.has(hero) or GameState.is_hero_busy(hero)):
			_party[i] = null
	_build_hero_slots()
	_update_send_button()
	_rebuild_running_list()


func _build_hero_slots() -> void:
	_clear(_hero_row)
	for i in _party.size():
		_hero_row.add_child(_create_hero_slot(i))


## Slot frame with the hero's portrait (or "+"), his name below; a click opens the picker.
func _create_hero_slot(index: int) -> Control:
	var hero: Hero = _party[index]
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(HERO_SLOT_WIDTH, 0)
	box.add_theme_constant_override("separation", 1)
	var slot := Panel.new()
	slot.theme_type_variation = &"ItemSlot"
	slot.custom_minimum_size = HERO_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.tooltip_text = Language.translate("Held wählen") if hero == null else Language.translate("Anderen Helden wählen")
	slot.gui_input.connect(_on_hero_slot_input.bind(index, slot))
	box.add_child(slot)
	if hero == null:
		GuideFrame.attach(slot, func() -> bool:
				return index == _party.find(null) and not _hero_picker.visible and _is_guide_dungeon(_selected) 						and not _party.any(_is_guide_hero) and GameState.heroes.any(_is_guide_hero))
	if hero:
		var portrait := TextureRect.new()
		portrait.texture = CharacterBaker.get_portrait(hero.get_appearance())
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(portrait)
	else:
		var plus := _create_label("+", COLOR_HINT)
		plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(plus)
	var name_label := _create_label(hero.display_name if hero else Language.translate("Held %d") % (index + 1),
			hero.hero_class.color if hero else COLOR_HINT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	box.add_child(name_label)
	if hero:
		var level_label := _create_label(Language.translate("Lv %d · %s") % [hero.level, _stamina_text(hero)], COLOR_HINT)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(level_label)
	return box


func _on_hero_slot_input(event: InputEvent, index: int, slot: Control) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		if _picking_slot == index and _hero_picker.visible:
			_close_picker()
		else:
			_open_picker(index, slot)
		slot.accept_event()


## Small window below the slot: every free hero (not on an adventure, not in another slot),
## "Entfernen" for a filled slot, "Abbrechen".
func _open_picker(index: int, slot: Control) -> void:
	_picking_slot = index
	_clear(_picker_list)
	_picker_list.add_child(_create_label(Language.translate("Held wählen:")))
	var any: bool = false
	for hero in GameState.heroes:
		if GameState.is_hero_busy(hero) or (_party.has(hero) and _party[index] != hero):
			continue
		any = true
		var button := _create_button(Language.translate("%s (%s, Lv %d, Ausdauer %s)") % [hero.display_name, hero.hero_class.display_name,
				hero.level, _stamina_text(hero)])
		button.icon = CharacterBaker.get_portrait(hero.get_appearance())
		if _selected and hero.stamina < _selected.stamina_cost:
			button.disabled = true
			button.tooltip_text = Language.translate("Zu erschöpft für diesen Dungeon.")
		button.add_theme_color_override("font_color", hero.hero_class.color)
		button.pressed.connect(_pick_hero.bind(hero))
		GuideFrame.attach(button, func() -> bool: return not button.disabled and _is_guide_hero(hero))
		_picker_list.add_child(button)
	if not any:
		var hint: String = Language.translate("Heuere zuerst einen Helden an.") if GameState.heroes.is_empty() else Language.translate("Kein Held frei.")
		_picker_list.add_child(_create_label(hint, COLOR_HINT))
	if _party[index] != null:
		var remove := _create_button(Language.translate("Entfernen"))
		remove.pressed.connect(_pick_hero.bind(null))
		_picker_list.add_child(remove)
	var cancel := _create_button(Language.translate("Abbrechen"))
	cancel.pressed.connect(_close_picker)
	_picker_list.add_child(cancel)
	_hero_picker.reset_size()
	_hero_picker.show()
	# The picker is a top-level child of the board panel: drawn above the board in any case, also
	# after a click brings the board to the front (WindowTitleBar does that deferred, after this).
	_title_bar.bring_to_front()
	# Below the slot, kept inside the screen.
	var screen: Vector2 = _hero_picker.get_viewport_rect().size
	var at: Vector2 = slot.global_position + Vector2(0, slot.size.y + 2)
	_hero_picker.position = at.clamp(Vector2.ZERO, screen - _hero_picker.size)


func _pick_hero(hero: Hero) -> void:
	if _picking_slot >= 0:
		_party[_picking_slot] = hero
	_close_picker()
	_refresh()


func _close_picker() -> void:
	_picking_slot = -1
	if _hero_picker:
		_hero_picker.hide()


func _get_party() -> Array[Hero]:
	var party: Array[Hero] = []
	for hero: Hero in _party:
		if hero:
			party.append(hero)
	return party


func _update_send_button() -> void:
	_message_label.text = ""
	if GameState.heroes.is_empty():
		_message_label.text = Language.translate("Heuere zuerst einen Helden an.")
	elif GameState.heroes.all(GameState.is_hero_busy):
		_message_label.text = Language.translate("Alle Helden sind unterwegs.")
	_send_button.disabled = _selected == null or _get_party().is_empty()
	var cost: int = _selected.get_cost(GameState.achievements.counters) if _selected else 0
	_send_button.text = Language.translate("Losschicken") if cost == 0 else Language.translate("Losschicken (%d Gold)") % cost
	if not _send_button.disabled:
		var problem: String = GameState.get_send_problem(_get_party(), _selected)
		if not problem.is_empty():
			_message_label.text = problem
			_send_button.disabled = true


## "80/100" (rounded down).
func _stamina_text(hero: Hero) -> String:
	return "%d/%d" % [floori(hero.stamina), roundi(Hero.get_max_stamina())]


func _on_send_pressed() -> void:
	var party: Array[Hero] = _get_party()
	if _selected == null or party.is_empty():
		return
	if GameState.send_party(party, _selected, _power):
		_party.fill(null)
		close()


# --- Running adventures ---------------------------------------------------------------

func _rebuild_running_list() -> void:
	_clear(_running_list)
	_running_labels.clear()
	if GameState.adventures.is_empty():
		_running_list.add_child(_create_label(Language.translate("Keine laufenden Abenteuer."), COLOR_HINT))
		return
	for adventure in GameState.adventures:
		var row := HBoxContainer.new()
		var label: Label = _create_label(_running_text(adventure))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		row.add_child(label)
		var follow := _create_button(Language.translate("Verfolgen"))
		follow.pressed.connect(func() -> void:
				close()
				Events.adventure_view_requested.emit(adventure))
		row.add_child(follow)
		# TEMPORARY dev shortcut (Adventure.finish_instantly), remove before release.
		if adventure.can_finish_instantly(GameState.achievements.counters):
			var instant := _create_button(Language.translate("Sofort"))
			instant.tooltip_text = Language.translate("Test: den Kampf sofort zu Ende rechnen.")
			instant.pressed.connect(adventure.finish_instantly)
			row.add_child(instant)
		_running_list.add_child(row)
		_running_labels[adventure] = label


func _running_text(adventure: Adventure) -> String:
	var text: String = Language.translate("Abenteuer %d: %s · %s · Stufe %d/%d") % [GameState.adventures.find(adventure) + 1,
			adventure.get_dungeon_title(), adventure.get_party_names(), adventure.stage, adventure.dungeon.stage_count]
	if adventure.dungeon.time_limit > 0.0:
		text += " · " + DungeonData.format_time(adventure.get_time_left())
	return text


# --- Guide ----------------------------------------------------------------------------

func _is_guide_dungeon(dungeon: DungeonData) -> bool:
	return dungeon != null and Guide.is_target("dungeon:" + String(dungeon.id))


## A free hero the guide points at ("hero:<id>"); null slots of the party are never.
func _is_guide_hero(hero: Variant) -> bool:
	return hero is Hero and not GameState.is_hero_busy(hero) and Guide.is_target("hero:" + String((hero as Hero).id))


# --- Helpers --------------------------------------------------------------------------

func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _create_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
