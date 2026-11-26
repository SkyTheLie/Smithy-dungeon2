extends "res://assets/_reference/_lib/base_test.gd"
## data/*.json: every picture exists, every id that is named somewhere exists, every item and
## synergy has a name and a description, every value is a known stat.

const KNOWN_FLAGS: Array[String] = ["homing", "pierce", "bounce", "boomerang", "split", "wave", "bread", "charge", "jitter", "explosive", "burn", "slow", "grow", "shield", "blast_proof", "mantle",
		"poison", "freeze", "fear", "daze", "spectral", "back", "cross", "shrink", "burst", "overkill", "alternate",
		"bomb_ring", "blast_heal", "damage_cap", "dodge", "thorns", "still_guard", "regen", "kill_heal", "double_heal",
		"desperate", "fury", "small", "stomp", "extra_life", "blue_burst", "discount", "magnet", "choice",
		"bleed", "shuriken", "arrow", "dash", "blink", "fire_slash"]
const KNOWN_STATS: Array[String] = ["damage", "fire_delay", "reach", "shot_speed", "size", "spread", "move_speed", "knockback", "shots", "orbitals", "hearts", "blue_hearts",
		"bomb_size", "luck", "guard_time", "helpers", "body"]


func run() -> void:
	var content: Script = script("res://scripts/core/content.gd")
	var items: Dictionary = content.call("items")
	check_eq(items.size(), 203, "203 items (200 + the three start weapons)")
	var enemies_data: Dictionary = content.call("enemies")
	for id: String in items:
		var item: Dictionary = items[id]
		check(not String(item.get("name", "")).is_empty(), "item %s has a name" % id)
		check(not String(item.get("desc", "")).is_empty(), "item %s has a description" % id)
		check(ResourceLoader.exists(String(item.get("icon", ""))), "item %s icon exists" % id)
		check(String(item.get("category", "")) in ["offensiv", "defensiv", "utility"], "item %s has a category" % id)
		for pool: Variant in item.get("pools", []):
			check(String(pool) in ["shop", "boss", "pact", "shrine"], "item %s: known pool %s" % [id, pool])
		check(not (bool(item.get("secret", false)) and not (item.get("pools", []) as Array).is_empty()), "item %s: secret items only in secret rooms" % id)
		for kind: Variant in item.get("spawn", []):
			check(String(kind) in ["coin", "heart", "bomb", "key"], "item %s: known spawn %s" % [id, kind])
		if item.has("unlock"):
			var unlock: Dictionary = item["unlock"]
			check(String(unlock.get("type", "")) in ["boss", "wins", "kills", "discovered", "best", "fast_win"], "item %s: known unlock" % id)
			if unlock.get("type", "") == "best":
				check(String(unlock.get("key", "")) in ["hearts", "coins", "blue", "clean_floors", "pacts", "floor"], "item %s: known best key" % id)
			if unlock.get("type", "") == "boss":
				check(bool(enemies_data.get(String(unlock.get("id", "")), {}).get("ai", "") == "boss"), "item %s: unlock boss exists" % id)
			else:
				check(int(unlock.get("count", 0)) > 0, "item %s: unlock count > 0" % id)
				if unlock.get("type", "") == "discovered":
					check(int(unlock["count"]) < items.size(), "item %s: unlock count can be reached" % id)
		_check_bonus("item " + id, item)
	for pool: String in ["item", "shop", "boss", "pact", "shrine", "secret"]:
		check((content.call("pool", pool) as Array).size() >= 6, "pool %s has items" % pool)
	check_eq((content.call("pool", "item") as Array).size() + (content.call("pool", "secret") as Array).size(), items.size(), "item room: every item except the secret ones")
	var characters: Dictionary = content.call("characters")
	check(characters.size() >= 3 and characters.has("magier"), "Magier, Bogenschütze, Krieger")
	check(not (characters["magier"] as Dictionary).has("unlock"), "the Magier is there from the start")
	for id: String in characters:
		check(ResourceLoader.exists(String(characters[id].get("icon", ""))), "character %s picture" % id)
		_check_bonus("character " + id, characters[id])
		# The main weapon is a normal item.
		var start_items: Array = characters[id].get("start_items", [])
		check(not start_items.is_empty(), "character %s starts with its weapon item" % id)
		for item_id: Variant in start_items:
			check(items.has(String(item_id)), "character %s: start item %s exists" % [id, item_id])
	var synergies: Dictionary = content.call("synergies")
	for id: String in synergies:
		var synergy: Dictionary = synergies[id]
		check(not String(synergy.get("name", "")).is_empty(), "synergy %s has a name" % id)
		check((synergy.get("requires", []) as Array).size() >= 2, "synergy %s needs two groups" % id)
		for group: Array in synergy.get("requires", []):
			for item_id: Variant in group:
				check(items.has(String(item_id)), "synergy %s: item %s exists" % [id, item_id])
		_check_bonus("synergy " + id, synergy)
	var enemies: Dictionary = content.call("enemies")
	for id: String in enemies:
		var base: String = String(enemies[id].get("sprite", ""))
		check(ResourceLoader.exists(base + "_walk.png"), "enemy %s walk sheet" % id)
		check(ResourceLoader.exists(base + "_death.png"), "enemy %s death sheet" % id)
		check(float(enemies[id].get("hp", 0)) > 0.0, "enemy %s has life" % id)
		check(not (enemies[id].get("voice", {}) as Dictionary).is_empty(), "enemy %s has its own voice" % id)
		check(String(enemies[id].get("ai", "")) in ["lurk", "chase", "fly", "hop", "shooter", "guard", "boss"], "enemy %s: known ai" % id)
		if bool(enemies[id].get("front_guard", false)):
			check(enemies[id].get("ai", "") == "guard", "enemy %s: shield bearers use ai guard (so they can be beaten)" % id)
		if enemies[id].has("summon"):
			check(enemies.has(String(enemies[id]["summon"])), "enemy %s summons a known enemy" % id)
		# Animal cries: known kinds, and every one really makes a sound.
		var cries: Dictionary = enemies[id].get("cries", {})
		for kind: String in cries:
			check(kind in ["idle", "wake", "near", "attack"], "enemy %s: known cry %s" % [id, kind])
			var stream: AudioStreamWAV = SoundSynth.make(cries[kind], "cry")
			check(stream.data.size() > 400, "enemy %s: cry %s has sound" % [id, kind])
		if cries.has("idle"):
			var every: Array = (cries["idle"] as Dictionary).get("every", [3.0, 7.0])
			check(every.size() == 2 and float(every[0]) > 0.5 and float(every[1]) >= float(every[0]), "enemy %s: idle cry not too often" % id)
	# Every boss is different: known attacks, no two with the same list.
	var known_attacks: Array[String] = ["dash", "charge", "summon", "rat_wave", "ring", "spray", "spiral", "burrow", "leap", "teleport", "phase", "mirror", "web", "axes", "boulder", "skulls", "march"]
	var attack_lists: Array = []
	for id: String in enemies:
		if enemies[id].get("ai", "") != "boss":
			continue
		var attacks: Array = enemies[id].get("attacks", [])
		check(attacks.size() >= 3, "boss %s has at least 3 attacks" % id)
		for attack: Variant in attacks:
			check(known_attacks.has(String(attack)), "boss %s: known attack %s" % [id, attack])
		check(not attack_lists.has(attacks), "boss %s fights differently from the others" % id)
		attack_lists.append(attacks)
	var floor_count: int = (content.call("floors") as Array).size()
	check_eq(floor_count, 6, "six floors")
	var theme_of: Array = []
	for index in floor_count:
		var floor_data: Dictionary = content.call("floor_data", index)
		var name: String = "floor %d (%s)" % [index + 1, floor_data.get("name", "")]
		theme_of.append(String(floor_data.get("theme", "")))
		check(not String(floor_data.get("name", "")).is_empty(), "%s has a theme with a name" % name)
		check(ResourceLoader.exists(String(floor_data.get("floor_texture", ""))), "%s floor texture" % name)
		check(ResourceLoader.exists(String(floor_data.get("wall_texture", ""))), "%s wall texture" % name)
		var bosses: Array = floor_data.get("bosses", [])
		check(bosses.size() >= 2 and bosses.size() <= 4, "%s: 2 to 4 bosses" % name)
		for boss: Variant in bosses:
			check(String(enemies.get(String(boss), {}).get("ai", "")) == "boss", "%s boss %s exists" % [name, boss])
		for entry: Array in floor_data.get("enemies", []):
			check(enemies.has(String(entry[0])), "%s enemy %s exists" % [name, entry[0]])
		for id: Variant in floor_data.get("first_room_enemies", []):
			check(enemies.has(String(id)), "%s first room enemy %s exists" % [name, id])
	# The theme changes every second floor.
	for index in floor_count:
		if index % 2 == 1:
			check_eq(theme_of[index], theme_of[index - 1], "floors %d and %d share a theme" % [index, index + 1])
		elif index > 0:
			check(theme_of[index] != theme_of[index - 1], "floor %d has a new theme" % (index + 1))
	_check_loot(content, enemies)


## data/loot.json: every material has a picture, a name, a rarity 1-8 and a value; every enemy
## with loot exists and only drops known materials; every enemy drops something.
func _check_loot(content: Script, enemies: Dictionary) -> void:
	var materials: Dictionary = content.call("materials")
	check(materials.size() >= 5, "there is loot")
	for id: String in materials:
		var entry: Dictionary = materials[id]
		check(ResourceLoader.exists(String(entry.get("icon", ""))), "loot %s picture" % id)
		check(not String(entry.get("name", "")).is_empty() and not String(entry.get("desc", "")).is_empty(), "loot %s name and text" % id)
		check(int(entry.get("rarity", 0)) >= 1 and int(entry.get("rarity", 0)) <= 8, "loot %s rarity 1-8" % id)
		check(int(entry.get("value", 0)) > 0, "loot %s has a value" % id)
	var tables: Dictionary = (content.call("get_file", "loot") as Dictionary).get("enemies", {})
	for enemy_id: String in tables:
		check(enemies.has(enemy_id), "loot for enemy %s: enemy exists" % enemy_id)
		for drop: Dictionary in tables[enemy_id]:
			check(materials.has(String(drop.get("id", ""))), "enemy %s drops known loot %s" % [enemy_id, drop.get("id")])
			var chance: float = float(drop.get("chance", 0.0))
			check(chance > 0.0 and chance <= 1.0, "enemy %s: chance 0-1" % enemy_id)
			var amount: Array = drop.get("amount", [1, 1])
			check(amount.size() == 2 and int(amount[0]) >= 1 and int(amount[1]) >= int(amount[0]), "enemy %s: amount [min, max]" % enemy_id)
	for enemy_id: String in enemies:
		check(tables.has(enemy_id), "enemy %s drops something (loot.json)" % enemy_id)
	var bag: Dictionary = content.call("meta", "bag")
	check(int(bag.get("slots", 0)) > 0 and int(bag.get("safe_slots", 0)) >= 1 and int(bag.get("stack", 0)) > 1, "bag sizes in meta.json")
	var box: Dictionary = content.call("meta", "money_box")
	check(int(box.get("limit", 0)) > 0, "money box limit")
	check(float(box.get("steal_all_chance", 1.0)) + float(box.get("steal_part_chance", 1.0)) < 1.0, "theft chances below 100 %")


func _check_bonus(what: String, source: Dictionary) -> void:
	for flag: Variant in source.get("flags", []):
		check(KNOWN_FLAGS.has(String(flag)), "%s: known flag %s" % [what, flag])
	for key: String in (source.get("stats", {}) as Dictionary):
		check(KNOWN_STATS.has(key.trim_suffix("_mult")), "%s: known stat %s" % [what, key])
	for key: String in (source.get("per_coin", {}) as Dictionary):
		check(KNOWN_STATS.has(key), "%s: known per_coin stat %s" % [what, key])
	for key: String in (source.get("give", {}) as Dictionary):
		check(key in ["coins", "bombs", "keys"], "%s: known give %s" % [what, key])
		check(int(source["give"][key]) > 0, "%s: give %s is positive" % [what, key])
	for flag: String in (source.get("chance", {}) as Dictionary):
		check(KNOWN_FLAGS.has(flag), "%s: known chance flag %s" % [what, flag])
		check(float(source["chance"][flag]) > 0.0 and float(source["chance"][flag]) < 1.0, "%s: chance between 0 and 1" % what)
	if source.has("mode"):
		check(String(source["mode"]) in ["fire", "beam", "bomb", "melee"], "%s: known mode" % what)
