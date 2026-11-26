class_name SheetAnimation
extends Sprite2D
## Loops through the frames of a sprite sheet (hframes × vframes) at a fixed speed, e.g. torch
## flames or chimney smoke. `frame_count` 0 = all frames of the sheet.

@export var frames_per_second: float = 8.0
@export var frame_count: int = 0
## Start at a random frame so neighbouring torches don't flicker in sync.
@export var random_start: bool = true
## Gentle up/down hover in pixels (0 = none), e.g. floating swamp wisps.
@export var bob_amplitude: float = 0.0
@export var bob_speed: float = 1.6

var _time: float = 0.0
var _base_offset_y: float = 0.0


func _ready() -> void:
	if frame_count <= 0:
		frame_count = hframes * vframes
	if random_start:
		_time = randf() * frame_count / frames_per_second
	_base_offset_y = offset.y


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * frames_per_second) % frame_count
	if bob_amplitude != 0.0:
		offset.y = _base_offset_y + roundf(sin(_time * bob_speed) * bob_amplitude)
