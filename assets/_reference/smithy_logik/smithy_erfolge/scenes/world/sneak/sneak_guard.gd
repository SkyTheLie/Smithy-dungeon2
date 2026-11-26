class_name SneakGuard
extends Node2D
## A guard of the sneaking parts (the way into the Finsterburg). He looks straight in one of the four
## directions and sees in a cone in front of him (drawn on the ground, shortened where walls, crates
## and pillars block the view). Standing guards turn between `look_directions` every `turn_seconds`;
## guards with a `patrol` walk from point to point (straight lines only, they look where they walk)
## and look around at each point. Sees he the player (in the cone and nothing in between, or right
## next to him), the scene's SneakZone sends the player back to the start of the area. While a
## dialogue is open nobody looks, and a guard hidden by the story (e.g. under a StoryProp) is not there.

signal spotted(guard: SneakGuard)

const DIRECTION_VECTORS: Dictionary = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}
## Rays of the cone (more = smoother edge).
const CONE_RAYS: int = 10
## Height of the eyes / of the player's body above the feet (the rays start and end there).
const EYE_HEIGHT: float = 10.0
## Closer than this the guard notices the player in any direction.
const TOUCH_DISTANCE: float = 16.0
const COLOR_CONE: Color = Color(1.0, 0.92, 0.55, 0.22)
const COLOR_ALERT: Color = Color(1.0, 0.3, 0.25, 0.4)

@export var appearance: Appearance
## PixelLab sheet (assets/sprites/residents/<resident>.png), wins over `appearance`.
@export var resident: String = ""
## Directions he looks in turn ("down", "up", "left", "right"); with a patrol: where he looks at
## each point.
@export var look_directions: PackedStringArray = ["down"]
@export var turn_seconds: float = 2.0
## Points to walk to, relative to the start (axis-aligned steps). Empty = he stands.
@export var patrol: PackedVector2Array = []
@export var walk_speed: float = 40.0
@export var view_range: float = 110.0
## Full width of the cone in degrees.
@export var view_angle: float = 60.0
## false = he only walks his patrol (or turns), without a cone and without seeing the player
## (guards for the look of a place, e.g. at the south gate of the Finsterstadt).
@export var watching: bool = true

var facing: String = "down"
var _sprite: AnimatedSprite2D
var _cone: Polygon2D
var _start: Vector2
var _target: int = 0
var _look_index: int = 0
var _wait: float = 0.0
var _alert: bool = false


func _ready() -> void:
	_start = position
	_cone = Polygon2D.new()
	_cone.color = COLOR_CONE
	_cone.z_index = -1
	_cone.position = Vector2(0, -EYE_HEIGHT)
	_cone.visible = watching
	add_child(_cone)
	_sprite = AnimatedSprite2D.new()
	_sprite.offset = Vector2(0, -13)
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident)
	if sheet:
		_sprite.sprite_frames = CharacterBaker.make_frames(sheet)
	elif appearance:
		_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(appearance))
	add_child(_sprite)
	facing = look_directions[0] if not look_directions.is_empty() else "down"
	_wait = turn_seconds
	_play(false)


func _physics_process(delta: float) -> void:
	# Hidden by the story (e.g. under a StoryProp that is switched off): he is not there.
	if _alert or not is_visible_in_tree():
		return
	var talking: bool = DialogueBox.is_any_open(get_tree())
	if not talking:
		if patrol.is_empty():
			_turn(delta)
		else:
			_walk(delta)
	if not watching:
		return
	_update_cone()
	if not talking and _sees_player():
		_alert = true
		_cone.color = COLOR_ALERT
		_play(false)
		spotted.emit(self)


## Standing: the next direction every `turn_seconds`.
func _turn(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or look_directions.size() < 2:
		return
	_wait = turn_seconds
	_look_index = (_look_index + 1) % look_directions.size()
	facing = look_directions[_look_index]
	_play(false)


## Patrol: walk to the next point; there look around (each of `look_directions` for a moment).
func _walk(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		var step: float = turn_seconds / maxf(1.0, look_directions.size())
		var index: int = clampi(int((turn_seconds - _wait) / step), 0, look_directions.size() - 1)
		if not look_directions.is_empty() and facing != look_directions[index]:
			facing = look_directions[index]
			_play(false)
		return
	var goal: Vector2 = _start + patrol[_target]
	var offset: Vector2 = goal - position
	if offset.length() < 1.0:
		position = goal
		_target = (_target + 1) % patrol.size()
		_wait = turn_seconds if not look_directions.is_empty() else 0.0
		return
	facing = _direction_of(offset)
	_play(true)
	position += offset.limit_length(walk_speed * delta)


static func _direction_of(offset: Vector2) -> String:
	if absf(offset.x) > absf(offset.y):
		return "right" if offset.x > 0.0 else "left"
	return "down" if offset.y > 0.0 else "up"


func _play(walking: bool) -> void:
	if _sprite.sprite_frames:
		_sprite.play(StringName(("walk_" if walking else "idle_") + facing))


## The cone: rays from the eyes, each stopped by the first wall.
func _update_cone() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var eye: Vector2 = global_position + Vector2(0, -EYE_HEIGHT)
	var forward: Vector2 = DIRECTION_VECTORS.get(facing, Vector2.DOWN)
	var half: float = deg_to_rad(view_angle) / 2.0
	var points := PackedVector2Array([Vector2.ZERO])
	# The player doesn't stop the view (he is what the guard is looking for).
	var exclude: Array[RID] = []
	var player := get_tree().get_first_node_in_group(Player.GROUP) as CollisionObject2D
	if player:
		exclude.append(player.get_rid())
	for i in CONE_RAYS + 1:
		var direction: Vector2 = forward.rotated(-half + 2.0 * half * i / CONE_RAYS)
		var end: Vector2 = eye + direction * view_range
		var hit: Dictionary = space.intersect_ray(_ray(eye, end, exclude))
		points.append((hit["position"] if not hit.is_empty() else end) - eye)
	_cone.polygon = points


func _sees_player() -> bool:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null:
		return false
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= TOUCH_DISTANCE:
		return true
	if to_player.length() > view_range:
		return false
	var forward: Vector2 = DIRECTION_VECTORS.get(facing, Vector2.DOWN)
	if absf(forward.angle_to(to_player)) > deg_to_rad(view_angle) / 2.0:
		return false
	var eye: Vector2 = global_position + Vector2(0, -EYE_HEIGHT)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(
			_ray(eye, player.global_position + Vector2(0, -EYE_HEIGHT), [(player as CollisionObject2D).get_rid()]))
	return hit.is_empty()


static func _ray(from: Vector2, to: Vector2, exclude: Array[RID] = []) -> PhysicsRayQueryParameters2D:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = exclude
	query.collide_with_areas = false
	return query
