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
	check_eq(skills.call("exp_to_next", 0), 64, "64 EXP to level 1 (levels.json exp_table)")
	check_eq(skills.call("exp_to_next", 1), 90, "90 to level 2")
	check_eq(skills.call("exp_to_next", 2), 90, "then at least 90")
	check_eq(skills.call("exp_to_next", 10), 279, "later levels as before: 30 x 1.25^10 (rounded)")
	# A first run on floor 1: about 12 enemies and the boss -> about 80 % of level 1.
	var first_run: int = 12 * int(skills.call("kill_exp", false)) + int(skills.call("kill_exp", true))
	var share: float = float(first_run) / float(skills.call("exp_to_next", 0))
	check(share >= 0.7 and share < 1.0, "a first run gives about 80 %% of level 1 (%d %%)" % roundi(share * 100.0))
	check_eq(skills.call("kill_exp", false), 2, "a kill gives 2 EXP")
	check_eq(skills.call("kill_exp", true), 25, "a boss 25")
	var run: Object = script("res://scripts/systems/run_state.gd").new(1)
	for i in 10:
		run.call("add_kill_exp", false)
	run.call("add_kill_exp", true)
	check_eq(run.get("exp_earned"), 45, "10 kills and a boss: 45 EXP in the run")
	check_eq(meta.call("add_exp", 45), 0, "after one run: no level yet")
	check_eq(meta.call("exp_points"), 45, "45 of 64 EXP")
	check_eq(meta.call("add_exp", 45), 1, "after the second run: level 1")
	check_eq(meta.call("exp_points"), 26, "26 EXP left over")
	check_eq(meta.call("skill_points"), 1, "level 1: the first skill point")
	check_eq(meta.call("add_exp", 500), 5, "lots of EXP: several levels at once")
	check_eq(meta.call("level"), 6, "level 6")


func _learning() -> void:
	check_eq(skills.call("problem", "leichtfuss"), "Erst den Skill davor lernen", "Leichtfuß needs Kraft first (same group)")
	check_eq(skills.call("problem", "rucksack"), "Zu wenig Gold", "no gold yet")
	var starts: Array = (skills.call("all") as Dictionary).keys().filter(func(id: String) -> bool: return not (skills.call("data", id) as Dictionary).has("requires"))
	check_eq(starts.size(), 5, "five chains, each with its own start")
	# Left only skill points, growing to the left; right only gold, growing to the right.
	for id: String in (skills.call("all") as Dictionary):
		var x: float = float(((skills.call("data", id) as Dictionary)["pos"] as Array)[0])
		var gold: int = 0
		var points: int = 0
		for level in range(1, int(skills.call("max_level", id)) + 1):
			gold += int(skills.call("gold_at", id, level))
			points += int(skills.call("points_at", id, level))
		if x < 0:
			check(gold == 0 and points > 0, "%s (left): only skill points" % id)
		else:
			check(points == 0 and gold > 0, "%s (right): only gold" % id)
		var needed: String = String((skills.call("data", id) as Dictionary).get("requires", ""))
		if not needed.is_empty():
			var from: float = float(((skills.call("data", needed) as Dictionary)["pos"] as Array)[0])
			check(x < from if x < 0 else x > from, "%s grows outwards from %s" % [id, needed])
	# Straight into the box (an end_run above the limit could let Egon steal that night).
	meta.call("gift_gold", 1500)
	var points: int = meta.call("skill_points")
	check(meta.call("buy_skill", "rucksack"), "the backpack can be learned at level 1")
	check_eq(meta.call("box"), 1470, "it cost 30 gold")
	check_eq(meta.call("skill_points"), points, "and no skill point (a gold skill)")
	check(meta.call("buy_skill", "rucksack"), "second level (needs level 5: we are 6)")
	check_eq(skills.call("problem", "rucksack"), "Stufe zu niedrig", "the third level needs level 15")
	check(not meta.call("buy_skill", "rucksack"), "so it cannot be learned")
	check_eq(skills.call("problem", "dicke_haut"), "Erst den Skill davor lernen", "Dicke Haut needs Blaues Herz")
	check(meta.call("buy_skill", "blaues_herz"), "Blaues Herz")
	check_eq(meta.call("skill_points"), points - 1, "it cost a skill point (no gold)")
	check(not meta.call("buy_skill", "blaues_herz"), "Blaues Herz has one level")
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
	check_eq(run.get("shield"), 0, "no skill gives shield hearts any more")
	check_eq(run.get("blue"), 2, "Blaues Herz: one blue heart (two halves)")
	check_eq(run.get("sell_bonus"), 2, "Goldnase 1: the dungeon shop pays 2 gold more per piece")
	check_eq((meta.call("relic_slot_names") as Array).size(), 2, "Relikt-Platz: two relic places")
	var relic: Dictionary = script("res://scripts/systems/shop_goods.gd").call("make_relic", "dreizack")
	check_eq(relic.get("left"), 2, "Reliktpflege: the Dreifachschuss holds 2 dungeons instead of 1")
	var forever: Dictionary = script("res://scripts/systems/shop_goods.gd").call("make_relic", "moorherz")
	check_eq(forever.get("left"), 6, "Moorherz (tier 1): 5 dungeons + 1 Reliktpflege")
	var goods: Script = script("res://scripts/systems/shop_goods.gd")
	check(not goods.call("relic_forever", forever), "tier 1 breaks without Reliktschutz")
	check(meta.call("buy_skill", "reliktschutz"), "Reliktschutz 1")
	check(goods.call("relic_forever", forever), "Reliktschutz 1: tier 1 never breaks")
	check(not goods.call("relic_forever", relic), "but tier 4 still does")
	check(goods.call("relic_forever", {"id": "dreizack", "relic": true, "left": -1}), "for ever stays for ever")


func _window() -> void:
	var window: Control = script("res://scenes/shop/skill_tree_window.gd").new()
	root.add_child(window)
	await process_frame
	window.call("open")
	await process_frame
	var tree: Control = window.call("get_tree_view")
	var before: int = meta.call("skill_level", "leichtfuss")
	for level in range(1, 4):
		check(tree.find_child("Skill_leichtfuss_%d" % level, true, false) != null, "every level of a skill is its own button (%d)" % level)
	check(tree.find_child("Skill_leichtfuss_4", true, false) == null, "no more than max_level")
	var button: Button = tree.find_child("Skill_leichtfuss_%d" % (before + 1), true, false)
	check(button != null and button.tooltip_text.contains("Leichtfuß"), "the tooltip names it")
	var top: Button = tree.find_child("Skill_leichtfuss_1", true, false)
	var below: Button = tree.find_child("Skill_leichtfuss_2", true, false)
	check(below.position.y > top.position.y and is_equal_approx(below.position.x, top.position.x), "the levels stand under each other")
	var kraft: Button = tree.find_child("Skill_kraft_1", true, false)
	check(not is_equal_approx(kraft.position.x, top.position.x) and is_equal_approx(kraft.position.y, top.position.y), "the next skill of a chain stands beside it")
	if before + 2 <= 3:
		var later: Button = tree.find_child("Skill_leichtfuss_%d" % (before + 2), true, false)
		check_eq(script("res://scenes/shop/skill_tree.gd").call("level_problem", "leichtfuss", before + 2), "Erst die Stufe davor lernen", "the level below waits for the one above")
		later.pressed.emit()
		await process_frame
		check_eq(meta.call("skill_level", "leichtfuss"), before, "a click on a locked level learns nothing")
	button.pressed.emit()
	await process_frame
	check_eq(meta.call("skill_level", "leichtfuss"), before + 1, "a click on the next level (gold frame) learns it")
	window.queue_free()
