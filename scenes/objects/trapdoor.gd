class_name Trapdoor
extends Node3D
## Opens in the boss room after the boss falls: a dark hole in the floor. Stepping in leads one
## floor deeper; after the last boss it is a golden light instead and ends the run as a victory.

signal entered

const ENTER_DISTANCE: float = 0.9

var final: bool = false
var player: Node3D

var _used: bool = false
var _ready_time: float = 1.0


func _ready() -> void:
	var color := Color(1, 0.85, 0.35) if final else Color(0.02, 0.02, 0.03)
	var hole := RoomBuilder.box(self, Vector3(1.6, 0.04, 1.6), Vector3(0, 0.02, 0), RoomBuilder.color_material(color, 1.5 if final else 0.0), 0)
	hole.name = "Hole"
	var rim := RoomBuilder.color_material(Color(0.3, 0.22, 0.15))
	for side: Vector3 in [Vector3(0, 0, 0.9), Vector3(0, 0, -0.9)]:
		RoomBuilder.box(self, Vector3(2.0, 0.08, 0.2), side + Vector3(0, 0.04, 0), rim, 0)
	for side: Vector3 in [Vector3(0.9, 0, 0), Vector3(-0.9, 0, 0)]:
		RoomBuilder.box(self, Vector3(0.2, 0.08, 1.6), side + Vector3(0, 0.04, 0), rim, 0)
	if final:
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 2.0
		light.omni_range = 5.0
		light.position.y = 1.0
		add_child(light)


func _physics_process(delta: float) -> void:
	_ready_time -= delta
	if _used or player == null or _ready_time > 0.0:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() < ENTER_DISTANCE:
		_used = true
		entered.emit()
