class_name FinsterChase
extends StoryCutscene
## The chase in the Finsterstadt (part 7, chapter 1), fully scripted. When the player enters the city
## during STEP (through the south gate) and the intro (INTRO_FLAG) is over, he walks a few steps in
## and the dialogue of `narrator` starts.
## Its lines run the beats (story action "cutscene:<id>"):
## - chase_spotted: the baker `shouter` recognises him from the wanted poster, a red "!" over her
## - chase_guards: the gate guards burst in behind him (from `guard_gate`), each with a red "!"
## - chase_run: the player runs in one go along the road, into the alley and through the curtain to
##   `hide_spot` (the curtain swings by itself, CurtainGate). The guards follow a few steps behind,
##   never ahead of him; once he is behind the curtain they run past the alley along `guards_path`
##   and are gone. The start of the run sets PULLED_FLAG: the hooded figure and the two guards stand in
##   the winery's yard behind the curtain before he gets there.

const STEP: String = "finster_wanted"
## The intro on entering the city ("Kopf runter. Unauffällig."), the shout comes right after it.
const INTRO_FLAG: String = "finster_intro_seen"
const PULLED_FLAG: String = "chase_pulled"
const RUN_SPEED: float = 150.0
const COLOR_ALERT: Color = Color(1.0, 0.3, 0.25)
## How far the guards stay behind the player while they chase him (first runner, each further one more).
const CHASE_GAP: float = 80.0
const CHASE_GAP_STEP: float = 26.0
## Seconds after the player is behind the curtain before the guards run past the alley.
const PASS_DELAY: float = 0.5
## The player's way out of the yard behind Nyra: down the passage, through the curtain.
const EXIT_PATH: PackedVector2Array = [Vector2(265, -212), Vector2(265, -20)]
const GUARD_RESIDENTS: Array[String] = ["finster_warden_a", "finster_warden_b", "finster_warden_a"]

@export var narrator: StoryNpc
## Nyra (the hooded figure) in the yard, she leads the way out.
@export var nyra_path: NodePath
## The narrator of the intro on entering the city (INTRO_FLAG); started here if it didn't start by itself.
@export var intro_npc: StoryNpc
## The citizen who recognises the player.
@export var shouter: Node2D
## Where the player stands when the baker shouts (he walks there from the gate).
@export var enter_spot: Vector2 = Vector2(0, 250)
## Where the guards come from (the south gate, behind the player) and where they stop at first.
@export var guard_gate: Vector2 = Vector2(0, 392)
@export var guard_stop: PackedVector2Array = []
## The player's way to the alley (scene coordinates), the last point is the mouth of the alley.
@export var run_path: PackedVector2Array = []
## Behind the curtain in the alley.
@export var hide_spot: Vector2 = Vector2.ZERO
## Where the guards run after the player is gone (they disappear at the last point).
@export var guards_path: PackedVector2Array = []

var _started: bool = false
var _runners: Array[Sprite2D] = []
## true while the runners follow the player (from chase_run until he is behind the curtain).
var _chasing: bool = false
var _target: Node2D
var _walk_time: float = 0.0


func _ready() -> void:
	super()
	if GameState.story.step == STEP:
		_begin.call_deferred()
	elif _leads_here(GameState.story.step):
		# The step just before (south gate): entering this scene starts STEP, but the "enter:" event
		# comes a frame after _ready.
		GameState.story.step_started.connect(_on_step_started)


## true if entering this scene during `step` starts STEP (story "enter:<scene>" events).
func _leads_here(step: String) -> bool:
	var events: Dictionary = Story.get_data("steps").get(step, {}).get("events", {})
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	var scene_name: String = scene.scene_file_path.get_file().get_basename() if scene else "finster_city"
	return events.get("enter:" + scene_name, "") == STEP


func _on_step_started(step: String) -> void:
	if step == STEP:
		_begin()


## After the intro the player walks in from the gate, then the baker shouts (the dialogue starts).
func _begin() -> void:
	if _started or narrator == null:
		return
	if not GameState.story.has_flag(INTRO_FLAG):
		if not GameState.story.changed.is_connected(_on_story_changed):
			GameState.story.changed.connect(_on_story_changed)
		_start_intro()
		return
	_started = true
	if not await wait(0.4):
		return
	var body := player()
	if body and body.global_position.distance_to(enter_spot) < 160.0:
		walk_player(PackedVector2Array([enter_spot]), "up", 0.8)
		if not await wait(1.0):
			return
	narrator.talk()


## The intro narrator talks when the player walks into its area; spawning inside it right when the
## step changes doesn't always start it, so the chase starts it unless a dialogue is open already.
func _start_intro() -> void:
	if intro_npc == null or not await wait(0.5):
		return
	for box in get_tree().get_nodes_in_group(&"dialogue_boxes"):
		if box.get("visible"):
			return
	if not GameState.story.has_flag(INTRO_FLAG):
		intro_npc.talk()


func _on_story_changed() -> void:
	if GameState.story.has_flag(INTRO_FLAG) and GameState.story.step == STEP:
		GameState.story.changed.disconnect(_on_story_changed)
		_begin()


func _play_beat(id: String) -> bool:
	match id:
		"chase_spotted":
			if shouter:
				_pop_mark(shouter)
				face_npc(shouter, "down")
			face_player("up")
		"chase_guards":
			_guards_burst_in()
		"chase_run":
			_run()
		"yard_exit":
			_yard_exit()
		_:
			return false
	return true


func _pop_mark(over: Node2D) -> void:
	var mark := Label.new()
	mark.text = "!"
	mark.position = Vector2(-4, -64)
	mark.add_theme_font_size_override("font_size", 22)
	mark.add_theme_color_override("font_color", COLOR_ALERT)
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 4)
	over.add_child(mark)
	get_tree().create_timer(2.5, false).timeout.connect(mark.queue_free)


## The guards run in through the gate behind the player and stop there, looking at him.
func _guards_burst_in() -> void:
	for i in GUARD_RESIDENTS.size():
		var runner := extra(GUARD_RESIDENTS[i], guard_gate + Vector2((i - 1) * 14, i * 6), "up")
		_runners.append(runner)
		_pop_mark(runner)
		if i < guard_stop.size():
			walk_extra(runner, PackedVector2Array([guard_stop[i]]), RUN_SPEED, "up")


## The player runs to the alley and through the curtain, the guards follow behind him.
func _run() -> void:
	var body := player()
	if body == null:
		return
	_target = body
	var way := PackedVector2Array()
	# from the gate road first up to the main road, then along it (not across the houses)
	if body.global_position.y > run_path[0].y + 40.0 and absf(body.global_position.x) < 60.0:
		way.append(Vector2(body.global_position.x, run_path[0].y))
	way.append_array(run_path)
	way.append(hide_spot)
	body.call("auto_walk", way, "up", RUN_SPEED)
	_chasing = true
	# the hooded figure and the two guards are in the yard already when he gets there (he is far away now)
	GameState.story.set_flag(PULLED_FLAG)
	if body.has_signal("auto_walk_finished"):
		body.connect("auto_walk_finished", _on_hidden, CONNECT_ONE_SHOT)


## Behind the curtain: the hooded figure appears, the guards run past the alley and are gone.
func _on_hidden() -> void:
	if not await wait(PASS_DELAY):
		return
	_chasing = false
	for i in _runners.size():
		var runner := _runners[i]
		if is_instance_valid(runner):
			_pass_by(runner, 0.2 * i)


func _pass_by(runner: Sprite2D, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return
	walk_extra(runner, guards_path, RUN_SPEED, "", true)


## While chasing, every runner runs towards the player but stops a few steps behind him.
func _process(delta: float) -> void:
	if not _chasing or not is_instance_valid(_target):
		return
	_walk_time += delta
	var target: Vector2 = _target.global_position
	# into the alley they don't follow: they stay on the main road
	if not run_path.is_empty():
		target.y = maxf(target.y, run_path[0].y)
	for i in _runners.size():
		var runner := _runners[i]
		if not is_instance_valid(runner):
			continue
		var distance: float = runner.global_position.distance_to(target)
		var gap: float = CHASE_GAP + CHASE_GAP_STEP * i
		# along the roads, straight (no running across the corner): first up the gate road to the
		# main road, then along it
		var goal: Vector2 = target
		if not run_path.is_empty() and runner.global_position.y > run_path[0].y + 2.0 and target.y < runner.global_position.y:
			goal = Vector2(runner.global_position.x, maxf(run_path[0].y, target.y))
		elif not run_path.is_empty() and absf(runner.global_position.y - run_path[0].y) <= 2.0:
			goal = Vector2(target.x, run_path[0].y)
		var offset: Vector2 = goal - runner.global_position
		var direction: String = SneakGuard._direction_of(offset if offset.length() > 0.5 else target - runner.global_position)
		if distance > gap and offset.length() > 0.5:
			runner.global_position += offset.normalized() * minf(RUN_SPEED * 0.95 * delta, minf(offset.length(), distance - gap))
			runner.region_rect = CharacterBaker.get_frame_rect(direction,
					1 + int(_walk_time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1))
		else:
			runner.region_rect = CharacterBaker.get_frame_rect(direction)


## After the talk in the yard (box hidden): Nyra goes ahead along the passage and through the curtain,
## the player follows her a moment later. The next line and the dialogue's end take him to the hideout.
func _yard_exit() -> void:
	var nyra := node2d(nyra_path)
	if nyra:
		walk_npc(nyra, PackedVector2Array([Vector2(nyra.global_position.x, EXIT_PATH[0].y)]) + EXIT_PATH, 95.0, "down")
	var body := player()
	if body == null or not await wait(0.7):
		return
	body.call("auto_walk", PackedVector2Array([Vector2(body.global_position.x, EXIT_PATH[0].y),
			EXIT_PATH[0], EXIT_PATH[1] + Vector2(0, -26)]), "down", 90.0)


## The runners of the chase (for tests).
func get_runners() -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for runner in _runners:
		if is_instance_valid(runner):
			result.append(runner)
	return result
