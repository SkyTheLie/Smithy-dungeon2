extends StationMenu
## Menu of the teleport crystal: the world map (CrystalMapView in teleport mode) with a glowing
## crystal on every place whose teleporter is awake (GameState.is_teleporter_built). Where each one
## stands comes from world_map.json "teleporters". Under the mouse the line below names the place;
## a click travels there. The place you are at and places closed at night are grey.
## Some regions have more than one teleporter (e.g. the edge of the desert and Sahrim).

@export var destinations: Array[TravelDestination] = []

@onready var _map: CrystalMapView = %MapView
@onready var _info: Label = %Info

## Destination id -> TravelDestination of the spots on the map.
var _shown: Dictionary = {}


func _ready() -> void:
	super()
	visibility_changed.connect(_on_visibility_changed)
	_map.spot_hovered.connect(_on_spot_hovered)
	_map.spot_pressed.connect(_on_spot_pressed)


func _on_visibility_changed() -> void:
	if visible:
		_build_spots()


func _build_spots() -> void:
	_shown.clear()
	var places: Dictionary = CrystalMapView.data().get("teleporters", {})
	var spots: Array[Dictionary] = []
	for destination in destinations:
		var id: String = String(destination.id)
		if not GameState.is_teleporter_built(id) or not places.has(id):
			continue
		_shown[id] = destination
		var at: Array = places[id].get("at", [0, 0])
		spots.append({"id": id, "at": Vector2(at[0], at[1]), "enabled": _can_travel(destination)})
	_map.set_spots(spots)
	_info.text = Language.translate("Wähle einen Teleporter auf der Karte.") if spots.size() > 1 \
			else Language.translate("Noch kein anderer Teleporter ist erwacht.")


func _can_travel(destination: TravelDestination) -> bool:
	return destination.scene_path != get_tree().current_scene.scene_file_path \
			and not GameState.is_blocked_at_night(destination.scene_path)


func _on_spot_hovered(spot_id: String) -> void:
	if not _shown.has(spot_id):
		_build_info_default()
		return
	var destination: TravelDestination = _shown[spot_id]
	var text: String = destination.display_name
	if destination.scene_path == get_tree().current_scene.scene_file_path:
		text += Language.translate(" (hier bist du)")
	elif GameState.is_blocked_at_night(destination.scene_path):
		text += " (%s)" % Language.translate(GameState.NIGHT_BLOCKED_MESSAGE)
	_info.text = text


func _build_info_default() -> void:
	_info.text = Language.translate("Wähle einen Teleporter auf der Karte.")


func _on_spot_pressed(spot_id: String) -> void:
	var destination: TravelDestination = _shown.get(spot_id)
	if destination == null or not _can_travel(destination):
		return
	hide()
	GameState.travel_to(destination.scene_path, destination.spawn_point)
