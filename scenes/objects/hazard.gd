class_name Hazard
extends Node3D
## A trap on the floor of a room (data/floors.json "hazard_types"): lava, a poison puddle, spikes or
## ice spikes. A square patch `size` metres wide, flat on the floor, in its colour (lava and poison
## glow and pulse a little). Spikes with a "cycle" [down, up] come out and go in again; they only
## hurt while they are up (a short warning shake before). Dungeon asks hurts_at() every physics
## frame and hits the player (Player.take_hit, so the usual invulnerable time after a hit counts).
## Built in code, no scene. Timers run with _process, so they stop while the game is paused.

const SPIKE_ROWS: int = 3
const SPIKE_HEIGHT: float = 0.45
const WARN_TIME: float = 0.35

var kind: String = "lava"
var data: Dictionary = {}
var size: float = 2.0
## Half hearts per hit.
var damage: int = 1

var _time: float = 0.0
var _floor_mat: StandardMaterial3D
var _spikes: Node3D
var _cycle: Array = []


## `type_data` = floors.json hazard_types[kind]; `side` = edge length in metres; `offset` = where
## in the cycle the spikes start (so not all of a room move together).
func setup(kind_name: String, type_data: Dictionary, side: float, offset: float) -> void:
	kind = kind_name
	data = type_data
	size = side
	damage = maxi(1, int(data.get("damage", 1)))
	_cycle = data.get("cycle", [])
	_time = offset


func _ready() -> void:
	var color_values: Array = data.get("color", [1.0, 0.4, 0.1])
	var color := Color(float(color_values[0]), float(color_values[1]), float(color_values[2]))
	var patch := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	patch.mesh = plane
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = color.darkened(0.45) if has_cycle() else color
	var glow: float = float(data.get("glow", 0.0))
	if glow > 0.0:
		_floor_mat.emission_enabled = true
		_floor_mat.emission = color
		_floor_mat.emission_energy_multiplier = glow
	patch.material_override = _floor_mat
	patch.position.y = 0.02
	add_child(patch)
	if has_cycle():
		_build_spikes(color)


func has_cycle() -> bool:
	return _cycle.size() == 2


## true while the trap hurts: always for lava and poison, spikes only while they are up.
func is_dangerous() -> bool:
	if not has_cycle():
		return true
	return fmod(_time, _period()) >= float(_cycle[0])


## true if `at` (world position, height ignored) stands on the trap while it is dangerous.
func hurts_at(at: Vector3) -> bool:
	if not is_dangerous():
		return false
	var local: Vector3 = at - global_position
	var half: float = size / 2.0
	return absf(local.x) <= half and absf(local.z) <= half


func _period() -> float:
	return maxf(0.1, float(_cycle[0]) + float(_cycle[1]))


func _process(delta: float) -> void:
	_time += delta
	if has_cycle():
		_move_spikes()
	elif _floor_mat.emission_enabled:
		_floor_mat.emission_energy_multiplier = float(data.get("glow", 0.0)) * (0.8 + 0.2 * sin(_time * 2.5))


## A grid of thin cones on the patch.
func _build_spikes(color: Color) -> void:
	_spikes = Node3D.new()
	add_child(_spikes)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.09
	mesh.height = SPIKE_HEIGHT
	mesh.radial_segments = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.6
	var glow: float = float(data.get("glow", 0.0))
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	mesh.material = material
	var step: float = size / SPIKE_ROWS
	for x in SPIKE_ROWS:
		for z in SPIKE_ROWS:
			var spike := MeshInstance3D.new()
			spike.mesh = mesh
			spike.position = Vector3(-size / 2.0 + step * (x + 0.5), SPIKE_HEIGHT / 2.0, -size / 2.0 + step * (z + 0.5))
			_spikes.add_child(spike)
	_move_spikes()


## Down: hidden in the floor; a short shake just before they come out; up: out.
func _move_spikes() -> void:
	var at: float = fmod(_time, _period())
	var down: float = float(_cycle[0])
	if at >= down:
		_spikes.position.y = 0.0
	elif at >= down - WARN_TIME:
		_spikes.position.y = -SPIKE_HEIGHT * 0.75 + sin(_time * 60.0) * 0.03
	else:
		_spikes.position.y = -SPIKE_HEIGHT
