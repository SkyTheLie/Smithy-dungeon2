class_name Rope
extends Node3D
## The way out after the very first boss (MetaState.rope_due, data/meta.json ruby_quest): instead
## of the trapdoor and the boss item, a rope falls from the sky into the boss room. Its upper end
## stays up in the sky (the rooms have no ceiling), with a pale light from above. Walking to it
## sends `grabbed` once; Dungeon.climb_rope lets the player climb up, RunScene ends the day.

signal grabbed

## Long enough that its upper end is never seen.
const LENGTH: float = 40.0
const RADIUS: float = 0.06
## Knots for the hands, this far apart, up to KNOTS_UP metres.
const KNOT_STEP: float = 0.55
const KNOTS_UP: float = 8.0
const FALL_TIME: float = 1.1
## Its lower end hangs this high over the floor.
const HANG: float = 0.25
const GRAB_DISTANCE: float = 0.9
const COLOR := Color(0.58, 0.4, 0.2)
const SKY_COLOR := Color(0.85, 0.92, 1.0)

var player: Node3D

## The rope itself (falls down; this node stays on the floor).
var _strand: Node3D
var _hanging: bool = false
var _used: bool = false


func _ready() -> void:
	_strand = Node3D.new()
	_strand.name = "Strand"
	add_child(_strand)
	var cord := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = LENGTH
	mesh.radial_segments = 6
	mesh.rings = 1
	cord.mesh = mesh
	cord.material_override = RoomBuilder.color_material(COLOR)
	cord.position.y = LENGTH / 2.0
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_strand.add_child(cord)
	var knot_material := RoomBuilder.color_material(COLOR.darkened(0.35))
	var height: float = 0.3
	while height < KNOTS_UP:
		RoomBuilder.box(_strand, Vector3(0.17, 0.11, 0.17), Vector3(0, height, 0), knot_material, 0)
		height += KNOT_STEP
	# Daylight from above: where the rope comes from.
	var sky := OmniLight3D.new()
	sky.name = "Sky"
	sky.light_color = SKY_COLOR
	sky.light_energy = 0.0
	sky.omni_range = 6.0
	sky.position.y = 3.6
	add_child(sky)
	_strand.position.y = LENGTH
	var tween := create_tween()
	tween.tween_property(sky, "light_energy", 1.6, 0.6)
	tween.tween_property(_strand, "position:y", HANG - 0.15, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_strand, "position:y", HANG + 0.12, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(_strand, "position:y", HANG, 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _hanging = true)
	AudioManager.play_sound("rope_fall", 0.7)


## true once it hangs (then it can be grabbed).
func is_hanging() -> bool:
	return _hanging


func _physics_process(_delta: float) -> void:
	if _used or not _hanging or player == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() < GRAB_DISTANCE:
		_used = true
		grabbed.emit()
