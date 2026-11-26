class_name ColdFurnace
extends Node
## The casting furnace of the empty smithy is cold (picture `cold_texture`, only ash) until its
## cobweb is gone (`flag`, story step "clean_smithy"). When the flag is set while the player is in
## the room, the fire catches: a few sparks, the opening flickers between cold and lit and a warm
## glow puffs up. Loading a game with the flag shows the lit furnace straight away.

## The furnace station (a Station with a Sprite2D child).
@export var forge_path: NodePath
@export var cold_texture: Texture2D
@export var flag: String = "cobweb_forge"

## Flicker pattern: seconds lit, seconds cold, ... until it stays lit.
const FLICKER: Array[float] = [0.08, 0.18, 0.12, 0.12, 0.2, 0.08, 0.3, 0.05]
const SPARK_COLOR := Color(1.0, 0.62, 0.25)
## Middle of the furnace opening, relative to the station position.
const MOUTH := Vector2(0, -18)

var _sprite: Sprite2D
var _lit_texture: Texture2D
var _cold: bool = false


func _ready() -> void:
	var forge := get_node_or_null(forge_path) as Node2D
	if forge == null:
		return
	_sprite = forge.get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null or cold_texture == null:
		return
	_lit_texture = _sprite.texture
	if GameState.story.has_flag(flag):
		return
	_cold = true
	_sprite.texture = cold_texture
	GameState.story.changed.connect(_on_story_changed)


func is_cold() -> bool:
	return _cold


func _on_story_changed() -> void:
	if _cold and GameState.story.has_flag(flag):
		_cold = false
		GameState.story.changed.disconnect(_on_story_changed)
		_ignite()


func _ignite() -> void:
	var forge := _sprite.get_parent() as Node2D
	var fx := WorldVfx.new()
	forge.get_parent().add_child(fx)
	var mouth: Vector2 = forge.global_position + MOUTH
	fx.spawn("impact", mouth, SPARK_COLOR)
	var lit: bool = true
	for seconds in FLICKER:
		_sprite.texture = _lit_texture if lit else cold_texture
		lit = not lit
		await get_tree().create_timer(seconds, false).timeout
		if not is_instance_valid(_sprite):
			return
	_sprite.texture = _lit_texture
	fx.spawn("glow", mouth, SPARK_COLOR)
	fx.spawn("impact", mouth + Vector2(0, -6), SPARK_COLOR)
	var puff := _sprite.create_tween()
	_sprite.modulate = Color(1.35, 1.15, 0.95)
	puff.tween_property(_sprite, "modulate", Color.WHITE, 0.6)
	await get_tree().create_timer(1.5, false).timeout
	if is_instance_valid(fx):
		fx.queue_free()
