extends "res://assets/_reference/_lib/base_test.gd"
## Potions (data/potions.json): the data is complete; deaths are counted; after the second death
## Egon's potion show is due (not after fleeing, not before his first tour); in the real shop he
## turns the table once (only a potion on it, free, not a pull of the day), it lands in the
## potion place under the hero, and from then on potions come on the table. In the real dungeon
## Q (RunState.drink_potion) heals, takes the potion off the hero at home, and does nothing at
## full life or without a potion. Fixed seeds.

var meta: Script
var content: Script
var goods: Script
var game: Node


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	content = script("res://scripts/core/content.gd")
	goods = script("res://scripts/systems/shop_goods.gd")
	game = root.get_node("Game")
	_data()
	_rules()
	await _show_in_shop()
	await _drink_in_dungeon()


func _data() -> void:
	var potions: Dictionary = content.call("potions")
	check(int(potions.get("unlock_deaths", 0)) == 2, "Egon shows the potions after the second death")
	check(int(potions.get("slots", 0)) >= 1, "at least one potion place")
	check(ResourceLoader.exists(String(potions.get("hint", ""))), "picture of the empty potion place")
	check(not (content.call("potion", String(potions.get("tour_potion", ""))) as Dictionary).is_empty(), "Egon's gift is a known potion")
	for id: String in (potions.get("potions", {}) as Dictionary):
		var data: Dictionary = content.call("potion", id)
		check(ResourceLoader.exists(String(data.get("icon", ""))), "potion %s picture" % id)
		check(not String(data.get("name", "")).is_empty() and not String(data.get("desc", "")).is_empty(), "potion %s name and text" % id)
		check(int(data.get("heal", 0)) > 0 and int(data.get("price", 0)) > 0, "potion %s heals and has a price" % id)


func _rules() -> void:
	meta.call("start_new")
	check(not meta.call("potion_tour_due"), "a new game: no potion show")
	meta.call("finish_tutorial")
	meta.call("add_death")
	check(not meta.call("potion_tour_due"), "one death: not yet")
	meta.call("add_death")
	check(meta.call("potion_tour_due"), "the second death: Egon shows the potions")
	meta.call("reload")
	check_eq(meta.call("deaths"), 2, "deaths are saved")
	# Before the show: no potions on the table, a potion cannot be put on.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var seen: bool = false
	for i in 40:
		for place: Dictionary in goods.call("roll", rng, 0):
			seen = seen or goods.call("is_potion", place)
	check(not seen, "no potions on the table before Egon showed them")
	check_eq(meta.call("slot_of", {"id": "heal_potion", "potion": true}), "", "no potion place before the show")
	meta.call("unlock_potions")
	check_eq(meta.call("slot_of", {"id": "heal_potion", "potion": true}), "potion_1", "after it: the potion place")
	for i in 60:
		for place: Dictionary in goods.call("roll", rng, 0):
			seen = seen or goods.call("is_potion", place)
	check(seen, "after the show potions come on the table")
	check_eq(goods.call("sell_price", {"id": "heal_potion", "potion": true, "count": 1}), roundi(25 * 0.3), "Egon buys a potion back for his share")
	meta.call("start_new")


## The real shop after two deaths: Egon's show from the worry to the potion in its place.
func _show_in_shop() -> void:
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("add_death")
	meta.call("add_death")
	var pulls: int = meta.call("pulls_today")
	game.call("to_shop")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Shop" and current_scene.is_node_ready(), 3.0), "the shop opens")
	var shop: Node = current_scene
	check(await _click_until(func() -> bool: return not meta.call("potion_tour_due") and not (meta.call("worn_potions") as Array).is_empty() and not shop.get("_locked"), 40.0), "Egon's show ends with the potion in its place")
	var worn: Array = meta.call("worn_potions")
	check_eq(worn.size(), 1, "one potion on the hero")
	if not worn.is_empty():
		check_eq(String(worn[0]["id"]), "heal_potion", "the gift is a Heiltrank")
	check_eq(meta.call("box"), 0, "the gift was free")
	check_eq(meta.call("pulls_today"), pulls, "Egon's turn of the table is not a pull of the day")
	check((meta.call("stash") as Array).is_empty(), "the inventory is empty again")
	var hero: Node = shop.get("_hero")
	check((hero.call("get_potion_row") as Control).visible, "the potion place shows under the hero")
	check(not (hero.call("get_slot", "potion_1") as Node).call("is_empty"), "the potion lies in it")
	# Taken off and put on again like gear.
	shop.call("_on_hero_slot_clicked", "potion_1")
	check((meta.call("worn_potions") as Array).is_empty() and (meta.call("stash") as Array).size() == 1, "a click takes it off into the inventory")
	await shop.call("_on_inventory_clicked", 0)
	check_eq((meta.call("worn_potions") as Array).size(), 1, "a click in the inventory puts it on again")
	game.call("to_main_menu")
	await process_frame
	await process_frame


## Presses Space (Egon's next line) until `condition` holds or `max_seconds` passed.
func _click_until(condition: Callable, max_seconds: float) -> bool:
	var waited: float = 0.0
	while not condition.call():
		if waited >= max_seconds:
			return false
		var press := InputEventAction.new()
		press.action = "ui_accept"
		press.pressed = true
		Input.parse_input_event(press)
		var release := InputEventAction.new()
		release.action = "ui_accept"
		Input.parse_input_event(release)
		for i in 12:
			await physics_frame
		waited += 12.0 / 60.0
	return true


## The real dungeon with the potion on: Q heals 2 hearts and the potion is gone at home too.
func _drink_in_dungeon() -> void:
	check_eq((meta.call("worn_potions") as Array).size(), 1, "the potion is still on the hero")
	game.call("start_new_run", "magier", "glut")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.name == "Run" and current_scene.is_node_ready(), 3.0), "the run starts")
	await physics_frame
	var run_state: Object = game.get("run")
	check_eq((run_state.get("potions") as Array).size(), 1, "the potion comes along")
	var full: int = int(run_state.get("health"))
	check(not run_state.call("drink_potion"), "at full life Q does nothing")
	check_eq((run_state.get("potions") as Array).size(), 1, "and the potion stays")
	run_state.set("health", 1)
	var press := InputEventAction.new()
	press.action = "potion"
	press.pressed = true
	Input.parse_input_event(press)
	await physics_frame
	await physics_frame
	var release := InputEventAction.new()
	release.action = "potion"
	Input.parse_input_event(release)
	await physics_frame
	check_eq(int(run_state.get("health")), mini(full, 1 + 4), "Q drinks it: two hearts back")
	check((run_state.get("potions") as Array).is_empty(), "the potion is used up")
	check((meta.call("worn_potions") as Array).is_empty(), "and gone from the hero at home")
	check(not run_state.call("drink_potion"), "without a potion Q does nothing")
	game.call("to_main_menu")
	await process_frame
	await process_frame
