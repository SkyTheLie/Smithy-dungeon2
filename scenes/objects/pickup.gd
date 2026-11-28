class_name Pickup
extends Node3D
## Something lying on the floor: a heart or loot for the bag ("loot": bombs and keys are loot too,
## data/loot.json materials, setup_loot; also gold the player dropped from the bag). There are no
## coins in the dungeon. Walking over it picks it up (a heart only if the player is hurt, loot
## only if there is room in the bag). Pops out of the floor when it appears.
## Loot the player dropped from the bag (Tab) waits until the player walked away once, so it is
## not picked up again at once.

## Walked over loot while the bag is full (once per approach).
signal bag_full

const KINDS: Dictionary[String, String] = {
	"heart": "res://assets/sprites/items/arena_heart.png",
	"bomb": "res://assets/sprites/skills/smoke_bomb.png",
	"key": "res://assets/sprites/items/smithy_key.png",
}
const LOOT: String = "loot"
const PICK_DISTANCE: float = 0.8
## Dropped loot can be taken again after the player was this far away.
const LEAVE_DISTANCE: float = 1.6
const HEIGHT: float = 0.55
const LOOT_HEIGHT: float = 0.45

var kind: String = "heart"
## Only for "loot": which material and how many.
var material_id: String = ""
var amount: int = 1
var run: RunState
var player: Node3D

var _sprite: Sprite3D
var _time: float = 0.0
var _ready_to_take: float = 0.4
var _must_leave: bool = false
var _warned: bool = false


static func icon(kind_name: String) -> Texture2D:
	return load(KINDS.get(kind_name, KINDS["heart"])) as Texture2D


## The picture it shows (for the map); null before it is in the scene.
func map_icon() -> Texture2D:
	return _sprite.texture if _sprite else null


func setup(kind_name: String, run_state: RunState, the_player: Node3D) -> void:
	kind = kind_name
	run = run_state
	player = the_player


## Loot for the bag. `dropped` = the player dropped it (wait until they walked away).
func setup_loot(id: String, count: int, run_state: RunState, the_player: Node3D, dropped: bool = false) -> void:
	setup(LOOT, run_state, the_player)
	material_id = id
	amount = maxi(1, count)
	_must_leave = dropped


func _ready() -> void:
	var texture: Texture2D = icon(kind)
	var height: float = HEIGHT
	if kind == LOOT:
		texture = load(String(Content.material(material_id).get("icon", KINDS["heart"]))) as Texture2D
		height = LOOT_HEIGHT
	_sprite = Fx.billboard(texture, height)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(_sprite)
	_sprite.position.y = 1.0
	var pop := create_tween()
	pop.tween_property(_sprite, "position:y", height / 2.0 + 0.05, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	_ready_to_take -= delta
	if player == null or run == null or run.is_dead():
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length() > LEAVE_DISTANCE:
		_must_leave = false
		_warned = false
	if _must_leave or _ready_to_take > 0.0:
		return
	# Magnet: pickups fly to the player (not loot that does not fit anyway).
	if run.stats.has("magnet") and not _warned:
		var effects: Dictionary = Content.player().get("effects", {})
		if offset.length() < float(effects.get("magnet_range", 4.0)):
			global_position += offset.normalized() * minf(offset.length(), float(effects.get("magnet_speed", 7.0)) * delta)
	if offset.length() < PICK_DISTANCE and _take():
		Fx.puff(get_parent() as Node3D, global_position + Vector3(0, 0.3, 0), "spark", 0.3)
		queue_free()


## Gives the thing to the player; false if it cannot be taken (full life, full bag).
func _take() -> bool:
	match kind:
		"heart":
			if not run.heal(run.heart_value()):
				return false
		LOOT:
			var left: int = run.add_coins(amount) if material_id == Bag.GOLD else run.bag.add(material_id, amount)
			if left < amount:
				run.loot_picked.emit(material_id, amount - left)
				run.note_loot(material_id)
			if left > 0:
				if left < amount:
					AudioManager.play_sound("pickup")
				amount = left
				if not _warned:
					_warned = true
					bag_full.emit()
				return false
			if material_id == Bag.GOLD:
				AudioManager.play_sound("coin")
				return true
	AudioManager.play_sound("pickup")
	return true
