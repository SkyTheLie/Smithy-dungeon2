class_name HigherLowerMenu
extends StationMenu
## Window of the card player at the right table of the gambling den: "Höher oder Tiefer" for
## gaming coins (bought from Vex at the bar). Rules and coins: GamblingDen. The window only shows
## and calls.
## A hand: pay the bet (it becomes the pot), he shows a card, the player guesses higher or lower;
## right = the pot grows and the new card is the shown one, wrong = the pot is gone. After a right
## guess the player can cash in. Closing the window with won rounds cashes in; before the first
## guess the hand stays open (closing must not give the bet back, or one could peek at the card).

## Seconds the next card lies face down before it is turned.
const TURN_SECONDS: float = 0.35

var _rng := RandomNumberGenerator.new()
var _bet: int = 1
# The running hand lives only in the window (# not saved on purpose: a scene change or loading
# ends it, like leaving the table).
var _in_hand: bool = false
var _turning: bool = false
var _pot: float = 0.0
var _rounds: int = 0
var _shown: Dictionary = {}

@onready var _coins_label: Label = %CoinsLabel
@onready var _shown_card: PlayingCard = %ShownCard
@onready var _next_card: PlayingCard = %NextCard
@onready var _pot_label: Label = %PotLabel
@onready var _bets: HBoxContainer = %Bets
@onready var _deal: Button = %DealButton
@onready var _higher: Button = %HigherButton
@onready var _lower: Button = %LowerButton
@onready var _take: Button = %TakeButton
@onready var _result: Label = %ResultLabel


func _ready() -> void:
	super()
	_rng.randomize()
	for bet in GamblingDen.get_bets():
		var button := Button.new()
		button.text = DamageKinds.format_number(bet)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_set_bet.bind(bet))
		_bets.add_child(button)
	_deal.pressed.connect(deal)
	_higher.pressed.connect(guess.bind(true))
	_lower.pressed.connect(guess.bind(false))
	_take.pressed.connect(take_pot)
	GameState.gambling_den.coins_changed.connect(_queue_refresh)
	visibility_changed.connect(_on_visibility_changed)
	_set_bet(GamblingDen.get_bets()[0])


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
	elif _in_hand and _rounds > 0 and not _turning:
		take_pot()


func _set_bet(bet: int) -> void:
	if not _in_hand:
		_bet = bet
	_refresh()


## Pays the bet and turns the first card.
func deal() -> void:
	if _in_hand or _turning:
		return
	if not GameState.gambling_den.spend_coins(_bet):
		_result.text = Language.translate("Nicht genug Münzen. Vex an der Bar verkauft welche.")
		_refresh()
		return
	_in_hand = true
	_pot = _bet
	_rounds = 0
	_shown = GamblingDen.draw_card(_rng)
	_shown_card.show_card(_shown)
	_next_card.show_back()
	_result.text = Language.translate("Höher oder tiefer?")
	_refresh()


## The player's guess: the next card is turned after a moment.
func guess(higher: bool) -> void:
	var rank: int = int(_shown.get("rank", 0))
	if not _in_hand or _turning or GamblingDen.get_multiplier(rank, higher) <= 0.0:
		return
	_turning = true
	_refresh()
	var next: Dictionary = GamblingDen.draw_card(_rng)
	await get_tree().create_timer(TURN_SECONDS, false).timeout
	if not is_inside_tree():
		return
	_turning = false
	_next_card.show_card(next)
	if GamblingDen.is_right_guess(rank, int(next.rank), higher):
		_pot = GamblingDen.get_next_pot(_pot, rank, higher)
		_rounds += 1
		_shown = next
		_shown_card.show_card(_shown)
		_next_card.show_back()
		if _rounds >= GamblingDen.get_max_rounds():
			take_pot()
			_result.text = Language.translate("Er winkt ab: genug für eine Hand. %d Münzen für dich.") % GamblingDen.get_payout(_pot)
		else:
			_result.text = Language.translate("Richtig! Im Topf: %d Münzen.") % GamblingDen.get_payout(_pot)
			if not visible:
				take_pot()
	else:
		_in_hand = false
		_result.text = Language.translate("Er grinst. Der Topf gehört ihm.")
		if not visible:
			GameState.show_message(_result.text)
	_refresh()


## Takes the pot (only after at least one right guess).
func take_pot() -> void:
	if not _in_hand or _rounds == 0 or _turning:
		return
	_in_hand = false
	GameState.gambling_den.add_coins(GamblingDen.get_payout(_pot))
	_result.text = Language.translate("Du kassierst %d Münzen.") % GamblingDen.get_payout(_pot)
	if not visible:
		GameState.show_message(_result.text)
	_refresh()


func _refresh() -> void:
	_refresh_done()
	_coins_label.text = Language.translate("Münzen: %d") % GameState.gambling_den.coins
	for button: Button in _bets.get_children():
		button.button_pressed = int(button.text) == _bet
		button.disabled = _in_hand
	_deal.text = Language.translate("Austeilen (%d)") % _bet
	_deal.disabled = _in_hand or _turning
	var rank: int = int(_shown.get("rank", 0))
	for pair: Array in [[_higher, true, "Höher"], [_lower, false, "Tiefer"]]:
		var button: Button = pair[0]
		var multiplier: float = GamblingDen.get_multiplier(rank, pair[1]) if _in_hand else 0.0
		button.text = Language.translate(pair[2]) + (" ×%s" % DamageKinds.format_number(multiplier) if multiplier > 0.0 else "")
		button.disabled = not _in_hand or _turning or multiplier <= 0.0
	_take.disabled = not _in_hand or _turning or _rounds == 0
	if _in_hand:
		_pot_label.text = Language.translate("Topf: %d Münzen, Tipp %d von %d") % [GamblingDen.get_payout(_pot), _rounds + 1, GamblingDen.get_max_rounds()]
	else:
		_pot_label.text = ""
		if _shown.is_empty():
			_shown_card.show_back()
