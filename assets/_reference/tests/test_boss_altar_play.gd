extends "res://assets/_reference/_lib/base_test.gd"
## The Boss-Altar in the real run scene: a hall bigger than a room (the portal after the boss of
## the last floor leads here); the whole scene at the altar plays (dark, crystals, pillars light up, silence, the boss
## falls in: the end boss of the dungeon), the player cannot move meanwhile, the boss stays still while its bar fills, then the
## fight music runs and the fight starts. The admin menu (P) opens, gives an item, puts on gear
## and a relic, takes the player to the Boss-Altar and back to a room.

var scene: Node
var dungeon: Node
var player: Node3D
var run_state: Object


func run() -> void:
	var game: Node = root.get_node("Game")
	run_state = script("res://scripts/systems/run_state.gd").new(123)
	game.set("run", run_state)
	scene = (load("res://scenes/run/run.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	await physics_frame
	dungeon = scene.get_node("%Dungeon")
	player = scene.get_node("%Player") as Node3D
	await _scene()
	await _admin()


func _scene() -> void:
	var audio: Node = root.get_node("AudioManager")
	var hud: CanvasLayer = scene.get_node("HUD") as CanvasLayer
	dungeon.call("enter_boss_altar")
	var hall: Node3D = dungeon.get("altar")
	check(dungeon.call("in_boss_altar"), "in the Boss-Altar")
	var rect: Rect2 = dungeon.call("room_rect", 0.0)
	check(rect.size.x > 20.0 and rect.size.y > 15.0, "the hall is bigger than a room (%s)" % str(rect.size))
	check_eq(audio.call("get_music_id"), "altar", "gloomy music in the hall")
	var parts: Array = hall.get("_parts")
	check_eq(parts.size(), 9, "nine pillars")
	# Walk to the altar: the scene starts.
	player.global_position = hall.global_position + Vector3(0, 0, 4.0)
	check(await wait_until(func() -> bool: return not player.get("controls_enabled"), 1.0), "near the altar the scene starts, the player stands still")
	check(not hud.visible, "no HUD during the scene")
	check(await wait_until(func() -> bool: return parts.all(func(p: Dictionary) -> bool: return p["crystal"] != null), 4.0), "the crystals fly in")
	check(await wait_until(func() -> bool: return parts.all(func(p: Dictionary) -> bool: return bool(p["lit"])), 12.0), "every pillar lights up")
	check(await wait_until(func() -> bool: return audio.call("get_music_id") == "", 3.0), "silence before the boss")
	check(dungeon.get("boss") == null, "no boss yet")
	check(await wait_until(func() -> bool: return dungeon.get("boss") != null, 5.0), "the boss lands")
	var boss: Node3D = dungeon.get("boss")
	var end_boss: String = String(script("res://scripts/core/content.gd").call("end_boss", ""))
	check(not end_boss.is_empty(), "the first dungeon has an end boss")
	check_eq(String(boss.get("id")), end_boss, "the end boss of the dungeon lands")
	check_eq(audio.call("get_music_id"), "boss_rock", "the fight music starts at the landing")
	check(hud.visible, "the HUD is back")
	check(not boss.is_physics_processing(), "the boss waits while its life bar fills")
	check(await wait_until(func() -> bool: return player.get("controls_enabled"), 2.0), "then the player may move")
	check(boss.is_physics_processing(), "and the boss fights")
	check((boss.global_position - (hall.call("boss_spot") as Vector3)).length() < 0.5, "it landed behind the altar")
	boss.call("take_damage", 99999.0, Vector3.ZERO, false)
	check(await wait_until(func() -> bool: return not dungeon.call("is_fighting"), 2.0), "boss beaten")
	check(hall.get("exit_open"), "the gate opens")
	# Egon's quest: the end boss leaves the Glutrubin (data/quests.json).
	var stone: bool = (hall.get("loot") as Array).any(func(node: Variant) -> bool:
		return is_instance_valid(node) and (node as Node).get("material_id") == "glutrubin")
	check(stone, "the end boss drops the Glutrubin for Egon's quest")


func _admin() -> void:
	var menu: CanvasLayer = scene.get("admin_menu")
	check(menu != null, "the admin menu exists in debug builds")
	menu.call("open")
	check(menu.visible and paused, "P opens it and stops the game")
	var before: int = (run_state.get("items") as Array).size()
	var ids: Array = menu.get("_item_ids")
	menu.call("_on_give_item", 0)
	check_eq((run_state.get("items") as Array).size(), before + 1, "an item is given (%s)" % ids[0])
	# Gear: the first copper weapon, then a relic.
	var entries: Array = menu.get("_gear_entries")
	var weapon: int = entries.find_custom(func(e: Dictionary) -> bool: return e["kind"] == "gear" and String(e["id"]).ends_with("_staff"))
	menu.call("_on_wear", weapon)
	var meta: Script = script("res://scripts/systems/meta_state.gd")
	check((meta.call("equipment") as Dictionary).has("weapon"), "gear is put on")
	var relic: int = entries.find_custom(func(e: Dictionary) -> bool: return e["kind"] == "relic")
	if relic >= 0:
		var relic_id: String = String(entries[relic]["id"])
		menu.call("_on_wear", relic)
		check(run_state.call("has_item", relic_id), "a relic counts in the run at once")
	menu.call("_on_take_off", "weapon")
	check(not (meta.call("equipment") as Dictionary).has("weapon"), "and taken off")
	menu.call("close")
	check(not paused, "closing goes on with the game")
	var layout: Object = dungeon.get("layout")
	var start: Vector2i = layout.call("cell_of", "start")
	dungeon.call("teleport_to_cell", start)
	check_eq(dungeon.get("current_cell"), start, "admin: back to the start room")
	dungeon.call("teleport_to_boss_altar")
	check(dungeon.call("in_boss_altar"), "admin: into the Boss-Altar")
	scene.queue_free()
	await process_frame
