extends Sprite3D
## Wall torch: plays the flame frames of the Smithy torch (props/torch_sheet.png, 7 frames).

const FPS: float = 9.0

var _time: float = 0.0


func _ready() -> void:
	_time = randf() * 2.0


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * FPS) % hframes
