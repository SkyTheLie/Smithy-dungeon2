class_name ArenaFighterPanel
extends PanelContainer
## One of the two boards above the ring (ArenaFightStage): "Held" or "Gegner", the fighter's name in
## the colour of his class, class and level, and his equipment on the silhouette of the hero
## window (same places, HeroWindow.SLOT_POSITIONS). Only shows, nothing can be taken out
## (ItemSlotUI without inventory index). The item tooltips work as everywhere.

@onready var _title_label: Label = %TitleLabel
@onready var _name_label: Label = %NameLabel
@onready var _info_label: Label = %InfoLabel
@onready var _doll: EquipmentDoll = %Doll

var _slot_uis: Array[ItemSlotUI] = []


func _ready() -> void:
	for slot in Hero.EquipmentSlot.values():
		var hint: String = Hero.SLOT_KEYS[slot].trim_suffix("_1").trim_suffix("_2")  # ring_1/ring_2 -> ring
		_slot_uis.append(_doll.add_slot(HeroWindow.SLOT_POSITIONS[slot], Language.translate(Hero.SLOT_NAMES[slot]), hint))


## Shows `hero` under the heading `title` (German key, e.g. "Held").
func show_hero(title: String, hero: Hero) -> void:
	_title_label.text = Language.translate(title)
	_name_label.text = hero.display_name
	_name_label.add_theme_color_override("font_color", HeroTournamentMenu.class_color(hero))
	var class_text: String = hero.hero_class.display_name if hero.hero_class else ""
	_info_label.text = Language.translate("%s · Lv %d") % [class_text, hero.level]
	for slot in _slot_uis.size():
		EquipmentDoll.show_stack(_slot_uis[slot], hero.get_equipped(slot))
