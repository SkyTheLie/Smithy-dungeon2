class_name LexiconWindow
extends PanelContainer
## The lexicon (key L or the book in the side menu): tabs "Monster", "Items" and "Effekte" (all
## status effects, always open: buffs and debuffs with what they do), each a table of slots. Discovered entries show their picture, the others only a dark silhouette (Lexicon:
## monsters once beaten, items once owned). A click on a discovered slot opens its entry
## (LexiconEntryWindow via GameState.open_lexicon), on a silhouette the slot shakes.
## Sorting: monsters by level, name or loot (one block per item they drop), items by kind or name.
## Search field: only discovered entries whose name fits (monsters also by the names of their known
## loot, items also by kind and by the monsters that drop them); the secret ones stay hidden.

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.45)
const FONT_SIZE: int = 11
## Big headers above several groups of the item tab (Waffen, Rüstung).
const SECTION_FONT_SIZE: int = 14
const COLOR_SECTION: Color = Color(1.0, 0.88, 0.6)
const SECTION_INDENT: float = 6.0
const COLUMNS: int = 8
const SLOT_SIZE: Vector2 = Vector2(28, 28)
const ICON_SIZE: Vector2 = Vector2(24, 24)
## Silhouette of what is not discovered yet: the picture in black, a bit see-through.
const COLOR_SILHOUETTE: Color = Color(0.0, 0.0, 0.0, 0.8)
## Shaking of a refused slot: pixels and seconds.
const SHAKE_DISTANCE: float = 3.0
const SHAKE_TIME: float = 0.3

enum Tab { MONSTERS, ITEMS, EFFECTS }
const TAB_NAMES: Array[String] = ["Monster", "Items", "Effekte"]
const MONSTER_SORTS: Array[String] = ["Nach Level", "Nach Name", "Nach Beute"]
const ITEM_SORTS: Array[String] = ["Nach Art", "Nach Name"]
const EFFECT_SORTS: Array[String] = ["Nach Art", "Nach Name"]

@onready var _tab_bar: TabBar = %TabBar
@onready var _sort_button: OptionButton = %SortButton
@onready var _count_label: Label = %CountLabel
@onready var _search: LineEdit = %Search
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %Content

## Chosen sorting per tab.
var _sorts: Array[int] = [0, 0, 0]
## Search text in lower case ("" = show everything).
var _query: String = ""
## Link ("enemy:rat") -> its slots in the table (several when sorted by loot).
var _slots: Dictionary = {}
## Running shake of each slot (a new one replaces it).
var _shakes: Dictionary = {}


func _ready() -> void:
	for tab_name in TAB_NAMES:
		_tab_bar.add_tab(Language.translate(tab_name))
	_tab_bar.tab_changed.connect(func(_index: int) -> void:
		_fill_sort_button()
		_refresh())
	_sort_button.item_selected.connect(func(index: int) -> void:
		_sorts[_tab_bar.current_tab] = index
		_refresh())
	_search.placeholder_text = Language.translate("Suchen …")
	_search.text_changed.connect(func(text: String) -> void:
		_query = text.strip_edges().to_lower()
		_refresh())
	visibility_changed.connect(_refresh)
	GameState.lexicon.changed.connect(_refresh)
	GameState.achievements.changed.connect(_refresh)
	_fill_sort_button()
	_refresh()


## Opens the window at the tab of `link` ("enemy:..." / "item:...") and shakes that slot: used for
## links to things not discovered yet.
func point_at(link: String) -> void:
	if link.begins_with(Lexicon.ITEM + ":"):
		_tab_bar.current_tab = Tab.ITEMS
	elif link.begins_with(Lexicon.EFFECT + ":"):
		_tab_bar.current_tab = Tab.EFFECTS
	else:
		_tab_bar.current_tab = Tab.MONSTERS
	# A search would hide the silhouette.
	_search.text = ""
	_query = ""
	show()
	_refresh()
	var slots: Array = _slots.get(link, [])
	if slots.is_empty():
		return
	var slot: Control = slots[0]
	# Deferred twice: the table gets its size first, then the scroll knows how far to go.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(slot):
		_scroll.ensure_control_visible(slot)
		_shake(slot)


func _fill_sort_button() -> void:
	_sort_button.clear()
	var sorts: Array[String] = [MONSTER_SORTS, ITEM_SORTS, EFFECT_SORTS][_tab_bar.current_tab]
	for text: String in sorts:
		_sort_button.add_item(Language.translate(text))
	_sort_button.select(_sorts[_tab_bar.current_tab])


func _refresh() -> void:
	if not visible:
		return
	_clear(_content)
	_slots.clear()
	_shakes.clear()
	match _tab_bar.current_tab:
		Tab.MONSTERS:
			_show_monsters()
		Tab.ITEMS:
			_show_items()
		Tab.EFFECTS:
			_show_effects()


# --- Monsters ---------------------------------------------------------------------------

func _show_monsters() -> void:
	var enemies: Array[EnemyData] = Lexicon.get_enemies().duplicate()
	var known: int = enemies.filter(GameState.lexicon.is_enemy_known).size()
	_count_label.text = Language.translate("%d / %d besiegt") % [known, enemies.size()]
	if not _query.is_empty():
		enemies.assign(enemies.filter(_enemy_fits_search))
		_count_label.text = Language.translate("%d Treffer") % enemies.size()
		if enemies.is_empty():
			_content.add_child(_make_header(Language.translate("Nichts gefunden")))
			return
	match _sorts[Tab.MONSTERS]:
		0:
			_add_grid(enemies.map(_make_enemy_slot))
		1:
			enemies.sort_custom(func(a: EnemyData, b: EnemyData) -> bool:
				return _sort_name(a.display_name, GameState.lexicon.is_enemy_known(a)) < _sort_name(b.display_name, GameState.lexicon.is_enemy_known(b)))
			_add_grid(enemies.map(_make_enemy_slot))
		2:
			_show_monsters_by_loot(enemies)


## One block per item the monsters drop (in the order of the item tab), with the monsters that
## drop it; monsters without loot at the end.
func _show_monsters_by_loot(enemies: Array[EnemyData]) -> void:
	var by_item: Dictionary = {}
	var without: Array[EnemyData] = []
	for enemy in enemies:
		if enemy.drops.is_empty():
			without.append(enemy)
		for drop: Dictionary in enemy.drops:
			var item: ItemData = drop["item"]
			if not by_item.has(item):
				by_item[item] = []
			if not by_item[item].has(enemy):
				by_item[item].append(enemy)
	var items: Array = by_item.keys()
	var order: Array[ItemData] = Lexicon.get_items()
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool: return order.find(a) < order.find(b))
	for item: ItemData in items:
		var known: bool = GameState.lexicon.is_item_known(item)
		_content.add_child(_make_header(item.display_name if known else "???", item.icon, not known))
		_add_grid(by_item[item].map(_make_enemy_slot))
	if not without.is_empty():
		_content.add_child(_make_header(Language.translate("Ohne Beute")))
		_add_grid(without.map(_make_enemy_slot))


func _make_enemy_slot(enemy: EnemyData) -> Control:
	var known: bool = GameState.lexicon.is_enemy_known(enemy)
	var tooltip: String = Language.translate("%s · Lv %d · %d× besiegt") % [enemy.display_name, enemy.level, GameState.lexicon.get_kills(enemy)] \
			if known else Language.translate("??? · Noch nicht besiegt")
	var slot: Control = _make_slot("%s:%s" % [Lexicon.ENEMY, enemy.id], Lexicon.get_enemy_icon(enemy), known, tooltip)
	# Every monster looks left, as in fights.
	(slot.get_child(0) as TextureRect).flip_h = enemy.faces_right
	return slot


# --- Items ------------------------------------------------------------------------------

func _show_items() -> void:
	var items: Array[ItemData] = Lexicon.get_items().duplicate()
	var known: int = items.filter(GameState.lexicon.is_item_known).size()
	_count_label.text = Language.translate("%d / %d gefunden") % [known, items.size()]
	if not _query.is_empty():
		items.assign(items.filter(_item_fits_search))
		_count_label.text = Language.translate("%d Treffer") % items.size()
		if items.is_empty():
			_content.add_child(_make_header(Language.translate("Nichts gefunden")))
			return
	if _sorts[Tab.ITEMS] == 1:
		items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
			return _sort_name(a.display_name, GameState.lexicon.is_item_known(a)) < _sort_name(b.display_name, GameState.lexicon.is_item_known(b)))
		_add_grid(items.map(_make_item_slot))
		return
	# One block per group (Lexicon.get_item_group); weapon and armour groups under a big header.
	var group: String = ""
	var section: String = ""
	var block: Array = []
	for item in items:
		var item_group: String = Lexicon.get_item_group(item)
		if item_group != group:
			if not block.is_empty():
				_add_grid(block)
			block = []
			group = item_group
			var item_section: String = Lexicon.get_group_section(group)
			if item_section != section:
				section = item_section
				if not section.is_empty():
					_content.add_child(_make_section_header(Language.translate(section)))
			_content.add_child(_make_header(Lexicon.get_group_name(group), null, false, not section.is_empty()))
		block.append(_make_item_slot(item))
	if not block.is_empty():
		_add_grid(block)


func _make_item_slot(item: ItemData) -> Control:
	var known: bool = GameState.lexicon.is_item_known(item)
	var tooltip: String = "%s · %s" % [item.display_name, Lexicon.get_item_category(item)] if known \
			else Language.translate("??? · Noch nicht gefunden")
	return _make_slot("%s:%s" % [Lexicon.ITEM, item.id], item.icon, known, tooltip)


# --- Status effects -----------------------------------------------------------------------

## Every status effect (nothing to discover): buffs, then debuffs, or all by name.
func _show_effects() -> void:
	var effects: Array[StatusEffectData] = EffectInfo.get_all()
	_count_label.text = Language.translate("%d Effekte") % effects.size()
	if not _query.is_empty():
		effects.assign(effects.filter(func(effect: StatusEffectData) -> bool:
			return _fits(effect.display_name) or _fits(effect.description) or _fits(EffectInfo.get_kind_text(effect))))
		_count_label.text = Language.translate("%d Treffer") % effects.size()
		if effects.is_empty():
			_content.add_child(_make_header(Language.translate("Nichts gefunden")))
			return
	if _sorts[Tab.EFFECTS] == 1:
		effects.sort_custom(func(a: StatusEffectData, b: StatusEffectData) -> bool:
			return a.display_name.to_lower() < b.display_name.to_lower())
		_add_grid(effects.map(_make_effect_slot))
		return
	for kind: StatusEffectData.Kind in [StatusEffectData.Kind.BUFF, StatusEffectData.Kind.DEBUFF]:
		var block: Array = effects.filter(func(effect: StatusEffectData) -> bool: return effect.kind == kind)
		if block.is_empty():
			continue
		_content.add_child(_make_header(Language.translate("Stärkungen") if kind == StatusEffectData.Kind.BUFF else Language.translate("Schwächungen")))
		_add_grid(block.map(_make_effect_slot))


func _make_effect_slot(effect: StatusEffectData) -> Control:
	return _make_slot("%s:%s" % [Lexicon.EFFECT, effect.id], effect.icon, true,
			"%s · %s" % [effect.display_name, EffectInfo.get_kind_text(effect)])


# --- Search -----------------------------------------------------------------------------

## A beaten monster whose name, or the name of a known item it drops, contains the search text.
func _enemy_fits_search(enemy: EnemyData) -> bool:
	if not GameState.lexicon.is_enemy_known(enemy):
		return false
	if _fits(enemy.display_name):
		return true
	for drop: Dictionary in enemy.drops:
		var item: ItemData = drop["item"]
		if GameState.lexicon.is_item_known(item) and _fits(item.display_name):
			return true
	return false


## A found item whose name or kind, or the name of a beaten monster that drops it, contains the
## search text.
func _item_fits_search(item: ItemData) -> bool:
	if not GameState.lexicon.is_item_known(item):
		return false
	if _fits(item.display_name) or _fits(Lexicon.get_item_category(item)):
		return true
	return Lexicon.get_droppers(item).any(func(enemy: EnemyData) -> bool:
		return GameState.lexicon.is_enemy_known(enemy) and _fits(enemy.display_name))


func _fits(text: String) -> bool:
	return text.to_lower().contains(_query)


## Undiscovered entries go to the end when sorted by name (their name is a secret).
static func _sort_name(display_name: String, known: bool) -> String:
	return ("0" if known else "1") + display_name.to_lower()


# --- Building blocks --------------------------------------------------------------------------

func _add_grid(slots: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	for slot: Control in slots:
		grid.add_child(slot)
	_content.add_child(grid)


func _make_slot(link: String, icon: Texture2D, known: bool, tooltip: String) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.theme_type_variation = &"ItemSlot"
	slot.tooltip_text = tooltip
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if known else Control.CURSOR_ARROW
	var picture := TextureRect.new()
	# Ignore the texture size first: else the size below is held at the (big) frame size.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = icon
	picture.position = (SLOT_SIZE - ICON_SIZE) / 2.0
	picture.size = ICON_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not known:
		picture.modulate = COLOR_SILHOUETTE
	slot.add_child(picture)
	slot.gui_input.connect(_on_slot_input.bind(slot, link, known))
	if not _slots.has(link):
		_slots[link] = []
	_slots[link].append(slot)
	return slot


func _on_slot_input(event: InputEvent, slot: Control, link: String, known: bool) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	slot.accept_event()
	if known:
		AudioManager.play_sound("ui_click")
		GameState.open_lexicon(link)
	else:
		_shake(slot)


## Left-right shake of a slot: "not discovered yet". The picture inside moves, so the table stays.
func _shake(slot: Control) -> void:
	AudioManager.play_sound("ui_click", 0.6)
	var picture: Control = slot.get_child(0)
	var start: Vector2 = (SLOT_SIZE - ICON_SIZE) / 2.0
	if _shakes.has(slot) and (_shakes[slot] as Tween).is_valid():
		(_shakes[slot] as Tween).kill()
	var tween := slot.create_tween()
	_shakes[slot] = tween
	var step: float = SHAKE_TIME / 6.0
	for offset: float in [SHAKE_DISTANCE, -SHAKE_DISTANCE, SHAKE_DISTANCE * 0.66, -SHAKE_DISTANCE * 0.66, SHAKE_DISTANCE * 0.33]:
		tween.tween_property(picture, "position:x", start.x + offset, step)
	tween.tween_property(picture, "position:x", start.x, step)
	# The frame flashes red for a moment.
	slot.modulate = Color(1.0, 0.55, 0.5)
	tween.parallel().tween_property(slot, "modulate", Color.WHITE, SHAKE_TIME)


## Big header above several groups ("Waffen", "Rüstung"): larger, with a line below.
func _make_section_header(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_SECTION)
	box.add_child(label)
	var line := ColorRect.new()
	line.color = COLOR_SECTION.darkened(0.4)
	line.custom_minimum_size = Vector2(0, 1)
	box.add_child(line)
	return box


## `indented`: a group under a section header (a bit to the right).
func _make_header(text: String, icon: Texture2D = null, silhouette: bool = false, indented: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	if indented:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(SECTION_INDENT, 0)
		row.add_child(gap)
	if icon:
		var picture := TextureRect.new()
		picture.texture = icon
		picture.custom_minimum_size = Vector2(12, 12)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if silhouette:
			picture.modulate = COLOR_SILHOUETTE
		row.add_child(picture)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_HEADER)
	row.add_child(label)
	return row


## Removes all children right away (queue_free alone would keep them until the end of the frame).
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
