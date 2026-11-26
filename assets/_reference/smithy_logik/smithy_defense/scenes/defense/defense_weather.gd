class_name DefenseWeather
extends Control
## Weather over the forge defense field, in screen space under the HUD: ash with a few embers
## (lava), snow, leaves, spores (swamp), sand, rain, dust motes or nothing. Which one: the part's
## ground picture (DefenseRun.weather_for, defense.json effects.weather). A fixed number of flakes
## in reused arrays; nothing is made while it runs (FEHLERKLASSEN 12).

const MAX_FLAKES: int = 90

## Per kind: how many flakes, their speed range (px/s, x and y), size and colours.
const KINDS: Dictionary = {
	"ash": {"count": 60, "speed": Vector4(-12, 12, 8, 22), "size": 2.0, "colors": [Color(0.35, 0.33, 0.33, 0.7), Color(0.5, 0.48, 0.46, 0.6), Color(1.0, 0.55, 0.2, 0.9)], "sway": 10.0},
	"snow": {"count": 80, "speed": Vector4(-8, 8, 18, 38), "size": 2.0, "colors": [Color(1, 1, 1, 0.85), Color(0.85, 0.92, 1.0, 0.7)], "sway": 14.0},
	"leaves": {"count": 26, "speed": Vector4(18, 40, 12, 26), "size": 3.0, "colors": [Color(0.85, 0.5, 0.15, 0.9), Color(0.55, 0.7, 0.2, 0.9), Color(0.75, 0.3, 0.12, 0.9)], "sway": 22.0},
	"spores": {"count": 40, "speed": Vector4(-5, 5, -14, -5), "size": 2.0, "colors": [Color(0.6, 1.0, 0.4, 0.55), Color(0.85, 1.0, 0.5, 0.45)], "sway": 9.0},
	"sand": {"count": 70, "speed": Vector4(90, 160, -4, 6), "size": 1.0, "colors": [Color(0.9, 0.78, 0.5, 0.55), Color(0.8, 0.65, 0.4, 0.45)], "sway": 2.0},
	"rain": {"count": 90, "speed": Vector4(-40, -30, 260, 330), "size": 1.0, "colors": [Color(0.65, 0.75, 0.95, 0.45)], "sway": 0.0},
	"dust": {"count": 22, "speed": Vector4(-5, 5, -6, 4), "size": 1.0, "colors": [Color(1.0, 0.95, 0.8, 0.35)], "sway": 6.0},
}

var kind: String = "none"

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _phase := PackedFloat32Array()
var _color := PackedColorArray()
var _count: int = 0
var _size: float = 1.0
var _sway: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos.resize(MAX_FLAKES)
	_vel.resize(MAX_FLAKES)
	_phase.resize(MAX_FLAKES)
	_color.resize(MAX_FLAKES)


## Another weather (spread over the whole screen at once).
func set_kind(new_kind: String) -> void:
	if new_kind == kind and _count > 0:
		return
	kind = new_kind
	var entry: Dictionary = KINDS.get(kind, {})
	_count = mini(int(entry.get("count", 0)), MAX_FLAKES)
	_size = float(entry.get("size", 1.0))
	_sway = float(entry.get("sway", 0.0))
	var speed: Vector4 = entry.get("speed", Vector4.ZERO)
	var colors: Array = entry.get("colors", [Color.WHITE])
	for i in _count:
		_pos[i] = Vector2(randf() * maxf(size.x, 1.0), randf() * maxf(size.y, 1.0))
		_vel[i] = Vector2(randf_range(speed.x, speed.y), randf_range(speed.z, speed.w))
		_phase[i] = randf() * TAU
		_color[i] = colors[randi() % colors.size()]
	queue_redraw()


func _process(delta: float) -> void:
	if _count == 0:
		return
	_time += delta
	var area: Vector2 = size + Vector2(8, 8)
	for i in _count:
		var at: Vector2 = _pos[i] + _vel[i] * delta
		at.x = fposmod(at.x + 4.0, area.x) - 4.0
		at.y = fposmod(at.y + 4.0, area.y) - 4.0
		_pos[i] = at
	queue_redraw()


func _draw() -> void:
	for i in _count:
		var at: Vector2 = _pos[i] + Vector2(sin(_time * 1.3 + _phase[i]) * _sway, 0)
		match kind:
			"rain":
				draw_line(at, at + _vel[i] * 0.03, _color[i], 1.0)
			"sand":
				draw_line(at, at - Vector2(6, 0), _color[i], 1.0)
			"leaves":
				draw_rect(Rect2(at, Vector2(_size, _size * (0.5 + 0.5 * absf(sin(_time * 3.0 + _phase[i]))))), _color[i])
			_:
				var twinkle: float = 0.6 + 0.4 * sin(_time * 2.0 + _phase[i])
				draw_rect(Rect2(at, Vector2(_size, _size)), Color(_color[i], _color[i].a * twinkle))
