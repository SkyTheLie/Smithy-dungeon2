class_name AltarElements
extends Node2D
## The awakened Altar of the Nine: from the altar in the middle the power of each holy crystal runs
## over the floor to its pillar, the pillar shines in the colour of its element and the element
## floats on its top. All of it is PixelLab art, animated (2026-11-14, `_reference/altar_vfx/`):
## - beam_<element>.png: the stream, 8 frames of 64x16 one under the other, drawn tiled along the
##   path from the altar (left) to the pillar (right) and flowing slowly towards the pillar
## - crown_<element>.png: the element over the pillar (fire, lightning ball, poison drop, light orb,
##   dark orb, ice crystal, whirlwind, water drop, floating stones), 8 frames of 32x32
## - ring.png: the nine coloured orbs circling the crystal over the altar, 8 frames of 64x32
## Energy runs up the glowing veins of every lit pillar (altar_pillar.gdshader).
## Before the flag `flag` everything is dark; awaken() plays it (cut scene), loading with the flag
## set shows it at once. Pillars: StaticBody2D with a Sprite2D (pillar picture) and a NightLight.
## After the story the crystals can be taken out of the setting (AltarCrystals): the pillar of a
## crystal that is out goes dark, its beam and element are gone (refresh_crystals).

## The pillars (in the order of `elements`).
@export var pillars: Array[NodePath] = []
## Element of each pillar: fire, lightning, poison, light, dark, ice, wind, water, earth.
@export var elements: PackedStringArray = []
## The altar (the anvil of the first smith) in the middle; paths start at its foot.
@export var altar: NodePath
## Story flag: the altar is awake (everything lit).
@export var flag: String = "altar_awakened"
## Picture of a lit pillar per element (%s = element).
@export var lit_picture_dir: String = "res://assets/sprites/altar/pillar_%s.png"
## The unlit pillar picture (the shader finds the veins as the pixels that differ from it).
@export var unlit_picture: Texture2D = preload("res://assets/sprites/altar/pillar.png")

const COLORS: Dictionary = {
	"fire": Color(1.0, 0.45, 0.15), "lightning": Color(1.0, 0.92, 0.3), "poison": Color(0.45, 0.95, 0.25),
	"light": Color(1.0, 0.97, 0.75), "dark": Color(0.55, 0.3, 0.85), "ice": Color(0.65, 0.92, 1.0),
	"wind": Color(0.7, 1.0, 0.85), "water": Color(0.3, 0.6, 1.0), "earth": Color(0.65, 0.5, 0.3)}
const BEAM_SHEET: String = "res://assets/sprites/altar/beam_%s.png"
const CROWN_SHEET: String = "res://assets/sprites/altar/crown_%s.png"
const RING_SHEET: Texture2D = preload("res://assets/sprites/altar/ring.png")
const PILLAR_SHADER: Shader = preload("res://scenes/world/finster/altar_pillar.gdshader")
## Frames per sheet and frames per second.
const FRAMES: int = 8
const FPS: float = 8.0
## One tile of a beam (64x16) and how fast it flows towards the pillar (pixels per second).
const BEAM_TILE: Vector2 = Vector2(64, 16)
const BEAM_FLOW: float = 14.0
## How far above a pillar's foot its top is (pillar picture 84 px high) and the element floats.
const TOP: float = 92.0
## Where the paths start (from the altar position): behind the anvil's body, so the point where
## they meet stays hidden.
const ALTAR_FOOT: Vector2 = Vector2(0, -14)
## The ring of the nine colours floats above the top of the altar (the big anvil, 73 px high).
const RING_TOP: Vector2 = Vector2(0, -80)
const GROW_SECONDS: float = 1.3
const STAGGER: float = 0.45

## One per pillar: {"element", "from", "to" (local), "progress" 0..1, "lit": bool, "pillar": Node2D,
## "beam", "crown": Texture2D, "phase": int (frame offset, so the nine don't move in step),
## "out": bool (its crystal is out of the setting), "light_color": the NightLight's colour unlit}.
var _paths: Array[Dictionary] = []
var _time: float = 0.0
var _awake: bool = false
var _crowns: Node2D
## Altar glow (the ring of the nine colours over the altar), 0..1.
var _altar_glow: float = 0.0
## The setting lies on the altar (set by the cut scene once the king put it there).
var setting_on_altar: bool = false


func _ready() -> void:
	z_index = -1  # paths on the floor, under the figures
	_crowns = _Crowns.new()
	_crowns.owner_elements = self
	_crowns.z_index = 2
	_crowns.z_as_relative = false
	add_child(_crowns)
	_build.call_deferred()


func _build() -> void:
	var middle: Vector2 = _altar_position()
	for i in mini(pillars.size(), elements.size()):
		var pillar := get_node_or_null(pillars[i]) as Node2D
		if pillar == null:
			continue
		var element: String = elements[i]
		var target: Vector2 = to_local(pillar.global_position) + Vector2(0, -2)
		var light := pillar.get_node_or_null("NightLight") as PointLight2D
		_paths.append({"element": element, "from": middle + ALTAR_FOOT, "to": target, "progress": 0.0,
				"lit": false, "pillar": pillar, "beam": load(BEAM_SHEET % element),
				"crown": load(CROWN_SHEET % element), "phase": i * 3, "out": false,
				"light_color": light.color if light else Color.WHITE})
	if GameState.story.has_flag(flag):
		light_all()
	GameState.story.changed.connect(refresh_crystals)


## Each pillar with its element and where it stands seen from the altar (global offset), in the
## order of `elements` (the window of the setting lays its slots out like this).
func get_pillar_layout() -> Array[Dictionary]:
	var layout: Array[Dictionary] = []
	var middle: Vector2 = _altar_position()
	for path in _paths:
		layout.append({"element": path["element"], "offset": (path["to"] as Vector2) - middle})
	return layout


## The pillars of crystals that are out of the setting go dark, the others shine (after the story).
func refresh_crystals() -> void:
	if not _awake or not AltarCrystals.is_open():
		return
	var changed: bool = false
	for path in _paths:
		var out: bool = not AltarCrystals.is_in_setting(path["element"])
		if out == path["out"]:
			continue
		path["out"] = out
		changed = true
		if out:
			_darken_pillar(path)
		elif path["lit"]:
			_light_pillar(path, is_inside_tree() and is_visible_in_tree())
	if changed:
		queue_redraw()
		_crowns.queue_redraw()


## true if the pillar of `element` shines (for tests).
func is_pillar_lit(element: String) -> bool:
	for path in _paths:
		if path["element"] == element:
			return path["lit"] and not path["out"]
	return false


func _darken_pillar(path: Dictionary) -> void:
	var pillar: Node2D = path["pillar"]
	if not is_instance_valid(pillar):
		return
	var sprite := pillar.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture = unlit_picture
		sprite.material = null
	var light := pillar.get_node_or_null("NightLight") as PointLight2D
	if light:
		light.color = path["light_color"]
		light.set("always_on", false)


func _altar_position() -> Vector2:
	var node := get_node_or_null(altar) as Node2D
	return to_local(node.global_position) if node else Vector2.ZERO


## Everything lit at once (loading with the flag set).
func light_all() -> void:
	_awake = true
	setting_on_altar = true
	_altar_glow = 1.0
	for path in _paths:
		path["progress"] = 1.0
		_light_pillar(path, false)
	set_process(true)
	refresh_crystals()


## true once the paths run (for tests).
func is_awake() -> bool:
	return _awake


## Number of lit pillars (for tests).
func lit_count() -> int:
	return _paths.filter(func(path: Dictionary) -> bool: return path["lit"]).size()


## The cut scene: the altar lights up, then one path after the other runs to its pillar, which
## lights up. Awaitable (until the last pillar is lit).
func awaken() -> void:
	_awake = true
	set_process(true)
	var glow := create_tween()
	glow.tween_property(self, "_altar_glow", 1.0, 0.8)
	for i in _paths.size():
		_grow(_paths[i], 0.6 + STAGGER * i)
	await get_tree().create_timer(0.6 + STAGGER * _paths.size() + GROW_SECONDS + 0.1, false).timeout


func _grow(path: Dictionary, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if not is_inside_tree():
		return
	AudioManager.play_sound("skill_used", 0.6 + 0.08 * _paths.find(path))
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: path["progress"] = value, 0.0, 1.0, GROW_SECONDS) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if is_inside_tree():
		_light_pillar(path, true)


## The pillar takes its element's picture, the veins flow (shader); its light shines in the colour.
func _light_pillar(path: Dictionary, with_flash: bool) -> void:
	path["lit"] = true
	var pillar: Node2D = path["pillar"]
	if not is_instance_valid(pillar):
		return
	var color: Color = COLORS.get(path["element"], Color.WHITE)
	var sprite := pillar.get_node_or_null("Sprite2D") as Sprite2D
	var picture: String = lit_picture_dir % path["element"]
	if sprite and ResourceLoader.exists(picture):
		sprite.texture = load(picture)
		var material := ShaderMaterial.new()
		material.shader = PILLAR_SHADER
		material.set_shader_parameter("base_tex", unlit_picture)
		material.set_shader_parameter("glow_color", color)
		material.set_shader_parameter("offset", float(_paths.find(path)) * 0.29)
		sprite.material = material
	var light := pillar.get_node_or_null("NightLight") as PointLight2D
	if light:
		light.color = color
		light.set("always_on", true)
		light.enabled = true
	if with_flash and sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.5)
		AudioManager.play_sound("rarity_up", 0.9)


## The cut scene put the setting on the altar (drawn from now on).
func place_setting() -> void:
	setting_on_altar = true
	_crowns.queue_redraw()


## Frame of an 8-frame sheet now (`phase` shifts it).
func frame_now(phase: int = 0) -> int:
	return (int(_time * FPS) + phase) % FRAMES


func _process(delta: float) -> void:
	if not _awake:
		return
	_time += delta
	queue_redraw()
	_crowns.queue_redraw()


func _draw() -> void:
	for path in _paths:
		if path["progress"] > 0.0 and not path["out"]:
			_draw_beam(path)


## The beam: its sheet tiled from the altar to the pillar (as far as it has grown), turned along the
## path, flowing towards the pillar.
func _draw_beam(path: Dictionary) -> void:
	var sheet: Texture2D = path["beam"]
	if sheet == null:
		return
	var from: Vector2 = path["from"]
	var to: Vector2 = path["to"]
	var length: float = from.distance_to(to) * float(path["progress"])
	var row: float = frame_now(path["phase"]) * BEAM_TILE.y
	var shift: float = fmod(_time * BEAM_FLOW, BEAM_TILE.x)
	draw_set_transform(from, (to - from).angle())
	var start: float = shift - BEAM_TILE.x
	while start < length:
		var a: float = maxf(start, 0.0)
		var b: float = minf(start + BEAM_TILE.x, length)
		if b > a:
			draw_texture_rect_region(sheet, Rect2(a, -BEAM_TILE.y / 2.0, b - a, BEAM_TILE.y),
					Rect2(a - start, row, b - a, BEAM_TILE.y))
		start += BEAM_TILE.x
	draw_set_transform(Vector2.ZERO)


## The elements on top of the lit pillars and the ring over the altar (drawn above the figures).
class _Crowns extends Node2D:
	var owner_elements: AltarElements

	func _draw() -> void:
		var elements := owner_elements
		if elements == null:
			return
		# the setting sank into the altar (setting_on_altar): it is not drawn, only the ring of the
		# nine crystals floats above it
		if not elements._awake:
			return
		if elements._altar_glow > 0.0:
			_draw_sheet(RING_SHEET, Vector2(64, 32), elements.frame_now(), elements._altar_position() + RING_TOP,
					Color(1, 1, 1, elements._altar_glow))
		for path: Dictionary in elements._paths:
			if path["lit"] and path["crown"] and not path["out"]:
				_draw_sheet(path["crown"], Vector2(32, 32), elements.frame_now(path["phase"]),
						(path["to"] as Vector2) + Vector2(0, -TOP), Color.WHITE)

	## One frame of a sheet with frames side by side, centred on `at`.
	func _draw_sheet(sheet: Texture2D, cell: Vector2, frame: int, at: Vector2, tint: Color) -> void:
		draw_texture_rect_region(sheet, Rect2(at - cell / 2.0, cell), Rect2(Vector2(frame * cell.x, 0), cell), tint)
