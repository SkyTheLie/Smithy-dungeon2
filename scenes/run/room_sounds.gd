class_name RoomSounds
extends Node
## Quiet sounds of the place, now and then, somewhere in the room the player is in: drops, chains,
## wind, frogs, crickets … (floors.json theme "ambience" [[type, weight], …], the sounds in
## "ambience_types": a SoundSynth voice like the enemies' cries, with "volume" in dB; how often and
## how far away: "ambience" settings at the top). Pauses with the game. Own random numbers, so the
## dungeon's random order stays the same.

var dungeon: Dungeon
var _rng := RandomNumberGenerator.new()
var _wait: float = 0.0
## The theme's list [[type, weight], …] and the settings, read once per floor.
var _table: Array = []
var _types: Dictionary = {}
var _every: Array = [5.0, 11.0]
var _distance: Array = [2.5, 6.0]


func setup(the_dungeon: Dungeon, table: Array, rng_seed: int) -> void:
	dungeon = the_dungeon
	_table = table
	_types = Content.floors_extra("ambience_types")
	var settings: Dictionary = Content.floors_extra("ambience")
	_every = settings.get("every", _every)
	_distance = settings.get("distance", _distance)
	_rng.seed = rng_seed
	_wait = _rng.randf_range(float(_every[0]) * 0.5, float(_every[1]) * 0.5)


func _process(delta: float) -> void:
	# Silent in the halls of the end bosses (they have their own quiet scene) and after the run.
	if _table.is_empty() or dungeon == null or dungeon.in_end_hall() or dungeon.run.is_dead():
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = _rng.randf_range(float(_every[0]), float(_every[1]))
	play_next()


## Plays one sound of the list now (somewhere around the player, inside the room). Returns its type
## ("" if nothing played).
func play_next() -> String:
	if _table.is_empty() or dungeon.player == null:
		return ""
	var kind: String = Content.pick_weighted(_table, _rng)
	var voice: Dictionary = _types.get(kind, {})
	if voice.is_empty():
		return ""
	var around: Vector3 = dungeon.player.global_position
	var away := Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU) * _rng.randf_range(float(_distance[0]), float(_distance[1]))
	var rect: Rect2 = RoomBuilder.inner_rect(RoomBuilder.cell_at(around), 0.3)
	var spot := Vector3(clampf(around.x + away.x, rect.position.x, rect.end.x), _rng.randf_range(0.3, 2.6),
			clampf(around.z + away.z, rect.position.y, rect.end.y))
	AudioManager.play_stream_at(SoundSynth.make(voice, kind), spot, dungeon.effects, _rng.randf_range(0.92, 1.08), float(voice.get("volume", -16.0)))
	return kind
