class_name ArenaCelebration
extends RefCounted
## What the arenas use to celebrate a winner: confetti and small hops. The hero ring
## (ArenaFightStage) and the smith arenas (SmithVictory) share it.


## Confetti falling down from a strip `width` wide (centred on its position); colours of the
## result window (TournamentResultWindow.confetti_colors).
static func make_confetti(width: float, amount: int = 90) -> CPUParticles2D:
	var confetti := CPUParticles2D.new()
	confetti.z_index = 20
	confetti.amount = amount
	confetti.lifetime = 2.6
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(width / 2.0, 4)
	confetti.direction = Vector2(0, 1)
	confetti.spread = 25.0
	confetti.initial_velocity_min = 20.0
	confetti.initial_velocity_max = 50.0
	confetti.gravity = Vector2(0, 60)
	confetti.angular_velocity_min = -180.0
	confetti.angular_velocity_max = 180.0
	confetti.scale_amount_min = 1.5
	confetti.scale_amount_max = 2.5
	confetti.color_initial_ramp = TournamentResultWindow.confetti_colors()
	return confetti


## `times` small jumps of `node`, starting after `delay` seconds (the tween belongs to the node).
static func hop(node: Node2D, times: int, delay: float, height: float = 7.0) -> Tween:
	var base: float = node.position.y
	var tween: Tween = node.create_tween()
	tween.tween_interval(delay)
	for i in times:
		tween.tween_property(node, "position:y", base - height, 0.16).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position:y", base, 0.16).set_ease(Tween.EASE_IN)
	return tween


## Every figure of the node "Crowd" of `scene` hops a few times (spectators of an arena).
static func cheer_crowd(scene: Node, times: int = 3) -> void:
	var crowd: Node = scene.get_node_or_null("Crowd") if scene else null
	if crowd == null:
		return
	for figure in crowd.get_children():
		if figure is Node2D and not figure is Sprite2D:
			hop(figure, times, randf_range(0.0, 0.5))
