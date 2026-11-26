class_name DefenseGame
extends Node2D
## Forge defense (roguelite): the smithy stands in the middle; a run is an endless chain of waves
## (part 1: 15, 25, 40 rats, boss; part 2 ...), each coming at once from the left and right edge,
## the next `pause` seconds after the last enemy died. It ends when the smithy falls. Holding the
## left mouse button swings the hammer once per interval on the circle around the mouse
## (HammerCursor): every enemy and crystal inside takes damage.
## Between runs the window opens (shop with random crystal offers, lasting upgrades, relics,
## mastery, collection, quests). The bought crystals lie near the smithy when the run starts; the
## hammer breaks them and their units appear (random by rarity, sometimes giant or shiny), guard the
## smithy, fight, level up and stay until they die or the run ends. Enemies fight the units first
## and the smithy only when none is left. Everyone has a body: enemies and units push each other apart
## instead of standing on one spot. A boss (life bar in the HUD) drops a treasure chest with a relic:
## no new enemies come until the hammer breaks it open, then a card shows the relic.
## A unit seen for the first time and an opened chest stop the game (time stands still) until the
## player clicks (PauseCard); not for the auto hammer (simulator).
## Rules and numbers: DefenseRun / defense.json. Esc pauses the game: menu with settings, main menu
## and quit (DefensePauseMenu).
##
## Effects (only pictures, DefenseFx in the world, DefenseScreenFx and DefenseWeather in the HUD):
## hammer blows shake the camera, stop time for a moment (hitstop), throw dust and knock enemies
## back (not bosses); quick hammer kills count a combo; dead enemies burst into splinters
## and their coins fly to the counter; crystals shatter with a light column, their units drop in;
## the smithy smokes more and burns the more it is hurt, a hit makes the screen edges glow red;
## waves get darker towards the boss (night, lights at the smithy and the units), each part has
## its weather; a wave banner flies through, a boss comes with a title card and heavy steps, its
## death slows time and its relic falls in a light column; when the smithy falls time slows, dust
## rises and the picture turns grey before the window opens. Arrows at the screen edge point at
## enemies outside the view. Time effects are left out for the auto hammer (simulator).
##
## Built for many enemies at once (40+): enemies, units and crystals are kept in arrays (no node
## searching each frame), targets are picked a few times per second (`TARGET_INTERVAL`).

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu/main_menu.tscn"
## Our music over the scene's (AudioManager.set_music_override), cleared when the scene goes.
const MUSIC_KEY: String = "defense"
const ENEMY_SCENE: PackedScene = preload("res://scenes/defense/defense_enemy.tscn")
const UNIT_SCENE: PackedScene = preload("res://scenes/defense/defense_unit.tscn")
const CRYSTAL_SCENE: PackedScene = preload("res://scenes/defense/defense_crystal.tscn")
const COIN_ICON: Texture2D = preload("res://assets/ui/icon_coin.png")
## Sheets: res://assets/sprites/enemies/<sprite>_<anim>.png, 6 frames of 48x48, facing left.
const SHEET_PATH: String = "res://assets/sprites/enemies/%s_%s.png"
const SHEET_FRAMES: int = 6
const SHEET_FPS: Dictionary[StringName, float] = {&"walk": 10.0, &"attack": 16.0, &"death": 10.0}
const GRASS_PICTURE: String = "res://assets/sprites/maps/smithy_yard_ground.png"
const GRASS_REGION := Rect2i(0, 0, 480, 140)
## Field size (bigger than any window shows at the camera's zoom).
const FIELD_SIZE := Vector2(2800, 2000)
const CASTLE_REACH: float = 44.0
const CHEST_PICTURE: Texture2D = preload("res://assets/sprites/props/chest.png")
## Hammer hits to break a boss's treasure chest.
const CHEST_HITS: int = 3
const SPAWN_MARGIN: float = 20.0
## Knocked enemies stay this far inside the edge of the view.
const VIEW_INSET: float = 12.0
const BODY_RADIUS: float = 8.0
const CRYSTAL_DISTANCE := Vector2(70.0, 120.0)
## Units guard on a ring this far from the smithy.
const GUARD_RADIUS: float = 72.0
## First sight of a new unit: the camera zooms in this far, for this long.
const REVEAL_ZOOM := Vector2(1.3, 1.3)
const REVEAL_TIME: float = 2.2
const BOLT_SPEED: float = 160.0
const TARGET_INTERVAL: float = 0.2
## Bodies (enemies and units) keep at least this far apart (× their size); closer ones push each
## other away.
const BODY_SPACING: float = 14.0
## Grid cells of the push: big enough for the biggest pair (boss 1.5 × giant 1.35).
const BODY_CELL: float = BODY_SPACING * 1.6
## At most this far per frame, so the pushing looks like making room, not jumping.
const MAX_PUSH: float = 1.5
## Floating texts are drawn this much bigger so they stay readable at the zoomed-out camera.
const FLOAT_SCALE: float = 2.0
## Hammer: a hit stops time this long (real seconds) and shakes the camera; crits more.
const HITSTOP_TIME: float = 0.05
const HITSTOP_SCALE: float = 0.05
const HAMMER_SHAKE: float = 2.5
const CRIT_SHAKE: float = 5.0
## Enemies hit by the hammer slide away from the smithy this fast (px/s).
const HAMMER_KNOCK: float = 150.0
const CRIT_COLOR := Color(1.0, 0.85, 0.2)
## Hammer kills within this many seconds of each other count as one combo (shown from 2).
const COMBO_TIME: float = 1.2
const COMBO_COLD := Color(1.0, 0.9, 0.4)
const COMBO_HOT := Color(1.0, 0.25, 0.15)
const COMBO_HOT_AT: int = 20
## At most this many coins fly to the counter at once (the rest only count).
const MAX_FLYING_COINS: int = 25
const COIN_FLY_TIME: float = 0.55
## Where the smoke leaves the chimney (the smithy picture is centred on its node).
const CHIMNEY := Vector2(-25, -54)
const SMOKE := Color(0.55, 0.52, 0.5, 0.55)
## Night: how the field looks at night amount 1 (defense.json effects.night per wave).
const NIGHT_COLOR := Color(0.35, 0.4, 0.68)
const NIGHT_FADE: float = 1.5
const CASTLE_LIGHT_SCALE: float = 7.0
const UNIT_LIGHT_SCALE: float = 2.2
## Boss: steps shake the ground this often; the camera looks at it this long when it comes.
const BOSS_STEP: float = 0.5
const BOSS_LOOK_TIME: float = 1.0
const BOSS_LOOK_ZOOM := Vector2(0.9, 0.9)
const RELIC_COLOR := Color(0.75, 0.6, 1.0)
## The smithy falls: slow motion and grey picture for this long (real seconds) before the window.
const FALL_TIME: float = 1.4

## not saved on purpose: the run lives only as long as this scene; the meta progress (mastery,
## relics) is saved by DefenseRun itself.
var run: DefenseRun
## sprite name -> its frames (built on first use).
var _frames: Dictionary[String, SpriteFrames] = {}
var _enemy_list: Array[DefenseEnemy] = []
var _unit_list: Array[DefenseUnit] = []
var _crystal_list: Array[DefenseCrystal] = []
## Enemy type ids still to come this wave.
## Counts down to the next tavern crystal (≤ 0 = no tavern).
var _tavern_timer: float = -1.0
var _target_timer: float = 0.0
var _hammer_cooldown: float = 0.0
var _hammer_count: int = 0
var _holding: bool = false
## DEV-ONLY (simulator, tests): the hammer swings by itself, at crystals first, then at the
## thickest crowd near the smithy. Never set in the game.
var auto_hammer: bool = false
## How close to the smithy the auto hammer looks first.
const AUTO_NEAR: float = 220.0
var _fighting: bool = false
var _elite: DefenseEnemy = null
var _camera_tween: Tween = null
## Grid cell -> bodies in it, refilled every frame by _spread_bodies (kept to avoid new dictionaries).
var _cells: Dictionary[Vector2i, Array] = {}
## Living enemies and units of this frame (kept to avoid new arrays).
var _bodies: Array[Node2D] = []
## Time stands still (new unit, opened chest) until the player clicks.
var _frozen: bool = false
var _light: GradientTexture2D = null
## The camera zoom of the field (from the scene), the reveal zooms in and back to it.
var _field_zoom: Vector2 = Vector2.ONE
## sprite name -> its average colour (splinters), built with its frames.
var _colors: Dictionary[String, Color] = {}
var _fx: DefenseFx
var _screen_fx: DefenseScreenFx
var _weather: DefenseWeather
var _night: CanvasModulate
var _castle_light: PointLight2D
var _night_amount: float = 0.0
var _combo: int = 0
var _combo_timer: float = 0.0
var _flying_coins: int = 0
var _smoke_timer: float = 0.0
var _boss_step_timer: float = 0.0
## The smithy is falling (slow motion before the window).
var _falling: bool = false
## Counts time effects: only the newest one sets time back to normal.
var _time_token: int = 0

@onready var _ground: Sprite2D = $Ground
@onready var _castle: Sprite2D = $Castle
@onready var _enemies: Node2D = %Enemies
@onready var _units: Node2D = %Units
@onready var _crystals: Node2D = %Crystals
@onready var _shots: Node2D = $Shots
@onready var _camera: Camera2D = $Camera2D
@onready var _cursor: HammerCursor = $HammerCursor
@onready var _coins_label: Label = %CoinsLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _castle_bar: ProgressBar = %CastleBar
@onready var _castle_label: Label = %CastleLabel
@onready var _elite_panel: Control = %ElitePanel
@onready var _elite_label: Label = %EliteLabel
@onready var _elite_bar: ProgressBar = %EliteBar
@onready var _window: DefenseUpgradeWindow = %UpgradeWindow
@onready var _pause_card: DefensePauseCard = %PauseCard
@onready var _pause_menu: DefensePauseMenu = %PauseMenu
@onready var _hud: CanvasLayer = $Hud
@onready var _hud_coin_icon: Control = $Hud/TopBar/Row/CoinIcon


func _ready() -> void:
	# Nothing of the smithy game (day, workshop, autosave) runs here.
	GameState.in_main_menu = true
	_field_zoom = _camera.zoom
	_build_effects()
	run = DefenseRun.new()
	run.save_path = DefenseSaves.path()
	run.load_meta()
	# The save exists from the first second (a new game shows up in "Weiterspielen").
	run.save_meta()
	run.coins_changed.connect(_on_coins_changed)
	run.castle_changed.connect(_on_castle_changed)
	run.quest_completed.connect(_on_quest_completed)
	_window.start_requested.connect(_on_start_requested)
	_pause_menu.closed.connect(_on_pause_closed)
	_pause_menu.main_menu_requested.connect(_to_main_menu)
	_pause_menu.give_up_requested.connect(give_up)
	_ground.texture = _grass_texture()
	_ground.region_rect = Rect2(-FIELD_SIZE / 2.0, FIELD_SIZE)
	_set_ground(run.part_ground())
	_elite_panel.hide()
	_on_coins_changed(run.coins)
	_on_castle_changed(run.castle_hp, run.castle_max_hp())
	run.relic_found.connect(_on_relic_found)
	run.part_beaten.connect(_on_part_beaten)
	_update_wave_label()
	_open_window(-1)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.set_music_override(MUSIC_KEY, "")


func _unhandled_input(event: InputEvent) -> void:
	if _frozen:
		var click := event as InputEventMouseButton
		if (click != null and click.pressed) or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			resume()
			return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_holding = false
		_pause_menu.open(_fighting)
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_holding = event.is_pressed() and _fighting


func _process(delta: float) -> void:
	_update_smithy_fx(delta)
	if not _fighting:
		return
	_combo_timer -= delta
	_update_boss_steps(delta)
	_update_hammer(delta)
	_update_spawning(delta)
	_spread_bodies()
	_target_timer -= delta
	if _target_timer <= 0.0:
		_target_timer = TARGET_INTERVAL
		_pick_targets()
	if _elite != null:
		_elite_bar.value = _elite.hp


## Living enemies, units and unbroken crystals (for tests; don't change the arrays).
func enemies() -> Array[DefenseEnemy]:
	return _enemy_list


func units() -> Array[DefenseUnit]:
	return _unit_list


func crystals() -> Array[DefenseCrystal]:
	return _crystal_list


func is_fighting() -> bool:
	return _fighting


## Pause menu closed: the mouse is the hammer again while fighting.
func _on_pause_closed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if _fighting else Input.MOUSE_MODE_VISIBLE


## "Run aufgeben": the run is lost at once, like when the smithy falls (result, window).
func give_up() -> void:
	if not _fighting:
		return
	if _frozen:
		_frozen = false
		_pause_card.close()
		Engine.time_scale = 1.0
	_castle_fell()


## "Zum Hauptmenü": the run is lost, everything lasting is saved already.
func _to_main_menu() -> void:
	Engine.time_scale = 1.0
	MainMenu.skip_title_page = true
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)


## Time stands still (a new unit or an opened chest is shown) until `resume`.
func is_frozen() -> bool:
	return _frozen


## A boss's treasure chest lies on the field (no new enemies until it is open).
func has_chest() -> bool:
	return _crystal_list.any(func(c: DefenseCrystal) -> bool: return not c.relic_id.is_empty())


## The world effects and the screen effects (for tests).
func effects() -> DefenseFx:
	return _fx


func screen_effects() -> DefenseScreenFx:
	return _screen_fx


# --- Run flow --------------------------------------------------------------------

## Between runs: the window (shop, upgrades, relics, mastery, collection, quests).
## `gained` = mastery of the run that just ended, -1 = no run yet.
func _open_window(gained: int) -> void:
	_set_fighting(false)
	_set_night(0.0)
	# Between runs: ground and music of the part the next run starts in.
	_set_ground(run.part_ground_at(run.start_part()))
	_update_music()
	_window.open_lobby(run, gained)


## "Run starten": full smithy, the bought crystals lie near it, wave 1 comes at once.
func _on_start_requested() -> void:
	run.start_run()
	_castle.modulate = Color.WHITE
	_hammer_cooldown = 0.0
	_tavern_timer = run.tavern_interval()
	for id: String in run.take_crystal_stock():
		_place_crystal(id)
	_set_fighting(true)
	_start_wave()


## The whole wave comes at once, from all around the edge.
func _start_wave() -> void:
	var wave_enemies: Array[String] = run.next_wave()
	for i in wave_enemies.size():
		_spawn_enemy(wave_enemies[i])
	_update_wave_label()
	_update_music()
	if run.wave_in_part().x == 1:
		_set_ground(run.part_ground())
		_float_text(_castle.position + Vector2(0, -90), run.part_name(), Color(1, 0.86, 0.55))
	_screen_fx.banner(_wave_label.text, Color(1, 0.86, 0.55))
	_set_night(run.night_amount())


## The next wave comes at once when this one is (nearly) beaten: only `early_next` enemies left
## and none of them a boss.
func _update_spawning(delta: float) -> void:
	if _enemy_list.size() <= run.early_next() and _elite == null and not has_chest():
		run.wave_cleared()
		_float_text(_castle.position + Vector2(0, -60), Language.translate("Welle geschafft!"), Color(1, 0.86, 0.55))
		_start_wave()
	if _tavern_timer > 0.0:
		_tavern_timer -= delta
		if _tavern_timer <= 0.0:
			_tavern_timer = run.tavern_interval()
			_place_crystal(run.random_crystal())


func _update_wave_label() -> void:
	var at: Vector2i = run.wave_in_part()
	_wave_label.text = run.part_name() + "  ·  " + Language.translate("Welle %s/%s") % [
			DamageKinds.format_number(at.x), DamageKinds.format_number(at.y)]


# --- Enemies -----------------------------------------------------------------------

func _spawn_enemy(type_id: String) -> void:
	var stats: Dictionary = run.enemy_stats(type_id, run.roll_shiny_enemy())
	if stats.is_empty():
		return
	var enemy: DefenseEnemy = ENEMY_SCENE.instantiate()
	enemy.setup(_frames_for(String(stats.get("sprite", "rat"))), stats, _castle.position, CASTLE_REACH)
	enemy.position = _edge_point()
	enemy.field = _view_rect()
	enemy.attacked.connect(_on_enemy_attacked)
	enemy.died.connect(_on_enemy_died)
	_enemies.add_child(enemy)
	_enemy_list.append(enemy)
	if enemy.elite:
		_elite = enemy
		_elite_label.text = Language.translate(String(stats.get("name", type_id)))
		_elite_bar.max_value = enemy.max_hp
		_elite_bar.value = enemy.hp
		_elite_panel.show()
		_boss_entrance(enemy)


## What the camera shows of the field (at the field zoom), a little inside the edge: the hammer
## never knocks an enemy out of it.
func _view_rect() -> Rect2:
	var half: Vector2 = get_viewport_rect().size / (2.0 * _field_zoom) - Vector2(VIEW_INSET, VIEW_INSET)
	return Rect2(-half, half * 2.0)


## A random point just outside the edge of what the camera shows, all around (top, bottom, left,
## right; any window size and zoom), each edge as often as its length.
func _edge_point() -> Vector2:
	var half: Vector2 = get_viewport_rect().size / (2.0 * _field_zoom) + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var out: float = randf_range(0.0, 40.0)
	if randf() < half.x / (half.x + half.y):
		return Vector2(randf_range(-half.x, half.x), (half.y + out) * (1.0 if randf() < 0.5 else -1.0))
	return Vector2((half.x + out) * (1.0 if randf() < 0.5 else -1.0), randf_range(-half.y, half.y))


func _on_enemy_attacked(enemy: DefenseEnemy) -> void:
	if run.is_castle_down():
		return
	_castle.modulate = Color(1.0, 0.5, 0.5)
	create_tween().tween_property(_castle, "modulate", Color.WHITE, 0.2)
	_screen_fx.vignette(Color(1.0, 0.1, 0.05), 0.7, 0.45)
	_fx.shake(1.5, 0.15)
	if run.damage_castle(enemy.damage):
		_castle_fell()


func _on_enemy_died(enemy: DefenseEnemy) -> void:
	_enemy_list.erase(enemy)
	if _falling:
		# The run is already over (slow motion of the fall): nothing counts any more.
		return
	var boss: bool = enemy == _elite
	_fx.splinters(enemy.global_position, CRIT_COLOR if bool(enemy.stats.get("shiny", false))
			else _colors.get(String(enemy.stats.get("sprite", "")), Color(0.7, 0.6, 0.5)), enemy.elite)
	run.enemy_killed(enemy.stats)
	_drop_coin(enemy.global_position, int(enemy.stats.get("coins", 1)))
	if boss:
		_elite = null
		_elite_panel.hide()
		_update_music()
		_boss_died(enemy)


## A coin jumps out of the enemy and flies in an arc to the coin counter in the HUD, which pops.
func _drop_coin(at: Vector2, amount: int) -> void:
	if _flying_coins < MAX_FLYING_COINS:
		_flying_coins += 1
		var coin := Sprite2D.new()
		coin.texture = COIN_ICON
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hud.add_child(coin)
		var from: Vector2 = get_viewport().get_canvas_transform() * (at + Vector2(0, -10))
		var to: Vector2 = _hud_coin_icon.get_global_rect().get_center()
		var top: Vector2 = Vector2(lerpf(from.x, to.x, 0.3), minf(from.y, to.y) - 40.0)
		coin.position = from
		var fly := create_tween()
		fly.tween_method(func(t: float) -> void: coin.position = from.lerp(top, t).lerp(top.lerp(to, t), t), 0.0, 1.0, COIN_FLY_TIME) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		fly.tween_callback(coin.queue_free)
		fly.tween_callback(_on_coin_arrived)
	if amount > 1:
		_float_text(at + Vector2(0, -24), "+" + DamageKinds.format_number(amount), Color(1, 0.86, 0.35))
	AudioManager.play_sound("coins")


## The run is over: slow motion, the smithy collapses in dust, the picture turns grey; then
## everything on the field goes, the mastery is added, the lobby opens.
func _castle_fell() -> void:
	if _falling:
		return
	if _elite != null and _elite.is_alive():
		run.note_boss(String(_elite.stats.get("name", "")), float(_elite.hp) / float(_elite.max_hp))
	_set_fighting(false)
	if auto_hammer:
		_finish_fall()
		return
	_falling = true
	_time_warp(0.35, FALL_TIME)
	_fx.shake(6.0, 1.0)
	for i in 5:
		_fx.dust(_castle.position + Vector2(randf_range(-45.0, 45.0), randf_range(0.0, 35.0)), 30.0, 12)
	_fx.burst(_castle.position + Vector2(0, -20), SMOKE, 30, 90.0, 1.6, 7.0, -30.0, 20.0)
	_castle.modulate = Color(0.45, 0.45, 0.45)
	_screen_fx.gray(1.0, FALL_TIME * 0.7)
	AudioManager.play_sound("rock_break")
	var wait := create_tween().set_ignore_time_scale(true)
	wait.tween_interval(FALL_TIME)
	wait.tween_callback(_finish_fall)


func _finish_fall() -> void:
	_falling = false
	_frozen = false
	_pause_card.close()
	_time_token += 1
	Engine.time_scale = 1.0
	_screen_fx.gray(0.0, 0.4)
	for holder: Node in [_enemies, _units, _crystals, _shots]:
		for child in holder.get_children():
			child.queue_free()
	_enemy_list.clear()
	_unit_list.clear()
	_crystal_list.clear()
	_tavern_timer = -1.0
	_elite = null
	_elite_panel.hide()
	_castle.modulate = Color(0.45, 0.45, 0.45)
	_open_window(run.end_run())


# --- Crystals and units ------------------------------------------------------------

func _place_crystal(id: String) -> void:
	var crystal: DefenseCrystal = CRYSTAL_SCENE.instantiate()
	var item: ItemData = ContentDB.item(id)
	crystal.setup(id, item.icon if item else null, run.crystal_hits(id), run.crystal_color(id), _light_texture())
	crystal.position = _castle.position + Vector2.from_angle(randf() * TAU) * randf_range(CRYSTAL_DISTANCE.x, CRYSTAL_DISTANCE.y)
	crystal.broken.connect(_on_crystal_broken)
	_crystals.add_child(crystal)
	_crystal_list.append(crystal)


## The crystal breaks: shards fly, a column of light rises, its units drop in at its place and go
## to their posts around the smithy.
func _on_crystal_broken(crystal: DefenseCrystal) -> void:
	_crystal_list.erase(crystal)
	if not crystal.relic_id.is_empty():
		_open_chest(crystal)
		return
	var center: Vector2 = crystal.position + DefenseCrystal.CENTER
	_fx.burst(center, crystal.color, 18, 150.0, 0.7, 3.0, 320.0, 60.0)
	_fx.burst(center, Color.WHITE, 6, 100.0, 0.5, 2.0, 200.0, 40.0)
	_fx.beam(crystal.position, crystal.color, 260.0, 0.9, 26.0)
	_fx.ring(center, 40.0, crystal.color, 0.4, 3.0)
	_fx.shake(2.0, 0.2)
	AudioManager.play_sound("rock_break")
	var count: int = run.roll_unit_count(crystal.crystal_id)
	var direction: float = (crystal.position - _castle.position).angle()
	for i in count:
		var spread: float = (float(i) - float(count - 1) / 2.0) * 0.35
		var post: Vector2 = _castle.position + Vector2.from_angle(direction + spread) * GUARD_RADIUS * randf_range(0.85, 1.25)
		var unit: DefenseUnit = summon_unit(run.roll_unit(crystal.crystal_id), run.roll_rarity(), crystal.position, post)
		if unit != null:
			_drop_unit(unit)
	run.crystal_opened()
	AudioManager.play_sound("level_up")


## A unit appears at `at` and guards `post` (crystals; tests). Giant/shiny by chance.
## Returns it (null for an unknown id).
func summon_unit(unit_id: String, rarity: String, at: Vector2, post: Vector2) -> DefenseUnit:
	var stats: Dictionary = run.unit_stats(unit_id, rarity, run.roll_giant(), run.roll_shiny_unit())
	if stats.is_empty():
		return null
	var unit: DefenseUnit = UNIT_SCENE.instantiate()
	unit.setup(_frames_for(String(stats.get("sprite", "fire_salamander"))), stats, post)
	unit.level_kills = run.level_kills()
	unit.level_factor = run.level_factor()
	unit.max_level = run.max_level()
	unit.element = run.unit_element(unit_id)
	unit.rarity_rank = run.rarity_rank(rarity)
	unit.position = at + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
	unit.shot.connect(_on_unit_shot)
	unit.died.connect(_on_unit_died)
	unit.leveled_up.connect(_on_unit_leveled_up)
	unit.skill_ready.connect(_on_unit_skill)
	_units.add_child(unit)
	_unit_list.append(unit)
	_add_unit_light(unit)
	if run.unit_summoned(unit_id, rarity):
		_reveal_unit(unit)
	else:
		_announce_unit(unit)
	return unit


## A unit's skill is ready: fireball at the farthest enemy in range, quake around itself, lightning
## on a random enemy in range. Nothing to hit: it asks again in half a second.
func _on_unit_skill(unit: DefenseUnit) -> void:
	var skill: Dictionary = unit.skill()
	var radius: float = float(skill.get("radius", 30.0)) * unit.scale.x
	var reach_sq: float = pow(float(skill.get("range", 260.0)), 2.0)
	var tint: Color = Color.from_string(String(skill.get("color", "#ffffff")), Color.WHITE)
	var in_range: Array[DefenseEnemy] = []
	for enemy: DefenseEnemy in _enemy_list:
		if enemy.is_visible_to_units() and unit.global_position.distance_squared_to(enemy.global_position) <= reach_sq:
			in_range.append(enemy)
	match String(skill.get("type", "")):
		"fireball":
			if in_range.is_empty():
				unit.delay_skill(0.5)
				return
			var farthest: DefenseEnemy = in_range[0]
			for enemy: DefenseEnemy in in_range:
				if unit.global_position.distance_squared_to(enemy.global_position) > unit.global_position.distance_squared_to(farthest.global_position):
					farthest = enemy
			var ball := DefenseWindBall.new()
			ball.launch(unit, farthest, BOLT_SPEED)
			ball.fx = _fx
			ball.make_skill(radius, tint, unit.skill_damage(), String(skill.get("name", "")))
			ball.landed.connect(_on_skill_ball_landed)
			_shots.add_child(ball)
		"quake":
			var near: bool = in_range.any(func(e: DefenseEnemy) -> bool: return e.global_position.distance_to(unit.global_position) <= radius)
			if not near:
				unit.delay_skill(0.5)
				return
			_area_hit(unit.global_position, radius, unit.skill_damage(), tint, unit)
			_fx.dust(unit.global_position, radius, 14)
			_fx.shake(2.0, 0.2)
		"lightning":
			if in_range.is_empty():
				unit.delay_skill(0.5)
				return
			var struck: DefenseEnemy = in_range[randi() % in_range.size()]
			_lightning_chain(struck.global_position, radius, tint)
			_area_hit(struck.global_position, radius, unit.skill_damage(), tint, unit)
		_:
			unit.delay_skill(5.0)
			return
	unit.use_skill()
	_float_text(unit.global_position + Vector2(0, -50), Language.translate(String(skill.get("name", ""))), tint)


func _on_skill_ball_landed(ball: DefenseWindBall, at: Vector2) -> void:
	_fx.burst(at, ball.color, 14, 110.0, 0.6, 3.0, 150.0, 50.0)
	_area_hit(at, ball.area, ball.damage, ball.color, ball.shooter if is_instance_valid(ball.shooter) else null)


## Every living enemy within `radius` of `at` takes `amount`; kills count for `by` (may be null).
func _area_hit(at: Vector2, radius: float, amount: int, tint: Color, by: DefenseUnit) -> void:
	var blast := DefenseBlast.new()
	_shots.add_child(blast)
	blast.play(at, radius, tint)
	var radius_sq: float = radius * radius
	for enemy: DefenseEnemy in _enemy_list.duplicate():
		if enemy.global_position.distance_squared_to(at) <= radius_sq and enemy.hit(amount) and by != null and by.is_alive():
			by.credit_kill()


## Name of the new unit above it, in its rarity colour; giants and shiny ones say so.
func _announce_unit(unit: DefenseUnit) -> void:
	var text: String = Language.translate(String(unit.stats.get("name", "")))
	if String(unit.stats.get("rarity", "r1")) != "r1":
		text = String(run.rarity_name(String(unit.stats.rarity))) + " " + text
	if bool(unit.stats.get("giant", false)):
		text = Language.translate("Riese") + " " + text
	if bool(unit.stats.get("shiny", false)):
		text = Language.translate("Schimmernd") + " " + text
	_float_text(unit.position + Vector2(0, -40), text, unit.stats.get("rarity_color", Color.WHITE))


func _on_unit_shot(unit: DefenseUnit, enemy: DefenseEnemy) -> void:
	var bolt := DefenseWindBall.new()
	bolt.launch(unit, enemy, BOLT_SPEED)
	bolt.fx = _fx
	_shots.add_child(bolt)


func _on_unit_died(unit: DefenseUnit) -> void:
	_unit_list.erase(unit)


func _on_unit_leveled_up(unit: DefenseUnit) -> void:
	_fx.ring(unit.global_position + Vector2(0, -6), 18.0, CRIT_COLOR, 0.6, 2.0, 30.0)
	_fx.burst(unit.global_position + Vector2(0, -16), CRIT_COLOR, 8, 50.0, 0.6, 2.0, -40.0, 30.0)
	AudioManager.play_sound("rarity_up", 1.3)
	_float_text(unit.global_position + Vector2(0, -44), Language.translate("Stufe %s") % DamageKinds.format_number(unit.level), Color(0.6, 1, 0.5))


## Every enemy and unit has a body: two closer than BODY_SPACING (× the bigger one's size) push
## each other apart a little, so nobody stands on another one; a crowd blocks the way.
## A grid with cells of BODY_CELL: each body only looks at the 9 cells around it.
func _spread_bodies() -> void:
	var view: Rect2 = _view_rect()
	_bodies.clear()
	for enemy: DefenseEnemy in _enemy_list:
		if enemy.is_alive():
			_bodies.append(enemy)
	for unit: DefenseUnit in _unit_list:
		if unit.is_alive():
			_bodies.append(unit)
	_cells.clear()
	for body: Node2D in _bodies:
		var key := Vector2i(floori(body.position.x / BODY_CELL), floori(body.position.y / BODY_CELL))
		if _cells.has(key):
			_cells[key].append(body)
		else:
			_cells[key] = [body]
	for body: Node2D in _bodies:
		var key := Vector2i(floori(body.position.x / BODY_CELL), floori(body.position.y / BODY_CELL))
		var push := Vector2.ZERO
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var near: Variant = _cells.get(key + Vector2i(dx, dy))
				if near == null:
					continue
				for other: Node2D in near:
					if other == body:
						continue
					var away: Vector2 = body.position - other.position
					var distance: float = away.length()
					var needed: float = BODY_SPACING * maxf(body.scale.x, other.scale.x)
					if distance < needed:
						var direction: Vector2 = away / distance if distance > 0.01 else Vector2.from_angle(randf() * TAU)
						push += direction * (needed - distance) * 0.5
		# A boss stands firm (units pushed it out of the picture, where nobody could reach it).
		if body is DefenseEnemy and (body as DefenseEnemy).elite:
			continue
		var moved: Vector2 = body.position + push.limit_length(MAX_PUSH)
		# Who is in the picture stays in it (enemies still coming in from outside are left alone).
		if view.has_point(body.position):
			moved = moved.clamp(view.position, view.end)
		body.position = moved


## Units: each goes for the closest visible enemy anywhere (they always fight while enemies live). Enemies fight the units first: each one (not sneaky) without a living target
## goes for the closest unit anywhere; only when no unit is left do they go for the smithy.
func _pick_targets() -> void:
	if _unit_list.is_empty():
		return
	for unit: DefenseUnit in _unit_list:
		var center: Vector2 = unit.global_position
		var best: DefenseEnemy = null
		var best_sq: float = INF
		for enemy: DefenseEnemy in _enemy_list:
			if not enemy.is_visible_to_units():
				continue
			var distance_sq: float = center.distance_squared_to(enemy.global_position)
			if distance_sq <= best_sq:
				best = enemy
				best_sq = distance_sq
		unit.target = best
	for enemy: DefenseEnemy in _enemy_list:
		if enemy.sneaky or (enemy.target_unit != null and enemy.target_unit.is_alive()):
			continue
		var closest: DefenseUnit = null
		var closest_sq: float = INF
		for unit: DefenseUnit in _unit_list:
			var distance_sq: float = enemy.global_position.distance_squared_to(unit.global_position)
			if distance_sq <= closest_sq:
				closest = unit
				closest_sq = distance_sq
		enemy.target_unit = closest


# --- Hammer ------------------------------------------------------------------------

func _update_hammer(delta: float) -> void:
	var interval: float = run.hammer_interval()
	_cursor.radius = run.hammer_radius()
	_hammer_cooldown = maxf(_hammer_cooldown - delta, 0.0)
	_cursor.ready_part = 1.0 - _hammer_cooldown / interval
	if _hammer_cooldown > 0.0:
		return
	if _holding:
		_hammer_cooldown = interval
		_strike(_cursor.global_position)
	elif auto_hammer:
		var aim: Variant = _auto_aim()
		if aim != null:
			_hammer_cooldown = interval
			_strike(aim)


## DEV-ONLY: where the auto hammer strikes: a crystal, else the enemy with the most others in
## the circle (near the smithy first), null = nothing to hit.
func _auto_aim() -> Variant:
	if not _crystal_list.is_empty():
		return _crystal_list[0].global_position
	var best: Variant = null
	var best_score: int = -1
	var reach_sq: float = pow(_cursor.radius + BODY_RADIUS, 2.0)
	for enemy: DefenseEnemy in _enemy_list:
		var near: bool = enemy.global_position.length() < AUTO_NEAR
		var score: int = 1000 if near else 0
		for other: DefenseEnemy in _enemy_list:
			if other.global_position.distance_squared_to(enemy.global_position) <= reach_sq:
				score += 1
		if score > best_score:
			best_score = score
			best = enemy.global_position
	return best


## One blow on the circle at `at`: every living enemy and every crystal inside takes the hammer's
## damage; every third blow more with the thunder relic (a crit: more shake, longer hitstop).
## Looks: dust ring, enemies knocked back (not bosses), shake and a short hitstop, combo. No damage
## numbers (2026-11-25, player wish: they only cluttered the field).
func _strike(at: Vector2) -> void:
	_cursor.strike()
	_hammer_count += 1
	var damage: int = run.hammer_damage()
	var crit: bool = false
	if _hammer_count % 3 == 0:
		damage = int(round(float(damage) * run.hammer_third_factor()))
		crit = run.hammer_third_factor() > 1.0
	var reach_sq: float = pow(_cursor.radius + BODY_RADIUS, 2.0)
	var hit_any: bool = false
	var hit_boss: bool = false
	var kills: int = 0
	# Copies: a hit can remove the enemy/crystal from its list.
	for enemy: DefenseEnemy in _enemy_list.duplicate():
		if enemy.global_position.distance_squared_to(at) <= reach_sq * enemy.scale.x:
			enemy.reveal()
			enemy.knock(enemy.global_position - _castle.position, HAMMER_KNOCK)
			hit_boss = hit_boss or enemy.elite
			if enemy.hit(damage):
				kills += 1
			hit_any = true
	for crystal: DefenseCrystal in _crystal_list.duplicate():
		if crystal.global_position.distance_squared_to(at) <= reach_sq:
			crystal.hit(1)
			_fx.burst(crystal.position + DefenseCrystal.CENTER, crystal.color, 5, 70.0, 0.4, 2.0, 200.0, 30.0)
			hit_any = true
	_fx.dust(at, _cursor.radius, 8)
	_fx.ring(at, _cursor.radius + 6.0, Color(DefenseFx.DUST, 0.8), 0.3, 2.0)
	if hit_any:
		_fx.shake(CRIT_SHAKE if crit or hit_boss else HAMMER_SHAKE, 0.18)
		if Engine.time_scale >= 1.0:
			_time_warp(HITSTOP_SCALE, HITSTOP_TIME * (2.0 if crit else 1.0))
	_count_combo(kills)
	AudioManager.play_sound("anvil_good" if hit_any else "anvil_miss")


## Hammer kills close after each other add up; from 2 on "×N!" jumps up at the hammer, warmer
## the higher it goes.
func _count_combo(kills: int) -> void:
	if kills <= 0:
		return
	_combo = _combo + kills if _combo_timer > 0.0 else kills
	_combo_timer = COMBO_TIME
	if _combo >= 2:
		var heat: float = clampf(float(_combo) / COMBO_HOT_AT, 0.0, 1.0)
		_fx.number(_cursor.global_position + Vector2(0, -_cursor.radius - 34.0), "×" + DamageKinds.format_number(_combo) + "!",
				COMBO_COLD.lerp(COMBO_HOT, heat), true)


## Fighting: the mouse is the hammer circle. In the window: the normal mouse pointer.
func _set_fighting(fighting: bool) -> void:
	_fighting = fighting
	_holding = false
	_cursor.visible = fighting
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if fighting else Input.MOUSE_MODE_VISIBLE


# --- HUD ---------------------------------------------------------------------------

func _on_coins_changed(coins: int) -> void:
	_coins_label.text = DamageKinds.format_number(coins)


## A flying coin reached the counter: it pops.
func _on_coin_arrived() -> void:
	_flying_coins -= 1
	_coins_label.pivot_offset = _coins_label.size / 2.0
	_coins_label.scale = Vector2(1.45, 1.45)
	create_tween().tween_property(_coins_label, "scale", Vector2.ONE, 0.15)


func _on_castle_changed(hp: int, max_hp: int) -> void:
	_castle_bar.max_value = max_hp
	_castle_bar.value = hp
	_castle_label.text = "%s/%s" % [DamageKinds.format_number(hp), DamageKinds.format_number(max_hp)]


## A short text that rises and fades at a place in the world.
func _float_text(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.scale = Vector2(FLOAT_SCALE, FLOAT_SCALE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 20
	_shots.add_child(label)
	label.position = at - Vector2(label.get_minimum_size().x * FLOAT_SCALE / 2.0, 0)
	var rise := create_tween()
	rise.tween_property(label, "position:y", label.position.y - 30.0, 1.2)
	rise.parallel().tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.5)
	rise.tween_callback(label.queue_free)


## A unit seen for the first time: the camera zooms in on it, a bright light flares up, the unit
## glows and its numbers (life, damage, attack speed, walking speed) stand above it for a while.
func _reveal_unit(unit: DefenseUnit) -> void:
	var at: Vector2 = unit.position
	var light := Sprite2D.new()
	light.texture = _light_texture()
	light.position = at + Vector2(0, -16)
	light.scale = Vector2(0.2, 0.2)
	light.z_index = 15
	_shots.add_child(light)
	var flare := create_tween()
	flare.tween_property(light, "scale", Vector2(2.5, 2.5), 0.35).set_ease(Tween.EASE_OUT)
	flare.tween_property(light, "modulate:a", 0.0, 0.6)
	flare.tween_callback(light.queue_free)
	unit.modulate = Color(4, 4, 4)
	create_tween().tween_property(unit, "modulate", Color.WHITE, 0.9)
	if _camera_tween:
		_camera_tween.kill()
	# Ignores the stopped time: the camera moves in while the game stands still.
	_camera_tween = create_tween().set_ignore_time_scale(true)
	_camera_tween.tween_property(_camera, "position", at * 0.7, 0.35).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel().tween_property(_camera, "zoom", REVEAL_ZOOM, 0.35).set_trans(Tween.TRANS_SINE)
	_show_stats(unit)
	AudioManager.play_sound("level_up")
	if auto_hammer:
		# Simulator: no stop, the camera goes back by itself.
		_camera_tween.tween_interval(REVEAL_TIME)
		_camera_back()
		return
	_freeze()
	_pause_card.show_hint()


## The unit's numbers in a small dark box above it (follows it, fades after a while).
func _show_stats(unit: DefenseUnit) -> void:
	var stats: Dictionary = unit.stats
	var label := Label.new()
	label.text = "\n".join([
			Language.translate("Neu:") + " " + Language.translate(String(stats.get("name", ""))) + "  " + run.rarity_name(String(stats.get("rarity", "r1"))),
			Language.translate("Leben %s  Schaden %s") % [DamageKinds.format_number(int(stats.hp)), DamageKinds.format_number(int(stats.damage))],
			Language.translate("Angriff alle %s s  Tempo %s") % [String.num(float(stats.attack_interval), 2), DamageKinds.format_number(int(stats.get("speed", 0)))]]
			+ ([Language.translate("Fähigkeit: %s") % Language.translate(String(stats.skill.get("name", "")))] if stats.has("skill") else []))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = stats.get("rarity_color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.06, 0.05, 0.85)
	box.set_content_margin_all(3)
	label.add_theme_stylebox_override("normal", box)
	label.z_index = 20
	unit.add_child(label)
	label.position = Vector2(-label.get_minimum_size().x / 2.0, -48.0 - label.get_minimum_size().y)
	var fade := create_tween()
	fade.tween_interval(REVEAL_TIME + 1.5)
	fade.tween_property(label, "modulate:a", 0.0, 0.6)
	fade.tween_callback(label.queue_free)


## A soft round light (white in the middle, clear at the edge), built once.
func _light_texture() -> Texture2D:
	if _light == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 0.9, 1))
		gradient.set_color(1, Color(1, 1, 0.8, 0))
		_light = GradientTexture2D.new()
		_light.gradient = gradient
		_light.fill = GradientTexture2D.FILL_RADIAL
		_light.fill_from = Vector2(0.5, 0.5)
		_light.fill_to = Vector2(0.5, 0.0)
		_light.width = 64
		_light.height = 64
	return _light


## A part's boss fell for the first time: new crystals and upgrades are unlocked.
func _on_part_beaten(index: int) -> void:
	_float_text(_castle.position + Vector2(0, -120), Language.translate("%s besiegt! Neues freigeschaltet.") % run.part_dungeon_name(index),
			Color(0.6, 1, 0.5))


## The field shows the ground picture of the part's region, big enough to fill the view.
func _set_ground(path: String) -> void:
	_weather.set_kind(run.weather_for(path))
	if not ResourceLoader.exists(path):
		return
	var picture: Texture2D = load(path)
	_ground.texture = picture
	_ground.region_enabled = false
	var view: Vector2 = get_viewport_rect().size / _field_zoom + Vector2(SPAWN_MARGIN, SPAWN_MARGIN) * 4.0
	var cover: float = maxf(view.x / float(picture.get_width()), view.y / float(picture.get_height()))
	_ground.scale = Vector2(cover, cover)


## Each part has its own music (parts[].music); while a boss is on the field the boss music; between
## runs the music of the part the next run starts in.
func _update_music() -> void:
	var music: String
	if not _fighting:
		music = run.part_music(run.start_part())
	elif _elite != null or (run.is_boss_wave() and _enemy_list.any(func(e: DefenseEnemy) -> bool: return e.elite)):
		music = run.boss_music()
	else:
		music = run.part_music(run.wave_place().x)
	AudioManager.set_music_override(MUSIC_KEY, music)


## A boss dropped a relic (already owned, DefenseRun.grant_relic): a treasure chest falls in a light
## column somewhere near the smithy. No new enemies come until the hammer breaks it open.
func _on_relic_found(id: String) -> void:
	# Near the smithy, somewhere random like a crystal: never out of the picture where the boss fell.
	_drop_chest(id, _castle.position + Vector2.from_angle(randf() * TAU) * randf_range(CRYSTAL_DISTANCE.x, CRYSTAL_DISTANCE.y))
	_float_text(_castle.position + Vector2(0, -100), Language.translate("Eine Schatztruhe! Schlag sie auf."), RELIC_COLOR)
	AudioManager.play_sound("level_up")


## A quest is done: its name and reward rise above the smithy.
func _on_quest_completed(quest: Dictionary) -> void:
	var text: String = Language.translate("Auftrag erfüllt:") + " " + Language.translate(String(quest.get("name", "")))
	if int(quest.get("crystal_coins", 0)) > 0:
		text += "  " + Language.translate("+%s Kristallmünzen im Vorrat") % DamageKinds.format_number(int(quest.get("crystal_coins", 0)))
	_float_text(_castle.position + Vector2(0, -80), text, Color(1, 0.7, 0.3))
	AudioManager.play_sound("level_up")


# --- Pictures ----------------------------------------------------------------------

func _frames_for(sprite: String) -> SpriteFrames:
	if _frames.has(sprite):
		return _frames[sprite]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: StringName in SHEET_FPS:
		var sheet: Texture2D = load(SHEET_PATH % [sprite, anim])
		var size := Vector2(sheet.get_width() / SHEET_FRAMES, sheet.get_height())
		frames.add_animation(anim)
		frames.set_animation_loop(anim, anim == &"walk")
		frames.set_animation_speed(anim, SHEET_FPS[anim])
		for i in SHEET_FRAMES:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(size.x * i, 0), size)
			frames.add_frame(anim, frame)
	_frames[sprite] = frames
	_colors[sprite] = _average_color(SHEET_PATH % [sprite, "walk"])
	return frames


## Average colour of the first frame of a sheet (for splinters); brownish if it cannot be read.
func _average_color(path: String) -> Color:
	var fallback := Color(0.7, 0.6, 0.5)
	if not ResourceLoader.exists(path):
		return fallback
	var image: Image = (load(path) as Texture2D).get_image()
	if image == null or image.is_empty():
		return fallback
	if image.is_compressed():
		image.decompress()
	var side: int = mini(image.get_width(), image.get_height())
	var sum := Color(0, 0, 0, 0)
	var count: int = 0
	for y in range(0, side, 3):
		for x in range(0, side, 3):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.5:
				sum += pixel
				count += 1
	return Color(sum.r / count, sum.g / count, sum.b / count) if count > 0 else fallback


func _grass_texture() -> Texture2D:
	var picture: Texture2D = load(GRASS_PICTURE)
	return ImageTexture.create_from_image(picture.get_image().get_region(GRASS_REGION))


# --- Effects -----------------------------------------------------------------------

## The effect nodes: particles in the world, night tint and the smithy's light; weather and
## screen effects in the HUD under its panels and windows.
func _build_effects() -> void:
	_fx = DefenseFx.new()
	_fx.camera = _camera
	add_child(_fx)
	_night = CanvasModulate.new()
	add_child(_night)
	_castle_light = PointLight2D.new()
	_castle_light.texture = _light_texture()
	_castle_light.texture_scale = CASTLE_LIGHT_SCALE
	_castle_light.color = Color(1.0, 0.75, 0.45)
	_castle_light.energy = 0.0
	_castle_light.enabled = false
	_castle.add_child(_castle_light)
	_weather = DefenseWeather.new()
	_hud.add_child(_weather)
	_hud.move_child(_weather, 0)
	_screen_fx = DefenseScreenFx.new()
	_screen_fx.game = self
	_hud.add_child(_screen_fx)
	_hud.move_child(_screen_fx, 1)


## How dark the field is (0 = day, 1 = night): the field tint fades, the smithy and every unit
## carry a warm light at night.
func _set_night(amount: float) -> void:
	_night_amount = amount
	var tint: Color = Color.WHITE.lerp(NIGHT_COLOR, amount)
	create_tween().tween_property(_night, "color", tint, NIGHT_FADE)
	_castle_light.enabled = amount > 0.05
	create_tween().tween_property(_castle_light, "energy", amount * 1.3, NIGHT_FADE)
	for unit: DefenseUnit in _unit_list:
		var light: PointLight2D = unit.get_node_or_null("NightLight")
		if light != null:
			light.enabled = amount > 0.05
			create_tween().tween_property(light, "energy", amount, NIGHT_FADE)


## Night amount of the field now (for tests).
func night_amount() -> float:
	return _night_amount


func _add_unit_light(unit: DefenseUnit) -> void:
	var light := PointLight2D.new()
	light.name = "NightLight"
	light.texture = _light_texture()
	light.texture_scale = UNIT_LIGHT_SCALE
	light.position = Vector2(0, -12)
	light.color = unit.stats.get("rarity_color", Color.WHITE)
	light.energy = _night_amount
	light.enabled = _night_amount > 0.05
	unit.add_child(light)


## Time runs at `scale` for `seconds` real seconds (hitstop, slow motion). Not for the simulator.
func _time_warp(scale: float, seconds: float) -> void:
	if auto_hammer or _frozen:
		return
	_time_token += 1
	var token: int = _time_token
	Engine.time_scale = scale
	var back := create_tween().set_ignore_time_scale(true)
	back.tween_interval(seconds)
	back.tween_callback(func() -> void:
		if token == _time_token:
			Engine.time_scale = 1.0)


## The smithy smokes from its chimney; hurt it smokes more, from half life on it burns.
func _update_smithy_fx(delta: float) -> void:
	_smoke_timer -= delta
	if _smoke_timer > 0.0:
		return
	var hurt: float = 1.0 - float(run.castle_hp) / float(maxi(run.castle_max_hp(), 1)) if _fighting else 0.0
	_smoke_timer = lerpf(0.35, 0.07, hurt)
	var chimney: Vector2 = _castle.position + CHIMNEY
	_fx.particle(chimney + Vector2(randf_range(-2, 2), 0), Vector2(randf_range(-3.0, 3.0) + 6.0, randf_range(-26.0, -18.0)),
			Color(SMOKE, SMOKE.a + hurt * 0.3), 2.2, randf_range(4.0, 6.0) + hurt * 3.0, -3.0)
	if randf() < 0.25:
		_fx.particle(chimney, Vector2(randf_range(-8, 8), -40), Color(1.0, 0.6, 0.2), 0.6, 2.0, 30.0)
	if hurt > 0.5:
		var roof: Vector2 = _castle.position + Vector2(randf_range(-45.0, 45.0), randf_range(-35.0, 5.0))
		_fx.particle(roof, Vector2(randf_range(-6, 6), randf_range(-45, -25)), Color(1.0, randf_range(0.35, 0.8), 0.1), 0.7,
				randf_range(3.0, 5.0), -10.0)
		_fx.particle(roof + Vector2(0, -8), Vector2(randf_range(-4, 4), -20), Color(0.3, 0.28, 0.28, 0.6), 1.6, 6.0, -4.0)


## A unit out of a crystal falls from above; dust where it lands.
func _drop_unit(unit: DefenseUnit) -> void:
	var fall: float = unit.drop_in(48.0)
	var land := create_tween()
	land.tween_interval(fall)
	land.tween_callback(func() -> void:
		if is_instance_valid(unit):
			_fx.dust(unit.global_position, 10.0, 6))


## A lightning skill: a bolt from the sky onto the target, jumping on to up to 3 enemies around.
func _lightning_chain(at: Vector2, radius: float, tint: Color) -> void:
	var points := PackedVector2Array([at + Vector2(randf_range(-20, 20), -170), at + Vector2(0, -14)])
	var radius_sq: float = radius * radius * 4.0
	for enemy: DefenseEnemy in _enemy_list:
		if points.size() >= 5:
			break
		if enemy.is_alive() and enemy.global_position.distance_squared_to(at) <= radius_sq and enemy.global_position.distance_squared_to(at) > 4.0:
			points.append(enemy.global_position + Vector2(0, -14))
	_fx.chain(points, tint)
	_fx.burst(at + Vector2(0, -14), tint, 8, 90.0, 0.3, 2.0, 0.0)
	AudioManager.play_sound("lightning_strike")


## A boss comes: its name slams in, the camera looks at it for a moment, the ground shakes.
func _boss_entrance(boss: DefenseEnemy) -> void:
	_screen_fx.title_card(Language.translate(String(boss.stats.get("name", ""))), run.part_name(), Color(1.0, 0.45, 0.35))
	_fx.shake(4.0, 0.5)
	_boss_step_timer = BOSS_STEP
	if auto_hammer:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(_camera, "position", boss.position * 0.6, 0.4).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel().tween_property(_camera, "zoom", BOSS_LOOK_ZOOM, 0.4).set_trans(Tween.TRANS_SINE)
	_camera_tween.tween_interval(BOSS_LOOK_TIME)
	_camera_tween.tween_property(_camera, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel().tween_property(_camera, "zoom", _field_zoom, 0.5).set_trans(Tween.TRANS_SINE)


## While the boss walks, each step shakes the ground a little and throws dust.
func _update_boss_steps(delta: float) -> void:
	if _elite == null or not _elite.is_alive() or _elite.state != DefenseEnemy.State.WALK:
		return
	_boss_step_timer -= delta
	if _boss_step_timer > 0.0:
		return
	_boss_step_timer = BOSS_STEP
	_fx.shake(1.2, 0.12)
	_fx.dust(_elite.global_position, 10.0 * _elite.scale.x, 4)


## The boss died: slow motion, a white flash, a big burst.
func _boss_died(boss: DefenseEnemy) -> void:
	_screen_fx.flash()
	_fx.shake(7.0, 0.6)
	_fx.burst(boss.global_position + Vector2(0, -20), CRIT_COLOR, 24, 160.0, 0.9, 3.0, 200.0, 60.0)
	_fx.ring(boss.global_position, 70.0, Color.WHITE, 0.5, 3.0)
	_time_warp(0.25, 0.6)


## The chest falls from above into a light column at `at` and bounces; the hammer opens it.
func _drop_chest(relic_id: String, at: Vector2) -> void:
	_fx.beam(at, RELIC_COLOR, 300.0, 1.8, 30.0)
	var chest: DefenseCrystal = CRYSTAL_SCENE.instantiate()
	chest.setup("", CHEST_PICTURE, CHEST_HITS, RELIC_COLOR, _light_texture())
	chest.relic_id = relic_id
	chest.position = at
	chest.broken.connect(_on_crystal_broken)
	_crystals.add_child(chest)
	_crystal_list.append(chest)
	var sprite: Node2D = chest.get_node("Sprite")
	sprite.position.y = -160.0
	var fall := create_tween()
	fall.tween_property(sprite, "position:y", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_callback(func() -> void:
		_fx.ring(at, 26.0, RELIC_COLOR, 0.5, 2.0)
		_fx.dust(at, 14.0, 8))


## The chest breaks open: light and sparks, then time stands still and the card shows the relic
## (picture, name, tier, what it does, where it went) until the player clicks.
func _open_chest(chest: DefenseCrystal) -> void:
	var at: Vector2 = chest.position + DefenseCrystal.CENTER
	_fx.beam(chest.position, RELIC_COLOR, 300.0, 1.2, 30.0)
	_fx.burst(at, RELIC_COLOR, 20, 140.0, 0.8, 3.0, 220.0, 60.0)
	_fx.burst(at, CRIT_COLOR, 10, 90.0, 0.6, 2.0, 150.0, 40.0)
	_fx.ring(at, 40.0, RELIC_COLOR, 0.4, 3.0)
	_fx.shake(3.0, 0.25)
	AudioManager.play_sound("achievement")
	var entry: Dictionary = run.relic(chest.relic_id)
	var relic_name: String = Language.translate(String(entry.get("name", chest.relic_id)))
	_float_text(_castle.position + Vector2(0, -100), Language.translate("Relikt gefunden:") + " " + relic_name, RELIC_COLOR)
	if auto_hammer:
		return
	var path: String = String(entry.get("icon", ""))
	var where: String = Language.translate("Eingesetzt: wirkt ab sofort.") if run.is_relic_equipped(chest.relic_id) \
			else Language.translate("Alle Plätze belegt: im Tab Relikte einsetzen.")
	_pause_card.show_relic(load(path) if ResourceLoader.exists(path) else null, relic_name, run.relic_tier(chest.relic_id),
			Language.translate(String(entry.get("description", ""))), where)
	_freeze()


## Time stands still (Engine.time_scale 0) until `resume`; the hammer stops swinging.
func _freeze() -> void:
	_frozen = true
	_holding = false
	_time_token += 1
	Engine.time_scale = 0.0


## The click after a new unit or a chest: time runs again, the card goes, the camera goes back.
func resume() -> void:
	if not _frozen:
		return
	_frozen = false
	_time_token += 1
	Engine.time_scale = 1.0
	_pause_card.close()
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_ignore_time_scale(true)
	_camera_back()


## Appends the way back to the field (position and zoom of the field) to the camera tween.
func _camera_back() -> void:
	_camera_tween.tween_property(_camera, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel().tween_property(_camera, "zoom", _field_zoom, 0.5).set_trans(Tween.TRANS_SINE)
