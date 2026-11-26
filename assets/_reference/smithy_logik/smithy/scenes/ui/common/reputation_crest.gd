class_name ReputationCrest
extends Control
## The reputation crest: a shield (assets/sprites/ui/reputation_crest.png, grey) tinted with the
## colour of the rank (economy.json "reputation.ranks.color") and the rank letter on it ("D", "S+").
## Call show_rank after the rank changed.

const SHIELD: Texture2D = preload("res://assets/sprites/ui/reputation_crest.png")
const FONT_SIZE: int = 22
const COLOR_LETTER: Color = Color(1.0, 0.98, 0.92)
const COLOR_OUTLINE: Color = Color(0.13, 0.075, 0.12)
## The letter sits in the upper, wide part of the shield.
const LETTER_CENTER_Y: float = 16.0

var _rank: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = SHIELD.get_size()


func show_rank(rank: Dictionary) -> void:
	_rank = rank
	queue_redraw()


func _draw() -> void:
	draw_texture(SHIELD, Vector2.ZERO, Reputation.get_color(_rank))
	var text: String = String(_rank.get("id", "F"))
	var font: Font = get_theme_default_font()
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var at := Vector2(roundf((SHIELD.get_width() - size.x) / 2.0),
			roundf(LETTER_CENTER_Y - size.y / 2.0 + font.get_ascent(FONT_SIZE)))
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, COLOR_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_LETTER)
