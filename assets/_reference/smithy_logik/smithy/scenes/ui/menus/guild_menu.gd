class_name GuildMenu
extends StationMenu
## Adventurers' guild: list of heroes that can be hired here, one row each with [portrait]
## name, class (in class color), level, price and "Anheuern". With `daily_offers` (default) the
## heroes are a new group every day (HeroOffers); otherwise the fixed `heroes`. Hired heroes
## disappear from the list. Only classes the player has unlocked come, from the day after the
## unlock (ClassUnlocks: a weapon they may carry can be made).

const PORTRAIT_SIZE: Vector2 = Vector2(24, 24)
const FONT_SIZE: int = 11
const SMALL_FONT_SIZE: int = 11
const COLOR_GOLD: Color = Color(1, 0.85, 0.35)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_ERROR: Color = Color(0.9, 0.4, 0.35)

## A new group of generated heroes every day (HeroOffers). Off = the fixed `heroes` below.
@export var daily_offers: bool = true
## Fixed hero templates (only used without `daily_offers`).
@export var heroes: Array[Hero] = []

@onready var _list: VBoxContainer = %HeroList
@onready var _message_label: Label = %MessageLabel
@onready var _intro: Label = $Panel/VBox/Intro

## Page buttons "Helden" / "Suchaufträge" (only once Hedwig expanded the guild, GuildLevel) and
## the search order page (SearchOrderPanel), both built in code.
var _page_tabs: HBoxContainer
var _heroes_tab: Button
var _search_tab: Button
var _search_panel: SearchOrderPanel


func _ready() -> void:
	super()
	_build_pages()
	visibility_changed.connect(_rebuild)
	# Deferred: hiring happens inside the pressed signal of a row button that gets removed.
	GameState.heroes_changed.connect(_rebuild, CONNECT_DEFERRED)
	_rebuild()


func _build_pages() -> void:
	var vbox: VBoxContainer = $Panel/VBox
	_page_tabs = HBoxContainer.new()
	_page_tabs.add_theme_constant_override("separation", 4)
	var group := ButtonGroup.new()
	_heroes_tab = _create_tab(Language.translate("Helden"), group)
	_search_tab = _create_tab(Language.translate("Suchaufträge"), group)
	vbox.add_child(_page_tabs)
	vbox.move_child(_page_tabs, _intro.get_index())
	_search_panel = SearchOrderPanel.new()
	_search_panel.visible = false
	vbox.add_child(_search_panel)
	vbox.move_child(_search_panel, _message_label.get_index())
	_heroes_tab.button_pressed = true


func _create_tab(text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggled.connect(func(_on: bool) -> void: _show_page())
	_page_tabs.add_child(button)
	return button


## Hero list or search orders; without a guild level only the hero list (no page buttons).
func _show_page() -> void:
	var expanded: bool = GuildLevel.get_level(GameState.story) > 0
	_page_tabs.visible = expanded
	var search: bool = expanded and _search_tab.button_pressed
	_intro.visible = not search
	_list.visible = not search
	_search_panel.visible = search
	if search:
		_search_panel.refresh()
	_message_label.text = ""


func _rebuild() -> void:
	_show_page()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var offered: int = 0
	for hero in get_offered_heroes():
		if GameState.has_hero(hero.id):
			continue
		_list.add_child(_create_row(hero))
		offered += 1
	if offered == 0 and ClassUnlocks.get_available_class_ids().is_empty():
		_list.add_child(_create_label(Language.translate("Noch keine Helden hier. Sobald du eine Waffe herstellen kannst, kommen ab dem nächsten Tag Helden, die sie tragen."), COLOR_HINT, SMALL_FONT_SIZE))
	elif offered == 0:
		_list.add_child(_create_label(Language.translate("Alle Helden der Gilde sind bereits angeheuert."), COLOR_HINT, SMALL_FONT_SIZE))


func _create_row(hero: Hero) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var portrait := TextureRect.new()
	portrait.texture = hero.get_portrait()
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	names.add_child(_create_label(hero.display_name))
	names.add_child(_create_label(Language.translate("%s · Lv %d") % [hero.hero_class.display_name, hero.level],
			hero.hero_class.color, SMALL_FONT_SIZE))
	row.add_child(names)
	row.add_child(_create_label(Language.translate("%d Gold") % hero.hire_cost, COLOR_GOLD, SMALL_FONT_SIZE))
	var button := Button.new()
	button.text = Language.translate("Anheuern")
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	button.pressed.connect(_hire.bind(hero))
	row.add_child(button)
	return row


func _hire(hero: Hero) -> void:
	var blocker: String = GameState.get_hire_blocker(hero)
	if not GameState.hire_hero(hero):
		_message_label.text = blocker
		_message_label.add_theme_color_override("font_color", COLOR_ERROR)


func _create_label(text: String, color: Color = Color.WHITE, size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


## The heroes the guild offers today (hired ones included; callers skip GameState.has_hero).
func get_offered_heroes() -> Array[Hero]:
	var classes: Array[String] = ClassUnlocks.get_available_class_ids()
	if daily_offers:
		return HeroOffers.for_day(GameState.day_cycle.day, classes, GuildLevel.get_info(GameState.story))
	var result: Array[Hero] = []
	for hero in heroes:
		if hero.hero_class and classes.has(String(hero.hero_class.id)):
			result.append(hero)
	return result
