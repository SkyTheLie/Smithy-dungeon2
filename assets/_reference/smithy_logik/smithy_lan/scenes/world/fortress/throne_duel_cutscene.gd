class_name ThroneDuelCutscene
extends Node
## The end of part 5 in the throne hall of the Finsterburg: Lake fights the Lich, breaks his staff,
## the Lich kneels and begs, the king orders his death and Lake strikes him down. Arriving in step
## `walk_in_step` the player walks in by himself and the narrator starts; the dialogue lines start
## each part with the story action "cutscene:<id>" (Events.cutscene_requested):
## - duel_charge: Lake's blade lights up, he runs at the Lich
## - duel_clash: they fight (dark bolts against the shield, Lake's slashes), loops until the next part
## - duel_push: still fighting, every hit drives the Lich a step back
## - lich_kneel: the staff breaks (flash), the Lich sinks to his knees and trembles
## - lich_crawl: the Lich crawls over to the player
## - lake_execute: Lake runs at him, raises the sword and strikes (flash)
## - lich_dust: the Lich falls apart into grey dust
## - lake_dim: the light on Lake's blade goes out
## - dark_lake_approach: the dark Lake walks up to the player
## - dark_lake_raise: he raises the black sword (on the king's order)
## - aurelius_shield: Aurelius runs in from the door and stands between them behind a star shield
## - shield_hammer: Lake strikes the shield again and again (sparks), loops until shield_burst
## - faelan_leaves: Faelan runs back out of the door to lead the army out
## - shield_burst: the shield bursts in a blinding light, Lake staggers back, Aurelius sinks down
## - flee_start: the player runs to the door, Aurelius limps along at his side
## - dark_lake_chase: Lake shakes off the light and runs after them
## - king_laughs: the freed king laughs, rises without effort and dusts off his cloak
## - player_bound: dark magic grips the player (a dark aura until he flees), the blue light goes out
## - king_takes_crystal: the king walks up, takes the lightning crystal out of the bag and walks back
## - lake_kneels: Lake sinks to one knee before the throne
## - lake_darkened: the king lays a hand on his shoulder, raises the crystal of darkness, black
##   gleam flows over Lake
## - chains_fall: the chains on the king's pillar click open, slide down and drop to the floor
## When `lake_fallen` is set the dark Lake takes the place where Lake stands.

@export var lich: NodePath
@export var lake: NodePath
@export var dark_lake: NodePath
@export var narrator: NodePath
@export var aurelius: NodePath
@export var faelan: NodePath
@export var king: NodePath
## Where Aurelius and Faelan come in and where the player flees to (scene coordinates).
@export var door_point: Vector2 = Vector2(0, 200)
@export var walk_in_step: String = "throne_hall"
## Where the player walks to on arrival (scene coordinates), then looks up.
@export var walk_in_path: PackedVector2Array = []
@export var lake_fallen_flag: String = "lake_fallen"
## The chains picture at the pillar (a StoryProp hides it for good with the flag "chains_off").
@export var chains: NodePath = "../Chains/Post/Sprite2D"

const LICH_STILL: Texture2D = preload("res://assets/sprites/fortress/lich_still.png")
const LICH_CAST: Texture2D = preload("res://assets/sprites/enemies/lich_battle_cast.png")
const LICH_FRAME: int = 64
const LICH_KNEEL: Texture2D = preload("res://assets/sprites/fortress/lich_kneel.png")
const LICH_CRAWL: Texture2D = preload("res://assets/sprites/fortress/lich_crawl.png")
const LICH_POSE_FRAMES: int = 6
const LICH_CAST_FRAMES: int = 6
## Lake's spot left of the Lich while fighting (relative to the Lich).
const LAKE_AT_LICH: Vector2 = Vector2(-26, 4)
const LUNGE: float = 8.0
## Lake's sword over the head and down (6 frames of 64 px, facing right); the blow lands on frame 3.
const LAKE_SLASH: Texture2D = preload("res://assets/sprites/residents/lake_slash.png")
const LAKE_DARK_SLASH: Texture2D = preload("res://assets/sprites/residents/lake_dark_slash.png")
const SLASH_CELL: int = 64
const SLASH_FRAMES: int = 6
const SLASH_HIT_FRAME: int = 3
const PUSH_STEP: float = 7.0
const MAX_PUSHES: int = 3
const SHAKE_SECONDS: float = 0.6
const SHAKE: float = 4.0
const COLOR_LIGHT: Color = Color(1.0, 0.95, 0.6)
const COLOR_DARK: Color = Color(0.55, 0.3, 0.85)
const COLOR_DUST: Color = Color(0.7, 0.7, 0.7)
const COLOR_STARS: Color = Color(0.65, 0.85, 1.0)
const AURELIUS_LIMP: Texture2D = preload("res://assets/sprites/residents/aurelius_limp.png")
const AURELIUS_STAR_SHIELD: Texture2D = preload("res://assets/sprites/residents/aurelius_star_shield.png")

var _fx: WorldVfx
var _dueling: bool = false
var _pushing: bool = false
var _pushes: int = 0
var _tremble: Tween
var _hammering: bool = false
var _raised: bool = false
## The dark grip on the player (player_bound) until he flees.
var _bound: Node2D


func _ready() -> void:
	Events.cutscene_requested.connect(_on_cutscene)
	GameState.story.changed.connect(_on_story_changed)
	_fx = WorldVfx.new()
	(get_parent() as Node).add_child.call_deferred(_fx)
	_check_walk_in.call_deferred()


func _npc(path: NodePath) -> StoryNpc:
	return get_node_or_null(path) as StoryNpc


func _check_walk_in() -> void:
	if GameState.story.step != walk_in_step:
		return
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var map := get_parent() as Node2D
	if player == null or map == null or walk_in_path.is_empty():
		_start_talk()
		return
	var way := PackedVector2Array()
	for point in walk_in_path:
		way.append(map.to_global(point))
	player.auto_walk(way, "up")
	player.auto_walk_finished.connect(_start_talk, CONNECT_ONE_SHOT)


func _start_talk() -> void:
	var npc := _npc(narrator)
	if npc and GameState.story.step == walk_in_step and GameState.story.npc_has_news(npc.npc_id):
		npc.interacted.emit()


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"duel_charge":
			_charge()
		"duel_clash":
			_start_duel()
		"duel_push":
			_pushing = true
			_start_duel()
		"lich_kneel":
			_kneel()
		"lich_crawl":
			_crawl()
		"lake_execute":
			_execute()
		"lich_dust":
			_dust()
		"lake_dim":
			_glow(false)
		"dark_lake_approach":
			_dark_lake_approach()
		"dark_lake_raise":
			_raise_sword(_npc(dark_lake))
		"aurelius_shield":
			_aurelius_shield()
		"shield_hammer":
			_hammer_shield()
		"faelan_leaves":
			_faelan_leaves()
		"shield_burst":
			_shield_burst()
		"flee_start":
			_flee()
		"dark_lake_chase":
			_chase()
		"king_laughs":
			_king_laughs()
		"player_bound":
			_player_bound()
		"king_takes_crystal":
			_king_takes_crystal()
		"lake_kneels":
			NpcActing.play(_npc(lake), "kneel")
		"lake_darkened":
			_lake_darkened()
		"chains_fall":
			_chains_fall()


## The dark Lake appears where Lake stands (not at his place in the scene).
func _on_story_changed() -> void:
	var old := _npc(lake)
	var dark := _npc(dark_lake)
	if old and dark and GameState.story.has_flag(lake_fallen_flag) and old.position != dark.position:
		dark.position = old.position
		_pose(dark, "right")


# --- figures ---------------------------------------------------------------------------------

func _figure(npc: Node2D) -> Sprite2D:
	return npc.get_node_or_null("Figure") as Sprite2D if npc else null


## A resident sheet figure looks in `direction` (frame 0 = standing, 1..6 walking).
func _pose(npc: Node2D, direction: String, frame: int = 0) -> void:
	var figure := _figure(npc)
	if figure and figure.region_enabled:
		figure.region_rect = CharacterBaker.get_frame_rect(direction, frame)


## Moves `npc` to `to` (global) in `seconds`, stepping through the walk frames.
func _walk(npc: Node2D, to: Vector2, seconds: float, direction: String) -> void:
	var tween := create_tween()
	tween.tween_property(npc, "global_position", to, seconds)
	var steps: int = maxi(1, int(seconds / 0.08))
	for step in steps:
		if not is_instance_valid(npc):
			return
		_pose(npc, direction, 1 + step % 6)
		await get_tree().create_timer(seconds / steps, false).timeout
	if is_instance_valid(npc):
		_pose(npc, direction)


func _glow(on: bool) -> void:
	var npc := _npc(lake)
	var figure := _figure(npc)
	if figure == null:
		return
	if on:
		_fx.add_loop(npc, "aura_holy", COLOR_LIGHT)
		create_tween().tween_property(figure, "modulate", Color(1.35, 1.3, 1.1), 0.4)
	else:
		_fx.remove_loop(npc)
		create_tween().tween_property(figure, "modulate", Color.WHITE, 0.8)


# --- the fight -------------------------------------------------------------------------------

func _charge() -> void:
	var hero := _npc(lake)
	var enemy := _npc(lich)
	if hero == null or enemy == null:
		return
	_glow(true)
	AudioManager.play_sound("skill_used", 0.9)
	await _walk(hero, enemy.global_position + LAKE_AT_LICH, 0.5, "right")


func _start_duel() -> void:
	if _dueling:
		return
	_dueling = true
	while _dueling and is_inside_tree():
		await _lich_casts()
		if not _dueling:
			break
		await get_tree().create_timer(0.2, false).timeout
		if not _dueling:
			break
		await _lake_strikes()
		await get_tree().create_timer(0.3, false).timeout


func _lich_casts() -> void:
	var enemy := _npc(lich)
	var hero := _npc(lake)
	var figure := _figure(enemy)
	if figure == null or hero == null:
		return
	figure.texture = LICH_CAST
	figure.region_enabled = true
	for frame in LICH_CAST_FRAMES:
		if not is_instance_valid(figure) or not _dueling:
			break
		figure.region_rect = Rect2(frame * LICH_FRAME, 0, LICH_FRAME, LICH_FRAME)
		if frame == 4 and is_instance_valid(hero) and is_instance_valid(enemy):
			_fx.spawn("dark_bolt", hero.global_position + Vector2(4, -14), COLOR_DARK, -1.0,
					enemy.global_position + Vector2(-14, -16), 0.22)
		await get_tree().create_timer(0.09, false).timeout
	if is_instance_valid(figure):
		figure.texture = LICH_STILL
		figure.region_enabled = false
	await get_tree().create_timer(0.13, false).timeout
	if is_instance_valid(hero):
		_fx.spawn("block", hero.global_position + Vector2(6, -12), COLOR_LIGHT, -1.0)
		_fx.spawn("dark_hit", hero.global_position + Vector2(6, -12), COLOR_DARK)
		_recoil(hero, -3.0)
		AudioManager.play_sound("anvil_good", 1.7)


func _lake_strikes() -> void:
	var hero := _npc(lake)
	var enemy := _npc(lich)
	if hero == null or enemy == null:
		return
	var home: Vector2 = hero.position
	_pose(hero, "right", 3)
	var tween := create_tween()
	tween.tween_property(hero, "position:x", home.x + LUNGE, 0.1)
	await tween.finished
	if not is_instance_valid(hero) or not is_instance_valid(enemy):
		return
	_fx.spawn("slash", enemy.global_position + Vector2(-8, -16), COLOR_LIGHT, 1.0)
	_fx.spawn("light_hit", enemy.global_position + Vector2(-6, -16), COLOR_LIGHT)
	AudioManager.play_sound("anvil_perfect", 1.4)
	_pose(hero, "right", 5)
	if _pushing and _pushes < MAX_PUSHES:
		_pushes += 1
		create_tween().tween_property(enemy, "position:x", enemy.position.x + PUSH_STEP, 0.15)
		home.x += PUSH_STEP
	else:
		_recoil(enemy, 3.0)
	tween = create_tween()
	tween.tween_property(hero, "position:x", home.x, 0.18)
	await tween.finished
	if is_instance_valid(hero):
		_pose(hero, "right")


func _recoil(npc: Node2D, by: float) -> void:
	var figure := _figure(npc)
	if figure == null:
		return
	var home: float = figure.position.x
	var tween := create_tween()
	tween.tween_property(figure, "position:x", home + by, 0.06)
	tween.tween_property(figure, "position:x", home, 0.15)


## The staff breaks, the Lich sinks to his knees and trembles.
func _kneel() -> void:
	_dueling = false
	var enemy := _npc(lich)
	var figure := _figure(enemy)
	if figure == null:
		return
	_flash()
	_shake()
	_fx.spawn("dark_hit", enemy.global_position + Vector2(-6, -18), COLOR_DARK)
	_fx.spawn("impact", enemy.global_position + Vector2(-6, -18), COLOR_LIGHT)
	AudioManager.play_sound("wood_break", 0.8)
	# he sinks onto his knees (PixelLab, fortress/lich_kneel.png, 6 frames of 64 px, facing left)
	figure.texture = LICH_KNEEL
	figure.region_enabled = true
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(figure):
			figure.region_rect = Rect2(int(round(value)) * LICH_FRAME, 0, LICH_FRAME, LICH_FRAME),
		0.0, float(LICH_POSE_FRAMES - 1), 0.6)
	tween.parallel().tween_property(figure, "modulate", Color(0.8, 0.8, 0.9), 0.6)
	await tween.finished
	if is_instance_valid(figure):
		_start_tremble(figure)


func _start_tremble(figure: Sprite2D) -> void:
	if _tremble:
		_tremble.kill()
	var x: float = figure.position.x
	_tremble = figure.create_tween().set_loops()  # dies with the figure
	_tremble.tween_property(figure, "position:x", x + 1.0, 0.07)
	_tremble.tween_property(figure, "position:x", x - 1.0, 0.07)


## The Lich crawls over to the player, in small jerks.
func _crawl() -> void:
	var enemy := _npc(lich)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var figure := _figure(enemy)
	if figure == null or player == null:
		return
	if _tremble:
		_tremble.kill()
	var target: Vector2 = player.global_position + Vector2(-16, -10)
	figure.flip_h = target.x > enemy.global_position.x
	var start: Vector2 = enemy.global_position
	var jerks: int = 5
	for jerk in range(1, jerks + 1):
		if not is_instance_valid(enemy):
			return
		create_tween().tween_property(enemy, "global_position", start.lerp(target, float(jerk) / jerks), 0.25) \
				.set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.45, false).timeout
	if is_instance_valid(figure):
		_start_tremble(figure)


## Lake runs at the kneeling Lich, raises the sword and strikes.
func _execute() -> void:
	var hero := _npc(lake)
	var enemy := _npc(lich)
	if hero == null or enemy == null:
		return
	_dueling = false
	if _tremble:
		_tremble.kill()
	var side: float = -1.0 if hero.global_position.x < enemy.global_position.x else 1.0
	var direction: String = "right" if side < 0.0 else "left"
	# the Lich is freed as soon as `lich_slain` is set (next line of the dialogue), maybe while
	# Lake is still striking: remember where he knelt
	var lich_at: Vector2 = enemy.global_position
	_fx.add_loop(hero, "aura_holy", Color(1.0, 1.0, 0.85))
	await _walk(hero, lich_at + Vector2(side * 20.0, 2.0), 0.6, direction)
	if not is_instance_valid(hero):
		return
	var figure := _figure(hero)
	if figure == null:
		return
	# the sword over the head and down (PixelLab slash, residents/lake_slash.png, drawn facing right)
	create_tween().tween_property(figure, "modulate", Color(1.8, 1.7, 1.3), 0.35)
	var resident_sheet: Texture2D = figure.texture
	var region: Rect2 = figure.region_rect
	figure.texture = LAKE_SLASH
	figure.flip_h = side > 0.0
	for frame in SLASH_FRAMES:
		if not is_instance_valid(figure):
			return
		figure.region_rect = Rect2(frame * SLASH_CELL, 0, SLASH_CELL, SLASH_CELL)
		await get_tree().create_timer(0.4 if frame == 1 else 0.07, false).timeout
		if frame == SLASH_HIT_FRAME:
			break
	if not is_instance_valid(hero) or not is_instance_valid(figure):
		return
	hero.global_position.x -= side * 6.0
	_fx.spawn("slash", lich_at + Vector2(0, -14), Color(1.0, 1.0, 0.9), -side)
	_fx.spawn("light_hit", lich_at + Vector2(0, -12), COLOR_LIGHT)
	_flash()
	_shake()
	AudioManager.play_sound("anvil_perfect", 0.8)
	var lich_figure := _figure(enemy) if is_instance_valid(enemy) else null
	if lich_figure:
		create_tween().tween_property(lich_figure, "rotation_degrees", 80.0 if side < 0.0 else -80.0, 0.3)
	create_tween().tween_property(figure, "modulate", Color(1.35, 1.3, 1.1), 0.6)
	await get_tree().create_timer(0.35, false).timeout
	if is_instance_valid(figure):
		figure.texture = resident_sheet
		figure.flip_h = false
		figure.region_rect = region
		_pose(hero, direction, 5)


func _dust() -> void:
	var enemy := _npc(lich)
	if enemy == null:
		return
	_fx.spawn("death", enemy.global_position + Vector2(0, -6), COLOR_DUST)
	var figure := _figure(enemy)
	if figure:
		if _tremble:
			_tremble.kill()
		# the Lich itself is freed right after (flag lich_slain): the figure fades on its own
		figure.reparent(get_parent())
		var tween := figure.create_tween()
		tween.tween_property(figure, "modulate", Color(0.6, 0.6, 0.6, 0.0), 0.8)
		tween.tween_callback(figure.queue_free)


func _dark_lake_approach() -> void:
	var dark := _npc(dark_lake)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if dark == null or player == null:
		return
	var side: float = -1.0 if dark.global_position.x < player.global_position.x else 1.0
	await _walk(dark, player.global_position + Vector2(side * 22.0, -4.0), 1.2, "right" if side < 0.0 else "left")


# --- the dark Lake, Aurelius' shield, the flight -------------------------------------------

func _direction_to(from: Node2D, to: Node2D) -> String:
	return "right" if to.global_position.x > from.global_position.x else "left"


## The dark Lake raises the sword over his head (frame 1 of residents/lake_dark_slash.png), it
## stays up until _lower_sword.
func _raise_sword(npc: Node2D) -> void:
	if npc == null or _raised:
		return
	_raised = true
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	_slash_pose(npc, 1, player == null or player.global_position.x >= npc.global_position.x)


func _lower_sword(npc: Node2D) -> void:
	if npc == null or not _raised:
		return
	_raised = false
	_slash_pose(npc, SLASH_HIT_FRAME, not _figure(npc).flip_h if _figure(npc) else true)


## Shows frame `frame` of the dark Lake's slash sheet (drawn facing right) on `npc`; the resident
## sheet comes back with _end_slash.
func _slash_pose(npc: Node2D, frame: int, face_right: bool) -> void:
	var figure := _figure(npc)
	if figure == null:
		return
	if not figure.has_meta(&"resident_sheet"):
		figure.set_meta(&"resident_sheet", figure.texture)
		figure.set_meta(&"resident_region", figure.region_rect)
	figure.texture = LAKE_DARK_SLASH
	figure.region_enabled = true
	figure.flip_h = not face_right
	figure.region_rect = Rect2(frame * SLASH_CELL, 0, SLASH_CELL, SLASH_CELL)


func _end_slash(npc: Node2D) -> void:
	var figure := _figure(npc)
	if figure == null or not figure.has_meta(&"resident_sheet"):
		return
	figure.texture = figure.get_meta(&"resident_sheet")
	figure.region_rect = figure.get_meta(&"resident_region")
	figure.flip_h = false
	figure.remove_meta(&"resident_sheet")
	figure.remove_meta(&"resident_region")


## Aurelius runs in from the door and stops between the player and the dark Lake, the shield up.
func _aurelius_shield() -> void:
	var mage := _npc(aurelius)
	var knight := _npc(dark_lake)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if mage == null or knight == null or player == null:
		return
	var map := get_parent() as Node2D
	mage.global_position = map.to_global(door_point)
	var spot: Vector2 = player.global_position.lerp(knight.global_position, 0.55)
	await _walk(mage, spot, 0.5, "up" if spot.y < mage.global_position.y else "down")
	if not is_instance_valid(mage) or not is_instance_valid(knight):
		return
	_pose(mage, _direction_to(mage, knight))
	var toward: Vector2 = (knight.global_position - mage.global_position).normalized()
	# he holds up the star shield (PixelLab pose, one cell per direction: down, up, left, right)
	var mage_figure := _figure(mage)
	if mage_figure:
		mage_figure.texture = AURELIUS_STAR_SHIELD
		mage_figure.region_enabled = true
		var cell: int = ["down", "up", "left", "right"].find(_direction_to(mage, knight))
		mage_figure.region_rect = Rect2(cell * 48, 0, 48, 48)
	# the blade crashes into the shield
	_lower_sword(knight)
	_fx.spawn("block", mage.global_position + Vector2(0, -14) + toward * 10.0, COLOR_STARS)
	AudioManager.play_sound("anvil_perfect", 1.2)


## Lake strikes the shield again and again until it bursts.
func _hammer_shield() -> void:
	if _hammering:
		return
	_hammering = true
	while _hammering and is_inside_tree():
		var mage := _npc(aurelius)
		var knight := _npc(dark_lake)
		if mage == null or knight == null:
			break
		var toward: Vector2 = (mage.global_position - knight.global_position).normalized()
		var home: Vector2 = knight.global_position
		_slash_pose(knight, 1, mage.global_position.x >= knight.global_position.x)
		await get_tree().create_timer(0.12, false).timeout
		if not is_instance_valid(mage) or not is_instance_valid(knight):
			break
		_slash_pose(knight, SLASH_HIT_FRAME, mage.global_position.x >= knight.global_position.x)
		var tween := create_tween()
		tween.tween_property(knight, "global_position", home + toward * 6.0, 0.09)
		await tween.finished
		if not is_instance_valid(mage) or not is_instance_valid(knight):
			break
		var hit: Vector2 = mage.global_position + Vector2(0, -14) - toward * 10.0
		_fx.spawn("block", hit, COLOR_STARS)
		_fx.spawn("dark_hit", hit, COLOR_DARK)
		_recoil(mage, toward.x * 2.0)
		AudioManager.play_sound("anvil_good", randf_range(1.3, 1.6))
		tween = create_tween()
		tween.tween_property(knight, "global_position", home, 0.2)
		await tween.finished
		if not is_instance_valid(knight) or not is_instance_valid(mage):
			break
		_end_slash(knight)
		_pose(knight, _direction_to(knight, mage))
		await get_tree().create_timer(randf_range(0.35, 0.6), false).timeout


func _faelan_leaves() -> void:
	var elf := _npc(faelan)
	if elf == null:
		return
	var map := get_parent() as Node2D
	await _walk(elf, map.to_global(door_point + Vector2(-30, 30)), 0.8, "down")
	if is_instance_valid(elf):
		create_tween().tween_property(elf, "modulate:a", 0.0, 0.3)


## The shield bursts: blinding light, the dark Lake staggers back, Aurelius sinks down.
func _shield_burst() -> void:
	_hammering = false
	var mage := _npc(aurelius)
	var knight := _npc(dark_lake)
	_end_slash(knight)
	if mage:
		_fx.remove_loop(mage)
		_fx.spawn("light_hit", mage.global_position + Vector2(0, -14), Color.WHITE)
		_fx.spawn("impact", mage.global_position + Vector2(0, -14), COLOR_STARS)
	_flash()
	await get_tree().create_timer(0.25, false).timeout
	_flash()
	_shake()
	AudioManager.play_sound("rock_break", 1.2)
	mage = _npc(aurelius)
	knight = _npc(dark_lake)
	if knight and mage:
		var away: Vector2 = (knight.global_position - mage.global_position).normalized() * 22.0
		create_tween().tween_property(knight, "global_position", knight.global_position + away, 0.3).set_ease(Tween.EASE_OUT)
		var figure := _figure(knight)
		if figure:
			_start_tremble(figure)
	if mage:
		var mage_figure := _figure(mage)
		if mage_figure:
			mage_figure.texture = AURELIUS_LIMP
			_pose(mage, "down")


## The player runs to the door, Aurelius limps along at his side (his arm over the shoulders).
func _flee() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null:
		return
	_unbind()
	var map := get_parent() as Node2D
	player.auto_walk(PackedVector2Array([map.to_global(door_point)]), "down", 60.0)
	var mage := _npc(aurelius)
	if mage == null:
		return
	var figure := _figure(mage)
	if figure:
		figure.texture = AURELIUS_LIMP
	var frame: int = 0
	while is_inside_tree() and is_instance_valid(mage) and is_instance_valid(player) and player.is_auto_walking():
		mage.global_position = mage.global_position.lerp(player.global_position + Vector2(13, -1), 0.35)
		frame += 1
		_pose(mage, "down", 1 + (frame / 4) % 6)
		await get_tree().physics_frame
	if is_instance_valid(mage) and is_instance_valid(player):
		mage.global_position = player.global_position + Vector2(13, -1)
		_pose(mage, "down")


## The dark Lake shakes off the light and runs after them, down to the door.
func _chase() -> void:
	var knight := _npc(dark_lake)
	if knight == null:
		return
	if _tremble:
		_tremble.kill()
	var map := get_parent() as Node2D
	await _walk(knight, map.to_global(door_point + Vector2(-14, -30)), 0.9, "down")


# --- the king --------------------------------------------------------------------------------

func _king_laughs() -> void:
	var lord := _npc(king)
	if lord == null:
		return
	var figure := _figure(lord)
	if figure:
		var home: Vector2 = figure.position
		for i in 8:
			figure.position = home + Vector2(0, -1 if i % 2 == 0 else 0)
			await get_tree().create_timer(0.09, false).timeout
			if not is_instance_valid(figure):
				return
		figure.position = home
	await NpcActing.play(lord, "stand_up")
	if is_instance_valid(lord):
		_fx.spawn("dodge", lord.global_position + Vector2(0, -6), Color(0.75, 0.7, 0.65))
		NpcActing.play(lord, "shake")


func _player_bound() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null:
		return
	_fx.spawn("light_hit", player.global_position + Vector2(0, -12), NpcActing.BLUE)
	_fx.spawn("area_shadow", player.global_position, COLOR_DARK)
	AudioManager.play_sound("skill_used", 0.6)
	_bound = Node2D.new()
	player.add_child(_bound)
	_fx.add_loop(_bound, "aura_curse", COLOR_DARK)
	var sprite := NpcActing.figure_of(player)
	if sprite:
		create_tween().tween_property(sprite, "modulate", Color(0.75, 0.65, 0.95), 0.4)


func _unbind() -> void:
	if _bound == null:
		return
	_fx.remove_loop(_bound)
	var sprite := NpcActing.figure_of(_bound.get_parent() as Node2D)
	if sprite:
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	_bound.queue_free()
	_bound = null


func _king_takes_crystal() -> void:
	var lord := _npc(king)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if lord == null or player == null:
		return
	var home: Vector2 = lord.global_position
	var side: float = 1.0 if home.x > player.global_position.x else -1.0
	await _walk(lord, player.global_position + Vector2(16 * side, -2), 0.7, "left" if side > 0.0 else "right")
	if not is_instance_valid(lord):
		return
	var crystal := Sprite2D.new()
	crystal.texture = NpcActing.icon("holy_lightning_crystal")
	crystal.scale = Vector2(0.6, 0.6)
	crystal.z_index = 2
	get_parent().add_child(crystal)
	crystal.global_position = player.global_position + Vector2(0, -12)
	var take := create_tween()
	take.tween_property(crystal, "global_position", lord.global_position + Vector2(0, -30), 0.45).set_trans(Tween.TRANS_SINE)
	await take.finished
	_fx.spawn("lightning_hit", crystal.global_position, Color(1.0, 0.95, 0.5))
	AudioManager.play_sound("item_reveal", 0.5)
	await get_tree().create_timer(0.35, false).timeout
	if not is_instance_valid(lord):
		return
	crystal.reparent(lord)
	await _walk(lord, home, 0.7, "right" if side > 0.0 else "left")
	_pose(lord, "down")
	if is_instance_valid(crystal):
		var away := create_tween()
		away.tween_property(crystal, "modulate:a", 0.0, 0.3)
		away.tween_callback(crystal.queue_free)


func _lake_darkened() -> void:
	var lord := _npc(king)
	var knight := _npc(lake)
	if lord == null or knight == null:
		return
	var home: Vector2 = lord.global_position
	var side: float = 1.0 if home.x > knight.global_position.x else -1.0
	await _walk(lord, knight.global_position + Vector2(16 * side, -2), 0.6, "left" if side > 0.0 else "right")
	if not is_instance_valid(knight):
		return
	var crystal := Sprite2D.new()
	crystal.texture = NpcActing.icon("holy_dark_crystal")
	crystal.scale = Vector2(0.6, 0.6)
	lord.add_child(crystal)
	crystal.position = Vector2(-6 * side, -14)
	var raise := create_tween()
	raise.tween_property(crystal, "position", Vector2(-4 * side, -32), 0.4)
	await raise.finished
	AudioManager.play_sound("skill_used", 0.7)
	_fx.spawn("dark_bolt", knight.global_position + Vector2(0, -12), COLOR_DARK, -side, crystal.global_position, 0.4)
	await get_tree().create_timer(0.4, false).timeout
	if not is_instance_valid(knight):
		return
	_fx.spawn("area_shadow", knight.global_position, COLOR_DARK)
	_fx.add_loop(knight, "aura_curse", COLOR_DARK)
	var figure := _figure(knight)
	if figure:
		create_tween().tween_property(figure, "modulate", Color(0.35, 0.3, 0.45), 0.9)
	await get_tree().create_timer(0.9, false).timeout
	if is_instance_valid(knight):
		_fx.remove_loop(knight)
	if is_instance_valid(crystal):
		crystal.queue_free()
	if is_instance_valid(lord):
		await _walk(lord, home, 0.6, "right" if side > 0.0 else "left")
		if is_instance_valid(lord):
			_pose(lord, "down")


# --- screen ----------------------------------------------------------------------------------

## White flash over the whole screen.
## The chains click open (a glint), slide down the pillar and drop with a clatter, then fade.
func _chains_fall() -> void:
	var sprite := get_node_or_null(chains) as Sprite2D
	if sprite == null or not sprite.is_visible_in_tree():
		return
	AudioManager.play_sound("unlock", 0.7)
	_fx.spawn("light_hit", sprite.global_position + sprite.offset, Color(0.85, 0.85, 0.9))
	var home: Vector2 = sprite.position
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(sprite, "position:y", home.y + 18.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		AudioManager.play_sound("anvil_miss", 0.8)
		_fx.spawn("dodge", sprite.global_position + Vector2(0, -4), Color(0.6, 0.6, 0.65)))
	tween.tween_property(sprite, "position:y", home.y + 14.0, 0.07)
	tween.tween_property(sprite, "position:y", home.y + 18.0, 0.07)
	tween.tween_interval(0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)


func _flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(1, 1, 1, 0.85)
	layer.add_child(veil)
	var tween: Tween = create_tween()
	tween.tween_property(veil, "color:a", 0.0, 0.45)
	tween.tween_callback(layer.queue_free)


func _shake() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + SHAKE_SECONDS
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera):
		camera.offset = home + Vector2(randf_range(-SHAKE, SHAKE), randf_range(-SHAKE, SHAKE)).round()
		await get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home
