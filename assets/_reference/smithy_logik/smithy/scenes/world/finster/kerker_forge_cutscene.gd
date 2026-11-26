class_name KerkerForgeCutscene
extends StoryCutscene
## Halvard is freed in the dungeon forge. His hands are chained with starsteel (no shackle item):
## - hands_on_anvil (dialogue "halvard_meet"): he shuffles to the anvil and lays his chained hands on
##   it (the shackle lies on the anvil, glowing blue)
## - step "break_shackle": E at the anvil does not open the anvil menu but the shackle event: the
##   player steps beside the anvil, the forging minigame with exactly SHACKLE_STRIKES strikes opens
##   (title "Fessel aufschmieden"). All strikes green = the shackle springs open (step
##   "halvard_freed", Halvard starts "halvard_free"). Otherwise Halvard says "halvard_shackle_miss_1"
##   / "_2" and the player tries again; the third failed try opens it anyway
##   ("halvard_shackle_failed": Halvard is puzzled and a bit let down, flag shackle_forced). Closing
##   the minigame with X counts as no try.
## Each beat below is a line with "hide_for" (the dialogue box is out of sight while it plays) and
## "cutscene:<id>":
## - shackle_off: the shackle springs open and drops from the anvil, Halvard sways, Nyra comes to
##   hold him
## - lake_door: heavy steps, then the dark Lake stands in the door (flag lake_in_forge)
## - stand_before: the player steps between Lake and the two, the hands glow
## - lake_halt: Lake raises the sword, the blue light hits him, a golden gleam in his eyes
## - lake_aside: he lowers the sword and steps aside (flag lake_stepped_aside at the end of the talk)
## - leave_forge: Nyra puts Halvard's arm over her shoulder and half carries him past Lake out of
##   the door; the player stays standing before Lake
## - player_leaves: after his "Danke" the player walks past Lake to the door (then the fade)
## - nyra_slips_in (dialogue "halvard_meet"): a door creaks, Nyra slips in from the door, wet from
##   the canals, and goes to her place

## Emitted when a shackle try ends: 1 = all strikes green, 0 = failed, -1 = window closed.
signal shackle_try_done(result: int)

@export var halvard: NodePath
@export var nyra: NodePath
@export var dark_lake: NodePath
@export var anvil: NodePath
@export var anvil_menu: NodePath

## Reason for Player.lock while the shackle minigame is open.
const LOCK_REASON: StringName = &"kerker_forge"
## The open shackle on the floor (PixelLab, lies straight: nothing in the world is tilted).
const SHACKLE: String = "res://assets/sprites/finster/shackle_open.png"
const SHACKLE_CLOSED: String = "res://assets/sprites/items/starsteel_shackle.png"
const SLASH_DARK: String = "res://assets/sprites/residents/lake_dark_slash.png"
const LAKE_DARK: String = "res://assets/sprites/residents/lake_dark.png"
const MINIGAME: String = "res://scenes/ui/minigames/forging_minigame.tscn"
const BLUE: Color = Color(0.45, 0.7, 1.0)
const GOLD: Color = Color(1.0, 0.82, 0.35)
## Scene coordinates: the door at the bottom, where Lake stands in it, where the player meets him.
const DOOR: Vector2 = Vector2(0, 232)
const LAKE_SPOT: Vector2 = Vector2(0, 186)
const PLAYER_SPOT: Vector2 = Vector2(0, 140)
const ASIDE: Vector2 = Vector2(34, 186)
## Halvard beside the anvil with his hands on it, where the shackle lies, where the player strikes.
const HALVARD_AT_ANVIL: Vector2 = Vector2(-30, -31)
const SHACKLE_ON_ANVIL: Vector2 = Vector2(-11, -55)
const PLAYER_AT_ANVIL: Vector2 = Vector2(27, -31)
## Way out for Halvard (Nyra walks at his left, NYRA_BESIDE) and the player's last spot, past Lake.
const LEAVE_WAY: Array[Vector2] = [Vector2(-30, 40), Vector2(-24, 170), Vector2(-20, 262)]
const NYRA_BESIDE: Vector2 = Vector2(-11, 1)
const LEAVE_SPEED: float = 40.0
const PLAYER_OUT: Vector2 = Vector2(0, 214)
const SHACKLE_ITEM: String = "starsteel_shackle"
const SHACKLE_STRIKES: int = 3
## Failed tries until the shackle gives way by itself (the last one opens it anyway).
const SHACKLE_TRIES: int = 3
## Flags shackle_miss_1, shackle_miss_2: failed tries so far (kept in the save).
const MISS_FLAG: String = "shackle_miss_"

var _glow: Node2D
## The closed shackle lying on the anvil (with Halvard's hands) until it springs open.
var _shackle: Sprite2D
var _try_running: bool = false


func _ready() -> void:
	super()
	# Nyra comes later in "halvard_meet" (nyra_slips_in): not standing at her place before that.
	# Also on "sneak_castle": entering this scene only then starts "free_halvard" (event
	# enter:kerker_forge), which makes her present (reached_free_halvard) - invisible until she comes in.
	if GameState.story.step in ["sneak_castle", "free_halvard"]:
		var girl := node2d(nyra)
		if girl:
			girl.modulate.a = 0.0
	# his hands already lie on the anvil (or the shackle just came off and he still has to talk)
	if GameState.story.step in ["break_shackle", "halvard_freed"]:
		var old := node2d(halvard)
		if old:
			old.global_position = _at(HALVARD_AT_ANVIL)
			old.set("facing", "right")
			old.call("_face", "right")
	if GameState.story.step == "break_shackle":
		_lay_shackle()
		_take_anvil()
		# old saves: the shackle used to be an item in the inventory, it lies on the anvil now
		if GameState.has_items(SHACKLE_ITEM):
			GameState.take_items(SHACKLE_ITEM)


func _play_beat(id: String) -> bool:
	match id:
		"shackle_off":
			_shackle_off()
		"lake_door":
			_lake_door()
		"stand_before":
			_stand_before()
		"lake_halt":
			_lake_halt()
		"lake_aside":
			_lake_aside()
		"nyra_slips_in":
			_nyra_slips_in()
		"hands_on_anvil":
			_hands_on_anvil()
		"leave_forge":
			_leave_forge()
		"player_leaves":
			_player_leaves()
		_:
			return false
	return true


## Scene coordinates (of the forge map) to global.
func _at(point: Vector2) -> Vector2:
	return (get_parent() as Node2D).to_global(point)


# --- the shackle on the anvil -------------------------------------------------------------------

## Halvard shuffles to the anvil and lays his chained hands on it.
func _hands_on_anvil() -> void:
	var old := node2d(halvard)
	if old == null:
		return
	await _walk_npc(old, _at(HALVARD_AT_ANVIL), "right", 34.0)
	if not is_inside_tree():
		return
	AudioManager.play_sound("anvil_good", 0.7)
	_lay_shackle()
	fx.spawn("impact", _shackle.global_position, BLUE)
	_take_anvil()


## The closed shackle on the anvil, glowing in the blue of his hands.
func _lay_shackle() -> void:
	if _shackle:
		return
	_shackle = Sprite2D.new()
	_shackle.texture = load(SHACKLE_CLOSED)
	_shackle.scale = Vector2.ONE * 0.7
	_shackle.z_index = 1
	add_child(_shackle)
	_shackle.global_position = _at(SHACKLE_ON_ANVIL)
	fx.add_loop(_shackle, "glow", BLUE)


## While the shackle lies there, E at the anvil starts a shackle try instead of the anvil menu.
func _take_anvil() -> void:
	var station := get_node_or_null(anvil)
	if station == null:
		return
	var menu := get_node_or_null(anvil_menu)
	if menu and station.is_connected(&"interacted", Callable(menu, &"toggle")):
		station.disconnect(&"interacted", Callable(menu, &"toggle"))
	if not station.is_connected(&"interacted", _on_anvil_pressed):
		station.connect(&"interacted", _on_anvil_pressed)


func _give_back_anvil() -> void:
	var station := get_node_or_null(anvil)
	if station == null:
		return
	if station.is_connected(&"interacted", _on_anvil_pressed):
		station.disconnect(&"interacted", _on_anvil_pressed)
	var menu := get_node_or_null(anvil_menu)
	if menu and not station.is_connected(&"interacted", Callable(menu, &"toggle")):
		station.connect(&"interacted", Callable(menu, &"toggle"))


func _on_anvil_pressed() -> void:
	if _try_running or DialogueBox.is_any_open(get_tree()):
		return
	if GameState.story.step != "break_shackle":
		_give_back_anvil()
		return
	shackle_try()


## One try: the player steps beside the anvil and strikes SHACKLE_STRIKES times.
func shackle_try() -> void:
	_try_running = true
	# his waiting line ("Ich halte still ...") must not pop up while the player strikes
	var old := node2d(halvard)
	if old:
		old.set("_last_auto_dialogue", GameState.story.get_npc_dialogue("halvard"))
	var smith := player()
	if smith and smith.has_method("auto_walk"):
		smith.call("auto_walk", PackedVector2Array([_at(PLAYER_AT_ANVIL)]), "left", 90.0)
		if smith.call("is_auto_walking"):
			await smith.auto_walk_finished
	if not is_inside_tree():
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var game := (load(MINIGAME) as PackedScene).instantiate() as ForgingMinigame
	layer.add_child(game)
	game.get_node("%TitleBar").set("title", Language.translate("Fessel aufschmieden"))
	game.finished.connect(func(_points: int, perfect: bool) -> void: shackle_try_done.emit(1 if perfect else 0))
	game.close_requested.connect(func() -> void: shackle_try_done.emit(-1))
	if smith:
		smith.call("lock", LOCK_REASON)
	game.start(null, ContentDB.item(SHACKLE_ITEM), SHACKLE_STRIKES)
	var result: int = await shackle_try_done
	if result >= 0 and is_inside_tree():
		await wait(0.6)  # see the last strike before the window goes
	if is_instance_valid(smith):
		smith.call("unlock", LOCK_REASON)
	layer.queue_free()
	_try_running = false
	if not is_inside_tree() or result < 0:
		return
	_after_try(result == 1)


func _after_try(perfect: bool) -> void:
	var old := node2d(halvard)
	if perfect:
		_give_back_anvil()
		GameState.story.advance("halvard_freed")
		_close_box()
		if old:
			old.call("talk")
		return
	var misses: int = 0
	while misses < SHACKLE_TRIES and GameState.story.has_flag(MISS_FLAG + str(misses + 1)):
		misses += 1
	if old:
		NpcActing.play(old, "tremble")
	if misses + 1 >= SHACKLE_TRIES:
		_give_back_anvil()  # it opens by itself now ("halvard_shackle_failed" » "halvard_free")
		# set before the talk: "halvard_free" (its "then") picks its lines when the talk starts
		GameState.story.set_flag("shackle_forced")
		_talk("halvard_shackle_failed")
		return
	GameState.story.set_flag(MISS_FLAG + str(misses + 1))
	_talk("halvard_shackle_miss_" + str(misses + 1))


## Halvard starts `dialogue_id` (story.json) in his own box (it stays open wherever the player is).
func _talk(dialogue_id: String) -> void:
	var old := node2d(halvard)
	if old == null:
		return
	_close_box()
	var box := old.get_node("DialogueBox") as DialogueBox
	box.play(GameState.story.get_dialogue(dialogue_id), "halvard", old.call("get_portrait"))


## Closes a line Halvard may still show (e.g. his waiting line) before he says something new.
func _close_box() -> void:
	var old := node2d(halvard)
	var box := old.get_node_or_null("DialogueBox") as DialogueBox if old else null
	if box and box.visible:
		box.hide()


func _shackle_off() -> void:
	var old := node2d(halvard)
	if old == null:
		return
	var from: Vector2 = _shackle.global_position if _shackle else _at(SHACKLE_ON_ANVIL)
	if _shackle:
		fx.remove_loop(_shackle)
		_shackle.queue_free()
		_shackle = null
	AudioManager.play_sound("unlock", 0.9)
	fx.spawn("impact", from, Color.WHITE)
	# the open shackle drops from the anvil to the floor between him and the anvil
	var shackle := Sprite2D.new()
	shackle.texture = load(SHACKLE)
	add_child(shackle)
	shackle.global_position = from
	var drop := create_tween().set_parallel()
	drop.tween_property(shackle, "global_position", old.global_position + Vector2(14, 4), 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# he sways ...
	var figure := old.get_node_or_null("Figure") as Node2D
	if figure:
		var sway := create_tween()
		for angle in [0.12, -0.1, 0.08, 0.0]:
			sway.tween_property(figure, "rotation", angle, 0.22)
	# ... and Nyra comes to hold him (from his left, the anvil is on his right)
	var helper := node2d(nyra)
	if helper:
		_walk_npc(helper, old.global_position + Vector2(-16, 4), "right", 110.0)


func _lake_door() -> void:
	var lake := node2d(dark_lake)
	if lake:
		lake.modulate.a = 0.0  # the flag lake_in_forge shows him at once: he comes up the stairs first
	for i in 3:
		AudioManager.play_sound("step", 0.9)
		if not await wait(0.35):
			return
	if lake == null:
		return
	lake.global_position = to_global(DOOR)
	var fade := create_tween()
	fade.tween_property(lake, "modulate:a", 1.0, 0.3)
	await _walk_npc(lake, to_global(LAKE_SPOT), "up", 45.0)


func _stand_before() -> void:
	var smith := player()
	if smith == null or not smith.has_method("auto_walk"):
		return
	smith.call("auto_walk", PackedVector2Array([to_global(PLAYER_SPOT)]), "down", 110.0)
	if smith.call("is_auto_walking"):
		await smith.auto_walk_finished
	if not is_inside_tree():
		return
	_glow = Node2D.new()
	add_child(_glow)
	_glow.global_position = smith.global_position + Vector2(0, -2)
	fx.add_loop(_glow, "glow", BLUE)
	fx.spawn("buff", _glow.global_position, BLUE)
	AudioManager.play_sound("skill_used", 0.8)


func _lake_halt() -> void:
	var lake := node2d(dark_lake)
	var smith := player()
	if lake == null:
		return
	var figure := lake.get_node_or_null("Figure") as Sprite2D
	# he lifts the black sword over his head
	if figure:
		figure.texture = load(SLASH_DARK)
		figure.region_rect = Rect2(0, 0, 64, 64)
	AudioManager.play_sound("anvil_miss", 0.6)
	await wait(0.5)
	if not is_inside_tree() or not is_instance_valid(lake):
		return
	# the blue light hits him, he freezes; deep down a golden gleam
	var from: Vector2 = smith.global_position + Vector2(0, -10) if smith else to_global(PLAYER_SPOT)
	fx.spawn("light_bolt", lake.global_position + Vector2(0, -16), BLUE, 1.0, from)
	await wait(0.35)
	if not is_inside_tree() or not is_instance_valid(lake):
		return
	fx.spawn("light_hit", lake.global_position + Vector2(0, -18), BLUE)
	fx.add_loop(lake, "glow", BLUE, Vector2(0, -14))
	await wait(0.5)
	if not is_inside_tree() or not is_instance_valid(lake):
		return
	fx.spawn("light_hit", lake.global_position + Vector2(1, -28), GOLD)
	AudioManager.play_sound("rarity_up", 0.5)


func _lake_aside() -> void:
	var lake := node2d(dark_lake)
	if lake == null:
		return
	fx.remove_loop(lake)
	if _glow:
		fx.remove_loop(_glow)
	var figure := lake.get_node_or_null("Figure") as Sprite2D
	if figure:
		figure.texture = load(LAKE_DARK)
	await _walk_npc(lake, to_global(ASIDE), "left", 40.0)


## Nyra puts Halvard's arm over her shoulder and half carries him out past Lake; the player stays.
func _leave_forge() -> void:
	var old := node2d(halvard)
	var helper := node2d(nyra)
	if old == null:
		return
	var leaning: Array[Tween] = []
	if helper:
		# she steps under his arm first
		await _walk_npc(helper, old.global_position + NYRA_BESIDE, "down", 60.0)
		if not is_inside_tree() or not is_instance_valid(old):
			return
		leaning.append(_lean(helper, 0.07))
	leaning.append(_lean(old, -0.12))
	if helper:
		var her_way: Array[Vector2] = []
		for point in LEAVE_WAY:
			her_way.append(_at(point) + NYRA_BESIDE)
		_walk_path(helper, her_way, LEAVE_SPEED, true)
	var his_way: Array[Vector2] = []
	for point in LEAVE_WAY:
		his_way.append(_at(point))
	await _walk_path(old, his_way, LEAVE_SPEED, true)
	for tween in leaning:
		if tween and tween.is_valid():
			tween.kill()


## The figure leans to one side and bobs a little with every step (weak, held up) until killed.
func _lean(npc: Node2D, angle: float) -> Tween:
	var figure := npc.get_node_or_null("Figure") as Node2D
	if figure == null:
		return null
	var tween := figure.create_tween().set_loops()
	tween.tween_property(figure, "rotation", angle, 0.3)
	tween.tween_property(figure, "rotation", angle * 0.5, 0.3)
	return tween


## Walks along `points` (global); with `fade_out` the figure fades on the last stretch (out of the
## door) and is hidden at the end.
func _walk_path(npc: Node2D, points: Array[Vector2], speed: float, fade_out: bool = false) -> void:
	for i in points.size():
		if not is_inside_tree() or not is_instance_valid(npc):
			return
		if fade_out and i == points.size() - 1:
			var time: float = npc.global_position.distance_to(points[i]) / speed
			npc.create_tween().tween_property(npc, "modulate:a", 0.0, time)
		await _walk_npc(npc, points[i], "down", speed)
	if fade_out and is_instance_valid(npc):
		npc.hide()


## After his "Danke" the player walks past Lake towards the door (the fade to the hideout follows).
func _player_leaves() -> void:
	if _glow:
		fx.remove_loop(_glow)
	var smith := player()
	if smith and smith.has_method("auto_walk"):
		smith.call("auto_walk", PackedVector2Array([_at(PLAYER_OUT)]), "down", 60.0)


## A story NPC walks to `target` (global) with its walk frames.
func _walk_npc(npc: Node2D, target: Vector2, facing: String, speed: float) -> void:
	await walk_npc(npc, PackedVector2Array([target]), speed, facing)


func _nyra_slips_in() -> void:
	var girl := node2d(nyra)
	if girl == null:
		return
	var spot: Vector2 = girl.global_position
	AudioManager.play_sound("door", 0.6)
	girl.global_position = (get_parent() as Node2D).to_global(DOOR)
	if girl.modulate.a < 1.0:
		create_tween().tween_property(girl, "modulate:a", 1.0, 0.3)
	fx.spawn("water_hit", girl.global_position + Vector2(0, -8), Color(0.7, 0.85, 1.0))
	await _walk_npc(girl, spot, "up", 70.0)
