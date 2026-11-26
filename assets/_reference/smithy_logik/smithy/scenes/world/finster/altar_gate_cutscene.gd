class_name AltarGateCutscene
extends Sprite2D
## The gate at the Altar of the Nine moves during the dialogue (story actions "cutscene:gate_open" and
## "cutscene:gate_close"): this sprite lies over the gate props (StoryProp, switched by the flags
## gate_cracked and gate_sealed) and plays the sheet once, then hides again.

const FRAME_TIME: float = 0.16


func _ready() -> void:
	visible = false
	Events.cutscene_requested.connect(_on_cutscene)


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"gate_open":
			_play(hframes - 1, 0)
		"gate_close":
			# goes on from where the stones left the crack (AltarSealCutscene holds a frame)
			_play(frame if visible else 0, hframes - 1)


func _play(from_frame: int, to_frame: int) -> void:
	frame = from_frame
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "frame", to_frame, FRAME_TIME * maxi(1, absi(to_frame - from_frame)))
	tween.tween_callback(hide)
