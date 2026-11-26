class_name HandInClerk
extends Station
## "Abgeben": the tournament helper below the player's anvil in every smith arena. E hands in the
## finished piece of the running round (SmithTournament.hand_in), so the player does not have to
## walk to the herald; the herald's window then opens with the result. Without a piece (or outside
## a round) he only says what he is there for.
## The figure is a Baukasten figure (GoblinFigure with `appearance`), one look per arena.

const TEXT_NO_ROUND: String = "Hier gibst du im Schmiedeturnier dein fertiges Stück ab."
const TEXT_NO_PIECE: String = "Bring mir das fertige, abgekühlte Stück: %s."

## Look of the helper in this arena.
@export var appearance: Appearance
## The herald's window of this arena (shows the result after handing in).
@export var menu: TournamentMenu


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	var figure := GoblinFigure.new()
	figure.appearance = appearance
	add_child(figure)
	move_child(figure, 0)
	interacted.connect(_on_interacted)
	if menu:
		player_left.connect(menu.close)


func _on_interacted() -> void:
	var tournament: SmithTournament = GameState.tournament
	if tournament.state != SmithTournament.State.RUNNING:
		GameState.show_message(Language.translate(TEXT_NO_ROUND))
		return
	if not tournament.hand_in():
		GameState.show_message(Language.translate(TEXT_NO_PIECE) % tournament.get_task_name())
		return
	if menu:
		menu.show()
