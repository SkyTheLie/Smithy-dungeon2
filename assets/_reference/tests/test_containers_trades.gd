extends "res://assets/_reference/_lib/base_test.gd"
## Containers in the stash (data/containers.json): only pieces of their kind go in, loot stacks,
## a full container takes nothing more, taking out puts one piece back, a container never goes
## into the bag and is only sold empty; the window in the shop opens on a click and takes stash
## pieces by drag and drop. Egon's exchange (data/trades.json): counts loot at home (stash, bag,
## containers), takes it, gives the piece; closed offers cannot be traded; the Tausch tab shows it.

var meta: Script
var goods: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	goods = script("res://scripts/systems/shop_goods.gd")
	_data()
	meta.call("start_new")
	meta.call("finish_tutorial")
	_container_rules()
	await _container_window()
	_trades()
	await _trade_tab()


## Every container and offer points at things that exist.
func _data() -> void:
	var content: Script = script("res://scripts/core/content.gd")
	var kinds: Dictionary = content.call("get_file", "containers").get("kinds", {})
	for id: String in goods.call("containers"):
		var data: Dictionary = goods.call("container_data", id)
		check(kinds.has(String(data.get("kind", ""))), "%s: known kind" % id)
		check(ResourceLoader.exists(String(data.get("icon", ""))), "%s: icon exists" % id)
		check(int(data.get("slots", 0)) >= 3, "%s: at least 3 places" % id)
	var trades: Script = script("res://scripts/systems/trades.gd")
	for offer: Dictionary in trades.call("all"):
		check(trades.call("gives_something", offer), "trade %s gives something real" % offer.get("id"))
		for cost: Array in trades.call("costs", offer):
			check(not (content.call("material", String(cost[0])) as Dictionary).is_empty(), "trade %s costs real loot %s" % [offer.get("id"), cost[0]])


func _stash() -> Array:
	return meta.call("stash")


func _index_of(id: String) -> int:
	var own: Array = _stash()
	for i in own.size():
		if String((own[i] as Dictionary).get("id", "")) == id:
			return i
	return -1


func _container_rules() -> void:
	meta.call("give_piece", {"id": "materialbeutel", "container": true})
	var box: Dictionary = _stash()[_index_of("materialbeutel")]
	var uid: int = int(box.get("uid", 0))
	check(uid > 0, "a container gets a uid")
	check_eq(meta.call("container_index", uid), _index_of("materialbeutel"), "found by its uid")
	# Loot goes in and stacks.
	for i in 3:
		meta.call("admin_give_loot", "rat_fur")
	check(meta.call("container_put", uid, _index_of("rat_fur")), "rat fur into the material bag")
	check(meta.call("container_put", uid, _index_of("rat_fur")), "a second one")
	var items: Array = meta.call("container_items", uid)
	check_eq(items.size(), 1, "the same loot stacks on one place")
	check_eq(int((items[0] as Dictionary).get("count", 0)), 2, "two on it")
	# Gear does not go into a material bag.
	meta.call("give_piece", goods.call("make_piece", "copper_helmet", 1))
	check(not meta.call("container_put", uid, _index_of("copper_helmet")), "a helmet is no material")
	# Full: 4 places (materials.json slots).
	for id: String in ["bat_skin", "coal", "copper_ore", "iron_ore"]:
		meta.call("admin_give_loot", id)
		meta.call("container_put", uid, _index_of(id))
	check_eq((meta.call("container_items", uid) as Array).size(), 4, "four places used")
	check_eq(_index_of("iron_ore") >= 0, true, "the fifth kind stays outside (full)")
	check(not meta.call("container_put", uid, _index_of("iron_ore")), "a full container takes nothing new")
	check(meta.call("container_put", uid, _index_of("rat_fur")), "but the stack still grows")
	# Never into the bag, sold only empty.
	check(not meta.call("stash_fits_bag", _index_of("materialbeutel"), Vector2i.ZERO, false), "a container stays at home")
	var gold: int = meta.call("box")
	check_eq(meta.call("sell", _index_of("materialbeutel")), 0, "a full container is not for sale")
	check_eq(meta.call("box"), gold, "no gold for it")
	check(_index_of("materialbeutel") >= 0, "it is still there")
	# Taking out: one piece at a time.
	check(meta.call("container_take", uid, 0), "one rat fur out")
	check_eq(int(((meta.call("container_items", uid) as Array)[0] as Dictionary).get("count", 0)), 2, "two left on the place")
	# Relics only into relic containers.
	meta.call("give_piece", {"id": "reliktdose", "container": true})
	var relics: int = int((_stash()[_index_of("reliktdose")] as Dictionary).get("uid", 0))
	meta.call("give_piece", {"id": "moorherz", "relic": true, "left": 3})
	check(meta.call("container_put", relics, _index_of("moorherz")), "a relic into the relic case")
	check(not meta.call("container_put", relics, _index_of("bat_skin")), "loot does not go into it")
	var kept: Dictionary = (meta.call("container_items", relics) as Array)[0]
	check_eq(int(kept.get("left", 0)), 3, "the relic keeps its runs inside")


func _container_window() -> void:
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var window: Control = shop.call("get_container_window")
	check(not window.visible, "no container open at first")
	shop.call("_on_inventory_clicked", _index_of("reliktdose"))
	check(window.visible, "a click opens the container")
	check_eq((window.call("get_slots") as Array).size(), 3, "the relic case shows its 3 places")
	# Drag a relic from the stash onto a place of the window.
	meta.call("give_piece", {"id": "moorherz", "relic": true, "left": 2})
	shop.call("refresh_all")
	var place: Control = (window.call("get_slots") as Array)[1]
	var drag: Dictionary = {"from": "stash", "index": _index_of("moorherz"), "piece": _stash()[_index_of("moorherz")]}
	window.call("_can_drop_in", Vector2.ZERO, drag, place)
	window.call("_drop_in", Vector2.ZERO, drag)
	await process_frame
	var uid: int = int(window.get("uid"))
	check_eq((meta.call("container_items", uid) as Array).size(), 2, "dropped onto a place: inside")
	# Out of the window into the stash.
	var out: Dictionary = {"from": "container", "uid": uid, "index": 0, "piece": (meta.call("container_items", uid) as Array)[0], "rot": false, "grab": Vector2i.ZERO, "size": Vector2i.ONE}
	var stash_board: Control = shop.call("get_stash_board")
	var free: Dictionary = script("res://scripts/systems/item_grid.gd").call("free_spot", _stash(), meta.call("stash_grid"), {"id": "moorherz", "relic": true})
	var cell := Vector2i(int(free.get("x", 0)), int(free.get("y", 0)))
	check_eq(shop.call("_stash_judge", out, cell, false), 1, "the stash takes it back on a free cell")
	shop.call("_on_stash_dropped", out, cell, false)
	check_eq((meta.call("container_items", uid) as Array).size(), 1, "taken out")
	# Dropping a stash piece onto the container itself puts it in.
	var own: Array = _stash()
	var target: Dictionary = own[_index_of("reliktdose")]
	var onto: Dictionary = {"from": "stash", "index": _index_of("moorherz"), "piece": own[_index_of("moorherz")], "grab": Vector2i.ZERO}
	var at := Vector2i(int(target["x"]), int(target["y"]))
	check_eq(shop.call("_container_under", onto, at), uid, "a relic over the relic case")
	shop.call("_on_stash_dropped", onto, at, false)
	check_eq((meta.call("container_items", uid) as Array).size(), 2, "dropped on the case: inside")
	shop.call("_on_inventory_clicked", _index_of("reliktdose"))
	check(not window.visible, "a second click closes it")
	shop.queue_free()
	await process_frame


func _trades() -> void:
	meta.call("admin_clear_stash")
	check(not meta.call("can_trade", "reliktdose"), "no rubies: no trade")
	check(not meta.call("trade", "reliktdose"), "and nothing happens")
	meta.call("admin_give_loot", "ruby")
	meta.call("admin_give_loot", "ruby")
	# The third ruby lies in a material bag.
	meta.call("give_piece", {"id": "materialbeutel", "container": true, "items": [{"id": "ruby", "count": 1}]})
	check_eq(meta.call("home_count", "ruby"), 3, "rubies counted in the stash and in containers")
	check(meta.call("can_trade", "reliktdose"), "three rubies: the trade is possible")
	check(meta.call("trade", "reliktdose"), "traded")
	check_eq(meta.call("home_count", "ruby"), 0, "all three rubies are gone")
	check(_index_of("reliktdose") >= 0, "the relic case lies in the stash")
	var box: Dictionary = _stash()[_index_of("reliktdose")]
	check(int(box.get("uid", 0)) > 0 and (box.get("items", []) as Array).is_empty(), "a new, empty container")
	# Closed offer (after the first quest).
	for i in 3:
		meta.call("admin_give_loot", "heartleaf")
	check(not meta.call("can_trade", "heiltrank"), "the potion trade waits for the quest")
	meta.call("admin_finish_quest", "glutrubin")
	check(meta.call("can_trade", "heiltrank"), "after the quest it is open")
	_bigger_stash()


## Ruby + amber: the stash gets twice as wide, only once per save; pieces without room move in.
func _bigger_stash() -> void:
	meta.call("admin_clear_stash")
	var before: Vector2i = meta.call("stash_grid")
	check(not meta.call("can_trade", "lager_gross"), "no gems: no bigger stash")
	meta.call("admin_give_loot", "ruby")
	meta.call("admin_give_loot", "amber")
	# Fill the stash so one more piece has no room.
	while not (script("res://scripts/systems/item_grid.gd").call("free_spot", _stash(), before, {"id": "rat_fur", "count": 1}) as Dictionary).is_empty():
		meta.call("admin_give_loot", "rat_fur")
	meta.call("admin_give_loot", "rat_fur")
	var outside: int = 0
	for piece: Variant in _stash():
		if not (piece as Dictionary).has("x"):
			outside += 1
	check(outside >= 1, "one fur lies under Kein Platz")
	check(meta.call("can_trade", "lager_gross"), "ruby and amber: the trade is possible")
	var count: int = _stash().size()
	check(meta.call("trade", "lager_gross"), "traded")
	check_eq(meta.call("stash_grid"), Vector2i(before.x * 2, before.y), "the stash is twice as wide")
	check_eq(_stash().size(), count - 2, "ruby and amber gone, no new piece")
	for piece: Variant in _stash():
		check((piece as Dictionary).has("x"), "every piece has room now")
	meta.call("admin_give_loot", "ruby")
	meta.call("admin_give_loot", "amber")
	check(not meta.call("can_trade", "lager_gross"), "only once")
	check(not meta.call("trade", "lager_gross"), "a second trade does nothing")
	check_eq(meta.call("stash_grid"), Vector2i(before.x * 2, before.y), "still twice, not more")
	meta.call("start_new")
	meta.call("finish_tutorial")
	check_eq(meta.call("stash_grid"), before, "a new game has the small stash")
	# Back to what the Tausch tab test expects: the quest done, three herbs at home.
	meta.call("admin_finish_quest", "glutrubin")
	for i in 3:
		meta.call("admin_give_loot", "heartleaf")


func _trade_tab() -> void:
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var tab: Button = shop.find_child("TradeTab", true, false)
	check(tab != null, "the Tausch tab exists")
	tab.pressed.emit()
	var panel: Control = shop.call("get_trade_panel")
	check(panel.visible, "the tab shows the offers")
	await process_frame
	var button: Button = panel.call("get_button", "heiltrank")
	check(button != null and not button.disabled, "the potion trade can be pressed")
	var locked: Button = panel.call("get_button", "reliktdose")
	check(locked != null and locked.disabled, "without rubies the button is off")
	button.pressed.emit()
	await process_frame
	check_eq(meta.call("home_count", "heartleaf"), 0, "the herbs are gone")
	var potion: bool = false
	for piece: Variant in _stash():
		if (piece as Dictionary).get("potion", false):
			potion = true
	check(potion, "a potion lies in the stash")
	shop.queue_free()
	await process_frame
