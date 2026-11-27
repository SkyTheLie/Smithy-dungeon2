extends Node
## Autoload "Game": holds the running RunState and switches between the scenes:
## main menu -> (Neues Spiel) intro -> shop (Egon's) -> dungeon board -> run -> back to the shop.
## Also sets up the language and the key bindings at the start of the program.

const MENU_SCENE: String = "res://scenes/ui/main_menu/main_menu.tscn"
const RUN_SCENE: String = "res://scenes/run/run.tscn"
const INTRO_SCENE: String = "res://scenes/story/intro.tscn"
const SHOP_SCENE: String = "res://scenes/shop/shop.tscn"
const CONTROLS_SECTION: String = "controls"
const DEFAULT_MOUSE_SENSITIVITY: float = 0.5

## The field of view of the dungeon camera was changed in the settings (DisplaySettings).
signal fov_changed(degrees: float)

## The run being played (null in the main menu before the first run). Not saved on purpose.
var run: RunState = null


func _ready() -> void:
	Language.apply()
	Controls.register()
	DisplaySettings.apply()


## A new run on floor 1 with a fresh random seed, as `character` (data/characters.json), in
## `dungeon` (data/dungeons.json). Without them: those of the last run.
func start_new_run(character: String = "", dungeon: String = "") -> void:
	if character.is_empty():
		character = run.character if run else "magier"
	if dungeon.is_empty():
		dungeon = Content.active_dungeon
	Content.active_dungeon = Content.dungeon_id(dungeon)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	run = RunState.new(rng.randi(), character)
	# What the hero wears at home counts in the dungeon (shield hearts, weapon damage).
	run.use_gear(MetaState.equipment())
	# The skills learned at Egon's (bag places, hearts, damage …).
	run.use_skills()
	# The gold at home stays in the money box: the run starts without gold.
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(RUN_SCENE)


## Admin menu (debug builds): the same run goes on in `dungeon` (dungeons.json) on floor
## `floor_index` (0 = the first), the floor is built anew.
func travel(dungeon: String, floor_index: int) -> void:
	if run == null:
		return
	Content.active_dungeon = Content.dungeon_id(dungeon)
	run.floor_index = clampi(floor_index, 0, Content.floors().size() - 1)
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(RUN_SCENE)


## Down the trapdoor: the next floor (same run).
func next_floor() -> void:
	if run == null:
		return
	run.next_floor()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(RUN_SCENE)


func is_last_floor() -> bool:
	return run != null and run.floor_index >= Content.floors().size() - 1


## "Neues Spiel": the save slot starts over, then the intro (cave, Egon waves) leads to the shop.
func start_intro() -> void:
	MetaState.start_new()
	run = null
	_change_scene(INTRO_SCENE)


## "Weiter", the end of the intro and the end of a run: Egon's shop (between the days).
func to_shop() -> void:
	run = null
	_change_scene(SHOP_SCENE)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred(path)


func to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


# --- Settings ---------------------------------------------------------------------

## 0..1, the slider in the settings; turned into radians per pixel by the player.
func get_mouse_sensitivity() -> float:
	return clampf(float(WindowLayout.get_setting(CONTROLS_SECTION, "mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY)), 0.0, 1.0)


func set_mouse_sensitivity(value: float) -> void:
	WindowLayout.set_setting(CONTROLS_SECTION, "mouse_sensitivity", clampf(value, 0.0, 1.0))
