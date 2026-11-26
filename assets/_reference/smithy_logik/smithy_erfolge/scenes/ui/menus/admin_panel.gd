class_name AdminPanel
extends StationMenu
## Admin panel (key P, opened by the HUD): every item of the game to take out without limit.
## Click = a full stack, Ctrl + click = 1 piece, Shift + click = 10 pieces.
## Weapons and armor are offered ready-made, once per material of their main part (e.g. copper
## sword, iron sword); their other parts use the same material if there is one.
## The window can be made bigger at its bottom right corner (ResizeGrip), the item grid then
## gets more columns.

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/item_slot.tscn")
## Columns of the item grid until the window has its size (then as many as fit, _update_columns).
const COLUMNS: int = 14
## Width of one item slot in the grid (item_slot.tscn).
const SLOT_WIDTH: float = 28.0
const HINT: String = "Klick = Stapel, Strg = 1, Umschalt = 10"
const CATEGORY_ALL: String = "Alle"
## Category name -> item types in it (everything else lands in "Sonstiges").
const CATEGORIES: Dictionary = {
	"Rohstoffe": [ItemData.ItemType.MATERIAL, ItemData.ItemType.FUEL, ItemData.ItemType.ORE, ItemData.ItemType.INGOT],
	"Teile": [ItemData.ItemType.PART],
	"Waffen": [ItemData.ItemType.WEAPON, ItemData.ItemType.SHIELD],
	"Rüstung": [ItemData.ItemType.ARMOR, ItemData.ItemType.HELMET, ItemData.ItemType.BOOTS,
		ItemData.ItemType.SHOULDERS, ItemData.ItemType.CLOAK, ItemData.ItemType.LEGS, ItemData.ItemType.GLOVES],
	"Werkzeug & Schmuck": [ItemData.ItemType.PICKAXE, ItemData.ItemType.LUMBER_AXE, ItemData.ItemType.BACKPACK, ItemData.ItemType.SHOES,
		ItemData.ItemType.WATERING_CAN, ItemData.ItemType.ACCESSORY, ItemData.ItemType.NECKLACE, ItemData.ItemType.RING],
}
const CATEGORY_OTHER: String = "Sonstiges"
const TAB_ITEMS: int = 0
const TAB_EVENTS: int = 1
const TAB_HOUSE: int = 2
const TAB_CHAPTERS: int = 3
const TAB_QUESTS: int = 4
const TAB_MAPS: int = 5
const TAB_SMITHY: int = 6
const TAB_SOUNDS: int = 7
const TAB_TIME: int = 8
const TIME_HINT: String = "Stellt die Uhr. Festhalten gilt auch nach einem Neustart."
## Hours of the clock buttons (24 = midnight, 25 = 1 at night; the day ends at 2).
const TIME_HOURS: Array[int] = [6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 25]
const SOUNDS_HINT: String = "Klick spielt ab, Zahlen = Varianten. Hintergrund/Musik: nochmal klicken = Szene."
## German names of the sound ids for the sound tab (unknown ids show the id).
const SOUND_NAMES: Dictionary = {
	"anvil_perfect": "Amboss perfekt", "anvil_good": "Amboss gut", "anvil_miss": "Amboss daneben",
	"skill_used": "Skill", "level_up": "Level-Up", "item_reveal": "Fertiges Stück", "rarity_up": "Seltenheit steigt",
	"quench_hiss": "Wassertrog", "ingot_ready": "Schmelze fertig", "cast_pour": "Gießen (Esse)",
	"pickaxe_hit": "Spitzhacke", "axe_hit": "Axt", "rock_break": "Stein zerbricht", "wood_break": "Baum fällt",
	"plant_pick": "Pflanze pflücken", "door": "Tür", "step": "Schritt", "coins": "Münzen", "ui_click": "Klick",
	"window_open": "Fenster auf", "window_close": "Fenster zu", "chest_open": "Loot-Kiste", "achievement": "Erfolg",
	"forest": "Wald", "village": "Dorf", "village_night": "Dorf nachts", "forge": "Schmiedefeuer",
	"cave": "Höhle", "lava": "Lava", "default": "Dorf (Standard)", "raid": "Überfall",
}
const SMITHY_HINT: String = "Klick schaltet frei oder wieder ab. Die Szene lädt neu."
## Workshop unlocks besides the bought stations (economy.json "stations"): name -> story flags.
const SMITHY_UNLOCKS: Dictionary = {
	"Spinnweben weg (Esse, Amboss, Schmelze, Werkbank)": ["cobweb_forge", "cobweb_anvil", "cobweb_smelter", "cobweb_workbench"],
	"Mörser (Zauberbuch)": [Enchanting.BOOK_FLAG],
	"Auftragsbrett": ["order_board_unlocked"],
	"Erster Dungeon (Loot-Kiste, Bogentisch)": ["loot_chest_unlocked"],
	"Stammkunden": ["regular_customers"],
	"Ninas Laden": ["nina_shop_unlocked"],
}
const CHAPTERS_HINT: String = "Springt an den Anfang des Kapitels."
const QUESTS_HINT: String = "Springt an den Schritt, alles davor gilt als gespielt."
const MAPS_HINT: String = "Teleportiert dich auf die Karte."
## Maps are found by themselves: every scene below this folder that contains the player.
## New maps show up without changes here; MAP_AREAS and data/content/map_names.json only give them nicer names.
const MAPS_ROOT: String = "res://scenes/world"
const PLAYER_SCENE: String = "res://scenes/actors/player.tscn"
## Template of new maps (they inherit from it, so their file names it instead of PLAYER_SCENE).
const MAP_BASE_SCENE: String = "res://scenes/world/_template/map_base.tscn"
## Maps that are templates of other maps themselves (the tournament halls of the cities inherit it).
const MAP_TEMPLATES: Array[String] = ["res://scenes/world/tournament/tournament_hall.tscn"]
## Folders below MAPS_ROOT that hold no maps.
const MAP_SKIP_FOLDERS: Array[String] = ["objects", "_template"]
## Folder -> area name, in this order (unknown folders follow, sorted).
const MAP_AREAS: Dictionary = {
	"village": "Dorf", "smithy": "Schmiede", "market": "Markt", "forest": "Wald", "mine": "Mine", "capital": "Leonheim",
	"volcano": "Lavaberg", "tournament": "Turnierhallen",
}
## Scene file name -> map name (unknown ones use the file name, e.g. "new_cave" » "New Cave").
const EVENTS_HINT: String = "Startet ein Story-Ereignis von vorn."
const HOUSE_HINT: String = "Kostenlos, ohne Ruf. Die Szene lädt neu."
const GREENHOUSE_PAID_FLAG: String = "greenhouse_paid"
const GREENHOUSE_FLAG: String = "greenhouse_built"
## Raid (chapter 10, the lich at the tree of life): flags it sets, taken back so it can be played
## again; the "reached_<step>" flags of its steps are taken back too.
const RAID_FLAGS: Array[String] = ["raid_started", "raid_woken", "raid_yard_seen", "raid_heroes", "bruno_follows",
	"emma_follows", "raid_spared", "tree_drain_start", "tree_withered", "raid_over", "raid_watch_done", "hilde_dead", "bruno_dead"]
const RAID_STEPS: Array[String] = ["raid_wake", "raid_outside", "raid_bruno", "raid_to_market", "raid_market",
	"raid_rescue", "raid_flee", "raid_ambush", "raid_home", "raid_robbed", "raid_night", "raid_morning", "chapter10_end"]
const RAID_START_SCENE: String = "res://scenes/world/smithy/bedroom.tscn"
const RAID_START_SPAWN: StringName = &"InBed"
const TOURNAMENT_SCENE: String = "res://scenes/world/capital/tournament_arena.tscn"
const KING_RIDE_ACTION: String = "set_flag:left_for_capital;advance:castle_arrival;travel_fade:res://scenes/world/capital/castle_garden.tscn,FromCarriage"

## One template stack (amount 1) per offered item, in ContentDB order.
var _entries: Array[InventorySlot] = []
## Entries shown with the current search and category, same order as the slots in the grid.
var _shown: Array[InventorySlot] = []

@onready var _grid: GridContainer = %Grid
@onready var _item_scroll: ScrollContainer = %Scroll
@onready var _search: LineEdit = %Search
@onready var _category: OptionButton = %Category
## What the next taken items get: rarity (index 0 = "Standard", the item's own) and quality 0-100.
@onready var _rarity_pick: OptionButton = %RarityPick
@onready var _quality_pick: SpinBox = %QualityPick
@onready var _status_label: Label = %StatusLabel
@onready var _tab_bar: TabBar = %TabBar
@onready var _items_page: Control = %ItemsPage
@onready var _events_page: Control = %EventsPage
@onready var _raid_button: Button = %RaidButton
@onready var _king_button: Button = %KingButton
@onready var _house_page: Control = %HousePage
@onready var _house_info: Label = %HouseInfo
@onready var _house_buttons: VBoxContainer = %HouseButtons
@onready var _greenhouse_button: Button = %GreenhouseButton
@onready var _chapters_page: Control = %ChaptersPage
@onready var _chapter_info: Label = %ChapterInfo
@onready var _chapter_buttons: VBoxContainer = %ChapterButtons
@onready var _maps_page: Control = %MapsPage
@onready var _map_info: Label = %MapInfo
@onready var _map_buttons: VBoxContainer = %MapButtons
## Tab "Schmiede" (built in code, _build_smithy_page): one toggle per station / unlock.
var _smithy_page: ScrollContainer
## Tab "Quests" (built in code, _build_quests_page): jump to every single story step (QuestJump).
var _quests_page: VBoxContainer
var _quest_info: Label
var _quest_buttons: VBoxContainer
var _quest_travel: CheckBox
var _quest_items: CheckBox
var _smithy_buttons: VBoxContainer
## Tab "Geräusche" (built in code, _build_sounds_page): listen to every sound, loop and piece.
var _sounds_page: ScrollContainer
## Tab "Zeit" (built in code, _build_time_page): set the clock, hold it.
var _time_page: VBoxContainer
var _time_info: Label
var _time_hold: CheckBox
## Buttons of the background loops and music pieces (to mark the playing one).
var _ambience_buttons: Array[Button] = []
var _music_buttons: Array[Button] = []


func _ready() -> void:
	super()
	freezes_player = false
	closes_on_interact = false
	layer = 20
	_tab_bar.add_tab(Language.translate("Items"))
	_tab_bar.add_tab(Language.translate("Events"))
	_tab_bar.add_tab(Language.translate("Haus"))
	_tab_bar.add_tab(Language.translate("Kapitel"))
	_tab_bar.add_tab(Language.translate("Quests"))
	_tab_bar.add_tab(Language.translate("Karten"))
	_tab_bar.add_tab(Language.translate("Schmiede"))
	_tab_bar.add_tab(Language.translate("Geräusche"))
	_tab_bar.add_tab(Language.translate("Zeit"))
	_build_quests_page()
	_build_smithy_page()
	_build_sounds_page()
	_build_time_page()
	# The panel opens on the tab it was left on (also after a restart).
	_tab_bar.current_tab = clampi(int(WindowLayout.get_setting(GameState.ADMIN_SECTION, "tab", TAB_ITEMS)), 0, _tab_bar.tab_count - 1)
	_tab_bar.tab_changed.connect(func(tab: int) -> void:
		WindowLayout.set_setting(GameState.ADMIN_SECTION, "tab", tab)
		_show_tab())
	_raid_button.pressed.connect(_start_raid)
	_king_button.pressed.connect(_ride_to_king)
	_build_tournament_events()
	for level in range(1, House.MAX_LEVEL + 1):
		var button := Button.new()
		button.text = Language.translate("Stufe %d – %s") % [level, House.get_level_data(level).get("name", "")]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_set_house_level.bind(level))
		_house_buttons.add_child(button)
	_greenhouse_button.pressed.connect(_build_greenhouse)
	for chapter: Array in StorySkip.CHAPTERS:
		var button := Button.new()
		button.text = chapter[0]
		button.tooltip_text = chapter[0]
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_play_chapter.bind(chapter[1]))
		_chapter_buttons.add_child(button)
	_build_map_buttons()
	_grid.columns = COLUMNS
	_item_scroll.resized.connect(_update_columns)
	_category.add_item(CATEGORY_ALL)
	for category_name: String in CATEGORIES:
		_category.add_item(category_name)
	_category.add_item(CATEGORY_OTHER)
	_search.text_changed.connect(func(_text: String) -> void: _rebuild())
	_category.item_selected.connect(func(_index: int) -> void: _rebuild())
	_rarity_pick.add_item(Language.translate("Standard"))
	for tier: int in Rarity.Tier.values():
		_rarity_pick.add_item(Rarity.get_display_name(tier as Rarity.Tier))
	_quality_pick.min_value = 0
	_quality_pick.max_value = 100
	_quality_pick.step = 1
	visibility_changed.connect(_on_visibility_changed)
	_entries = _collect_entries()
	_rebuild()


func _on_visibility_changed() -> void:
	_show_tab()
	if not visible:
		_search.release_focus()


func _show_tab() -> void:
	var tab: int = _tab_bar.current_tab
	_items_page.visible = tab == TAB_ITEMS
	_events_page.visible = tab == TAB_EVENTS
	_house_page.visible = tab == TAB_HOUSE
	_chapters_page.visible = tab == TAB_CHAPTERS
	_quests_page.visible = tab == TAB_QUESTS
	_maps_page.visible = tab == TAB_MAPS
	_smithy_page.visible = tab == TAB_SMITHY
	_sounds_page.visible = tab == TAB_SOUNDS
	_time_page.visible = tab == TAB_TIME
	_status_label.text = {TAB_EVENTS: EVENTS_HINT, TAB_HOUSE: HOUSE_HINT, TAB_CHAPTERS: CHAPTERS_HINT,
		TAB_QUESTS: QUESTS_HINT, TAB_MAPS: MAPS_HINT, TAB_SMITHY: SMITHY_HINT, TAB_SOUNDS: SOUNDS_HINT, TAB_TIME: TIME_HINT}.get(tab, HINT)
	if tab != TAB_ITEMS:
		_search.release_focus()
	if tab == TAB_HOUSE:
		_refresh_house()
	if tab == TAB_CHAPTERS:
		var current: String = StorySkip.chapter_of(GameState.story.step)
		_chapter_info.text = Language.translate("Jetzt: %s") % (current if not current.is_empty() else Language.translate("Story beendet"))
	if tab == TAB_QUESTS:
		_refresh_quests()
	if tab == TAB_MAPS:
		_refresh_maps()
	if tab == TAB_SMITHY:
		_refresh_smithy()
	if tab == TAB_SOUNDS:
		_refresh_sounds()
	if tab == TAB_TIME:
		_refresh_time()


## One heading per area, below it a button per map of that area (find_maps).
func _build_map_buttons() -> void:
	var area: String = ""
	for map: Dictionary in find_maps():
		if map.area != area:
			area = map.area
			var heading := Label.new()
			heading.text = area
			_map_buttons.add_child(heading)
		var button := Button.new()
		button.text = map.name
		button.tooltip_text = map.path
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.set_meta(&"map_path", map.path)
		button.pressed.connect(_teleport_to_map.bind(map.path, map.name))
		_map_buttons.add_child(button)


## Shows the current map and turns its button off.
func _refresh_maps() -> void:
	var scene: Node = get_tree().current_scene
	var current_path: String = scene.scene_file_path if scene else ""
	_map_info.text = Language.translate("Jetzt: %s") % map_name(current_path) if not current_path.is_empty() else ""
	for child in _map_buttons.get_children():
		if child is Button:
			(child as Button).disabled = child.get_meta(&"map_path") == current_path


## Puts the player on the map at its normal start position (where the player node stands in the scene).
## Started from the introduction, the clock runs from then on (like the other admin jumps).
func _teleport_to_map(path: String, display_name: String) -> void:
	_release_clock()
	GameState.next_player_position = Vector2.INF
	GameState.pending_message = Language.translate("Admin: Teleport nach %s.") % display_name
	close()
	GameState.travel_to(path, &"")


## Every map below MAPS_ROOT as {path, name, area}, sorted by area (MAP_AREAS order) and name.
static func find_maps() -> Array[Dictionary]:
	var maps: Array[Dictionary] = []
	_collect_maps(MAPS_ROOT, maps)
	maps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.area == b.area:
			return a.name.naturalnocasecmp_to(b.name) < 0
		if _area_rank(a.area) != _area_rank(b.area):
			return _area_rank(a.area) < _area_rank(b.area)
		return a.area.naturalnocasecmp_to(b.area) < 0)
	return maps


## Position of the area in MAP_AREAS; unknown areas come after all known ones.
static func _area_rank(area: String) -> int:
	var index: int = MAP_AREAS.values().find(area)
	return index if index != -1 else MAP_AREAS.size()


static func _collect_maps(folder: String, maps: Array[Dictionary]) -> void:
	for sub_folder in DirAccess.get_directories_at(folder):
		if folder != MAPS_ROOT or not sub_folder in MAP_SKIP_FOLDERS:
			_collect_maps(folder.path_join(sub_folder), maps)
	for file in DirAccess.get_files_at(folder):
		# Exported games list "x.tscn.remap" instead of "x.tscn".
		var file_name: String = file.trim_suffix(".remap")
		if file_name.get_extension() != "tscn":
			continue
		var path: String = folder.path_join(file_name)
		var text: String = FileAccess.get_file_as_string(path)
		if not (PLAYER_SCENE in text or MAP_BASE_SCENE in text or MAP_TEMPLATES.any(func(template: String) -> bool: return template in text)):
			continue
		if path in MAP_TEMPLATES:
			continue
		var area_folder: String = folder.trim_prefix(MAPS_ROOT + "/").get_slice("/", 0)
		maps.append({"path": path, "name": map_name(path), "area": MAP_AREAS.get(area_folder, area_folder.capitalize())})


## Map name from map_names.json (ContentDB.map_name), otherwise from the file name.
static func map_name(path: String) -> String:
	var name: String = ContentDB.map_name(path)
	return name if not name.is_empty() else path.get_file().get_basename().capitalize()


## Jumps to the start of a chapter (StorySkip). Chapter 1 begins on the village square, every
## other one in the bed of the smithy.
func _play_chapter(first_step: String) -> void:
	StorySkip.jump_to(first_step)
	GameState.pending_message = Language.translate("Admin: %s") % StorySkip.chapter_of(first_step)
	close()
	if first_step == StorySkip.CHAPTERS[0][1]:
		var start: Dictionary = Story.get_data("start")
		GameState.travel_to(str(start.get("scene", "")), StringName(str(start.get("spawn", ""))))
	else:
		GameState.travel_to(RAID_START_SCENE, RAID_START_SPAWN)


## Like the builder's test row: the current level, a button for every level (current one off).
func _refresh_house() -> void:
	var house: House = GameState.house
	_house_info.text = Language.translate("Dein Haus: Stufe %d – %s") % [house.level, house.get_level_name()]
	for index in _house_buttons.get_child_count():
		(_house_buttons.get_child(index) as Button).disabled = index + 1 == house.level
	var built: bool = GameState.story.has_flag(GREENHOUSE_FLAG)
	_greenhouse_button.disabled = built
	_greenhouse_button.text = Language.translate("Gewächshaus steht schon") if built else Language.translate("Gewächshaus bauen")


## Sets the house level for free (House.set_level) and reloads the scene so the rooms match;
## the player stays where they are.
func _set_house_level(level: int) -> void:
	GameState.house.set_level(level)
	GameState.pending_message = Language.translate("Admin: Haus auf Stufe %d gesetzt (%s).") % [level, GameState.house.get_level_name()]
	_reload_scene()


## Builds the greenhouse right away, for free (the builder needs 20 wooden beams, 20 glass, 500 gold
## and one night); finishes the side task "greenhouse".
func _build_greenhouse() -> void:
	GameState.story.set_flag(GREENHOUSE_PAID_FLAG)
	GameState.story.set_flag(GREENHOUSE_FLAG)
	GameState.pending_message = Language.translate("Admin: Gewächshaus gebaut (links neben der Schmiede).")
	_reload_scene()


## Reloads the current scene (buildings and rooms follow flags and house level); the player stays
## where they are.
func _reload_scene() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player:
		GameState.next_player_position = player.global_position
	close()
	var scene: Node = get_tree().current_scene
	if scene:
		GameState.travel_to(scene.scene_file_path, &"")


## Starts the raid (chapter 10) from the beginning: raid flags back, Bruno back in the party if he
## died in an earlier raid, step "raid_wake" (sets the night time), player wakes up in the bed.
func _start_raid() -> void:
	var flags: Array = RAID_FLAGS.duplicate()
	for step_id in RAID_STEPS:
		flags.append("reached_" + step_id)
	if GameState.story.has_flag("bruno_dead"):
		GameState.run_story_action("hire_hero:bruno")
	GameState.story.clear_flags(flags)
	_release_clock()
	GameState.story.advance("raid_wake")
	GameState.travel_to(RAID_START_SCENE, RAID_START_SPAWN)
	close()


## Skips to the king (Part 2, chapter 3): the village carriage ride to the castle garden, like the
## coachman's choice "Nach Leonheim, zum König." (story.json "coachman_to_king"); the audience follows there.
func _ride_to_king() -> void:
	_release_clock()
	GameState.story.advance("royal_carriage")
	GameState.run_story_action(KING_RIDE_ACTION)
	close()


## Tab "Events", below the raid and the king: test tools for the smith tournament (SmithTournament).
func _build_tournament_events() -> void:
	var info := Label.new()
	info.text = Language.translate("Schmiedeturnier (Teil 3): Turnierplatz in Leonheim, Ende der Schmiedegasse. Beim Herold antreten.")
	info.custom_minimum_size = Vector2(236, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_events_page.add_child(info)
	var buttons: Array = [
		[Language.translate("Zum Turnierplatz"), Language.translate("Öffnet den Turnierplatz und bringt dich hin."), _go_to_tournament],
		[Language.translate("Runde gewinnen"), Language.translate("Während einer Runde: ein fertiges Stück der Aufgabe (Selten) ins Inventar, dann beim Herold abgeben."), _win_tournament_round],
		[Language.translate("Monatssperre aufheben"), Language.translate("Das Monatsturnier kann heute noch einmal starten (mit Startgeld)."), _reset_tournament_month],
		[Language.translate("Wie beim ersten Mal"), Language.translate("Kostenlos und beliebig oft, der erste Sieg gibt wieder die Meisterhandschuhe."), _reset_tournament_first_win],
	]
	for entry: Array in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.tooltip_text = entry[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[2])
		_events_page.add_child(button)


func _go_to_tournament() -> void:
	_release_clock()
	GameState.story.set_flag(str(SmithTournament.settings().get("open_flag", "tournament_open")))
	GameState.pending_message = Language.translate("Admin: Turnierplatz")
	close()
	GameState.travel_to(TOURNAMENT_SCENE, &"FromSmithLane")


func _win_tournament_round() -> void:
	var tournament: SmithTournament = GameState.tournament
	if tournament.state != SmithTournament.State.RUNNING:
		_status_label.text = Language.translate("Admin: Erst beim Herold eine Runde beginnen.")
		return
	var piece: InventorySlot = ContentDB.make_stack(tournament.get_wanted_spec())
	ForgeQuality.set_total(piece, Rarity.Tier.RARE * ForgeQuality.POINTS_PER_TIER + 50)
	GameState.inventory.add_stack(piece)
	_status_label.text = Language.translate("Admin: %s im Inventar, beim Herold abgeben.") % tournament.get_task_name()


func _reset_tournament_month() -> void:
	GameState.tournament.last_month = -1
	GameState.tournament.venue_months.clear()
	_status_label.text = Language.translate("Admin: Das Monatsturnier kann wieder starten.")


func _reset_tournament_first_win() -> void:
	GameState.tournament.last_month = -1
	GameState.story.clear_flags([SmithTournament.WON_FLAG])
	_status_label.text = Language.translate("Admin: Turnier wie beim ersten Mal (kostenlos, mit Handschuhen).")


## Tab "Schmiede": the stations to buy (economy.json "stations", with their price and conditions as
## tooltip), the other workshop unlocks (SMITHY_UNLOCKS) and a button for all molds and recipes.
func _build_smithy_page() -> void:
	_smithy_page = ScrollContainer.new()
	_smithy_page.name = Language.translate("SmithyPage")
	_smithy_page.visible = false
	_smithy_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_smithy_page.custom_minimum_size = Vector2(236, 0)
	_smithy_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_smithy_buttons = VBoxContainer.new()
	_smithy_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_smithy_buttons.add_theme_constant_override("separation", 2)
	_smithy_page.add_child(_smithy_buttons)
	_add_page(_smithy_page)
	_smithy_buttons.add_child(_heading(Language.translate("Stationen")))
	var stations: Dictionary = ContentDB.economy("stations")
	for station_id: String in stations:
		var info: Dictionary = stations[station_id]
		var tooltip: String = Language.translate("%d Gold") % int(info.get("price", 0))
		if info.has("house_level"):
			tooltip += Language.translate(", ab Hausstufe %d") % int(info["house_level"])
		if info.has("unlock_flag"):
			tooltip += Language.translate(", im Laden ab „%s“") % info["unlock_flag"]
		_add_smithy_toggle(str(info.get("name", station_id)), [str(info.get("flag", ""))], tooltip)
	_smithy_buttons.add_child(_heading(Language.translate("Werkstatt")))
	for unlock_name: String in SMITHY_UNLOCKS:
		_add_smithy_toggle(unlock_name, SMITHY_UNLOCKS[unlock_name], ", ".join(SMITHY_UNLOCKS[unlock_name]))
	var recipes := Button.new()
	recipes.name = "AllRecipes"
	recipes.focus_mode = Control.FOCUS_NONE
	recipes.alignment = HORIZONTAL_ALIGNMENT_LEFT
	recipes.pressed.connect(_unlock_all_recipes)
	_smithy_buttons.add_child(recipes)
	var dungeons := Button.new()
	dungeons.name = "AllDungeons"
	dungeons.focus_mode = Control.FOCUS_NONE
	dungeons.alignment = HORIZONTAL_ALIGNMENT_LEFT
	dungeons.tooltip_text = Language.translate("Das Dungeon-Brett zeigt jeden Dungeon, egal wie weit die Story ist. Nochmal klicken: wieder nach Story.")
	dungeons.pressed.connect(_toggle_all_dungeons)
	_smithy_buttons.add_child(dungeons)


# --- Time ---------------------------------------------------------------------------

## Day and clock, a button per hour (TIME_HOURS) and "Uhrzeit festhalten".
func _build_time_page() -> void:
	_time_page = VBoxContainer.new()
	_time_page.name = "TimePage"
	_time_page.visible = false
	_time_page.custom_minimum_size = Vector2(236, 0)
	_time_page.add_theme_constant_override("separation", 4)
	_add_page(_time_page)
	_time_info = Label.new()
	_time_page.add_child(_time_info)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_time_page.add_child(grid)
	for hour in TIME_HOURS:
		var button := Button.new()
		button.text = "%02d:00" % (hour % 24)
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(56, 0)
		button.pressed.connect(_set_time.bind(hour))
		grid.add_child(button)
	_time_hold = CheckBox.new()
	_time_hold.text = Language.translate("Uhrzeit festhalten")
	_time_hold.tooltip_text = Language.translate("Die Uhr bleibt stehen, bis du das Häkchen wieder entfernst.")
	_time_hold.focus_mode = Control.FOCUS_NONE
	_time_hold.toggled.connect(_hold_time)
	_time_page.add_child(_time_hold)


func _refresh_time() -> void:
	_time_info.text = Language.translate("Tag %d, %s Uhr") % [GameState.day_cycle.day, GameState.day_cycle.get_clock_text()]
	_time_hold.set_pressed_no_signal(GameState.frozen_minutes >= 0.0)


## Sets the clock (backwards too); while it is held, it stays at the new time.
func _set_time(hour: int) -> void:
	_release_clock()
	if GameState.frozen_minutes >= 0.0:
		GameState.set_frozen_time(hour * 60.0)
	else:
		GameState.day_cycle.set_minutes(hour * 60.0)
	_refresh_time()


func _hold_time(held: bool) -> void:
	GameState.set_frozen_time(GameState.day_cycle.minutes if held else -1.0)
	_refresh_time()


# --- Quests ---------------------------------------------------------------------------

## Current step, "next step" / "restart", two options and below a button per story step, grouped
## by chapter.
func _build_quests_page() -> void:
	_quests_page = VBoxContainer.new()
	_quests_page.name = "QuestsPage"
	_quests_page.visible = false
	_quests_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_quests_page.custom_minimum_size = Vector2(236, 0)
	_quests_page.add_theme_constant_override("separation", 2)
	_add_page(_quests_page)
	_quest_info = Label.new()
	_quest_info.custom_minimum_size = Vector2(236, 0)
	_quest_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quests_page.add_child(_quest_info)
	var row := HBoxContainer.new()
	_quests_page.add_child(row)
	var next := Button.new()
	next.text = Language.translate("Nächster Schritt")
	next.tooltip_text = Language.translate("Springt an den Schritt nach dem aktuellen.")
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(func() -> void: _play_step(QuestJump.next_step(GameState.story.step)))
	row.add_child(next)
	var restart := Button.new()
	restart.text = Language.translate("Neu starten")
	restart.tooltip_text = Language.translate("Startet den aktuellen Schritt von vorn.")
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.focus_mode = Control.FOCUS_NONE
	restart.pressed.connect(func() -> void: _play_step(GameState.story.step))
	row.add_child(restart)
	_quest_travel = CheckBox.new()
	_quest_travel.text = Language.translate("Hinbringen")
	_quest_travel.tooltip_text = Language.translate("Bringt dich zur Figur bzw. auf die Karte des Schritts.")
	_quest_travel.button_pressed = true
	_quest_travel.focus_mode = Control.FOCUS_NONE
	_quest_items = CheckBox.new()
	_quest_items.text = Language.translate("Quest-Items geben")
	_quest_items.tooltip_text = Language.translate("Gibt dir, was der Schritt zum Abgeben oder Vorzeigen braucht.")
	_quest_items.button_pressed = true
	_quest_items.focus_mode = Control.FOCUS_NONE
	var options := HBoxContainer.new()
	options.add_child(_quest_travel)
	options.add_child(_quest_items)
	_quests_page.add_child(options)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(236, 130)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_quests_page.add_child(scroll)
	_quest_buttons = VBoxContainer.new()
	_quest_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_buttons.add_theme_constant_override("separation", 2)
	scroll.add_child(_quest_buttons)
	var steps: Dictionary = Story.get_data("steps")
	for chapter: Array in QuestJump.chapters_with_steps():
		var heading := _heading(chapter[0])
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.custom_minimum_size = Vector2(228, 0)
		_quest_buttons.add_child(heading)
		for step_id: String in chapter[1]:
			var button := Button.new()
			button.text = Language.translate(str(steps[step_id].get("title", step_id)))
			button.tooltip_text = "%s\n%s" % [step_id, Language.translate(str(steps[step_id].get("goal", "")))]
			button.clip_text = true
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.focus_mode = Control.FOCUS_NONE
			button.set_meta(&"step", step_id)
			button.pressed.connect(_play_step.bind(step_id))
			_quest_buttons.add_child(button)


## Shows the current step and turns its button off.
func _refresh_quests() -> void:
	var story: Story = GameState.story
	var title: String = Language.translate(str(story.get_step().get("title", "")))
	_quest_info.text = Language.translate("Jetzt: %s » %s") % [StorySkip.chapter_of(story.step), title] 			if story.is_running() else Language.translate("Story beendet")
	for child in _quest_buttons.get_children():
		if child is Button:
			(child as Button).disabled = child.get_meta(&"step") == story.step


## Jumps to the step (StorySkip), gives its items and brings the player to where it happens
## (QuestJump), or reloads the current scene so its figures follow the new flags.
func _play_step(step_id: String) -> void:
	if step_id.is_empty():
		GameState.show_message(Language.translate("Admin: Das war der letzte Schritt."))
		return
	StorySkip.jump_to(step_id)
	if _quest_items.button_pressed:
		for specs: String in QuestJump.required_items(step_id):
			GameState.give_items(specs)
	var title: String = Language.translate(str(Story.get_data("steps")[step_id].get("title", step_id)))
	GameState.pending_message = Language.translate("Admin: %s") % title
	var scene: Node = get_tree().current_scene
	var current_path: String = scene.scene_file_path if scene else ""
	var place: Dictionary = QuestJump.location_of(step_id, current_path) if _quest_travel.button_pressed else {}
	close()
	if place.get("scene", "") == "":
		_reload_scene()
		return
	GameState.next_player_position = place.position
	GameState.travel_to(place.scene, place.spawn)


# --- Sounds ---------------------------------------------------------------------------

## One row per sound (name + a button per variant), then the background loops and the music.
func _build_sounds_page() -> void:
	_sounds_page = ScrollContainer.new()
	_sounds_page.name = Language.translate("SoundsPage")
	_sounds_page.visible = false
	_sounds_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sounds_page.custom_minimum_size = Vector2(236, 0)
	_sounds_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	_sounds_page.add_child(box)
	_add_page(_sounds_page)
	box.add_child(_heading(Language.translate("Geräusche")))
	for id in AudioManager.get_ids("sounds"):
		var row := HBoxContainer.new()
		var files: Array[String] = AudioManager.get_sound_files(id)
		var names: PackedStringArray = []
		for path in files:
			names.append(path.get_file())
		var play := _sound_button(_sound_name(id), ", ".join(names))
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.pressed.connect(AudioManager.play_sound.bind(id, 1.0))
		row.add_child(play)
		if files.size() > 1:
			for i in files.size():
				var variant := _sound_button(str(i + 1), files[i].get_file())
				variant.pressed.connect(AudioManager.play_sound_variant.bind(id, i))
				row.add_child(variant)
		box.add_child(row)
	box.add_child(_heading(Language.translate("Hintergrund (Regler Umgebung)")))
	for id in AudioManager.get_ids("ambience"):
		var button := _sound_button(_sound_name(id), id)
		button.set_meta(&"sound_id", id)
		button.pressed.connect(_toggle_ambience.bind(id))
		_ambience_buttons.append(button)
		box.add_child(button)
	box.add_child(_heading(Language.translate("Musik")))
	for id in AudioManager.get_ids("music"):
		var button := _sound_button(_sound_name(id), id)
		button.set_meta(&"sound_id", id)
		button.pressed.connect(_toggle_music.bind(id))
		_music_buttons.append(button)
		box.add_child(button)


func _sound_button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.set_meta(AudioManager.SILENT_META, true)
	return button


static func _sound_name(id: String) -> String:
	return String(SOUND_NAMES.get(id, id))


## Plays the loop; clicking the playing one goes back to the scene's own background.
func _toggle_ambience(id: String) -> void:
	AudioManager.preview_ambience("" if AudioManager.get_ambience_id() == id else id)
	_refresh_sounds()


func _toggle_music(id: String) -> void:
	if AudioManager.get_music_id() == id:
		AudioManager.update_music()
	else:
		AudioManager.play_music(id)
	_refresh_sounds()


## Marks the playing loop and music piece with "» ".
func _refresh_sounds() -> void:
	for pair: Array in [[_ambience_buttons, AudioManager.get_ambience_id()], [_music_buttons, AudioManager.get_music_id()]]:
		for button: Button in pair[0]:
			var id: String = button.get_meta(&"sound_id")
			button.text = ("» " if id == pair[1] else "") + _sound_name(id)


## Puts a page built in code into the window above the status row, filling the whole window.
func _add_page(page: Control) -> void:
	var status_row: Control = _status_label.get_parent()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_row.get_parent().add_child(page)
	status_row.get_parent().move_child(page, status_row.get_index())


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


## A button that sets all `flags` (or takes them back if they are all set already).
func _add_smithy_toggle(label: String, flags: Array, tooltip: String) -> void:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.tooltip_text = tooltip
	button.set_meta("label", label)
	button.set_meta("flags", flags)
	button.pressed.connect(_toggle_smithy.bind(button))
	_smithy_buttons.add_child(button)


func _refresh_smithy() -> void:
	for child in _smithy_buttons.get_children():
		var button := child as Button
		if button == null:
			continue
		if button.has_meta("flags"):
			button.text = ("[x] " if GameState.story.has_flags(button.get_meta("flags")) else "[ ] ") + str(button.get_meta("label"))
		elif button.name == "AllDungeons":
			button.text = ("[x] " if GameState.admin_all_dungeons else "[ ] ") + Language.translate("Alle Dungeons auf dem Brett")
		else:
			var locked: int = ContentDB.get_all_recipes().filter(
					func(recipe: RecipeData) -> bool: return not GameState.is_recipe_unlocked(recipe)).size()
			button.text = Language.translate("Alle Gussformen und Rezepte (%d fehlen)") % locked
			button.disabled = locked == 0


func _toggle_smithy(button: Button) -> void:
	var flags: Array = button.get_meta("flags")
	var label: String = button.get_meta("label")
	if GameState.story.has_flags(flags):
		GameState.story.clear_flags(flags)
		GameState.pending_message = Language.translate("Admin: %s wieder gesperrt.") % label
	else:
		for flag: String in flags:
			GameState.story.set_flag(flag)
		GameState.pending_message = Language.translate("Admin: %s freigeschaltet.") % label
	_reload_scene()


## Every mold and recipe known (unlock_recipe also unlocks what is built from new parts).
func _unlock_all_recipes() -> void:
	var count: int = 0
	for recipe: RecipeData in ContentDB.get_all_recipes():
		if GameState.unlock_recipe(recipe):
			count += 1
	_status_label.text = Language.translate("Admin: %d Gussformen und Rezepte freigeschaltet.") % count
	_refresh_smithy()


func _toggle_all_dungeons() -> void:
	GameState.admin_all_dungeons = not GameState.admin_all_dungeons
	_status_label.text = Language.translate("Admin: Dungeon-Brett zeigt alle Dungeons.") if GameState.admin_all_dungeons 			else Language.translate("Admin: Dungeon-Brett wieder nach Story.")
	_refresh_smithy()


## Started from the introduction, the clock would stay stopped (story.json "clock_stops_until").
func _release_clock() -> void:
	GameState.story.set_flag(str(Story.get_data("start").get("clock_stops_until", "")))


## Every item of ContentDB; composed weapons/armor/pickaxes/axes/backpacks/watering cans as finished pieces per material.
func _collect_entries() -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for item_data: ItemData in ContentDB.get_all_items():
		var recipe: RecipeData = ContentDB.recipe(item_data.id) if ContentDB.has_recipe(item_data.id) else null
		var part_ingredients: Array[Ingredient] = []
		if recipe and (item_data.is_weapon() or item_data.is_armor() or item_data.type in [ItemData.ItemType.PICKAXE, ItemData.ItemType.LUMBER_AXE, ItemData.ItemType.BACKPACK,
				ItemData.ItemType.WATERING_CAN]):
			for ingredient in recipe.ingredients:
				if ingredient.part_type != ItemData.PartType.NONE:
					part_ingredients.append(ingredient)
		if part_ingredients.is_empty():
			result.append(Crafting.create_result(item_data, 1, 0, item_data.base_rarity))
			continue
		for main_part in _parts_of_type(part_ingredients[0].part_type):
			var components: Array[ItemData] = []
			for ingredient in part_ingredients:
				var part: ItemData = main_part if ingredient == part_ingredients[0] \
						else _pick_part(ingredient, main_part.material_id)
				if part == null:
					components.clear()
					break
				for i in ingredient.amount:
					components.append(part)
			if not components.is_empty():
				result.append(Crafting.create_result(item_data, 1, 0, Crafting.get_base_rarity(item_data, components), components))
	return result


func _parts_of_type(part_type: ItemData.PartType) -> Array[ItemData]:
	var parts: Array[ItemData] = []
	for item_data: ItemData in ContentDB.get_all_items():
		if item_data.part_type == part_type:
			parts.append(item_data)
	return parts


## A part of that type, preferably of `material_id`, otherwise the first one. null if there is none.
func _pick_part(ingredient: Ingredient, material_id: String) -> ItemData:
	var parts: Array[ItemData] = []
	for part in _parts_of_type(ingredient.part_type):
		if ingredient.matches(part):
			parts.append(part)
	for part in parts:
		if part.material_id == material_id:
			return part
	return parts[0] if not parts.is_empty() else null


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_shown.clear()
	var search: String = _search.text.strip_edges().to_lower()
	var category: String = _category.get_item_text(_category.selected)
	for entry in _entries:
		if not search.is_empty() and not (search in entry.get_display_name().to_lower() or search in String(entry.item.id)):
			continue
		if category != CATEGORY_ALL and _get_category(entry.item) != category:
			continue
		_shown.append(entry)
		var slot_ui: ItemSlotUI = ITEM_SLOT_SCENE.instantiate()
		_grid.add_child(slot_ui)
		slot_ui.display(entry)
		slot_ui.gui_input.connect(_on_slot_gui_input.bind(_shown.size() - 1))
	_status_label.text = HINT if not _shown.is_empty() else Language.translate("Nichts gefunden.")


## As many item columns as fit next to the scroll bar.
func _update_columns() -> void:
	var width: float = _item_scroll.size.x - _item_scroll.get_v_scroll_bar().size.x
	_grid.columns = maxi(1, floori(width / SLOT_WIDTH))


func _get_category(item_data: ItemData) -> String:
	for category_name: String in CATEGORIES:
		if item_data.type in CATEGORIES[category_name]:
			return category_name
	return CATEGORY_OTHER


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if not (mouse_event and mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]):
		return
	var entry: InventorySlot = _shown[index]
	var amount: int = entry.item.max_stack
	if mouse_event.ctrl_pressed:
		amount = 1
	elif mouse_event.shift_pressed:
		amount = 10
	_give(entry, amount)
	_grid.get_child(index).accept_event()


## Adds `amount` pieces of `entry` to the inventory (weapons/armor each with new random attributes),
## with the rarity and quality picked above the list.
func _give(entry: InventorySlot, amount: int) -> void:
	entry = with_pick(entry, _picked_rarity(), int(_quality_pick.value))
	var leftover: int = amount
	if entry.item.max_stack == 1:
		leftover = 0
		for i in amount:
			var piece: InventorySlot = Crafting.create_result(entry.item, 1, entry.quality, entry.rarity, entry.components)
			if GameState.inventory.add_stack(piece) > 0:
				leftover = amount - i
				break
	else:
		leftover = GameState.inventory.add_stack(entry.copy_with_amount(amount))
	if leftover >= amount:
		_status_label.text = Language.translate("Kein Platz im Inventar.")
	elif leftover > 0:
		_status_label.text = Language.translate("Nur %d× %s passten ins Inventar.") % [amount - leftover, entry.get_display_name()]
	else:
		_status_label.text = Language.translate("%d× %s genommen.") % [amount, entry.get_display_name()]


## The rarity picked above the list, -1 = "Standard" (the item's own).
func _picked_rarity() -> int:
	return _rarity_pick.selected - 1


## `entry` with another rarity (-1 = keep) and quality (only for things that have one: ingots,
## parts, equipment; 0 = none). A new slot, the list entry stays as it is.
static func with_pick(entry: InventorySlot, rarity: int, quality: int) -> InventorySlot:
	var picked: InventorySlot = entry.copy_with_amount(entry.amount)
	if rarity >= 0:
		picked.rarity = rarity as Rarity.Tier
	if picked.has_quality():
		picked.quality = clampi(quality, 0, 100)
	return picked
