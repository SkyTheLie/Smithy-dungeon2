class_name MonsterPreview
extends Control
## Shows a monster (EnemyData) playing its animations in a loop, as in fights (looking left):
## stand -> walk -> attack -> walk -> die -> stand ... Every round takes the next attack picture
## (lunge, slam, skills ...; same pictures only once). Monsters without a walk picture stand while
## "walking". Used in the lexicon entry (LexiconEntryWindow).

## The shown part changed ("Stehen", "Laufen", "Angriff: Biss" ...), for a label below.
signal phase_changed(text: String)

## Seconds of each part (attack and death last as long as their pictures).
const STAND_TIME: float = 1.6
const WALK_TIME: float = 1.2
const DEAD_HOLD: float = 0.9
## Animations that are no attack.
const NO_ATTACK: Array[String] = ["walk", "death", "hit", "idle"]
## Attack poses first, in this order; skill pictures after them.
const POSE_ORDER: Array[String] = ["lunge", "slam", "shoot", "cast"]
const POSE_NAMES: Dictionary = {"lunge": "Angriff", "slam": "Schlag", "shoot": "Schuss", "cast": "Zauber"}
## Floating monsters bob this many pixels.
const HOVER_BOB: float = 2.0

enum Phase { STAND, WALK_IN, ATTACK, WALK_OUT, DEATH }

var enemy: EnemyData
var _phase: Phase = Phase.STAND
var _time: float = 0.0
var _total: float = 0.0
## Attack animation keys (one per picture) and the one of this round.
var _attacks: Array[String] = []
var _attack_index: int = 0


func show_enemy(data: EnemyData) -> void:
	enemy = data
	_attacks = _find_attacks(data)
	_attack_index = 0
	_start(Phase.STAND)


func _process(delta: float) -> void:
	if enemy == null or not is_visible_in_tree():
		return
	_time += delta
	_total += delta
	if _time >= _get_phase_length():
		_start(_next_phase())
	queue_redraw()


func _next_phase() -> Phase:
	match _phase:
		Phase.STAND:
			return Phase.WALK_IN
		Phase.WALK_IN:
			return Phase.ATTACK if not _attacks.is_empty() else Phase.WALK_OUT
		Phase.ATTACK:
			_attack_index = (_attack_index + 1) % maxi(1, _attacks.size())
			return Phase.WALK_OUT
		Phase.WALK_OUT:
			return Phase.DEATH if enemy.animations.has("death") else Phase.STAND
	return Phase.STAND


func _start(phase: Phase) -> void:
	_phase = phase
	_time = 0.0
	phase_changed.emit(_get_phase_text())
	queue_redraw()


func _get_phase_length() -> float:
	match _phase:
		Phase.STAND:
			return STAND_TIME
		Phase.WALK_IN, Phase.WALK_OUT:
			return WALK_TIME
		Phase.ATTACK:
			return _animation_length(_attacks[_attack_index]) if not _attacks.is_empty() else 0.0
		Phase.DEATH:
			return _animation_length("death") + DEAD_HOLD
	return 1.0


func _animation_length(key: String) -> float:
	var animation: Dictionary = enemy.animations.get(key, {})
	if animation.is_empty():
		return 0.0
	return float(maxi(1, animation["frames"])) / maxf(0.1, float(animation["fps"]))


func _get_phase_text() -> String:
	match _phase:
		Phase.STAND:
			return Language.translate("Stehen")
		Phase.WALK_IN, Phase.WALK_OUT:
			return Language.translate("Laufen")
		Phase.ATTACK:
			return _attack_name(_attacks[_attack_index]) if not _attacks.is_empty() else ""
		Phase.DEATH:
			return Language.translate("Sterben")
	return ""


func _attack_name(key: String) -> String:
	if POSE_NAMES.has(key):
		return Language.translate(POSE_NAMES[key])
	var skill: SkillData = ContentDB.find_skill(key)
	return skill.display_name if skill else Language.translate("Angriff")


func _get_frame() -> Texture2D:
	match _phase:
		Phase.WALK_IN, Phase.WALK_OUT:
			var walk: Texture2D = enemy.get_walk_frame(_time)
			if walk:
				return walk
		Phase.ATTACK:
			if not _attacks.is_empty():
				var attack: Texture2D = enemy.get_animation_frame(_attacks[_attack_index], _time)
				if attack:
					return attack
		Phase.DEATH:
			var death: Texture2D = enemy.get_animation_frame("death", _time)
			if death:
				return death
	return enemy.get_frame(int(_total * enemy.frames_per_second))


func _draw() -> void:
	if enemy == null:
		return
	var frame: Texture2D = _get_frame()
	if frame == null:
		return
	# Same scale for every picture, from the monster's normal frame: whole steps while it fits,
	# smaller pictures stay sharp. Bigger pictures (room for breath ...) stay centred.
	var base: Vector2 = Vector2(enemy.frame_size)
	var fit: float = minf(size.x / base.x, size.y / base.y)
	var picture_scale: float = floorf(fit) if fit >= 1.0 else fit
	var picture_size: Vector2 = frame.get_size() * picture_scale
	var position_offset: Vector2 = (size - picture_size) / 2.0
	if enemy.hover:
		position_offset.y += sin(_total * 3.0) * HOVER_BOB - HOVER_BOB
	var rect := Rect2(position_offset.round(), picture_size)
	if enemy.faces_right:
		# Mirrored around the middle of its rect: looks left like in fights. (A negative rect size
		# would flip it too, but draws it one picture width further right.)
		draw_set_transform(Vector2(2.0 * rect.position.x + rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(frame, rect, false, enemy.tint)
	if enemy.faces_right:
		draw_set_transform(Vector2.ZERO)


## One key per attack picture: poses first, then skill pictures; pictures used by an earlier key
## (e.g. the rat uses the same one for all poses) are left out.
static func _find_attacks(data: EnemyData) -> Array[String]:
	var keys: Array[String] = []
	for key: String in POSE_ORDER:
		if data.animations.has(key):
			keys.append(key)
	var others: Array = data.animations.keys().filter(func(key: Variant) -> bool:
		return not POSE_ORDER.has(str(key)) and not NO_ATTACK.has(str(key)))
	others.sort()
	for key: Variant in others:
		keys.append(str(key))
	var sheets: Array = []
	var result: Array[String] = []
	for key: String in keys:
		var sheet: Variant = data.animations[key].get("sheet")
		if sheets.has(sheet):
			continue
		sheets.append(sheet)
		result.append(key)
	return result
