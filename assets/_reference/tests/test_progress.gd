extends "res://assets/_reference/_lib/base_test.gd"
## Progress (user://progress.cfg): picked-up items are remembered, kills / bosses / wins unlock
## items, and it is all still there after loading the file again.


func run() -> void:
	var progress: Script = script("res://scripts/systems/progress.gd")
	check(not progress.call("is_discovered", "glutkern"), "nothing discovered at first")
	check(not progress.call("is_unlocked", "gesprengte_fessel"), "Gesprengte Fessel locked at first")
	check(progress.call("is_unlocked", "glutkern"), "items without unlock are open")

	var run_state: Object = script("res://scripts/systems/run_state.gd").new(1)
	# The Magier's Glutstab (start weapon) counts as discovered as well.
	check(progress.call("is_discovered", "glutstab"), "the start weapon is discovered")
	run_state.call("add_item", "glutkern")
	check(progress.call("is_discovered", "glutkern"), "picking up an item discovers it")
	check_eq((progress.call("discovered") as Array).size(), 2, "discovered once only")
	run_state.call("add_item", "glutkern")
	check_eq((progress.call("discovered") as Array).size(), 2, "the same item counts once")

	var test_run: Object = script("res://scripts/systems/run_state.gd").new(2)
	test_run.set("record_progress", false)
	test_run.call("add_item", "blasebalg")
	check(not progress.call("is_discovered", "blasebalg"), "a test room run does not count")

	var opened: Array = progress.call("beat_boss", "rat_king")
	check(opened.has("gesprengte_fessel"), "beating the Rattenkönig unlocks Gesprengte Fessel")
	check(progress.call("is_unlocked", "gesprengte_fessel"), "and it stays open")
	check((progress.call("beat_boss", "rat_king") as Array).is_empty(), "beating it again unlocks nothing new")

	check((progress.call("add_kills", 150) as Array).is_empty(), "150 kills: not enough for 200")
	check((progress.call("add_kills", 50) as Array).has("ruhmeskette"), "200 kills unlock the Ruhmeskette")
	var characters: Dictionary = script("res://scripts/core/content.gd").call("characters")
	check(not progress.call("meets", characters["bogenschuetze"]["unlock"]), "Bogenschütze locked at first")
	var after_win: Array = progress.call("add_win")
	check(after_win.has("mondsiegel"), "a win unlocks the Mondsiegel")
	check(after_win.has("bogenschuetze"), "a win unlocks the Bogenschütze")

	# Load the file again: everything is still there.
	progress.call("reload")
	check(progress.call("is_discovered", "glutkern"), "discovered after loading")
	check_eq(progress.call("kills"), 200, "kills after loading")
	check_eq(progress.call("wins"), 1, "wins after loading")
	check(progress.call("is_unlocked", "gesprengte_fessel"), "unlocks after loading")
	check(not progress.call("is_unlocked", "goblinkrone"), "Goblinkrone still locked (Ork-Häuptling not beaten)")

