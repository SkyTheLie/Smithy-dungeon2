extends "res://assets/_reference/_lib/base_test.gd"
## Egon's quests (data/quests.json, Quests, MetaState): the end boss drops the stone of the open
## quest only while it is open and the player does not have it; stones cannot be sold; handing
## one in opens the next dungeon, moves Egon (another background) and pays gold. In the shop:
## buying by dragging from the table into the stash, selling by dragging onto the table, putting
## on by dragging onto a hero place (also a potion), taking off by dragging into the stash, the
## quest place and the quest window.

var meta: Script
var quests: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	quests = script("res://scripts/systems/quests.gd")
	meta.call("start_new")
	meta.call("finish_tutorial")
	_rules()
	await _shop_dragging()
	_handing_in()


func _rules() -> void:
	check_eq(quests.call("open_quests"), ["glutrubin"] as Array[String], "at first: Egon's Glutrubin")
	var bag: Object = script("res://scripts/systems/bag.gd").new()
	check_eq(quests.call("drop_for", "glut", bag), "glutrubin", "the end boss of the Glut drops the Glutrubin")
	check_eq(quests.call("drop_for", "moor", bag), "", "the Moor has no open quest yet")
	bag.call("add", "glutrubin", 1)
	check_eq(quests.call("drop_for", "glut", bag), "", "not while it is in the bag")
	check(not meta.call("is_dungeon_open", "moor"), "the Moor is closed")


func _shop_dragging() -> void:
	meta.call("gift_gold", 100)
	meta.call("lay_tutorial_table")
	meta.call("announce_quest", "glutrubin")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var stash: Control = shop.call("get_stash_board")
	var table: Control = shop.call("get_table_board")
	var px: float = stash.get("cell_px")
	# Buying: from the table down into the stash, onto cell 1,1.
	var goods: Array = meta.call("table")
	var helmet: int = goods.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "copper_helmet")
	var drag: Dictionary = {"from": "table", "index": helmet, "piece": goods[helmet], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check_eq(shop.call("_stash_judge", drag, Vector2i(1, 1), false), 1, "over a free spot: green")
	check_eq(shop.call("_stash_judge", drag, Vector2i(4, 3), false), 0, "half outside: red")
	var box: int = meta.call("box")
	stash.call("_drop_data", (Vector2(1, 1) + Vector2(0.5, 0.5)) * px, drag)
	var own: Array = meta.call("stash")
	check(own.size() == 1 and own[0].get("id") == "copper_helmet", "dragged into the stash: bought")
	check_eq(Vector2i(int(own[0].get("x", -1)), int(own[0].get("y", -1))), Vector2i(1, 1), "it lies where it was dropped")
	check(int(meta.call("box")) < box, "and paid")
	check((meta.call("table") as Array)[helmet].is_empty(), "gone from the table")

	# Putting on: onto the head place; the wrong place says no.
	var piece: Dictionary = own[0]
	var on_head: Dictionary = {"from": "stash", "index": 0, "piece": piece, "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check_eq(shop.call("_hero_judge", "feet", on_head), 2, "a helmet over the feet: red")
	check_eq(shop.call("_hero_judge", "head", on_head), 1, "over the head: green")
	shop.call("_hero_drop", "head", on_head)
	check_eq(((meta.call("equipment") as Dictionary).get("head", {}) as Dictionary).get("id"), "copper_helmet", "dragged onto the head: put on")
	# Taking off: from the head into the stash.
	var off: Variant = shop.call("_hero_drag", (shop.get("_hero") as Object).call("get_slot", "head"), "head")
	check(off is Dictionary and (off as Dictionary).get("from") == "hero", "the worn helmet can be dragged")
	stash.call("_drop_data", (Vector2(3, 2) + Vector2(0.5, 0.5)) * px, off)
	check(not (meta.call("equipment") as Dictionary).has("head"), "dragged into the stash: taken off")
	own = meta.call("stash")
	check_eq(Vector2i(int(own[0].get("x", -1)), int(own[0].get("y", -1))), Vector2i(3, 2), "onto that cell")

	# A potion onto the potion place.
	meta.call("_write", "potions_unlocked", true)
	meta.call("give_piece", {"id": "heal_potion", "potion": true})
	own = meta.call("stash")
	var potion: int = own.find_custom(func(place: Dictionary) -> bool: return bool(place.get("potion", false)))
	var potion_drag: Dictionary = {"from": "stash", "index": potion, "piece": own[potion], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	check_eq(shop.call("_hero_judge", "potion_1", potion_drag), 1, "a potion over the potion place: green")
	shop.call("_hero_drop", "potion_1", potion_drag)
	check_eq((meta.call("worn_potions") as Array).size(), 1, "dragged there: it is on")

	# Selling: from the stash onto the table.
	meta.call("end_run", 0, [{"id": "rat_fur", "count": 1}] as Array[Dictionary], RandomNumberGenerator.new())
	own = meta.call("stash")
	var fur: int = own.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur")
	var sell: Dictionary = {"from": "stash", "index": fur, "piece": own[fur], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check(table.call("_can_drop_data", Vector2(5, 5), sell), "the table takes stash pieces")
	check_eq(shop.call("_table_judge", sell, Vector2i.ZERO, false), 1, "a fur over the table: green")
	box = meta.call("box")
	table.call("_drop_data", Vector2(5, 5), sell)
	check_eq(int(meta.call("box")), box + 2, "sold for 2 gold")
	check(not (meta.call("stash") as Array).any(func(place: Dictionary) -> bool: return place.get("id") == "rat_fur"), "the fur is gone")

	# The quest stone: not for sale, but for the quest place.
	meta.call("give_piece", {"id": "glutrubin"})
	own = meta.call("stash")
	var stone: int = own.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "glutrubin")
	var stone_drag: Dictionary = {"from": "stash", "index": stone, "piece": own[stone], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i(2, 2)}
	check_eq(shop.call("_table_judge", stone_drag, Vector2i.ZERO, false), 0, "the stone over the table: red")
	check_eq(meta.call("sell", stone), 0, "Egon does not buy it")
	check(shop.call("_can_drop_on_quest", Vector2.ZERO, stone_drag), "the quest place takes it")
	shop.call("_refresh")
	check((shop.find_child("QuestsButton", true, false) as Button).text.ends_with("!"), "the Quests button says it can be handed in")
	var window: Control = shop.call("get_quest_window")
	(shop.find_child("QuestsButton", true, false) as Button).pressed.emit()
	await process_frame
	check(window.visible and window.find_child("Deliver_glutrubin", true, false) != null, "the quest window offers Abgeben")
	window.hide()
	shop.queue_free()
	await process_frame


func _handing_in() -> void:
	var own: Array = meta.call("stash")
	var stone: int = own.find_custom(func(place: Dictionary) -> bool: return place.get("id") == "glutrubin")
	var box: int = meta.call("box")
	check_eq(meta.call("deliver_quest", 999), "", "nothing there: nothing handed in")
	check_eq(meta.call("deliver_quest", stone), "glutrubin", "handed in")
	check(meta.call("quest_done", "glutrubin"), "the quest is done")
	check(meta.call("is_dungeon_open", "moor"), "the Moor opens")
	check_eq(meta.call("location"), "moor", "Egon moves to the Moor")
	check_eq(int(meta.call("box")), box + 100, "and pays 100 gold")
	check_eq(quests.call("drop_for", "glut", null), "", "the Glutrubin comes only once")
	check_eq(quests.call("open_quests"), ["moorperle"] as Array[String], "the next quest: the Moor")
	var background: Texture2D = script("res://scenes/shop/shop.gd").call("_location_background")
	check(background != null and background.resource_path.ends_with("swamp_mire.png"), "the shop stands at the Moor now")
	meta.call("reload")
	check(meta.call("quest_done", "glutrubin") and meta.call("location") == "moor", "saved")
