class_name SkillTree
extends Control
## The skill tree picture (after the upgrade tree of Smithy Defense): every skill of
## data/skills.json is an icon at its `pos` [column, row] (also negative); an L-shaped line joins it
## to the skill it `requires` (gold once that one is learned). Under each icon: level/max and the
## price. The frame shows the state: gold (pulsing) = can be learned now, green = fully learned,
## grey = too dear / level too low, dark = the skill before is missing. The tooltip says everything
## (what it does, level, gold, skill points, needed player level, what is missing).
## Groups (skills.json "groups"): a title over each column (Kampf, Rucksack, Relikte & Überleben).
## A click sends learn_requested (the window learns it through MetaState). Lies in a PanZoomView
## (pull in every direction, wheel zooms): a click that was a drag learns nothing.

signal learn_requested(id: String)

const CELL := Vector2(64, 56)
const NODE_SIZE := Vector2(30, 30)
const MARGIN := Vector2(24, 14)
const LINE_LIT := Color(0.9, 0.78, 0.3)
const LINE_DARK := Color(0.4, 0.38, 0.35)
const LINE_SHADOW := Color(0.08, 0.05, 0.07, 0.9)
const GRID_DOT := Color(1.0, 0.9, 0.7, 0.06)
const FRAME_GROW: float = 3.0
const FRAME_AFFORD := Color(0.95, 0.75, 0.25)
const FRAME_MAXED := Color(0.4, 0.8, 0.4)
const FRAME_POOR := Color(0.35, 0.3, 0.3)
const FRAME_LOCKED := Color(0.18, 0.16, 0.18)
const LABEL_FONT_SIZE: int = 9

## [from, to, lit] per line.
var _lines: Array = []
## [rect, colour] per icon.
var _frames: Array = []
var _any_affordable: bool = false
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
		var cell: Vector2 = _cell(id)
		first = first.min(cell)
		last = last.max(cell)
	for group: String in groups:
		var pos: Array = (groups[group] as Dictionary).get("pos", [0, 0])
		var cell := Vector2(float(pos[0]), float(pos[1]))
		first = first.min(cell)
		last = last.max(cell)
	if skills.is_empty():
		first = Vector2.ZERO
		last = Vector2.ZERO
	var centers: Dictionary = {}
	for id: String in skills:
		centers[id] = MARGIN + (_cell(id) - first) * CELL + NODE_SIZE / 2.0
	for id: String in skills:
		var needed: String = String(Skills.data(id).get("requires", ""))
		if centers.has(needed):
			_lines.append([centers[needed], centers[id], MetaState.skill_level(needed) > 0])
		_add_node(id, centers[id])
	for group: String in groups:
		var data: Dictionary = groups[group]
		var pos: Array = data.get("pos", [0, 0])
		var center: Vector2 = MARGIN + (Vector2(float(pos[0]), float(pos[1])) - first) * CELL + NODE_SIZE / 2.0
		var title := Label.new()
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		title.text = Language.translate(String(data.get("name", group)))
		title.add_theme_font_size_override("font_size", 12)
		title.add_theme_color_override("font_color", LINE_LIT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size = Vector2(CELL.x * 2.0, 16)
		title.position = center - Vector2(CELL.x, 4)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(title)
	custom_minimum_size = MARGIN * 2.0 + (last - first + Vector2.ONE) * CELL
	queue_redraw()


func _cell(id: String) -> Vector2:
	var pos: Array = Skills.data(id).get("pos", [0, 0])
	return Vector2(float(pos[0]), float(pos[1]))


## A faint dot grid (so a drag shows movement), the lines, the frames behind the icons.
func _draw() -> void:
	for x in range(int(MARGIN.x), int(size.x), int(CELL.x / 2.0)):
		for y in range(int(MARGIN.y), int(size.y), int(CELL.y / 2.0)):
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
		draw_rect(rect.grow(1.0), LINE_SHADOW)
		draw_rect(rect, color)


func _process(delta: float) -> void:
	if _any_affordable and is_visible_in_tree():
		_pulse_time += delta
		queue_redraw()


func _add_node(id: String, center: Vector2) -> void:
	var data: Dictionary = Skills.data(id)
	var button := Button.new()
	button.name = "Skill_" + id
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
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size = Vector2(CELL.x, 12)
	info.position = Vector2(center.x - CELL.x / 2.0, center.y + NODE_SIZE.y / 2.0 + 2.0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	var level: int = MetaState.skill_level(id)
	var gold: int = Skills.next_gold(id)
	info.text = "%d/%d" % [level, Skills.max_level(id)]
	if gold >= 0:
		info.text += " · %d" % gold
	button.tooltip_text = describe(id)
	var frame := Rect2(button.position, NODE_SIZE).grow(FRAME_GROW)
	var problem: String = Skills.problem(id)
	if problem == "Voll ausgebaut":
		button.modulate = Color(0.65, 1.0, 0.65)
		info.modulate = FRAME_MAXED
		_frames.append([frame, FRAME_MAXED])
	elif problem.is_empty():
		button.pressed.connect(_on_pressed.bind(id))
		info.modulate = Color(1.0, 0.9, 0.55)
		_frames.append([frame, FRAME_AFFORD])
		_any_affordable = true
	elif problem == "Erst den Skill davor lernen":
		button.modulate = Color(0.45, 0.45, 0.45)
		info.modulate = Color(0.5, 0.48, 0.45)
		_frames.append([frame, FRAME_LOCKED])
	else:
		button.modulate = Color(0.75, 0.75, 0.75)
		info.modulate = Color(0.7, 0.65, 0.6)
		_frames.append([frame, FRAME_POOR])


## Tooltip of a skill: name, what it does, level, the next level's price and needs, what is missing.
static func describe(id: String) -> String:
	var data: Dictionary = Skills.data(id)
	var lines: Array[String] = [Language.translate(String(data.get("name", id))), Language.translate(String(data.get("desc", ""))),
			Language.translate("Stufe %d/%d") % [MetaState.skill_level(id), Skills.max_level(id)]]
	var problem: String = Skills.problem(id)
	if problem != "Voll ausgebaut":
		lines.append(Language.translate("Nächste Stufe: %d Gold, %d Skillpunkte, ab Spielerstufe %d") % [Skills.next_gold(id), Skills.next_points(id), Skills.next_min_level(id)])
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
	return Language.translate("Erst den Skill davor lernen")


func _on_pressed(id: String) -> void:
	var view: PanZoomView = PanZoomView.around(self)
	if view != null and view.just_dragged():
		return
	learn_requested.emit(id)
