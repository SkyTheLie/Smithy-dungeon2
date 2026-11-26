extends CanvasLayer
## Always-visible UI: hotbar at the bottom with thin experience / reputation bars on top
## (ProgressStrips), gold bottom left, time compass top centre, side menu
## on the right (character,
## inventory, heroes, quests, save, load, settings) and the windows it opens.
## Keys: C = character, I = inventory, P = admin panel (every item without limit, only when the
## game runs from the editor), Escape = closes open windows, otherwise opens settings.
## The recipe book opens at the nightstand in the bedroom (RecipeBookStand) or with a right click
## on Aurelius' book.
## Character, heroes, quest and settings window share one place: only one of them is open at a time.
## The hero window (opened from the hero list) stands on its own.
## The inventory can stay open next to them. All windows can be dragged by their title bar.
## While the settings window is open the game is paused (clock, player, smelter, adventures ...);
## the HUD itself keeps running (process mode ALWAYS), so the window still works.
## Messages come in boxes above the action bar (ToastStack: 3 seconds each, they wait while the
## mouse is on one); new things in small boxes with a picture (UnlockPopup); player level
## and reputation rank come as a big banner (RewardBanner), finished equipment big in the middle
## (ItemReveal).

const TEXT_MAIN_MENU: String = "Hauptmenü"
const TEXT_MAIN_MENU_CONFIRM: String = "Wirklich? Nicht Gespeichertes geht verloren"
## "Ich stecke fest" (settings window): back to the spot in front of the smithy, once per 5 minutes.
const TEXT_STUCK: String = "Ich stecke fest"
const STUCK_COOLDOWN_MSEC: int = 5 * 60 * 1000
const STUCK_SCENE: String = "res://scenes/world/village/village.tscn"
const STUCK_SPAWN_POINT: StringName = &"FromSmithy"
const ADMIN_PANEL_SCENE: PackedScene = preload("res://scenes/ui/menus/admin_panel.tscn")
const TRASH_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/trash_slot.tscn")
const CRYSTAL_MAP_SCENE: PackedScene = preload("res://scenes/ui/hud/crystal_map_window.tscn")
const DESERT_MAP_SCENE: PackedScene = preload("res://scenes/ui/hud/desert_map_window.tscn")
const STORM_MAP_SCENE: PackedScene = preload("res://scenes/ui/hud/storm_map_window.tscn")
const POTION_RECIPE_SCENE: PackedScene = preload("res://scenes/ui/hud/potion_recipe_window.tscn")
const LEXICON_SCENE: PackedScene = preload("res://scenes/ui/hud/lexicon_window.tscn")
const LEXICON_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/hud/lexicon_entry_window.tscn")
const LEXICON_ICON: Texture2D = preload("res://assets/sprites/ui/menu_lexicon.png")
## After sleeping: how long the screen stays black, then how long it fades in.
const WAKE_UP_HOLD: float = 1.2
const WAKE_UP_FADE: float = 0.8
## With a day summary (GameState.wake_up_report) the screen waits for a click or key, at the
## earliest after WAKE_UP_HOLD; the game is paused meanwhile.
const TEXT_WAKE_CONTINUE: String = "Klicken oder Taste drücken"
## Pixels between the date / morning messages and the day summary under them.
const WAKE_REPORT_GAP: float = 12.0
const COLOR_REPORT: Color = Color(0.92, 0.88, 0.78)
const COLOR_WAKE_HINT: Color = Color(0.6, 0.6, 0.6)
## The hotbar (and the bars above it) goes see-through while the player stands behind it, e.g.
## right after coming in from the south edge of a map; with the mouse on it, it is solid again.
const HOTBAR_HIDDEN_ALPHA: float = 0.3
const HOTBAR_FADE_SPEED: float = 5.0
## The player's figure on screen, from his feet: width and height in pixels.
const PLAYER_SCREEN_SIZE: Vector2 = Vector2(16, 32)

@onready var _inventory_window: Control = $InventoryWindow
@onready var _character_window: CharacterWindow = %CharacterWindow
@onready var _quest_window: QuestLogWindow = %QuestWindow
@onready var _quest_detail_window: QuestDetailWindow = %QuestDetailWindow
@onready var _quest_tracker: QuestTracker = %QuestTracker
@onready var _recipe_book_window: RecipeBookWindow = %RecipeBookWindow
@onready var _save_window: SaveWindow = %SaveWindow
@onready var _settings_window: Control = %SettingsWindow
@onready var _heroes_window: HeroesWindow = %HeroesWindow
@onready var _hero_window: HeroWindow = %HeroWindow
@onready var _hero_stats_window: HeroStatsWindow = %HeroStatsWindow
@onready var _skill_command_window: SkillCommandWindow = %SkillCommandWindow
@onready var _battle_window: BattleWindow = %BattleWindow
@onready var _gold_label: Label = %GoldLabel
@onready var _day_label: Label = %DayLabel
@onready var _wake_overlay: ColorRect = %WakeOverlay
@onready var _wake_label: Label = %WakeLabel
## Every item without limit (key P), see AdminPanel.
@onready var _admin_panel: AdminPanel = ADMIN_PANEL_SCENE.instantiate()
## Recipe page of a potion (tab "Rezepte" of the character window).
@onready var _potion_recipe_window: PotionRecipeWindow = POTION_RECIPE_SCENE.instantiate()
## Lexicon (key L): monsters and items; a page of it stands on its own next to it.
@onready var _lexicon_window: LexiconWindow = LEXICON_SCENE.instantiate()
@onready var _lexicon_entry_window: LexiconEntryWindow = LEXICON_ENTRY_SCENE.instantiate()
@onready var _main_windows: Array[Control] = [_character_window, _heroes_window, _quest_window, _settings_window,
	_save_window, _recipe_book_window, _lexicon_window]
## Every HUD window (for Escape and the X of the title bars).
@onready var _all_windows: Array[Control] = [
	_inventory_window, _hero_window, _hero_stats_window, _skill_command_window, _battle_window, _character_window, _heroes_window, _quest_window,
	_settings_window, _save_window, _quest_detail_window, _recipe_book_window, _potion_recipe_window,
	_lexicon_window, _lexicon_entry_window]

## Real time of the last "Ich stecke fest" (static: every scene has its own HUD). -1 = not used yet.
static var _last_stuck_msec: int = -1
var _stuck_button: Button = Button.new()

## true while the inventory is open only because a window asked for it (shop): it closes with
## that window. Opening/closing it by hand clears it.
var _inventory_opened_for_window: bool = false
## true after the first click on "Hauptmenü" (the button asks, the second click leaves).
var _main_menu_asked: bool = false
## Messages above the action bar.
var _toasts: ToastStack = ToastStack.new()
var _banner: RewardBanner = RewardBanner.new()
var _unlock_popup: UnlockPopup = UnlockPopup.new()
## Lower edge of the messages, and how far an unlock popup pushes them up.
var _toast_bottom: float = 0.0
var _unlock_height: float = 0.0
var _item_reveal: ItemReveal = ItemReveal.new()
## Thin experience / reputation bars above the action bar (no numbers).
var _progress_strips: ProgressStrips = ProgressStrips.new()
## The player of this map (null in menus); found once when the map is ready.
var _player: Node2D
## Day summary below the date on the wake-up screen, and the hint to go on.
var _report_label: Label = Label.new()
var _wake_hint: Label = Label.new()
## true while the wake-up screen waits for input; input counts from this tick on.
var _wake_waiting: bool = false
var _wake_ready_msec: int = 0
## Offsets of the date label without a summary (it moves up when there is one).
var _wake_label_top: float = 0.0
var _wake_label_bottom: float = 0.0


## Opens or closes the crystal map or the sand map (right click on it in the inventory).
func _toggle_map_window(window: Control) -> void:
	window.visible = not window.visible
	if window.visible:
		(window.get_node("VBox/TitleBar") as WindowTitleBar).bring_to_front()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The crystal map (right click on it in the inventory) stands on its own like the hero window.
	var crystal_map: Control = CRYSTAL_MAP_SCENE.instantiate()
	add_child(crystal_map)
	_all_windows.append(crystal_map)
	add_child(_potion_recipe_window)
	add_child(_lexicon_window)
	add_child(_lexicon_entry_window)
	_add_lexicon_button()
	Events.lexicon_requested.connect(_open_lexicon)
	_character_window.potion_recipe_selected.connect(_potion_recipe_window.show_potion)
	# A bound method, no lambda: Godot drops the connection when this HUD is freed (scene change);
	# a lambda would stay connected to the autoload and touch the freed window of the old HUD.
	Events.crystal_map_requested.connect(_toggle_map_window.bind(crystal_map))
	# The sand map of the desert works the same way; the desert compass is always on screen while held.
	var desert_map: Control = DESERT_MAP_SCENE.instantiate()
	add_child(desert_map)
	_all_windows.append(desert_map)
	Events.desert_map_requested.connect(_toggle_map_window.bind(desert_map))
	var storm_map: Control = STORM_MAP_SCENE.instantiate()
	add_child(storm_map)
	_all_windows.append(storm_map)
	Events.storm_map_requested.connect(_toggle_map_window.bind(storm_map))
	add_child(CompassOverlay.new())
	# Hidden in the editor (hud.tscn), so it does not cover the maps. Close the windows BEFORE
	# showing the layer: open windows move themselves to the front when the layer appears
	# (WindowTitleBar), and reordering the children while Godot tells them the layer is visible
	# skips some of them - those windows (character, quests, settings) then never showed up.
	for window in _all_windows:
		window.hide()
	show()
	_wake_overlay.hide()
	_build_wake_report()
	add_child(_admin_panel)
	_toasts.z_index = 1
	_toasts.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	add_child(_toasts)
	add_child(_banner)
	add_child(_item_reveal)
	_progress_strips.anchor_control = $HotbarFrame
	add_child(_progress_strips)
	_find_player.call_deferred()
	_unlock_popup.anchor_control = _progress_strips
	_unlock_popup.height_changed.connect(_on_unlock_popup_height)
	add_child(_unlock_popup)
	%CharacterButton.pressed.connect(_toggle_main_window.bind(_character_window))
	%InventoryButton.pressed.connect(_toggle_inventory)
	# Hand-in slots (dialogues, quests) need the bag to drag items from.
	Events.inventory_open_requested.connect(_on_inventory_open_requested)
	Events.inventory_close_requested.connect(_on_inventory_close_requested)
	# Closed by hand (X, I/Tab): later close requests leave it alone.
	_inventory_window.visibility_changed.connect(func() -> void:
		if not _inventory_window.visible:
			_inventory_opened_for_window = false)
	%HeroesButton.pressed.connect(_toggle_main_window.bind(_heroes_window))
	%QuestButton.pressed.connect(_toggle_main_window.bind(_quest_window))
	%SaveButton.pressed.connect(_toggle_save_window.bind(SaveWindow.Mode.SAVE))
	%LoadButton.pressed.connect(_toggle_save_window.bind(SaveWindow.Mode.LOAD))
	%SettingsButton.pressed.connect(_toggle_main_window.bind(_settings_window))
	%QuitButton.pressed.connect(get_tree().quit)
	# Tips may point at side menu buttons (story.json "hints" » "glow").
	for pair: Array in [[%SettingsButton, "menu:settings"], [%SaveButton, "menu:save"], [%LoadButton, "menu:load"]]:
		GuideFrame.attach(pair[0], Guide.is_target.bind(pair[1]))
	# X in the title bar closes the window.
	for window in _all_windows:
		(window.get_node("VBox/TitleBar") as WindowTitleBar).close_requested.connect(window.hide)
	_add_inventory_sort_button()
	_add_settings_extras()
	_heroes_window.hero_selected.connect(_open_hero)
	_hero_window.more_stats_requested.connect(_open_hero_stats)
	_hero_window.skill_command_requested.connect(_skill_command_window.show_command)
	_quest_window.quest_selected.connect(_quest_detail_window.show_quest)
	_quest_window.order_selected.connect(_quest_detail_window.show_order)
	_quest_window.story_selected.connect(_quest_detail_window.show_story)
	_quest_window.side_task_selected.connect(_quest_detail_window.show_side_task)
	# The tracker opens the same detail window.
	_quest_tracker.quest_selected.connect(_quest_detail_window.show_quest)
	_quest_tracker.order_selected.connect(_quest_detail_window.show_order)
	_quest_tracker.story_selected.connect(_quest_detail_window.show_story)
	_quest_tracker.side_task_selected.connect(_quest_detail_window.show_side_task)
	Events.message_requested.connect(_toasts.show_message)
	Events.recipe_book_requested.connect(_open_recipe_book)
	Events.recipe_book_toggle_requested.connect(_toggle_main_window.bind(_recipe_book_window))
	Events.recipe_book_close_requested.connect(_recipe_book_window.hide)
	GameState.customers.customer_arrived.connect(_on_customer_arrived)
	GameState.customers.order_accepted.connect(_on_order_accepted)
	GameState.quest_completed.connect(_on_quest_completed)
	GameState.hero_hired.connect(_on_hero_hired)
	GameState.gold_changed.connect(_update_gold)
	GameState.adventure_started.connect(_battle_window.show_adventure)
	Events.adventure_view_requested.connect(_battle_window.show_adventure)
	GameState.adventure_finished.connect(_on_adventure_finished)
	GameState.player_stats.leveled_up.connect(_on_player_leveled_up)
	GameState.achievements.unlocked.connect(_on_achievement_unlocked)
	GameState.reputation.rank_reached.connect(func(rank_id: String) -> void:
		_banner.announce(Language.translate("Ruf-Rang %s!") % rank_id, Language.translate("Dein Ruf steigt")))
	GameState.slept.connect(_on_slept)
	GameState.game_saved.connect(_on_game_saved)
	_update_gold(GameState.gold)
	add_to_group(UiScale.LISTENER_GROUP)
	apply_ui_scale()
	_show_wake_up()
	if not GameState.pending_message.is_empty():
		_show_toast(GameState.pending_message)
		GameState.pending_message = ""


## Sizes chosen in the settings (tab "Oberfläche", UiScale), each part on its own.
func apply_ui_scale() -> void:
	var parts: Dictionary = {
		"hotbar": [[$HotbarFrame], UiScale.Anchor.BOTTOM],
		"gold": [[$GoldBox], UiScale.Anchor.BOTTOM_LEFT],
		"time": [[$TimePanel], UiScale.Anchor.TOP],
		"side_menu": [[$SideMenu], UiScale.Anchor.RIGHT],
		"inventory": [[_inventory_window], UiScale.Anchor.CENTER],
		"character": [[_character_window, _potion_recipe_window], UiScale.Anchor.CENTER],
		"heroes": [[_heroes_window, _hero_window, _hero_stats_window, _skill_command_window], UiScale.Anchor.CENTER],
		"battle": [[_battle_window], UiScale.Anchor.CENTER],
		"quests": [[_quest_window, _quest_detail_window], UiScale.Anchor.CENTER],
		"recipes": [[_recipe_book_window, _lexicon_window, _lexicon_entry_window], UiScale.Anchor.CENTER],
	}
	for id: String in parts:
		for control: Control in parts[id][0]:
			UiScale.apply(control, UiScale.get_scale(id), parts[id][1])
	_progress_strips.place()
	# messages stay just above the action bar, however big it is
	# (+ the thin experience / reputation bars on top of it)
	var bar_height: float = (($HotbarFrame as Control).size.y + 6.0) * ($HotbarFrame as Control).scale.y
	_toast_bottom = -bar_height - 8.0
	_on_unlock_popup_height(_unlock_height)
	# open windows that got bigger must not stick out of the screen
	for window in _all_windows:
		if window.visible:
			(window.get_node("VBox/TitleBar") as WindowTitleBar).keep_on_screen()


func _on_unlock_popup_height(height: float) -> void:
	_unlock_height = height
	_toasts.offset_bottom = _toast_bottom - height
	_toasts.offset_top = _toasts.offset_bottom


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle_inventory()
	elif event.is_action_pressed("character"):
		_toggle_main_window(_character_window)
	elif event.is_action_pressed("journal"):
		_toggle_main_window(_quest_window)
	elif event.is_action_pressed("heroes"):
		_toggle_main_window(_heroes_window)
	elif event.is_action_pressed("lexicon"):
		_toggle_main_window(_lexicon_window)
	elif event.is_action_pressed("quick_save"):
		_quick_save()
	elif event.is_action_pressed("quick_load"):
		_quick_load()
	elif event.is_action_pressed("admin_panel") and GameState.has_dev_tools():  # DEV-ONLY
		_admin_panel.toggle()
	elif event.is_action_pressed("ui_cancel"):
		# Open station windows close themselves on Escape (StationMenu) - leave the key to them.
		if StationMenu.is_any_open(get_tree()):
			return
		_on_cancel_pressed()
	else:
		return
	get_viewport().set_input_as_handled()



## F5: saves into the quicksave slot (the "... gespeichert" message comes from game_saved).
func _quick_save() -> void:
	if GameState.in_main_menu:
		return
	if not GameState.save_game(SaveSystem.QUICKSAVE_SLOT):
		_show_toast(Language.translate("Schnellspeichern hat nicht geklappt."))


## F7: loads the quicksave.
func _quick_load() -> void:
	if not SaveSystem.exists(SaveSystem.QUICKSAVE_SLOT):
		_show_toast(Language.translate("Noch keine Schnellspeicherung (F5 speichert)."))
		return
	GameState.load_game(SaveSystem.QUICKSAVE_SLOT)

## Escape: close every open HUD window; if none was open, open the settings.
func _on_cancel_pressed() -> void:
	var any_open: bool = false
	for window in _all_windows:
		any_open = any_open or window.visible
	if not any_open:
		_toggle_main_window(_settings_window)
		return
	for window in _all_windows:
		window.hide()


## Book button of the lexicon in the side menu, below the quests (placeholder icon).
func _add_lexicon_button() -> void:
	var button := Button.new()
	button.name = "LexiconButton"
	button.custom_minimum_size = Vector2(28, 28)
	button.focus_mode = Control.FOCUS_NONE
	button.icon = LEXICON_ICON
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = Language.translate("Lexikon (%s)") % KeyBindings.get_action_text("lexicon")
	button.pressed.connect(_toggle_main_window.bind(_lexicon_window))
	var quest_button: Button = %QuestButton
	quest_button.add_sibling(button)


## A link or slot of the lexicon: a discovered monster / item opens its page (beside the lexicon
## when that is open), anything else opens the lexicon at its silhouette, which shakes.
## "" = just the lexicon.
func _open_lexicon(link: String) -> void:
	if link.is_empty():
		if not _lexicon_window.visible:
			_toggle_main_window(_lexicon_window)
		return
	var kind: String = link.get_slice(":", 0)
	var id: String = link.get_slice(":", 1)
	var known: bool = false
	# Status effects and skills have no secret: their page opens right away.
	if (kind == Lexicon.EFFECT and ContentDB.has_status_effect(id)) or (kind == Lexicon.SKILL and ContentDB.find_skill(id) != null):
		known = true
	elif kind == Lexicon.ENEMY and ContentDB.has_enemy(id):
		known = GameState.lexicon.is_enemy_known(ContentDB.enemy(id))
	elif kind == Lexicon.ITEM and ContentDB.has_item(id):
		known = GameState.lexicon.is_item_known(ContentDB.item(id))
	if known:
		_lexicon_entry_window.show_link(link)
		_place_beside_lexicon.call_deferred()
		return
	if not _lexicon_window.visible:
		for other in _main_windows:
			other.hide()
	_lexicon_window.point_at(link)


## The page goes right of the lexicon; without room there the lexicon moves left (unless pinned),
## and only if both don't fit the page goes left of it. Nothing moves while the page is pinned
## or the lexicon is closed.
func _place_beside_lexicon() -> void:
	var bar := _lexicon_entry_window.get_node("VBox/TitleBar") as WindowTitleBar
	if not _lexicon_window.visible or not _lexicon_entry_window.visible or bar.is_pinned():
		return
	var book: Rect2 = UiScale.get_visual_rect(_lexicon_window)
	var rect: Rect2 = UiScale.get_visual_rect(_lexicon_entry_window)
	if not rect.intersects(book):
		return
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var book_bar := _lexicon_window.get_node("VBox/TitleBar") as WindowTitleBar
	if book.end.x + INVENTORY_GAP + rect.size.x > screen_size.x and not book_bar.is_pinned():
		book.position.x = maxf(0.0, screen_size.x - INVENTORY_GAP - rect.size.x - book.size.x)
		UiScale.set_visual_position(_lexicon_window, book.position)
	if book.end.x + INVENTORY_GAP + rect.size.x <= screen_size.x:
		rect.position.x = book.end.x + INVENTORY_GAP
	else:
		rect.position.x = maxf(0.0, book.position.x - INVENTORY_GAP - rect.size.x)
	rect.position.y = book.position.y
	UiScale.set_visual_position(_lexicon_entry_window, rect.position)
	bar.keep_on_screen()


## Aurelius' book (right click in the inventory) opens the recipe book at a tab.
func _open_recipe_book(tab_name: String) -> void:
	for other in _main_windows:
		other.hide()
	_recipe_book_window.open_tab(tab_name)


## Under the bag: "Sortieren" (merges and orders the bag, Inventory.sort, the hotbar stays) and
## the trash slot "Wegschmeißen" (TrashSlot). The window fits itself to the bag, which grows and
## shrinks with the backpack.
func _add_inventory_sort_button() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var button := Button.new()
	button.text = Language.translate("Sortieren")
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(GameState.inventory.sort.bind(Inventory.HOTBAR_SIZE))
	row.add_child(button)
	row.add_child(TRASH_SLOT_SCENE.instantiate())
	_inventory_window.get_node("VBox").add_child(row)
	var shown_size: Array[int] = [GameState.inventory.slots.size()]
	GameState.inventory.changed.connect(func() -> void:
		if GameState.inventory.slots.size() != shown_size[0]:
			shown_size[0] = GameState.inventory.slots.size()
			_fit_inventory_window.call_deferred())


## New size after the backpack changed; a pinned window moves up so it stays on the screen.
func _fit_inventory_window() -> void:
	_inventory_window.reset_size()
	var bottom: float = get_viewport().get_visible_rect().size.y
	_inventory_window.position.y = maxf(0.0, minf(_inventory_window.position.y, bottom - _inventory_window.size.y))


## Settings window: the tabs (SettingsPanel, same block as in the main menu) and "Hauptmenü"
## above "Spiel beenden" (asks once).
func _add_settings_extras() -> void:
	var quit_button: Button = %QuitButton
	var panel := SettingsPanel.new()
	quit_button.add_sibling(panel)
	quit_button.get_parent().move_child(panel, quit_button.get_index())
	var menu_button := Button.new()
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.add_theme_font_size_override("font_size", 11)
	menu_button.text = Language.translate(TEXT_MAIN_MENU)
	menu_button.pressed.connect(_on_main_menu_pressed.bind(menu_button))
	_settings_window.visibility_changed.connect(func() -> void:
		_main_menu_asked = false
		menu_button.text = Language.translate(TEXT_MAIN_MENU))
	_settings_window.visibility_changed.connect(_update_pause)
	quit_button.add_sibling(menu_button)
	quit_button.get_parent().move_child(menu_button, quit_button.get_index())
	_stuck_button.focus_mode = Control.FOCUS_NONE
	_stuck_button.add_theme_font_size_override("font_size", 11)
	_stuck_button.tooltip_text = Language.translate("Bringt dich vor deine Schmiede. Nur alle 5 Minuten.")
	_stuck_button.pressed.connect(_on_stuck_pressed)
	menu_button.add_sibling(_stuck_button)
	menu_button.get_parent().move_child(_stuck_button, menu_button.get_index())
	_update_stuck_button()


## Milliseconds until "Ich stecke fest" works again (0 = ready).
func _stuck_cooldown_left() -> int:
	if _last_stuck_msec < 0:
		return 0
	return maxi(_last_stuck_msec + STUCK_COOLDOWN_MSEC - Time.get_ticks_msec(), 0)


func _update_stuck_button() -> void:
	var left: int = _stuck_cooldown_left()
	_stuck_button.disabled = left > 0
	if left > 0:
		var seconds: int = ceili(left / 1000.0)
		_stuck_button.text = "%s (%d:%02d)" % [Language.translate(TEXT_STUCK), floori(seconds / 60.0), seconds % 60]
	else:
		_stuck_button.text = Language.translate(TEXT_STUCK)


## Safety if the player got stuck somewhere: straight to the door of the own smithy.
func _on_stuck_pressed() -> void:
	if _stuck_cooldown_left() > 0:
		return
	_last_stuck_msec = Time.get_ticks_msec()
	_settings_window.hide()
	GameState.travel_to(STUCK_SCENE, STUCK_SPAWN_POINT)


## The world stands still while the settings are open.
func _update_pause() -> void:
	get_tree().paused = _settings_window.visible


func _exit_tree() -> void:
	# Leaving the scene (main menu, travel) with the settings open: nothing stays paused.
	get_tree().paused = false
	# The old scene leaves the tree before it is freed; GameState must not reach this HUD in between
	# (e.g. a customer arriving during a scene change made the toast call get_tree() on null).
	_disconnect_from_outside()


## Takes back every connection from signals outside this HUD (GameState, its systems, the story).
func _disconnect_from_outside() -> void:
	for connection: Dictionary in get_incoming_connections():
		var source_signal: Signal = connection["signal"]
		var source: Object = source_signal.get_object()
		if source is Node and (source == self or is_ancestor_of(source)):
			continue
		if source_signal.is_connected(connection["callable"]):
			source_signal.disconnect(connection["callable"])


## First click asks, the second leaves (what was not saved is lost).
func _on_main_menu_pressed(button: Button) -> void:
	if not _main_menu_asked:
		_main_menu_asked = true
		button.text = Language.translate(TEXT_MAIN_MENU_CONFIRM)
		return
	GameState.return_to_main_menu()


func _toggle_inventory() -> void:
	_inventory_window.visible = not _inventory_window.visible
	# Opened or closed by hand: the player decides, a shop closing doesn't close it.
	_inventory_opened_for_window = false


## A window needs the inventory (shop, hand-in slots): open it, and remember that it was closed
## before, so it can close again with the window.
func _on_inventory_open_requested() -> void:
	if not _inventory_window.visible:
		_inventory_window.show()
		_inventory_opened_for_window = true
	_place_inventory_beside_window.call_deferred()


## Gap in pixels between the inventory and the window it was opened for.
const INVENTORY_GAP: float = 8.0


## A shop (station menu with opens_inventory) opened the inventory: unless it is pinned, it moves
## left of that window (right of it if there is no room on the left), so it isn't hidden behind it.
## Deferred: both windows get their size and their own position first.
func _place_inventory_beside_window() -> void:
	var bar := _inventory_window.get_node("VBox/TitleBar") as WindowTitleBar
	if not _inventory_window.visible or bar.is_pinned():
		return
	var shop: Control = null
	for node in get_tree().get_nodes_in_group(StationMenu.QUICK_MOVE_GROUP):
		var menu := node as StationMenu
		if menu and menu.visible and menu.opens_inventory:
			shop = menu.get_node("%TitleBar")._get_window()
	if shop == null:
		return
	var shop_rect: Rect2 = UiScale.get_visual_rect(shop)
	var rect: Rect2 = UiScale.get_visual_rect(_inventory_window)
	if not rect.intersects(shop_rect):
		return
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	if shop_rect.position.x - INVENTORY_GAP - rect.size.x >= 0.0:
		rect.position.x = shop_rect.position.x - INVENTORY_GAP - rect.size.x
	else:
		rect.position.x = minf(shop_rect.end.x + INVENTORY_GAP, screen_size.x - rect.size.x)
	rect.position.y = shop_rect.position.y
	UiScale.set_visual_position(_inventory_window, rect.position)
	bar.keep_on_screen()


## The window that needed it closed: close the inventory again if it opened it and it isn't pinned.
func _on_inventory_close_requested() -> void:
	if not _inventory_opened_for_window:
		return
	_inventory_opened_for_window = false
	if not (_inventory_window.get_node("VBox/TitleBar") as WindowTitleBar).is_pinned():
		_inventory_window.hide()


func _toggle_main_window(window: Control) -> void:
	var open: bool = not window.visible
	for other in _main_windows:
		other.hide()
	window.visible = open


## Same button again (and same mode) closes the window.
func _toggle_save_window(mode: SaveWindow.Mode) -> void:
	var was_open: bool = _save_window.visible and _save_window.get_mode() == mode
	for other in _main_windows:
		other.hide()
	if not was_open:
		_save_window.open(mode)


func _on_customer_arrived(visitor: Customers.Visitor) -> void:
	_show_toast(Language.translate("%s wartet vor der Schmiede") % visitor.order.customer_name)


func _on_order_accepted(order: CustomerOrder) -> void:
	_show_toast(Language.translate("Auftrag angenommen: %s") % order.get_item_name())


func _on_game_saved(slot: int, success: bool) -> void:
	if success:
		_show_toast(Language.translate("%s gespeichert") % SaveSystem.get_slot_name(slot))
	else:
		_show_toast(Language.translate("Speichern fehlgeschlagen"))


func _on_quest_completed(quest: QuestData, rewards_text: String) -> void:
	_show_toast(Language.translate("Auftrag erledigt: %s – %s") % [quest.title, rewards_text])


func _open_hero(hero: Hero) -> void:
	_hero_window.show_hero(hero)
	_hero_window.show()
	if _hero_stats_window.visible:
		_hero_stats_window.show_hero(hero)


func _open_hero_stats(hero: Hero) -> void:
	_hero_stats_window.show_hero(hero)
	_hero_stats_window.show()


func _on_hero_hired(hero: Hero) -> void:
	_show_toast(Language.translate("%s schließt sich dir an!") % hero.display_name)


func _on_adventure_finished(adventure: Adventure) -> void:
	# Arena duels: the tournament says itself what happened (HeroTournament.fight_finished).
	if adventure is ArenaDuel:
		return
	var many: bool = adventure.heroes.size() > 1
	var result: String
	if adventure.state == Adventure.State.VICTORY:
		result = "haben %s geschafft!" if many else Language.translate("hat %s geschafft!")
	else:
		result = Language.translate("sind in %s gescheitert.") if many else Language.translate("ist in %s gescheitert.")
		if adventure.timed_out:
			result = Language.translate("haben es in %s nicht rechtzeitig geschafft.") if many else Language.translate("hat es in %s nicht rechtzeitig geschafft.")
		if adventure.gave_up:
			result = Language.translate("kehren aus %s zurück. Du hast zum Rückzug gerufen.") if many else Language.translate("kehrt aus %s zurück. Du hast zum Rückzug gerufen.")
	var text: String = "%s %s" % [adventure.get_party_names(), result % adventure.dungeon.display_name]
	if adventure.state == Adventure.State.VICTORY and not (adventure.reward_items.is_empty() and adventure.loot.is_empty()):
		text += Language.translate(" Die Beute liegt in der Loot-Kiste in der Werkstatt.")
	elif adventure.state != Adventure.State.VICTORY and not adventure.loot.is_empty():
		text += Language.translate(" Ein Teil der Beute konnte gerettet werden (Loot-Kiste).")
	_show_toast(text)


func _process(delta: float) -> void:
	_fade_hotbar(delta)
	var cycle: DayCycle = GameState.day_cycle
	_day_label.text = "%s · %s · %s" % [GameCalendar.get_short_text(cycle.day), cycle.get_clock_text(), cycle.get_phase_name()]
	if GameCalendar.is_full_moon(cycle.day):
		_day_label.text += " · Vollmond"
	if _settings_window.visible:
		_update_stuck_button()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Node2D


## Is the player's figure behind the hotbar (and the mouse not on it)?
func is_player_behind_hotbar() -> bool:
	if not is_instance_valid(_player) or not _player.is_visible_in_tree():
		return false
	var bar: Rect2 = ($HotbarFrame as Control).get_global_rect()
	if bar.has_point(($HotbarFrame as Control).get_global_mouse_position()):
		return false
	var feet: Vector2 = _player.get_global_transform_with_canvas().origin
	var figure := Rect2(feet - Vector2(PLAYER_SCREEN_SIZE.x / 2.0, PLAYER_SCREEN_SIZE.y), PLAYER_SCREEN_SIZE)
	return bar.intersects(figure)


func _fade_hotbar(delta: float) -> void:
	var target: float = HOTBAR_HIDDEN_ALPHA if is_player_behind_hotbar() else 1.0
	var frame := $HotbarFrame as Control
	if is_equal_approx(frame.modulate.a, target):
		return
	var alpha: float = move_toward(frame.modulate.a, target, HOTBAR_FADE_SPEED * delta)
	frame.modulate.a = alpha
	_progress_strips.modulate.a = alpha


func _update_gold(gold: int) -> void:
	_gold_label.text = str(gold)


func _on_slept(_day: int) -> void:
	_show_wake_up()


## Black screen with GameState.wake_up_text (the date, e.g. "Dienstag, 2. Frühling, Jahr 1"), then fades into the game.
## With a day summary (GameState.wake_up_report: "Gestern" / "Heute") it shows that below the date
## and waits for a click or key (game paused).
func _show_wake_up() -> void:
	if GameState.wake_up_text.is_empty():
		return
	_wake_label.text = GameState.wake_up_text
	GameState.wake_up_text = ""
	var report: String = GameState.wake_up_report
	GameState.wake_up_report = ""
	_report_label.text = report
	_report_label.visible = not report.is_empty()
	_wake_hint.visible = not report.is_empty()
	_layout_wake_up()
	_wake_overlay.modulate.a = 1.0
	_wake_overlay.show()
	if _report_label.visible:
		_wake_waiting = true
		_wake_ready_msec = Time.get_ticks_msec() + roundi(WAKE_UP_HOLD * 1000.0)
		_wake_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		get_tree().paused = true
		return
	_fade_out_wake_up(WAKE_UP_HOLD)


## Date (and the morning messages under it: Nina, the shop, Lotte …) and the day summary stacked
## by their real heights and centred together, so a long list of messages never runs into the
## summary.
func _layout_wake_up() -> void:
	if not _report_label.visible:
		_wake_label.offset_top = _wake_label_top
		_wake_label.offset_bottom = _wake_label_bottom
		return
	var wake_height: float = maxf(_wake_label_bottom - _wake_label_top, _wake_label.get_combined_minimum_size().y)
	var report_height: float = _report_label.get_line_count() * (_report_label.get_line_height() \
			+ _report_label.get_theme_constant("line_spacing"))
	var top: float = -(wake_height + WAKE_REPORT_GAP + report_height) / 2.0
	# never above the screen; the "click" hint at the bottom keeps its place
	top = maxf(top, -_wake_overlay.size.y / 2.0 + WAKE_REPORT_GAP)
	_wake_label.offset_top = top
	_wake_label.offset_bottom = top + wake_height
	_report_label.offset_top = top + wake_height + WAKE_REPORT_GAP
	_report_label.offset_bottom = _report_label.offset_top + report_height


func _fade_out_wake_up(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(_wake_overlay, "modulate:a", 0.0, WAKE_UP_FADE)
	tween.tween_callback(_wake_overlay.hide)


## While the day summary waits, every input is taken; a press after the hold time closes it.
func _input(event: InputEvent) -> void:
	if not _wake_waiting:
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo() or Time.get_ticks_msec() < _wake_ready_msec:
		return
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		_close_wake_report()


func _close_wake_report() -> void:
	_wake_waiting = false
	_wake_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_pause()
	_fade_out_wake_up(0.0)


## Labels for the day summary, built once inside the wake-up screen.
func _build_wake_report() -> void:
	_wake_label_top = _wake_label.offset_top
	_wake_label_bottom = _wake_label.offset_bottom
	_report_label.set_anchors_preset(Control.PRESET_CENTER)
	_report_label.offset_left = -130.0
	_report_label.offset_right = 130.0
	_report_label.offset_top = -80.0
	_report_label.offset_bottom = 130.0
	_report_label.add_theme_font_size_override("font_size", 11)
	_report_label.add_theme_color_override("font_color", COLOR_REPORT)
	_report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wake_overlay.add_child(_report_label)
	_wake_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_wake_hint.offset_left = -150.0
	_wake_hint.offset_right = 150.0
	_wake_hint.offset_top = -24.0
	_wake_hint.offset_bottom = -8.0
	_wake_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wake_hint.add_theme_font_size_override("font_size", 11)
	_wake_hint.add_theme_color_override("font_color", COLOR_WAKE_HINT)
	_wake_hint.text = Language.translate(TEXT_WAKE_CONTINUE)
	_wake_overlay.add_child(_wake_hint)
	_report_label.hide()
	_wake_hint.hide()


func _on_achievement_unlocked(id: String, level: int) -> void:
	var data: Dictionary = Achievements.get_data(id)
	var max_text: String = " (max)" if level >= Achievements.get_max_level(id) and level > 1 else ""
	var level_text: String = Language.translate(" Lv %d%s") % [level, max_text] if Achievements.get_max_level(id) > 1 else ""
	_show_toast(Language.translate("Erfolg: %s%s") % [data.get("name", id), level_text])
	AudioManager.play_sound("achievement")


func _on_player_leveled_up(level: int) -> void:
	_banner.announce(Language.translate("Level %d!") % level, "+1 Skillpunkt")


## Shows a message above the action bar (ToastStack; the same text twice at once is shown once).
func _show_toast(text: String) -> void:
	_toasts.show_message(text)
