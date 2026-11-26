class_name GoblinThroneCutscene
extends StoryCutscene
## The audience with the goblin king (part 2, chapter 7) plays by itself while the dialogue runs:
## the dialogue lines start each part with the story action "cutscene:<id>" (GameState
## .cutscene_requested) and wait for it ("wait" seconds).
## - crowd_gold: the crowd shouts "Gold!" (words pop up over the goblins)
## - crowd_food: a thin voice at the back: "Essen?"
## - silence: everybody turns to look at the hungry goblin
## - king_alert: a red "!" above the king
## - crowd_throw: the goblins around him lift him up and throw him in a high arc out of the crowd
##   into the middle, in front of the throne, where he lands on his bottom
## - goblin_fall: two guards carry him through the lane in the crowd (`lane`) to the edge of the
##   platform and throw him down (flag THROWN_FLAG: he is gone for good)
## The goblins of the crowd are the GoblinFigure children of `crowd`.

const THROWN_FLAG: String = "goblin_thrown"
const SHOUTS: Array[String] = ["Gold!", "GOLD!", "Gold! Gold!", "Mehr Gold!", "GOLD!!"]
const COLOR_SHOUT: Color = Color(1.0, 0.85, 0.3)
const COLOR_ALERT: Color = Color(0.95, 0.25, 0.2)
const FONT_SIZE: int = 11

## GoblinFigures of the crowd (children of this node).
@export var crowd: Node2D
## The goblin who asks for food (a GoblinFigure in the crowd).
@export var hungry: GoblinFigure
## Where the king sits (for the "!") and the middle of the platform in front of the throne.
@export var king: Node2D
@export var middle: Vector2 = Vector2.ZERO
## The two guards that throw him down, and the point at the edge of the platform where they do.
@export var guard_west: GoblinFigure
@export var guard_east: GoblinFigure
@export var edge: Vector2 = Vector2.ZERO
## A point in the lane through the crowd the guards carry him through (ZERO = straight to the edge).
@export var lane: Vector2 = Vector2.ZERO

## The throw: how high the arc goes, how long it flies, and how close the goblins that throw stand.
const THROW_HEIGHT: float = 46.0
const THROW_TIME: float = 0.9
const THROWER_DISTANCE: float = 40.0
## Height of the middle of a goblin's body over its feet (pixels).
const BODY_HEIGHT: float = 16.0


func _ready() -> void:
	super()
	for guard: GoblinFigure in [guard_west, guard_east]:
		if guard:
			guard.set_meta("home", guard.position)


func _play_beat(id: String) -> bool:
	match id:
		"crowd_gold":
			for i in 12:
				get_tree().create_timer(i * 0.28, false).timeout.connect(_shout_random)
		"crowd_food":
			if is_instance_valid(hungry):
				_pop_text(hungry, Language.translate("Essen?"), Color(0.85, 0.85, 0.85))
		"silence":
			if is_instance_valid(hungry):
				for figure in _figures():
					if figure != hungry:
						figure.face("right" if hungry.position.x > figure.position.x else "left")
		"king_alert":
			if king:
				_pop_text(king, "!", COLOR_ALERT, 22, 2.0)
		"crowd_throw":
			if is_instance_valid(hungry):
				_throw_into_middle()
		"goblin_fall":
			if is_instance_valid(hungry):
				_carry_to_edge()
		_:
			return false
	return true


func _figures() -> Array[GoblinFigure]:
	var result: Array[GoblinFigure] = []
	if crowd:
		for child in crowd.get_children():
			if child is GoblinFigure:
				result.append(child)
	return result


func _shout_random() -> void:
	var figures: Array[GoblinFigure] = _figures().filter(func(figure: GoblinFigure) -> bool: return figure != hungry)
	if not figures.is_empty():
		var shouter: GoblinFigure = figures.pick_random()
		_pop_text(shouter, SHOUTS.pick_random(), COLOR_SHOUT)
		shouter.hop()
		figures.pick_random().hop(0.1)


## A word that rises over `over` and fades.
func _pop_text(over: Node2D, text: String, color: Color, size: int = FONT_SIZE, seconds: float = 1.2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.13, 0.07, 0.12))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 20
	add_child(label)
	label.global_position = over.global_position + Vector2(-label.get_minimum_size().x / 2.0, -58)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 14.0, seconds)
	tween.parallel().tween_property(label, "modulate:a", 0.0, seconds).set_delay(seconds * 0.5)
	tween.tween_callback(label.queue_free)


## The goblins around him heave him up (they hop twice), then he flies in a high arc with a
## somersault into the middle in front of the throne and lands with a bump.
func _throw_into_middle() -> void:
	var throwers: Array[GoblinFigure] = _figures().filter(func(figure: GoblinFigure) -> bool:
		return figure != hungry and figure.position.distance_to(hungry.position) < THROWER_DISTANCE)
	for thrower in throwers:
		thrower.face("right" if hungry.position.x > thrower.position.x else "left")
		thrower.hop()
		get_tree().create_timer(0.3, false).timeout.connect(thrower.hop)
	hungry.reparent(self)
	hungry.z_index = 5  # over the heads of the crowd while it flies
	var start: Vector2 = hungry.position
	var tween := hungry.create_tween()
	# heaved up: a short lift on the hands of the crowd
	tween.tween_property(hungry, "position", start + Vector2(0, -12), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t: float) -> void:
		# the somersault turns round the middle of the body, not round the feet
		var spin: float = TAU * t * (1.0 if middle.x > start.x else -1.0)
		var body: Vector2 = Vector2(0, -BODY_HEIGHT)
		hungry.rotation = spin
		hungry.position = start.lerp(middle, t) + Vector2(0, -12 * (1.0 - t) - 4.0 * THROW_HEIGHT * t * (1.0 - t)) 				+ body - body.rotated(spin),
		0.0, 1.0, THROW_TIME)
	tween.tween_callback(func() -> void:
		hungry.rotation = 0.0
		hungry.z_index = 0
		hungry.face("up")
		_pop_text(hungry, Language.translate("Uff!"), Color(0.85, 0.85, 0.85)))
	# landing: squashed flat for a moment
	tween.tween_property(hungry, "scale", Vector2(1.25, 0.75), 0.08)
	tween.tween_property(hungry, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The guards walk to him, all three go to the edge, then he flies down into the depth.
func _carry_to_edge() -> void:
	if guard_west:
		guard_west.walk_to(middle + Vector2(-12, 0), 70.0)
	if guard_east:
		guard_east.walk_to(middle + Vector2(12, 0), 70.0, _walk_to_edge)
	else:
		_walk_to_edge()


func _walk_to_edge() -> void:
	if lane == Vector2.ZERO:
		_walk_lane_to_edge()
		return
	if guard_west:
		guard_west.walk_to(lane + Vector2(-12, 0), 55.0)
	if guard_east:
		guard_east.walk_to(lane + Vector2(12, 0), 55.0)
	hungry.walk_to(lane, 55.0, _walk_lane_to_edge)


func _walk_lane_to_edge() -> void:
	if guard_west:
		guard_west.walk_to(edge + Vector2(-12, -6), 55.0)
	if guard_east:
		guard_east.walk_to(edge + Vector2(12, -6), 55.0)
	hungry.walk_to(edge, 55.0, _fall)


func _fall() -> void:
	GameState.story.set_flag(THROWN_FLAG)
	_pop_text(hungry, Language.translate("Waaaah!"), Color(0.85, 0.85, 0.85), FONT_SIZE, 1.6)
	var tween := hungry.create_tween()
	tween.tween_property(hungry, "position", hungry.position + Vector2(10, -16), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(hungry, "position", hungry.position + Vector2(24, 140), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(hungry, "scale", Vector2(0.4, 0.4), 1.1)
	tween.parallel().tween_property(hungry, "modulate:a", 0.0, 1.1)
	tween.tween_callback(hungry.queue_free)
	# the guards go back to their posts (through the lane)
	for guard: GoblinFigure in [guard_west, guard_east]:
		if guard:
			var home: Vector2 = guard.get_meta("home", guard.position)
			if lane == Vector2.ZERO:
				get_tree().create_timer(1.2, false).timeout.connect(guard.walk_to.bind(home, 55.0))
			else:
				var side: Vector2 = Vector2(-12 if guard == guard_west else 12, 0)
				var back: Callable = guard.walk_to.bind(home, 55.0, guard.face.bind("down"))
				get_tree().create_timer(1.2, false).timeout.connect(guard.walk_to.bind(lane + side, 55.0, back))
