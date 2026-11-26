extends Node
## Autoload "AudioManager": plays the background music (endless loop) and short sounds.
## Which file belongs to which sound id is in res://data/content/audio.json, so sounds can be
## swapped without touching code. Missing files only give a warning and stay silent.
##   AudioManager.play_sound("anvil_perfect")
##   AudioManager.play_skill_sound(skill.id)   # own sound from "skill_sounds", else "skill_used"
##   AudioManager.play_music("default")
## The music follows the scene (audio.json "scene_music", e.g. the forest scenes play "forest")
## and the story (audio.json "flag_music", e.g. the raid plays "raid" in every scene).
## A piece in "music" can be a list of files: they play one after another, then start over.
## The player's volume settings (0-100 %, on/off) live on audio buses: "Master" (everything),
## "Music", "Sounds" (effects), "Ambience" (steps, doors, background noises) and "Interface"
## (clicks, windows); saved in user://settings.cfg (section "audio", WindowLayout). Which bus a
## sound uses: audio.json "sound_buses" (id -> bus), otherwise "Sounds".
## A sound can be a list of files: one is picked at random each time (e.g. footsteps), and
## "sound_volume_db_by_id" (id -> dB) makes single sounds louder or quieter.
## Background noises (birds, crickets, fire ...) loop on the "Ambience" bus: audio.json "ambience"
## (id -> file) and "scene_ambience" (scene file -> id); at night "<id>_night" is used if it exists.

const CONFIG_PATH: String = "res://data/content/audio.json"
## Sounds that can play at the same time (more are cut off: the oldest player is reused).
const SOUND_VOICES: int = 8
## Kinds of volume the settings can change; also the bus names.
const MASTER: String = "Master"
const MUSIC: String = "Music"
const SOUNDS: String = "Sounds"
const AMBIENCE: String = "Ambience"
const INTERFACE: String = "Interface"
const KINDS: Array[String] = [MASTER, MUSIC, SOUNDS, AMBIENCE, INTERFACE]
## A new background noise fades in from this much quieter over these seconds.
const AMBIENCE_FADE_DB: float = 30.0
## Meta on a button that should not play the click sound.
const SILENT_META: StringName = &"no_click_sound"
const AMBIENCE_FADE_SECONDS: float = 1.5
const SETTINGS_SECTION: String = "audio"

var _config: Dictionary = {}
## Path -> AudioStream (null if it could not be loaded), so every file is loaded only once.
var _streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
## Id of the running background noise ("" = none).
var _ambience_id: String = ""
var _sound_players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_id: String = ""
## Files of the running piece (more than one = playlist) and which one is playing.
var _music_paths: Array[String] = []
var _music_index: int = 0
## Piece id -> index of the file to play next time (a playlist goes on where it stopped).
var _next_track: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	for kind in KINDS:
		_create_bus(kind)
		_apply_volume(kind)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = float(_config.get("music_volume_db", 0.0))
	_music_player.bus = MUSIC
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = AMBIENCE
	add_child(_ambience_player)
	for i in SOUND_VOICES:
		var player := AudioStreamPlayer.new()
		player.volume_db = float(_config.get("sound_volume_db", 0.0))
		player.bus = SOUNDS
		add_child(player)
		_sound_players.append(player)
	play_music("default")
	get_tree().scene_changed.connect(update_music)
	get_tree().scene_changed.connect(update_ambience)
	GameState.day_cycle.phase_changed.connect(func(_phase: DayCycle.Phase) -> void: update_ambience())
	# Every button in the game clicks (also the ones created later).
	get_tree().node_added.connect(_on_node_added)
	GameState.story.changed.connect(update_music)


## Plays the piece that fits now: a "flag_music" rule whose story flags hold, otherwise the
## scene's piece from "scene_music", otherwise "default".
func update_music() -> void:
	for rule: Dictionary in _config.get("flag_music", []):
		var from: String = String(rule.get("from", ""))
		var until: String = String(rule.get("until", ""))
		if GameState.story.has_flag(from) and (until.is_empty() or not GameState.story.flags.has(until)):
			play_music(String(rule.get("music", "default")))
			return
	var scene: Node = get_tree().current_scene
	var file: String = scene.scene_file_path.get_file() if scene else ""
	play_music(String((_config.get("scene_music", {}) as Dictionary).get(file, "default")))


# --- Volume settings (MUSIC / SOUNDS) ---------------------------------------------

## Volume 0..1 the player set (default 0.8, "Master" 1.0).
func get_volume(kind: String) -> float:
	var default: float = 1.0 if kind == MASTER else 0.8
	return clampf(float(WindowLayout.get_setting(SETTINGS_SECTION, kind.to_lower() + "_volume", default)), 0.0, 1.0)


func set_volume(kind: String, volume: float) -> void:
	WindowLayout.set_setting(SETTINGS_SECTION, kind.to_lower() + "_volume", clampf(volume, 0.0, 1.0))
	_apply_volume(kind)


func is_muted(kind: String) -> bool:
	return bool(WindowLayout.get_setting(SETTINGS_SECTION, kind.to_lower() + "_muted", false))


func set_muted(kind: String, muted: bool) -> void:
	WindowLayout.set_setting(SETTINGS_SECTION, kind.to_lower() + "_muted", muted)
	_apply_volume(kind)


func _create_bus(kind: String) -> void:
	if AudioServer.get_bus_index(kind) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, kind)
	AudioServer.set_bus_send(index, Language.translate("Master"))


func _apply_volume(kind: String) -> void:
	var index: int = AudioServer.get_bus_index(kind)
	if index < 0:
		return
	var volume: float = get_volume(kind)
	AudioServer.set_bus_mute(index, is_muted(kind) or volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("AudioManager: %s not found, no sounds." % CONFIG_PATH)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		_config = data
	else:
		push_error("AudioManager: %s is not valid JSON." % CONFIG_PATH)


## Buttons with the meta SILENT_META don't click (e.g. the sound test in the admin panel).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.pressed.connect(func() -> void:
			if not button.has_meta(SILENT_META):
				play_sound("ui_click"))


# --- Listening test (admin panel) -------------------------------------------------------

## Ids of all sounds / background loops / music pieces in audio.json, in file order.
func get_ids(section: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign((_config.get(section, {}) as Dictionary).keys())
	return ids


## Files of one sound (a list has several variants).
func get_sound_files(id: String) -> Array[String]:
	var entry: Variant = (_config.get("sounds", {}) as Dictionary).get(id, "")
	var files: Array[String] = []
	if entry is Array:
		files.assign(entry)
	elif not String(entry).is_empty():
		files.append(String(entry))
	return files


## Plays exactly this variant of a sound (index into get_sound_files).
func play_sound_variant(id: String, index: int) -> void:
	var files: Array[String] = get_sound_files(id)
	if index >= 0 and index < files.size():
		_play_path(files[index], id)


## Plays a background loop no matter the scene ("" = back to the scene's own).
func preview_ambience(id: String) -> void:
	if id.is_empty():
		_ambience_id = ""
		update_ambience()
		return
	_ambience_id = id
	_ambience_player.stop()
	var stream: AudioStream = _get_stream(String((_config.get("ambience", {}) as Dictionary).get(id, "")), id)
	if stream:
		_ambience_player.stream = _with_loop(stream, true)
		_ambience_player.volume_db = float(_config.get("ambience_volume_db", 0.0))
		_ambience_player.play()


## Whether this scene is inside a building (audio.json "indoor_scenes"): doors to or from it
## play the door sound, map changes outside don't.
func is_indoor(scene_path: String) -> bool:
	return (_config.get("indoor_scenes", []) as Array).has(scene_path.get_file())


func get_ambience_id() -> String:
	return _ambience_id


func get_music_id() -> String:
	return _music_id


## Plays a sound from "sounds" once (a list: one of its files at random). Unknown ids or missing
## files stay silent. `pitch` > 1 plays it higher (e.g. the anvil combo).
func play_sound(id: String, pitch: float = 1.0) -> void:
	var entry: Variant = (_config.get("sounds", {}) as Dictionary).get(id, "")
	if entry is Array:
		entry = (entry as Array).pick_random() if not (entry as Array).is_empty() else ""
	_play_path(String(entry), id, pitch)


## Starts the background noise of the current scene ("scene_ambience"), the night version if
## it is night and one exists; fades in. No entry = silence.
func update_ambience() -> void:
	var scene: Node = get_tree().current_scene
	var file: String = scene.scene_file_path.get_file() if scene else ""
	var id: String = String((_config.get("scene_ambience", {}) as Dictionary).get(file, ""))
	var loops: Dictionary = _config.get("ambience", {})
	if not id.is_empty() and GameState.day_cycle.is_night() and loops.has(id + "_night"):
		id += "_night"
	if id == _ambience_id and (_ambience_player.playing or id.is_empty()):
		return
	_ambience_id = id
	_ambience_player.stop()
	var stream: AudioStream = _get_stream(String(loops.get(id, "")), id)
	if stream == null:
		return
	var volume: float = float(_config.get("ambience_volume_db", 0.0))
	_ambience_player.stream = _with_loop(stream, true)
	_ambience_player.volume_db = volume - AMBIENCE_FADE_DB
	_ambience_player.play()
	create_tween().tween_property(_ambience_player, "volume_db", volume, AMBIENCE_FADE_SECONDS)


## Sound of a skill: its own from "skill_sounds", otherwise the general "skill_used".
func play_skill_sound(skill_id: String) -> void:
	var own: String = String((_config.get("skill_sounds", {}) as Dictionary).get(skill_id, ""))
	if own.is_empty():
		play_sound("skill_used")
	else:
		_play_path(own, skill_id)


## Starts a piece from "music" (the same piece keeps running). "" = silence. One file loops
## endlessly; a list plays its files in turn (coming back later goes on with the next one).
func play_music(id: String) -> void:
	if id == _music_id and _music_player.playing:
		return
	_music_id = id
	_music_index = int(_next_track.get(id, 0))
	_music_paths.clear()
	var entry: Variant = (_config.get("music", {}) as Dictionary).get(id, "")
	if entry is Array:
		for path: Variant in entry:
			_music_paths.append(String(path))
	elif not String(entry).is_empty():
		_music_paths.append(String(entry))
	_start_track()


func stop_music() -> void:
	_music_id = ""
	_music_paths.clear()
	_music_player.stop()


func _start_track() -> void:
	_music_player.stop()
	if _music_paths.is_empty():
		return
	_music_index %= _music_paths.size()
	_next_track[_music_id] = _music_index + 1
	var stream: AudioStream = _get_stream(_music_paths[_music_index], _music_id)
	if stream == null:
		return
	_music_player.stream = _with_loop(stream, _music_paths.size() == 1)
	_music_player.play()


## A track of a playlist ended: the next one (a single piece loops and never ends).
func _on_music_finished() -> void:
	if _music_paths.size() > 1:
		_music_index += 1
		_start_track()


func _play_path(path: String, id: String, pitch: float = 1.0) -> void:
	var stream: AudioStream = _get_stream(path, id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sound_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sound_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = float(_config.get("sound_volume_db", 0.0)) \
			+ float((_config.get("sound_volume_db_by_id", {}) as Dictionary).get(id, 0.0))
	player.bus = String((_config.get("sound_buses", {}) as Dictionary).get(id, SOUNDS))
	player.play()


func _get_stream(path: String, id: String) -> AudioStream:
	if path.is_empty():
		return null
	if not _streams.has(path):
		var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
		if stream == null:
			push_warning("AudioManager: sound '%s' not found: %s" % [id, path])
		_streams[path] = stream
	return _streams[path]


## Turns looping on or off for the music, whatever the import settings say.
func _with_loop(stream: AudioStream, loop: bool) -> AudioStream:
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamWAV:
		var wav := looped as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		wav.loop_begin = 0
		wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = loop
	elif looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = loop
	return looped
