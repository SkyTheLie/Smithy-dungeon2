class_name Player
extends CharacterBody2D

## Group of the player node (GameState finds him there for saving).
const GROUP: StringName = &"player"

## Movement speed in pixels per second.
@export var speed: float = 200.0
## Speed factor while the sprint key (Shift) is held.
@export var sprint_multiplier: float = 1.5
## Walk frames (0-5) with a footstep sound.
const STEP_FRAMES: Array[int] = [1, 4]

## Walking speed while the player walks by himself (auto_walk).
const AUTO_WALK_SPEED: float = 70.0

## The player arrived at the end of an auto_walk.
signal auto_walk_finished

## Direction the player looks at: "down", "up", "left" or "right".
## Used to pick the animations "idle_<facing>" and "walk_<facing>".
var _facing: String = "down"
## true while the walk sheet is the cloak of the Finsterstadt (Disguise).
var _cloaked: bool = false
## Seconds until the player can hit a rock again.
var _mining_cooldown_left: float = 0.0
## Points (global) the player still walks along by himself, and where he looks at the end.
var _auto_path: PackedVector2Array = []
## Who holds the player still right now (lock): reason -> true.
var _locks: Dictionary = {}
var _auto_facing: String = ""
var _auto_speed: float = AUTO_WALK_SPEED

## Pickaxe swing while mining (try_mine with swing): the pickaxe overlay (gear/pickaxe.png in the
## metals of the equipped pickaxe) turns around the hand. Keys per facing, in sprite pixels from the
## frame centre: [hand, angle (degrees, 0 = head up, clockwise), vertical scale (< 0 = head
## towards the camera)] for rest, wind up and strike; "left" is "right" mirrored.
const SWING_KEYS: Dictionary = {
	"right": [[Vector2(4, 4), 30.0, 1.0], [Vector2(-1, -12), -80.0, 1.0], [Vector2(7, 2), 115.0, 1.0]],
	"down": [[Vector2(4, 4), 10.0, 1.0], [Vector2(8, -8), -5.0, 1.0], [Vector2(2, 6), 0.0, -1.0]],
	"up": [[Vector2(-4, 4), -10.0, 1.0], [Vector2(-2, -16), 0.0, 1.0], [Vector2(-2, -10), 0.0, 0.35]],
}
## Longest swing (seconds); shorter if the mining cooldown is shorter. The pickaxe hits at
## SWING_HIT of it (the rock takes the hit then, see get_swing_hit_delay).
const SWING_TIME: float = 0.36
const SWING_HIT: float = 0.7
## With a mining sheet (CharacterBaker.get_mine_sheet) the whole figure swings the pickaxe
## instead ("mine_<facing>", 9 frames): length of the swing and the frame where it strikes.
const MINE_SWING_TIME: float = 0.6
const MINE_HIT_FRAMES: Dictionary = {"down": 5, "up": 5, "left": 4, "right": 4}  # "up" unused, see try_mine
## Chopping a tree (CharacterBaker.get_chop_sheet, "chop_<facing>", the mining swing with an axe):
## frame where the axe strikes. Trees are always chopped from the side (try_mine).
const CHOP_HIT_FRAMES: Dictionary = {"down": 4, "up": 4, "left": 4, "right": 4}
## The player stands still while swinging.
var _swing_left: float = 0.0
var _has_mine_animation: bool = false
var _has_chop_animation: bool = false
## The tool of the current swing: "pickaxe" or "axe".
var _swing_tool: String = "pickaxe"
var _pickaxe: Sprite2D
var _swing_tween: Tween

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group(GROUP)
	_apply_appearance()
	GameState.story.changed.connect(_on_story_changed)
	_move_to_spawn_point()
	GameState.player_stats.leveled_up.connect(_on_leveled_up)
	_sprite.frame_changed.connect(_on_frame_changed)
	Events.cutscene_requested.connect(_on_cutscene)
	Events.player_look_changed.connect(_on_look_changed)
	GameState.on_scene_entered.call_deferred(get_tree().current_scene.scene_file_path if get_tree().current_scene else scene_file_path)


## A gesture of the player during a dialogue ("act:player:<gesture>[:<item>]", see NpcActing).
func _on_cutscene(cutscene_id: String) -> void:
	var parts: PackedStringArray = cutscene_id.split(":", true, 3)
	if parts.size() >= 3 and parts[0] == "act" and parts[1] == "player":
		NpcActing.play(self, parts[2], parts[3] if parts.size() > 3 else "")


## Footsteps on the walk frames where a foot touches the ground.
func _on_frame_changed() -> void:
	if _sprite.animation.begins_with("walk_") and _sprite.frame in STEP_FRAMES:
		AudioManager.play_sound("step", randf_range(0.85, 1.15))


## Level up: the figure lights up golden, a ring of light spreads and sparks rise (+ sound).
func _on_leveled_up(_level: int) -> void:
	AudioManager.play_sound("level_up")
	var glow := LevelUpGlow.new()
	glow.position = _sprite.position
	add_child(glow)
	var flash := create_tween()
	for i in 3:
		flash.tween_property(_sprite, "self_modulate", Color(1.8, 1.6, 0.9), 0.12)
		flash.tween_property(_sprite, "self_modulate", Color.WHITE, 0.18)


## The tailor changed clothes or colour (Events.player_look_changed): new sheets, same animation.
func _on_look_changed() -> void:
	var animation: StringName = _sprite.animation
	_apply_appearance()
	if _sprite.sprite_frames.has_animation(animation):
		_sprite.play(animation)


## The look from the character creator (GameState.player_appearance) replaces the default sheet.
func _apply_appearance() -> void:
	var look: Appearance = GameState.player_appearance
	var cloak: Texture2D = Disguise.get_sheet() if Disguise.is_worn(_scene_path()) else null
	_cloaked = cloak != null
	_sprite.sprite_frames = CharacterBaker.make_frames(cloak if cloak else CharacterBaker.get_sheet(look))
	var mine_sheet: Texture2D = CharacterBaker.get_mine_sheet(look)
	_has_mine_animation = mine_sheet != null
	if mine_sheet:
		CharacterBaker.add_mine_frames(_sprite.sprite_frames, mine_sheet)
	var chop_sheet: Texture2D = CharacterBaker.get_chop_sheet(look)
	_has_chop_animation = chop_sheet != null
	if chop_sheet:
		CharacterBaker.add_mine_frames(_sprite.sprite_frames, chop_sheet, "chop")
	var raise_sheet: Texture2D = CharacterBaker.get_raise_sheet(look)
	if raise_sheet:
		CharacterBaker.add_mine_frames(_sprite.sprite_frames, raise_sheet, "raise")
	_sprite.scale = Vector2.ONE * look.get_scale()
	_sprite.play("idle_" + _facing)


## The map the player stands in (its owner while the scene is still being set up).
func _scene_path() -> String:
	if owner and not owner.scene_file_path.is_empty():
		return owner.scene_file_path
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	return scene.scene_file_path if scene else ""


## Nyra hands over the cloak (or the city rises): the walk sheet changes on the spot.
func _on_story_changed() -> void:
	if Disguise.is_worn(_scene_path()) != _cloaked:
		var animation: StringName = _sprite.animation
		_apply_appearance()
		if _sprite.sprite_frames.has_animation(animation):
			_sprite.play(animation)


## Cut scene: the player walks along `points` (global) by himself, through everything in the way,
## and ignores the keys meanwhile; at the end he looks at `facing` ("" = as he walked) and
## auto_walk_finished is emitted. E.g. into the crowd at the spring festival (FestivalShow).
## `walk_speed`: pixels per second (faster e.g. for the chase in the Finsterstadt).
func auto_walk(points: PackedVector2Array, facing: String = "", walk_speed: float = AUTO_WALK_SPEED) -> void:
	# A copy: the path is used up point by point, the caller (often an export) keeps its list.
	_auto_path = points.duplicate()
	_auto_facing = facing
	_auto_speed = walk_speed
	velocity = Vector2.ZERO


## Cut scene: holds both arms up (e.g. the sword at the spring festival) until the player walks again.
func raise_arms(facing: String) -> void:
	var animation := StringName("raise_" + facing)
	if not _sprite.sprite_frames.has_animation(animation):
		return
	_facing = facing
	_sprite.offset = CharacterBaker.MINE_OFFSET
	_sprite.stop()
	_sprite.animation = animation
	_sprite.frame = 0


## Cut scene: arms up and `times` small jumps of the figure (not the body, so the camera stays
## still), e.g. after winning a smith tournament. The arms stay up until the player walks again.
func cheer(times: int = 4) -> void:
	raise_arms("down")
	ArenaCelebration.hop(_sprite, times, 0.2, 5.0)


## The direction the player looks ("down", "up", "left", "right").
func get_facing() -> String:
	return _facing


func is_auto_walking() -> bool:
	return not _auto_path.is_empty()


## Cut scene / minigame: the keys don't move the player until unlock() with the same `reason`
## (auto_walk still does). Several may lock at once, he walks again when the last one unlocked.
## Whoever locks must unlock on every way out (end, Esc, close); a scene change needs nothing, the
## lock goes with this Player. Not saved on purpose.
func lock(reason: StringName) -> void:
	_locks[reason] = true
	velocity = Vector2.ZERO


func unlock(reason: StringName) -> void:
	_locks.erase(reason)


func is_locked() -> bool:
	return not _locks.is_empty()


func _auto_walk_step(delta: float) -> void:
	var offset: Vector2 = _auto_path[0] - global_position
	if offset.length() <= 1.0:
		global_position = _auto_path[0]
		_auto_path.remove_at(0)
		if _auto_path.is_empty():
			if not _auto_facing.is_empty():
				_facing = _auto_facing
			_update_animation(Vector2.ZERO)
			auto_walk_finished.emit()
		return
	global_position += offset.limit_length(_auto_speed * delta)
	_update_animation(offset)


func _physics_process(delta: float) -> void:
	_mining_cooldown_left = maxf(_mining_cooldown_left - delta, 0.0)
	_swing_left = maxf(_swing_left - delta, 0.0)
	# The water in the holy water crystal sloshes against the last movement (still while auto-walking).
	WaterSlosh.step(Vector2.ZERO if not _auto_path.is_empty() else get_real_velocity() / speed, delta)
	if not _auto_path.is_empty():
		_auto_walk_step(delta)
		return
	# Returns a normalized direction, so diagonal movement isn't faster.
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Station windows and dialogues (anvil, chests, shops, conversations ...): stand still until
	# it is closed (E / Esc). Dialogues of story steps with "move_in_dialogue" don't freeze.
	if is_locked() or StationMenu.is_player_frozen(get_tree()) or _swing_left > 0.0:
		direction = Vector2.ZERO
	var current_speed: float = speed * GameState.player_stats.get_move_speed_factor()
	var sprinting: bool = Input.is_action_pressed("sprint")
	if sprinting:
		current_speed *= sprint_multiplier
	# The legs move faster while sprinting.
	_sprite.speed_scale = sprint_multiplier if sprinting and _swing_left <= 0.0 else 1.0
	velocity = direction * current_speed
	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	if _sprite.animation.begins_with("raise_"):
		if direction == Vector2.ZERO:
			return
		_sprite.offset = Vector2.ZERO
	if _sprite.animation.begins_with("mine_") or _sprite.animation.begins_with("chop_"):
		if _sprite.is_playing():
			return
		_sprite.offset = Vector2.ZERO
	if direction == Vector2.ZERO:
		_sprite.play("idle_" + _facing)
		return
	# On diagonals the horizontal view wins.
	if absf(direction.x) >= absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"
	_sprite.play("walk_" + _facing)


## Starts a mining hit if the cooldown is over (see PlayerStats.mining_cooldown).
## Returns true if the hit happens; the rock then applies PlayerStats.mining_damage.
## With `swing` the player turns to `target` (global) and swings the pickaxe (`tool` "axe": the
## lumber axe, trees); the rock or tree should take the hit after get_swing_hit_delay().
func try_mine(target: Vector2 = Vector2.INF, swing: bool = false, tool: String = "pickaxe") -> bool:
	if _mining_cooldown_left > 0.0:
		return false
	_mining_cooldown_left = GameState.player_stats.mining_cooldown
	if swing:
		if target != Vector2.INF:
			var to_target: Vector2 = target - global_position
			# A rock above is hit from the side (the swing seen from behind looked odd), a tree
			# always (the chopping sheet only has the side view).
			if absf(to_target.x) >= absf(to_target.y) or to_target.y < 0.0 or tool == "axe":
				_facing = "right" if to_target.x > 0.0 else "left"
			else:
				_facing = "down"
		_swing_tool = tool
		_swing_pickaxe()
	return true


## Seconds from try_mine until the swung pickaxe hits.
func get_swing_hit_delay() -> float:
	if _has_swing_animation():
		var hit_frames: Dictionary = CHOP_HIT_FRAMES if _swing_tool == "axe" else MINE_HIT_FRAMES
		return _get_swing_time() * hit_frames[_facing] / CharacterBaker.MINE_COLUMNS
	return _get_swing_time() * SWING_HIT


func _get_swing_time() -> float:
	return minf(MINE_SWING_TIME if _has_swing_animation() else SWING_TIME, GameState.player_stats.mining_cooldown * 0.85)


## The whole figure swings the current tool (mining or chopping sheet).
func _has_swing_animation() -> bool:
	return _has_chop_animation if _swing_tool == "axe" else _has_mine_animation


func _swing_pickaxe() -> void:
	if _has_swing_animation():
		_play_mine_animation()
		return
	if not _pickaxe:
		_pickaxe = Sprite2D.new()
		_pickaxe.centered = false
		add_child(_pickaxe)
	var axe: bool = _swing_tool == "axe"
	var stack: InventorySlot = GameState.player_stats.get_tool(PlayerStats.ToolSlot.AXE if axe else PlayerStats.ToolSlot.PICKAXE)
	var overlay: Dictionary = CharacterBaker.get_weapon_overlay({"type": "axe" if axe else "pickaxe",
		"head": Hero.get_gear_material(stack, true) if stack else "iron",
		"grip": Hero.get_gear_material(stack, false) if stack else "wood"})
	if overlay.is_empty():
		return
	_pickaxe.texture = overlay["texture"]
	_pickaxe.offset = -overlay["anchor"]
	_pickaxe.flip_h = _facing == "left"
	# Looking up, the pickaxe is behind the body.
	move_child(_pickaxe, 0 if _facing == "up" else get_child_count() - 1)
	_pickaxe.show()
	_sprite.play("idle_" + _facing)
	var time: float = _get_swing_time()
	_swing_left = time
	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween()
	_swing_tween.tween_method(_pose_pickaxe.bind(0, 1), 0.0, 1.0, time * (SWING_HIT - 0.15)) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_method(_pose_pickaxe.bind(1, 2), 0.0, 1.0, time * 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.tween_interval(time * 0.1)
	_swing_tween.tween_method(_pose_pickaxe.bind(2, 0), 0.0, 1.0, time * (0.9 - SWING_HIT))
	_swing_tween.tween_interval(0.3)
	_swing_tween.tween_callback(_pickaxe.hide)


## The whole figure swings the pickaxe (mining sheet); _update_animation waits until it is over.
func _play_mine_animation() -> void:
	var time: float = _get_swing_time()
	_swing_left = time
	var animation := StringName(("chop_" if _swing_tool == "axe" else "mine_") + _facing)
	_sprite.sprite_frames.set_animation_speed(animation, CharacterBaker.MINE_COLUMNS / time)
	_sprite.offset = CharacterBaker.MINE_OFFSET
	_sprite.speed_scale = 1.0
	_sprite.stop()
	_sprite.play(animation)


## Puts the pickaxe between swing key `from` and key `to` (weight 0..1) for the current facing.
func _pose_pickaxe(weight: float, from: int, to: int) -> void:
	var keys: Array = SWING_KEYS["right" if _facing == "left" else _facing]
	var a: Array = keys[from]
	var b: Array = keys[to]
	var hand: Vector2 = (a[0] as Vector2).lerp(b[0], weight)
	var angle: float = lerpf(a[1], b[1], weight)
	if _facing == "left":
		hand.x = -hand.x
		angle = -angle
	_pickaxe.position = _sprite.position + hand * _sprite.scale
	_pickaxe.rotation_degrees = angle
	_pickaxe.scale = Vector2(1.0, lerpf(a[2], b[2], weight)) * _sprite.scale


## A saved position can lie in the rock or an abyss if the cave was rebuilt since: back to `start`.
func _leave_rock(start: Vector2) -> void:
	for walls: Node in get_tree().get_nodes_in_group(CaveWalls.GROUP):
		var cave := walls as CaveWalls
		if not cave.is_floor(cave.to_local(global_position)):
			global_position = start


## Places the player at the spawn point requested by the last door, or at the exact position
## from a loaded save (see GameState).
func _move_to_spawn_point() -> void:
	if GameState.next_player_position != Vector2.INF:
		_leave_rock.call_deferred(global_position)  # deferred: the walls are not ready yet
		global_position = GameState.next_player_position
		GameState.next_player_position = Vector2.INF
	if GameState.next_spawn_point == &"":
		return
	for spawn_point: Node in get_tree().get_nodes_in_group("spawn_points"):
		if spawn_point.name == GameState.next_spawn_point:
			global_position = (spawn_point as Node2D).global_position
			break
	GameState.next_spawn_point = &""
	_walk_to_auto_walk_point()


## Start of a new game: walks from the spawn point to GameState.next_auto_walk_point.
func _walk_to_auto_walk_point() -> void:
	if GameState.next_auto_walk_point == &"":
		return
	for spawn_point: Node in get_tree().get_nodes_in_group("spawn_points"):
		if spawn_point.name == GameState.next_auto_walk_point:
			auto_walk(PackedVector2Array([(spawn_point as Node2D).global_position]), "up")
			break
	GameState.next_auto_walk_point = &""
