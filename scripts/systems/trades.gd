class_name Trades
extends RefCounted
## Egon's exchange (data/trades.json): loot from home against a container, a backpack, a potion or
## a relic, without gold. Only rules about the data; MetaState.trade does the exchange, the shop
## (Tausch tab) shows it.


## The offers in their order (each {id, give, get, unlock?}).
static func all() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Variant in Content.get_file("trades").get("trades", []):
		if entry is Dictionary:
			list.append(entry)
	return list


static func find(id: String) -> Dictionary:
	for offer: Dictionary in all():
		if String(offer.get("id", "")) == id:
			return offer
	return {}


## true when the offer's "unlock" is met (MetaState.meets).
static func is_open(offer: Dictionary) -> bool:
	return MetaState.meets(offer.get("unlock", {}))


## true for an offer that can be traded only once per save ("once": true).
static func is_once(offer: Dictionary) -> bool:
	return bool(offer.get("once", false))


## true when a once-only offer was already traded.
static func is_used_up(offer: Dictionary) -> bool:
	return is_once(offer) and MetaState.trade_done(String(offer.get("id", "")))


## How many columns the stash gains from this offer (get.stash_columns, 0 = none).
static func stash_columns(offer: Dictionary) -> int:
	return maxi(0, int((offer.get("get", {}) as Dictionary).get("stash_columns", 0)))


## true when the offer gives something real: a piece for the stash or a bigger stash.
static func gives_something(offer: Dictionary) -> bool:
	return stash_columns(offer) > 0 or not piece_of(offer).is_empty()


## Why an offer cannot be traded now apart from its cost (translated), "" when it can.
static func lock_reason(offer: Dictionary) -> String:
	var unlock: Dictionary = offer.get("unlock", {})
	if is_used_up(offer):
		return Language.translate("Schon getauscht")
	if is_open(offer):
		return ""
	if unlock.has("quest") and not MetaState.quest_done(String(unlock["quest"])):
		return Language.translate("Nach der Quest: %s") % Language.translate(String(Quests.data(String(unlock["quest"])).get("name", "")))
	if unlock.has("dungeon") and not MetaState.has_won(String(unlock["dungeon"])):
		return Language.translate("Nach dem Sieg in: %s") % Language.translate(String((Content.dungeons().get(String(unlock["dungeon"]), {}) as Dictionary).get("name", "")))
	return Language.translate("Ab Stufe %d") % int(unlock.get("level", 0))


## What the offer gives, as a piece for the stash ({} if the data is wrong or it gives no piece,
## e.g. a bigger stash).
static func piece_of(offer: Dictionary) -> Dictionary:
	var gets: Dictionary = offer.get("get", {})
	if gets.has("container") and not ShopGoods.container_data(String(gets["container"])).is_empty():
		return {"id": String(gets["container"]), "container": true}
	if gets.has("backpack") and not BagLayout.backpack(String(gets["backpack"])).is_empty():
		return {"id": String(gets["backpack"]), "backpack": true}
	if gets.has("potion") and not Content.potion(String(gets["potion"])).is_empty():
		return {"id": String(gets["potion"]), "potion": true}
	if gets.has("loot") and not Content.material(String(gets["loot"])).is_empty():
		return {"id": String(gets["loot"]), "count": 1}
	if gets.has("relic") and not Content.item(String(gets["relic"])).is_empty():
		return {"id": String(gets["relic"]), "relic": true, "left": maxi(1, int(gets.get("runs", 1)))}
	return {}


## The price: [[loot id, count], …] with counts > 0.
static func costs(offer: Dictionary) -> Array[Array]:
	var list: Array[Array] = []
	var give: Dictionary = offer.get("give", {})
	for id: String in give:
		if int(give[id]) > 0:
			list.append([id, int(give[id])])
	return list
