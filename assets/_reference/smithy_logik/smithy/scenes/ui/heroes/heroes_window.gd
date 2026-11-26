class_name HeroesWindow
extends PanelContainer
## List of the hired heroes: one row per hero with two lines next to the portrait:
## [name ............ Lv 40]
## [class (in class color)  stamina bar] (or "unterwegs" while the hero is on an adventure).
## Clicking a row emits hero_selected (the HUD then opens the hero window).
## The title bar shows hired heroes / hero places (GameState.get_max_heroes), e.g. "1/2".

signal hero_selected(hero: Hero)

const PORTRAIT_SIZE: Vector2 = Vector2(24, 24)
const FONT_SIZE: int = 11
const COLOR_BUSY: Color = Color(0.62, 0.6, 0.56)
## Size of the small stamina bar in a row.
const STAMINA_BAR_SIZE: Vector2 = Vector2(36, 3)
## Space between the button frame and the row (left, top, right, bottom); the bottom edge of the
## button graphic is thicker.
const ROW_MARGIN: Vector4 = Vector4(4, 3, 4, 4)
## A label is 16 px high but the letters only fill about 8 of it: pull the class line up to the name.
const LINE_SEPARATION: int = -7

## Heroes whose "changed" already rebuilds the list (renamed, level up, stamina ...).
var _watched: Array[Hero] = []
var _rebuild_queued: bool = false

@onready var _list: VBoxContainer = %HeroList
@onready var _empty_label: Label = %EmptyLabel
@onready var _title_bar: WindowTitleBar = $VBox/TitleBar


func _ready() -> void:
	GameState.heroes_changed.connect(_rebuild)
	GameState.adventure_started.connect(_rebuild.unbind(1))
	GameState.adventure_finished.connect(_rebuild.unbind(1))
	GameState.story.changed.connect(_update_count)
	GameState.player_stats.stats_changed.connect(_update_count)
	_rebuild()


func _rebuild() -> void:
	_rebuild_queued = false
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_empty_label.visible = GameState.heroes.is_empty()
	for hero in GameState.heroes:
		_list.add_child(_create_row(hero))
		if hero not in _watched:
			_watched.append(hero)
			hero.changed.connect(_queue_rebuild)
	_update_count()


## A hero changed: rebuild once at the end of the frame (equipping fires "changed" several times).
func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


func _update_count() -> void:
	_title_bar.info = "%d/%d" % [GameState.heroes.size(), GameState.get_max_heroes()]


func _create_row(hero: Hero) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, PORTRAIT_SIZE.y + 4)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = Language.translate("%s · %s · Ausdauer %d/%d") % [hero.display_name, hero.hero_class.display_name,
			floori(hero.stamina), roundi(Hero.get_max_stamina())]
	var league: int = TournamentRanking.league_index(hero.best_league)
	if league >= 0:
		button.tooltip_text += "
" + Language.translate("Höchster Turniersieg: %s") % TournamentRanking.league_name(league)
	button.pressed.connect(func() -> void: hero_selected.emit(hero))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_MARGIN.x
	row.offset_top = ROW_MARGIN.y
	row.offset_right = -ROW_MARGIN.x
	row.offset_bottom = -ROW_MARGIN.w
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	var portrait := TextureRect.new()
	portrait.texture = hero.get_portrait()
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", LINE_SEPARATION)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lines)
	var top := _create_line()
	lines.add_child(top)
	var name_label := _create_label(hero.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(name_label)
	# Badge of the highest league the hero has won, left of the level (none before his first league victory).
	var badge_texture: Texture2D = TournamentRanking.league_badge(hero.best_league)
	if badge_texture:
		var badge := TextureRect.new()
		badge.name = "LeagueBadge"
		badge.texture = badge_texture
		badge.custom_minimum_size = Vector2(TournamentRanking.BADGE_SIZE, TournamentRanking.BADGE_SIZE)
		badge.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(badge)
	top.add_child(_create_label(Language.translate("Lv %d") % hero.level))
	var bottom := _create_line()
	lines.add_child(bottom)
	var class_label := _create_label(hero.hero_class.display_name)
	class_label.add_theme_color_override("font_color", hero.hero_class.color)
	class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(class_label)
	if GameState.is_hero_busy(hero):
		var busy_label := _create_label(Language.translate("unterwegs"))
		busy_label.add_theme_color_override("font_color", COLOR_BUSY)
		bottom.add_child(busy_label)
	else:
		var stamina := ProgressBar.new()
		stamina.custom_minimum_size = STAMINA_BAR_SIZE
		stamina.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stamina.max_value = 1.0
		stamina.step = 0.0
		stamina.show_percentage = false
		stamina.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HeroWindow.style_bar(stamina, HeroWindow.COLOR_STAMINA_HIGH)
		HeroWindow.show_stamina(stamina, hero)
		bottom.add_child(stamina)
	button.add_child(row)
	# The button does not grow with its child: make it as high as the row plus the frame.
	# (The row only knows its size once it is in the tree and has its font.)
	var fit_height := func() -> void:
		button.custom_minimum_size.y = row.get_combined_minimum_size().y + ROW_MARGIN.y + ROW_MARGIN.w
	row.minimum_size_changed.connect(fit_height)
	row.ready.connect(fit_height)
	return button


func _create_line() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _create_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
