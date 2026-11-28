extends "res://assets/_reference/_lib/base_test.gd"
## Egon's table: pieces the player cannot afford are marked (gold_limit = the box), gear better
## than what the hero wears gets a green arrow (ShopGoods.better_than_worn); a worse or equal piece
## and a weapon of another class do not.

func run() -> void:
	var goods: Script = script("res://scripts/systems/shop_goods.gd")
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	var helmet: Dictionary = {"id": "copper_helmet", "rarity": 1}
	var good_helmet: Dictionary = {"id": "copper_helmet", "rarity": 3}
	check(goods.call("better_than_worn", helmet, {}, "magier"), "an empty slot: any helmet is better")
	check(goods.call("better_than_worn", good_helmet, {"head": helmet}, "magier"), "a rarer helmet beats a plain one")
	check(not goods.call("better_than_worn", helmet, {"head": good_helmet}, "magier"), "a worse one does not")
	check(not goods.call("better_than_worn", helmet, {"head": helmet}, "magier"), "the same one does not")
	check(not goods.call("better_than_worn", {"id": "copper_bow", "rarity": 3}, {}, "magier"), "a bow is no upgrade for a mage")
	meta.call("gift_gold", 5)
	meta.call("lay_tutorial_table")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var table: Object = shop.call("get_table_board")
	check_eq(int(table.get("gold_limit")), int(meta.call("box")), "the table knows the gold in the box")
	check(not (table.get("better") as Array).is_empty(), "free slots: some goods get a green arrow")
	shop.queue_free()
	await process_frame
