class_name PrizeChoiceList
extends RefCounted
## Entries for the prizes a league winner still has to pick (TournamentRanking.get_pending): one
## line per tournament won, then one button per prize. Used by the tournament master in the halls
## (TournamentDeskMenu) and the crier of the arenas (HeroTournamentMenu).


## Adds the pending prizes to `box` (nothing if there are none). Returns true if there were any.
static func fill(box: Container) -> bool:
	var ranking: TournamentRanking = GameState.ranking
	var pending: Array[Dictionary] = ranking.get_pending()
	for index in pending.size():
		var entry: Dictionary = pending[index]
		var league: int = TournamentRanking.league_index(str(entry.get("league", "")))
		var header := Label.new()
		header.text = Language.translate("Siegerpreis der %s: Wähle einen.") % TournamentRanking.league_name(league)
		header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
		header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(header)
		var choices: Array = entry.get("choices", [])
		for choice in choices.size():
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text = TournamentRanking.describe_prize(str(choices[choice]))
			button.pressed.connect(_on_chosen.bind(index, choice))
			box.add_child(button)
	return not pending.is_empty()


static func _on_chosen(index: int, choice: int) -> void:
	var text: String = GameState.ranking.claim_prize(index, choice)
	if not text.is_empty():
		AudioManager.play_sound("coins")
		GameState.show_message(text)
