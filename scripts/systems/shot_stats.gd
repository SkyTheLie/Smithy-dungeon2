class_name ShotStats
extends RefCounted
## Everything that decides how the player shoots and moves, worked out from the start values
## (data/player.json), the collected items and their synergies (RunState.compute_stats).
## Additive values are summed up, *_mult values multiplied, "spread" takes the largest value.
## "chance" of an item: flag -> probability per shot (e.g. {"freeze": 0.15}); several items with
## the same flag stack (1 - (1-a)(1-b)), luck raises every chance a little (roll()).

const MODE_FIRE: String = "fire"
const MODE_BEAM: String = "beam"
const MODE_BOMB: String = "bomb"
## Sword / axe swing in front of the player (Krieger, melee items). Order: beam > bomb > melee > fire.
const MODE_MELEE: String = "melee"

## Numbers that items may change with "<name>" (add) or "<name>_mult" (multiply).
const NUMBERS: Array[String] = ["damage", "fire_delay", "reach", "shot_speed", "size", "spread",
		"move_speed", "knockback", "bomb_size", "luck", "guard_time", "body"]
## Each point of luck adds this much to every chance (0.1 = +10 %).
const LUCK_PER_POINT: float = 0.04

var damage: float = 1.0
## Seconds between two shots.
var fire_delay: float = 0.42
## Metres a fireball flies before it drops.
var reach: float = 2.5
var shot_speed: float = 9.0
var size: float = 1.0
## Fireballs per shot.
var shots: int = 1
## Degrees between two neighbouring fireballs of one shot.
var spread: float = 7.0
var move_speed: float = 5.0
var knockback: float = 2.0
## Bombs (placed and thrown): radius and damage times this.
var bomb_size: float = 1.0
## More room rewards and enemy drops, chance effects come more often.
var luck: float = 0.0
## Extra seconds of safety after a hit.
var guard_time: float = 0.0
## Size of the player (1 = normal): bigger = easier to hit but sees from higher up; items with
## "body_mult" multiply, so they combine.
var body: float = 1.0
## Fireballs circling the player (Glutmond).
var orbitals: int = 0
## Little sparks following the player that shoot at enemies.
var helpers: int = 0
var mode: String = MODE_FIRE
## Flags that are always on (see data/items.json "_info").
var flags: Dictionary[String, bool] = {}
## Flag -> chance 0..1 (per shot, per hit).
var chances: Dictionary[String, float] = {}
## The player's own traps a shot lays where it ends (items/relics "traps": [{kind, chance}],
## kinds = floors.json hazard_types with "owner": "player"; Dungeon.shot_ended).
var traps: Array[Dictionary] = []


func has(flag: String) -> bool:
	return flags.has(flag)


## Chance of `flag` with luck, 0..1 (1 if the flag is always on).
func chance(flag: String) -> float:
	if flags.has(flag):
		return 1.0
	if not chances.has(flag):
		return 0.0
	return clampf(chances[flag] + luck * LUCK_PER_POINT, 0.0, 1.0)


## true if `flag` happens this time (always-on flags always).
func roll(flag: String) -> bool:
	var value: float = chance(flag)
	return value >= 1.0 or (value > 0.0 and randf() < value)


## The flags for one shot: the fixed ones plus the chance flags that came up.
func roll_flags() -> Dictionary[String, bool]:
	var result: Dictionary[String, bool] = flags.duplicate()
	for flag: String in chances:
		if not result.has(flag) and roll(flag):
			result[flag] = true
	return result


## Values from data/player.json "stats".
static func from_base(base: Dictionary) -> ShotStats:
	var stats := ShotStats.new()
	for key: String in NUMBERS:
		if base.has(key):
			stats.set(key, float(base[key]))
	stats.shots = int(base.get("shots", 1))
	stats.orbitals = int(base.get("orbitals", 0))
	stats.helpers = int(base.get("helpers", 0))
	return stats


## Adds the "stats" of an item or synergy (additions only; multiplications come in apply_mults).
func apply_adds(changes: Dictionary) -> void:
	for key: String in changes:
		var value: float = float(changes[key])
		if key == "spread":
			spread = maxf(spread, value)
		elif key == "shots":
			shots += int(value)
		elif key == "orbitals":
			orbitals += int(value)
		elif key == "helpers":
			helpers += int(value)
		elif NUMBERS.has(key):
			set(key, float(get(key)) + value)


func apply_mults(changes: Dictionary) -> void:
	for key: String in changes:
		if key.ends_with("_mult"):
			var stat: String = key.trim_suffix("_mult")
			if NUMBERS.has(stat):
				set(stat, float(get(stat)) * float(changes[key]))


## "chance" of an item or synergy: stacks with what is there.
func apply_chances(changes: Dictionary) -> void:
	for flag: String in changes:
		var before: float = chances.get(flag, 0.0)
		chances[flag] = 1.0 - (1.0 - before) * (1.0 - clampf(float(changes[flag]), 0.0, 1.0))


## Keeps every value in a playable range (data/player.json "limits"): fire rate and shot speed
## have a floor, walking speed has a hard top.
func clamp_to(limits: Dictionary) -> void:
	fire_delay = maxf(fire_delay, float(limits.get("fire_delay_min", 0.07)))
	shot_speed = maxf(shot_speed, float(limits.get("shot_speed_min", 3.0)))
	reach = maxf(reach, float(limits.get("reach_min", 1.0)))
	move_speed = clampf(move_speed, float(limits.get("move_speed_min", 2.5)), float(limits.get("move_speed_max", 9.0)))
	damage = maxf(damage, 0.1)
	size = maxf(size, 0.3)
	bomb_size = maxf(bomb_size, 0.5)
	body = clampf(body, float(limits.get("body_min", 0.5)), float(limits.get("body_max", 1.7)))
	shots = maxi(shots, 1)
