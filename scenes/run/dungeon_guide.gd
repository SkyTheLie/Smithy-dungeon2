class_name DungeonGuide
extends Node
## The guide of the very first run (MetaState.guide_done false, first floor). Step by step, one
## line at a time in the HUD (Hud.show_guide):
##   1. walk with W A S D,   2. look around with the mouse,   3. shoot (left click);
##   then the door to the practice room opens (Dungeon.open_guide_door):
##   4. go through the door, 5. shoot the practice rat (it does no harm and drops a rat fur),
##   6. pick the fur up (walk over it), 7. open the bag with Tab,
##   8. drag the fur into the safe place (the bag window shows the line and lets it pulse).
## Then: well done, MetaState.finish_guide, every door opens (Dungeon.end_guide).
## The steps only look at what happened (moved, turned, shot, room, bag); the rules stay in
## Dungeon, Bag and RunState.

signal finished

enum Step { MOVE, LOOK, SHOOT, ENTER, RAT, PICK, OPEN, SAFE, DONE }

## Metres to walk and radians to turn before the next step.
const WALK_NEEDED: float = 3.0
const TURN_NEEDED: float = 1.2
const LOOT: String = "rat_fur"
const DONE_TIME: float = 5.0

var step: Step = Step.MOVE
var dungeon: Dungeon
var player: Player
var run: RunState
var hud: Hud
var bag_window: BagWindow

var _walked: float = 0.0
var _turned: float = 0.0
var _last_position := Vector3.ZERO
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
var _done_left: float = 0.0


func setup(the_dungeon: Dungeon, the_player: Player, run_state: RunState, the_hud: Hud, window: BagWindow) -> void:
	dungeon = the_dungeon
	player = the_player
	run = run_state
	hud = the_hud
	bag_window = window
	_last_position = player.global_position
	_last_yaw = player.rotation.y
	_last_pitch = player.camera.rotation.x
	# Also while the bag window pauses the game (the last step happens in there).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_show()


## The text of the current step (German key, translated where it is shown).
func text() -> String:
	match step:
		Step.MOVE:
			return "Laufe mit W A S D."
		Step.LOOK:
			return "Schau dich mit der Maus um."
		Step.SHOOT:
			return "Linksklick: schießen. Probier es!"
		Step.ENTER:
			return "Die Tür ist offen. Geh in den nächsten Raum."
		Step.RAT:
			return "Eine Übungsratte! Sie tut dir nichts. Schieß sie ab."
		Step.PICK:
			return "Sie hat etwas fallen lassen. Lauf darüber, um es aufzuheben."
		Step.OPEN:
			return "Öffne dein Inventar mit Tab."
		Step.SAFE:
			return "Zieh das Rattenfell in den goldenen sicheren Platz. Was dort liegt, behältst du, wenn du stirbst."
		Step.DONE:
			return "Gut gemacht! Jetzt ab in den Dungeon."
	return ""


func _process(delta: float) -> void:
	# The bag window shows the line itself; the HUD box would shine through behind it.
	if hud.guide_box != null:
		hud.guide_box.visible = not bag_window.visible
	if step == Step.DONE:
		_done_left -= delta
		if _done_left <= 0.0:
			hud.show_guide("")
			queue_free()
		return
	if run.is_dead():
		return
	match step:
		Step.MOVE:
			var flat: Vector3 = (player.global_position - _last_position) * Vector3(1, 0, 1)
			_walked += flat.length()
			_last_position = player.global_position
			if _walked >= WALK_NEEDED:
				_advance(Step.LOOK)
		Step.LOOK:
			_turned += absf(angle_difference(_last_yaw, player.rotation.y)) + absf(player.camera.rotation.x - _last_pitch)
			_last_yaw = player.rotation.y
			_last_pitch = player.camera.rotation.x
			if _turned >= TURN_NEEDED:
				_advance(Step.SHOOT)
		Step.SHOOT:
			if not get_tree().paused and player.controls_enabled and Input.is_action_pressed(Controls.SHOOT):
				dungeon.open_guide_door()
				if dungeon.guide_cell == Vector2i(-1, -1):
					_finish()
				else:
					_advance(Step.ENTER)
		Step.ENTER:
			if dungeon.current_cell == dungeon.guide_cell:
				_advance(Step.RAT)
		Step.RAT:
			if dungeon.guide_room_cleared():
				_advance(Step.PICK)
		Step.PICK:
			if run.bag.count_of(LOOT) > 0:
				_advance(Step.OPEN)
		Step.OPEN:
			if run.bag.count_of(LOOT) <= 0:
				_advance(Step.PICK)
			elif bag_window.visible:
				_advance(Step.SAFE)
		Step.SAFE:
			if _loot_is_safe():
				_finish()
			elif run.bag.count_of(LOOT) <= 0:
				_advance(Step.PICK)


func _loot_is_safe() -> bool:
	for i in run.bag.size():
		if run.bag.is_safe(i) and String(run.bag.get_place(i)["id"]) == LOOT:
			return true
	return false


func _advance(next: Step) -> void:
	step = next
	AudioManager.play_sound("unlock", 1.3)
	_show()


func _show() -> void:
	var line: String = Language.translate(text())
	hud.show_guide(line)
	# In the bag window: the line at its top, the safe place pulses for the last step.
	if step == Step.SAFE:
		bag_window.set_guide(line, true)
	elif step == Step.DONE:
		bag_window.set_guide(line, false)
	else:
		bag_window.set_guide("", false)


func _finish() -> void:
	step = Step.DONE
	_done_left = DONE_TIME
	MetaState.finish_guide()
	dungeon.end_guide()
	AudioManager.play_sound("unlock", 1.0)
	_show()
	finished.emit()
