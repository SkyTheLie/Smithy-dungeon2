class_name Lamplighter
extends Node2D
## The lamplighter of the dark city: walks his round through the streets (`route`, a loop of
## points, straight pieces only), and wherever a StreetLantern has gone out he stops, turns to it,
## and after a moment it burns again. He is in the group StreetLantern.LIGHTERS, the lantern calls
## reach_lantern() when he comes close. Not a physics body: he walks through the player like the
## market walkers. Look: a PixelLab resident sheet (`resident`, assets/sprites/residents/<id>.png,
## same layout and size as the other townsfolk); `look` (a kit figure) only if there is none.

const WALK_SPEED: float = 28.0
## Feet of a 48x48 frame, measured from its centre (see MarketWalker).
const FEET_FROM_CENTRE: float = 17.0
## Seconds he stands at a lantern before it burns.
const LIGHT_TIME: float = 1.4

## Id of a PixelLab resident (file name in assets/sprites/residents/ without .png).
@export var resident: String = ""
@export var look: Appearance
## The round (world points), walked again and again; the last point leads back to the first.
@export var route: PackedVector2Array = []

var _path: PackedVector2Array = PackedVector2Array()
var _next: int = 0
var _busy: bool = false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group(StreetLantern.LIGHTERS)
	_sprite = AnimatedSprite2D.new()
	var sheet: Texture2D = CharacterBaker.get_resident_sheet(resident)
	if sheet:
		_sprite.sprite_frames = CharacterBaker.make_frames(sheet)
	else:
		var figure: Appearance = look if look else Appearance.from_seed("finster_lamplighter", "")
		_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(figure))
		_sprite.scale = Vector2.ONE * figure.get_scale()
	_sprite.offset = Vector2(0.0, -FEET_FROM_CENTRE)
	add_child(_sprite)
	_sprite.play("idle_down")
	if not route.is_empty():
		global_position = route[0]
		_next = 1 % route.size()


## Called by a lantern that is out when he comes close: he stops and lights it.
func reach_lantern(lantern: StreetLantern) -> void:
	if _busy or lantern.lit:
		return
	_busy = true
	var to: Vector2 = lantern.global_position - global_position
	_sprite.play("idle_" + MarketWalker._direction_name(to))
	await get_tree().create_timer(LIGHT_TIME, false).timeout
	if not is_instance_valid(lantern) or not is_inside_tree():
		return
	lantern.light_up()
	_busy = false


func is_busy() -> bool:
	return _busy


func _process(delta: float) -> void:
	if _busy or route.size() < 2:
		return
	if _path.is_empty():
		_path = MarketWalker.straighten(global_position, PackedVector2Array([route[_next]]))
		_next = (_next + 1) % route.size()
	var to: Vector2 = _path[0] - global_position
	var step: float = WALK_SPEED * delta
	if to.length() <= step:
		global_position = _path[0]
		_path.remove_at(0)
		return
	global_position += to.normalized() * step
	_sprite.play("walk_" + MarketWalker._direction_name(to))
