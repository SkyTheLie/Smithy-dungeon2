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


## Why an offer is still closed (translated), "" when it is open.
static func lock_reason(offer: Dictionary) -> String:
	var unlock: Dictionary = offer.get("unlock", {})
	if is_open(offer):
		return ""
	if unlock.has("quest") and not MetaState.quest_done(String(unlock["quest"])):
		return Language.translate("Nach der Quest: %s") % Language.translate(String(Quests.data(String(unlock["quest"])).get("name", "")))
	if unlock.has("dungeon") and not MetaState.has_won(String(unlock["dungeon"])):
		return Language.translate("Nach dem Sieg in: %s") % Language.translate(String((Content.dungeons().get(String(unlock["dungeon"]), {}) as Dictionary).get("name", "")))
	return Language.translate("Ab Stufe %d") % int(unlock.get("level", 0))


## What the offer gives, as a piece for the stash ({} if the data is wrong).
static func piece_of(offer: Dictionary) -> Dictionary:
	var gets: Dictionary = offer.get("get", {})
	if gets.has("container") and not ShopGoods.container_data(String(gets["container"])).is_empty():
		return {"id": String(gets["container"]), "container": true}
	if gets.has("backpack") and not BagLayout.backpack(String(gets["backpack"])).is_empty():
		return {"id": String(gets["backpack"]), "backpack": true}
	if gets.has("potion") and not Content.potion(String(gets["potion"])).is_empty():
		return {"id": String(gets["potion"]), "potion": true}
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
