class_name BallKids
extends Node2D
## Two children playing with a ball during the day. They come out of a house door at PLAY_FROM,
## walk to their place and play until PLAY_UNTIL, then walk to the nearest door and go in.
## Two games, they switch every now and then (and walk over to the other place):
## - toss (where the node stands): the ball flies in an arc from hand to hand, the child who
##   catches it hops a little;
## - football (at `soccer_spot`): they stand further apart and kick the ball along the ground
##   from left to right and back; the receiver steps up or down to where the ball rolls.
## The children are PixelLab residents (assets/sprites/residents/<id>.png, see Villager).
## The node itself moves (it is the middle between the two children); a StoryHider may hide the
## whole node, the children's own visibility (day / night) is set here.

## Resident ids of the left and the right child.
@export var left_child: String = "girl_red"
@export var right_child: String = "girl_braids"
## Seconds the ball is in the air, and the pause before it is thrown back.
@export var flight_time: float = 0.9
@export var hold_time: float = 0.7
## How high the ball flies (pixels).
@export var arc_height: float = 22.0
## Where they play football (global position, middle between the two). Zero = no football.
@export var soccer_spot: Vector2 = Vector2.ZERO
## House doors (VillagerSpot DOOR children) and the streets of the map, for coming and going.
@export var spots: Node2D
@export var roads: VillageRoads

## Hand height above the feet (children are small).
const HAND_HEIGHT: float = 9.0
## The ball is held a little in front of the body, towards the other child.
const HAND_REACH: float = 7.0
## Hours (in-game) they are out playing.
const PLAY_FROM: float = 8.0
const PLAY_UNTIL: float = 18.0
## In-game minutes one game lasts before they switch (random in this range).
const GAME_MINUTES := Vector2(60.0, 150.0)
## Half the distance between the two children: tossing, football, walking side by side.
const TOSS_SPREAD: float = 36.0
const SOCCER_SPREAD: float = 46.0
const WALK_SPREAD: float = 7.0
const WALK_SPEED: float = 30.0
## Football: seconds the ball rolls, how far up or down the receiver may have to go, ball at
## the feet a little in front of the body, how far the ball turns while rolling.
const KICK_TIME := Vector2(0.8, 1.2)
const KICK_SPREAD_Y: float = 10.0
const FOOT_REACH: float = 6.0
const FOOT_HEIGHT: float = 2.0
const ROLL_TURNS: float = 3.0

enum Game { TOSS, SOCCER }

var _game: Game = Game.TOSS
var _game_until: float = 0.0
var _out: bool = false
var _home: Vector2

@onready var _left: AnimatedSprite2D = $Left/Sprite
@onready var _right: AnimatedSprite2D = $Right/Sprite
@onready var _ball: Sprite2D = $Ball


func _ready() -> void:
	_home = global_position
	_left.sprite_frames = CharacterBaker.make_frames(load(Villager.RESIDENT_DIR + left_child + ".png"))
	_right.sprite_frames = CharacterBaker.make_frames(load(Villager.RESIDENT_DIR + right_child + ".png"))
	if _is_play_time():
		# entering the scene during the day: already playing one of the games
		_pick_game(Game.SOCCER if _has_soccer() and randf() < 0.5 else Game.TOSS)
		global_position = _place(_game)
		_spread(_spread_of(_game))
		_set_out(true)
	else:
		_set_out(false)
	_life.call_deferred()


# --- day ----------------------------------------------------------------------------------------

func _hour() -> float:
	return GameState.day_cycle.minutes / 60.0


func _is_play_time() -> bool:
	var hour: float = _hour()
	return hour >= PLAY_FROM and hour < PLAY_UNTIL


func _has_soccer() -> bool:
	return soccer_spot != Vector2.ZERO


func _place(game: Game) -> Vector2:
	return soccer_spot if game == Game.SOCCER else _home


func _spread_of(game: Game) -> float:
	return SOCCER_SPREAD if game == Game.SOCCER else TOSS_SPREAD


func _pick_game(game: Game) -> void:
	_game = game
	_game_until = GameState.day_cycle.minutes + randf_range(GAME_MINUTES.x, GAME_MINUTES.y)


## Shown and solid while they are out; inside (night) hidden and without collision.
func _set_out(out: bool) -> void:
	_out = out
	for child: Node2D in [$Left, $Right]:
		child.visible = out
	_ball.visible = out
	_update_collision()


## Solid only while out and not hidden by the story (StoryHider switches the whole node off).
func _update_collision() -> void:
	var solid: bool = _out and visible
	for shape: CollisionShape2D in [$Left/CollisionShape2D, $Right/CollisionShape2D]:
		if shape.disabled == solid:
			shape.set_deferred("disabled", not solid)


## The whole day: come out, play (switching games now and then), go home in the evening.
func _life() -> void:
	while is_inside_tree():
		_update_collision()
		if not _is_play_time():
			if _out:
				await _go_home()
			else:
				await get_tree().create_timer(0.5, false).timeout
			continue
		if not _out:
			await _come_out()
			continue
		if _has_soccer() and GameState.day_cycle.minutes >= _game_until:
			await _switch_game()
			continue
		if _game == Game.SOCCER:
			await _kick(randf() < 0.5)
		else:
			await _toss(randf() < 0.5)


func _come_out() -> void:
	var door: Node2D = _nearest_door(_home)
	global_position = door.global_position if door else _home
	_spread(WALK_SPREAD)
	_set_out(true)
	_ball.hide()
	_pick_game(Game.TOSS)
	await _walk_to(_home)
	await _arrange(TOSS_SPREAD)


func _go_home() -> void:
	var door: Node2D = _nearest_door(global_position)
	if door:
		await _walk_to(door.global_position)
	_set_out(false)


func _switch_game() -> void:
	var next: Game = Game.TOSS if _game == Game.SOCCER else Game.SOCCER
	_pick_game(next)
	await _walk_to(_place(next))
	await _arrange(_spread_of(next))


func _nearest_door(from: Vector2) -> Node2D:
	if spots == null:
		return null
	var best: Node2D = null
	for spot in spots.get_children():
		if spot is VillagerSpot and spot.kind == VillagerSpot.Kind.DOOR:
			if best == null or from.distance_to(spot.global_position) < from.distance_to(best.global_position):
				best = spot
	return best


# --- walking ------------------------------------------------------------------------------------

## Both close together, then along the streets (around houses and benches) to `goal`.
func _walk_to(goal: Vector2) -> void:
	_ball.hide()
	await _arrange(WALK_SPREAD)
	var path := PackedVector2Array([goal])
	if roads and roads.is_ready():
		path = roads.plan_through(global_position, PackedVector2Array([goal]))
	for point in path:
		var way: Vector2 = point - global_position
		if way.length() < 0.5:
			continue
		var animation: String = "walk_" + _direction(way)
		_left.play(animation)
		_right.play(animation)
		var tween := create_tween()
		tween.tween_property(self, "global_position", point, way.length() / WALK_SPEED)
		await tween.finished
		if not is_inside_tree():
			return
	_left.play("idle_down")
	_right.play("idle_down")


## The children walk apart (or together) to `spread` either side and face each other.
func _arrange(spread: float) -> void:
	var moves: Array = []
	for pair in [[$Left, -spread, _left], [$Right, spread, _right]]:
		var way: Vector2 = Vector2(pair[1], 0.0) - (pair[0] as Node2D).position
		if way.length() >= 0.5:
			moves.append([pair[0], Vector2(pair[1], 0.0), pair[2], way])
	if not moves.is_empty():
		var tween := create_tween().set_parallel()
		for move in moves:
			(move[2] as AnimatedSprite2D).play("walk_" + _direction(move[3]))
			tween.tween_property(move[0], "position", move[1], (move[3] as Vector2).length() / WALK_SPEED)
		await tween.finished
	_face()


## Puts the children `spread` either side at once, facing each other.
func _spread(spread: float) -> void:
	$Left.position = Vector2(-spread, 0)
	$Right.position = Vector2(spread, 0)
	_face()
	_ball.position = _hand($Left)
	_ball.rotation = 0.0


func _face() -> void:
	_left.play("idle_right")
	_right.play("idle_left")


func _direction(way: Vector2) -> String:
	if absf(way.x) >= absf(way.y):
		return "right" if way.x > 0.0 else "left"
	return "down" if way.y > 0.0 else "up"


# --- toss ---------------------------------------------------------------------------------------

func _hand(child: Node2D) -> Vector2:
	var towards: float = signf(-child.position.x)
	return child.position + Vector2(towards * HAND_REACH, -HAND_HEIGHT)


func _toss(from_left: bool) -> void:
	var thrower: Node2D = $Left if from_left else $Right
	_ball.rotation = 0.0
	_ball.position = _hand(thrower)
	_ball.show()
	await get_tree().create_timer(hold_time + randf() * 0.4, false).timeout
	if not is_inside_tree():
		return
	var start: Vector2 = _hand(thrower)
	var end: Vector2 = _hand($Right if from_left else $Left)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_ball.position = start.lerp(end, t) + Vector2(0, -arc_height * 4.0 * t * (1.0 - t)),
		0.0, 1.0, flight_time)
	await tween.finished
	_hop(_right if from_left else _left)


## The catching child jumps up a few pixels.
func _hop(child: AnimatedSprite2D) -> void:
	var base: float = child.position.y
	var tween := create_tween()
	tween.tween_property(child, "position:y", base - 4.0, 0.1)
	tween.tween_property(child, "position:y", base, 0.12)


# --- football -----------------------------------------------------------------------------------

func _foot(child: Node2D) -> Vector2:
	var towards: float = signf(-child.position.x)
	return child.position + Vector2(towards * FOOT_REACH, -FOOT_HEIGHT)


## One kick: the kicker steps into the ball, it rolls (slowing down, turning) to the other side,
## the receiver walks up or down to meet it and stops it.
func _kick(from_left: bool) -> void:
	var kicker: Node2D = $Left if from_left else $Right
	var receiver: Node2D = $Right if from_left else $Left
	var receiver_sprite: AnimatedSprite2D = _right if from_left else _left
	var kicker_sprite: AnimatedSprite2D = _left if from_left else _right
	_ball.position = _foot(kicker)
	_ball.show()
	await get_tree().create_timer(hold_time * 0.6 + randf() * 0.5, false).timeout
	if not is_inside_tree():
		return
	# step into the ball
	var towards: float = signf(-kicker.position.x)
	var step := create_tween()
	kicker_sprite.play("walk_" + ("right" if towards > 0.0 else "left"))
	step.tween_property(kicker, "position:x", kicker.position.x + towards * 3.0, 0.12)
	await step.finished
	# the ball rolls, the receiver goes to where it will end
	var target_y: float = clampf(receiver.position.y + randf_range(-KICK_SPREAD_Y, KICK_SPREAD_Y), -KICK_SPREAD_Y, KICK_SPREAD_Y)
	var time: float = randf_range(KICK_TIME.x, KICK_TIME.y)
	var end: Vector2 = Vector2(receiver.position.x, target_y) + Vector2(-towards * FOOT_REACH, -FOOT_HEIGHT)
	var roll := create_tween()
	roll.tween_property(_ball, "position", end, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	roll.parallel().tween_property(_ball, "rotation", _ball.rotation + towards * TAU * ROLL_TURNS, time) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var meet := create_tween()
	var way: float = target_y - receiver.position.y
	if absf(way) > 1.0:
		receiver_sprite.play("walk_" + ("down" if way > 0.0 else "up"))
		meet.tween_property(receiver, "position:y", target_y, minf(time * 0.8, absf(way) / WALK_SPEED + 0.1))
	meet.tween_callback(func() -> void: receiver_sprite.play("idle_" + ("left" if towards > 0.0 else "right")))
	# kicker steps back
	var back := create_tween()
	back.tween_property(kicker, "position:x", kicker.position.x - towards * 3.0, 0.2)
	back.tween_callback(func() -> void: kicker_sprite.play("idle_" + ("right" if towards > 0.0 else "left")))
	await roll.finished
	if not is_inside_tree():
		return
	# a stop with the foot: tiny hop
	_hop(receiver_sprite)
