class_name FurnitureLayer
extends Node2D
## The furniture standing in one room of the player's house (GameState.house.placed with this
## `room`, see House), and the placing mode: start_placing(id) puts a see-through copy under the
## mouse (green = free, red = blocked); left click places it, Escape ends. Right click ends too; a
## piece that was picked up with move_piece() then goes into storage (otherwise Escape puts it
## back where it stood). move_piece() picks a placed piece up and places it again (HouseEditor).
## start_picking() lets the player click placed pieces to put them back into storage.
## Pieces stand on their bottom centre with a small collision (house.json "size"); "floor" pieces
## (rugs) lie flat under everything and can be walked over. Plant pots (house.json "planter") are
## Planter stations; moving one keeps its uid (soil and plants stay in it). Storage boxes
## (house.json "storage") are StorageBox stations, moving keeps their contents. R ("house_rotate")
## turns the piece being placed to its next direction (Facing views "<texture>_east.png" ...;
## sideways the footprint turns with it); the direction is kept in House.placed "facing".
## The jewel case (house.json "jewel_slots") is a JewelDisplay station that sells rings and amulets.

## Emitted when the placing or picking mode starts or ends.
signal mode_changed(active: bool)

const GRID: float = 4.0
const COLOR_FREE := Color(0.6, 1.0, 0.6, 0.75)
const COLOR_BLOCKED := Color(1.0, 0.45, 0.45, 0.75)
const COLOR_PICK := Color(1.0, 0.85, 0.5)
const PLANTER_SCENE: PackedScene = preload("res://scenes/world/objects/planter.tscn")
const STORAGE_BOX_SCENE: PackedScene = preload("res://scenes/world/objects/storage_box.tscn")
const JEWEL_DISPLAY_SCENE: PackedScene = preload("res://scenes/world/objects/jewel_display.tscn")

## Where furniture may stand (the floor of the room, in this node's coordinates).
@export var floor_rect: Rect2 = Rect2(-150, -50, 300, 140)
## Room key of the pieces shown here (House.SHOP_ROOM for the shop; furniture there raises prices).
@export var room: String = "shop"

var _rugs: Node2D
var _ghost: Sprite2D
var _placing_id: String = ""
var _picking: bool = false
var _hovered: CanvasItem
## move_piece: where the piece stood, it goes back there if placing is cancelled (INF = none).
var _return_to: Vector2 = Vector2.INF
## move_piece: uid of the plant pot being moved ("" = none, or not a pot).
var _moving_uid: String = ""
## move_piece: direction the piece had where it stood.
var _return_facing: int = Facing.SOUTH
## Direction of the piece being placed.
var _facing: int = Facing.SOUTH


func _ready() -> void:
	y_sort_enabled = true
	_rugs = Node2D.new()
	_rugs.z_index = -1
	add_child(_rugs)
	_ghost = Sprite2D.new()
	_ghost.centered = false
	_ghost.z_index = 5
	_ghost.hide()
	add_child(_ghost)
	GameState.house.changed.connect(_rebuild)
	_rebuild()


func is_active() -> bool:
	return not _placing_id.is_empty() or _picking


## Placing mode for one piece from storage, turned to `facing`.
func start_placing(id: String, facing: int = Facing.SOUTH) -> void:
	stop()
	if GameState.house.get_owned(id) <= 0:
		return
	if not House.can_stand_in(id, room):
		GameState.show_message(Language.translate("%s passt nicht in diesen Raum.") % House.get_furniture(id).get("name", ""))
		return
	_placing_id = id
	_facing = facing if Facing.get_view(_texture_of(id), facing)[0] != null else Facing.SOUTH
	_show_ghost()
	_ghost.show()
	mode_changed.emit(true)


func _show_ghost() -> void:
	var view: Array = _view_of(_placing_id, _facing)
	_ghost.texture = view[0]
	_ghost.flip_h = view[1]
	_ghost.offset = Vector2(-_ghost.texture.get_width() / 2.0, -_ghost.texture.get_height())
	if House.get_furniture(_placing_id).get("floor", false):
		_ghost.offset.y = -_ghost.texture.get_height() / 2.0


## R while placing: the next direction with a view. false = the piece can't be turned.
func rotate_placing() -> bool:
	if _placing_id.is_empty():
		return false
	var base: Texture2D = _texture_of(_placing_id)
	for step in range(1, 4):
		var next: int = (_facing + step) % 4
		if Facing.get_view(base, next)[0] != null:
			_facing = next
			_show_ghost()
			return true
	return false


## Moves a placed piece: it goes back into storage and its placing mode starts right away.
func move_piece(index: int) -> void:
	if index < 0 or index >= GameState.house.placed.size():
		return
	var entry: Dictionary = GameState.house.lift_furniture(index)
	start_placing(entry["id"], int(entry.get("facing", Facing.SOUTH)))
	_return_to = Vector2(entry["x"], entry["y"])
	_return_facing = int(entry.get("facing", Facing.SOUTH))
	_moving_uid = str(entry.get("uid", ""))


## Picking mode: a click on a placed piece puts it back into storage.
func start_picking() -> void:
	stop()
	_picking = true
	mode_changed.emit(true)


func stop() -> void:
	var was_active: bool = is_active()
	if _return_to != Vector2.INF and not _placing_id.is_empty() and GameState.house.get_owned(_placing_id) > 0:
		GameState.house.place_furniture(_placing_id, _return_to, room, _moving_uid, _return_facing)
	_return_to = Vector2.INF
	_return_facing = Facing.SOUTH
	_moving_uid = ""
	_placing_id = ""
	_picking = false
	_ghost.hide()
	_set_hovered(null)
	if was_active:
		mode_changed.emit(false)


func _process(_delta: float) -> void:
	if not _placing_id.is_empty():
		var at: Vector2 = _mouse_spot()
		_ghost.position = at
		_ghost.modulate = COLOR_FREE if _is_free(_placing_id, at, _facing) else COLOR_BLOCKED
	elif _picking:
		var index: int = piece_under_mouse()
		_set_hovered(_node_of(index) if index >= 0 else null)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event.is_action_pressed("house_rotate") and not _placing_id.is_empty():
		get_viewport().set_input_as_handled()
		if not rotate_placing():
			GameState.show_message(Language.translate("Das lässt sich nicht drehen."))
		return
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		# A piece that was picked up goes into storage instead of back to its place (a plant pot
		# with plants or a box with things inside goes back; soil and sign come back into the
		# inventory).
		if _return_to != Vector2.INF:
			var piece_blocker: String = GameState.house.get_piece_blocker(_moving_uid)
			if not piece_blocker.is_empty():
				GameState.show_message(piece_blocker)
				stop()
				get_viewport().set_input_as_handled()
				return
			GameState.house.release_piece(_moving_uid)
			GameState.show_message(Language.translate("%s eingelagert.") % House.get_furniture(_placing_id).get("name", ""))
		elif piece_under_mouse() >= 0:
			# Still placing (more of that piece in storage): the piece under the mouse goes into
			# storage right away instead of the right click only ending the placing.
			var index: int = piece_under_mouse()
			var piece_name: String = House.get_furniture(GameState.house.placed[index]["id"]).get("name", "")
			var blocker: String = GameState.house.get_store_blocker(index)
			GameState.show_message(Language.translate("%s eingelagert.") % piece_name if GameState.house.pick_up_furniture(index) else blocker)
		_return_to = Vector2.INF
		_moving_uid = ""
		stop()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		stop()
		get_viewport().set_input_as_handled()
		return
	if not (mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT):
		return
	get_viewport().set_input_as_handled()
	if _picking:
		var index: int = piece_under_mouse()
		if index >= 0:
			_set_hovered(null)
			var blocker: String = GameState.house.get_store_blocker(index)
			if not GameState.house.pick_up_furniture(index):
				GameState.show_message(blocker)
		return
	var at: Vector2 = _mouse_spot()
	if not _is_free(_placing_id, at, _facing):
		GameState.show_message(Language.translate("Hier ist kein Platz."))
		return
	var id: String = _placing_id
	GameState.house.place_furniture(id, at, room, _moving_uid, _facing)
	_return_to = Vector2.INF
	_moving_uid = ""
	if GameState.house.get_owned(id) <= 0:
		stop()


# --- Showing the furniture -------------------------------------------------------------

func _rebuild() -> void:
	for child in get_children():
		if child != _rugs and child != _ghost:
			child.queue_free()
	for child in _rugs.get_children():
		child.queue_free()
	_hovered = null
	var placed: Array[Dictionary] = GameState.house.placed
	for i in placed.size():
		if placed[i].get("room", House.SHOP_ROOM) == room:
			_spawn(i, placed[i])


func _spawn(index: int, entry: Dictionary) -> void:
	var id: String = entry["id"]
	var data: Dictionary = House.get_furniture(id)
	var facing: int = int(entry.get("facing", Facing.SOUTH))
	var view: Array = _view_of(id, facing)
	var texture: Texture2D = view[0]
	if texture == null:
		return
	var at := Vector2(entry["x"], entry["y"])
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.flip_h = view[1]
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	if data.get("floor", false):
		sprite.offset.y = -texture.get_height() / 2.0
		sprite.position = at
		sprite.set_meta("furniture_index", index)
		_rugs.add_child(sprite)
		return
	var body: StaticBody2D
	if House.get_planter_size(id) > 0:
		var planter: Planter = PLANTER_SCENE.instantiate()
		planter.setup(str(entry.get("uid", "")), id)
		body = planter
	elif House.get_storage_size(id) > 0:
		var box: StorageBox = STORAGE_BOX_SCENE.instantiate()
		box.setup(str(entry.get("uid", "")), id)
		body = box
	elif int(data.get("jewel_slots", 0)) > 0:
		var case: JewelDisplay = JEWEL_DISPLAY_SCENE.instantiate()
		case.setup(id)
		body = case
	else:
		body = StaticBody2D.new()
	body.position = at
	body.set_meta("furniture_index", index)
	body.add_child(sprite)
	body.move_child(sprite, 0)
	var size: Vector2 = _footprint(id, facing)
	if size.x > 0.0 and size.y > 0.0:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		shape.position = Vector2(0.0, -size.y / 2.0)
		body.add_child(shape)
	add_child(body)


func _texture_of(id: String) -> Texture2D:
	var path: String = House.get_furniture(id).get("texture", "")
	return load(path) if ResourceLoader.exists(path) else null


## Picture of a piece facing `facing`: [texture, mirrored] (no view that way = the south picture).
func _view_of(id: String, facing: int) -> Array:
	var base: Texture2D = _texture_of(id)
	var view: Array = Facing.get_view(base, facing)
	return view if view[0] != null else [base, false]


## Footprint (house.json "size"), turned sideways for east and west.
func _footprint(id: String, facing: int = Facing.SOUTH) -> Vector2:
	var size_data: Array = House.get_furniture(id).get("size", [12, 6])
	var size: Vector2 = Vector2(size_data[0], size_data[1]) if size_data.size() == 2 else Vector2(12, 6)
	if (facing != Facing.EAST and facing != Facing.WEST) or size.x <= 0.0:
		return size
	var base: Texture2D = _texture_of(id)
	var view: Array = _view_of(id, facing)
	if base == null or view[0] == base:
		return size
	return Facing.turn_footprint(size, Facing.get_used_rect(base), Facing.get_used_rect(view[0], view[1]))


# --- Placing and picking -------------------------------------------------------------

func _mouse_spot() -> Vector2:
	return (get_local_mouse_position() / GRID).round() * GRID


## The piece fits: its footprint lies on the floor and (unless it is a rug) touches nothing solid.
func _is_free(id: String, at: Vector2, facing: int = Facing.SOUTH) -> bool:
	var size: Vector2 = _footprint(id, facing)
	var texture: Texture2D = _view_of(id, facing)[0]
	if House.get_furniture(id).get("floor", false):
		var half: Vector2 = texture.get_size() / 2.0 if texture else Vector2(8, 8)
		return floor_rect.encloses(Rect2(at - half, half * 2.0))
	var foot := Rect2(at - Vector2(size.x / 2.0, size.y), size)
	if not floor_rect.encloses(foot):
		return false
	var rect := RectangleShape2D.new()
	rect.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = rect
	query.transform = Transform2D(0.0, to_global(at - Vector2(0.0, size.y / 2.0)))
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Index of the placed piece whose picture is under the mouse (the front-most), -1 = none.
func piece_under_mouse() -> int:
	var mouse: Vector2 = get_local_mouse_position()
	var best: int = -1
	var best_y: float = -INF
	var placed: Array[Dictionary] = GameState.house.placed
	for i in placed.size():
		if placed[i].get("room", House.SHOP_ROOM) != room:
			continue
		var texture: Texture2D = _view_of(placed[i]["id"], int(placed[i].get("facing", Facing.SOUTH)))[0]
		if texture == null:
			continue
		var at := Vector2(placed[i]["x"], placed[i]["y"])
		var is_floor: bool = House.get_furniture(placed[i]["id"]).get("floor", false)
		var top_left: Vector2 = at - Vector2(texture.get_width() / 2.0, texture.get_height() / (2.0 if is_floor else 1.0))
		# Rugs count as lying behind everything else.
		var sort_y: float = at.y - (10000.0 if is_floor else 0.0)
		if Rect2(top_left, texture.get_size()).has_point(mouse) and sort_y > best_y:
			best = i
			best_y = sort_y
	return best


func _node_of(index: int) -> CanvasItem:
	for child in get_children() + _rugs.get_children():
		if child.has_meta("furniture_index") and int(child.get_meta("furniture_index")) == index:
			return child
	return null


func _set_hovered(node: CanvasItem) -> void:
	if _hovered == node:
		return
	if is_instance_valid(_hovered):
		_hovered.modulate = Color.WHITE
	_hovered = node
	if is_instance_valid(_hovered):
		_hovered.modulate = COLOR_PICK
