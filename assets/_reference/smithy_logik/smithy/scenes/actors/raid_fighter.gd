class_name RaidFighter
extends Node2D
## A fighter during the raid on the market: from `start_flag` on it walks to its `target` (a Zombie
## or the Lich) and fights it there: it lunges at it again and again, a hit makes a zombie flinch.
## Hedwig and the heroes come out of the guild, one zombie each; Bruno leaves the player
## (`start_from` = his Companion, he starts where it stands) and goes for the Lich.
## With an `npc_id` it can speak in dialogues of the scene (portrait like a StoryNpc).

@export var npc_id: String = ""
## The look: a PixelLab resident (`resident`), a hero template (`hero`) or an Appearance.
@export var resident: String = ""
@export var hero: Hero
@export var appearance: Appearance
@export var target: Node2D
## Story flag from which it comes and fights.
@export var start_flag: String = ""
## Story flag from which it is gone.
@export var hidden_when_flag: String = ""
## Takes over the place of this node when it starts (e.g. Bruno's Companion).
@export var start_from: Node2D
@export var walk_speed: float = 95.0
## Distance to the target while fighting (left or right of it), more for the big Lich.
@export var fight_distance: float = 16.0

const LUNGE: float = 5.0
const ATTACK_INTERVAL := Vector2(0.5, 0.9)

enum State { WAIT, WALK, FIGHT }

var _state: State = State.WAIT
var _sprite: AnimatedSprite2D
var _facing: String = "down"
var _attack_wait: float = 0.0
var _look: Appearance


func _ready() -> void:
	_look = appearance if appearance else (hero.get_appearance() if hero else null)
	_sprite = AnimatedSprite2D.new()
	_sprite.position = Vector2(0, -13)
	if _get_resident_sheet():
		_sprite.sprite_frames = CharacterBaker.make_frames(_get_resident_sheet())
	elif _look:
		_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(_look))
		_sprite.scale = Vector2.ONE * _look.get_scale()
	add_child(_sprite)
	_sprite.play("idle_down")
	if not npc_id.is_empty():
		add_to_group(StoryNpc.GROUP)
	visible = false
	GameState.story.changed.connect(_update)
	_update()


func get_portrait() -> Texture2D:
	if _get_resident_sheet():
		return CharacterBaker.get_sheet_portrait(_get_resident_sheet())
	return CharacterBaker.get_portrait(_look) if _look else null


func _get_resident_sheet() -> Texture2D:
	var path: String = Villager.RESIDENT_DIR + resident + ".png"
	return load(path) if not resident.is_empty() and ResourceLoader.exists(path) else null


func _update() -> void:
	var story: Story = GameState.story
	var gone: bool = not hidden_when_flag.is_empty() and story.has_flag(hidden_when_flag)
	if gone:
		visible = false
		_state = State.WAIT
		return
	if _state == State.WAIT and story.has_flag(start_flag):
		if start_from:
			global_position = start_from.global_position
		visible = true
		_state = State.WALK


func _process(delta: float) -> void:
	if _state == State.WAIT or target == null:
		return
	var side: float = signf(global_position.x - target.global_position.x)
	if side == 0.0:
		side = -1.0
	var spot: Vector2 = target.global_position + Vector2(side * fight_distance, 2)
	if _state == State.WALK:
		var offset: Vector2 = spot - global_position
		if offset.length() <= 2.0:
			_start_fight()
			return
		global_position += offset.limit_length(walk_speed * delta)
		_facing = Companion._direction_name(offset)
		_sprite.play("walk_" + _facing)
		return
	# FIGHT: stay at the target and lunge at it now and then.
	global_position = global_position.lerp(spot, minf(1.0, delta * 4.0))
	_attack_wait -= delta
	if _attack_wait <= 0.0:
		_attack_wait = randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)
		_lunge()


func _start_fight() -> void:
	_state = State.FIGHT
	_facing = "left" if target.global_position.x < global_position.x else "right"
	_sprite.play("idle_" + _facing)
	if target.has_method("engage"):
		target.engage(self)


func _lunge() -> void:
	var direction := Vector2(-1 if _facing == "left" else 1, 0)
	var tween := create_tween()
	tween.tween_property(_sprite, "position", Vector2(0, -13) + direction * LUNGE, 0.08)
	tween.tween_callback(func() -> void:
		if target.has_method("hit"):
			target.hit(direction))
	tween.tween_property(_sprite, "position", Vector2(0, -13), 0.15)
