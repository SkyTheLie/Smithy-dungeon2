class_name AltarBattleCutscene
extends StoryCutscene
## The Altar of the Nine from the moment the alliance comes in (2026-11-14, sketches "altaraum1-3").
## Beats (lines with "hide_for" and "cutscene:<id>"):
## dialogue "gate_opens":
## - altar_enter: the smith walks in from the south door (the leaders come in by their arrive_path)
## - camera_up: the view goes up to the altar where the king stands
## - king_insert: the king lays his setting into the hollow of the altar
## - crystals_rise: the nine holy crystals rise out of his coat and circle over the altar
## - crystals_fall: one after the other they dive into the setting
## - altar_awaken: the altar wakes, the power of each crystal runs over the floor to its pillar
##   (AltarElements), the pillars light up in their colours
## - battle_start: the view goes back; the king's troops pour in from left and right, the warriors
##   of the alliance storm in through the south door (SkirmishGroups under `battle`)
## dialogues "report_altar_*":
## - boss_west, boss_south, boss_east: a captain of the king breaks through from that side
## - king_to_tablet: the king walks to the tablet (gate) in the north, the dark Lake stands below him;
##   the view goes up with him
## - king_hands: the king turns to the tablet and presses his hands on it (steps against it, the
##   stone sparks dark, the pillars flicker)
## dialogue "king_shatters" (step final_forge):
## - evil_into_king: something evil flies out of the tablet into the king, he turns dark
## - lake_holds_king: Lake grabs the king and holds him back
## The king and Lake exist twice each (StoryNpcs switched by flags): at the altar until king_at_tablet,
## at the tablet after it; Lake (light) until king_possessed, holding the king after it.

@export var elements: NodePath
@export var altar: NodePath
@export var king_altar: NodePath
@export var king_tablet: NodePath
@export var dark_lake: NodePath
@export var lake: NodePath
@export var lake_holding: NodePath
## Node with the SkirmishGroups of the battle in the hall.
@export var battle: NodePath
@export var boss_west: NodePath
@export var boss_south: NodePath
@export var boss_east: NodePath
## The south door (global position of the marker where the alliance comes in).
@export var entrance: NodePath
## The narrator (StoryNpc): when his conversation ends (also cut short), the view goes back.
@export var narrator: NodePath

const CRYSTALS: Array[String] = ["fire", "lightning", "poison", "light", "dark", "ice", "wind", "water", "earth"]
const CRYSTAL_DIR: String = "res://assets/sprites/items/holy_crystals/holy_%s_crystal.png"
const CRYSTAL_CELL: int = 48
const SETTING: String = "res://assets/sprites/items/true_setting.png"
const SHADOW: String = "res://assets/sprites/effects/lake_shadow.png"
const SHADOW_FRAMES: int = 9
const HIT: Dictionary = {"fire": "fire_hit", "lightning": "lightning_hit", "poison": "poison_hit", "light": "light_hit",
		"dark": "dark_hit", "ice": "ice_hit", "wind": "air_hit", "water": "water_hit", "earth": "earth_hit"}
## Above the altar's foot: the hollow where the setting lies, and the middle of the crystals' circle.
const HOLLOW: Vector2 = Vector2(0, -36)
const CIRCLE: Vector2 = Vector2(0, -78)
const CIRCLE_RADIUS: Vector2 = Vector2(38, 14)
## Where the king and the dark Lake stand at the tablet (scene coordinates).
const TABLET_SPOT: Vector2 = Vector2(0, -226)
const GUARD_SPOT: Vector2 = Vector2(0, -196)
const HOLD_SPOT: Vector2 = Vector2(0, -212)
## Where the captains come from (offset from their place).
const BOSS_FROM: Dictionary = {"west": Vector2(-330, 0), "south": Vector2(0, 300), "east": Vector2(330, 0)}
## Walk sheets of the captains (6 frames of 48 px, looking left like every enemy picture).
const BOSS_WALK: Dictionary = {
	"west": "res://assets/sprites/enemies/altar_shadow_lord_walk.png",
	"south": "res://assets/sprites/enemies/altar_hellhound_walk.png",
	"east": "res://assets/sprites/enemies/altar_champion_walk.png",
}
## Step in which each captain comes. When it begins the captain waits out of sight (BOSS_FROM) for his
## beat, instead of standing there first and then jumping out to march in (2026-11-14).
const BOSS_STEPS: Dictionary = {"altar_west": "west", "altar_south": "south", "altar_east": "east"}
## If his beat does not come (narrator closed early), the captain marches in after this many seconds
## in which neither the narrator talks nor the fight window is open.
const BOSS_WAIT_MAX: float = 8.0
## The way of each captain to his place (offsets from it, the first one = where he waits). Garm's
## place is right above the south pillar: he walks round it on the left instead of through it.
const BOSS_WAYS: Dictionary = {
	"west": [Vector2(-330, 0), Vector2.ZERO],
	"south": [Vector2(0, 300), Vector2(0, 118), Vector2(-72, 104), Vector2(-72, 8), Vector2.ZERO],
	"east": [Vector2(330, 0), Vector2.ZERO],
}
## Idle loops of the captains once they stand at their place (PixelLab, 2026-11-15; looking left).
const BOSS_IDLE: Dictionary = {
	"west": "res://assets/sprites/enemies/altar_shadow_lord_idle.png",
	"south": "res://assets/sprites/enemies/altar_hellhound_idle.png",
	"east": "res://assets/sprites/enemies/altar_champion_idle.png",
}
const BOSS_IDLE_FPS: float = 5.0
## Walking speed of a captain (px per second) and of his walk frames.
const BOSS_SPEED: float = 130.0
const BOSS_WALK_FPS: float = 8.0
const POSSESSED: Color = Color(0.55, 0.4, 0.7)
const VIOLET: Color = Color(0.6, 0.35, 0.9)

## The crystals while they circle (Sprite2D), with their element in the meta "element".
var _crystals: Array[Sprite2D] = []
var _circle_time: float = 0.0
var _circle_speed: float = 1.2
var _setting: Sprite2D
var _shadow: Sprite2D
var _shadow_time: float = 0.0


## Captains waiting out of sight for their beat: side -> their place (position in the scene).
var _parked: Dictionary = {}
## Captains walking in right now (side -> true): no idle meanwhile.
var _walking: Dictionary = {}
## Idle loop per captain: side -> {"figure": Sprite2D, "sheet": Texture2D, "frames": int}.
var _idle: Dictionary = {}
var _idle_time: float = 0.0


func _ready() -> void:
	super()
	GameState.story.step_started.connect(_on_step_started)
	_restore.call_deferred()


func _exit_tree() -> void:
	if GameState.story.step_started.is_connected(_on_step_started):
		GameState.story.step_started.disconnect(_on_step_started)


## A captain's step begins while the altar is open: he waits out of sight for his beat.
func _on_step_started(step_id: String) -> void:
	var side: String = BOSS_STEPS.get(step_id, "")
	var boss := node2d(_boss_path(side)) if not side.is_empty() else null
	if boss == null or _parked.has(side):
		return
	_parked[side] = boss.position
	boss.position += BOSS_FROM.get(side, Vector2.ZERO)
	# The fallback counts only time in which nothing else can send him: while the fight that brought
	# the step is still on screen the narrator waits for it, and while he talks his line (or his end)
	# sends the captain. Before, the 8 s ran during the fight window and he came before his text.
	var free_time: float = 0.0
	while free_time < BOSS_WAIT_MAX:
		if not await wait(0.25) or not _parked.has(side):
			return
		free_time = 0.0 if _narrator_busy() else free_time + 0.25
	_boss_arrives(side)


## The narrator talks or is about to (the fight window that brought the news is still open).
func _narrator_busy() -> bool:
	var teller := node2d(narrator)
	var box := teller.get_node_or_null("DialogueBox") as DialogueBox if teller else null
	if box != null and box.visible:
		return true
	var battle := get_tree().get_first_node_in_group(BattleWindow.GROUP) as Control
	return battle != null and battle.visible


## Loaded later in the story: the king possessed (dark, with an aura). The view always comes back
## to the player when the narrator's conversation ends, however it ends.
func _restore() -> void:
	for side: String in BOSS_IDLE:
		var boss := node2d(_boss_path(side))
		var figure := figure_of(boss.get_node_or_null("Talk") as Node2D) if boss else null
		if figure and ResourceLoader.exists(BOSS_IDLE[side]):
			var sheet: Texture2D = load(BOSS_IDLE[side])
			_idle[side] = {"figure": figure, "sheet": sheet, "frames": maxi(1, sheet.get_width() / sheet.get_height())}
	var teller := node2d(narrator)
	var box := teller.get_node_or_null("DialogueBox") as DialogueBox if teller else null
	if box:
		box.finished.connect(_on_narrator_finished)
	var story: Story = GameState.story
	if story.has_flag("king_possessed") and not story.has_flag("king_fell"):
		_darken_king(false)


func _on_narrator_finished() -> void:
	camera_home(0.6)
	# the narrator ended before a captain's beat: he comes anyway
	for side: String in _parked.keys():
		_boss_arrives(side)


func _process(delta: float) -> void:
	_play_idles(delta)
	if not _crystals.is_empty():
		_circle_time += delta * _circle_speed
		var middle: Vector2 = _altar_point(CIRCLE)
		for i in _crystals.size():
			var crystal := _crystals[i]
			if not is_instance_valid(crystal) or crystal.get_meta(&"falling", false):
				continue
			var angle: float = _circle_time + TAU * i / _crystals.size()
			crystal.global_position = crystal.global_position.lerp(
					middle + Vector2(cos(angle) * CIRCLE_RADIUS.x, sin(angle) * CIRCLE_RADIUS.y), minf(1.0, delta * 4.0))
			crystal.z_index = 3 if sin(angle) > 0.0 else 1
	if _shadow and is_instance_valid(_shadow):
		_shadow_time += delta
		_shadow.frame = int(_shadow_time * 10.0) % SHADOW_FRAMES


## The captains breathe at their place (not while waiting out of sight or walking in).
func _play_idles(delta: float) -> void:
	_idle_time += delta
	for side: String in _idle:
		if _walking.has(side) or _parked.has(side):
			continue
		var entry: Dictionary = _idle[side]
		var figure: Sprite2D = entry["figure"]
		if not is_instance_valid(figure) or not figure.is_visible_in_tree():
			continue
		if figure.texture != entry["sheet"]:
			figure.texture = entry["sheet"]
			figure.hframes = entry["frames"]
		figure.frame = int(_idle_time * BOSS_IDLE_FPS) % int(entry["frames"])


## The idle frame a captain shows now (-1 = he does not idle, e.g. walking in). For tests.
func get_idle_frame(side: String) -> int:
	var entry: Dictionary = _idle.get(side, {})
	if entry.is_empty() or (entry["figure"] as Sprite2D).texture != entry["sheet"]:
		return -1
	return (entry["figure"] as Sprite2D).frame


func _play_beat(id: String) -> bool:
	match id:
		"altar_enter":
			_enter()
		"camera_up":
			pan_camera(_altar_point(Vector2(0, -40)), 2.2)
		"king_insert":
			_insert()
		"crystals_rise":
			_rise()
		"crystals_fall":
			_fall()
		"altar_awaken":
			_awaken()
		"battle_start":
			_battle()
		"boss_west":
			_boss_arrives("west")
		"boss_south":
			_boss_arrives("south")
		"boss_east":
			_boss_arrives("east")
		"king_to_tablet":
			_to_tablet()
		"king_hands":
			_king_hands()
		"evil_into_king":
			_evil()
		"lake_holds_king":
			_hold()
		"camera_back":
			camera_home(1.0)
		_:
			return false
	return true


## Crystals still circling over the altar (for tests).
func get_circling_count() -> int:
	return _crystals.size()


func _altar_point(offset: Vector2) -> Vector2:
	var node := node2d(altar)
	return (node.global_position if node else global_position) + offset


func _at(point: Vector2) -> Vector2:
	return to_global(point)


func _enter() -> void:
	var door := node2d(entrance)
	var body := player()
	if body == null:
		return
	var start: Vector2 = door.global_position if door else body.global_position
	walk_player(PackedVector2Array([start, start + Vector2(0, -80)]), "up", 2.4)


func _insert() -> void:
	var king := node2d(king_altar)
	if king == null:
		return
	_setting = Sprite2D.new()
	_setting.texture = load(SETTING)
	_setting.z_index = 3
	_setting.z_as_relative = false
	add_child(_setting)
	_setting.global_position = king.global_position + Vector2(0, -26)
	_setting.modulate.a = 0.0
	var lift := create_tween()
	lift.tween_property(_setting, "modulate:a", 1.0, 0.3)
	lift.tween_property(_setting, "global_position", king.global_position + Vector2(0, -40), 0.5)
	lift.tween_property(_setting, "global_position", _altar_point(HOLLOW), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await lift.finished
	if not is_inside_tree():
		return
	AudioManager.play_sound("anvil_good", 0.7)
	fx.spawn("impact", _altar_point(HOLLOW), Color(0.7, 0.6, 0.9))
	var place := node2d(elements)
	if place and place.has_method("place_setting"):
		place.call("place_setting")
	_setting.queue_free()
	_setting = null


func _rise() -> void:
	var king := node2d(king_altar)
	var from: Vector2 = king.global_position + Vector2(0, -18) if king else _altar_point(CIRCLE)
	_circle_speed = 1.2
	for i in CRYSTALS.size():
		var crystal := Sprite2D.new()
		crystal.texture = load(CRYSTAL_DIR % CRYSTALS[i])
		crystal.region_enabled = true
		crystal.region_rect = Rect2(0, 0, CRYSTAL_CELL, CRYSTAL_CELL)
		crystal.scale = Vector2.ONE * 0.4
		crystal.z_as_relative = false
		crystal.set_meta(&"element", CRYSTALS[i])
		add_child(crystal)
		crystal.global_position = from
		_crystals.append(crystal)
		fx.spawn("glow", from, AltarElements.COLORS[CRYSTALS[i]])
		AudioManager.play_sound("rarity_up", 0.6 + 0.06 * i)
		if not await wait(0.22):
			return
	# faster and faster
	var spin := create_tween()
	spin.tween_property(self, "_circle_speed", 4.5, 2.0)


func _fall() -> void:
	var target: Vector2 = _altar_point(HOLLOW)
	for crystal in _crystals.duplicate():
		if not is_instance_valid(crystal):
			continue
		crystal.set_meta(&"falling", true)
		var dive := create_tween().set_parallel()
		dive.tween_property(crystal, "global_position", target, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		dive.tween_property(crystal, "scale", Vector2.ONE * 0.15, 0.28)
		await dive.finished
		if not is_inside_tree():
			return
		var element: String = crystal.get_meta(&"element", "light")
		fx.spawn(HIT.get(element, "glow"), target, Color.WHITE)
		AudioManager.play_sound("anvil_good", 0.9)
		crystal.queue_free()
		_crystals.erase(crystal)
		if not await wait(0.12):
			return
	flash(Color(1, 1, 1, 0.6), 0.6)
	shake(0.6, 2.0)


func _awaken() -> void:
	var place := node2d(elements)
	fx.spawn("area_holy", _altar_point(Vector2(0, -10)), Color.WHITE)
	shake(0.8, 1.5)
	if place and place.has_method("awaken"):
		await place.call("awaken")


func _battle() -> void:
	await camera_home(1.2)
	if not is_inside_tree():
		return
	var holder := node2d(battle)
	var door := node2d(entrance)
	if holder == null:
		return
	var middle: float = _altar_point(Vector2.ZERO).x
	for group in holder.get_children():
		if not group.has_method("march_in"):
			continue
		var side: float = -1.0 if (group as Node2D).global_position.x < middle else 1.0
		group.call("march_in", Vector2(side * 220.0, 0), door.global_position if door else Vector2.ZERO)
	AudioManager.play_sound("rock_break", 0.6)
	shake(1.5, 1.0)


func _boss_path(side: String) -> NodePath:
	return {"west": boss_west, "south": boss_south, "east": boss_east}.get(side, NodePath())


func _boss_arrives(side: String) -> void:
	var boss := node2d(_boss_path(side))
	if boss == null:
		return
	# he waits out of sight since his step began. Not waiting = he stands at his place already (loaded
	# later in the step, or the narrator's report played again with E): he stays there, no second
	# entrance (2026-11-14: he vanished and walked in again whenever the player pressed E near him)
	if not _parked.has(side):
		return
	var home: Vector2 = _parked[side]
	_parked.erase(side)
	_walking[side] = true
	var figure := figure_of(boss.get_node_or_null("Talk") as Node2D)
	# at his place he shows his idle loop (or his standing picture), looking left
	var stand: Texture2D = (_idle[side]["sheet"] if _idle.has(side) else figure.texture) if figure else null
	var stand_frames: int = int(_idle[side]["frames"]) if _idle.has(side) else 1
	if figure and ResourceLoader.exists(BOSS_WALK.get(side, "")):
		figure.texture = load(BOSS_WALK[side])
		figure.hframes = 6
	var steps: float = 0.0
	var walked: float = 0.0
	for offset: Vector2 in BOSS_WAYS.get(side, [Vector2.ZERO]):
		var target: Vector2 = home + offset
		while is_inside_tree() and boss.position.distance_to(target) > 0.5:
			var delta: float = get_process_delta_time()
			var move: Vector2 = (target - boss.position).limit_length(BOSS_SPEED * delta)
			boss.position += move
			walked += move.length()
			if figure:
				# walk frames; enemy pictures look left, so a captain walking right is mirrored
				figure.frame = int(walked / BOSS_SPEED * BOSS_WALK_FPS) % 6
				if absf(move.x) > 0.01:
					figure.flip_h = move.x > 0.0
			# heavy steps every half second
			steps += delta
			if steps >= 0.5:
				steps = 0.0
				AudioManager.play_sound("rock_break", 0.4)
				shake(0.15, 1.5)
			await get_tree().process_frame
		if not is_inside_tree():
			return
		boss.position = target
	_walking.erase(side)
	if figure:
		figure.texture = stand
		figure.hframes = stand_frames
		figure.frame = 0
		figure.flip_h = false
	fx.spawn("area_quake", boss.to_global(_talk_offset(boss)), Color.WHITE)


## Where the figure of a captain stands inside its node (its Talk child), for the dust.
func _talk_offset(boss: Node2D) -> Vector2:
	var talk := boss.get_node_or_null("Talk") as Node2D
	return talk.position if talk else Vector2.ZERO


func _to_tablet() -> void:
	var king := node2d(king_altar)
	var knight := node2d(dark_lake)
	if knight:
		walk_npc(knight, PackedVector2Array([Vector2(knight.global_position.x, _at(GUARD_SPOT).y), _at(GUARD_SPOT)]), 60.0, "down")
	pan_camera(_at(TABLET_SPOT), 2.4)
	if king:
		await walk_npc(king, PackedVector2Array([_at(TABLET_SPOT)]), 45.0, "up")
	if not is_inside_tree():
		return
	fx.spawn("dark_hit", _at(TABLET_SPOT + Vector2(0, -30)), Color.WHITE)
	if king:
		face_npc(king, "down")


## The king lays his hands on the tablet: he faces it and leans against it three times, each push
## sparks dark at the stone, the camera shakes a little and the pillars' beams flicker.
func _king_hands() -> void:
	await pan_camera(_at(TABLET_SPOT), 0.3)  # already there after king_to_tablet (unless skipped)
	var king := node2d(king_tablet)
	if king == null or not is_inside_tree():
		return
	face_npc(king, "up")
	var stand: Vector2 = king.position
	var glow := node2d(elements)
	for i in 3:
		var push := create_tween()
		push.tween_property(king, "position", stand + Vector2(0, -3), 0.12).set_trans(Tween.TRANS_QUAD)
		push.tween_property(king, "position", stand, 0.22).set_trans(Tween.TRANS_SINE)
		fx.spawn("dark_hit", _at(TABLET_SPOT + Vector2(0, -30)), Color.WHITE)
		AudioManager.play_sound("skill_used", 0.3)
		shake(0.15, 1.0 + i)
		if glow:
			var flicker := create_tween()
			flicker.tween_property(glow, "modulate", Color(0.45, 0.4, 0.55), 0.08)
			flicker.tween_property(glow, "modulate", Color.WHITE, 0.2)
		if not await wait(0.45):
			return
	king.position = stand


func _evil() -> void:
	var king := node2d(king_tablet)
	if king == null:
		return
	_shadow = Sprite2D.new()
	_shadow.texture = load(SHADOW)
	_shadow.hframes = SHADOW_FRAMES
	_shadow.z_index = 3
	_shadow.z_as_relative = false
	add_child(_shadow)
	_shadow.global_position = _at(Vector2(0, -320))
	_shadow.scale = Vector2.ONE * 0.6
	AudioManager.play_sound("skill_used", 0.4)
	var dive := create_tween()
	dive.tween_property(_shadow, "global_position", king.global_position + Vector2(0, -60), 0.7).set_trans(Tween.TRANS_SINE)
	dive.tween_property(_shadow, "global_position", king.global_position + Vector2(0, -16), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dive.parallel().tween_property(_shadow, "scale", Vector2.ONE * 0.2, 0.35)
	await dive.finished
	if not is_inside_tree():
		return
	_shadow.queue_free()
	_shadow = null
	fx.spawn("area_shadow", king.global_position, Color.WHITE)
	fx.spawn("dark_hit", king.global_position + Vector2(0, -16), Color.WHITE)
	shake(0.8, 2.0)
	_darken_king(true)


## The possessed king: dark, a curse aura at his feet.
func _darken_king(slowly: bool) -> void:
	var king := node2d(king_tablet)
	if king == null:
		return
	if slowly:
		create_tween().tween_property(king, "modulate", POSSESSED, 0.8)
	else:
		king.modulate = POSSESSED
	fx.add_loop(king, "aura_curse", VIOLET, Vector2(0, -4))


func _hold() -> void:
	var knight := node2d(lake)
	if knight == null:
		return
	await walk_npc(knight, PackedVector2Array([Vector2(_at(HOLD_SPOT).x + 20, knight.global_position.y), _at(HOLD_SPOT)]), 110.0, "up")
	if not is_inside_tree():
		return
	fx.spawn("impact", _at(HOLD_SPOT + Vector2(0, -16)), Color(1.0, 0.85, 0.4))
	AudioManager.play_sound("anvil_good", 0.6)
	var king := node2d(king_tablet)
	for i in 4:
		for who: Node2D in [king, knight]:
			if who:
				var jolt := create_tween()
				jolt.tween_property(who, "position:x", who.position.x + (2.0 if i % 2 == 0 else -2.0), 0.08)
				jolt.tween_property(who, "position:x", who.position.x, 0.08)
		if not await wait(0.2):
			return
