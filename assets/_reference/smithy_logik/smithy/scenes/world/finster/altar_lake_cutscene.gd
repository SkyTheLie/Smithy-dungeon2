class_name AltarLakeCutscene
extends StoryCutscene
## Lake's awakening at the Altar of the Nine (dialogue "lake_awakens"). Each beat is a line with
## "hide_for" (the dialogue box is out of sight while it plays) and "cutscene:<id>":
## - lake_kneel: the dark Lake sinks onto one knee (residents/lake_dark_kneel.png)
## - lake_approach: the player walks up beside him (left)
## - lake_hands: the player's hands glow blue on his armour
## - lake_glow: the glow turns from blue to gold, Lake shines
## - lake_shadow: a shadow with claws tears itself out of his chest (effects/lake_shadow.png)
## - lake_strike: Lake gets up and cuts the shadow in two, it falls apart into ash
## - lake_gold: the black armour flickers to gold (flag lake_redeemed: the light Lake takes over)
## - lake_beside: the light Lake steps beside the player, facing the king

@export var dark_lake: NodePath
@export var lake: NodePath

const KNEEL_DARK: String = "res://assets/sprites/residents/lake_dark_kneel.png"
const SLASH_DARK: String = "res://assets/sprites/residents/lake_dark_slash.png"
const LAKE_LIGHT: String = "res://assets/sprites/residents/lake.png"
const SHADOW: String = "res://assets/sprites/effects/lake_shadow.png"
const KNEEL_FRAMES: int = 5
const CELL: int = 48
const SLASH_CELL: int = 64
const SHADOW_FRAMES: int = 9
const BLUE: Color = Color(0.45, 0.7, 1.0)
const GOLD: Color = Color(1.0, 0.82, 0.35)
## Where the shadow hovers (from Lake's feet), right of him, so his slash to the right hits it.
const SHADOW_SPOT: Vector2 = Vector2(30, -26)

## The glow between the player's hands and Lake's chest (a loop of WorldVfx).
var _glow: Node2D
var _shadow: Sprite2D
var _shadow_time: float = 0.0


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	if _shadow and is_instance_valid(_shadow) and _shadow.visible:
		_shadow_time += delta
		_shadow.frame = int(_shadow_time * 10.0) % SHADOW_FRAMES


func _play_beat(id: String) -> bool:
	match id:
		"lake_kneel":
			_kneel()
		"lake_approach":
			_approach()
		"lake_hands":
			_hands()
		"lake_glow":
			_turn_gold()
		"lake_shadow":
			_tear_shadow()
		"lake_strike":
			_strike()
		"lake_gold":
			_gold()
		"lake_beside":
			_beside()
		_:
			return false
	return true


func _dark() -> Node2D:
	return get_node_or_null(dark_lake) as Node2D


func _figure(npc: Node2D) -> Sprite2D:
	return npc.get_node_or_null("Figure") as Sprite2D if npc else null


## Shows frame `index` of a one-row sheet with cells of `cell` px on the figure of `npc`.
func _show_frame(npc: Node2D, path: String, cell: int, index: int) -> void:
	var figure := _figure(npc)
	if figure == null or not ResourceLoader.exists(path):
		return
	figure.texture = load(path)
	figure.region_enabled = true
	figure.region_rect = Rect2(index * cell, 0, cell, cell)


## Plays frames `from`..`to` of a sheet on `npc` in `seconds`.
func _play(npc: Node2D, path: String, cell: int, from: int, to: int, seconds: float) -> void:
	if npc == null:
		return
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(npc):
			_show_frame(npc, path, cell, int(round(value))),
		float(from), float(to), seconds)
	await tween.finished


func _kneel() -> void:
	await _play(_dark(), KNEEL_DARK, CELL, 0, KNEEL_FRAMES - 1, 1.0)


func _approach() -> void:
	var smith := player()
	var dark := _dark()
	if smith == null or dark == null or not smith.has_method("auto_walk"):
		return
	# beside him on the left (in front of him the player would hide the kneeling Lake)
	var target: Vector2 = dark.global_position + Vector2(-22, 1)
	var speed: float = maxf(70.0, smith.global_position.distance_to(target) / 2.6)
	smith.call("auto_walk", PackedVector2Array([Vector2(target.x, smith.global_position.y), target]), "right", speed)


func _hands() -> void:
	var dark := _dark()
	if dark == null:
		return
	_glow = Node2D.new()
	add_child(_glow)
	_glow.global_position = dark.global_position + Vector2(-9, 0)
	fx.add_loop(_glow, "glow", BLUE, Vector2(0, -12))
	fx.spawn("buff", _glow.global_position + Vector2(0, -10), BLUE)
	AudioManager.play_sound("skill_used", 0.8)


func _turn_gold() -> void:
	if _glow == null:
		_hands()
	var dark := _dark()
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(_glow):
			fx.add_loop(_glow, "glow", BLUE.lerp(GOLD, value), Vector2(0, -12)),
		0.0, 1.0, 1.6)
	if dark:
		var figure := _figure(dark)
		if figure:
			var pulse := create_tween().set_loops(3)
			pulse.tween_property(figure, "modulate", Color(1.4, 1.25, 0.8), 0.25)
			pulse.tween_property(figure, "modulate", Color.WHITE, 0.25)
	fx.spawn("light_hit", (dark.global_position if dark else Vector2.ZERO) + Vector2(0, -16), GOLD)


func _tear_shadow() -> void:
	var dark := _dark()
	if dark == null:
		return
	if _glow:
		fx.remove_loop(_glow)
	_shadow = Sprite2D.new()
	_shadow.texture = load(SHADOW)
	_shadow.hframes = SHADOW_FRAMES
	_shadow.z_index = 2
	_shadow.z_as_relative = false
	add_child(_shadow)
	var chest: Vector2 = dark.global_position + Vector2(0, -18)
	_shadow.global_position = chest
	_shadow.scale = Vector2.ONE * 0.2
	_shadow.modulate.a = 0.0
	fx.spawn("dark_hit", chest, Color.WHITE)
	AudioManager.play_sound("rock_break", 0.6)
	var tween := create_tween().set_parallel()
	tween.tween_property(_shadow, "global_position", dark.global_position + SHADOW_SPOT, 0.9) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_shadow, "scale", Vector2.ONE, 0.9)
	tween.tween_property(_shadow, "modulate:a", 1.0, 0.3)
	shake(0.9)
	# the kneeling Lake rears up while it tears out
	var figure := _figure(dark)
	if figure:
		var jolt := create_tween()
		jolt.tween_property(figure, "position:y", figure.position.y - 3.0, 0.1)
		jolt.tween_property(figure, "position:y", figure.position.y, 0.4)


func _strike() -> void:
	var dark := _dark()
	if dark == null:
		return
	await _play(dark, KNEEL_DARK, CELL, KNEEL_FRAMES - 1, 0, 0.5)
	if not is_instance_valid(dark):
		return
	await _play(dark, SLASH_DARK, SLASH_CELL, 0, 5, 0.45)
	if not is_instance_valid(dark):
		return
	AudioManager.play_sound("anvil_perfect", 0.9)
	if _shadow and is_instance_valid(_shadow):
		fx.spawn("slash", _shadow.global_position, Color.WHITE)
		_split_shadow()
	shake(0.4)
	_show_frame(dark, "res://assets/sprites/residents/lake_dark.png", CELL, 0)
	var figure := _figure(dark)
	if figure:
		figure.region_rect = CharacterBaker.get_frame_rect("right")


## The shadow falls apart in two halves that drift away and fade to ash.
func _split_shadow() -> void:
	var frame_rect := Rect2((_shadow.frame % SHADOW_FRAMES) * 64, 0, 64, 64)
	for side in [-1, 1]:
		var half := Sprite2D.new()
		half.texture = _shadow.texture
		half.region_enabled = true
		half.region_rect = Rect2(frame_rect.position + Vector2(32 if side > 0 else 0, 0), Vector2(32, 64))
		half.z_index = 2
		half.z_as_relative = false
		add_child(half)
		half.global_position = _shadow.global_position + Vector2(16 * side, 0)
		var tween := create_tween().set_parallel()
		tween.tween_property(half, "global_position", half.global_position + Vector2(18 * side, -10), 0.8)
		tween.tween_property(half, "rotation", 0.5 * side, 0.8)
		tween.tween_property(half, "modulate", Color(0.4, 0.4, 0.45, 0.0), 0.8)
		tween.chain().tween_callback(half.queue_free)
	fx.spawn("area_shadow", _shadow.global_position + Vector2(0, 10), Color.WHITE)
	_shadow.queue_free()
	_shadow = null


func _gold() -> void:
	var dark := _dark()
	if dark:
		var figure := _figure(dark)
		# the armour flickers between black and gold, faster and faster
		var waits: Array[float] = [0.3, 0.22, 0.16, 0.12, 0.09, 0.07, 0.06]
		var light: bool = false
		for pause in waits:
			light = not light
			if figure and is_instance_valid(figure):
				figure.texture = load(LAKE_LIGHT if light else "res://assets/sprites/residents/lake_dark.png")
				figure.region_rect = CharacterBaker.get_frame_rect("right")
			fx.spawn("light_hit", dark.global_position + Vector2(randf_range(-6, 6), randf_range(-26, -6)), GOLD)
			await wait(pause)
			if not is_inside_tree() or not is_instance_valid(dark):
				return
	if _glow:
		fx.remove_loop(_glow)
	fx.spawn("area_holy", (dark.global_position if dark else Vector2.ZERO), GOLD)
	AudioManager.play_sound("rarity_up", 0.9)
	GameState.run_story_action("set_flag:lake_redeemed")
	if dark and is_instance_valid(dark) and dark.has_method("_hide_body"):
		dark.call("_hide_body")  # the light Lake (required_flag lake_redeemed) stands in his place
	await get_tree().process_frame
	var light_lake := get_node_or_null(lake) as Node2D
	if light_lake:
		if dark:
			light_lake.global_position = dark.global_position
		light_lake.set("facing", "right")
		light_lake.call("_face", "right")
		fx.add_loop(light_lake, "aura_holy", GOLD, Vector2(0, -12))
		await wait(1.2)
		fx.remove_loop(light_lake)


func _beside() -> void:
	var light_lake := get_node_or_null(lake) as Node2D
	var smith := player()
	if light_lake == null or smith == null:
		return
	var target: Vector2 = smith.global_position + Vector2(24, 0)
	smith.call("auto_walk", PackedVector2Array([smith.global_position]), "up")
	var shape := light_lake.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	while is_inside_tree() and is_instance_valid(light_lake) and light_lake.global_position.distance_to(target) > 1.0:
		light_lake.call("_walk_step", target - light_lake.global_position, 50.0, get_process_delta_time())
		await get_tree().process_frame
	if is_instance_valid(light_lake):
		light_lake.global_position = target
		light_lake.set("facing", "up")
		light_lake.call("_face", "up")
	if smith.has_method("auto_walk"):
		smith.call("auto_walk", PackedVector2Array([smith.global_position]), "up")


