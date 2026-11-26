class_name Cobweb
extends Station
## Cobweb over a station while the smithy is being cleaned (story step "clean_smithy").
## The covered station can't be used. Walk to it and press E: the web is gone, the story flag
## is set (e.g. "cobweb_anvil") and a tip explains the station. Entering a room with a web shows
## the tip `ENTER_HINT` (how to clean) once. Shows `texture` (PixelLab
## cobweb), standing on the node position; without a texture a simple web is drawn by code.

## The station under the web (it stays blocked until the web is removed).
@export var station_path: NodePath
## Story flag set when the web is removed; the web never appears again once it is set.
@export var flag: String = ""
## Tip (story.json "hints") shown after cleaning, e.g. how the station works.
@export var hint_id: String = ""
## Size of the web in pixels.
@export var web_size: Vector2 = Vector2(36, 28)
## Picture of the web (bottom centre on the node position). Empty = web drawn by code.
@export var texture: Texture2D

## Tip (story.json "hints") shown the first time the player sees a web.
const ENTER_HINT: String = "cleaning"
const COLOR_WEB: Color = Color(0.92, 0.92, 0.95, 0.75)
const COLOR_WEB_FAINT: Color = Color(0.92, 0.92, 0.95, 0.4)
const RINGS: int = 3
const SPOKES: int = 7


func _ready() -> void:
	if GameState.story.has_flag(flag):
		queue_free()
		return
	var station := get_node_or_null(station_path) as Station
	if station:
		station.blocked = true
	interacted.connect(_on_interacted)
	GameState.story.show_hint(ENTER_HINT)


func _on_interacted() -> void:
	var station := get_node_or_null(station_path) as Station
	if station:
		station.blocked = false
	# Tip first: the last web also ends the story step, whose own tip comes after it.
	GameState.story.show_hint(hint_id)
	GameState.story.set_flag(flag)
	queue_free()


## The web draws itself, the guide outline follows its picture.
func get_guide_shape() -> Callable:
	return func() -> Dictionary:
		if texture == null:
			return {"texture": null, "rect": Rect2(-web_size.x / 2.0, -web_size.y, web_size.x, web_size.y)}
		return {"texture": texture, "rect": Rect2(-texture.get_width() / 2.0, -texture.get_height(), texture.get_width(), texture.get_height())}


## A simple spider web: spokes from the centre and rings between them.
func _draw() -> void:
	if texture:
		draw_texture(texture, Vector2(-texture.get_width() / 2.0, -texture.get_height()))
		return
	var center := Vector2(0, -web_size.y / 2.0)
	var radius: Vector2 = web_size / 2.0
	var points: Array[Vector2] = []
	for i in SPOKES:
		var angle: float = TAU * i / SPOKES + 0.3
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		draw_line(center, points[i], COLOR_WEB, 1.0)
	for ring in range(1, RINGS + 1):
		var factor: float = float(ring) / RINGS
		for i in SPOKES:
			var a: Vector2 = center.lerp(points[i], factor)
			var b: Vector2 = center.lerp(points[(i + 1) % SPOKES], factor)
			draw_line(a, b, COLOR_WEB if ring == RINGS else COLOR_WEB_FAINT, 1.0)
