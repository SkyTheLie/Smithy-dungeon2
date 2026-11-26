class_name NpcActing
extends RefCounted
## Small gestures any figure can play during a dialogue, without a cut scene of its own: a line with
## "action": "cutscene:act:<npc_id>:<gesture>[:<item>]" (and "hide_for") makes the StoryNpc with
## that id (or the player: npc_id "player") play it where it stands. <item> is an item id, several
## ids joined with "+" (composed like the finished item, e.g. "copper_hammer_head+wooden_shaft") or
## a res:// path.
## Gestures:
## - bite / eat: the item goes to the mouth, a few nibbles (eat: it gets smaller and is gone)
## - count: the item bobs twice in front of the figure
## - hold: the item is lifted above the head and shines
## - swing: the item swings once in a wide arc over the head
## - strike: hammers the item down three times in front (sparks, anvil sound)
## - hammer: the player steps beside a figure (<item> = "<npc_id>[,<colour>]") and swings a hammer
##   at it with the fight pose; with a colour the target rings ("ring") at the hit
## - thrust: spins the item once and thrusts it forward (ice splinters)
## - give: the item floats from the figure to the player (the player gives to the nearest figure);
##   several items one after the other: "<item>|<item>"
## - glow: blue light in the hands (the mark of the smiths)
## - shake: shakes itself; tremble: trembles
## - hop: two happy hops; nod: nods twice; bow: bows
## - kneel: sinks down and stays low; rise: stands up again
## - whistle: whistles through the fingers (a little burst above the head)
## - count_bite: counts the item, then bites it; inspect: turns it in the light, it glimmers blue;
##   knead: the item goes soft and hard again in the hands
## - vanish: gone in a puff of blue smoke; get_up: a lying figure gets up
## - stand_up: rises (e.g. from a throne); sit: sits down and stays low; face_player: looks at him
## - quake: the camera shakes; boom: a bang (flash, shake); storm: lightning strikes the ground
##   around the view; firelight: fire flickers on the walls;
##   cheer: cheering and little lights all around; build: sawing and hammering all around;
##   swarm: a swarm of dark shapes flies over; hammering: someone hammers out of sight;
##   ring: the figure (a pillar) rings and shines in the colour <item> (html, e.g. "88ccff")
## - stomp: heavy footsteps come closer; turn: looks to <item> ("up", "down", "left", "right")
## - unlock: three rings of a lock click into place, a bolt springs back (<item> = "x,y" of the lock)
## - block: steps into the player's way with a clank; push: shoves something heavy open (creak);
##   splash: water splashes and glitters around; shadows: shadows crawl out and spread downwards
## - laugh: shakes with laughter; drink: the item goes to the mouth, tips up and is empty;
##   drop: the item slips from the hands and falls to the ground; fizzle: a hand goes up, only a
##   grey puff comes out; sleep: lies down and stays there, little "z" rise; trace: the item lies
##   in front, a finger (a glint) runs across it; crash: something breaks out of sight (splinters
##   rain down, the camera shakes); run_off: walks away from the player and is gone
## - glow takes an optional colour <item> (html, e.g. "a0703c"), default the blue of the smiths
## Several gestures one after the other: "<gesture>><gesture>", e.g. "drink>get_up".

const LIFT: Vector2 = Vector2(0, -26)
const HAND: Vector2 = Vector2(7, -14)
const MOUTH: Vector2 = Vector2(3, -24)
const BLUE: Color = Color(0.45, 0.75, 1.0)
## Gesture "hammer": the one-handed chop of the fights, the distance to the target's foot, frame time.
const HAMMER_POSE: String = "one_chop"
const HAMMER_REACH: float = 27.0
const HAMMER_FRAME_TIME: float = 0.08


## Plays `gesture` on `body` (a StoryNpc or the player). Awaitable, returns when it is done.
static func play(body: Node2D, gesture: String, item: String = "") -> void:
	if body == null or not body.is_inside_tree():
		return
	if ">" in gesture:
		for part in gesture.split(">", false):
			if not is_instance_valid(body) or not body.is_inside_tree():
				return
			await play(body, part, item)
		return
	var figure := figure_of(body)
	var looking: String = str(body.get("_direction") if body.get("_direction") != null else body.get("_facing"))
	var side: float = -1.0 if looking == "left" else 1.0
	match gesture:
		"bite", "eat":
			await _bite(body, item, gesture == "eat", side)
		"count":
			await _count(body, item, side)
		"hold":
			await _hold(body, item)
		"swing":
			await _swing(body, item, side)
		"strike":
			await _strike(body, item, side)
		"thrust":
			await _thrust(body, item, side)
		"give":
			# several things one after the other: "<item>|<item>", e.g. a purse and a gem
			for part in item.split("|", false):
				await _give(body, part)
		"glow":
			await _glow(body, Color.html(item) if Color.html_is_valid(item) else BLUE)
		"shake", "tremble":
			await _shake(figure, 6 if gesture == "shake" else 14, 1.0)
		"hop":
			await _hop(figure, 2)
		"nod":
			await _nod(figure, 2, 1.0)
		"bow":
			await _nod(figure, 1, 3.0)
		"kneel":
			await _kneel(figure, true)
		"rise":
			await _kneel(figure, false)
		"whistle":
			await _whistle(body)
		"count_bite":
			await _count(body, item, side)
			await _bite(body, item, false, side)
		"inspect":
			await _inspect(body, item, side)
		"knead":
			await _knead(body, item, side)
		"vanish":
			await _vanish(body)
		"stand_up":
			await _stand_up(figure)
		"sit":
			await _kneel(figure, true, 0.88)
		"face_player":
			_face_player(body)
		"quake":
			await _quake(body, 1.0, 3.0)
		"boom":
			await _boom(body)
		"storm":
			await _storm(body)
		"hammer":
			await _hammer(body, item)
		"firelight":
			await _firelight(body)
		"cheer":
			await _cheer(body)
		"build":
			await _build(body)
		"swarm":
			await _swarm(body)
		"hammering":
			await _hammering(body)
		"ring":
			await _ring(body, item)
		"get_up":
			await _get_up(body, figure)
		"stomp":
			await _stomp(body)
		"unlock":
			await _unlock(body, item)
		"block":
			await _block(body)
		"push":
			await _push(body, figure)
		"splash":
			await _splash(body)
		"shadows":
			await _shadows(body)
		"turn":
			if body.has_method("_face"):
				body.set("facing", item)
				body.call("_face", item)
			elif body.has_method("face"):
				body.call("face", item)
		"laugh":
			await _laugh(figure)
		"drink":
			await _drink(body, item, side)
		"drop":
			await _drop(body, item, side)
		"fizzle":
			await _fizzle(body, side)
		"sleep":
			await _sleep(body, figure, side)
		"trace":
			await _trace(body, item)
		"crash":
			await _crash(body)
		"run_off":
			await _run_off(body)


## The visible figure of a StoryNpc ("Figure") or of the player ("AnimatedSprite2D").
static func figure_of(body: Node2D) -> Node2D:
	if body == null:
		return null
	for name in ["Figure", "AnimatedSprite2D"]:
		var node := body.get_node_or_null(name) as Node2D
		if node:
			return node
	return null


## The texture of `item`: an item id, ids joined with "+" (composed) or a res:// path.
static func icon(item: String) -> Texture2D:
	if item.is_empty():
		return null
	if item.begins_with("res://"):
		return load(item) if ResourceLoader.exists(item) else null
	var parts: Array[ItemData] = []
	for id in item.split("+"):
		if ContentDB.has_item(id):
			parts.append(ContentDB.item(id))
	if parts.is_empty():
		return null
	return parts[0].icon if parts.size() == 1 else ItemIcons.compose(parts)


static func _item_sprite(body: Node2D, item: String, at: Vector2) -> Sprite2D:
	var texture := icon(item)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(0.7, 0.7)
	sprite.position = at
	sprite.z_index = 1
	body.add_child(sprite)
	return sprite


static func _vfx(body: Node2D) -> WorldVfx:
	var fx := WorldVfx.new()
	body.get_parent().add_child(fx)
	body.get_tree().create_timer(3.0, false).timeout.connect(fx.queue_free)
	return fx


static func _wait(body: Node2D, seconds: float) -> bool:
	if not body.is_inside_tree():
		return false
	await body.get_tree().create_timer(seconds, false).timeout
	return is_instance_valid(body) and body.is_inside_tree()


static func _bite(body: Node2D, item: String, eat: bool, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y))
	if sprite == null:
		return
	var up := body.create_tween()
	up.tween_property(sprite, "position", Vector2(MOUTH.x * side, MOUTH.y), 0.35)
	await up.finished
	for i in 3:
		if not is_instance_valid(sprite):
			return
		AudioManager.play_sound("pickaxe_hit" if not eat else "plant_pick", 0.4)
		var nibble := body.create_tween()
		nibble.tween_property(sprite, "position:y", MOUTH.y + 2.0, 0.08)
		nibble.tween_property(sprite, "position:y", MOUTH.y, 0.1)
		if eat:
			nibble.parallel().tween_property(sprite, "scale", sprite.scale * 0.72, 0.18)
		await nibble.finished
		if not await _wait(body, 0.12):
			return
	if not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	if eat:
		away.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	else:
		away.tween_property(sprite, "position", Vector2(HAND.x * side, HAND.y), 0.3)
		away.tween_interval(0.3)
		away.tween_property(sprite, "modulate:a", 0.0, 0.2)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _count(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y))
	if sprite == null:
		return
	for i in 2:
		AudioManager.play_sound("coins", 0.4)
		var bob := body.create_tween()
		bob.tween_property(sprite, "position:y", HAND.y - 5.0, 0.18)
		bob.tween_property(sprite, "position:y", HAND.y, 0.18)
		await bob.finished
	var away := body.create_tween()
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _hold(body: Node2D, item: String) -> void:
	var sprite := _item_sprite(body, item, HAND)
	if sprite == null:
		return
	var up := body.create_tween()
	up.tween_property(sprite, "position", LIFT, 0.4).set_trans(Tween.TRANS_SINE)
	await up.finished
	if not is_instance_valid(sprite):
		return
	_vfx(body).spawn("light_hit", sprite.global_position, Color(1, 0.95, 0.7))
	AudioManager.play_sound("item_reveal", 0.5)
	if not await _wait(body, 1.0) or not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	away.tween_property(sprite, "modulate:a", 0.0, 0.3)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _swing(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(-6 * side, -18))
	if sprite == null:
		return
	sprite.rotation = -1.2 * side
	var arc := body.create_tween()
	arc.tween_property(sprite, "rotation", -2.4 * side, 0.25).set_trans(Tween.TRANS_SINE)
	arc.parallel().tween_property(sprite, "position", Vector2(-2 * side, -30), 0.25)
	arc.tween_property(sprite, "rotation", 1.4 * side, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	arc.parallel().tween_property(sprite, "position", Vector2(12 * side, -12), 0.22)
	await arc.finished
	if not is_instance_valid(sprite):
		return
	AudioManager.play_sound("axe_hit", 0.5)
	_vfx(body).spawn("air_hit", sprite.global_position, Color.WHITE, side)
	if not await _wait(body, 0.4) or not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _strike(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(8 * side, -20))
	if sprite == null:
		return
	var fx := _vfx(body)
	for i in 3:
		var hit := body.create_tween()
		hit.tween_property(sprite, "rotation", -1.0 * side, 0.18 if i == 0 else 0.12)
		hit.tween_property(sprite, "rotation", 0.9 * side, 0.08).set_ease(Tween.EASE_IN)
		await hit.finished
		if not is_instance_valid(sprite):
			return
		AudioManager.play_sound("anvil_good" if i < 2 else "anvil_perfect", 0.6)
		fx.spawn("impact", body.global_position + Vector2(16 * side, -6), Color(1, 0.8, 0.4))
		if not await _wait(body, 0.25 if i == 0 else 0.12):
			return
	var away := body.create_tween()
	away.tween_property(sprite, "rotation", 0.0, 0.2)
	away.tween_interval(0.3)
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _thrust(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(0, -16))
	if sprite == null:
		return
	var spin := body.create_tween()
	spin.tween_property(sprite, "rotation", TAU * side, 0.45)
	spin.tween_property(sprite, "rotation", PI / 2.0 * side, 0.1)
	spin.tween_property(sprite, "position", Vector2(20 * side, -10), 0.1).set_ease(Tween.EASE_IN)
	await spin.finished
	if not is_instance_valid(sprite):
		return
	AudioManager.play_sound("rock_break", 0.6)
	_vfx(body).spawn("ice_hit", sprite.global_position + Vector2(8 * side, 0), Color(0.8, 0.95, 1.0), side)
	if not await _wait(body, 0.5) or not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _give(body: Node2D, item: String) -> void:
	var sprite := _item_sprite(body, item, HAND)
	var target := body.get_tree().get_first_node_in_group(&"player") as Node2D
	if target == body:
		target = _nearest_npc(body)
	if sprite == null or target == null:
		return
	var fly := body.create_tween()
	fly.tween_property(sprite, "global_position", target.global_position + Vector2(0, -14), 0.6) \
			.set_trans(Tween.TRANS_SINE)
	fly.tween_interval(0.3)
	fly.tween_property(sprite, "modulate:a", 0.0, 0.2)
	fly.tween_callback(sprite.queue_free)
	await fly.finished


static func _glow(body: Node2D, color: Color = BLUE) -> void:
	var fx := _vfx(body)
	for i in 2:
		fx.spawn("light_hit", body.global_position + Vector2(0, -12), color)
		if not await _wait(body, 0.35):
			return
	var figure := figure_of(body)
	if figure:
		var tint := body.create_tween()
		tint.tween_property(figure, "modulate", Color(0.6, 0.6, 0.6).lerp(color, 0.5) * 1.6, 0.25)
		tint.tween_property(figure, "modulate", Color.WHITE, 0.6)
		await tint.finished


static func _shake(figure: Node2D, times: int, strength: float) -> void:
	if figure == null:
		return
	var home: Vector2 = figure.position
	for i in times:
		figure.position = home + Vector2(strength if i % 2 == 0 else -strength, 0)
		if not await _wait(figure, 0.05):
			return
	figure.position = home


static func _hop(figure: Node2D, times: int) -> void:
	if figure == null:
		return
	var home: Vector2 = figure.position
	for i in times:
		var hop := figure.create_tween()
		hop.tween_property(figure, "position:y", home.y - 4.0, 0.12).set_ease(Tween.EASE_OUT)
		hop.tween_property(figure, "position:y", home.y, 0.12).set_ease(Tween.EASE_IN)
		await hop.finished
	if is_instance_valid(figure):
		figure.position = home


static func _nod(figure: Node2D, times: int, depth: float) -> void:
	if figure == null:
		return
	var home: Vector2 = figure.position
	for i in times:
		var nod := figure.create_tween()
		nod.tween_property(figure, "position:y", home.y + depth, 0.15 * depth)
		nod.tween_interval(0.1 * depth)
		nod.tween_property(figure, "position:y", home.y, 0.15 * depth)
		await nod.finished
	if is_instance_valid(figure):
		figure.position = home


## Kneeling: the figure sinks (squashed from the feet up), standing: back to normal.
static func _kneel(figure: Node2D, down: bool, depth: float = 0.75) -> void:
	if figure == null:
		return
	if down and not figure.has_meta(&"stand_scale"):
		figure.set_meta(&"stand_scale", figure.scale)
		figure.set_meta(&"stand_position", figure.position)
	if not figure.has_meta(&"stand_scale"):
		return
	var stand_scale: Vector2 = figure.get_meta(&"stand_scale")
	var stand_position: Vector2 = figure.get_meta(&"stand_position")
	var tween := figure.create_tween()
	if down:
		# the frame is centred: lower it by the part cut off below, so the feet stay on the ground
		tween.tween_property(figure, "scale", Vector2(stand_scale.x, stand_scale.y * depth), 0.35)
		tween.parallel().tween_property(figure, "position", stand_position + Vector2(0, 20.0 * (1.0 - depth)), 0.35)
	else:
		tween.tween_property(figure, "scale", stand_scale, 0.3)
		tween.parallel().tween_property(figure, "position", stand_position, 0.3)
		figure.remove_meta(&"stand_scale")
		figure.remove_meta(&"stand_position")
	await tween.finished


static func _whistle(body: Node2D) -> void:
	AudioManager.play_sound("unlock", 0.5)
	var fx := _vfx(body)
	fx.spawn("buff", body.global_position + Vector2(0, -26), Color(1, 1, 0.85))
	await _wait(body, 0.5)


static func _nearest_npc(body: Node2D) -> Node2D:
	var best: Node2D = null
	for node in body.get_tree().get_nodes_in_group(StoryNpc.GROUP):
		var npc := node as Node2D
		if npc == null or not npc.visible or bool(npc.get("narrator")):
			continue
		if best == null or npc.global_position.distance_to(body.global_position) < best.global_position.distance_to(body.global_position):
			best = npc
	return best


static func _inspect(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y - 4))
	if sprite == null:
		return
	var turn := body.create_tween()
	turn.tween_property(sprite, "rotation", 0.6 * side, 0.35)
	turn.tween_property(sprite, "rotation", -0.4 * side, 0.35)
	await turn.finished
	if not is_instance_valid(sprite):
		return
	_vfx(body).spawn("light_hit", sprite.global_position, BLUE)
	var glow := body.create_tween()
	glow.tween_property(sprite, "modulate", Color(0.7, 1.1, 1.8), 0.2)
	glow.tween_property(sprite, "modulate", Color.WHITE, 0.6)
	glow.tween_property(sprite, "modulate:a", 0.0, 0.25)
	glow.tween_callback(sprite.queue_free)
	await glow.finished


static func _knead(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y))
	if sprite == null:
		return
	var base: Vector2 = sprite.scale
	var soft := body.create_tween()
	soft.tween_property(sprite, "modulate", Color(1.6, 1.3, 1.0), 0.3)
	for i in 3:
		soft.tween_property(sprite, "scale", Vector2(base.x * 1.3, base.y * 0.7), 0.18)
		soft.tween_property(sprite, "scale", Vector2(base.x * 0.8, base.y * 1.2), 0.18)
	soft.tween_property(sprite, "scale", base, 0.15)
	soft.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	await soft.finished
	if not is_instance_valid(sprite):
		return
	AudioManager.play_sound("anvil_perfect", 0.4)
	_vfx(body).spawn("light_hit", sprite.global_position, BLUE)
	var away := body.create_tween()
	away.tween_interval(0.4)
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


static func _vanish(body: Node2D) -> void:
	var fx := _vfx(body)
	fx.spawn("area_nova", body.global_position + Vector2(0, -8), Color(0.45, 0.6, 1.0))
	fx.spawn("death", body.global_position + Vector2(0, -12), Color(0.55, 0.7, 1.0))
	AudioManager.play_sound("rock_break", 0.5)
	if not await _wait(body, 0.15):
		return
	body.hide()
	var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)


static func _stand_up(figure: Node2D) -> void:
	if figure == null:
		return
	if not figure.has_meta(&"stand_scale"):
		await _kneel(figure, true, 0.88)
	await _kneel(figure, false)


## A lying figure (StoryNpc.lying, turned on its side) gets up.
static func _get_up(body: Node2D, figure: Node2D) -> void:
	if figure == null:
		return
	var tween := body.create_tween()
	tween.tween_property(figure, "rotation", -0.6, 0.3)
	tween.tween_property(figure, "rotation", 0.0, 0.25)
	tween.parallel().tween_property(figure, "position", Vector2(0, -13), 0.25)
	await tween.finished
	await _shake(figure, 4, 1.0)


static func _face_player(body: Node2D) -> void:
	var target := body.get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null or not body.has_method("_face"):
		return
	var offset: Vector2 = target.global_position - body.global_position
	var facing: String
	if absf(offset.x) > absf(offset.y):
		facing = "right" if offset.x > 0.0 else "left"
	else:
		facing = "down" if offset.y > 0.0 else "up"
	body.set("facing", facing)
	body.call("_face", facing)


static func _quake(body: Node2D, seconds: float, strength: float) -> void:
	var camera: Camera2D = body.get_viewport().get_camera_2d()
	if camera == null:
		return
	var home: Vector2 = camera.offset
	var end_time: float = Time.get_ticks_msec() / 1000.0 + seconds
	while Time.get_ticks_msec() / 1000.0 < end_time and is_instance_valid(camera) and body.is_inside_tree():
		camera.offset = home + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await body.get_tree().process_frame
	if is_instance_valid(camera):
		camera.offset = home


## A coloured rect over the whole map (in the world, below the dialogue box) fading in `seconds`.
static func _flash(body: Node2D, color: Color, seconds: float) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(6000, 6000)
	rect.z_index = 3
	rect.z_as_relative = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.get_parent().add_child(rect)
	rect.global_position = Vector2(-3000, -3000)
	var fade := rect.create_tween()
	fade.tween_property(rect, "modulate:a", 0.0, seconds)
	fade.tween_callback(rect.queue_free)


static func _camera_center(body: Node2D) -> Vector2:
	var camera: Camera2D = body.get_viewport().get_camera_2d()
	return camera.get_screen_center_position() if camera else body.global_position


static func _boom(body: Node2D) -> void:
	AudioManager.play_sound("rock_break", 0.9)
	_flash(body, Color(1.0, 0.6, 0.25, 0.55), 0.6)
	await _quake(body, 0.6, 3.0)


## The player steps beside the figure with npc id <target> (e.g. a pillar's talk spot), turns to it
## and swings a hammer at it with the one-handed chop pose of the fights (the hammer is its own
## picture in the hand, as in battle). At the hit: sparks, a clang and, with ",<colour>", the target
## rings in that colour (gesture "ring"). <item> = "<target>[,<html colour>]". Figures without that
## pose fall back to "strike".
static func _hammer(body: Node2D, item: String) -> void:
	var parts: PackedStringArray = item.split(",")
	var target: Node2D = _find_npc(body, parts[0])
	var sprite := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var look: Appearance = GameState.player_appearance if body is Player else null
	if target == null or sprite == null or look == null or not CharacterBaker.has_pose(look.outfit, HAMMER_POSE):
		await _strike(body, "iron_hammer_head+wooden_shaft", 1.0)
		if target and parts.size() > 1:
			await _ring(target, parts[1])
		return
	# The foot of the pillar (the talk spot sits a few px below it).
	var anchor: Node2D = target.get_parent() as Node2D if target.get_parent() is StaticBody2D else target
	var side: float = -1.0 if body.global_position.x <= anchor.global_position.x else 1.0
	var stand: Vector2 = anchor.global_position + Vector2(side * HAMMER_REACH, 2.0)
	var facing: String = "right" if side < 0.0 else "left"
	# Walk there.
	body.set("_facing", facing)
	sprite.play("walk_" + facing)
	var walk := body.create_tween()
	walk.tween_property(body, "global_position", stand, clampf(body.global_position.distance_to(stand) / 90.0, 0.1, 0.6))
	await walk.finished
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	# The swing: pose frames, the hammer turned around the hand, the fist over the grip.
	var weapon: Dictionary = CharacterBaker.get_weapon_overlay({"type": "hammer", "head": "iron", "grip": "wood"})
	var sheet: Texture2D = CharacterBaker.get_pose_sheet(look, {}, HAMMER_POSE)
	var count: int = CharacterBaker.get_pose_frame_count(look.outfit, HAMMER_POSE)
	var rig := Node2D.new()
	rig.position = sprite.position
	rig.scale = Vector2(-sprite.scale.x if facing == "left" else sprite.scale.x, sprite.scale.y)
	body.add_child(rig)
	var corner := Vector2(-CharacterBaker.FRAME, -CharacterBaker.FRAME) / 2.0
	var figure := Sprite2D.new()
	figure.texture = sheet
	figure.region_enabled = true
	rig.add_child(figure)
	var hammer := Sprite2D.new()
	hammer.centered = false
	if not weapon.is_empty():
		hammer.texture = weapon["texture"]
		hammer.offset = -weapon["anchor"] - Vector2(0.5, 0.5)
	rig.add_child(hammer)
	var fist := Sprite2D.new()
	fist.texture = sheet
	fist.centered = false
	fist.region_enabled = true
	rig.add_child(fist)
	sprite.hide()
	var hit_frame: int = 0
	for frame in count:
		if CharacterBaker.get_pose_angle(look.outfit, HAMMER_POSE, frame) > CharacterBaker.get_pose_angle(look.outfit, HAMMER_POSE, hit_frame):
			hit_frame = frame
	for frame in count:
		var hand: Vector2 = CharacterBaker.get_pose_hand(look.outfit, HAMMER_POSE, frame)
		figure.region_rect = Rect2(frame * CharacterBaker.FRAME, 0, CharacterBaker.FRAME, CharacterBaker.FRAME)
		hammer.position = corner + hand + Vector2(0.5, 0.5)
		hammer.rotation_degrees = CharacterBaker.get_pose_angle(look.outfit, HAMMER_POSE, frame)
		fist.region_rect = Rect2(Vector2(frame * CharacterBaker.FRAME, 0) + hand - Vector2(2, 2), Vector2(4, 4))
		fist.position = corner + hand - Vector2(2, 2)
		if frame == hit_frame:
			# A ringing target (pillar) sounds like a deep bell, otherwise a plain clang.
			AudioManager.play_sound("pillar_chime" if parts.size() > 1 else "anvil_good", 1.0 if parts.size() > 1 else 0.7)
			_vfx(body).spawn("impact", anchor.global_position + Vector2(side * 10.0, -14.0), Color(1, 0.85, 0.5))
			_quake(body, 0.15, 1.5)
			if parts.size() > 1:
				_ring(target, parts[1])
		if not await _wait(body, HAMMER_FRAME_TIME * (3.0 if frame == hit_frame else 1.0)):
			break
	if is_instance_valid(rig):
		rig.queue_free()
	if is_instance_valid(sprite):
		sprite.show()
		sprite.play("idle_" + facing)


## The StoryNpc (or any node with that npc_id) in the current scene, null if none.
static func _find_npc(body: Node2D, npc_id: String) -> Node2D:
	# The map the figure belongs to (its owner), else the current scene.
	var scene: Node = body.owner if body.owner else body.get_tree().current_scene
	if scene == null or npc_id.is_empty():
		return null
	for node in scene.find_children("*", "", true, false):
		if node is Node2D and str(node.get("npc_id")) == npc_id:
			return node
	return null


## A thunderstorm: four bolts from the sky strike the sand around the view, each with a pale flash,
## a short shake and a crack.
static func _storm(body: Node2D) -> void:
	var fx := _vfx(body)
	var center: Vector2 = _camera_center(body)
	for i in 4:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var hit: Vector2 = center + Vector2(side * randf_range(90, 260), randf_range(-130, 70))
		fx.spawn("lightning_bolt", hit, Color.WHITE, -1.0, hit + Vector2(randf_range(-40, 40), -240))
		fx.spawn("lightning_hit", hit, Color.WHITE)
		_flash(body, Color(0.8, 0.88, 1.0, 0.45), 0.3)
		AudioManager.play_sound("lightning_strike", randf_range(0.9, 1.1))
		_quake(body, 0.25, 2.0)
		if not await _wait(body, randf_range(0.35, 0.55)):
			return


static func _firelight(body: Node2D) -> void:
	for i in 4:
		_flash(body, Color(1.0, 0.45, 0.1, randf_range(0.18, 0.32)), 0.35)
		if not await _wait(body, randf_range(0.25, 0.4)):
			return


static func _cheer(body: Node2D) -> void:
	var fx := _vfx(body)
	var center: Vector2 = _camera_center(body)
	AudioManager.play_sound("achievement", 0.6)
	for i in 10:
		fx.spawn("buff" if i % 2 == 0 else "light_hit", center + Vector2(randf_range(-180, 180), randf_range(-90, 60)),
				Color.from_hsv(randf(), 0.4, 1.0))
		if not await _wait(body, 0.12):
			return


static func _build(body: Node2D) -> void:
	var fx := _vfx(body)
	var center: Vector2 = _camera_center(body)
	for i in 8:
		AudioManager.play_sound("wood_break" if i % 3 == 2 else "anvil_miss", 0.5)
		fx.spawn("impact" if i % 2 == 0 else "dodge", center + Vector2(randf_range(-150, 150), randf_range(-80, 40)), Color(1, 0.9, 0.7))
		if not await _wait(body, 0.22):
			return
	_flash(body, Color(1, 1, 1, 0.5), 0.5)


static func _swarm(body: Node2D) -> void:
	var fx := _vfx(body)
	var center: Vector2 = _camera_center(body)
	for i in 9:
		var start := center + Vector2(-260, randf_range(-30, 90))
		fx.spawn("dark_bolt", start + Vector2(500, randf_range(-160, -60)), Color(0.4, 0.35, 0.45), 1.0, start, 0.9)
		if i % 3 == 0:
			AudioManager.play_sound("skill_used", 0.4)
		if not await _wait(body, 0.1):
			return
	await _wait(body, 0.8)


static func _hammering(body: Node2D) -> void:
	for gap: float in [0.0, 0.35, 0.3, 0.45, 0.25]:
		if not await _wait(body, gap):
			return
		AudioManager.play_sound("anvil_miss" if gap > 0.4 else "anvil_good", 0.45)


static func _ring(body: Node2D, color_html: String) -> void:
	var color: Color = Color.html(color_html) if Color.html_is_valid(color_html) else Color(0.9, 0.95, 1.0)
	var fx := _vfx(body)
	AudioManager.play_sound("anvil_perfect", 0.6)
	fx.spawn("light_hit", body.global_position + Vector2(0, -20), color)
	fx.spawn("buff", body.global_position + Vector2(0, -10), color)
	await _wait(body, 0.5)


## Heavy footsteps coming closer (out of sight), the ground shakes a little with each.
static func _stomp(body: Node2D) -> void:
	for i in 4:
		AudioManager.play_sound("step", 0.5 + 0.12 * i)
		await _quake(body, 0.12, 1.0 + i * 0.5)
		if not await _wait(body, 0.25):
			return


## Three rings of a lock click into place one after the other (a glint each), then a bolt springs
## back deep inside. <item> = "x,y": where the middle ring is, relative to the figure.
static func _unlock(body: Node2D, offset_text: String) -> void:
	var parts: PackedStringArray = offset_text.split(",")
	var center := Vector2(float(parts[0]), float(parts[1])) if parts.size() == 2 else Vector2(0, -24)
	var fx := _vfx(body)
	for i in 3:
		AudioManager.play_sound("ui_click", 0.7)
		fx.spawn("light_hit", body.global_position + center + Vector2((i - 1) * 9, 0), Color(0.75, 0.85, 1.0))
		if not await _wait(body, 0.35):
			return
	AudioManager.play_sound("chest_open", 0.7)
	await _quake(body, 0.25, 1.0)


## Steps in the player's way with a clank of weapons (e.g. guards crossing their spears).
static func _block(body: Node2D) -> void:
	var target := body.get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return
	_face_player(body)
	var toward: Vector2 = (target.global_position - body.global_position).normalized()
	var step := body.create_tween()
	step.tween_property(body, "global_position", body.global_position + toward * 6.0, 0.15)
	await step.finished
	AudioManager.play_sound("anvil_miss", 0.6)
	_vfx(body).spawn("block", body.global_position + toward * 10.0 + Vector2(0, -14), Color.WHITE)
	await _wait(body, 0.3)


## Pushes something heavy open in front of it (e.g. the wings of a door): two shoves, a creak.
static func _push(body: Node2D, figure: Node2D) -> void:
	if figure == null:
		return
	var home: Vector2 = figure.position
	for i in 2:
		var shove := body.create_tween()
		shove.tween_property(figure, "position", home + Vector2(0, -3), 0.15)
		shove.tween_property(figure, "position", home, 0.2)
		await shove.finished
	AudioManager.play_sound("door", 0.8)
	_vfx(body).spawn("dodge", body.global_position + Vector2(0, -24), Color(0.9, 0.95, 1.0))
	await _wait(body, 0.3)


## Water splashes and glitters around the figure (e.g. the first water through Kesh's pipe).
static func _splash(body: Node2D) -> void:
	var fx := _vfx(body)
	AudioManager.play_sound("quench_hiss", 0.5)
	for i in 6:
		fx.spawn("water_hit" if i % 2 == 0 else "light_hit", body.global_position + Vector2(randf_range(-40, 40), randf_range(-24, 8)),
				Color(0.6, 0.9, 1.0))
		if not await _wait(body, 0.18):
			return


## Shadows crawl out around the figure and spread downwards (e.g. hellhounds out of the gate).
static func _shadows(body: Node2D) -> void:
	var fx := _vfx(body)
	AudioManager.play_sound("skill_used", 0.7)
	for i in 7:
		var at := body.global_position + Vector2(randf_range(-50, 50), 10 + i * 9)
		fx.spawn("area_shadow" if i % 2 == 0 else "dark_hit", at, Color(0.55, 0.3, 0.75))
		if not await _wait(body, 0.2):
			return


## Shakes with laughter: quick little bobs.
static func _laugh(figure: Node2D) -> void:
	if figure == null:
		return
	var home: Vector2 = figure.position
	for i in 10:
		figure.position = home + Vector2(0, -1 if i % 2 == 0 else 0)
		if not await _wait(figure, 0.08):
			return
	figure.position = home


## The item goes to the mouth, tips up (a few sips) and is empty.
static func _drink(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y))
	if sprite == null:
		return
	var up := body.create_tween()
	up.tween_property(sprite, "position", Vector2(MOUTH.x * side, MOUTH.y), 0.35)
	up.tween_property(sprite, "rotation", -1.6 * side, 0.3)
	await up.finished
	for i in 3:
		AudioManager.play_sound("plant_pick", 0.35)
		if not await _wait(body, 0.25) or not is_instance_valid(sprite):
			return
	var away := body.create_tween()
	away.tween_property(sprite, "rotation", 0.0, 0.2)
	away.parallel().tween_property(sprite, "position", Vector2(HAND.x * side, HAND.y), 0.25)
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


## The item slips from the hands, falls to the ground with a bump and lies there a moment.
static func _drop(body: Node2D, item: String, side: float) -> void:
	var sprite := _item_sprite(body, item, Vector2(HAND.x * side, HAND.y))
	if sprite == null:
		return
	var fall := body.create_tween()
	fall.tween_property(sprite, "position:y", -2.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(sprite, "rotation", 0.8 * side, 0.28)
	fall.tween_property(sprite, "position:y", -5.0, 0.08)
	fall.tween_property(sprite, "position:y", -2.0, 0.08)
	await fall.finished
	if not is_instance_valid(sprite):
		return
	AudioManager.play_sound("step", 0.6)
	_vfx(body).spawn("dodge", sprite.global_position + Vector2(0, 2), Color(0.8, 0.75, 0.6))
	if not await _wait(body, 0.9) or not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	away.tween_property(sprite, "modulate:a", 0.0, 0.3)
	away.tween_callback(sprite.queue_free)
	await away.finished


## A hand goes up for a spell, but only a grey puff comes out.
static func _fizzle(body: Node2D, side: float) -> void:
	var fx := _vfx(body)
	var hand: Vector2 = body.global_position + Vector2(9 * side, -26)
	for i in 2:
		AudioManager.play_sound("ui_click", 0.3)
		fx.spawn("dodge", hand + Vector2(0, -3 * i), Color(0.6, 0.6, 0.6))
		if not await _wait(body, 0.45):
			return
	await _wait(body, 0.3)


## Lies down on its side and stays there; little "z" rise above it.
static func _sleep(body: Node2D, figure: Node2D, side: float) -> void:
	if figure == null:
		return
	var tween := body.create_tween()
	tween.tween_property(figure, "rotation", PI / 2.0 * side, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(figure, "position:y", figure.position.y + 8.0, 0.5)
	await tween.finished
	for i in 3:
		if not await _wait(body, 0.35):
			return
		var z := Label.new()
		z.text = "z"
		z.add_theme_font_size_override("font_size", 8 + i * 2)
		z.modulate = Color(0.85, 0.9, 1.0)
		z.position = Vector2(4 + 4 * i, -18 - 2 * i)
		z.z_index = 2
		body.add_child(z)
		var rise := z.create_tween()
		rise.tween_property(z, "position:y", z.position.y - 14.0, 1.2)
		rise.parallel().tween_property(z, "modulate:a", 0.0, 1.2)
		rise.tween_callback(z.queue_free)


## The item lies in front of the figure; a finger (a glint) runs across it from left to right.
static func _trace(body: Node2D, item: String) -> void:
	var sprite := _item_sprite(body, item, Vector2(0, -6))
	if sprite == null:
		return
	sprite.scale = Vector2(0.9, 0.9)
	var fx := _vfx(body)
	for i in 4:
		AudioManager.play_sound("ui_click", 0.25)
		fx.spawn("light_hit", sprite.global_position + Vector2(-8 + i * 5, -2 + (i % 2) * 3), Color(1, 0.95, 0.8))
		if not await _wait(body, 0.3):
			return
	if not is_instance_valid(sprite):
		return
	var away := body.create_tween()
	away.tween_interval(0.2)
	away.tween_property(sprite, "modulate:a", 0.0, 0.25)
	away.tween_callback(sprite.queue_free)
	await away.finished


## Something breaks out of sight with a crack: splinters rain down, the camera shakes.
static func _crash(body: Node2D) -> void:
	var fx := _vfx(body)
	var center: Vector2 = _camera_center(body)
	AudioManager.play_sound("wood_break", 0.9)
	_quake(body, 0.4, 3.0)
	for i in 7:
		var at := center + Vector2(randf_range(-90, 90), -100 + i * 22)
		fx.spawn("impact" if i % 2 == 0 else "dodge", at, Color(0.85, 0.7, 0.5))
		if i == 3:
			AudioManager.play_sound("wood_break", 0.6)
		if not await _wait(body, 0.12):
			return
	await _wait(body, 0.3)


## Walks away from the player (or the figure's own way) and is gone.
static func _run_off(body: Node2D) -> void:
	if body.has_method("run_off"):
		await body.call("run_off")
		return
	var target := body.get_tree().get_first_node_in_group(&"player") as Node2D
	var away: Vector2 = Vector2.RIGHT
	if target and target != body:
		away = (body.global_position - target.global_position).normalized()
	var walk := body.create_tween()
	walk.tween_property(body, "global_position", body.global_position + away * 120.0, 1.2)
	walk.parallel().tween_property(body, "modulate:a", 0.0, 1.2).set_delay(0.6)
	await walk.finished
	if is_instance_valid(body):
		body.hide()
		body.modulate.a = 1.0
