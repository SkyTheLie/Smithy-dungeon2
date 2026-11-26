class_name Lexicon
extends RefCounted
## The lexicon (key L, LexiconWindow): every monster and item of the game, but only the ones the
## player discovered show their entry. Undiscovered ones are listed as a dark silhouette.
##   Monster: discovered once beaten at least once (counter "kill:<id>" of the achievements, so
##            saves from before the lexicon already know their monsters).
##   Item:    discovered once it lay in the inventory, a chest or the loot chest (note_inventory);
##            a composed item (sword ...) also discovers its parts.
## Links in texts: a RichTextLabel with bbcode shows "[url=enemy:rat]Ratte[/url]" as a link
## (enemy_link, item_link, or {enemy:rat} / {item:copper_ore} in a text through format_links);
## connect_links makes a click open the entry (GameState.open_lexicon). Not yet discovered: the
## lexicon opens at its silhouette and shakes it.

signal changed

## Link prefixes ("enemy:rat", "item:copper_ore").
const ENEMY: String = "enemy"
const ITEM: String = "item"
## Pages that are always open (no discovering): status effects (EffectInfo) and skills.
const EFFECT: String = "effect"
const SKILL: String = "skill"
const COLOR_SKILL_LINK: Color = Color(0.85, 0.75, 1.0)
## Colour of monster and item links in texts.
const COLOR_ENEMY_LINK: Color = Color(1.0, 0.62, 0.4)
const COLOR_ITEM_LINK: Color = Color(0.55, 0.8, 1.0)
## Items that never show up in the lexicon: glowing blanks (between forge and anvil) and admin things.
const HIDDEN_PREFIXES: Array[String] = ["hot_", "admin_"]

## Item id -> true for every item the player had.
var seen_items: Dictionary = {}
## Reads "kill:<id>" (set by GameState: Achievements.get_value).
var kill_count: Callable = func(_counter: String) -> int: return 0

static var _enemy_list: Array[EnemyData] = []
static var _item_list: Array[ItemData] = []


# --- Discovering ------------------------------------------------------------------------

## Notes every item in `inventory` (and the parts of composed items) as seen.
func note_inventory(inventory: Inventory) -> void:
	for slot: InventorySlot in inventory.slots:
		note_stack(slot)


func note_stack(slot: InventorySlot) -> void:
	if slot == null or slot.is_empty():
		return
	var added: bool = _note_item(slot.item)
	for part: ItemData in slot.components:
		added = _note_item(part) or added
	if slot.jewel_crystal:
		added = _note_item(slot.jewel_crystal) or added
	for arrows: InventorySlot in slot.contents:
		if not arrows.is_empty():
			added = _note_item(arrows.item) or added
	if added:
		changed.emit()


func _note_item(item: ItemData) -> bool:
	if item == null or seen_items.has(String(item.id)):
		return false
	seen_items[String(item.id)] = true
	return true


func is_item_known(item: ItemData) -> bool:
	return item != null and seen_items.has(String(item.id))


func is_enemy_known(enemy: EnemyData) -> bool:
	return enemy != null and kill_count.call("kill:" + String(enemy.id)) > 0


func get_kills(enemy: EnemyData) -> int:
	return int(kill_count.call("kill:" + String(enemy.id)))


## Percent (rounded down) of the lexicon's monsters discovered: 100 only when every one is
## (achievement counter "lexicon:enemies").
func get_enemy_percent() -> int:
	var all: Array[EnemyData] = get_enemies()
	var known: int = 0
	for enemy: EnemyData in all:
		if is_enemy_known(enemy):
			known += 1
	return floori(100.0 * known / maxf(all.size(), 1))


## Percent (rounded down) of the lexicon's items discovered (achievement counter "lexicon:items").
func get_item_percent() -> int:
	var all: Array[ItemData] = get_items()
	var known: int = 0
	for item: ItemData in all:
		if seen_items.has(String(item.id)):
			known += 1
	return floori(100.0 * known / maxf(all.size(), 1))


func to_save_data() -> Dictionary:
	return {"items": seen_items.keys()}


func load_save_data(data: Dictionary) -> void:
	seen_items.clear()
	for id: Variant in data.get("items", []):
		seen_items[str(id)] = true
	changed.emit()


# --- What the lexicon lists ---------------------------------------------------------------

## Every monster the heroes can meet: those of the dungeons and the helpers they call (boss
## summons, summoning skills). Lowest level first, then by name.
static func get_enemies() -> Array[EnemyData]:
	_check_generation()
	if not _enemy_list.is_empty():
		return _enemy_list
	var found: Array[EnemyData] = []
	for dungeon: DungeonData in ContentDB.get_all_dungeons():
		for enemy: EnemyData in dungeon.get_enemies():
			if not found.has(enemy):
				found.append(enemy)
	# Helpers called by the found monsters, and their helpers in turn.
	var index: int = 0
	while index < found.size():
		var enemy: EnemyData = found[index]
		var helpers: Array = enemy.summon.get("pool", []).duplicate()
		for skill: SkillData in enemy.skills:
			for helper_id: String in skill.summon_enemy_ids:
				helpers.append(ContentDB.enemy(helper_id))
		for phase: Dictionary in enemy.phases:
			for skill: SkillData in phase.get("skills", []):
				for helper_id: String in skill.summon_enemy_ids:
					helpers.append(ContentDB.enemy(helper_id))
		for helper: EnemyData in helpers:
			if helper and not found.has(helper):
				found.append(helper)
		index += 1
	found.sort_custom(func(a: EnemyData, b: EnemyData) -> bool:
		return [a.level, a.display_name] < [b.level, b.display_name])
	_enemy_list = found
	return _enemy_list


## Every item that can be found or made (no glowing blanks, no admin things), ordered by group,
## material tier and name (see get_item_group).
static func get_items() -> Array[ItemData]:
	_check_generation()
	if not _item_list.is_empty():
		return _item_list
	for item: ItemData in ContentDB.get_all_items():
		if not is_listed(item):
			continue
		_item_list.append(item)
	_item_list.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return [get_item_group_index(a), a.material_tier, a.display_name] < [get_item_group_index(b), b.material_tier, b.display_name])
	return _item_list


static func is_listed(item: ItemData) -> bool:
	if item == null:
		return false
	for prefix: String in HIDDEN_PREFIXES:
		if String(item.id).begins_with(prefix):
			return false
	return true


# --- Item groups -----------------------------------------------------------------------------
## Each item is in one group (a block with a header in the item tab). Group keys are the German
## names (translated for the screen), except the weapon groups: "weapon:<weapon type id>", named
## and ordered like weapon_types.json. items.json "lexicon": "<group>" puts an item into a fixed
## group by hand (only GROUPS_BEFORE / GROUPS_AFTER: the nine holy crystals, quest items no rule
## finds).

const GROUP_RAW: String = "Rohstoffe"
const GROUP_INGOTS: String = "Barren"
const GROUP_HIDES: String = "Felle & Leder"
const GROUP_LOOT: String = "Monsterbeute"
const GROUP_CRYSTALS: String = "Kristalle"
const GROUP_HOLY: String = "Die neun Kristalle"
const GROUP_GARDEN: String = "Garten"
const GROUP_POTIONS: String = "Tränke"
const GROUP_ARROWS: String = "Pfeile & Köcher"
const GROUP_JEWELRY: String = "Schmuck"
const GROUP_TOOLS: String = "Werkzeug"
const GROUP_PARTS: String = "Teile"
const GROUP_QUEST: String = "Quest-Items"
const GROUP_OTHER: String = "Sonstiges"
const WEAPON_GROUP: String = "weapon:"
## Armour pieces: one group per slot, in this order.
const ARMOR_GROUPS: Dictionary = {
	ItemData.ItemType.HELMET: "Helme",
	ItemData.ItemType.SHOULDERS: "Schultern",
	ItemData.ItemType.ARMOR: "Brustpanzer",
	ItemData.ItemType.LEGS: "Beinschutz",
	ItemData.ItemType.GLOVES: "Handschuhe",
	ItemData.ItemType.BOOTS: "Stiefel",
	ItemData.ItemType.CLOAK: "Umhänge",
}
## Groups before the weapons and after the armour, in this order.
const GROUPS_BEFORE: Array[String] = [GROUP_RAW, GROUP_INGOTS, GROUP_HIDES, GROUP_LOOT, GROUP_CRYSTALS,
		GROUP_HOLY, GROUP_GARDEN, GROUP_POTIONS]
const GROUPS_AFTER: Array[String] = [GROUP_JEWELRY, GROUP_TOOLS, GROUP_PARTS, GROUP_QUEST, GROUP_OTHER]
## Big headers above several groups: "Waffen" over the weapon groups and arrows, "Rüstung" over
## the armour slots.
const SECTION_WEAPONS: String = "Waffen"
const SECTION_ARMOR: String = "Rüstung"

## Content caches (cleared when ContentDB reloads, see _check_generation).
static var _cache_generation: int = -1
## Items some listed monster drops (see is_monster_drop).
static var _dropped: Dictionary = {}
## Every group key in screen order.
static var _group_order: Array[String] = []
## Part type -> the one group whose items are built from it ("" = several groups: "Teile").
static var _part_groups: Dictionary = {}
## Items grown from a seed.
static var _grown: Dictionary = {}
## Item -> its group.
static var _item_groups: Dictionary = {}


## Drops every content cache once ContentDB loaded its files again (e.g. a new language).
static func _check_generation() -> void:
	if _cache_generation == ContentDB.generation:
		return
	_cache_generation = ContentDB.generation
	_enemy_list.clear()
	_item_list.clear()
	_dropped.clear()
	_group_order.clear()
	_part_groups.clear()
	_grown.clear()
	_item_groups.clear()
	_enemy_icons.clear()


## Every group key in the order of the item tab.
static func get_group_order() -> Array[String]:
	_check_generation()
	if _group_order.is_empty():
		_group_order.append_array(GROUPS_BEFORE)
		for weapon_type: WeaponType in ContentDB.get_all_weapon_types():
			_group_order.append(WEAPON_GROUP + String(weapon_type.id))
		_group_order.append(GROUP_ARROWS)
		for group: String in ARMOR_GROUPS.values():
			_group_order.append(group)
		_group_order.append_array(GROUPS_AFTER)
	return _group_order


## The group of `item` (key, see get_group_name for the text).
static func get_item_group(item: ItemData) -> String:
	_check_generation()
	if not _item_groups.has(item):
		_item_groups[item] = _find_group(item)
	return _item_groups[item]


static func get_item_group_index(item: ItemData) -> int:
	return get_group_order().find(get_item_group(item))


## Shown name of a group key.
static func get_group_name(group: String) -> String:
	if group.begins_with(WEAPON_GROUP):
		var id: String = group.trim_prefix(WEAPON_GROUP)
		return ContentDB.weapon_type(id).display_name
	return Language.translate(group)


## Big header above the group ("" = none): "Waffen" or "Rüstung", untranslated.
static func get_group_section(group: String) -> String:
	if group.begins_with(WEAPON_GROUP) or group == GROUP_ARROWS:
		return SECTION_WEAPONS
	if ARMOR_GROUPS.values().has(group):
		return SECTION_ARMOR
	return ""


## Shown name of the item's group (the "kind" on its page and in its tooltip).
static func get_item_category(item: ItemData) -> String:
	return get_group_name(get_item_group(item))


static func _find_group(item: ItemData) -> String:
	if not item.lexicon_group.is_empty():
		return item.lexicon_group
	if _is_quest_item(item):
		return GROUP_QUEST
	# Furs and hides (for the tanning rack) and the leather made from them.
	if item.tan_result or item.part_type == ItemData.PartType.LEATHER:
		return GROUP_HIDES
	# Raw crystals (jewellery, potions), their cut gems, and dusts are with what they come from.
	if not item.jewel_effects.is_empty() or item.grind_result or item.part_type == ItemData.PartType.GEM:
		return GROUP_CRYSTALS
	var dust: DustData = ContentDB.dust_of_item(item)
	if dust:
		return get_item_group(dust.source)
	if ContentDB.potion_of_item(item) or ContentDB.brew_of_item(item) or not item.hero_potion.is_empty() \
			or item == ContentDB.mortar_item("vial") or item == ContentDB.mortar_item("failed"):
		return GROUP_POTIONS
	if item.grows_into or item.is_soil or _is_grown(item) or ContentDB.get_potion_plants().has(item):
		return GROUP_GARDEN
	if item.weapon_type:
		return WEAPON_GROUP + String(item.weapon_type.id)
	if ARMOR_GROUPS.has(item.type):
		return ARMOR_GROUPS[item.type]
	match item.type:
		ItemData.ItemType.ORE, ItemData.ItemType.FUEL:
			return GROUP_RAW
		ItemData.ItemType.INGOT:
			return GROUP_INGOTS
		ItemData.ItemType.PART:
			return _get_part_group(item.part_type)
		ItemData.ItemType.ARROWS, ItemData.ItemType.QUIVER:
			return GROUP_ARROWS
		ItemData.ItemType.RING, ItemData.ItemType.NECKLACE, ItemData.ItemType.ACCESSORY:
			return GROUP_JEWELRY
		ItemData.ItemType.PICKAXE, ItemData.ItemType.LUMBER_AXE, ItemData.ItemType.WATERING_CAN, \
				ItemData.ItemType.BACKPACK, ItemData.ItemType.SHOES:
			return GROUP_TOOLS
		ItemData.ItemType.MATERIAL:
			if item.smelt_result:
				return GROUP_RAW
			# Fangs, venom, essences ... that monsters drop or dungeons give.
			if is_monster_drop(item) or not get_reward_dungeons(item).is_empty():
				return GROUP_LOOT
	return GROUP_OTHER


## Story things: marked in items.json (story_item, quest_part, mold_shape) or forged on the anvil
## without being a part, weapon or armour (seals, the lightning rod, the true setting ...).
static func _is_quest_item(item: ItemData) -> bool:
	if item.story_item or item.quest_part or not item.mold_shape.is_empty():
		return true
	if item.type != ItemData.ItemType.MATERIAL:
		return false
	var recipe: RecipeData = ContentDB.get_recipe_making(String(item.id))
	return recipe != null and recipe.station == &"anvil"


static func _is_grown(item: ItemData) -> bool:
	if _grown.is_empty():
		for other: ItemData in ContentDB.get_all_items():
			if other.grows_into:
				_grown[other.grows_into] = true
	return _grown.has(item)


## Group of a part: the weapon, armour, jewellery or tool group built from it, when that is only
## one group (a blade: swords); parts of several groups (handles, shafts) are "Teile".
static func _get_part_group(part_type: ItemData.PartType) -> String:
	if _part_groups.is_empty():
		var found: Dictionary = {}
		for recipe: RecipeData in ContentDB.get_all_recipes():
			if recipe.result == null or recipe.result.type == ItemData.ItemType.PART:
				continue
			var group: String = get_item_group(recipe.result)
			if group in [GROUP_PARTS, GROUP_QUEST, GROUP_OTHER]:
				continue
			for ingredient: Ingredient in recipe.ingredients:
				var used: ItemData.PartType = ingredient.part_type
				if used == ItemData.PartType.NONE and ingredient.item:
					used = ingredient.item.part_type
				if used == ItemData.PartType.NONE:
					continue
				if not found.has(used):
					found[used] = {}
				found[used][group] = true
		for used: ItemData.PartType in found:
			var groups: Array = found[used].keys()
			_part_groups[used] = groups[0] if groups.size() == 1 else ""
		# Filled, even when no recipe uses a part.
		_part_groups[ItemData.PartType.NONE] = ""
	var group: String = _part_groups.get(part_type, "")
	return group if not group.is_empty() else GROUP_PARTS


## True when a monster of the lexicon drops `item`.
static func is_monster_drop(item: ItemData) -> bool:
	if _dropped.is_empty():
		for enemy: EnemyData in get_enemies():
			for drop: Dictionary in enemy.drops:
				if drop["item"]:
					_dropped[drop["item"]] = true
	return _dropped.has(item) or ContentDB.is_rare_drop(item)


## Monsters that drop `item` (only from the lexicon's list).
static func get_droppers(item: ItemData) -> Array[EnemyData]:
	var list: Array[EnemyData] = []
	for enemy: EnemyData in get_enemies():
		for drop: Dictionary in enemy.drops:
			if drop["item"] == item:
				list.append(enemy)
				break
	return list


## Dungeons that give `item` as a reward (or as the boss ingot).
static func get_reward_dungeons(item: ItemData) -> Array[DungeonData]:
	var list: Array[DungeonData] = []
	for dungeon: DungeonData in ContentDB.get_all_dungeons():
		if dungeon.boss_ingot == item or dungeon.reward_items.any(func(entry: Dictionary) -> bool: return entry["item"] == item) 				or ContentDB.rare_drops().any(func(rule: RareDropRule) -> bool: return rule.item == item and rule.covers(dungeon)):
			list.append(dungeon)
	return list


## Dungeons where `enemy` lives.
static func get_dungeons_of(enemy: EnemyData) -> Array[DungeonData]:
	var list: Array[DungeonData] = []
	for dungeon: DungeonData in ContentDB.get_all_dungeons():
		if dungeon.get_enemies().has(enemy):
			list.append(dungeon)
	return list


## Picture of a monster for slots and links: its first frame, cut to the drawn pixels so it fills
## a small slot (null without a picture).
static func get_enemy_icon(enemy: EnemyData) -> Texture2D:
	_check_generation()
	if _enemy_icons.has(enemy):
		return _enemy_icons[enemy]
	var frame: Texture2D = enemy.get_frame(0)
	var icon: Texture2D = frame
	var atlas := frame as AtlasTexture
	if atlas:
		var image: Image = atlas.get_image()
		if image:
			if image.is_compressed():
				image.decompress()
			var used: Rect2i = image.get_used_rect()
			if used.has_area():
				var trimmed := AtlasTexture.new()
				trimmed.atlas = atlas.atlas
				trimmed.region = Rect2(atlas.region.position + Vector2(used.position), Vector2(used.size))
				icon = trimmed
	_enemy_icons[enemy] = icon
	return icon


## Monster -> its trimmed picture (get_enemy_icon).
static var _enemy_icons: Dictionary = {}


# --- Links in texts ------------------------------------------------------------------------

static func enemy_link(enemy: EnemyData, text: String = "") -> String:
	return "[url=%s:%s][color=#%s]%s[/color][/url]" % [ENEMY, enemy.id, COLOR_ENEMY_LINK.to_html(false),
			text if not text.is_empty() else enemy.display_name]


static func item_link(item: ItemData, text: String = "") -> String:
	return "[url=%s:%s][color=#%s]%s[/color][/url]" % [ITEM, item.id, COLOR_ITEM_LINK.to_html(false),
			text if not text.is_empty() else item.display_name]


static func skill_link(skill: SkillData, text: String = "") -> String:
	return "[url=%s:%s][color=#%s]%s[/color][/url]" % [SKILL, skill.id, COLOR_SKILL_LINK.to_html(false),
			text if not text.is_empty() else skill.display_name]


## Turns {enemy:rat} and {item:copper_ore} in a text into links with the name ({enemy:rat|Ratten}
## with an own text). Unknown ids stay as they are.
static func format_links(text: String) -> String:
	if not "{" in text:
		return text
	var regex := RegEx.create_from_string("\\{(enemy|item):([a-z0-9_]+)(?:\\|([^}]*))?\\}")
	var result: String = text
	for found: RegExMatch in regex.search_all(text):
		var kind: String = found.get_string(1)
		var id: String = found.get_string(2)
		var own_text: String = found.get_string(3)
		var link: String = ""
		if kind == ENEMY and ContentDB.has_enemy(id):
			link = enemy_link(ContentDB.enemy(id), own_text)
		elif kind == ITEM and ContentDB.has_item(id):
			link = item_link(ContentDB.item(id), own_text)
		if not link.is_empty():
			result = result.replace(found.get_string(), link)
	return result


## A click on a link in `label` opens its lexicon entry; the mouse shows a hand over links.
static func connect_links(label: RichTextLabel) -> void:
	label.meta_underlined = true
	# GameState through the tree: a direct reference would keep this class (used by ContentDB) from
	# compiling in headless scripts, which do not know the autoloads yet.
	label.meta_clicked.connect(func(meta: Variant) -> void:
		(Engine.get_main_loop() as SceneTree).root.get_node("GameState").open_lexicon(str(meta)))
	label.meta_hover_started.connect(func(_meta: Variant) -> void:
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND)
	label.meta_hover_ended.connect(func(_meta: Variant) -> void:
		label.mouse_default_cursor_shape = Control.CURSOR_ARROW)
