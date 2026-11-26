class_name BattleWindow
extends PanelContainer
## Shows a running adventure. The fight itself runs in Adventure (ticked by GameState), so
## closing this window does not stop it. Three parts:
## 1. BattleStage: the heroes on the left, the monsters on the right (side view).
## 2. Header: "« Brett" (back to the dungeon board, only if one is in the scene), stage and the
##    tabs "Schaden" / "Buffs".
## 3. One column per hero: name, HP and MP (bar + number), then
##    "Schaden": damage per basic attack and per skill;
##    "Buffs": active buffs/debuffs (icon, stacks, seconds left), damage dealt through effects
##    (green), damage taken through effects (red), healed and shielded.
## 4. After the fight: the result, on a victory the rewards as slots (gold, PEXP, items, new molds;
##    the recipes that come with a mold only in its tooltip), names in the tooltips.
## Closes with Escape or the interact key (E) like a station window.

## Group of this window (story figures wait for it before they start talking).
const GROUP: StringName = &"battle_windows"
## Group of the dungeon board menu (DungeonBoardMenu adds itself) for the back button.
const DUNGEON_BOARD_GROUP: StringName = &"dungeon_board_menus"
const COLUMN_WIDTH: float = 120.0
const BAR_HEIGHT: float = 4.0
## Effect icons are 24x24 (like item icons), drawn 1:1.
const ICON_SIZE: int = 24
## Seconds between two updates of the statistics text.
const TEXT_INTERVAL: float = 0.25
const COLOR_HEALTH: Color = Color(0.8, 0.28, 0.25)
const COLOR_MANA: Color = Color(0.35, 0.55, 0.95)
const COLOR_BAR_BACK: Color = Color(0.13, 0.075, 0.12)
const COLOR_COLUMN: Color = Color(0.2, 0.15, 0.19)
const COLOR_COLUMN_BORDER: Color = Color(0.36, 0.26, 0.26)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_DEALT: Color = Color(0.45, 0.85, 0.45)
const COLOR_TAKEN: Color = Color(0.92, 0.38, 0.33)
const COLOR_SHIELD: Color = Color(0.5, 0.72, 1.0)
## Damage statistics: basic attacks and physical skills in dark red, magic in its element's color.
const COLOR_PHYSICAL_DAMAGE: Color = Color(0.82, 0.27, 0.24)
const COLOR_VICTORY: Color = Color(0.55, 0.85, 0.45)
const COLOR_DEFEAT: Color = Color(0.9, 0.4, 0.35)
const COLOR_GOLD: Color = Color(1, 0.85, 0.35)
const COLOR_EXPERIENCE: Color = Color(0.55, 0.75, 1)
const COLOR_RECIPE: Color = Color(0.85, 0.65, 1.0)
const ICON_GOLD: Texture2D = preload("res://assets/ui/icon_coin.png")
const ICON_EXPERIENCE: Texture2D = preload("res://assets/ui/icon_exp.png")
const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")

var _adventure: Adventure
## Combatant -> {"health_bar", "health_label", "mana_bar", "mana_label", "details"}
var _columns: Dictionary = {}
var _text_timer: float = 0.0

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
## Seconds the "Aufgeben" button waits for the second click.
const GIVE_UP_CONFIRM_SECONDS: float = 3.0
var _give_up_armed: bool = false
## TEMPORARY "Sofort" button next to "Aufgeben" (built in _ready).
var _instant_button: Button

@onready var _stage: BattleStage = %Stage
@onready var _stage_label: Label = %StageLabel
@onready var _back_button: Button = %BackButton
@onready var _give_up_button: Button = %GiveUpButton
@onready var _damage_tab: Button = %DamageTab
@onready var _buffs_tab: Button = %BuffsTab
@onready var _hero_columns: HBoxContainer = %HeroColumns
@onready var _result_label: Label = %ResultLabel
@onready var _reward_row: HBoxContainer = %RewardRow


func _ready() -> void:
	add_to_group(GROUP)
	var group := ButtonGroup.new()
	_damage_tab.button_group = group
	_buffs_tab.button_group = group
	group.pressed.connect(func(_button: BaseButton) -> void: _update_texts())
	_back_button.pressed.connect(_on_back_pressed)
	_give_up_button.pressed.connect(_on_give_up_pressed)
	# TEMPORARY dev shortcut (Adventure.finish_instantly), remove before release.
	_instant_button = Button.new()
	_instant_button.text = Language.translate("Sofort")
	_instant_button.tooltip_text = Language.translate("Test: den Kampf sofort zu Ende rechnen.")
	_instant_button.focus_mode = Control.FOCUS_NONE
	_instant_button.visible = false
	_give_up_button.add_sibling(_instant_button)
	_instant_button.pressed.connect(func() -> void:
			if _adventure:
				_adventure.finish_instantly())
	visibility_changed.connect(func() -> void: _back_button.visible = _get_board() != null)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or StationMenu.is_any_open(get_tree()):
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		hide()
		get_viewport().set_input_as_handled()


## The dungeon board of the current scene (null if there is none).
func _get_board() -> StationMenu:
	return get_tree().get_first_node_in_group(DUNGEON_BOARD_GROUP) as StationMenu


## First click: "Wirklich?" for a few seconds; second click calls the heroes back (Adventure.give_up).
func _on_give_up_pressed() -> void:
	if _adventure == null or _adventure.state != Adventure.State.RUNNING:
		return
	if not _give_up_armed:
		_give_up_armed = true
		_give_up_button.text = Language.translate("Wirklich?")
		get_tree().create_timer(GIVE_UP_CONFIRM_SECONDS, false).timeout.connect(_reset_give_up)
		return
	_reset_give_up()
	_adventure.give_up()


func _reset_give_up() -> void:
	_give_up_armed = false
	if _give_up_button:
		_give_up_button.text = Language.translate("Aufgeben")
		_give_up_button.visible = _adventure != null and _adventure.state == Adventure.State.RUNNING
	if _instant_button:
		_instant_button.visible = _adventure != null and _adventure.can_finish_instantly(GameState.achievements.counters)


func _on_back_pressed() -> void:
	var board: StationMenu = _get_board()
	if board:
		hide()
		board.show()


func show_adventure(adventure: Adventure) -> void:
	if _adventure:
		_adventure.finished.disconnect(_on_finished)
		_adventure.skill_used.disconnect(_on_skill_used)
	_adventure = adventure
	_adventure.finished.connect(_on_finished)
	_adventure.skill_used.connect(_on_skill_used)
	_title_bar.title = "%s – %s" % [adventure.get_dungeon_title(), adventure.get_party_names()]
	_stage.show_adventure(adventure)
	_result_label.text = ""
	_reset_give_up()
	_clear_rewards()
	_build_columns()
	if adventure.state != Adventure.State.RUNNING:
		_on_finished(adventure.state == Adventure.State.VICTORY)
	show()


## Skill sounds only while the fight is on screen (adventures also run with the window closed).
func _on_skill_used(_user: Combatant, skill: SkillData) -> void:
	if is_visible_in_tree() and not _adventure.fast_forwarding:
		AudioManager.play_skill_sound(String(skill.id))


func _process(delta: float) -> void:
	if not visible or _adventure == null:
		return
	var parts: Array[String] = [Language.translate("Stufe %d / %d") % [_adventure.stage, _adventure.dungeon.stage_count]]
	var stage_label: String = _adventure.dungeon.get_stage_label(_adventure.stage)
	if not stage_label.is_empty():
		parts.append(stage_label)
	if _adventure.is_walking():
		parts.append("unterwegs")
	if _adventure.dungeon.time_limit > 0.0:
		parts.append(Language.translate("Zeit ") + DungeonData.format_time(_adventure.get_time_left()))
	_stage_label.text = " · ".join(parts)
	for fighter: Combatant in _columns:
		var column: Dictionary = _columns[fighter]
		(column["health_bar"] as ProgressBar).value = fighter.health
		(column["health_label"] as Label).text = "HP %d / %d" % [ceili(fighter.health), fighter.max_health]
		(column["mana_bar"] as ProgressBar).value = fighter.mana
		(column["mana_label"] as Label).text = "MP %d / %d" % [floori(fighter.mana), fighter.max_mana]
	_text_timer -= delta
	if _text_timer <= 0.0:
		_text_timer = TEXT_INTERVAL
		_update_texts()


# --- Hero columns -------------------------------------------------------------------

func _build_columns() -> void:
	for child in _hero_columns.get_children():
		_hero_columns.remove_child(child)
		child.queue_free()
	_columns.clear()
	var fighters: Array[Combatant] = _adventure.hero_fighters.duplicate()
	# A duel in the arena: the opponent is a hero too and gets his own column.
	if _adventure is ArenaDuel:
		fighters.append_array(_adventure.enemies)
	for fighter in fighters:
		_hero_columns.add_child(_create_column(fighter))
	_update_texts()


func _create_column(fighter: Combatant) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_COLUMN
	style.border_color = COLOR_COLUMN_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	var name_label := Label.new()
	name_label.text = Language.translate("%s Lv %d") % [fighter.display_name, fighter.level]
	if fighter.hero:
		name_label.add_theme_color_override("font_color", fighter.hero.hero_class.color)
		var role: String = fighter.hero.get_role()
		if not role.is_empty():
			name_label.tooltip_text = Language.translate("Rolle: %s") % HeroRole.get_display_name(role)
			name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(name_label)
	var health_label := Label.new()
	box.add_child(health_label)
	var health_bar := _create_bar(fighter.max_health, COLOR_HEALTH)
	box.add_child(health_bar)
	var mana_label := Label.new()
	box.add_child(mana_label)
	var mana_bar := _create_bar(maxi(fighter.max_mana, 1), COLOR_MANA)
	box.add_child(mana_bar)
	var details := RichTextLabel.new()
	details.bbcode_enabled = true
	details.fit_content = true
	details.scroll_active = false
	details.custom_minimum_size = Vector2(COLUMN_WIDTH - 6, 0)
	# Names of buffs and debuffs are links: a click opens what the effect does (lexicon).
	Lexicon.connect_links(details)
	box.add_child(details)
	_columns[fighter] = {"health_bar": health_bar, "health_label": health_label, "mana_bar": mana_bar,
			"mana_label": mana_label, "details": details}
	return panel


func _create_bar(maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.show_percentage = false
	bar.max_value = maximum
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BAR_BACK
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _update_texts() -> void:
	for fighter: Combatant in _columns:
		var details: RichTextLabel = _columns[fighter]["details"]
		var text: String = _buffs_text(fighter) if _buffs_tab.button_pressed else _damage_text(fighter)
		# Unchanged text stays (a new text in the middle of a click would lose the link).
		if details.text != text:
			details.text = text


## Damage per basic attack and per skill, biggest first, and the total.
func _damage_text(fighter: Combatant) -> String:
	var lines: Array[String] = []
	var sources: Array = fighter.damage_by_source.keys()
	sources.sort_custom(func(a: String, b: String) -> bool: return fighter.damage_by_source[a] > fighter.damage_by_source[b])
	var total: int = 0
	for source: String in sources:
		lines.append(_colored("%s: %d" % [source, fighter.damage_by_source[source]],
				_damage_color(fighter.damage_kind_by_source.get(source, DamageKinds.PHYSICAL))))
		total += fighter.damage_by_source[source]
	for effect_name: String in fighter.effect_damage_dealt:
		total += fighter.effect_damage_dealt[effect_name]
	if lines.is_empty():
		return _colored(Language.translate("Noch kein Schaden."), COLOR_HINT)
	lines.append(_colored(Language.translate("Gesamt (mit Effekten): %d") % total, COLOR_HINT))
	return "\n".join(lines)


## Color of a damage line: physical kinds dark red, elements / magic their color (dark ones a
## bit lighter, so they stay readable on the dark column).
func _damage_color(kind: String) -> Color:
	if DamageKinds.is_physical(kind):
		return COLOR_PHYSICAL_DAMAGE
	var color: Color = DamageKinds.get_color(kind)
	return color.lightened(0.3) if color.get_luminance() < 0.4 else color


## Active effects with icon, stacks and time left; effect damage dealt (green) and taken
## (red), healing / shields done (per skill) and received.
func _buffs_text(fighter: Combatant) -> String:
	var lines: Array[String] = []
	for active in fighter.effects:
		var icon: String = "[img=%dx%d]%s[/img] " % [ICON_SIZE, ICON_SIZE, active.data.icon.resource_path] if active.data.icon else ""
		var stacks: String = " x%d" % active.stacks if active.stacks > 1 else ""
		lines.append("%s%s%s (%ds)" % [icon, EffectInfo.link(active.data), stacks, ceili(active.time_left)])
	if lines.is_empty():
		lines.append(_colored(Language.translate("Keine Effekte aktiv."), COLOR_HINT))
	for effect_name: String in fighter.effect_damage_dealt:
		lines.append(_colored(Language.translate("%s verursacht: %d") % [effect_name, fighter.effect_damage_dealt[effect_name]], COLOR_DEALT))
	for effect_name: String in fighter.effect_damage_taken:
		lines.append(_colored(Language.translate("%s erlitten: %d") % [effect_name, fighter.effect_damage_taken[effect_name]], COLOR_TAKEN))
	# Done by this fighter (credited to the healer / shield caster), then what it got itself.
	_append_by_source(lines, fighter.healing_by_source, Language.translate("Heilung gewirkt: %d"), COLOR_DEALT)
	_append_by_source(lines, fighter.shielding_by_source, Language.translate("Schild gewirkt (abgefangen): %d"), COLOR_SHIELD)
	if fighter.total_healed > 0:
		lines.append(_colored(Language.translate("Heilung erhalten: %d") % fighter.total_healed, COLOR_DEALT))
	if fighter.total_shielded > 0:
		lines.append(_colored(Language.translate("Schild erhalten (abgefangen): %d") % fighter.total_shielded, COLOR_SHIELD))
	return "\n".join(lines)


## A total line ("Heilung gewirkt: 1234") and under it one line per skill / effect, biggest first.
func _append_by_source(lines: Array[String], by_source: Dictionary, title: String, color: Color) -> void:
	var sources: Array = by_source.keys()
	if sources.is_empty():
		return
	sources.sort_custom(func(a: String, b: String) -> bool: return by_source[a] > by_source[b])
	var total: int = 0
	for source: String in sources:
		total += by_source[source]
	lines.append(_colored(title % total, color))
	for source: String in sources:
		lines.append(_colored("  %s: %d" % [source, by_source[source]], COLOR_HINT))


func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]


func _clear_rewards() -> void:
	for child in _reward_row.get_children():
		_reward_row.remove_child(child)
		child.queue_free()


## One slot per reward of the won adventure. New molds get one slot each, the recipes they bring
## (anvil, workbench) are named in its tooltip; other new recipes get their own slot.
func _build_reward_slots() -> void:
	if _adventure.reward_gold > 0:
		_add_reward_slot(null).display_custom(ICON_GOLD, _colored("%d Gold" % _adventure.reward_gold, COLOR_GOLD),
				str(_adventure.reward_gold))
	if _adventure.reward_experience > 0:
		_add_reward_slot(null).display_custom(ICON_EXPERIENCE, _colored("%d PEXP für dich" % _adventure.reward_experience,
				COLOR_EXPERIENCE), str(_adventure.reward_experience))
	for item: ItemData in _adventure.reward_items:
		var stack := InventorySlot.new()
		stack.item = item
		stack.amount = _adventure.reward_items[item]
		_add_reward_slot(stack)
	for stack in _adventure.loot:
		_add_reward_slot(stack)
	var with_mold: Array[RecipeData] = []
	for recipe in _adventure.unlocked_recipes:
		if recipe.get_mold_part():
			with_mold.append_array(ContentDB.get_mold_unlocks(recipe))
	# A group (e.g. the nine staffs of a metal, one per crystal) is one entry, like rings and amulets.
	for recipe in RecipeData.collapse_groups(_adventure.unlocked_recipes):
		if recipe.get_mold_part():
			var names: Array[String] = []
			for other in ContentDB.get_mold_unlocks(recipe):
				if other != recipe and _adventure.unlocked_recipes.has(other) and not names.has(other.get_list_name()):
					names.append(other.get_list_name())
			var text: String = _colored("Neue " + recipe.get_display_name(), COLOR_RECIPE)
			if not names.is_empty():
				text += "\n" + _colored(Language.translate("Damit herstellbar: ") +", ".join(names), COLOR_HINT)
			_add_reward_slot(null).display_custom(recipe.get_icon(), text)
		elif not with_mold.has(recipe):
			_add_reward_slot(null).display_custom(recipe.get_icon(), _colored("Neues Rezept: " + recipe.get_list_name(), COLOR_RECIPE))


## Adds a slot to the reward row (it must be in the tree before it can show anything) and shows
## `stack` in it, if given.
func _add_reward_slot(stack: InventorySlot) -> ItemSlotUI:
	var slot: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
	_reward_row.add_child(slot)
	if stack:
		slot.display(stack)
	return slot


# --- Result -------------------------------------------------------------------------

func _on_finished(victory: bool) -> void:
	_reset_give_up()
	_clear_rewards()
	if victory:
		_build_reward_slots()
		var molds: Array[String] = []
		for recipe in _adventure.unlocked_recipes:
			if recipe.get_mold_part():
				molds.append(recipe.get_mold_part().display_name)
		if _reward_row.get_child_count() == 0:
			_result_label.text = Language.translate("Sieg! Diesmal gab es keine Belohnung.")
		else:
			_result_label.text = Language.translate("Sieg! Die Beute liegt in der Loot-Kiste.")
		if not molds.is_empty():
			_result_label.text += Language.translate(" Neue Gussform: %s.") % ", ".join(molds)
		_result_label.add_theme_color_override("font_color", COLOR_VICTORY)
	else:
		if _adventure.gave_up:
			_result_label.text = Language.translate("Aufgegeben in Stufe %d – die Helden kehren um. Keine Belohnung.") % _adventure.stage
		elif _adventure.timed_out:
			_result_label.text = Language.translate("Zeit abgelaufen in Stufe %d – die Helden kehren um. Keine Belohnung.") % _adventure.stage
		else:
			_result_label.text = Language.translate("Niederlage in Stufe %d – die Helden sind geflohen. Keine Belohnung.") % _adventure.stage
		_result_label.add_theme_color_override("font_color", COLOR_DEFEAT)
	var kill_parts: Array[String] = []
	for hero: Hero in _adventure.kill_experience:
		kill_parts.append("%s %d" % [hero.display_name, _adventure.kill_experience[hero]])
	if not kill_parts.is_empty():
		_result_label.text += Language.translate(" EXP aus Kämpfen: %s.") % ", ".join(kill_parts)
	_update_texts()
