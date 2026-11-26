class_name HeroPanel
extends PanelContainer
## Left in Egon's shop: the hero with his equipment, like the hero view in Smithy (template
## assets/_reference/vorlagen/helden_ansicht.png): a silhouette (ui/doll.png) and one ShopSlot per
## place of data/gear.json "slots" (at = centre of the place). An empty place shows a faint hint
## picture. A click on a place sends slot_clicked (the shop takes it off). Built in code.

signal slot_clicked(slot: String)

const DOLL: Texture2D = preload("res://assets/sprites/ui/doll.png")
const DOLL_OFFSET := Vector2(14, 8)
const AREA_SIZE := Vector2(124, 146)
const HINT_PATH: String = "res://assets/sprites/ui/slot_hints/equip_%s.png"

var _slots: Dictionary = {}


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
	refresh()


## Shows what MetaState says the hero wears.
func refresh() -> void:
	var worn: Dictionary = MetaState.equipment()
	for slot: String in _slots:
		(_slots[slot] as ShopSlot).show_entry(worn.get(slot, {}))


func get_slot(slot: String) -> ShopSlot:
	return _slots.get(slot)
