class_name PokerMenu
extends StationMenu
## Window of the poker table on the left of the gambling den: Limit Texas Hold'em against the bots
## who sit there today (each with his coins for the day, broke = gone), for gaming coins (bought
## from Vex at the bar). Rules: DenPoker; the window shows
## the table (the bots left, top and right, the table cards in the middle, the player's cards at
## the bottom), lets the bots act one after another with a short pause, and calls the player's
## choices. Closing the window during a hand folds it (standing up from the table).

## Seconds a bot "thinks" before it acts.
const BOT_SECONDS: float = 0.7
const COLOR_ACTIVE := Color(0.95, 0.8, 0.5)
const COLOR_IDLE := Color(0.62, 0.6, 0.56)
## Name and status of who won the hand (gold like the frame round his cards).
const COLOR_WIN := PlayingCard.WIN_COLOUR

var _poker: DenPoker = DenPoker.new()
var _big: int = 0
## true while the bots are acting (the player's buttons wait).
var _busy: bool = false

@onready var _coins_label: Label = %CoinsLabel
@onready var _blinds_label: Label = %BlindsLabel
@onready var _seats: Array[VBoxContainer] = [%Seat0, %Seat1, %Seat2, %Seat3]
@onready var _table_cards: HBoxContainer = %TableCards
@onready var _pot_label: Label = %PotLabel
@onready var _hand_label: Label = %HandLabel
@onready var _result: Label = %ResultLabel
@onready var _fold: Button = %FoldButton
@onready var _call: Button = %CallButton
@onready var _raise: Button = %RaiseButton
@onready var _blinds: HBoxContainer = %Blinds
@onready var _play: Button = %PlayButton


func _ready() -> void:
	super()
	for big in DenPoker.get_blinds():
		var button := Button.new()
		# Only the small blind on the button (the big blind is twice that).
		button.text = DamageKinds.format_number(DenPoker.get_small_blind(big))
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.set_meta("big", big)
		button.pressed.connect(_set_big.bind(big))
		_blinds.add_child(button)
	_play.pressed.connect(play)
	_fold.pressed.connect(player_act.bind(DenPoker.Action.FOLD))
	_call.pressed.connect(player_act.bind(DenPoker.Action.CALL))
	_raise.pressed.connect(player_act.bind(DenPoker.Action.RAISE))
	GameState.gambling_den.coins_changed.connect(_queue_refresh)
	GameState.gambling_den.poker_table_changed.connect(_queue_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_big = DenPoker.get_blinds()[0]


func _on_visibility_changed() -> void:
	if visible:
		if not _poker.is_running():
			_poker.take_seats()
		_refresh()
	elif _poker.is_running():
		_poker.fold()
		GameState.show_message(Language.translate("Du stehst auf und steigst aus. Was du gesetzt hast, bleibt im Topf."))


## The running hand (tests and the window read it).
func get_poker() -> DenPoker:
	return _poker


func _set_big(big: int) -> void:
	if not _poker.is_running():
		_big = big
	_refresh()


## Starts a hand: the button moves on, the blinds are posted, the cards dealt; then the bots act
## until it is the player's turn.
func play() -> void:
	if _poker.is_running() or _busy:
		return
	if not _poker.start(_big):
		_poker.take_seats()
		if _poker.get_bot_count() == 0:
			_result.text = Language.translate("Heute sitzt niemand mehr mit Münzen am Tisch. Morgen kommen neue.")
		else:
			_result.text = Language.translate("Für diesen Tisch brauchst du mindestens %d Münzen. Vex an der Bar verkauft welche.") % _big
		_refresh()
		return
	_result.text = ""
	_refresh()
	_run_bots()


## The player's choice (only on his turn); then the bots go on.
func player_act(action: DenPoker.Action) -> void:
	if _busy or _poker.actor != DenPoker.PLAYER:
		return
	_poker.act(DenPoker.PLAYER, action)
	_refresh()
	_run_bots()


## Lets the bots act one after another, a short pause each, until the player is to act or the
## hand is over.
func _run_bots() -> void:
	if _busy:
		return
	_busy = true
	_refresh()
	while _poker.is_running() and _poker.actor > DenPoker.PLAYER:
		await get_tree().create_timer(BOT_SECONDS, false).timeout
		if not is_inside_tree() or not _poker.is_running():
			break
		_poker.bot_act()
		_refresh()
	_busy = false
	if is_inside_tree():
		_refresh()


func _end_text() -> String:
	if _poker.folded[DenPoker.PLAYER]:
		return Language.translate("Du steigst aus. Was du gesetzt hast, bleibt im Topf.")
	if _poker.player_won and not _poker.showdown:
		return Language.translate("Alle anderen steigen aus. Du bekommst %d Münzen.") % _poker.payout
	var hand: String = Language.translate(DenPoker.get_hand_name(_poker.get_score(DenPoker.PLAYER)))
	if _poker.player_won and _poker.winners.size() == 1:
		return Language.translate("Du gewinnst mit %s: %d Münzen.") % [hand, _poker.payout]
	if _poker.player_won:
		return Language.translate("Gleichstand mit %s. Dein Anteil: %d Münzen.") % [hand, _poker.payout]
	if _poker.winners.is_empty():
		return ""
	var winner: int = _poker.winners[0]
	return Language.translate("%s gewinnt mit %s.") % [_seat_name(winner),
			Language.translate(DenPoker.get_hand_name(_poker.get_score(winner)))]


func _seat_name(seat: int) -> String:
	return Language.translate(_poker.get_seat_name(seat))


## What a seat did last, for its status line.
func _action_text(seat: int) -> String:
	var action: Dictionary = _poker.last_action[seat]
	var amount: int = int(action.get("amount", 0))
	match str(action.get("kind", "")):
		"small_blind":
			return Language.translate("Small Blind %d") % amount
		"big_blind":
			return Language.translate("Big Blind %d") % amount
		"fold":
			return Language.translate("steigt aus")
		"check":
			return Language.translate("schiebt")
		"call":
			return Language.translate("geht mit (%d)") % amount
		"raise":
			return Language.translate("erhöht auf %d") % amount
		"all_in":
			return Language.translate("All-in (%d)") % amount
	return ""


func _refresh() -> void:
	_refresh_done()
	var started: bool = _poker.street != DenPoker.Street.IDLE
	var running: bool = _poker.is_running()
	var done: bool = _poker.street == DenPoker.Street.DONE
	_coins_label.text = Language.translate("Münzen: %d") % GameState.gambling_den.coins
	_blinds_label.text = Language.translate("Blinds %d/%d") % [DenPoker.get_small_blind(_poker.big_blind), _poker.big_blind] if started else ""
	for seat in DenPoker.SEATS:
		_refresh_seat(seat, started, done)
	var shown: int = _poker.get_table_count()
	for i in _table_cards.get_child_count():
		var card: PlayingCard = _table_cards.get_child(i)
		if started and i < shown:
			card.show_card(_poker.table_cards[i])
		else:
			card.show_back()
	if not started and _poker.get_bot_count() == 0:
		_pot_label.text = Language.translate("Heute sitzt niemand mehr mit Münzen am Tisch. Morgen kommen neue.")
	elif not started:
		_pot_label.text = Language.translate("Wähle die Blinds und drück „Spielen“.")
	elif running and _poker.actor == DenPoker.PLAYER and _poker.get_to_call(DenPoker.PLAYER) > 0:
		_pot_label.text = Language.translate("Topf: %d · Zum Mitgehen: %d") % [_poker.get_pot(), _poker.get_to_call(DenPoker.PLAYER)]
	else:
		_pot_label.text = Language.translate("Topf: %d") % _poker.get_pot()
	_hand_label.text = Language.translate("Deine Hand: %s") % Language.translate(DenPoker.get_hand_name(_poker.get_score(DenPoker.PLAYER))) \
			if started and not _poker.folded[DenPoker.PLAYER] else ""
	if done:
		_result.text = _end_text()
	elif running and _poker.actor == DenPoker.PLAYER and not _busy:
		_result.text = Language.translate("Du bist dran.")
	elif running:
		_result.text = Language.translate("%s überlegt …") % _seat_name(_poker.actor)
	# The player's buttons: only on his turn.
	var my_turn: bool = running and _poker.actor == DenPoker.PLAYER and not _busy
	var to_call: int = _poker.get_to_call(DenPoker.PLAYER) if started else 0
	_fold.disabled = not my_turn
	_call.disabled = not my_turn
	_raise.disabled = not my_turn or not _poker.can_raise(DenPoker.PLAYER)
	if to_call == 0:
		_call.text = Language.translate("Schieben")
	elif GameState.gambling_den.coins < to_call:
		_call.text = Language.translate("All-in (%d)") % GameState.gambling_den.coins
	else:
		_call.text = Language.translate("Mitgehen (%d)") % to_call
	var raise_by: int = to_call + _poker.get_bet_size() if started else 0
	_raise.text = (Language.translate("Setzen (%d)") if _poker.current_bet == 0 else Language.translate("Erhöhen (%d)")) % raise_by \
			if started else Language.translate("Erhöhen")
	for button: Button in _blinds.get_children():
		button.button_pressed = int(button.get_meta("big", 0)) == _big
		button.disabled = running or _busy
	_play.disabled = running or _busy or (not running and _poker.get_bot_count() == 0)
	_play.text = Language.translate("Nächste Hand") if done else Language.translate("Spielen")


func _refresh_seat(seat: int, started: bool, done: bool) -> void:
	var box: VBoxContainer = _seats[seat]
	var name_label: Label = box.get_node("Name")
	var status: Label = box.get_node("Status")
	var cards_box: Control = box.get_node("Cards")
	var won: bool = done and _poker.winners.has(seat)
	for card: PlayingCard in cards_box.get_children():
		card.set_glow(won)
	if won:
		status.add_theme_color_override("font_color", COLOR_WIN)
	else:
		status.remove_theme_color_override("font_color")
	# A seat without a bot, or with one who went broke today.
	if seat != DenPoker.PLAYER and _poker.seat_bots[seat].is_empty():
		name_label.text = ""
		status.text = Language.translate("frei")
		cards_box.modulate.a = 0.0
		return
	var broke: bool = seat != DenPoker.PLAYER and _poker.get_seat_coins(seat) <= 0 and not (started and not _poker.folded[seat])
	cards_box.modulate.a = 0.0 if broke else 1.0
	var title: String = _seat_name(seat)
	if seat != DenPoker.PLAYER:
		title += " · %d" % _poker.get_seat_coins(seat)
	if started and seat == _poker.dealer:
		title += " " + Language.translate("(Geber)")
	name_label.text = title
	if broke:
		name_label.add_theme_color_override("font_color", COLOR_IDLE)
		status.text = Language.translate("pleite")
		return
	var active: bool = _poker.is_running() and _poker.actor == seat
	name_label.add_theme_color_override("font_color", COLOR_WIN if won else (COLOR_ACTIVE if active else COLOR_IDLE))
	var is_folded: bool = started and _poker.folded[seat]
	var cards: Array[Node] = box.get_node("Cards").get_children()
	for c in cards.size():
		var card: PlayingCard = cards[c]
		var face_up: bool = started and (seat == DenPoker.PLAYER or (done and _poker.showdown and not is_folded))
		if face_up:
			card.show_card(_poker.hole_cards[seat][c])
		else:
			card.show_back()
		card.modulate.a = 0.35 if is_folded else 1.0
	if not started:
		status.text = ""
	elif won:
		# Showdown: the hand and the coins; everyone else folded: only the coins.
		status.text = Language.translate(DenPoker.get_hand_name(_poker.get_score(seat))) + " · " if _poker.showdown else ""
		status.text += Language.translate("gewinnt") + " +" + DamageKinds.format_number(_won_coins(seat))
	elif done and _poker.showdown and not is_folded:
		status.text = Language.translate(DenPoker.get_hand_name(_poker.get_score(seat)))
	elif active:
		status.text = Language.translate("ist dran")
	else:
		status.text = _action_text(seat)


## Coins `seat` took from the pot (the player: after the house's rake).
func _won_coins(seat: int) -> int:
	return _poker.payout if seat == DenPoker.PLAYER else _poker.won_by_seat[seat]
