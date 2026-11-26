class_name HardBoulder
extends StaticBody2D
## A boulder that blocks a way for good until the player breaks it (e.g. in front of the gate of
## the goblin castle). Like an ore rock (stand next to it, press or hold E), but only a pickaxe with
## at least `min_pickaxe_damage` bites into it (6 = bronze); with a weaker one there is only a
## message. Broken, it sets its story `flag` and never comes back.

## Story flag set when it breaks; a boulder whose flag is set is gone when the scene loads.
@export var flag: String = ""
@export var max_health: int = 40
## Mining damage the pickaxe itself needs (PlayerStats.get_pickaxe_damage, bronze head = 6).
@export var min_pickaxe_damage: int = 6
@export var too_weak_text: String = "Der Fels ist steinhart. Deine Spitzhacke prallt ab. Dafür brauchst du mindestens eine Bronzespitzhacke."
## Boulders that belong together (their flags): once all of them are broken, `group_done_flag`
## is set too (e.g. the way to the castle gate is free).
@export var group_flags: PackedStringArray = []
@export var group_done_flag: String = ""

const COLOR_HIT_FLASH: Color = Color(1.8, 1.8, 1.8)
## Loaded by path, so the rock still works while the editor has not registered the class yet.
const HitChipsScript: GDScript = preload("res://scenes/world/objects/hit_chips.gd")

var _health: int = 0
var _player: Player
## So the message does not repeat every frame while E is held.
var _warned: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _health_bar: Control = $HealthBar
@onready var _health_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	if not flag.is_empty() and GameState.story.has_flag(flag):
		queue_free()
		return
	_health = max_health
	_health_bar.hide()
	add_to_group(MobileUi.TAP_HOLD_GROUP)


func _process(_delta: float) -> void:
	if not _player:
		return
	if not Input.is_action_pressed("interact"):
		_warned = false
		return
	if GameState.player_stats.get_pickaxe_damage() < min_pickaxe_damage:
		if not _warned:
			_warned = true
			GameState.show_message(too_weak_text)
		return
	if _player.try_mine(global_position, true):
		get_tree().create_timer(_player.get_swing_hit_delay(), false).timeout.connect(
			_take_hit.bind(GameState.player_stats.get_mining_damage()))


func _take_hit(damage: int) -> void:
	_health = maxi(_health - damage, 0)
	AudioManager.play_sound("pickaxe_hit" if _health > 0 else "rock_break", randf_range(0.85, 0.95))
	_health_bar.show()
	_health_fill.size.x = _health_bar.size.x * _health / max_health
	_sprite.modulate = COLOR_HIT_FLASH
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	HitChipsScript.spawn(self, _sprite, Color(0.55, 0.5, 0.48))
	if _health == 0:
		GameState.player_stats.add_experience(GameState.player_stats.experience_per_rock * 3)
		if not flag.is_empty():
			GameState.story.set_flag(flag)
		if not group_done_flag.is_empty() and GameState.story.has_flags(Array(group_flags)):
			GameState.story.set_flag(group_done_flag)
		queue_free()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null


## Phone: a tap on this works like holding E while the player stands in reach (MobileUi).
func wants_touch() -> bool:
	return _player != null
