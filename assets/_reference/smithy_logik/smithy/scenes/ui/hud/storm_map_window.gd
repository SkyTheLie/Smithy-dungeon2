class_name StormMapWindow
extends PanelContainer
## Window with Fürst Ssarok's map of the storm paths (StormMapView): the ways to Sahrim and to the
## storm temple on papyrus, later the treasures. Opens with a right click on the map in the
## inventory (Events.storm_map_requested, see ItemSlotUI).

@onready var _view: StormMapView = %MapView


func _ready() -> void:
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if visible:
		_view.refresh()
		reset_size()
