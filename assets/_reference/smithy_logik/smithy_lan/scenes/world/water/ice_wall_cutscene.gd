class_name IceWallCutscene
extends Node2D
## The crown of the ice wall (part 6): the ice crystal, the king's shadow rift and Subar's fall.
## Each beat is a dialogue line with "hide_for" (the box is out of sight while it plays) and
## "cutscene:<id>":
## singing_wall_open: wall_hands (the hands glow on the ice), wall_sing (the wall rings with light),
##   wall_crystal (the crystal floats out into the player's hands), wall_rift (a shadow rift tears
##   open, ice_wall/shadow_rift.png), wall_step_out (the king and Lake step out of it)
## wall_aftermath: wall_stagger (Lake reels back to the edge), wall_crack (a crack runs across the
##   crown, ice_wall/ice_crack.png), wall_fall (Subar shoves the player back and slides over the
##   edge, only his head and hands still show), wall_roll (the crystal rolls towards the crack)
## wall_save_subar: save_dive (the player throws himself to the edge), save_pull (Torgai helps,
##   Subar is pulled up), king_take (the king takes the crystal out of the snow), king_leave (king
##   and Lake go back into the rift, it closes; flag king_left_wall)
## wall_save_crystal: crystal_dive (the player catches the crystal at the edge), harpoon (Torgai's
##   line catches Subar), king_take, king_leave, subar_up (Torgai and Kahn pull him up, wounded)

@export var king: NodePath
@export var dark_lake: NodePath
@export var subar: NodePath
@export var subar_down: NodePath
@export var torgai: NodePath
@export var kahn: NodePath
@export var singing_wall: NodePath

const RIFT: String = "res://assets/sprites/ice_wall/shadow_rift.png"
const CRACK: String = "res://assets/sprites/ice_wall/ice_crack.png"
const CRYSTAL: String = "res://assets/sprites/items/holy_crystals/holy_ice_crystal.png"
const KNEEL_DARK: String = "res://assets/sprites/residents/lake_dark_kneel.png"
const LAKE_DARK: String = "res://assets/sprites/residents/lake_dark.png"
const RIFT_FRAMES: int = 8
const BLUE: Color = Color(0.5, 0.8, 1.0)
## Scene coordinates on the crown.
const RIFT_SPOT: Vector2 = Vector2(-5, 4)
const CRACK_Y: float = 182.0
const EDGE_Y: float = 200.0
## The fall is right of the player: right below him the hotbar would hide the edge.
const PLAYER_SPOT: Vector2 = Vector2(60, 172)
const SUBAR_EDGE: Vector2 = Vector2(210, 206)
const CRYSTAL_EDGE: Vector2 = Vector2(250, 194)

var _fx: WorldVfx
var _glow: Node2D
var _crystal: Sprite2D
var _rift: Sprite2D
var _hanging: Sprite2D
var _rope: Line2D


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)
	_fx = WorldVfx.new()
	add_child(_fx)


func _process(_delta: float) -> void:
	# the rift swirls as long as it is there
	if _rift and is_instance_valid(_rift):
		_rift.frame = int(Time.get_ticks_msec() / 110) % RIFT_FRAMES


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"wall_hands":
			_hands()
		"wall_sing":
			_sing()
		"wall_crystal":
			_take_crystal()
		"wall_rift":
			_open_rift()
		"wall_step_out":
			_step_out()
		"wall_stagger":
			_stagger()
		"wall_crack":
			_crack()
		"wall_fall":
			_fall()
		"wall_roll":
			_roll()
		"save_dive":
			_dive(SUBAR_EDGE + Vector2(0, -14), "down")
		"save_pull":
			_pull_subar(false)
		"crystal_dive":
			_crystal_dive()
		"harpoon":
			_harpoon()
		"king_take":
			_king_take()
		"king_leave":
			_king_leave()
		"subar_up":
			_pull_subar(true)


func _node(path: NodePath) -> Node2D:
	return get_node_or_null(path) as Node2D


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func _walk_player(target: Vector2, facing: String, speed: float = 90.0) -> void:
	var player := _player()
	if player and player.has_method("auto_walk"):
		player.call("auto_walk", PackedVector2Array([to_global(target)]), facing, speed)


func _crystal_sprite() -> Sprite2D:
	if _crystal == null or not is_instance_valid(_crystal):
		_crystal = Sprite2D.new()
		_crystal.texture = load(CRYSTAL)
		_crystal.region_enabled = true  # the crystal sheet holds 48 px frames
		_crystal.region_rect = Rect2(0, 0, 48, 48)
		_crystal.scale = Vector2.ONE * 0.4
		_crystal.z_index = 2
		_crystal.z_as_relative = false
		add_child(_crystal)
	return _crystal


# --- singing_wall_open ---------------------------------------------------------------------------

func _hands() -> void:
	var player := _player()
	if player == null:
		return
	_glow = Node2D.new()
	add_child(_glow)
	_glow.global_position = player.global_position + Vector2(0, -10)
	_fx.add_loop(_glow, "glow", BLUE)
	_fx.spawn("buff", _glow.global_position, BLUE)
	AudioManager.play_sound("skill_used", 0.8)


func _sing() -> void:
	var wall := _node(singing_wall)
	if wall == null:
		return
	AudioManager.play_sound("rarity_up", 0.7)
	var sprite := wall.get_node_or_null("Sprite2D") as CanvasItem
	if sprite:
		var pulse := create_tween().set_loops(3)
		pulse.tween_property(sprite, "modulate", Color(1.5, 1.7, 2.0), 0.25)
		pulse.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	for i in 4:
		_fx.spawn("area_ice", wall.global_position + Vector2(randf_range(-40, 40), randf_range(-60, -10)), Color.WHITE)
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree():
			return


func _take_crystal() -> void:
	var wall := _node(singing_wall)
	var player := _player()
	if wall == null or player == null:
		return
	var crystal := _crystal_sprite()
	crystal.global_position = wall.global_position + Vector2(0, -44)
	crystal.modulate.a = 0.0
	_fx.spawn("light_hit", crystal.global_position, BLUE)
	var tween := create_tween()
	tween.tween_property(crystal, "modulate:a", 1.0, 0.3)
	tween.tween_property(crystal, "global_position", player.global_position + Vector2(0, -14), 0.9) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(crystal, "modulate:a", 0.0, 0.3)
	await tween.finished
	if _glow:
		_fx.remove_loop(_glow)


func _open_rift() -> void:
	# the flag king_on_wall brings the king and Lake: they wait unseen until the rift is open
	for path in [king, dark_lake]:
		var npc := _node(path)
		if npc:
			npc.modulate.a = 0.0
	_rift = Sprite2D.new()
	_rift.texture = load(RIFT)
	_rift.hframes = RIFT_FRAMES
	_rift.offset = Vector2(0, -44)
	add_child(_rift)
	_rift.position = RIFT_SPOT
	AudioManager.play_sound("rock_break", 0.6)
	_shake(0.5, 1.5)
	# it tears open from a thin line
	_rift.scale = Vector2(0.05, 0.6)
	var tween := create_tween()
	tween.tween_property(_rift, "scale:y", 1.0, 0.3)
	tween.tween_property(_rift, "scale:x", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.spawn("area_shadow", to_global(RIFT_SPOT), Color.WHITE)


func _step_out() -> void:
	for path in [king, dark_lake]:
		var npc := _node(path)
		if npc == null:
			continue
		var home: Vector2 = npc.position
		npc.global_position = to_global(RIFT_SPOT)
		npc.modulate.a = 0.0
		create_tween().tween_property(npc, "modulate:a", 1.0, 0.4)
		_walk_npc(npc, npc.get_parent().to_global(home), "down", 75.0)


# --- wall_aftermath ------------------------------------------------------------------------------

func _stagger() -> void:
	var lake := _node(dark_lake)
	_walk_player(PLAYER_SPOT, "up", 120.0)
	if lake == null:
		return
	var figure := lake.get_node_or_null("Figure") as Sprite2D
	var tween := create_tween()
	tween.tween_property(lake, "position", lake.position + Vector2(0, -12), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	if figure and is_instance_valid(figure):
		# he leans on his black sword, half on one knee
		figure.texture = load(KNEEL_DARK)
		figure.region_rect = Rect2(3 * 48, 0, 48, 48)


func _crack() -> void:
	var texture: Texture2D = load(CRACK)
	AudioManager.play_sound("rock_break", 0.8)
	_shake(1.2, 1.5)
	# three pieces from the king's side across the crown to the right edge, one after another
	var width: float = texture.get_width()
	var x: float = -150.0
	while x < 230.0:
		var piece := Sprite2D.new()
		piece.texture = texture
		piece.centered = false
		piece.region_enabled = true
		piece.region_rect = Rect2(0, 0, 0, texture.get_height())
		piece.z_index = -1
		add_child(piece)
		piece.position = Vector2(x, CRACK_Y - texture.get_height() / 2.0)
		var grow := create_tween()
		grow.tween_property(piece, "region_rect:size:x", width, 0.35)
		await grow.finished
		if not is_inside_tree():
			return
		x += width - 4.0


func _fall() -> void:
	var player := _player()
	var subar_npc := _node(subar)
	# Subar shoves the player back into the snow
	if player and player.has_method("auto_walk"):
		player.call("auto_walk", PackedVector2Array([player.global_position + Vector2(-26, -22)]), "down", 160.0)
	if subar_npc:
		_walk_npc(subar_npc, to_global(PLAYER_SPOT + Vector2(10, 4)), "left", 120.0)
	await get_tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return
	_fx.spawn("area_ice", to_global(SUBAR_EDGE + Vector2(0, -14)), Color.WHITE)
	AudioManager.play_sound("rock_break", 1.0)
	_shake(0.5, 2.0)
	if subar_npc:
		await _walk_npc(subar_npc, to_global(SUBAR_EDGE + Vector2(0, -6)), "up", 110.0)
		if not is_inside_tree():
			return
		subar_npc.modulate.a = 0.0
	_hang(subar_npc)


## Subar hangs at the edge: only his head and hands above it (top of his standing figure).
func _hang(subar_npc: Node2D) -> void:
	if _hanging and is_instance_valid(_hanging):
		return
	var figure := subar_npc.get_node_or_null("Figure") as Sprite2D if subar_npc else null
	_hanging = Sprite2D.new()
	if figure:
		_hanging.texture = figure.texture
		_hanging.region_enabled = true
		var rect: Rect2 = CharacterBaker.get_frame_rect("up")
		_hanging.region_rect = Rect2(rect.position, Vector2(rect.size.x, 22))
		_hanging.scale = figure.scale
	_hanging.centered = true
	_hanging.offset = Vector2(0, -11)
	_hanging.z_index = 1
	_hanging.z_as_relative = false
	add_child(_hanging)
	_hanging.position = SUBAR_EDGE + Vector2(0, 8)


func _roll() -> void:
	var player := _player()
	var crystal := _crystal_sprite()
	crystal.modulate.a = 1.0
	crystal.global_position = (player.global_position if player else to_global(PLAYER_SPOT)) + Vector2(0, -4)
	var tween := create_tween().set_parallel()
	tween.tween_property(crystal, "global_position", to_global(CRYSTAL_EDGE), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(crystal, "rotation", TAU * 1.5, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- the rescue ----------------------------------------------------------------------------------

func _dive(target: Vector2, facing: String) -> void:
	_walk_player(target, facing, 170.0)
	await get_tree().create_timer(0.45, false).timeout
	if not is_inside_tree():
		return
	_fx.spawn("area_ice", to_global(target + Vector2(0, 4)), Color.WHITE)
	var player := _player()
	if player:
		_glow = Node2D.new()
		add_child(_glow)
		_glow.global_position = player.global_position + Vector2(0, 6)
		_fx.add_loop(_glow, "glow", BLUE)


func _crystal_dive() -> void:
	# the lying Subar of the flag subar_wounded waits until he is pulled up
	var down := _node(subar_down)
	if down:
		down.modulate.a = 0.0
	_hang(_node(subar))
	await _dive(CRYSTAL_EDGE + Vector2(-2, -12), "down")
	var player := _player()
	if player and player.has_method("is_auto_walking") and player.call("is_auto_walking"):
		await player.auto_walk_finished
	if player and _crystal and is_inside_tree():
		create_tween().tween_property(_crystal, "global_position", player.global_position + Vector2(0, 2), 0.2)


func _harpoon() -> void:
	var torgai_npc := _node(torgai)
	if torgai_npc == null or _hanging == null:
		return
	await _walk_npc(torgai_npc, to_global(SUBAR_EDGE + Vector2(-26, -20)), "down", 120.0)
	if not is_inside_tree():
		return
	_rope = Line2D.new()
	_rope.width = 1.0
	_rope.default_color = Color(0.82, 0.74, 0.55)
	_rope.z_index = 2
	_rope.z_as_relative = false
	add_child(_rope)
	var from: Vector2 = to_local(torgai_npc.global_position) + Vector2(4, -12)
	var to: Vector2 = _hanging.position + Vector2(0, -6)
	_rope.points = PackedVector2Array([from, from])
	var throw := create_tween()
	throw.tween_method(func(t: float) -> void:
		if is_instance_valid(_rope):
			_rope.points = PackedVector2Array([from, from.lerp(to, t)]),
		0.0, 1.0, 0.3)
	await throw.finished
	AudioManager.play_sound("pickaxe_hit", 0.6)
	# the line jerks Torgai almost over the edge, Subar slips lower
	var jerk := create_tween().set_parallel()
	jerk.tween_property(torgai_npc, "position:y", torgai_npc.position.y + 8.0, 0.2)
	jerk.tween_property(_hanging, "position:y", _hanging.position.y + 5.0, 0.2)
	jerk.tween_method(func(_t: float) -> void:
		if is_instance_valid(_rope) and is_instance_valid(torgai_npc):
			_rope.points = PackedVector2Array([to_local(torgai_npc.global_position) + Vector2(4, -12), _hanging.position + Vector2(0, -6)]),
		0.0, 1.0, 0.2)
	_shake(0.3, 1.0)


func _king_take() -> void:
	var king_npc := _node(king)
	if _crystal == null:
		return
	var spot: Vector2 = _crystal.global_position
	if king_npc:
		# out of the shadows right behind the crystal
		_fx.spawn("area_shadow", spot + Vector2(10, -4), Color.WHITE)
		var fade := create_tween()
		fade.tween_property(king_npc, "modulate:a", 0.0, 0.25)
		fade.tween_callback(func() -> void:
			king_npc.global_position = spot + Vector2(14, -6)
			king_npc.call("_face", "left"))
		fade.tween_property(king_npc, "modulate:a", 1.0, 0.35)
		await fade.finished
		if not is_inside_tree():
			return
	var take := create_tween()
	take.tween_property(_crystal, "global_position", spot + Vector2(10, -18), 0.5)
	take.tween_property(_crystal, "modulate:a", 0.0, 0.3)


func _king_leave() -> void:
	if _glow:
		_fx.remove_loop(_glow)
	var walkers: Array[Node2D] = []
	for path in [king, dark_lake]:
		var npc := _node(path)
		if npc:
			walkers.append(npc)
	var lake := _node(dark_lake)
	if lake:
		var figure := lake.get_node_or_null("Figure") as Sprite2D
		if figure:
			figure.texture = load(LAKE_DARK)
	if _rift == null or not is_instance_valid(_rift):
		_open_rift()
		for npc in walkers:
			npc.modulate.a = 1.0
	for npc in walkers:
		_fx.spawn("area_shadow", npc.global_position, Color.WHITE)
		var fade := create_tween().set_parallel()
		fade.tween_property(npc, "global_position", to_global(RIFT_SPOT), 0.9).set_trans(Tween.TRANS_QUAD)
		fade.tween_property(npc, "modulate:a", 0.0, 0.9)
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree():
		return
	var close := create_tween()
	close.tween_property(_rift, "scale:x", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	close.tween_callback(func() -> void:
		if is_instance_valid(_rift):
			_rift.queue_free())
	GameState.run_story_action("set_flag:king_left_wall")


func _pull_subar(wounded: bool) -> void:
	var torgai_npc := _node(torgai)
	if not wounded and torgai_npc:
		await _walk_npc(torgai_npc, to_global(SUBAR_EDGE + Vector2(20, -16)), "down", 120.0)
	elif wounded:
		var kahn_npc := _node(kahn)
		if kahn_npc:
			await _walk_npc(kahn_npc, to_global(SUBAR_EDGE + Vector2(-22, -16)), "down", 120.0)
	if not is_inside_tree():
		return
	if _rope:
		_rope.queue_free()
		_rope = null
	if _glow:
		_fx.remove_loop(_glow)
	if _hanging:
		var up := create_tween()
		up.tween_property(_hanging, "position:y", _hanging.position.y - 14.0, 0.6)
		await up.finished
		if is_instance_valid(_hanging):
			_hanging.queue_free()
		_hanging = null
	if not is_inside_tree():
		return
	_fx.spawn("area_ice", to_global(SUBAR_EDGE + Vector2(0, -8)), Color.WHITE)
	var standing := _node(subar_down if wounded else subar)
	if standing:
		standing.global_position = to_global(SUBAR_EDGE + Vector2(0, -16))
		standing.modulate.a = 1.0
		if not wounded:
			standing.call("_face", "up")


## A story NPC walks to `target` (global) with its walk frames.
func _walk_npc(npc: Node2D, target: Vector2, facing: String, speed: float) -> void:
	var shape := npc.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	while is_inside_tree() and is_instance_valid(npc) and npc.global_position.distance_to(target) > 1.0:
		npc.call("_walk_step", target - npc.global_position, speed, get_process_delta_time())
		await get_tree().process_frame
	if is_instance_valid(npc):
		npc.global_position = target
		npc.set("facing", facing)
		npc.call("_face", facing)


func _shake(seconds: float, strength: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + seconds
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera):
		camera.offset = home + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home
