class_name ArenaOverlay
extends CanvasLayer
## Screen of the ring (ArenaFightStage), above the battle window: the two boards "Held" (top left)
## and "Gegner" (top right) with the fighters' equipment (ArenaFighterPanel, item tooltips on
## hover), the "Ausrüstung" button on the right that shows or hides them at any time (also during
## the fight), and the announcement in a box at the bottom ("Halbfinale! A gegen B!"), which stays
## until the round is over.

@onready var _boards: Array[ArenaFighterPanel] = [%HeroBoard, %RivalBoard]
@onready var _gear_button: Button = %GearButton
@onready var _banner: PanelContainer = %Banner
@onready var _banner_label: Label = %BannerLabel


func _ready() -> void:
	_gear_button.toggled.connect(_on_gear_toggled)


## Fills both boards, shows them and the button.
func show_fighters(hero: Hero, rival: Hero) -> void:
	_boards[0].show_hero("Held", hero)
	_boards[1].show_hero("Gegner", rival)
	_gear_button.show()
	set_boards_visible(true)


## Shows or hides both boards (the button follows).
func set_boards_visible(on: bool) -> void:
	_gear_button.set_pressed_no_signal(on)
	_on_gear_toggled(on)


func are_boards_visible() -> bool:
	return _boards[0].visible


## The line at the bottom (already translated); stays until hide_announcement().
func announce(text: String) -> void:
	_banner_label.text = text
	_banner.show()


func hide_announcement() -> void:
	_banner.hide()


func is_announcing() -> bool:
	return _banner.visible


## Everything off (after the round: the celebration and the result window take over).
func hide_all() -> void:
	set_boards_visible(false)
	_gear_button.hide()
	hide_announcement()


func _on_gear_toggled(on: bool) -> void:
	for board in _boards:
		board.visible = on
