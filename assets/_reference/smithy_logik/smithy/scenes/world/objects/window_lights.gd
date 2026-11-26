class_name WindowLights
extends Node
## Put one into a map: every house with lit windows (LightPoints) gets a small warm light behind
## them, which comes on in the evening like the lanterns. Houses with dark windows stay dark.

const NIGHT_LIGHT: PackedScene = preload("res://scenes/world/objects/night_light.tscn")
const COLOR := Color(1, 0.78, 0.48, 1)
const ENERGY: float = 1.0
const SIZE: float = 0.6
const FLICKER: float = 0.03


func _ready() -> void:
	_light_houses.call_deferred()


func _light_houses() -> void:
	for node in get_parent().find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null or not sprite.centered:
			continue
		for point in LightPoints.windows(sprite.texture):
			var light := NIGHT_LIGHT.instantiate() as NightLight
			light.position = sprite.offset + point
			light.color = COLOR
			light.night_energy = ENERGY
			light.texture_scale = SIZE
			light.flicker = FLICKER
			sprite.add_child(light)
