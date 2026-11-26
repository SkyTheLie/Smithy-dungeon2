class_name TempleCrystalCutscene
extends StoryCutscene
## The innermost chamber of the storm temple (dialogues "temple_rod_placed" and "temple_crystal_take"):
## - rod_lightning: all lightning leaps from the crystal into the copper rod and sinks into the
##   ground, the crackling bolts of the crystal flicker and go out
## - crystal_grab: the player steps up to the altar, the crystal sinks into his hands, he lifts it
## - crystal_arc: lightning leaps from the crystal in his hands, the player's hands glow blue
## - crystal_vision: the temple blurs, a tall man at a glowing anvil appears (half transparent),
##   his hands glow in the same blue; "vision_end" lets it fade

@export var crystal: NodePath
@export var rod_stand: NodePath
@export var altar: NodePath
## The crackling bolts of the crystal (CrystalArcs); the rod beat bends them into the rod.
@export var arcs: NodePath
## The crystal floats this high over its node (as the Crystal sprite in the scene).
const CRYSTAL_HEIGHT: float = 118.0

const BLUE: Color = Color(0.45, 0.7, 1.0)
const EMBER: Color = Color(1.0, 0.55, 0.2)
const ANVIL: String = "res://assets/sprites/altar/first_anvil.png"
const SMITH: String = "res://assets/sprites/residents/halvard.png"

var _hands: Node2D
var _vision: Node2D
var _veil: ColorRect


func _play_beat(id: String) -> bool:
	match id:
		"rod_lightning":
			_rod_lightning()
		"crystal_grab":
			_grab()
		"crystal_arc":
			_arc()
		"crystal_vision":
			_show_vision()
		"vision_end":
			_end_vision()
		_:
			return false
	return true


func _crystal_top() -> Vector2:
	var node := node2d(crystal)
	return (node.global_position if node else global_position) + Vector2(0, -CRYSTAL_HEIGHT)


func _rod_top() -> Vector2:
	var node := node2d(rod_stand)
	return (node.global_position if node else global_position) + Vector2(0, -34)


func _rod_lightning() -> void:
	# The crystal's bolts sweep over from the floor into the copper rod, crackle there a moment
	# (bolts fly down the rod) and sink into the ground.
	var bolts := get_node_or_null(arcs) as CrystalArcs
	if bolts == null or not bolts.is_crackling():
		bolts = CrystalArcs.new()
		bolts.z_index = 1
		add_child(bolts)
		bolts.global_position = _crystal_top()
	AudioManager.play_sound("lightning_strike", 1.0)
	flash(Color(0.8, 0.9, 1.0, 0.4), 0.3)
	await bolts.redirect_to(_rod_top(), 0.5)
	for i in 5:
		fx.spawn("lightning_bolt", _rod_top(), Color.WHITE, -1.0, _crystal_top() + Vector2(randf_range(-10, 10), randf_range(-8, 8)))
		if not await wait(0.16):
			return
		fx.spawn("lightning_hit", _rod_top(), Color.WHITE)
	# down the rod into the ground
	var stand := node2d(rod_stand)
	if stand:
		fx.spawn("area_thunder", stand.global_position, Color.WHITE)
	shake(0.5, 1.5)
	AudioManager.play_sound("rock_break", 0.6)
	if is_instance_valid(bolts):
		bolts.fade_out(0.6)


## The player walks up to the altar and looks up, the crystal sinks down into his hands and he
## lifts it over his head, it flares, then he tucks it away; the crystal over the altar is gone.
func _grab() -> void:
	var stone := node2d(altar)
	var body := player()
	if stone == null or body == null:
		return
	walk_player(PackedVector2Array([stone.global_position + Vector2(0, 22)]), "up", 0.8)
	if not await wait(0.85):
		return
	var floating := node2d(crystal)
	var gem: Node2D = floating.get_node_or_null("Sprite2D") as Node2D if floating else null
	var bolts := get_node_or_null(arcs) as CrystalArcs
	if bolts:
		bolts.set_process(false)
	if gem:
		AudioManager.play_sound("item_reveal", 0.8)
		floating.z_index = 1
		var sink := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sink.tween_property(gem, "global_position", body.global_position + Vector2(0, -20), 0.6)
		# ... and up over the head in both hands, where it flares once.
		sink.tween_property(gem, "global_position", body.global_position + Vector2(0, -44), 0.4)
		await sink.finished
		if not is_instance_valid(floating):
			return
		fx.spawn("light_hit", gem.global_position, Color(0.75, 0.88, 1.0))
		AudioManager.play_sound("item_reveal", 0.6)
		if not await wait(1.1) or not is_instance_valid(floating):
			return
		var away := create_tween()
		away.tween_property(gem, "global_position", body.global_position + Vector2(0, -18), 0.3)
		away.parallel().tween_property(gem, "modulate:a", 0.0, 0.3)
		await away.finished
		if is_instance_valid(floating):
			floating.hide()


func _arc() -> void:
	var body := player()
	var at: Vector2 = body.global_position if body else _crystal_top()
	# The lightning leaps from the crystal in the player's hands up across the room.
	for i in 3:
		var to: Vector2 = at + Vector2(randf_range(-90, 90), randf_range(-110, -60))
		fx.spawn("lightning_bolt", to, Color.WHITE, 1.0, at + Vector2(0, -16))
		fx.spawn("lightning_hit", to, Color.WHITE)
	AudioManager.play_sound("lightning_strike", 1.15)
	shake(0.25, 1.5)
	flash(Color(0.8, 0.9, 1.0, 0.7), 0.35)
	if body:
		_hands = Node2D.new()
		add_child(_hands)
		_hands.global_position = at + Vector2(0, -12)
		fx.add_loop(_hands, "glow", BLUE)


func _show_vision() -> void:
	# the temple blurs: a blue veil over the screen, the man at the anvil over the altar
	_veil = world_tint(Color(0.1, 0.15, 0.3, 0.0))
	create_tween().tween_property(_veil, "color:a", 0.55, 0.8)
	_vision = Node2D.new()
	_vision.z_index = 4
	_vision.z_as_relative = false
	add_child(_vision)
	_vision.global_position = _crystal_top() + Vector2(0, -24)
	var anvil := Sprite2D.new()
	anvil.texture = load(ANVIL)
	anvil.position = Vector2(-10, 0)
	anvil.scale = Vector2(0.7, 0.7)
	_vision.add_child(anvil)
	var smith := Sprite2D.new()
	smith.texture = load(SMITH)
	smith.region_enabled = true
	smith.region_rect = CharacterBaker.get_frame_rect("down")
	smith.position = Vector2(12, -18)
	_vision.add_child(smith)
	_vision.modulate = Color(0.75, 0.85, 1.3, 0.0)
	var show := create_tween()
	show.tween_property(_vision, "modulate:a", 0.7, 0.9)
	# its own effects above the veil
	var glow := WorldVfx.new()
	_vision.add_child(glow)
	glow.z_index = 5
	glow.add_loop(anvil, "aura_burn", EMBER)
	glow.add_loop(smith, "glow", BLUE, Vector2(0, 8))
	AudioManager.play_sound("item_reveal", 0.6)
	# it flickers like a memory
	if not await wait(1.2):
		return
	var flicker := create_tween().set_loops(4)
	flicker.tween_property(_vision, "modulate:a", 0.45, 0.25)
	flicker.tween_property(_vision, "modulate:a", 0.7, 0.25)


func _end_vision() -> void:
	if _vision and is_instance_valid(_vision):
		var vision: Node2D = _vision
		var fade := create_tween()
		fade.tween_property(vision, "modulate:a", 0.0, 0.6)
		fade.tween_callback(vision.queue_free)
	_vision = null
	if _veil and is_instance_valid(_veil):
		var veil: ColorRect = _veil
		var fade_veil := create_tween()
		fade_veil.tween_property(veil, "color:a", 0.0, 0.6)
		fade_veil.tween_callback(veil.queue_free)
	_veil = null
	if _hands and is_instance_valid(_hands):
		var hands: Node2D = _hands
		_hands = null
		if await wait(1.5):
			fx.remove_loop(hands)
			hands.queue_free()
