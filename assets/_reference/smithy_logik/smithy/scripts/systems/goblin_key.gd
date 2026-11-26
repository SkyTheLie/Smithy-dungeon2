class_name GoblinKey
extends RefCounted
## The key of the treasure chamber in the goblin castle (part 2, chapter 8):
## - The gate of the treasure chamber (hall) shows three runes once the player touched it
##   (RUNES_SEEN_FLAG, the smith's magic wakes them).
## - The old forge (GoblinForge scene) is cold until the chain lever lets the lava in (LAVA_FLAG).
##   Then three discs on its column light up; each shows one of four runes towards the south. Three
##   levers turn them clockwise, one rune further (turn_disc).
## - The key mold of the goblin king goes under the spout (MOLD_FLAG). Melting copper and iron ore
##   together into bronze (ORE_SPEC) pours a key into it whose bit has the runes the discs show right then (code flags).
## - The key comes out of the mold glowing hot (HOT_KEY_ITEM) and is cooled in the water trough
##   (KEY_ITEM). Only one key at a time.
## - At the gate: with the runes of the gate (SOLUTION) it opens (GATE_FLAG), otherwise the key
##   breaks in the lock and the player casts a new one.
## Disc 0 = top (orange), 1 = middle (blue), 2 = bottom (green); the levers from west to east.

const DISCS: int = 3
const RUNES: int = 4
## Rune per disc that opens the gate (the runes on the gate).
const SOLUTION: Array[int] = [2, 3, 1]
const LAVA_FLAG: String = "goblin_forge_lava"
const MOLD_FLAG: String = "goblin_forge_mold"
const IN_MOLD_FLAG: String = "goblin_key_in_mold"
const RUNES_SEEN_FLAG: String = "treasury_runes_seen"
## Set once the right key opened the gate (the name is older than the puzzle).
const GATE_FLAG: String = "goblin_key_forged"
const ORE_SPEC: String = "copper_ore*2,iron_ore"
const MOLD_ITEM: String = "goblin_key_mold"
const HOT_KEY_ITEM: String = "treasury_key_hot"
const KEY_ITEM: String = "treasury_key"
## Names of the discs (colour) for the messages.
const DISC_NAMES: Array[String] = ["orange", "blaue", "grüne"]

const TEXT_NO_LAVA: String = "Die Schmiede ist kalt. Ohne Glut schmilzt hier nichts."
const TEXT_NO_MOLD: String = "Unter dem Ausguss steht keine Gussform."
const TEXT_KEY_EXISTS: String = "Du hast schon einen Schlüssel. Die Form fasst nur einen."
const TEXT_NO_ORE: String = "Für einen Schlüssel braucht die Schmelze 2 Kupfererz und 1 Eisenerz."
const TEXT_POURED: String = "Kupfer und Eisen schmelzen zu Bronze und rinnen glühend in die Gussform. Darin liegt jetzt ein Schlüssel."
const TEXT_MOLD_PLACED: String = "Du stellst die Schlüssel-Gussform unter den Ausguss. Sie passt genau."
const TEXT_MOLD_MISSING: String = "Hier gehört eine Gussform hin. Du hast keine passende."
const TEXT_MOLD_EMPTY: String = "Die Gussform ist leer."
const TEXT_TAKE_KEY: String = "Du ziehst den glühenden Schlüssel mit der Zange aus der Form."
const TEXT_COOLED: String = "Es zischt und dampft. Der Schlüssel ist abgekühlt."
const TEXT_NOTHING_TO_COOL: String = "Ein Trog voll Wasser. Hier kühlt man heißes Metall ab."
const TEXT_DISC_TURNED: String = "Die %s Scheibe dreht sich mit einem Knirschen weiter."
const TEXT_DISCS_COLD: String = "Der Hebel klemmt. Die Scheiben bewegen sich nicht, solange die Schmiede kalt ist."
const TEXT_GATE_LOCKED: String = "Das Tor ist verschlossen. Ein Schlüsselloch so groß wie eine Faust."
const TEXT_KEY_HOT: String = "Der Schlüssel glüht noch. Kühl ihn erst im Wasser ab, sonst verbiegt er im Schloss."
const TEXT_KEY_BROKE: String = "Du drehst den Schlüssel. Die Zeichen auf dem Tor flackern, dann bricht der Schlüssel im Schloss ab. Die Zeichen auf seinem Bart passen nicht."
const TEXT_GATE_OPEN: String = "Der Schlüssel dreht sich. Die drei Zeichen glühen hell auf, dann schwingt das Tor knarrend auf."


static func disc_flag(disc: int, rune: int) -> String:
	return "goblin_disc_%d_%d" % [disc, rune]


static func code_flag(disc: int, rune: int) -> String:
	return "goblin_key_code_%d_%d" % [disc, rune]


## Rune the disc shows towards the south now (rune 0 has no flag: the start).
static func disc_rune(disc: int) -> int:
	var story: Story = _game_state().story
	for rune in range(1, RUNES):
		if story.has_flag(disc_flag(disc, rune)):
			return rune
	return 0


## One lever: the disc turns clockwise to its next rune. false while the forge is cold.
static func turn_disc(disc: int) -> bool:
	var game_state: Node = _game_state()
	if not game_state.story.has_flag(LAVA_FLAG):
		game_state.show_message(Language.translate(TEXT_DISCS_COLD))
		return false
	var rune: int = disc_rune(disc)
	if rune > 0:
		game_state.story.clear_flags([disc_flag(disc, rune)])
	var next: int = (rune + 1) % RUNES
	if next > 0:
		game_state.story.set_flag(disc_flag(disc, next))
	game_state.show_message(Language.translate(TEXT_DISC_TURNED) % Language.translate(DISC_NAMES[disc]))
	return true


## true while a key exists: in the mold, hot or cooled in the inventory.
static func has_key() -> bool:
	var game_state: Node = _game_state()
	return game_state.story.has_flag(IN_MOLD_FLAG) or game_state.has_items(HOT_KEY_ITEM) or game_state.has_items(KEY_ITEM)


## The mold stand: puts the goblin king's mold under the spout, or takes the cast key out of it.
static func use_mold() -> void:
	var game_state: Node = _game_state()
	var story: Story = game_state.story
	if not story.has_flag(MOLD_FLAG):
		if game_state.take_items(MOLD_ITEM):
			story.set_flag(MOLD_FLAG)
			game_state.show_message(Language.translate(TEXT_MOLD_PLACED))
		else:
			game_state.show_message(Language.translate(TEXT_MOLD_MISSING))
		return
	if not story.has_flag(IN_MOLD_FLAG):
		game_state.show_message(Language.translate(TEXT_MOLD_EMPTY))
		return
	story.clear_flags([IN_MOLD_FLAG])
	game_state.give_items(HOT_KEY_ITEM)
	game_state.show_message(Language.translate(TEXT_TAKE_KEY))


## The forge: melts the ore into bronze and pours a key with the runes of the discs. false (with a
## message) if something is missing.
static func pour_key() -> bool:
	var game_state: Node = _game_state()
	var story: Story = game_state.story
	var problem: String = ""
	if not story.has_flag(LAVA_FLAG):
		problem = TEXT_NO_LAVA
	elif not story.has_flag(MOLD_FLAG):
		problem = TEXT_NO_MOLD
	elif has_key():
		problem = TEXT_KEY_EXISTS
	elif not game_state.take_items(ORE_SPEC):
		problem = TEXT_NO_ORE
	if not problem.is_empty():
		game_state.show_message(Language.translate(problem))
		return false
	var old_code: Array[String] = []
	for disc in DISCS:
		for rune in RUNES:
			old_code.append(code_flag(disc, rune))
	story.clear_flags(old_code)
	for disc in DISCS:
		story.set_flag(code_flag(disc, disc_rune(disc)))
	story.set_flag(IN_MOLD_FLAG)
	AudioManager.play_sound("cast_pour")
	game_state.show_message(Language.translate(TEXT_POURED))
	return true


## The water trough: cools the hot key.
static func cool_key() -> bool:
	var game_state: Node = _game_state()
	if not game_state.take_items(HOT_KEY_ITEM):
		game_state.show_message(Language.translate(TEXT_NOTHING_TO_COOL))
		return false
	game_state.give_items(KEY_ITEM)
	AudioManager.play_sound("quench_hiss")
	game_state.show_message(Language.translate(TEXT_COOLED))
	return true


## Rune on the bit of the current key for this disc (-1 = no key cast yet).
static func key_rune(disc: int) -> int:
	var story: Story = _game_state().story
	for rune in RUNES:
		if story.has_flag(code_flag(disc, rune)):
			return rune
	return -1


## The gate: tries the key. Returns true if the gate opened.
static func try_gate() -> bool:
	var game_state: Node = _game_state()
	if game_state.story.has_flag(GATE_FLAG):
		return true
	if not game_state.has_items(KEY_ITEM):
		var text: String = TEXT_KEY_HOT if game_state.has_items(HOT_KEY_ITEM) else TEXT_GATE_LOCKED
		game_state.show_message(Language.translate(text))
		return false
	game_state.take_items(KEY_ITEM)
	for disc in DISCS:
		if key_rune(disc) != SOLUTION[disc]:
			AudioManager.play_sound("rock_break", 1.4)
			game_state.show_message(Language.translate(TEXT_KEY_BROKE))
			return false
	game_state.story.set_flag(GATE_FLAG)
	AudioManager.play_sound("door", 0.7)
	game_state.show_message(Language.translate(TEXT_GATE_OPEN))
	return true


static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
