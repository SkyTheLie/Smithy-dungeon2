class_name QuestDetailWindow
extends PanelContainer
## Details of one quest (opened from the quest log): who gives it, where to find him, what he
## wants (with progress, e.g. "Kupferaxt 0/1"), and the rewards (hidden ones as "[?]").
## Customer orders (show_order): customer, wanted item with parts and rarity, deadline, reward,
## and whether a matching item is in the inventory.

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_DONE: Color = Color(0.55, 0.85, 0.45)
const COLOR_MISSING: Color = Color(0.9, 0.4, 0.35)

var _quest: QuestData
var _order: CustomerOrder
## true = shows the current story task.
var _story: bool = false
## Id of the shown side task (story.json "side_tasks"), "" = none.
var _side_task: String = ""
## Something changed while the window was closed (see _refresh_if_visible).
var _stale: bool = false

@onready var _title_bar: WindowTitleBar = $VBox/TitleBar
@onready var _info_label: RichTextLabel = %InfoLabel


func _ready() -> void:
	GameState.quests_changed.connect(_refresh_if_visible)
	GameState.inventory.changed.connect(_refresh_if_visible)
	GameState.customers.changed.connect(_on_customers_changed)
	GameState.story.changed.connect(_refresh_if_visible)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree() and _stale:
			_refresh())


## Something changed: rebuilt only while the window is open; a closed one remembers it and
## rebuilds when it shows again (the inventory changes with every picked up ore).
func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		_refresh()
	else:
		_stale = true


func show_quest(quest: QuestData) -> void:
	_quest = quest
	_order = null
	_story = false
	_side_task = ""
	_refresh()
	show()


func show_order(order: CustomerOrder) -> void:
	_order = order
	_quest = null
	_story = false
	_side_task = ""
	_refresh()
	show()


## A handed-in or expired order is gone: close its window.
func _on_customers_changed() -> void:
	if _order and not GameState.customers.orders.has(_order):
		_order = null
		hide()


## The current task of the story (title, text, progress).
func show_story() -> void:
	_story = true
	_quest = null
	_order = null
	_side_task = ""
	_refresh()
	show()


## A side task of the story (title, text, which pieces of the set the player has).
func show_side_task(task_id: String) -> void:
	_side_task = task_id
	_story = false
	_quest = null
	_order = null
	_refresh()
	show()


func _refresh() -> void:
	_stale = false
	if not _side_task.is_empty():
		_refresh_side_task()
		return
	if _story:
		_refresh_story()
		return
	if _order:
		_refresh_order()
		return
	if _quest == null:
		return
	_title_bar.title = _quest.title
	var state: QuestData.State = GameState.get_quest_state(_quest)
	var have: int = GameState.count_quest_items(_quest)
	var lines: Array[String] = [
		_line(Language.translate("Auftraggeber"), _quest.giver_name),
		_line("Ort", _quest.location),
		"",
		_colored(Language.translate("Aufgabe"), COLOR_HINT),
		_quest.description,
		"",
	]
	if state == QuestData.State.COMPLETED:
		lines.append(_colored(Language.translate("Erledigt!"), COLOR_DONE))
	else:
		var color: Color = COLOR_DONE if have >= _quest.required_amount else COLOR_MISSING
		lines.append(Language.translate("Benötigt: ") + _colored("%s %d/%d" % [_quest.requirement_name, mini(have, _quest.required_amount), _quest.required_amount], color))
	lines.append("")
	lines.append(_colored(Language.translate("Belohnung"), COLOR_HINT))
	for reward in _quest.rewards:
		lines.append("· " + reward.get_text(state == QuestData.State.COMPLETED))
	_info_label.text = "\n".join(lines)


func _refresh_story() -> void:
	var objective: Dictionary = GameState.get_story_objective()
	_title_bar.title = Language.translate("Story")
	var lines: Array[String] = [
		_colored(objective.get("title", ""), COLOR_DONE),
		"",
		GameState.format_story_text(objective.get("text", "")),
	]
	if objective.has("status"):
		lines.append("")
		lines.append(objective["status"])
	elif objective.get("total", 0) > 0 and (objective.get("shopping", []) as Array).is_empty():
		# With a shopping list the list itself shows the progress.
		lines.append("")
		var goal: String = str(objective.get("goal", ""))
		if "{done}" in goal:
			lines.append(goal.replace("{done}", str(objective["done"])).replace("{total}", str(objective["total"])))
		else:
			lines.append(Language.translate("Fortschritt: %d/%d") % [objective["done"], objective["total"]])
	if not str(objective.get("items", "")).is_empty():
		lines.append("")
		_add_item_lines(lines, objective["items"], 0)
	if not (objective.get("shopping", []) as Array).is_empty():
		lines.append("")
		lines.append(_colored(Language.translate("Einkaufsliste (Marktplatz)"), COLOR_HINT))
		for entry: Dictionary in objective["shopping"]:
			var text: String = "%d/%d %s" % [entry["have"], entry["need"], entry["name"]]
			if not str(entry["where"]).is_empty():
				text += ": " + entry["where"]
			lines.append(_colored(text + " – " + Language.translate("Erledigt").to_lower(), COLOR_DONE) if entry["done"] else "· " + text)
	if not (objective.get("extra_goals", []) as Array).is_empty():
		lines.append("")
		for entry: Dictionary in objective["extra_goals"]:
			var extra: String = "%d/1 %s" % [int(entry["done"]), entry["name"]]
			lines.append(_colored(extra, COLOR_DONE) if entry["done"] else "· " + extra)
	if objective.has("quest_goal"):
		var quest_goal: Dictionary = objective["quest_goal"]
		var text: String = Language.translate("Benötigt: %s %d/%d") % [quest_goal["name"], quest_goal["have"], quest_goal["need"]]
		lines.append("")
		lines.append(_colored(text, COLOR_DONE) if quest_goal["have"] >= quest_goal["need"] else text)
	if GameState.rent.active:
		lines.append("")
		lines.append(_line(Language.translate("Miete"), GameState.rent.get_status_text()))
	_info_label.text = "\n".join(lines)


## "Holzbrett: 12/20" per thing (story.json "show_items"), green once there are enough; with
## `gold` > 0 also a line for the gold. With `task_id` what was handed in for that side task
## already counts along (GameState.deliver).
func _add_item_lines(lines: Array[String], specs: String, gold: int, task_id: String = "") -> void:
	for entry in GameState.get_item_progress(specs, task_id):
		var text: String = "%s: %d/%d" % [entry["name"], entry["have"], entry["need"]]
		lines.append(_colored(text, COLOR_DONE) if entry["have"] >= entry["need"] else text)
	if gold > 0:
		var have: int = GameState.get_gold_progress(task_id)[0] if not task_id.is_empty() else mini(GameState.gold, gold)
		var text: String = Language.translate("Gold: %d/%d") % [have, gold]
		lines.append(_colored(text, COLOR_DONE) if have >= gold else text)


func _refresh_side_task() -> void:
	var task: Dictionary = GameState.story.get_side_task(_side_task)
	_title_bar.title = Language.translate("Hauptquest" if task.get("main", false) else "Nebenquest")
	var lines: Array[String] = [
		_colored(task.get("title", ""), COLOR_DONE),
		"",
		GameState.format_story_text(task.get("text", "")),
	]
	if GameState.story.has_flag(task.get("done_flag", "")):
		lines.append("")
		lines.append(_colored(Language.translate("Erledigt!"), COLOR_DONE))
	elif task.has("set_items"):
		lines.append("")
		for entry in GameState.get_set_progress(task):
			if task.get("hand_in", false):
				# Only handed-in pieces count: 0/1 or 1/1.
				lines.append(_colored("%s: 1/1" % entry["name"], COLOR_DONE) if entry["given"] else "%s: 0/1" % entry["name"])
			else:
				lines.append(_colored("%s: ja" % entry["name"], COLOR_DONE) if entry["have"] else Language.translate("%s: fehlt noch") % entry["name"])
		if GameState.story.flags.has(task.get("complete_flag", "")):
			lines.append("")
			lines.append(_colored(GameState.format_story_text(task.get("complete_text", "")), COLOR_DONE))
	elif task.has("todo"):
		lines.append("")
		for entry in GameState.get_todo_progress(task):
			var text: String = "%s: %d/%d" % [entry["name"], entry["have"], entry["need"]] if entry.has("need") else entry["name"]
			lines.append(_colored(text, COLOR_DONE) if entry["done"] else "· " + text)
	elif task.has("show_items") or task.has("show_gold"):
		lines.append("")
		_add_item_lines(lines, task.get("show_items", ""), int(task.get("show_gold", 0)), _side_task)
	elif GameState.story.flags.has(task.get("complete_flag", "@")):
		lines.append("")
		lines.append(_colored(GameState.format_story_text(task.get("complete_text", "")), COLOR_DONE))
	_info_label.text = "\n".join(lines)


func _refresh_order() -> void:
	_title_bar.title = Language.translate("Kundenauftrag")
	var days: int = _order.days_left(GameState.day_cycle.day)
	var have: bool = GameState.find_order_item(_order) >= 0
	var lines: Array[String] = [
		_line(Language.translate("Kunde"), _order.customer_name),
		_line(Language.translate("Abgabe"), Language.translate("Auftragsbrett vor der Schmiede")),
		_line(Language.translate("Frist"), Language.translate("bis %s (%s)") % [GameCalendar.get_short_text(_order.deadline_day), CustomerOrder.get_days_left_text(days)]),
		"",
		_colored(Language.translate("Gegenstand"), COLOR_HINT),
		_colored(_order.get_item_name(), Rarity.get_color(_order.rarity)),
		Language.translate("Seltenheit: mindestens ") + _colored(Rarity.get_display_name(_order.rarity), Rarity.get_color(_order.rarity)),
	]
	for part in _order.parts:
		lines.append("%s: %s" % [Language.translate(ItemData.PART_TYPE_NAMES[part.part_type]), part.display_name])
	lines.append("")
	lines.append(_colored("Im Inventar: ja", COLOR_DONE) if have else _colored("Im Inventar: nein", COLOR_MISSING))
	lines.append("")
	lines.append(_colored(Language.translate("Belohnung"), COLOR_HINT))
	lines.append(Language.translate("· %d Gold") % _order.gold)
	lines.append(Language.translate("· %d PEXP") % _order.experience)
	_info_label.text = "\n".join(lines)


func _line(label: String, value: String) -> String:
	return "%s: %s" % [_colored(label, COLOR_HINT), value]


func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]
