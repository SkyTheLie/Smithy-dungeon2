class_name BreakableProp
extends StaticBody3D
## A crate, barrel or sack along the wall that breaks (floors.json props "break"): fireballs, the
## sword swing and bombs smash it, sometimes coins fall out. Built by RoomProps, broken by
## Dungeon.break_prop. Blocks shots and walking like a small rock.

## The standing picture (made by RoomProps, feet on the floor).
var sprite: Sprite3D
## Sound id when it breaks (audio.json).
var sound: String = ""


## `the_sprite`: the picture; `height` in metres (collision as tall as the picture, a bit narrower).
func setup(the_sprite: Sprite3D, height: float, break_sound: String) -> void:
	sprite = the_sprite
	sound = break_sound
	collision_layer = RoomBuilder.LAYER_ROCKS
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	var width: float = height
	if sprite.texture:
		width = height * float(sprite.texture.get_width()) / float(maxi(1, sprite.texture.get_height()))
	cylinder.radius = clampf(width * 0.4, 0.2, 0.5)
	cylinder.height = height
	shape.shape = cylinder
	shape.position.y = height / 2.0
	add_child(shape)
	add_child(sprite)
