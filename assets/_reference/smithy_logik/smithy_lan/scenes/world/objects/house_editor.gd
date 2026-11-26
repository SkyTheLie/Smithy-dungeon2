class_name HouseEditor
extends Node2D
## Moving things in the player's house: the key "house_edit" (B) switches the mode on and off.
## In the mode the storage window opens (HouseStorageMenu): a click on a piece there places it
## (furniture of this room, `furniture_layer`). A click in the room picks up one of `movables`
## (stations, tables, cash box, decoration) or a piece of furniture; it follows the mouse in a 4 px
## grid, green = free, red = blocked (its collision must lie on `floor_rect`, touch nothing solid
## and keep away from doors). A click puts it down. Right click on a carried or hovered piece of
## furniture, decoration (house.json "decorations": barrel, sacks, coal) or bought station
## (Station.get_store_id: water trough, grindstone ...) puts it into storage; anvil, forge, smelter,
## workbench, tables, cash box, bed and chest go back where they were. A stored station or
## decoration is chosen in the storage window like furniture and is carried at once. R
## ("house_rotate") turns the carried or hovered thing to its next direction (Facing, only things
## with turned views; a hovered one only if it still fits). B, Escape or closing the window ends
## the mode.
## Rooms without their own FurnitureLayer get one (room key = `room`), so decoration can stand in
## every room of the house; only furniture in the shop raises the prices (House.SHOP_ROOM).
## Positions and directions are saved per room (`room`) in GameState.house.moved and set again
## when the room loads. Stations still covered by a cobweb can't be moved.

const GRID: float = 4.0
## Nothing may stand this close to a door (its centre).
const DOOR_DISTANCE: float = 28.0
const COLOR_FREE := Color(0.6, 1.0, 0.6, 0.85)
const COLOR_BLOCKED := Color(1.0, 0.45, 0.45, 0.85)
const COLOR_HOVER := Color(1.0, 0.85, 0.5)
const HINT: String = "Einrichten: Klick hebt an, Klick stellt ab, {key_rotate} dreht, Rechtsklick lagert Möbel, Deko und Geräte ein. {key_build} beendet."
const STORAGE_MENU: PackedScene = preload("res://scenes/ui/menus/house_storage_menu.tscn")
const DESIGN_MENU: PackedScene = preload("res://scenes/ui/menus/room_design_menu.tscn")

## Key of the room in GameState.house.moved (one per room size, e.g. "smithy_big").
@export var room: String = ""
## Floor of the room in global coordinates (everything moved must stand on it).
@export var floor_rect: Rect2 = Rect2(-150, -50, 300, 140)
## What can be moved (relative to this node). Missing or removed nodes are skipped.
@export var movables: Array[NodePath] = []
## The furniture of the shop (optional): its pieces can be moved too.
@export var furniture_layer: FurnitureLayer

var _active: bool = false
var _storage_menu: HouseStorageMenu
## Room designer of this room (only if the room has a RoomStyleLayer).
var _design_menu: RoomDesignMenu
var _style_layer: RoomStyleLayer
var _carried: Node2D
var _carried_from: Vector2
## Direction of the carried thing when it was picked up (it goes back to it with the thing).
var _carried_facing: int = Facing.SOUTH
var _hovered: Node2D


func _ready() -> void:
	if furniture_layer == null:
		_create_furniture_layer.call_deferred()
	_storage_menu = STORAGE_MENU.instantiate()
	add_child(_storage_menu)
	_storage_menu.piece_chosen.connect(_on_piece_chosen)
	_storage_menu.station_chosen.connect(_on_station_chosen)
	_storage_menu.decor_chosen.connect(_on_decor_chosen)
	_storage_menu.room = room
	if furniture_layer:
		_storage_menu.furniture_room = furniture_layer.room
	_find_style_layer.call_deferred()
	_storage_menu.design_requested.connect(_open_design)
	_storage_menu.visibility_changed.connect(func() -> void:
		if not _storage_menu.visible and _active:
			_set_active(false))
	for path in movables:
		var node: Node2D = _movable(path)
		if node == null:
			continue
		var saved: Vector2 = GameState.house.get_moved(room, String(path))
		if saved != Vector2.INF:
			node.global_position = saved
		var facing: int = GameState.house.get_moved_facing(room, String(path))
		if facing != Facing.SOUTH:
			Facing.apply(node, facing)
		if GameState.house.is_decor_stored(room, String(path)):
			_set_decor_stored(node, true)


## Furniture of this room (decoration in the workshop or bedroom), on the same floor.
func _create_furniture_layer() -> void:
	var layer := FurnitureLayer.new()
	layer.room = room
	_storage_menu.furniture_room = room
	get_parent().add_child(layer)
	layer.floor_rect = Rect2(layer.to_local(floor_rect.position), floor_rect.size)
	furniture_layer = layer


func _movable(path: NodePath) -> Node2D:
	var node: Node = get_node_or_null(path)
	if node == null or node.is_queued_for_deletion() or not node is Node2D:
		return null
	return node


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("house_edit"):
		get_viewport().set_input_as_handled()
		_set_active(not _active)
		return
	if not _active or (furniture_layer and furniture_layer.is_active()):
		return
	var mouse := event as InputEventMouseButton
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_set_active(false)
	elif event.is_action_pressed("house_rotate"):
		get_viewport().set_input_as_handled()
		_rotate()
	elif mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if _carried:
			if not _store_node(_carried):
				_put_back()
		else:
			_store_under_mouse()
	elif mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if _carried:
			_put_down()
		else:
			_pick_up()


## The RoomStyleLayer of this room (below the editor's parent, e.g. SmallShop), if any.
func _find_style_layer() -> void:
	for node: Node in get_parent().find_children("*", "Node2D", true, false):
		if node is RoomStyleLayer:
			_style_layer = node
			break
	_storage_menu.can_design = _style_layer != null


func _open_design() -> void:
	if _style_layer == null:
		return
	if _design_menu == null:
		_design_menu = DESIGN_MENU.instantiate()
		add_child(_design_menu)
	var kinds: Array[String] = ["floor", "wall"]
	if not _style_layer.door_rects.is_empty():
		kinds.append("door")
	_design_menu.open_for(_style_layer.room, kinds)


func _set_active(active: bool) -> void:
	if _carried:
		_put_back()
	_set_hovered(null)
	if not active and furniture_layer:
		furniture_layer.stop()
	if not active and _design_menu:
		_design_menu.close()
	_active = active
	_storage_menu.visible = active
	GameState.show_message(KeyBindings.fill(Language.translate(HINT)) if active else Language.translate("Einrichten beendet."))


## A piece from the storage window: placing starts (left click places, right click ends).
func _on_piece_chosen(id: String) -> void:
	if _carried:
		_put_back()
	_set_hovered(null)
	if furniture_layer:
		furniture_layer.start_placing(id)


## A stored station from the storage window: it appears where it stood and is carried at once
## (left click puts it down, right click stores it again).
func _on_station_chosen(id: String) -> void:
	if _carried:
		_put_back()
	_set_hovered(null)
	if furniture_layer:
		furniture_layer.stop()
	var station: Station = _find_station(id)
	if station == null:
		GameState.show_message(Language.translate("Das Gerät kann hier nicht aufgestellt werden."))
		return
	station.set_stored(false)
	GameState.house.set_station_stored(id, false)
	_carry(station)


## The entry of `movables` that points to `node` (empty if none).
func _path_of(node: Node2D) -> NodePath:
	for path in movables:
		if _movable(path) == node:
			return path
	return NodePath("")


func _find_station(id: String) -> Station:
	for path in movables:
		var station := _movable(path) as Station
		if station and station.get_store_id() == id:
			return station
	return null


## A stored decoration (node path) from the storage window: it appears where it stood and is
## carried at once.
func _on_decor_chosen(path: String) -> void:
	if _carried:
		_put_back()
	_set_hovered(null)
	if furniture_layer:
		furniture_layer.stop()
	var node: Node2D = _movable(NodePath(path))
	if node == null:
		return
	_set_decor_stored(node, false)
	GameState.house.set_decor_stored(room, path, false)
	_carry(node)


## In storage: invisible and without collision (a disabled node leaves the physics).
func _set_decor_stored(node: Node2D, stored: bool) -> void:
	node.visible = not stored
	node.process_mode = Node.PROCESS_MODE_DISABLED if stored else Node.PROCESS_MODE_INHERIT


## Right click (nothing carried): the piece of furniture, decoration or bought station under the
## mouse goes into storage (furniture in front of a station wins, like when picking up).
func _store_under_mouse() -> void:
	var node: Node2D = _movable_under_mouse()
	if furniture_layer:
		var piece: int = furniture_layer.piece_under_mouse()
		if piece >= 0 and (node == null or _piece_y(piece) >= node.global_position.y):
			var piece_name: String = House.get_furniture(GameState.house.placed[piece]["id"]).get("name", "")
			var blocker: String = GameState.house.get_store_blocker(piece)
			if GameState.house.pick_up_furniture(piece):
				GameState.show_message(Language.translate("%s eingelagert.") % piece_name)
			else:
				GameState.show_message(blocker)
			return
	if node and not _store_node(node):
		GameState.show_message(Language.translate("Das bleibt stehen (einlagern lassen sich Möbel, Deko und gekaufte Geräte)."))


## Puts a bought station or a decoration (carried or not) into storage. false = it can't be stored.
func _store_node(node: Node2D) -> bool:
	var path: String = String(_path_of(node))
	if not path.is_empty() and not House.get_decoration(node.name).is_empty():
		if _carried == node:
			_put_back()
		_set_hovered(null)
		node.modulate = Color.WHITE
		_set_decor_stored(node, true)
		GameState.house.set_decor_stored(room, path, true)
		GameState.show_message(Language.translate("%s eingelagert.") % House.get_decoration(node.name).get("name", ""))
		return true
	var station := node as Station
	if station == null or station.get_store_id().is_empty():
		return false
	if station.blocked:
		GameState.show_message(Language.translate("Erst die Spinnweben entfernen."))
		return true
	if _carried == station:
		_put_back()
	_set_hovered(null)
	station.modulate = Color.WHITE
	station.set_stored(true)
	GameState.house.set_station_stored(station.get_store_id(), true)
	GameState.show_message(Language.translate("%s eingelagert.") % Economy.get_station_offer(station.get_store_id()).get("name", ""))
	return true


func _process(_delta: float) -> void:
	if not _active or (furniture_layer and furniture_layer.is_active()):
		return
	if _carried:
		var at: Vector2 = (get_global_mouse_position() / GRID).round() * GRID
		_carried.global_position = at
		_carried.modulate = COLOR_FREE if _can_stand(_carried) else COLOR_BLOCKED
	else:
		_set_hovered(_movable_under_mouse())


# --- Picking up and putting down ---------------------------------------------------------

func _pick_up() -> void:
	if furniture_layer:
		var piece: int = furniture_layer.piece_under_mouse()
		var node: Node2D = _movable_under_mouse()
		# a piece of furniture in front of (below) a station wins
		if piece >= 0 and (node == null or _piece_y(piece) >= node.global_position.y):
			_set_hovered(null)
			furniture_layer.move_piece(piece)
			return
	var target: Node2D = _movable_under_mouse()
	if target == null:
		return
	if target.get("blocked") == true:
		GameState.show_message(Language.translate("Erst die Spinnweben entfernen."))
		return
	_set_hovered(null)
	_carry(target)


func _carry(node: Node2D) -> void:
	_carried = node
	_carried_from = node.global_position
	_carried_facing = Facing.get_facing(node)


func _put_down() -> void:
	if not _can_stand(_carried):
		GameState.show_message(Language.translate("Hier ist kein Platz."))
		return
	_carried.modulate = Color.WHITE
	GameState.house.set_moved(room, String(get_path_to(_carried)), _carried.global_position, Facing.get_facing(_carried))
	_carried = null


func _put_back() -> void:
	_carried.global_position = _carried_from
	if Facing.get_facing(_carried) != _carried_facing:
		Facing.apply(_carried, _carried_facing)
	_carried.modulate = Color.WHITE
	_carried = null


## R: turns the carried thing, or the one under the mouse where it stands (if it still fits there);
## a piece of furniture under the mouse is picked up turned.
func _rotate() -> void:
	var target: Node2D = _carried if _carried else _movable_under_mouse()
	# A piece of furniture in front of the station: it is picked up turned (a click places it).
	if furniture_layer and not _carried:
		var piece: int = furniture_layer.piece_under_mouse()
		if piece >= 0 and (target == null or _piece_y(piece) >= target.global_position.y):
			_set_hovered(null)
			furniture_layer.move_piece(piece)
			if not furniture_layer.rotate_placing():
				GameState.show_message(Language.translate("Das lässt sich nicht drehen."))
			return
	if target == null:
		return
	if target.get("blocked") == true:
		GameState.show_message(Language.translate("Erst die Spinnweben entfernen."))
		return
	var facing: int = Facing.get_facing(target)
	var next: int = Facing.get_next(target)
	if next == facing:
		GameState.show_message(Language.translate("Das lässt sich nicht drehen."))
		return
	Facing.apply(target, next)
	if target == _carried:
		return
	if not _can_stand(target):
		Facing.apply(target, facing)
		GameState.show_message(Language.translate("Zum Drehen ist hier kein Platz."))
		return
	GameState.house.set_moved(room, String(get_path_to(target)), target.global_position, next)


func _piece_y(index: int) -> float:
	return float(GameState.house.placed[index]["y"])


## The node may stand where it is now: its collision on the floor, touching nothing solid, away
## from doors. Without a collision only its position counts.
func _can_stand(node: Node2D) -> bool:
	for door in get_tree().current_scene.find_children("*", Language.translate("Door"), true, false):
		if is_instance_valid(door) and (door as Node2D).global_position.distance_to(node.global_position) < DOOR_DISTANCE:
			return false
	var shapes: Array[CollisionShape2D] = []
	for child in node.get_children():
		if child is CollisionShape2D and not child.disabled and child.shape:
			shapes.append(child)
	if shapes.is_empty():
		return floor_rect.has_point(node.global_position)
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	for shape in shapes:
		var bounds: Rect2 = shape.global_transform * shape.shape.get_rect()
		if not floor_rect.encloses(bounds):
			return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape.shape
		query.transform = shape.global_transform
		query.collide_with_areas = false
		if node is CollisionObject2D:
			query.exclude = [(node as CollisionObject2D).get_rid()]
		if not space.intersect_shape(query, 1).is_empty():
			return false
	return true


# --- Finding things under the mouse -------------------------------------------------------

## The movable whose picture is under the mouse (the front-most one), null = none.
func _movable_under_mouse() -> Node2D:
	var mouse: Vector2 = get_global_mouse_position()
	var best: Node2D = null
	for path in movables:
		var node: Node2D = _movable(path)
		if node and node.is_visible_in_tree() and _picture_rect(node).has_point(mouse):
			if best == null or node.global_position.y > best.global_position.y:
				best = node
	return best


## Global rectangle of all pictures of a node (Sprite2D / AnimatedSprite2D in it).
func _picture_rect(node: Node2D) -> Rect2:
	var rect := Rect2()
	var found: bool = false
	var sprites: Array[Node] = node.find_children("*", Language.translate("Node2D"), true, false)
	sprites.push_front(node)
	for item in sprites:
		var local := Rect2()
		if item is Sprite2D and (item as Sprite2D).texture and item.visible:
			local = (item as Sprite2D).get_rect()
		elif item is AnimatedSprite2D and (item as AnimatedSprite2D).sprite_frames and item.visible:
			var animated := item as AnimatedSprite2D
			var texture: Texture2D = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
			if texture == null:
				continue
			var size: Vector2 = texture.get_size()
			local = Rect2(animated.offset - (size / 2.0 if animated.centered else Vector2.ZERO), size)
		else:
			continue
		var global_rect: Rect2 = (item as Node2D).global_transform * local
		rect = global_rect if not found else rect.merge(global_rect)
		found = true
	return rect if found else Rect2(node.global_position - Vector2(8, 16), Vector2(16, 16))


func _set_hovered(node: Node2D) -> void:
	if _hovered == node:
		return
	if is_instance_valid(_hovered) and _hovered != _carried:
		_hovered.modulate = Color.WHITE
	_hovered = node
	if is_instance_valid(_hovered):
		_hovered.modulate = COLOR_HOVER
