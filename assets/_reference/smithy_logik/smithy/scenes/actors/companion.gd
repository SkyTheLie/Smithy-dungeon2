class_name Companion
extends Node2D
## A figure that walks along behind the player for a part of the story (e.g. Bruno on the way to
## the market during the raid, Lotte on the way home). There from `required_flag`
## until `hidden_when_flag`: it appears next to the player and keeps a few steps behind. It does not
## block the player (no body) and catches up if it falls far behind (e.g. after a door).
## The look: a PixelLab resident (`resident`), a hero template (`hero`) or an Appearance.
## With an `npc_id` it can speak in dialogues of the scene (portrait like a StoryNpc).

## Id in story.json "npcs" (for its name and portrait when it speaks in a dialogue).
@export var npc_id: String = ""
@export var resident: String = ""
@export var hero: Hero
@export var appearance: Appearance
## Story flag from which it walks along (empty = from the start).
@export var required_flag: String = ""
## Story flag from which it is gone.
@export var hidden_when_flag: String = ""
## Distance it keeps from the player.
@export var follow_distance: float = 22.0
## Walks right next to the player at this distance instead of behind him (someone he supports).
@export var side_distance: float = 0.0

## Where it appears, relative to the player.
const APPEAR_OFFSET := Vector2(-18, 8)
## Slower than this it never walks (pixels per second); it speeds up when far behind.
const MIN_SPEED: float = 90.0
## Further away than this it jumps next to the player (e.g. the player sprinted round a corner).
const CATCH_UP_DISTANCE: float = 160.0

## Supported figure (side_distance > 0): how many pixels behind the player (drawn behind him).
const SUPPORT_BEHIND: float = 2.0
## Supported figure: how fast he slides to the player's shoulder when the player turns.
const SUPPORT_FOLLOW: float = 14.0
## Supported figure standing: this walk frame (bent, the limp sheet) instead of standing straight.
const SUPPORTED_REST_FRAME: int = 2

var _last_player_at: Vector2 = Vector2.INF
## Supported figure: a direction a cut scene turned him to (face); kept until the player walks.
var _held_facing: String = ""
var _sprite: AnimatedSprite2D
var _facing: String = "down"
## Ran off in a cut scene (run_off): stays away until it should be here no longer.
var _gone: bool = false


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"  # NpcActing.figure_of
	_sprite.position = Vector2(0, -13)
	add_child(_sprite)
	var look: Appearance = appearance if appearance else (hero.get_appearance() if hero else null)
	var sheet_path: String = Villager.RESIDENT_DIR + resident + ".png"
	if not resident.is_empty() and ResourceLoader.exists(sheet_path):
		_sprite.sprite_frames = CharacterBaker.make_frames(load(sheet_path))
	elif look:
		_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(look))
		_sprite.scale = Vector2.ONE * look.get_scale()
	_sprite.play("idle_down")
	if not npc_id.is_empty():
		add_to_group(StoryNpc.GROUP)
	GameState.story.changed.connect(_update)
	Events.cutscene_requested.connect(_on_cutscene)
	visible = false
	_update()


## Portrait for the dialogue box (it takes part in conversations like a StoryNpc).
func get_portrait() -> Texture2D:
	var sheet_path: String = Villager.RESIDENT_DIR + resident + ".png"
	if not resident.is_empty() and ResourceLoader.exists(sheet_path):
		return CharacterBaker.get_sheet_portrait(load(sheet_path))
	var look: Appearance = appearance if appearance else (hero.get_appearance() if hero else null)
	return CharacterBaker.get_portrait(look) if look else null


func _should_be_here() -> bool:
	var story: Story = GameState.story
	return story.has_flag(required_flag) and (hidden_when_flag.is_empty() or not story.has_flag(hidden_when_flag))


func _update() -> void:
	var here: bool = _should_be_here() and not _gone
	if here == visible:
		return
	visible = here
	var player := _player()
	if here and player:
		global_position = player.global_position + APPEAR_OFFSET


func _process(delta: float) -> void:
	var player := _player()
	if not visible or player == null or _gone:
		return
	if side_distance > 0.0:
		_hang_on(player, delta)
		return
	var offset: Vector2 = player.global_position + Vector2(side_distance, 0.0) - global_position
	var distance: float = offset.length()
	if distance > CATCH_UP_DISTANCE:
		global_position = player.global_position - offset.normalized() * follow_distance
		return
	if distance <= follow_distance:
		_sprite.play("idle_" + _facing)
		return
	var speed: float = maxf(MIN_SPEED, (distance - follow_distance) * 6.0)
	global_position += offset.normalized() * minf(speed * delta, distance - follow_distance)
	_facing = _direction_name(offset)
	_sprite.play("walk_" + _facing)


## Someone the player supports (side_distance > 0): hangs on his shoulder, shoulder to shoulder
## and a little behind him (drawn behind), looks where he looks and limps when he walks. Standing,
## he stays bent (frame SUPPORTED_REST_FRAME of the walk) instead of standing up straight.
func _hang_on(player: Node2D, delta: float) -> void:
	var facing: String = player.get_facing() if player.has_method("get_facing") else "down"
	var target: Vector2 = player.global_position + _support_offset(facing)
	if global_position.distance_to(target) > CATCH_UP_DISTANCE:
		global_position = target
	else:
		global_position = global_position.lerp(target, minf(1.0, delta * SUPPORT_FOLLOW))
	var moving: bool = player.global_position.distance_to(_last_player_at) > 0.05
	_last_player_at = player.global_position
	if moving:
		_held_facing = ""
	_facing = facing if _held_facing.is_empty() else _held_facing
	var animation := StringName("walk_" + _facing)
	if moving:
		if _sprite.animation != animation or not _sprite.is_playing():
			_sprite.play(animation)
	else:
		_sprite.animation = animation
		_sprite.frame = SUPPORTED_REST_FRAME
		_sprite.pause()


## Where the supported figure hangs: at the player's side (screen right) looking down or up,
## right behind his shoulder when he walks sideways.
func _support_offset(facing: String) -> Vector2:
	if facing == "left" or facing == "right":
		return Vector2(-2.0 if facing == "right" else 2.0, -SUPPORT_BEHIND * 2.0)
	return Vector2(side_distance, -SUPPORT_BEHIND)


## A gesture of this figure during a dialogue ("act:<npc_id>:<gesture>[:<item>]", see NpcActing).
func _on_cutscene(cutscene_id: String) -> void:
	var parts: PackedStringArray = cutscene_id.split(":", true, 3)
	if parts.size() >= 3 and parts[0] == "act" and parts[1] == npc_id and not npc_id.is_empty() and visible:
		NpcActing.play(self, parts[2], parts[3] if parts.size() > 3 else "")


## Cut scene (NpcActing "run_off"): walks away from the player out of sight and is gone.
func run_off() -> void:
	var player := _player()
	var away: Vector2 = _direction_vector(global_position - player.global_position) if player else Vector2.RIGHT
	_gone = true
	_facing = _direction_name(away)
	_sprite.play("walk_" + _facing)
	var walk := create_tween()
	walk.tween_property(self, "global_position", global_position + away * 140.0, 1.3)
	walk.parallel().tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.7)
	await walk.finished
	visible = false
	modulate.a = 1.0


## Cut scene: turns to `direction` ("down", "up", "left", "right") while standing.
func face(direction: String) -> void:
	_facing = direction
	_held_facing = direction
	if _sprite:
		_sprite.play("idle_" + _facing)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(Player.GROUP) as Node2D


static func _direction_name(motion: Vector2) -> String:
	if absf(motion.x) > absf(motion.y):
		return "right" if motion.x > 0.0 else "left"
	return "down" if motion.y > 0.0 else "up"


## The main direction of `motion` as a unit vector (left, right, up or down).
static func _direction_vector(motion: Vector2) -> Vector2:
	if absf(motion.x) > absf(motion.y):
		return Vector2.RIGHT if motion.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if motion.y > 0.0 else Vector2.UP
