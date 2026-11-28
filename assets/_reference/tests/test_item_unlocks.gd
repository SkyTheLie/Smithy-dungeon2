extends "res://assets/_reference/_lib/base_test.gd"
## Item unlocks like in Isaac (data/items.json "unlock"): about half of the relic items have to be
## unlocked first: beat an enemy so often ("kill"), do something so often ("count": dying, by a
## trap, Egon's lever, sacrifices …), have loot in the bag at once ("best" "loot:<id>"). Locked
## items never come in the dungeon; what opened outside a run waits for the shop (take_fresh).


func run() -> void:
	var progress: Script = script("res://scripts/systems/progress.gd")
	var content: Script = script("res://scripts/core/content.gd")
	var items: Dictionary = content.call("items")
	var relics: Dictionary = (content.call("get_file", "relics") as Dictionary).get("items", {})

	# About half of the relics that were free before need an unlock now.
	var locked: int = 0
	for id: Variant in relics:
		if (items.get(String(id), {}) as Dictionary).has("unlock"):
			locked += 1
	check(locked >= 90 and locked <= 110, "about half of the relics are locked (%d of %d)" % [locked, relics.size()])

	# "kill": the Rattenfell-loving Brotkanone wants 150 rats.
	check(not progress.call("is_unlocked", "brotkanone"), "Brotkanone locked at first")
	for i in 149:
		progress.call("add_enemy_kill", "rat")
	check(not progress.call("is_unlocked", "brotkanone"), "149 rats are not enough")
	check((progress.call("add_enemy_kill", "rat") as Array).has("brotkanone"), "the 150th rat unlocks the Brotkanone")
	check_eq(progress.call("kills"), 150, "every enemy kill counts for the kills too")

	# "count": dying, by a trap, Egon's lever.
	check((progress.call("add_count", "deaths") as Array).has("kinderschuhe"), "dying once unlocks the Kinderschuhe")
	check((progress.call("add_count", "deaths_trap") as Array).has("eisenhaut"), "dying by a trap unlocks the Eisenhaut")
	check((progress.call("add_count", "nonsense") as Array).is_empty(), "unknown keys count nothing")
	check_eq(progress.call("count", "nonsense"), 0, "and stay 0")
	check((progress.call("add_count", "rerolls", 0) as Array).is_empty(), "0 counts nothing")

	# Opened outside a run: the shop gets them once.
	var fresh: Array = progress.call("take_fresh")
	check(fresh.has("kinderschuhe") and fresh.has("eisenhaut"), "unlocks wait for the shop")
	check((progress.call("take_fresh") as Array).is_empty(), "and only once")

	# In a run: picking up loot counts how many are in the bag ("best" "loot:bomb").
	var run_state: Object = script("res://scripts/systems/run_state.gd").new(1)
	var bag: Object = run_state.get("bag")
	bag.call("add", "bomb", 19)
	run_state.call("note_loot", "bomb")
	check(not progress.call("is_unlocked", "pulverhand"), "19 bombs are not enough")
	bag.call("add", "bomb", 1)
	run_state.call("note_loot", "bomb")
	check(progress.call("is_unlocked", "pulverhand"), "20 bombs at once unlock the Pulverhandschuh")
	check((progress.call("take_fresh") as Array).is_empty(), "the run showed it itself (banner)")

	# A test room run counts nothing.
	var test_run: Object = script("res://scripts/systems/run_state.gd").new(2)
	test_run.set("record_progress", false)
	test_run.call("count", "secret_rooms")
	check_eq(progress.call("count", "secret_rooms"), 0, "the test room does not count")
	run_state.call("count", "secret_rooms")
	check(progress.call("is_unlocked", "schatzkarte"), "a secret room unlocks the Schatzkarte")

	# Locked items never come in the dungeon.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var picker: Object = script("res://scripts/systems/run_state.gd").new(3)
	for i in 300:
		var id: String = picker.call("pick_item", "item", rng)
		if id.is_empty():
			break
		check(progress.call("is_unlocked", id), "picked item %s is unlocked" % id)

	# The lexicon says what is missing, with the progress.
	var lexicon: Script = script("res://scenes/ui/menus/lexicon_window.gd")
	var text: String = lexicon.call("unlock_text", (items["giftzahn"] as Dictionary)["unlock"])
	check(text.contains("40") and text.contains("0 / 40"), "Giftzahn: '%s'" % text)
	text = lexicon.call("unlock_text", (items["lebenstau"] as Dictionary)["unlock"])
	check(text.contains("50"), "Lebenstau: '%s'" % text)

	# Everything is still there after loading the file again.
	progress.call("reload")
	check_eq(progress.call("enemy_kills", "rat"), 150, "enemy kills after loading")
	check_eq(progress.call("count", "deaths"), 1, "counts after loading")
	check(progress.call("is_unlocked", "pulverhand"), "best loot after loading")
