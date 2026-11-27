class_name ChanceBar
extends Control
## Over Egon's lever: how likely each rarity is on the next pull (ShopGoods.rarity_chances: the
## player level, the shop skills and every pull today make rarer goods likelier): one coloured part per rarity (Rarity colours, as wide as its chance), below it
## "R1 85 % · R2 15 %". The tooltip lists every rarity and which relic tiers can come.
## refresh() after a level change; drawing reads only the stored parts.

const BAR_HEIGHT: float = 8.0
const BORDER := Color(0.08, 0.05, 0.07)

## [rarity, percent] as shown.
var _parts: Array = []
var _text: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_text = Label.new()
	_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_constant_override("outline_size", 4)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.position = Vector2(0, BAR_HEIGHT + 1.0)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	refresh()


func refresh() -> void:
	_parts = ShopGoods.rarity_chances()
	_text.size = Vector2(size.x, 10)
	var shown: Array[String] = []
	var lines: Array[String] = [Language.translate("Chancen auf dem Tisch:")]
	for part: Array in _parts:
		shown.append("R%d %d%%" % [part[0], roundi(part[1])])
		lines.append("%s: %d %%" % [Rarity.label(int(part[0])), roundi(part[1])])
	_text.text = " · ".join(shown)
	var tiers: Array[String] = []
	for tier: int in ShopGoods.open_relic_tiers():
		tiers.append("R%d" % tier)
	lines.append(Language.translate("Relikte: %d %% pro Hebel, Stufen %s") % [roundi(float(Content.relics().get("table_chance", 0.0)) * 100.0), ", ".join(tiers)])
	lines.append(Language.translate("Höhere Stufen kommen mit deiner Spielerstufe."))
	var materials: Array[String] = []
	for part: Array in ShopGoods.material_chances():
		materials.append("%s %d %%" % [Language.translate(ShopGoods.material_name(String(part[0]))), roundi(part[1])])
	lines.append(Language.translate("Material: %s") % ", ".join(materials))
	var next: Dictionary = ShopGoods.next_material()
	if not next.is_empty():
		lines.append(_unlock_text(String(next["id"]), next["unlock"]))
	lines.append(Language.translate("Jeder weitere Dreh heute: %d %% von R1 zu den selteneren Stufen (höchstens %d %%).") % [roundi(float(Content.shop().get("reroll_shift", 0.0))), roundi(float(Content.shop().get("reroll_shift_max", 0.0)))])
	tooltip_text = "\n".join(lines)
	queue_redraw()


## "Eisen: nach Dungeon der Glut" / "Bronze: ab Stufe 3".
static func _unlock_text(material: String, unlock: Dictionary) -> String:
	var name: String = Language.translate(ShopGoods.material_name(material))
	if unlock.has("dungeon"):
		var dungeon: String = Language.translate(String(Content.dungeon(String(unlock["dungeon"])).get("name", unlock["dungeon"])))
		return Language.translate("%s: nach %s") % [name, dungeon]
	return Language.translate("%s: ab Stufe %d") % [name, int(unlock.get("level", 0))]


func get_parts() -> Array:
	return _parts


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, BAR_HEIGHT)).grow(1.0), BORDER)
	var x: float = 0.0
	for part: Array in _parts:
		var width: float = size.x * float(part[1]) / 100.0
		draw_rect(Rect2(x, 0, width, BAR_HEIGHT), Rarity.color(int(part[0])))
		x += width
