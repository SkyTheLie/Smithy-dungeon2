class_name HallPlaqueMenu
extends StationMenu
## The plaque in the hall of fame (House "hall_of_fame"): how many trophies stand in the hall, the
## reputation they bring each morning, the player's title, both tournament ranks (RP) and all titles.


func _ready() -> void:
	super()
	remove_from_group(QUICK_MOVE_GROUP)
	visibility_changed.connect(_refresh)


## Text of the plaque (also for tests).
static func describe() -> String:
	var house: House = GameState.house
	var data: Dictionary = House.get_hall_data()
	var lines: Array[String] = []
	var trophies: int = house.count_hall_trophies()
	lines.append(Language.translate("Pokale in der Halle: %d") % trophies)
	lines.append(Language.translate("Ruf jeden Morgen: +%d (zählt bis %d Pokale)") % [house.get_hall_reputation(),
			int(data.get("max_trophies_counted", 14))])
	var ranking: TournamentRanking = GameState.ranking
	var title: String = ranking.get_title()
	lines.append(Language.translate("Titel: %s") % (title if not title.is_empty() else Language.translate("noch keiner")))
	for type: String in TournamentRanking.TYPES:
		var counts: Array = ranking.get_counts(type)
		lines.append(Language.translate("%s: %s, %d RP (%d Turniere, %d Siege)") % [Language.translate(TournamentRanking.TYPE_NAMES[type]),
				ranking.get_rank_name(type), ranking.get_points(type), int(counts[0]), int(counts[1])])
	var titles: Array[String] = []
	for entry: Dictionary in ranking.get_titles():
		titles.append(str(entry["title"]))
	if not titles.is_empty():
		lines.append(Language.translate("Alle Titel: %s") % ", ".join(titles))
	if trophies == 0:
		lines.append(Language.translate("Drück B und stell deine Pokale aus dem Hauslager hier auf."))
	return "\n".join(lines)


func _refresh() -> void:
	if visible:
		%TextLabel.text = describe()
