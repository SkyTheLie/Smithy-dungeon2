class_name AltarSealCutscene
extends StoryCutscene
## Sealing the gate at the Altar of the Nine (dialogue "seal_the_gate"), beats while the box is hidden:
## - seal_gather: the player steps up to the anvil, Halvard comes beside him
## - seal_stones: eight stones go into the setting one after the other; with each a light flies to
##   its pillar, the pillar lights up and the crack in the gate closes a little (gate sheet frames)
## - seal_hands: the ninth stone (ice); Halvard lays his hands on the player's, both glow like embers,
##   the glow flows into the setting, the last pillar lights up
## - seal_strike: the last hammer blow (then "gate_close" of AltarGateCutscene closes the gate)

@export var halvard: NodePath
## The pillars in the order the stones light them (Sprite2D child with StoryTexture).
@export var pillars: Array[NodePath] = []
## AltarGateCutscene (the gate sheet, frame 0 = open, last = closed).
@export var gate: NodePath
@export var anvil: NodePath

const PILLAR_LIT: String = "res://assets/sprites/altar/pillar_lit.png"
## Earth, wind, fire, water, light, dark, lightning, poison, ice (Halvard's order).
const STONE_COLORS: Array[Color] = [Color(0.55, 0.85, 0.35), Color(0.75, 1.0, 0.85), Color(1.0, 0.5, 0.2),
		Color(0.3, 0.6, 1.0), Color(1.0, 0.9, 0.45), Color(0.65, 0.4, 0.95), Color(1.0, 0.95, 0.3),
		Color(0.45, 0.9, 0.3), Color(0.6, 0.95, 1.0)]
const EMBER: Color = Color(1.0, 0.6, 0.25)

var _glows: Array[Node2D] = []


func _play_beat(id: String) -> bool:
	match id:
		"seal_gather":
			_gather()
		"seal_stones":
			_stones()
		"seal_hands":
			_hands()
		"seal_strike":
			_strike()
		_:
			return false
	return true


func _anvil_top() -> Vector2:
	var node := node2d(anvil)
	return (node.global_position if node else global_position) + Vector2(0, -14)


func _gather() -> void:
	var node := node2d(anvil)
	if node == null:
		return
	var spot: Vector2 = node.global_position + Vector2(0, 24)
	var body := player()
	if body:
		walk_player(PackedVector2Array([Vector2(body.global_position.x, spot.y + 30), spot]), "up", 2.2)
	var smith := node2d(halvard)
	if smith:
		await walk_npc(smith, PackedVector2Array([Vector2(spot.x - 22, spot.y + 30), spot + Vector2(-22, 0)]),
				maxf(60.0, smith.global_position.distance_to(spot) / 2.4), "up")


func _gate_sprite() -> Sprite2D:
	return get_node_or_null(gate) as Sprite2D


func _light_pillar(index: int) -> void:
	if index >= pillars.size():
		return
	var pillar := node2d(pillars[index])
	if pillar == null:
		return
	var color: Color = STONE_COLORS[index % STONE_COLORS.size()]
	var top: Vector2 = pillar.global_position + Vector2(0, -60)
	fx.spawn("light_bolt", top, color, 1.0, _anvil_top())
	await wait(0.3)
	var sprite := pillar.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture = load(PILLAR_LIT)
		sprite.modulate = Color(1.8, 1.8, 1.8)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.4)
	fx.spawn("light_hit", top, color)
	AudioManager.play_sound("rarity_up", 0.5 + 0.05 * index)


func _stones() -> void:
	var sheet := _gate_sprite()
	if sheet:
		sheet.frame = 0
		sheet.show()
	var steps: int = maxi(1, pillars.size() - 1)
	for i in steps:
		fx.spawn("glow", _anvil_top(), STONE_COLORS[i])
		AudioManager.play_sound("anvil_good", 0.6)
		_light_pillar(i)
		await wait(0.35)
		if not is_inside_tree():
			return
		if sheet:
			# the crack closes a little, the last frame is left for the final blow
			sheet.frame = clampi(int(round(float(i + 1) * (sheet.hframes - 2) / steps)), 0, sheet.hframes - 2)
		await wait(0.2)
		if not is_inside_tree():
			return


func _hands() -> void:
	var body := player()
	var smith := node2d(halvard)
	for who: Node2D in [smith, body]:
		if who == null:
			continue
		var glow := Node2D.new()
		add_child(glow)
		glow.global_position = who.global_position + Vector2(0, -12)
		fx.add_loop(glow, "glow", EMBER)
		_glows.append(glow)
	AudioManager.play_sound("skill_used", 0.8)
	if not await wait(0.8):
		return
	# the glow flows from the hands into the setting
	for glow in _glows:
		var flow := create_tween()
		flow.tween_property(glow, "global_position", _anvil_top(), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await wait(0.65):
		return
	for glow in _glows:
		fx.remove_loop(glow)
		glow.queue_free()
	_glows.clear()
	fx.spawn("area_holy", _anvil_top() + Vector2(0, 14), EMBER)
	_light_pillar(pillars.size() - 1)


func _strike() -> void:
	AudioManager.play_sound("anvil_perfect", 1.0)
	fx.spawn("crit", _anvil_top(), Color.WHITE)
	fx.spawn("area_nova", _anvil_top() + Vector2(0, 14), Color(0.8, 0.95, 1.0))
	shake(1.4, 2.0)
	var sheet := _gate_sprite()
	if sheet:
		# AltarGateCutscene plays on from here to the closed gate ("gate_close" right after)
		sheet.show()
