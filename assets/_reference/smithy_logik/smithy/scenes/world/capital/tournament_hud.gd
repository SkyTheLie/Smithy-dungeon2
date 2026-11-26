class_name TournamentHud
extends CanvasLayer
## Scoreboard of the smith tournament (SmithTournament) while a round runs, below the time compass:
## round and task, the player and the opponent with the clock between them, what the opponent is
## doing right now and how far his work has come. Below it, for a few seconds, the announcements
## of the round, like in the hero arena: "Halbfinale! Du gegen Kuno!", "Kuno ist fertig!", who
## won the round.

## Seconds an announcement stays.
const ANNOUNCE_SECONDS: float = 4.0

@onready var _board: PanelContainer = %Board
@onready var _title_label: Label = %TitleLabel
@onready var _player_label: Label = %PlayerLabel
@onready var _time_label: Label = %TimeLabel
@onready var _rival_label: Label = %RivalLabel
@onready var _step_label: Label = %StepLabel
@onready var _rival_bar: ProgressBar = %RivalBar
@onready var _announcement: PanelContainer = %Announcement
@onready var _announcement_label: Label = %AnnouncementLabel

var _tournament: SmithTournament = GameState.tournament
## State seen at the last change (announcements only on a real change).
var _last_state: SmithTournament.State = SmithTournament.State.IDLE
## The opponent was already announced as done in this round.
var _rival_done: bool = false
## Text of the opponent's step and the whole second shown (only redrawn when they change).
var _shown_step: String = ""
var _shown_second: int = -1
var _announce_left: float = 0.0


func _ready() -> void:
	_tournament.changed.connect(_on_tournament_changed)
	_last_state = _tournament.state
	_fill_board()


func _on_tournament_changed() -> void:
	var state: SmithTournament.State = _tournament.state
	if state == SmithTournament.State.RUNNING and _last_state == SmithTournament.State.BETWEEN_ROUNDS:
		_rival_done = false
		var round_name: String = _tournament.get_round_name()
		if round_name.is_empty():
			round_name = Language.translate("Runde %d") % (_tournament.round_index + 1)
		announce(Language.translate("%s! %s gegen %s!") % [round_name, GameState.get_player_name(), _tournament.get_opponent_name()]
				+ "\n" + Language.translate("Aufgabe: %s") % _tournament.get_task_name())
	elif state == SmithTournament.State.RESULT and _last_state == SmithTournament.State.RUNNING:
		var won: bool = _tournament.last_result.get("won", false)
		announce(Language.translate("Du gewinnst die Runde!") if won
				else Language.translate("%s gewinnt die Runde.") % _tournament.get_opponent_name())
	elif state == SmithTournament.State.OVER and _tournament.champion:
		announce(Language.translate("%s gewinnt das Turnier!") % GameState.get_player_name())
	elif state == SmithTournament.State.IDLE:
		_hide_announcement()
	_last_state = state
	_fill_board()


## Shows `text` (already translated) below the board for a few seconds.
func announce(text: String) -> void:
	_announcement_label.text = text
	_announcement.show()
	_announce_left = ANNOUNCE_SECONDS


func is_announcing() -> bool:
	return _announcement.visible


func get_announcement() -> String:
	return _announcement_label.text if _announcement.visible else ""


func _hide_announcement() -> void:
	_announcement.hide()
	_announce_left = 0.0


## The fixed parts of the board (round, task, names); the clock and the opponent's step follow
## in _process.
func _fill_board() -> void:
	var running: bool = _tournament.state == SmithTournament.State.RUNNING
	_board.visible = running
	if not running:
		return
	var round_name: String = _tournament.get_round_name()
	if round_name.is_empty():
		round_name = Language.translate("Runde %d von %d") % [_tournament.round_index + 1, SmithTournament.get_rounds().size()]
	_title_label.text = "%s · %s" % [round_name, _tournament.get_task_name()]
	_player_label.text = GameState.get_player_name()
	_rival_label.text = _tournament.get_opponent_name()
	_shown_step = ""
	_shown_second = -1


func _process(delta: float) -> void:
	if _announce_left > 0.0:
		_announce_left -= delta
		if _announce_left <= 0.0:
			_hide_announcement()
	if not _board.visible:
		return
	var second: int = floori(_tournament.elapsed)
	if second != _shown_second:
		_shown_second = second
		_time_label.text = TournamentMenu.format_time(_tournament.elapsed)
	var progress: float = _tournament.get_opponent_progress()
	_rival_bar.value = progress
	var step: Dictionary = _tournament.get_opponent_step()
	var step_text: String = str(step.get("text", "fertig!"))
	if step_text != _shown_step:
		_shown_step = step_text
		_step_label.text = Language.translate(step_text)
	if progress >= 1.0 and not _rival_done:
		_rival_done = true
		announce(Language.translate("%s ist fertig!") % _tournament.get_opponent_name())
