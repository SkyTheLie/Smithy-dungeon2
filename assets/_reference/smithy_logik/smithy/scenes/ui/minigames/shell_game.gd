class_name ShellGame
extends StationMenu
## The beggar's shell game on the village square (window of ShellGameBeggar).
## The beggar shows the marble under one of three cups, covers it and swaps the cups slowly a few
## times; the player clicks the cup he thinks the marble is under. A win pays the stake twice.
## Rules and stakes: economy.json "shell_game".
## Phase 1 (bait): the stake is 1 gold and the game is fair (the marble really follows its cup),
## and slow enough to follow. After 2-3 wins the beggar asks for higher stakes (story flag
## "beggar_high_stakes"). Phase 2: higher stakes (economy.json high_stakes), the shuffle looks exactly the same, but
## the beggar palms the marble: whichever cup the player picks, the marble is under another one.
## Progress lives in story flags (saved with the story): "beggar_win_<n>", "beggar_needs_3"
## (3 instead of 2 bait wins, rolled on the first game), "beggar_high_stakes".

enum State { IDLE, SHOWING, SHUFFLING, CHOOSING, REVEAL }

const CUP_TEXTURE: Texture2D = preload("res://assets/sprites/props/shell_cup.png")
const HIGH_STAKES_FLAG: String = "beggar_high_stakes"
const NEEDS_THREE_FLAG: String = "beggar_needs_3"
const WIN_FLAG: String = "beggar_win_%d"
## Distance between the cups (centre to centre) and how high a cup is lifted.
const CUP_SPACING: float = 48.0
const LIFT: float = 18.0
## Seconds a cup takes to go up or down.
const LIFT_SECONDS: float = 0.35
## Marble: radius in pixels and colours (glass, dark rim, highlight).
const MARBLE_RADIUS: int = 4
const MARBLE_COLOR := Color8(0x28, 0xcf, 0xfc)
const MARBLE_DARK := Color8(0x14, 0x4c, 0xad)
const MARBLE_RIM := Color8(0x21, 0x13, 0x1e)

const TEXT_WELCOME: String = "Na, Fremder? Ein kleines Spiel? Drei Becher, eine Murmel. Find sie, und du kriegst das Doppelte!"
const TEXT_WELCOME_HIGH: String = "Da ist ja mein Glückspilz! Heute um richtiges Gold?"
const TEXT_WATCH: String = "Schau genau hin, hier ist die Murmel ..."
const TEXT_SHUFFLE: String = "Und jetzt ... gaaanz langsam ..."
const TEXT_CHOOSE: String = "Na? Unter welchem Becher ist sie?"
const TEXT_WIN: String = "Ha! Gut aufgepasst! Hier, dein Gewinn: %d Gold."
const TEXT_LOSE: String = "Ooh, knapp daneben! Sie war genau hier. Noch eine Runde?"
const TEXT_NO_GOLD: String = "Ohne Einsatz kein Spiel, mein Freund. Komm wieder, wenn du %d Gold hast."
const TEXT_HIGH_STAKES: String = "Du hast ja richtig scharfe Augen! Wie wär's mit mehr Einsatz? Ab jetzt spielen wir um mindestens %d Gold. Da lohnt sich ein Gewinn wenigstens!"

var _state: State = State.IDLE
## Cup nodes; `_cup_slot[i]` = slot (0 left, 1 middle, 2 right) cup i stands in now.
var _cups: Array[TextureRect] = []
var _cup_slot: Array[int] = [0, 1, 2]
## Index of the cup the marble is under.
var _marble_cup: int = 0
var _stake: int = 0
var _rng := RandomNumberGenerator.new()

@onready var _speech: Label = %SpeechLabel
@onready var _table: Control = %Table
@onready var _marble: TextureRect = %Marble
@onready var _stakes: HBoxContainer = %Stakes
@onready var _gold_label: Label = %GoldLabel


func _ready() -> void:
	super()
	_rng.randomize()
	_marble.texture = _make_marble_texture()
	for i in 3:
		var cup := TextureRect.new()
		cup.texture = CUP_TEXTURE
		cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cup.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cup.gui_input.connect(_on_cup_input.bind(i))
		_table.add_child(cup)
		_cups.append(cup)
	_table.resized.connect(_place_cups)
	visibility_changed.connect(_on_visibility_changed)
	GameState.gold_changed.connect(func(_gold: int) -> void: _update_gold())


func _on_visibility_changed() -> void:
	if not visible:
		return
	if _state != State.IDLE:
		return
	_speech.text = Language.translate(TEXT_WELCOME_HIGH) if _is_high_stakes() else Language.translate(TEXT_WELCOME)
	_reset_table()
	_show_stake_buttons()
	_update_gold()


## Closing before a cup was picked: the beggar pushes the stake back, the table is reset.
func close() -> void:
	super()
	if _state in [State.SHOWING, State.SHUFFLING, State.CHOOSING]:
		GameState.add_gold(_stake)
		GameState.show_message(Language.translate("Der Bettler schiebt dir deinen Einsatz zurück."))
	_state = State.IDLE


# --- Rules ------------------------------------------------------------------------

static func _settings() -> Dictionary:
	return ContentDB.economy("shell_game")


func _is_high_stakes() -> bool:
	return GameState.story.has_flag(HIGH_STAKES_FLAG)


func _get_stakes() -> Array:
	var settings: Dictionary = _settings()
	if _is_high_stakes():
		return settings.get("high_stakes", [50, 100, 200])
	return [int(settings.get("bait_stake", 1))]


## Wins in the bait phase so far.
func _bait_wins() -> int:
	var wins: int = 0
	while GameState.story.has_flag(WIN_FLAG % (wins + 1)):
		wins += 1
	return wins


func _bait_wins_needed() -> int:
	var settings: Dictionary = _settings()
	var key: String = "bait_wins_max" if GameState.story.has_flag(NEEDS_THREE_FLAG) else "bait_wins_min"
	return int(settings.get(key, 2))


# --- Round ------------------------------------------------------------------------

func _show_stake_buttons() -> void:
	for child in _stakes.get_children():
		child.queue_free()
	for stake: Variant in _get_stakes():
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.text = Language.translate("Spielen (%d Gold)") % int(stake) if not _is_high_stakes() else Language.translate("%d Gold") % int(stake)
		button.pressed.connect(_start_round.bind(int(stake)))
		_stakes.add_child(button)
	_stakes.show()


func _start_round(stake: int) -> void:
	if _state != State.IDLE:
		return
	if not GameState.spend_gold(stake):
		_speech.text = Language.translate(TEXT_NO_GOLD) % stake
		return
	if _bait_wins() == 0 and not _is_high_stakes() and not GameState.story.has_flag("beggar_played"):
		GameState.story.set_flag("beggar_played")
		if _rng.randf() < 0.5:
			GameState.story.set_flag(NEEDS_THREE_FLAG)
	_stake = stake
	_stakes.hide()
	_play_round()


func _play_round() -> void:
	var settings: Dictionary = _settings()
	_reset_table()
	_marble_cup = _rng.randi() % 3
	# Show the marble under its cup.
	_state = State.SHOWING
	_speech.text = Language.translate(TEXT_WATCH)
	await _lift(_marble_cup, true)
	await get_tree().create_timer(float(settings.get("show_seconds", 1.2)), false).timeout
	await _lift(_marble_cup, false)
	if not _is_round_alive():
		return
	# Shuffle: always the same slow swaps, fair or not.
	_state = State.SHUFFLING
	_speech.text = Language.translate(TEXT_SHUFFLE)
	var swap_seconds: float = float(settings.get("swap_seconds", 0.8))
	for i in int(settings.get("swaps", 5)):
		var a: int = _rng.randi() % 3
		var b: int = (a + 1 + _rng.randi() % 2) % 3
		await _swap_slots(a, b, swap_seconds)
		if not _is_round_alive():
			return
	_state = State.CHOOSING
	_speech.text = Language.translate(TEXT_CHOOSE)
	_set_cups_clickable(true)


func _on_cup_input(event: InputEvent, cup: int) -> void:
	var click := event as InputEventMouseButton
	if _state != State.CHOOSING or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	_set_cups_clickable(false)
	_choose(cup)


func _choose(cup: int) -> void:
	_state = State.REVEAL
	# The trick: in the high-stakes phase the beggar has palmed the marble and slips it under
	# another cup while lifting. The player never sees it move.
	if _is_high_stakes() and cup == _marble_cup:
		var others: Array[int] = [0, 1, 2]
		others.erase(cup)
		_marble_cup = others[_rng.randi() % others.size()]
	await _lift(cup, true)
	if not _is_round_alive():
		return
	if cup == _marble_cup:
		_win()
		return
	await get_tree().create_timer(0.4, false).timeout
	await _lift(_marble_cup, true)
	if not _is_round_alive():
		return
	_speech.text = Language.translate(TEXT_LOSE)
	_end_round()


func _win() -> void:
	var payout: int = _stake * 2
	GameState.add_gold(payout)
	_speech.text = Language.translate(TEXT_WIN) % payout
	if not _is_high_stakes():
		var wins: int = _bait_wins() + 1
		GameState.story.set_flag(WIN_FLAG % wins)
		if wins >= _bait_wins_needed():
			GameState.story.set_flag(HIGH_STAKES_FLAG)
			_speech.text += "\n" + Language.translate(TEXT_HIGH_STAKES) % int(_get_stakes()[0])
	_end_round()


func _end_round() -> void:
	_state = State.IDLE
	_show_stake_buttons()


## false once the window was closed mid-round (the coroutine stops).
func _is_round_alive() -> bool:
	return visible and _state != State.IDLE


# --- Table and animation ------------------------------------------------------------

func _slot_position(slot: int) -> Vector2:
	var centre: Vector2 = _table.size / 2.0
	var cup_size: Vector2 = CUP_TEXTURE.get_size()
	return Vector2(centre.x + (slot - 1) * CUP_SPACING - cup_size.x / 2.0, centre.y - cup_size.y / 2.0 + 6.0)


func _place_cups() -> void:
	for i in _cups.size():
		_cups[i].position = _slot_position(_cup_slot[i])
	_marble.position = _marble_position(_marble_cup)


func _reset_table() -> void:
	_cup_slot = [0, 1, 2]
	_set_cups_clickable(false)
	_marble.hide()
	_place_cups()


func _marble_position(cup: int) -> Vector2:
	var cup_size: Vector2 = CUP_TEXTURE.get_size()
	var base: Vector2 = _slot_position(_cup_slot[cup])
	return base + Vector2(cup_size.x / 2.0 - MARBLE_RADIUS - 1, cup_size.y - 2 * MARBLE_RADIUS - 4)


func _set_cups_clickable(clickable: bool) -> void:
	for cup in _cups:
		cup.mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE


## Lifts (up = true) or puts down a cup; the marble shows while its cup is up.
func _lift(cup: int, up: bool) -> void:
	var target: Vector2 = _slot_position(_cup_slot[cup]) + (Vector2(0, -LIFT) if up else Vector2.ZERO)
	if up:
		_marble.position = _marble_position(_marble_cup)
		_marble.visible = cup == _marble_cup
	var tween: Tween = create_tween()
	tween.tween_property(_cups[cup], "position", target, LIFT_SECONDS).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if not up and cup == _marble_cup:
		_marble.hide()


## Swaps the cups standing in two slots: one slides over in front, the other behind (a small arc
## down and up), both at the same slow speed.
func _swap_slots(slot_a: int, slot_b: int, seconds: float) -> void:
	var cup_a: int = _cup_slot.find(slot_a)
	var cup_b: int = _cup_slot.find(slot_b)
	_cup_slot[cup_a] = slot_b
	_cup_slot[cup_b] = slot_a
	# The one passing in front is drawn on top.
	_table.move_child(_cups[cup_a], -1)
	var tween: Tween = create_tween().set_parallel()
	_tween_arc(tween, _cups[cup_a], _slot_position(slot_b), 7.0, seconds)
	_tween_arc(tween, _cups[cup_b], _slot_position(slot_a), -7.0, seconds)
	await tween.finished


func _tween_arc(tween: Tween, cup: TextureRect, target: Vector2, depth: float, seconds: float) -> void:
	var start: Vector2 = cup.position
	tween.tween_method(func(t: float) -> void:
		cup.position = start.lerp(target, t) + Vector2(0, sin(t * PI) * depth), 0.0, 1.0, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_gold() -> void:
	_gold_label.text = Language.translate("Dein Gold: %d") % GameState.gold


## A small blue glass marble (drawn here, it is only a few pixels).
func _make_marble_texture() -> Texture2D:
	var size: int = MARBLE_RADIUS * 2 + 1
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(MARBLE_RADIUS, MARBLE_RADIUS)
	for y in size:
		for x in size:
			var distance: float = Vector2(x, y).distance_to(centre)
			if distance > MARBLE_RADIUS + 0.4:
				continue
			var color: Color = MARBLE_COLOR
			if distance > MARBLE_RADIUS - 0.6:
				color = MARBLE_RIM
			elif x + y > size:
				color = MARBLE_DARK
			image.set_pixel(x, y, color)
	image.set_pixel(MARBLE_RADIUS - 2, MARBLE_RADIUS - 2, Color.WHITE)
	return ImageTexture.create_from_image(image)
