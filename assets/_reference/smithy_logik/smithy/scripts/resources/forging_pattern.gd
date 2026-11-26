class_name ForgingPattern
extends Resource
## How a part is forged in the anvil minigame: the glowing workpiece and the spots to strike, in
## the order they light up. Created by ContentDB from data/content/forging_patterns.json
## (format: docs/CONTENT.md). Items use their own "forging_pattern" or the one of their part type
## (ContentDB.forging_pattern_for).

## Size of every pattern picture in pixels (the minigame shows it bigger).
const IMAGE_SIZE: Vector2 = Vector2(80, 48)

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## Glowing workpiece, IMAGE_SIZE pixels.
@export var image: Texture2D
## Strike spots as ellipses inside these rectangles (pixels of the picture).
@export var spots: Array[Rect2] = []


## Spot of the n-th strike (starts again at the first spot after the last one).
func get_spot(strike: int) -> Rect2:
	if spots.is_empty():
		return Rect2(IMAGE_SIZE / 2.0 - Vector2(4, 4), Vector2(8, 8))
	return spots[strike % spots.size()]
