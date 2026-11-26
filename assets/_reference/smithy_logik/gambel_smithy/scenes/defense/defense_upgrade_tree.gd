class_name DefenseUpgradeTree
extends Control
## One upgrade tree of the forge defense window (coins or mastery): every upgrade is an icon at its
## `pos` [column, row]; a line joins it to the upgrade it `requires`. An upgrade only shows once the
## one before has a level, so buying one reveals the next. One that needs a beaten part (dungeon)
## shows "?" and names the dungeon. Under each icon: level and price. Behind each icon a frame in
## the colour of its state (gold = can buy, green = full, grey = too dear or locked). A click sends
## `buy_requested`; the window buys through DefenseRun and calls `build` again. Cells may be negative
## (a branch can grow in any direction from the root). The tree sits in a PanZoomView (pull with the
## mouse, wheel zooms): a click that was a drag buys nothing. Frames of upgrades that can be bought
## pulse gold; the one just bought gets a stamp (`stamp`: ring and sparks).

signal buy_requested(id: String)

const CELL := Vector2(58, 48)
const NODE_SIZE := Vector2(28, 28)
const MARGIN := Vector2(14, 8)
const LINE_LIT := Color(0.9, 0.78, 0.3)
const LINE_DARK := Color(0.4, 0.38, 0.35)
const MAXED_TINT := Color(0.65, 1.0, 0.65)
const AFFORD_TINT := Color(1.0, 1.0, 0.75)
const POOR_TINT := Color(0.7, 0.7, 0.7)
const LABEL_FONT_SIZE: int = 10
const LINE_SHADOW := Color(0.08, 0.05, 0.07, 0.9)
const GRID_DOT := Color(1.0, 0.9, 0.7, 0.06)
const FRAME_GROW: float = 3.0
const FRAME_AFFORD := Color(0.95, 0.75, 0.25)
const FRAME_MAXED := Color(0.4, 0.8, 0.4)
const FRAME_POOR := Color(0.35, 0.3, 0.3)
const FRAME_LOCKED := Color(0.22, 0.2, 0.22)
const STAMP_TIME: float = 0.5
const STAMP_SPARKS: int = 10

## [from, to, lit] per line, drawn behind the icons.
var _lines: Array = []
## [rect, colour] per icon: the frame drawn behind it.
var _frames: Array = []
## Upgrade id -> centre of its icon.
var _centers: Dictionary = {}
var _any_affordable: bool = false
var _pulse_time: float = 0.0
var _stamp_at: Vector2 = Vector2.ZERO
var _stamp_left: float = 0.0


func build(run: DefenseRun, entries: Array[Dictionary]) -> void:
	for child in get_children():
		child.queue_free()
	_lines.clear()
	_frames.clear()
	_any_affordable = false
	var centers: Dictionary = {}
	_centers = centers
	# Cells may be negative (branches up or left of the root): the smallest one is the top left.
	var first_cell := Vector2(INF, INF)
	var last_cell := Vector2(-INF, -INF)
	for entry: Dictionary in entries:
		var pos: Array = entry.get("pos", [0, 0])
		var cell := Vector2(float(pos[0]), float(pos[1]))
		first_cell = first_cell.min(cell)
		last_cell = last_cell.max(cell)
	if entries.is_empty():
		first_cell = Vector2.ZERO
		last_cell = Vector2.ZERO
	for entry: Dictionary in entries:
		var pos: Array = entry.get("pos", [0, 0])
		var cell := Vector2(float(pos[0]), float(pos[1])) - first_cell
		centers[String(entry.get("id", ""))] = MARGIN + cell * CELL + NODE_SIZE / 2.0
	for entry: Dictionary in entries:
		var id: String = String(entry.get("id", ""))
		if not run.is_upgrade_visible(id):
			continue
		var needed: String = String(entry.get("requires", ""))
		if centers.has(needed):
			_lines.append([centers[needed], centers[id], run.is_upgrade_unlocked(id)])
		_add_node(run, entry, centers[id])
	custom_minimum_size = MARGIN * 2.0 + (last_cell - first_cell + Vector2.ONE) * CELL
	queue_redraw()


## A faint dot grid (so a drag shows movement), then L-shaped lines like a skill tree (down from
## the parent, across, down to the child) with a dark shadow, then the frames behind the icons.
func _draw() -> void:
	for x in range(int(MARGIN.x + NODE_SIZE.x / 2.0), int(size.x), int(CELL.x / 2.0)):
		for y in range(int(MARGIN.y + NODE_SIZE.y / 2.0), int(size.y), int(CELL.y / 2.0)):
			draw_rect(Rect2(x, y, 1, 1), GRID_DOT)
	for line: Array in _lines:
		var from: Vector2 = line[0]
		var to: Vector2 = line[1]
		var mid_y: float = (from.y + to.y) / 2.0
		var points := PackedVector2Array([from, Vector2(from.x, mid_y), Vector2(to.x, mid_y), to])
		draw_polyline(points, LINE_SHADOW, 4.0)
		draw_polyline(points, LINE_LIT if line[2] else LINE_DARK, 2.0)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time * 4.0)
	for frame: Array in _frames:
		var rect: Rect2 = frame[0]
		var color: Color = frame[1]
		if color == FRAME_AFFORD:
			draw_rect(rect.grow(1.0 + 2.0 * pulse), Color(FRAME_AFFORD, 0.35 * pulse))
			color = FRAME_AFFORD.lerp(Color(1, 0.95, 0.7), 0.4 * pulse)
		draw_rect(rect.grow(1.0), LINE_SHADOW)
		draw_rect(rect, color)
	if _stamp_left > 0.0:
		var part: float = 1.0 - _stamp_left / STAMP_TIME
		draw_arc(_stamp_at, NODE_SIZE.x * (0.6 + 0.9 * part), 0.0, TAU, 24, Color(1, 0.9, 0.5, 1.0 - part), 2.0)
		for i in STAMP_SPARKS:
			var spark: Vector2 = _stamp_at + Vector2.from_angle(float(i) / STAMP_SPARKS * TAU) * (NODE_SIZE.x * 0.5 + 26.0 * part)
			draw_rect(Rect2(spark - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.85, 0.35, 1.0 - part))


## The upgrade `id` was just bought: its icon gets a stamp (nothing if it is not in this tree).
func stamp(id: String) -> void:
	if not _centers.has(id):
		return
	_stamp_at = _centers[id]
	_stamp_left = STAMP_TIME
	queue_redraw()


## Pulse and stamp run only while the tree is on screen.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _stamp_left > 0.0:
		_stamp_left -= delta
		queue_redraw()
	if _any_affordable:
		_pulse_time += delta
		queue_redraw()


func _add_node(run: DefenseRun, entry: Dictionary, center: Vector2) -> void:
	var id: String = String(entry.get("id", ""))
	var button := Button.new()
	button.position = center - NODE_SIZE / 2.0
	button.size = NODE_SIZE
	button.custom_minimum_size = NODE_SIZE
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(button)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size = Vector2(CELL.x, 12)
	info.position = Vector2(center.x - CELL.x / 2.0, center.y + NODE_SIZE.y / 2.0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	var frame := Rect2(button.position, NODE_SIZE).grow(FRAME_GROW)
	if not run.is_upgrade_unlocked(id):
		_frames.append([frame, FRAME_LOCKED])
		button.text = "?"
		button.disabled = true
		button.tooltip_text = Language.translate("Freischalten: besiege %s") % run.part_dungeon_name(int(entry.get("unlock_part", 1)) - 1)
		return
	var path: String = String(entry.get("icon", ""))
	var crystal_item: ItemData = ContentDB.item(String(entry.get("crystal", ""))) if entry.has("crystal") else null
	if crystal_item:
		# Crystal path: the crystal's own (animated) icon.
		button.icon = crystal_item.icon
	else:
		button.icon = load(path) if ResourceLoader.exists(path) else null
	var level: int = run.upgrade_level(id)
	var cost: int = run.upgrade_cost(id)
	info.text = "%s/%s" % [DamageKinds.format_number(level), DamageKinds.format_number(int(entry.get("max_level", 1)))]
	if cost >= 0:
		info.text += " · " + DamageKinds.format_number(cost)
	var lines: PackedStringArray = [Language.translate(String(entry.get("name", id))),
			Language.translate(String(entry.get("description", ""))),
			Language.translate("Stufe %s/%s") % [DamageKinds.format_number(level), DamageKinds.format_number(int(entry.get("max_level", 1)))]]
	if cost < 0:
		lines.append(Language.translate("Voll ausgebaut"))
	else:
		# What the next level costs and in which currency; how much is still missing.
		var mastery: bool = run.is_mastery_upgrade(id)
		var have: int = run.mastery if mastery else run.coins
		var currency: String = Language.translate("Meisterschaft") if mastery else Language.translate("Münzen")
		lines.append(Language.translate("Nächste Stufe: %s %s") % [DamageKinds.format_number(cost), currency])
		if have < cost:
			lines.append(Language.translate("Es fehlen noch %s %s") % [DamageKinds.format_number(cost - have), currency])
	button.tooltip_text = "\n".join(lines)
	if cost < 0:
		button.modulate = MAXED_TINT
		_frames.append([frame, FRAME_MAXED])
		info.modulate = FRAME_MAXED
	elif run.can_buy_upgrade(id):
		button.modulate = AFFORD_TINT
		button.pressed.connect(_on_node_pressed.bind(id))
		_frames.append([frame, FRAME_AFFORD])
		_any_affordable = true
		info.modulate = Color(1.0, 0.9, 0.55)
	else:
		button.modulate = POOR_TINT
		button.disabled = true
		_frames.append([frame, FRAME_POOR])
		info.modulate = Color(0.7, 0.65, 0.6)


func _on_node_pressed(id: String) -> void:
	var view: PanZoomView = PanZoomView.around(self)
	if view != null and view.just_dragged():
		return
	buy_requested.emit(id)
