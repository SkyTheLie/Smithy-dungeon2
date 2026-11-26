class_name FortressYardCutscene
extends StoryCutscene
## The yard of the Finsterburg (dialogues "yard_battle" and "keep_won"):
## - shield_charge: a row of undead shield bearers storms down from the stairs towards Lake, a black
##   spear hisses out of the shadow at his open flank
## - silver_arrow: Faelan's silver arrow breaks the spear in flight, he leaps to Lake's side, back to
##   back they cut the shield bearers down
## - keep_doors: rumbling from inside, the wings of the keep gate swing open
## - lake_storms: Lake runs from the player up the stairs and into the keep

@export var lake: NodePath
@export var faelan: NodePath
@export var gate: NodePath
@export var closed_texture: Texture2D
@export var open_texture: Texture2D

const BEARER: String = "res://assets/sprites/enemies/skeleton_knight_walk.png"
const BEARER_ATTACK: String = "res://assets/sprites/enemies/skeleton_knight_attack.png"
const BEARER_DEATH: String = "res://assets/sprites/enemies/skeleton_knight_death.png"
const BEARER_FRAMES: int = 6
const SPEAR: Color = Color(0.13, 0.1, 0.16)
const SILVER: Color = Color(0.85, 0.92, 1.0)
const GOLD: Color = Color(1.0, 0.85, 0.4)

var _bearers: Array[Sprite2D] = []
## The black spear while it hangs in the air (until the arrow breaks it).
var _spear: Line2D


func _play_beat(id: String) -> bool:
	match id:
		"shield_charge":
			_charge()
		"silver_arrow":
			_arrow()
		"keep_doors":
			_doors()
		"lake_storms":
			_lake_runs()
		_:
			return false
	return true


func _sheet_frame(sprite: Sprite2D, path: String, frame: int) -> void:
	sprite.texture = load(path)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame * 48, 0, 48, 48)


func _charge() -> void:
	var knight := node2d(lake)
	if knight == null:
		return
	# from the stairs on the right, looking left (the enemy sheets face left)
	for i in 3:
		var bearer := Sprite2D.new()
		bearer.offset = Vector2(0, -22)
		_sheet_frame(bearer, BEARER, 0)
		var holder := get_parent() if get_parent() is Node2D and (get_parent() as Node2D).y_sort_enabled else self
		holder.add_child(bearer)
		bearer.global_position = knight.global_position + Vector2(110 + 18 * i, -30 + 22 * i)
		bearer.modulate.a = 0.0
		_bearers.append(bearer)
		_march(bearer, knight.global_position + Vector2(44 + 14 * i, -18 + 18 * i), 0.15 * i)
	face_npc(knight, "right")
	if not await wait(1.2):
		return
	# the black spear out of the shadow on the left, at his open flank
	var flank: Vector2 = knight.global_position + Vector2(-6, -14)
	var shadow: Vector2 = flank + Vector2(-150, -10)
	_spear = _projectile(shadow, flank + Vector2(-46, -3), 16.0, SPEAR, 0.55, false)
	AudioManager.play_sound("skill_used", 0.5)


## A straight shaft of `length` px flying from `from` to `to` in `seconds` (free_at_end: gone there).
func _projectile(from: Vector2, to: Vector2, length: float, color: Color, seconds: float, free_at_end: bool) -> Line2D:
	var shaft := Line2D.new()
	shaft.width = 1.0
	shaft.default_color = color
	var direction: Vector2 = (to - from).normalized()
	shaft.points = PackedVector2Array([-direction * length, Vector2.ZERO, direction * 2.0])
	shaft.z_index = 2
	shaft.z_as_relative = false
	add_child(shaft)
	shaft.global_position = from
	var flight := create_tween()
	flight.tween_property(shaft, "global_position", to, seconds)
	if free_at_end:
		flight.tween_callback(shaft.queue_free)
	return shaft


func _march(bearer: Sprite2D, target: Vector2, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return
	create_tween().tween_property(bearer, "modulate:a", 1.0, 0.2)
	var time: float = 0.0
	while is_inside_tree() and is_instance_valid(bearer) and bearer.global_position.distance_to(target) > 1.0:
		var delta: float = get_process_delta_time()
		bearer.global_position += (target - bearer.global_position).limit_length(70.0 * delta)
		time += delta
		bearer.region_rect = Rect2((int(time * 10.0) % BEARER_FRAMES) * 48, 0, 48, 48)
		await get_tree().process_frame


func _arrow() -> void:
	var knight := node2d(lake)
	var elf := node2d(faelan)
	if knight == null:
		return
	var flank: Vector2 = knight.global_position + Vector2(-6, -14)
	var hit: Vector2 = flank + Vector2(-46, -3)
	# the spear breaks where the arrow meets it
	if elf:
		_projectile(elf.global_position + Vector2(0, -16), hit, 8.0, SILVER, 0.2, true)
	if not await wait(0.22):
		return
	if _spear and is_instance_valid(_spear):
		_spear.queue_free()
	_spear = null
	fx.spawn("impact", hit, SILVER)
	fx.spawn("dark_hit", hit, Color.WHITE)
	AudioManager.play_sound("anvil_good", 0.8)
	_spear_halves(hit)
	# Faelan leaps to Lake's side, back to back
	if elf:
		await walk_npc(elf, PackedVector2Array([knight.global_position + Vector2(-20, 0)]), 160.0, "left")
	face_npc(knight, "right")
	if not is_inside_tree():
		return
	for bearer in _bearers:
		if is_instance_valid(bearer):
			_sheet_frame(bearer, BEARER_ATTACK, 2)
	fx.spawn("slash", knight.global_position + Vector2(18, -14), GOLD)
	AudioManager.play_sound("anvil_perfect", 0.7)
	if not await wait(0.3):
		return
	for bearer in _bearers:
		if is_instance_valid(bearer):
			_fall(bearer)
	_bearers.clear()


## The broken spear: two dark splinters that tumble down.
func _spear_halves(at: Vector2) -> void:
	for side in [-1, 1]:
		var half := Line2D.new()
		half.width = 1.0
		half.default_color = SPEAR
		half.points = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0)])
		half.z_index = 2
		half.z_as_relative = false
		add_child(half)
		half.global_position = at + Vector2(5 * side, 0)
		var tween := create_tween().set_parallel()
		tween.tween_property(half, "global_position", at + Vector2(10 * side, 16), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(half, "rotation", 1.6 * side, 0.45)
		tween.chain().tween_property(half, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(half.queue_free)


func _fall(bearer: Sprite2D) -> void:
	fx.spawn("hit_great", bearer.global_position + Vector2(0, -14), Color.WHITE)
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(bearer):
			_sheet_frame(bearer, BEARER_DEATH, int(round(value))),
		0.0, 5.0, 0.6)
	tween.tween_property(bearer, "modulate:a", 0.0, 0.5)
	tween.tween_callback(bearer.queue_free)


func _doors() -> void:
	var sprite := get_node_or_null(gate) as Sprite2D
	if sprite == null:
		return
	sprite.texture = closed_texture
	AudioManager.play_sound("rock_break", 0.5)
	await shake(0.6, 1.0)
	if not is_inside_tree():
		return
	AudioManager.play_sound("door", 0.6)
	# the wings swing: the picture narrows and comes back open
	var width: float = sprite.scale.x
	var swing := create_tween()
	swing.tween_property(sprite, "scale:x", width * 0.85, 0.25)
	swing.tween_callback(func() -> void: sprite.texture = open_texture)
	swing.tween_property(sprite, "scale:x", width, 0.25)
	for i in 3:
		fx.spawn("earth_hit", sprite.global_position + Vector2(-24 + 24 * i, -4), Color.WHITE)
	shake(0.5, 1.5)


func _lake_runs() -> void:
	var sprite := get_node_or_null(gate) as Node2D
	var body := player()
	if sprite == null or body == null:
		return
	var start: Vector2 = body.global_position + Vector2(-16, 4)
	var runner := extra("lake", start, "up")
	fx.add_loop(runner, "aura_holy", GOLD, Vector2(0, -12))
	var door: Vector2 = sprite.global_position + Vector2(0, -6)
	await walk_extra(runner, PackedVector2Array([Vector2(door.x, start.y), door]), 120.0, "up")
	if is_instance_valid(runner):
		fx.remove_loop(runner)
		var fade := create_tween()
		fade.tween_property(runner, "modulate:a", 0.0, 0.25)
		fade.tween_callback(runner.queue_free)
	walk_player(PackedVector2Array([Vector2(door.x, body.global_position.y), door + Vector2(0, 34)]), "up", 1.4)
