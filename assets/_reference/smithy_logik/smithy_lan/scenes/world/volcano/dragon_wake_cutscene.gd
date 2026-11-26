class_name DragonWakeCutscene
extends Node
## The treasure chamber of the goblin castle. Pitch dark at first: only the fire crystal on top of
## the gold mountain glows. The dragon sleeps buried in the gold (only head and tail show). The
## dialogue lines start each part with the story action "cutscene:<id>"
## (Events.cutscene_requested) and wait for it:
## - treasury_enter: the player walks into the chamber
## - treasury_sneak: the player creeps towards the gold mountain
## - gold_shift: coins slide down the mountain, the ground trembles
## - dragon_eye: green eyes open in the gold
## - dragon_rise: the dragon pushes up out of the gold ("rise"), glows red and lights up the chamber
## - dragon_step: the dragon stomps down from the mountain in front of the player ("walk"), who backs off
## - take_crystal: (after the fight) the player climbs up and takes the crystal
## Once awake (AWAKE_FLAG) he stands breathing ("idle") in front of the mountain when the scene
## loads; beaten (BEATEN_FLAG) he lies there exhausted ("tired").

const AWAKE_FLAG: String = "dragon_challenge"
const BEATEN_FLAG: String = "dragon_defeated"
const CRYSTAL_FLAG: String = "fire_crystal_owned"

## The dragon (moves) and its animations (rise, walk, idle, tired), its glow, the dragon buried
## in the gold with the eyes over it, the crystal and its light.
@export var dragon: Node2D
@export var dragon_sprite: AnimatedSprite2D
@export var dragon_glow: PointLight2D
@export var buried: CanvasItem
@export var eye: CanvasItem
@export var crystal: CanvasItem
@export var crystal_light: PointLight2D
@export var darkness: CanvasModulate
## Where the dragon stands once awake (it sleeps where it is placed in the scene).
@export var front_position: Vector2 = Vector2(0, 40)
## Where the player walks to: into the chamber, sneaking closer, backing off from the dragon.
@export var enter_point: Vector2 = Vector2(0, 150)
@export var sneak_point: Vector2 = Vector2(0, 76)
@export var back_point: Vector2 = Vector2(0, 150)
## The way up the gold mountain to the crystal (around the dragon).
@export var climb_path: PackedVector2Array = PackedVector2Array([Vector2(100, 110), Vector2(50, -60), Vector2(14, -122)])
## The top of the gold mountain (coins slide down from here).
@export var mountain_top: Vector2 = Vector2(0, -140)

const COLOR_DARK: Color = Color(0.1, 0.08, 0.1)
const COLOR_LIT: Color = Color(0.2, 0.13, 0.13)
## Seconds the gold takes to fall off him before he starts to rise.
const SHED_TIME: float = 0.8
const STEP_TIME: float = 2.2
## Stomps (sound and shake) on the way down.
const STEPS: int = 4
const SNEAK_SPEED: float = 22.0
const WALK_SPEED: float = 55.0
const SHAKE: float = 2.0
const COIN_COUNT: int = 14
## Glow after the fight: weaker.
const TIRED_GLOW: float = 0.6

var _glow_energy: float = 1.0


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)
	GameState.story.changed.connect(_on_story_changed)
	_glow_energy = dragon_glow.energy
	var story: Story = GameState.story
	eye.visible = false
	if story.has_flag(AWAKE_FLAG):
		buried.visible = false
		dragon.position = front_position
		darkness.color = COLOR_LIT
		if story.has_flag(BEATEN_FLAG):
			_lie_down()
		else:
			dragon_sprite.play("idle")
	else:
		dragon_sprite.visible = false
		dragon_glow.energy = 0.0
		darkness.color = COLOR_DARK
	if story.has_flag(CRYSTAL_FLAG):
		crystal.visible = false
		crystal_light.enabled = false


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"treasury_enter":
			_walk_player(PackedVector2Array([enter_point]), "up", WALK_SPEED)
		"treasury_sneak":
			_walk_player(PackedVector2Array([sneak_point]), "up", SNEAK_SPEED)
		"gold_shift":
			AudioManager.play_sound("coins", 0.7)
			_slide_coins()
			_shake_camera(1.2, 1.0)
		"dragon_eye":
			eye.visible = true
			eye.modulate.a = 0.0
			create_tween().tween_property(eye, "modulate:a", 1.0, 0.8)
		"dragon_rise":
			_rise()
		"dragon_step":
			_step_down()
		"take_crystal":
			_take_crystal()


## Won the fight while still in the chamber: he sinks down at once.
func _on_story_changed() -> void:
	if GameState.story.has_flag(BEATEN_FLAG) and dragon_sprite.animation != "tired" and dragon_sprite.visible:
		_lie_down()


func _lie_down() -> void:
	dragon_sprite.play("tired")
	dragon_glow.energy = _glow_energy * TIRED_GLOW


func _player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player


func _walk_player(points: PackedVector2Array, facing: String, speed: float) -> void:
	var player: Player = _player()
	if player:
		player.auto_walk(points, facing, speed)


## The gold slides off him (the buried picture fades into the lying dragon), then he rises and
## starts to glow.
func _rise() -> void:
	AudioManager.play_sound("rock_break", 0.5)
	AudioManager.play_sound("coins", 0.6)
	_slide_coins()
	dragon_sprite.animation = "rise"
	dragon_sprite.frame = 0
	dragon_sprite.visible = true
	dragon_sprite.modulate.a = 0.0
	var rise_time: float = SHED_TIME + _get_length("rise")
	_shake_camera(rise_time, SHAKE)
	var shed := create_tween().set_parallel()
	shed.tween_property(buried, "modulate:a", 0.0, SHED_TIME)
	shed.tween_property(dragon_sprite, "modulate:a", 1.0, SHED_TIME)
	shed.tween_property(eye, "modulate:a", 0.0, SHED_TIME)
	var light := create_tween().set_parallel()
	light.tween_property(dragon_glow, "energy", _glow_energy, rise_time)
	light.tween_property(darkness, "color", COLOR_LIT, rise_time)
	await shed.finished
	buried.visible = false
	eye.visible = false
	dragon_sprite.play("rise")
	await dragon_sprite.animation_finished
	dragon_sprite.play("idle")


## Heavy steps down to the front of the mountain; the player backs off.
func _step_down() -> void:
	_walk_player(PackedVector2Array([back_point]), "up", WALK_SPEED * 1.6)
	dragon_sprite.play("walk")
	var start: Vector2 = dragon.position
	for step in STEPS:
		var target: Vector2 = start.lerp(front_position, float(step + 1) / STEPS)
		var tween := create_tween()
		tween.tween_property(dragon, "position", target, STEP_TIME / STEPS)
		await tween.finished
		AudioManager.play_sound("rock_break", 0.4)
		_shake_camera(0.2, SHAKE)
	dragon_sprite.play("idle")


## Up the mountain (around the dragon), the crystal goes into the bag, and down again.
func _take_crystal() -> void:
	var player: Player = _player()
	if player == null:
		return
	var way: PackedVector2Array = climb_path.duplicate()
	player.auto_walk(way, "up", WALK_SPEED)
	await player.auto_walk_finished
	AudioManager.play_sound("item_reveal")
	create_tween().tween_property(crystal, "modulate:a", 0.0, 0.4).finished.connect(crystal.hide)
	create_tween().tween_property(crystal_light, "energy", 0.0, 0.4)
	way.reverse()
	way.append(back_point)
	player.auto_walk(way.slice(1), "up", WALK_SPEED)


## Seconds animation `animation_name` plays once.
func _get_length(animation_name: String) -> float:
	var frames: SpriteFrames = dragon_sprite.sprite_frames
	return frames.get_frame_count(animation_name) / maxf(frames.get_animation_speed(animation_name), 0.1)


## A few coins tumble down both sides of the gold mountain.
func _slide_coins() -> void:
	var parent := crystal.get_parent() as Node2D
	for i in COIN_COUNT:
		var coin := ColorRect.new()
		coin.size = Vector2(2, 2)
		coin.color = Color(0.96, 0.81, 0.29) if i % 2 else Color(0.83, 0.63, 0.16)
		coin.position = mountain_top + Vector2(randf_range(-20, 20), randf_range(0, 20))
		coin.z_index = 5
		parent.add_child(coin)
		var side: float = -1.0 if i % 2 else 1.0
		var target: Vector2 = coin.position + Vector2(side * randf_range(40, 110), randf_range(60, 110))
		var tween := coin.create_tween()
		tween.tween_interval(randf_range(0.0, 0.6))
		tween.tween_property(coin, "position", target, randf_range(0.6, 1.1)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(coin.queue_free)


func _shake_camera(seconds: float, strength: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + seconds
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera):
		camera.offset = home + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home
