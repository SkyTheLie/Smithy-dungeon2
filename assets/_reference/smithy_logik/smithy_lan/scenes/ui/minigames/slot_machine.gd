class_name SlotMachine
extends StationMenu
## The slot machine in the black market (window of a Station). Bet 1-5 gold, pull: three reels
## spin and stop one after the other. What comes out is rolled first (economy.json
## "slot_machine.outcomes", e.g. about 30 % win / 70 % lose, jackpot 0.001 %), then the reels are
## made to show it: jackpot = three crowns, three gems, three of a kind, a pair, or three different
## symbols (lost). Winnings = bet x "pays" (the bet is gone either way, so a pair at x2 is +1 bet).

const SYMBOL_DIR: String = "res://assets/sprites/ui/slot/"
## Seconds between two symbols while a reel spins, and how much slower it gets before stopping.
const TICK: float = 0.05
const SLOW_DOWN: float = 1.18

var _bet: int = 1
var _spinning: bool = false
var _rng := RandomNumberGenerator.new()
var _symbols: Dictionary = {}  # symbol id -> Texture2D

@onready var _reels: Array[TextureRect] = [%Reel1, %Reel2, %Reel3]
@onready var _bets: HBoxContainer = %Bets
@onready var _spin_button: Button = %SpinButton
@onready var _result: Label = %ResultLabel
@onready var _gold_label: Label = %GoldLabel


func _ready() -> void:
	super()
	_rng.randomize()
	for symbol: String in _settings().get("symbols", []):
		var path: String = SYMBOL_DIR + symbol + ".png"
		_symbols[symbol] = load(path) if ResourceLoader.exists(path) else null
	for bet: Variant in _settings().get("bets", [1, 2, 3, 4, 5]):
		var button := Button.new()
		button.text = "%d" % int(bet)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_set_bet.bind(int(bet)))
		_bets.add_child(button)
	_spin_button.pressed.connect(_spin)
	for reel in _reels:
		reel.texture = _symbols.values()[0]
	GameState.gold_changed.connect(func(_gold: int) -> void: _update_labels())
	visibility_changed.connect(_update_labels)
	_set_bet(int(_settings().get("bets", [1])[0]))


static func _settings() -> Dictionary:
	return ContentDB.economy("slot_machine")


func _set_bet(bet: int) -> void:
	if _spinning:
		bet = _bet
	_bet = bet
	for button: Button in _bets.get_children():
		button.button_pressed = int(button.text) == _bet
	_update_labels()


func _update_labels() -> void:
	_spin_button.text = Language.translate("Drehen (%d Gold)") % _bet
	_gold_label.text = Language.translate("Dein Gold: %d") % GameState.gold


func _spin() -> void:
	if _spinning:
		return
	if not GameState.spend_gold(_bet):
		_result.text = Language.translate("Nicht genug Gold.")
		return
	_spinning = true
	_spin_button.disabled = true
	_result.text = "..."
	var outcome: Dictionary = roll(_rng)
	var shown: Array = outcome.symbols
	for i in _reels.size():
		_spin_reel(_reels[i], shown[i], float(_settings().get("spin_seconds", 1.2)) + i * 0.45)
	await get_tree().create_timer(float(_settings().get("spin_seconds", 1.2)) + (_reels.size() - 1) * 0.45 + 0.3, false).timeout
	var win: int = _bet * int(outcome.pays)
	if win > 0:
		GameState.add_gold(win)
	_result.text = _result_text(outcome, win)
	# Window closed while the reels ran: the result still reaches the player.
	if not visible:
		GameState.show_message(_result.text)
	_spinning = false
	_spin_button.disabled = false


## One reel: symbols flick by, slower and slower, until it stops on `final`.
func _spin_reel(reel: TextureRect, final: String, seconds: float) -> void:
	var keys: Array = _symbols.keys()
	var wait: float = TICK
	var elapsed: float = 0.0
	while elapsed < seconds:
		reel.texture = _symbols[keys[_rng.randi() % keys.size()]]
		await get_tree().create_timer(wait, false).timeout
		elapsed += wait
		if elapsed > seconds * 0.6:
			wait *= SLOW_DOWN
	reel.texture = _symbols[final]
	var tween: Tween = create_tween()
	reel.position.y -= 3
	tween.tween_property(reel, "position:y", reel.position.y + 3, 0.12).set_trans(Tween.TRANS_BOUNCE)


func _result_text(outcome: Dictionary, win: int) -> String:
	match String(outcome.id):
		"jackpot":
			return Language.translate("JACKPOT!!! %d Gold!") % win
		"lose":
			return Language.translate("Leider nichts. Noch mal?")
	return Language.translate("Gewonnen: %d Gold!") % win


## Rolls one spin: {"id", "pays", "symbols": [3 symbol ids]}. Outcomes from economy.json in order;
## whatever is left over is a loss (three different symbols).
static func roll(rng: RandomNumberGenerator) -> Dictionary:
	var settings: Dictionary = _settings()
	var all_symbols: Array = settings.get("symbols", [])
	var jackpot_symbol: String = settings.get("jackpot_symbol", "")
	var plain: Array = all_symbols.filter(func(s: String) -> bool: return s != jackpot_symbol)
	var draw: float = rng.randf()
	for outcome: Dictionary in settings.get("outcomes", []):
		draw -= float(outcome.get("chance", 0.0))
		if draw >= 0.0:
			continue
		var choices: Array = outcome.get("symbols", plain)
		var symbol: String = choices[rng.randi() % choices.size()]
		var shown: Array = [symbol, symbol, symbol]
		if String(outcome.get("id", "")) == "pair":
			var odd: String = symbol
			while odd == symbol:
				odd = plain[rng.randi() % plain.size()]
			shown[rng.randi() % 3] = odd
		return {"id": outcome.get("id", ""), "pays": int(outcome.get("pays", 0)), "symbols": shown}
	# Lost: three different symbols (a single crown may tease).
	var pool: Array = all_symbols.duplicate()
	pool.shuffle()
	var shown_lost: Array = []
	for symbol: String in pool:
		if shown_lost.size() < 3:
			shown_lost.append(symbol)
	return {"id": "lose", "pays": 0, "symbols": shown_lost}
