class_name TournamentDeskMenu
extends StationMenu
## The tournament master at the reception of a tournament hall (TournamentHall): shows the smith
## rank, lets the winner of a league tournament pick his prize (PrizeChoiceList) and registers
## the player for a league tournament: one button per league (rank), the ones above his rank or
## blocked (hours, one per day, entry fee) greyed out with the reason as tooltip. Registering pays
## the entry fee (SmithTournament.enter_league) and brings him into the arena of the city
## (SmithTournament.league_arena, spawn point TournamentHall.FROM_HALL).

const TEXT_GREETING: String = "Willkommen in der Turnierhalle! Hier meldest du dich für die Liga-Turniere an. Acht Schmiede, einer gegen einen: Viertelfinale, Halbfinale, Finale. Für Platz 1 bis 3 gibt es Preise, für jede Platzierung Rangpunkte."
const TEXT_RUNNING: String = "Du bist schon angemeldet. Ab in die Arena!"

## Venue of this hall ("" = Leonheim, otherwise a key of economy.json "smith_tournament" "venues").
@export var venue: String = ""

@onready var _text_label: Label = %TextLabel
@onready var _prize_box: VBoxContainer = %PrizeBox
@onready var _league_box: VBoxContainer = %LeagueBox


func _ready() -> void:
	super()
	%CloseButton.pressed.connect(close)
	GameState.ranking.changed.connect(_queue_refresh)
	GameState.gold_changed.connect(_queue_refresh)
	visibility_changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	_refresh_done()
	for box: Container in [_prize_box, _league_box]:
		for child in box.get_children():
			child.queue_free()
	var ranking: TournamentRanking = GameState.ranking
	var tournament: SmithTournament = GameState.tournament
	_text_label.text = Language.translate(TEXT_GREETING) + "\n\n" + ranking.describe("smith", venue)
	PrizeChoiceList.fill(_prize_box)
	if tournament.is_active():
		_text_label.text += "\n" + Language.translate(TEXT_RUNNING)
		return
	for index in TournamentRanking.league_count():
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = Language.translate("Anmelden: %s (%d Gold)") % [TournamentRanking.league_name(index),
				TournamentRanking.get_entry_fee("smith", index)]
		var blocker: String = ranking.get_blocker("smith", venue, index)
		button.disabled = not blocker.is_empty()
		button.tooltip_text = ranking.describe_league("smith", index) + ("\n" + blocker if not blocker.is_empty() else "")
		button.pressed.connect(_on_league_chosen.bind(index))
		_league_box.add_child(button)


## Registers for the league and travels into the arena of the city.
func _on_league_chosen(index: int) -> void:
	var tournament: SmithTournament = GameState.tournament
	tournament.select_venue(venue)
	var arena: String = SmithTournament.league_arena()
	if arena.is_empty() or not tournament.enter_league(index):
		var blocker: String = GameState.ranking.get_blocker("smith", venue, index)
		GameState.show_message(blocker if not blocker.is_empty() else Language.translate("Das ging nicht."))
		return
	AudioManager.play_sound("coins")
	close()
	GameState.show_message(Language.translate("Angemeldet: %s. Der Herold in der Arena sagt dir, was geschmiedet wird.") % TournamentRanking.league_name(index))
	GameState.travel_to(arena, TournamentHall.FROM_HALL, true)
