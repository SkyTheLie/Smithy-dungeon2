class_name PlayLog
extends RefCounted
## Local play log for testers (docs/BINDUNG.md: where testers stop says more than any rule).
## One line per session in user://play_log.csv (";" between the columns, opens in Excel/LibreOffice):
## when it started, when it was last played, minutes, how it ended ("Beendet", "Hauptmenü", or
## "läuft" if the game was closed some other way or crashed), the story step and its task, day,
## time, gold, level, reputation rank, total play time and the game version.
## The line of the running session is rewritten every FLUSH_SECONDS of play and at the end, so even
## a crash leaves the last state. Nothing is sent anywhere: testers send the file themselves
## (settings: "Spiel-Protokoll öffnen" opens the folder).
## GameState starts the session once a game runs (start), ticks it while the player is in a map
## (tick) and ends it (finish) on "Hauptmenü" and "Spiel beenden".

const PATH: String = "user://play_log.csv"
const FLUSH_SECONDS: float = 30.0
const HEADER: String = "Start;Zuletzt;Minuten;Ende;Schritt;Aufgabe;Tag;Uhrzeit;Gold;Level;Ruf-Rang;Spielzeit gesamt;Version"
const RUNNING: String = "läuft"
const ENDED_QUIT: String = "Beendet"
const ENDED_MENU: String = "Hauptmenü"

var _active: bool = false
var _started: String = ""
var _seconds: float = 0.0
var _flush_left: float = FLUSH_SECONDS
## The file as it was before this session (header and the older sessions).
var _earlier: String = ""


func is_active() -> bool:
	return _active


## A game runs: a new line for this session (does nothing if one is running).
func start(state: Node) -> void:
	if _active:
		return
	_earlier = _read_earlier()
	_started = _now()
	_seconds = 0.0
	_flush_left = FLUSH_SECONDS
	_active = true
	write(state, RUNNING)


## Played `delta` seconds; every FLUSH_SECONDS the line is written anew.
func tick(delta: float, state: Node) -> void:
	if not _active:
		return
	_seconds += delta
	_flush_left -= delta
	if _flush_left <= 0.0:
		_flush_left = FLUSH_SECONDS
		write(state, RUNNING)


## The session ends (`reason`: ENDED_QUIT, ENDED_MENU): its line gets the end and stays as it is.
func finish(state: Node, reason: String) -> void:
	if not _active:
		return
	write(state, reason)
	_active = false


func write(state: Node, reason: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(_earlier + make_line(state, reason) + "\n")
	file.close()


## The line of this session.
func make_line(state: Node, reason: String) -> String:
	var objective: Dictionary = state.get_story_objective()
	var total: int = floori(state.play_time / 60.0)
	var fields: Array[String] = [_started, _now(), str(floori(_seconds / 60.0)), reason, state.story.step,
			str(objective.get("title", "")), str(state.day_cycle.day), state.day_cycle.get_clock_text(), str(state.gold),
			str(state.player_stats.level), state.reputation.get_rank_id(), "%d:%02d" % [total / 60, total % 60],
			str(ProjectSettings.get_setting("application/config/version", ""))]
	return ";".join(fields.map(func(field: String) -> String: return field.replace(";", ",").replace("\n", " ")))


static func _now() -> String:
	return Time.get_datetime_string_from_system(false, true)


static func _read_earlier() -> String:
	if not FileAccess.file_exists(PATH):
		return HEADER + "\n"
	var text: String = FileAccess.get_file_as_string(PATH)
	if text.is_empty():
		return HEADER + "\n"
	return text if text.ends_with("\n") else text + "\n"
