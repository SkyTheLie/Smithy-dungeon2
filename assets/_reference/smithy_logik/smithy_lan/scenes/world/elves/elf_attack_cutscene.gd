class_name ElfAttackCutscene
extends Node
## The night the Lich takes the wind crystal (part 3, top of Sylvaris). The dialogue lines start
## each part with the story action "cutscene:<id>" (Events.cutscene_requested):
## - lich_arrives: a black cloud sinks onto the elder's terrace, the Lich steps out of it
## - wind_shield: a ring of wind rises around the elder and the crystal
## - lich_strike: a flash, the shield bursts, the elder and Faelan fall, the ground shakes
## - player_thrown: the player is flung back across the terrace
## - crystal_taken: the crystal floats out of its holder into the Lich's hand
## - lich_vanish: the Lich sinks back into his cloud and is gone
## - lake_strikes: (the elves won, ElfDefense) a pillar of light, Lake lands before the crystal and
##   strikes, the Lich is pushed back a step
## - arrow_volley: the wind guard's arrows hail into the black cloud, the Lich gives way twice
## - lich_stone_glow: the Lich raises his hand, the stone of earth glows brown in it
## - hammer_bounce: the player's hammer flies at the Lich and bounces off an invisible wall a step
##   in front of him, then clatters to the ground
## - crystal_handover: (the morning after, the elves won) the elder lifts the crystal out of its
##   holder, it floats into his hands and on into the player's
## - crystal_to_king: the crystal floats from the player to the king
## Effects are WorldVfx (battle effects in the world). Fallers with a sheet
## residents/<resident>_fall.png (PixelLab "falling-back-death", bake_elf_attack_anims.gd) play it
## and stay on its last frame, others are tipped over. Lake plays residents/lake_slash.png.
## Figures that fell lie on the ground while story flag `fallen_flag` is set (also after loading).

@export var lich: Sprite2D
@export var cloud: Node2D
@export var crystal: Node2D
@export var shield_center: Node2D
## Figures that fall at "lich_strike" (the elder, Faelan).
@export var fallers: Array[NodePath] = []
## Story flags: from `arrived_flag` the Lich stands there, from `taken_flag` the crystal is in his
## hand, from `gone_flag` he is gone, from `fallen_flag` the fallers lie on the ground.
@export var arrived_flag: String = "lich_on_summit"
@export var taken_flag: String = "wind_crystal_taken"
@export var gone_flag: String = "lich_left_summit"
@export var fallen_flag: String = "elder_fallen"
## Arriving on the summit in this story step, the player walks by himself along `walk_in_path`
## (scene coordinates) and `talker` starts the conversation (the Lich's attack plays to the morning).
@export var walk_in_step: String = "elf_attack_summit"
@export var walk_in_path: PackedVector2Array = []
@export_enum("down", "up", "left", "right") var walk_in_facing: String = "right"
@export var talker: NodePath
## Lake, who comes to the rescue (lake_strikes).
@export var lake: NodePath
## The elder and the king of the crisis council (crystal_handover, crystal_to_king).
@export var council_elder: NodePath
@export var king: NodePath

const SHAKE_SECONDS: float = 1.2
const SHAKE: float = 5.0
const SHIELD_TEXTURE: Texture2D = preload("res://assets/sprites/elves/wind_shield.png")
const SHIELD_FRAMES: int = 8
const SHIELD_LOOP_SECONDS: float = 0.6
const RESIDENT_DIR: String = "res://assets/sprites/residents/"
## Cells of the baked cut scene sheets (bake_elf_attack_anims.gd), centred like the 48 px frames.
const SHEET_CELL: int = 64
const FALL_SECONDS: float = 0.9
const LAKE_SLASH: String = "res://assets/sprites/residents/lake_slash.png"
## Lich sheet: one row of CAST_FRAMES per direction.
const CAST_FRAMES: int = 6
const COLOR_DARK: Color = Color(0.55, 0.3, 0.85)
const COLOR_WIND: Color = Color(0.7, 1.0, 0.95)
const COLOR_LIGHT: Color = Color(1.0, 0.95, 0.6)
const COLOR_DUST: Color = Color(0.75, 0.7, 0.62)
const COLOR_ARROW: Color = Color(0.85, 0.75, 0.55)
const COLOR_EARTH: Color = Color(0.63, 0.44, 0.24)
## The hammer the player throws (NpcActing.icon: composed like the finished item).
const THROWN_HAMMER: String = "copper_hammer_head+wooden_shaft"
const HAMMER_FLIGHT: float = 0.45
## Where the elf archers shoot from, relative to the Lich (west and south-west, off the terrace).
const ARCHERS_FROM: Rect2 = Rect2(-300, -60, 120, 200)
const VOLLEYS: int = 3
const ARROWS_PER_VOLLEY: int = 9
const ARROW_FLIGHT: float = 0.35
## The player is thrown this far, spinning once, in a little arc.
const THROW_DISTANCE: float = 64.0
const THROW_SECONDS: float = 0.55
const THROW_HOP: float = 18.0

var _shield: Sprite2D
var _fx: WorldVfx


func _ready() -> void:
	_fx = WorldVfx.new()
	(get_parent() as Node).add_child.call_deferred(_fx)
	Events.cutscene_requested.connect(_on_cutscene)
	# The morning after the attack (the night ends on the spot): everyone stands up again.
	GameState.slept.connect(func(_day: int) -> void: _apply_state())
	_apply_state.call_deferred()
	# deferred: the step may only begin with this scene's "enter:" event (sent by the Player's _ready)
	_check_walk_in.call_deferred()


func _check_walk_in() -> void:
	if GameState.story.step == walk_in_step and not talker.is_empty():
		_walk_to_talker()


## Cut scene on arrival (step `walk_in_step`): the player walks by himself along `walk_in_path` to the
## elder, then the elder starts talking. The conversation stays open to the end (keep_dialogue_open
## on the elder), so the player can't walk off in the middle and start it again.
func _walk_to_talker() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var map := get_parent() as Node2D
	# already close (e.g. put next to the elder by the admin panel's quest jump): talk right away
	var npc := get_node_or_null(talker) as Node2D
	if player == null or map == null or walk_in_path.is_empty() \
			or (npc and player.global_position.distance_to(npc.global_position) < 80.0):
		_start_talk()
		return
	var way := PackedVector2Array()
	for point in walk_in_path:
		way.append(map.to_global(point))
	player.auto_walk(way, walk_in_facing)
	player.auto_walk_finished.connect(_start_talk, CONNECT_ONE_SHOT)


func _start_talk() -> void:
	var npc := get_node_or_null(talker) as StoryNpc
	if npc and npc.visible and GameState.story.step == walk_in_step and GameState.story.npc_has_news(npc.npc_id):
		npc.interacted.emit()


## Shows the scene as the story left it (after loading or coming back).
func _apply_state() -> void:
	var story: Story = GameState.story
	var lich_here: bool = story.has_flag(arrived_flag) and not story.has_flag(gone_flag)
	for node: Node2D in [lich, cloud]:
		if node:
			node.visible = lich_here
			node.modulate.a = 1.0
	if crystal:
		crystal.visible = not story.has_flag(taken_flag)
	for faller in _get_fallers():
		_lay_down(faller, false, not story.has_flag(fallen_flag))


func _get_fallers() -> Array[Node2D]:
	var list: Array[Node2D] = []
	for path in fallers:
		var faller := get_node_or_null(path) as Node2D
		if faller:
			list.append(faller)
	return list


func _on_cutscene(cutscene_id: String) -> void:
	match cutscene_id:
		"lich_arrives":
			_arrive()
		"wind_shield":
			_raise_shield()
		"lich_strike":
			_strike()
		"player_thrown":
			_throw_player()
		"crystal_taken":
			_take_crystal()
		"lich_vanish":
			_vanish()
		"lake_strikes":
			_lake_strikes()
		"arrow_volley":
			_arrow_volley()
		"lich_stone_glow":
			_stone_glow()
		"hammer_bounce":
			_hammer_bounce()
		"crystal_handover":
			_hand_over_crystal()
		"crystal_to_king":
			_crystal_to_king()


func _arrive() -> void:
	GameState.story.set_flag(arrived_flag)
	for node: Node2D in [cloud, lich]:
		if node == null:
			continue
		node.visible = true
		node.modulate.a = 0.0
		create_tween().tween_property(node, "modulate:a", 1.0, 1.4)
	if cloud:
		var home: Vector2 = cloud.position
		cloud.position = home + Vector2(0, -60)
		create_tween().tween_property(cloud, "position", home, 1.4).set_ease(Tween.EASE_OUT)
	AudioManager.play_sound("rock_break", 0.5)
	# the elder and Faelan turn to the Lich
	for faller in _get_fallers():
		_pose(faller, "right")
	if lich:
		await get_tree().create_timer(1.0, false).timeout
		_fx.spawn("area_shadow", lich.global_position, COLOR_DARK)
		_fx.spawn("dark_hit", lich.global_position + Vector2(0, -20), COLOR_DARK)


func _raise_shield() -> void:
	if shield_center == null:
		return
	_shield = Sprite2D.new()
	_shield.texture = SHIELD_TEXTURE
	_shield.hframes = SHIELD_FRAMES
	_shield.scale = Vector2(0.1, 0.1)
	shield_center.add_child(_shield)
	create_tween().tween_property(_shield, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK)
	_shield.create_tween().set_loops().tween_property(_shield, "frame", SHIELD_FRAMES - 1, SHIELD_LOOP_SECONDS).from(0)
	AudioManager.play_sound("skill_used", 0.8)
	_fx.spawn("area_storm", shield_center.global_position, COLOR_WIND)
	for i in 4:
		var angle: float = i * TAU / 4.0
		_fx.spawn("air_hit", shield_center.global_position + Vector2(cos(angle) * 22.0, sin(angle) * 10.0 - 12.0), COLOR_WIND)


func _strike() -> void:
	GameState.story.set_flag(fallen_flag)
	# the Lich raises his hand, a bolt of dark lightning tears into the wind
	if lich and shield_center:
		_cast()
		_fx.spawn("lightning_bolt", shield_center.global_position + Vector2(0, -14), COLOR_DARK, -1.0,
				lich.global_position + Vector2(-10, -26), 0.25)
		await get_tree().create_timer(0.25, false).timeout
		_fx.spawn("lightning_hit", shield_center.global_position + Vector2(0, -14), COLOR_DARK)
		_fx.spawn("dark_hit", shield_center.global_position + Vector2(0, -10), COLOR_DARK)
	_flash()
	if _shield:
		var tween: Tween = create_tween()
		tween.tween_property(_shield, "scale", Vector2(1.6, 1.6), 0.25)
		tween.parallel().tween_property(_shield, "modulate:a", 0.0, 0.25)
		tween.tween_callback(_shield.queue_free)
	for faller in _get_fallers():
		_lay_down(faller, true)
	AudioManager.play_sound("rock_break", 0.7)
	_shake()
	await get_tree().create_timer(FALL_SECONDS * 0.8, false).timeout
	for faller in _get_fallers():
		_fx.spawn("impact", faller.global_position + Vector2(-10, -4), COLOR_DUST)


## A fist of air and ash flies from the Lich into the player, who is flung back across the terrace
## in a little arc, spinning once, and lands in a cloud of dust.
func _throw_player() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if player == null:
		return
	var away: Vector2 = Vector2(-1, 0)
	if lich:
		_cast()
		away = (player.global_position - lich.global_position).normalized()
		_fx.spawn("dark_bolt", player.global_position + Vector2(0, -14), COLOR_DARK, -1.0,
				lich.global_position + Vector2(-10, -26), 0.3)
		await get_tree().create_timer(0.3, false).timeout
	_fx.spawn("dark_hit", player.global_position + Vector2(0, -14), COLOR_DARK)
	_fx.spawn("impact", player.global_position + Vector2(0, -14), Color.WHITE)
	_flash()
	_shake()
	var start: Vector2 = player.global_position
	var end: Vector2 = start + away * THROW_DISTANCE
	var spinner: Node2D = _player_visual(player)
	var turn: float = -1.0 if away.x >= 0.0 else 1.0
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		player.global_position = start.lerp(end, value) + Vector2(0, -sin(value * PI) * THROW_HOP)
		spinner.rotation = TAU * value * turn,
		0.0, 1.0, THROW_SECONDS).set_ease(Tween.EASE_OUT)
	await tween.finished
	spinner.rotation = 0.0
	_fx.spawn("impact", end + Vector2(0, -4), COLOR_DUST)
	AudioManager.play_sound("wood_break", 0.6)


## The node that draws the player (spins without turning the camera or the collision).
func _player_visual(player: Node2D) -> Node2D:
	for child in player.get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			return child as Node2D
	return player


func _take_crystal() -> void:
	GameState.story.set_flag(taken_flag)
	if crystal == null or lich == null:
		return
	_fx.spawn("air_hit", crystal.global_position, COLOR_WIND)
	var tween: Tween = create_tween()
	tween.tween_property(crystal, "global_position", lich.global_position + Vector2(0, -30), 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(crystal, "modulate:a", 0.0, 0.3)
	tween.tween_callback(crystal.hide)
	create_tween().tween_property(lich, "modulate", Color(1.4, 1.6, 1.5), 1.6)
	AudioManager.play_sound("rarity_up", 0.6)
	# a trail of wind sparks behind the crystal
	for i in 6:
		await get_tree().create_timer(0.25, false).timeout
		if is_instance_valid(crystal) and crystal.visible:
			_fx.spawn("glow", crystal.global_position, COLOR_WIND)
	_fx.spawn("air_hit", lich.global_position + Vector2(0, -30), COLOR_WIND)


## A pillar of light falls onto the terrace, Lake lands in it between the Lich and the crystal and
## strikes; the Lich is pushed back.
func _lake_strikes() -> void:
	var hero := get_node_or_null(lake) as Node2D
	if hero:
		_fx.spawn("light_bolt", hero.global_position + Vector2(0, -8), COLOR_LIGHT, 1.0,
				hero.global_position + Vector2(0, -180), 0.22)
		await get_tree().create_timer(0.22, false).timeout
		_fx.spawn("area_holy", hero.global_position, COLOR_LIGHT)
		_fx.add_loop(hero, "aura_holy", COLOR_LIGHT)
	_flash()
	AudioManager.play_sound("rock_break", 0.6)
	_shake()
	if hero:
		await _play_sheet(hero, LAKE_SLASH, 0.5, false)
		if lich:
			_fx.spawn("slash", lich.global_position + Vector2(-8, -18), COLOR_LIGHT, 1.0)
			_fx.spawn("light_hit", lich.global_position + Vector2(-6, -18), COLOR_LIGHT)
		AudioManager.play_sound("anvil_perfect", 1.3)
	_push_lich(18.0)
	if hero:
		await get_tree().create_timer(2.5, false).timeout
		_fx.remove_loop(hero)


## The wind guard's volleys: arrows from the west and south-west into the cloud, each wave pushes
## the Lich back a little.
func _arrow_volley() -> void:
	if lich == null:
		return
	AudioManager.play_sound("skill_used", 1.3)
	var target: Vector2 = lich.global_position + Vector2(0, -18)
	_fx.spawn("area_arrows", lich.global_position + Vector2(0, -6), COLOR_ARROW)
	for wave in VOLLEYS:
		for i in ARROWS_PER_VOLLEY:
			var from: Vector2 = lich.global_position + Vector2(
					randf_range(ARCHERS_FROM.position.x, ARCHERS_FROM.end.x),
					randf_range(ARCHERS_FROM.position.y, ARCHERS_FROM.end.y))
			var hit: Vector2 = target + Vector2(randf_range(-20, 20), randf_range(-22, 10))
			_fx.spawn("arrow", hit, COLOR_ARROW, 1.0, from, ARROW_FLIGHT)
			_hit_later(hit, ARROW_FLIGHT)
			await get_tree().create_timer(0.06, false).timeout
		await get_tree().create_timer(ARROW_FLIGHT, false).timeout
		_fx.spawn("dark_hit", target, COLOR_DARK)
		AudioManager.play_sound("wood_break", 1.4)
		_push_lich(7.0)
		target = lich.global_position + Vector2(0, -18)
		await get_tree().create_timer(0.35, false).timeout


## The elder turns to the pedestal, the crystal rises out of its holder into his hands, he turns
## to the player and the crystal floats on into the player's hands (and is gone into the bag).
func _stone_glow() -> void:
	if lich == null or not lich.visible:
		return
	_cast()
	var hand: Vector2 = lich.global_position + Vector2(-8, -26)
	AudioManager.play_sound("skill_used", 0.6)
	for i in 3:
		_fx.spawn("light_hit" if i % 2 == 0 else "buff", hand, COLOR_EARTH)
		await get_tree().create_timer(0.3, false).timeout


## The hammer spins through the air at the Lich, stops short with a flash of dark light, bounces
## back and falls.
func _hammer_bounce() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var texture := NpcActing.icon(THROWN_HAMMER)
	if player == null or lich == null or texture == null:
		return
	var hammer := Sprite2D.new()
	hammer.texture = texture
	hammer.scale = Vector2(0.8, 0.8)
	hammer.z_index = 2
	(get_parent() as Node).add_child(hammer)
	var start: Vector2 = player.global_position + Vector2(0, -16)
	var wall: Vector2 = start.lerp(lich.global_position + Vector2(0, -16), 0.8)
	hammer.global_position = start
	AudioManager.play_sound("axe_hit", 0.5)
	var fly := create_tween()
	fly.tween_property(hammer, "global_position", wall, HAMMER_FLIGHT)
	fly.parallel().tween_property(hammer, "rotation", TAU * 2.0, HAMMER_FLIGHT)
	await fly.finished
	AudioManager.play_sound("anvil_miss", 0.9)
	_fx.spawn("block", wall, COLOR_DARK)
	_fx.spawn("dark_hit", wall, COLOR_DARK)
	var back: Vector2 = wall + (start - wall).normalized() * 30.0 + Vector2(0, 14)
	var bounce := create_tween()
	bounce.tween_property(hammer, "global_position", back + Vector2(0, -16), 0.2).set_ease(Tween.EASE_OUT)
	bounce.parallel().tween_property(hammer, "rotation", hammer.rotation - PI, 0.35)
	bounce.tween_property(hammer, "global_position", back, 0.18).set_ease(Tween.EASE_IN)
	bounce.tween_callback(func() -> void: AudioManager.play_sound("step", 0.7))
	bounce.tween_interval(0.8)
	bounce.tween_property(hammer, "modulate:a", 0.0, 0.3)
	bounce.tween_callback(hammer.queue_free)


func _hand_over_crystal() -> void:
	var elder := get_node_or_null(council_elder) as Node2D
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if crystal == null or elder == null or player == null:
		return
	crystal.show()
	crystal.modulate.a = 1.0
	crystal.z_index = 2  # floats in front of the figures (it sorts with its pedestal otherwise)
	_pose(elder, "right" if crystal.global_position.x > elder.global_position.x else "left")
	_fx.spawn("air_hit", crystal.global_position, COLOR_WIND)
	AudioManager.play_sound("rarity_up", 0.7)
	var tween := create_tween()
	tween.tween_property(crystal, "global_position", crystal.global_position + Vector2(0, -8), 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(crystal, "global_position", elder.global_position + Vector2(0, -22), 0.6).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_pose(elder, _direction_to(elder, player))
	_fx.spawn("glow", crystal.global_position, COLOR_WIND)
	await get_tree().create_timer(0.35, false).timeout
	tween = create_tween()
	tween.tween_property(crystal, "global_position", player.global_position + Vector2(0, -20), 0.7).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_fx.spawn("buff", player.global_position + Vector2(0, -14), COLOR_WIND)
	AudioManager.play_sound("item_reveal", 1.0)
	tween = create_tween()
	tween.tween_property(crystal, "modulate:a", 0.0, 0.3)
	tween.tween_callback(crystal.hide)


## The crystal shows in the player's hands again and floats over to the king.
func _crystal_to_king() -> void:
	var monarch := get_node_or_null(king) as Node2D
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if crystal == null or monarch == null or player == null:
		return
	crystal.global_position = player.global_position + Vector2(0, -20)
	crystal.modulate.a = 0.0
	crystal.z_index = 2
	crystal.show()
	_pose(monarch, _direction_to(monarch, player))
	var tween := create_tween()
	tween.tween_property(crystal, "modulate:a", 1.0, 0.25)
	tween.tween_property(crystal, "global_position", monarch.global_position + Vector2(0, -22), 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_fx.spawn("glow", crystal.global_position, COLOR_WIND)
	AudioManager.play_sound("coins", 0.8)
	tween = create_tween()
	tween.tween_property(crystal, "modulate:a", 0.0, 0.4)
	tween.tween_callback(crystal.hide)


func _direction_to(from: Node2D, to: Node2D) -> String:
	var offset: Vector2 = to.global_position - from.global_position
	if absf(offset.x) > absf(offset.y):
		return "right" if offset.x > 0.0 else "left"
	return "down" if offset.y > 0.0 else "up"


func _hit_later(at: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	_fx.spawn("hit_arrow", at, COLOR_ARROW)


func _push_lich(by: float) -> void:
	if lich == null:
		return
	var away: Vector2 = Vector2(by, -by * 0.2)
	create_tween().tween_property(lich, "position", lich.position + away, 0.3).set_ease(Tween.EASE_OUT)
	if cloud:
		create_tween().tween_property(cloud, "position", cloud.position + away, 0.3).set_ease(Tween.EASE_OUT)


## The Lich plays his casting row once (his sheet: CAST_FRAMES per direction).
func _cast() -> void:
	if lich == null or lich.hframes < CAST_FRAMES:
		return
	var row_start: int = (lich.frame / CAST_FRAMES) * CAST_FRAMES
	var tween := create_tween()
	tween.tween_property(lich, "frame", row_start + CAST_FRAMES - 1, 0.45).from(row_start)
	tween.tween_property(lich, "frame", row_start, 0.0)


func _vanish() -> void:
	GameState.story.set_flag(gone_flag)
	if lich:
		_fx.spawn("area_shadow", lich.global_position, COLOR_DARK)
	for node: Node2D in [lich, cloud]:
		if node:
			var tween: Tween = create_tween()
			tween.tween_property(node, "modulate:a", 0.0, 1.2)
			tween.tween_callback(node.hide)


## Lays a figure down (`stand_up` = back on its feet, e.g. the morning after). With a fall sheet
## (residents/<resident>_fall.png) it plays it or shows its last frame, otherwise it is tipped over.
func _lay_down(faller: Node2D, animated: bool, stand_up: bool = false) -> void:
	var figure := faller.get_node_or_null("Figure") as Sprite2D
	var sheet_path: String = _fall_sheet(faller)
	if figure and not sheet_path.is_empty():
		if stand_up:
			if figure.texture == load(sheet_path):
				figure.texture = load(RESIDENT_DIR + str(faller.get("resident")) + ".png")
				figure.region_rect = CharacterBaker.get_frame_rect("down")
			return
		if animated:
			_play_sheet(faller, sheet_path, FALL_SECONDS, true)
		else:
			_show_sheet_frame(figure, load(sheet_path), -1)
		return
	var target: Node2D = figure if figure else faller
	var angle: float = 0.0 if stand_up else -90.0
	if animated:
		create_tween().tween_property(target, "rotation_degrees", angle, 0.3)
	else:
		target.rotation_degrees = angle


func _fall_sheet(faller: Node2D) -> String:
	var resident: String = str(faller.get("resident")) if "resident" in faller else ""
	var path: String = RESIDENT_DIR + resident + "_fall.png"
	return path if not resident.is_empty() and ResourceLoader.exists(path) else ""


## Plays a one-row sheet (SHEET_CELL cells) on the figure of `npc` in `seconds`. `hold` = stays on
## the last frame, otherwise the figure gets its walk sheet back (standing, looking right).
func _play_sheet(npc: Node2D, path: String, seconds: float, hold: bool) -> void:
	var figure := npc.get_node_or_null("Figure") as Sprite2D
	if figure == null or not ResourceLoader.exists(path):
		return
	var sheet: Texture2D = load(path)
	var walk_sheet: Texture2D = figure.texture
	var count: int = sheet.get_width() / SHEET_CELL
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		_show_sheet_frame(figure, sheet, mini(int(value), count - 1)),
		0.0, float(count), seconds)
	await tween.finished
	if not hold and is_instance_valid(figure):
		figure.texture = walk_sheet
		figure.region_rect = CharacterBaker.get_frame_rect("right")


## Shows frame `index` of a one-row sheet (-1 = the last one).
func _show_sheet_frame(figure: Sprite2D, sheet: Texture2D, index: int) -> void:
	var count: int = sheet.get_width() / SHEET_CELL
	figure.texture = sheet
	figure.region_enabled = true
	figure.region_rect = Rect2((count - 1 if index < 0 else index) * SHEET_CELL, 0, SHEET_CELL, SHEET_CELL)


## A resident figure looks in `direction` (standing frame of its walk sheet). A StoryNpc also keeps
## it (its `facing`), so it doesn't turn back when it talks.
func _pose(npc: Node2D, direction: String) -> void:
	if "facing" in npc:
		npc.set("facing", direction)
	if npc.has_method("_face"):
		npc.call("_face", direction)
		return
	var figure := npc.get_node_or_null("Figure") as Sprite2D
	if figure and figure.region_enabled and figure.region_rect.size.x == CharacterBaker.FRAME:
		figure.region_rect = CharacterBaker.get_frame_rect(direction)


## White flash over the whole screen.
func _flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(1, 1, 1, 0.9)
	layer.add_child(veil)
	var tween: Tween = create_tween()
	tween.tween_property(veil, "color:a", 0.0, 0.5)
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
