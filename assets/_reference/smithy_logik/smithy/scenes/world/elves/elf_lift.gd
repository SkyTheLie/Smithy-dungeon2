class_name ElfLift
extends Station
## The rope lift of Sylvaris: a round platform of living wood. Standing on it and pressing E, it
## lifts the player up (or down) to the next level of the elf city: the rune flares up, the screen
## fades and the player arrives on the lift of the other level. Where it goes on upwards, two
## vine-wrapped ropes rise out of the picture (`ropes`).

@export_file("*.tscn") var target_scene: String
@export var target_spawn_point: StringName
## Shown above the disc, e.g. "Hinauf zu den Kronen".
@export var text: String = "Hinauf"
@export var glow_color: Color = Color(0.55, 0.95, 0.85)
## Ropes going up from the platform: for the lifts that lead higher.
@export var ropes: bool = false
## From this story flag the lift does not move (`closed_text`) until `open_flag` is set (e.g. roots
## hold it during the night attack). Empty = always works.
@export var closed_flag: String = ""
@export var open_flag: String = ""
@export var closed_text: String = "Die Plattform rührt sich nicht.":
	get:
		return Language.translate(closed_text)
## While the story is at one of these steps the lift does not move either (`blocked_text`), e.g.
## the way down during "Eine Nacht in Sylvaris": the player should go to bed first.
@export var blocked_steps: PackedStringArray = []
@export var blocked_text: String = "Jetzt nicht.":
	get:
		return Language.translate(blocked_text)

const RADIUS: Vector2 = Vector2(30, 14)
const RISE_SECONDS: float = 0.6
const ROPES_TEXTURE: Texture2D = preload("res://assets/sprites/elves/lift_ropes.png")
const DISC_TEXTURE: Texture2D = preload("res://assets/sprites/elves/lift_disc.png")
## From the bottom of the pictures up to the middle of the platform.
const DISC_MIDDLE: float = 17.0
const RUNE_RADIUS: Vector2 = Vector2(18, 7)

var _glow: float = 0.0
var _time: float = 0.0
var _busy: bool = false


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	z_index = -1
	var area := Area2D.new()
	area.name = Language.translate("InteractionArea")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = RADIUS * 2.0 + Vector2(8, 8)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_interaction_area_body_entered)
	area.body_exited.connect(_on_interaction_area_body_exited)
	var label := Label.new()
	label.text = KeyBindings.get_action_text("interact") + ": " + text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_outline_color", Color(0.13, 0.075, 0.12))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -RADIUS.y - 16)
	label.size = Vector2(120, 12)
	label.z_index = 2
	add_child(label)
	var light := PointLight2D.new()
	light.texture = load("res://scenes/world/objects/night_light_texture.tres")
	light.color = glow_color
	light.energy = 0.8
	light.texture_scale = 0.8
	add_child(light)
	interacted.connect(_ride)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var texture: Texture2D = ROPES_TEXTURE if ropes else DISC_TEXTURE
	draw_texture(texture, Vector2(-texture.get_width() / 2.0, DISC_MIDDLE - texture.get_height()).round())
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.0)
	_draw_ellipse(RUNE_RADIUS * (0.8 + 0.2 * pulse + _glow * 0.4), Color(glow_color, 0.12 + 0.08 * pulse + _glow * 0.5))


func _draw_ellipse(radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle: float = i / 24.0 * TAU
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _ride() -> void:
	if _busy or target_scene.is_empty():
		return
	var story: Story = GameState.story
	if not closed_flag.is_empty() and story.has_flag(closed_flag) and (open_flag.is_empty() or not story.has_flag(open_flag)):
		GameState.show_message(closed_text)
		return
	if story.step in blocked_steps:
		GameState.show_message(blocked_text)
		return
	_busy = true
	AudioManager.play_sound("rarity_up", 0.8)
	create_tween().tween_property(self, "_glow", 1.0, RISE_SECONDS)
	GameState.travel_to(target_scene, target_spawn_point, true)
