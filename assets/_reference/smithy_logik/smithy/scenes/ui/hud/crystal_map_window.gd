class_name CrystalMapWindow
extends PanelContainer
## Window with the crystal map (CrystalMapView) and a legend: how many map pieces the player has and
## which element crystals are drawn on them. Opens with a right click on the map in the inventory
## (Events.crystal_map_requested, see ItemSlotUI).

@onready var _view: CrystalMapView = %MapView
@onready var _legend: Label = %Legend


func _ready() -> void:
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	_view.queue_redraw()
	var lines: Array[String] = [Language.translate("Kartenteile: %d von %d") % [CrystalMapView.count_pieces(), CrystalMapView.total_pieces()]]
	for crystal: Dictionary in CrystalMapView.shown_crystals():
		var state: String = ""
		if CrystalMapView.flag_set(str(crystal.get("gone_flag", ""))):
			state = Language.translate(" (geraubt)")
		elif CrystalMapView.is_owned(crystal):
			state = Language.translate(" (gefunden)")
		var element: String = str(crystal["name"])
		# German: "Kristall des Feuers" / "Kristall der Erde"; other languages: "{element}" pattern ("Fire Crystal").
		var default_title: String = Language.translate("Kristall ") + (Language.translate("des ") + element + "s" if element != Language.translate("Erde") else Language.translate("der Erde"))
		if not Language.is_base():
			default_title = Language.translate("{element}-Kristall").format({"element": Language.translate(element)})
		var title: String = Language.translate(str(crystal.get("title", default_title)))
		lines.append("%s: %s%s" % [Language.translate(str(crystal.get("place", ""))), title, state])
	_legend.text = "\n".join(lines)
