class_name SkillTree
extends Control
## The skill tree picture (after the upgrade tree of Smithy Defense). Every LEVEL of a skill of
## data/skills.json is its own icon: level 1 at the skill's `pos` [column, row] (also negative,
## also halves), the next levels beside it in the same row, outwards (left side to the left,
## right side to the right). A level opens only when the one before it is learned. A skill that
## `requires` another one stands in a row below: a line from level 1 of that skill (gold once it
## is learned) down along the inner edge (towards the middle) to level 1 of this one; one in the
## same row (further out) hangs on the last level of that skill with a straight line.
## Under each icon: what that level costs (or a tick when learned). The frame shows the state:
## gold (pulsing) = can be learned now, green = learned, grey = the next one but too dear / level
## too low, dark = the level above (or the skill before) is missing. The tooltip says everything.
## Groups (skills.json "groups"): a title over the skills of a group ("big": the side titles).
## Left of column 0 the skills that cost only skill points (they grow to the left), right of it
## those that cost only gold (they grow to the right); a line in column 0 parts the two sides.
## A click sends learn_requested (the window learns it through MetaState). Lies in a PanZoomView
## (pull in every direction, wheel zooms): a click that was a drag learns nothing.

signal learn_requested(id: String)

const CELL := Vector2(52, 42)
const NODE_SIZE := Vector2(24, 24)
const MARGIN := Vector2(30, 18)
const LINE_LIT := Color(0.9, 0.78, 0.3)
const LINE_DARK := Color(0.4, 0.38, 0.35)
const LINE_SHADOW := Color(0.08, 0.05, 0.07, 0.9)
const GRID_DOT := Color(1.0, 0.9, 0.7, 0.06)
const FRAME_GROW: float = 3.0
const FRAME_AFFORD := Color(0.95, 0.75, 0.25)
const FRAME_MAXED := Color(0.4, 0.8, 0.4)
const FRAME_POOR := Color(0.35, 0.3, 0.3)
const FRAME_LOCKED := Color(0.18, 0.16, 0.18)
const LABEL_FONT_SIZE: int = 8
## Under a learned level instead of its price.
const LEARNED_MARK: String = "✓"

## [points, lit] per line (a polyline).
var _lines: Array = []
## [rect, colour] per icon.
var _frames: Array = []
var _any_affordable: bool = false
## x of the line between the two sides (NAN: no line).
var _divider_x: float = NAN
const DIVIDER := Color(0.9, 0.78, 0.3, 0.35)
var _pulse_time: float = 0.0


func build() -> void:
	for child: Node in get_children():
		child.queue_free()
	_lines.clear()
	_frames.clear()
	_any_affordable = false
	var skills: Dictionary = Skills.all()
	var first := Vector2(INF, INF)
	var last := Vector2(-INF, -INF)
	var groups: Dictionary = Content.get_file("skills").get("groups", {})
	for id: String in skills:
		var outer: Vector2 = _level_cell(id, Skills.max_level(id))
		first = first.min(_cell(id)).min(outer)
		last = last.max(_cell(id)).max(outer)
	for group: String in groups:
		var cell: Vector2 = _vector((groups[group] as Dictionary).get("pos", [0, 0]))
		first = first.min(cell)
		last = last.max(cell)
	if skills.is_empty():
		first = Vector2.ZERO
		last = Vector2.ZERO
	_divider_x = _center(Vector2.ZERO, first).x if first.x < 0.0 and last.x > 0.0 else NAN
	# Lines first (they lie under the icons), then the icons.
	for id: String in skills:
		var top: Vector2 = _center(_cell(id), first)
		var needed: String = String(Skills.data(id).get("requires", ""))
		if skills.has(needed) and _cell(needed).y == _cell(id).y:
			# A chain in one row: straight from the last level of the skill before.
			var last_level: Vector2 = _center(_level_cell(needed, Skills.max_level(needed)), first)
			_lines.append([PackedVector2Array([last_level, top]), MetaState.skill_level(needed) > 0])
		elif skills.has(needed):
			# Down along the inner edge (towards the middle line), then into the skill.
			var from: Vector2 = _center(_cell(needed), first)
			var rail_x: float = from.x - _outwards(needed) * CELL.x / 2.0
			_lines.append([PackedVector2Array([from, Vector2(rail_x, from.y), Vector2(rail_x, top.y), top]), MetaState.skill_level(needed) > 0])
		for level in range(2, Skills.max_level(id) + 1):
			var before: Vector2 = _center(_level_cell(id, level - 1), first)
			_lines.append([PackedVector2Array([before, _center(_level_cell(id, level), first)]), MetaState.skill_level(id) >= level - 1])
	for id: String in skills:
		for level in range(1, Skills.max_level(id) + 1):
			_add_node(id, level, _center(_level_cell(id, level), first))
	for group: String in groups:
		var data: Dictionary = groups[group]
		var center: Vector2 = _center(_vector(data.get("pos", [0, 0])), first)
		var title := Label.new()
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		title.text = Language.translate(String(data.get("name", group)))
		var big: bool = bool(data.get("big", false))
		title.add_theme_font_size_override("font_size", 14 if big else 11)
		title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7) if big else LINE_LIT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size = Vector2(CELL.x * 3.0, 16)
		title.position = center - Vector2(CELL.x * 1.5, 4)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(title)
	custom_minimum_size = MARGIN * 2.0 + (last - first + Vector2.ONE) * CELL
	queue_redraw()


func _cell(id: String) -> Vector2:
	return _vector(Skills.data(id).get("pos", [0, 0]))


## -1 for the left side (levels grow to the left), +1 for the right side.
func _outwards(id: String) -> float:
	return -1.0 if _cell(id).x < 0.0 else 1.0


## Where level `level` of `id` stands: level 1 at pos, every further one a column further out.
func _level_cell(id: String, level: int) -> Vector2:
	return _cell(id) + Vector2(_outwards(id) * (level - 1), 0)


static func _vector(pos: Variant) -> Vector2:
	var list: Array = pos if pos is Array else [0, 0]
	return Vector2(float(list[0]), float(list[1])) if list.size() >= 2 else Vector2.ZERO


func _center(cell: Vector2, first: Vector2) -> Vector2:
	return MARGIN + (cell - first) * CELL + NODE_SIZE / 2.0


## A faint dot grid (so a drag shows movement), the lines, the frames behind the icons.
func _draw() -> void:
	for x in range(int(MARGIN.x), int(size.x), int(CELL.x / 2.0)):
		for y in range(int(MARGIN.y), int(size.y), int(CELL.y / 2.0)):
			draw_rect(Rect2(x, y, 1, 1), GRID_DOT)
	if not is_nan(_divider_x):
		draw_line(Vector2(_divider_x, 4.0), Vector2(_divider_x, size.y - 4.0), DIVIDER, 2.0)
	for line: Array in _lines:
		var points: PackedVector2Array = line[0]
		draw_polyline(points, LINE_SHADOW, 4.0)
		draw_polyline(points, LINE_LIT if line[1] else LINE_DARK, 2.0)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time * 4.0)
	for frame: Array in _frames:
		var rect: Rect2 = frame[0]
		var color: Color = frame[1]
		if color == FRAME_AFFORD:
			draw_rect(rect.grow(1.0 + 2.0 * pulse), Color(FRAME_AFFORD, 0.35 * pulse))
		draw_rect(rect.grow(1.0), LINE_SHADOW)
		draw_rect(rect, color)


func _process(delta: float) -> void:
	if _any_affordable and is_visible_in_tree():
		_pulse_time += delta
		queue_redraw()


## One icon: level `level` of skill `id`.
func _add_node(id: String, level: int, center: Vector2) -> void:
	var data: Dictionary = Skills.data(id)
	var button := Button.new()
	button.name = "Skill_%s_%d" % [id, level]
	button.position = center - NODE_SIZE / 2.0
	button.size = NODE_SIZE
	button.custom_minimum_size = NODE_SIZE
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var path: String = String(data.get("icon", ""))
	button.icon = load(path) as Texture2D if ResourceLoader.exists(path) else null
	add_child(button)
	var info := Label.new()
	info.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	info.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	info.add_theme_constant_override("outline_size", 2)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size = Vector2(CELL.x, 10)
	info.position = Vector2(center.x - CELL.x / 2.0, center.y + NODE_SIZE.y / 2.0 + 1.0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	info.text = LEARNED_MARK if level <= MetaState.skill_level(id) else cost_text(id, level)
	button.tooltip_text = describe(id, level)
	var frame := Rect2(button.position, NODE_SIZE).grow(FRAME_GROW)
	var problem: String = level_problem(id, level)
	if problem == "Voll ausgebaut":
		button.modulate = Color(0.65, 1.0, 0.65)
		info.modulate = FRAME_MAXED
		_frames.append([frame, FRAME_MAXED])
	elif problem.is_empty():
		button.pressed.connect(_on_pressed.bind(id))
		info.modulate = Color(1.0, 0.9, 0.55)
		_frames.append([frame, FRAME_AFFORD])
		_any_affordable = true
	elif problem in ["Erst den Skill davor lernen", "Erst die Stufe davor lernen", "Dungeon noch nicht offen"]:
		button.modulate = Color(0.4, 0.4, 0.4)
		info.modulate = Color(0.5, 0.48, 0.45)
		_frames.append([frame, FRAME_LOCKED])
	else:
		button.modulate = Color(0.75, 0.75, 0.75)
		info.modulate = Color(0.7, 0.65, 0.6)
		_frames.append([frame, FRAME_POOR])


## Why level `level` of `id` cannot be learned now ("" = it can; "Voll ausgebaut" = learned).
static func level_problem(id: String, level: int) -> String:
	var learned: int = MetaState.skill_level(id)
	if level <= learned:
		return "Voll ausgebaut"
	if level > learned + 1:
		return "Erst die Stufe davor lernen"
	return Skills.problem(id)


## The price under an icon: gold (G) and / or skill points (P) of that level.
static func cost_text(id: String, level: int) -> String:
	var parts: Array[String] = []
	if Skills.gold_at(id, level) > 0:
		parts.append("%dG" % Skills.gold_at(id, level))
	if Skills.points_at(id, level) > 0:
		parts.append("%dP" % Skills.points_at(id, level))
	return " ".join(parts)


## Tooltip of one level (-1 = the next one): name and level, what it does, its price and needs,
## what is missing.
static func describe(id: String, level: int = -1) -> String:
	var data: Dictionary = Skills.data(id)
	if level < 1:
		level = mini(MetaState.skill_level(id) + 1, Skills.max_level(id))
	var lines: Array[String] = [
		"%s · %s" % [Language.translate(String(data.get("name", id))), Language.translate("Stufe %d/%d") % [level, Skills.max_level(id)]],
		Language.translate(String(data.get("desc", "")))]
	var problem: String = level_problem(id, level)
	if problem == "Voll ausgebaut":
		lines.append(Language.translate("Gelernt"))
		return "\n".join(lines)
	var cost: Array[String] = []
	if Skills.gold_at(id, level) > 0:
		cost.append(Language.translate("%d Gold") % Skills.gold_at(id, level))
	if Skills.points_at(id, level) > 0:
		cost.append(Language.translate("%d Skillpunkte") % Skills.points_at(id, level))
	lines.append(Language.translate("Kostet: %s") % ", ".join(cost))
	lines.append(Language.translate("Ab Spielerstufe %d") % Skills.min_level_at(id, level))
	var dungeon: String = Skills.dungeon_at(id, level)
	if not dungeon.is_empty():
		var dungeon_name: String = Language.translate(String((Content.dungeons().get(dungeon, {}) as Dictionary).get("name", dungeon)))
		lines.append(Language.translate("Erst wenn offen: %s") % dungeon_name)
	var needed: String = String(data.get("requires", ""))
	if problem == "Erst den Skill davor lernen":
		lines.append(Language.translate("Braucht: %s") % Language.translate(String(Skills.data(needed).get("name", needed))))
	elif not problem.is_empty():
		lines.append(_problem_text(problem))
	return "\n".join(lines)


## Written out so the translation script finds every text.
static func _problem_text(problem: String) -> String:
	match problem:
		"Voll ausgebaut": return Language.translate("Voll ausgebaut")
		"Stufe zu niedrig": return Language.translate("Stufe zu niedrig")
		"Zu wenig Skillpunkte": return Language.translate("Zu wenig Skillpunkte")
		"Zu wenig Gold": return Language.translate("Zu wenig Gold")
		"Dungeon noch nicht offen": return Language.translate("Dungeon noch nicht offen")
		"Erst die Stufe davor lernen": return Language.translate("Erst die Stufe davor lernen")
	return Language.translate("Erst den Skill davor lernen")


func _on_pressed(id: String) -> void:
	var view: PanZoomView = PanZoomView.around(self)
	if view != null and view.just_dragged():
		return
	learn_requested.emit(id)
