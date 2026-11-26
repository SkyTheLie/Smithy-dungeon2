class_name ThemedLantern
extends StaticBody2D
## Lantern, bush ... with several pictures. Picks one from its position, so a map always looks
## the same but neighbouring lanterns differ. A lantern with `facing` hangs its lamp that way, always
## towards the road (assets/_reference/lamps_1030/bake_facing.py).

## Pictures of this region, feet at the bottom edge.
@export var variants: Array[Texture2D] = []
## Which way the lamp hangs: "west", "east", "south", "north". Empty = as the picture was drawn.
@export var facing: String = ""
## Pictures with a direction: path with %d (variant) and %s (`facing`).
@export var facing_path: String = ""


func _ready() -> void:
	if variants.is_empty():
		return
	var pick: int = absi(int(position.x) * 7 + int(position.y) * 13) % variants.size()
	var texture: Texture2D = variants[pick]
	if not facing.is_empty() and not facing_path.is_empty():
		# not every picture has all four directions (the lamp of some can't be taken off the post)
		for i in variants.size():
			var path: String = facing_path % [(pick + i) % variants.size(), facing]
			if ResourceLoader.exists(path):
				texture = load(path)
				break
	var sprite: Sprite2D = $Sprite2D
	sprite.texture = texture
	sprite.offset = Vector2(0, -texture.get_height() / 2.0)
	var light := get_node_or_null("NightLight") as Node2D
	if light:
		light.position = LightPoints.lamp(texture, light.position)
