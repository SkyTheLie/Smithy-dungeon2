class_name GambaBuckets
extends Control
## The five buckets of the next strike (break | damage | hold | success | great), drawn as bars
## that fill with their chance; the percent under each, its name above. The bucket a strike drew
## lights up for a moment (flash). Colours and names: gamba.json.

const BAR_HEIGHT: float = 34.0
const GAP: float = 6.0
const FLASH_TIME: float = 0.35

var _chances: Dictionary[String, float] = {}
## Outcome -> colour / translated name, read once in _ready.
var _colors: Dictionary[String, Color] = {}
var _names: Dictionary[String, String] = {}
var _flash_outcome: String = ""
var _flash_left: float = 0.0
## No break possible right now (frenzy or rune): the break bucket shows a lock.
var _break_locked: bool = false


func _ready() -> void:
	for outcome: String in GambaRun.OUTCOMES:
		_colors[outcome] = GambaRun.outcome_color(outcome)
		_names[outcome] = GambaRun.outcome_name(outcome)
		_chances[outcome] = 0.0
	custom_minimum_size = Vector2(5 * 54 + 4 * GAP, BAR_HEIGHT + 26)
	set_process(false)


func set_chances(chances: Dictionary[String, float], break_locked: bool) -> void:
	_chances = chances.duplicate()
	_break_locked = break_locked
	queue_redraw()


func flash(outcome: String) -> void:
	_flash_outcome = outcome
	_flash_left = FLASH_TIME
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_flash_left -= delta
	if _flash_left <= 0.0:
		_flash_outcome = ""
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var width: float = (size.x - GAP * 4) / 5.0
	var x: float = 0.0
	for outcome: String in GambaRun.OUTCOMES:
		var color: Color = _colors.get(outcome, Color.WHITE)
		var chance: float = _chances.get(outcome, 0.0)
		var top: float = 11.0
		var bar := Rect2(x, top, width, BAR_HEIGHT)
		var lit: bool = outcome == _flash_outcome
		draw_rect(bar, Color(0.05, 0.03, 0.05, 0.75))
		var fill: float = BAR_HEIGHT * clampf(chance, 0.0, 1.0)
		if chance > 0.0:
			fill = maxf(fill, 1.0)
		draw_rect(Rect2(x, top + BAR_HEIGHT - fill, width, fill), color.lightened(0.4) if lit else Color(color, 0.85))
		draw_rect(bar, Color.WHITE if lit else color.darkened(0.3), false, 2.0 if lit else 1.0)
		draw_string(font, Vector2(x, 8), _names.get(outcome, outcome), HORIZONTAL_ALIGNMENT_CENTER, width, font_size - 1, color)
		var percent: String = "-" if outcome == "break" and _break_locked else DamageKinds.format_number(chance * 100.0) + " %"
		draw_string(font, Vector2(x, top + BAR_HEIGHT + 11), percent, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color.WHITE)
		x += width + GAP
