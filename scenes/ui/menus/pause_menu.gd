class_name PauseMenu
extends CanvasLayer
## Esc during a run: the game stops, the mouse is free. Shows the current values (damage, fire
## rate ...) and the active synergies; on the left the run's items: hovering over one (or
## clicking it) shows its name, effect, kind and the active synergies it is part of.
## Weiter / Einstellungen / Hauptmenü.

signal resumed

var run: RunState

@onready var _stats: Label = %Stats
@onready var _settings: SettingsWindow = %SettingsWindow
@onready var _panel: Control = %Panel
@onready var _items_panel: Control = %ItemsPanel
@onready var _item_grid: GridContainer = %ItemGrid
@onready var _item_name: Label = %ItemName
@onready var _item_text: Label = %ItemText


func _ready() -> void:
	hide()
	_settings.hide()
	%Resume.pressed.connect(resume)
	%Settings.pressed.connect(_open_settings)
	%Menu.pressed.connect(Game.to_main_menu)
	_settings.closed.connect(func() -> void:
		_panel.show()
		_items_panel.show())


func open(run_state: RunState) -> void:
	run = run_state
	_stats.text = describe(run)
	_fill_items()
	_panel.show()
	_items_panel.show()
	_settings.hide()
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	hide()
	get_tree().paused = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(Controls.PAUSE):
		get_viewport().set_input_as_handled()
		if _settings.visible:
			_settings.close()
		else:
			resume()


func _open_settings() -> void:
	_panel.hide()
	_items_panel.hide()
	_settings.open(false)


## The values of the run as text (also used by the end screen).
static func describe(state: RunState) -> String:
	var s: ShotStats = state.stats
	var lines: Array[String] = [
		Language.translate("Schaden: %s") % format_number(s.damage),
		Language.translate("Schüsse pro Sekunde: %s") % format_number(1.0 / s.fire_delay),
		Language.translate("Reichweite: %s m") % format_number(s.reach),
		Language.translate("Schüsse auf einmal: %d") % s.shots,
		Language.translate("Tempo: %s") % format_number(s.move_speed),
	]
	if not state.synergies.is_empty():
		var names: Array[String] = []
		for id: String in state.synergies:
			names.append(Language.translate(String(Content.synergies()[id].get("name", id))))
		lines.append(Language.translate("Synergien: %s") % ", ".join(names))
	return "\n".join(lines)


static func format_number(value: float) -> String:
	return String.num(value, 1) if absf(value - roundf(value)) > 0.05 else str(roundi(value))


# --- Items on the left -----------------------------------------------------------------

## One picture per item (an item taken twice shows "x2").
func _fill_items() -> void:
	for child: Node in _item_grid.get_children():
		child.queue_free()
	var counts: Dictionary[String, int] = {}
	for id: String in run.items:
		counts[id] = counts.get(id, 0) + 1
	for id: String in counts:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(28, 28)
		slot.focus_mode = Control.FOCUS_NONE
		slot.expand_icon = true
		slot.icon = load(String(Content.item(id).get("icon", ""))) as Texture2D
		if counts[id] > 1:
			slot.text = "x%d" % counts[id]
			slot.add_theme_font_size_override("font_size", 9)
			slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot.mouse_entered.connect(_show_item.bind(id))
		slot.pressed.connect(_show_item.bind(id))
		_item_grid.add_child(slot)
	if counts.is_empty():
		_item_name.text = ""
		_item_text.text = Language.translate("Noch keine Items")
	else:
		_item_name.text = ""
		_item_text.text = Language.translate("Fahre mit der Maus über ein Item")


func _show_item(id: String) -> void:
	var data: Dictionary = Content.item(id)
	_item_name.text = Language.translate(String(data.get("name", id)))
	var lines: Array[String] = [Language.translate(String(data.get("desc", "")))]
	var category: String = LexiconWindow.category_text(String(data.get("category", "")))
	if not category.is_empty():
		lines.append(category)
	var names: Array[String] = []
	for synergy_id: String in run.synergies:
		for group: Array in Content.synergies()[synergy_id].get("requires", []):
			if group.has(id):
				names.append(Language.translate(String(Content.synergies()[synergy_id].get("name", synergy_id))))
				break
	if not names.is_empty():
		lines.append(Language.translate("Synergien: %s") % ", ".join(names))
	_item_text.text = "\n".join(lines)
