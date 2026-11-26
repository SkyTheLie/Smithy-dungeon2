class_name FighterMotion
extends RefCounted
## How one fighter moves on the BattleStage: the current pose (an attack or a spell), being hit
## (knockback, short white flash, then red) and which status effects it had last frame (so the
## stage sees new buffs/debuffs). Only looks: the fight (Combatant, Adventure) never waits for it.
##
## A pose is a set of key frames over its length (time 0-1): the body moves forward/back and
## up/down, the weapon turns around the hand (0° = upright like in the picture, positive = forward).
## Values are for a fighter looking right; for one looking left the stage mirrors them.

## Poses, used in weapon_types.json "attack_anim" and skills.json "anim".
const POSES: Array[String] = ["swing", "thrust", "slam", "shoot", "cast", "lunge"]
## Seconds per pose.
const LENGTH: Dictionary = {"swing": 0.3, "thrust": 0.28, "slam": 0.42, "shoot": 0.55, "cast": 0.4, "lunge": 0.26}
## When (0-1) the hit lands or the shot/spell leaves the hand.
const IMPACT: Dictionary = {"swing": 0.45, "thrust": 0.45, "slam": 0.6, "shoot": 0.62, "cast": 0.5, "lunge": 0.45}
## Key frames [time, pixels forward].
const BODY_X: Dictionary = {
	"swing": [[0.0, 0.0], [0.27, -1.5], [0.45, 6.0], [0.7, 5.0], [1.0, 0.0]],
	"thrust": [[0.0, 0.0], [0.25, -3.0], [0.45, 9.0], [0.6, 9.0], [1.0, 0.0]],
	"slam": [[0.0, 0.0], [0.35, -2.0], [0.6, 5.0], [0.8, 5.0], [1.0, 0.0]],
	"lunge": [[0.0, 0.0], [0.25, -2.0], [0.45, 10.0], [0.6, 10.0], [1.0, 0.0]],
	"shoot": [[0.0, 0.0], [0.62, 0.0], [0.72, -2.0], [1.0, 0.0]],
}
## Key frames [time, pixels up].
const BODY_Y: Dictionary = {
	"slam": [[0.0, 0.0], [0.35, 3.0], [0.6, 0.0], [1.0, 0.0]],
	"lunge": [[0.0, 0.0], [0.25, 0.0], [0.37, 4.0], [0.5, 0.0], [1.0, 0.0]],
	"cast": [[0.0, 0.0], [0.4, 2.0], [0.7, 2.0], [1.0, 0.0]],
}
## Key frames [time, weapon angle in degrees].
const WEAPON_ANGLE: Dictionary = {
	"swing": [[0.0, 0.0], [0.16, -70.0], [0.33, -70.0], [0.45, 100.0], [0.65, 125.0], [1.0, 0.0]],
	"thrust": [[0.0, 0.0], [0.25, 80.0], [0.45, 90.0], [0.75, 90.0], [1.0, 0.0]],
	"slam": [[0.0, 0.0], [0.16, -130.0], [0.33, -130.0], [0.5, 100.0], [0.7, 120.0], [1.0, 0.0]],
	"cast": [[0.0, 0.0], [0.4, -30.0], [0.6, -30.0], [1.0, 0.0]],
}
## Squash and stretch of monster pictures (the stage keeps their feet on the ground): key frames
## [time, width factor]; the height changes the other way (a wider body is flatter). Crouch before
## the jump, stretch while flying forward, land flat.
const SQUASH: Dictionary = {
	"lunge": [[0.0, 1.0], [0.25, 1.12], [0.4, 0.9], [0.55, 1.08], [0.75, 1.0]],
	"slam": [[0.0, 1.0], [0.35, 0.92], [0.6, 1.14], [0.8, 1.0]],
	"cast": [[0.0, 1.0], [0.4, 0.94], [0.55, 1.06], [0.8, 1.0]],
	"shoot": [[0.0, 1.0], [0.4, 0.95], [0.5, 1.05], [0.8, 1.0]],
}
## Width factor when hit (flattened, then back).
const HIT_SQUASH: float = 1.1
## Being hit: seconds of the whole reaction, of the white flash, pixels pushed back.
const HIT_TIME: float = 0.22
const FLASH_TIME: float = 0.06
const KNOCKBACK: float = 3.0
## Starting the same pose again this soon does nothing (an area skill hits several targets).
const RESTART_GAP: float = 0.1

var pose: String = ""
## Status effect ids of the last frame (the stage fills it).
var effect_ids: Dictionary = {}
var _pose_age: float = 0.0
var _hit_age: float = INF


## Seconds from the start of `pose_id` until its hit lands.
static func get_impact_delay(pose_id: String) -> float:
	return LENGTH.get(pose_id, 0.3) * IMPACT.get(pose_id, 0.5)


func start(pose_id: String) -> void:
	if pose_id == pose and _pose_age < RESTART_GAP:
		return
	pose = pose_id
	_pose_age = 0.0


func hit() -> void:
	_hit_age = 0.0


func tick(delta: float) -> void:
	_hit_age += delta
	if pose.is_empty():
		return
	_pose_age += delta
	if _pose_age >= LENGTH.get(pose, 0.3):
		pose = ""


## Pixels to move the body (x forward, y down), whole pixels.
func get_offset() -> Vector2:
	var offset := Vector2.ZERO
	if not pose.is_empty():
		var time: float = _get_time()
		offset.x = _sample(BODY_X.get(pose, []), time)
		offset.y = -_sample(BODY_Y.get(pose, []), time)
	if _hit_age < HIT_TIME:
		offset.x -= KNOCKBACK * (1.0 - _hit_age / HIT_TIME)
	return offset.round()


## Size factor of a monster picture (x wider, y flatter or the other way round), 1 = unchanged.
func get_squash() -> Vector2:
	var width: float = 1.0
	if not pose.is_empty() and SQUASH.has(pose):
		width = _sample(SQUASH[pose], _get_time())
	if _hit_age < HIT_TIME:
		width *= lerpf(HIT_SQUASH, 1.0, _hit_age / HIT_TIME)
	return Vector2(width, 1.0 / width)


## Weapon angle in degrees (0 = upright, positive = turned forward).
## `rest` = how the fighter holds the weapon between attacks; the pose starts and ends there.
func get_weapon_angle(rest: float = 0.0) -> float:
	if pose.is_empty():
		return rest
	var time: float = _get_time()
	return _sample(WEAPON_ANGLE.get(pose, []), time) + rest * pow(2.0 * time - 1.0, 2.0)


## How far the current pose is (0-1); 0 without a pose.
func get_progress() -> float:
	return _get_time() if not pose.is_empty() else 0.0


## 0 = not hit, 1 = white flash, 2 = red (the rest of the hit reaction).
func get_hit_state() -> int:
	if _hit_age < FLASH_TIME:
		return 1
	return 2 if _hit_age < HIT_TIME else 0


func _get_time() -> float:
	return clampf(_pose_age / LENGTH.get(pose, 0.3), 0.0, 1.0)


## Linear between the key frames [[time, value], ...] (0 without key frames).
static func _sample(keys: Array, time: float) -> float:
	if keys.is_empty():
		return 0.0
	for i in range(1, keys.size()):
		if time <= keys[i][0]:
			var span: float = maxf(keys[i][0] - keys[i - 1][0], 0.001)
			return lerpf(keys[i - 1][1], keys[i][1], (time - keys[i - 1][0]) / span)
	return keys[-1][1]
