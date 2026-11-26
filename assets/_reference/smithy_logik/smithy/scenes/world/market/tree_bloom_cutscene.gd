class_name TreeBloomCutscene
extends StoryCutscene
## A holy crystal at the Tree of Life after the story (the tree's StoryNpc TreeOfLifeTalk on the
## market). The earth crystal heals the withered tree (dialogue "tree_of_life_heal"), the poison
## crystal takes its light again and leaves a rotten tree (dialogue "tree_of_life_rot"):
## - tree_<crystal>_stirs: the crystal stirs in the player's bag, light pulses at his side
## - tree_<crystal>_flies: it jumps out of the bag, rises and floats to the trunk (the view follows)
## - tree_bloom / tree_rot: it sinks into the bark, light in the crystal's colour floods the whole
##   picture, the tree changes under it (RaidTree.restore / RaidTree.rot), the light fades
## - tree_<crystal>_returns: the crystal comes out of the bark again, floats back to the player and
##   slips into his bag; the view goes back to the player
## <crystal> is "crystal" (earth) or "poison". The crystal stays in the inventory the whole time;
## the dialogue sets the flags, this script only shows it.

@export var raid_tree: NodePath

const LIGHT_TEXTURE: String = "res://scenes/world/objects/night_light_texture.tres"
## Item and colours per crystal: [item, light colour, colour of the whole picture].
const EARTH: Array = ["holy_earth_crystal", Color(0.55, 1.0, 0.5), Color(1.0, 0.85, 0.3)]
const POISON: Array = ["holy_poison_crystal", Color(0.75, 0.4, 1.0), Color(0.45, 0.75, 0.2)]
## Where the bag hangs, from the player's feet.
const BAG_OFFSET: Vector2 = Vector2(5, -10)
const RISE: Vector2 = Vector2(0, -26)
const PULSES: int = 3
const PULSE_TIME: float = 0.4
const FLY_TIME: float = 1.1
const SINK_TIME: float = 0.5
const TINT_IN: float = 0.8
const TINT_ALPHA: float = 0.7
const TINT_OUT: float = 1.4

## The flying crystal (while it flies to the trunk and back).
var _crystal: Sprite2D


func _ready() -> void:
	super()


func _play_beat(id: String) -> bool:
	match id:
		"tree_crystal_stirs":
			_stirs(EARTH)
		"tree_crystal_flies":
			_flies(EARTH)
		"tree_bloom":
			_change(EARTH)
		"tree_crystal_returns":
			_returns(EARTH)
		"tree_poison_stirs":
			_stirs(POISON)
		"tree_poison_flies":
			_flies(POISON)
		"tree_rot":
			_change(POISON)
		"tree_poison_returns":
			_returns(POISON)
		_:
			return false
	return true


func _tree() -> RaidTree:
	return get_node_or_null(raid_tree) as RaidTree


func _heart() -> Vector2:
	var tree: RaidTree = _tree()
	return tree.get_heart_point() if tree else global_position


func _bag() -> Vector2:
	var body: Node2D = player()
	return body.global_position + BAG_OFFSET if body else global_position


func _stirs(crystal: Array) -> void:
	face_player("up")
	for i in PULSES:
		fx.spawn("glow", _bag(), crystal[1])
		AudioManager.play_sound("skill_used", 0.3 + i * 0.15)
		var sprite: Sprite2D = figure_of(player())
		if sprite:
			var twitch := create_tween()
			twitch.tween_property(sprite, "position:x", sprite.position.x + 1.0, 0.05)
			twitch.tween_property(sprite, "position:x", sprite.position.x, 0.05)
		if not await wait(PULSE_TIME):
			return


## The glowing crystal sprite at `at` (global), small at first.
func _make_crystal(crystal: Array, at: Vector2) -> void:
	_drop_crystal()
	_crystal = Sprite2D.new()
	if ContentDB.has_item(crystal[0]):
		_crystal.texture = ContentDB.item(crystal[0]).icon
	_crystal.z_index = 3
	_crystal.z_as_relative = false
	var light := PointLight2D.new()
	light.texture = load(LIGHT_TEXTURE)
	light.texture_scale = 0.8
	light.color = crystal[1]
	light.energy = 1.4
	_crystal.add_child(light)
	add_child(_crystal)
	_crystal.global_position = at
	_crystal.scale = Vector2(0.3, 0.3)


func _flies(crystal: Array) -> void:
	var start: Vector2 = _bag()
	_make_crystal(crystal, start)
	fx.spawn("glow", start, crystal[1])
	AudioManager.play_sound("skill_used", 0.8)
	var pop := create_tween().set_parallel()
	pop.tween_property(_crystal, "global_position", start + RISE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_crystal, "scale", Vector2.ONE, 0.45)
	await pop.finished
	if not is_inside_tree():
		return
	var target: Vector2 = _heart()
	pan_camera(target, FLY_TIME)
	var fly := create_tween()
	fly.tween_property(_crystal, "global_position", target, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var left: float = FLY_TIME
	while left > 0.0 and is_inside_tree() and is_instance_valid(_crystal):
		fx.spawn("glow", _crystal.global_position, crystal[1])
		if not await wait(0.2):
			return
		left -= 0.2


## The crystal sinks into the trunk, the whole picture takes its colour and the tree changes under
## it: the earth crystal heals it, the poison crystal lets it rot.
func _change(crystal: Array) -> void:
	var tree: RaidTree = _tree()
	var heart: Vector2 = _heart()
	var healing: bool = crystal == EARTH
	if tree:
		# under the coloured light: the tree starts to change once the light is up
		if healing:
			tree.restore(SINK_TIME + TINT_IN)
		else:
			tree.rot(SINK_TIME + TINT_IN)
	pan_camera(heart, 0.4)
	if _crystal and is_instance_valid(_crystal):
		_crystal.global_position = heart
		var sink := create_tween().set_parallel()
		sink.tween_property(_crystal, "scale", Vector2(0.2, 0.2), SINK_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sink.tween_property(_crystal, "global_position", heart + Vector2(0, 4), SINK_TIME)
		await sink.finished
		if not is_inside_tree():
			return
	_drop_crystal()
	var tint_color: Color = crystal[2]
	flash(Color(1, 1, 0.85, 0.9) if healing else Color(tint_color, 0.9), 0.5)
	fx.spawn("light_hit", heart, tint_color)
	AudioManager.play_sound("skill_used", 1.0 if healing else 0.5)
	var tint := world_tint(Color(tint_color, 0.0))
	var rise := create_tween()
	rise.tween_property(tint, "color:a", TINT_ALPHA, TINT_IN)
	shake(TINT_IN, 1.5)
	await rise.finished
	if not is_inside_tree():
		return
	# while the tree changes: life rises around it, or poison
	for i in 7:
		fx.spawn("heal" if healing else "debuff", heart + Vector2(randf_range(-45, 45), randf_range(-10, 40)), crystal[1])
		if not await wait(0.4):
			return
	var fade := create_tween()
	fade.tween_property(tint, "color:a", 0.0, TINT_OUT)
	fade.tween_callback(tint.queue_free)
	await fade.finished


func _returns(crystal: Array) -> void:
	var heart: Vector2 = _heart()
	_make_crystal(crystal, heart)
	fx.spawn("glow", heart, crystal[1])
	AudioManager.play_sound("skill_used", 0.6)
	var out := create_tween().set_parallel()
	out.tween_property(_crystal, "global_position", heart + RISE * 0.5, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	out.tween_property(_crystal, "scale", Vector2.ONE, 0.5)
	await out.finished
	if not await wait(0.3):
		return
	camera_home(FLY_TIME)
	var fly := create_tween()
	fly.tween_property(_crystal, "global_position", _bag() + RISE, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fly.finished
	if not is_inside_tree() or not is_instance_valid(_crystal):
		return
	var into := create_tween().set_parallel()
	into.tween_property(_crystal, "global_position", _bag(), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	into.tween_property(_crystal, "scale", Vector2(0.2, 0.2), 0.35)
	await into.finished
	if not is_inside_tree():
		return
	_drop_crystal()
	fx.spawn("glow", _bag(), crystal[1])
	AudioManager.play_sound("item_reveal")


func _drop_crystal() -> void:
	if _crystal and is_instance_valid(_crystal):
		_crystal.queue_free()
	_crystal = null
