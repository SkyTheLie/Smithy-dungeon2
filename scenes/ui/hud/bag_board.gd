class_name BagBoard
extends Control
## One part of the bag grid on screen (Bag): the bag with its backpacks (Bag.MAIN) or the safe
## place (Bag.SAFE). Draws the cells (backpack cells in the backpack's colour, the safe place
## golden), the loot on them (frame in its rarity colour, the count) and, while something is
## dragged over it, where it would land (green = fits, yellow = swaps, red = no).
## Drag and drop: take a piece, drop it on a cell (Bag.move_to); turn it while dragging with R or
## the right mouse button (rotate_drag, called by the window). A right click without dragging
## sends right_clicked (the merchant buys it). Only shows and forwards; the rules are in Bag.

signal hovered(index: int)
signal right_clicked(index: int)
## Shift + left click on a piece (moves it between the bag and the safe place).
signal shift_clicked(index: int)
signal dropped

const CELL_COLOR := Color(0.2, 0.15, 0.13)
const CELL_LINE := Color(0.33, 0.27, 0.23)
const SAFE_CELL := Color(0.3, 0.24, 0.1)
const SAFE_LINE := Color(1.0, 0.78, 0.3)
const FIT_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const SWAP_COLOR := Color(1.0, 0.85, 0.3, 0.45)
const BAD_COLOR := Color(1.0, 0.25, 0.2, 0.45)
const PULSE_COLOR := Color(1.0, 0.85, 0.3)

var bag: Bag
var section: String = Bag.MAIN
var cell_px: float = 16.0
## Pulsing frame (the guide points at the safe place).
var pulse: bool = false:
	set(value):
		pulse = value
		queue_redraw()

var _origin := Vector2i.ZERO
var _span := Vector2i.ONE
## While dragging over: {"cell", "id", "rot", "color"}.
var _drop_hint: Dictionary = {}
var _hover_index: int = -1
var _time: float = 0.0


func setup(the_bag: Bag, the_section: String) -> void:
	bag = the_bag
	section = the_section
	mouse_filter = Control.MOUSE_FILTER_STOP
	bag.changed.connect(refresh)
	mouse_exited.connect(_on_mouse_exited)
	refresh()


## Cell size that lets a board of `span` cells fit into `room` pixels (between 10 and 18).
static func fit_cell(cells_span: Vector2i, room: Vector2) -> float:
	return clampf(floorf(minf(room.x / maxf(1.0, cells_span.x), room.y / maxf(1.0, cells_span.y))), 10.0, 18.0)


## The cells this board shows, from the top left (Bag.section_cells).
func board_span() -> Vector2i:
	return _span


func refresh() -> void:
	# Load the pictures now, not while drawing (a texture loaded in _draw shows white).
	for i in bag.size():
		icon_of_place(bag.get_place(i))
	var cells: Array[Vector2i] = bag.section_cells(section)
	if cells.is_empty():
		_origin = Vector2i.ZERO
		_span = Vector2i.ONE
	else:
		var low: Vector2i = cells[0]
		var high: Vector2i = cells[0]
		for cell: Vector2i in cells:
			low = low.min(cell)
			high = high.max(cell)
		_origin = low
		_span = high - low + Vector2i.ONE
	custom_minimum_size = Vector2(_span) * cell_px
	queue_redraw()


func cell_at(at: Vector2) -> Vector2i:
	return _origin + Vector2i(floori(at.x / cell_px), floori(at.y / cell_px))


func _rect_of(cell: Vector2i, size_in_cells: Vector2i) -> Rect2:
	return Rect2(Vector2(cell - _origin) * cell_px, Vector2(size_in_cells) * cell_px)


## The middle of place `index` on screen (the guide points there), or the board's middle.
func place_center(index: int) -> Vector2:
	var place: Dictionary = bag.get_place(index)
	if place.is_empty():
		return global_position + size / 2.0
	return global_position + _rect_of(Vector2i(int(place["x"]), int(place["y"])), Bag.footprint(place)).get_center()


func _process(delta: float) -> void:
	if pulse and is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var backpack_colors: Dictionary = {}
	for cell: Vector2i in bag.section_cells(section):
		var holder_id: String = bag.cells[cell]
		var fill: Color = CELL_COLOR
		var line: Color = CELL_LINE
		if holder_id == Bag.SAFE:
			fill = SAFE_CELL
			line = SAFE_LINE.darkened(0.3)
		elif not holder_id.is_empty():
			if not backpack_colors.has(holder_id):
				var rgb: Array = BagLayout.backpack(holder_id).get("color", [0.4, 0.3, 0.25])
				backpack_colors[holder_id] = Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
			fill = (backpack_colors[holder_id] as Color).darkened(0.55)
			line = (backpack_colors[holder_id] as Color).darkened(0.15)
		var rect: Rect2 = _rect_of(cell, Vector2i.ONE)
		draw_rect(rect.grow(-0.5), fill)
		draw_rect(rect.grow(-0.5), line, false, 1.0)
	var font: Font = get_theme_default_font()
	for i in bag.size():
		var place: Dictionary = bag.get_place(i)
		var at := Vector2i(int(place["x"]), int(place["y"]))
		if bag.section_of(at) != section:
			continue
		var rect: Rect2 = _rect_of(at, Bag.footprint(place)).grow(-1.5)
		var tier_color: Color = Rarity.color(ShopSlot.rarity_of(place))
		draw_rect(rect, Color(tier_color, 0.16 if i != _hover_index else 0.32))
		draw_rect(rect, tier_color, false, 1.5)
		draw_icon(self, icon_of_place(place), rect, bool(place["rot"]))
		if int(place["count"]) > 1 and font:
			var text: String = str(int(place["count"]))
			var at_text := Vector2(rect.end.x - 2 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, rect.end.y - 2)
			draw_string_outline(font, at_text, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			draw_string(font, at_text, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	if not _drop_hint.is_empty():
		var footprint: Vector2i = BagLayout.turned(Bag.size_of(_drop_hint["piece"]), bool(_drop_hint["rot"]))
		draw_rect(_rect_of(_drop_hint["cell"], footprint), _drop_hint["color"])
	if pulse:
		var glow: float = 0.5 + 0.5 * sin(_time * 6.0)
		draw_rect(Rect2(Vector2.ZERO, Vector2(_span) * cell_px).grow(2.0), Color(PULSE_COLOR, 0.4 + 0.6 * glow), false, 2.0)


## Draws the picture of loot `id` into `rect` (keeps its shape; turned by 90 degrees when `rot`).
static func draw_loot_icon(canvas: CanvasItem, id: String, rect: Rect2, rot: bool) -> void:
	draw_icon(canvas, _icon(id), rect, rot)


## Draws `texture` into `rect` of `canvas` (keeps its shape; turned by 90 degrees when `rot`;
## long things lie diagonally along the whole length).
static func draw_icon(canvas: CanvasItem, texture: Texture2D, rect: Rect2, rot: bool) -> void:
	if texture == null:
		return
	var box: Vector2 = Vector2(rect.size.y, rect.size.x) if rot else rect.size
	var side: float = minf(box.x, box.y) * 0.92
	var angle: float = PI / 2.0 if rot else 0.0
	# Long things (a staff 4×1): the pictures lie diagonally, so turn them by 45 degrees and let
	# the diagonal fill the whole length.
	var long_side: float = maxf(box.x, box.y)
	if long_side >= minf(box.x, box.y) * 3.0:
		side = long_side / sqrt(2.0) * 0.95
		angle += PI / 4.0 if box.x > box.y else -PI / 4.0
	var icon_size := Vector2(side, side)
	if angle != 0.0:
		canvas.draw_set_transform(rect.get_center(), angle, Vector2.ONE)
		canvas.draw_texture_rect(texture, Rect2(-icon_size / 2.0, icon_size), false)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		canvas.draw_texture_rect(texture, Rect2(rect.get_center() - icon_size / 2.0, icon_size), false)


static var _icons: Dictionary = {}
## Pictures of gear, relics and potions in the bag ("relic:<id>", "potion:<id>", "gear:<id>").
static var _piece_icons: Dictionary = {}


## The picture of a bag place: loot from loot.json, a piece like in Egon's shop (ShopSlot).
## Loads once; call it before drawing (refresh), not first in _draw.
static func icon_of_place(place: Dictionary) -> Texture2D:
	if not Bag.is_piece(place):
		return _icon(String(place.get("id", "")))
	var kind: String = "relic" if ShopGoods.is_relic(place) else ("potion" if ShopGoods.is_potion(place) else "gear")
	var key: String = "%s:%s" % [kind, String(place.get("id", ""))]
	if not _piece_icons.has(key):
		_piece_icons[key] = ShopSlot.icon_of_piece(place)
	return _piece_icons[key]


static func _icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path: String = String(Content.material(id).get("icon", ""))
		_icons[id] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[id]


# --- Mouse ------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var index: int = _index_at(event.position)
		if index != _hover_index:
			_hover_index = index
			hovered.emit(index)
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
			and (event as InputEventMouseButton).shift_pressed:
		var shifted: int = _index_at(event.position)
		if shifted >= 0:
			accept_event()
			shift_clicked.emit(shifted)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT \
			and not get_viewport().gui_is_dragging():
		var index: int = _index_at(event.position)
		if index >= 0:
			accept_event()
			right_clicked.emit(index)


func _index_at(at: Vector2) -> int:
	var index: int = bag.place_at_cell(cell_at(at))
	return index if index >= 0 and bag.section_of(cell_at(at)) == section else -1


func _on_mouse_exited() -> void:
	_drop_hint = {}
	if _hover_index != -1:
		_hover_index = -1
		hovered.emit(-1)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_drop_hint = {}
		queue_redraw()


func _get_drag_data(at: Vector2) -> Variant:
	var index: int = _index_at(at)
	if index < 0:
		return null
	var place: Dictionary = bag.get_place(index)
	var grab: Vector2i = cell_at(at) - Vector2i(int(place["x"]), int(place["y"]))
	var preview := DragPreview.new()
	if Bag.is_piece(place):
		preview.setup_box(icon_of_place(place), Bag.size_of(place), bool(place["rot"]), grab, cell_px, Rarity.color(ShopSlot.rarity_of(place)))
	else:
		preview.setup_loot(String(place["id"]), bool(place["rot"]), grab, cell_px)
	# Godot moves the preview's root with the mouse; the picture is its child, shifted by grab.
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	AudioManager.play_sound("pickup", 1.4)
	return {"bag_index": index, "id": String(place["id"]), "piece": place.duplicate(), "rot": bool(place["rot"]), "grab": grab,
			"preview": preview, "size": Bag.size_of(place)}


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has("bag_index")):
		return false
	fit_preview(data, cell_px)
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	var index: int = int(drag["bag_index"])
	var color: Color = BAD_COLOR
	var piece: Dictionary = drag.get("piece", {"id": String(drag["id"])})
	if bag.fits_piece(piece, cell, bool(drag["rot"]), [index]):
		color = FIT_COLOR
	elif _covers_one(piece, cell, bool(drag["rot"]), index):
		color = SWAP_COLOR
	_drop_hint = {"cell": cell, "piece": piece, "rot": bool(drag["rot"]), "color": color}
	queue_redraw()
	return true


## true if `piece` at `cell` lies on exactly one other place and only on cells of the bag.
func _covers_one(piece: Dictionary, cell: Vector2i, rot: bool, index: int) -> bool:
	var under: Array[int] = []
	var probe: Dictionary = piece.duplicate()
	probe.merge({"x": cell.x, "y": cell.y, "rot": rot}, true)
	for c: Vector2i in Bag.cells_of_place(probe):
		if bag.section_of(c).is_empty():
			return false
		var other: int = bag.place_at_cell(c)
		if other >= 0 and other != index and not under.has(other):
			under.append(other)
	return under.size() == 1


func _drop_data(at: Vector2, data: Variant) -> void:
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	_drop_hint = {}
	if bag.move_to(int(drag["bag_index"]), cell, bool(drag["rot"])):
		AudioManager.play_sound("pickup", 1.3)
		dropped.emit()
	else:
		AudioManager.play_sound("denied")
	queue_redraw()


## R or the right mouse button while something is dragged: turns it (data "rot", "grab",
## "size", "preview"). Square things do not turn. true if it turned.
static func rotate_drag(viewport: Viewport) -> bool:
	if viewport == null or not viewport.gui_is_dragging():
		return false
	var data: Variant = viewport.gui_get_drag_data()
	if not (data is Dictionary and (data as Dictionary).has("rot") and (data as Dictionary).has("size")):
		return false
	var drag: Dictionary = data
	var size_in_cells: Vector2i = drag["size"]
	if size_in_cells.x == size_in_cells.y:
		return false
	drag["rot"] = not bool(drag["rot"])
	var grab: Vector2i = drag["grab"]
	drag["grab"] = Vector2i(grab.y, grab.x)
	var preview: Variant = drag.get("preview")
	if preview is DragPreview and is_instance_valid(preview):
		(preview as DragPreview).turn(bool(drag["rot"]), drag["grab"])
	AudioManager.play_sound("pickup", 1.6)
	return true


## The picture of a drag (data "preview") takes cell size `cell` (the grid under the mouse).
static func fit_preview(data: Variant, cell: float) -> void:
	if data is Dictionary:
		var preview: Variant = (data as Dictionary).get("preview")
		if preview is DragPreview and is_instance_valid(preview):
			(preview as DragPreview).use_cell(cell)


## true for the keys that turn a dragged thing (R, right mouse button).
static func is_turn_event(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		return (event as InputEventKey).physical_keycode == KEY_R
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		return (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT
	return false


## The picture under the mouse while dragging: the cells the thing covers and its icon; the
## grabbed cell stays under the mouse, also after turning.
class DragPreview:
	extends Control

	var loot_id: String = ""
	var icon: Texture2D = null
	var cells_size := Vector2i.ONE
	var rot: bool = false
	var px: float = 16.0
	var tint := Color(1, 1, 1, 0.25)
	var _grab := Vector2i.ZERO

	func setup_loot(id: String, turned_now: bool, grab: Vector2i, cell: float) -> void:
		loot_id = id
		cells_size = BagLayout.loot_size(id)
		px = cell
		tint = Color(Rarity.color(int(Content.material(id).get("rarity", 1))), 0.3)
		turn(turned_now, grab)

	func setup_box(texture: Texture2D, size_in_cells: Vector2i, turned_now: bool, grab: Vector2i, cell: float, color: Color) -> void:
		icon = texture
		cells_size = size_in_cells
		px = cell
		tint = Color(color, 0.55)
		turn(turned_now, grab)

	func turn(turned_now: bool, grab: Vector2i) -> void:
		rot = turned_now
		_grab = grab
		var span: Vector2i = BagLayout.turned(cells_size, rot)
		size = Vector2(span) * px
		position = -(Vector2(grab) + Vector2(0.5, 0.5)) * px
		queue_redraw()

	## Takes the cell size of the grid under the mouse (a stash piece over the bag is as big as
	## the bag's cells it would cover).
	func use_cell(cell: float) -> void:
		if cell > 0.0 and not is_equal_approx(cell, px):
			px = cell
			turn(rot, _grab)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, tint)
		draw_rect(rect, Color(tint, 0.9), false, 1.0)
		if not loot_id.is_empty():
			BagBoard.draw_loot_icon(self, loot_id, rect.grow(-1.5), rot)
		elif icon:
			var side: float = minf(size.x, size.y) * 0.8
			draw_texture_rect(icon, Rect2(rect.get_center() - Vector2(side, side) / 2.0, Vector2(side, side)), false)
