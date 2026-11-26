class_name DayTint
extends CanvasModulate
## Colours the whole scene by the time of day (GameState.day_cycle): bright at noon,
## orange in the evening, dark blue at night. Put one into every scene that should follow the day.

## 1.0 = full effect (outside), lower values for rooms with only a little daylight.
@export_range(0.0, 1.0) var strength: float = 1.0
## Always a little darker on top of the time of day, e.g. under the glass dome of Sahrim
## (white = not darker).
@export var shade: Color = Color.WHITE


func _process(_delta: float) -> void:
	color = Color.WHITE.lerp(GameState.day_cycle.get_tint(), strength) * shade
