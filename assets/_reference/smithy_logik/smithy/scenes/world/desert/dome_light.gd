class_name DomeLight
extends Node2D
## Daylight under the glass dome of Sahrim (DayTint with `shade` keeps the rest dim): the net of
## hexagons the glass throws onto the floor (child HexLight, a PointLight2D with
## sahrim_hex_light.png) and, above the spring, the bright spot under the hole in the dome (child
## SkyLight, a PointLight2D, and Beam, a light column drawn without shading). Each child is optional.
## All of it follows the sun: full by day, fading in the evening, gone at night; the net wanders a
## little with the sun from morning to evening.

## Brightness of the hexagon net and of the spot under the hole at full day.
@export var net_energy: float = 0.5
@export var sky_energy: float = 1.0
## Opacity of the light column at full day.
@export var beam_alpha: float = 0.35
## How far (pixels) the net wanders between morning and evening.
@export var net_drift: Vector2 = Vector2(90, 24)

## Like NightLight, the other way round: tint brightness from which the sun is gone / is full.
const NIGHT_LUMINANCE: float = 0.45
const DAY_LUMINANCE: float = 0.85
const SUNRISE_HOUR: float = 6.0
const SUNSET_HOUR: float = 21.0

@onready var _net: PointLight2D = get_node_or_null("HexLight")
@onready var _sky: PointLight2D = get_node_or_null("SkyLight")
@onready var _beam: CanvasItem = get_node_or_null("Beam")

var _net_home: Vector2


func _ready() -> void:
	if _net:
		_net_home = _net.position


func _process(_delta: float) -> void:
	var day: float = daylight()
	if _net:
		_net.energy = net_energy * day
		_net.enabled = day > 0.0
		_net.position = _net_home + net_drift * (sun_progress() - 0.5)
	if _sky:
		_sky.energy = sky_energy * day
		_sky.enabled = day > 0.0
	if _beam:
		_beam.modulate.a = beam_alpha * day


## 1 = full daylight, 0 = night (from the tint of GameState.day_cycle).
static func daylight() -> float:
	var luminance: float = GameState.day_cycle.get_tint().get_luminance()
	return clampf(inverse_lerp(NIGHT_LUMINANCE, DAY_LUMINANCE, luminance), 0.0, 1.0)


## 0 at sunrise, 1 at sunset.
static func sun_progress() -> float:
	var hour: float = GameState.day_cycle.minutes / 60.0
	return clampf(inverse_lerp(SUNRISE_HOUR, SUNSET_HOUR, hour), 0.0, 1.0)
