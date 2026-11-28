class_name Chest
extends StaticBody3D
## A chest in a room (data/chests.json "kinds"): a wooden chest opens when the player walks against
## it, a lock chest and a vault chest need a key (any key). A bomb breaks a wooden chest (the
## loot falls out), blows a lock chest open (some loot is lost) and bounces off a vault chest
## (clank, the runes flash). Blocks walking and shots like a rock. The Dungeon decides what falls
## out (Dungeon.open_chest); this node only shows and sounds.

## Walking this close (metres between the middles) touches it.
const TOUCH: float = 1.2
const RADIUS: float = 0.45

## Id in chests.json "kinds" (wood, lock, vault) and its values.
var kind: String = ""
var data: Dictionary = {}
var opened: bool = false

var _sprite: Sprite3D
var _glow: MeshInstance3D
var _time: float = 0.0
var _flash_left: float = 0.0


func setup(kind_id: String) -> void:
	kind = kind_id
	data = (Content.get_file("chests").get("kinds", {}) as Dictionary).get(kind_id, {})


func _ready() -> void:
	collision_layer = RoomBuilder.LAYER_ROCKS
	collision_mask = 0
	var height: float = float(data.get("height", 0.8))
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS
	cylinder.height = height
	shape.shape = cylinder
	shape.position.y = height / 2.0
	add_child(shape)
	var texture := load(String(data.get("texture", ""))) as Texture2D
	if texture:
		_sprite = Fx.billboard(texture, height)
		_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_sprite.shaded = true
		_sprite.position.y = height / 2.0
		_sprite.modulate = _tint()
		add_child(_sprite)
	var glow: Array = data.get("glow", [])
	if glow.size() == 3:
		_glow = Fx.halo(Color(float(glow[0]), float(glow[1]), float(glow[2]), 0.45), height * 1.8)
		_glow.position.y = height / 2.0
		add_child(_glow)


func _process(delta: float) -> void:
	_time += delta
	_flash_left = maxf(0.0, _flash_left - delta)
	if _glow and not opened:
		# Runes hum softly; a bomb makes them flare up.
		_glow.scale = Vector3.ONE * (1.0 + 0.08 * sin(_time * 3.0) + 0.6 * _flash_left)


## Lock and vault chests need a key.
func needs_key() -> bool:
	return bool(data.get("key", false))


## What a bomb does: "break" (opens it, wood breaks, lock loses some loot) or "none" (vault).
func bomb_effect() -> String:
	return String(data.get("bomb", "break"))


## Shows it open (the Dungeon drops the loot). `with_key`: the lock clicks first.
func show_open(with_key: bool) -> void:
	opened = true
	AudioManager.play_sound_at("chest_unlock" if with_key else "chest_open", global_position, get_parent() as Node3D, randf_range(0.95, 1.05))
	if with_key:
		AudioManager.play_sound_at("chest_open", global_position, get_parent() as Node3D, randf_range(0.95, 1.05))
	var open_texture := load(String(data.get("open_texture", ""))) as Texture2D
	if _sprite and open_texture:
		var height: float = float(data.get("height", 0.8))
		_sprite.texture = open_texture
		_sprite.pixel_size = height * 1.15 / float(maxi(1, open_texture.get_height()))
		_sprite.position.y = height * 1.15 / 2.0
	if _glow:
		_glow.queue_free()
		_glow = null
	Fx.puff(get_parent() as Node3D, global_position + Vector3(0, 0.6, 0), "spark", 0.7)


## A bomb broke it apart (wood, lock): splinters, the picture stays as an open chest.
func show_blasted() -> void:
	AudioManager.play_sound_at("chest_break", global_position, get_parent() as Node3D, randf_range(0.85, 1.0))
	if _sprite:
		Fx.shards(get_parent() as Node3D, global_position, _sprite.texture, float(data.get("height", 0.8)))
	show_open(false)


## A bomb bounced off (vault): clank, sparks, the runes flare.
func show_bounce() -> void:
	_flash_left = 0.5
	AudioManager.play_sound_at("chest_clank", global_position, get_parent() as Node3D, randf_range(0.8, 0.9))
	Fx.puff(get_parent() as Node3D, global_position + Vector3(0, 0.5, 0), "spark", 0.9)


## Picture for the map while it is closed (null once open).
func map_icon() -> Texture2D:
	if opened or _sprite == null:
		return null
	return _sprite.texture


func _tint() -> Color:
	var tint: Array = data.get("tint", [1, 1, 1])
	return Color(float(tint[0]), float(tint[1]), float(tint[2]))
