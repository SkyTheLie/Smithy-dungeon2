class_name TournamentMenu
extends StationMenu
## The herald's desk on the tournament ground in Leonheim (SmithTournament): enter the tournament,
## start a round, hand in the finished piece, see who won the round, end the tournament.
## Other venues (Sylvaris) use the same window with their `venue` (economy.json "smith_tournament"
## "venues"; "intro_text" and "champion_text" there replace the texts of Leonheim).
## Below the intro: the smith rating and today's league tournament (TournamentRanking), entered with
## the league button (created here, next to "Antreten").

const TEXT_IDLE: String = "Das große Schmiedeturnier! Vier Runden, Schmied gegen Schmied. Ich sage, was geschmiedet wird, das Material liegt in der Vorratstruhe. Das bessere Stück gewinnt, wer schneller ist, bekommt etwas dazu.\nDeine Taschen bleiben draußen: Was du dabei hast, bekommst du nach dem Turnier zurück."
const TEXT_ROUND: String = "Runde %d von %d. Dein Gegner: %s.\nBist du bereit?"
const TEXT_RUNNING: String = "Aufgabe: %s\nDas Material liegt in der Vorratstruhe. Bring mir das fertige, abgekühlte Stück.\nZeit: %s"
const TEXT_UNKNOWN: String = "\nRezepte, die du nicht kanntest: %d (je -%d Punkte)"
const TEXT_WON_ROUND: String = "Du gewinnst die Runde!"
const TEXT_LOST_ROUND: String = "%s gewinnt die Runde."
const TEXT_CHAMPION: String = "Du hast das große Schmiedeturnier gewonnen!"
const TEXT_OUT: String = "Du bist ausgeschieden."

## Venue of this herald ("" = Leonheim, otherwise a key of "venues").
@export var venue: String = ""

@onready var _text_label: Label = %TextLabel
@onready var _primary_button: Button = %PrimaryButton
@onready var _secondary_button: Button = %SecondaryButton

var _tournament: SmithTournament = GameState.tournament
var _league_button: Button


func _ready() -> void:
	super()
	_league_button = Button.new()
	_league_button.focus_mode = Control.FOCUS_NONE
	_primary_button.add_sibling(_league_button)
	_league_button.pressed.connect(_on_league_pressed)
	GameState.ranking.changed.connect(_refresh)
	_primary_button.pressed.connect(_on_primary_pressed)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_tournament.changed.connect(_refresh)
	visibility_changed.connect(_refresh)


func _process(_delta: float) -> void:
	if visible and _tournament.state == SmithTournament.State.RUNNING:
		_refresh()


static func format_time(seconds: float) -> String:
	var whole: int = floori(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]


func _refresh() -> void:
	if not visible:
		return
	_tournament.select_venue(venue)
	var rounds: int = SmithTournament.get_rounds().size()
	_secondary_button.visible = true
	_primary_button.visible = true
	_primary_button.disabled = false
	_league_button.visible = false
	match _tournament.state:
		SmithTournament.State.IDLE:
			var blocker: String = _tournament.get_entry_blocker()
			_text_label.text = Language.translate(str(SmithTournament.settings().get("intro_text", TEXT_IDLE))) + ("\n" + blocker if not blocker.is_empty() else "")
			var fee: int = _tournament.get_entry_fee()
			_primary_button.text = Language.translate("Antreten (%d Gold)") % fee if fee > 0 else Language.translate("Antreten")
			_primary_button.disabled = not blocker.is_empty()
			_secondary_button.text = Language.translate("Später")
			if SmithTournament.settings().get("league_only", false):
				# League grounds of the cities (e.g. Sahrim): no great tournament here.
				_text_label.text = Language.translate(str(SmithTournament.settings().get("intro_text", TEXT_IDLE)))
				_primary_button.visible = false
			_refresh_league()
		SmithTournament.State.BETWEEN_ROUNDS:
			_text_label.text = Language.translate(TEXT_ROUND) % [_tournament.round_index + 1, rounds, _tournament.get_opponent_name()]
			_primary_button.text = Language.translate("Runde beginnen")
			_secondary_button.text = Language.translate("Aufgeben")
		SmithTournament.State.RUNNING:
			var text: String = Language.translate(TEXT_RUNNING) % [_tournament.get_task_name(), format_time(_tournament.elapsed)]
			if _tournament.unknown_recipes > 0 and _tournament.get_unknown_recipe_penalty() > 0:
				text += Language.translate(TEXT_UNKNOWN) % [_tournament.unknown_recipes, _tournament.get_unknown_recipe_penalty()]
			_text_label.text = text
			_primary_button.text = Language.translate("Abgeben")
			_primary_button.disabled = _tournament.find_piece() < 0
			_secondary_button.text = Language.translate("Aufgeben")
		SmithTournament.State.RESULT:
			_text_label.text = _result_text()
			_primary_button.text = Language.translate("Weiter")
			_secondary_button.visible = false
		SmithTournament.State.OVER:
			_text_label.text = Language.translate(str(SmithTournament.settings().get("champion_text", TEXT_CHAMPION))) if _tournament.champion else Language.translate(TEXT_OUT)
			if _tournament.last_result.get("gave_up", false) and _tournament.last_result.has("rating_change"):
				_text_label.text += "\n" + _rating_line(int(_tournament.last_result["rating_change"]))
			_primary_button.text = Language.translate("Turnier beenden")
			_secondary_button.visible = false


func _result_text() -> String:
	var result: Dictionary = _tournament.last_result
	var piece: InventorySlot = result["piece"]
	var lines: Array[String] = [
		Language.translate("Dein Stück: %s (%s)") % [piece.get_display_name(), format_time(result["seconds"])],
		Language.translate("Seltenheit und Qualität: %d") % result["quality"],
		Language.translate("Zeitbonus: +%d") % result["time_bonus"],
	]
	if result["penalty"] > 0:
		lines.append(Language.translate("Unbekannte Rezepte: -%d") % result["penalty"])
	lines.append(Language.translate("Zusammen: %d") % result["total"])
	lines.append("%s: %d + %d = %d" % [_tournament.get_opponent_name(), result["opponent_quality"],
			result["opponent_bonus"], result["opponent_total"]])
	lines.append(Language.translate(TEXT_WON_ROUND) if result["won"] else Language.translate(TEXT_LOST_ROUND) % _tournament.get_opponent_name())
	if result.has("rating_change"):
		lines.append(_rating_line(int(result["rating_change"])))
	return "\n".join(lines)


## The league part of the idle text and the league button (hidden where there are no leagues).
func _refresh_league() -> void:
	var ranking: TournamentRanking = GameState.ranking
	var info: String = ranking.describe("smith", venue)
	if info.is_empty():
		return
	_text_label.text += "\n\n" + info
	var today: int = ranking.get_today("smith", venue)
	_league_button.visible = true
	_league_button.text = Language.translate("%s (%d Gold)") % [TournamentRanking.league_name(today),
			TournamentRanking.get_entry_fee("smith", today)]
	var blocker: String = ranking.get_blocker("smith", venue)
	_league_button.disabled = not blocker.is_empty()
	_league_button.tooltip_text = blocker


func _rating_line(change: int) -> String:
	return Language.translate("Schmiede-Wertung: %d (%+d)") % [GameState.ranking.get_rating("smith"), change]


func _on_league_pressed() -> void:
	if _tournament.state == SmithTournament.State.IDLE and _tournament.enter_league():
		AudioManager.play_sound("coins")


func _on_primary_pressed() -> void:
	match _tournament.state:
		SmithTournament.State.IDLE:
			if _tournament.enter():
				AudioManager.play_sound("coins")
		SmithTournament.State.BETWEEN_ROUNDS:
			_tournament.start_round()
			close()
			GameState.show_message(Language.translate("Aufgabe: %s. Das Material liegt in der Vorratstruhe.") % _tournament.get_task_name())
		SmithTournament.State.RUNNING:
			_tournament.hand_in()
		SmithTournament.State.RESULT:
			_tournament.continue_after_result()
		SmithTournament.State.OVER:
			var prize: String = _tournament.finish()
			close()
			if not prize.is_empty():
				GameState.show_message(prize)


func _on_secondary_pressed() -> void:
	if _tournament.state in [SmithTournament.State.BETWEEN_ROUNDS, SmithTournament.State.RUNNING]:
		_tournament.give_up()
	else:
		close()
