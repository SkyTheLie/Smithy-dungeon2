class_name Gloom
extends CanvasModulate
## Instead of DayTint: a place that is always dim, whatever the time of day (e.g. the black market
## in its back yard). Darkens by `color` (set it in the inspector) and switches every NightLight
## of the scene on for good, so torches and lanterns always glow.


func _ready() -> void:
	_light_up.call_deferred()


func _light_up() -> void:
	var scene: Node = owner if owner else get_parent()
	for light in scene.find_children("*", "PointLight2D", true, false):
		if light is NightLight:
			(light as NightLight).always_on = true
