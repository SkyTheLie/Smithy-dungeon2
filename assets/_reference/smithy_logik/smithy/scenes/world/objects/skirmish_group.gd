class_name SkirmishGroup
extends StaticBody2D
## A small fight in the world that never ends (background battle): `soldiers` (PixelLab resident
## sheets, on the left, looking right) against `foes` (enemy battle sprites, on the right, looking
## left), e.g. 1 against 1, 1 against 2 or 3 against 4. Every fighter acts on its own: a soldier
## lunges at a foe and slashes, a foe plays its attack at a soldier, who parries; now and then the
## whole group shuffles a step. Like SkirmishPair, but for groups. With `march_in` a cut scene lets
## the fighters walk in from somewhere else first (they fight once they are there).

## Sheets in assets/sprites/residents/ of the soldiers (one fighter each, top to bottom).
@export var soldiers: PackedStringArray = ["leon_soldier_a"]
## Enemy ids of the foes: assets/sprites/enemies/<foe>.png (standing), <foe>_walk.png and
## <foe>_attack.png (6 frames each, looking left).
@export var foes: PackedStringArray = ["dark_knight"]
## Shown from this story flag on (empty = always). Not there yet: hidden and quiet.
@export var required_flag: String = ""
## Gone (freed) once this story flag is set.
@export var hidden_when_flag: String = ""
## Distance between the two lines (pixels).
@export var gap: float = 28.0
## Distance between two fighters of one line (pixels).
@export var row: float = 14.0
## Higher = faster fight.
@export var pace: float = 1.0

const ENEMY_DIR: String = "res://assets/sprites/enemies/"
const FOE_FRAME: int = 48
const FOE_FRAMES: int = 6
const SOLDIER_Y: float = -13.0
const FOE_Y: float = -22.0
const LUNGE: float = 7.0
const RECOIL: float = 3.0
const MAX_DRIFT: float = 10.0
const SHUFFLE_STEP: float = 5.0
const SOUND_CHANCE: float = 0.08
const COLOR_STEEL: Color = Color(1.0, 0.95, 0.8)
const MARCH_SPEED: float = 70.0

## One per fighter: {"sprite": Sprite2D, "home": Vector2, "foe": bool, "stand", "walk", "attack" (foes)}.
var _fighters: Array[Dictionary] = []
var _fx: WorldVfx
var _drift: float = 0.0
## false while marching in (march_in) or hidden: nobody fights.
var _fighting: bool = false


func _ready() -> void:
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag):
		queue_free()
		return
	pace *= randf_range(0.85, 1.2)
	var height: float = maxf(soldiers.size(), foes.size()) * row
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(gap + 16.0, maxf(6.0, height - row + 6.0))
	shape.shape = rect
	add_child(shape)
	_fx = WorldVfx.new()
	add_child(_fx)
	for i in soldiers.size():
		_add_soldier(soldiers[i], Vector2(-gap / 2.0, _line_y(i, soldiers.size())))
	for i in foes.size():
		_add_foe(foes[i], Vector2(gap / 2.0, _line_y(i, foes.size())))
	GameState.story.changed.connect(_update)
	_update()
	if visible:
		_start()


## y of fighter `index` of a line of `count`, the line centred on the group.
func _line_y(index: int, count: int) -> float:
	return (index - (count - 1) / 2.0) * row


func _add_soldier(resident: String, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = CharacterBaker.get_resident_sheet(resident)
	sprite.region_enabled = true
	sprite.region_rect = CharacterBaker.get_frame_rect("right", 0)
	sprite.offset = Vector2(0, SOLDIER_Y)
	sprite.position = at
	add_child(sprite)
	_fighters.append({"sprite": sprite, "home": at, "foe": false})


func _add_foe(foe: String, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.region_enabled = true
	sprite.offset = Vector2(0, FOE_Y)
	sprite.position = at
	add_child(sprite)
	var entry: Dictionary = {"sprite": sprite, "home": at, "foe": true, "stand": load(ENEMY_DIR + foe + ".png"),
			"walk": load(ENEMY_DIR + foe + "_walk.png"), "attack": load(ENEMY_DIR + foe + "_attack.png")}
	_fighters.append(entry)
	_foe_frame(entry, entry["stand"], 0)


func _update() -> void:
	if not is_inside_tree():
		return
	if not hidden_when_flag.is_empty() and GameState.story.has_flag(hidden_when_flag):
		queue_free()
		return
	var shown: bool = required_flag.is_empty() or GameState.story.has_flag(required_flag)
	if shown == visible:
		return
	visible = shown
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not shown)
	if shown and not _fighting:
		_start()


func _start() -> void:
	if _fighting:
		return
	_fighting = true
	for fighter in _fighters:
		_fight(fighter)
	_shuffle_loop()


## The fighters walk to their places, then fight: the foes from `foe_offset` (from their place,
## e.g. from the edge of the map), the soldiers from `soldier_start` (global, e.g. a door; ZERO =
## from foe_offset as well). Awaitable.
func march_in(foe_offset: Vector2, soldier_start: Vector2 = Vector2.ZERO, delay_step: float = 0.15) -> void:
	_fighting = false
	visible = true
	var longest: float = 0.0
	for i in _fighters.size():
		var fighter: Dictionary = _fighters[i]
		var sprite: Sprite2D = fighter["sprite"]
		var jitter := Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		if fighter["foe"] or soldier_start == Vector2.ZERO:
			sprite.position = fighter["home"] + foe_offset + jitter
		else:
			sprite.global_position = soldier_start + jitter
		var seconds: float = sprite.position.distance_to(fighter["home"]) / MARCH_SPEED
		longest = maxf(longest, seconds + delay_step * i)
		_march(fighter, seconds, delay_step * i)
	await get_tree().create_timer(longest + 0.05, false).timeout
	if is_inside_tree():
		_start()


func _march(fighter: Dictionary, seconds: float, delay: float) -> void:
	var sprite: Sprite2D = fighter["sprite"]
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(sprite) or not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(sprite, "position", fighter["home"], seconds)
	var time: float = 0.0
	var direction: Vector2 = (fighter["home"] - sprite.position).normalized()
	# they look where they walk (2026-11-15: soldiers walking left looked right, foes walking right
	# looked left the whole way); at their place soldiers look right and foes left again
	var look: String = walk_look(direction)
	while is_instance_valid(sprite) and is_inside_tree() and tween.is_running():
		time += get_process_delta_time()
		var frame: int = int(time * 10.0) % FOE_FRAMES
		if fighter["foe"]:
			_foe_frame(fighter, fighter["walk"], frame)
			sprite.flip_h = look == "right"  # enemy pictures look left
		else:
			sprite.region_rect = CharacterBaker.get_frame_rect(look, 1 + frame)
		await get_tree().process_frame
	if is_instance_valid(sprite):
		sprite.flip_h = false
		if fighter["foe"]:
			_foe_frame(fighter, fighter["stand"], 0)
		else:
			sprite.region_rect = CharacterBaker.get_frame_rect("right", 0)


## The direction a fighter walking along `direction` looks: the bigger part of the way decides,
## never diagonal.
static func walk_look(direction: Vector2) -> String:
	if absf(direction.y) > absf(direction.x):
		return "up" if direction.y < 0.0 else "down"
	return "left" if direction.x < 0.0 else "right"


func _foe_frame(fighter: Dictionary, sheet: Texture2D, frame: int) -> void:
	var sprite: Sprite2D = fighter["sprite"]
	sprite.texture = sheet
	sprite.region_rect = Rect2(frame * FOE_FRAME if sheet != fighter["stand"] else 0, 0, FOE_FRAME, FOE_FRAME)


func _wait(seconds: float) -> bool:
	if not is_inside_tree():
		return false
	await get_tree().create_timer(seconds / pace, false).timeout
	return is_inside_tree() and _fighting


func _targets(of_foes: bool) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for fighter in _fighters:
		if fighter["foe"] == of_foes:
			found.append(fighter)
	return found


func _fight(fighter: Dictionary) -> void:
	if not await _wait(randf_range(0.0, 1.5)):
		return
	while true:
		var others: Array[Dictionary] = _targets(not fighter["foe"])
		if others.is_empty():
			return
		var target: Dictionary = others.pick_random()
		if fighter["foe"]:
			await _foe_attacks(fighter, target)
		else:
			await _soldier_attacks(fighter, target)
		if not await _wait(randf_range(0.5, 1.6)):
			return


func _soldier_attacks(fighter: Dictionary, target: Dictionary) -> void:
	var sprite: Sprite2D = fighter["sprite"]
	var foe: Sprite2D = target["sprite"]
	if not is_instance_valid(sprite) or not is_instance_valid(foe):
		return
	var home: Vector2 = sprite.position
	var towards: Vector2 = (foe.position - home).normalized() * LUNGE
	sprite.region_rect = CharacterBaker.get_frame_rect("right", 3)
	var tween := create_tween()
	tween.tween_property(sprite, "position", home + towards, 0.12 / pace)
	await tween.finished
	if not is_instance_valid(sprite) or not is_instance_valid(foe):
		return
	_fx.spawn("slash", foe.global_position + Vector2(-4, 4), COLOR_STEEL, 1.0)
	_ring()
	_recoil(foe, RECOIL)
	sprite.region_rect = CharacterBaker.get_frame_rect("right", 5)
	tween = create_tween()
	tween.tween_property(sprite, "position", home, 0.2 / pace)
	await tween.finished
	if is_instance_valid(sprite):
		sprite.region_rect = CharacterBaker.get_frame_rect("right", 0)


func _foe_attacks(fighter: Dictionary, target: Dictionary) -> void:
	var soldier: Sprite2D = target["sprite"]
	for frame in FOE_FRAMES:
		if not is_instance_valid(fighter["sprite"]):
			return
		_foe_frame(fighter, fighter["attack"], frame)
		if frame == 3 and is_instance_valid(soldier):
			_fx.spawn("block", soldier.global_position + Vector2(5, 2), COLOR_STEEL, -1.0)
			_ring()
			_recoil(soldier, -RECOIL)
		if not await _wait(0.09):
			return
	_foe_frame(fighter, fighter["stand"], 0)


## Now and then the whole group steps a little to one side (the fight moves back and forth).
func _shuffle_loop() -> void:
	while await _wait(randf_range(3.0, 6.0)):
		var step: float = SHUFFLE_STEP if randf() < 0.5 else -SHUFFLE_STEP
		if absf(_drift + step) > MAX_DRIFT:
			step = -step
		_drift += step
		for fighter in _fighters:
			fighter["home"] = fighter["home"] + Vector2(step, 0)
			var sprite: Sprite2D = fighter["sprite"]
			if is_instance_valid(sprite):
				create_tween().tween_property(sprite, "position:x", sprite.position.x + step, 0.5 / pace)


func _recoil(sprite: Sprite2D, by: float) -> void:
	var home: float = sprite.position.x
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", home + by, 0.06)
	tween.parallel().tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6), 0.06)
	tween.tween_property(sprite, "position:x", home, 0.15)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _ring() -> void:
	if randf() < SOUND_CHANCE:
		AudioManager.play_sound("anvil_good", randf_range(1.5, 1.9))


## Number of fighters (soldiers + foes), for tests.
func get_fighter_count() -> int:
	return _fighters.size()
