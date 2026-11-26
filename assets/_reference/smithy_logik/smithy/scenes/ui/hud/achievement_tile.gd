class_name AchievementTile
extends Control
## One achievement in the character window (tab "Erfolge"): its icon in a slot frame (dimmed while
## not reached, "?" for a secret one), below a bar towards the next level with "Lv 2" in it (nothing
## before level 1, "max lv" in gold at the last level). Hover: name, what to do and the exact numbers.

const SIZE: Vector2 = Vector2(36, 32)
const SLOT_SIZE: Vector2 = Vector2(20, 20)
const ICON_SIZE: Vector2 = Vector2(16, 16)
const BAR_SIZE: Vector2 = Vector2(34, 9)
const FONT_SIZE: int = 11
const COLOR_BAR_BACK: Color = Color(0.13, 0.075, 0.12)
const COLOR_BAR_BORDER: Color = Color(0.55, 0.4, 0.32)
const COLOR_BAR_FILL: Color = Color(0.36, 0.55, 0.3)
const COLOR_BAR_MAX: Color = Color(0.62, 0.45, 0.12)
const COLOR_TEXT: Color = Color(0.96, 0.92, 0.84)
const COLOR_MAX: Color = Color(1.0, 0.84, 0.3)
const COLOR_LOCKED: Color = Color(0.4, 0.4, 0.4, 0.7)
const COLOR_HEADER: String = "#f2cc80"
const COLOR_HINT: String = "#a89c8c"
const DEFAULT_ICON: Texture2D = preload("res://assets/sprites/items/default.png")

var achievement_id: String = ""
var _icon: Texture2D
var _icon_tint: Color = Color.WHITE


func setup(id: String) -> void:
	achievement_id = id
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = id
	_load_icon()
	queue_redraw()


func _load_icon() -> void:
	var data: Dictionary = Achievements.get_data(achievement_id)
	_icon = null
	_icon_tint = Color.WHITE
	if data.has("icon") and ResourceLoader.exists(String(data["icon"])):
		_icon = load(String(data["icon"]))
	elif data.has("item") and ContentDB.item(String(data["item"])):
		_icon = ContentDB.item(String(data["item"])).icon
	elif data.has("enemy") and ContentDB.enemy(String(data["enemy"])):
		var enemy: EnemyData = ContentDB.enemy(String(data["enemy"]))
		_icon = enemy.get_frame(0)
		_icon_tint = enemy.tint
	if _icon == null:
		_icon = DEFAULT_ICON


func _draw() -> void:
	var achievements: Achievements = GameState.achievements
	var level: int = achievements.get_level(achievement_id)
	var font: Font = get_theme_default_font()
	# Slot frame with the icon.
	var slot_rect := Rect2(Vector2((SIZE.x - SLOT_SIZE.x) / 2.0, 0), SLOT_SIZE)
	draw_style_box(get_theme_stylebox("panel", Language.translate("ItemSlot")), slot_rect)
	if achievements.is_hidden(achievement_id):
		_draw_centered(font, "?", slot_rect, COLOR_TEXT)
	else:
		var icon_rect := Rect2(slot_rect.position + (SLOT_SIZE - ICON_SIZE) / 2.0, ICON_SIZE)
		draw_texture_rect(_icon, icon_rect, false, _icon_tint if level > 0 else _icon_tint * COLOR_LOCKED)
	# Bar towards the next level, the level in it.
	var bar := Rect2(Vector2((SIZE.x - BAR_SIZE.x) / 2.0, SLOT_SIZE.y + 2), BAR_SIZE)
	draw_rect(bar, COLOR_BAR_BACK)
	var is_max: bool = achievements.is_max(achievement_id)
	var fill: float = 0.0 if achievements.is_hidden(achievement_id) else achievements.get_fraction(achievement_id)
	if fill > 0.0:
		draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * fill), bar.size.y)), COLOR_BAR_MAX if is_max else COLOR_BAR_FILL)
	draw_rect(bar, COLOR_BAR_BORDER, false, 1.0)
	if is_max:
		_draw_centered(font, Language.translate("max lv"), bar, COLOR_MAX)
	elif level > 0:
		_draw_centered(font, Language.translate("Lv %d") % level, bar, COLOR_TEXT)


func _draw_centered(font: Font, text: String, rect: Rect2, color: Color) -> void:
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var at := Vector2(rect.position.x + roundf((rect.size.x - size.x) / 2.0),
			rect.position.y + roundf((rect.size.y - size.y) / 2.0) + font.get_ascent(FONT_SIZE))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _make_custom_tooltip(_for_text: String) -> Object:
	return RichTooltip.create(get_tooltip_bbcode())


## Name, what to do and the numbers ("24 / 50"); a secret one only says that it is secret.
func get_tooltip_bbcode() -> String:
	var achievements: Achievements = GameState.achievements
	if achievements.is_hidden(achievement_id):
		return Language.translate("[color=%s]Geheimer Erfolg[/color]\n[color=%s]Wird verraten, sobald du ihn geschafft hast.[/color]") % [COLOR_HEADER, COLOR_HINT]
	var data: Dictionary = Achievements.get_data(achievement_id)
	var level: int = achievements.get_level(achievement_id)
	var max_level: int = Achievements.get_max_level(achievement_id)
	var lines: Array[String] = ["[color=%s]%s[/color]" % [COLOR_HEADER, data.get("name", achievement_id)]]
	lines.append(String(data.get("description", "")))
	var progress: int = achievements.get_progress(achievement_id)
	if achievements.is_max(achievement_id):
		lines.append(Language.translate("Geschafft: %d / %d") % [progress, achievements.get_next_target(achievement_id)] if max_level > 1 or progress > 1 else Language.translate("Geschafft!"))
	else:
		lines.append(Language.translate("Fortschritt: %d / %d") % [progress, achievements.get_next_target(achievement_id)])
	if max_level > 1:
		var targets: Array[String] = []
		for target in Achievements.get_targets(achievement_id):
			targets.append(str(target))
		lines.append(Language.translate("[color=%s]Stufe %d / %d (Ziele: %s)[/color]") % [COLOR_HINT, level, max_level, ", ".join(targets)])
	return "\n".join(lines)
