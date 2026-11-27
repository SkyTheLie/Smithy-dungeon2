class_name Portal
extends Node3D
## After the boss of the last floor of a dungeon with an end boss (dungeons.json end_boss): rises
## out of the floor of the boss room instead of the trapdoor (data/boss_altar.json portal,
## portal_light). Dungeon checks is_open() and the distance and takes the player to the
## Boss-Altar when they walk into it.

const HEIGHT: float = 3.2
const RISE_TIME: float = 1.6

var _sprite: Sprite3D
var _open: bool = false


func _ready() -> void:
	var settings: Dictionary = Content.get_file("boss_altar")
	_sprite = Fx.billboard(load(String(settings.get("portal", ""))) as Texture2D, HEIGHT)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.position.y = -HEIGHT / 2.0
	add_child(_sprite)
	var rgb: Array = settings.get("portal_light", [0.9, 0.25, 0.15])
	var glow := OmniLight3D.new()
	glow.light_color = Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
	glow.light_energy = 0.0
	glow.omni_range = 5.0
	glow.position.y = 1.2
	add_child(glow)
	AudioManager.play_sound("portal", 0.7)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "position:y", HEIGHT / 2.0, RISE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "light_energy", 1.4, RISE_TIME)
	tween.chain().tween_callback(func() -> void: _open = true)


## true once it stands (then walking into it leads to the Boss-Altar).
func is_open() -> bool:
	return _open
