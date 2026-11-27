class_name BackpackBoard
extends Control
## The grid in Egon's shop where backpacks are attached to the bag (BackpackWindow): the area
## where backpacks may lie (BagLayout.board_rect, faint), the bag itself (brown, fixed) and the
## attached backpacks (their colour and picture). Drag a backpack to move it (from here or from
## the list of loose ones), R or the right mouse button while dragging turns it; while dragging the
## cells it would cover show green (allowed) or red. MetaState.place_backpack decides.

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_drop_hint = {}
		queue_redraw())
	refresh()


func refresh() -> void:
	_area = BagLayout.board_rect()
	custom_minimum_size = Vector2(_area.size) * cell_px
	queue_redraw()


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
	if not _drop_hint.is_empty():
		var hint_span: Vector2i = BagLayout.turned(BagLayout.backpack_size(String(_drop_hint["id"])), bool(_drop_hint["rot"]))
		draw_rect(_rect_of(_drop_hint["cell"], hint_span), _drop_hint["color"])


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


## Drag data for backpack `id` (also used by the list of loose backpacks): turned `rot`, grabbed
## at cell `grab` of it. Sets the preview on `source`.
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
	var id: String = backpack_at(cell)
	if id.is_empty():
		return null
	for entry: Variant in MetaState.backpacks():
		var placement: Dictionary = entry
		if String(placement["id"]) == id:
			return make_drag(self, id, bool(placement["rot"]), cell - Vector2i(int(placement["x"]), int(placement["y"])))
	return null


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has("backpack")):
		return false
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	var id: String = String(drag["backpack"])
	var allowed: bool = BagLayout.is_valid(BagLayout.with_moved(MetaState.backpacks(), id, cell, bool(drag["rot"])))
	_drop_hint = {"cell": cell, "id": id, "rot": bool(drag["rot"]), "color": OK_COLOR if allowed else BAD_COLOR}
	queue_redraw()
	return true


func _drop_data(at: Vector2, data: Variant) -> void:
	var drag: Dictionary = data
	var cell: Vector2i = cell_at(at) - (drag["grab"] as Vector2i)
	_drop_hint = {}
	if MetaState.place_backpack(String(drag["backpack"]), cell, bool(drag["rot"])):
		AudioManager.play_sound("unlock", 1.2)
	else:
		AudioManager.play_sound("denied")
	queue_redraw()
	changed.emit()
