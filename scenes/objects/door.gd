class_name Door
extends Node3D
## Iron bars in a doorway between two rooms (sits on the border of the two cells).
## Open = the bars are sunk into the floor. Closed = during a fight (the room's enemies are
## alive). Locked = needs a key (shop, item room on later floors): touching it with a key opens it
## for good. Built in code by Dungeon (one per pair of neighbouring rooms).
## Hidden = a real piece of wall fills the doorway (same texture as the walls on both sides,
## mapped by world position, so no seam, no frame, no bars): secret room and the special room
## behind the boss. A bomb next to it (secret) or the Dungeon after the boss (special) opens it
## with reveal(): the piece of wall vanishes and it is an open doorway.

const IRON: String = "res://assets/sprites/rooms/styles/door_iron.png"
const GOLD: String = "res://assets/sprites/rooms/styles/door_gold.png"
const MOVE_TIME: float = 0.3

## The two cells it connects.
var cells: Array[Vector2i] = []
var locked: bool = false
var closed: bool = false
var hidden: bool = false
## Wall textures of the two rooms (cells[0] side, cells[1] side) for the hidden wall piece.
var wall_textures: Array[String] = []
var _plug: Node3D = null

var _bars: Node3D
var _body: StaticBody3D
var _along_x: bool = true
var _front: MeshInstance3D
var _back: MeshInstance3D
var _tween: Tween


func setup(cell_a: Vector2i, cell_b: Vector2i, is_locked: bool) -> void:
	cells = [cell_a, cell_b]
	locked = is_locked
	# The doorway is in a wall between rooms side by side (x) or one above the other (z).
	_along_x = cell_a.x == cell_b.x
	position = (RoomBuilder.cell_center(cell_a) + RoomBuilder.cell_center(cell_b)) / 2.0


func _ready() -> void:
	_bars = Node3D.new()
	add_child(_bars)
	var texture := load(GOLD if locked else IRON) as Texture2D
	_front = _quad(texture, 0.0)
	_back = _quad(texture, PI)
	if hidden:
		_build_plug()
	_body = StaticBody3D.new()
	_body.collision_layer = RoomBuilder.LAYER_WORLD
	_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(RoomBuilder.DOOR_W, RoomBuilder.DOOR_H, RoomBuilder.WALL_T * 2.0) if _along_x \
			else Vector3(RoomBuilder.WALL_T * 2.0, RoomBuilder.DOOR_H, RoomBuilder.DOOR_W)
	shape.shape = box
	shape.position.y = RoomBuilder.DOOR_H / 2.0
	_body.add_child(shape)
	add_child(_body)
	_apply(true)


## Two quads (one per side) with the door picture, on the border between the rooms.
func _quad(texture: Texture2D, turn: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(RoomBuilder.DOOR_W, RoomBuilder.DOOR_H)
	mesh_instance.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.cull_mode = BaseMaterial3D.CULL_BACK
	mesh_instance.material_override = material
	# QuadMesh faces +z; rooms one above the other need it facing z, side by side facing x.
	var base_turn: float = 0.0 if _along_x else PI / 2.0
	mesh_instance.rotation.y = base_turn + turn
	mesh_instance.position.y = RoomBuilder.DOOR_H / 2.0
	_bars.add_child(mesh_instance)
	return mesh_instance


func is_blocking() -> bool:
	return locked or closed or hidden


## A hidden doorway becomes an open doorway (the piece of wall breaks away).
func reveal() -> void:
	if not hidden:
		return
	hidden = false
	if _plug:
		_plug.queue_free()
		_plug = null
	_apply(true)
	AudioManager.play_sound("explosion", 0.8)


## Two wall boxes (one per room side, WALL_T thick each) in the doorway, with the same world-mapped
## wall material as RoomBuilder uses, so they look exactly like the wall around them.
func _build_plug() -> void:
	_plug = Node3D.new()
	add_child(_plug)
	for i in 2:
		if i >= wall_textures.size() or wall_textures[i].is_empty():
			continue
		var toward_room: Vector3 = (RoomBuilder.cell_center(cells[i]) - position) * Vector3(1, 0, 1)
		var size: Vector3 = Vector3(RoomBuilder.DOOR_W, RoomBuilder.DOOR_H, RoomBuilder.WALL_T) if _along_x \
				else Vector3(RoomBuilder.WALL_T, RoomBuilder.DOOR_H, RoomBuilder.DOOR_W)
		var material := RoomBuilder.tiled_material(wall_textures[i], Vector3(2.0, 3.0, 2.0))
		RoomBuilder.box(_plug, size, toward_room.normalized() * RoomBuilder.WALL_T / 2.0 + Vector3(0, RoomBuilder.DOOR_H / 2.0, 0), material, 0)


func set_closed(value: bool) -> void:
	if closed == value:
		return
	closed = value
	_apply(false)
	AudioManager.play_sound("door", 0.8 if value else 1.0)


## Opens a locked door for good (the key is paid by the caller).
func unlock() -> void:
	if not locked:
		return
	locked = false
	var texture := load(IRON) as Texture2D
	for quad: MeshInstance3D in [_front, _back]:
		(quad.material_override as StandardMaterial3D).albedo_texture = texture
	_apply(false)
	AudioManager.play_sound("unlock")


## Moves the bars up (blocking) or into the floor (open) and switches the collision.
func _apply(at_once: bool) -> void:
	var blocking: bool = is_blocking()
	_body.process_mode = Node.PROCESS_MODE_INHERIT if blocking else Node.PROCESS_MODE_DISABLED
	var target_y: float = 0.0 if blocking else -RoomBuilder.DOOR_H - 0.05
	if _tween:
		_tween.kill()
	if at_once:
		_bars.position.y = target_y
		# A hidden doorway shows only its piece of wall, no bars.
		_bars.visible = blocking and not hidden
		return
	_bars.visible = true
	_tween = create_tween()
	_tween.tween_property(_bars, "position:y", target_y, MOVE_TIME)
	if not blocking:
		_tween.tween_callback(_bars.hide)
