class_name LightPoints
extends RefCounted
## Where light comes from on a picture: data/content/light_points.json, measured by
## assets/_reference/map_tools/bake_light_points.py ("lamps": lamp of a lantern picture, x from its
## middle, y from its foot; "windows": lit windows of a house picture, from its middle).

const PATH: String = "res://data/content/light_points.json"

static var _data: Dictionary = {}


## Position of the lamp on `texture` relative to the lantern's foot. `fallback` if it was not measured.
static func lamp(texture: Texture2D, fallback: Vector2) -> Vector2:
	var point: Array = _load().get("lamps", {}).get(texture.resource_path.get_file().get_basename(), [])
	return Vector2(point[0], point[1]) if point.size() == 2 else fallback


## Lit windows of `texture`, relative to the middle of the picture.
static func windows(texture: Texture2D) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point: Array in _load().get("windows", {}).get(texture.resource_path.get_file().get_basename(), []):
		points.append(Vector2(point[0], point[1]))
	return points


static func _load() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"lamps": {}}
	return _data
