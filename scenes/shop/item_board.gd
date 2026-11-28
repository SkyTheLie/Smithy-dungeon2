class_name ItemBoard
extends Control
## A grid of cells in Egon's shop with pieces on it (ItemGrid): the stash (drag and drop, turn
## with R / right mouse button while dragging) or Egon's table (with prices, click to buy). Every
## piece covers ShopGoods.piece_size cells, a frame in its rarity colour, its picture, the count or
## the price; the tooltip says what it is (ShopSlot.describe). While something is dragged over it
## the cells it would cover show green (fits), yellow (swaps) or red. Only shows and forwards:
## the shop decides what a click, a right click or a drop does (signals), `judge` says whether a
## drop would work.

signal clicked(index: int)
signal right_clicked(index: int)
## Strg + left click on a piece (lock / unlock it).
signal lock_clicked(index: int)
signal dropped(data: Dictionary, cell: Vector2i, rot: bool)

const LOCK_COLOR := Color(1.0, 0.85, 0.3)
## Stash: the tooltip also says what Egon pays (and whether it is locked).
var show_sell_value: bool = false

const CELL_COLOR := Color(0.18, 0.14, 0.12, 0.92)
const CELL_LINE := Color(0.32, 0.27, 0.24)
const PRICE_COLOR := Color(1.0, 0.86, 0.35)
const FIT_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const SWAP_COLOR := Color(1.0, 0.85, 0.3, 0.45)
const BAD_COLOR := Color(1.0, 0.25, 0.2, 0.45)
const GLOW_COLOR := Color(1.0, 0.85, 0.35)

## The pieces (Dictionaries; those without "x" are not drawn). The index is the place in this list.
var pieces: Array = []
var grid := Vector2i(5, 4)
var cell_px: float = 24.0
var show_price: bool = false
## Egon's table: the gold the player has (-1 = no check); dearer pieces are darker, price red.
var gold_limit: int = -1
## Pieces better than what the hero wears: a small green arrow.
var better: Array[int] = []
const TOO_DEAR_COLOR := Color(1.0, 0.35, 0.3)
const BETTER_COLOR := Color(0.35, 1.0, 0.4)
## Pieces can be dragged away; the drag data says {"from": drag_from, "index": i, …}.
var draggable: bool = true
var drag_from: String = "stash"
## (data: Dictionary) -> bool: which drags this board takes at all.
var accepts: Callable = Callable()
## (data: Dictionary, cell: Vector2i, rot: bool) -> int: 0 no, 1 fits, 2 swaps.
var judge: Callable = Callable()
## A piece shown faint (lies on Egon's sell place).
var faint_index: int = -1
## Pieces that shine (Egon points at them).
var glowing: Array[int] = []

## The pictures of the pieces, loaded in show_pieces (never while drawing).
var _icons: Array[Texture2D] = []
var _hint: Dictionary = {}
var _hover: int = -1
var _press: int = -1
var _dragging: bool = false
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The tooltip is translated already (ShopSlot.describe).
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	mouse_exited.connect(func() -> void:
		_hint = {}
		_hover = -1
		queue_redraw())


func show_pieces(list: Array, cells: Vector2i) -> void:
	pieces = list
	grid = cells
	_icons.clear()
	for piece: Variant in pieces:
		_icons.append(ShopSlot.icon_of_piece(piece) if piece is Dictionary and not (piece as Dictionary).is_empty() else null)
	custom_minimum_size = Vector2(grid) * cell_px
	if _hover >= pieces.size():
		_hover = -1
	tooltip_text = _tooltip(_hover)
	queue_redraw()


func set_glow(index: int, on: bool) -> void:
	if on and not glowing.has(index):
		glowing.append(index)
	elif not on:
		glowing.erase(index)
	queue_redraw()


func cell_at(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / cell_px), floori(at.y / cell_px))


func _local_rect(piece: Dictionary) -> Rect2:
	return Rect2(Vector2(int(piece["x"]), int(piece["y"])) * cell_px, Vector2(ItemGrid.footprint(piece)) * cell_px)


## Where piece `index` lies on screen (global; an empty Rect2 if it is not in the grid).
func rect_of(index: int) -> Rect2:
	if index < 0 or index >= pieces.size() or not pieces[index] is Dictionary or not ItemGrid.is_placed(pieces[index]):
		return Rect2()
	var rect: Rect2 = _local_rect(pieces[index])
	return Rect2(get_global_transform() * rect.position, rect.size * get_global_transform().get_scale())


func index_at(at: Vector2) -> int:
	return ItemGrid.index_at(pieces, cell_at(at))


func _process(delta: float) -> void:
	if not glowing.is_empty() and is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	for y in grid.y:
		for x in grid.x:
			var cell := Rect2(Vector2(x, y) * cell_px, Vector2(cell_px, cell_px)).grow(-0.5)
			draw_rect(cell, CELL_COLOR)
			draw_rect(cell, CELL_LINE, false, 1.0)
	var font: Font = get_theme_default_font()
	for i in pieces.size():
		if not pieces[i] is Dictionary or not ItemGrid.is_placed(pieces[i]):
			continue
		var piece: Dictionary = pieces[i]
		var rect: Rect2 = _local_rect(piece).grow(-1.5)
		var color: Color = Rarity.color(ShopSlot.rarity_of(piece))
		var faint: float = 0.35 if i == faint_index else 1.0
		draw_rect(rect, Color(color, (0.3 if i == _hover else 0.16) * faint))
		draw_rect(rect, Color(color, faint), false, 1.5)
		BagBoard.draw_icon(self, _icons[i] if i < _icons.size() else null, rect.grow(-1.0), bool(piece.get("rot", false)))
		if faint < 1.0:
			draw_rect(rect, Color(0, 0, 0, 0.5))
		var too_dear: bool = show_price and gold_limit >= 0 and int(piece.get("price", 0)) > gold_limit
		if too_dear:
			draw_rect(rect, Color(0, 0, 0, 0.4))
		if better.has(i):
			var tip := Vector2(rect.end.x - 5, rect.position.y + 2)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(3, 4), tip + Vector2(-3, 4)]), BETTER_COLOR)
			draw_rect(Rect2(tip + Vector2(-1, 4), Vector2(2, 3)), BETTER_COLOR)
		var text: String = ""
		if show_price:
			text = str(int(piece.get("price", 0)))
		elif int(piece.get("count", 1)) > 1:
			text = str(int(piece["count"]))
		if not text.is_empty() and font:
			var at := Vector2(rect.end.x - 2 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, rect.end.y - 2)
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			var color_now: Color = Color.WHITE
			if show_price:
				color_now = TOO_DEAR_COLOR if gold_limit >= 0 and int(piece.get("price", 0)) > gold_limit else PRICE_COLOR
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color_now)
		if bool(piece.get("locked", false)):
			_draw_lock(rect.position + Vector2(2, 2))
		if glowing.has(i):
			var glow: float = 0.5 + 0.5 * sin(_time * 7.0)
			draw_rect(rect.grow(2.0), Color(GLOW_COLOR, 0.35 + 0.65 * glow), false, 2.5)
	if not _hint.is_empty():
		draw_rect(Rect2(Vector2(_hint["cell"] as Vector2i) * cell_px, Vector2(_hint["span"] as Vector2i) * cell_px), _hint["color"])


## A small padlock (locked piece: never sold, stays when sorting).
func _draw_lock(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(0, 3), Vector2(6, 5)), LOCK_COLOR)
	draw_arc(at + Vector2(3, 3), 2.0, PI, TAU, 6, LOCK_COLOR, 1.0)


func _tooltip(index: int) -> String:
	if index < 0 or index >= pieces.size() or not pieces[index] is Dictionary:
		return ""
	var text: String = ShopSlot.describe(pieces[index], show_price)
	if show_sell_value:
		var piece: Dictionary = pieces[index]
		if bool(piece.get("locked", false)):
			text += "\n" + Language.translate("Gesperrt: wird nicht verkauft (Strg+Klick: entsperren)")
		elif not Quests.is_stone(String(piece.get("id", ""))) and ShopGoods.sell_price(piece) > 0:
			text += "\n" + Language.translate("Egon zahlt: %d Gold") % ShopGoods.sell_price(piece)
	return text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var index: int = index_at(event.position)
		if index != _hover:
			_hover = index
			tooltip_text = _tooltip(index)
			queue_redraw()
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	if button.button_index == MOUSE_BUTTON_LEFT and button.pressed and button.ctrl_pressed:
		var locking: int = index_at(button.position)
		if locking >= 0:
			accept_event()
			lock_clicked.emit(locking)
		return
	if button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press = index_at(button.position)
			_dragging = false
		elif not _dragging and _press >= 0 and _press == index_at(button.position):
			accept_event()
			clicked.emit(_press)
			_press = -1
	elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed and not get_viewport().gui_is_dragging():
		var index: int = index_at(button.position)
		if index >= 0:
			accept_event()
			right_clicked.emit(index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_dragging = true
	elif what == NOTIFICATION_DRAG_END:
		_hint = {}
		_press = -1
		queue_redraw()


func _get_drag_data(at: Vector2) -> Variant:
	if not draggable:
		return null
	var index: int = index_at(at)
	if index < 0:
		return null
	var piece: Dictionary = pieces[index]
	var grab: Vector2i = cell_at(at) - Vector2i(int(piece["x"]), int(piece["y"]))
	return make_drag(self, drag_from, index, piece, bool(piece.get("rot", false)), grab, cell_px)


## Drag data for `piece` (index `index` of `from`), with the picture under the mouse.
static func make_drag(source: Control, from: String, index: int, piece: Dictionary, rot: bool, grab: Vector2i, px: float) -> Dictionary:
	var preview := BagBoard.DragPreview.new()
	preview.setup_box(ShopSlot.icon_of_piece(piece), ShopGoods.piece_size(piece), rot, grab, px, Rarity.color(ShopSlot.rarity_of(piece)))
	var holder := Control.new()
	holder.add_child(preview)
	source.set_drag_preview(holder)
	AudioManager.play_sound("pickup", 1.4)
	return {"from": from, "index": index, "piece": piece, "rot": rot, "grab": grab, "size": ShopGoods.piece_size(piece), "preview": preview}


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not accepts.is_valid() or not bool(accepts.call(data)):
		return false
	BagBoard.fit_preview(data, cell_px)
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	var verdict: int = int(judge.call(drag, cell, bool(drag["rot"]))) if judge.is_valid() else 1
	_hint = {"cell": cell, "span": BagLayout.turned(drag["size"] as Vector2i, bool(drag["rot"])),
			"color": [BAD_COLOR, FIT_COLOR, SWAP_COLOR][clampi(verdict, 0, 2)]}
	queue_redraw()
	return true


func _drop_data(at: Vector2, data: Variant) -> void:
	var drag: Dictionary = data
	_hint = {}
	queue_redraw()
	dropped.emit(drag, cell_at(at) - (drag["grab"] as Vector2i), bool(drag["rot"]))
