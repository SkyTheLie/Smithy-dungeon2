class_name DenPoker
extends RefCounted
## Poker at the left table of the gambling den: Limit Texas Hold'em, the player against the bots
## who sit there today (GamblingDen.prepare_poker_table: 2-3 of the six in economy.json
## gambling_den.poker.bots, each with a random bankroll for the day; broke = out until tomorrow).
## PokerMenu shows it and paces the bots. Seats clockwise: 0 = the player (bottom), 1 = left,
## 2 = top, 3 = right; a seat without a bot or with a broke bot is empty.
## A hand: the dealer button moves to the next seat in play, the next two post the small and the
## big blind (two players: the dealer is the small blind), everyone gets two cards. Four betting
## rounds (before the flop, flop = three table cards, turn, river = one more each). Before the flop
## the seat after the big blind starts, later the first seat after the dealer. Who is to act folds,
## checks / calls or raises by the fixed bet (big blind before the flop and on the flop, twice that
## on turn and river), at most `raise_cap` raises a round. A round ends when everyone still able
## to bet has acted since the last raise. Whoever is left after the river shows: best five of seven
## cards, ties split.
## Who can't pay a call goes all-in with what is left; side pots keep him from winning more from
## each than he put in. When fewer than two can still bet, the rest is dealt without bets.
## The player pays with his coins (GameState.gambling_den), the bots with their stacks of today
## (written back after the hand). The house keeps `rake` of the player's profit (what the others paid into his pot).
## Bot styles: "heuristic" (hand strength + looseness + chance against call / raise thresholds,
## `pot_odds` also weighs the price of a call) and "equity" (plays `sims` random endings of the
## hand against the others still in and compares the chance to win with the price of a call).
## A hand lives only here (# not saved on purpose: a scene change, loading or standing up folds;
## what the bots won or lost so far in it is written back when it ends).
## Cards: {"rank": 2 .. 14, "suit": 0 .. 3}, one 52-card deck per hand.

enum Street { IDLE, PREFLOP, FLOP, TURN, RIVER, DONE }
enum Action { FOLD, CALL, RAISE }

const PLAYER: int = 0
const SEATS: int = 4
## Hand categories (evaluate()[0]), names for the window.
const HAND_NAMES: Array[String] = ["Höchste Karte", "Ein Paar", "Zwei Paare", "Drilling", "Straße",
		"Flush", "Full House", "Vierling", "Straight Flush"]
const TABLE_CARDS_AFTER: Dictionary = {Street.PREFLOP: 0, Street.FLOP: 3, Street.TURN: 4, Street.RIVER: 5}

var street: Street = Street.IDLE
var big_blind: int = 0
## Dealer button, small and big blind seat of this hand (the first hand: the player deals).
var dealer: int = -1
var small_blind_seat: int = 0
var big_blind_seat: int = 0
## Bot id at each seat this hand ("" = the player at 0, or an empty seat).
var seat_bots: Array[String] = ["", "", "", ""]
## true = the seat plays this hand (the player, or a bot with coins).
var seated: Array[bool] = [true, false, false, false]
## Coins of each bot seat (the player's are GameState.gambling_den.coins).
var stacks: Array[int] = [0, 0, 0, 0]
## Two cards per seat.
var hole_cards: Array = []
## The five table cards; only the first get_table_count() are shown.
var table_cards: Array[Dictionary] = []
var folded: Array[bool] = []
var all_in: Array[bool] = []
## Coins each seat put in this hand / in this betting round.
var paid: Array[int] = []
var round_bets: Array[int] = []
## The highest bet of this round, raises made in it.
var current_bet: int = 0
var raises: int = 0
## Last action of each seat for the window: {"kind": "small_blind" / "big_blind" / "fold" /
## "check" / "call" / "raise" / "all_in", "amount": coins}; {} = nothing yet.
var last_action: Array[Dictionary] = []
## How much each seat has shown this hand (for the reading bot): 0 = only checked or blinds,
## 1 = called a bet, 2 = raised.
var aggression: Array[int] = [0, 0, 0, 0]
## Who is to act now (-1 = nobody: the hand is over).
var actor: int = -1
## After DONE: coins the player got (0 = lost), the seats that won (or shared) the main pot,
## whether the cards were shown, what each seat won.
var payout: int = 0
var winners: Array[int] = []
var player_won: bool = false
var showdown: bool = false
var won_by_seat: Array[int] = [0, 0, 0, 0]

var _rng: RandomNumberGenerator
var _table_shown: int = 0
## Seats that still have to act this round.
var _pending: Array[int] = []


func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()


static func settings() -> Dictionary:
	return GamblingDen.settings().get("poker", {})


## The big blinds the player can pick (the small blind is half, at least 1).
static func get_blinds() -> Array[int]:
	var blinds: Array[int] = []
	for value: Variant in settings().get("blinds", [2]):
		blinds.append(int(value))
	return blinds


static func get_small_blind(big: int) -> int:
	@warning_ignore("integer_division")
	return maxi(1, big / 2)


static func get_rake() -> float:
	return float(settings().get("rake", 0.0))


static func get_raise_cap() -> int:
	return int(settings().get("raise_cap", 3))


func is_running() -> bool:
	return street != Street.IDLE and street != Street.DONE


## How many table cards are face up now.
func get_table_count() -> int:
	return _table_shown


## The fixed bet of this round: the big blind, on turn and river twice that.
func get_bet_size() -> int:
	return big_blind * (2 if street == Street.TURN or street == Street.RIVER else 1)


func get_pot() -> int:
	var pot: int = 0
	for value in paid:
		pot += value
	return pot


## Coins `seat` can still bet (the player: his coins).
func get_seat_coins(seat: int) -> int:
	return GameState.gambling_den.coins if seat == PLAYER else stacks[seat]


## What `seat` still has to put in to call (0 = can check).
func get_to_call(seat: int) -> int:
	return maxi(0, current_bet - round_bets[seat])


## Whether `seat` may raise now (raise cap, and the coins for call plus raise).
func can_raise(seat: int) -> bool:
	return raises < get_raise_cap() and get_seat_coins(seat) >= get_to_call(seat) + get_bet_size()


## The bots of today in their seats (GamblingDen), with their coins; who has none sits out.
func take_seats() -> void:
	var den: GamblingDen = GameState.gambling_den
	den.prepare_poker_table()
	for seat in range(1, SEATS):
		var id: String = den.poker_seats[seat - 1] if seat - 1 < den.poker_seats.size() else ""
		seat_bots[seat] = id
		stacks[seat] = den.get_bot_stack(id) if not id.is_empty() else 0
		seated[seat] = stacks[seat] > 0


## Seats with a bot that still has coins.
func get_bot_count() -> int:
	var count: int = 0
	for seat in range(1, SEATS):
		if seated[seat]:
			count += 1
	return count


## Starts a hand with this big blind: the bots of today sit down, the button moves on, the blinds
## are posted, cards dealt. false (nothing happens) while a hand runs, for big <= 0, with fewer
## coins than the big blind, or without a bot with coins at the table.
func start(big: int) -> bool:
	if is_running() or big <= 0 or GameState.gambling_den.coins < big:
		return false
	take_seats()
	if get_bot_count() == 0:
		return false
	big_blind = big
	dealer = _next_seated(dealer + 1)
	if get_bot_count() == 1:
		# Two players: the dealer posts the small blind.
		small_blind_seat = dealer
		big_blind_seat = _next_seated(dealer + 1)
	else:
		small_blind_seat = _next_seated(dealer + 1)
		big_blind_seat = _next_seated(small_blind_seat + 1)
	var deck: Array[Dictionary] = _new_deck()
	hole_cards = []
	for seat in SEATS:
		hole_cards.append([deck.pop_back(), deck.pop_back()])
	table_cards = []
	for i in 5:
		table_cards.append(deck.pop_back())
	folded = []
	all_in = [false, false, false, false]
	for seat in SEATS:
		folded.append(not seated[seat])
	paid = [0, 0, 0, 0]
	round_bets = [0, 0, 0, 0]
	won_by_seat = [0, 0, 0, 0]
	aggression = [0, 0, 0, 0]
	last_action = [{}, {}, {}, {}]
	payout = 0
	winners = []
	player_won = false
	showdown = false
	_table_shown = 0
	street = Street.PREFLOP
	raises = 0
	current_bet = 0
	_put_in(small_blind_seat, get_small_blind(big))
	last_action[small_blind_seat] = {"kind": "small_blind", "amount": round_bets[small_blind_seat]}
	_put_in(big_blind_seat, big)
	last_action[big_blind_seat] = {"kind": "big_blind", "amount": round_bets[big_blind_seat]}
	current_bet = big
	# Everyone acts before the flop, the big blind last (he may still raise).
	_pending = _active_seats()
	actor = _next_pending(big_blind_seat + 1)
	if actor < 0:
		_after_round(big_blind_seat)
	return true


func _new_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	for suit in GamblingDen.SUITS:
		for rank in range(GamblingDen.LOWEST_RANK, GamblingDen.HIGHEST_RANK + 1):
			deck.append({"rank": rank, "suit": suit})
	# Fisher-Yates with our own rng (seedable in tests).
	for i in range(deck.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: Dictionary = deck[i]
		deck[i] = deck[j]
		deck[j] = swap
	return deck


## The seat to act does `action`. false (nothing happens) if it is not that seat's turn or a raise
## isn't allowed.
func act(seat: int, action: Action) -> bool:
	if not is_running() or seat != actor:
		return false
	if action == Action.RAISE and not can_raise(seat):
		return false
	var to_call: int = get_to_call(seat)
	match action:
		Action.FOLD:
			folded[seat] = true
			last_action[seat] = {"kind": "fold", "amount": 0}
		Action.CALL:
			var put: int = _put_in(seat, to_call)
			var kind: String = "check" if to_call == 0 else "call"
			if to_call > 0:
				aggression[seat] = maxi(aggression[seat], 1)
			if all_in[seat]:
				kind = "all_in"
			last_action[seat] = {"kind": kind, "amount": put}
		Action.RAISE:
			_put_in(seat, to_call + get_bet_size())
			current_bet = round_bets[seat]
			raises += 1
			aggression[seat] = 2
			last_action[seat] = {"kind": "all_in" if all_in[seat] else "raise", "amount": round_bets[seat]}
			# Everyone else still able to bet has to answer the raise.
			_pending = _active_seats()
	_pending.erase(seat)
	_after_action(seat)
	return true


## Lets the bot whose turn it is act. false if it isn't a bot's turn.
func bot_act() -> bool:
	if actor <= PLAYER:
		return false
	return act(actor, decide_bot(actor))


## What bot `seat` does now, by its style (economy.json poker.bots).
func decide_bot(seat: int) -> Action:
	var bot: Dictionary = GamblingDen.get_poker_bot(seat_bots[seat])
	if str(bot.get("style", "heuristic")) == "equity":
		return _decide_equity(seat, bot)
	return _decide_heuristic(seat, bot)


## Hand strength with the table cards it sees, plus looseness and chance, against the thresholds
## of this round; `pot_odds`: a cheap call (small part of the pot) lowers the call threshold;
## `fold_to_raise`: chance to give up when facing a raise (the easy bot).
func _decide_heuristic(seat: int, bot: Dictionary) -> Action:
	var round_index: int = street - Street.PREFLOP
	var call_at: float = _threshold(bot, "call_thresholds", round_index, 0.3)
	var raise_at: float = _threshold(bot, "raise_thresholds", round_index, 0.8)
	var hole: Array[Dictionary] = []
	hole.assign(hole_cards[seat])
	var bluff: float = float(bot.get("bluff", 0.1))
	var strength: float = hand_strength(hole, get_shown_table()) + float(bot.get("looseness", 0.0)) \
			+ _rng.randf_range(-bluff, bluff)
	var to_call: int = get_to_call(seat)
	if bool(bot.get("pot_odds", false)) and to_call > 0:
		var price: float = float(to_call) / (get_pot() + to_call)
		call_at += (price - 0.25) * 0.6
	if strength >= raise_at and can_raise(seat):
		return Action.RAISE
	# A timid player gets cold feet when someone raised (fold_to_raise: chance to fold anyway).
	if to_call > 0 and raises > 0 and _rng.randf() < float(bot.get("fold_to_raise", 0.0)):
		return Action.FOLD
	if to_call == 0 or strength >= call_at:
		return Action.CALL
	return Action.FOLD


## Monte Carlo: its chance to win against everyone still in, compared with what a call costs of
## the pot after it. It reads the others: who raised this hand likely holds a good hand, who called
## a fair one (their sampled cards must be at least that strong). Raises when clearly ahead,
## sometimes bluffs.
func _decide_equity(seat: int, bot: Dictionary) -> Action:
	var others: Array[int] = _seats_in()
	others.erase(seat)
	var ranges: Array[float] = []
	for other in others:
		ranges.append([0.0, 0.25, 0.5][aggression[other]])
	var to_call: int = get_to_call(seat)
	var equity: float = estimate_equity(seat, ranges, int(bot.get("sims", 200)))
	var price: float = float(to_call) / (get_pot() + to_call) if to_call > 0 else 0.0
	var fair: float = 1.0 / (others.size() + 1)
	# Bluffs after the flop; when nobody bet (checked to her) she steals more often.
	var bluff: float = float(bot.get("bluff", 0.05)) * (2.5 if to_call == 0 else 1.0)
	var bluffing: bool = _rng.randf() < bluff and street >= Street.FLOP
	# Raise for value when clearly ahead of a fair share (heads-up from 58 %, against three from 40 %).
	if (equity >= fair + (1.0 - fair) * 0.15 or bluffing) and can_raise(seat):
		return Action.RAISE
	if to_call == 0 or equity >= price + 0.03:
		return Action.CALL
	return Action.FOLD


## Chance 0 .. 1 that `seat` wins (ties count shared) against one unknown hand per entry of
## `ranges` (the least hand_strength that opponent is believed to hold), from `sims` random
## endings with what `seat` can see (its cards and the open table cards).
func estimate_equity(seat: int, ranges: Array[float], sims: int) -> float:
	var hole: Array[Dictionary] = _hole(seat)
	var board: Array[Dictionary] = get_shown_table()
	var known: Dictionary = {}
	for card in join(hole, board):
		known[int(card.rank) * 4 + int(card.suit)] = true
	var rest: Array[Dictionary] = []
	for suit in GamblingDen.SUITS:
		for rank in range(GamblingDen.LOWEST_RANK, GamblingDen.HIGHEST_RANK + 1):
			if not known.has(rank * 4 + suit):
				rest.append({"rank": rank, "suit": suit})
	var missing: int = 5 - board.size()
	var score: float = 0.0
	for i in maxi(1, sims):
		# A random draw without shuffling the whole rest: swap the needed cards to the front.
		for k in missing:
			_swap_random(rest, k)
		var full_board: Array[Dictionary] = board.duplicate()
		for k in missing:
			full_board.append(rest[k])
		var mine: Array[int] = evaluate(join(hole, full_board))
		var winning: bool = true
		var ties: int = 1
		var next: int = missing
		for least in ranges:
			# Hands weaker than what this opponent showed are drawn again (a few tries).
			var theirs: Array[Dictionary] = []
			for attempt in 8:
				_swap_random(rest, next)
				_swap_random(rest, next + 1)
				theirs = [rest[next], rest[next + 1]]
				if least <= 0.0 or hand_strength(theirs, board) >= least:
					break
			next += 2
			var versus: int = compare(evaluate(join(theirs, full_board)), mine)
			if versus > 0:
				winning = false
				break
			if versus == 0:
				ties += 1
		if winning:
			score += 1.0 / ties
	return score / maxi(1, sims)


## Swaps a random card from index `at` on into place `at`.
func _swap_random(cards: Array[Dictionary], at: int) -> void:
	var j: int = _rng.randi_range(at, cards.size() - 1)
	var swap: Dictionary = cards[at]
	cards[at] = cards[j]
	cards[j] = swap


static func _threshold(bot: Dictionary, key: String, round_index: int, fallback: float) -> float:
	var values: Array = bot.get(key, [fallback])
	return float(values[clampi(round_index, 0, values.size() - 1)])


## The player gives up (also when standing up from the table).
func fold() -> void:
	if not is_running():
		return
	folded[PLAYER] = true
	last_action[PLAYER] = {"kind": "fold", "amount": 0}
	_finish()


# --- Inside a hand ------------------------------------------------------------------------

## Puts up to `amount` coins of `seat` into the pot (what it has: all-in if short).
func _put_in(seat: int, amount: int) -> int:
	if amount <= 0:
		return 0
	amount = mini(amount, get_seat_coins(seat))
	if seat == PLAYER:
		GameState.gambling_den.spend_coins(amount)
	else:
		stacks[seat] -= amount
	if get_seat_coins(seat) == 0:
		all_in[seat] = true
	paid[seat] += amount
	round_bets[seat] += amount
	return amount


## Seats still in that can still bet (not folded, not all-in).
func _active_seats() -> Array[int]:
	var seats: Array[int] = []
	for seat in SEATS:
		if not folded[seat] and not all_in[seat]:
			seats.append(seat)
	return seats


func _next_seated(from: int) -> int:
	for step in SEATS:
		var seat: int = posmod(from + step, SEATS)
		if seated[seat]:
			return seat
	return PLAYER


## The first seat from `from` on (clockwise) that still has to act, -1 = none.
func _next_pending(from: int) -> int:
	for step in SEATS:
		var seat: int = posmod(from + step, SEATS)
		if _pending.has(seat):
			return seat
	return -1


func _seats_in() -> Array[int]:
	var seats: Array[int] = []
	for seat in SEATS:
		if not folded[seat]:
			seats.append(seat)
	return seats


func _after_action(seat: int) -> void:
	if folded[PLAYER] or _seats_in().size() == 1:
		_finish()
		return
	for other in SEATS:
		if all_in[other]:
			_pending.erase(other)
	# Nobody else can bet against the one still able to: no need to ask him (unless he must call).
	if _active_seats().size() == 1 and get_to_call(_active_seats()[0]) == 0:
		_pending.clear()
	actor = _next_pending(seat + 1)
	if actor < 0:
		_after_round(seat)


## Round over: next street (or the showdown after the river); with fewer than two able to bet,
## the rest is dealt without bets.
func _after_round(_seat: int) -> void:
	while true:
		if street == Street.RIVER:
			_finish()
			return
		street = (street + 1) as Street
		_table_shown = int(TABLE_CARDS_AFTER[street])
		round_bets = [0, 0, 0, 0]
		current_bet = 0
		raises = 0
		for other in SEATS:
			if not folded[other] and not all_in[other]:
				last_action[other] = {}
		_pending = _active_seats()
		if _pending.size() >= 2:
			actor = _next_pending(dealer + 1)
			return


## Ends the hand: the showdown with side pots (layers of what was paid) and the bots' coins back
## to GamblingDen.
func _finish() -> void:
	street = Street.DONE
	actor = -1
	_pending.clear()
	var still_in: Array[int] = _seats_in()
	showdown = still_in.size() > 1 and not folded[PLAYER]
	if showdown:
		_table_shown = 5
	var scores: Dictionary = {}
	for seat in still_in:
		scores[seat] = evaluate(join(_hole(seat), table_cards))
	var levels: Array[int] = []
	for value in paid:
		if value > 0 and not levels.has(value):
			levels.append(value)
	levels.sort()
	var previous: int = 0
	winners = []
	for level in levels:
		var layer: int = 0
		for seat in SEATS:
			layer += mini(paid[seat], level) - mini(paid[seat], previous)
		var best: Array[int] = []
		for seat in still_in:
			if paid[seat] < level:
				continue
			if best.is_empty() or compare(scores[seat], scores[best[0]]) > 0:
				best = [seat]
			elif compare(scores[seat], scores[best[0]]) == 0:
				best.append(seat)
		if best.is_empty():
			# Nobody still in paid this much (the rest folded): back to who paid it.
			for seat in SEATS:
				won_by_seat[seat] += mini(paid[seat], level) - mini(paid[seat], previous)
		else:
			if winners.is_empty():
				winners = best
			for k in best.size():
				@warning_ignore("integer_division")
				won_by_seat[best[k]] += layer / best.size() + (layer % best.size() if k == 0 else 0)
		previous = level
	payout = get_payout(won_by_seat[PLAYER], paid[PLAYER])
	player_won = payout > 0
	if payout > 0:
		GameState.gambling_den.add_coins(payout)
	var bot_stacks: Dictionary = {}
	for seat in range(1, SEATS):
		if not seat_bots[seat].is_empty():
			stacks[seat] += won_by_seat[seat]
			bot_stacks[seat_bots[seat]] = stacks[seat]
	GameState.gambling_den.set_bot_stacks(bot_stacks)


func _hole(seat: int) -> Array[Dictionary]:
	var hole: Array[Dictionary] = []
	hole.assign(hole_cards[seat])
	return hole


# --- Cards and hands ----------------------------------------------------------------------

## The table cards face up now.
func get_shown_table() -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	shown.assign(table_cards.slice(0, _table_shown))
	return shown


## Best hand of `seat` with the table cards face up now.
func get_score(seat: int) -> Array[int]:
	return evaluate(join(_hole(seat), get_shown_table()))


## Name of `seat` for the window (German key, translate it): its bot's name, "Du" for the player.
func get_seat_name(seat: int) -> String:
	if seat == PLAYER:
		return "Du"
	return str(GamblingDen.get_poker_bot(seat_bots[seat]).get("name", ""))


static func join(a: Array[Dictionary], b: Array[Dictionary]) -> Array[Dictionary]:
	var cards: Array[Dictionary] = a.duplicate()
	cards.append_array(b)
	return cards


## Name (German key, translate it) of a score from evaluate().
static func get_hand_name(score: Array[int]) -> String:
	return HAND_NAMES[score[0]]


## Coins the player gets for `share` of the pot when he put `own` in: the house keeps its rake of
## the profit only (what the others paid), never of his own coins.
static func get_payout(share: int, own: int = 0) -> int:
	var profit: int = maxi(0, share - own)
	# Rounded down: small pots cost no rake.
	return share - floori(profit * get_rake() + 0.0001)


## Rough strength 0 .. 1 of two hole cards with the table cards seen so far (for the opponents).
static func hand_strength(hole: Array[Dictionary], table: Array[Dictionary]) -> float:
	var high: int = maxi(int(hole[0].rank), int(hole[1].rank))
	var low: int = mini(int(hole[0].rank), int(hole[1].rank))
	if table.is_empty():
		if high == low:
			return 0.5 + high / 28.0
		var value: float = (high + low) / 28.0 * 0.75
		if int(hole[0].suit) == int(hole[1].suit):
			value += 0.05
		if high - low == 1:
			value += 0.03
		return value
	var category: int = evaluate(join(hole, table))[0]
	# A pair or more that lies on the table alone belongs to everyone.
	if category > 0 and evaluate(table)[0] >= category:
		return 0.15 + high / 100.0
	const BY_CATEGORY: Array[float] = [0.15, 0.45, 0.65, 0.75, 0.82, 0.86, 0.92, 0.97, 1.0]
	return BY_CATEGORY[category] + (high / 100.0 if category == 0 else 0.0)


## Score of the best five of `cards` (5 .. 7): [category (0 = high card .. 8 = straight flush),
## tie breakers ...]; compare two with compare().
static func evaluate(cards: Array[Dictionary]) -> Array[int]:
	var counts: Dictionary[int, int] = {}
	var by_suit: Dictionary[int, Array] = {}
	for card in cards:
		var rank: int = int(card.rank)
		counts[rank] = counts.get(rank, 0) + 1
		if not by_suit.has(int(card.suit)):
			by_suit[int(card.suit)] = []
		by_suit[int(card.suit)].append(rank)
	for suit: int in by_suit:
		if by_suit[suit].size() >= 5:
			var flush_ranks: Array[int] = []
			flush_ranks.assign(by_suit[suit])
			var straight_flush: int = _straight_top(flush_ranks)
			if straight_flush > 0:
				return [8, straight_flush]
			flush_ranks.sort()
			flush_ranks.reverse()
			var flush: Array[int] = [5]
			flush.append_array(flush_ranks.slice(0, 5))
			# A flush beats everything below a full house; check those first.
			var better: Array[int] = _by_counts(counts)
			return better if better[0] > 5 else flush
	var ranks: Array[int] = []
	ranks.assign(counts.keys())
	var straight: int = _straight_top(ranks)
	var by_counts: Array[int] = _by_counts(counts)
	if straight > 0 and by_counts[0] < 4:
		return [4, straight]
	return by_counts


## Highest rank of a straight in `ranks` (ace also low), 0 = none.
static func _straight_top(ranks: Array[int]) -> int:
	var present: Dictionary[int, bool] = {}
	for rank in ranks:
		present[rank] = true
	if present.has(GamblingDen.HIGHEST_RANK):
		present[1] = true
	for top in range(GamblingDen.HIGHEST_RANK, 4, -1):
		var run: bool = true
		for step in 5:
			if not present.has(top - step):
				run = false
				break
		if run:
			return top
	return 0


## Pairs, trips, quads and full houses (and high card), from the counts of each rank.
static func _by_counts(counts: Dictionary[int, int]) -> Array[int]:
	var groups: Array = []
	for rank: int in counts:
		groups.append([counts[rank], rank])
	# Most of a kind first, then the higher rank.
	groups.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	var first: Array = groups[0]
	var second: Array = groups[1] if groups.size() > 1 else [0, 0]
	var result: Array[int] = []
	if first[0] == 4:
		result = [7, first[1], _kickers(groups, [first[1]], 1)[0]]
	elif first[0] == 3 and second[0] >= 2:
		result = [6, first[1], second[1]]
	elif first[0] == 3:
		result = [3, first[1]]
		result.append_array(_kickers(groups, [first[1]], 2))
	elif first[0] == 2 and second[0] == 2:
		result = [2, first[1], second[1]]
		result.append_array(_kickers(groups, [first[1], second[1]], 1))
	elif first[0] == 2:
		result = [1, first[1]]
		result.append_array(_kickers(groups, [first[1]], 3))
	else:
		result = [0]
		result.append_array(_kickers(groups, [], 5))
	return result


## The `count` highest ranks not in `used`.
static func _kickers(groups: Array, used: Array, count: int) -> Array[int]:
	var ranks: Array[int] = []
	for group: Array in groups:
		if not used.has(group[1]):
			ranks.append(group[1])
	ranks.sort()
	ranks.reverse()
	while ranks.size() < count:
		ranks.append(0)
	return ranks.slice(0, count)


## > 0 if score `a` beats `b`, 0 for a tie.
static func compare(a: Array[int], b: Array[int]) -> int:
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			return 1 if a[i] > b[i] else -1
	return 0


