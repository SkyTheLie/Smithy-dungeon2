class_name IceWall
extends RefCounted
## The puzzles on the crown of the ice wall (part 6), run by story actions (story.json dialogues of
## the pillars and mirror sockets), like StormTemple:
## - Five ice pillars sing in different voices: "ice_pillar:<n>" strikes one. In the order of
##   Torgai's lullaby (PILLAR_ORDER: the gull, the whale, the seal, the fish, the wave) they wake the
##   wall (SONG_FLAG); a wrong one starts over.
## - Three sockets for silver mirrors: "ice_mirror:<n>" puts a mirror from the inventory into one
##   (flag "ice_mirror_<n>"). With all three the morning light falls on the wall (BEAM_FLAG).

## Pillars (1-5 from west to east) in the order of the lullaby.
const PILLAR_ORDER: Array[int] = [3, 5, 1, 4, 2]
const MIRROR_SOCKETS: int = 3
const SONG_FLAG: String = "ice_song_done"
const BEAM_FLAG: String = "ice_beam_on"
const MIRROR_ITEM: String = "ice_mirror"
const TEXT_WRONG_PILLAR: String = "Die Stimmen der Säulen klingen schief durcheinander und verstummen. Das Lied beginnt von vorn."
const TEXT_SONG_DONE: String = "Das Lied ist zu Ende. Ein tiefes Summen geht durch die ganze Mauer, und im Eis vor dir glimmt ein blasses Licht auf."
const TEXT_BEAM_ON: String = "Der dritte Spiegel fängt das Licht. Ein Strahl springt von Spiegel zu Spiegel und trifft die Wand im Norden. Das Eis dort wird klar wie Wasser."

## Pillars struck in the right order so far.
const STRUCK_FLAG: String = "ice_pillar_struck_%d"
static var _struck: Array[int] = []


static func mirror_flag(socket: int) -> String:
	return "ice_mirror_%d" % socket


## Story action "ice_pillar:<n>" (1-5).
static func strike_pillar(pillar: int) -> void:
	var game_state: Node = _game_state()
	if game_state.story.has_flag(SONG_FLAG):
		return
	_load_struck()
	if PILLAR_ORDER[_struck.size()] != pillar:
		var had_progress: bool = not _struck.is_empty()
		_struck.clear()
		# The first pillar of the song always starts a new try.
		if pillar == PILLAR_ORDER[0]:
			_struck.append(pillar)
		elif had_progress:
			game_state.show_message(Language.translate(TEXT_WRONG_PILLAR))
		_save_struck()
		return
	_struck.append(pillar)
	_save_struck()
	if _struck.size() == PILLAR_ORDER.size():
		game_state.story.set_flag(SONG_FLAG)
		game_state.show_message(Language.translate(TEXT_SONG_DONE))


## The current try lives in story flags, so it survives saving and loading.
static func _load_struck() -> void:
	var story: Story = _game_state().story
	_struck.clear()
	for index in PILLAR_ORDER.size():
		if not story.has_flag(STRUCK_FLAG % index):
			break
		_struck.append(PILLAR_ORDER[index])


static func _save_struck() -> void:
	var story: Story = _game_state().story
	var flags: Array[String] = []
	for index in PILLAR_ORDER.size():
		flags.append(STRUCK_FLAG % index)
	story.clear_flags(flags)
	for index in _struck.size():
		story.set_flag(STRUCK_FLAG % index)


## Story action "ice_mirror:<n>" (1-3). false if the socket is taken or the player has no mirror
## (the dialogue then shows its "else").
static func place_mirror(socket: int) -> bool:
	var game_state: Node = _game_state()
	if game_state.story.has_flag(mirror_flag(socket)) or not game_state.take_items(MIRROR_ITEM):
		return false
	game_state.story.set_flag(mirror_flag(socket))
	for index in range(1, MIRROR_SOCKETS + 1):
		if not game_state.story.has_flag(mirror_flag(index)):
			return true
	game_state.story.set_flag(BEAM_FLAG)
	game_state.show_message(Language.translate(TEXT_BEAM_ON))
	return true


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
