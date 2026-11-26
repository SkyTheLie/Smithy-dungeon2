class_name DesertMapWindow
extends PanelContainer
## Window with the sand map of the desert (DesertMapView): the ways the player has walked, as rows
## of arrows. Opens with a right click on the map in the inventory (Events.desert_map_requested,
## see ItemSlotUI); its size follows the longest route.

@onready var _view: DesertMapView = %MapView
@onready var _legend: Label = %Legend


func _ready() -> void:
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	var rows: Array[Dictionary] = _view.get_rows()
	var longest: int = 0
	for row in rows:
		longest = maxi(longest, (row["moves"] as Array).size())
	_view.custom_minimum_size = Vector2(maxf(240.0, 12.0 + DesertMapView.NAME_WIDTH * 2.0 + longest * DesertMapView.STEP_WIDTH),
			maxf(28.0, 12.0 + rows.size() * DesertMapView.ROW_HEIGHT))
	_view.queue_redraw()
	_legend.text = Language.translate("Jeder Pfeil ist ein Schritt, den du gegangen bist. Wer vom Weg abkommt, steht wieder am Schild.") \
			+ ("\nVerlaufen: %d-mal" % GameState.desert.lost_count if GameState.desert.lost_count > 0 else "")
	reset_size()
