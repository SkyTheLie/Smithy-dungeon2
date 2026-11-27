class_name BossAltar
extends DungeonRoom
## The Boss-Altar: the great hall of the end boss (dungeons.json end_boss). After the boss of the
## last floor a portal rises in the boss room (Portal); it leads here. A room as big as several
## rooms (data/boss_altar.json "size"), far away from the floor grid (like the test room), with
## the Altar der Neun in the middle and nine pillars around it. Dungeon builds it the first time
## the player walks into the portal and moves the player in and out (enter_boss_altar / leave).
##
## The scene when the player comes near the altar (wake_distance), like the end of Smithy:
##   1. the altar wakes (rumble), the hall goes darker, black bars, the view turns to the altar;
##   2. the nine holy crystals fly in from above, each glowing in the colour of its element;
##   3. they circle over the altar faster and faster, flash and drop into it in a quick motion;
##   4. the altar lights up; along the grooves in the floor the energy flows to the pillars and
##      every pillar lights up in its colour (its element floats on top);
##   5. the music stops: a short silence;
##   6. the end boss falls in from high above and lands with a blow; its life bar fills up
##      (WAKE_TIME), the heavy fight music starts, then the fight begins.
## skip_intro() jumps to the end of it (admin menu, tests). After the boss (on_cleared) the hall
## brightens and the gate back to the boss room opens; the golden light (victory) is in the hall.
## Only builds and plays the scene; spawning the boss and the rewards are in Dungeon.

## Sent when the scene starts (true) and when the player may move again (false): the HUD hides.
signal cutscene_changed(active: bool)

const TYPE: String = "boss_altar"
## Seconds between the landing of the boss and the start of the fight (the HUD fills the life
## bar in this time).
const WAKE_TIME: float = 1.2
const ALTAR_HEIGHT: float = 2.4
const ALTAR_RADIUS: float = 1.1
const PILLAR_HEIGHT: float = 3.6
const PILLAR_RADIUS: float = 0.6
const CRYSTAL_HEIGHT: float = 0.75
const CRYSTAL_FRAME: int = 48
const SHEET_FRAMES: int = 8
const SHEET_FPS: float = 8.0
const CROWN_HEIGHT: float = 0.8
## The ring of crystals over the altar.
const RING_HEIGHT: float = 3.4
const RING_RADIUS: float = 1.4
## Grooves in the floor from the altar to the pillars and the energy in them.
const GROOVE_WIDTH: float = 0.4
const BEAM_WIDTH: float = 0.3
const BEAM_FLOW: float = 0.6
const GATE_HEIGHT: float = 3.4
const GATE_TOUCH: float = 1.4
const FLOOR_TILE: float = 5.0
const BAR_HEIGHT: float = 34.0
## Where the boss lands: this far behind the altar (seen from the gate).
const BOSS_SPOT: float = 4.0
const CRYSTAL_PATH: String = "res://assets/sprites/items/holy_crystals/holy_%s_crystal.png"
const PILLAR_DARK: String = "res://assets/sprites/altar/pillar.png"
const PILLAR_LIT: String = "res://assets/sprites/altar/pillar_%s.png"
const BEAM_PATH: String = "res://assets/sprites/altar/beam_%s.png"
const CROWN_PATH: String = "res://assets/sprites/altar/crown_%s.png"
const RING_PATH: String = "res://assets/sprites/altar/ring.png"

enum Step { SLEEPING, SCENE, FIGHT, DONE }

var dungeon: Dungeon
var player: Player
var settings: Dictionary = {}
var step: Step = Step.SLEEPING
## Half the walkable size (x, z) in metres.
var half: Vector2 = Vector2.ZERO
var exit_open: bool = false

var _altar: Sprite3D
var _altar_light: OmniLight3D
var _ring: Sprite3D
var _gate: Sprite3D
## One per element: {"element", "color", "pillar": Sprite3D, "light": OmniLight3D,
## "crown": Sprite3D, "beam": Node3D (grows along the groove), "beam_material", "crystal": Sprite3D,
## "crystal_light": OmniLight3D, "slot": Vector3 (place in the ring), "lit": bool}.
var _parts: Array[Dictionary] = []
var _time: float = 0.0
var _ring_angle: float = 0.0
var _ring_speed: float = 0.0
var _spinning: bool = false
var _skipping: bool = false
var _tweens: Array[Tween] = []
var _cinema: CanvasLayer
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _black: ColorRect
var _environment: Environment
var _ambient_base: float = 1.0
var _falling: Sprite3D = null


# --- Building ---------------------------------------------------------------------------

func setup(the_dungeon: Dungeon, the_player: Player, at_cell: Vector2i) -> void:
	dungeon = the_dungeon
	player = the_player
	settings = Content.get_file("boss_altar")
	cell = at_cell
	type = TYPE
	name = "BossAltar"
	var size: Array = settings.get("size", [2, 2])
	half = Vector2(RoomBuilder.ROOM_W * float(size[0]), RoomBuilder.ROOM_D * float(size[1])) / 2.0 - Vector2(RoomBuilder.WALL_T, RoomBuilder.WALL_T)


func _ready() -> void:
	position = RoomBuilder.cell_center(cell)
	_build_shell()
	_build_altar()
	_build_pillars()
	_build_gate()
	_build_cinema()
	# Its own copy of the light settings, so darkening the hall changes no other scene.
	var world_environment := dungeon.get_parent().get_node_or_null("Environment") as WorldEnvironment if dungeon else null
	if world_environment and world_environment.environment:
		world_environment.environment = world_environment.environment.duplicate() as Environment
		_environment = world_environment.environment
		_ambient_base = _environment.ambient_light_energy


## Walkable area in world x/z, `margin` metres away from the walls.
func inner_rect(margin: float) -> Rect2:
	var center := Vector2(global_position.x, global_position.z)
	var inside: Vector2 = half - Vector2(margin, margin)
	return Rect2(center - inside, inside * 2.0)


## Where the player stands after coming in (in front of the gate, looking at the altar).
func arrival_point() -> Vector3:
	return global_position + Vector3(0, 0, half.y - 2.2)


func altar_position() -> Vector3:
	return global_position


func boss_spot() -> Vector3:
	return global_position + Vector3(0, 0, -BOSS_SPOT)


## Floor in tiles (so the many coloured lights each light their part of it), walls, torches.
func _build_shell() -> void:
	var wall_height: float = float(settings.get("wall_height", 5.0))
	var floor_material := RoomBuilder.tiled_material(String(settings.get("floor_texture", "")), Vector3(1.5, 1.5, 1.5))
	var wall_material := RoomBuilder.tiled_material(String(settings.get("wall_texture", "")), Vector3(2.0, 3.0, 2.0))
	var outer: Vector2 = half + Vector2(RoomBuilder.WALL_T, RoomBuilder.WALL_T)
	var tiles := Vector2i(ceili(outer.x * 2.0 / FLOOR_TILE), ceili(outer.y * 2.0 / FLOOR_TILE))
	var tile_size := Vector2(outer.x * 2.0 / tiles.x, outer.y * 2.0 / tiles.y)
	for x in tiles.x:
		for z in tiles.y:
			var at := Vector3(-outer.x + (x + 0.5) * tile_size.x, -0.1, -outer.y + (z + 0.5) * tile_size.y)
			RoomBuilder.box(self, Vector3(tile_size.x, 0.2, tile_size.y), at, floor_material, 0)
	# One collision body for the whole floor.
	var floor_body := RoomBuilder.box(self, Vector3(outer.x * 2.0, 0.2, outer.y * 2.0), Vector3(0, -0.1, 0), floor_material, RoomBuilder.LAYER_WORLD)
	floor_body.visible = false
	for side: float in [-1.0, 1.0]:
		RoomBuilder.box(self, Vector3(outer.x * 2.0, wall_height, RoomBuilder.WALL_T), Vector3(0, wall_height / 2.0, side * (outer.y - RoomBuilder.WALL_T / 2.0)), wall_material, RoomBuilder.LAYER_WORLD)
		RoomBuilder.box(self, Vector3(RoomBuilder.WALL_T, wall_height, outer.y * 2.0), Vector3(side * (outer.x - RoomBuilder.WALL_T / 2.0), wall_height / 2.0, 0), wall_material, RoomBuilder.LAYER_WORLD)
	# A few cold torches: just enough to see the walls in the dark.
	var cold := Color(0.45, 0.55, 0.9)
	for x: float in [-half.x * 0.6, half.x * 0.6]:
		RoomBuilder.torch(self, Vector3(x, 2.4, -half.y + 0.12), cold)
		RoomBuilder.torch(self, Vector3(x, 2.4, half.y - 0.12), cold)


func _build_altar() -> void:
	var texture := load(String(settings.get("altar", ""))) as Texture2D
	_altar = Fx.billboard(texture, ALTAR_HEIGHT)
	_altar.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_altar.position = Vector3(0, ALTAR_HEIGHT / 2.0, 0)
	_altar.modulate = Color(0.55, 0.55, 0.65)
	add_child(_altar)
	_add_blocker(Vector3.ZERO, ALTAR_RADIUS)
	_altar_light = OmniLight3D.new()
	_altar_light.light_color = Color(1.0, 0.9, 0.7)
	_altar_light.light_energy = 0.0
	_altar_light.omni_range = 9.0
	_altar_light.position = Vector3(0, ALTAR_HEIGHT + 0.6, 0)
	add_child(_altar_light)
	# The nine coloured orbs circling over the altar once it is awake (8 frames of 64x32).
	_ring = Fx.billboard(load(RING_PATH) as Texture2D, 0.9)
	_ring.hframes = SHEET_FRAMES
	_ring.pixel_size = 0.9 / 32.0
	_ring.position = Vector3(0, ALTAR_HEIGHT + 0.7, 0)
	_ring.visible = false
	add_child(_ring)


## Nine dark pillars on an ellipse around the altar, a groove from the altar to each, and in it
## the energy (hidden until it flows).
func _build_pillars() -> void:
	var elements: Array = settings.get("elements", [])
	var colors: Dictionary = settings.get("colors", {})
	var reach: Array = settings.get("pillars", [9.5, 7.0])
	var dark := load(PILLAR_DARK) as Texture2D
	var groove_material := RoomBuilder.color_material(Color(0.04, 0.035, 0.05))
	for i in elements.size():
		var element: String = String(elements[i])
		var rgb: Array = colors.get(element, [1, 1, 1])
		var color := Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
		# Starting north (behind the altar), so the way from the gate to the altar stays free.
		var angle: float = -PI / 2.0 + TAU * i / elements.size()
		var foot := Vector3(cos(angle) * float(reach[0]), 0, sin(angle) * float(reach[1]))
		var pillar := Fx.billboard(dark, PILLAR_HEIGHT)
		pillar.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		pillar.position = foot + Vector3(0, PILLAR_HEIGHT / 2.0, 0)
		add_child(pillar)
		_add_blocker(foot, PILLAR_RADIUS)
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 0.0
		light.omni_range = 5.5
		light.position = foot + Vector3(0, PILLAR_HEIGHT * 0.7, 0) - foot.normalized() * 0.6
		add_child(light)
		var crown := Fx.billboard(load(CROWN_PATH % element) as Texture2D, CROWN_HEIGHT)
		crown.hframes = SHEET_FRAMES
		crown.pixel_size = CROWN_HEIGHT / 32.0
		crown.position = foot + Vector3(0, PILLAR_HEIGHT + CROWN_HEIGHT * 0.7, 0)
		crown.visible = false
		add_child(crown)
		# The groove: a dark strip from the foot of the altar to the foot of the pillar.
		var start: Vector3 = foot.normalized() * (ALTAR_RADIUS + 0.1)
		var end: Vector3 = foot - foot.normalized() * (PILLAR_RADIUS + 0.1)
		var length: float = start.distance_to(end)
		var groove := RoomBuilder.box(self, Vector3(length, 0.02, GROOVE_WIDTH), (start + end) / 2.0 + Vector3(0, 0.005, 0), groove_material, 0)
		groove.rotation.y = -atan2(end.z - start.z, end.x - start.x)
		var beam := Node3D.new()
		beam.position = start + Vector3(0, 0.025, 0)
		beam.rotation.y = groove.rotation.y
		beam.scale = Vector3(0.001, 1, 1)
		beam.visible = false
		add_child(beam)
		var beam_material := _beam_material(element, length)
		var strip := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(length, BEAM_WIDTH)
		strip.mesh = plane
		strip.material_override = beam_material
		strip.position = Vector3(length / 2.0, 0, 0)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.add_child(strip)
		var slot_angle: float = TAU * i / elements.size()
		_parts.append({"element": element, "color": color, "pillar": pillar, "light": light, "crown": crown,
				"beam": beam, "beam_material": beam_material, "crystal": null, "crystal_light": null,
				"slot": Vector3(cos(slot_angle) * RING_RADIUS, RING_HEIGHT, sin(slot_angle) * RING_RADIUS),
				"foot": foot, "lit": false})


## The flowing energy: the beam picture (8 frames of 64x16 one under the other), one frame shown,
## repeated along the groove, glowing (added on top of the floor).
func _beam_material(element: String, length: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(BEAM_PATH % element) as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	# One picture is 64x16 pixels: as long as 4x the width of the strip.
	material.uv1_scale = Vector3(length / (BEAM_WIDTH * 4.0), 1.0 / SHEET_FRAMES, 1.0)
	return material


## The gate back to the boss room in the south wall (shut until the boss is beaten).
func _build_gate() -> void:
	_gate = Fx.billboard(load(String(settings.get("gate", ""))) as Texture2D, GATE_HEIGHT)
	_gate.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_gate.rotation.y = PI
	_gate.position = Vector3(0, GATE_HEIGHT / 2.0, half.y - 0.02)
	add_child(_gate)


## An invisible round body that stops the player, enemies on foot and shots (like a rock).
func _add_blocker(at: Vector3, radius: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = RoomBuilder.LAYER_ROCKS
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position.y = 1.5
	body.add_child(shape)
	body.position = at
	add_child(body)


## Black bars and a black fade, drawn into the 3D view (under the HUD).
func _build_cinema() -> void:
	_cinema = CanvasLayer.new()
	_cinema.layer = 2
	add_child(_cinema)
	_bar_top = ColorRect.new()
	_bar_bottom = ColorRect.new()
	for bar: ColorRect in [_bar_top, _bar_bottom]:
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size = Vector2(4096, 0)
		_cinema.add_child(bar)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cinema.add_child(_black)
	_cinema.visible = false


# --- Entering, leaving -------------------------------------------------------------------

## The player just came in: dark hall, the gloomy music, the gate shuts behind them.
func on_enter() -> void:
	_cinema.visible = visible
	_set_ambient(float(settings.get("ambient_dark", 0.25)) if step != Step.DONE else float(settings.get("ambient_lit", 0.8)), 0.0)
	if step == Step.SLEEPING:
		AudioManager.play_music(String(settings.get("music_altar", "")))
		AudioManager.play_sound("gate", 0.8)
		_fade_from_black(0.6)


## The player went back to the boss room: the light of the other rooms again.
func on_leave() -> void:
	_cinema.visible = false
	if _environment:
		_environment.ambient_light_energy = _ambient_base


## The boss is beaten: the hall brightens and the gate opens.
func on_cleared() -> void:
	step = Step.DONE
	exit_open = true
	_gate.texture = load(String(settings.get("gate_open", ""))) as Texture2D
	_set_ambient(float(settings.get("ambient_lit", 0.8)), 1.5)
	AudioManager.play_sound("gate", 1.1)


## Each frame while the player is in the hall (Dungeon): wakes the altar when they come near.
## Returns true when the player walks into the open gate (Dungeon takes them back).
func tick() -> bool:
	if step == Step.SLEEPING:
		var offset: Vector3 = player.global_position - altar_position()
		offset.y = 0.0
		if offset.length() < float(settings.get("wake_distance", 5.5)):
			_play_scene()
	if exit_open:
		var to_gate: Vector3 = player.global_position - (global_position + Vector3(0, 0, half.y))
		to_gate.y = 0.0
		return to_gate.length() < GATE_TOUCH
	return false


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var frame: int = int(_time * SHEET_FPS) % SHEET_FRAMES
	if _ring.visible:
		_ring.frame = frame
	if _spinning:
		_ring_speed = minf(_ring_speed + delta * 5.0, 14.0)
		_ring_angle += _ring_speed * delta
	for i in _parts.size():
		var part: Dictionary = _parts[i]
		var crown: Sprite3D = part["crown"]
		if crown.visible:
			crown.frame = (frame + i) % SHEET_FRAMES
		var beam: Node3D = part["beam"]
		if beam.visible:
			var material: StandardMaterial3D = part["beam_material"]
			material.uv1_offset = Vector3(-_time * BEAM_FLOW, float((frame + i) % SHEET_FRAMES) / SHEET_FRAMES, 0)
		var crystal: Sprite3D = part["crystal"]
		if crystal and is_instance_valid(crystal):
			crystal.frame = int(_time * 12.0 + i * 3) % crystal.hframes
			if _spinning:
				var angle: float = _ring_angle + TAU * i / _parts.size()
				crystal.position = Vector3(cos(angle) * RING_RADIUS, RING_HEIGHT + sin(_time * 3.0 + i) * 0.08, sin(angle) * RING_RADIUS)


# --- The scene ---------------------------------------------------------------------------

func _play_scene() -> void:
	step = Step.SCENE
	cutscene_changed.emit(true)
	player.controls_enabled = false
	player.invulnerable = 999.0
	player.velocity = Vector3.ZERO
	_cinema.visible = true
	# 1. The altar wakes.
	AudioManager.play_sound("altar_wake", 0.7)
	player.shake(0.7)
	_letterbox(true)
	_set_ambient(float(settings.get("ambient_dark", 0.25)) * 0.5, 1.2)
	_turn_view(altar_position() + Vector3(0, RING_HEIGHT * 0.8, 0), 1.2)
	_track(create_tween()).tween_property(_altar, "modulate", Color(0.8, 0.8, 0.95), 1.0)
	if not await _wait(1.2):
		return
	# 2. The crystals fly in.
	for i in _parts.size():
		_fly_in(i, 2.6)
		if not await _wait(0.18):
			return
	if not await _wait(2.6):
		return
	# 3. They circle, faster and faster, glow brighter, flash and drop in.
	_spinning = true
	_ring_angle = 0.0
	_ring_speed = 0.5
	for part: Dictionary in _parts:
		var light: OmniLight3D = part["crystal_light"]
		var tween := _track(create_tween()).set_parallel(true)
		tween.tween_property(light, "light_energy", 2.6, 2.2)
		tween.tween_property(part["crystal"] as Sprite3D, "scale", Vector3.ONE * 1.35, 2.2)
	if not await _wait(2.2):
		return
	_spinning = false
	for i in _parts.size():
		_drop_in(i)
		if not await _wait(0.13):
			return
	if not await _wait(0.3):
		return
	# 4. The altar lights up, the energy flows to the pillars.
	_altar_awake()
	if not await _wait(0.6):
		return
	_turn_view(altar_position() + Vector3(0, 1.0, 0), 1.0)
	for i in _parts.size():
		_flow(i, 1.0)
		if not await _wait(0.22):
			return
	if not await _wait(1.3):
		return
	# 5. Silence.
	AudioManager.play_music("")
	if not await _wait(float(settings.get("silence", 1.6))):
		return
	# 6. The boss falls in.
	await _boss_falls()


## Crystal `index` comes from high above its pillar and flies in a curve to its place in the ring.
func _fly_in(index: int, time: float) -> void:
	var part: Dictionary = _parts[index]
	var crystal := _make_crystal(part)
	var from: Vector3 = (part["foot"] as Vector3) * 1.5 + Vector3(0, 11.0, 0)
	var to: Vector3 = part["slot"]
	var bend: Vector3 = (from + to) / 2.0 + Vector3(0, 3.0, 0) + (part["foot"] as Vector3).normalized().rotated(Vector3.UP, PI / 2.0) * 3.0
	crystal.position = from
	var tween := _track(create_tween())
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(crystal):
			crystal.position = from.lerp(bend, t).lerp(bend.lerp(to, t), t), 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: AudioManager.play_sound("crystal_chime", 0.8 + index * 0.06))


func _make_crystal(part: Dictionary) -> Sprite3D:
	var texture := load(CRYSTAL_PATH % String(part["element"])) as Texture2D
	var crystal := Fx.billboard(texture, CRYSTAL_HEIGHT)
	crystal.hframes = maxi(1, floori(float(texture.get_width()) / CRYSTAL_FRAME))
	crystal.pixel_size = CRYSTAL_HEIGHT / CRYSTAL_FRAME
	add_child(crystal)
	var light := OmniLight3D.new()
	light.light_color = part["color"]
	light.light_energy = 1.2
	light.omni_range = 3.5
	crystal.add_child(light)
	part["crystal"] = crystal
	part["crystal_light"] = light
	return crystal


## Crystal `index` flashes white and drops into the altar.
func _drop_in(index: int) -> void:
	var part: Dictionary = _parts[index]
	var crystal: Sprite3D = part["crystal"]
	if crystal == null or not is_instance_valid(crystal):
		return
	var tween := _track(create_tween())
	tween.tween_property(crystal, "modulate", Color(3, 3, 3), 0.06)
	tween.tween_property(crystal, "position", Vector3(0, ALTAR_HEIGHT * 0.75, 0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(crystal, "scale", Vector3.ONE * 0.3, 0.14)
	tween.tween_callback(func() -> void:
		AudioManager.play_sound("crystal_drop", 0.9 + index * 0.07)
		Fx.flash(self, global_position + Vector3(0, ALTAR_HEIGHT, 0), part["color"] as Color, 3.0, 5.0, 0.3)
		crystal.queue_free()
		part["crystal"] = null)


func _altar_awake() -> void:
	AudioManager.play_sound("altar_glow")
	player.shake(0.4)
	Fx.flash(self, global_position + Vector3(0, ALTAR_HEIGHT, 0), Color(1, 0.95, 0.8), 8.0, 14.0, 0.8)
	Fx.puff(dungeon.effects if dungeon else self, global_position + Vector3(0, ALTAR_HEIGHT * 0.8, 0), "spark", 2.5)
	_ring.visible = true
	var tween := _track(create_tween()).set_parallel(true)
	tween.tween_property(_altar, "modulate", Color.WHITE, 0.4)
	tween.tween_property(_altar_light, "light_energy", 2.2, 0.6)


## The energy runs along groove `index` to its pillar (in `time` seconds), then the pillar lights up.
func _flow(index: int, time: float) -> void:
	var part: Dictionary = _parts[index]
	var beam: Node3D = part["beam"]
	beam.visible = true
	var tween := _track(create_tween())
	tween.tween_property(beam, "scale:x", 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_light_pillar.bind(index, true))


func _light_pillar(index: int, with_sound: bool) -> void:
	var part: Dictionary = _parts[index]
	if bool(part["lit"]):
		return
	part["lit"] = true
	(part["pillar"] as Sprite3D).texture = load(PILLAR_LIT % String(part["element"])) as Texture2D
	(part["crown"] as Sprite3D).visible = true
	var beam: Node3D = part["beam"]
	beam.visible = true
	beam.scale.x = 1.0
	var light: OmniLight3D = part["light"]
	if with_sound:
		AudioManager.play_sound("pillar_lit", 0.8 + index * 0.05)
		Fx.flash(self, (part["foot"] as Vector3) + global_position + Vector3(0, PILLAR_HEIGHT, 0), part["color"] as Color, 4.0, 6.0, 0.4)
		_track(create_tween()).tween_property(light, "light_energy", 1.6, 0.5)
	else:
		light.light_energy = 1.6


## The end boss drops from high above to its spot, a shadow grows under it; on the ground it gets
## its life and the fight music starts.
func _boss_falls() -> void:
	var spot: Vector3 = boss_spot()
	var data: Dictionary = Content.enemy(dungeon.end_boss_id)
	var sprite_path: String = String(data.get("sprite", ""))
	var texture: Texture2D = null
	for suffix: String in [".png", "_walk.png"]:
		if ResourceLoader.exists(sprite_path + suffix):
			texture = load(sprite_path + suffix) as Texture2D
			break
	var height: float = float(data.get("height", 1.2))
	var drop: float = float(settings.get("boss_drop", 16.0))
	var fall_time: float = 1.0
	Fx.marker(dungeon.effects, spot, float(data.get("radius", 0.8)), fall_time)
	_turn_view(spot + Vector3(0, drop * 0.45, 0), 0.5)
	if texture:
		_falling = Fx.billboard(texture, height)
		_falling.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		# One picture of the sheet (enemies.json "frame" [width, height], else 48 x 48).
		var frame_size: Array = data.get("frame", [Enemy.FRAME_SIZE, Enemy.FRAME_SIZE])
		_falling.hframes = maxi(1, floori(float(texture.get_width()) / maxi(1, int(frame_size[0]))))
		_falling.pixel_size = height / maxi(1, int(frame_size[-1]))
		dungeon.effects.add_child(_falling)
		_falling.global_position = spot + Vector3(0, drop, 0)
		var tween := _track(create_tween())
		tween.tween_property(_falling, "global_position:y", height / 2.0, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await _wait(0.35):
		return
	_turn_view(spot + Vector3(0, height * 0.6, 0), fall_time - 0.35)
	if not await _wait(fall_time - 0.35):
		return
	_land()


## The end of the scene: the boss is there (frozen for WAKE_TIME while its bar fills), the music
## starts, then the player may move.
func _land() -> void:
	if step != Step.SCENE:
		return
	step = Step.FIGHT
	_spinning = false
	if _falling and is_instance_valid(_falling):
		_falling.queue_free()
	_falling = null
	var spot: Vector3 = boss_spot()
	AudioManager.play_sound("boss_land", 0.8)
	player.shake(0.8)
	Fx.explosion(dungeon.effects, spot, 2.5)
	AudioManager.play_music(String(settings.get("music_fight", "boss")))
	var boss: Enemy = dungeon.start_boss_fight(spot)
	if boss:
		boss.set_physics_process(false)
	_letterbox(false)
	cutscene_changed.emit(false)
	_set_ambient(float(settings.get("ambient_dark", 0.25)) * 1.6, 1.0)
	await get_tree().create_timer(WAKE_TIME, false).timeout
	if not is_inside_tree():
		return
	if boss and is_instance_valid(boss):
		boss.set_physics_process(true)
	player.controls_enabled = true
	player.invulnerable = Player.INVULNERABLE_TIME


## Jumps to the end of the scene at once (admin menu, tests): everything lit, the boss lands now.
func skip_intro() -> void:
	if step == Step.SLEEPING:
		step = Step.SCENE
		cutscene_changed.emit(true)
	if step != Step.SCENE:
		return
	_skipping = true
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_spinning = false
	for part: Dictionary in _parts:
		var crystal: Sprite3D = part["crystal"]
		if crystal and is_instance_valid(crystal):
			crystal.queue_free()
		part["crystal"] = null
	for i in _parts.size():
		_light_pillar(i, false)
	_ring.visible = true
	_altar.modulate = Color.WHITE
	_altar_light.light_energy = 2.2
	_land()
	_skipping = false


# --- Helpers ---------------------------------------------------------------------------------

## Waits `seconds` of game time (stops with the pause). false if the scene was skipped or the
## hall is gone: then the caller stops.
func _wait(seconds: float) -> bool:
	if _skipping or not is_inside_tree():
		return false
	await get_tree().create_timer(seconds, false).timeout
	return is_inside_tree() and not _skipping and step == Step.SCENE


func _track(tween: Tween) -> Tween:
	_tweens.append(tween)
	return tween


## Turns the player's view (body left/right, camera up/down) to `target` in `time` seconds.
func _turn_view(target: Vector3, time: float) -> void:
	var eye: Vector3 = player.camera.global_position
	var flat := Vector3(target.x - eye.x, 0, target.z - eye.z)
	if flat.length() < 0.01:
		return
	var yaw: float = atan2(-flat.x, -flat.z)
	var pitch: float = clampf(atan2(target.y - eye.y, flat.length()), -Player.PITCH_LIMIT, Player.PITCH_LIMIT)
	var start_yaw: float = player.rotation.y
	var start_pitch: float = player.camera.rotation.x
	var tween := _track(create_tween())
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(player):
			player.rotation.y = lerp_angle(start_yaw, yaw, t)
			player.camera.rotation.x = lerpf(start_pitch, pitch, t), 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _letterbox(on: bool) -> void:
	var view: Vector2 = _cinema.get_viewport().get_visible_rect().size if _cinema.is_inside_tree() else Vector2(640, 360)
	var height: float = BAR_HEIGHT if on else 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_bar_top, "size:y", height, 0.6)
	tween.tween_property(_bar_bottom, "size:y", height, 0.6)
	tween.tween_property(_bar_bottom, "position:y", view.y - height, 0.6)
	_bar_bottom.position.y = view.y - _bar_bottom.size.y


func _fade_from_black(time: float) -> void:
	_black.color.a = 1.0
	create_tween().tween_property(_black, "color:a", 0.0, time)


## Changes the light of the whole view (WorldEnvironment ambient) to `factor` x the normal one.
func _set_ambient(factor: float, time: float) -> void:
	if _environment == null:
		return
	var target: float = _ambient_base * factor
	if time <= 0.0:
		_environment.ambient_light_energy = target
		return
	create_tween().tween_property(_environment, "ambient_light_energy", target, time)
