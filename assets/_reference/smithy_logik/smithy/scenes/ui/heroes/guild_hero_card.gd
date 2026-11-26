class_name GuildHeroCard
extends CanvasLayer
## Small card of a hero waiting at a guild table (GuildPatrons, E next to him): picture, name,
## level and class (in class colour), race and its bonus, life, mana, damage, the attributes and the
## hire price.
## Built in code; E, Esc or walking away closes it.

const PORTRAIT_SCALE: float = 2.0
const FONT_SIZE: int = 11
const COLOR_GOLD: Color = Color(1.0, 0.85, 0.35)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_RACE: Color = Color(0.85, 0.78, 0.6)
## Width of the race line (longer bonuses wrap).
const RACE_TEXT_WIDTH: float = 170.0

var hero: Hero

var _portrait: TextureRect
var _name_label: Label
var _class_label: Label
var _race_label: Label
var _values: GridContainer
var _price_label: Label


func _init() -> void:
	layer = 15
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -95.0
	panel.offset_right = 95.0
	panel.offset_top = 40.0
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	_portrait = TextureRect.new()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.add_child(_portrait)
	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	_name_label = _label("", 13)
	names.add_child(_name_label)
	_class_label = _label("")
	names.add_child(_class_label)
	_race_label = _label("")
	_race_label.custom_minimum_size.x = RACE_TEXT_WIDTH
	_race_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_race_label.add_theme_color_override("font_color", COLOR_RACE)
	box.add_child(_race_label)
	_values = GridContainer.new()
	_values.columns = 2
	_values.add_theme_constant_override("h_separation", 10)
	box.add_child(_values)
	_price_label = _label("")
	_price_label.add_theme_color_override("font_color", COLOR_GOLD)
	box.add_child(_price_label)
	var hint := _label(KeyBindings.fill(Language.translate("Anheuern an der Theke · {key_interact}: schließen")))
	hint.add_theme_color_override("font_color", COLOR_HINT)
	box.add_child(hint)
	visible = false


func show_hero(new_hero: Hero) -> void:
	hero = new_hero
	var portrait: Texture2D = CharacterBaker.get_portrait(hero.get_appearance())
	_portrait.texture = portrait
	_portrait.custom_minimum_size = portrait.get_size() * PORTRAIT_SCALE if portrait else Vector2.ZERO
	_name_label.text = hero.display_name
	var class_name_text: String = hero.hero_class.display_name if hero.hero_class else ""
	_class_label.text = Language.translate("Lvl %d %s") % [hero.level, class_name_text]
	_class_label.add_theme_color_override("font_color", hero.hero_class.color if hero.hero_class else Color.WHITE)
	_race_label.text = hero.get_race_line()
	for child in _values.get_children():
		_values.remove_child(child)
		child.queue_free()
	_add_value(Language.translate("Leben"), str(hero.get_max_health()))
	_add_value(Language.translate("Mana"), str(hero.get_max_mana()))
	_add_value(Language.translate("Schaden"), "%d–%d" % [hero.get_damage_min(), hero.get_damage_max()])
	for type in ItemAttribute.Type.values():
		_add_value(Language.translate(ItemAttribute.NAMES[type]), str(hero.get_attribute(type)))
	_price_label.text = Language.translate("%d Gold") % hero.hire_cost
	visible = true


func close() -> void:
	visible = false
	hero = null


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()


func _add_value(title: String, value: String) -> void:
	_values.add_child(_label(title))
	var value_label := _label(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_values.add_child(value_label)


func _label(text: String, font_size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label
