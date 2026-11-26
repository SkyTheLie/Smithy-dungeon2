extends Station
## Smelter in the world. Shows the state of its busiest place (GameState.get_smelters(), alloy) with 4 frames:
## 1 = empty, 2 = smelting, 3 = from 20 % until the end, 4 = done (until the output is taken out).
## The frames were made with PixelLab from one base image (frame 3), see docs/ART_STYLE.md.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/stations/smelter/frame_1.png"),
	preload("res://assets/sprites/stations/smelter/frame_2.png"),
	preload("res://assets/sprites/stations/smelter/frame_3.png"),
	preload("res://assets/sprites/stations/smelter/frame_4.png"),
]
const FRAME_IDLE: int = 0
const FRAME_SMELTING: int = 1
const FRAME_HOT: int = 2
const FRAME_DONE: int = 3
const HOT_FROM: float = 0.2

## Own picture for this oven (e.g. the desert kiln), replaces the state frames.
@export var skin: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D

## Smelters whose running batch has already reached the hot frame.
var _hot: Dictionary = {}


func _ready() -> void:
	super()
	for smelter: Smelter in [GameState.smelter, GameState.alloy_smelter] + GameState.extra_smelters:
		smelter.ingot_finished.connect(_on_ingot_finished.bind(smelter))


## Chime once the whole batch is done (deferred: the smelter starts its next unit right after).
func _on_ingot_finished(smelter: Smelter) -> void:
	_chime_if_done.call_deferred(smelter)


func _chime_if_done(smelter: Smelter) -> void:
	if not smelter.is_smelting():
		AudioManager.play_sound("ingot_ready")


## South picture for Facing (the turned views are drawn from the empty oven).
func get_facing_base() -> Texture2D:
	return FRAMES[FRAME_IDLE]


func _process(_delta: float) -> void:
	# Turned, the oven shows its side or back: the glow of the opening is out of sight.
	if Facing.get_facing(self) != Facing.SOUTH:
		return
	# All places and the alloy tab share the oven: the busiest one decides the picture.
	if skin != null:
		_sprite.texture = skin
		return
	var frame: int = _get_frame(GameState.alloy_smelter)
	for smelter in GameState.get_smelters():
		frame = maxi(frame, _get_frame(smelter))
	_sprite.texture = FRAMES[frame]


func _get_frame(smelter: Smelter) -> int:
	if smelter.is_smelting():
		# Topping up lowers the progress: an oven that is hot stays hot until the batch ends.
		if smelter.get_progress() >= HOT_FROM:
			_hot[smelter] = true
		return FRAME_HOT if _hot.has(smelter) else FRAME_SMELTING
	_hot.erase(smelter)
	if not smelter.output_slot.is_empty():
		return FRAME_DONE
	return FRAME_IDLE
