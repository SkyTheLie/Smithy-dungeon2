class_name TournamentHud
extends CanvasLayer
## Line at the top of the screen on the tournament ground while a round runs: round, task, time
## and what the opponent is doing (SmithTournament).

var _label: Label


func _ready() -> void:
	layer = 5
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-150, 4)
	panel.custom_minimum_size = Vector2(300, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_label)


func _process(_delta: float) -> void:
	var tournament: SmithTournament = GameState.tournament
	var running: bool = tournament.state == SmithTournament.State.RUNNING
	visible = running
	if not running:
		return
	var opponent: String = "fertig" if tournament.get_opponent_progress() >= 1.0 else "arbeitet"
	_label.text = Language.translate("Runde %d · %s · %s · %s %s") % [tournament.round_index + 1, tournament.get_task_name(),
			TournamentMenu.format_time(tournament.elapsed), tournament.get_opponent_name(), opponent]
