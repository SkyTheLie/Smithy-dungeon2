class_name AltarKingCutscene
extends StoryCutscene
## The king's fall at the Altar of the Nine (dialogue "king_shatters"). Each beat is a line with
## "hide_for" (the dialogue box is out of sight while it plays) and "cutscene:<id>":
## - king_eyes: two huge eyes open in the crack of the gate (altar/gate_eyes.png)
## - king_run: Lake throws himself at the shadows, the player runs past the king to the key
## - king_burn: the player's hands burn into the key, sparks fly
## - king_shatter: the key bursts, the nine stones fly onto the altar
## - king_dark: without the key the gate tips, darkness pours out
## - king_grab: black hands reach out of the crack for the king (altar/shadow_hands.png)
## - king_pulled: they drag him into the crack, only his white glove stays (flag king_fell)
## The key (a ring of the nine holy crystals) sits in the gate until it bursts.

@export var king: NodePath
@export var lake: NodePath
## The glove on the floor (a StoryProp with required_flag king_fell, its Sprite2D drops in).
@export var glove: NodePath

const EYES: String = "res://assets/sprites/altar/gate_eyes.png"
const HANDS: String = "res://assets/sprites/altar/shadow_hands.png"
const HAND_FRAMES: int = 9
const CRYSTALS: Array[String] = ["fire", "wind", "water", "lightning", "earth", "ice", "poison", "light", "dark"]
const CRYSTAL_CELL: int = 48
const CRYSTAL_DIR: String = "res://assets/sprites/items/holy_crystals/holy_%s_crystal.png"
## Scene coordinates: the key in the gate, the crack in the gate, the altar stone in the middle.
const KEY_SPOT: Vector2 = Vector2(0, -266)
const CRACK: Vector2 = Vector2(1, -330)
const ALTAR: Vector2 = Vector2(0, -64)
const GOLD: Color = Color(1.0, 0.82, 0.35)
const BLUE: Color = Color(0.45, 0.7, 1.0)

var _key: Node2D
var _eyes: Sprite2D
var _hands: Sprite2D
var _stones: Array[Sprite2D] = []


func _ready() -> void:
	super()
	# since 2026-11-14 the king's setting lies in the altar (AltarElements), not in the gate: the key
	# is only built for the beat king_shatter


func _play_beat(id: String) -> bool:
	match id:
		"king_eyes":
			_open_eyes()
		"king_run":
			_run_to_key()
		"king_burn":
			_burn()
		"king_shatter":
			_shatter()
		"king_dark":
			_darkness()
		"king_grab":
			_grab()
		"king_pulled":
			_pull()
		_:
			return false
	return true


func _at(point: Vector2) -> Vector2:
	return to_global(point)


## The key: the nine holy crystals in a ring, in the lock of the gate.
func _build_key() -> void:
	_key = Node2D.new()
	_key.z_index = 1
	add_child(_key)
	_key.position = KEY_SPOT
	for i in CRYSTALS.size():
		var path: String = CRYSTAL_DIR % CRYSTALS[i]
		if not ResourceLoader.exists(path):
			continue
		var stone := Sprite2D.new()
		stone.texture = load(path)
		stone.region_enabled = true  # the crystal sheets hold 48 px frames (sloshing water etc.)
		stone.region_rect = Rect2(0, 0, CRYSTAL_CELL, CRYSTAL_CELL)
		stone.scale = Vector2.ONE * 0.28
		var angle: float = TAU * i / CRYSTALS.size() - PI / 2.0
		stone.position = Vector2(cos(angle), sin(angle)) * 9.0
		_key.add_child(stone)
		_stones.append(stone)


func _open_eyes() -> void:
	_eyes = Sprite2D.new()
	_eyes.texture = load(EYES)
	_eyes.z_index = 1
	add_child(_eyes)
	_eyes.position = CRACK
	_eyes.modulate.a = 0.0
	_eyes.scale = Vector2(1.0, 0.1)
	var tween := create_tween().set_parallel()
	tween.tween_property(_eyes, "modulate:a", 1.0, 0.6)
	tween.tween_property(_eyes, "scale", Vector2.ONE, 0.5).set_delay(0.3)
	AudioManager.play_sound("rock_break", 0.5)
	shake(0.6, 1.0)


func _run_to_key() -> void:
	var smith := player()
	if smith and smith.has_method("auto_walk"):
		var way := PackedVector2Array([_at(Vector2(-26, -150)), _at(Vector2(-22, -214)), _at(KEY_SPOT + Vector2(-20, 30))])
		var length: float = smith.global_position.distance_to(way[0]) + way[0].distance_to(way[1]) + way[1].distance_to(way[2])
		smith.call("auto_walk", way, "up", maxf(80.0, length / 2.0))
	var lake_npc := get_node_or_null(lake) as Node2D
	if lake_npc:
		_walk_npc(lake_npc, _at(Vector2(46, -232)), "right", 95.0)
		await wait(1.1)
		if is_inside_tree() and is_instance_valid(lake_npc):
			fx.spawn("slash", lake_npc.global_position + Vector2(14, -16), Color.WHITE)
			fx.spawn("dark_hit", lake_npc.global_position + Vector2(22, -14), Color.WHITE)
			AudioManager.play_sound("anvil_good", 0.7)
	var king_npc := get_node_or_null(king) as Node2D
	if king_npc:
		king_npc.call("_face", "left")


func _burn() -> void:
	if _key == null:
		return
	fx.add_loop(_key, "glow", BLUE)
	for i in 6:
		fx.spawn("lightning_hit", _key.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 6)), GOLD)
		_key.position = KEY_SPOT + Vector2(randf_range(-1, 1), randf_range(-1, 1)).round()
		fx.add_loop(_key, "glow", BLUE.lerp(GOLD, i / 5.0))
		if not await wait(0.22):
			return
	_key.position = KEY_SPOT
	shake(0.5, 1.0)


func _shatter() -> void:
	if _key == null:
		_build_key()
	fx.remove_loop(_key)
	fx.spawn("light_hit", _key.global_position, GOLD)
	fx.spawn("lightning_hit", _key.global_position, Color.WHITE)
	AudioManager.play_sound("rock_break", 1.0)
	shake(0.5, 3.0)
	# the nine stones fly in arcs onto the altar stone and lie there in a ring
	for i in _stones.size():
		var stone := _stones[i]
		var from: Vector2 = stone.global_position
		var angle: float = TAU * i / _stones.size()
		var to: Vector2 = _at(ALTAR + Vector2(cos(angle) * 20.0, sin(angle) * 8.0))
		var height: float = randf_range(30.0, 60.0)
		var spin: float = randf_range(-6.0, 6.0)
		var tween := create_tween()
		tween.tween_method(func(t: float) -> void:
			if is_instance_valid(stone):
				stone.global_position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * height)
				stone.rotation = spin * t,
			0.0, 1.0, randf_range(0.8, 1.2)).set_delay(i * 0.04)
		tween.tween_callback(func() -> void:
			if is_instance_valid(stone):
				stone.rotation = 0.0
				AudioManager.play_sound("pickaxe_hit", 0.35))


func _darkness() -> void:
	fx.spawn("area_shadow", _at(CRACK + Vector2(0, 50)), Color.WHITE)
	fx.spawn("dark_hit", _at(CRACK + Vector2(0, 20)), Color.WHITE)
	if _eyes:
		var flare := create_tween()
		flare.tween_property(_eyes, "modulate", Color(1.8, 1.4, 1.4), 0.3)
		flare.tween_property(_eyes, "modulate", Color.WHITE, 0.6)
	shake(1.0, 2.0)


func _grab() -> void:
	var king_npc := get_node_or_null(king) as Node2D
	_hands = Sprite2D.new()
	_hands.texture = load(HANDS)
	_hands.hframes = HAND_FRAMES
	_hands.z_index = 2
	_hands.z_as_relative = false
	_hands.offset = Vector2(0, 32)  # hangs from the crack
	add_child(_hands)
	_hands.position = KEY_SPOT + Vector2(0, -6)
	_hands.scale = Vector2(1.0, 0.2)
	if king_npc:
		king_npc.call("_face", "up")
	var reach: float = (to_local(king_npc.global_position).y - 30.0 - _hands.position.y) / 64.0 if king_npc else 1.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_hands, "scale", Vector2(1.0, clampf(reach, 0.6, 1.4)), 0.9).set_trans(Tween.TRANS_QUAD)
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(_hands):
			_hands.frame = mini(int(value), HAND_FRAMES - 1),
		0.0, float(HAND_FRAMES - 1), 1.4)
	AudioManager.play_sound("skill_used", 0.5)
	if king_npc:
		# he flinches back once
		var shove := create_tween()
		shove.tween_property(king_npc, "position:y", king_npc.position.y + 4.0, 0.15)
		shove.tween_property(king_npc, "position:y", king_npc.position.y, 0.5)


func _pull() -> void:
	var king_npc := get_node_or_null(king) as Node2D
	var spot: Vector2 = king_npc.global_position if king_npc else _at(Vector2(0, -190))
	if _hands == null:
		_grab()
		await wait(0.6)
	if king_npc:
		var drag := create_tween().set_parallel()
		drag.tween_property(king_npc, "global_position", _at(KEY_SPOT + Vector2(0, -10)), 1.1) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		drag.tween_property(king_npc, "modulate", Color(0.2, 0.15, 0.25, 0.0), 1.1).set_delay(0.3)
		drag.tween_property(_hands, "scale:y", 0.15, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await drag.finished
	if not is_inside_tree():
		return
	fx.spawn("area_shadow", _at(KEY_SPOT), Color.WHITE)
	shake(0.4, 2.0)
	if _hands:
		_hands.queue_free()
		_hands = null
	GameState.run_story_action("set_flag:king_fell")
	if king_npc and is_instance_valid(king_npc) and king_npc.has_method("_hide_body"):
		king_npc.call("_hide_body")
	# the glove flutters down where he stood
	var glove_prop := get_node_or_null(glove) as Node2D
	if glove_prop:
		glove_prop.global_position = spot
		glove_prop.show()
		var sprite := glove_prop.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			var rest: Vector2 = sprite.position
			sprite.position = rest + Vector2(0, -22)
			sprite.modulate.a = 0.0
			var fall := create_tween().set_parallel()
			fall.tween_property(sprite, "position", rest, 0.9).set_trans(Tween.TRANS_SINE)
			fall.tween_property(sprite, "modulate:a", 1.0, 0.3)
	if _eyes:
		var close := create_tween()
		close.tween_property(_eyes, "modulate:a", 0.35, 1.0)


## A story NPC walks to `target` (global) with its walk frames.
func _walk_npc(npc: Node2D, target: Vector2, facing: String, speed: float) -> void:
	await walk_npc(npc, PackedVector2Array([target]), speed, facing)


