extends Sprite3D
## Wall torch: plays the flame frames of the Smithy torch (props/torch_sheet.png, 7 frames) and
## lets its light flicker a little (two waves plus a slow random jitter).

const FPS: float = 9.0
## How much the light strength swings around its normal value (0.18 = +-18 %).
const FLICKER: float = 0.18

## The light of this torch (set by RoomBuilder before add_child); flickers around its start energy.
var light: OmniLight3D

var _base_energy: float = 0.0
var _time: float = 0.0
var _jitter: float = 0.0


func _ready() -> void:
	_time = randf() * 20.0
	if light:
		_base_energy = light.light_energy


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * FPS) % hframes
	if light == null or not is_instance_valid(light):
		return
	# The jitter moves slowly towards a new random value, so the light does not blink.
	_jitter = lerpf(_jitter, randf_range(-1.0, 1.0), minf(1.0, delta * 12.0))
	var wave: float = sin(_time * 7.3) * 0.5 + sin(_time * 12.9 + 1.7) * 0.3 + _jitter * 0.4
	light.light_energy = _base_energy * (1.0 + wave * FLICKER)
