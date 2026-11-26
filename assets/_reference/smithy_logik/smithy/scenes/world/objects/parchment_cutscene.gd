class_name ParchmentCutscene
extends StoryCutscene
## Close-ups of the old map of the nine stones (dialogues "king_treasury" and "crisis_council"):
## - treasury_glow: in the treasury light falls on the parchment, three points glow (brown, light,
##   red: earth, light, fire)
## - pieces_match: the elder lays his piece beside the king's, the edges fit, two points glow
##   (wind in the west, lightning far in the south)
## - blade_thrown: Faelan throws an undead's blade on the ground in front of the player
## - blade_picked: the player picks the blade up and turns it in the light (a glint at the mark)
## The pieces are cut from the painted world map (assets/_reference/story_anims/make_map_pieces.py).

@export var faelan: NodePath
## How long a close-up stays before it fades (the dialogue box shows on top meanwhile).
@export var hold: float = 5.0

const PIECE_1: String = "res://assets/sprites/ui/map_piece_1.png"
const PIECE_2: String = "res://assets/sprites/ui/map_piece_2.png"
## Top-left of piece 2 in the painted map, relative to piece 1 (from make_map_pieces.py).
const PIECE_2_AT: Vector2 = Vector2(172, 53)
## World map coordinates (data/content/world_map.json) to painted map pixels.
const MAP_SCALE: float = 300.0 / 1180.0
const BLADE: String = "res://assets/sprites/items/bronze_blade.png"

var _veil: ColorRect
var _close_up: Node2D
var _glow: WorldVfx
## The blade Faelan threw (blade_thrown), until the player picks it up.
var _thrown_blade: Sprite2D


func _play_beat(id: String) -> bool:
	match id:
		"treasury_glow":
			_treasury()
		"pieces_match":
			_pieces()
		"blade_thrown":
			_blade()
		"blade_picked":
			_pick_blade()
		_:
			return false
	return true


func _crystal(name: String) -> Dictionary:
	for crystal: Dictionary in ContentDB.world_map().get("crystals", []):
		if crystal.get("name", "") == name:
			return crystal
	return {}


## The close-up holder in the middle of the screen, above a dark veil.
func _open_close_up() -> Node2D:
	_close()
	_veil = world_tint(Color(0.05, 0.04, 0.03, 0.0))
	create_tween().tween_property(_veil, "color:a", 0.6, 0.5)
	_close_up = Node2D.new()
	_close_up.z_index = 4
	_close_up.z_as_relative = false
	add_child(_close_up)
	var camera: Camera2D = get_viewport().get_camera_2d()
	_close_up.global_position = (camera.get_screen_center_position() if camera else global_position) + Vector2(0, -20)
	_glow = WorldVfx.new()
	_close_up.add_child(_glow)
	_glow.z_index = 5
	return _close_up


func _piece(path: String, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.position = at
	_close_up.add_child(sprite)
	return sprite


## A glowing point at the world map spot of crystal `name` (`origin` = where the painted map's
## top-left lies in the close-up).
func _dot(name: String, origin: Vector2, delay: float) -> void:
	var crystal: Dictionary = _crystal(name)
	if crystal.is_empty() or not await wait(delay):
		return
	var at: Array = crystal.get("at", [0, 0])
	var spot := Node2D.new()
	_close_up.add_child(spot)
	spot.position = origin + Vector2(float(at[0]), float(at[1])) * MAP_SCALE
	var color := Color(str(crystal.get("color", "#ffffff")))
	_glow.add_loop(spot, "glow", color)
	_glow.spawn("light_hit", spot.global_position, color)
	AudioManager.play_sound("item_reveal", 0.5)


func _treasury() -> void:
	var holder := _open_close_up()
	var size: Vector2 = load(PIECE_1).get_size()
	var origin: Vector2 = -size / 2.0
	var parchment := _piece(PIECE_1, origin)
	parchment.modulate = Color(0.5, 0.5, 0.5, 0.0)
	var light := create_tween()
	light.tween_property(parchment, "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.5)
	light.tween_property(parchment, "modulate", Color.WHITE, 0.6)
	_dot("Erde", origin, 1.1)
	_dot("Licht", origin, 1.5)
	_dot("Feuer", origin, 1.9)
	_fade_later(holder)


func _pieces() -> void:
	var holder := _open_close_up()
	var size: Vector2 = load(PIECE_1).get_size()
	var whole: Vector2 = Vector2(maxf(size.x, PIECE_2_AT.x + load(PIECE_2).get_width()), size.y)
	var origin: Vector2 = -whole / 2.0
	var king := _piece(PIECE_1, origin + Vector2(-30, 0))
	var elder := _piece(PIECE_2, origin + PIECE_2_AT + Vector2(40, 0))
	king.modulate.a = 0.0
	elder.modulate.a = 0.0
	var slide := create_tween().set_parallel()
	slide.tween_property(king, "modulate:a", 1.0, 0.3)
	slide.tween_property(elder, "modulate:a", 1.0, 0.3)
	slide.tween_property(king, "position", origin, 0.9).set_delay(0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	slide.tween_property(elder, "position", origin + PIECE_2_AT, 0.9).set_delay(0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not await wait(1.2):
		return
	AudioManager.play_sound("ui_click", 0.7)
	_glow.spawn("light_hit", holder.global_position + origin + PIECE_2_AT + Vector2(0, 20), Color(1.0, 0.95, 0.7))
	_dot("Wind", origin, 0.3)
	_dot("Blitz", origin, 0.7)
	_fade_later(holder)


func _fade_later(holder: Node2D) -> void:
	if not await wait(hold) or holder != _close_up:
		return
	_close()


func _close() -> void:
	if _close_up and is_instance_valid(_close_up):
		var holder: Node2D = _close_up
		var fade := create_tween()
		fade.tween_property(holder, "modulate:a", 0.0, 0.5)
		fade.tween_callback(holder.queue_free)
	_close_up = null
	if _veil and is_instance_valid(_veil):
		var veil: ColorRect = _veil
		var fade_veil := create_tween()
		fade_veil.tween_property(veil, "color:a", 0.0, 0.5)
		fade_veil.tween_callback(veil.queue_free)
	_veil = null


func _blade() -> void:
	var elf := node2d(faelan)
	var body := player()
	if body == null:
		return
	var ground: Vector2 = body.global_position + Vector2(0, 18)
	var from: Vector2 = (elf.global_position if elf else ground + Vector2(60, -20)) + Vector2(0, -16)
	var blade := Sprite2D.new()
	blade.texture = load(BLADE)
	blade.z_index = 1
	var holder := get_parent() if get_parent() is Node2D and (get_parent() as Node2D).y_sort_enabled else self
	holder.add_child(blade)
	blade.global_position = from
	var arc := create_tween()
	arc.tween_method(func(t: float) -> void:
		if is_instance_valid(blade):
			blade.global_position = from.lerp(ground, t) + Vector2(0, -26.0 * sin(t * PI))
			blade.rotation = t * TAU * 1.5,
		0.0, 1.0, 0.55)
	await arc.finished
	if not is_instance_valid(blade):
		return
	blade.rotation = 0.0
	_thrown_blade = blade
	AudioManager.play_sound("anvil_miss", 0.9)
	fx.spawn("impact", ground, Color.WHITE)


## The player bends down for the blade, lifts it to his face and turns it; a glint at the hilt.
func _pick_blade() -> void:
	var body := player()
	var blade := _thrown_blade
	if body == null or not is_instance_valid(blade):
		return
	var held: Vector2 = body.global_position + Vector2(8, -18)
	var lift := create_tween()
	lift.tween_property(blade, "global_position", held, 0.45).set_trans(Tween.TRANS_SINE)
	lift.parallel().tween_property(blade, "rotation", -0.5, 0.45)
	lift.tween_property(blade, "rotation", 0.4, 0.4)
	await lift.finished
	if not is_instance_valid(blade):
		return
	AudioManager.play_sound("item_reveal", 0.5)
	fx.spawn("light_hit", blade.global_position + Vector2(0, 6), Color(0.65, 0.85, 1.0))
	var away := create_tween()
	away.tween_interval(1.2)
	away.tween_property(blade, "modulate:a", 0.0, 0.3)
	away.tween_callback(blade.queue_free)
