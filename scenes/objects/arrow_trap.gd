class_name ArrowTrap
extends Node3D
## A hole in a wall that shoots arrows across the room (floors.json "arrow_traps"). Modes:
##   timed: shoots every few seconds by itself;
##   plate: shoots when someone (the player or an enemy) steps on a pressure plate of its room;
##   row: one of several holes along a wall, they shoot one after another.
## Before every shot it warns (Rule 12): the hole glows red and rattles, a mechanical click is
## heard from it; then the arrow hisses out. Arrows hurt the player and enemies alike (lure
## enemies onto the plate!). The Dungeon calls tick() only for the room the player is in.

## Direction the arrows fly (into the room), set before adding it.
var direction: Vector3 = Vector3.RIGHT
## "timed", "plate" or "row".
var mode: String = "timed"
## floors.json arrow_traps (damage, speed, warn, enemy_damage …).
var settings: Dictionary = {}
var player: Player
var dungeon: Dungeon
## timed/row: seconds between shots; first shot after `delay`.
var cycle: float = 3.0
var delay: float = 1.0

var _wait: float = 0.0
var _warn_left: float = 0.0
var _hole: MeshInstance3D
var _time: float = 0.0

const HOLE_SIZE: float = 0.32
const SHOT_HEIGHT: float = 0.8
const COLOR_IDLE := Color(0.08, 0.06, 0.05)
const COLOR_WARN := Color(1.0, 0.25, 0.1)
## The click before a shot (SoundSynth voice): short and metallic.
const CLICK := {"wave": "square", "freq": 1900, "slide": 0.8, "length": 0.035, "noise": 0.35, "vibrato": 0}


func _ready() -> void:
	_wait = delay
	_hole = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(HOLE_SIZE, HOLE_SIZE)
	_hole.mesh = quad
	_hole.material_override = RoomBuilder.color_material(COLOR_IDLE)
	add_child(_hole)
	_hole.position = Vector3(0, SHOT_HEIGHT, 0)
	# The quad faces +Z; turn it to face into the room.
	_hole.basis = Basis.looking_at(-direction, Vector3.UP)


## Every frame while the player is in this room.
func tick(delta: float) -> void:
	_time += delta
	if _warn_left > 0.0:
		_warn_left -= delta
		_hole.position = Vector3(0, SHOT_HEIGHT, 0) + _side() * randf_range(-0.03, 0.03)
		if _warn_left <= 0.0:
			_shoot()
		return
	if mode == "plate":
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = cycle
		warn()


## Starts the warning; the arrow follows after "warn" seconds (plates call this).
func warn() -> void:
	if _warn_left > 0.0:
		return
	_warn_left = float(settings.get("warn", 0.6))
	_hole.material_override = RoomBuilder.color_material(COLOR_WARN, 2.0)
	AudioManager.play_stream_at(SoundSynth.make(CLICK, "cry"), global_position + Vector3(0, SHOT_HEIGHT, 0), dungeon.effects if dungeon else null, randf_range(0.95, 1.05), -2.0)


func is_warning() -> bool:
	return _warn_left > 0.0


func _shoot() -> void:
	_warn_left = 0.0
	_hole.position = Vector3(0, SHOT_HEIGHT, 0)
	_hole.material_override = RoomBuilder.color_material(COLOR_IDLE)
	if dungeon == null:
		return
	var shot := EnemyShot.new()
	shot.velocity = direction * float(settings.get("speed", 7.0))
	shot.player = player
	shot.arrow = true
	shot.damage = int(settings.get("damage", 2))
	shot.enemy_damage = float(settings.get("enemy_damage", 4.0))
	shot.dungeon = dungeon
	shot.lifetime = 4.0
	dungeon.effects.add_child(shot)
	shot.global_position = global_position + direction * 0.35 + Vector3(0, SHOT_HEIGHT, 0)
	AudioManager.play_sound_at("enemy_shoot", shot.global_position, dungeon.effects, randf_range(0.75, 0.85))


func _side() -> Vector3:
	return direction.cross(Vector3.UP).normalized()
