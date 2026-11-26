class_name DefensePauseCard
extends Control
## Shown while the forge defense stands still (DefenseGame freezes time): a card in the middle with
## a relic out of a chest (picture, name, tier, what it does, where it went), or only the hint at
## the bottom when a new unit is shown. "Klicken zum Weiterspielen" blinks; the game listens for
## the click (nothing here takes the mouse). Blinking ignores the stopped time.

const BLINK_TIME: float = 0.5

var _blink: Tween = null

@onready var _card: Control = %Card
@onready var _picture: TextureRect = %Picture
@onready var _title: Label = %Title
@onready var _name: Label = %RelicName
@onready var _text: Label = %Text
@onready var _hint: Label = %Hint


func _ready() -> void:
	hide()
	_hint.text = Language.translate("Klicken zum Weiterspielen")


## The relic of an opened chest: picture, name, "Stufe N", what it does, and `where` (in a slot or not).
func show_relic(picture: Texture2D, relic_name: String, tier: int, description: String, where: String) -> void:
	_title.text = Language.translate("Relikt gefunden!")
	_picture.texture = picture
	_name.text = relic_name + "  ·  " + Language.translate("Stufe %s") % DamageKinds.format_number(tier)
	_text.text = description + "\n" + where
	_card.show()
	_open()


## Only the hint (a new unit is shown on the field).
func show_hint() -> void:
	_card.hide()
	_open()


func close() -> void:
	if _blink:
		_blink.kill()
	hide()


func _open() -> void:
	show()
	if _blink:
		_blink.kill()
	_hint.modulate.a = 1.0
	_blink = create_tween().set_loops().set_ignore_time_scale(true)
	_blink.tween_property(_hint, "modulate:a", 0.35, BLINK_TIME)
	_blink.tween_property(_hint, "modulate:a", 1.0, BLINK_TIME)
