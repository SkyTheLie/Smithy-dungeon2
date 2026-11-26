class_name Reputation
extends RefCounted
## The smith's reputation ("Ruf", replaces the old karma): points and a rank F, E, D, C, B, A, S, S+.
## All numbers are in economy.json "reputation" (format: docs/CONTENT.md):
##   ranks: {"id", "from" (points), "required_flag" (story flag needed for the rank, e.g. D only
##          after the raid), "customers" [min, max] per day, "pay_bonus" (% more for orders),
##          "shop_bonus" (% higher prices in the shops), "house_level" (highest house level the
##          builder builds), "color" (of the crest)}
## The rank also decides how hard the forging and joining minigames are for each material
## (ForgeQuality.get_difficulty).
##   gains: points for "order_completed", "order_expired", "rent_late"
##   sale: points for each piece sold in Nina's or the own shop (get_sale_points):
##         (1 + material tier x "per_tier") x (1 + rarity steps above R1 x "per_rarity"), e.g. a copper
##         sword R1 = 1, copper R2 = 2, iron R1 = 2, iron R2 = 4
##   story: {story flag: points}, given once when the flag is set (chapters, quests)
## Points are always collected; a rank whose required_flag is not set yet stays locked until it is.
## Lives in GameState.reputation.

## Points or rank changed.
signal changed
## A new, higher rank was reached (HUD message).
signal rank_reached(rank_id: String)

var points: int = 0
## Story flags whose points were given already.
var granted: Array[String] = []
## Story flags are read through this (set by GameState).
var has_flag: Callable = func(_flag: String) -> bool: return false
var _last_rank: int = 0


# --- Points -----------------------------------------------------------------------------

## Adds (or with a negative amount takes away) points; never below 0.
func add(amount: int) -> void:
	if amount == 0:
		return
	points = maxi(0, points + amount)
	_after_change()


## Points of a gain from economy.json "reputation.gains" (e.g. "order_completed").
func add_gain(key: String) -> void:
	add(get_gain(key))


## Points for selling `stack` in a shop (economy.json "reputation.sale"): better metal and
## higher rarity give more.
static func get_sale_points(stack: InventorySlot) -> int:
	var sale: Dictionary = _data().get("sale", {})
	var tier: int = ForgeQuality.get_hardest_tier([stack])
	for part: ItemData in stack.components:
		tier = maxi(tier, part.material_tier)
	# Copper is tier 1, wood 0: wood counts like copper.
	var by_tier: float = maxf(1.0, tier * float(sale.get("per_tier", 1.0)))
	var by_rarity: float = 1.0 + int(stack.rarity) * float(sale.get("per_rarity", 1.0))
	return maxi(1, roundi(by_tier * by_rarity))


static func get_gain(key: String) -> int:
	return int(_data().get("gains", {}).get(key, 0))


## Story changed: points for newly set flags, and a locked rank may open now.
func on_story_changed() -> void:
	check_story()
	if get_rank_index() != _last_rank:
		_after_change()


## Gives the points of every story flag in "story" that is set and was not rewarded yet.
func check_story() -> void:
	var total: int = 0
	var story: Dictionary = _data().get("story", {})
	for flag: String in story:
		if not granted.has(flag) and has_flag.call(flag):
			granted.append(flag)
			total += int(story[flag])
	if total != 0:
		add(total)


func _after_change() -> void:
	var rank: int = get_rank_index()
	if rank > _last_rank:
		rank_reached.emit(get_rank_id())
	_last_rank = rank
	changed.emit()


# --- Ranks ------------------------------------------------------------------------------

static func get_ranks() -> Array:
	return _data().get("ranks", [])


## Index of the rank the player has: the highest one with enough points whose story flag is set.
func get_rank_index() -> int:
	var ranks: Array = get_ranks()
	var index: int = 0
	for i in ranks.size():
		var rank: Dictionary = ranks[i]
		if points < int(rank.get("from", 0)) or not has_flag.call(String(rank.get("required_flag", ""))):
			break
		index = i
	return index


## Index of the rank with this id (e.g. "E" = 1); unknown ids = 0.
static func get_rank_index_of(rank_id: String) -> int:
	var ranks: Array = get_ranks()
	for i in ranks.size():
		if String(ranks[i].get("id", "")) == rank_id:
			return i
	return 0


func get_rank() -> Dictionary:
	var ranks: Array = get_ranks()
	return ranks[get_rank_index()] if not ranks.is_empty() else {}


func get_rank_id() -> String:
	return String(get_rank().get("id", "F"))


## The next rank ({} at the highest).
func get_next_rank() -> Dictionary:
	var ranks: Array = get_ranks()
	var next: int = get_rank_index() + 1
	return ranks[next] if next < ranks.size() else {}


## true when the points would be enough for the next rank but the story has not unlocked it yet.
func is_next_locked() -> bool:
	var next: Dictionary = get_next_rank()
	return not next.is_empty() and points >= int(next.get("from", 0)) \
			and not has_flag.call(String(next.get("required_flag", "")))


## 0..1 from the current rank to the next one (1 at the highest rank).
func get_fraction() -> float:
	var next: Dictionary = get_next_rank()
	if next.is_empty():
		return 1.0
	var start: int = int(get_rank().get("from", 0))
	var end: int = int(next.get("from", 0))
	return clampf(float(points - start) / maxf(end - start, 1), 0.0, 1.0)


# --- Effects ------------------------------------------------------------------------------

## Customers per day [min, max].
func get_customer_range() -> Array:
	return get_rank().get("customers", [0, 2])


## Extra pay for orders (0.1 = +10 %).
func get_pay_bonus() -> float:
	return float(get_rank().get("pay_bonus", 0)) / 100.0


## Higher prices in Nina's and the own shop (0.05 = +5 %).
func get_price_bonus() -> float:
	return float(get_rank().get("shop_bonus", 0)) / 100.0


## Highest house level the builder may build at this rank.
func get_max_house_level() -> int:
	return int(get_rank().get("house_level", 1))


## The first rank that allows `house_level` ({} if none).
static func get_rank_for_house_level(house_level: int) -> Dictionary:
	for rank: Dictionary in get_ranks():
		if int(rank.get("house_level", 1)) >= house_level:
			return rank
	return {}


## Crest colour of a rank.
static func get_color(rank: Dictionary) -> Color:
	return Color.html(String(rank.get("color", "#8a7f74")))


static func _data() -> Dictionary:
	return ContentDB.economy("reputation")


# --- Saving -------------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"points": points, "granted": granted.duplicate()}


## `old_karma`: saves from before the reputation: positive karma counts double, the story
## points of everything already reached are given (check_story, without a rank message).
func load_save_data(data: Dictionary, old_karma: int = 0) -> void:
	granted.clear()
	if data.is_empty():
		points = maxi(0, old_karma * 2)
	else:
		points = int(data.get("points", 0))
		for flag: String in data.get("granted", []):
			granted.append(flag)
	check_story()
	_last_rank = get_rank_index()
	changed.emit()


## New game / skipped story: the current rank counts as known (no message).
func mark_known() -> void:
	_last_rank = get_rank_index()
