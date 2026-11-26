class_name DefenseCrystal
extends Node2D
## A summoning crystal lying near the smithy in the forge defense. The hammer breaks it after
## `hp` hits (`hit`); then it disappears and the game calls its units at its place (signal
## `broken`). Enemies leave it alone.
## Looks: a soft light in its element's colour pulses behind it, every hit lets cracks grow over
## it (fixed for each crystal, the more hits taken the more cracks show), and a hit flashes it.

signal broken(crystal: DefenseCrystal)

const CENTER := Vector2(0, -20)
const CRACKS: int = 6
const CRACK_COLOR := Color(1.0, 1.0, 1.0, 0.85)
const CRACK_SHADOW := Color(0.1, 0.05, 0.1, 0.8)
const HALO_SIZE: float = 54.0

## Item id (defense.json crystals), e.g. holy_fire_crystal.
var crystal_id: String = ""
var hp: int = 1
var max_hp: int = 1
## Its element's colour (DefenseRun.crystal_color).
var color: Color = Color.WHITE
## The soft light texture behind it (set by the game, shared).
var halo: Texture2D = null
## A boss's treasure chest instead of a crystal: the relic it holds (the game shows it when the
## hammer breaks the chest open), "" = a crystal.
var relic_id: String = ""

## Each crack: a short jagged line from near the middle outwards (made once in setup).
var _cracks: Array[PackedVector2Array] = []
var _time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _crack_layer: Node2D = $Cracks


func setup(id: String, picture: Texture2D, life: int, tint: Color = Color.WHITE, light: Texture2D = null) -> void:
	crystal_id = id
	hp = maxi(life, 1)
	max_hp = hp
	color = tint
	halo = light
	$Sprite.texture = picture
	_cracks.clear()
	for i in CRACKS:
		var angle: float = float(i) / CRACKS * TAU + randf_range(-0.4, 0.4)
		var line := PackedVector2Array([CENTER + Vector2.from_angle(angle) * 2.0])
		for step in range(1, 4):
			line.append(CENTER + Vector2.from_angle(angle + randf_range(-0.5, 0.5)) * (2.0 + step * 3.5))
		_cracks.append(line)


func _ready() -> void:
	_crack_layer.draw.connect(_draw_cracks)


func is_intact() -> bool:
	return hp > 0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## The pulsing light behind the crystal.
func _draw() -> void:
	if halo == null:
		return
	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
	var light_size: float = HALO_SIZE * (0.85 + 0.25 * pulse)
	draw_texture_rect(halo, Rect2(CENTER - Vector2(light_size, light_size) / 2.0, Vector2(light_size, light_size)), false,
			Color(color, 0.45 + 0.3 * pulse))


## Cracks over the picture: as many as hits taken (all of them just before it breaks).
func _draw_cracks() -> void:
	var shown: int = int(ceil(float(max_hp - hp) / float(max_hp) * CRACKS))
	for i in mini(shown, _cracks.size()):
		_crack_layer.draw_polyline(_cracks[i], CRACK_SHADOW, 2.0)
		_crack_layer.draw_polyline(_cracks[i], CRACK_COLOR, 1.0)


## A hammer hit. Returns true if this hit broke it.
func hit(amount: int) -> bool:
	if not is_intact() or amount <= 0:
		return false
	hp -= amount
	_crack_layer.queue_redraw()
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	if hp > 0:
		return false
	broken.emit(self)
	flash.kill()
	var burst := create_tween()
	burst.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
	burst.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	burst.tween_callback(queue_free)
	return true
