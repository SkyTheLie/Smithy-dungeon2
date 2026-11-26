class_name QuestLogWindow
extends PanelContainer
## Quest log ("Aufträge" in the side menu) with two tabs, each split into sections.
## "Offen": "Story" (only the current story task, the one that moves the story on), "Nebenquests"
## (the running side tasks), "Kundenaufträge" (soonest deadline first, in their rarity colour) and
## "Aufträge" (the running quests).
## "Erledigt": the same sections with what the player has finished (story steps in story order,
## the task text as tooltip).
## Clicking emits quest_selected / order_selected / story_selected / side_task_selected (the HUD
## opens the detail window).

signal quest_selected(quest: QuestData)
signal order_selected(order: CustomerOrder)
signal story_selected
signal side_task_selected(task_id: String)

enum Tab { OPEN, DONE }

const COLOR_DONE: Color = Color(0.55, 0.52, 0.5)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.5)

@onready var _tab_bar: TabBar = %TabBar
@onready var _list: VBoxContainer = %QuestList
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_tab_bar.add_tab(Language.translate("Offen"))
	_tab_bar.add_tab(Language.translate("Erledigt"))
	_tab_bar.tab_changed.connect(func(_tab: int) -> void: _refresh())
	# The list is rebuilt only while the window is open, and once whenever it opens (not with
	# every story flag and customer while it is closed).
	GameState.quests_changed.connect(_refresh_if_visible)
	GameState.customers.changed.connect(_refresh_if_visible)
	GameState.story.changed.connect(_refresh_if_visible)
	visibility_changed.connect(_refresh_if_visible)
	# Text size (settings » "Textgröße: Aufgaben"): the list grows with the text.
	TextSize.attach(self, "quests", [$VBox/Scroll, _list], func() -> void: reset_size())
	_refresh()


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var active: Array[QuestData] = []
	var done: Array[QuestData] = []
	for path in GameState.quest_log:
		var quest := load(path) as QuestData
		# Handled by the story (e.g. Holger's axe): already there as the story task.
		if GameState.is_story_quest(quest):
			continue
		if GameState.get_quest_state(quest) == QuestData.State.COMPLETED:
			done.append(quest)
		else:
			active.append(quest)
	if _tab_bar.current_tab == Tab.OPEN:
		_fill_open(active)
	else:
		_fill_done(done)
	_empty_label.visible = _list.get_child_count() == 0
	_empty_label.text = Language.translate("Noch keine Aufträge.") if _tab_bar.current_tab == Tab.OPEN else Language.translate("Noch nichts erledigt.")


func _fill_open(active: Array[QuestData]) -> void:
	var objective: Dictionary = GameState.get_story_objective()
	if not str(objective.get("title", "")).is_empty():
		_list.add_child(_create_header(Language.translate("Story")))
		var story_button: Button = _create_button(null, false)
		story_button.text = objective["title"]
		if objective["total"] > 0:
			story_button.text += " (%d/%d)" % [objective["done"], objective["total"]]
		story_button.pressed.connect(story_selected.emit)
		_list.add_child(story_button)
	# Side tasks with "main": true belong to the story (e.g. the desert compass): right under it.
	var side_tasks: Array[Dictionary] = []
	for task in GameState.story.get_side_tasks():
		if task.get("main", false):
			_list.add_child(_create_side_task_button(task))
		else:
			side_tasks.append(task)
	if not side_tasks.is_empty():
		_list.add_child(_create_header(Language.translate("Nebenquests")))
	for task in side_tasks:
		_list.add_child(_create_side_task_button(task))
	var orders: Array[CustomerOrder] = GameState.customers.orders.duplicate()
	orders.sort_custom(func(a: CustomerOrder, b: CustomerOrder) -> bool: return a.deadline_day < b.deadline_day)
	if not orders.is_empty():
		_list.add_child(_create_header(Language.translate("Kundenaufträge")))
		for order in orders:
			var button: Button = _create_button(null, false)
			button.text = Language.translate("%s (bis %s)") % [order.get_item_name(), GameCalendar.get_short_text(order.deadline_day)]
			button.add_theme_color_override("font_color", Rarity.get_color(order.rarity))
			button.pressed.connect(func() -> void: order_selected.emit(order))
			_list.add_child(button)
	if not active.is_empty():
		_list.add_child(_create_header(Language.translate("Aufträge")))
		for quest in active:
			_list.add_child(_create_button(quest, false))


func _fill_done(done: Array[QuestData]) -> void:
	var finished_side: Array[Dictionary] = GameState.story.get_finished_side_tasks()
	var main_story: Array[Dictionary] = GameState.story.get_finished_steps()
	main_story.append_array(finished_side.filter(func(task: Dictionary) -> bool: return task.get("main", false)))
	_add_finished(Language.translate("Story"), main_story)
	_add_finished(Language.translate("Nebenquests"), finished_side.filter(func(task: Dictionary) -> bool: return not task.get("main", false)))
	if not done.is_empty():
		_list.add_child(_create_header(Language.translate("Aufträge")))
		for quest in done:
			_list.add_child(_create_button(quest, true))


func _create_side_task_button(task: Dictionary) -> Button:
	var task_button: Button = _create_button(null, false)
	task_button.text = task.get("title", "")
	task_button.pressed.connect(side_task_selected.emit.bind(task["id"]))
	return task_button


## A section of finished story steps or side tasks: their titles, the task text as tooltip.
func _add_finished(header: String, steps: Array[Dictionary]) -> void:
	if steps.is_empty():
		return
	_list.add_child(_create_header(header))
	for step in steps:
		var label := Label.new()
		label.text = step["title"]
		label.tooltip_text = GameState.format_story_text(step["text"])
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.add_theme_color_override("font_color", COLOR_DONE)
		_list.add_child(label)


## Button for a quest (quest = null: an empty button, the caller fills it).
func _create_button(quest: QuestData, done: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if quest == null:
		return button
	button.text = quest.title
	if done:
		button.add_theme_color_override("font_color", COLOR_DONE)
	button.pressed.connect(func() -> void: quest_selected.emit(quest))
	return button


func _create_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_HEADER)
	return label
