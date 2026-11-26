class_name ForgingMinigame
extends PanelContainer
## Forging minigame: the part being forged is shown glowing (its item icon, e.g. the copper
## pickaxe head; it cools to its real colours with every strike) and its strike spots light up one
## after another (ForgingWorkpiece; items without an icon use their ForgingPattern from
## data/content/forging_patterns.json, ContentDB.forging_pattern_for). Click the current spot
## while the marker of the timing bar is in the green or yellow zone.
## A strike only scores if the spot itself is hit. Clicking next to it on the workpiece
## ("daneben gehauen"), clicking outside the green/yellow zone, or letting the marker reach
## the right end all count as a miss.
## Every strike gives or takes quality points (ForgeQuality.anvil_points): green many, yellow a
## few, a miss costs points. The piece keeps the rarity and quality of its hot blank, the points
## are added on top (more than 100 = next rarity, below 0 = one rarity down).
## How hard it is depends on the material and the reputation (ForgeQuality.get_difficulty): the
## marker gets faster, the zones smaller, up to no green zone at all.
## Strikes and zones come from GameState.player_stats.
## Hits have weight: sparks, floating points and a shake on the workpiece (ForgingWorkpiece.burst),
## the marker stops for a moment (hit stop), and green strikes in a row are a combo ("Perfekt! x3",
## the clang a bit higher every time).
## The first forging from the anvil menu (start with offer_tutorial) begins with ForgingTutorial:
## three picture cards, then a hammer that shows a green, a yellow and a late strike (they count
## nothing); after that the forging starts fresh. The "?" button shows it again at any time (the
## forging begins anew, like closing and opening the window).

## `points` = quality points of the whole forging, `perfect` = every strike was green.
signal finished(points: int, perfect: bool)
## The X of the title bar was clicked (the station menu aborts the forging).
signal close_requested

## Seconds the marker needs from left to right at normal difficulty (lower = harder).
@export var beat_duration: float = 1.6
## Seconds the marker stands still after a green / yellow strike.
const HIT_STOP_GREEN: float = 0.09
const HIT_STOP_YELLOW: float = 0.05
## Every green strike in a row plays the clang this much higher, up to COMBO_PITCH_MAX.
const COMBO_PITCH_STEP: float = 0.06
const COMBO_PITCH_MAX: float = 1.4
## Size of the feedback text right after a strike (shrinks back to 1).
const FEEDBACK_POP: float = 1.5

var _running: bool = false
## Values from GameState.player_stats, read when a forging starts.
var _strike_count: int = 4
var _strikes_done: int = 0
var _points: int = 0
var _all_green: bool = true
## Seconds per pass of the marker for this forging (beat_duration / difficulty speed).
var _duration: float = 1.6
## Rarity and quality of the hot blank (for the preview label).
var _start: InventorySlot = InventorySlot.new()
var _difficulty: Dictionary = {}
## What start() got, to begin anew after the tutorial.
var _item: ItemData
var _strikes_wanted: int = 0
## Green strikes in a row.
var _combo: int = 0
## Seconds the marker still stands still.
var _hit_stop: float = 0.0

@onready var _info_label: Label = %InfoLabel
@onready var _workpiece: ForgingWorkpiece = %Workpiece
@onready var _timing_bar: TimingBar = %TimingBar
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _quality_label: Label = %QualityLabel
@onready var _rarity_label: Label = %RarityLabel
@onready var _tutorial: ForgingTutorial = %Tutorial


func _ready() -> void:
	_workpiece.struck.connect(_on_workpiece_struck)
	%TitleBar.close_requested.connect(close_requested.emit)
	%HelpButton.pressed.connect(_on_help_pressed)
	%HelpButton.tooltip_text = Language.translate("Anleitung zum Schmieden")
	_tutorial.finished.connect(_begin_strikes)
	# Phone: the whole window bigger (grows down from its top centre), MobileUi.
	if MobileUi.active():
		scale = Vector2.ONE * MobileUi.FORGE_WINDOW_SCALE
		resized.connect(_keep_pivot)
		_keep_pivot()


func _keep_pivot() -> void:
	pivot_offset = Vector2(size.x / 2.0, 0.0)


## `start_slot` = the hot blank (its rarity and quality are the starting point of the preview),
## `item` = what is forged (decides the picture, the spots and the difficulty of its material).
## `strikes` > 0: exactly that many strikes instead of the player's own (e.g. 3 for Halvard's
## shackle, KerkerForgeCutscene).
## `offer_tutorial`: the very first time (ForgingTutorial.was_seen) the tutorial comes first.
func start(start_slot: InventorySlot = null, item: ItemData = null, strikes: int = 0, offer_tutorial: bool = false) -> void:
	_start = start_slot.copy_with_amount(1) if start_slot else InventorySlot.new()
	_item = item
	_strikes_wanted = strikes
	show()
	if offer_tutorial and not ForgingTutorial.was_seen():
		_play_tutorial()
	else:
		_begin_strikes()


## Puts a fresh piece on the anvil (no strike done, nothing running).
func _set_up() -> void:
	var stats: PlayerStats = GameState.player_stats
	_difficulty = ForgeQuality.get_difficulty(_item.material_tier if _item else 0)
	_duration = beat_duration / maxf(0.1, float(_difficulty.get("speed", 1.0)))
	_strike_count = _strikes_wanted if _strikes_wanted > 0 else stats.get_forging_strikes()
	_workpiece.set_item(_item, ContentDB.forging_pattern_for(_item), _strike_count)
	_timing_bar.configure(stats, _difficulty)
	_timing_bar.marker = 0.0
	_strikes_done = 0
	_points = 0
	_all_green = true
	_combo = 0
	_hit_stop = 0.0
	_feedback_label.text = ""
	_update_labels()


## The real forging: a fresh piece, the first spot lights up.
func _begin_strikes() -> void:
	_set_up()
	_running = true
	_next_strike()


func _play_tutorial() -> void:
	_running = false
	_set_up()
	_workpiece.hide_strike()
	_tutorial.play(self)


func _on_help_pressed() -> void:
	if visible and not _tutorial.is_playing():
		_play_tutorial()


## Aborts the minigame without result.
func stop() -> void:
	_running = false
	_tutorial.cancel()
	_workpiece.hide_strike()
	hide()


## true while forging or while the tutorial plays (the window is busy).
func is_running() -> bool:
	return _running or _tutorial.is_playing()


# --- For the tutorial (ForgingTutorial) --------------------------------------------

func get_workpiece() -> ForgingWorkpiece:
	return _workpiece


func get_timing_bar() -> TimingBar:
	return _timing_bar


## The labels with the quality points and the rarity they give (top: quality).
func get_quality_labels() -> Array[Control]:
	return [_quality_label, _rarity_label]


## Quality points a strike in `zone` gives in this forging.
func points_for(zone: TimingBar.Zone) -> int:
	return ForgeQuality.anvil_points(zone, _strike_count)


## A strike shown by the tutorial: sparks, sound, text and points like a real one, but the
## forging does not go on (the points vanish when it begins anew).
func demo_strike(zone: TimingBar.Zone, miss_text: String = "") -> int:
	var points: int = _apply_strike(zone, miss_text)
	_update_labels()
	return points


## Quality points collected so far.
func get_points() -> int:
	return _points


func _process(delta: float) -> void:
	if not _running:
		return
	if _hit_stop > 0.0:
		_hit_stop -= delta
		return
	_timing_bar.marker += delta / _duration
	if _timing_bar.marker >= 1.0:
		_register_strike(TimingBar.Zone.MISS, Language.translate("Zu spät"))


func _next_strike() -> void:
	_update_labels()
	if _strikes_done >= _strike_count:
		_running = false
		_workpiece.hide_strike()
		finished.emit(_points, _all_green)
		return
	_timing_bar.marker = 0.0
	_workpiece.show_strike(_strikes_done)


## A click on the workpiece: inside the lit spot it counts with the timing, next to it it missed.
func _on_workpiece_struck(on_spot: bool) -> void:
	if not _running:
		return
	if on_spot:
		_register_strike(_timing_bar.get_zone(_timing_bar.marker))
	else:
		_register_strike(TimingBar.Zone.MISS, Language.translate("Daneben gehauen"))


func _register_strike(zone: TimingBar.Zone, miss_text: String = "") -> void:
	_apply_strike(zone, miss_text)
	_next_strike()


## Counts and shows one strike, returns its quality points. `miss_text` (translated) for a miss,
## empty = "Nicht im Takt".
func _apply_strike(zone: TimingBar.Zone, miss_text: String) -> int:
	var points: int = ForgeQuality.anvil_points(zone, _strike_count)
	_points += points
	_all_green = _all_green and zone == TimingBar.Zone.GREEN
	_combo = _combo + 1 if zone == TimingBar.Zone.GREEN else 0
	match zone:
		TimingBar.Zone.GREEN:
			_feedback_label.text = Language.translate("Perfekt!") if _combo < 2 else Language.translate("Perfekt! x%d") % _combo
			AudioManager.play_sound("anvil_perfect", minf(1.0 + COMBO_PITCH_STEP * (_combo - 1), COMBO_PITCH_MAX))
			_hit_stop = HIT_STOP_GREEN
		TimingBar.Zone.YELLOW:
			_feedback_label.text = Language.translate("Gut")
			AudioManager.play_sound("anvil_good")
			_hit_stop = HIT_STOP_YELLOW
		TimingBar.Zone.MISS:
			_feedback_label.text = miss_text if not miss_text.is_empty() else Language.translate("Nicht im Takt")
			AudioManager.play_sound("anvil_miss")
	_pop_feedback(zone)
	_workpiece.mark(_strikes_done, zone)
	_workpiece.burst(_strikes_done, zone, points, _combo)
	_strikes_done += 1
	_workpiece.set_cooling(float(_strikes_done) / _strike_count)
	return points


## The feedback text pops up big in the colour of the zone and shrinks back.
func _pop_feedback(zone: TimingBar.Zone) -> void:
	var color: Color = ForgingWorkpiece.COLOR_HIT if zone == TimingBar.Zone.GREEN else (
			ForgingWorkpiece.COLOR_HALF if zone == TimingBar.Zone.YELLOW else ForgingWorkpiece.COLOR_MISS)
	_feedback_label.add_theme_color_override("font_color", Color(color, 1.0))
	_feedback_label.pivot_offset = _feedback_label.size / 2.0
	_feedback_label.scale = Vector2.ONE * FEEDBACK_POP
	create_tween().tween_property(_feedback_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_labels() -> void:
	_info_label.text = Language.translate("Schlag %d/%d · %s") % [mini(_strikes_done + 1, _strike_count), _strike_count,
			_difficulty.get("name", Language.translate("Normal"))]
	_quality_label.text = Language.translate("Qualität %+d") % _points
	var preview: InventorySlot = _start.copy_with_amount(1)
	ForgeQuality.add(preview, _points)
	_rarity_label.text = ForgeQuality.describe(preview.rarity, preview.quality)
	_rarity_label.add_theme_color_override("font_color", Rarity.get_color(preview.rarity))
