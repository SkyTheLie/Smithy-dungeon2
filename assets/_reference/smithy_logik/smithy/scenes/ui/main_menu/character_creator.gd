extends Control
## Character creator ("Neues Spiel" in the main menu): choose race, skin tone, hair style and
## colour, eye shape and colour, size, clothes and their colour and a name. The preview walks in the chosen direction
## (arrows below it turn the figure). "Los geht's" stores the look in GameState, starts a new
## story and shows the intro (scenes/story/intro.tscn); "Zurück" goes back to the main menu.
## The choices come from data/content/appearance.json (see Appearance), new options need no code.
##
## Menu: on the right the categories (CATEGORIES). Clicking one makes the list narrow and its
## options slide in from the right: per field a title and a row of slots (portraits of the figure
## with that option, colour swatches). "Farben" shows every colour field and a colour wheel for an
## own colour. Clicking the open category again closes it.

const MAIN_MENU: String = "res://scenes/ui/main_menu/main_menu.tscn"
const INTRO: String = "res://scenes/story/intro.tscn"
const FIELD_NAMES: Dictionary = {
	"race": "Rasse", "skin": "Hautfarbe", "hair_style": "Frisur", "hair_color": "Haarfarbe",
	"eye_type": "Augen", "eye_color": "Augenfarbe", "size": "Größe", "outfit": "Kleidung",
	"clothes_color": "Kleidungsfarbe", "horn_style": "Hörner", "horn_color": "Hornfarbe",
	"ear_style": "Ohren", "body": "Figur",
}
## Buttons of the menu: name and the fields on its page; "wheel" = colour wheel below; "horns" =
## only for races with horns (Appearance.has_horns), "ears" = only for races with ears of their own
## (Appearance.has_ears).
const CATEGORIES: Array[Dictionary] = [
	{"name": "Volk", "fields": ["race", "body", "size"]},
	{"name": "Hörner", "fields": ["horn_style", "horn_color"], "wheel": true, "horns": true},
	{"name": "Ohren", "fields": ["ear_style"], "ears": true},
	{"name": "Farben", "fields": ["skin", "hair_color", "eye_color", "clothes_color"], "wheel": true},
	{"name": "Haare", "fields": ["hair_style", "hair_color"]},
	{"name": "Augen", "fields": ["eye_type", "eye_color"]},
	{"name": "Kleidung", "fields": ["outfit", "clothes_color"]},
]
## Fields whose slots show the figure's head with that option.
const PORTRAIT_FIELDS: Array[String] = ["race", "hair_style", "eye_type", "outfit", "horn_style", "ear_style"]
const PREVIEW_ZOOM: float = 4.0
const WALK_FPS: float = 8.0
const FONT_SIZE: int = 11
## Widths of the menu (scene node Menu): all, the option page, the narrow category list.
const MENU_WIDTH: float = 260.0
const MENU_SEPARATION: float = 4.0
const OPTIONS_WIDTH: float = 176.0
const CATEGORY_WIDTH_OPEN: float = MENU_WIDTH - MENU_SEPARATION - OPTIONS_WIDTH
const CATEGORY_HEIGHT: float = 24.0
const SLIDE_TIME: float = 0.25
const SLOT_SIZE: float = 26.0
const COLOR_SLOT_SIZE: float = 16.0
const TEXT_SLOT_WIDTH: float = 46.0
const SWATCH_INSET: float = 3.0
## Width of the race bonus text under the race slots (longer lines wrap).
const RACE_TEXT_WIDTH: float = 166.0
const COLOR_RACE_TEXT: Color = Color(0.85, 0.78, 0.6)
const COLOR_TITLE: Color = Color(0.95, 0.85, 0.55)
const COLOR_SELECTED: Color = Color(1.0, 0.82, 0.3)
const COLOR_HOVER: Color = Color(1.25, 1.2, 1.1)
## Directions in turning order for the arrows under the preview.
const TURN_ORDER: Array[String] = ["down", "left", "up", "right"]
## Slot value of the "own colour" slot behind the colour swatches.
const CUSTOM_SLOT: String = "#"

var _look: Appearance = Appearance.new()
var _direction: int = 0
var _time: float = 0.0
var _preview_texture := AtlasTexture.new()
## Open category (index in CATEGORIES), -1 = none.
var _category: int = -1
var _category_buttons: Array[Button] = []
## 0 = closed, 1 = option page fully in (tweened).
var _open_amount: float = 0.0
## Extra shift of the option page to the right (slides a new page in when switching).
var _content_offset: float = 0.0
var _tween: Tween
## Slots of the open page: {"field", "value", "button", "icon", "frame"}.
var _slots: Array[Dictionary] = []
## field -> title Label of the open page.
var _titles: Dictionary = {}
## Options of the fields when the page was built; if they change (other race, outfit) it is rebuilt.
var _built_options: String = ""
## Field the colour wheel changes and its title.
var _wheel_field: String = "hair_color"
var _wheel: ColorWheel
var _wheel_title: Label
## field -> last own colour "#rrggbb" (the own-colour slot keeps it after choosing a swatch).
var _custom_colors: Dictionary = {}
## What the chosen race gives the smith and heroes of that race (appearance.json bonuses).
var _race_label: Label
var _slot_style: StyleBox
var _frame_style := StyleBoxFlat.new()

@onready var _preview: TextureRect = %Preview
@onready var _name_edit: LineEdit = %NameEdit
@onready var _options: Control = %Options
@onready var _options_scroll: ScrollContainer = %OptionsScroll
@onready var _options_list: VBoxContainer = %OptionsList
@onready var _category_scroll: ScrollContainer = %CategoryScroll
@onready var _categories: VBoxContainer = %Categories


func _ready() -> void:
	_slot_style = get_theme_stylebox("panel", "ItemSlot")
	_frame_style.draw_center = false
	_frame_style.border_color = COLOR_SELECTED
	_frame_style.set_border_width_all(1)
	for i in CATEGORIES.size():
		var button := _create_button(Language.translate(CATEGORIES[i]["name"]), _on_category_pressed.bind(i))
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, CATEGORY_HEIGHT)
		_categories.add_child(button)
		_category_buttons.append(button)
	_options.resized.connect(_place_options)
	_set_open_amount(0.0)
	_name_edit.text = Language.translate(GameState.DEFAULT_PLAYER_NAME)
	_preview.texture = _preview_texture
	%TurnLeftButton.pressed.connect(_turn.bind(1))
	%TurnRightButton.pressed.connect(_turn.bind(-1))
	%RandomButton.pressed.connect(_randomize)
	%BackButton.pressed.connect(_on_back_pressed)
	%StartButton.pressed.connect(_on_start_pressed)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_update_preview_frame()


# --- Category menu ------------------------------------------------------------------------

func _on_category_pressed(index: int) -> void:
	if index == _category:
		_close_category()
		return
	var was_open: bool = _category >= 0
	_category = index
	_build_page()
	_update_category_buttons()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if was_open:
		_set_open_amount(1.0)
		_tween.tween_method(_set_content_offset, OPTIONS_WIDTH, 0.0, SLIDE_TIME)
	else:
		_set_content_offset(0.0)
		_tween.tween_method(_set_open_amount, _open_amount, 1.0, SLIDE_TIME)


func _close_category() -> void:
	_category = -1
	_update_category_buttons()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_open_amount, _open_amount, 0.0, SLIDE_TIME)
	_tween.tween_callback(_clear_page)


## Pressed state; "Hörner" and "Ohren" only for races that have them (their open page closes when
## the race has none).
func _update_category_buttons() -> void:
	for i in _category_buttons.size():
		_category_buttons[i].set_pressed_no_signal(i == _category)
		_category_buttons[i].visible = (not CATEGORIES[i].get("horns", false) or _look.has_horns()) \
				and (not CATEGORIES[i].get("ears", false) or _look.has_ears())
	if _category >= 0 and not _category_buttons[_category].visible:
		_close_category()


## The option page grows from 0 to OPTIONS_WIDTH while the category list gets narrower, so the
## menu keeps its width.
func _set_open_amount(amount: float) -> void:
	_open_amount = amount
	var width: float = roundf(OPTIONS_WIDTH * amount)
	_options.custom_minimum_size.x = width
	_category_scroll.custom_minimum_size.x = MENU_WIDTH - MENU_SEPARATION - width
	_place_options()


func _set_content_offset(offset: float) -> void:
	_content_offset = offset
	_place_options()


## The page hangs at the right edge of its clip (next to the categories): it moves in from there.
func _place_options() -> void:
	_options_scroll.size = Vector2(OPTIONS_WIDTH, _options.size.y)
	_options_scroll.position = Vector2(roundf(_options.custom_minimum_size.x - OPTIONS_WIDTH + _content_offset), 0)


# --- Option page --------------------------------------------------------------------------

func _clear_page() -> void:
	for child in _options_list.get_children():
		_options_list.remove_child(child)
		child.queue_free()
	_slots.clear()
	_titles.clear()
	_wheel = null
	_wheel_title = null
	_race_label = null
	_built_options = ""


func _build_page() -> void:
	_clear_page()
	_options_scroll.scroll_vertical = 0
	var category: Dictionary = CATEGORIES[_category]
	var fields: Array = category["fields"]
	if category.get("wheel", false) and not fields.has(_wheel_field):
		_wheel_field = fields.filter(func(f: String) -> bool: return Appearance.COLOR_FIELDS.has(f))[0]
	for field: String in fields:
		var title := _create_label("")
		title.add_theme_color_override("font_color", COLOR_TITLE)
		_options_list.add_child(title)
		_titles[field] = title
		if field == "clothes_color" and not _clothes_colorable():
			# no swatches that would do nothing: just say so (keeps the page without scrolling)
			var note := _create_label(Language.translate("Diese Kleidung behält ihre Farbe."))
			note.add_theme_color_override("font_color", COLOR_RACE_TEXT)
			_options_list.add_child(note)
			continue
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 2)
		row.add_theme_constant_override("v_separation", 2)
		_options_list.add_child(row)
		var options: Array = _options_for(field)
		for value: String in options:
			row.add_child(_create_slot(field, value))
		var is_color: bool = Appearance.COLOR_FIELDS.has(field)
		if is_color and category.get("wheel", false):
			row.add_child(_create_slot(field, CUSTOM_SLOT))
		if field == "race":
			_race_label = _create_label("")
			_race_label.custom_minimum_size.x = RACE_TEXT_WIDTH
			_race_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_race_label.add_theme_color_override("font_color", COLOR_RACE_TEXT)
			_options_list.add_child(_race_label)
	if category.get("wheel", false):
		_wheel_title = _create_label("")
		_wheel_title.add_theme_color_override("font_color", COLOR_TITLE)
		_options_list.add_child(_wheel_title)
		_wheel = ColorWheel.new()
		_wheel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_wheel.color_changed.connect(_on_wheel_changed)
		_options_list.add_child(_wheel)
		_wheel.set_color(_main_color(_wheel_field, String(_look.get(_wheel_field))))
	_built_options = _page_options()
	_update_page()


## Text of all options of the open page (changes when e.g. the race allows other skin tones).
func _page_options() -> String:
	var parts: Array[String] = []
	for field: String in CATEGORIES[_category]["fields"]:
		parts.append(",".join(_options_for(field)))
	return "|".join(parts)


## Titles, selection frames, portraits and the race text of the open page.
func _update_page() -> void:
	if _category < 0:
		return
	if _page_options() != _built_options:
		var scroll: int = _options_scroll.scroll_vertical
		_build_page()
		_options_scroll.set_deferred("scroll_vertical", scroll)
		return
	for field: String in _titles:
		(_titles[field] as Label).text = "%s: %s" % [Language.translate(FIELD_NAMES[field]), _look.get_option_name(field)]
	for slot in _slots:
		var field: String = slot["field"]
		var current: String = String(_look.get(field))
		var custom: bool = slot["value"] == CUSTOM_SLOT
		(slot["frame"] as Control).visible = current == slot["value"] or (custom and Appearance.is_custom_color(current))
		if custom:
			var color: String = current if Appearance.is_custom_color(current) else String(_custom_colors.get(field, ""))
			(slot["icon"] as ColorRect).visible = not color.is_empty()
			if not color.is_empty():
				(slot["icon"] as ColorRect).color = _main_color(field, color)
			(slot["button"] as Button).disabled = field == "clothes_color" and not _clothes_colorable()
		elif PORTRAIT_FIELDS.has(field):
			var look: Appearance = _look.duplicate() as Appearance
			look.set(field, slot["value"])
			look.normalize()
			(slot["icon"] as TextureRect).texture = CharacterBaker.get_portrait(look)
	if _race_label:
		_race_label.text = Language.translate("Als Schmied: %s\nHelden dieser Rasse: %s") % [PlayerStats.get_race_bonus_text(_look.race),
				Appearance.get_race_hero_text(_look.race)]
	if _wheel_title:
		_wheel_title.text = Language.translate("Eigene Farbe: %s") % Language.translate(FIELD_NAMES[_wheel_field])


func _create_slot(field: String, value: String) -> Button:
	var is_color: bool = Appearance.COLOR_FIELDS.has(field)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var side: float = COLOR_SLOT_SIZE if is_color else SLOT_SIZE
	button.custom_minimum_size = Vector2(side, side)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	for state in ["normal", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, _slot_style)
	var hover: StyleBox = _slot_style.duplicate()
	if hover is StyleBoxTexture:
		(hover as StyleBoxTexture).modulate_color = COLOR_HOVER
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(_on_slot_pressed.bind(field, value))
	var icon: Control = null
	if value == CUSTOM_SLOT:
		button.text = "+"
		button.tooltip_text = Language.translate("Eigene Farbe")
		icon = _create_swatch(Color.WHITE)
	elif is_color:
		button.tooltip_text = _option_name(field, value)
		icon = _create_swatch(_main_color(field, value))
	elif PORTRAIT_FIELDS.has(field):
		var portrait := TextureRect.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon = portrait
		button.tooltip_text = _option_name(field, value)
		if field == "race":
			button.tooltip_text += "\n" + Appearance.get_race_hero_text(value)
	else:
		button.text = _option_name(field, value)
		button.custom_minimum_size.x = TEXT_SLOT_WIDTH
	if icon:
		button.add_child(icon)
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _frame_style)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(frame)
	_slots.append({"field": field, "value": value, "button": button, "icon": icon, "frame": frame})
	return button


## Display name of an option of a field (e.g. "Lang" for hair_style "long").
## Choices of a field here: clothes with a price are only sold by the tailor (Tailor), not offered.
func _options_for(field: String) -> Array:
	var options: Array = _look.get_options_for(field)
	if field == "outfit":
		options = options.filter(Tailor.is_starter_outfit)
	return options


func _option_name(field: String, value: String) -> String:
	var look: Appearance = _look.duplicate() as Appearance
	look.set(field, value)
	return look.get_option_name(field)


## false for clothes that keep their colours (appearance.json outfit without "colorable").
func _clothes_colorable() -> bool:
	return _look.get_outfit_data().get("colorable", false)


func _create_swatch(color: Color) -> ColorRect:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	swatch.offset_left = SWATCH_INSET
	swatch.offset_top = SWATCH_INSET
	swatch.offset_right = -SWATCH_INSET
	swatch.offset_bottom = -SWATCH_INSET
	return swatch


## Colour a swatch shows: the main shade (eyes: the iris).
func _main_color(field: String, value: String) -> Color:
	var colors: Array[Color] = Appearance.get_colors(field, value)
	return colors[0] if field == "eye_color" or colors.size() < 2 else colors[1]


func _on_slot_pressed(field: String, value: String) -> void:
	if Appearance.COLOR_FIELDS.has(field) and _wheel:
		_wheel_field = field
	if value == CUSTOM_SLOT:
		var stored: String = String(_custom_colors.get(field, ""))
		if not stored.is_empty():
			_look.set(field, stored)
	else:
		_look.set(field, value)
		_look.normalize()
	if _wheel and Appearance.COLOR_FIELDS.has(field):
		_wheel.set_color(_main_color(field, String(_look.get(field))))
	_refresh()


## An own colour for the field of the wheel; the sheet of the previous own colour is dropped
## (dragging tries many colours).
func _on_wheel_changed(color: Color) -> void:
	if _wheel_field == "clothes_color" and not _clothes_colorable():
		return
	if Appearance.is_custom_color(String(_look.get(_wheel_field))):
		CharacterBaker.forget(_look)
	var value: String = "#" + color.to_html(false)
	_custom_colors[_wheel_field] = value
	_look.set(_wheel_field, value)
	_refresh()


# --- Preview and buttons ------------------------------------------------------------------

func _randomize() -> void:
	_look = Appearance.create_random()
	_refresh()


func _turn(step: int) -> void:
	_direction = posmod(_direction + step, TURN_ORDER.size())
	_update_preview_frame()


func _refresh() -> void:
	_update_category_buttons()
	_update_page()
	_preview_texture.atlas = CharacterBaker.get_sheet(_look)
	_preview.custom_minimum_size = Vector2.ONE * CharacterBaker.FRAME * PREVIEW_ZOOM
	_preview.scale = Vector2.ONE * _look.get_scale()
	_preview.pivot_offset = Vector2(CharacterBaker.FRAME * PREVIEW_ZOOM / 2.0, CharacterBaker.FRAME * PREVIEW_ZOOM)
	_update_preview_frame()


## Walks in place: frames 1-6 of the chosen direction.
func _update_preview_frame() -> void:
	var frame: int = 1 + int(_time * WALK_FPS) % (CharacterBaker.COLUMNS - 1)
	_preview_texture.region = CharacterBaker.get_frame_rect(TURN_ORDER[_direction], frame)


func _on_back_pressed() -> void:
	MainMenu.skip_title_page = true
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU)


func _on_start_pressed() -> void:
	GameState.player_appearance = _look
	var player_name: String = _name_edit.text.strip_edges()
	GameState.player_name = player_name  # "" = the default name in the current language
	GameState.start_new_game()
	get_tree().change_scene_to_file.call_deferred(INTRO)


func _create_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _create_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(18, 0)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(on_pressed)
	return button
