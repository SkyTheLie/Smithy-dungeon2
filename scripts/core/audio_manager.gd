extends Node
## Autoload "AudioManager" (smaller version of the one in Smithy): plays the background music
## (endless loop) and short sounds. Which file belongs to which id is in res://data/audio.json,
## so sounds can be swapped without touching code. Missing files only give a warning.
##   AudioManager.play_sound("shoot", randf_range(0.9, 1.1))
##   AudioManager.play_music("floor_1")
## A sound can be a list of files: one is picked at random each time.
## Volumes (0-100 %) live on the buses "Master", "Music", "Sounds" and "Interface"; saved in
## user://settings.cfg (section "audio", WindowLayout).
## Sounds of things in the dungeon (enemies) play in 3D: play_sound_at / play_stream_at put a
## short-lived AudioStreamPlayer3D at the spot (left/right and quieter further away, heard by the
## camera of the run's SubViewport). audio.json "spatial": unit_size, max_distance, voices.
## Music and the player's own sounds stay plain (no direction).

const CONFIG_PATH: String = "res://data/audio.json"
## Sounds that can play at the same time (more cut off the oldest one).
const SOUND_VOICES: int = 12
const MASTER: String = "Master"
const MUSIC: String = "Music"
const SOUNDS: String = "Sounds"
const INTERFACE: String = "Interface"
const KINDS: Array[String] = [MASTER, MUSIC, SOUNDS, INTERFACE]
const SETTINGS_SECTION: String = "audio"

var _config: Dictionary = {}
## Path -> AudioStream (null if it could not be loaded), so every file is loaded only once.
var _streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_id: String = ""
var _sound_players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
## The 3D sounds playing now (at most "spatial" voices).
var _spatial_playing: Array[AudioStreamPlayer3D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	for kind in KINDS:
		_create_bus(kind)
		_apply_volume(kind)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = float(_config.get("music_volume_db", 0.0))
	_music_player.bus = MUSIC
	add_child(_music_player)
	for i in SOUND_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SOUNDS
		add_child(player)
		_sound_players.append(player)
	# Every button clicks (also the ones created later).
	get_tree().node_added.connect(_on_node_added)


func get_volume(kind: String) -> float:
	var default: float = 1.0 if kind == MASTER else 0.8
	return clampf(float(WindowLayout.get_setting(SETTINGS_SECTION, kind.to_lower() + "_volume", default)), 0.0, 1.0)


func set_volume(kind: String, volume: float) -> void:
	WindowLayout.set_setting(SETTINGS_SECTION, kind.to_lower() + "_volume", clampf(volume, 0.0, 1.0))
	_apply_volume(kind)


func _create_bus(kind: String) -> void:
	if AudioServer.get_bus_index(kind) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, kind)
	AudioServer.set_bus_send(index, MASTER)


func _apply_volume(kind: String) -> void:
	var index: int = AudioServer.get_bus_index(kind)
	if index < 0:
		return
	var volume: float = get_volume(kind)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func _load_config() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if data is Dictionary:
		_config = data
	else:
		push_error("AudioManager: %s is missing or not valid JSON." % CONFIG_PATH)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play_sound.bind("ui_click", 1.0))


## Plays a sound from "sounds" once (a list: one of its files at random). Unknown ids stay silent.
## Plays a sound made in code (SoundSynth) on the "Sounds" bus.
func play_stream(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = _sound_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sound_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.bus = SOUNDS
	player.play()


func play_sound(id: String, pitch: float = 1.0) -> void:
	var entry: Variant = (_config.get("sounds", {}) as Dictionary).get(id, "")
	if entry is Array:
		entry = (entry as Array).pick_random() if not (entry as Array).is_empty() else ""
	var stream: AudioStream = _get_stream(String(entry), id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sound_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sound_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = float((_config.get("sound_volume_db", {}) as Dictionary).get(id, 0.0))
	player.bus = String((_config.get("sound_buses", {}) as Dictionary).get(id, SOUNDS))
	player.play()


## A sound from "sounds" at `at` in the 3D world of `parent` (e.g. Dungeon.effects): it comes
## from that side and is quieter further away. Without a parent in the tree: plain play_sound.
func play_sound_at(id: String, at: Vector3, parent: Node3D, pitch: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		play_sound(id, pitch)
		return
	var entry: Variant = (_config.get("sounds", {}) as Dictionary).get(id, "")
	if entry is Array:
		entry = (entry as Array).pick_random() if not (entry as Array).is_empty() else ""
	var stream: AudioStream = _get_stream(String(entry), id)
	var volume: float = float((_config.get("sound_volume_db", {}) as Dictionary).get(id, 0.0))
	_play_3d(stream, at, parent, pitch, volume, String((_config.get("sound_buses", {}) as Dictionary).get(id, SOUNDS)))


## A sound made in code (SoundSynth) at `at`, like play_sound_at.
func play_stream_at(stream: AudioStream, at: Vector3, parent: Node3D, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		play_stream(stream, pitch, volume_db)
		return
	_play_3d(stream, at, parent, pitch, volume_db, SOUNDS)


func _play_3d(stream: AudioStream, at: Vector3, parent: Node3D, pitch: float, volume_db: float, bus: String) -> void:
	if stream == null:
		return
	var settings: Dictionary = _config.get("spatial", {})
	_forget_finished()
	# Too many at once: the oldest one stops (like the plain voices).
	if _spatial_playing.size() >= int(settings.get("voices", 16)):
		var oldest: AudioStreamPlayer3D = _spatial_playing.pop_front()
		oldest.queue_free()
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.bus = bus
	player.unit_size = float(settings.get("unit_size", 4.0))
	player.max_distance = float(settings.get("max_distance", 40.0))
	player.panning_strength = float(settings.get("panning_strength", 1.0))
	player.attenuation_filter_cutoff_hz = 20500.0
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	player.global_position = at
	player.play()
	_spatial_playing.append(player)


## Drops the 3D sounds that ended (freed) from the list.
func _forget_finished() -> void:
	var still: Array[AudioStreamPlayer3D] = []
	for player: Variant in _spatial_playing:
		if is_instance_valid(player) and (player as AudioStreamPlayer3D).playing:
			still.append(player as AudioStreamPlayer3D)
	_spatial_playing = still


## How many 3D sounds play right now (tests).
func spatial_count() -> int:
	_forget_finished()
	return _spatial_playing.size()


## Starts a piece from "music" (the same piece keeps running). "" = silence.
func play_music(id: String) -> void:
	if id == _music_id and _music_player.playing:
		return
	_music_id = id
	_music_player.stop()
	var stream: AudioStream = _get_stream(String((_config.get("music", {}) as Dictionary).get(id, "")), id)
	if stream == null:
		return
	_music_player.stream = _with_loop(stream)
	_music_player.play()


func get_music_id() -> String:
	return _music_id


func _get_stream(path: String, id: String) -> AudioStream:
	if path.is_empty():
		return null
	if not _streams.has(path):
		var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
		if stream == null:
			push_warning("AudioManager: sound '%s' not found: %s" % [id, path])
		_streams[path] = stream
	return _streams[path]


## Music always loops, whatever the import settings say.
func _with_loop(stream: AudioStream) -> AudioStream:
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamWAV:
		var wav := looped as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	elif looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	return looped
