class_name PlayingCard
extends PanelContainer
## One playing card of the den's card games (HigherLowerMenu, PokerMenu): face up shows the rank
## (2 .. 10, face cards as a word) and the suit, face down a dark red back. `small`: a smaller card
## (the poker opponents' hands).

const SUIT_DIR: String = "res://assets/sprites/ui/cards/suit_%d.png"
## Ranks 11 .. 14 as words (translated).
const FACE_NAMES: Dictionary = {11: "Bube", 12: "Dame", 13: "König", 14: "Ass"}
const FACE_COLOUR := Color8(0xf0, 0xe6, 0xd2)
const BACK_COLOUR := Color8(0x8a, 0x24, 0x34)
const BORDER_COLOUR := Color8(0x21, 0x13, 0x1e)
const RED := Color8(0xc8, 0x2c, 0x3a)
const BLACK := Color8(0x2a, 0x22, 0x30)
## Frame of a winning card (poker: who took the pot).
const WIN_COLOUR := Color8(0xff, 0xd0, 0x40)

const SMALL_SIZE := Vector2(28, 38)

## true = smaller card with a smaller rank.
@export var small: bool = false

var _style := StyleBoxFlat.new()
var _suits: Array[Texture2D] = []
var _glowing: bool = false

@onready var _rank: Label = %Rank
@onready var _suit: TextureRect = %Suit


func _ready() -> void:
	for i in GamblingDen.SUITS:
		_suits.append(load(SUIT_DIR % i))
	_style.border_color = BORDER_COLOUR
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(2)
	if small:
		custom_minimum_size = SMALL_SIZE
	add_theme_stylebox_override("panel", _style)
	show_back()


## `card`: {"rank": 2 .. 14, "suit": 0 .. 3} (GamblingDen.draw_card).
func show_card(card: Dictionary) -> void:
	var rank: int = int(card.get("rank", 2))
	var suit: int = int(card.get("suit", 0))
	_style.bg_color = FACE_COLOUR
	_rank.text = Language.translate(FACE_NAMES[rank]) if FACE_NAMES.has(rank) else DamageKinds.format_number(rank)
	_rank.add_theme_color_override("font_color", RED if suit < 2 else BLACK)
	_rank.add_theme_font_size_override("font_size", 11 if FACE_NAMES.has(rank) else (16 if small else 22))
	_suit.texture = _suits[suit]
	_suit.visible = true


## Gold frame around the card (true) or the normal thin border (false).
func set_glow(on: bool) -> void:
	_glowing = on
	_style.border_color = WIN_COLOUR if on else BORDER_COLOUR
	_style.set_border_width_all(2 if on else 1)
	_style.set_expand_margin_all(2.0 if on else 0.0)


func is_glowing() -> bool:
	return _glowing


func show_back() -> void:
	_style.bg_color = BACK_COLOUR
	_rank.text = ""
	_suit.visible = false
