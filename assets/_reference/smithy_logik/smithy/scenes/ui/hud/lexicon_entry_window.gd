class_name LexiconEntryWindow
extends PanelContainer
## One page of the lexicon (opened by a link or a slot of the LexiconWindow, GameState.open_lexicon).
## Monster: left its animations in a loop (MonsterPreview: stand, walk, attack, walk, die), right
## name, level, EXP, health, mana, damage, skills with icons (hover = description), strengths and
## weaknesses, loot (links to the items) and where it lives.
## Item: left its picture, right its tooltip text, which monsters drop it (links) and which
## dungeons give it. "« Zurück" goes to the page before (links lead from page to page).
## Status effect ("effect:<id>"): what it does (EffectInfo) and which skills / monsters cause it.
## Skill ("skill:<id>", e.g. a monster's ability): its values, its effects (links) and who uses it.

const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_HEADER: Color = Color(0.95, 0.8, 0.45)
const COLOR_STAT: Color = Color(0.92, 0.9, 0.82)
const COLOR_GOOD: Color = Color(0.55, 0.85, 0.45)
const COLOR_BAD: Color = Color(1.0, 0.5, 0.4)
const COLOR_EXPERIENCE: Color = Color(0.55, 0.75, 1)
const COLOR_SILHOUETTE: Color = Color(0.0, 0.0, 0.0, 0.8)
const ICON_SIZE: int = 12
## Meta of skill names (hover shows the description, a click opens the skill's page).
const SKILL: String = "skill"
const PICTURE_SIZE: Vector2 = Vector2(48, 48)
## Most pages kept for "« Zurück".
const MAX_HISTORY: int = 20

@onready var _back_button: Button = %BackButton
@onready var _preview: MonsterPreview = %Preview
@onready var _item_picture: TextureRect = %ItemPicture
@onready var _phase_label: Label = %PhaseLabel
@onready var _text: RichTextLabel = %Text
@onready var _title_bar: WindowTitleBar = $VBox/TitleBar

## Shown page ("enemy:rat") and the ones before it.
var _link: String = ""
var _history: Array[String] = []


func _ready() -> void:
	_back_button.text = Language.translate("« Zurück")
	_back_button.pressed.connect(_go_back)
	_preview.phase_changed.connect(func(text: String) -> void: _phase_label.text = text)
	_text.meta_underlined = true
	_text.meta_clicked.connect(_on_meta_clicked)
	_text.meta_hover_started.connect(_on_meta_hover_started)
	_text.meta_hover_ended.connect(func(_meta: Variant) -> void:
		_text.mouse_default_cursor_shape = Control.CURSOR_ARROW)
	visibility_changed.connect(func() -> void:
		if not visible:
			_history.clear()
			_link = "")


## Shows the page of `link` ("enemy:<id>" / "item:<id>"); the page before goes into the history.
func show_link(link: String) -> void:
	if not _link.is_empty() and _link != link and visible:
		_history.append(_link)
		if _history.size() > MAX_HISTORY:
			_history.pop_front()
	_show(link)
	show()
	_title_bar.bring_to_front()


func _go_back() -> void:
	if _history.is_empty():
		return
	_show(_history.pop_back())


func _show(link: String) -> void:
	_link = link
	_back_button.disabled = _history.is_empty()
	_text.clear()
	var kind: String = link.get_slice(":", 0)
	var id: String = link.get_slice(":", 1)
	if kind == Lexicon.ENEMY and ContentDB.has_enemy(id):
		_show_enemy(ContentDB.enemy(id))
	elif kind == Lexicon.ITEM and ContentDB.has_item(id):
		_show_item(ContentDB.item(id))
	elif kind == Lexicon.EFFECT and ContentDB.has_status_effect(id):
		_show_effect(ContentDB.status_effect(id))
	elif kind == Lexicon.SKILL and ContentDB.find_skill(id) != null:
		_show_skill(ContentDB.find_skill(id))
	(get_node("VBox/Columns/Scroll") as ScrollContainer).scroll_vertical = 0


# --- Monster ----------------------------------------------------------------------------

func _show_enemy(enemy: EnemyData) -> void:
	_title_bar.title = Language.translate("Bestiarium")
	_preview.show()
	_item_picture.hide()
	_phase_label.show()
	_preview.show_enemy(enemy)
	_add_text("[b]%s[/b]\n" % enemy.display_name, COLOR_HEADER)
	_add_text(Language.translate("Lv %d · %d× besiegt\n") % [enemy.level, GameState.lexicon.get_kills(enemy)], COLOR_HINT)
	_add_text(Language.translate("EXP: %d je Held\n") % enemy.experience, COLOR_EXPERIENCE)
	var health: String = _range(enemy.health_min, enemy.health_max)
	if not enemy.phases.is_empty():
		health += Language.translate(" (%d Lebensbalken)") % (enemy.phases.size() + 1)
	_add_text(Language.translate("Leben: %s · Mana: %d\n") % [health, enemy.mana], COLOR_STAT)
	var damage: String = Language.translate("Schaden: %s") % _range(enemy.damage_min, enemy.damage_max)
	var split: Dictionary = DamageKinds.normalized(enemy.damage_split)
	if split.size() > 1 or not split.has(DamageKinds.PHYSICAL):
		damage += " (%s)" % ", ".join(split.keys().map(DamageKinds.get_display_name))
	damage += Language.translate(" · alle %s s") % _number(enemy.attack_interval)
	_add_text(damage + "\n", COLOR_STAT)
	if enemy.magic_damage_max > 0:
		_add_text(Language.translate("Magieschaden: %s\n") % _range(enemy.magic_damage_min, enemy.magic_damage_max), COLOR_STAT)
	_add_text(Language.translate("Rüstung: %d · Magieresistenz: %d\n") % [enemy.armor, enemy.magic_resistance], COLOR_STAT)
	_add_skills(enemy)
	_add_enemy_effects(enemy)
	_add_strengths(enemy)
	_add_traits(enemy)
	_add_drops(enemy)
	var places: Array = Lexicon.get_dungeons_of(enemy).map(func(dungeon: DungeonData) -> String: return dungeon.display_name)
	if not places.is_empty():
		_add_heading(Language.translate("Vorkommen"))
		_add_text(", ".join(places) + "\n", COLOR_HINT)


func _add_skills(enemy: EnemyData) -> void:
	var skills: Array[SkillData] = EffectInfo.get_enemy_skills(enemy)
	if skills.is_empty():
		return
	_add_heading(Language.translate("Fähigkeiten"))
	for skill in skills:
		if skill.icon:
			_text.add_image(skill.icon, ICON_SIZE, ICON_SIZE)
			_text.add_text(" ")
		_text.push_meta("%s:%s" % [SKILL, skill.id], RichTextLabel.META_UNDERLINE_ON_HOVER, skill.description)
		_add_text(skill.display_name, COLOR_STAT)
		_text.pop()
		_text.add_text("\n")


## Every status effect the monster can cause (with its hits or skills), as links to their pages.
func _add_enemy_effects(enemy: EnemyData) -> void:
	var effects: Array[StatusEffectData] = EffectInfo.get_effects_of_enemy(enemy)
	if effects.is_empty():
		return
	_add_heading(Language.translate("Statuseffekte"))
	for effect in effects:
		_add_effect_line(effect)


## Icon, name (link) and "Stärkung" / "Schwächung".
func _add_effect_line(effect: StatusEffectData, extra: String = "") -> void:
	if effect.icon:
		_text.add_image(effect.icon, ICON_SIZE, ICON_SIZE)
		_text.add_text(" ")
	_text.append_text(EffectInfo.link(effect))
	_add_text(" · " + EffectInfo.get_kind_text(effect) + extra + "\n", COLOR_HINT)


## Resistances above 0 and absorbed kinds are strengths, below 0 weaknesses.
func _add_strengths(enemy: EnemyData) -> void:
	var strengths: Array[String] = []
	var weaknesses: Array[String] = []
	for kind: String in enemy.resistances:
		var value: int = roundi(enemy.resistances[kind])
		var text: String = "%s %+d" % [DamageKinds.get_display_name(kind), value]
		if value > 0:
			strengths.append(text)
		elif value < 0:
			weaknesses.append(text)
	for kind: String in enemy.absorb:
		strengths.append(Language.translate("%s heilt ihn") % DamageKinds.get_display_name(kind))
	_add_heading(Language.translate("Stärken"))
	_add_text((", ".join(strengths) if not strengths.is_empty() else Language.translate("keine besonderen")) + "\n",
			COLOR_GOOD if not strengths.is_empty() else COLOR_HINT)
	_add_heading(Language.translate("Schwächen"))
	_add_text((", ".join(weaknesses) if not weaknesses.is_empty() else Language.translate("keine bekannt")) + "\n",
			COLOR_BAD if not weaknesses.is_empty() else COLOR_HINT)


## Special things it does (flies, splits, hides, calls helpers, poisons ...).
func _add_traits(enemy: EnemyData) -> void:
	var traits: Array[String] = []
	if enemy.hover:
		traits.append(Language.translate("Fliegt"))
	if enemy.back_row:
		traits.append(Language.translate("Steht hinten (erst erreichbar, wenn vorne keiner mehr steht)"))
	if not enemy.shroud_effect_id.is_empty():
		traits.append(Language.translate("Nicht zu treffen, solange seine Helfer leben"))
	if not enemy.split.is_empty():
		traits.append(Language.translate("Teilt sich, wenn es fast besiegt ist"))
	if not enemy.regrow.is_empty():
		traits.append(Language.translate("Wächst nach, solange die anderen leben"))
	if not enemy.summon.is_empty():
		traits.append(Language.translate("Ruft Helfer"))
	for entry: Dictionary in enemy.on_hit:
		var effect: StatusEffectData = entry.get("effect")
		if effect:
			traits.append(Language.translate("Treffer: %s (%d %%)") % [EffectInfo.link(effect), roundi(float(entry.get("chance", 0.0)) * 100.0)])
	if traits.is_empty():
		return
	_add_heading(Language.translate("Besonderes"))
	_add_text("\n".join(traits) + "\n", COLOR_STAT)


func _add_drops(enemy: EnemyData) -> void:
	_add_heading(Language.translate("Beute"))
	if enemy.drops.is_empty():
		_add_text(Language.translate("nichts") + "\n", COLOR_HINT)
		return
	var shown: Array[ItemData] = []
	for drop: Dictionary in enemy.drops:
		var item: ItemData = drop["item"]
		if shown.has(item):
			continue
		shown.append(item)
		_add_item_link(item)
		_add_text(drop_text(drop) + "\n", COLOR_HINT)


## " 1–3× · 14 % · Solide 100 %": amount, chance (with the dungeon loot factor) and the chances of
## a better rarity, read live from enemies.json "drops" (EnemyData.drops), so the lexicon always
## shows the current values.
static func drop_text(drop: Dictionary) -> String:
	var chance_factor: float = float(ContentDB.dungeon_loot().get("chance_factor", 1.0))
	var amount: String = "" if drop["max"] <= 1 else " %s×" % _range(drop["min"], drop["max"])
	var text: String = "%s · %s %%" % [amount, _number(minf(drop["chance"] * chance_factor, 1.0) * 100.0)]
	# Rarities are rolled from the highest down: a lower one only if the higher ones missed.
	var left: float = 1.0
	var parts: Array[String] = []
	for entry: Array in drop.get("rarities", []):
		var chance: float = left * minf(float(entry[1]), 1.0)
		left -= chance
		if chance > 0.0:
			parts.append("%s %s %%" % [Rarity.get_display_name(entry[0]), _number(chance * 100.0)])
	if not parts.is_empty():
		text += " · " + ", ".join(parts)
	return text


# --- Item -------------------------------------------------------------------------------

func _show_item(item: ItemData) -> void:
	_title_bar.title = Language.translate("Lexikon")
	_preview.hide()
	_preview.enemy = null
	_item_picture.show()
	_item_picture.texture = item.icon
	_phase_label.hide()
	var stack := InventorySlot.new()
	stack.item = item
	stack.amount = 1
	stack.rarity = item.base_rarity
	_text.append_text(ItemTooltip.build_text(stack) + "\n")
	_add_text(Language.translate("Art: %s\n") % Lexicon.get_item_category(item), COLOR_HINT)
	# Fur -> leather at the tanning rack, and back.
	if item.tan_result:
		_add_heading(Language.translate("Gerberbank ergibt"))
		_add_item_link(item.tan_result)
		_text.add_text("\n")
	var tanned_from: Array = Lexicon.get_items().filter(func(other: ItemData) -> bool: return other.tan_result == item)
	if not tanned_from.is_empty():
		_add_heading(Language.translate("Gegerbt aus"))
		for source: ItemData in tanned_from:
			_add_item_link(source)
			_text.add_text("\n")
	var droppers: Array[EnemyData] = Lexicon.get_droppers(item)
	if not droppers.is_empty():
		_add_heading(Language.translate("Beute von"))
		for enemy in droppers:
			_add_enemy_link(enemy)
			for drop: Dictionary in enemy.drops:
				if drop["item"] == item:
					_add_text(drop_text(drop), COLOR_HINT)
					break
			_text.add_text("\n")
	var dungeons: Array = Lexicon.get_reward_dungeons(item).map(func(dungeon: DungeonData) -> String: return dungeon.display_name)
	if not dungeons.is_empty():
		_add_heading(Language.translate("Belohnung in"))
		_add_text(", ".join(dungeons) + "\n", COLOR_HINT)


# --- Status effect ------------------------------------------------------------------------

func _show_effect(effect: StatusEffectData) -> void:
	_title_bar.title = Language.translate("Statuseffekt")
	_show_picture(effect.icon)
	_add_text("[b]%s[/b]\n" % effect.display_name, effect.color)
	_add_text(EffectInfo.get_kind_text(effect) + "\n", EffectInfo.get_kind_color(effect))
	if not effect.description.is_empty():
		_add_text(effect.description + "\n", COLOR_STAT)
	_add_heading(Language.translate("Wirkung"))
	_text.append_text("\n".join(EffectInfo.get_lines(effect)) + "\n")
	var hero_skills: Array[Dictionary] = EffectInfo.get_hero_skills(effect)
	if not hero_skills.is_empty():
		_add_heading(Language.translate("Von Helden-Skills"))
		for entry: Dictionary in hero_skills:
			_add_skill_link(entry["skill"])
			_add_text(" · %s, %s%s\n" % [entry["class"], entry["tree"], _chance_text(entry["chance"])], COLOR_HINT)
	var enemies: Array[Dictionary] = EffectInfo.get_enemies(effect)
	if not enemies.is_empty():
		_add_heading(Language.translate("Von Monstern"))
		for entry: Dictionary in enemies:
			_add_enemy_link(entry["enemy"])
			var via: String = Language.translate("Treffer") if str(entry["via"]).is_empty() else str(entry["via"])
			if GameState.lexicon.is_enemy_known(entry["enemy"]):
				_add_text(" · %s%s" % [via, _chance_text(entry["chance"])], COLOR_HINT)
			_text.add_text("\n")


static func _chance_text(chance: float) -> String:
	return "" if chance >= 1.0 else " (%d %%)" % roundi(chance * 100.0)


# --- Skill --------------------------------------------------------------------------------

func _show_skill(skill: SkillData) -> void:
	_title_bar.title = Language.translate("Fähigkeit")
	_show_picture(skill.icon)
	var tooltip: String = skill.get_tooltip(1, true)
	# The hint for the details is not needed here, the page shows them.
	tooltip = tooltip.replace("[color=#9e998f][font_size=11]Shift: Details[/font_size][/color]", "").strip_edges()
	_text.append_text(tooltip + "\n")
	var effects: Array[StatusEffectData] = EffectInfo.get_effects_of_skill(skill)
	if not effects.is_empty():
		_add_heading(Language.translate("Statuseffekte"))
		for effect in effects:
			_add_effect_line(effect, _chance_text(EffectInfo.get_chance(skill, effect)))
	var users: Array[EnemyData] = []
	for enemy: EnemyData in Lexicon.get_enemies():
		if EffectInfo.get_enemy_skills(enemy).has(skill):
			users.append(enemy)
	if not users.is_empty():
		_add_heading(Language.translate("Benutzt von"))
		for enemy in users:
			_add_enemy_link(enemy)
			_text.add_text("\n")


## Left side for effects and skills: the icon, big.
func _show_picture(icon: Texture2D) -> void:
	_preview.hide()
	_preview.enemy = null
	_phase_label.hide()
	_item_picture.show()
	_item_picture.texture = icon


# --- Links and text -----------------------------------------------------------------------

func _add_skill_link(skill: SkillData) -> void:
	if skill.icon:
		_text.add_image(skill.icon, ICON_SIZE, ICON_SIZE)
		_text.add_text(" ")
	_text.append_text(Lexicon.skill_link(skill))

## Icon + name as a link; not discovered yet: dark icon and "???" (the link shows its silhouette
## in the lexicon).
func _add_item_link(item: ItemData) -> void:
	var known: bool = GameState.lexicon.is_item_known(item)
	if item.icon:
		_text.add_image(item.icon, ICON_SIZE, ICON_SIZE, Color.WHITE if known else COLOR_SILHOUETTE)
		_text.add_text(" ")
	_text.push_meta("%s:%s" % [Lexicon.ITEM, item.id])
	_add_text(item.display_name if known else "???", Lexicon.COLOR_ITEM_LINK)
	_text.pop()


func _add_enemy_link(enemy: EnemyData) -> void:
	var known: bool = GameState.lexicon.is_enemy_known(enemy)
	var icon: Texture2D = Lexicon.get_enemy_icon(enemy)
	if icon:
		_text.add_image(icon, ICON_SIZE, ICON_SIZE, Color.WHITE if known else COLOR_SILHOUETTE)
		_text.add_text(" ")
	_text.push_meta("%s:%s" % [Lexicon.ENEMY, enemy.id])
	_add_text(enemy.display_name if known else "???", Lexicon.COLOR_ENEMY_LINK)
	_text.pop()
	if known:
		_add_text(Language.translate(" · Lv %d") % enemy.level, COLOR_HINT)


func _on_meta_clicked(meta: Variant) -> void:
	GameState.open_lexicon(str(meta))


func _on_meta_hover_started(_meta: Variant) -> void:
	_text.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _add_heading(text: String) -> void:
	_add_text("\n" + text + "\n", COLOR_HEADER)


func _add_text(text: String, color: Color = Color.WHITE) -> void:
	_text.push_color(color)
	_text.append_text(text)
	_text.pop()


static func _range(low: int, high: int) -> String:
	return str(low) if low == high else "%d–%d" % [low, high]


static func _number(value: float) -> String:
	var text: String = ("%.1f" % value).trim_suffix(".0")
	return text.replace(".", ",") if Language.get_current() == Language.BASE else text
