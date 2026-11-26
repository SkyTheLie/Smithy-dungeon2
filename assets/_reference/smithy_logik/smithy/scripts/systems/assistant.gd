class_name Assistant
extends RefCounted
## Lotte as the smith's helper (side tasks "lotte_forge" and "lotte_shopping" in story.json, then
## every day). Settings: economy.json "assistant".
## Once "flag" is set she waits in the workshop every morning ("wait_hours", 7-9; she walks there
## for "travel_minutes" first). Talked to there,
## the player can send her to the market for one ware (ErrandMenu): he pays the price of today's
## stock plus her wage ("wage", share of what she spends) in advance. She walks to the market,
## buys what the merchant still has when she gets there ("travel_minutes" of her roam after
## leaving) and is back in the workshop after "market_hours". Talked to, she hands over the ware
## and the gold she did not need; not collected by "deliver_until" (or at night) it goes into the
## loot chest. Without an errand she roams as always (Roaming).
## She is in the workshop or follows the player during the side tasks, too: get_spot overrides her
## roaming place (Roaming._planned_spot). Her dialogues follow the flags set by update_flags.
## Selling (reward of "lotte_shopping"): in the loot chest (ChestMenu) the player hands her stacks
## to sell ("sale_pending"). Next morning she takes them along ("sale_selling", gold fixed then:
## merchant sell price × "sale_share" + skill "Wie die Oma, so die Nichte"), the morning after the
## gold lies in the loot chest.
## In GameState.assistant, saved.

signal changed

## Her place inside the workshop (StoryNpc roam_spot in smithy.tscn).
const WORKSHOP: String = "workshop"
## No place: she walks along with the player (Companion nodes).
const FOLLOWING: String = "with_player"
const WORKSHOP_SCENE: String = "res://scenes/world/smithy/smithy.tscn"
## Side task "lotte_forge": she watches in the workshop until the player forged a piece there.
const FORGE_ACCEPTED: String = "lotte_forge_accepted"
const FORGE_WATCHED: String = "lotte_forge_watched"
const FORGE_DONE: String = "lotte_forge_done"
## Side task "lotte_shopping": she follows the player to the market.
const SHOP_ACCEPTED: String = "lotte_shop_accepted"
const SHOP_DONE: String = "lotte_shop_done"
## Flags for her dialogues (story.json "side_dialogues"), set by update_flags.
const READY_FLAG: String = "errand_ready"
const OUT_FLAG: String = "errand_out"
const BACK_FLAG: String = "errand_back"

enum State { OUT, BOUGHT, DONE }

## Today's errand ({} = none): {"spec", "amount", "merchant" (index in "merchants"), "paid" (gold
## given to her), "day", "hour" (when she left), "state" (State), "bought" (pieces she got),
## "cost" (gold she spent), "wage" (gold she kept)}.
var errand: Dictionary = {}
## Stacks waiting in the chest for her next morning, and the ones she is selling (gold tomorrow).
var sale_pending: Array[InventorySlot] = []
var sale_selling: Array[InventorySlot] = []
## Gold she brings for sale_selling (fixed when she took them).
var sale_gold: int = 0
## "forge" counter (Achievements) last seen outside the workshop, -1 = not looked yet.
var _forge_seen: int = -1


static func get_settings() -> Dictionary:
	return ContentDB.economy("assistant")


static func get_npc_id() -> String:
	return str(get_settings().get("npc", "niece"))


## true once she can be sent shopping.
static func is_unlocked(story: Story) -> bool:
	return story.has_flag(str(get_settings().get("flag", "lotte_errands")))


## Her place on `day` at `hour` instead of the roaming one, "" = she roams as always.
func get_spot(npc_id: String, day: int, hour: float) -> String:
	if npc_id != get_npc_id():
		return ""
	var story: Story = GameState.story
	var settings: Dictionary = get_settings()
	var roam: NpcInfo.Roam = ContentDB.npc_info(npc_id).roam
	if roam == null:
		roam = NpcInfo.Roam.new()  # the defaults
	var outside: bool = hour >= roam.from_hour and hour < roam.until_hour
	if story.has_flag(SHOP_ACCEPTED) and not story.has_flag(SHOP_DONE):
		return FOLLOWING
	if story.has_flag(FORGE_ACCEPTED) and not story.has_flag(FORGE_DONE):
		return WORKSHOP if outside else ""
	if not is_unlocked(story):
		return ""
	# The morning wait may start before her roaming day (she walks there first, "travel_minutes").
	var wait: Array = settings.get("wait_hours", [7, 9])
	var after_wait_start: bool = hour >= float(wait[0])
	if not errand.is_empty() and int(errand["day"]) == day:
		if int(errand["state"]) == State.DONE:
			return ""
		var left: float = float(errand["hour"])
		if hour < left:
			return WORKSHOP if after_wait_start else ""
		if hour < left + _market_hours():
			return "market"
		return WORKSHOP if hour < float(settings.get("deliver_until", 20)) else ""
	return WORKSHOP if after_wait_start and hour < float(wait[1]) else ""


## true while she is at the market or on her way back.
func is_out() -> bool:
	return not errand.is_empty() and int(errand["state"]) != State.DONE \
			and GameState.day_cycle.get_hour() < float(errand["hour"]) + _market_hours()


## true while she waits in the workshop with the ware.
func is_back() -> bool:
	return not errand.is_empty() and int(errand["state"]) != State.DONE and not is_out()


## true while she waits in the workshop for an errand (morning, none given today).
func is_ready() -> bool:
	var story: Story = GameState.story
	if not is_unlocked(story) or (not errand.is_empty() and int(errand["day"]) == GameState.day_cycle.day):
		return false
	return Roaming.get_spot(get_npc_id(), GameState.day_cycle.day, GameState.day_cycle.get_hour()) == WORKSHOP


static func _market_hours() -> float:
	return float(get_settings().get("market_hours", 2.0))


## Hours from leaving the workshop until she is at the market (her roaming "travel_minutes").
static func _travel_hours() -> float:
	var roam: NpcInfo.Roam = ContentDB.npc_info(get_npc_id()).roam
	return (roam.travel_minutes if roam else Roaming.DEFAULT_TRAVEL_MINUTES) / 60.0


# --- Wares ---------------------------------------------------------------------------------

## The market merchants' wares of today she can buy: [{"merchant": index in "merchants",
## "name": merchant name, "spec", "stack" (one piece), "left" (-1 = no limit), "price" (one piece)}].
static func get_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var merchants: Array = get_settings().get("merchants", [])
	for index in merchants.size():
		var merchant: Dictionary = merchants[index]
		for entry: Dictionary in _get_stock(merchant):
			var spec: String = entry["spec"]
			if not MerchantStock.is_item_spec(spec) or int(entry["amount"]) == 0:
				continue
			var stack: InventorySlot = ContentDB.make_stack(spec)
			if stack == null:
				continue
			var piece: InventorySlot = stack.copy_with_amount(1)
			offers.append({"merchant": index, "name": str(merchant.get("name", "")), "spec": spec, "stack": piece,
					"left": int(entry["amount"]), "price": _get_piece_price(entry, piece)})
	return offers


static func _get_stock(merchant: Dictionary) -> Array:
	var no_offers: Array[String] = []
	return GameState.merchant_stock.get_entries(str(merchant.get("key", "")), no_offers, str(merchant.get("stock_id", "")))


## Price of one piece like at the stall (ShopDialog): the fixed stock price or from the item value.
static func _get_piece_price(entry: Dictionary, piece: InventorySlot) -> int:
	return int(entry["price"]) if int(entry["price"]) > 0 else Economy.get_buy_price(piece)


## Her wage for spending `cost` gold (at least 1 for any purchase).
static func get_wage(cost: int) -> int:
	return 0 if cost <= 0 else maxi(1, ceili(cost * float(get_settings().get("wage", 0.1))))


static func get_max_amount(offer: Dictionary) -> int:
	var most: int = int(get_settings().get("max_amount", 20))
	return most if int(offer["left"]) < 0 else mini(most, int(offer["left"]))


## Why she can't be sent now ("" = she can): not waiting in the workshop, not enough gold.
func get_blocker(gold: int, total: int) -> String:
	if not is_ready():
		return Language.translate("Lotte ist gerade nicht in der Werkstatt.")
	if gold < total:
		return Language.translate("Du hast nicht genug Gold.")
	return ""


## Sends her off for `amount` pieces of `offer` (from get_offers). The caller checked get_blocker;
## the gold is taken here. false = not enough gold.
func send(offer: Dictionary, amount: int) -> bool:
	var cost: int = int(offer["price"]) * amount
	var total: int = cost + get_wage(cost)
	if not GameState.spend_gold(total):
		return false
	errand = {"spec": offer["spec"], "amount": amount, "merchant": int(offer["merchant"]), "paid": total,
			"day": GameState.day_cycle.day, "hour": GameState.day_cycle.get_hour(), "state": State.OUT,
			"bought": 0, "cost": 0, "wage": 0}
	update_flags()
	changed.emit()
	return true


## At the market: she buys as many pieces as the merchant has left (at most what was asked for).
func _buy() -> void:
	var merchants: Array = get_settings().get("merchants", [])
	var index: int = int(errand["merchant"])
	if index >= 0 and index < merchants.size():
		for entry: Dictionary in _get_stock(merchants[index]):
			if entry["spec"] != errand["spec"] or int(entry["amount"]) == 0:
				continue
			var piece: InventorySlot = ContentDB.make_stack(entry["spec"])
			if piece == null:
				break
			var left: int = int(entry["amount"])
			var bought: int = int(errand["amount"]) if left < 0 else mini(int(errand["amount"]), left)
			var cost: int = _get_piece_price(entry, piece.copy_with_amount(1)) * bought
			# Prices don't change during the day, but never more than she was given.
			var wage: int = mini(get_wage(cost), maxi(0, int(errand["paid"]) - cost))
			if cost > int(errand["paid"]):
				break
			MerchantStock.take(entry, bought)
			errand["bought"] = bought
			errand["cost"] = cost
			errand["wage"] = wage
			break
	errand["state"] = State.BOUGHT


## Gold she brings back (what she did not spend and did not keep).
func get_change() -> int:
	return maxi(0, int(errand.get("paid", 0)) - int(errand.get("cost", 0)) - int(errand.get("wage", 0)))


## What she brings back: the ware (null = nothing bought).
func get_ware() -> InventorySlot:
	if errand.is_empty() or int(errand.get("bought", 0)) <= 0:
		return null
	var stack: InventorySlot = ContentDB.make_stack(errand["spec"])
	return stack.copy_with_amount(int(errand["bought"])) if stack else null


## "Ich hab 5× Kohle. 4 Gold sind übrig. Meinen Lohn hab ich schon behalten." (story text
## {errand_report}).
func get_report() -> String:
	var ware: InventorySlot = get_ware()
	if ware == null:
		return Language.translate("Es war alles weg. Hier, dein Gold.")
	var text: String = Language.translate("Ich hab %d× %s.") % [ware.amount, ware.get_display_name()]
	if get_change() > 0:
		text += " " + Language.translate("%d Gold sind übrig.") % get_change()
	return text + " " + Language.translate("Meinen Lohn hab ich schon behalten.")


## Story action "errand_hand_over": she gives the ware (inventory, overflow into the loot chest)
## and the change to the player.
func hand_over() -> bool:
	if errand.is_empty() or int(errand["state"]) == State.DONE:
		return false
	if int(errand["state"]) == State.OUT:
		_buy()
	var ware: InventorySlot = get_ware()
	if ware:
		var leftover: int = GameState.inventory.add_stack(ware.copy_with_amount(ware.amount))
		if leftover > 0:
			GameState.put_stack_into_reward_chest(ware.copy_with_amount(leftover))
			GameState.show_message(Language.translate("Kein Platz im Inventar: Der Rest liegt in der Loot-Kiste."))
	GameState.add_gold(get_change())
	_finish()
	return true


## Not collected: ware and change go into the loot chest. Returns the line for the player ("" = nothing).
func put_into_chest() -> String:
	if errand.is_empty() or int(errand["state"]) == State.DONE:
		return ""
	if int(errand["state"]) == State.OUT:
		_buy()
	var ware: InventorySlot = get_ware()
	if ware:
		GameState.put_stack_into_reward_chest(ware)
	if get_change() > 0:
		GameState.put_gold_into_reward_chest(get_change())
	var text: String = Language.translate("Lotte hat deine Einkäufe in die Loot-Kiste gelegt.") if ware \
			else Language.translate("Lotte hat nichts bekommen und dein Gold in die Loot-Kiste gelegt.")
	_finish()
	return text


func _finish() -> void:
	errand["state"] = State.DONE
	update_flags()
	changed.emit()


# --- Selling ----------------------------------------------------------------------

## Share of the merchant sell price she brings back (economy.json "sale_share" + skill).
static func get_sale_share() -> float:
	return float(get_settings().get("sale_share", 0.8)) + GameState.player_stats.get_lotte_sale_bonus()


## Gold she brings for `stack` (0 = no merchant takes it, she leaves it in the chest).
static func get_sale_price(stack: InventorySlot) -> int:
	if stack == null or stack.is_empty():
		return 0
	return floori(Economy.get_sell_price(stack) * stack.amount * get_sale_share())


## Hands her the stacks at `indexes` of the loot chest (taken out of it). Returns how many stacks
## she took; unsellable ones stay.
func give_for_sale(indexes: Array[int]) -> int:
	if not is_unlocked(GameState.story):
		return 0
	var chest: Inventory = GameState.reward_chest
	var given: int = 0
	for index in indexes:
		if index < 0 or index >= chest.slots.size():
			continue
		var stack: InventorySlot = chest.slots[index]
		if get_sale_price(stack) <= 0:
			continue
		sale_pending.append(stack.copy_with_amount(stack.amount))
		chest.remove_from_slot(index, stack.amount)
		given += 1
	if given > 0:
		changed.emit()
	return given


## Gold the pending stacks would bring with today's share.
func get_pending_gold() -> int:
	var gold: int = 0
	for stack in sale_pending:
		gold += get_sale_price(stack)
	return gold


## New morning: yesterday's sale pays into the loot chest, then she takes the pending stacks.
func _on_new_day_sale() -> String:
	var text: String = ""
	if not sale_selling.is_empty():
		GameState.put_gold_into_reward_chest(sale_gold)
		text += "\n" + Language.translate("Lotte hat deine Sachen verkauft: %d Gold liegen in der Loot-Kiste.") % sale_gold
		sale_selling.clear()
		sale_gold = 0
	if not sale_pending.is_empty():
		sale_gold = get_pending_gold()
		sale_selling = sale_pending.duplicate()
		sale_pending.clear()
		text += "\n" + Language.translate("Lotte hat die Sachen aus der Loot-Kiste zum Verkaufen mitgenommen.")
	if not text.is_empty():
		changed.emit()
	return text


# --- Ticking ------------------------------------------------------------------------------

## Called often (GameState story check): buys at the market when she gets there, puts the ware
## into the chest after "deliver_until", watches the player forge, updates her dialogue flags.
func tick() -> void:
	var hour: float = GameState.day_cycle.get_hour()
	if not errand.is_empty() and int(errand["state"]) != State.DONE:
		if int(errand["day"]) != GameState.day_cycle.day:
			_report(put_into_chest())
		elif int(errand["state"]) == State.OUT and hour >= float(errand["hour"]) + _travel_hours():
			_buy()
			changed.emit()
		elif hour >= float(get_settings().get("deliver_until", 20)):
			_report(put_into_chest())
	_watch_forging()
	update_flags()


## New morning: an errand of yesterday that was not collected goes into the chest. Returns the
## line for the wake-up text.
func on_new_day() -> String:
	var text: String = put_into_chest()
	errand = {}
	update_flags()
	return ("\n" + text if not text.is_empty() else "") + _on_new_day_sale()


func _report(text: String) -> void:
	if not text.is_empty():
		GameState.show_message(text)


## Side task "lotte_forge": a piece forged while the player is in the workshop (and she is there).
func _watch_forging() -> void:
	var story: Story = GameState.story
	if not story.has_flag(FORGE_ACCEPTED) or story.has_flag(FORGE_WATCHED):
		_forge_seen = -1
		return
	var forged: int = int(GameState.achievements.counters.get("forge", 0))
	var scene: Node = GameState.get_tree().current_scene
	var in_workshop: bool = scene != null and scene.scene_file_path == WORKSHOP_SCENE \
			and Roaming.is_at(get_npc_id(), WORKSHOP)
	if in_workshop and _forge_seen >= 0 and forged > _forge_seen:
		story.set_flag(FORGE_WATCHED)
	_forge_seen = forged


## Her dialogue flags: waiting for an errand, out shopping, back with the ware.
func update_flags() -> void:
	var story: Story = GameState.story
	_set_flag(story, READY_FLAG, is_ready())
	_set_flag(story, OUT_FLAG, is_out())
	_set_flag(story, BACK_FLAG, is_back())


static func _set_flag(story: Story, flag: String, on: bool) -> void:
	if on and not story.has_flag(flag):
		story.set_flag(flag)
	elif not on and story.has_flag(flag):
		story.clear_flags([flag])


# --- Saving -------------------------------------------------------------------------

## The errand's fields plus "sale_pending", "sale_selling", "sale_gold".
func to_save_data() -> Dictionary:
	var data: Dictionary = errand.duplicate(true)
	if not sale_pending.is_empty() or not sale_selling.is_empty():
		data["sale_pending"] = sale_pending.map(func(stack: InventorySlot) -> Dictionary: return stack.to_save_data())
		data["sale_selling"] = sale_selling.map(func(stack: InventorySlot) -> Dictionary: return stack.to_save_data())
		data["sale_gold"] = sale_gold
	return data


func load_save_data(data: Dictionary) -> void:
	errand = data.duplicate(true)
	sale_pending = _load_stacks(errand.get("sale_pending", []))
	sale_selling = _load_stacks(errand.get("sale_selling", []))
	sale_gold = int(errand.get("sale_gold", 0))
	for key in ["sale_pending", "sale_selling", "sale_gold"]:
		errand.erase(key)
	_forge_seen = -1
	changed.emit()


static func _load_stacks(data: Array) -> Array[InventorySlot]:
	var stacks: Array[InventorySlot] = []
	for entry in data:
		var stack: InventorySlot = InventorySlot.from_save_data(entry)
		if not stack.is_empty():
			stacks.append(stack)
	return stacks
