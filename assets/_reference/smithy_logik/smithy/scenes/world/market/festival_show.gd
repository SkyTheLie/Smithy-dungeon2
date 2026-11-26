class_name FestivalShow
extends Node2D
## The magician's show at the spring festival as a cut scene. When story step `step` begins (the
## player comes onto the market), the player walks into the crowd by himself and the magician
## starts talking. Lines of the show (story.json "magician_show") set flags, and this node plays
## what they tell: `pumpkin_flag` = the flying pumpkin (rises, circles three times, bursts into
## petals); a flag of `tries` = that villager walks up to the sword, tugs at it, fails and goes back
## into the crowd, or home out of the map if the flag is in `leave_flags`.
## All positions are scene coordinates of the map (the parent of this node).

## Story step of the show.
@export var step: String = "festival_show"
## The magician (talks once the player stands in the crowd).
@export var magician: StoryNpc
## Where the player stands in the crowd (he looks up at the magician).
@export var player_spot: Vector2 = Vector2(8, 132)
## Height of the road the player comes along, the lanes left and right of the stalls (x, mirrored)
## and the row behind the crowd: the player walks road -> lane -> behind the crowd -> his spot.
@export var road_y: float = 0.0
@export var lane_x: float = 110.0
@export var crowd_back_y: float = 186.0
## Where a villager stands to pull the sword (in front of it, looking up).
@export var sword_spot: Vector2 = Vector2(0, 100)
## Flag -> figure that tries to pull the sword when the flag is set (a StoryNpc or a crowd Sprite2D
## on a resident sheet).
@export var tries: Dictionary = {}
## Flags of `tries` whose figure gives up and goes home instead of back into the crowd.
@export var leave_flags: PackedStringArray = []
## Way home from the sword, the last point outside the map.
@export var leave_path: PackedVector2Array = []
@export var pumpkin_flag: String = "pumpkin_flies"
## Flags set during the show; taken back when it starts (e.g. after loading in the middle of it).
@export var show_flags: PackedStringArray = ["sword_conjured", "crowd_thins", "sword_try_player", "sword_glows",
		"sword_pulled"]
## The conjured sword (a StoryProp) and the player's turn at it: `player_try_flag` = the magician
## steps aside and the player walks round behind the sword (facing the crowd), `glow_flag` = it
## lights up, `pull_flag` = he heaves twice, it jerks and then slides out of the ground (blade and
## tip come out of the mound, earth crumbles) and he holds it up above his head.
@export var sword: Node2D
## The sword picture, child of `sword`: its region is the part above the ground (the mound with
## the slit is a picture of its own and stays).
@export var sword_blade: Sprite2D
## Where the player stands to pull: just behind the sword, his hands on the grip.
@export var pull_spot: Vector2 = Vector2(0, 62)
## Where the magician steps aside to while the player pulls.
@export var magician_aside: Vector2 = Vector2(-40, 66)
## The mound with the slit (a StoryProp of its own): shows up when the conjured sword lands.
@export var sword_ground: Node2D
## The magician conjures the sword: it floats down out of the air and drives into the ground.
@export var conjure_flag: String = "sword_conjured"
@export var player_try_flag: String = "sword_try_player"
@export var glow_flag: String = "sword_glows"
@export var pull_flag: String = "sword_pulled"

const WALK_SPEED: float = 50.0
## How often a villager heaves at the sword, and the seconds per heave.
const PULLS: int = 4
const PULL_TIME: float = 0.6
const PULL_SOUNDS: Array[String] = ["Hnnngh!", "Uff!", "Grrr!", "Hmpf!"]
## Pumpkin: where it starts (relative to the magician), how high it flies, the circle.
const PUMPKIN_START := Vector2(8, -18)
const PUMPKIN_TOP := Vector2(0, -50)
const PUMPKIN_RADIUS: float = 16.0
const PUMPKIN_RISE_TIME: float = 1.0
const PUMPKIN_CIRCLE_TIME: float = 2.4
const PUMPKIN_TEXTURE: Texture2D = preload("res://assets/sprites/props/festival_pumpkin.png")
const PETAL_TEXTURE: Texture2D = preload("res://assets/sprites/props/festival_petal.png")
const PETAL_COLORS: Array[Color] = [Color(1.0, 0.62, 0.78), Color(1.0, 0.95, 0.9), Color(1.0, 0.86, 0.35),
		Color(0.85, 0.55, 0.95)]
## The sword lighting up (modulate) and coming out: the pixels it jerks up with each heave (the
## rest slides out in one go), the seconds of a heave and of the slide, then the lift over the
## head: how high above the player's feet the grip is held and the seconds for it.
const SWORD_GLOW := Color(1.6, 1.8, 2.4)
const SWORD_GLOW_TIME: float = 1.2
const SWORD_JERKS: Array[float] = [2.0, 4.0]
const HEAVE_TIME: float = 0.45
const SWORD_SLIDE_TIME: float = 0.7
const SWORD_HELD_HEIGHT: float = 44.0
const SWORD_LIFT_TIME: float = 0.6
## Earth crumbs flying off the mound while the sword comes out.
## The conjured sword starts this high above its spot and floats down in SWORD_FLOAT_TIME.
const SWORD_FLOAT_HEIGHT: float = 70.0
const SWORD_FLOAT_TIME: float = 1.3
const SWORD_PLUNGE_TIME: float = 0.18
const SPARK_COLOR := Color(0.55, 0.8, 1.0)
const CRUMB_COLORS: Array[Color] = [Color(0.5, 0.27, 0.17), Color(0.31, 0.19, 0.18), Color(0.45, 0.43, 0.45)]

var _started: bool = false
## Flags whose animation already ran.
var _played: Dictionary = {}


func _ready() -> void:
	y_sort_enabled = true  # figures walking home are sorted with the rest of the map
	GameState.story.step_started.connect(func(_step: String) -> void: _try_start())
	GameState.story.changed.connect(_on_story_changed)
	Events.cutscene_requested.connect(_on_cutscene)
	_try_start.call_deferred()


## "cutscene:sword_sparks" (story.json magician_sword): the sword over the player's head falls
## apart into blue sparks that rise into the evening sky.
func _on_cutscene(cutscene_id: String) -> void:
	if cutscene_id == "sword_sparks" and _started:
		_sword_to_sparks()


func _try_start() -> void:
	if _started or GameState.story.step != step:
		return
	_started = true
	var flags: Array = Array(show_flags) + tries.keys() + [pumpkin_flag]
	GameState.story.clear_flags(flags)
	_played.clear()
	await get_tree().physics_frame
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null:
		return
	player.auto_walk(_way_into_crowd(player.global_position), "up")
	await player.auto_walk_finished
	if magician:
		magician.talk()


## From where the player is along the road, down the lane on his side, behind the crowd to his spot.
func _way_into_crowd(from: Vector2) -> PackedVector2Array:
	var start: Vector2 = _map().to_local(from)
	var lane: float = -lane_x if start.x < player_spot.x else lane_x
	var way := PackedVector2Array([Vector2(start.x, road_y), Vector2(lane, road_y), Vector2(lane, crowd_back_y),
			Vector2(player_spot.x, crowd_back_y), player_spot])
	return _to_global(way)


func _on_story_changed() -> void:
	if not _started:
		return
	var story: Story = GameState.story
	if story.has_flag(conjure_flag) and not _played.has(conjure_flag):
		_played[conjure_flag] = true
		_conjure_sword()
	if story.has_flag(pumpkin_flag) and not _played.has(pumpkin_flag):
		_played[pumpkin_flag] = true
		_fly_pumpkin()
	for flag: String in tries:
		if story.has_flag(flag) and not _played.has(flag):
			_played[flag] = true
			var figure := get_node_or_null(tries[flag]) as Node2D
			if figure:
				_try_sword(figure, leave_flags.has(flag))
	for flag: String in [player_try_flag, glow_flag, pull_flag]:
		if story.has_flag(flag) and not _played.has(flag):
			_played[flag] = true
			if flag == player_try_flag:
				_player_to_sword()
			elif flag == glow_flag:
				_glow_sword()
			else:
				_pull_sword()


# --- The player's turn ---------------------------------------------------------------

## The magician steps aside, the player walks from his spot in the crowd round the sword to
## `pull_spot` behind it and faces the crowd.
func _player_to_sword() -> void:
	if magician:
		_step_aside(magician)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null:
		return
	var home: Vector2 = _map().to_local(player.global_position)
	var side: float = pull_spot.x + (24.0 if home.x >= pull_spot.x else -24.0)
	player.auto_walk(_to_global([Vector2(home.x, sword_spot.y), Vector2(side, sword_spot.y),
			Vector2(side, pull_spot.y), pull_spot]), "down")


func _step_aside(figure: Node2D) -> void:
	var sprite: Sprite2D = _sprite_of(figure)
	await _walk(figure, sprite, _to_global([magician_aside]))
	_face(sprite, "right" if magician_aside.x < pull_spot.x else "left")


## The sword lights up brighter and brighter (the mound stays as it is).
func _glow_sword() -> void:
	if sword_blade:
		create_tween().tween_property(sword_blade, "modulate", SWORD_GLOW, SWORD_GLOW_TIME)


## The player heaves twice (leans back, shakes), each time the sword jerks up a little and earth
## crumbles off the mound; then it slides out of the ground to its tip, he lifts it over his head
## and turns it point up.
func _pull_sword() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if sword_blade == null or player == null:
		return
	if player.is_auto_walking():
		await player.auto_walk_finished
	var rest_y: float = sword_blade.position.y
	var rest_height: float = sword_blade.region_rect.size.y
	var buried: float = sword_blade.texture.get_height() - rest_height
	var home: Vector2 = player.position
	var risen: float = 0.0
	for jerk in SWORD_JERKS:
		var heave := create_tween()
		heave.tween_property(player, "position:y", home.y - 1.0, HEAVE_TIME * 0.4)
		for side in [-1.0, 1.0, -1.0, 0.0]:
			heave.tween_property(player, "position:x", home.x + side, HEAVE_TIME * 0.1)
		await heave.finished
		risen += jerk
		_set_sword_risen(risen, rest_y, rest_height)
		_crumble(6, true)
		var back := create_tween()
		back.tween_property(player, "position:y", home.y, HEAVE_TIME * 0.2)
		await back.finished
	player.position = home
	_crumble(14, false)
	var slide := create_tween()
	slide.tween_method(_set_sword_risen.bind(rest_y, rest_height), risen, buried, SWORD_SLIDE_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await slide.finished
	_crumble(8, true)
	# Lift: the grip goes from where it is to above the head, the point turns up.
	player.raise_arms("down")
	var grip: Vector2 = sword_blade.global_position + Vector2(8, 7)
	sword_blade.flip_v = true
	var flipped_grip := Vector2(8, sword_blade.texture.get_height() - 8)
	sword_blade.global_position = grip - flipped_grip
	var held: Vector2 = player.global_position + Vector2(0, -SWORD_HELD_HEIGHT) - flipped_grip
	create_tween().tween_property(sword_blade, "global_position", held, SWORD_LIFT_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The whole sword shines in the air above its spot, floats down point first and drives into the
## ground (earth bursts up); the mound fades in as it lands.
func _conjure_sword() -> void:
	if sword == null or sword_blade == null:
		return
	var rest_y: float = sword_blade.position.y
	var rest_height: float = sword_blade.region_rect.size.y
	var buried: float = sword_blade.texture.get_height() - rest_height
	var home: Vector2 = sword.position
	_set_sword_risen(buried, rest_y, rest_height)
	sword.position = home + Vector2(0, -SWORD_FLOAT_HEIGHT)
	sword.modulate = Color(1, 1, 1, 0)
	sword_blade.modulate = SWORD_GLOW
	if sword_ground:
		sword_ground.modulate.a = 0.0
	AudioManager.play_sound("skill_used", 0.7)
	var fall := create_tween()
	fall.tween_property(sword, "modulate:a", 1.0, 0.4)
	fall.parallel().tween_property(sword, "position", home, SWORD_FLOAT_TIME) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fall.tween_method(_set_sword_risen.bind(rest_y, rest_height), buried, 0.0, SWORD_PLUNGE_TIME) 			.set_ease(Tween.EASE_IN)
	await fall.finished
	if not is_instance_valid(sword):
		return
	AudioManager.play_sound("anvil_perfect", 0.8)
	_crumble(16, true)
	if sword_ground:
		create_tween().tween_property(sword_ground, "modulate:a", 1.0, 0.12)
	create_tween().tween_property(sword_blade, "modulate", Color.WHITE, 0.8)


## The held sword flickers and falls apart into blue sparks rising into the sky; the player lowers
## his arms. The StoryProp hides it for good with the flag of the next line.
func _sword_to_sparks() -> void:
	if sword_blade == null or not sword_blade.is_visible_in_tree():
		return
	AudioManager.play_sound("item_reveal", 0.6)
	var sparks := CPUParticles2D.new()
	sparks.amount = 40
	sparks.lifetime = 1.6
	sparks.one_shot = true
	sparks.explosiveness = 0.3
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(3, 18)
	sparks.direction = Vector2.UP
	sparks.spread = 30.0
	sparks.initial_velocity_min = 14.0
	sparks.initial_velocity_max = 34.0
	sparks.gravity = Vector2(0, -20)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color = SPARK_COLOR
	sparks.z_index = 2
	add_child(sparks)
	sparks.global_position = sword_blade.global_position + Vector2(8, sword_blade.region_rect.size.y / 2.0)
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	var fade := create_tween()
	for i in 3:
		fade.tween_property(sword_blade, "modulate", SWORD_GLOW * 1.3, 0.1)
		fade.tween_property(sword_blade, "modulate", Color(1, 1, 1, 0.6), 0.1)
	fade.tween_property(sword_blade, "modulate:a", 0.0, 0.5)
	await fade.finished
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player and not player.is_auto_walking():
		player.auto_walk(PackedVector2Array([player.global_position]), "down")


## Shows `risen` pixels more of the sword above the ground: the picture moves up and its region
## grows by as much, so the ground line stays where it is.
func _set_sword_risen(risen: float, rest_y: float, rest_height: float) -> void:
	var pixels: float = roundf(risen)
	sword_blade.position.y = rest_y - pixels
	sword_blade.region_rect.size.y = rest_height + pixels


## Earth crumbs from the slit: a burst (`burst`) or a trickle while the sword slides out.
func _crumble(amount: int, burst: bool) -> void:
	var crumbs := CPUParticles2D.new()
	crumbs.amount = amount
	crumbs.lifetime = 0.55
	crumbs.one_shot = true
	crumbs.explosiveness = 1.0 if burst else 0.0
	crumbs.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	crumbs.emission_rect_extents = Vector2(3, 0.5)
	crumbs.direction = Vector2.UP
	crumbs.spread = 75.0
	crumbs.initial_velocity_min = 18.0
	crumbs.initial_velocity_max = 42.0
	crumbs.gravity = Vector2(0, 170)
	crumbs.scale_amount_min = 1.0
	crumbs.scale_amount_max = 2.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	colors.colors = PackedColorArray(CRUMB_COLORS)
	crumbs.color_initial_ramp = colors
	crumbs.z_index = 1
	sword.add_child(crumbs)
	crumbs.position = Vector2(0, -2)
	crumbs.emitting = true
	crumbs.finished.connect(crumbs.queue_free)


# --- Villagers at the sword ------------------------------------------------------------

## Walks up (first up to the sword's row, then sideways), heaves, then back or home.
func _try_sword(figure: Node2D, goes_home: bool) -> void:
	var sprite: Sprite2D = _sprite_of(figure)
	var home: Vector2 = _map().to_local(figure.global_position)
	await _walk(figure, sprite, _to_global([Vector2(home.x, sword_spot.y), sword_spot]))
	await _heave(figure, sprite)
	if not is_instance_valid(figure):
		return
	if goes_home:
		# A crowd sprite leaves its group, so the group walking out later doesn't move it as well.
		if figure is Sprite2D:
			figure.reparent(self)
		await _walk(figure, sprite, _to_global(Array(leave_path)))
		if is_instance_valid(figure):
			figure.hide()
	else:
		await _walk(figure, sprite, _to_global([Vector2(home.x, sword_spot.y), home]))
		_face(sprite, "up")


## Walks along `points` (global), straight from one to the next, with the walk frames.
func _walk(figure: Node2D, sprite: Sprite2D, points: PackedVector2Array) -> void:
	var time: float = 0.0
	for point in points:
		while is_instance_valid(figure) and figure.global_position.distance_to(point) > 0.5:
			var delta: float = get_physics_process_delta_time()
			var offset: Vector2 = point - figure.global_position
			figure.global_position += offset.limit_length(WALK_SPEED * delta)
			time += delta
			var frame: int = 1 + int(time * CharacterBaker.WALK_SPEED) % (CharacterBaker.COLUMNS - 1)
			_face(sprite, _direction_name(offset), frame)
			await get_tree().physics_frame
	if is_instance_valid(figure):
		_face(sprite, "up")


## Pulls at the sword a few times: leans back, shakes, a grunt above the head. Nothing moves.
func _heave(figure: Node2D, sprite: Sprite2D) -> void:
	if not is_instance_valid(figure):
		return
	_face(sprite, "up")
	var grunt := _make_grunt(PULL_SOUNDS.pick_random())
	figure.add_child(grunt)
	var rest: Vector2 = sprite.position
	var tween := create_tween()
	for i in PULLS:
		tween.tween_property(sprite, "position", rest + Vector2(0, 2), PULL_TIME * 0.3)
		for shake in [-1.0, 1.0, -1.0, 1.0]:
			tween.tween_property(sprite, "position", rest + Vector2(shake, 2), PULL_TIME * 0.1)
		tween.tween_property(sprite, "position", rest, PULL_TIME * 0.3)
	await tween.finished
	grunt.queue_free()


func _make_grunt(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(-30, -52)
	label.size = Vector2(60, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 3
	return label


## The picture of a figure: a StoryNpc's "Figure", or the crowd sprite itself.
func _sprite_of(figure: Node2D) -> Sprite2D:
	if figure is Sprite2D:
		return figure as Sprite2D
	return figure.get_node_or_null("Figure") as Sprite2D


func _face(sprite: Sprite2D, direction: String, frame: int = 0) -> void:
	if sprite and sprite.region_enabled:
		sprite.region_rect = CharacterBaker.get_frame_rect(direction, frame)


static func _direction_name(offset: Vector2) -> String:
	if absf(offset.x) > absf(offset.y):
		return "right" if offset.x > 0.0 else "left"
	return "down" if offset.y > 0.0 else "up"


# --- The flying pumpkin ---------------------------------------------------

## Rises from the magician's hand, circles three times above him and bursts into petals.
func _fly_pumpkin() -> void:
	var center: Vector2 = magician.global_position + PUMPKIN_TOP if magician else global_position
	var pumpkin := Sprite2D.new()
	pumpkin.texture = PUMPKIN_TEXTURE
	pumpkin.z_index = 5
	add_child(pumpkin)
	pumpkin.global_position = (magician.global_position if magician else global_position) + PUMPKIN_START
	pumpkin.scale = Vector2.ZERO
	var start: Vector2 = center + Vector2(PUMPKIN_RADIUS, 0)
	var tween := create_tween()
	tween.tween_property(pumpkin, "scale", Vector2.ONE, 0.25)
	tween.tween_property(pumpkin, "global_position", start, PUMPKIN_RISE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_circle_pumpkin.bind(pumpkin, center), 0.0, TAU * 3.0, PUMPKIN_CIRCLE_TIME)
	tween.tween_property(pumpkin, "global_position", center, 0.2)
	tween.tween_property(pumpkin, "scale", Vector2(1.6, 1.6), 0.12)
	await tween.finished
	_burst_petals(pumpkin.global_position)
	pumpkin.queue_free()


## One point of the circles (`angle` from 0 to 3 turns); it spins while it flies.
func _circle_pumpkin(angle: float, pumpkin: Node2D, center: Vector2) -> void:
	pumpkin.global_position = center + Vector2(cos(angle), sin(angle)) * PUMPKIN_RADIUS
	pumpkin.rotation = angle * 0.5


func _burst_petals(at: Vector2) -> void:
	var petals := CPUParticles2D.new()
	petals.texture = PETAL_TEXTURE
	petals.z_index = 5
	petals.one_shot = true
	petals.emitting = false
	petals.amount = 48
	petals.lifetime = 1.8
	petals.explosiveness = 1.0
	petals.spread = 180.0
	petals.direction = Vector2.UP
	petals.initial_velocity_min = 25.0
	petals.initial_velocity_max = 70.0
	petals.gravity = Vector2(0, 45)
	petals.damping_min = 10.0
	petals.damping_max = 25.0
	petals.scale_amount_min = 1.0
	petals.scale_amount_max = 2.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colors.colors = PackedColorArray(PETAL_COLORS)
	petals.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.7, 1.0])
	petals.color_ramp = fade
	add_child(petals)
	petals.global_position = at
	petals.emitting = true
	petals.finished.connect(petals.queue_free)


func _map() -> Node2D:
	return get_parent() as Node2D


func _to_global(points: Array) -> PackedVector2Array:
	var way := PackedVector2Array()
	for point: Vector2 in points:
		way.append(_map().to_global(point))
	return way
