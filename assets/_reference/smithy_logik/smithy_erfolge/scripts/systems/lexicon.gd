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


## Every item that can be found or made (no glowing blanks, no admin things), ordered by kind,
## material tier and name (see get_item_category).
static func get_items() -> Array[ItemData]:
	if not _item_list.is_empty():
		return _item_list
	for item: ItemData in ContentDB.get_all_items():
		if not is_listed(item):
			continue
		_item_list.append(item)
	_item_list.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return [get_item_category_index(a), a.material_tier, a.display_name] < [get_item_category_index(b), b.material_tier, b.display_name])
	return _item_list


static func is_listed(item: ItemData) -> bool:
	if item == null:
		return false
	for prefix: String in HIDDEN_PREFIXES:
		if String(item.id).begins_with(prefix):
			return false
	return true


## Groups of the item tab, in this order (indexes: the CATEGORY_ constants).
const ITEM_CATEGORIES: Array[String] = ["Rohstoffe", "Felle & Leder", "Monsterbeute", "Barren", "Teile",
		"Waffen", "Rüstung", "Schmuck", "Werkzeug", "Sonstiges"]
const CATEGORY_RAW: int = 0
const CATEGORY_HIDES: int = 1
const CATEGORY_LOOT: int = 2
const CATEGORY_INGOTS: int = 3
const CATEGORY_PARTS: int = 4
const CATEGORY_WEAPONS: int = 5
const CATEGORY_ARMOR: int = 6
const CATEGORY_JEWELRY: int = 7
const CATEGORY_TOOLS: int = 8
const CATEGORY_OTHER: int = 9

## Items some listed monster drops (filled once, see is_monster_drop).
static var _dropped: Dictionary = {}


static func get_item_category_index(item: ItemData) -> int:
	# Furs and hides (for the tanning rack) and the leather made from them.
	if item.tan_result or item.part_type == ItemData.PartType.LEATHER:
		return CATEGORY_HIDES
	match item.type:
		ItemData.ItemType.ORE, ItemData.ItemType.FUEL:
			return CATEGORY_RAW
		ItemData.ItemType.INGOT:
			return CATEGORY_INGOTS
		ItemData.ItemType.PART:
			return CATEGORY_PARTS
		ItemData.ItemType.WEAPON, ItemData.ItemType.ARROWS, ItemData.ItemType.QUIVER:
			return CATEGORY_WEAPONS
		ItemData.ItemType.ARMOR, ItemData.ItemType.HELMET, ItemData.ItemType.BOOTS, ItemData.ItemType.SHOULDERS, \
				ItemData.ItemType.CLOAK, ItemData.ItemType.LEGS, ItemData.ItemType.SHIELD, ItemData.ItemType.GLOVES, \
				ItemData.ItemType.SHOES:
			return CATEGORY_ARMOR
		ItemData.ItemType.RING, ItemData.ItemType.NECKLACE, ItemData.ItemType.ACCESSORY:
			return CATEGORY_JEWELRY
		ItemData.ItemType.PICKAXE, ItemData.ItemType.LUMBER_AXE, ItemData.ItemType.WATERING_CAN, \
				ItemData.ItemType.BACKPACK:
			return CATEGORY_TOOLS
		ItemData.ItemType.MATERIAL:
			if item.smelt_result:
				return CATEGORY_RAW
			# Fangs, venom, feathers ... that monsters drop.
			if is_monster_drop(item):
				return CATEGORY_LOOT
	return CATEGORY_OTHER


## True when a monster of the lexicon drops `item`.
static func is_monster_drop(item: ItemData) -> bool:
	if _dropped.is_empty():
		for enemy: EnemyData in get_enemies():
			for drop: Dictionary in enemy.drops:
				if drop["item"]:
					_dropped[drop["item"]] = true
	return _dropped.has(item) or ContentDB.is_rare_drop(item)


static func get_item_category(item: ItemData) -> String:
	return Language.translate(ITEM_CATEGORIES[get_item_category_index(item)])


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
	label.meta_clicked.connect(func(meta: Variant) -> void: GameState.open_lexicon(str(meta)))
	label.meta_hover_started.connect(func(_meta: Variant) -> void:
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND)
	label.meta_hover_ended.connect(func(_meta: Variant) -> void:
		label.mouse_default_cursor_shape = Control.CURSOR_ARROW)
