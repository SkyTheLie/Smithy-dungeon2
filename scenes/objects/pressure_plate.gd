class_name PressurePlate
extends Node3D
## A stone plate on the floor (floors.json "arrow_traps" mode plate): when the player or an enemy
## steps on it, it sinks with a click and the plate traps of its room shoot (ArrowTrap.warn).
## Slightly lighter than the floor, so a careful player sees it. The Dungeon checks who stands on
## it (Dungeon._tick_arrow_traps).

var size: float = 0.9
var cooldown: float = 2.0
## Monster trap (floors.json "ceiling_traps"): hidden until stepped on, then enemies fall from
## the ceiling; works only once (`spent`), and only the player sets it off.
var hidden: bool = false
var ambush: bool = false
var spent: bool = false

var _wait: float = 0.0
var _stone: MeshInstance3D

const COLOR := Color(0.55, 0.5, 0.45)
const UP_Y: float = 0.03
const DOWN_Y: float = -0.01
## The click under the foot (SoundSynth voice).
const CLICK := {"wave": "square", "freq": 700, "slide": 0.6, "length": 0.05, "noise": 0.5, "vibrato": 0}


func _ready() -> void:
	_stone = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, 0.06, size)
	_stone.mesh = box
	_stone.material_override = RoomBuilder.color_material(COLOR)
	_stone.position.y = UP_Y
	_stone.visible = not hidden
	add_child(_stone)


## true if `point` (world) stands on the plate.
func covers(point: Vector3) -> bool:
	var offset: Vector3 = point - global_position
	return absf(offset.x) < size / 2.0 + 0.1 and absf(offset.z) < size / 2.0 + 0.1


## Someone stands on it: true when it goes down now (not while it is still down).
func press(delta: float, someone_on_it: bool) -> bool:
	_wait = maxf(0.0, _wait - delta)
	if not someone_on_it:
		if _wait <= 0.0:
			_stone.position.y = UP_Y
		return false
	if _wait > 0.0:
		return false
	_wait = cooldown
	if ambush:
		spent = true
		_wait = INF
	_stone.visible = true
	_stone.position.y = DOWN_Y
	AudioManager.play_stream_at(SoundSynth.make(CLICK, "cry"), global_position, get_parent() as Node3D, 1.0, 0.0)
	return true
