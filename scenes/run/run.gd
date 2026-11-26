class_name RunScene
extends Node
## The scene of one floor: the 3D world (in a SubViewport: drawn at the low base resolution and
## scaled up with sharp pixels, so the 3D looks like pixel art), the HUD, the pause menu and the
## end screen. Passes the mouse movement to the player, Tab to the map, Esc to the pause menu,
## and reacts to death and the trapdoor.

const DEATH_DELAY: float = 1.2

@onready var dungeon: Dungeon = %Dungeon
@onready var player: Player = %Player
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var end_screen: EndScreen = $EndScreen

var _leaving: bool = false


func _ready() -> void:
	if Game.run == null:
		# Scene started on its own (F6 in the editor): a fresh run.
		Game.run = RunState.new(randi())
	var run: RunState = Game.run
	player.setup(run, dungeon)
	dungeon.build(run, player, run.floor_index)
	hud.setup(run, dungeon, player)
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
		end_screen.open(Game.run, true)
		return
	AudioManager.play_sound("door", 0.6)
	await hud.fade_out(0.6)
	Game.next_floor()
