class_name TournamentMenu
extends StationMenu
## The herald's desk on the tournament ground in Leonheim (SmithTournament): enter the tournament,
## start a round, hand in the finished piece, see who won the round, end the tournament.
## Other venues (Sylvaris) use the same window with their `venue` (economy.json "smith_tournament"
## "venues"; "intro_text" and "champion_text" there replace the texts of Leonheim).
## League tournaments are entered at the tournament master of a tournament hall (TournamentDeskMenu);
## here the herald only runs their rounds. At the end of a league tournament the player goes back
## into the hall (SmithTournament.league_hall); before that the result window of the leagues
## shows place, rank points and prizes (TournamentResultWindow, the winner picks his prize there).
## The story tournament ends with the same window (place and prize, no rank points); after its
## victory the herald of Leonheim only points to the leagues (SmithTournament.is_league_only).

const TEXT_IDLE: String = "Das große Schmiedeturnier! Vier Runden, Schmied gegen Schmied. Ich sage, was geschmiedet wird, das Material liegt in der Vorratstruhe. Das bessere Stück gewinnt, wer schneller ist, bekommt etwas dazu.\nDeine Taschen bleiben draußen: Was du dabei hast, bekommst du nach dem Turnier zurück."
const TEXT_ROUND: String = "Runde %d von %d. Dein Gegner: %s.\nBist du bereit?"
const TEXT_LEAGUE_ROUND: String = "%s (Runde %d von %d). Dein Gegner: %s.\nBist du bereit?"
const TEXT_LEAGUE_ONLY: String = "\nAnmelden kannst du dich beim Turnierleiter in der Turnierhalle."
const TEXT_STORY_DONE: String = "Das große Schmiedeturnier hast du gewonnen. Jetzt geht es in den Ligen weiter: Schmied gegen Schmied, um Rang und Preise."
const TEXT_PLACE: String = "Platz 2! Erst im Finale verloren."
const TEXT_STRENGTH: String = "Dein Gegner schafft meist %s bis %s Punkte (Seltenheit und Qualität des Stücks, dazu der Zeitbonus)."
## Skills of the opponent (SmithBot), e.g. "Meisterhand 2, Härtekunst 1".
const TEXT_SKILLS: String = "Seine Fertigkeiten: %s."
## His workshop upgrades (SmithBot), e.g. "Glutkammer, Meisteramboss".
const TEXT_WORKSHOP: String = "Seine Werkstatt: %s."
const TEXT_RUNNING: String = "Aufgabe: %s\nDas Material liegt in der Vorratstruhe. Gib das fertige, abgekühlte Stück unter deinem Amboss bei Abgeben ab.\nZeit: %s"
const TEXT_UNKNOWN: String = "\nRezepte, die du nicht kanntest: %d (je -%d Punkte)"
const TEXT_WON_ROUND: String = "Du gewinnst die Runde!"
const TEXT_LOST_ROUND: String = "%s gewinnt die Runde."
const TEXT_CHAMPION: String = "Du hast das große Schmiedeturnier gewonnen!"
const TEXT_OUT: String = "Du bist ausgeschieden."
const RESULT_SCENE: PackedScene = preload("res://scenes/ui/heroes/tournament_result_window.tscn")
## Player lock while the victory is celebrated and the result window is open.
const LOCK_REASON: StringName = &"smith_league_result"
## Seconds the victory is celebrated in the arena before the result window opens.
const CELEBRATE_SECONDS: float = 3.4
const TEXT_VICTORY: String = "Sieg!"

## Venue of this herald ("" = Leonheim, otherwise a key of "venues").
@export var venue: String = ""

@onready var _text_label: Label = %TextLabel
@onready var _primary_button: Button = %PrimaryButton
@onready var _secondary_button: Button = %SecondaryButton

var _tournament: SmithTournament = GameState.tournament
## Whole seconds of the round the text shows (-1 = none); _process redraws only when it changes.
var _shown_second: int = -1


func _ready() -> void:
	super()
	_primary_button.pressed.connect(_on_primary_pressed)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_tournament.changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	# "Abgeben" is only active with the finished piece in the inventory.
	GameState.inventory.changed.connect(_queue_refresh)


## The clock of a running round: redraws once per second, not every frame.
func _process(_delta: float) -> void:
	if visible and _tournament.state == SmithTournament.State.RUNNING 			and floori(_tournament.elapsed) != _shown_second:
		_refresh()


static func format_time(seconds: float) -> String:
	var whole: int = floori(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]


func _refresh() -> void:
	if not visible:
		return
	_refresh_done()
	_shown_second = floori(_tournament.elapsed)
	_tournament.select_venue(venue)
	var rounds: int = SmithTournament.get_rounds().size()
	_secondary_button.visible = true
	_primary_button.visible = true
	_primary_button.disabled = false
	match _tournament.state:
		SmithTournament.State.IDLE:
			var blocker: String = _tournament.get_entry_blocker()
			_text_label.text = Language.translate(str(SmithTournament.settings().get("intro_text", TEXT_IDLE))) + ("\n" + blocker if not blocker.is_empty() else "")
			_primary_button.text = Language.translate("Antreten")
			_primary_button.disabled = not blocker.is_empty()
			_secondary_button.text = Language.translate("Später")
			if _tournament.is_league_only():
				# League grounds of the cities (e.g. Sahrim), and Leonheim after the story tournament.
				var intro: String = str(SmithTournament.settings().get("intro_text", TEXT_IDLE))
				if not SmithTournament.settings().get("league_only", false):
					intro = TEXT_STORY_DONE
				_text_label.text = Language.translate(intro) + Language.translate(str(SmithTournament.settings().get("league_only_text", TEXT_LEAGUE_ONLY)))
				_primary_button.visible = false
		SmithTournament.State.BETWEEN_ROUNDS:
			if not _tournament.get_round_name().is_empty():
				_text_label.text = Language.translate(TEXT_LEAGUE_ROUND) % [_tournament.get_round_name(), _tournament.round_index + 1,
						rounds, _tournament.get_opponent_name()]
			else:
				_text_label.text = Language.translate(TEXT_ROUND) % [_tournament.round_index + 1, rounds, _tournament.get_opponent_name()]
			var strength: Vector2i = _tournament.get_opponent_score_range()
			_text_label.text += "\n" + Language.translate(TEXT_STRENGTH) % [
					DamageKinds.format_number(strength.x), DamageKinds.format_number(strength.y)]
			var skills: String = _tournament.get_opponent_skills()
			if not skills.is_empty():
				_text_label.text += "\n" + Language.translate(TEXT_SKILLS) % skills
			var workshop: String = _tournament.get_opponent_upgrades()
			if not workshop.is_empty():
				_text_label.text += "\n" + Language.translate(TEXT_WORKSHOP) % workshop
			var news: String = _tournament.get_opponent_news()
			if not news.is_empty():
				_text_label.text += "\n" + news
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
			if SmithTournament.is_league():
				var place: int = _tournament.get_place()
				if place == 2:
					_text_label.text = Language.translate(TEXT_PLACE)
				elif place > 2:
					_text_label.text += " " + Language.translate("Platz %d.") % place
				_text_label.text += "\n" + Language.translate("Zurück in die Turnierhalle: Dort gibt es Rangpunkte und Preise.")
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
	return "\n".join(lines)


func _on_primary_pressed() -> void:
	match _tournament.state:
		SmithTournament.State.IDLE:
			_tournament.enter()
		SmithTournament.State.BETWEEN_ROUNDS:
			_tournament.start_round()
			close()
			GameState.show_message(Language.translate("Aufgabe: %s. Das Material liegt in der Vorratstruhe.") % _tournament.get_task_name())
		SmithTournament.State.RUNNING:
			_tournament.hand_in()
		SmithTournament.State.RESULT:
			_tournament.continue_after_result()
			if _tournament.state == SmithTournament.State.OVER:
				_end_tournament()
		SmithTournament.State.OVER:
			_end_tournament()


## The tournament is over (won, out or given up): like in the hero arenas there is no last text
## at the herald. A victory is celebrated in the arena (_celebrate), then the result window shows
## place and prizes (_show_result). A league tournament then goes back into the hall of the city.
func _end_tournament() -> void:
	close()
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player:
		player.lock(LOCK_REASON)
	if _tournament.champion:
		await _celebrate(player)
		if not is_inside_tree():
			return
	if _tournament.state != SmithTournament.State.OVER:
		if is_instance_valid(player):
			player.unlock(LOCK_REASON)
		return
	var hall: String = SmithTournament.league_hall() if SmithTournament.is_league() else ""
	var league: bool = SmithTournament.is_league()
	_tournament.finish()
	_show_result(GameState.ranking.last_result if league else _tournament.story_result, hall)


## The player won the whole tournament: big "Sieg!" banner with the champion text, fanfare,
## confetti over the screen, the player throws up his arms and hops, the spectators cheer.
func _celebrate(player: Player) -> void:
	Events.inventory_close_requested.emit()
	AudioManager.play_sound("achievement")
	Events.banner_requested.emit(Language.translate(TEXT_VICTORY),
			Language.translate(str(SmithTournament.settings().get("champion_text", TEXT_CHAMPION))))
	if player:
		player.cheer(5)
	var scene: Node = get_tree().current_scene
	ArenaCelebration.cheer_crowd(scene, 5)
	# Confetti over the whole screen (in a layer of its own, under the windows).
	var confetti_layer := CanvasLayer.new()
	confetti_layer.layer = 4
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var confetti: CPUParticles2D = ArenaCelebration.make_confetti(screen.x, 140)
	confetti.position = Vector2(screen.x / 2.0, -8.0)
	confetti.lifetime = 3.4
	confetti_layer.add_child(confetti)
	scene.add_child(confetti_layer)
	await get_tree().create_timer(CELEBRATE_SECONDS, false).timeout
	if is_instance_valid(confetti):
		confetti.emitting = false


## The result window (leagues: place, RP, prizes, the winner's pick; story tournament: place and
## prize); afterwards back into the hall of a league.
func _show_result(result: Dictionary, hall: String) -> void:
	if not is_inside_tree():
		return
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player:
		player.lock(LOCK_REASON)
	var window: TournamentResultWindow = RESULT_SCENE.instantiate()
	get_tree().current_scene.add_child(window)
	window.show_result(result, null)
	await window.closed
	if is_instance_valid(player):
		player.unlock(LOCK_REASON)
	if is_inside_tree() and not hall.is_empty():
		GameState.travel_to(hall, TournamentHall.FROM_ARENA, true)


func _on_secondary_pressed() -> void:
	if _tournament.state in [SmithTournament.State.BETWEEN_ROUNDS, SmithTournament.State.RUNNING]:
		_tournament.give_up()
		_end_tournament()
	else:
		close()
