extends "res://assets/_reference/_lib/base_test.gd"
## Buying back (MetaState.sold_today / buy_back): a sale is remembered (newest first, at most
## BUY_BACK_PLACES); buying back costs the same gold and puts the piece into the stash; too little
## gold: nothing happens; a new day forgets the sales. The shop shows them in its buy-back places.

func run() -> void:
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	for i in 4:
		meta.call("admin_give_loot", "rat_fur")
	var box: int = meta.call("box")
	var gold: int = 0
	for i in 4:
		gold += int(meta.call("sell", 0))
	check(gold > 0 and int(meta.call("box")) == box + gold, "sold four furs")
	var sold: Array = meta.call("sold_today")
	check_eq(sold.size(), int(meta.get("BUY_BACK_PLACES")), "Egon remembers the last ones")
	var price: int = int((sold[0] as Dictionary).get("gold", 0))
	var before: int = meta.call("box")
	check(meta.call("buy_back", 0), "buy back the newest sale")
	check_eq(int(meta.call("box")), before - price, "for the same price")
	check((meta.call("stash") as Array).any(func(p: Dictionary) -> bool: return p.get("id") == "rat_fur"), "the fur is back in the stash")
	check_eq((meta.call("sold_today") as Array).size(), int(meta.get("BUY_BACK_PLACES")) - 1, "that sale is gone from the list")
	meta.call("_write", "box", 0)
	check(not meta.call("buy_back", 0), "no gold: no buying back")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var slots: Array = shop.get("_buy_back_slots")
	check(not (slots[0] as Object).call("is_empty") and (slots[slots.size() - 1] as Object).call("is_empty"), "the shop shows the remembered sales")
	shop.queue_free()
	await process_frame
	meta.call("admin_next_day")
	check((meta.call("sold_today") as Array).is_empty(), "a new day forgets the sales")
