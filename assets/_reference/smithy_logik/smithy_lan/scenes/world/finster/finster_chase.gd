class_name FinsterChase
extends Node2D
## The chase in the Finsterstadt (part 7, chapter 1). While the story is at STEP, guards (SneakGuard
## children of `watch`) stand at the square. As soon as one of them sees the player, or he walks into
## `trigger`, the dialogue of `narrator` starts by itself. Its lines run the cutscenes (story action
## "cutscene:<id>", like GoblinThroneCutscene):
## - chase_spotted: a red "!" over every guard
## - chase_run: the player runs along `run_path` to the mouth of the alley, the guards run after him
##   along `guards_path` (past the alley)
## - chase_pull: a hand pulls him behind the curtain (he runs to `hide_spot`, flag PULLED_FLAG makes the hooded
##   figure appear), the guards run on past the alley along `guards_path` and are gone
## Outside of STEP the watching guards are not there.

const STEP: String = "finster_wanted"
const PULLED_FLAG: String = "chase_pulled"
const RUN_SPEED: float = 150.0
const COLOR_ALERT: Color = Color(1.0, 0.3, 0.25)

@export var watch: Node2D
@export var trigger: Area2D
@export var narrator: StoryNpc
## Sprite sheet of the curtain at the mouth of the alley, swings once when the player is pulled through.
@export var curtain: Sprite2D
## Where the player runs (scene coordinates), the last point is the mouth of the alley.
@export var run_path: PackedVector2Array = []
## Behind the curtain in the alley.
@export var hide_spot: Vector2 = Vector2.ZERO
## Where the guards run after the player is gone (they disappear at the last point).
@export var guards_path: PackedVector2Array = []

var _started: bool = false
var _runners: Array[Node2D] = []


func _ready() -> void:
	if GameState.story.step != STEP:
		# The step just before (south gate): entering this scene starts STEP, but the "enter:" event
		# comes a frame after _ready. Until then the guards are hidden.
		if _leads_here(GameState.story.step):
			if watch:
				watch.visible = false
			GameState.story.step_started.connect(_on_step_started)
		else:
			if watch:
				watch.queue_free()
			return
	Events.cutscene_requested.connect(_on_cutscene)
	if trigger:
		trigger.body_entered.connect(func(body: Node2D) -> void:
			if body is Player:
				_start())
	if watch:
		for guard in watch.get_children():
			if guard is SneakGuard:
				(guard as SneakGuard).spotted.connect(func(_guard: SneakGuard) -> void: _start())


## true if entering this scene during `step` starts STEP (story.json events "enter:<scene>").
func _leads_here(step: String) -> bool:
	var events: Dictionary = Story.get_data("steps").get(step, {}).get("events", {})
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	var scene_name: String = scene.scene_file_path.get_file().get_basename() if scene else "finster_city"
	return events.get("enter:" + scene_name, "") == STEP


func _on_step_started(step: String) -> void:
	if step == STEP and is_instance_valid(watch):
		watch.visible = true


func _start() -> void:
	if _started or GameState.story.step != STEP or narrator == null:
		return
	_started = true
	narrator.talk.call_deferred()


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"chase_spotted":
			for guard in _guards():
				_pop_mark(guard)
		"chase_run":
			_run()
		"chase_pull":
			_pull()


func _guards() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if is_instance_valid(watch):
		for guard in watch.get_children():
			if guard is SneakGuard:
				result.append(guard)
	return result


func _pop_mark(over: Node2D) -> void:
	var mark := Label.new()
	mark.text = "!"
	mark.position = Vector2(-4, -64)
	mark.add_theme_font_size_override("font_size", 22)
	mark.add_theme_color_override("font_color", COLOR_ALERT)
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 4)
	over.add_child(mark)


## The player runs to the alley, each guard is replaced by a runner that follows him a bit behind.
func _run() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player and not run_path.is_empty():
		player.auto_walk(run_path, "up", RUN_SPEED)
	for guard in _guards():
		var runner := _make_runner(guard)
		guard.queue_free()
		_runners.append(runner)
		_walk_along(runner, guards_path, 0.5 + randf() * 0.3)


## Behind the curtain: the player is pulled into the alley, the guards run past and are gone.
func _pull() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player:
		# Through the mouth of the alley, not across the houses.
		var way := PackedVector2Array([run_path[-1]] if not run_path.is_empty() else [])
		way.append(hide_spot)
		player.auto_walk(way, "up", RUN_SPEED)
	if curtain:
		curtain.frame = 0
		create_tween().tween_property(curtain, "frame", curtain.hframes - 1, 0.9)
	GameState.story.set_flag(PULLED_FLAG)


func _make_runner(guard: Node2D) -> Node2D:
	var runner := Node2D.new()
	runner.position = guard.position
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.offset = Vector2(0, -13)
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(str(guard.get("resident")))
	var look: Appearance = guard.get("appearance")
	if sheet:
		sprite.sprite_frames = CharacterBaker.make_frames(sheet)
	elif look:
		sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(look))
	runner.add_child(sprite)
	guard.get_parent().add_child(runner)
	return runner


## Walks `figure` from point to point (straight lines, walk animation), frees it at the end.
func _walk_along(figure: Node2D, points: PackedVector2Array, delay: float) -> void:
	var sprite := figure.get_node("Sprite") as AnimatedSprite2D
	var tween := figure.create_tween()
	tween.tween_interval(delay)
	var from: Vector2 = figure.position
	for point in points:
		var offset: Vector2 = point - from
		var facing: String = SneakGuard._direction_of(offset)
		tween.tween_callback(func() -> void:
			if sprite.sprite_frames:
				sprite.play(StringName("walk_" + facing)))
		tween.tween_property(figure, "position", point, offset.length() / RUN_SPEED)
		from = point
	tween.tween_callback(figure.queue_free)
