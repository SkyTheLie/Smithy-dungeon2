class_name NightLight
extends PointLight2D
## Warm light of a fire pole, torch or lantern. It follows the time of day: off in daylight,
## growing in the evening, full at night (the darker GameState.day_cycle's tint, the brighter).
## Flickers a little like a real flame.

## Brightness at full night.
@export var night_energy: float = 1.0
## How strongly the light flickers (0 = steady, e.g. for a lantern behind glass).
@export var flicker: float = 0.08
## Always lit, whatever the time (e.g. torches in the gloomy black market, where it is never bright).
@export var always_on: bool = false

## Tint brightness at which the light starts to glow / is at full strength.
const DUSK_LUMINANCE: float = 0.85
const NIGHT_LUMINANCE: float = 0.45
const FLICKER_SPEED: float = 9.0

var _time: float = 0.0


func _ready() -> void:
	_time = randf() * 10.0  # neighbouring lights don't flicker in sync


func _process(delta: float) -> void:
	_time += delta
	var luminance: float = GameState.day_cycle.get_tint().get_luminance()
	var strength: float = clampf(inverse_lerp(DUSK_LUMINANCE, NIGHT_LUMINANCE, luminance), 0.0, 1.0)
	if always_on:
		strength = 1.0
	var wobble: float = 1.0 + flicker * (sin(_time * FLICKER_SPEED) * 0.6 + sin(_time * FLICKER_SPEED * 2.3) * 0.4)
	energy = night_energy * strength * wobble
	enabled = strength > 0.0
