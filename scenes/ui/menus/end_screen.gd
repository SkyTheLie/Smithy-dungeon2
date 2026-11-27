class_name EndScreen
extends CanvasLayer
## End of a run: "Du bist gefallen" (dead), "Geschafft!" (last boss beaten), "Geflüchtet!"
## (out through the ladder in a start room) or "Hinausgeklettert!" (the rope after the very first
## boss, with its achievement), with the floor,
## kills, the run's values and its items. Below the title the EXP bar fills up with the EXP of
## the run; a new level makes it burst ("Stufe X!", confetti) and fill again from the start.
## No buttons: a click or a key (after a short moment, so nothing is clicked by mistake) and you
## wake up in front of Egon (Game.to_shop, the next day).

@onready var _title: Label = %Title
@onready var _summary: Label = %Summary
@onready var _summary_right: Label = %SummaryRight
@onready var _items: HFlowContainer = %Items
@onready var _hint: Label = %Hint

## Seconds before a click counts.
const WAIT_TIME: float = 0.6
## Seconds the EXP bar needs to fill once.
const EXP_FILL_TIME: float = 0.9
const EXP_COLOR := Color(0.45, 0.85, 1.0)
const LEVEL_COLOR := Color(1.0, 0.85, 0.3)
var _can_go_on: bool = false
var _exp_bar: ProgressBar
var _exp_label: Label
var _level_burst: Label


func _ready() -> void:
	hide()
	_build_exp_bar()


## The EXP bar under the title (built in code): bar, "Stufe 3 · 40 / 90 EXP", the burst label.
func _build_exp_bar() -> void:
	var box := VBoxContainer.new()
	box.name = "ExpBox"
	box.add_theme_constant_override("separation", 1)
	_title.get_parent().add_child(box)
	_title.get_parent().move_child(box, _title.get_index() + 1)
	_exp_bar = ProgressBar.new()
	_exp_bar.name = "ExpBar"
	_exp_bar.show_percentage = false
	_exp_bar.custom_minimum_size = Vector2(0, 8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.08, 0.12)
	back.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = EXP_COLOR
	fill.set_corner_radius_all(3)
	_exp_bar.add_theme_stylebox_override("background", back)
	_exp_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_exp_bar)
	_exp_label = Label.new()
	_exp_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_exp_label.add_theme_font_size_override("font_size", 9)
	_exp_label.add_theme_color_override("font_color", EXP_COLOR)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_exp_label)
	_level_burst = Label.new()
	_level_burst.name = "LevelBurst"
	_level_burst.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_level_burst.add_theme_font_size_override("font_size", 26)
	_level_burst.add_theme_color_override("font_color", LEVEL_COLOR)
	_level_burst.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	_level_burst.add_theme_constant_override("outline_size", 6)
	_level_burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_burst.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_level_burst.offset_left = -200
	_level_burst.offset_right = 200
	_level_burst.offset_top = -100
	_level_burst.offset_bottom = -64
	_level_burst.modulate.a = 0.0
	add_child(_level_burst)


## The bar fills from where the EXP stood before the run to now (MetaState.add_exp already ran):
## for every level gained it fills up, bursts and starts again.
func _play_exp(run: RunState) -> void:
	var level: int = MetaState.level()
	var need: int = Skills.exp_to_next(level)
	var now: float = float(MetaState.exp_points()) / float(need) if need > 0 else 1.0
	var gained: int = run.levels_gained
	var before_need: int = Skills.exp_to_next(level - gained)
	var before: float = 0.0
	if gained == 0:
		before = clampf(float(MetaState.exp_points() - run.exp_earned) / float(maxi(1, need)), 0.0, 1.0)
	else:
		# Roughly where it stood: what is left of the run's EXP after the levels.
		var spent: int = 0
		for i in gained:
			spent += Skills.exp_to_next(level - gained + i)
		before = clampf(float(spent - (run.exp_earned - MetaState.exp_points())) / float(maxi(1, before_need)), 0.0, 1.0)
	_exp_bar.max_value = 1.0
	_exp_bar.step = 0.001
	_exp_bar.value = before
	_exp_label.text = Language.translate("Stufe %d · EXP +%d") % [level - gained, run.exp_earned]
	var tween := create_tween()
	tween.tween_interval(0.35)
	for i in gained:
		var reached: int = level - gained + i + 1
		tween.tween_property(_exp_bar, "value", 1.0, EXP_FILL_TIME * 0.7).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_level_up.bind(reached, run.exp_earned))
		tween.tween_property(_exp_bar, "value", 0.0, 0.0)
	tween.tween_property(_exp_bar, "value", now, EXP_FILL_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## A new level: "Stufe X!" pops up, confetti, a chime.
func _level_up(reached: int, earned: int) -> void:
	_exp_label.text = Language.translate("Stufe %d · EXP +%d") % [reached, earned]
	_level_burst.text = Language.translate("Stufe %d!") % reached
	_level_burst.pivot_offset = _level_burst.size / 2.0
	_level_burst.scale = Vector2.ONE * 0.3
	_level_burst.modulate.a = 1.0
	var pop := create_tween()
	pop.tween_property(_level_burst, "scale", Vector2.ONE * 1.15, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_level_burst, "scale", Vector2.ONE, 0.15)
	pop.tween_interval(1.2)
	pop.tween_property(_level_burst, "modulate:a", 0.0, 0.5)
	AudioManager.play_sound("unlock")
	var confetti := CPUParticles2D.new()
	confetti.one_shot = true
	confetti.amount = 60
	confetti.lifetime = 1.4
	confetti.explosiveness = 0.9
	confetti.direction = Vector2.UP
	confetti.spread = 80.0
	confetti.initial_velocity_min = 120.0
	confetti.initial_velocity_max = 240.0
	confetti.gravity = Vector2(0, 260)
	confetti.scale_amount_min = 2.0
	confetti.scale_amount_max = 3.5
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0])
	ramp.colors = PackedColorArray([Fx.CONFETTI_COLORS[0]])
	for i in range(1, Fx.CONFETTI_COLORS.size()):
		ramp.add_point(float(i) / float(Fx.CONFETTI_COLORS.size() - 1), Fx.CONFETTI_COLORS[i])
	confetti.color_initial_ramp = ramp
	confetti.position = _level_burst.position + _level_burst.size / 2.0
	add_child(confetti)
	confetti.emitting = true
	confetti.finished.connect(confetti.queue_free)


## true once the burst "Stufe X!" was shown (tests).
func level_burst_text() -> String:
	return _level_burst.text


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
	_play_exp(run)
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
