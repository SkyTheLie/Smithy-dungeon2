class_name Villager
extends CharacterBody2D
## A villager going about their day. With `spots` (VillagerSpot children) and `roads`
## (VillageRoads) they pick a goal, walk there along the streets and do what the spot is for:
## go into a house (disappear for a while), sit on a bench, look at flowers or a stall, or talk to
## another villager (both meet at a pair of TALK spots, speech bubbles take turns). Without spots
## they just stroll between the Marker2D children of `waypoints` (old behaviour).
## The look is a resident drawn with PixelLab (`resident`: assets/sprites/residents/<id>.png, same
## sheet layout as the player: 7 columns idle + walk, rows down/up/left/right, 48 px). Without one,
## the look comes from Appearance.from_seed(`look_seed`) and CharacterBaker (the old kit figures).
## While the story sends everybody away (story.json "villagers_away": {"from", "until"} flags, e.g.
## the spring festival) the villager is gone.
## Evening: every villager goes home at its own time between BEDTIME_FROM and BEDTIME_UNTIL (it
## finishes what it is doing, walks to the nearest house door and goes in) and comes out of a door
## again at its own time between WAKE_FROM and WAKE_UNTIL. The times are fixed per villager, so
## entering a scene at 19:30 shows about half of them still out. (Resident has its own day.)

const RESIDENT_DIR: String = "res://assets/sprites/residents/"
const BUBBLE: String = "res://assets/sprites/residents/talk_bubble.png"
## Sitting pose of a resident: <resident>_sit.png, one row of 48 px frames (down, up, left, right),
## feet on the same row as in the walk sheet.
const SIT_SUFFIX: String = "_sit"
const SIT_DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
## Sitting without a sitting pose: the clip polygon cuts the legs off at HIP_LINE (in
## villager.tscn), the body moves up.
const SIT_RAISE: float = 3.0
## Where a villager stands before sitting down on a bench (relative to the seat spot).
const BENCH_FRONT := Vector2(0, 16)
## Seconds without getting closer to the next point before a villager gives up the goal.
const STUCK_TIME: float = 1.5
## Stuck this close to the goal counts as arrived.
const ARRIVE_NEAR: float = 20.0
## Hours (in-game) in which the villagers go home, one after the other, and come out again.
const BEDTIME_FROM: float = 19.0
const BEDTIME_UNTIL: float = 20.0
const WAKE_FROM: float = 6.5
const WAKE_UNTIL: float = 8.0
## How often (seconds) the clock is checked.
const BEDTIME_CHECK: float = 0.5
## Getting stuck this often on the way home: it just goes in where it is.
const HOME_TRIES: int = 3

enum State { WAIT, WALK, BUSY }

## Id of a PixelLab resident (file name in assets/sprites/residents/ without .png).
@export var resident: String = ""
## Seed of the kit look, used when `resident` is empty (any text, e.g. "market_1").
@export var look_seed: String = "villager"
## Kit look set from outside (e.g. a fixed villager from npcs.json); wins over `look_seed`.
var appearance: Appearance
## Goals (VillagerSpot children) and the streets to reach them. Both set = goal-driven villager.
@export var spots: Node2D
@export var roads: VillageRoads
## Old behaviour: parent node of the Marker2D points the villager strolls between.
@export var waypoints: Node2D
@export var walk_speed: float = 34.0
## Seconds standing still between two goals (random in this range).
@export var pause: Vector2 = Vector2(2.0, 6.0)
## Off for guests indoors (inn, guild): they stay out all night instead of going home at bedtime.
@export var goes_home_at_night: bool = true
## Its own house door (a DOOR VillagerSpot): it goes in there at night and comes out there in the
## morning (inside, a HomeDweller with the same `night_key` shows it). Empty: the nearest door.
@export var home_spot: VillagerSpot

var _state: State = State.WAIT
var _wait: float = 0.0
var _path: PackedVector2Array = []
var _spot: VillagerSpot
var _last_motion: Vector2 = Vector2.DOWN
## Talk partner while meeting / talking.
var _partner: Villager
var _bubble: Sprite2D
## Stuck check while walking: closest distance to the next point so far, time without progress.
var _best_distance: float = INF
var _stuck_time: float = 0.0
## True when the resident has a drawn sitting pose ("sit_<direction>" animations).
var _has_sit_pose: bool = false
## Evening: inside for the night / on the way to a door; tries left on the way, next clock check.
var _asleep: bool = false
var _going_home: bool = false
var _home_tries: int = 0
var _bedtime_check: float = 0.0

@onready var _clip: Polygon2D = $Clip
@onready var _sprite: AnimatedSprite2D = $Clip/AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# top-down: everything it bumps into is a wall (grounded mode took the player for a floor and
	# rode along on him)
	motion_mode = MOTION_MODE_FLOATING
	# villagers walk past each other (they only bump into the player and the world)
	for other in get_tree().get_nodes_in_group("villagers"):
		add_collision_exception_with(other)
		(other as PhysicsBody2D).add_collision_exception_with(self)
	add_to_group("villagers")
	if not resident.is_empty() and ResourceLoader.exists(RESIDENT_DIR + resident + ".png"):
		_sprite.sprite_frames = CharacterBaker.make_frames(load(RESIDENT_DIR + resident + ".png"))
		_add_sit_pose(RESIDENT_DIR + resident + SIT_SUFFIX + ".png")
	else:
		var look: Appearance = appearance if appearance else Appearance.from_seed(look_seed, "")
		_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(look))
		_sprite.scale = Vector2.ONE * look.get_scale()
	_set_sitting(false)
	_sprite.play("idle_down")
	_wait = randf_range(0.0, pause.y)
	_bubble = Sprite2D.new()
	_bubble.texture = load(BUBBLE) if ResourceLoader.exists(BUBBLE) else null
	_bubble.position = Vector2(8, -42)
	_bubble.z_index = 2
	_bubble.hide()
	add_child(_bubble)
	GameState.story.changed.connect(_update_away)
	_update_away()
	# Entering the scene at night: already inside, without walking.
	if _uses_bedtime() and _is_night():
		_set_asleep(true)


## Gone while story.json "villagers_away" says so (e.g. everybody is at the spring festival).
func _update_away() -> void:
	var gone: bool = GameState.story.are_villagers_away()
	if gone == (process_mode == PROCESS_MODE_DISABLED):
		return
	visible = not gone and not _asleep
	process_mode = PROCESS_MODE_DISABLED if gone else PROCESS_MODE_INHERIT
	_collision.set_deferred("disabled", gone or _asleep)

func _physics_process(_delta: float) -> void:
	if _uses_bedtime() and _follow_bedtime(_delta):
		return
	match _state:
		State.WAIT:
			_wait -= _delta
			if _wait <= 0.0:
				_choose_goal()
		State.WALK:
			_walk()


## Free for a chat (another villager asks).
func is_free() -> bool:
	return _state == State.WAIT and visible and not _going_home and not (_uses_bedtime() and _is_night())


# --- evening and morning ------------------------------------------------------------------------

## Whether this villager goes home in the evening by itself (Resident: npcs.json decides).
func _uses_bedtime() -> bool:
	return goes_home_at_night


## 0..1, the same for this villager every time: where its bedtime / wake time lies in the hours.
func _get_bedtime_roll() -> float:
	return float(absi(hash(get_night_key())) % 1000) / 1000.0


## What its bedtime is rolled from: "<node name>|<resident>|<look seed>". A HomeDweller with the
## same key is inside exactly while this villager is (is_night_for).
func get_night_key() -> String:
	return "%s|%s|%s" % [name, resident, look_seed]


## True between its own bedtime and its own wake time.
func _is_night() -> bool:
	return is_night_for(get_night_key(), GameState.day_cycle.minutes)


## Whether the villager with `key` (get_night_key) is in bed at `minutes`.
static func is_night_for(key: String, minutes: float) -> bool:
	var hour: float = minutes / 60.0
	var roll: float = float(absi(hash(key)) % 1000) / 1000.0
	return hour >= lerpf(BEDTIME_FROM, BEDTIME_UNTIL, roll) or hour < lerpf(WAKE_FROM, WAKE_UNTIL, roll)


## Checks the clock now and then: goes home once it is free, comes out in the morning.
## Returns true while it is inside (nothing else to do).
func _follow_bedtime(delta: float) -> bool:
	_bedtime_check -= delta
	if _bedtime_check <= 0.0:
		_bedtime_check = BEDTIME_CHECK
		var night: bool = _is_night()
		if _asleep and not night:
			_wake_up()
		elif night and not _asleep and not _going_home and _state == State.WAIT and visible:
			_go_home()
	return _asleep


func _go_home() -> void:
	var door: VillagerSpot = _find_door(global_position)
	if door == null or not roads.is_ready() or _home_tries >= HOME_TRIES:
		_set_asleep(true)
		return
	_going_home = true
	_release_spot()
	_path = roads.find_path(global_position, door.road, door.global_position) if door.road \
			else PackedVector2Array([door.global_position])
	_start_walking()


## Nearest house door (VillagerSpot DOOR) to `from`, null without spots or roads.
func _find_door(from: Vector2) -> VillagerSpot:
	if spots == null or roads == null:
		return null
	if home_spot and _can_use_spot(home_spot):
		return home_spot
	var best: VillagerSpot = null
	for spot in spots.get_children():
		if spot is VillagerSpot and spot.kind == VillagerSpot.Kind.DOOR and _can_use_spot(spot):
			if best == null or from.distance_to(spot.global_position) < from.distance_to(best.global_position):
				best = spot
	return best


## Out of a house door (any one, so they don't all come out of the same house) in the morning.
func _wake_up() -> void:
	var doors: Array[VillagerSpot] = []
	if spots:
		for spot in spots.get_children():
			if spot is VillagerSpot and spot.kind == VillagerSpot.Kind.DOOR and _can_use_spot(spot):
				doors.append(spot)
	if home_spot and _can_use_spot(home_spot):
		global_position = home_spot.global_position
	elif not doors.is_empty():
		global_position = doors.pick_random().global_position
	_home_tries = 0
	_set_asleep(false)
	_wait = randf_range(pause.x, pause.y)


## Inside for the night (hidden, not in the way) or out again.
func _set_asleep(asleep: bool) -> void:
	_asleep = asleep
	_going_home = false
	if asleep:
		_release_spot()
		_path.clear()
		velocity = Vector2.ZERO
		_bubble.hide()
	_state = State.WAIT
	_stand("down")
	var shown: bool = not asleep and process_mode != PROCESS_MODE_DISABLED
	visible = shown
	_collision.set_deferred("disabled", not shown)


# --- goals --------------------------------------------------------------------------------------

func _choose_goal() -> void:
	if spots == null or roads == null:
		_choose_waypoint()
		return
	if not roads.is_ready():
		_wait = 0.2  # the streets are still being prepared
		return
	var free: Array[VillagerSpot] = []
	for spot in spots.get_children():
		if spot is VillagerSpot and spot.occupant == null and _can_use_spot(spot):
			if spot.kind == VillagerSpot.Kind.TALK and (spot.partner == null or spot.partner.occupant != null):
				continue
			free.append(spot)
	if free.is_empty():
		_wait = pause.y
		return
	var spot: VillagerSpot = free.pick_random()
	if spot.kind == VillagerSpot.Kind.TALK:
		var partner: Villager = _find_partner()
		if partner == null:
			_wait = randf_range(pause.x, pause.y)
			return
		_partner = partner
		partner.go_talk(spot.partner, self)
	_go_to(spot)


## Which spots this villager may pick as a goal (Resident: only its own door).
func _can_use_spot(_spot_to_check: VillagerSpot) -> bool:
	return true


func _find_partner() -> Villager:
	var candidates: Array[Villager] = []
	for other in get_tree().get_nodes_in_group("villagers"):
		if other != self and other is Villager and other.spots == spots and other.is_free():
			candidates.append(other)
	return candidates.pick_random() if not candidates.is_empty() else null


## Another villager asked for a chat at `spot`.
func go_talk(spot: VillagerSpot, partner: Villager) -> void:
	_partner = partner
	_go_to(spot)


func _go_to(spot: VillagerSpot) -> void:
	_spot = spot
	spot.occupant = self
	# a bench is solid: walk to the place in front of it, sit down from there
	var goal: Vector2 = spot.global_position + (BENCH_FRONT if spot.kind == VillagerSpot.Kind.BENCH else Vector2.ZERO)
	_path = roads.find_path(global_position, spot.road, goal) if spot.road else PackedVector2Array([goal])
	_start_walking()


func _start_walking() -> void:
	_best_distance = INF
	_stuck_time = 0.0
	_state = State.WALK


func _choose_waypoint() -> void:
	if waypoints == null or waypoints.get_child_count() == 0:
		_wait = pause.y
		return
	var point: Node2D = waypoints.get_child(randi() % waypoints.get_child_count())
	_spot = null
	_path = PackedVector2Array([point.global_position])
	_start_walking()


# --- walking ------------------------------------------------------------------------------------

func _walk() -> void:
	if _path.is_empty():
		_arrive()
		return
	var to: Vector2 = _path[0] - global_position
	if to.length() < 3.0:
		_path.remove_at(0)
		_best_distance = INF
		return
	velocity = to.normalized() * walk_speed
	move_and_slide()
	# stuck (the player, a stall, sliding along something): give up after STUCK_TIME without
	# getting closer to the next point, try another goal later
	var distance: float = global_position.distance_to(_path[0])
	if distance < _best_distance - 2.0:
		_best_distance = distance
		_stuck_time = 0.0
	else:
		_stuck_time += get_physics_process_delta_time()
		if _stuck_time > STUCK_TIME:
			if _path.size() == 1 and distance < ARRIVE_NEAR:
				_path.clear()  # right in front of the goal (a door in the wall): good enough
				return
			_give_up()
			return
	_last_motion = velocity
	_sprite.play("walk_" + _direction_name(velocity))


func _give_up() -> void:
	if _going_home:
		# try again from here (after HOME_TRIES it just goes in)
		_going_home = false
		_home_tries += 1
		_state = State.WAIT
		_bedtime_check = 0.0
		return
	if _partner and is_instance_valid(_partner):
		_partner._partner = null
	_partner = null
	_release_spot()
	_stand(_direction_name(_last_motion))
	_state = State.WAIT
	_wait = randf_range(pause.x, pause.y)


func _arrive() -> void:
	velocity = Vector2.ZERO
	if _going_home:
		_set_asleep(true)
		return
	if _spot == null:
		_stand(_direction_name(_last_motion))
		_state = State.WAIT
		_wait = randf_range(pause.x, pause.y)
		return
	_state = State.BUSY
	_stand(_spot.facing)
	match _spot.kind:
		VillagerSpot.Kind.DOOR:
			_enter_house()
		VillagerSpot.Kind.BENCH:
			_sit()
		VillagerSpot.Kind.TALK:
			_talk()
		_:
			_finish_after(randf_range(_spot.duration.x, _spot.duration.y))


# --- doing things -------------------------------------------------------------------------------

func _enter_house() -> void:
	hide()
	_collision.set_deferred("disabled", true)
	await get_tree().create_timer(randf_range(_spot.duration.x, _spot.duration.y), false).timeout
	if _uses_bedtime() and _is_night():
		_set_asleep(true)  # visiting at bedtime: stays inside for the night
		return
	show()
	_collision.set_deferred("disabled", false)
	_stand("down")
	_finish()


func _sit() -> void:
	var front: Vector2 = global_position
	_collision.set_deferred("disabled", true)
	global_position = _spot.global_position
	_set_sitting(true)
	await get_tree().create_timer(randf_range(_spot.duration.x, _spot.duration.y), false).timeout
	_set_sitting(false)
	global_position = front
	_collision.set_deferred("disabled", false)
	_finish()


## Both talkers wait for each other, then speech bubbles take turns over their heads.
func _talk() -> void:
	var waited: float = 0.0
	while _partner and is_instance_valid(_partner) and _partner._state != State.BUSY and waited < 20.0:
		await get_tree().create_timer(0.25, false).timeout
		waited += 0.25
	if _partner == null or not is_instance_valid(_partner) or _partner._state != State.BUSY:
		_partner = null
		_finish()
		return
	var talk_time: float = randf_range(_spot.duration.x, _spot.duration.y)
	var my_turn: bool = get_instance_id() < _partner.get_instance_id()
	var elapsed: float = 0.0
	while elapsed < talk_time:
		_bubble.visible = my_turn
		await get_tree().create_timer(1.3, false).timeout
		elapsed += 1.3
		my_turn = not my_turn
	_bubble.hide()
	_partner = null
	_finish()


func _finish_after(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	_finish()


func _finish() -> void:
	_release_spot()
	_state = State.WAIT
	_wait = randf_range(pause.x, pause.y)


func _release_spot() -> void:
	if _spot and _spot.occupant == self:
		_spot.occupant = null
	_spot = null


func _add_sit_pose(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var strip: Texture2D = load(path)
	var size: int = strip.get_height()
	for i in SIT_DIRECTIONS.size():
		var animation := StringName("sit_" + SIT_DIRECTIONS[i])
		_sprite.sprite_frames.add_animation(animation)
		var texture := AtlasTexture.new()
		texture.atlas = strip
		texture.region = Rect2(i * size, 0, size, size)
		_sprite.sprite_frames.add_frame(animation, texture)
	_has_sit_pose = true


## Sitting: with a drawn sitting pose that one is shown, otherwise the legs are hidden (the clip
## polygon ends at the hips) and the body sits higher.
func _set_sitting(sitting: bool) -> void:
	var cut_legs: bool = sitting and not _has_sit_pose
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY if cut_legs else CanvasItem.CLIP_CHILDREN_DISABLED
	_clip.self_modulate.a = 1.0 if cut_legs else 0.0  # the polygon itself is never visible
	_clip.position.y = -SIT_RAISE if cut_legs else 0.0
	if _has_sit_pose:
		_sprite.play("sit_" + _spot.facing if sitting else "idle_down")


func _stand(direction: String) -> void:
	_sprite.play("idle_" + direction)


static func _direction_name(motion: Vector2) -> String:
	if absf(motion.x) > absf(motion.y):
		return "right" if motion.x > 0.0 else "left"
	return "down" if motion.y > 0.0 else "up"
