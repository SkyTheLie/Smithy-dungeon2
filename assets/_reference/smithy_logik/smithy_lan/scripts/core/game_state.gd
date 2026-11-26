extends Node
## Global game state that survives scene changes (registered as autoload "GameState").

signal gold_changed(gold: int)
## Something was thrown away or taken back out of the trash (inventory, TrashSlot).
signal trash_changed
## The hero list or a hero changed (hired, lost, stamina back every hour, game loaded).
signal heroes_changed
## A new hero joined (hired, story). Only this shows "... schließt sich dir an!".
signal hero_hired(hero: Hero)
signal adventure_started(adventure: Adventure)
## The adventure is over; rewards are already paid on victory.
signal adventure_finished(adventure: Adventure)
## A recipe was unlocked.
signal recipes_changed
## Heat or fuel of the forge changed; `heat` = castings left in total (see get_forge_heat()).
signal forge_heat_changed(heat: int)
## The player went to bed (or fell asleep); the next day has started.
signal slept(day: int)
## Something was put into the reward chest (daily rewards, dungeon loot).
signal reward_chest_filled
## A quest was accepted or completed.
signal quests_changed
## A quest was handed in; `rewards_text` lists what the player got (hidden ones revealed).
signal quest_completed(quest: QuestData, rewards_text: String)
## The game was saved into a slot (false = writing failed).
signal game_saved(slot: int, success: bool)
## A finished piece of equipment to show big (ItemReveal in the HUD); `rarity_up` = making it raised
## its rarity. Sent by the AssemblyMenu (workbench, bow table, enchanting table).
@warning_ignore("unused_signal")
signal item_revealed(slot: InventorySlot, rarity_up: bool)
## A customer order was handed in at the order board; `rewards_text` e.g. "39 Gold, 20 EXP".
signal order_completed(order: CustomerOrder, rewards_text: String)

const REWARD_CHEST_SIZE: int = 30
const REWARD_CHEST_ROW: int = 6
const STORAGE_CHEST_SIZE: int = 30
## Where the player wakes up.
const BEDROOM_SCENE: String = "res://scenes/world/smithy/bedroom.tscn"
const BED_SPAWN_POINT: StringName = &"InBed"
## Fallback if a save points to a scene that no longer exists. Also where a new game starts.
const START_SCENE: String = "res://scenes/world/smithy/smithy.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu/main_menu.tscn"
## Shown by the story action "show_ending" (the end of the story, see Ending).
const ENDING_SCENE: String = "res://scenes/story/ending.tscn"
## Debug: true = skip the title screen and main menu, the game starts directly in the smithy.
const SKIP_TITLE_SCREEN: bool = false
## Quests (QuestData) by id: data/quests/<id>.tres.
const QUEST_DIR: String = "res://data/quests/"
## Aurelius sends the player for the compass molds (story); before that no compass mold is known.
const COMPASS_FLAG: String = "compass_dungeons_unlocked"
## Workbench recipe of the desert compass (built from the compass quest parts).
const COMPASS_RECIPE: String = "desert_compass"
## Areas outside the village: no night there (the clock stops at nightfall), and at night the
## player can't go there (doors and the teleport crystal refuse).
const WILD_SCENES: Array[String] = [
	"res://scenes/world/village/village_gate.tscn",
	"res://scenes/world/village/south_road.tscn",
	"res://scenes/world/forest/forest_entrance.tscn",
	"res://scenes/world/forest/woodcutter_hut.tscn",
	"res://scenes/world/forest/deep_forest.tscn",
	"res://scenes/world/mine/mine_entrance.tscn",
	"res://scenes/world/mine/mine.tscn",
	"res://scenes/world/mine/old_mine.tscn",
	"res://scenes/world/mine/deep_mine.tscn",
	"res://scenes/world/volcano/lava_mountain.tscn",
	"res://scenes/world/volcano/crystal_cave.tscn",
	"res://scenes/world/volcano/goblin_cave.tscn",
	"res://scenes/world/volcano/goblin_mine.tscn",
	"res://scenes/world/volcano/goblin_deep_mine.tscn",
	"res://scenes/world/volcano/goblin_castle_gate.tscn",
	"res://scenes/world/volcano/goblin_castle.tscn",
	"res://scenes/world/volcano/goblin_forge.tscn",
	"res://scenes/world/volcano/goblin_treasury.tscn",
	"res://scenes/world/desert/desert.tscn",
	"res://scenes/world/desert/sahrim_gate.tscn",
]
## Steps (doors) from each wild scene back to the village. At night the player may still walk
## towards the village (to a scene with fewer steps), so nobody gets stuck e.g. in the deep forest.
const WILD_STEPS_HOME: Dictionary = {
	"res://scenes/world/village/village_gate.tscn": 1,
	"res://scenes/world/village/south_road.tscn": 2,
	"res://scenes/world/forest/forest_entrance.tscn": 2,
	"res://scenes/world/forest/woodcutter_hut.tscn": 3,
	"res://scenes/world/forest/deep_forest.tscn": 3,
	"res://scenes/world/mine/mine_entrance.tscn": 3,
	"res://scenes/world/mine/mine.tscn": 4,
	"res://scenes/world/mine/deep_mine.tscn": 4,
	"res://scenes/world/mine/old_mine.tscn": 5,
	"res://scenes/world/desert/desert.tscn": 3,
	"res://scenes/world/desert/sahrim_gate.tscn": 4,
	"res://scenes/world/volcano/lava_mountain.tscn": 1,
	"res://scenes/world/volcano/crystal_cave.tscn": 2,
	"res://scenes/world/volcano/goblin_cave.tscn": 2,
	"res://scenes/world/volcano/goblin_mine.tscn": 3,
	"res://scenes/world/volcano/goblin_deep_mine.tscn": 4,
	"res://scenes/world/volcano/goblin_castle_gate.tscn": 5,
	"res://scenes/world/volcano/goblin_castle.tscn": 6,
	"res://scenes/world/volcano/goblin_forge.tscn": 7,
	"res://scenes/world/volcano/goblin_treasury.tscn": 7,
}
## In the volcano (Lavaberg, Goblin caves and castle) the clock stands at 18:00: there is no
## night there, else the player could be stuck between two wild scenes that are closed at night.
const VOLCANO_SCENE_DIR: String = "res://scenes/world/volcano/"
const VOLCANO_CLOCK_STOP_HOUR: float = 18.0
const NIGHT_MESSAGE: String = "Es ist Nacht. Geh nach Hause und leg dich schlafen."
const NIGHT_BLOCKED_MESSAGE: String = "Es ist Nacht, das Dorf verlässt man jetzt besser nicht."
## Seconds between two checks of the story conditions (items, equipment, quests).
const STORY_CHECK_INTERVAL: float = 0.5
## Real seconds per step when the night is caught up after sleeping (see _pass_night).
const NIGHT_STEP_SECONDS: float = 0.1
## Travelling with a fade (travel_to(..., true)): seconds to black and back, layer above the HUD.
const FADE_SECONDS: float = 0.8
const FADE_LAYER: int = 120
## Story flag from which customers come (after the first customer of the story, chapter 5).
const CUSTOMERS_FLAG: String = "regular_customers"
## Until this flag is set, the landlady collects the rent in the story (chapter 5), not by herself.
const FIRST_RENT_FLAG: String = "first_rent_paid"
## Story flag from which Nina's shop sells (see ConsignmentShop).
const SHOP_FLAG: String = "nina_shop_unlocked"

## Name of the spawn point (Marker2D in group "spawn_points") the player
## should appear at after the next scene change. Empty = keep default position.
var next_spawn_point: StringName = &""
## Exact player position after the next scene change (loading a save). Vector2.INF = none.
## Admin panel: the clock stands at this time (minutes after midnight), -1 = it runs (set_frozen_time).
var frozen_minutes: float = -1.0
## Section of user://settings.cfg for the admin panel (last tab, held clock).
const ADMIN_SECTION: String = "admin"
var next_player_position: Vector2 = Vector2.INF
## Spawn point the player walks to by himself after the next scene change (start of a new game:
## from the south edge into the village square). Empty = none.
var next_auto_walk_point: StringName = &""

var inventory: Inventory = Inventory.new()
## Last stack thrown away ("Wegschmeißen" under the bag, TrashSlot); a click takes it back until
## the next one is thrown away. Not saved.
var trash: InventorySlot = InventorySlot.new()
## The last sold stack and its price per piece (ShopDialog, buyback slot of every merchant).
var buyback: InventorySlot = InventorySlot.new()
var buyback_price: int = 0
## Admin panel: the dungeon board lists every dungeon (except the hidden story fights), whatever
## the story says. Saved with the game.
var admin_all_dungeons: bool = false
var smelter: Smelter = Smelter.new()
## More smelting places next to `smelter` (each with its own ore, fuel and output), opened by the
## smelter upgrades (house.json "smelt_slots"); get_smelters() gives the ones in use.
var extra_smelters: Array[Smelter] = []
const MAX_EXTRA_SMELTERS: int = 3
## Alloy tab of the smelter (bronze = copper + iron ingot), runs next to the normal smelting.
var alloy_smelter: AlloySmelter = AlloySmelter.new()
## Water trough (cools glowing items).
var quencher: Quencher = Quencher.new()
## true = the water trough window was closed while it cooled: the cooled stack goes into the
## inventory by itself (see _process).
var quencher_returns_when_cool: bool = false
## Things the player has to own or hand in (sets, has_items / take_items, deliver, hand-in slots,
## shopping list). The old function names further down pass on to it.
var quest_items: QuestItems = QuestItems.new()
## Skill values of the player (forging minigame etc.).
var player_stats: PlayerStats = PlayerStats.new()
## Ids of the TravelDestinations the teleport crystal offers (new places get unlocked here).
## Places known from the start (also kept when loading an older save that lacks them).
const START_DESTINATIONS: Array[StringName] = [&"home", &"mine", &"forest"]
## Stations that put parts together; their recipes come as a set with the main part (unlock_mold).
const ASSEMBLY_STATIONS: Array[StringName] = [&"workbench", &"bow_table", &"enchanting_table"]
var known_destinations: Array[StringName] = START_DESTINATIONS.duplicate()
## Money of the player (a new game starts with story.json "start.gold").
var gold: int = 700
## Hired heroes (copies of the templates in res://data/heroes/).
var heroes: Array[Hero] = []
## Running adventures (heroes in dungeons).
var adventures: Array[Adventure] = []
## Ids of unlocked recipes (recipes with unlocked_by_default are always known).
var unlocked_recipes: Array[String] = []
## The fire of the forge (heat and fuel), see ForgeFire. The three fields below are its values
## under their old names (saves, the smith tournament and tests use them).
var forge_fire: ForgeFire = ForgeFire.new()
## Castings left from the fuel piece that is already burning (wood 1, coal 5).
var forge_heat: int:
	get:
		return forge_fire.heat
	set(value):
		forge_fire.heat = value
## Parts of a casting left over when fuel was lit with the skill "Glutwächter" (e.g. coal at
## +25 % = 6.25 castings: 6 now, 0.25 carried to the next piece).
var forge_heat_carry: float:
	get:
		return forge_fire.carry
	set(value):
		forge_fire.carry = value
## Unburned fuel in the forge's heat slot; one piece is lit when forge_heat runs out.
## Can be taken back out (see take_forge_fuel).
var forge_fuel: InventorySlot:
	get:
		return forge_fire.fuel
	set(value):
		forge_fire.fuel = value
## Day and time of day.
var day_cycle: DayCycle = DayCycle.new()
## Farmable resources of today per area (rocks, trees, plants), see ResourceFields.
var resource_fields: ResourceFields = ResourceFields.new()
## Chest in the workshop (6x5, grows by rows of 6): rewards that are not handed over directly.
var reward_chest: Inventory = Inventory.new(REWARD_CHEST_SIZE)
## Chest next to the bed (6x5): the player stores items here (StorageMenu).
var storage_chest: Inventory = Inventory.new(STORAGE_CHEST_SIZE)
## Rewards put into the chest every morning: {"item": item id, "amount": int, "source": text}.
var daily_rewards: Array[Dictionary] = []
## Quest states: resource path of the QuestData -> QuestData.State. Missing = AVAILABLE.
var quest_states: Dictionary = {}
## Accepted quests in the order they were accepted (resource paths), for the quest log.
var quest_log: Array[String] = []
## Look and name of the player (character creator at "Neues Spiel").
var player_appearance: Appearance = Appearance.new()
## "" = no name chosen: shown as DEFAULT_PLAYER_NAME in the current language (get_player_name).
var player_name: String = ""
const DEFAULT_PLAYER_NAME: String = "Schmied"
## Story progress (steps, flags, tips), see Story and data/content/story.json.
var story: Story = Story.new()
## Weekly rent of the smithy (collected by the landlady), see Rent.
var rent: Rent = Rent.new()
## Customers in front of the smithy and their orders.
var customers: Customers = Customers.new()
## Nina's shop at the market: displayed things, sales and the money waiting there.
var nina_shop: ConsignmentShop = ConsignmentShop.new()
## Today's goods of every merchant with amounts (bought out = gone until tomorrow).
var merchant_stock: MerchantStock = MerchantStock.new()
## The player's house: upgrade level, own shop and furniture (house.json).
var house: House = House.new()
## Gold in the loot chest (e.g. Nina's money the player did not pick up).
var reward_chest_gold: int = 0
## Plant beds (greenhouse): what grows where, see Garden.
var garden: Garden = Garden.new()
## Hero classes the player unlocked (ClassUnlocks): class id -> day of the unlock. The guilds offer
## a class from the next day on; -1 = right away (older saves, skipped story).
var class_unlock_days: Dictionary = {}
## Best rarity (tier) of every built weapon / armor piece: "<item id>:<metal>" (e.g. "sword:iron")
## and "<metal>" (any item of it) -> tier. Customer orders go up to it (Customers.best_rarity).
var best_rarities: Dictionary = {}
## true while a save is applied (no class unlock tips for half-loaded data).
var _loading: bool = false
## Unlock popups (UnlockNotices) run once the start is done; recipes unlocked in the same frame
## are shown together.
var _notices_ready: bool = false
var _new_recipes: Array[RecipeData] = []
## true after "Hauptmenü" in a running game: nothing ticks until a new game starts
## (reset_for_new_game) or a save is loaded.
var in_main_menu: bool = false
## Gold Nina paid out last time (story text {shop_gold}).
var last_shop_payout: int = 0
## Text the HUD shows when the screen fades in after sleeping (empty = nothing to show).
var wake_up_text: String = ""
## Day summary for the wake-up screen ("Gestern" / "Heute", DayReport); "" = nothing to tell.
var wake_up_report: String = ""
## Message the HUD shows once after the next scene change (e.g. "Spielstand 1 geladen").
var pending_message: String = ""
## Day the current story step began (story.json "wait_days": the step ends that many days later).
var story_step_day: int = 1
## Gold the player gave away in the last donation (story text {donated}).
var last_donation: int = 0
## Gold paid for each handed-in story order: story tag -> gold (story text {first_order_gold}).
var story_order_gold: Dictionary = {}
## Real seconds played in this game (only while the player is in the world, not in menus
## before the game or in the intro). Shown in the save window.
var play_time: float = 0.0
## Achievements (character window): counters and levels, see Achievements.
var achievements: Achievements = Achievements.new()
## What happened today and what tomorrow holds (DayReport), shown on the wake-up screen.
var day_report: DayReport = DayReport.new()
## Search orders at the guild counter (SearchOrders): adventurers bring items after 1-2 days.
var search_orders: SearchOrders = SearchOrders.new()
## Lotte as the smith's helper: her morning errands to the market (Assistant).
var assistant: Assistant = Assistant.new()
## Masterpieces and famous weapons (Fame, tab "Ruhm" in the character window).
var fame: Fame = Fame.new()
## Steam connection for the achievements (inactive without Steam), see SteamBridge.
var steam: SteamBridge
## The smith's reputation (rank F..S+, replaces the old karma), see Reputation.
var reputation: Reputation = Reputation.new()
## The great smith tournament in Leonheim (part 3, then once a month), see SmithTournament.
var tournament: SmithTournament = SmithTournament.new()
## Kahn's hero tournament in Eisquell (part 4), see HeroTournament. Not saved.
var hero_tournament: HeroTournament = HeroTournament.new()
## League tournaments and the ranking of smith and heroes (leagues.json), see TournamentRanking.
var ranking: TournamentRanking = TournamentRanking.new()
## The maze of the desert: where the player stands, what he has seen (DesertMaze).
var desert: DesertMaze = DesertMaze.new()
## Monsters and items the player discovered (lexicon, key L).
var lexicon: Lexicon = Lexicon.new()
var _story_check_left: float = 0.0
## Last full hour (day × 24 + hour) the heroes got their stamina for (-1 = start counting now).
var _stamina_hour_key: int = -1


func _ready() -> void:
	# The player's language, graphics settings and keys (user://settings.cfg).
	Language.apply()
	if has_dev_tools():  # DEV-ONLY: the admin clock
		frozen_minutes = float(WindowLayout.get_setting(ADMIN_SECTION, "frozen_minutes", -1.0))
	DisplaySettings.apply_saved()
	KeyBindings.load_saved()
	# Nina's shop has the places of her later expansion already (unused until the story expands it).
	nina_shop.add_expansion_slots()
	player_stats.stats_changed.connect(update_inventory_size)
	item_revealed.connect(day_report.note_item)
	item_revealed.connect(fame.note_item)
	day_cycle.phase_changed.connect(_on_phase_changed)
	# Castings per heat charge: skill "Glutwächter" x workshop upgrade (house.json "heat_bonus").
	forge_fire.charge_factor = func() -> float:
		return player_stats.get_fuel_factor() * (1.0 + house.get_upgrade_value("heat_bonus") / 100.0)
	forge_fire.heat_changed.connect(func(heat: int) -> void: forge_heat_changed.emit(heat))
	story.step_started.connect(_on_story_step_started)
	for i in MAX_EXTRA_SMELTERS:
		extra_smelters.append(Smelter.new())
	for lane: Smelter in [smelter] + extra_smelters:
		lane.ingot_finished.connect(func() -> void: player_stats.add_experience(player_stats.experience_per_ingot))
		lane.ingot_finished.connect(achievements.count.bind("smelt", 1))
	alloy_smelter.ingot_finished.connect(func() -> void: player_stats.add_experience(player_stats.experience_per_ingot))
	alloy_smelter.ingot_finished.connect(achievements.count.bind("smelt", 1))
	nina_shop.item_sold.connect(func(_stack: InventorySlot, _payout: int) -> void: achievements.count("sold"))
	house.shop.item_sold.connect(func(_stack: InventorySlot, _payout: int) -> void: achievements.count("sold"))
	achievements.has_flag = story.has_flag
	# Lexicon: beaten monsters come from the kill counters, items from what lay in the bags.
	lexicon.kill_count = achievements.get_value
	for bag: Inventory in [inventory, reward_chest, storage_chest]:
		bag.changed.connect(lexicon.note_inventory.bind(bag))
	player_stats.achievement_level = achievements.get_level
	player_stats.race_of = func() -> String: return player_appearance.race
	player_stats.workshop_bonus = house.get_upgrade_value
	player_stats.has_story_flag = func(flag: String) -> bool: return story.has_flag(flag)
	smelter.speed_bonus = func() -> float: return house.get_upgrade_value("smelt_speed")
	alloy_smelter.speed_bonus = smelter.speed_bonus
	for lane in extra_smelters:
		lane.speed_bonus = smelter.speed_bonus
	# Skills "Feuerprobe" (extra ingot), "Härtekunst" (quality in the trough), "Goldene Zunge" (orders).
	for lane: Smelter in [smelter] + extra_smelters:
		lane.extra_chance = player_stats.get_smelt_extra_chance
	quencher.quality_bonus = player_stats.get_quench_quality
	customers.skill_pay_bonus = player_stats.get_order_pay_bonus
	reputation.has_flag = story.has_flag
	customers.reputation = reputation
	story.changed.connect(reputation.on_story_changed)
	nina_shop.item_sold.connect(func(stack: InventorySlot, _payout: int) -> void: reputation.add(Reputation.get_sale_points(stack)))
	house.shop.item_sold.connect(func(stack: InventorySlot, _payout: int) -> void: reputation.add(Reputation.get_sale_points(stack)))
	story.changed.connect(achievements.check)
	customers.is_recipe_unlocked = is_recipe_unlocked
	customers.best_rarity = get_best_rarity
	customers.has_flag = story.has_flag
	item_revealed.connect(func(slot: InventorySlot, _rarity_up: bool) -> void: record_best_rarity(slot))
	recipes_changed.connect(_check_class_unlocks)
	story.changed.connect(_check_class_unlocks)
	nina_shop.item_sold.connect(_on_shop_item_sold)
	house.shop.item_sold.connect(_on_own_shop_item_sold)
	if SKIP_TITLE_SCREEN:
		_complete_story()
	else:
		start_new_game()
	# Customers of the first day (later days: _start_new_day); only once the order board is unlocked.
	customers.start_day(day_cycle.day, story.has_flag(CUSTOMERS_FLAG), _knight_comes())
	# What the start already reached (e.g. a skipped story) is not announced.
	achievements.mark_known()
	reputation.check_story()
	reputation.mark_known()
	# Reports the achievements to Steam (does nothing without the GodotSteam plugin).
	steam = SteamBridge.new()
	steam.name = Language.translate("SteamBridge")
	add_child(steam)
	steam.setup(achievements)
	# Classes of the start (e.g. a skipped story) are there right away, without a tip.
	_check_class_unlocks(false)
	# What the start unlocked already gets no popup; from now on new things do.
	UnlockNotices.mark_known()
	_notices_ready = true
	story.changed.connect(_check_unlock_notices)


## Popups for stations and furniture that became available (UnlockNotices), not while loading or
## in the main menu.
func _check_unlock_notices() -> void:
	if _notices_ready and not _loading and not in_main_menu:
		UnlockNotices.check(true)


func _announce_new_recipes() -> void:
	var recipes: Array[RecipeData] = _new_recipes
	_new_recipes = []
	UnlockNotices.announce_recipes(recipes)


## Remembers newly unlocked hero classes (a weapon they may carry can be made now, ClassUnlocks)
## and, with `announce`, shows a tip about them; the guilds offer them from the next day on.
## Test tools (admin panel on P, free house levels at the builder) only when the game runs from
## the editor, never in an exported game for testers.
func has_dev_tools() -> bool:
	return DevTools.enabled()


## Admin panel, tab "Zeit": holds the clock at this time (minutes after midnight) for good, also
## after a restart (user://settings.cfg); -1 = the clock runs. Sleeping still starts a new day.
func set_frozen_time(minutes: float) -> void:
	frozen_minutes = minutes
	if minutes >= 0.0:
		day_cycle.set_minutes(minutes)
	WindowLayout.set_setting(ADMIN_SECTION, "frozen_minutes", minutes)


func _check_class_unlocks(announce: bool = true) -> void:
	# Recipes known only for a tournament round unlock nothing.
	if _loading or tournament.is_active():
		return
	for class_id in ClassUnlocks.get_unlocked_class_ids():
		if class_unlock_days.has(class_id):
			continue
		class_unlock_days[class_id] = day_cycle.day if announce else -1
		if announce:
			var hero_class: HeroClass = HeroClass.load_class(class_id)
			story.show_custom_hint("class_" + class_id, Language.translate("Neue Heldenklasse: ") + hero_class.display_name,
					ClassUnlocks.get_unlock_text(class_id), "")


func _process(delta: float) -> void:
	if in_main_menu:
		return
	if get_tree().get_first_node_in_group(Player.GROUP):
		play_time += delta
	_tick_workshop(delta)
	tournament.tick(delta)
	if frozen_minutes >= 0.0:
		day_cycle.set_minutes(frozen_minutes)
	else:
		day_cycle.tick(delta, _get_time_limit())
	customers.tick(day_cycle.minutes)
	if story.has_flag(SHOP_FLAG):
		nina_shop.tick(day_cycle.day, day_cycle.minutes, reputation.get_price_bonus())
	if house.shop.active_slots > 0:
		house.shop.tick(day_cycle.day, day_cycle.minutes, reputation.get_price_bonus())
	_restore_stamina_by_the_hour()
	_story_check_left -= delta
	# LAN guest (prototype): the story runs at the host only, the guest plays on a copy.
	if _story_check_left <= 0.0 and not Net.is_guest():
		_story_check_left = STORY_CHECK_INTERVAL
		_check_story_conditions()
	_tick_adventures(delta)


## The smelting places in use: `smelter` and as many extra ones as the smelter upgrades give
## (house.json "smelt_slots", 1 per level: 1 to 4 places).
func get_smelters() -> Array[Smelter]:
	var lanes: Array[Smelter] = [smelter]
	var extra: int = clampi(int(house.get_upgrade_value("smelt_slots")), 0, extra_smelters.size())
	lanes.append_array(extra_smelters.slice(0, extra))
	return lanes


func get_extra_smelters_save_data() -> Array:
	return extra_smelters.map(func(lane: Smelter) -> Dictionary: return lane.to_save_data())


## Old saves have none: the extra places start empty.
func load_extra_smelters(data: Array) -> void:
	for i in extra_smelters.size():
		extra_smelters[i].load_save_data(data[i] if i < data.size() else {})


## Ticked here (not in the smelter scene) so smelting continues in every scene.
func _tick_workshop(delta: float) -> void:
	smelter.tick(delta)
	# every extra place smelts on, also one closed again (nothing is lost)
	for lane in extra_smelters:
		lane.tick(delta)
	alloy_smelter.tick(delta)
	quencher.tick(delta)
	if quencher_returns_when_cool and not quencher.is_cooling():
		quencher_returns_when_cool = false
		quencher.take_into(inventory)


## Same for adventures (duplicate: finished ones remove themselves while iterating).
func _tick_adventures(delta: float) -> void:
	for adventure in adventures.duplicate():
		adventure.tick(delta)


## Sleeping skips the night: smelters, water trough and adventures catch up on the real seconds
## from now until the next morning, in small steps so fights run as usual. Stops early once
## nothing runs any more (an idle tick changes nothing; a whole night is over 8000 steps).
func _pass_night() -> void:
	var night_minutes: float = (24.0 + DayCycle.DAY_START_HOUR) * 60.0 - day_cycle.minutes
	var left: float = maxf(night_minutes, 0.0) * DayCycle.REAL_SECONDS_PER_MINUTE
	while left > 0.0 and _is_anything_running():
		var step: float = minf(left, NIGHT_STEP_SECONDS)
		left -= step
		_tick_workshop(step)
		_tick_adventures(step)


## true while a smelter smelts, the trough cools or an adventure fights (what _pass_night ticks).
func _is_anything_running() -> bool:
	if smelter.is_smelting() or alloy_smelter.is_smelting() or quencher.is_cooling() or quencher_returns_when_cool:
		return true
	if extra_smelters.any(func(lane: Smelter) -> bool: return lane.is_smelting()):
		return true
	return adventures.any(func(adventure: Adventure) -> bool: return adventure.state == Adventure.State.RUNNING)


## Loads another scene and places the player at the given spawn point there. With `fade` the
## screen goes black first and lights up again in the new scene (e.g. a carriage ride).
func travel_to(scene_path: String, spawn_point: StringName, fade: bool = false) -> void:
	next_spawn_point = spawn_point
	if fade:
		_travel_with_fade(scene_path)
		return
	# Deferred, because the scene must not be swapped during a physics or input callback.
	get_tree().change_scene_to_file.call_deferred(scene_path)


func _travel_with_fade(scene_path: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = FADE_LAYER
	var curtain := ColorRect.new()
	curtain.color = Color(0, 0, 0, 0)
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(curtain)
	add_child(layer)
	var fade_out: Tween = create_tween()
	fade_out.tween_property(curtain, "color:a", 1.0, FADE_SECONDS)
	await fade_out.finished
	get_tree().change_scene_to_file.call_deferred(scene_path)
	await get_tree().create_timer(FADE_SECONDS, false).timeout
	var fade_in: Tween = create_tween()
	fade_in.tween_property(curtain, "color:a", 0.0, FADE_SECONDS)
	await fade_in.finished
	layer.queue_free()


## Story action "cutscene:fade": the screen goes black for a moment and lights up again (time
## passes in a conversation, e.g. the long talk with the elder of the elves).
func fade_blink() -> void:
	var layer := CanvasLayer.new()
	layer.layer = FADE_LAYER
	var curtain := ColorRect.new()
	curtain.color = Color(0, 0, 0, 0)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(curtain)
	add_child(layer)
	var tween: Tween = create_tween()
	tween.tween_property(curtain, "color:a", 1.0, FADE_SECONDS)
	tween.tween_interval(FADE_SECONDS)
	tween.tween_property(curtain, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(layer.queue_free)


## Ends the day and starts the next morning. The HUD fades in with `wake_up_text`. `bed_scene` and
## `bed_spawn`: where the autosave of this night wakes up (the own bed, or e.g. the inn in Leonheim).
## `announce` = false: no `slept` signal (the player changes the scene right after, story "sleep_at").
func sleep(bed_scene: String = BEDROOM_SCENE, bed_spawn: StringName = BED_SPAWN_POINT, announce: bool = true) -> void:
	# LAN: the host decides when the night comes; the guest sleeps along with him (Net).
	if not Net.may_sleep():
		show_message(Language.translate("Schlafen entscheidet der Host."))
		return
	var yesterday: Array[String] = day_report.get_summary_lines(achievements)
	_pass_night()
	var news: String = _start_new_day()
	news += _apply_overnight_flags()
	wake_up_text = GameCalendar.get_long_text(day_cycle.day) + news
	day_report.start(achievements)
	wake_up_report = _format_day_report(yesterday, DayReport.get_preview_lines(self, day_cycle.day))
	story_event("sleep")
	# E.g. a house level built over night lets the furniture trader offer more.
	_check_unlock_notices()
	_autosave_in_bed(bed_scene, bed_spawn)
	if announce:
		slept.emit(day_cycle.day)


## Lets `days` days pass at once (e.g. a carriage ride, Carriage): every night like sleeping
## (smelters and adventures catch up, the morning brings rent, customers, the reward chest and the
## overnight story flags), but no story event "sleep" and no autosave. Then the clock stands at
## `arrival_hour`. Returns the news of those mornings (lines for the morning screen).
func pass_days(days: int, arrival_hour: float) -> String:
	var news: String = ""
	for i in days:
		_pass_night()
		news += _start_new_day()
		news += _apply_overnight_flags()
	day_report.start(achievements)
	day_cycle.advance_to_hour(arrival_hour)
	_check_unlock_notices()
	return news


## "Gestern:" and "Heute:" with one line each ("" if both are empty).
func _format_day_report(yesterday: Array[String], today: Array[String]) -> String:
	var parts: Array[String] = []
	for section: Array in [[Language.translate("Gestern:"), yesterday], [Language.translate("Heute:"), today]]:
		var lines: Array[String] = []
		lines.assign(section[1])
		if lines.is_empty():
			continue
		var text: String = section[0]
		for line in lines:
			text += "\n· " + line
		parts.append(text)
	return "\n\n".join(parts)


# --- Time and areas ---------------------------------------------------------------------

## Whether the teleporter of this spot / destination id (e.g. "home", "leonheim") was created
## (Teleporter, story flag "teleporter_<id>_built"). The teleport menu only lists built ones.
func is_teleporter_built(spot_id: String) -> bool:
	return story.has_flag("teleporter_%s_built" % spot_id)


func build_teleporter(spot_id: String) -> void:
	story.set_flag("teleporter_%s_built" % spot_id)


## true while the story holds the clock back (story.json "start.clock_stops_until": until this
## flag is set, e.g. the first day doesn't end before Holger has his axe, so night can't block the way).
## The clock runs until "start.clock_stops_at_hour" (e.g. 18:00) and stands there.
func is_clock_stopped_by_story() -> bool:
	var until: String = str(Story.get_data("start").get("clock_stops_until", ""))
	return not until.is_empty() and story.is_running() and not story.has_flag(until)


## Latest time (minutes after midnight) the story lets the clock reach now; the day end otherwise.
func _get_story_time_limit() -> float:
	if not is_clock_stopped_by_story():
		return DayCycle.DAY_END_HOUR * 60.0
	return float(Story.get_data("start").get("clock_stops_at_hour", DayCycle.DAY_START_HOUR)) * 60.0


func is_wild_scene(scene_path: String) -> bool:
	return WILD_SCENES.has(scene_path)


## true if the player may not go to this scene now (outside the village at night).
## `from_scene` = where the player is: from a wild scene the way back towards the village
## (fewer steps home, see WILD_STEPS_HOME) stays open at night.
func is_blocked_at_night(scene_path: String, from_scene: String = "") -> bool:
	if not day_cycle.is_night() or not is_wild_scene(scene_path):
		return false
	if is_wild_scene(from_scene):
		return get_steps_home(scene_path) >= get_steps_home(from_scene)
	return true


## Doors from this wild scene back to the village (0 = in the village, unknown = far away).
func get_steps_home(scene_path: String) -> int:
	if not is_wild_scene(scene_path):
		return 0
	return int(WILD_STEPS_HOME.get(scene_path, 99))


## Outside the village the clock stops at nightfall; on the first day the story holds it at
## "clock_stops_at_hour" (see is_clock_stopped_by_story).
func _get_time_limit() -> float:
	var limit: float = _get_story_time_limit()
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	if scene and scene.scene_file_path.begins_with(VOLCANO_SCENE_DIR):
		return minf(limit, VOLCANO_CLOCK_STOP_HOUR * 60.0)
	if scene and is_wild_scene(scene.scene_file_path):
		return minf(limit, DayCycle.PHASE_START_HOURS[DayCycle.Phase.NIGHT] * 60.0)
	return minf(limit, DayCycle.DAY_END_HOUR * 60.0)


func _on_phase_changed(phase: DayCycle.Phase) -> void:
	if phase == DayCycle.Phase.NIGHT:
		show_message(Language.translate(NIGHT_MESSAGE))


## The player entered a scene (called by Player): story event "enter:<file name>".
func on_scene_entered(scene_path: String) -> void:
	story_event("enter:" + scene_path.get_file().get_basename())


## Next morning: new day, then the daily rewards go into the chest and the customers of the
## new day are rolled. Returns extra lines for the wake-up text (expired orders).
func _start_new_day() -> String:
	day_cycle.start_next_day()
	# The night: greenhouse decoration helps the plants near it (house.json furniture "garden").
	garden.night(house.placed, day_cycle.day)
	# The night: every hero rests (combat.json "hero_stamina_per_night").
	for hero in heroes:
		hero.change_stamina(ContentDB.combat_value("hero_stamina_per_night", 30.0))
	_stamina_hour_key = _get_hour_key()
	var news: String = _collect_rent()
	if house.finish_upgrade():
		news += Language.translate("\nDer Baumeister ist fertig: %s steht.") % house.get_level_name()
	for order in customers.start_day(day_cycle.day, story.has_flag(CUSTOMERS_FLAG), _knight_comes()):
		news += Language.translate("\nAuftrag von %s abgelaufen: %s (Ruf %+d)") % [order.customer_name, order.get_title(),
				Reputation.get_gain("order_expired")]
	if story.has_flag(CUSTOMERS_FLAG):
		for line in customers.take_praise(day_cycle.day):
			news += "\n" + line
	if nina_shop.pending_gold > 0:
		var shop_gold: int = nina_shop.collect()
		put_gold_into_reward_chest(shop_gold)
		news += Language.translate("\nNina hat %d Gold aus ihrem Laden in die Loot-Kiste gelegt.") % shop_gold
	if house.shop.pending_gold > 0:
		var own_gold: int = house.shop.collect()
		put_gold_into_reward_chest(own_gold)
		news += Language.translate("\nDie Einnahmen deines Ladens (%d Gold) liegen in der Loot-Kiste.") % own_gold
	for reward in daily_rewards:
		var item_id: String = reward.get("item", "")
		if ContentDB.has_item(item_id):
			var item: ItemData = ContentDB.item(item_id)
			put_into_reward_chest(item, int(reward.get("amount", 1)))
	# story.json "daily_rewards": gifts that depend on story flags (e.g. Gustav's coal).
	for reward: Dictionary in story.get_data("daily_rewards"):
		var flag: String = reward.get("flag", "")
		var until: String = reward.get("until", "")
		var reward_item: String = reward.get("item", "")
		if (flag.is_empty() or story.has_flag(flag)) and (until.is_empty() or not story.has_flag(until)) 				and ContentDB.has_item(reward_item):
			put_into_reward_chest(ContentDB.item(reward_item), int(reward.get("amount", 1)))
	news += ranking.on_new_day(day_cycle.day)
	var hall_reputation: int = house.get_hall_reputation()
	if hall_reputation > 0:
		reputation.add(hall_reputation)
		news += Language.translate("\nBesucher bestaunen deine Pokale in der Ruhmeshalle: +%d Ruf.") % hall_reputation
	for order in search_orders.take_due(day_cycle.day):
		var item_id: String = str(order["item"])
		if ContentDB.has_item(item_id):
			put_into_reward_chest(ContentDB.item(item_id), int(order["amount"]), int(order["rarity"]))
			news += "\n" + Language.translate("Die Abenteurer haben gefunden, was du gesucht hast: %s. Es liegt in der Loot-Kiste.") % SearchOrders.describe(order)
	news += assistant.on_new_day()
	return news


## story.json "overnight": things that happen during the night, [{"if": [flags], "set": flag,
## "text": wake-up line}] (e.g. Gustav clears the old tunnel once the player brought everything).
## Returns the lines for the wake-up text.
func _apply_overnight_flags() -> String:
	var news: String = ""
	for entry: Dictionary in story.get_data("overnight"):
		var flag: String = entry.get("set", "")
		var needed: Array = entry.get("if", [])
		if flag.is_empty() or story.flags.has(flag) or not needed.all(func(other: String) -> bool: return story.flags.has(other)):
			continue
		story.set_flag(flag)
		story.show_hint(str(entry.get("hint", "")))
		if not str(entry.get("text", "")).is_empty():
			news += "\n" + format_story_text(entry["text"])
	return news


## Morning: the landlady takes the rent when it is due. Returns a line for the wake-up text.
## The first rent is a story scene (chapter 5): she comes in person (story event "rent_due"; flag
## "first_rent_due" = it is really due, not paid early because the player had the gold).
func _collect_rent() -> String:
	if not rent.is_due(day_cycle.day):
		return ""
	if story.is_running() and not story.has_flag(FIRST_RENT_FLAG):
		story.set_flag("first_rent_due")
		story_event("rent_due")
		return ""
	if spend_gold(rent.get_amount()):
		rent.paid()
		return Language.translate("{0}{1} hat die Miete kassiert: {2} Gold.").format(["\n", rent.get_landlady(), rent.get_amount()])
	reputation.add_gain("rent_late")
	return Language.translate("{0}Die Miete ({1} Gold) ist fällig, aber du hast nicht genug Gold!{0}{2} ist verärgert (Ruf {3}).").format(
			["\n", rent.get_amount(), rent.get_landlady(), Reputation.get_gain("rent_late")])


# --- Story ------------------------------------------------------------------------

## Beginning of a new game (character creator): story from the start, start gold.
func start_new_game() -> void:
	class_unlock_days.clear()
	best_rarities.clear()
	story.start_new()
	play_time = 0.0
	gold = int(story.get_data("start").get("gold", 700))
	gold_changed.emit(gold)


## Leaves the running game for the main menu (not saved). Nothing ticks there; "Neues Spiel"
## resets everything (reset_for_new_game), "Laden" loads over it.
func return_to_main_menu() -> void:
	in_main_menu = true
	MainMenu.skip_title_page = true
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)


## Everything back to the start of a new game (after returning to the main menu): like loading
## an empty save, then the story starts again.
func reset_for_new_game() -> void:
	_loading = true
	_apply_save_data({"story": {"step": ""}, "recipes_locked": true})
	_loading = false
	start_new_game()
	customers.start_day(day_cycle.day, story.has_flag(CUSTOMERS_FLAG), _knight_comes())
	achievements.mark_known()
	UnlockNotices.mark_known()
	in_main_menu = false


## Scene and spawn point where a new game begins (after the intro), and the spawn point the
## player appears at first and walks in from ("walk_in_from", empty = appears at the spawn).
func get_story_start() -> Array:
	var start: Dictionary = story.get_data("start")
	return [str(start.get("scene", START_SCENE)), StringName(start.get("spawn", "")),
			StringName(start.get("walk_in_from", ""))]


## Fills the placeholders of story texts: {name}, {rent}, {rent_day} (date of the next rent),
## {gold}, {donated}, {shop_gold} (what Nina paid out last), {weekday} (today, e.g. "Montag"),
## {errand_report} (what Lotte brought from the market, Assistant.get_report), {first_order_gold}
## (what Ulrich paid for the first sword); keys: KeyBindings.fill.
func format_story_text(text: String) -> String:
	var values: Dictionary = {"name": get_player_name(), "rent": rent.get_amount(), "rent_day": GameCalendar.get_short_text(rent.due_day),
			"gold": gold, "donated": last_donation, "shop_gold": last_shop_payout,
			"weekday": GameCalendar.get_weekday_name(day_cycle.day),
			"first_order_gold": get_story_order_gold("first_customer")}
	if "{errand_report}" in text:
		values["errand_report"] = assistant.get_report()
	return KeyBindings.fill(text).format(values)


## Something happened that a story step may wait for (story.json "events": event -> next step),
## e.g. "sleep", "enter:guild_hall", "adventure_started", "adventure_won", "adventure_lost".
func story_event(event: String) -> void:
	var next: String = story.get_step().get("events", {}).get(event, "")
	if not next.is_empty():
		story.advance(next)


## A new story step began: its "on_start" actions run.
func _on_story_step_started(_step: String) -> void:
	story_step_day = day_cycle.day
	run_story_action(story.get_step().get("on_start", ""))


## Skip the story (debug start, saves from before the story): all flags and recipes it unlocks.
func _complete_story() -> void:
	story.complete_all()
	_unlock_recipe_ids(Story.get_data("skip_recipes"))
	_unlock_recipe_ids(Story.get_data("legacy_recipes"))


func _unlock_recipe_ids(recipe_ids: Array) -> void:
	for recipe_id: String in recipe_ids:
		if ContentDB.has_recipe(recipe_id):
			unlock_recipe(ContentDB.recipe(recipe_id))


## Sets bought before they got new molds (e.g. handles, bows): what was added since comes for free.
func _complete_bought_sets() -> void:
	var offers: Dictionary = ContentDB.economy("recipes")
	for offer_id: String in offers:
		if story.has_flag("bought_recipe_" + offer_id):
			_unlock_recipe_ids(offers[offer_id].get("unlock", []))


## Story steps that end when something is true (checked twice a second):
## "quest_ready": the item for the quest is in the inventory; "quest_done": the quest is handed
## in; "have_item": a stack like "sword:copper_blade+copper_handle" is in the inventory;
## "hero_armed": this hero has a weapon in his right hand; "hero_level": a hero has at least
## this level; "shopping_done": every entry of its "shopping" list is done (get_shopping_list);
## "have_gold": the player has at least this much gold (placeholders allowed, e.g. "{rent}").
## Running side tasks are checked here too.
func _check_story_conditions() -> void:
	assistant.tick()
	LotteCourier.check(get_tree())
	_run_item_actions()
	_check_side_tasks()
	if nina_shop.total_sales >= int(ConsignmentShop.setting("expansion_sales", 2000)):
		story.set_flag("nina_expansion_ready")
	var data: Dictionary = story.get_step()
	if not story.is_running() or not data.has("next"):
		return
	var done: bool = false
	if data.has("quest_ready"):
		var quest := SaveSystem.load_resource(QUEST_DIR + str(data["quest_ready"]) + ".tres") as QuestData
		done = quest != null and can_complete_quest(quest)
	elif data.has("quest_done"):
		var quest := SaveSystem.load_resource(QUEST_DIR + str(data["quest_done"]) + ".tres") as QuestData
		done = quest != null and get_quest_state(quest) == QuestData.State.COMPLETED
	elif data.has("have_item"):
		done = quest_items.has_stack_like(str(data["have_item"]))
	elif data.has("hero_armed"):
		for hero in heroes:
			if String(hero.id) == str(data["hero_armed"]) and hero.get_weapon() != null:
				done = true
	elif data.has("shop_display"):
		done = _shop_displays(str(data["shop_display"]))
	elif data.has("shop_sold"):
		done = nina_shop.sold_count >= int(data["shop_sold"])
	elif data.has("shop_goal"):
		var goal: Dictionary = _parse_shop_goal(str(data["shop_goal"]))
		done = int(nina_shop.sold_items.get(goal["item"], 0)) >= goal["amount"]
	elif data.has("hero_level"):
		done = heroes.any(func(hero: Hero) -> bool: return hero.level >= int(data["hero_level"]))
	elif data.has("have_gold"):
		done = gold >= int(format_story_text(str(data["have_gold"])))
	elif data.has("wait_days"):
		done = day_cycle.day >= story_step_day + int(data["wait_days"])
	elif data.get("shopping_done", false):
		done = get_shopping_list(data).all(func(entry: Dictionary) -> bool: return entry["done"])
	if done:
		story.advance(data["next"])


## Side tasks (story.json "side_tasks") with "set_items": once the player owns the whole set,
## the "complete_flag" is set and the "on_complete" actions run (e.g. a tip to show the set to
## someone, whose dialogue then sets the "done_flag").
## "check": "nina_dummy" = done once Nina's armor dummy wears a piece on every place.
func _check_side_tasks() -> void:
	for task in story.get_side_tasks():
		var complete_flag: String = task.get("complete_flag", task.get("done_flag", ""))
		if story.flags.has(complete_flag):
			continue
		var complete: bool = false
		if task.get("hand_in", false):
			# Done by hand_in_set() (the pieces are handed to someone), not by owning them.
			continue
		if task.has("set_items"):
			complete = get_set_progress(task).all(func(entry: Dictionary) -> bool: return entry["have"])
		elif task.get("check", "") == "nina_dummy":
			complete = nina_shop.is_dummy_full()
		if complete:
			story.set_flag(complete_flag)
			run_story_action(task.get("on_complete", ""))


# --- Things to own or hand in (QuestItems) under their old names -------------------------

func get_set_progress(task: Dictionary) -> Array[Dictionary]:
	return quest_items.get_set_progress(task)


func hand_in_set(task_id: String) -> bool:
	return quest_items.hand_in_set(task_id)


func is_like(slot: InventorySlot, wanted: InventorySlot) -> bool:
	return quest_items.is_like(slot, wanted)


func has_items(specs: String) -> bool:
	return quest_items.has_items(specs)


func get_item_progress(specs: String, task_id: String = "") -> Array[Dictionary]:
	return quest_items.get_item_progress(specs, task_id)


func get_todo_progress(task: Dictionary) -> Array[Dictionary]:
	return quest_items.get_todo_progress(task)


func take_items(specs: String) -> bool:
	return quest_items.take_items(specs)


func deliver(task_id: String) -> bool:
	return quest_items.deliver(task_id)


func deliver_gold(task_id: String) -> bool:
	return quest_items.deliver_gold(task_id)


func get_gold_progress(task_id: String) -> Array[int]:
	return quest_items.get_gold_progress(task_id)


func get_hand_in_requests(actions: String) -> Array[Dictionary]:
	return quest_items.get_hand_in_requests(actions)


func get_set_piece_icon(task: Dictionary, type_key: String) -> Texture2D:
	return quest_items.get_set_piece_icon(task, type_key)


func get_quest_hand_in(quest: QuestData) -> Array[Dictionary]:
	return quest_items.get_quest_hand_in(quest)


func run_with_hand_in(stacks: Array[InventorySlot], action: Callable) -> bool:
	return quest_items.run_with_hand_in(stacks, action)



## Story condition "shop_goal": "sword*3" -> {"item": "sword", "amount": 3}.
static func _parse_shop_goal(spec: String) -> Dictionary:
	return {"item": spec.get_slice("*", 0), "amount": int(spec.get_slice("*", 1)) if "*" in spec else 1}


## The current story task for the quest log (Story.get_objective) plus what only GameState knows:
## with "shop_goal" "done"/"total" = pieces Nina sold, "status" = how many lie on display.
func get_story_objective() -> Dictionary:
	var objective: Dictionary = story.get_objective()
	var data: Dictionary = story.get_step()
	objective["shopping"] = get_shopping_list(data)
	objective["extra_goals"] = get_extra_goals(data)
	# A quest the story hands in (quest_ready / quest_done): its item as goal of the story task.
	var quest: QuestData = get_story_step_quest(data)
	if quest and get_quest_state(quest) != QuestData.State.COMPLETED:
		objective["quest_goal"] = {"name": quest.requirement_name, "need": quest.required_amount,
				"have": mini(count_quest_items(quest), quest.required_amount)}
	if data.has("shop_goal"):
		var goal: Dictionary = _parse_shop_goal(str(data["shop_goal"]))
		objective["done"] = mini(int(nina_shop.sold_items.get(goal["item"], 0)), goal["amount"])
		objective["total"] = goal["amount"]
		objective["status"] = Language.translate("Verkauft: %d/%d · Gerade ausgestellt: %d") % [objective["done"], goal["amount"],
				nina_shop.count_displayed(goal["item"])]
	return objective



func get_extra_goals(step_data: Dictionary) -> Array[Dictionary]:
	return quest_items.get_extra_goals(step_data)


func get_shopping_list(step_data: Dictionary) -> Array[Dictionary]:
	return quest_items.get_shopping_list(step_data)


func is_shopping_entry_done(entry: Dictionary) -> bool:
	return quest_items.is_shopping_entry_done(entry)



## The quest a story step hands in ("quest_ready" / "quest_done"), null if none.
func get_story_step_quest(step_data: Dictionary) -> QuestData:
	var quest_id: String = str(step_data.get("quest_ready", step_data.get("quest_done", "")))
	if quest_id.is_empty():
		return null
	return SaveSystem.load_resource(QUEST_DIR + quest_id + ".tres") as QuestData


## true if the story handles this quest (a step has it as "quest_ready" / "quest_done"): it is part
## of the story task and not listed again as a quest of its own (quest log, tracker).
func is_story_quest(quest: QuestData) -> bool:
	var quest_id: String = quest.resource_path.get_file().get_basename()
	for step_data: Dictionary in (story.get_data("steps") as Dictionary).values():
		if str(step_data.get("quest_ready", "")) == quest_id or str(step_data.get("quest_done", "")) == quest_id:
			return true
	return false

## Story condition "shop_display": e.g. "sword*2:R1,sword*1:R2" = Nina's shop shows two swords
## of rarity R1 or better and one of R2 or better (each displayed piece counts once).
func _shop_displays(requirements: String) -> bool:
	var wanted: Array[Dictionary] = []
	for requirement in requirements.split(",", false):
		var head: String = requirement.get_slice(":", 0)
		var rarity: int = int(requirement.get_slice(":", 1).trim_prefix("R")) - 1
		var amount: int = int(head.get_slice("*", 1)) if "*" in head else 1
		for i in amount:
			wanted.append({"item": head.get_slice("*", 0), "rarity": rarity})
	# Hardest first, so a rare piece is not used up for an easy requirement.
	wanted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rarity"] > b["rarity"])
	var free: Array[InventorySlot] = []
	for slot in nina_shop.slots:
		if not slot.is_empty():
			free.append(slot)
	for need in wanted:
		var best: InventorySlot = null
		for slot in free:
			if String(slot.item.id) == need["item"] and slot.rarity >= need["rarity"] \
					and (best == null or slot.rarity < best.rarity):
				best = slot
		if best == null:
			return false
		free.erase(best)
	return true


func _on_shop_item_sold(stack: InventorySlot, payout: int) -> void:
	show_message(Language.translate("Nina hat %s verkauft: %d Gold liegen bei ihr bereit.") % [stack.get_display_name(), payout])
	if nina_shop.total_sales >= int(ConsignmentShop.setting("calendar_gift_sales", 200)):
		story.set_flag("nina_calendar_ready")


func _on_own_shop_item_sold(stack: InventorySlot, payout: int) -> void:
	show_message(Language.translate("Dein Laden hat %s verkauft: %d Gold in der Kasse.") % [stack.get_display_name(), payout])


## Gold the player got for the story order of figure `tag`. Saves from before it was kept: what
## Ulrich's sword pays without bonuses (a solid copper sword).
func get_story_order_gold(tag: String) -> int:
	if story_order_gold.has(tag):
		return int(story_order_gold[tag])
	var sword: InventorySlot = ContentDB.make_stack("sword:copper_blade+copper_handle")
	if sword == null:
		return 0
	var steps: int = maxi(0, Rarity.Tier.STURDY - Crafting.get_base_rarity(sword.item, sword.components))
	return Economy.get_order_gold(sword.components, steps, 0.0)


## Notes for one day of the calendar: rent, order deadlines, the traveller. Empty = nothing.
func get_calendar_notes(day: int) -> Array[String]:
	var notes: Array[String] = []
	var today: int = day_cycle.day
	var rent_days: int = int(ContentDB.economy("rent").get("days", 7))
	if rent.active and day >= today and day >= rent.due_day and (day - rent.due_day) % rent_days == 0:
		notes.append(Language.translate("Miete: %d Gold (%s)") % [rent.get_amount(), rent.get_landlady()])
	for order in customers.orders:
		if order.deadline_day == day:
			notes.append(Language.translate("Frist: %s für %s") % [order.get_item_name(), order.customer_name])
	if day >= today and is_traveler_day(day):
		notes.append(Language.translate("%s auf dem Markt") % ContentDB.economy("traveler").get("name", Language.translate("Reisender")))
	# The builder (npcs.json "builder.visits", e.g. Tuesday and Thursday).
	var visits: NpcInfo.Visits = ContentDB.npc_info("builder").visits
	if day >= today and visits and story.has_flag(visits.flag) and visits.weekdays.has(GameCalendar.get_weekday(day)):
		notes.append(Language.translate("%s auf dem Markt") % story.get_npc_name("builder"))
	if GameCalendar.is_full_moon(day):
		notes.append(Language.translate("Vollmond"))
	return notes


## The travelling merchant is on the market on this day (economy.json "traveler.weekday").
func is_traveler_day(day: int) -> bool:
	return GameCalendar.get_weekday(day) == int(ContentDB.economy("traveler").get("weekday", 6))


## The shop behind an id: "nina" = Nina's shop at the market, "house" = the player's own shop.
func get_consignment_shop(id: String) -> ConsignmentShop:
	return house.shop if id == "house" else nina_shop


## Story action "collect_shop_gold": Nina pays out. false = nothing was sold.
func collect_shop_gold() -> bool:
	last_shop_payout = nina_shop.collect()
	if last_shop_payout <= 0:
		return false
	add_gold(last_shop_payout)
	return true


func put_gold_into_reward_chest(amount: int) -> void:
	reward_chest_gold += amount
	reward_chest_filled.emit()


## Takes the gold out of the loot chest.
func take_reward_chest_gold() -> void:
	if reward_chest_gold <= 0:
		return
	add_gold(reward_chest_gold)
	reward_chest_gold = 0
	reward_chest_filled.emit()


## Something was bought from a merchant (offer spec, e.g. "copper_ingot", "recipe:copper_blade",
## "station:water_trough"): sets the story flag "bought_<spec with _ instead of :>" and the
## ones from story.json "purchase_flags", and shows the tip from "purchase_hints".
func record_purchase(spec: String) -> void:
	story.set_flag("bought_" + spec.replace(":", "_"))
	var flag: String = story.get_data("purchase_flags").get(spec, "")
	if not flag.is_empty():
		story.set_flag(flag)
	var hint_id: String = story.get_data("purchase_hints").get(spec, "")
	if not hint_id.is_empty():
		story.show_hint(hint_id)


## Runs the actions of a story dialogue, a story step or a side task (story.json "on_end",
## "choices.action", "on_start", "on_complete"), several are separated by ";". What each action
## does: StoryActions. Returns false if an action could not be done (e.g. not enough gold).
func run_story_action(actions: String) -> bool:
	return StoryActions.run(actions)


func rob_player() -> void:
	StoryActions.rob_player()


func lose_hero(hero_id: StringName) -> void:
	StoryActions.lose_hero(hero_id)



## The player's name for display; the default name in the current language if none was chosen.
func get_player_name() -> String:
	return player_name if not player_name.is_empty() else Language.translate(DEFAULT_PLAYER_NAME)


## Shows a short message in the HUD (no HUD right now, e.g. during a scene change: after the next
## scene change).
func show_message(text: String) -> void:
	if Events.message_requested.get_connections().is_empty():
		pending_message = text
		return
	Events.message_requested.emit(text)


## Throws the whole stack of an inventory slot away (into the trash, the old trash is gone).
func throw_away(inventory_index: int) -> void:
	var stack: InventorySlot = inventory.slots[inventory_index]
	if stack.is_empty():
		return
	if stack.item.story_item:
		show_message(Language.translate("Das brauchst du noch."))
		return
	trash = stack.copy_with_amount(stack.amount)
	inventory.remove_from_slot(inventory_index, stack.amount)
	trash_changed.emit()


## The last thrown stack back into the inventory (as much as fits).
func take_back_trash() -> void:
	if trash.is_empty():
		return
	var left: int = inventory.add_stack(trash)
	if left > 0:
		trash.amount = left
		show_message(Language.translate("Kein Platz im Inventar."))
	else:
		trash = InventorySlot.new()
	trash_changed.emit()


## Slots of the player's inventory with this backpack (null = none): hotbar + bag + its places.
func get_inventory_size(backpack: InventorySlot) -> int:
	return Inventory.HOTBAR_SIZE + Inventory.BAG_SIZE + (backpack.get_inventory_slots() if backpack else 0)


## Whether the backpack may change to `backpack` (null = take it off): the items in the places
## that go away, and the old backpack, must fit into the remaining empty places. `from_index` =
## inventory slot the new backpack comes from (it becomes empty).
func can_change_backpack(backpack: InventorySlot, from_index: int = -1) -> bool:
	var current: InventorySlot = player_stats.get_tool(PlayerStats.ToolSlot.BACKPACK)
	return inventory.can_resize(get_inventory_size(backpack), 1 if current else 0, from_index)


## The inventory follows the backpack (PlayerStats.stats_changed). What no longer fits (only in
## broken saves) goes into the storage chest, else the loot chest.
func update_inventory_size() -> void:
	for stack in inventory.resize(get_inventory_size(player_stats.get_tool(PlayerStats.ToolSlot.BACKPACK))):
		var left: int = storage_chest.add_stack(stack)
		if left > 0:
			put_stack_into_reward_chest(stack.copy_with_amount(left))


## Unlocks a reward that arrives in the chest every morning (e.g. wood from the woodcutter).
## The same item from the same source replaces the old amount (Holger: 1 wood, later 3).
func add_daily_reward(item: ItemData, amount: int, source: String) -> void:
	for reward in daily_rewards:
		if reward.get("item", "") == String(item.id) and reward.get("source", "") == source:
			reward["amount"] = amount
			return
	daily_rewards.append({"item": String(item.id), "amount": amount, "source": source})


## Story action "give_items:<list>" (same list as has_items, e.g. "moon_lily_seed*3"): into the
## inventory, whatever does not fit into the reward chest. A book goes straight into the empty book
## slot of the character window.
func give_items(specs: String) -> void:
	for spec in specs.split(",", false):
		var stack: InventorySlot = ContentDB.make_stack(spec)
		if stack == null or _put_into_book_slot(stack):
			continue
		var leftover: int = inventory.add_stack(stack)
		if leftover > 0:
			put_stack_into_reward_chest(stack.copy_with_amount(leftover))
			show_message(Language.translate("Kein Platz im Inventar – der Rest liegt in der Loot-Kiste."))


## Puts items (list like give_items) into `target`, e.g. the supply chest of the tournament.
## Whatever does not fit is lost.
func give_items_to(target: Inventory, specs: String) -> void:
	for spec in specs.split(",", false):
		var stack: InventorySlot = ContentDB.make_stack(spec)
		if stack:
			target.add_stack(stack)


## A single book (PlayerStats.BOOK_TABS) goes into the book slot if that is empty. true if it did.
func _put_into_book_slot(stack: InventorySlot) -> bool:
	var slot := PlayerStats.ToolSlot.BOOK
	if stack.amount != 1 or player_stats.get_tool(slot) or not player_stats.can_equip_tool(slot, stack.item):
		return false
	player_stats.equip_tool(slot, stack)
	return true


## Puts items into the reward chest. Returns how many did not fit (they are lost).
func put_into_reward_chest(item: ItemData, amount: int, rarity: int = -1) -> int:
	var leftover: int = reward_chest.add_item(item, amount, 0, rarity)
	while leftover > 0:
		_grow_reward_chest()
		leftover = reward_chest.add_item(item, leftover, 0, rarity)
	reward_chest_filled.emit()
	return 0


## Like put_into_reward_chest, but keeps rarity and quality of the stack.
func put_stack_into_reward_chest(stack: InventorySlot) -> int:
	var leftover: int = reward_chest.add_stack(stack.copy_with_amount(stack.amount))
	while leftover > 0:
		_grow_reward_chest()
		leftover = reward_chest.add_stack(stack.copy_with_amount(leftover))
	reward_chest_filled.emit()
	return 0


## A full chest gets one more row, nothing is lost (it stays that big, ChestMenu shows all slots).
func _grow_reward_chest() -> void:
	reward_chest.resize(reward_chest.slots.size() + REWARD_CHEST_ROW)


func get_quest_state(quest: QuestData) -> QuestData.State:
	return quest_states.get(quest.resource_path, QuestData.State.AVAILABLE)


func accept_quest(quest: QuestData) -> void:
	if get_quest_state(quest) != QuestData.State.AVAILABLE:
		return
	quest_states[quest.resource_path] = QuestData.State.ACTIVE
	quest_log.append(quest.resource_path)
	if not quest.accept_flag.is_empty():
		story.set_flag(quest.accept_flag)
	for recipe in quest.get_unlock_recipes():
		unlock_recipe(recipe)
	quests_changed.emit()


## How many matching items the player carries for the quest (QuestItems).
func count_quest_items(quest: QuestData) -> int:
	return quest_items.count_quest_items(quest)



func can_complete_quest(quest: QuestData) -> bool:
	return get_quest_state(quest) == QuestData.State.ACTIVE and count_quest_items(quest) >= quest.required_amount


## Takes the items and gives the rewards. Returns false if the quest can't be completed.
func complete_quest(quest: QuestData) -> bool:
	if not can_complete_quest(quest):
		return false
	quest_items.take_quest_items(quest)
	var texts: Array[String] = []
	for reward in quest.rewards:
		match reward.kind:
			QuestReward.Kind.EXPERIENCE:
				player_stats.add_experience(reward.amount)
			QuestReward.Kind.GOLD:
				add_gold(reward.amount)
			QuestReward.Kind.ITEM:
				if inventory.add_item(reward.get_item(), reward.amount) > 0:
					put_into_reward_chest(reward.get_item(), reward.amount)
			QuestReward.Kind.DAILY_ITEM:
				add_daily_reward(reward.get_item(), reward.amount, quest.giver_name)
		texts.append(reward.get_text(true))
	quest_states[quest.resource_path] = QuestData.State.COMPLETED
	quests_changed.emit()
	quest_completed.emit(quest, ", ".join(texts))
	return true


# --- Customer orders --------------------------------------------------------------

## Inventory index of a stack that can be handed in for the order (-1 = none).
func find_order_item(order: CustomerOrder) -> int:
	for i in inventory.slots.size():
		if order.matches(inventory.slots[i]):
			return i
	return -1


## Hands in `item` (already taken out of the inventory, e.g. lying in the order board slot):
## pays gold and EXP, raises the reputation. A knight order whose extras the piece has (CustomerOrder.extras_met)
## pays its bonus_gold on top. Returns false (item is kept by the caller) if it doesn't match.
func complete_order(order: CustomerOrder, item: InventorySlot) -> bool:
	if not order.matches(item) or not customers.orders.has(order):
		return false
	var bonus: int = order.bonus_gold if order.extras_met(item) else 0
	add_gold(order.gold + bonus)
	player_stats.add_experience(order.experience)
	customers.finish(order)
	customers.schedule_praise(order, item, day_cycle.day)
	achievements.count("order")
	if not order.story_tag.is_empty():
		story.set_flag("order_done_" + order.story_tag)
		story_order_gold[order.story_tag] = order.gold + bonus
	var rewards: String = Language.translate("%d Gold, %d PEXP") % [order.gold, order.experience]
	if bonus > 0:
		rewards = Language.translate("%d Gold (+%d Bonus), %d PEXP") % [order.gold, bonus, order.experience]
	order_completed.emit(order, rewards)
	return true


## The knight of the city guard brings orders once Hagen got his armor (economy.json "knight_orders").
func _knight_comes() -> bool:
	return story.has_flag(str(ContentDB.economy("knight_orders").get("flag", "knight_orders_unlocked")))


## Remembers the rarity of a built piece with parts (weapon, armor) for the customer orders.
func record_best_rarity(stack: InventorySlot) -> void:
	if stack == null or stack.is_empty() or stack.components.is_empty():
		return
	var metal: String = stack.components[0].material_id
	if metal.is_empty():
		return
	for key: String in ["%s:%s" % [stack.item.id, metal], metal]:
		best_rarities[key] = maxi(int(best_rarities.get(key, 0)), int(stack.rarity))


## Best rarity (tier) the player built of `item_id` in `metal`; never built: the best of any item of
## that metal minus one tier (a new weapon type is a bit harder), else 0 (R1).
func get_best_rarity(item_id: String, metal: String) -> int:
	var key: String = "%s:%s" % [item_id, metal]
	if best_rarities.has(key):
		return int(best_rarities[key])
	return maxi(int(best_rarities.get(metal, 0)) - 1, 0)


func add_gold(amount: int) -> void:
	if amount > 0:
		AudioManager.play_sound("coins")
	gold += amount
	day_report.add_gold(amount)
	gold_changed.emit(gold)


## Pays `amount` gold. Returns false (and pays nothing) if there is not enough.
func spend_gold(amount: int) -> bool:
	if amount < 0:
		# a negative price (broken data) must not give gold
		push_error("spend_gold: negative amount %d." % amount)
		return false
	if gold < amount:
		return false
	gold -= amount
	if amount > 0:
		AudioManager.play_sound("coins")
	gold_changed.emit(gold)
	return true


func has_hero(hero_id: StringName) -> bool:
	for hero in heroes:
		if hero.id == hero_id:
			return true
	return false


## Hires the hero of a template (pays template.hire_cost once). Returns false if he can't be
## hired (see get_hire_blocker).
func hire_hero(template: Hero) -> bool:
	if get_hire_blocker(template) != "" or not spend_gold(template.hire_cost):
		return false
	add_hero(template)
	return true


## How many heroes the player can have at the same time: combat.json "hero_slots_base" (3) +
## "hero_slots_per_rank" (2) for every reputation rank above F + the places of the guild levels
## (GuildLevel).
func get_max_heroes() -> int:
	return roundi(ContentDB.combat_value("hero_slots_base", 3.0)) 			+ roundi(ContentDB.combat_value("hero_slots_per_rank", 2.0)) * reputation.get_rank_index() 			+ GuildLevel.get_hero_slots(story)


## How many dungeons may run at the same time: combat.json "parallel_dungeons_base" (1) + 1 for
## every set flag of "parallel_dungeons_flags" (end of part 1) + skill "Gefolgschaft".
func get_max_parallel_dungeons() -> int:
	var count: int = roundi(ContentDB.combat_value("parallel_dungeons_base", 1.0)) 			+ player_stats.get_extra_parallel_dungeons()
	for flag in ContentDB.combat_list("parallel_dungeons_flags"):
		if story.has_flag(str(flag)):
			count += 1
	return count


## Dungeons running right now that count against get_max_parallel_dungeons (tournament duels and
## dungeons the story starts itself do not).
func get_running_dungeon_count() -> int:
	var count: int = 0
	for adventure in adventures:
		if not adventure is ArenaDuel and not adventure.story_started:
			count += 1
	return count


## Why this hero can't be hired ("" = he can): already hired, no free hero place
## (get_max_heroes), not enough gold.
## Heroes from the story (action hire_hero) don't count against the limit.
func get_hire_blocker(template: Hero) -> String:
	if has_hero(template.id):
		return Language.translate("Schon angeheuert.")
	if heroes.size() >= get_max_heroes():
		return Language.translate("Mehr Helden geht nicht (%d/%d).") % [heroes.size(), get_max_heroes()]
	if gold < template.hire_cost:
		return Language.translate("Du hast nicht genug Gold.")
	return ""


func add_hero(template: Hero) -> void:
	if has_hero(template.id):
		return
	var hero: Hero = template.duplicate()
	hero.template_path = template.resource_path
	hero.equipment = {}
	hero.learned_skills = {}
	hero.attribute_points = {}
	heroes.append(hero)
	heroes_changed.emit()
	hero_hired.emit(hero)


## Every full hour of the day each hero gets combat.json "hero_stamina_per_hour" stamina back
## (the night is handled in sleep()).
func _restore_stamina_by_the_hour() -> void:
	var hour_key: int = _get_hour_key()
	if _stamina_hour_key < 0 or hour_key < _stamina_hour_key:
		_stamina_hour_key = hour_key
		return
	if hour_key == _stamina_hour_key:
		return
	var amount: float = ContentDB.combat_value("hero_stamina_per_hour", 5.0) * (hour_key - _stamina_hour_key)
	_stamina_hour_key = hour_key
	for hero in heroes:
		hero.change_stamina(amount)
	heroes_changed.emit()


func _get_hour_key() -> int:
	return day_cycle.day * 24 + floori(day_cycle.minutes / 60.0)


## Why this party can't go into the dungeon from the board ("" = it can): gold for the run,
## stamina of every hero.
func get_send_problem(party: Array[Hero], dungeon: DungeonData) -> String:
	if get_running_dungeon_count() >= get_max_parallel_dungeons():
		return Language.translate("Es laufen schon %d von %d Dungeons gleichzeitig.") % [get_running_dungeon_count(), get_max_parallel_dungeons()]
	var cost: int = dungeon.get_cost(achievements.counters)
	if gold < cost:
		return Language.translate("Zu wenig Gold: der Raid kostet %d Gold.") % cost
	for hero in party:
		if hero.stamina < dungeon.stamina_cost:
			return Language.translate("%s ist zu erschöpft (Ausdauer %d, nötig %d).") % [hero.display_name, floori(hero.stamina), dungeon.stamina_cost]
	return ""


## Dungeon board: pays the run, uses every hero's stamina and starts the adventure.
## null if the party can't go (see get_send_problem) or a hero is busy. `power` > 1 = hard mode
## (only if the player has opened it, DungeonData.get_max_power).
func send_party(party: Array[Hero], dungeon: DungeonData, power: int = 1) -> Adventure:
	if not get_send_problem(party, dungeon).is_empty() or party.any(is_hero_busy):
		return null
	if power > get_max_dungeon_power(dungeon):
		return null
	spend_gold(dungeon.get_cost(achievements.counters))
	for hero in party:
		hero.change_stamina(-dungeon.stamina_cost)
	return start_adventure(party, dungeon, power)


## The hardest mode the player may send a party into (1 = only normal; admin "all dungeons": all).
func get_max_dungeon_power(dungeon: DungeonData) -> int:
	if admin_all_dungeons:
		return DungeonData.get_hard_mode_powers().back()
	return dungeon.get_max_power(achievements.counters)


func is_hero_busy(hero: Hero) -> bool:
	for adventure in adventures:
		if adventure.heroes.has(hero):
			return true
	return false


## Sends a party of 1-3 heroes into a dungeon. Returns null if the party is empty, too big
## or one of them is already on an adventure.
func start_adventure(party: Array[Hero], dungeon: DungeonData, power: int = 1, restored: bool = false) -> Adventure:
	if party.is_empty() or party.size() > Adventure.MAX_HEROES:
		return null
	for hero in party:
		if is_hero_busy(hero):
			return null
	var adventure := Adventure.new(party, dungeon, power)
	adventure.loot_filter = func(item: ItemData) -> bool: return is_loot_unlocked(item, dungeon)
	adventure.finished.connect(_on_adventure_finished.bind(adventure))
	adventure.enemy_defeated.connect(_on_enemy_defeated)
	adventures.append(adventure)
	# `restored` = an adventure of a loaded save goes on: that is no new start for the story or
	# the battle window.
	if not restored:
		adventure_started.emit(adventure)
		story_event("adventure_started")
	return adventure


## Kahn's hero tournament: `hero` fights `rival` alone (ArenaDuel), the battle window opens. null if
## the hero is busy.
func start_duel(hero: Hero, rival: Hero) -> ArenaDuel:
	if hero == null or rival == null or is_hero_busy(hero):
		return null
	var arena: DungeonData = ContentDB.dungeon(str(ContentDB.arena().get("dungeon", "arena_duel")))
	if arena == null:
		push_error("GameState: arena.json 'dungeon' is missing in dungeons.json.")
		return null
	var duel := ArenaDuel.new(hero, rival, arena)
	duel.finished.connect(_on_adventure_finished.bind(duel))
	adventures.append(duel)
	adventure_started.emit(duel)
	return duel


## Opens the lexicon at `link` ("enemy:<id>", "item:<id>", "" = just the window); the HUD shows it.
func open_lexicon(link: String = "") -> void:
	Events.lexicon_requested.emit(link)


## Seen items of the save, plus everything in the bags, chests, boxes and on the heroes now (older
## saves start with that).
func _load_lexicon(data: Dictionary) -> void:
	lexicon.load_save_data(data)
	var bags: Array[Inventory] = [inventory, reward_chest, storage_chest]
	bags.append_array(house.get_all_boxes())
	for bag: Inventory in bags:
		lexicon.note_inventory(bag)
	for hero: Hero in heroes:
		for slot: Variant in hero.equipment.values():
			lexicon.note_stack(slot as InventorySlot)


func _on_enemy_defeated(enemy: Combatant) -> void:
	achievements.count("kill")
	achievements.count("kill:" + String(enemy.enemy_data.id))
	# Weapon history: the weapon of the hero who struck the last blow remembers it.
	var weapon: InventorySlot = enemy.killed_by.get_weapon() if enemy.killed_by else null
	if weapon and not weapon.is_empty():
		weapon.record_kill(String(enemy.enemy_data.id), enemy.enemy_data.display_name if enemy.is_boss else "")


func _on_adventure_finished(victory: bool, adventure: Adventure) -> void:
	adventures.erase(adventure)
	# Arena duels bring nothing: the tournament (HeroTournament) handles the result itself.
	if adventure is ArenaDuel:
		adventure_finished.emit(adventure)
		return
	DungeonRewards.give(victory, adventure)
	adventure_finished.emit(adventure)
	# First the event of this dungeon ("adventure_won:rat_nest"), else the general one.
	var event: String = "adventure_won" if victory else "adventure_lost"
	var step_before: String = story.step
	story_event(event + ":" + String(adventure.dungeon.id))
	if story.step == step_before:
		story_event(event)


func is_recipe_unlocked(recipe: RecipeData) -> bool:
	return recipe.unlocked_by_default or unlocked_recipes.has(String(recipe.id))


## Molds of a metal (e.g. "copper") the player does not know yet.
func get_unknown_molds(material_id: String) -> Array[RecipeData]:
	var list: Array[RecipeData] = []
	for mold in ContentDB.get_mold_recipes(material_id):
		if not is_recipe_unlocked(mold):
			list.append(mold)
	return list


## Whether the story has reached a metal (materials.json "unlock_flag"; without one: always).
func is_metal_unlocked(material_id: String) -> bool:
	var flag: String = ContentDB.material_unlock_flag(material_id)
	return flag.is_empty() or story.has_flag(flag)


## Whether an item may come as loot (monsters, bosses, dungeon rewards): ore and ingots of a metal
## the story has not reached yet do not, unless the dungeon gives that metal early
## (DungeonData.early_metals). Story items (e.g. the Frostmähne's pelt) only on the first win of
## the dungeon: once it was won, replays never give them again.
func is_loot_unlocked(item: ItemData, dungeon: DungeonData = null) -> bool:
	if item.story_item and dungeon != null and dungeon.was_won(achievements.counters):
		return false
	var metal: String = ContentDB.metal_of(item)
	return metal.is_empty() or is_metal_unlocked(metal) or (dungeon != null and dungeon.early_metals.has(metal))


## Unlocks a mold and the anvil recipe of its part; unlock_recipe() then adds the recipes built
## from that part as a "set" (e.g. chest plate mold -> chest armor at the workbench, iron rod ->
## the iron staffs). Returns all new recipes.
func unlock_mold(mold: RecipeData) -> Array[RecipeData]:
	var known_before: int = unlocked_recipes.size()
	for recipe in ContentDB.get_mold_unlocks(mold):
		unlock_recipe(recipe)
	var unlocked: Array[RecipeData] = []
	for recipe_id in unlocked_recipes.slice(known_before):
		unlocked.append(ContentDB.recipe(recipe_id))
	return unlocked


## Unlocks every assembly recipe (ASSEMBLY_STATIONS) whose main part (its first part, e.g. the
## blade of a sword, the plate of an armor) or all of whose parts a known recipe makes. Leather
## counts as known nowhere (it has no recipe), so the leather cloak and shoes stay story items.
## A part limited to some metals (Ingredient.materials, e.g. the rod of a bronze staff) only counts
## once a part of one of them can be made.
func _unlock_assembly_recipes() -> void:
	# Parts a known recipe makes; an ingredient counts if one of them fits it (also its material,
	# e.g. a copper staff needs a copper rod).
	var makeable: Array[ItemData] = []
	for other in ContentDB.get_all_recipes():
		if other.station != &"forge" and other.result and other.result.part_type != ItemData.PartType.NONE 				and is_recipe_unlocked(other):
			makeable.append(other.result)
	var can_make: Callable = func(ingredient: Ingredient) -> bool: return makeable.any(ingredient.matches)
	for recipe in ContentDB.get_all_recipes():
		if not ASSEMBLY_STATIONS.has(recipe.station) or is_recipe_unlocked(recipe):
			continue
		var parts: Array = recipe.ingredients.filter(func(ingredient: Ingredient) -> bool: return ingredient.item == null)
		if parts.is_empty():
			continue
		if can_make.call(parts[0]) or parts.all(can_make):
			unlock_recipe(recipe)


## Like _can_make_all_parts, but a recipe without parts (e.g. the wooden staff) counts as makeable.
## Used for the hero classes (ClassUnlocks).
func can_make_all_parts(recipe: RecipeData) -> bool:
	for ingredient in recipe.ingredients:
		if ingredient.item == null:
			return _can_make_all_parts(recipe)
	return true


## True if the recipe takes parts ("any blade" ...) and a known recipe makes each kind of part.
## Parts no recipe makes at all (leather from the tanning rack, gems) count like fixed materials.
func _can_make_all_parts(recipe: RecipeData) -> bool:
	var has_parts: bool = false
	for ingredient in recipe.ingredients:
		if ingredient.item or not _is_craftable_part_type(ingredient.part_type):
			continue
		has_parts = true
		var makeable: bool = false
		for other in ContentDB.get_all_recipes():
			if other.station != &"forge" and other.result and ingredient.matches(other.result) and is_recipe_unlocked(other):
				makeable = true
				break
		if not makeable:
			return false
	return has_parts


## Whether any recipe (anvil, workbench ...) makes parts of this type at all.
func _is_craftable_part_type(part_type: ItemData.PartType) -> bool:
	for other in ContentDB.get_all_recipes():
		if other.station != &"forge" and other.result and other.result.part_type == part_type:
			return true
	return false


## Unlocks a recipe. Returns true if it was new.
func unlock_recipe(recipe: RecipeData) -> bool:
	if is_recipe_unlocked(recipe):
		return false
	unlocked_recipes.append(String(recipe.id))
	if _notices_ready and not _loading and not in_main_menu:
		if _new_recipes.is_empty():
			_announce_new_recipes.call_deferred()
		_new_recipes.append(recipe)
	# A new part (anvil, carving) brings the recipes built from it (sets, see _unlock_assembly_recipes).
	if recipe.result and recipe.result.part_type != ItemData.PartType.NONE:
		_unlock_assembly_recipes()
	_run_recipe_actions()
	recipes_changed.emit()
	return true


## Knows a recipe for a while without any of the usual consequences (no popup, no sets, no story
## actions), e.g. during a tournament round; SmithTournament gives the old list back afterwards.
func unlock_recipe_quietly(recipe: RecipeData) -> void:
	if not is_recipe_unlocked(recipe):
		unlocked_recipes.append(String(recipe.id))
		recipes_changed.emit()


## story.json "recipe_actions": recipe id -> story actions, run while the recipe is known (e.g.
## the first armor mold: "set_flag:armor_mold_found;hint:armor_mold"). A key ending in "*" matches
## every recipe starting with it (e.g. "mold_bronze_*" = any bronze mold). Only use actions that do
## nothing the second time (set_flag, hint): they run again after every new recipe and loading.
func _run_recipe_actions() -> void:
	var recipe_actions: Dictionary = story.get_data("recipe_actions")
	for recipe_id: String in recipe_actions:
		var known: bool = unlocked_recipes.has(recipe_id)
		if recipe_id.ends_with("*"):
			var prefix: String = recipe_id.trim_suffix("*")
			known = unlocked_recipes.any(func(id: String) -> bool: return id.begins_with(prefix))
		if known:
			run_story_action(recipe_actions[recipe_id])


## Saves from before quest molds were left out of random molds: a compass mold that came from a
## dungeon before Aurelius sent the player for it (COMPASS_FLAG) is forgotten again, with its anvil
## recipe, the compass itself and the todo flags of "Der Wüstenkompass".
func _lock_early_compass_molds() -> void:
	if story.has_flag(COMPASS_FLAG):
		return
	var forget: Array[String] = [COMPASS_RECIPE]
	for item: ItemData in ContentDB.get_all_items():
		if item.quest_part:
			forget.append_array(["mold_" + String(item.id), String(item.id)])
	var before: int = unlocked_recipes.size()
	unlocked_recipes.assign(unlocked_recipes.filter(func(id: String) -> bool: return not forget.has(id)))
	if unlocked_recipes.size() != before:
		story.clear_flags(["compass_mold_case", "compass_mold_needle", "compass_mold_rose", "compass_mold_lid"])
		recipes_changed.emit()


## story.json "item_actions": item id -> story actions, run as soon as such an item lies in the
## inventory or the storage chest (e.g. the first bronze ingot: "set_flag:bronze_found"). Checked
## twice a second, so like recipe_actions only actions that do nothing the second time.
func _run_item_actions() -> void:
	# The materials of a tournament round are not the player's own.
	if tournament.is_active():
		return
	var item_actions: Dictionary = story.get_data("item_actions")
	for item_id: String in item_actions:
		var owned: bool = false
		for container: Inventory in [inventory, storage_chest]:
			if container.slots.any(func(slot: InventorySlot) -> bool: return not slot.is_empty() and String(slot.item.id) == item_id):
				owned = true
				break
		if owned:
			run_story_action(item_actions[item_id])


# --- The forge's fire (ForgeFire) under its old names ---------------------------------------

## Castings left in total: the burning piece plus the unburned fuel in the slot.
func get_forge_heat() -> int:
	return forge_fire.get_heat()


## Whether `item` can go into the forge's heat slot (fuel with heat, same kind as what is there).
func can_add_forge_fuel(item: ItemData) -> bool:
	return forge_fire.can_add_fuel(item)


## Puts up to `amount` pieces of `stack` into the heat slot. Returns how many were taken.
func add_forge_fuel(stack: InventorySlot, amount: int) -> int:
	return forge_fire.add_fuel(stack, amount)


## Moves the unburned fuel back into the inventory (whatever does not fit stays in the forge).
func take_forge_fuel() -> void:
	forge_fire.take_fuel_into(inventory)


## The forge is cold: puts one piece of fuel from the inventory or the storage chest into the heat
## slot (the one that lasts longest, e.g. coal before wood). Returns false if there is none.
func refuel_forge() -> bool:
	return forge_fire.refuel(_get_fuel_sources())


## The fuel stack refuel_forge() would use (inventory first, then the storage chest), or null.
func find_forge_fuel() -> InventorySlot:
	return forge_fire.find_fuel(_get_fuel_sources())


## Uses the heat for one casting; lights the next fuel piece if needed.
## Returns false if the forge is cold.
func use_forge_heat() -> bool:
	return forge_fire.use_heat()


func _get_fuel_sources() -> Array[Inventory]:
	var sources: Array[Inventory] = [inventory]
	sources.append_array(get_crafting_extras())
	return sources


## Places besides the inventory the stations take ingredients and fuel from (the storage chest
## next to the bed and the storage boxes of the house), only while the player is in his own house.
## During a smith tournament only its supply chest (it stands in for the storage chest then). At a
## forge away from home (Schmiedegasse, league grounds, Sahrim, Eisquell ...) only the inventory.
func get_crafting_extras() -> Array[Inventory]:
	var extras: Array[Inventory] = []
	if tournament.is_active():
		extras.append(storage_chest)
	elif is_in_own_house():
		extras.append(storage_chest)
		extras.append_array(house.get_all_boxes())
	return extras


## Scenes of the player's own house (workshop, bedroom, shop, greenhouse, hall of fame).
const HOUSE_SCENE_DIR: String = "res://scenes/world/smithy/"


## true while the current scene is part of the player's own house (no scene = true, e.g. tests).
func is_in_own_house() -> bool:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene == null or scene.scene_file_path.is_empty():
		return true
	return scene.scene_file_path.begins_with(HOUSE_SCENE_DIR)


# --- Saving and loading ---------------------------------------------------------------

## Saves the game into a slot 1-3 or the quicksave (see SaveSystem), with the player where he stands right now.
## Slot 0 (autosave) is only written when sleeping (_autosave_in_bed), never by hand.
func save_game(slot: int) -> bool:
	if slot == SaveSystem.AUTOSAVE_SLOT:
		push_warning("The autosave slot can't be saved by hand.")
		return false
	if tournament.is_active():
		show_message(Language.translate("Während des Turniers kann man nicht speichern."))
		return false
	if is_cutscene_running():
		show_message(Language.translate("Mitten im Gespräch kann man nicht speichern."))
		return false
	if Net.is_guest():
		show_message(Language.translate("Als Gast kann man nicht speichern."))
		return false
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var data: Dictionary = _collect_save_data()
	var scene: Node = get_tree().current_scene
	data["scene"] = scene.scene_file_path if scene else START_SCENE
	if player:
		data["player_position"] = [player.global_position.x, player.global_position.y]
	var success: bool = SaveSystem.write(slot, data)
	game_saved.emit(slot, success)
	return success


## true while a conversation or cutscene holds the player: a dialogue box that freezes him is open,
## he walks by himself (auto_walk goes through everything) or a cutscene switched his movement off.
## Saving then would store a place and story flags from the middle of the scene.
func is_cutscene_running() -> bool:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player and (player.is_auto_walking() or not player.is_physics_processing()):
		return true
	return DialogueBox.is_any_blocking(get_tree())


## Autosave of the new morning: the player wakes up in his bed. Not during the smith tournament
## (like save_game): the inventory and recipes then are the tournament's, the real ones are set
## aside in memory only.
func _autosave_in_bed(bed_scene: String = BEDROOM_SCENE, bed_spawn: StringName = BED_SPAWN_POINT) -> void:
	if tournament.is_active():
		return
	var data: Dictionary = _collect_save_data()
	data["scene"] = bed_scene
	data["spawn_point"] = str(bed_spawn)
	SaveSystem.write(SaveSystem.AUTOSAVE_SLOT, data)


## Loads a slot: replaces the whole game state and changes to the saved place.
## Returns false if the slot is empty or broken (nothing is changed then).
func load_game(slot: int) -> bool:
	var data: Dictionary = SaveSystem.read(slot)
	if data.is_empty():
		return false
	load_from_data(data, Language.translate("%s geladen") % SaveSystem.get_slot_name(slot))
	return true


## Puts a save dictionary in place and changes to its scene (loading a slot, or the host's world a
## LAN guest gets, Net). `message` shows up in the new scene.
func load_from_data(data: Dictionary, message: String) -> void:
	_loading = true
	_apply_save_data(data)
	_loading = false
	in_main_menu = false
	# What the save has unlocked already gets no popup.
	UnlockNotices.mark_known()
	_new_recipes.clear()
	UnlockPopup.clear()
	class_unlock_days = (data.get("class_unlock_days", {}) as Dictionary).duplicate()
	# Older saves: what is unlocked already is there right away, without a tip.
	_check_class_unlocks(data.has("class_unlock_days"))
	var scene: String = data.get("scene", START_SCENE)
	if not ResourceLoader.exists(scene):
		scene = START_SCENE
	next_spawn_point = StringName(data.get("spawn_point", ""))
	var saved_position: Array = data.get("player_position", [])
	next_player_position = Vector2(saved_position[0], saved_position[1]) if saved_position.size() == 2 else Vector2.INF
	pending_message = message
	get_tree().change_scene_to_file.call_deferred(scene)


## What goes into a save and how a loaded one is put back: SaveData (scripts/core/save_data.gd).
func _collect_save_data() -> Dictionary:
	return SaveData.collect()


func _apply_save_data(data: Dictionary) -> void:
	SaveData.apply(data)
