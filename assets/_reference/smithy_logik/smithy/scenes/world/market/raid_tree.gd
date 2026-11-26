class_name RaidTree
extends Node2D
## The raid on the market (chapter 10) at the Tree of Life: the Lich stands at the tree with its
## hand in the bark, green life flows out of the tree into its hand (flag `drain_flag`), then it
## pulls out the glowing heart of the tree (the holy earth crystal: one pull with its arm, then it
## holds it) and the tree withers in a few seconds: it shakes,
## loses its leaves and turns old and grey step by step (`stage_textures`), the fireflies and its
## light go out (flag `wither_flag`); then it fights Bruno, casting again and again (`fight_flag`).
## The tree stays withered until the player brings the holy earth crystal back after the story
## (TreeBloomCutscene: restore() plays the stages backwards, flag `restore_flag`); the Lich and the
## heart are there from `raid_flag` until `over_flag`. With the holy poison crystal the player can
## take the light again (rot(): the stages forwards, a sickly tint, flag `rot_flag`): a rotten tree.
## Loading the scene after the withering shows the end state right away (no animation).
## Cut scene beats of the dialogue (cutscene:<id>): lich_turns (it turns to the player, its eyes
## flare), lich_fireball (a fireball grows between its fingers), bruno_shields (Bruno throws himself
## in front of the player, the fireball hits him in the chest, the player falls).

@export var tree_sprite: Sprite2D
@export var fireflies: CanvasItem
@export var tree_light: NightLight
## Pictures from healthy to dead; the last one stays.
@export var stage_textures: Array[Texture2D] = []
@export var raid_flag: String = "raid_started"
@export var drain_flag: String = "tree_drain_start"
@export var wither_flag: String = "tree_withered"
@export var over_flag: String = "raid_over"
## From this flag Bruno fights the Lich: it casts again and again (the heart hovers above its hand).
@export var fight_flag: String = "reached_raid_rescue"
## From this flag the tree is healthy again (the earth crystal is back in its trunk).
@export var restore_flag: String = "tree_of_life_restored"
## From this flag the tree is rotten (withered picture with ROT_TINT), until restore_flag again.
@export var rot_flag: String = "tree_of_life_rotten"

## Seconds per withering stage.
const STAGE_TIME: float = 0.55
const SHAKE_PIXELS: float = 1.5
## Where the Lich's hand is, relative to its feet (lich_cast.png, facing left).
const HAND_OFFSET := Vector2(-15, -22)
const CAST_FPS: float = 6.0
## Cast frames while the hand is in the tree (arm stretched out).
const HOLD_FRAMES: Array[int] = [2, 3, 4, 3]
const LICH_ROW_LEFT: int = 1
const LICH_FRAMES: int = 6
## Cast frames of the pull: arm in the trunk, drawn back, at the body; then it holds it up (frame 3).
const PULL_FRAMES: Array[int] = [4, 3, 2]
const PULL_TIME: float = 0.8
## The heart is the holy earth crystal (animated item icon, 24x24 like in a slot).
const HEART_ITEM: String = "holy_earth_crystal"
## Colour of the rotten tree (poison crystal).
const ROT_TINT: Color = Color(0.7, 0.82, 0.5)

var _withering: bool = false
var _withered: bool = false
## true while restore() runs or waits to run (the flag alone must not jump to the end picture).
var _restoring: bool = false
var _rotting: bool = false
var _rotten: bool = false
var _healthy_texture: Texture2D
var _light_energy: float = 0.0
var _time: float = 0.0
var _tree_offset: Vector2
var _pulling: bool = false
var _fx: WorldVfx

@onready var _lich: Sprite2D = $Lich
@onready var _heart: Sprite2D = $Heart
@onready var _heart_light: PointLight2D = $Heart/Light
@onready var _drain: CPUParticles2D = $Drain
@onready var _leaves: CPUParticles2D = $Leaves


func _ready() -> void:
	_tree_offset = tree_sprite.offset if tree_sprite else Vector2.ZERO
	_healthy_texture = tree_sprite.texture if tree_sprite else null
	_light_energy = tree_light.night_energy if tree_light else 0.0
	if ContentDB.has_item(HEART_ITEM):
		_heart.texture = ContentDB.item(HEART_ITEM).icon
	_heart.visible = false
	_drain.emitting = false
	_leaves.emitting = false
	GameState.story.changed.connect(_update)
	Events.cutscene_requested.connect(_on_cutscene)
	_fx = WorldVfx.new()
	add_child(_fx)
	if GameState.story.has_flag(restore_flag):
		_show_restored()
	elif GameState.story.has_flag(rot_flag):
		_show_rotten()
	elif GameState.story.has_flag(wither_flag):
		_show_withered()
	_update()


func _update() -> void:
	var story: Story = GameState.story
	var raid: bool = story.has_flag(raid_flag) and not story.has_flag(over_flag)
	_lich.visible = raid
	_drain.emitting = raid and story.has_flag(drain_flag) and not story.has_flag(wither_flag)
	if raid and story.has_flag(wither_flag) and not _withered and not _withering:
		_wither()
	_heart.visible = raid and story.has_flag(wither_flag)
	if story.has_flag(restore_flag) and _withered and not _restoring and not _rotting:
		_show_restored()
	elif story.has_flag(rot_flag) and not _withered and not _rotting and not _restoring:
		_show_rotten()


func _process(delta: float) -> void:
	_time += delta
	if not _lich.visible or _pulling:
		return
	var story: Story = GameState.story
	var frame: int = 0
	if story.has_flag(drain_flag) and not story.has_flag(wither_flag):
		frame = HOLD_FRAMES[int(_time * CAST_FPS) % HOLD_FRAMES.size()]
	elif story.has_flag(fight_flag):
		frame = int(_time * CAST_FPS) % LICH_FRAMES
	elif story.has_flag(wither_flag):
		frame = 3  # holds the heart up
	_lich.frame = LICH_ROW_LEFT * LICH_FRAMES + frame
	if _heart.visible and not _withering:
		_heart.position = _lich.position + HAND_OFFSET + Vector2(0, sin(_time * 3.0) * 1.5)
		_heart_light.energy = 1.2 + sin(_time * 5.0) * 0.3


## The Lich pulls the heart out of the trunk once (it flies into its hand), then the tree withers
## stage by stage.
func _wither() -> void:
	_withering = true
	_pulling = true
	var pull := create_tween()
	for frame: int in PULL_FRAMES:
		pull.tween_callback(func() -> void: _lich.frame = LICH_ROW_LEFT * LICH_FRAMES + frame)
		pull.tween_interval(PULL_TIME / PULL_FRAMES.size())
	pull.tween_callback(func() -> void: _pulling = false)
	_heart.visible = true
	_heart.global_position = tree_sprite.global_position + Vector2(0, -26) if tree_sprite else global_position
	_heart_light.energy = 3.0
	var fly := create_tween()
	fly.tween_property(_heart, "position", _lich.position + HAND_OFFSET, PULL_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fly.finished
	_leaves.emitting = true
	var fade := create_tween().set_parallel()
	if fireflies:
		fade.tween_property(fireflies, "modulate:a", 0.0, STAGE_TIME * stage_textures.size())
	if tree_light:
		fade.tween_property(tree_light, "night_energy", 0.0, STAGE_TIME * stage_textures.size())
	for texture in stage_textures:
		if tree_sprite:
			tree_sprite.texture = texture
		var shake_end: float = _time + STAGE_TIME
		while _time < shake_end:
			if tree_sprite:
				tree_sprite.offset = _tree_offset + Vector2(randf_range(-SHAKE_PIXELS, SHAKE_PIXELS), 0).round()
			await get_tree().process_frame
	_leaves.emitting = false
	_show_withered()
	_withering = false


## End state: dead tree, no fireflies, no light.
func _show_withered() -> void:
	_withered = true
	if tree_sprite:
		tree_sprite.offset = _tree_offset
		if not stage_textures.is_empty():
			tree_sprite.texture = stage_textures.back()
	if fireflies:
		fireflies.visible = false
	if tree_light:
		tree_light.night_energy = 0.0


## Where the heart sits in the trunk (global), e.g. where the earth crystal flies back to.
func get_heart_point() -> Vector2:
	return tree_sprite.global_position + Vector2(0, -26) if tree_sprite else global_position


## The tree comes back to life after `delay` seconds: it shakes and goes through the withering
## pictures backwards to its healthy picture, the fireflies and its light come back. Awaitable.
func restore(delay: float = 0.0) -> void:
	if _restoring or not _withered:
		return
	_restoring = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_inside_tree():
			return
	var stages: Array[Texture2D] = stage_textures.duplicate()
	stages.reverse()
	stages.pop_front()  # the dead picture is showing already
	if _healthy_texture:
		stages.append(_healthy_texture)
	var total: float = STAGE_TIME * stages.size()
	if fireflies:
		fireflies.visible = true
		fireflies.modulate.a = 0.0
	var fade := create_tween().set_parallel()
	if fireflies:
		fade.tween_property(fireflies, "modulate:a", 1.0, total)
	if tree_light:
		fade.tween_property(tree_light, "night_energy", _light_energy, total)
	if tree_sprite:
		fade.tween_property(tree_sprite, "modulate", Color.WHITE, total)
	for texture in stages:
		if tree_sprite:
			tree_sprite.texture = texture
		var shake_end: float = _time + STAGE_TIME
		while _time < shake_end:
			if tree_sprite:
				tree_sprite.offset = _tree_offset + Vector2(randf_range(-SHAKE_PIXELS, SHAKE_PIXELS), 0).round()
			await get_tree().process_frame
			if not is_inside_tree():
				return
	_show_restored()
	_restoring = false


## true once the tree is healthy again (for tests).
func is_restored() -> bool:
	return not _withered and not _restoring


## The poison crystal takes the light again after `delay` seconds: the tree shakes, loses its
## leaves and goes through the withering pictures to the dead one, turning sickly green; the
## fireflies and its light go out. Awaitable.
func rot(delay: float = 0.0) -> void:
	if _rotting or _withered:
		return
	_rotting = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
		if not is_inside_tree():
			return
	var total: float = STAGE_TIME * stage_textures.size()
	_leaves.emitting = true
	var fade := create_tween().set_parallel()
	if fireflies:
		fade.tween_property(fireflies, "modulate:a", 0.0, total)
	if tree_light:
		fade.tween_property(tree_light, "night_energy", 0.0, total)
	if tree_sprite:
		fade.tween_property(tree_sprite, "modulate", ROT_TINT, total)
	for texture in stage_textures:
		if tree_sprite:
			tree_sprite.texture = texture
		var shake_end: float = _time + STAGE_TIME
		while _time < shake_end:
			if tree_sprite:
				tree_sprite.offset = _tree_offset + Vector2(randf_range(-SHAKE_PIXELS, SHAKE_PIXELS), 0).round()
			await get_tree().process_frame
			if not is_inside_tree():
				return
	_leaves.emitting = false
	_show_rotten()
	_rotting = false


## true once the tree is rotten (for tests).
func is_rotten() -> bool:
	return _rotten and not _rotting


## End state after rot(): dead picture in a sickly tint, no fireflies, no light.
func _show_rotten() -> void:
	_show_withered()
	_rotten = true
	if tree_sprite:
		tree_sprite.modulate = ROT_TINT


## End state after restore(): healthy tree, fireflies and light.
func _show_restored() -> void:
	_withered = false
	_rotten = false
	if tree_sprite:
		tree_sprite.offset = _tree_offset
		tree_sprite.modulate = Color.WHITE
		if _healthy_texture:
			tree_sprite.texture = _healthy_texture
	if fireflies:
		fireflies.visible = true
		fireflies.modulate.a = 1.0
	if tree_light:
		tree_light.night_energy = _light_energy


# --- cut scene beats -------------------------------------------------------------------------

func _on_cutscene(cutscene_id: String) -> void:
	if not _lich.visible:
		return
	match cutscene_id:
		"lich_turns":
			_lich_turns()
		"lich_fireball":
			_lich_fireball()
		"bruno_shields":
			_bruno_shields()


func _hand() -> Vector2:
	return _lich.global_position + HAND_OFFSET


func _lich_turns() -> void:
	var home: Vector2 = _lich.position
	for i in 6:
		_lich.position = home + Vector2(1 if i % 2 == 0 else -1, 0)
		await get_tree().create_timer(0.05, false).timeout
	_lich.position = home
	AudioManager.play_sound("skill_used", 0.5)
	_fx.spawn("light_hit", _lich.global_position + Vector2(-2, -34), Color(0.85, 1.0, 0.9))


func _lich_fireball() -> void:
	_pulling = true
	_lich.frame = LICH_ROW_LEFT * LICH_FRAMES + 2
	for i in 4:
		_fx.spawn("fire_hit", _hand() + Vector2(0, -4), Color(1.0, 0.75 - i * 0.1, 0.3))
		AudioManager.play_sound("skill_used", 0.3 + i * 0.1)
		await get_tree().create_timer(0.3, false).timeout
	_lich.frame = LICH_ROW_LEFT * LICH_FRAMES + 4
	_pulling = false


func _bruno_shields() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null:
		return
	var bruno: Node2D = null
	for node in get_tree().get_nodes_in_group(StoryNpc.GROUP):
		if node is Companion and node.get("npc_id") == "bruno" and (node as Node2D).visible:
			bruno = node
	var toward: Vector2 = (_hand() - player.global_position).normalized()
	var shield_at: Vector2 = player.global_position + toward * 16.0
	if bruno:
		bruno.face(Companion._direction_name(toward))
		var dash := create_tween()
		dash.tween_property(bruno, "global_position", shield_at, 0.25).set_trans(Tween.TRANS_QUAD)
	_fx.spawn("fire_bolt", shield_at + Vector2(0, -12), Color.WHITE, -1.0, _hand(), 0.35)
	AudioManager.play_sound("skill_used", 0.7)
	# the player is knocked to the ground
	var sprite := NpcActing.figure_of(player)
	if sprite:
		var fall := create_tween()
		fall.tween_property(sprite, "rotation", -1.3 if toward.x > 0.0 else 1.3, 0.2)
		fall.tween_interval(0.9)
		fall.tween_property(sprite, "rotation", 0.0, 0.25)
	await get_tree().create_timer(0.35, false).timeout
	_fx.spawn("fire_hit", shield_at + Vector2(0, -12), Color.WHITE)
	AudioManager.play_sound("rock_break", 0.7)
	if bruno and is_instance_valid(bruno):
		_fx.add_loop(bruno, "aura_burn", Color.WHITE)
		var stagger := create_tween()
		stagger.tween_property(bruno, "global_position", shield_at - toward * 3.0, 0.15)
		stagger.tween_property(bruno, "global_position", shield_at, 0.25)
		await get_tree().create_timer(1.6, false).timeout
		if is_instance_valid(bruno):
			_fx.remove_loop(bruno)
