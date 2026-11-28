extends "res://assets/_reference/_lib/base_test.gd"
## Egon at his places (quests.json locations "egon", story.json place_lines): every place after the
## first has a look (colour, known gimmick) and an arrival line plus at least one lever line; in
## the real shop at the Frostgipfel Egon is bluish and shivers (his picture jitters), and the line
## for his place is found.

var meta: Script
var quests: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	quests = script("res://scripts/systems/quests.gd")
	var content: Script = script("res://scripts/core/content.gd")
	var locations: Dictionary = (content.call("get_file", "quests") as Dictionary).get("locations", {})
	var lines: Dictionary = content.call("story", "place_lines")
	var start: String = quests.call("start")
	for place: String in locations:
		if place == start:
			continue
		var look: Dictionary = (locations[place] as Dictionary).get("egon", {})
		check((look.get("tint", []) as Array).size() == 3, "%s: Egon's colour" % place)
		check(String(look.get("gimmick", "")) in ["shiver", "sweat", "mosquitoes", "sneeze"], "%s: known gimmick" % place)
		check(not String(lines.get("%s_arrive" % place, "")).is_empty(), "%s: a line when he arrives" % place)
		check(lines.has("%s_lever_1" % place), "%s: a line at the lever" % place)
	meta.call("start_new")
	meta.call("finish_tutorial")
	meta.call("_write", "location", "frost")
	var shop: Control = (load("res://scenes/shop/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop)
	current_scene = shop
	await process_frame
	await process_frame
	var merchant: TextureRect = shop.get("_merchant")
	check(merchant.modulate.b > merchant.modulate.r, "at the Frostgipfel Egon is bluish")
	check_eq(shop.get("_gimmick"), "shiver", "and shivers")
	var moved: bool = false
	var base: Vector2 = shop.get("_merchant_base")
	for i in 10:
		await process_frame
		if merchant.position != base:
			moved = true
	check(moved, "his picture jitters")
	check(String(shop.call("_place_line", "arrive")).begins_with("F-f-"), "his arrival line at the Frostgipfel")
	check(not String(shop.call("_place_line", "lever")).is_empty(), "a lever line there")
	shop.queue_free()
	await process_frame
