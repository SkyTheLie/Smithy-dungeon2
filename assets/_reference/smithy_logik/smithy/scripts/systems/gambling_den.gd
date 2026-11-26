class_name GamblingDen
extends RefCounted
## The gambling den above the black market in Leonheim (lives in GameState.gambling_den, saved):
## its currency are gaming coins, bought from Vex, the bartender; they can't be changed back into
## gold. The slot machines, the card player at the right table ("Höher oder Tiefer") and the poker
## table on the left (DenPoker) take and pay coins only.
## Höher oder Tiefer: the card player shows a card (rank 2 .. 14 = ace, every rank equally likely), the player
## bets whether the next card is higher or lower; the same rank wins for the house. A right guess
## multiplies the pot by house_edge / chance (one decimal, rounded down), then the player cashes
## in or guesses on (at most max_rounds guesses). The pot keeps its fractions and is rounded down
## only when cashed in, so every guess, also a sure-looking one, keeps the house edge.
## Also decides where the beggar with the shell game sits: some days in the village, then some in
## the den (economy.json "gambling_den").

signal coins_changed(coins: int)
## Who sits at the poker table today, or a bot's coins changed (PokerTable, PokerMenu).
signal poker_table_changed

const LOWEST_RANK: int = 2
const HIGHEST_RANK: int = 14
const SUITS: int = 4

## Gaming coins of the player.
var coins: int = 0
## The poker table today (prepare_poker_table): the day it was rolled, the bots at seats 1..3
## (ids of economy.json gambling_den.poker.bots, "" = empty seat) and each one's coins left today.
var poker_day: int = -1
var poker_seats: Array[String] = []
var poker_stacks: Dictionary[String, int] = {}


static func settings() -> Dictionary:
	return ContentDB.economy("gambling_den")


static func get_coin_price() -> int:
	return int(settings().get("coin_price", 10))


## What Vex asks in coins for something worth `gold_price` gold: × prize_factor (1 = as dear as
## the black-market price in gold; winnings at the tables make it cheaper), at least 1 coin.
static func get_prize_price(gold_price: int) -> int:
	if gold_price <= 0:
		return 0
	return maxi(1, ceili(gold_price * float(settings().get("prize_factor", 1.0)) / get_coin_price()))


## Buys `amount` coins with gold. false (nothing bought) without enough gold or for amount <= 0.
func buy_coins(amount: int) -> bool:
	if amount <= 0 or not GameState.spend_gold(amount * get_coin_price()):
		return false
	_set_coins(coins + amount)
	return true


## Pays a bet. false (nothing paid) without enough coins or for amount <= 0.
func spend_coins(amount: int) -> bool:
	if amount <= 0 or amount > coins:
		return false
	_set_coins(coins - amount)
	return true


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	AudioManager.play_sound("coins")
	_set_coins(coins + amount)


func _set_coins(value: int) -> void:
	coins = value
	coins_changed.emit(coins)


# --- Höher oder Tiefer -----------------------------------------------------------

## A random card: {"rank": 2 .. 14, "suit": 0 .. 3}.
static func draw_card(rng: RandomNumberGenerator) -> Dictionary:
	return {"rank": rng.randi_range(LOWEST_RANK, HIGHEST_RANK), "suit": rng.randi_range(0, SUITS - 1)}


## Chance that the next card is higher (`higher`) or lower than `rank`.
static func win_chance(rank: int, higher: bool) -> float:
	var ranks: int = HIGHEST_RANK - LOWEST_RANK + 1
	var better: int = HIGHEST_RANK - rank if higher else rank - LOWEST_RANK
	return float(better) / ranks


## What a right guess multiplies the pot by (0 = the guess can't win, e.g. "higher" on an ace).
static func get_multiplier(rank: int, higher: bool) -> float:
	var chance: float = win_chance(rank, higher)
	if chance <= 0.0:
		return 0.0
	var fair: float = float(settings().get("house_edge", 0.95)) / chance
	return floorf(fair * 10.0) / 10.0


## The pot after a right guess (with fractions; GamblingDen.get_payout rounds it down).
static func get_next_pot(pot: float, rank: int, higher: bool) -> float:
	return pot * get_multiplier(rank, higher)


## Coins the player gets for a pot.
static func get_payout(pot: float) -> int:
	return floori(pot + 0.0001)


static func is_right_guess(shown_rank: int, next_rank: int, higher: bool) -> bool:
	return next_rank > shown_rank if higher else next_rank < shown_rank


static func get_max_rounds() -> int:
	return int(settings().get("max_rounds", 6))


static func get_bets() -> Array[int]:
	var bets: Array[int] = []
	for bet: Variant in settings().get("bets", [1]):
		bets.append(int(bet))
	return bets


# --- The beggar --------------------------------------------------------------------

## true on the days the beggar sits in the gambling den instead of the village square: he takes
## turns, beggar_village_days in the village (from day 1), then beggar_den_days in the den.
static func is_beggar_in_den(day: int) -> bool:
	var village_days: int = maxi(int(settings().get("beggar_village_days", 3)), 1)
	var den_days: int = maxi(int(settings().get("beggar_den_days", 2)), 0)
	return (maxi(day, 1) - 1) % (village_days + den_days) >= village_days


## Where the beggar is today: in the den on his den days and while the villagers are away.
static func is_beggar_in_den_today() -> bool:
	return GameState.story.are_villagers_away() or is_beggar_in_den(GameState.day_cycle.day)


# --- The bots at the poker table --------------------------------------------------------

## The bots of economy.json gambling_den.poker.bots by id.
static func get_poker_bots() -> Dictionary:
	var bots: Dictionary = {}
	for bot: Dictionary in settings().get("poker", {}).get("bots", []):
		bots[str(bot.get("id", ""))] = bot
	return bots


static func get_poker_bot(id: String) -> Dictionary:
	return get_poker_bots().get(id, {})


## On the first visit of a new day: 2-3 random bots (poker.bots_per_day) sit down at random seats,
## each with a random bankroll (poker.bankroll, e.g. 100-700 coins). Who goes broke stays broke until
## the next day.
func prepare_poker_table() -> void:
	var day: int = GameState.day_cycle.day
	if day == poker_day and poker_seats.size() == 3:
		return
	poker_day = day
	var ids: Array = get_poker_bots().keys()
	ids.shuffle()
	var count_range: Array = settings().get("poker", {}).get("bots_per_day", [2, 3])
	var count: int = clampi(randi_range(int(count_range[0]), int(count_range[-1])), 1, mini(3, ids.size()))
	var seats: Array[String] = ["", "", ""]
	var free: Array = [0, 1, 2]
	free.shuffle()
	poker_stacks = {}
	for i in count:
		seats[free[i]] = ids[i]
		poker_stacks[ids[i]] = roll_bankroll()
	poker_seats = seats
	poker_table_changed.emit()


## Coins a bot starts a day with: random in poker.bankroll [from, to].
static func roll_bankroll() -> int:
	var range_of: Array = settings().get("poker", {}).get("bankroll", [300, 300])
	return randi_range(int(range_of[0]), int(range_of[-1]))


## The lowest and highest bankroll of a day (poker.bankroll).
static func get_bankroll_range() -> Vector2i:
	var range_of: Array = settings().get("poker", {}).get("bankroll", [300, 300])
	return Vector2i(int(range_of[0]), int(range_of[-1]))


## Coins bot `id` has left today (0 = broke or not here).
func get_bot_stack(id: String) -> int:
	return int(poker_stacks.get(id, 0))


## After a hand: the bots' coins (DenPoker writes back what they won or lost).
func set_bot_stacks(stacks: Dictionary) -> void:
	for id: String in stacks:
		if poker_stacks.has(id):
			poker_stacks[id] = maxi(0, int(stacks[id]))
	poker_table_changed.emit()


func to_save_data() -> Dictionary:
	return {"coins": coins, "poker_day": poker_day, "poker_seats": poker_seats.duplicate(),
			"poker_stacks": poker_stacks.duplicate()}


func load_save_data(data: Dictionary) -> void:
	_set_coins(maxi(int(data.get("coins", 0)), 0))
	poker_day = int(data.get("poker_day", -1))
	var known: Dictionary = get_poker_bots()
	poker_seats.clear()
	for id: Variant in data.get("poker_seats", []):
		var bot_id: String = _current_bot_id(str(id))
		poker_seats.append(bot_id if known.has(bot_id) else "")
	poker_stacks.clear()
	var stacks: Dictionary = data.get("poker_stacks", {})
	for id: Variant in stacks:
		var bot_id: String = _current_bot_id(str(id))
		if known.has(bot_id):
			poker_stacks[bot_id] = int(stacks[id])
	poker_table_changed.emit()


## Old saves: bots that were replaced keep their seat and coins under the new id
## (2026-11-21: Die Wache » Barde Lio, Die Adlige » Händlerin Grete).
const REPLACED_BOTS: Dictionary = {"wache": "lio", "adlige": "grete"}


static func _current_bot_id(id: String) -> String:
	return str(REPLACED_BOTS.get(id, id))
