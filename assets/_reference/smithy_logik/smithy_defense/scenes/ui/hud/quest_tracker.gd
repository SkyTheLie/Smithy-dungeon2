class_name QuestTracker
extends PanelContainer
## Quest tracker in the HUD (like in WoW): the open tasks without a window frame, each with its
## goals, e.g. "0/1 Kupferschwert" or "3/5 Kohle" (done goals in green). Same sources as the
## quest log / detail window: story task, side tasks, customer orders, quests.
## Header: arrow (fold in / out), title, pin. Dragging the header moves the tracker; a pinned
## tracker can't be moved and keeps its place across scene changes and restarts (WindowLayout,
## like the windows). Folded or not is stored too. Clicking a task title emits the same signals
## as QuestLogWindow, the HUD opens the detail window.
## The tasks stand in sections (main quest, side quests, customer orders, orders), each with its own
## arrow to fold it in (e.g. only the main quest visible); which ones are folded is stored.

signal quest_selected(quest: QuestData)
signal order_selected(order: CustomerOrder)
signal story_selected
signal side_task_selected(task_id: String)

const PIN_ICON: Texture2D = preload("res://assets/ui/icon_pin.png")
const PIN_ICON_ACTIVE: Texture2D = preload("res://assets/ui/icon_pin_active.png")
## Name of the pinned position (WindowLayout) and the settings section for "collapsed".
const LAYOUT_ID: String = "HUD/QuestTracker"
const SETTINGS_SECTION: String = "quest_tracker"
const COLOR_TITLE: Color = Color(0.95, 0.8, 0.5)
const COLOR_GOAL: Color = Color(0.93, 0.87, 0.78)
const COLOR_DONE: Color = Color(0.55, 0.85, 0.45)
const COLOR_OUTLINE: Color = Color(0.13, 0.075, 0.12)
const OUTLINE_SIZE: int = 3
## Width of the goal lines (longer ones wrap).
const LINE_WIDTH: float = 150.0
## Rebuilt at least this often (item counts in chests, deadlines ...), only if something changed.
const REFRESH_SECONDS: float = 1.0
## Space below the time compass and other free zones (WindowTitleBar.FREE_ZONE_GROUP).
const FREE_ZONE_GAP: float = 2.0
## Sections in their order: id -> heading (German, translated when shown).
const SECTIONS: Dictionary = {"main": "Hauptquest", "side": "Nebenquests", "orders": "Kundenaufträge", "quests": "Aufträge"}
const COLOR_SECTION: Color = Color(0.72, 0.66, 0.6)

var _collapsed: bool = false
## Ids of the folded sections (SECTIONS).
var _collapsed_sections: Array = []
var _dragging: bool = false
## Text of the last build, to skip rebuilding when nothing changed.
var _last_signature: String = ""

@onready var _arrow_button: Button = %ArrowButton
@onready var _pin_button: Button = %PinButton
@onready var _header: Control = %Header
@onready var _content: VBoxContainer = %Content


func _ready() -> void:
	_collapsed = bool(WindowLayout.get_setting(SETTINGS_SECTION, "collapsed", false))
	_collapsed_sections = Array(WindowLayout.get_setting(SETTINGS_SECTION, "collapsed_sections", []))
	_arrow_button.pressed.connect(_toggle_collapsed)
	_pin_button.toggled.connect(_on_pin_toggled)
	_header.gui_input.connect(_on_header_gui_input)
	GameState.quests_changed.connect(_refresh)
	GameState.customers.changed.connect(_refresh)
	GameState.story.changed.connect(_refresh)
	GameState.inventory.changed.connect(_refresh)
	GameState.gold_changed.connect(func(_gold: int) -> void: _refresh())
	var timer := Timer.new()
	timer.wait_time = REFRESH_SECONDS
	timer.autostart = true
	timer.timeout.connect(_refresh)
	add_child(timer)
	_update_arrow()
	# Text size (settings » "Textgröße: Aufgaben"): header and goal lines grow wider with the text.
	TextSize.attach(self, "quests", [self], func() -> void:
		_last_signature = ""
		_refresh()
		reset_size())
	_refresh()
	_restore_pinned_position()


## Rebuilds the task list if its text changed; hides the tracker when nothing is open.
func _refresh() -> void:
	var entries: Array[Dictionary] = _collect_entries()
	var signature: String = str(_collapsed) + str(_collapsed_sections) + JSON.stringify(entries.map(
			func(entry: Dictionary) -> Array: return [entry["section"], entry["title"], entry["goals"]]))
	if signature == _last_signature:
		return
	_last_signature = signature
	visible = not entries.is_empty()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_content.visible = not _collapsed
	if _collapsed:
		return
	for section: String in SECTIONS:
		var in_section: Array = entries.filter(func(entry: Dictionary) -> bool: return entry["section"] == section)
		if in_section.is_empty():
			continue
		var folded: bool = _collapsed_sections.has(section)
		_content.add_child(_create_section_header(section, in_section.size(), folded))
		if folded:
			continue
		for entry in in_section:
			var title := _create_title(entry["title"], entry.get("color", COLOR_TITLE))
			title.pressed.connect(entry["open"])
			_content.add_child(title)
			for goal: Dictionary in entry["goals"]:
				_content.add_child(_create_goal(goal["text"], goal["done"]))


## Open tasks: [{"section" (SECTIONS), "title", "color" (optional), "goals": [{"text", "done"}], "open": Callable}].
func _collect_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var objective: Dictionary = GameState.get_story_objective()
	if not str(objective.get("title", "")).is_empty():
		entries.append({"section": "main", "title": objective["title"], "goals": _story_goals(objective), "open": story_selected.emit})
	for task in GameState.story.get_side_tasks():
		entries.append({"section": "main" if task.get("main", false) else "side", "title": task.get("title", ""), "goals": _side_task_goals(task),
				"open": side_task_selected.emit.bind(task["id"])})
	var orders: Array[CustomerOrder] = GameState.customers.orders.duplicate()
	orders.sort_custom(func(a: CustomerOrder, b: CustomerOrder) -> bool: return a.deadline_day < b.deadline_day)
	for order in orders:
		var have: bool = GameState.find_order_item(order) >= 0
		entries.append({"section": "orders", "title": Language.translate("Kundenauftrag: %s") % order.customer_name, "color": Rarity.get_color(order.rarity),
				"goals": [_goal("%d/1 %s" % [int(have), order.get_item_name()], have),
					_goal(Language.translate("bis %s") % GameCalendar.get_short_text(order.deadline_day), false)],
				"open": order_selected.emit.bind(order)})
	for path in GameState.quest_log:
		var quest := load(path) as QuestData
		if GameState.get_quest_state(quest) == QuestData.State.COMPLETED or GameState.is_story_quest(quest):
			continue
		var have: int = mini(GameState.count_quest_items(quest), quest.required_amount)
		entries.append({"section": "quests", "title": quest.title,
				"goals": [_goal("%d/%d %s" % [have, quest.required_amount, quest.requirement_name], have >= quest.required_amount)],
				"open": quest_selected.emit.bind(quest)})
	return entries


func _story_goals(objective: Dictionary) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	# Short line of the step (story.json "goal"), e.g. "0/4 Spinnweben entfernt" or "Geh zu Oma Hilde im
	# Norden"; lists (shopping, items) follow below it.
	var goal_text: String = str(objective.get("goal", ""))
	if not goal_text.is_empty():
		var total: int = objective.get("total", 0)
		goal_text = goal_text.replace("{done}", str(objective["done"])).replace("{total}", str(total))
		goals.append(_goal(GameState.format_story_text(goal_text), total > 0 and objective["done"] >= total))
	# Shopping list of the first steps: "0/2 Holz (Kräuterhändlerin)".
	for entry: Dictionary in objective.get("shopping", []):
		var where: String = " (%s)" % entry["where"] if not str(entry["where"]).is_empty() else ""
		goals.append(_goal("%d/%d %s%s" % [entry["have"], entry["need"], entry["name"], where], entry["done"]))
	for entry: Dictionary in objective.get("extra_goals", []):
		goals.append(_goal("%d/1 %s" % [int(entry["done"]), entry["name"]], entry["done"]))
	if objective.has("quest_goal"):
		var quest_goal: Dictionary = objective["quest_goal"]
		goals.append(_goal("%d/%d %s" % [quest_goal["have"], quest_goal["need"], quest_goal["name"]],
				quest_goal["have"] >= quest_goal["need"]))
	for entry in GameState.get_item_progress(str(objective.get("items", ""))):
		goals.append(_goal("%d/%d %s" % [entry["have"], entry["need"], entry["name"]], entry["have"] >= entry["need"]))
	if objective.has("status"):
		goals.append(_goal(objective["status"], false))
	elif goals.is_empty() and objective.get("total", 0) > 0:
		goals.append(_goal(Language.translate("%d/%d erledigt") % [objective["done"], objective["total"]], objective["done"] >= objective["total"]))
	if goals.is_empty():
		goals.append(_goal(_first_sentence(GameState.format_story_text(objective.get("text", ""))), false))
	return goals


func _side_task_goals(task: Dictionary) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	if GameState.story.has_flag(task.get("done_flag", "")):
		return [_goal(Language.translate("Erledigt"), true)]
	if task.has("set_items"):
		for entry in GameState.get_set_progress(task):
			# Hand-in sets count the handed-in pieces, the others what the player has.
			var done: bool = entry["given"] if task.get("hand_in", false) else entry["have"]
			goals.append(_goal("%d/1 %s" % [int(done), entry["name"]], done))
	elif task.has("todo"):
		for entry in GameState.get_todo_progress(task):
			var text: String = "%d/%d %s" % [entry["have"], entry["need"], entry["name"]] if entry.has("need") else entry["name"]
			goals.append(_goal(text, entry["done"]))
	elif task.has("show_items") or task.has("show_gold"):
		for entry in GameState.get_item_progress(task.get("show_items", ""), task.get("id", "")):
			goals.append(_goal("%d/%d %s" % [entry["have"], entry["need"], entry["name"]], entry["have"] >= entry["need"]))
		var gold: Array[int] = GameState.get_gold_progress(task.get("id", ""))
		if gold[1] > 0:
			goals.append(_goal(Language.translate("%d/%d Gold") % gold, gold[0] >= gold[1]))
	if goals.is_empty():
		goals.append(_goal(_first_sentence(GameState.format_story_text(task.get("text", ""))), false))
	return goals


func _goal(text: String, done: bool) -> Dictionary:
	return {"text": text, "done": done}


## Up to the first ". ", "! " or "? " (the task texts are often several sentences long).
## A text that is a numbered list ("1. ...\n2. ...") gives its first step without the number.
func _first_sentence(text: String) -> String:
	var numbered: RegExMatch = RegEx.create_from_string("^\\d+\\.\\s+(.*)").search(text.get_slice("\n", 0))
	if numbered:
		return numbered.get_string(1).strip_edges()
	var plain: String = text.replace("\n", " ")
	var regex := RegEx.create_from_string("^.*?[.!?](\\s|$)")
	var found: RegExMatch = regex.search(plain)
	return found.get_string().strip_edges() if found else plain


func _create_title(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = Language.translate("Details öffnen")
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, color.lightened(0.15) if state == "font_hover_color" else color)
	button.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	button.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	for style in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	return button


## Heading of a section with its arrow and the number of tasks; a click folds it in or out.
func _create_section_header(section: String, count: int, folded: bool) -> Button:
	var button := Button.new()
	button.text = "%s (%d)" % [Language.translate(SECTIONS[section]), count]
	button.icon = _arrow_texture(folded, COLOR_SECTION)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = Language.translate("Ausklappen") if folded else Language.translate("Einklappen")
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COLOR_SECTION.lightened(0.2) if state == "font_hover_color" else COLOR_SECTION)
	button.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	button.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	for style in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	button.pressed.connect(_toggle_section.bind(section))
	return button


func _toggle_section(section: String) -> void:
	if _collapsed_sections.has(section):
		_collapsed_sections.erase(section)
	else:
		_collapsed_sections.append(section)
	WindowLayout.set_setting(SETTINGS_SECTION, "collapsed_sections", _collapsed_sections)
	_refresh()
	reset_size()


func _create_goal(text: String, done: bool) -> Label:
	var label := Label.new()
	label.text = "  " + text
	label.custom_minimum_size.x = TextSize.grown("quests", LINE_WIDTH)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", COLOR_DONE if done else COLOR_GOAL)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	return label


func _toggle_collapsed() -> void:
	_collapsed = not _collapsed
	WindowLayout.set_setting(SETTINGS_SECTION, "collapsed", _collapsed)
	_update_arrow()
	_refresh()
	# Folded the tracker shrinks to its header; the header keeps its width (custom_minimum_size),
	# so arrow, title and pin stay where they are.
	reset_size()


func _update_arrow() -> void:
	_arrow_button.icon = _arrow_texture(_collapsed)
	_arrow_button.tooltip_text = Language.translate("Aufgaben ausklappen") if _collapsed else Language.translate("Aufgaben einklappen")


## Small triangle: pointing down (open) or right (folded in).
static func _arrow_texture(pointing_right: bool, color: Color = COLOR_TITLE) -> Texture2D:
	var image := Image.create_empty(7, 7, false, Image.FORMAT_RGBA8)
	for i in 4:
		for j in range(i, 7 - i):
			var pixel := Vector2i(i, j) if pointing_right else Vector2i(j, i)
			image.set_pixelv(pixel + (Vector2i(1, 0) if pointing_right else Vector2i(0, 1)), color)
	return ImageTexture.create_from_image(image)


# --- Moving and pinning (like WindowTitleBar) ---

func _on_header_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if _pin_button.button_pressed:
		return
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		_header.accept_event()
	elif _dragging and event is InputEventMouseMotion:
		position += (event as InputEventMouseMotion).relative * scale
		_keep_on_screen()
		_header.accept_event()


func _on_pin_toggled(pinned: bool) -> void:
	_dragging = false
	if pinned:
		WindowLayout.pin(LAYOUT_ID, position)
	else:
		WindowLayout.unpin(LAYOUT_ID)
	_update_pin_look()


func _restore_pinned_position() -> void:
	# Wait one frame: the tracker gets its size first.
	await get_tree().process_frame
	# The scene may have changed in that frame (e.g. right at the start): the tracker is gone.
	if not is_inside_tree():
		return
	var saved: Vector2 = WindowLayout.get_pinned_position(LAYOUT_ID)
	if saved != Vector2.INF:
		position = saved
		_pin_button.set_pressed_no_signal(true)
	_keep_on_screen()
	_update_pin_look()


func _update_pin_look() -> void:
	var pinned: bool = _pin_button.button_pressed
	_pin_button.icon = PIN_ICON_ACTIVE if pinned else PIN_ICON
	_pin_button.tooltip_text = Language.translate("Lösen (wieder verschiebbar)") if pinned else Language.translate("Anpinnen (Position merken)")
	_header.mouse_default_cursor_shape = Control.CURSOR_ARROW if pinned else Control.CURSOR_MOVE


## Inside the screen and below the free zones (time compass).
func _keep_on_screen() -> void:
	if not is_inside_tree():
		return
	var screen_size: Vector2 = get_viewport_rect().size
	var rect := Rect2(position, size * scale)
	rect.position = rect.position.clamp(Vector2.ZERO, (screen_size - rect.size).max(Vector2.ZERO))
	for zone: Node in get_tree().get_nodes_in_group(WindowTitleBar.FREE_ZONE_GROUP):
		var zone_control := zone as Control
		if zone_control and zone_control.is_visible_in_tree() and rect.intersects(zone_control.get_global_rect()):
			rect.position.y = zone_control.get_global_rect().end.y + FREE_ZONE_GAP
	position = rect.position
