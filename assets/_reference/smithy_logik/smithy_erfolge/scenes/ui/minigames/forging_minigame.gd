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


func _ready() -> void:
	_workpiece.struck.connect(_on_workpiece_struck)
	%TitleBar.close_requested.connect(close_requested.emit)


## `start_slot` = the hot blank (its rarity and quality are the starting point of the preview),
## `item` = what is forged (decides the picture, the spots and the difficulty of its material).
## `strikes` > 0: exactly that many strikes instead of the player's own (e.g. 3 for Halvard's
## shackle, KerkerForgeCutscene).
func start(start_slot: InventorySlot = null, item: ItemData = null, strikes: int = 0) -> void:
	var stats: PlayerStats = GameState.player_stats
	_start = start_slot.copy_with_amount(1) if start_slot else InventorySlot.new()
	_difficulty = ForgeQuality.get_difficulty(item.material_tier if item else 0)
	_duration = beat_duration / maxf(0.1, float(_difficulty.get("speed", 1.0)))
	_strike_count = strikes if strikes > 0 else stats.get_forging_strikes()
	_workpiece.set_item(item, ContentDB.forging_pattern_for(item), _strike_count)
	_timing_bar.configure(stats, _difficulty)
	_strikes_done = 0
	_points = 0
	_all_green = true
	_combo = 0
	_hit_stop = 0.0
	_feedback_label.text = ""
	_running = true
	show()
	_next_strike()


## Aborts the minigame without result.
func stop() -> void:
	_running = false
	_workpiece.hide_strike()
	hide()


func is_running() -> bool:
	return _running


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


func _register_strike(zone: TimingBar.Zone, miss_text: String = "Nicht im Takt") -> void:
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
			_feedback_label.text = "Gut"
			AudioManager.play_sound("anvil_good")
			_hit_stop = HIT_STOP_YELLOW
		TimingBar.Zone.MISS:
			_feedback_label.text = miss_text
			AudioManager.play_sound("anvil_miss")
	_pop_feedback(zone)
	_workpiece.mark(_strikes_done, zone)
	_workpiece.burst(_strikes_done, zone, points, _combo)
	_strikes_done += 1
	_workpiece.set_cooling(float(_strikes_done) / _strike_count)
	_next_strike()


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
