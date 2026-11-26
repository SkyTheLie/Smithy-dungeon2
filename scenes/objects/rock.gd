class_name Rock
extends StaticBody3D
## A rock in a room (Smithy rock picture as a billboard). Blocks walking and fireballs; a bomb
## blows it up, sometimes with a coin inside.

## Taller than the shots fly (about 1.3 m), so nobody shoots over a rock.
const HEIGHT: float = 1.9
const RADIUS: float = 0.55

var texture_path: String = ""
## true = a coin falls out when it breaks.
var has_coin: bool = false


func _ready() -> void:
	collision_layer = RoomBuilder.LAYER_ROCKS
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS
	cylinder.height = HEIGHT
	shape.shape = cylinder
	shape.position.y = HEIGHT / 2.0
	add_child(shape)
	var texture := load(texture_path) as Texture2D
	if texture:
		var sprite := Fx.billboard(texture, HEIGHT)
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.shaded = true
		sprite.position.y = HEIGHT / 2.0
		add_child(sprite)
