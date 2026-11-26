class_name HeroPanel
extends PanelContainer
## Left in Egon's shop: the hero with his equipment, like the hero view in Smithy (template
## assets/_reference/vorlagen/helden_ansicht.png): a silhouette (ui/doll.png) and one ShopSlot per
## place of data/gear.json "slots" (at = centre of the place). An empty place shows a faint hint
## picture. Below the figure a row of relic places (MetaState.relic_slot_names: 1, more with the
## skill Relikt-Platz). A click on a place sends slot_clicked (the shop takes it off). Built in code.

signal slot_clicked(slot: String)

const DOLL: Texture2D = preload("res://assets/sprites/ui/doll.png")
const DOLL_OFFSET := Vector2(14, 8)
const AREA_SIZE := Vector2(124, 146)
const HINT_PATH: String = "res://assets/sprites/ui/slot_hints/equip_%s.png"
const RELIC_HINT: String = "necklace"

var _slots: Dictionary = {}
var _relic_row: HBoxContainer


func _ready() -> void:
	theme_type_variation = &"HudPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	var title := Label.new()
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = Language.translate("Ausrüstung")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	column.add_child(title)
	var area := Control.new()
	area.custom_minimum_size = AREA_SIZE
	column.add_child(area)
	var doll := TextureRect.new()
	doll.texture = DOLL
	doll.position = DOLL_OFFSET
	doll.size = DOLL.get_size()
	doll.modulate = Color(1, 1, 1, 0.55)
	doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(doll)
	for slot: String in Content.gear_slots():
		var data: Dictionary = Content.gear_slots()[slot]
		var place := ShopSlot.new()
		place.name = "Slot_" + slot
		var hint_path: String = HINT_PATH % String(data.get("hint", ""))
		place.hint = load(hint_path) as Texture2D if ResourceLoader.exists(hint_path) else null
		place.hint_name = Language.translate(String(data.get("name", slot)))
		var at: Array = data.get("at", [0, 0])
		place.position = (Vector2(float(at[0]), float(at[1])) - ShopSlot.SIZE / 2.0).round()
		place.clicked.connect(slot_clicked.emit.bind(slot))
		area.add_child(place)
		_slots[slot] = place
	var relic_title := Label.new()
	relic_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	relic_title.text = Language.translate("Relikte")
	relic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_title.add_theme_font_size_override("font_size", 10)
	relic_title.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	column.add_child(relic_title)
	_relic_row = HBoxContainer.new()
	_relic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_relic_row.add_theme_constant_override("separation", 4)
	column.add_child(_relic_row)
	refresh()


## Shows what MetaState says the hero wears.
func refresh() -> void:
	_build_relic_places()
	var worn: Dictionary = MetaState.equipment()
	for slot: String in _slots:
		(_slots[slot] as ShopSlot).show_entry(worn.get(slot, {}))


func get_slot(slot: String) -> ShopSlot:
	return _slots.get(slot)


## One place per relic place the player has (more after the skill); kept when the number is the same.
func _build_relic_places() -> void:
	var names: Array[String] = MetaState.relic_slot_names()
	var count: int = 0
	for slot: String in _slots.keys():
		if slot.begins_with("relic_"):
			count += 1
	if count == names.size():
		return
	for slot: String in _slots.keys():
		if slot.begins_with("relic_"):
			(_slots[slot] as Node).queue_free()
			_slots.erase(slot)
	var hint_path: String = HINT_PATH % RELIC_HINT
	for slot: String in names:
		var place := ShopSlot.new()
		place.name = "Slot_" + slot
		place.hint = load(hint_path) as Texture2D if ResourceLoader.exists(hint_path) else null
		place.hint_name = Language.translate("Relikt")
		place.clicked.connect(slot_clicked.emit.bind(slot))
		_relic_row.add_child(place)
		_slots[slot] = place
