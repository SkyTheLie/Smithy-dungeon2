class_name HeroStatsWindow
extends PanelContainer
## All values of a hero ("Mehr anzeigen" in the hero window): attributes split into base,
## learned points and equipment, plus everything derived from them (formulas: CombatRules).
## Left column: attributes and combat values; right column: resistance and damage taken per
## damage kind (in its colour) and progress.

const COLOR_HEADER: Color = Color(0.95, 0.8, 0.5)
const COLOR_BONUS: Color = Color(0.55, 0.85, 0.45)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)

var _hero: Hero

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _left: GridContainer = %Grid
@onready var _right: GridContainer = %RightGrid
## Grid the _add_* helpers write into.
@onready var _grid: GridContainer = _left


func _ready() -> void:
	# Text size (settings » "Textgröße: Werte"); the grids grow with it.
	TextSize.attach($VBox/Columns, "stats", [], func() -> void: reset_size.call_deferred())


func show_hero(hero: Hero) -> void:
	if _hero and _hero.changed.is_connected(_refresh):
		_hero.changed.disconnect(_refresh)
	_hero = hero
	_hero.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _hero == null:
		return
	_title_bar.title = Language.translate("Werte: %s") % _hero.display_name
	for grid in [_left, _right]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	_grid = _left
	_add_header(Language.translate("Attribute"), Language.translate("Basis"), Language.translate("Punkte"), Language.translate("Ausr."))
	for type in ItemAttribute.Type.values():
		var points: int = int(_hero.attribute_points.get(type, 0))
		var bonus: int = _hero.get_equipment_attribute(type)
		_add_row(Language.translate(ItemAttribute.NAMES[type]), str(_hero.get_base_attribute(type) - points),
			"+%d" % points if points > 0 else "-", "+%d" % bonus if bonus > 0 else "-")
	_add_header(Language.translate("Kampf"), "", "", "")
	_add_value("IQ (Befehle)", str(_hero.get_iq()))
	_add_value(Language.translate("Leben"), str(_hero.get_max_health()))
	_add_value(Language.translate("Leben-Regeneration"), "%s /s" % _number(_hero.get_health_regen()))
	_add_value(Language.translate("Mana"), str(_hero.get_max_mana()))
	_add_value(Language.translate("Mana-Regeneration"), "%s /s" % _number(_hero.get_mana_regen()))
	_add_value(Language.translate("Waffenschaden"), "%d-%d" % [_hero.get_damage_min(), _hero.get_damage_max()])
	_add_value(Language.translate("Magieschaden"), "%d-%d" % [_hero.get_magic_damage_min(), _hero.get_magic_damage_max()])
	_add_value(Language.translate("Zauberschaden"), "+%s %%" % _number((_hero.get_magic_damage_factor() - 1.0) * 100.0))
	_add_value(Language.translate("Angriffe pro Sekunde"), "%s" % _number(1.0 / _hero.get_attack_interval()))
	_add_value(Language.translate("Abklingzeit"), "-%s %%" % _number(_hero.get_cooldown_reduction() * 100.0))
	_add_value(Language.translate("Krit-Chance"), "%s %%" % _number(_hero.get_crit_chance() * 100.0))
	_add_value(Language.translate("Krit-Schaden"), "%d %%" % roundi(_hero.get_crit_damage() * 100.0))
	_add_value(Language.translate("Ausweichen"), "%s %%" % _number(_hero.get_evasion() * 100.0))
	# Only with a ring (or skill) that gives them.
	if _hero.get_passive_value("lifesteal") > 0.0:
		_add_value(Language.translate("Lebensraub"), "%s %%" % _number(_hero.get_passive_value("lifesteal")))
	if _hero.get_passive_value("stun_chance") > 0.0:
		_add_value(Language.translate("Betäubungs-Chance"), "%s %%" % _number(_hero.get_passive_value("stun_chance")))
	if _hero.get_passive_value("poison_chance") > 0.0:
		_add_value(Language.translate("Gift-Chance"), "%s %%" % _number(_hero.get_passive_value("poison_chance")))
	# Rogue with a weapon in the left hand: it hits on its own, half as often (combat.json).
	var left: InventorySlot = _hero.get_equipped(Hero.EquipmentSlot.LEFT_HAND)
	if left and left.item.is_weapon() and not left.item.uses_arrows() and _hero.hero_class \
			and String(_hero.hero_class.id) in ContentDB.combat_list("offhand_attack_classes"):
		var per_second: float = 1.0 / (_hero.get_attack_interval() * ContentDB.combat_value("offhand_attack_interval_factor", 2.0))
		var factor: float = ContentDB.combat_value("offhand_attack_damage", 0.5) * (1.0 + _hero.get_passive_value("offhand") / 100.0)
		_add_value(Language.translate("Linke Hand"), Language.translate("%d %% Schaden, %s /s") % [roundi(factor * 100.0), _number(per_second)])
	_add_value(Language.translate("Heilkraft"), "%d %%" % roundi(_hero.get_heal_power() * 100.0))
	_add_value(Language.translate("Schildkraft"), "%d %%" % roundi(_hero.get_shield_power() * 100.0))
	_add_value(Language.translate("Schild (Zauber)"), "%d" % roundi(CombatRules.caster_shield(_hero.level, _hero.get_attribute(ItemAttribute.Type.WISDOM))))
	_add_value(Language.translate("Zähigkeit"), "%s %%" % _number(_hero.get_tenacity() * 100.0))
	_add_value(Language.translate("Buff-Dauer"), "+%s %%" % _number(_hero.get_buff_duration_bonus() * 100.0))
	var armor: int = _hero.get_armor()
	var magic_resistance: int = _hero.get_magic_resistance()
	_add_value(Language.translate("Rüstung"), str(armor))
	_add_hint(Language.translate("  %s %% weniger körperl. Schaden") % _number(CombatRules.reduction(armor) * 100.0))
	_add_value(Language.translate("Magieresistenz"), str(magic_resistance))
	_add_hint(Language.translate("  %s %% weniger Zauberschaden") % _number(CombatRules.reduction(magic_resistance) * 100.0))
	var pen: Dictionary = _hero.get_penetration()
	_add_value(Language.translate("Rüstungsdurchdr."), "%s %% / +%s" % [_number(pen["armor_percent"] * 100.0), _number(pen["armor_flat"])])
	_add_value(Language.translate("Magiedurchdr."), "%s %% / +%s" % [_number(pen["magic_percent"] * 100.0), _number(pen["magic_flat"])])
	# Resistance per damage kind (with the RES attribute) and how much of that kind gets through.
	_grid = _right
	_add_header(Language.translate("Resistenzen"), "", Language.translate("Wert"), "erlitten")
	var resistances: Dictionary = _hero.get_total_resistances()
	for kind: String in DamageKinds.PHYSICAL_KINDS + DamageKinds.ELEMENT_KINDS + [DamageKinds.MAGIC]:
		var value: float = resistances.get(kind, 0.0)
		var taken: float = CombatRules.mitigation(kind, armor, magic_resistance, resistances) * 100.0
		_add_kind_row(kind, value, taken)
	_add_header(Language.translate("Fortschritt"), "", "", "")
	_add_value(Language.translate("Level"), "%d / %d" % [_hero.level, _hero.get_max_level()])
	_add_value(Language.translate("Attributpunkte frei"), str(_hero.get_free_attribute_points()))
	_add_value(Language.translate("Skillpunkte frei"), str(_hero.get_free_skill_points()))


func _add_header(title: String, a: String, b: String, c: String) -> void:
	for text in [title, a, b, c]:
		var label := Label.new()
		label.text = text
		label.add_theme_color_override("font_color", COLOR_HEADER)
		_grid.add_child(label)


func _add_row(title: String, a: String, b: String, c: String) -> void:
	var name_label := Label.new()
	name_label.text = title
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(name_label)
	for text in [a, b, c]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if text.begins_with("+"):
			label.add_theme_color_override("font_color", COLOR_BONUS)
		elif text == "-":
			label.add_theme_color_override("font_color", COLOR_HINT)
		_grid.add_child(label)


## Name in the colour of the damage kind, its own resistance and the damage taken in %.
func _add_kind_row(kind: String, value: float, taken: float) -> void:
	var name_label := Label.new()
	name_label.text = DamageKinds.get_display_name(kind)
	name_label.add_theme_color_override("font_color", DamageKinds.get_color(kind))
	_grid.add_child(name_label)
	_grid.add_child(Label.new())
	for text in ["%+d" % roundi(value) if value != 0.0 else "-", "%d %%" % roundi(taken)]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if text == "-":
			label.add_theme_color_override("font_color", COLOR_HINT)
		_grid.add_child(label)


func _number(value: float) -> String:
	return DamageKinds.format_number(value)


## A grey note under a value (e.g. how much armor reduces), over the whole row.
func _add_hint(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_HINT)
	_grid.add_child(label)
	for i in 3:
		_grid.add_child(Label.new())


## A value spans the last column; the two middle ones stay empty.
func _add_value(title: String, value: String) -> void:
	_add_row(title, "", "", value)
