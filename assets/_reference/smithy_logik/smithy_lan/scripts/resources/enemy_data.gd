class_name EnemyData
extends Resource
## A kind of monster/enemy (rat ...). Created by ContentDB from data/content/enemies.json
## (format: docs/CONTENT.md).

@export var id: StringName
@export var display_name: String = "":
	get:
		return Language.translate(display_name)
## Base level (shown in fights; later for scaling).
@export var level: int = 1

@export_group("Sprite")
## Sprite sheet: frames side by side, each frame_size big. One frame = a still picture.
@export var sprite_sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(16, 16)
@export var frame_count: int = 1
@export var frames_per_second: float = 4.0
## Pictures played once in fights (same frame size): skill id or pose ("lunge", "cast" ...), "hit"
## (being hit), "death" (stays on its last frame) -> {"sheet": Texture2D, "frames": int, "fps": float}, optional
## "frame_size": Vector2i when its pictures are bigger than frame_size (e.g. fire breath with room to
## the left); they are padded evenly on both sides, so the monster stays where it is.
@export var animations: Dictionary = {}
## Size in fights compared to a normal monster (1.5 = half again as big, e.g. for bosses).
@export var scale: float = 1.0
## Flies: floats above the ground in fights and bobs up and down (enemies.json "hover").
@export var hover: bool = false
## The pictures look right (enemies.json "faces_right"): the battle stage mirrors them, so the monster
## looks left at the heroes like all others (and right as a summon).
@export var faces_right: bool = false
## Effect of its basic hits on the target (enemies.json "attack_vfx", e.g. "claw" for animals);
## empty = from the pose (BattleStage._get_vfx).
@export var attack_vfx: String = ""
## Colour the sprite is multiplied with (white = unchanged), e.g. to tell a boss from its kin.
@export var tint: Color = Color.WHITE

@export_group("Values")
## Health is rolled between min and max for every spawned enemy.
@export var health_min: int = 7
@export var health_max: int = 10
@export var mana: int = 0
## Damage per basic hit (min..max).
@export var damage_min: int = 2
@export var damage_max: int = 2
## Seconds between two basic hits (attack speed: agility makes it shorter).
@export var attack_interval: float = 1.0
@export var armor: int = 0
## Reduces all magic damage (elements and pure magic), same formula as armor.
@export var magic_resistance: int = 0
## ItemAttribute.Type -> value.
@export var attributes: Dictionary = {}
## Kinds its basic hits are made of: DamageKinds id -> share (default 100 % physical).
@export var damage_split: Dictionary = {"physical": 1.0}
## Added to its magic skills.
@export var magic_damage_min: int = 0
@export var magic_damage_max: int = 0
## DamageKinds id -> value (negative = weakness), e.g. {"fire": -20, "slash": 10}.
@export var resistances: Dictionary = {}
## Extra crit chance (0.05 = +5 %).
@export var crit_chance: float = 0.0
@export var health_regen: float = 0.0
@export var mana_regen: float = 0.0
## Used automatically in fights like hero skills.
@export var skills: Array[SkillData] = []
## Status effects its basic hits can put on the target: [{"effect": StatusEffectData, "chance": 0..1}]
## (enemies.json "on_hit", e.g. the poison rat: poison 30 %).
@export var on_hit: Array[Dictionary] = []
## Stands in the back row (e.g. archers): single-target attacks can only reach it once no enemy
## of the front row is alive any more (area skills always reach it).
@export var back_row: bool = false
## Calls helpers when it loses health (enemies.json "summon"): {"every": 0.25 (share of max
## health), "count": 2 per call, "pool": [EnemyData]} -> at 75 %, 50 % and 25 % health 2 helpers.
@export var summon: Dictionary = {}
## Hides behind its allies (enemies.json "shroud": status effect id, e.g. "shrouded"): while any
## other monster of its side lives, it carries that effect (untargetable, takes no damage, also
## not from area attacks); alone it loses it (Adventure._update_shrouds).
@export var shroud_effect_id: String = ""
## Splits instead of dying (enemies.json "split"): {"below": 0.25 (share of max health), "count": 2,
## "share": 0.5 (health and damage of each part), "size": 0.75 (picture), "times": 2 (how often in a
## row)}. The splitting monster counts as defeated (EXP, drops). Empty = doesn't split.
@export var split: Dictionary = {}
## Grows back while another monster of its group lives (enemies.json "regrow", e.g. the three heads of
## the hydra): {"group": "hydra", "seconds": 30.0, "health": [0.5, 0.25] (share of max health for the
## 1st, 2nd ... time, the last one repeats), "text": shout}. Killed, it waits `seconds`; if every
## monster of the group is down by then, they all stay down, else it comes back. Loot and EXP
## only once the whole group is down (Adventure._regrow). Empty = doesn't grow back.
@export var regrow: Dictionary = {}
## Monsters with the same body (enemies.json "body", e.g. "hydra" for the three heads) are drawn in the
## battle window as one picture with one health bar per monster stacked above it; each still is its
## own fighter (health, attacks, target). Empty = its own picture.
@export var body: String = ""
## Short name on its bar when it shares a body (enemies.json "body_label", e.g. "Biss").
@export var body_label: String = ""
## What it shouts when it calls helpers (summon or a skill with summon_enemies).
@export var summon_shout: String = "Zu mir, Jungs!"
## Damage kinds that heal it instead of hurting it: DamageKinds id -> share (1.0 = all of it),
## e.g. {"fire": 1.0} for the lava golem (enemies.json "absorb").
@export var absorb: Dictionary = {}
## More health bars of a boss (enemies.json "phases"): when the health of one runs out, the next
## phase begins with full health and its own values. Each entry: {"name", "text" (shout),
## "hp_min", "hp_max", and optional "damage_min"/"damage_max", "magic_min"/"magic_max",
## "attack_interval", "armor", "magic_resistance", "hp_regen", "scale", "skills" [SkillData]}.
@export var phases: Array[Dictionary] = []
## EXP every living hero gets for a kill (before the level factor, CombatRules.kill_experience).
@export var experience: int = 0
## Loot: {"item": ItemData, "spec": "" or a composed item ("sword:copper_blade+copper_handle"),
## "chance": 0..1, "min": int, "max": int, "rarities": [[Rarity.Tier, chance], ...] (highest
## first; otherwise the item's own rarity)}. Rolled when it dies.
@export var drops: Array[Dictionary] = []


## Rolls the loot of one kill: a stack per drop that happened (item, amount, rarity).
## `chance_factor` raises every chance (combat.json "dungeon_loot"); `default_rarities`
## ([[tier, chance], ...]) are rolled for materials, ore and ingots that their own rarity chances
## left at the base rarity (so every one of them has at least that chance). `rarity_factor` raises
## every rarity chance (luck of the party, Adventure.loot_luck).
func roll_drops(chance_factor: float = 1.0, default_rarities: Array = [], rarity_factor: float = 1.0) -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for drop in drops:
		if randf() >= minf(drop["chance"] * chance_factor, 1.0):
			continue
		var stack := InventorySlot.new()
		if not str(drop.get("spec", "")).is_empty():
			# A whole weapon (with its parts), e.g. the sword of a bandit.
			stack = ContentDB.make_stack(drop["spec"])
		else:
			stack.item = drop["item"]
		stack.amount = randi_range(drop["min"], drop["max"])
		stack.rarity = stack.item.base_rarity
		var tables: Array = [drop.get("rarities", [])]
		if stack.item.purse_gold.is_empty() \
				and stack.item.type in [ItemData.ItemType.MATERIAL, ItemData.ItemType.ORE, ItemData.ItemType.INGOT]:
			tables.append(default_rarities)
		for rarities: Array in tables:
			if stack.rarity != stack.item.base_rarity:
				break
			for entry: Array in rarities:
				if randf() < entry[1] * rarity_factor:
					stack.rarity = entry[0]
					break
		if stack.amount > 0:
			result.append(stack)
	return result


## One frame of the sprite sheet (0 = first).
func get_frame(index: int) -> Texture2D:
	return _cut_frame(sprite_sheet, index % maxi(1, frame_count))


## Frame of the looping "walk" animation (coming into the fight), null without one.
func get_walk_frame(seconds: float) -> Texture2D:
	var animation: Dictionary = animations.get("walk", {})
	if animation.is_empty():
		return null
	return _cut_frame(animation["sheet"], int(seconds * animation["fps"]) % maxi(1, animation["frames"]),
			animation.get("frame_size", frame_size))


## Frame of animation `key` `seconds` after it started; null without such an animation or once it
## is over ("death" stays on its last frame).
func get_animation_frame(key: String, seconds: float) -> Texture2D:
	var animation: Dictionary = animations.get(key, {})
	if animation.is_empty():
		return null
	var count: int = maxi(1, animation["frames"])
	var frame: int = int(seconds * animation["fps"])
	if frame >= count:
		if key != "death":
			return null
		frame = count - 1
	return _cut_frame(animation["sheet"], frame, animation.get("frame_size", frame_size))


func _cut_frame(sheet: Texture2D, frame: int, size: Vector2i = frame_size) -> Texture2D:
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var columns: int = maxi(1, sheet.get_width() / size.x)
	atlas.region = Rect2(Vector2((frame % columns) * size.x, (frame / columns) * size.y), size)
	return atlas
