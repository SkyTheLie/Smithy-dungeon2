class_name RunScene
extends Node
## The scene of one floor: the 3D world (in a SubViewport: drawn at the low base resolution and
## scaled up with sharp pixels, so the 3D looks like pixel art), the HUD, the pause menu, the bag
## window and the end screen. Passes the mouse movement to the player, Tab to the bag, M to the
## map, Esc to the pause menu, and reacts to death and the trapdoor.
## The end of a run is settled with MetaState: a win brings the coins and the whole bag home, death
## only the safe places of the bag.

const DEATH_DELAY: float = 1.2

@onready var dungeon: Dungeon = %Dungeon
@onready var player: Player = %Player
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var end_screen: EndScreen = $EndScreen

var bag_window: BagWindow
var _leaving: bool = false


func _ready() -> void:
	if Game.run == null:
		# Scene started on its own (F6 in the editor): a fresh run.
		Game.run = RunState.new(randi())
	var run: RunState = Game.run
	player.setup(run, dungeon)
	dungeon.build(run, player, run.floor_index)
	hud.setup(run, dungeon, player)
	bag_window = BagWindow.new()
	bag_window.name = "BagWindow"
	add_child(bag_window)
	bag_window.setup(run, dungeon)
	bag_window.closed.connect(_capture_mouse)
	run.died.connect(_on_died)
	dungeon.trapdoor_entered.connect(_on_trapdoor_entered)
	pause_menu.resumed.connect(_capture_mouse)
	_capture_mouse()


func _capture_mouse() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		player.look((event as InputEventMouseMotion).screen_relative)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _leaving:
		return
	if event.is_action_pressed(Controls.PAUSE):
		get_viewport().set_input_as_handled()
		pause_menu.open(Game.run)
	elif event.is_action_pressed(Controls.TEST_ROOM) and OS.is_debug_build():
		get_viewport().set_input_as_handled()
		dungeon.toggle_test_room()
	elif event.is_action_pressed(Controls.BAG):
		get_viewport().set_input_as_handled()
		bag_window.open()
	elif event.is_action_pressed(Controls.MAP):
		get_viewport().set_input_as_handled()
		hud.toggle_map()
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Clicked back into the window after alt-tab.
		_capture_mouse()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not get_tree().paused and not _leaving and is_node_ready():
		pause_menu.open(Game.run)


func _on_died() -> void:
	_leaving = true
	player.controls_enabled = false
	if bag_window.visible:
		bag_window.close()
	# Dead: the coins and everything outside the safe places are lost.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	MetaState.end_run(0, Game.run.bag.lose_unsafe(), rng)
	await get_tree().create_timer(DEATH_DELAY, false).timeout
	end_screen.open(Game.run, false)


func _on_trapdoor_entered(final: bool) -> void:
	if _leaving:
		return
	_leaving = true
	player.controls_enabled = false
	if final:
		if Game.run.record_progress:
			Game.run.announce(Progress.add_win(Game.run.time))
		# Made it out: the coins and the whole bag come home.
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		MetaState.end_run(Game.run.coins, Game.run.bag.contents(), rng)
		end_screen.open(Game.run, true)
		return
	AudioManager.play_sound("door", 0.6)
	await hud.fade_out(0.6)
	Game.next_floor()
