class_name BackpackBoard
extends Control
## The bag of the next run in Egon's shop (tab Inventar): the area where backpacks may lie
## (BagLayout.board_rect, faint), the bag itself (brown, fixed) and the attached backpacks (their
## colour and picture). Drag a backpack from the stash onto it to attach it
## (MetaState.attach_backpack), drag an attached one to move it (place_backpack) or back into
## the stash (the shop: detach_backpack). R or the right mouse button while dragging turns it;
## the cells it would cover show green (allowed) or red.
## The loot brought home lies on it too (MetaState.bag_places, not the safe place: that is its own
## board in the shop): drag it to move it (move_in_bag), into the stash (the shop) or from the
## stash into the bag (stash_to_bag), also gear, relics and potions (carried along, lost on death
## unless in the safe place). A backpack with loot in it stays where it is.

signal changed

const AREA_DOT := Color(1.0, 0.9, 0.7, 0.12)
const BAG_FILL := Color(0.3, 0.22, 0.17)
const BAG_LINE := Color(0.55, 0.4, 0.28)
const OK_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const BAD_COLOR := Color(1.0, 0.25, 0.2, 0.45)

var cell_px: float = 16.0
var _area: Rect2i
var _drop_hint: Dictionary = {}
var _icons: Dictionary = {}
## The bag at home (MetaState.bag_places) and the pictures of its loot, read in refresh.
var _places: Array[Dictionary] = []
var _loot_icons: Array[Texture2D] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_drop_hint = {}
		queue_redraw())
	refresh()


func refresh() -> void:
	_area = BagLayout.board_rect()
	custom_minimum_size = Vector2(_area.size) * cell_px
	# Load every picture now: a texture loaded while drawing shows white.
	for id: String in BagLayout.backpacks():
		icon_of(id)
	_places = MetaState.bag_places()
	_loot_icons.clear()
	for place: Dictionary in _places:
		_loot_icons.append(ShopSlot.icon_of_piece(place))
	queue_redraw()


## Index of the bag place on `cell` (-1 = none; the safe place is not on this board).
func place_at(cell: Vector2i) -> int:
	for i in _places.size():
		if Bag.cells_of_place(_places[i]).has(cell):
			return i
	return -1


## A drag of something the bag can hold, from the bag or the stash: loot, gear, a relic, a potion
## (its id; "" = something else, e.g. a backpack).
static func dragged_loot(data: Variant) -> String:
	if not data is Dictionary:
		return ""
	var drag: Dictionary = data
	var piece: Dictionary = drag.get("piece", {})
	if String(drag.get("from", "")) == "bag":
		return String(piece.get("id", ""))
	if String(drag.get("from", "")) == "stash" and not ShopGoods.is_backpack(piece):
		return String(piece.get("id", ""))
	return ""


## true if the loot drag would go onto `cell` (bag coordinates).
static func loot_allowed(drag: Dictionary, cell: Vector2i) -> bool:
	if String(drag.get("from", "")) == "bag":
		return MetaState.bag_fits(int(drag["index"]), cell, bool(drag["rot"]))
	return MetaState.stash_fits_bag(int(drag["index"]), cell, bool(drag["rot"]))


## Moves / puts the loot of the drag onto `cell`. false = nothing changed.
static func drop_loot(drag: Dictionary, cell: Vector2i) -> bool:
	if String(drag.get("from", "")) == "bag":
		return MetaState.move_in_bag(int(drag["index"]), cell, bool(drag["rot"]))
	return MetaState.stash_to_bag(int(drag["index"]), cell, bool(drag["rot"]))


func cell_at(at: Vector2) -> Vector2i:
	return _area.position + Vector2i(floori(at.x / cell_px), floori(at.y / cell_px))


func _rect_of(cell: Vector2i, cells: Vector2i) -> Rect2:
	return Rect2(Vector2(cell - _area.position) * cell_px, Vector2(cells) * cell_px)


static func color_of(id: String) -> Color:
	var rgb: Array = BagLayout.backpack(id).get("color", [0.5, 0.4, 0.3])
	return Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))


func icon_of(id: String) -> Texture2D:
	if not _icons.has(id):
		var path: String = String(BagLayout.backpack(id).get("icon", ""))
		_icons[id] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[id]


func _draw() -> void:
	for y in _area.size.y:
		for x in _area.size.x:
			draw_rect(Rect2(Vector2(x, y) * cell_px + Vector2(cell_px, cell_px) / 2.0 - Vector2.ONE, Vector2(2, 2)), AREA_DOT)
	draw_rect(Rect2(Vector2.ZERO, size), Color(AREA_DOT, 0.3), false, 1.0)
	for cell: Vector2i in BagLayout.base_cells():
		var rect: Rect2 = _rect_of(cell, Vector2i.ONE).grow(-0.5)
		draw_rect(rect, BAG_FILL)
		draw_rect(rect, BAG_LINE, false, 1.0)
	var font: Font = get_theme_default_font()
	if font:
		var bag_rect: Rect2 = _rect_of(Vector2i.ZERO, Vector2i.ONE)
		for cell: Vector2i in BagLayout.base_cells():
			bag_rect = bag_rect.merge(_rect_of(cell, Vector2i.ONE))
		var text: String = Language.translate("Inventar")
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, bag_rect.get_center() + Vector2(-width / 2.0, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.86, 0.55, 0.8))
	for entry: Variant in MetaState.backpacks():
		var placement: Dictionary = entry
		var id: String = String(placement["id"])
		var color: Color = color_of(id)
		for cell: Vector2i in BagLayout.cells_of(placement):
			var rect: Rect2 = _rect_of(cell, Vector2i.ONE).grow(-0.5)
			draw_rect(rect, color.darkened(0.45))
			draw_rect(rect, color.darkened(0.1), false, 1.0)
		var span: Vector2i = BagLayout.turned(BagLayout.backpack_size(id), bool(placement["rot"]))
		var whole: Rect2 = _rect_of(Vector2i(int(placement["x"]), int(placement["y"])), span)
		draw_rect(whole.grow(-1.0), color.lightened(0.2), false, 2.0)
		var texture: Texture2D = icon_of(id)
		if texture:
			var side: float = minf(minf(whole.size.x, whole.size.y) * 0.8, 40.0)
			draw_texture_rect(texture, Rect2(whole.get_center() - Vector2(side, side) / 2.0, Vector2(side, side)), false, Color(1, 1, 1, 0.85))
	for i in _places.size():
		var place: Dictionary = _places[i]
		var at := Vector2i(int(place["x"]), int(place["y"]))
		if at.x >= Bag.SAFE_ORIGIN.x:
			continue
		var rect: Rect2 = _rect_of(at, Bag.footprint(place)).grow(-1.0)
		var color: Color = Rarity.color(ShopSlot.rarity_of(place))
		draw_rect(rect, Color(color, 0.22))
		draw_rect(rect, color, false, 1.0)
		BagBoard.draw_icon(self, _loot_icons[i], rect.grow(-0.5), bool(place.get("rot", false)))
	if not _drop_hint.is_empty():
		draw_rect(_rect_of(_drop_hint["cell"], _drop_hint["span"]), _drop_hint["color"])


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_drop_hint = {}
		queue_redraw()


## The attached backpack lying on `cell` ("" = none).
func backpack_at(cell: Vector2i) -> String:
	for entry: Variant in MetaState.backpacks():
		if BagLayout.cells_of(entry).has(cell):
			return String((entry as Dictionary)["id"])
	return ""


## Drag data for attached backpack `id`: turned `rot`, grabbed at cell `grab` of it. Sets the
## preview on `source`.
func make_drag(source: Control, id: String, rot: bool, grab: Vector2i) -> Dictionary:
	var preview := BagBoard.DragPreview.new()
	preview.setup_box(icon_of(id), BagLayout.backpack_size(id), rot, grab, cell_px, color_of(id))
	var holder := Control.new()
	holder.add_child(preview)
	source.set_drag_preview(holder)
	AudioManager.play_sound("pickup", 1.2)
	return {"backpack": id, "rot": rot, "grab": grab, "size": BagLayout.backpack_size(id), "preview": preview}


func _get_drag_data(at: Vector2) -> Variant:
	var cell: Vector2i = cell_at(at)
	# Loot first (it lies on top of the backpacks).
	var index: int = place_at(cell)
	if index >= 0:
		var place: Dictionary = _places[index]
		return ItemBoard.make_drag(self, "bag", index, place, bool(place.get("rot", false)), cell - Vector2i(int(place["x"]), int(place["y"])), cell_px)
	var id: String = backpack_at(cell)
	if id.is_empty():
		return null
	for entry: Variant in MetaState.backpacks():
		var placement: Dictionary = entry
		if String(placement["id"]) == id:
			return make_drag(self, id, bool(placement["rot"]), cell - Vector2i(int(placement["x"]), int(placement["y"])))
	return null


## The backpack id of a drag: an attached one ("backpack") or one from the stash ("" = neither).
static func dragged_backpack(data: Variant) -> String:
	if not data is Dictionary:
		return ""
	var drag: Dictionary = data
	if drag.has("backpack"):
		return String(drag["backpack"])
	if String(drag.get("from", "")) == "stash" and ShopGoods.is_backpack(drag.get("piece", {})):
		return String((drag["piece"] as Dictionary)["id"])
	return ""


## true if the drag would attach / move its backpack with its top left on `cell`.
static func allowed(drag: Dictionary, cell: Vector2i) -> bool:
	var id: String = dragged_backpack(drag)
	var placed: Array = MetaState.backpacks()
	if drag.has("backpack"):
		return BagLayout.is_valid(BagLayout.with_moved(placed, id, cell, bool(drag["rot"])))
	var next: Array = placed.duplicate()
	next.append({"id": id, "x": cell.x, "y": cell.y, "rot": bool(drag["rot"])})
	return BagLayout.is_valid(next)


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	var loot: String = dragged_loot(data)
	if not loot.is_empty():
		var loot_drag: Dictionary = data
		var at_cell: Vector2i = cell_at(at) - (loot_drag["grab"] as Vector2i)
		_drop_hint = {"cell": at_cell, "span": BagLayout.turned(Bag.size_of(loot_drag.get("piece", {"id": loot})), bool(loot_drag["rot"])),
				"color": OK_COLOR if loot_allowed(loot_drag, at_cell) else BAD_COLOR}
		queue_redraw()
		return true
	var id: String = dragged_backpack(data)
	if id.is_empty():
		return false
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	var ok: bool = allowed(drag, cell)
	_drop_hint = {"cell": cell, "span": BagLayout.turned(BagLayout.backpack_size(id), bool(drag["rot"])), "color": OK_COLOR if ok else BAD_COLOR}
	queue_redraw()
	return true


func _drop_data(at: Vector2, data: Variant) -> void:
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	_drop_hint = {}
	var done: bool = false
	if not dragged_loot(drag).is_empty():
		done = drop_loot(drag, cell)
	elif drag.has("backpack"):
		done = MetaState.place_backpack(String(drag["backpack"]), cell, bool(drag["rot"]))
	else:
		done = MetaState.attach_backpack(int(drag["index"]), cell, bool(drag["rot"]))
	if done:
		AudioManager.play_sound("unlock", 1.2)
	else:
		AudioManager.play_sound("denied")
	queue_redraw()
	changed.emit()
