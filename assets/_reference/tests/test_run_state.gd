extends "res://assets/_reference/_lib/base_test.gd"
## RunState and ShotStats: start values, items change the shot (double/triple/shotgun, beam, bomb),
## synergies are found and announced, life / coins / keys / bombs follow the rules.


func run() -> void:
	var run_script: Script = script("res://scripts/systems/run_state.gd")
	var base: Dictionary = script("res://scripts/core/content.gd").call("player")
	var run: Object = run_script.new(1)
	var stats: Object = run.get("stats")
	check_eq(stats.get("shots"), 1, "one fireball at the start")
	check_eq(stats.get("reach"), float(base["stats"]["reach"]), "start reach from player.json")
	check_eq(stats.get("mode"), "fire", "fire mode at the start")
	check_eq(run.get("health"), int(base["hearts"]) * 2, "full life at the start")

	run.call("add_item", "zwillingsstab")
	check_eq(run.get("stats").get("shots"), 2, "Gegabelter Stab: double shot")
	run.call("add_item", "dreizack")
	check_eq(run.get("stats").get("shots"), 4, "plus Dreizack: four fireballs")
	run.call("add_item", "leichte_feder")
	check_eq(run.get("stats").get("reach"), float(base["stats"]["reach"]) + 2.0, "Leichte Feder: +2 m reach")

	var found: Array = []
	run.connect("synergy_found", func(id: String) -> void: found.append(id))
	run.call("add_item", "suchender_funke")
	check(run.get("stats").call("has", "homing"), "Suchender Funke: homing")
	check(found.has("feuerwerk"), "homing + multi shot = Feuerwerk")

	run.call("add_item", "pulverhand")
	check_eq(run.get("stats").get("mode"), "bomb", "Pulverhandschuh: bombs")
	run.call("add_item", "feuerlanze")
	check_eq(run.get("stats").get("mode"), "beam", "beam wins over bombs")
	check(run.get("stats").call("has", "explosive"), "beam + bombs = Sprengstrahl (explosive)")
	check(found.has("suchender_strahl"), "beam + homing = Suchender Strahl")
	check(found.has("sprengstrahl"), "Sprengstrahl announced")

	# Shotgun: more fireballs, wider spread, slower.
	var shotgun: Object = run_script.new(2)
	var delay_before: float = shotgun.get("stats").get("fire_delay")
	shotgun.call("add_item", "kohlenschrot")
	check_eq(shotgun.get("stats").get("shots"), 6, "Kohlenschrot: six fireballs")
	check(shotgun.get("stats").get("fire_delay") > delay_before, "Kohlenschrot shoots slower")
	check(shotgun.get("stats").call("has", "jitter"), "Kohlenschrot scatters")

	# Life.
	var life: Object = run_script.new(3)
	var full: int = life.get("health")
	check(not life.call("take_damage", 0), "0 damage does nothing")
	check(life.call("take_damage", 1), "half a heart")
	check_eq(life.get("health"), full - 1, "life after half a heart")
	check(life.call("heal", 2), "heal when hurt")
	check(not life.call("heal", 2), "no healing when full")
	life.call("add_item", "herzblatt")
	check_eq(life.get("max_hearts"), int(base["hearts"]) + 1, "Herzblatt: one heart more")
	check_eq(life.get("health"), life.get("max_hearts") * 2, "Herzblatt heals fully")
	var died: Array = [false]
	life.connect("died", func() -> void: died[0] = true)
	life.call("take_damage", 99)
	check(life.call("is_dead"), "dead at 0 life")
	check(died[0], "died is sent")

	# Coins, keys, bombs.
	var wallet: Object = run_script.new(4)
	check(not wallet.call("spend", 5), "cannot pay without coins")
	wallet.call("add_coins", 7)
	check(wallet.call("spend", 5), "pay 5 of 7")
	check_eq(wallet.get("coins"), 2, "2 coins left")
	check(not wallet.call("spend", -1), "negative price refused")
	var keys: int = wallet.get("keys")
	for i in keys:
		check(wallet.call("use_key"), "use key %d" % i)
	check(not wallet.call("use_key"), "no key left")
	# Bombs and keys are loot in the bag: bombs stack to 5 on a cell, keys one per cell.
	var pouch: Object = wallet.get("bag")
	var bombs: int = wallet.get("bombs")
	wallet.call("add_bombs", 5 - bombs)
	check_eq(pouch.call("count_of", "bomb"), 5, "5 bombs in the bag")
	var places: int = pouch.call("size")
	wallet.call("add_bombs", 1)
	check_eq(pouch.call("size"), places + 1, "the 6th bomb needs a new cell")
	check(wallet.call("use_bomb"), "throwing takes a bomb out")
	check_eq(wallet.get("bombs"), 5, "5 left")
	wallet.call("add_keys", 2)
	pouch.call("add", "iron_key", 1)
	check_eq(wallet.get("keys"), 3, "two fragile keys and an iron key")
	check_eq(wallet.call("fragile_keys"), 2, "two of them fragile")
	var cells: int = 0
	for i in pouch.call("size"):
		if String((pouch.call("get_place", i) as Dictionary).get("id", "")) == "key":
			cells += 1
	check_eq(cells, 2, "keys do not stack: one cell each")
	check(wallet.call("use_key"), "a door opens")
	check_eq(wallet.call("fragile_keys"), 1, "a fragile key goes first")
	check_eq(pouch.call("count_of", "iron_key"), 1, "the iron key stays")

	# Item picks never repeat.
	var picker: Object = run_script.new(5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var picked: Array = []
	for i in 40:
		var id: String = picker.call("pick_item", "item", rng)
		if id.is_empty():
			break
		check(not picked.has(id), "item %s offered twice" % id)
		picked.append(id)
	check(picked.size() > 5, "item pool has enough items")

	# New items: give, per_coin, mantle, clearing (test room).
	var extra: Object = run_script.new(6)
	var bombs_before: int = extra.get("bombs")
	extra.call("add_item", "wanderbuendel")
	check_eq(extra.get("bombs"), bombs_before + 3, "Wanderbündel gives 3 bombs")
	check_eq(extra.get("coins"), 0, "Wanderbündel gives no coins")
	check_eq((extra.get("bag") as Object).call("count_of", "amber"), 1, "but an amber for the bag")
	var damage_before: float = extra.get("stats").get("damage")
	extra.call("add_item", "goldglut")
	var coins: int = extra.get("coins")
	check(is_equal_approx(extra.get("stats").get("damage"), damage_before + 0.04 * coins), "Goldglut: damage per coin")
	extra.call("add_coins", 10)
	check(is_equal_approx(extra.get("stats").get("damage"), damage_before + 0.04 * (coins + 10)), "more coins, more damage")
	check(not extra.call("block_with_mantle"), "no mantle without the Glutmantel")
	extra.call("add_item", "glutmantel")
	check(extra.call("block_with_mantle"), "Glutmantel catches the first hit")
	check(not extra.call("block_with_mantle"), "only once per room")
	extra.call("refresh_mantle")
	check(extra.call("block_with_mantle"), "again in the next room")
	extra.call("add_item", "herzblatt")
	extra.call("clear_items")
	check_eq(extra.get("items"), ["glutstab"], "clear_items drops every item but the main weapon")
	check_eq(extra.get("max_hearts"), int(base["hearts"]), "hearts back to the start value")
	check(is_equal_approx(extra.get("stats").get("damage"), damage_before), "shot back to the start values")

	# Blue hearts: on top of the red ones, hits take them first.
	var blue: Object = run_script.new(7)
	blue.call("add_item", "mondlilie")
	check_eq(blue.get("blue"), 4, "Mondlilie: two blue hearts (4 halves)")
	var red: int = blue.get("health")
	blue.call("take_damage", 3)
	check_eq(blue.get("blue"), 1, "a hit takes blue halves first")
	check_eq(blue.get("health"), red, "red hearts untouched")
	blue.call("take_damage", 2)
	check_eq(blue.get("blue"), 0, "blue hearts used up")
	check_eq(blue.get("health"), red - 1, "the rest goes to the red hearts")
	check(not blue.call("heal", 0), "no heal of 0")
	blue.call("add_blue_hearts", 30)
	check(int(blue.get("max_hearts")) * 2 + int(blue.get("blue")) <= 24, "red and blue together at most 12 hearts")

	# Locked items never come from a pool before they are unlocked.
	var content_script: Script = script("res://scripts/core/content.gd")
	var locked: Object = run_script.new(8)
	var lock_rng := RandomNumberGenerator.new()
	lock_rng.seed = 8
	var offered: Array = []
	for i in 300:
		var id: String = locked.call("pick_item", "item", lock_rng)
		if id.is_empty():
			break
		offered.append(id)
	check(not offered.has("mondsiegel"), "Mondsiegel (win a run) is locked at first")
	check(offered.has("glutkern"), "normal items come")
	for id: String in offered:
		check(script("res://scripts/systems/progress.gd").call("is_unlocked", id), "no locked item offered: %s" % id)
		check(not bool((content_script.call("item", id) as Dictionary).get("secret", false)), "no secret item in the item room: %s" % id)
	var boss_items: Array = content_script.call("pool", "boss")
	for id: String in boss_items:
		var flags: Array = (content_script.call("item", id) as Dictionary).get("flags", [])
		var boss_item: Dictionary = content_script.call("item", id)
		check(flags.is_empty() and not boss_item.has("mode") and not boss_item.has("chance"), "boss pool: only plain stat/heart items (%s)" % id)

	# Pacts: heart containers for an item; after a pact only pacts come.
	var pact: Object = run_script.new(9)
	var hearts_before: int = pact.get("max_hearts")
	check(pact.call("take_pact", "opferdolch", 1), "a pact for one heart container")
	check_eq(pact.get("max_hearts"), hearts_before - 1, "one heart container less")
	check(pact.call("has_item", "opferdolch"), "the pact item is there")
	check(not pact.call("take_pact", "jadefigur", 9), "a pact that would kill is refused")
	var special_rng := RandomNumberGenerator.new()
	special_rng.seed = 3
	pact.set("special_chance", 1.0)
	check_eq(pact.call("roll_special_room", special_rng), "pact", "after a pact only pacts")

	# Damage cap and extra life.
	var tough: Object = run_script.new(10)
	tough.call("add_item", "eisenhaut")
	var health_before: int = tough.get("health")
	tough.call("take_damage", 4)
	check_eq(tough.get("health"), health_before - 1, "Eisenhaut: a hit takes half a heart at most")
	var phoenix: Object = run_script.new(11)
	phoenix.call("add_item", "sternentrunk")
	phoenix.call("take_damage", 99)
	check(not phoenix.call("is_dead"), "Sternentrunk: a second life")
	check(not phoenix.call("has_item", "sternentrunk"), "the second life is used up")
	phoenix.call("take_damage", 99)
	check(phoenix.call("is_dead"), "the third time it is over")

	# Chance flags and luck.
	var lucky: Object = run_script.new(12)
	lucky.call("add_item", "hexenkessel")
	var stats_now: Object = lucky.get("stats")
	check(is_equal_approx(stats_now.call("chance", "poison"), 0.2), "Hexenkessel: 20 % poison")
	lucky.call("add_item", "kristallkarte")
	check(float(lucky.get("stats").call("chance", "poison")) > 0.2, "luck raises the chance")
	check_eq(lucky.get("stats").call("chance", "homing"), 0.0, "no chance without an item")

	# Characters: the Krieger swings a sword and has 4 hearts, the Bogenschütze charges arrows.
	var warrior: Object = run_script.new(13, "krieger")
	check_eq(warrior.get("stats").get("mode"), "melee", "Krieger: sword swing")
	check_eq(warrior.get("max_hearts"), 4, "Krieger: four hearts")
	var archer: Object = run_script.new(14, "bogenschuetze")
	check(archer.get("stats").call("has", "charge"), "Bogenschütze: charges the shot")
	check(float(archer.get("stats").get("reach")) > float(base["stats"]["reach"]) + 3.0, "Bogenschütze: much more range")
	check_eq(run_script.new(15, "unknown").get("character"), "magier", "unknown character = Magier")
	# The main weapon is an item: the Magier starts with the Glutstab, the Krieger with his sword.
	var mage: Object = run_script.new(17, "magier")
	check(mage.call("has_item", "glutstab"), "Magier starts with the Glutstab")
	check(warrior.call("has_item", "kriegerschwert"), "Krieger starts with the Kriegerschwert")
	check(archer.call("has_item", "jagdbogen"), "Bogenschütze starts with the Jagdbogen")
	# Crossing weapons: Glutstab + a sword or axe = Feuerhieb (swing plus a band of fire).
	mage.call("add_item", "kriegsaxt")
	check_eq(mage.get("stats").get("mode"), "melee", "Magier with the Kriegsaxt swings")
	check((mage.get("synergies") as Array).has("feuerhieb"), "Glutstab + Kriegsaxt = Feuerhieb")
	check(mage.get("stats").call("has", "fire_slash"), "Feuerhieb sends a band of fire")
	check(not warrior.get("stats").call("has", "fire_slash"), "a sword alone: no fire band")
	# The test room keeps the main weapon.
	mage.call("clear_items")
	check_eq(mage.get("items"), ["glutstab"], "clearing items keeps the Glutstab")
	# Body size: items multiply, so they combine.
	var size: Object = run_script.new(16)
	size.call("add_item", "riesentrank")
	size.call("add_item", "schrumpftrank")
	check(is_equal_approx(size.get("stats").get("body"), 1.3 * 0.75), "Riesentrank and Schrumpftrank combine")
