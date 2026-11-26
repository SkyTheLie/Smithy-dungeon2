class_name Zombie
extends CharacterBody2D
## A zombie during the raid on the market: shambles around where it was placed, a step at a time,
## and groans now and then ("Uuuargh" in a speech bubble). Harmless, it only stirs up unrest; a
## hero (RaidFighter) can take it on (`engage`, `hit`). The
## look is the PixelLab resident sheet `resident` (assets/sprites/residents/, player layout).
## Put zombies under a StoryProp so they come and go with the story.

@export var resident: String = "zombie"
## How far (pixels) it may wander from where it was placed.
@export var wander_radius: float = 60.0

const WALK_SPEED: float = 16.0
const STEP_LENGTH := Vector2(10.0, 30.0)
const PAUSE := Vector2(0.6, 2.8)
const GROANS: Array[String] = ["Uuuargh ...", "Hhrrrr ...", "Gnnnaaah!", "Uuuhh ..."]
const GROAN_CHANCE: float = 0.25
const GROAN_TIME: float = 1.8

var _home: Vector2
var _target: Vector2
var _walking: bool = false
var _wait: float = 0.0
var _facing: String = "down"
var _sprite: AnimatedSprite2D
var _bubble: Label
## The hero fighting this zombie (then it stands still and faces it).
var _fighter: Node2D


func _ready() -> void:
	# top-down: everything it bumps into is a wall (grounded mode took the player for a floor and
	# rode along on him)
	motion_mode = MOTION_MODE_FLOATING
	_home = global_position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 6)
	shape.shape = rect
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.position = Vector2(0, -13)
	var path: String = Villager.RESIDENT_DIR + resident + ".png"
	if ResourceLoader.exists(path):
		_sprite.sprite_frames = CharacterBaker.make_frames(load(path))
		# Shambling: the walk plays slower than a villager's.
		for direction in CharacterBaker.DIRECTIONS:
			_sprite.sprite_frames.set_animation_speed("walk_" + direction, 6.0)
		_sprite.play("idle_down")
	add_child(_sprite)
	_bubble = Label.new()
	_bubble.position = Vector2(-30, -52)
	_bubble.size = Vector2(60, 12)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.add_theme_font_size_override("font_size", 9)
	_bubble.add_theme_color_override("font_color", Color(0.75, 0.9, 0.7))
	_bubble.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	_bubble.add_theme_constant_override("outline_size", 3)
	_bubble.z_index = 3
	_bubble.hide()
	add_child(_bubble)
	_wait = randf_range(0.0, PAUSE.y)


## A hero takes this zombie on (RaidFighter): it stops wandering and turns to the fighter.
func engage(fighter: Node2D) -> void:
	_fighter = fighter
	_walking = false
	velocity = Vector2.ZERO
	_facing = "left" if fighter.global_position.x < global_position.x else "right"
	_sprite.play("idle_" + _facing)


## Struck by the fighter: flashes and stumbles back a little, now and then it groans.
func hit(direction: Vector2) -> void:
	var tween := create_tween()
	_sprite.modulate = Color(1.6, 1.3, 1.3)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	var back := create_tween()
	back.tween_property(_sprite, "position", Vector2(0, -13) + direction * 3.0, 0.06)
	back.tween_property(_sprite, "position", Vector2(0, -13), 0.2)
	if randf() < 0.15 and not _bubble.visible:
		_groan()


func _physics_process(delta: float) -> void:
	if not is_visible_in_tree() or _fighter:
		return
	if not _walking:
		_wait -= delta
		if _wait <= 0.0:
			_start_step()
		return
	var to_target: Vector2 = _target - global_position
	velocity = to_target.normalized() * WALK_SPEED
	var before: Vector2 = global_position
	move_and_slide()
	if to_target.length() < 2.0 or global_position.distance_to(before) < 0.05:
		velocity = Vector2.ZERO
		_walking = false
		_wait = randf_range(PAUSE.x, PAUSE.y)
		_sprite.play("idle_" + _facing)
		if randf() < GROAN_CHANCE:
			_groan()


func _start_step() -> void:
	var direction: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
	if global_position.distance_to(_home) > wander_radius:
		direction = Companion._direction_vector(_home - global_position)
	_target = global_position + direction * randf_range(STEP_LENGTH.x, STEP_LENGTH.y)
	_facing = Companion._direction_name(direction)
	_walking = true
	_sprite.play("walk_" + _facing)


func _groan() -> void:
	_bubble.text = GROANS.pick_random()
	_bubble.show()
	await get_tree().create_timer(GROAN_TIME, false).timeout
	_bubble.hide()
