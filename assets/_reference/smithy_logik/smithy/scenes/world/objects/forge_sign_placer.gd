class_name ForgeSignPlacer
extends Node2D
## Furnishing the outside of the smithy (a child of the smithy node in village.tscn, at its origin,
## next to the ForgeSignWall `sign_node`), like HouseEditor inside. In front of the house (the player
## below the wall areas, at most REACH px away) the key "house_edit" (B) switches the mode on and
## off; it opens the storage window of the outside (HouseExteriorMenu). It holds the forge sign
## (ForgeSign) and the wanted poster from the dark city (WantedPoster) while they are owned and not
## hanging. Both are "pieces" (ids HouseExteriorMenu.SIGN_ID / POSTER_ID); everything below works
## the same for both, except that only the sign opens its name window after hanging. Two pieces
## may not overlap.
## In the mode the wall areas of this house level show light (smithy_house_layout.gd "wall_rects").
## A click on the sign in the window, or on the hanging sign, lifts it: the board follows the mouse,
## green = enough of it lies on the wall (ForgeSign.min_on_wall, 60 %; the rest may stick out). A click hangs it there (ForgeSign.set_spot, the first
## time attach()), the mode ends and the name window opens. Right click on the carried or the
## hanging sign takes it down into the window's storage (ForgeSign.remove). Escape, B or closing
## the window end the mode (a carried sign goes back where it was).
## Phone (MobileUi.active): the "B" button is shown near the house (this node is in
## MobileUi.BUILD_GROUP and visible only then); a tap lifts the hanging sign, after that it follows
## the finger while it is down, the green check mark over it (PlaceCheck) hangs it, the box
## button ("house_store") takes it down.

## How far in front of and beside the walls B still works.
const REACH: float = 70.0
const STORAGE_MENU: PackedScene = preload("res://scenes/ui/menus/house_exterior_menu.tscn")
const HINT: String = "Haus außen einrichten: Klick hebt an, Klick hängt auf, Rechtsklick nimmt ab. {key_build} beendet."
const HINT_PHONE: String = "Haus außen einrichten: Antippen hebt an, mit dem Finger verschieben, der grüne Haken hängt auf. Kisten-Knopf nimmt ab, B beendet."
const WALL_COLOR := Color(1.0, 1.0, 0.85, 0.16)
const WALL_EDGE := Color(1.0, 1.0, 0.85, 0.45)

## The sign on the wall.
@export var sign_node: ForgeSignWall
## The wanted poster on the wall (optional).
@export var poster_node: WantedPosterWall

var _active: bool = false
## A piece hangs at the pointer.
var _carrying: bool = false
## The piece carried (or last carried): HouseExteriorMenu.SIGN_ID / POSTER_ID.
var _piece: String = HouseExteriorMenu.SIGN_ID
var _player: Node2D
var _storage_menu: HouseExteriorMenu
## Phone: a finger is down and pushes the board.
var _dragging: bool = false
var _check: PlaceCheck
## Where the board is now (smithy coordinates, top left) and whether it may hang there.
var _spot: Vector2 = Vector2.ZERO
var _free: bool = false
## The hanging piece under the pointer ("" = none).
var _hovered: String = ""


func _ready() -> void:
	add_to_group(MobileUi.BUILD_GROUP)
	z_index = 1
	if MobileUi.active():
		_check = PlaceCheck.new()
		_check.name = "PlaceCheck"
		add_child(_check)
	_storage_menu = STORAGE_MENU.instantiate()
	add_child(_storage_menu)
	_storage_menu.piece_chosen.connect(_on_piece_chosen)
	_storage_menu.visibility_changed.connect(func() -> void:
		if not _storage_menu.visible and _active:
			_set_active(false))


## true while the outside is being furnished (MobileUi.build_mode_active: taps move things).
func is_active() -> bool:
	return _active


## true while a piece hangs at the pointer.
func is_carrying() -> bool:
	return _carrying


## The piece carried now (or last), e.g. HouseExteriorMenu.POSTER_ID.
func get_carried_piece() -> String:
	return _piece


## The storage window of the outside (for tests and later decoration).
func get_storage_menu() -> HouseExteriorMenu:
	return _storage_menu


## The player stands in front of the house (only then B works and the phone shows "B").
func is_player_near() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if _player == null:
		return false
	var feet: Vector2 = to_local(_player.global_position)
	var left: float = INF
	var right: float = -INF
	for rect: Rect2 in _wall_rects():
		left = minf(left, rect.position.x)
		right = maxf(right, rect.end.x)
	return feet.x >= left - REACH and feet.x <= right + REACH and feet.y >= -REACH and feet.y <= REACH


func _process(_delta: float) -> void:
	# Phone: MobileUi.build_mode_offered shows "B" for visible nodes of the build group.
	var near: bool = _active or is_player_near()
	if visible != near:
		visible = near
	if not _active:
		return
	if not _carrying:
		_set_hovered(_piece_at_pointer())
		return
	var node: Node = _node(_piece)
	if _check == null or _dragging:
		var size: Vector2 = node.get_board_size()
		var spot: Vector2 = (_pointer_local() - size / 2.0).round()
		if spot != _spot:
			_spot = spot
			_free = fits(_spot, size)
			node.move_preview(_spot, _free)
	if _check:
		var size_now: Vector2 = node.get_board_size()
		var parent_2d := get_parent() as Node2D
		_check.show_over(parent_2d.to_global(_spot + Vector2(size_now.x / 2.0, -4.0)), _free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("house_edit"):
		if not _active and not is_player_near():
			return
		get_viewport().set_input_as_handled()
		_set_active(not _active)
		return
	if not _active:
		return
	var mouse := event as InputEventMouseButton
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_set_active(false)
	elif event.is_action_pressed("house_store") or (mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT):
		get_viewport().set_input_as_handled()
		var under: String = _piece_at_pointer()
		if _carrying or not under.is_empty():
			take_down(under)
	elif mouse and mouse.button_index == MOUSE_BUTTON_LEFT and MobileUi.active():
		get_viewport().set_input_as_handled()
		if not mouse.pressed:
			_dragging = false
		elif not _carrying:
			var touched: String = _piece_at_pointer()
			if not touched.is_empty():
				lift(touched)
		elif _check and _check.is_hit(MobileUi.pointer(self)):
			hang_at(_spot)
		else:
			_dragging = true
	elif mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if _carrying:
			hang_at(_spot)
		elif not _piece_at_pointer().is_empty():
			lift(_piece_at_pointer())


func _set_active(active: bool) -> void:
	if not active and _carrying:
		_put_back()
	_set_hovered("")
	_dragging = false
	if _check:
		_check.hide()
	_active = active
	_storage_menu.visible = active
	queue_redraw()
	var hint: String = HINT_PHONE if MobileUi.active() else HINT
	GameState.show_message(KeyBindings.fill(Language.translate(hint)) if active else Language.translate("Einrichten beendet."))


## A click on a piece in the storage window: it hangs at the pointer.
func _on_piece_chosen(id: String) -> void:
	lift(id)


## Lifts a piece (hanging or from the storage): it follows the pointer until it is hung.
func lift(id: String = HouseExteriorMenu.SIGN_ID) -> void:
	var node: Node = _node(id)
	if not _active or _carrying or node == null or not _state(id).is_owned():
		return
	_set_hovered("")
	_piece = id
	_carrying = true
	_dragging = false
	_spot = node.get_board_spot()
	_free = fits(_spot, node.get_board_size())
	node.start_preview()
	node.move_preview(_spot, _free)


## Takes the carried piece (else `id`, else the sign) down into the storage of the outside.
func take_down(id: String = "") -> void:
	if _carrying or id.is_empty():
		id = _piece if _carrying else HouseExteriorMenu.SIGN_ID
	_carrying = false
	_dragging = false
	_set_hovered("")
	if _check:
		_check.hide()
	var node: Node = _node(id)
	if node == null:
		return
	node.stop_preview()
	var state: RefCounted = _state(id)
	if state.attached:
		state.remove()
		var text: String = "Der Steckbrief ist abgenommen und liegt im Lager." if id == HouseExteriorMenu.POSTER_ID \
				else "Das Schild ist abgenommen und liegt im Lager."
		GameState.show_message(Language.translate(text))


## Escape or the end of the mode while carrying: the piece goes back where it was (or into storage).
func _put_back() -> void:
	_carrying = false
	_dragging = false
	var node: Node = _node(_piece)
	if node:
		node.stop_preview()


## Hangs the carried piece with its top left corner at `top_left` (smithy coordinates), if it lies
## on the wall enough there (fits). false = it doesn't (it stays at the pointer).
func hang_at(top_left: Vector2) -> bool:
	var node: Node = _node(_piece)
	var poster: bool = _piece == HouseExteriorMenu.POSTER_ID
	if not _carrying or node == null or not fits(top_left, node.get_board_size()):
		var refused: String = "Der Steckbrief muss größtenteils an der Hauswand hängen, nicht über dem Schild." if poster \
				else "Das Schild muss größtenteils an der Hauswand hängen, nicht über dem Steckbrief."
		GameState.show_message(Language.translate(refused))
		return false
	var state: RefCounted = _state(_piece)
	state.set_spot(GameState.house.level, top_left)
	if not state.attached:
		state.attach()
	_carrying = false
	node.stop_preview()
	_set_active(false)
	if poster:
		GameState.show_message(Language.translate("Der Steckbrief hängt jetzt an deiner Schmiede."))
		return true
	GameState.show_message(Language.translate("Das Schild hängt jetzt an deiner Schmiede."))
	# Every time it is hung up: the name window, the name field ready to type.
	sign_node.open_menu(true)
	return true


## Enough of the carried piece lies on the wall (ForgeSign.min_on_wall, e.g. 60 %), the rest may
## stick out over the edge, and it doesn't cover the other hanging piece.
func fits(top_left: Vector2, size: Vector2) -> bool:
	if get_wall_share(top_left, size) < ForgeSign.min_on_wall() - 0.0001:
		return false
	var board := Rect2(top_left, size)
	for id: String in [HouseExteriorMenu.SIGN_ID, HouseExteriorMenu.POSTER_ID]:
		if _carrying and id == _piece:
			continue
		var node: Node = _node(id)
		if node and _state(id).attached and board.intersects(node.get_board_rect()):
			return false
	return true


## Share (0..1) of the board's area that lies on the wall areas of this house level.
func get_wall_share(top_left: Vector2, size: Vector2) -> float:
	var board := Rect2(top_left, size)
	if board.get_area() <= 0.0:
		return 0.0
	var covered: float = 0.0
	for rect: Rect2 in _wall_rects():
		covered += board.intersection(rect).get_area()
	return minf(covered / board.get_area(), 1.0)


func _pointer_local() -> Vector2:
	return (get_parent() as Node2D).to_local(MobileUi.pointer(self))


## The hanging piece under the pointer ("" = none; the poster first, it is the smaller one).
func _piece_at_pointer() -> String:
	var pointer: Vector2 = _pointer_local()
	for id: String in [HouseExteriorMenu.POSTER_ID, HouseExteriorMenu.SIGN_ID]:
		var node: Node = _node(id)
		if node and _state(id).attached and node.get_board_rect().has_point(pointer):
			return id
	return ""


func _set_hovered(id: String) -> void:
	if id == _hovered:
		return
	if not _hovered.is_empty() and _node(_hovered):
		_node(_hovered).set_hovered(false)
	_hovered = id
	if not id.is_empty() and _node(id):
		_node(id).set_hovered(true)


## The wall node of a piece (null = none in this scene).
func _node(id: String) -> Node:
	return poster_node if id == HouseExteriorMenu.POSTER_ID else sign_node


## The saved state of a piece (ForgeSign or WantedPoster).
func _state(id: String) -> RefCounted:
	return GameState.house.wanted_poster if id == HouseExteriorMenu.POSTER_ID else GameState.house.forge_sign


## Wall areas of the current house level (smithy coordinates).
func _wall_rects() -> Array:
	var layout: Node = get_parent()
	return layout.get_wall_rects() if layout.has_method("get_wall_rects") else []


func _draw() -> void:
	if not _active:
		return
	# Drawn in the smithy's coordinates (this node sits at its origin).
	for rect: Rect2 in _wall_rects():
		draw_rect(rect, WALL_COLOR)
		draw_rect(rect, WALL_EDGE, false, 1.0)
