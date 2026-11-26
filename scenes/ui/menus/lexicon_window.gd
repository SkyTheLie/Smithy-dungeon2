class_name LexiconWindow
extends PanelContainer
## Lexikon (main menu): every item as a small picture. Items picked up at least once in some run
## (Progress) show their picture, name, effect and the synergies they are part of (once all
## partners of that synergy were found too). Others are dark: "???" and, if still locked, what
## unlocks them. Hover or click a picture to read it. Grouped by relic tier (data/relics.json):
## R1, R2, R3, R4 (title in the rarity colour, how long such a relic holds), then the items that
## are no relic.

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
## Sections (title + grid per relic tier), built in code in place of the scene's Grid.
var _sections: VBoxContainer


func _ready() -> void:
	%Close.pressed.connect(close)
	var scroll: Node = _grid.get_parent()
	scroll.remove_child(_grid)
	_sections = VBoxContainer.new()
	_sections.add_theme_constant_override("separation", 4)
	scroll.add_child(_sections)


func open() -> void:
	_build()
	show()
	_show_item(_first_id)


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
					text = Language.translate("Habe %d Herz-Container gleichzeitig")
				"coins":
					text = Language.translate("Habe %d Münzen gleichzeitig")
				"blue":
					text = Language.translate("Habe %d blaue Herzen gleichzeitig")
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
