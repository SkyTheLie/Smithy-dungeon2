class_name LexiconWindow
extends PanelContainer
## Lexikon (main menu), two tabs (like the lexicon of Smithy):
##   Items: every item as a small picture. Items picked up at least once in some run (Progress)
##     show their picture, name, effect and the synergies they are part of (once all partners of
##     that synergy were found too). Others are dark: "???" and, if still locked, what unlocks
##     them. Grouped by relic tier (data/relics.json): R1 … R4, then the items that are no relic.
##   Gegner: every enemy, grouped by the dungeon where it first comes (Content.dungeon_enemies).
##     Beaten at least once (Progress.meet_enemy): picture, name, life, damage, speed, boss, its
##     loot (loot.json) and where it lives; before that a black silhouette and "???".
## Hover or click a picture to read it.

signal closed

const SLOT_SIZE := Vector2(30, 30)
const HIDDEN_COLOR := Color(0.05, 0.03, 0.05, 0.9)
const LOCKED_COLOR := Color(0.25, 0.05, 0.05, 0.9)
const ICON_STATES: Array[String] = ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]

@onready var _grid: GridContainer = %Grid
@onready var _count: Label = %Count
@onready var _icon: TextureRect = %DetailIcon
@onready var _name: Label = %DetailName
@onready var _desc: Label = %DetailDesc
@onready var _extra: Label = %DetailExtra

var _first_id: String = ""
## Sections (title + grid per relic tier / per dungeon), built in code in place of the scene's Grid.
var _sections: VBoxContainer
## 0 = Items, 1 = Gegner.
var _tab: int = 0
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	%Close.pressed.connect(close)
	var scroll: Node = _grid.get_parent()
	scroll.remove_child(_grid)
	_sections = VBoxContainer.new()
	_sections.add_theme_constant_override("separation", 4)
	scroll.add_child(_sections)
	# Tabs under the count: Items, Gegner.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	_count.get_parent().add_child(tabs)
	_count.get_parent().move_child(tabs, _count.get_index() + 1)
	var group := ButtonGroup.new()
	for i in 2:
		var tab := Button.new()
		tab.name = "Tab%d" % i
		tab.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		tab.text = Language.translate("Items") if i == 0 else Language.translate("Gegner")
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(show_tab.bind(i))
		tabs.add_child(tab)
		_tab_buttons.append(tab)


func open() -> void:
	show()
	show_tab(_tab)


## 0 = Items, 1 = Gegner.
func show_tab(index: int) -> void:
	_tab = clampi(index, 0, 1)
	for i in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == _tab)
	if _tab == 0:
		_build()
		_show_item(_first_id)
	else:
		_build_enemies()
		_show_enemy(_first_id)


func close() -> void:
	hide()
	closed.emit()


## One slot per item: grouped by relic tier (R1 … R4), then "Kein Relikt"; in each group in the
## order of data/items.json.
func _build() -> void:
	for child: Node in _sections.get_children():
		child.queue_free()
	var found: int = 0
	_first_id = ""
	var groups: Dictionary = {}
	for id: String in Content.items():
		var tier: int = ShopGoods.relic_tier(id)
		if not groups.has(tier):
			groups[tier] = []
		(groups[tier] as Array).append(id)
		if Progress.is_discovered(id):
			found += 1
	var order: Array = groups.keys().filter(func(tier: int) -> bool: return tier > 0)
	order.sort()
	if groups.has(0):
		order.append(0)
	for tier: int in order:
		_sections.add_child(_section_title(tier))
		var grid := GridContainer.new()
		grid.columns = _grid.columns
		grid.add_theme_constant_override("h_separation", _grid.get_theme_constant("h_separation"))
		grid.add_theme_constant_override("v_separation", _grid.get_theme_constant("v_separation"))
		_sections.add_child(grid)
		for id: String in groups[tier]:
			if _first_id.is_empty():
				_first_id = id
			grid.add_child(_slot(id))
	_count.text = Language.translate("Entdeckt: %d / %d") % [found, Content.items().size()]


## "R2 · Relikt · Hält noch 3 Dungeons" in the colour of the tier ("Kein Relikt" for tier 0).
func _section_title(tier: int) -> Label:
	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.add_theme_font_size_override("font_size", 11)
	if tier <= 0:
		title.text = Language.translate("Kein Relikt")
		title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
		return title
	var data: Dictionary = (Content.relics().get("tiers", {}) as Dictionary).get(str(tier), {})
	var runs: int = int(data.get("dungeons", 0))
	var hold: String = Language.translate("Hält für immer") if runs <= 0 else Language.translate("Hält noch %d Dungeons") % runs
	title.text = "R%d · %s · %s" % [tier, Language.translate("Relikt"), hold]
	title.add_theme_color_override("font_color", Rarity.color(int(data.get("rarity", tier))))
	return title


func _slot(id: String) -> Button:
	var known: bool = Progress.is_discovered(id)
	var slot := Button.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.focus_mode = Control.FOCUS_NONE
	slot.expand_icon = true
	slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.icon = load(String(Content.item(id).get("icon", ""))) as Texture2D
	if not known:
		var tint: Color = HIDDEN_COLOR if Progress.is_unlocked(id) else LOCKED_COLOR
		for state: String in ICON_STATES:
			slot.add_theme_color_override(state, tint)
	slot.mouse_entered.connect(_show_item.bind(id))
	slot.pressed.connect(_show_item.bind(id))
	return slot


func _show_item(id: String) -> void:
	var data: Dictionary = Content.item(id)
	if data.is_empty():
		return
	_icon.texture = load(String(data.get("icon", ""))) as Texture2D
	if Progress.is_discovered(id):
		_icon.modulate = Color.WHITE
		_name.text = Language.translate(String(data.get("name", id)))
		_desc.text = Language.translate(String(data.get("desc", "")))
		var tier: int = ShopGoods.relic_tier(id)
		var relic: String = "R%d %s" % [tier, Language.translate("Relikt")] if tier > 0 else ""
		_extra.text = (category_text(String(data.get("category", ""))) + "\n" + relic + "\n" + _synergy_text(id)).strip_edges()
		return
	var open_to_find: bool = Progress.is_unlocked(id)
	_icon.modulate = HIDDEN_COLOR if open_to_find else LOCKED_COLOR
	_name.text = "???"
	if open_to_find:
		_desc.text = Language.translate("Noch nicht entdeckt")
		_extra.text = ""
	else:
		_desc.text = Language.translate("Gesperrt")
		_extra.text = unlock_text(data.get("unlock", {}))


## Offensiv / Defensiv / Utility (data "category").
static func category_text(category: String) -> String:
	match category:
		"offensiv":
			return Language.translate("Offensiv")
		"defensiv":
			return Language.translate("Defensiv")
		"utility":
			return Language.translate("Utility")
	return ""


## "Synergien: A, B" for known synergies with this item ("" if none).
func _synergy_text(id: String) -> String:
	var names: Array[String] = []
	var all: Dictionary = Content.synergies()
	for synergy_id: String in all:
		var takes_part: bool = false
		var all_known: bool = true
		for group: Array in all[synergy_id].get("requires", []):
			takes_part = takes_part or group.has(id)
			var any_known: bool = false
			for other: Variant in group:
				any_known = any_known or Progress.is_discovered(String(other))
			all_known = all_known and any_known
		if takes_part and all_known:
			names.append(Language.translate(String(all[synergy_id].get("name", synergy_id))))
	if names.is_empty():
		return ""
	return Language.translate("Synergien: %s") % ", ".join(names)


# --- Gegner ---------------------------------------------------------------------------

## One section per dungeon (its name; "???" while it is locked and none of its enemies is known),
## with the enemies that come there first.
func _build_enemies() -> void:
	for child: Node in _sections.get_children():
		child.queue_free()
	_first_id = ""
	var shown: Array[String] = []
	for dungeon_id: String in Content.dungeons():
		var ids: Array[String] = []
		for id: String in Content.dungeon_enemies(dungeon_id):
			if not shown.has(id):
				ids.append(id)
				shown.append(id)
		if ids.is_empty():
			continue
		var title := Label.new()
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		title.add_theme_font_size_override("font_size", 11)
		title.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
		var known_any: bool = ids.any(func(id: String) -> bool: return Progress.has_met(id))
		var named: bool = MetaState.is_dungeon_open(dungeon_id) or known_any
		title.text = Language.translate(String(Content.dungeon(dungeon_id).get("name", dungeon_id))) if named else "???"
		_sections.add_child(title)
		var grid := GridContainer.new()
		grid.columns = _grid.columns
		grid.add_theme_constant_override("h_separation", _grid.get_theme_constant("h_separation"))
		grid.add_theme_constant_override("v_separation", _grid.get_theme_constant("v_separation"))
		_sections.add_child(grid)
		for id: String in ids:
			if _first_id.is_empty():
				_first_id = id
			grid.add_child(_enemy_slot(id))
	var met: int = shown.filter(func(id: String) -> bool: return Progress.has_met(id)).size()
	_count.text = Language.translate("Besiegt: %d / %d") % [met, shown.size()]


func _enemy_slot(id: String) -> Button:
	var slot := Button.new()
	slot.name = "Enemy_" + id
	slot.custom_minimum_size = SLOT_SIZE
	slot.focus_mode = Control.FOCUS_NONE
	slot.expand_icon = true
	slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.icon = Content.enemy_icon(id)
	if not Progress.has_met(id):
		for state: String in ICON_STATES:
			slot.add_theme_color_override(state, HIDDEN_COLOR)
	slot.mouse_entered.connect(_show_enemy.bind(id))
	slot.pressed.connect(_show_enemy.bind(id))
	return slot


func _show_enemy(id: String) -> void:
	var data: Dictionary = Content.enemy(id)
	if data.is_empty():
		return
	_icon.texture = Content.enemy_icon(id)
	if not Progress.has_met(id):
		_icon.modulate = HIDDEN_COLOR
		_name.text = "???"
		_desc.text = Language.translate("Noch nicht besiegt")
		_extra.text = ""
		return
	_icon.modulate = Color.WHITE
	_name.text = Language.translate(String(data.get("name", id)))
	var lines: Array[String] = []
	if String(data.get("ai", "")) == "boss":
		lines.append(Language.translate("Boss"))
	lines.append(Language.translate("Leben: %d · Schaden: %d") % [int(data.get("hp", 0)), int(data.get("damage", 0))])
	lines.append(Language.translate("Tempo: %s") % PauseMenu.format_number(float(data.get("speed", 0.0))))
	_desc.text = "\n".join(lines)
	_extra.text = (enemy_loot_text(id) + "\n" + enemy_home_text(id)).strip_edges()


## "Beute: Rattenfell (100 %), Rubin (50 %)" ("" without loot).
static func enemy_loot_text(id: String) -> String:
	var parts: Array[String] = []
	for entry: Variant in Content.enemy_loot(id):
		if not entry is Dictionary:
			continue
		var loot_data: Dictionary = Content.material(String((entry as Dictionary).get("id", "")))
		if loot_data.is_empty():
			continue
		parts.append("%s (%d %%)" % [Language.translate(String(loot_data.get("name", ""))), roundi(float((entry as Dictionary).get("chance", 0.0)) * 100.0)])
	return Language.translate("Beute: %s") % ", ".join(parts) if not parts.is_empty() else ""


## "Fundort: Dungeon der Glut, Moor der Irrlichter".
static func enemy_home_text(id: String) -> String:
	var homes: Array[String] = []
	for dungeon_id: String in Content.dungeons():
		if Content.dungeon_enemies(dungeon_id).has(id):
			homes.append(Language.translate(String(Content.dungeon(dungeon_id).get("name", dungeon_id))))
	return Language.translate("Fundort: %s") % ", ".join(homes) if not homes.is_empty() else ""


## What unlocks an item, with the progress so far (translated).
static func unlock_text(unlock: Dictionary) -> String:
	var count: int = int(unlock.get("count", 1))
	match String(unlock.get("type", "")):
		"boss":
			var boss: String = String(Content.enemy(String(unlock.get("id", ""))).get("name", ""))
			return Language.translate("Besiege: %s") % Language.translate(boss)
		"wins":
			if count == 1:
				return Language.translate("Gewinne einen Run")
			return Language.translate("Gewinne %d Runs") % count
		"kills":
			return Language.translate("Besiege %d Gegner (%d / %d)") % [count, mini(Progress.kills(), count), count]
		"discovered":
			return Language.translate("Entdecke %d Items (%d / %d)") % [count, mini(Progress.discovered().size(), count), count]
		"fast_win":
			return Language.translate("Gewinne in unter %d Minuten") % count
		"best":
			var key: String = String(unlock.get("key", ""))
			var text: String = ""
			match key:
				"hearts":
					text = Language.translate("Habe %d Kohlestücke gleichzeitig")
				"coins":
					text = Language.translate("Habe %d Münzen gleichzeitig")
				"blue":
					text = Language.translate("Habe %d Schlammschichten gleichzeitig")
				"clean_floors":
					text = Language.translate("Schaffe %d Ebenen nacheinander ohne Treffer")
				"pacts":
					text = Language.translate("Nimm %d Glutpakte in einem Run")
				"floor":
					text = Language.translate("Erreiche Ebene %d")
				_:
					return ""
			return text % count + "  (%d / %d)" % [mini(Progress.best(key), count), count]
	return ""
