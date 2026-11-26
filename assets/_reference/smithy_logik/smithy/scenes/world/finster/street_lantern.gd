class_name StreetLantern
extends Station
## A lantern of the foggy dark city (finster_city.tscn) that can go out. Looks like ThemedLantern
## (picture from its position, lamp towards the road); unlit it shows <picture>_off.png and its
## NightLight is out, so the fog (FinsterFog) closes in around it. The player lights it with E.
## Every node in the group LIGHTERS that comes within LIGHT_REACH lights it too: one with the method
## `reach_lantern(lantern)` (Lamplighter) does it itself, any other walker right away.
## A lit lantern goes out again after a while (a gust of wind), never while the player stands at it.
## Lit or not is not saved on purpose: on entering the map about OUT_AT_START of them are out.

signal lit_changed(is_lit: bool)

const GROUP: StringName = &"street_lanterns"
const LIGHTERS: StringName = &"lamp_lighters"
## How close (feet to feet) a lighter has to come.
const LIGHT_REACH: float = 36.0
## Seconds a lantern burns before it may go out (random in this range).
const BURN_TIME := Vector2(70.0, 200.0)
const OUT_AT_START: float = 0.35
const CHECK_INTERVAL: float = 0.3
## Seconds the flame takes to die down or to catch.
const FADE_TIME: float = 0.5
const OFF_SUFFIX: String = "_off.png"
## Tip the first time the player stands at a lantern that is out (hints.json).
const HINT: String = "finster_fog"

## Pictures of the lantern, feet at the bottom edge (see ThemedLantern).
@export var variants: Array[Texture2D] = []
## Which way the lamp hangs: "west", "east", "south", "north".
@export var facing: String = ""
## Pictures with a direction: path with %d (variant) and %s (`facing`).
@export var facing_path: String = ""

var lit: bool = true
var _burn_left: float = 0.0
var _check_left: float = 0.0
var _lit_texture: Texture2D
var _off_texture: Texture2D
var _fade: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _light: NightLight = $NightLight


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	add_to_group(GROUP)
	_lit_texture = ThemedLantern.pick_texture(position, variants, facing, facing_path)
	var off_path: String = _lit_texture.resource_path.replace(".png", OFF_SUFFIX)
	_off_texture = load(off_path) if ResourceLoader.exists(off_path) else _lit_texture
	_sprite.offset = Vector2(0, -_lit_texture.get_height() / 2.0)
	_light.position = LightPoints.lamp(_lit_texture, _light.position)
	_set_lit(randf() >= OUT_AT_START, false)


func wants_interact() -> bool:
	return super() and not lit


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and wants_interact() and is_nearest_interactable(self):
		light_up()
		get_viewport().set_input_as_handled()


## Lights the lantern (E, a lighter); nothing if it burns already.
func light_up() -> void:
	if not lit:
		_set_lit(true, true)
		AudioManager.play_sound("quench_hiss", 1.8)


## The flame goes out (a gust of wind).
func blow_out() -> void:
	if lit:
		_set_lit(false, true)


func _set_lit(on: bool, animate: bool) -> void:
	lit = on
	_burn_left = randf_range(BURN_TIME.x, BURN_TIME.y)
	_sprite.texture = _lit_texture if on else _off_texture
	if _fade:
		_fade.kill()
	if animate:
		_fade = create_tween()
		_fade.tween_property(_light, "dim", 1.0 if on else 0.0, FADE_TIME)
	else:
		_light.dim = 1.0 if on else 0.0
	lit_changed.emit(on)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_INTERVAL
	if lit:
		_burn_left -= CHECK_INTERVAL
		if _burn_left <= 0.0:
			if _player_in_range:
				_burn_left = BURN_TIME.x * 0.25
			else:
				blow_out()
		return
	if _player_in_range:
		GameState.story.show_hint(HINT)
	for node: Node in get_tree().get_nodes_in_group(LIGHTERS):
		var walker := node as Node2D
		if walker == null or walker.global_position.distance_to(global_position) > LIGHT_REACH:
			continue
		if walker.has_method("reach_lantern"):
			walker.call("reach_lantern", self)
		else:
			light_up()
		return
