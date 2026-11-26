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

## The run being played (null in the main menu before the first run). Not saved on purpose.
var run: RunState = null


func _ready() -> void:
	Language.apply()
	Controls.register()
	_apply_fullscreen()


## A new run on floor 1 with a fresh random seed, as `character` (data/characters.json). Without
## one: the character of the last run (Neuer Run on the end screen).
func start_new_run(character: String = "") -> void:
	if character.is_empty():
		character = run.character if run else "magier"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	run = RunState.new(rng.randi(), character)
	# The purse from home goes into the dungeon (and is lost there on death).
	run.bring_gold(MetaState.take_purse_for_run())
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


func is_fullscreen() -> bool:
	return bool(WindowLayout.get_setting("display", "fullscreen", false))


func set_fullscreen(on: bool) -> void:
	WindowLayout.set_setting("display", "fullscreen", on)
	_apply_fullscreen()


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED)
