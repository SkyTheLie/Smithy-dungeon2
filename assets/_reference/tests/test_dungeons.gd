extends "res://assets/_reference/_lib/base_test.gd"
## Four dungeons (data/dungeons.json): each has its own six floors (floors.json floors_<id>, two
## per area), the next one opens after the one before was won (MetaState.win_dungeon), and its
## numbers work into the floors (life, EXP, shop prices). Egon's materials open with the dungeons
## (shop.json materials: bronze at level 3, iron after the first dungeon …), the lever gets dearer
## with them, the Größere Dose makes the box safe for more. The traps (hazard_types) are known and
## only hurt while they are dangerous. Fixed seeds.

var meta: Script
var content: Script
var goods: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	content = script("res://scripts/core/content.gd")
	goods = script("res://scripts/systems/shop_goods.gd")
	meta.call("start_new")
	_floors()
	_unlocks()
	_materials()
	_box()
	await _hazards()


func _floors() -> void:
	var dungeons: Dictionary = content.call("dungeons")
	check_eq(dungeons.keys(), ["glut", "moor", "frost", "vulkan"], "four dungeons in order")
	var enemies: Dictionary = content.call("enemies")
	var types: Dictionary = content.call("floors_extra", "hazard_types")
	var used_themes: Array = []
	var before_hp: float = 0.0
	for id: String in dungeons:
		var floors: Array = content.call("floors", id)
		check_eq(floors.size(), 6, "%s: six floors" % id)
		var first: Dictionary = content.call("floor_data", 0, id)
		check(float(first.get("hp_mult", 0.0)) > before_hp, "%s: enemies have more life than in the dungeon before" % id)
		before_hp = float(first.get("hp_mult", 0.0))
		for index in floors.size():
			var data: Dictionary = content.call("floor_data", index, id)
			var name: String = "%s floor %d" % [id, index + 1]
			check(not String(data.get("name", "")).is_empty(), "%s has an area" % name)
			check(ResourceLoader.exists(String(data.get("floor_texture", ""))) and ResourceLoader.exists(String(data.get("wall_texture", ""))), "%s textures" % name)
			check(not String(script("res://scripts/core/content.gd").call("get_file", "audio").get("music", {}).get(String(data.get("music", "")), "")).is_empty(), "%s has music" % name)
			for entry: Array in data.get("enemies", []):
				check(enemies.has(String(entry[0])) and enemies[String(entry[0])].get("ai", "") != "boss", "%s: enemy %s exists" % [name, entry[0]])
			for boss: Variant in data.get("bosses", []):
				check(String(enemies.get(String(boss), {}).get("ai", "")) == "boss", "%s: boss %s exists" % [name, boss])
			for hazard: Array in data.get("hazards", []):
				check(types.has(String(hazard[0])), "%s: known trap %s" % [name, hazard[0]])
			if id != "glut" and index % 2 == 0 and not used_themes.has(data.get("theme")):
				used_themes.append(data.get("theme"))
	check_eq(used_themes.size(), 9, "nine new areas")
	# The dungeon's numbers work into the floor (dungeons.json hp_mult x floor hp_mult …).
	var deep: Dictionary = content.call("floor_data", 5, "vulkan")
	var vulkan: Dictionary = dungeons["vulkan"]
	var shape: Dictionary = (content.call("floors", "vulkan") as Array)[5]
	check(is_equal_approx(float(deep["hp_mult"]), float(shape["hp_mult"]) * float(vulkan["hp_mult"])), "life = floor x dungeon")
	check_eq(float(deep["exp_mult"]), float(vulkan["exp_mult"]), "EXP of the dungeon")
	check(float(deep["shop_mult"]) > float(vulkan["shop_mult"]), "the run shop gets dearer deeper down")
	check_eq(content.call("floors").size(), 6, "without a dungeon: the first one")


func _unlocks() -> void:
	check(meta.call("is_dungeon_open", "glut"), "the first dungeon is open")
	check(not meta.call("is_dungeon_open", "moor"), "the Moor is closed at first")
	check_eq(script("res://scenes/shop/dungeon_board.gd").call("lock_text", "moor"), "Gesperrt: erst Dungeon der Glut schaffen.", "the board says what opens it")
	meta.call("win_dungeon", "glut")
	check(meta.call("is_dungeon_open", "moor"), "won the first: the Moor opens")
	check(not meta.call("is_dungeon_open", "frost"), "but not the one after it")
	meta.call("reload")
	check(meta.call("has_won", "glut"), "the win is saved in the slot")
	meta.call("start_new")
	check(not meta.call("has_won", "glut"), "a new game starts over")


func _materials() -> void:
	check_eq(_ids(goods.call("open_materials")), ["copper"], "level 0: only copper")
	check_eq(goods.call("next_material").get("id"), "bronze", "bronze comes next")
	meta.call("_write", "level", 3)
	check_eq(_ids(goods.call("open_materials")), ["copper", "bronze"], "level 3: bronze too")
	check_eq(goods.call("roll_price", 1), 10, "copper and bronze: the lever costs as before")
	meta.call("win_dungeon", "glut")
	check_eq(_ids(goods.call("open_materials")), ["copper", "bronze", "iron"], "after the first dungeon: iron")
	check_eq(goods.call("roll_price", 1), 30, "with iron the lever costs 3 times")
	meta.call("win_dungeon", "moor")
	var weights: Array = goods.call("open_materials")
	check(float(weights[0][1]) < 10.0, "silver open: copper is rare now (%s)" % [weights[0][1]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Dictionary = {}
	for i in 60:
		for place: Dictionary in goods.call("roll", rng, 0):
			if not place.is_empty() and not place.get("relic", false):
				seen[String(content.call("gear_item", String(place["id"])).get("material", ""))] = true
	check(seen.has("iron") and seen.has("silver"), "iron and silver come on the table (%s)" % [seen.keys()])
	check(not seen.has("gold"), "gold not yet (needs the Frostgipfel)")
	var chances: Array = goods.call("material_chances")
	check(is_equal_approx(chances.reduce(func(sum: float, part: Array) -> float: return sum + float(part[1]), 0.0), 100.0), "material chances: 100 %")
	meta.call("start_new")


func _box() -> void:
	check_eq(meta.call("box_limit"), 200, "the box: 200 safe")
	meta.call("_write", "skills", {"groessere_dose": 2})
	check_eq(meta.call("box_limit"), 800, "Größere Dose 2: 600 more")
	meta.call("start_new")


## A trap in a real room: lava always hurts, spikes only while they are out.
func _hazards() -> void:
	var types: Dictionary = content.call("floors_extra", "hazard_types")
	for kind: String in types:
		if kind.begins_with("_"):
			continue
		check(int(types[kind].get("damage", 0)) > 0, "trap %s hurts" % kind)
	var lava: Node3D = script("res://scenes/objects/hazard.gd").new()
	lava.call("setup", "lava", types["lava"], 2.0, 0.0)
	root.add_child(lava)
	lava.global_position = Vector3(10, 0, 10)
	check(lava.call("hurts_at", Vector3(10.5, 1.0, 9.5)), "standing on lava hurts")
	check(not lava.call("hurts_at", Vector3(11.5, 0, 10)), "next to it not")
	var spikes: Node3D = script("res://scenes/objects/hazard.gd").new()
	spikes.call("setup", "spikes", types["spikes"], 1.5, 0.0)
	root.add_child(spikes)
	check(not spikes.call("is_dangerous"), "spikes start down")
	var cycle: Array = types["spikes"]["cycle"]
	check(await wait_until(func() -> bool: return spikes.call("is_dangerous"), float(cycle[0]) + 1.0), "then they come out")
	check(spikes.call("hurts_at", spikes.global_position), "and hurt")
	check(await wait_until(func() -> bool: return not spikes.call("is_dangerous"), float(cycle[1]) + 1.0), "and go in again")
	lava.queue_free()
	spikes.queue_free()


func _ids(parts: Array) -> Array:
	return parts.map(func(part: Array) -> String: return String(part[0]))
