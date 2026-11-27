class_name EndScreen
extends CanvasLayer
## End of a run: "Du bist gefallen" (dead), "Geschafft!" (last boss beaten), "Geflüchtet!"
## (out through the ladder in a start room) or "Hinausgeklettert!" (the rope after the very first
## boss, with its achievement), with the floor,
## kills, the run's values and its items. No buttons: a click or a key (after a short moment, so
## nothing is clicked by mistake) and you wake up in front of Egon (Game.to_shop, the next day).

@onready var _title: Label = %Title
@onready var _summary: Label = %Summary
@onready var _summary_right: Label = %SummaryRight
@onready var _items: HFlowContainer = %Items
@onready var _hint: Label = %Hint

## Seconds before a click counts.
const WAIT_TIME: float = 0.6
var _can_go_on: bool = false


func _ready() -> void:
	hide()


func open(run: RunState, won: bool, fled: bool = false, climbed: bool = false) -> void:
	if climbed:
		_title.text = Language.translate("Hinausgeklettert!")
		_title.modulate = Color(0.75, 1.0, 0.7)
	elif fled:
		_title.text = Language.translate("Geflüchtet!")
		_title.modulate = Color(0.7, 0.9, 1.0)
	else:
		_title.text = Language.translate("Geschafft!") if won else Language.translate("Du bist gefallen")
		_title.modulate = Color(1, 0.86, 0.45) if won else Color(1, 0.45, 0.4)
	# Two columns, so everything fits on the screen.
	var lines: Array[String] = [
		Language.translate("Ebene: %d") % (run.floor_index + 1),
		Language.translate("Besiegte Gegner: %d") % run.kills,
		Language.translate("EXP: +%d") % run.exp_earned,
	]
	if run.levels_gained > 0:
		lines.append(Language.translate("Stufe %d erreicht! +%d Skillpunkte") % [MetaState.level(), run.levels_gained * int(Skills.levels().get("points_per_level", 1))])
	# What comes home (MetaState.end_run already ran in RunScene).
	if won or fled or climbed:
		lines.append(Language.translate("Mit nach Hause: %d Gold, %d Beute") % [run.coins, _count(run.bag.contents())])
	else:
		lines.append(Language.translate("Gerettet (sicherer Platz): %d Gold, %d Beute") % [_gold(run.bag.safe_contents()), _count(run.bag.safe_contents())])
	# Keys stay in the dungeon: they break at the way out (Egon tells it in the tutorial).
	if run.keys > 0:
		lines.append(Language.translate("Schlüssel zerbrochen: %d") % run.keys)
	if climbed:
		var achievement: Dictionary = Content.achievement(String(Content.meta("ruby_quest").get("achievement", "")))
		if not achievement.is_empty():
			lines.append(Language.translate("Erfolg: %s") % Language.translate(String(achievement.get("name", ""))))
	for line: String in PauseMenu.describe(run).split("\n"):
		lines.append(line)
	var half: int = ceili(lines.size() / 2.0)
	_summary.text = "\n".join(lines.slice(0, half))
	_summary_right.text = "\n".join(lines.slice(half))
	for child in _items.get_children():
		child.queue_free()
	for id: String in run.items:
		var icon := TextureRect.new()
		icon.texture = load(String(Content.item(id).get("icon", ""))) as Texture2D
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.tooltip_text = Language.translate(String(Content.item(id).get("name", id)))
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_items.add_child(icon)
	show()
	get_tree().paused = true
	_can_go_on = false
	_hint.modulate.a = 0.0
	# The end screen works while the game is paused, so this timer must run then too.
	await get_tree().create_timer(WAIT_TIME, true).timeout
	if not is_inside_tree():
		return
	_can_go_on = true
	var blink := create_tween().set_loops()
	blink.tween_property(_hint, "modulate:a", 1.0, 0.5)
	blink.tween_property(_hint, "modulate:a", 0.35, 0.5)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if won:
		AudioManager.play_music("victory")


## Any click or key: wake up in front of Egon.
func _input(event: InputEvent) -> void:
	if not visible or not _can_go_on:
		return
	var is_button: bool = event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton
	if is_button and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_can_go_on = false
		Game.to_shop()


func can_go_on() -> bool:
	return _can_go_on


## Pieces of loot (without the gold).
static func _count(places: Array[Dictionary]) -> int:
	var total: int = 0
	for place: Dictionary in places:
		if String(place.get("id", "")) != Bag.GOLD:
			total += int(place.get("count", 0))
	return total


static func _gold(places: Array[Dictionary]) -> int:
	var total: int = 0
	for place: Dictionary in places:
		if String(place.get("id", "")) == Bag.GOLD:
			total += int(place.get("count", 0))
	return total
