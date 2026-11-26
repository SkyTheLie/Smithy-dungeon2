extends "res://assets/_reference/_lib/base_test.gd"
## Player levels and the skill tree (data/levels.json, data/skills.json, Skills, MetaState): EXP
## per kill and at the end of a run, levels give skill points, a skill costs gold and points and
## needs the skill before it and a player level, and the learned skills work in the run (bag
## places, damage, shield hearts, red hearts, more gold per coin, relic places, longer relics).
## Then the window: a click on a gold frame learns.

var meta: Script
var skills: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	skills = script("res://scripts/systems/skills.gd")
	meta.call("start_new")
	_levels()
	_learning()
	_effects()
	await _window()


func _data_check() -> void:
	for id: String in skills.call("all"):
		var data: Dictionary = skills.call("data", id)
		check(ResourceLoader.exists(String(data.get("icon", ""))), "skill %s has a picture" % id)
		var needed: String = String(data.get("requires", ""))
		check(needed.is_empty() or (skills.call("all") as Dictionary).has(needed), "skill %s: known skill before it" % id)


func _levels() -> void:
	_data_check()
	check_eq(meta.call("level"), 0, "a new game starts at level 0")
	check_eq(meta.call("skill_points"), 0, "without skill points")
	check_eq(skills.call("exp_to_next", 0), 30, "30 EXP to level 1")
	check_eq(skills.call("exp_to_next", 1), 39, "then 30 x 1.3")
	check_eq(skills.call("kill_exp", false), 2, "a kill gives 2 EXP")
	check_eq(skills.call("kill_exp", true), 25, "a boss 25")
	var run: Object = script("res://scripts/systems/run_state.gd").new(1)
	for i in 10:
		run.call("add_kill_exp", false)
	run.call("add_kill_exp", true)
	check_eq(run.get("exp_earned"), 45, "10 kills and a boss: 45 EXP in the run")
	check_eq(meta.call("add_exp", 45), 1, "at the end of the run: level 1")
	check_eq(meta.call("exp_points"), 15, "15 EXP left over")
	check_eq(meta.call("skill_points"), 1, "level 1: the first skill point")
	check_eq(meta.call("add_exp", 500), 6, "lots of EXP: several levels at once")
	check_eq(meta.call("level"), 7, "level 7")


func _learning() -> void:
	check_eq(skills.call("problem", "leichtfuss"), "Erst den Skill davor lernen", "Leichtfuß needs Kraft first (same group)")
	check_eq(skills.call("problem", "rucksack"), "Zu wenig Gold", "no gold yet")
	var starts: Array = (skills.call("all") as Dictionary).keys().filter(func(id: String) -> bool: return not (skills.call("data", id) as Dictionary).has("requires"))
	check_eq(starts.size(), 3, "three groups, each with its own start")
	# Straight into the box (an end_run above the limit could let Egon steal that night).
	meta.call("gift_gold", 1000)
	var points: int = meta.call("skill_points")
	check(meta.call("buy_skill", "rucksack"), "the backpack can be learned at level 1")
	check_eq(meta.call("box"), 970, "it cost 30 gold")
	check_eq(meta.call("skill_points"), points - 1, "and one skill point")
	check(meta.call("buy_skill", "rucksack"), "second level (needs level 5: we are 7)")
	check_eq(skills.call("problem", "rucksack"), "Stufe zu niedrig", "the third level needs level 15")
	check(not meta.call("buy_skill", "rucksack"), "so it cannot be learned")
	check_eq(skills.call("problem", "reliktplatz"), "Erst den Skill davor lernen", "Relikt-Platz needs Zähigkeit")
	check(meta.call("buy_skill", "zaehigkeit"), "Zähigkeit")
	check_eq(skills.call("problem", "reliktplatz"), "Stufe zu niedrig", "Relikt-Platz needs level 10")
	meta.call("add_exp", 2000)
	check(meta.call("level") >= 10, "level %d now" % meta.call("level"))
	for id: String in ["reliktplatz", "reliktpflege", "kraft", "kraft", "goldnase"]:
		check(meta.call("buy_skill", id), "learn %s" % id)
	check_eq(meta.call("skill_level", "kraft"), 2, "Kraft level 2")
	meta.call("reload")
	check_eq(meta.call("skill_level", "kraft"), 2, "skills are saved")


func _effects() -> void:
	var run: Object = script("res://scripts/systems/run_state.gd").new(2)
	var damage: float = (run.get("stats") as Object).get("damage")
	var places: int = (run.get("bag") as Object).call("size")
	run.call("use_skills")
	check_eq((run.get("bag") as Object).call("size"), places + 2, "Größerer Rucksack 2: two places more")
	check(is_equal_approx((run.get("stats") as Object).get("damage"), damage + 1.0), "Kraft 2: damage +1")
	check_eq(run.get("shield"), 1, "Zähigkeit 1: half a white heart")
	check_eq(run.get("sell_bonus"), 2, "Goldnase 1: the dungeon shop pays 2 gold more per piece")
	check_eq((meta.call("relic_slot_names") as Array).size(), 2, "Relikt-Platz: two relic places")
	var relic: Dictionary = script("res://scripts/systems/shop_goods.gd").call("make_relic", "dreizack")
	check_eq(relic.get("left"), 2, "Reliktpflege: the Dreifachschuss holds 2 dungeons instead of 1")
	var forever: Dictionary = script("res://scripts/systems/shop_goods.gd").call("make_relic", "moorherz")
	check_eq(forever.get("left"), -1, "for ever stays for ever")


func _window() -> void:
	var window: Control = script("res://scenes/shop/skill_tree_window.gd").new()
	root.add_child(window)
	await process_frame
	window.call("open")
	await process_frame
	var tree: Control = window.call("get_tree_view")
	var button: Button = tree.find_child("Skill_leichtfuss", true, false)
	check(button != null, "every skill has a button in the tree")
	check(button.tooltip_text.contains("Leichtfuß"), "the tooltip names it")
	var before: int = meta.call("skill_level", "leichtfuss")
	button.pressed.emit()
	await process_frame
	check_eq(meta.call("skill_level", "leichtfuss"), before + 1, "a click on a gold frame learns it")
	window.queue_free()
