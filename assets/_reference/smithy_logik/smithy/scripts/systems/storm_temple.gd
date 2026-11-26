class_name StormTemple
extends RefCounted
## The puzzles of the storm temple in the deep desert, run by story actions (story.json dialogues of
## the sockets and pillars):
## - The gate has three sockets, 0 = west (left), 1 = middle, 2 = east (right). "temple_seal:<socket>,
##   <seal>" puts a forged seal from the inventory into a socket (flag "temple_socket_<n>_<seal>").
##   When all three hold one: in the right places (SOLUTION, the mural: the sun rises in the east,
##   the moon stands in the middle of the night, the storm comes from the west) the gate opens
##   (GATE_FLAG), otherwise the seals fall out and go back into the inventory. After
##   MAX_WRONG_SEALS wrong orders the seals sort themselves and the gate opens anyway.
## - Four pillars of different heights: "temple_pillar:<n>" strikes one. From the highest to the
##   lowest (PILLAR_ORDER, the mural: lightning strikes the highest first) opens the way to the
##   sanctum (PILLARS_FLAG); a wrong one starts over.

const SEALS: Array[String] = ["sun_seal", "moon_seal", "storm_seal"]
## Seal per socket: west, middle, east.
const SOLUTION: Array[String] = ["storm_seal", "moon_seal", "sun_seal"]
## Pillars from the highest to the lowest (1-4 from west to east).
const PILLAR_ORDER: Array[int] = [3, 1, 4, 2]
const GATE_FLAG: String = "temple_gate_open"
const PILLARS_FLAG: String = "temple_pillars_done"
const TEXT_WRONG_SEALS: String = "Die Runen am Tor flackern rot. Mit einem Knirschen springen die drei Siegel aus den Vertiefungen. Sie sitzen nicht am richtigen Platz."
const TEXT_GATE_OPEN: String = "Die drei Siegel leuchten auf. Ein Blitz fährt in das Tor, und es gleitet grollend zur Seite."
## After this many wrong orders in a row the gate opens by itself.
const MAX_WRONG_SEALS: int = 5
const MISS_FLAG: String = "temple_seal_miss_%d"
const TEXT_GATE_SOLVED: String = "Die Runen flackern ein letztes Mal. Dann ordnen sich die Siegel wie von selbst: der Sturm im Westen, der Mond in der Mitte, die Sonne im Osten. Ein Blitz fährt in das Tor, und es gleitet grollend zur Seite."
const TEXT_WRONG_PILLAR: String = "Die Töne klingen schief durcheinander und verhallen. Die Runen an den Säulen erlöschen."
const TEXT_PILLARS_DONE: String = "Der letzte Ton fährt wie Donner durch die Halle. Im Norden schiebt sich die Steinplatte zur Seite."

## Pillars struck in the right order so far.
const STRUCK_FLAG: String = "temple_pillar_struck_%d"
static var _struck: Array[int] = []


static func socket_flag(socket: int, seal: String) -> String:
	return "temple_socket_%d_%s" % [socket, seal]


## Seal id in this socket ("" = empty).
static func socket_content(socket: int) -> String:
	var story: Story = _game_state().story
	for seal in SEALS:
		if story.has_flag(socket_flag(socket, seal)):
			return seal
	return ""


## Story action "temple_seal:<socket>,<seal>". false if the player has no such seal or the socket
## is taken (the dialogue then shows its "else").
static func insert_seal(parameter: String) -> bool:
	var values: PackedStringArray = parameter.split(",")
	if values.size() < 2:
		return false
	var socket: int = int(values[0])
	var seal: String = values[1].strip_edges()
	var game_state: Node = _game_state()
	if game_state.story.has_flag(GATE_FLAG) or not socket_content(socket).is_empty():
		return false
	if not game_state.take_items(seal):
		return false
	game_state.story.set_flag(socket_flag(socket, seal))
	for index in SOLUTION.size():
		if socket_content(index).is_empty():
			return true
	_check_gate()
	return true


static func _check_gate() -> void:
	var game_state: Node = _game_state()
	var right: bool = true
	for index in SOLUTION.size():
		right = right and socket_content(index) == SOLUTION[index]
	if right:
		game_state.story.set_flag(GATE_FLAG)
		game_state.show_message(Language.translate(TEXT_GATE_OPEN))
		return
	var flags: PackedStringArray = []
	var seals: PackedStringArray = []
	for index in SOLUTION.size():
		var seal: String = socket_content(index)
		flags.append(socket_flag(index, seal))
		seals.append(seal)
	game_state.story.clear_flags(flags)
	game_state.give_items(",".join(seals))
	var misses: int = wrong_attempts() + 1
	if misses >= MAX_WRONG_SEALS:
		# Five wrong tries in a row: the seals slip into the right places by themselves (user
		# 2026-11-11). The player keeps the seals he put in, the gate shows the right ones.
		for index in SOLUTION.size():
			game_state.story.set_flag(socket_flag(index, SOLUTION[index]))
		game_state.story.set_flag(GATE_FLAG)
		game_state.show_message(Language.translate(TEXT_GATE_SOLVED))
		return
	game_state.story.set_flag(MISS_FLAG % misses)
	game_state.show_message(Language.translate(TEXT_WRONG_SEALS))


## Wrong orders of the seals so far (flags "temple_seal_miss_<n>").
static func wrong_attempts() -> int:
	var count: int = 0
	while _game_state().story.has_flag(MISS_FLAG % (count + 1)):
		count += 1
	return count


## Story action "temple_pillar:<n>" (1-4).
static func strike_pillar(pillar: int) -> void:
	var game_state: Node = _game_state()
	if game_state.story.has_flag(PILLARS_FLAG):
		return
	_load_struck()
	if PILLAR_ORDER[_struck.size()] != pillar:
		var had_progress: bool = not _struck.is_empty()
		_struck.clear()
		# The first pillar of the order always starts a new try.
		if pillar == PILLAR_ORDER[0]:
			_struck.append(pillar)
		elif had_progress:
			game_state.show_message(Language.translate(TEXT_WRONG_PILLAR))
		_save_struck()
		return
	_struck.append(pillar)
	_save_struck()
	if _struck.size() == PILLAR_ORDER.size():
		game_state.story.set_flag(PILLARS_FLAG)
		game_state.show_message(Language.translate(TEXT_PILLARS_DONE))


## Whether this pillar glows right now (struck in the current try, or the puzzle is solved).
static func is_lit(pillar: int) -> bool:
	_load_struck()
	return _game_state().story.has_flag(PILLARS_FLAG) or _struck.has(pillar)


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


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
