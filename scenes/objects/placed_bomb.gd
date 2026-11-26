class_name PlacedBomb
extends Node3D
## A bomb the player drops (E / right mouse button): blinks for FUSE seconds, then explodes. Hurts
## enemies, breaks rocks and also hurts the player if they stand too close. Bigger with
## "bomb_size"; with "bomb_ring" it shoots fireballs all around. A blinking red light and a red
## ring on the floor (the blast radius) show where it is.

const FUSE: float = 1.6
const RADIUS: float = 2.3
const DAMAGE: float = 8.0

var dungeon: Dungeon

var _sprite: Sprite3D
var _light: OmniLight3D
var _time: float = 0.0


func _ready() -> void:
	_sprite = Fx.billboard(Pickup.icon("bomb"), 0.8)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.position.y = 0.4
	add_child(_sprite)
	# A red light that blinks with the fuse, and a red ring on the floor as big as the blast,
	# so the bomb can be seen even when it is not in view.
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.25, 0.15)
	_light.omni_range = 3.0
	_light.position.y = 0.6
	add_child(_light)


func _physics_process(delta: float) -> void:
	# The ring on the first frame: by then the bomb stands where it was dropped.
	if _time == 0.0 and dungeon:
		Fx.marker(dungeon.effects, global_position, RADIUS * dungeon.run.stats.bomb_size, FUSE)
	_time += delta
	# Blinks faster and faster.
	var blink: float = lerpf(4.0, 16.0, _time / FUSE)
	var lit: bool = sin(_time * blink) > 0.0
	_sprite.modulate = Color(1, 0.4, 0.3) if lit else Color.WHITE
	_light.light_energy = 2.0 if lit else 0.4
	_sprite.scale = Vector3.ONE * (1.0 + _time / FUSE * 0.3)
	if _time >= FUSE:
		if dungeon:
			var size: float = dungeon.run.stats.bomb_size
			dungeon.explode(global_position, RADIUS * size, DAMAGE * size, true)
			# Feuerring: fireballs fly out all around.
			if dungeon.run.stats.has("bomb_ring"):
				var count: int = int((Content.player().get("effects", {}) as Dictionary).get("bomb_ring", 8))
				for i in count:
					var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / count)
					dungeon.spawn_projectile(global_position + Vector3(0, 0.6, 0), direction, dungeon.run.stats, 0.0, false, [])
		queue_free()
