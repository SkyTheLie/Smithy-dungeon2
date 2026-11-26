class_name LexiconWindow
extends PanelContainer
## Lexikon (main menu): every item as a small picture. Items picked up at least once in some run
## (Progress) show their picture, name, effect and the synergies they are part of (once all
## partners of that synergy were found too). Others are dark: "???" and, if still locked, what
## unlocks them. Hover or click a picture to read it.

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


func _ready() -> void:
	%Close.pressed.connect(close)


func open() -> void:
	_build()
	show()
	_show_item(_first_id)


func close() -> void:
	hide()
	closed.emit()


## One slot per item, in the order of data/items.json.
func _build() -> void:
	for child: Node in _grid.get_children():
		child.queue_free()
	var found: int = 0
	_first_id = ""
	for id: String in Content.items():
		if _first_id.is_empty():
			_first_id = id
		var known: bool = Progress.is_discovered(id)
		if known:
			found += 1
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
		_grid.add_child(slot)
	_count.text = Language.translate("Entdeckt: %d / %d") % [found, Content.items().size()]


func _show_item(id: String) -> void:
	var data: Dictionary = Content.item(id)
	if data.is_empty():
		return
	_icon.texture = load(String(data.get("icon", ""))) as Texture2D
	if Progress.is_discovered(id):
		_icon.modulate = Color.WHITE
		_name.text = Language.translate(String(data.get("name", id)))
		_desc.text = Language.translate(String(data.get("desc", "")))
		_extra.text = (category_text(String(data.get("category", ""))) + "\n" + _synergy_text(id)).strip_edges()
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
