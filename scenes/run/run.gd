class_name RunScene
extends Node
## The scene of one floor: the 3D world (in a SubViewport: drawn at the low base resolution and
## scaled up with sharp pixels, so the 3D looks like pixel art), the HUD, the pause menu, the bag
## window and the end screen. Passes the mouse movement to the player, Tab to the bag, M to the
## map, Esc to the pause menu, and reacts to death, the trapdoor, the way out of the start room
## and the rope after the very first boss.
## The end of a run is settled with MetaState: a win, fleeing (the ladder in the start room,
## after a question) or climbing out at the rope brings the coins and the whole bag home, death
## only the safe places.

const DEATH_DELAY: float = 1.2

@onready var dungeon: Dungeon = %Dungeon
@onready var player: Player = %Player
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var end_screen: EndScreen = $EndScreen

var bag_window: BagWindow
## The guide of the very first run (null otherwise or once it is over).
var guide: DungeonGuide = null
## P (only in debug builds): the admin menu for testing (AdminMenu).
var admin_menu: AdminMenu = null
var _leaving: bool = false
## "Flüchten?" (built in code, works while the game is paused).
var _flee_question: ConfirmationDialog


func _ready() -> void:
	if Game.run == null:
		# Scene started on its own (F6 in the editor): a fresh run.
		Game.run = RunState.new(randi())
	var run: RunState = Game.run
	player.setup(run, dungeon)
	# The guide of the very first run (DungeonGuide): only on the first floor.
	dungeon.guide = run.guided and run.floor_index == 0
	dungeon.build(run, player, run.floor_index)
	hud.setup(run, dungeon, player)
	bag_window = BagWindow.new()
	bag_window.name = "BagWindow"
	add_child(bag_window)
	bag_window.setup(run, dungeon)
	bag_window.closed.connect(_capture_mouse)
	if dungeon.guide:
		guide = DungeonGuide.new()
		guide.name = "Guide"
		add_child(guide)
		guide.setup(dungeon, player, run, hud, bag_window)
	if OS.is_debug_build():
		admin_menu = AdminMenu.new()
		admin_menu.name = "AdminMenu"
		add_child(admin_menu)
		admin_menu.setup(run, dungeon, player)
		admin_menu.closed.connect(_capture_mouse)
	run.died.connect(_on_died)
	dungeon.trapdoor_entered.connect(_on_trapdoor_entered)
	dungeon.exit_entered.connect(_ask_flee)
	dungeon.rope_grabbed.connect(_on_rope_grabbed)
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
	elif event.is_action_pressed(Controls.TEST_ROOM) and admin_menu != null:
		get_viewport().set_input_as_handled()
		admin_menu.open()
	elif event.is_action_pressed(Controls.BAG):
		get_viewport().set_input_as_handled()
		bag_window.open()
	elif event.is_action_pressed(Controls.TALK) and dungeon.near_merchant():
		get_viewport().set_input_as_handled()
		bag_window.open(true)
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
	Game.run.levels_gained = MetaState.add_exp(Game.run.exp_earned)
	# Counted: after the second death Egon shows the potions (data/potions.json unlock_deaths).
	MetaState.add_death()
	# Unlocks by dying (not shown here: the shop shows them, Progress.take_fresh).
	if Game.run.record_progress:
		Progress.add_count("deaths")
		if Game.run.last_hit_cause in ["trap", "bomb"]:
			Progress.add_count("deaths_" + Game.run.last_hit_cause)
	MetaState.end_run(0, Game.run.bag.lose_unsafe(), rng)
	await get_tree().create_timer(DEATH_DELAY, false).timeout
	end_screen.open(Game.run, false)


## The ladder in the start room: the game stops and asks.
func _ask_flee() -> void:
	if _leaving or get_tree().paused:
		return
	if _flee_question == null:
		_flee_question = ConfirmationDialog.new()
		_flee_question.process_mode = Node.PROCESS_MODE_ALWAYS
		_flee_question.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_flee_question.title = Language.translate("Ausgang")
		_flee_question.dialog_text = Language.translate("Aus dem Dungeon flüchten? Du nimmst alles mit, was du trägst.")
		_flee_question.ok_button_text = Language.translate("Flüchten")
		_flee_question.cancel_button_text = Language.translate("Weiterkämpfen")
		_flee_question.confirmed.connect(_flee)
		_flee_question.canceled.connect(_on_flee_canceled)
		add_child(_flee_question)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_flee_question.popup_centered()


func _on_flee_canceled() -> void:
	get_tree().paused = false
	_capture_mouse()


## Out of the dungeon alive: like a win, the coins and the whole bag come home.
func _flee() -> void:
	_leaving = true
	player.controls_enabled = false
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Game.run.levels_gained = MetaState.add_exp(Game.run.exp_earned)
	MetaState.end_run(0, Game.run.bag.contents(), rng)
	end_screen.open(Game.run, false, true)


func get_flee_question() -> ConfirmationDialog:
	return _flee_question


## The rope after the very first boss (Egon's errand, data/meta.json ruby_quest): the player
## climbs out, the achievement comes, the day ends and everything carried comes home.
func _on_rope_grabbed() -> void:
	if _leaving:
		return
	_leaving = true
	if bag_window.visible:
		bag_window.close()
	MetaState.finish_rope()
	if Progress.unlock_achievement(String(Content.meta("ruby_quest").get("achievement", ""))):
		hud.show_achievement(String(Content.meta("ruby_quest").get("achievement", "")))
	await dungeon.climb_rope()
	if not is_inside_tree():
		return
	await hud.fade_out(0.6)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Game.run.levels_gained = MetaState.add_exp(Game.run.exp_earned)
	MetaState.end_run(0, Game.run.bag.contents(), rng)
	end_screen.open(Game.run, false, false, true)


func _on_trapdoor_entered(final: bool) -> void:
	if _leaving:
		return
	_leaving = true
	player.controls_enabled = false
	if final:
		if Game.run.record_progress:
			Game.run.announce(Progress.add_win(Game.run.time))
			MetaState.win_dungeon(Content.dungeon_id())
		# Made it out: the coins and the whole bag come home.
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		Game.run.levels_gained = MetaState.add_exp(Game.run.exp_earned)
		MetaState.end_run(0, Game.run.bag.contents(), rng)
		end_screen.open(Game.run, true)
		return
	AudioManager.play_sound("door", 0.6)
	await hud.fade_out(0.6)
	Game.next_floor()
