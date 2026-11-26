class_name FinsterFog
extends Node2D
## Fog over the whole dark city (finster_city.tscn): you see clearly only around yourself and
## around burning lights, further away the houses fade into the drifting fog (finster_fog.gdshader).
## Every NightLight of the scene is a light; one that is out (dim 0, a StreetLantern that went out)
## clears nothing. Nodes in the group CLEAR_GROUP clear their own spot: get_fog_clearing() returns
## Vector3(x, y, radius) in world coordinates, radius 0 = nothing (SneakGuard: where his cone looks,
## so sneaking stays fair). During cutscenes the fog thins out so the story stays visible.
## Draws one rect over `map_rect`, above the world (z_index), below the HUD (CanvasLayer).

const MAX_HOLES: int = 24
const CLEAR_GROUP: StringName = &"fog_clear"
## Only lights this close to the player are passed to the shader.
const LIGHT_RANGE: float = 420.0
## How fast the fog thins / comes back (share per second).
const THIN_SPEED: float = 0.8
const CUTSCENE_THIN: float = 0.6

## Area the fog covers (world), the ground picture.
@export var map_rect: Rect2 = Rect2(-512, -640, 1024, 1024)
## Clear radius around the player.
@export var player_radius: float = 92.0
## Clear radius of a light at texture_scale 1.
@export var light_radius: float = 58.0
## How much a light clears (1 = all, less leaves some fog glowing in its light).
@export var light_strength: float = 0.75

var _lights: Array[NightLight] = []
var _clearers: Array[Node] = []
var _holes: PackedVector4Array = PackedVector4Array()
var _thin: float = 0.0
var _player: Node2D


func _ready() -> void:
	_holes.resize(MAX_HOLES)
	_collect.call_deferred()


func _collect() -> void:
	var scene: Node = owner if owner else get_parent()
	for light in scene.find_children("*", "PointLight2D", true, false):
		if light is NightLight:
			_lights.append(light as NightLight)
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	_clearers = get_tree().get_nodes_in_group(CLEAR_GROUP)


func _draw() -> void:
	draw_rect(map_rect, Color.WHITE)


func _process(delta: float) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var center: Vector2 = _player.global_position + Vector2(0, -14) if is_instance_valid(_player) else map_rect.get_center()
	var count: int = 0
	_holes[count] = Vector4(center.x, center.y, player_radius, 1.0)
	count += 1
	for node in _clearers:
		if count >= MAX_HOLES:
			break
		if not is_instance_valid(node) or not (node as CanvasItem).is_visible_in_tree():
			continue
		var spot: Vector3 = node.call("get_fog_clearing")
		if spot.z > 0.0:
			_holes[count] = Vector4(spot.x, spot.y, spot.z, 1.0)
			count += 1
	for light in _lights:
		if count >= MAX_HOLES:
			break
		if not is_instance_valid(light) or not light.is_visible_in_tree() or light.dim <= 0.0:
			continue
		var at: Vector2 = light.global_position
		if at.distance_squared_to(center) > LIGHT_RANGE * LIGHT_RANGE:
			continue
		_holes[count] = Vector4(at.x, at.y, light_radius * light.texture_scale, light_strength * light.dim)
		count += 1
	var target: float = CUTSCENE_THIN if GameState.is_cutscene_running() else 0.0
	_thin = move_toward(_thin, target, THIN_SPEED * delta)
	mat.set_shader_parameter("holes", _holes)
	mat.set_shader_parameter("hole_count", count)
	mat.set_shader_parameter("thin", _thin)


## How much the fog is thinned out right now (0 = full fog, CUTSCENE_THIN during cutscenes).
func get_thinning() -> float:
	return _thin
