class_name ProgressStrips
extends VBoxContainer
## Two thin bars right above the action bar, without numbers, only as a hint: player experience
## (violet, to the next level) and reputation (gold, to the next rank; grey while the next rank
## is still locked by the story). Hovering shows the exact values. Follows the action bar's
## place, size (UI scale) and visibility; built in code by the HUD (ProgressStrips.new()).

const COLOR_EXPERIENCE: Color = Color(0.62, 0.38, 0.78)
const COLOR_REPUTATION: Color = Color(0.85, 0.65, 0.3)
const COLOR_LOCKED: Color = Color(0.5, 0.48, 0.45)
const COLOR_BACK: Color = Color(0.13, 0.075, 0.12, 0.85)
## Height of one bar, gap between them and above the action bar, inset from its left/right edge.
const BAR_HEIGHT: float = 2.0
const GAP: float = 1.0
const INSET: float = 3.0

## The action bar the strips sit on (set before adding to the tree).
var anchor_control: Control

var _experience: ProgressBar
var _reputation: ProgressBar
var _reputation_fill: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", int(GAP))
	_experience = _make_bar(COLOR_EXPERIENCE)
	_reputation = _make_bar(COLOR_REPUTATION)
	_reputation_fill = _reputation.get_theme_stylebox("fill") as StyleBoxFlat
	GameState.player_stats.experience_changed.connect(refresh)
	GameState.player_stats.leveled_up.connect(func(_level: int) -> void: refresh())
	GameState.reputation.changed.connect(refresh)
	# Deferred: UiScale moves the bar's pivot on resize first.
	anchor_control.item_rect_changed.connect(place, CONNECT_DEFERRED)
	anchor_control.visibility_changed.connect(place)
	refresh()
	place.call_deferred()


func refresh() -> void:
	var stats: PlayerStats = GameState.player_stats
	if stats.level >= stats.get_max_level():
		_experience.value = 1.0
		_experience.tooltip_text = Language.translate("Level %d (höchstes)") % stats.level
	else:
		var needed: int = stats.get_experience_to_next_level()
		_experience.value = float(stats.experience) / maxf(needed, 1)
		_experience.tooltip_text = Language.translate("Level %d: %d / %d PEXP") % [stats.level, stats.experience, needed]
	var reputation: Reputation = GameState.reputation
	var next: Dictionary = reputation.get_next_rank()
	_reputation.value = reputation.get_fraction()
	_reputation_fill.bg_color = COLOR_LOCKED if reputation.is_next_locked() else COLOR_REPUTATION
	if next.is_empty():
		_reputation.tooltip_text = Language.translate("Ruf: Rang %s (höchster)") % reputation.get_rank_id()
	else:
		_reputation.tooltip_text = Language.translate("Ruf: Rang %s, %d / %d bis %s%s") % [reputation.get_rank_id(), reputation.points,
				int(next.get("from", 0)), next.get("id", ""), Language.translate(" (noch gesperrt)") if reputation.is_next_locked() else ""]


## Right above the action bar, as wide as it (minus INSET), scaled like it. The HUD calls this
## again when the UI scale changes (scaling doesn't emit item_rect_changed). The action bar is
## scaled around its bottom middle (UiScale), so its real place on screen is its visual rect.
func place() -> void:
	visible = anchor_control.visible
	var bar_scale: Vector2 = anchor_control.scale
	scale = bar_scale
	pivot_offset = Vector2.ZERO
	size = Vector2(anchor_control.size.x - INSET * 2.0, BAR_HEIGHT * 2.0 + GAP)
	position = UiScale.get_visual_rect(anchor_control).position + Vector2(INSET, -size.y - GAP) * bar_scale


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BACK
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	add_child(bar)
	return bar
