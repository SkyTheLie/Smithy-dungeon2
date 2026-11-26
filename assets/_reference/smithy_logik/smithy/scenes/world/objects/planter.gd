class_name Planter
extends Station
## A plant pot in the greenhouse (house.json furniture with "planter", placed by FurnitureLayer).
## E opens its window (PlanterMenu): fill in soil, plant seeds, scatter ash, harvest. It shows the
## soil and a plant per field; the state lives in GameState.garden under the pot's `uid` (Garden).
## The picture of the pot is the Sprite2D FurnitureLayer adds as first child; the geometry here
## must match assets/_reference/greenhouse_1029/make_planters.py.

const CELL := Vector2(14, 8)
const SIDE: float = 4.0
const TOP: float = 3.0
const FRONT: float = 19.0
const STAGE_TEXTURES: Array[Texture2D] = [
	null,
	preload("res://assets/sprites/plants/sprout.png"),
	preload("res://assets/sprites/plants/growing.png"),
]
const MENU_SCENE: PackedScene = preload("res://scenes/ui/menus/planter_menu.tscn")

## Key of this pot in GameState.garden (House.placed "uid").
var uid: String = ""
## house.json furniture id (e.g. planter_2x2).
var furniture_id: String = ""
## Fields per side.
var size: int = 2

var _soil_sprite: Sprite2D
var _plants: Array[Sprite2D] = []
var _menu: PlanterMenu
## What the pot showed last (soil + stage of every field), to redraw only on changes.
var _shown: String = ""


## Called by FurnitureLayer before the pot enters the tree.
func setup(pot_uid: String, id: String) -> void:
	uid = pot_uid
	furniture_id = id
	size = maxi(1, House.get_planter_size(id))


func _ready() -> void:
	super()
	var picture_size := Vector2(size * CELL.x + 2.0 * SIDE, TOP + size * CELL.y + FRONT)
	_add_interaction_area(picture_size)
	_soil_sprite = Sprite2D.new()
	_soil_sprite.texture = load("res://assets/sprites/furniture/greenhouse/planter_%dx%d_soil.png" % [size, size])
	_soil_sprite.centered = false
	_soil_sprite.offset = Vector2(-picture_size.x / 2.0, -picture_size.y)
	add_child(_soil_sprite)
	for field in size * size:
		var plant := Sprite2D.new()
		plant.position = get_field_position(field)
		plant.hide()
		add_child(plant)
		_plants.append(plant)
	interacted.connect(_open_menu)
	player_left.connect(func() -> void:
		if _menu and _menu.visible:
			_menu.close())
	_refresh()


## Bottom centre of a field (where its plant stands), relative to the pot.
func get_field_position(field: int) -> Vector2:
	var picture_size := Vector2(size * CELL.x + 2.0 * SIDE, TOP + size * CELL.y + FRONT)
	var column: int = field % size
	@warning_ignore("integer_division")
	var row: int = field / size
	return Vector2(-picture_size.x / 2.0 + SIDE + (column + 0.5) * CELL.x,
			-picture_size.y + TOP + (row + 1) * CELL.y - 1.0)


func get_bed_id(field: int) -> String:
	return Garden.get_bed_id(uid, field)


func _add_interaction_area(picture_size: Vector2) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = picture_size + Vector2(24, 24)
	shape.shape = rect
	shape.position = Vector2(0, -picture_size.y / 2.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_interaction_area_body_entered)
	area.body_exited.connect(_on_interaction_area_body_exited)


func _open_menu() -> void:
	if _menu == null:
		_menu = MENU_SCENE.instantiate()
		add_child(_menu)
	_menu.open_for(self)


func _process(_delta: float) -> void:
	# The day changes while sleeping and the menu changes fields: cheap to check every frame.
	if _get_state() != _shown:
		_refresh()


func _get_state() -> String:
	var garden: Garden = GameState.garden
	var parts: Array[String] = [str(garden.has_soil(uid))]
	for field in size * size:
		var texture: Texture2D = get_field_texture(get_bed_id(field))
		parts.append(texture.resource_path if texture else "")
	return ",".join(parts)


func _refresh() -> void:
	_shown = _get_state()
	var garden: Garden = GameState.garden
	_soil_sprite.visible = garden.has_soil(uid)
	for field in _plants.size():
		var texture: Texture2D = get_field_texture(get_bed_id(field))
		var plant: Sprite2D = _plants[field]
		plant.texture = texture
		plant.visible = texture != null
		if texture:
			plant.offset = Vector2(0, -texture.get_height() / 2.0)


## Picture of a field: the plant's own growth stage (seedling to bud, by progress), the shared
## sprout or growing plant, or the bloom (null = empty).
static func get_field_texture(bed: String) -> Texture2D:
	var garden: Garden = GameState.garden
	var day: int = GameState.day_cycle.day
	var stage: Garden.Stage = garden.get_stage(bed, day)
	if stage == Garden.Stage.EMPTY:
		return null
	var seed_item: ItemData = garden.get_seed(bed)
	if stage == Garden.Stage.READY:
		return seed_item.bloom_texture if seed_item.bloom_texture else seed_item.grows_into.icon
	var stages: Array[Texture2D] = seed_item.stage_textures
	if not stages.is_empty():
		return stages[mini(stages.size() - 1, int(garden.get_progress(bed, day) * stages.size()))]
	return STAGE_TEXTURES[stage]
