class_name IceWallCutscene
extends StoryCutscene
## The crown of the ice wall (part 6): the ice crystal, the king's shadow rift and Subar's fall.
## Each beat is a dialogue line with "hide_for" (the box is out of sight while it plays) and
## "cutscene:<id>":
## singing_wall_open: wall_hands (the hands glow on the ice), wall_sing (the wall rings with light),
##   wall_crystal (the crystal floats out into the player's hands), wall_rift (a shadow rift tears
##   open, ice_wall/shadow_rift.png), wall_step_out (the king and Lake step out of it)
## wall_aftermath: wall_stagger (Lake stumbles back and kneels on his sword, the player goes to the
##   crack), wall_crack (a crack runs across the
##   crown, ice_wall/ice_crack.png), wall_fall (Subar shoves the player back and slides over the
##   edge right below the player, only his head and hands still show), wall_roll (the crystal rolls
##   towards the crack); all with fixed short tweens, over before the box comes back
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
const RIFT_FRAMES: int = 8
const BLUE: Color = Color(0.5, 0.8, 1.0)
## Scene coordinates on the crown.
const RIFT_SPOT: Vector2 = Vector2(-5, 4)
const CRACK_Y: float = 182.0
const EDGE_Y: float = 200.0
## Where the player stands when the ice breaks: at the crack, right above Subar's fall (right of
## the middle: right below the middle the hotbar would hide the edge).
const PLAYER_SPOT: Vector2 = Vector2(196, 170)
## Subar's shove throws the player this far back (up-left, into the snow).
const SHOVE: Vector2 = Vector2(-30, -24)
## Lake's stumbling steps backwards (towards the edge of the wall behind him).
const STAGGER_STEPS: Array[Vector2] = [Vector2(-3, -5), Vector2(4, -5), Vector2(-2, -4)]
const SUBAR_EDGE: Vector2 = Vector2(210, 206)
const CRYSTAL_EDGE: Vector2 = Vector2(250, 194)

var _glow: Node2D
var _crystal: Sprite2D
var _rift: Sprite2D
var _hanging: Sprite2D
var _rope: Line2D


func _ready() -> void:
	super()


func _process(_delta: float) -> void:
	# the rift swirls as long as it is there
	if _rift and is_instance_valid(_rift):
		_rift.frame = int(Time.get_ticks_msec() / 110) % RIFT_FRAMES


func _play_beat(id: String) -> bool:
	match id:
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
		_:
			return false
	return true


func _walk_player(target: Vector2, facing: String, speed: float = 90.0) -> void:
	var smith := player()
	if smith and smith.has_method("auto_walk"):
		smith.call("auto_walk", PackedVector2Array([to_global(target)]), facing, speed)


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
	var smith := player()
	if smith == null:
		return
	_glow = Node2D.new()
	add_child(_glow)
	_glow.global_position = smith.global_position + Vector2(0, -10)
	fx.add_loop(_glow, "glow", BLUE)
	fx.spawn("buff", _glow.global_position, BLUE)
	AudioManager.play_sound("skill_used", 0.8)


func _sing() -> void:
	var wall := node2d(singing_wall)
	if wall == null:
		return
	AudioManager.play_sound("rarity_up", 0.7)
	var sprite := wall.get_node_or_null("Sprite2D") as CanvasItem
	if sprite:
		var pulse := create_tween().set_loops(3)
		pulse.tween_property(sprite, "modulate", Color(1.5, 1.7, 2.0), 0.25)
		pulse.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	for i in 4:
		fx.spawn("area_ice", wall.global_position + Vector2(randf_range(-40, 40), randf_range(-60, -10)), Color.WHITE)
		if not await wait(0.3):
			return


func _take_crystal() -> void:
	var wall := node2d(singing_wall)
	var smith := player()
	if wall == null or smith == null:
		return
	var crystal := _crystal_sprite()
	crystal.global_position = wall.global_position + Vector2(0, -44)
	crystal.modulate.a = 0.0
	fx.spawn("light_hit", crystal.global_position, BLUE)
	var tween := create_tween()
	tween.tween_property(crystal, "modulate:a", 1.0, 0.3)
	tween.tween_property(crystal, "global_position", smith.global_position + Vector2(0, -14), 0.9) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(crystal, "modulate:a", 0.0, 0.3)
	await tween.finished
	if _glow:
		fx.remove_loop(_glow)


func _open_rift() -> void:
	# the flag king_on_wall brings the king and Lake: they wait unseen until the rift is open
	for path in [king, dark_lake]:
		var npc := node2d(path)
		if npc:
			npc.modulate.a = 0.0
	_rift = Sprite2D.new()
	_rift.texture = load(RIFT)
	_rift.hframes = RIFT_FRAMES
	_rift.offset = Vector2(0, -44)
	add_child(_rift)
	_rift.position = RIFT_SPOT
	AudioManager.play_sound("rock_break", 0.6)
	shake(0.5, 1.5)
	# it tears open from a thin line
	_rift.scale = Vector2(0.05, 0.6)
	var tween := create_tween()
	tween.tween_property(_rift, "scale:y", 1.0, 0.3)
	tween.tween_property(_rift, "scale:x", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fx.spawn("area_shadow", to_global(RIFT_SPOT), Color.WHITE)


func _step_out() -> void:
	for path in [king, dark_lake]:
		var npc := node2d(path)
		if npc == null:
			continue
		var home: Vector2 = npc.position
		npc.global_position = to_global(RIFT_SPOT)
		npc.modulate.a = 0.0
		create_tween().tween_property(npc, "modulate:a", 1.0, 0.4)
		_walk_npc(npc, npc.get_parent().to_global(home), "down", 75.0)


# --- wall_aftermath ------------------------------------------------------------------------------

## Lake reels back to the edge: three stumbling steps backwards, then he sinks onto his black sword
## (the kneeling frames lake_dark_kneel.png). The player walks to the place where the ice will
## break, quickly enough to be there before the box comes back.
func _stagger() -> void:
	var smith := player()
	if smith:
		var distance: float = smith.global_position.distance_to(to_global(PLAYER_SPOT))
		_walk_player(PLAYER_SPOT, "up", maxf(140.0, distance / 1.1))
	var lake := node2d(dark_lake)
	if lake == null:
		return
	AudioManager.play_sound("wood_break", 0.5)
	for step in STAGGER_STEPS:
		var reel := create_tween()
		reel.tween_property(lake, "position", lake.position + step, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await reel.finished
		if not is_inside_tree() or not is_instance_valid(lake):
			return
	shake(0.3, 1.0)
	await NpcActing.play(lake, "kneel")


func _crack() -> void:
	var texture: Texture2D = load(CRACK)
	AudioManager.play_sound("rock_break", 0.8)
	shake(1.2, 1.5)
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


## Subar leaps in and shoves the player back into the snow; the ice breaks right under Subar, he
## slides over the edge and hangs there. Fixed short tweens (no walking), so it is over before the
## box comes back (it was still walking when the crystal already rolled, 2026-11-14).
func _fall() -> void:
	var smith := player()
	var subar_npc := node2d(subar)
	var shove_at: Vector2 = smith.global_position if smith else to_global(PLAYER_SPOT)
	if subar_npc:
		subar_npc.call("_face", "left", 1)
		var leap := create_tween()
		leap.tween_property(subar_npc, "global_position", shove_at + Vector2(14, 2), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await leap.finished
		if not is_inside_tree():
			return
	# the shove: the player flies back up-left into the snow
	fx.spawn("impact", shove_at + Vector2(4, -12), Color.WHITE)
	AudioManager.play_sound("pickaxe_hit", 0.6)
	if smith and smith.has_method("auto_walk"):
		smith.call("auto_walk", PackedVector2Array([shove_at + SHOVE]), "down", 240.0)
	if not await wait(0.2):
		return
	# the ice breaks under Subar; in the same moment the crystal rolls out of the player's bag
	_roll()
	fx.spawn("area_ice", to_global(SUBAR_EDGE + Vector2(0, -14)), Color.WHITE)
	AudioManager.play_sound("rock_break", 1.0)
	shake(0.5, 2.0)
	if subar_npc:
		subar_npc.call("_face", "up")
		var slide := create_tween()
		slide.tween_property(subar_npc, "global_position", to_global(SUBAR_EDGE + Vector2(0, -6)), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		slide.tween_property(subar_npc, "modulate:a", 0.0, 0.12)
		await slide.finished
		if not is_inside_tree():
			return
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


## The crystal rolls from the player towards the crack (started by wall_fall; the beat wall_roll
## only starts it if it is not rolling yet, e.g. a save loaded in between).
func _roll() -> void:
	if _crystal and is_instance_valid(_crystal) and _crystal.modulate.a > 0.9:
		return
	var smith := player()
	var crystal := _crystal_sprite()
	crystal.modulate.a = 1.0
	crystal.global_position = (smith.global_position if smith else to_global(PLAYER_SPOT)) + Vector2(0, -4)
	var tween := create_tween().set_parallel()
	tween.tween_property(crystal, "global_position", to_global(CRYSTAL_EDGE), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(crystal, "rotation", TAU * 1.5, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- the rescue ----------------------------------------------------------------------------------

func _dive(target: Vector2, facing: String) -> void:
	_walk_player(target, facing, 170.0)
	if not await wait(0.45):
		return
	fx.spawn("area_ice", to_global(target + Vector2(0, 4)), Color.WHITE)
	var smith := player()
	if smith:
		_glow = Node2D.new()
		add_child(_glow)
		_glow.global_position = smith.global_position + Vector2(0, 6)
		fx.add_loop(_glow, "glow", BLUE)


func _crystal_dive() -> void:
	# the lying Subar of the flag subar_wounded waits until he is pulled up
	var down := node2d(subar_down)
	if down:
		down.modulate.a = 0.0
	_hang(node2d(subar))
	await _dive(CRYSTAL_EDGE + Vector2(-2, -12), "down")
	var smith := player()
	if smith and smith.has_method("is_auto_walking") and smith.call("is_auto_walking"):
		await smith.auto_walk_finished
	if smith and _crystal and is_inside_tree():
		create_tween().tween_property(_crystal, "global_position", smith.global_position + Vector2(0, 2), 0.2)


func _harpoon() -> void:
	var torgai_npc := node2d(torgai)
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
	shake(0.3, 1.0)


func _king_take() -> void:
	var king_npc := node2d(king)
	if _crystal == null:
		return
	var spot: Vector2 = _crystal.global_position
	if king_npc:
		# out of the shadows right behind the crystal
		fx.spawn("area_shadow", spot + Vector2(10, -4), Color.WHITE)
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
		fx.remove_loop(_glow)
	var walkers: Array[Node2D] = []
	for path in [king, dark_lake]:
		var npc := node2d(path)
		if npc:
			walkers.append(npc)
	var lake := node2d(dark_lake)
	if lake:
		# up from his knee (puts his own sheet back)
		await NpcActing.play(lake, "rise")
		if not is_inside_tree():
			return
	if _rift == null or not is_instance_valid(_rift):
		_open_rift()
		for npc in walkers:
			npc.modulate.a = 1.0
	for npc in walkers:
		fx.spawn("area_shadow", npc.global_position, Color.WHITE)
		var fade := create_tween().set_parallel()
		fade.tween_property(npc, "global_position", to_global(RIFT_SPOT), 0.9).set_trans(Tween.TRANS_QUAD)
		fade.tween_property(npc, "modulate:a", 0.0, 0.9)
	if not await wait(1.0):
		return
	var close := create_tween()
	close.tween_property(_rift, "scale:x", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	close.tween_callback(func() -> void:
		if is_instance_valid(_rift):
			_rift.queue_free())
	GameState.run_story_action("set_flag:king_left_wall")


func _pull_subar(wounded: bool) -> void:
	var torgai_npc := node2d(torgai)
	if not wounded and torgai_npc:
		await _walk_npc(torgai_npc, to_global(SUBAR_EDGE + Vector2(20, -16)), "down", 120.0)
	elif wounded:
		var kahn_npc := node2d(kahn)
		if kahn_npc:
			await _walk_npc(kahn_npc, to_global(SUBAR_EDGE + Vector2(-22, -16)), "down", 120.0)
	if not is_inside_tree():
		return
	if _rope:
		_rope.queue_free()
		_rope = null
	if _glow:
		fx.remove_loop(_glow)
	if _hanging:
		var up := create_tween()
		up.tween_property(_hanging, "position:y", _hanging.position.y - 14.0, 0.6)
		await up.finished
		if is_instance_valid(_hanging):
			_hanging.queue_free()
		_hanging = null
	if not is_inside_tree():
		return
	fx.spawn("area_ice", to_global(SUBAR_EDGE + Vector2(0, -8)), Color.WHITE)
	var standing := node2d(subar_down if wounded else subar)
	if standing:
		standing.global_position = to_global(SUBAR_EDGE + Vector2(0, -16))
		standing.modulate.a = 1.0
		if not wounded:
			standing.call("_face", "up")


## A story NPC walks to `target` (global) with its walk frames.
func _walk_npc(npc: Node2D, target: Vector2, facing: String, speed: float) -> void:
	await walk_npc(npc, PackedVector2Array([target]), speed, facing)


