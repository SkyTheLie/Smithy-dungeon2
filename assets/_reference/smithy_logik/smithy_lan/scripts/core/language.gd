class_name Language
extends RefCounted
## The game's language. German is the original: every German text is its own key, and each other
## language is one file res://locale/<code>.po (msgid = German text, msgstr = translation; made
## with assets/_reference/i18n/, see docs/SPRACHEN.md). A missing or empty translation shows the
## German text. Saved in user://settings.cfg (section "language", WindowLayout).
## Labels and buttons translate their text by themselves (Godot's auto translate). The content
## of data/content/*.json is translated once when ContentDB loads it, so a new language only
## shows everywhere after a restart.

const SECTION: String = "language"
const BASE: String = "de"
const LOCALE_DIR: String = "res://locale/"
## Name of each language in its own language (for the choice in the settings). Languages without
## a .po file are not offered.
const NAMES: Dictionary = {
	"de": "Deutsch", "en": "English", "es": "Español", "fr": "Français", "it": "Italiano",
	"pt": "Português", "pl": "Polski", "ru": "Русский", "tr": "Türkçe", "nl": "Nederlands",
	"ja": "日本語", "zh": "中文", "ko": "한국어",
}

static var _applied: bool = false
## Language at the start of the game (the one ContentDB was translated with).
static var _started_with: String = ""


## Codes of all languages there is a file for, German first.
static func get_available() -> Array[String]:
	var list: Array[String] = [BASE]
	for file in ResourceLoader.list_directory(LOCALE_DIR):
		if file.get_extension() == "po":
			var code: String = file.get_basename()
			if not list.has(code):
				list.append(code)
	return list


static func get_language_name(code: String) -> String:
	return NAMES.get(code, code)


## The chosen language; before the player chose one: the system language if there is a file for
## it, else English if there is one, else German.
static func get_current() -> String:
	var available: Array[String] = get_available()
	var saved: String = String(WindowLayout.get_setting(SECTION, "locale", ""))
	if available.has(saved):
		return saved
	var system: String = OS.get_locale_language()
	if available.has(system):
		return system
	return "en" if available.has("en") else BASE


static func is_base() -> bool:
	return TranslationServer.get_locale().begins_with(BASE)


## Loads the translations and switches to the chosen language (once; ContentDB and GameState call it).
static func apply() -> void:
	if _applied:
		return
	_applied = true
	add_font_fallbacks()
	for code in get_available():
		if code == BASE:
			continue
		var translation: Translation = load(LOCALE_DIR + code + ".po") as Translation
		if translation:
			translation.locale = code
			TranslationServer.add_translation(translation)
	_started_with = get_current()
	TranslationServer.set_locale(_started_with)


## The pixel font micro5 only has Latin letters. Characters it lacks (Chinese) come from these
## pixel fonts, drawn at their own pixel size and only scaled by whole numbers (sharp at the UI
## sizes 9-16, twice/three times as big for titles). Fusion Pixel Font, OFL (assets/fonts/).
const FALLBACK_FONTS: Array[String] = ["res://assets/fonts/fusion_pixel_12px_zh_hans.ttf"]
const FALLBACK_PIXEL_SIZE: int = 12


static func add_font_fallbacks() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	var base: Font = theme.default_font if theme else null
	if base == null:
		return
	var fallbacks: Array[Font] = base.fallbacks.duplicate()
	for path in FALLBACK_FONTS:
		var font := load(path) as FontFile
		if font == null or fallbacks.has(font):
			continue
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		font.fixed_size = FALLBACK_PIXEL_SIZE
		font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		fallbacks.append(font)
	base.fallbacks = fallbacks


## Saves the choice. The interface changes at once, the game content after a restart.
static func set_current(code: String) -> void:
	WindowLayout.set_setting(SECTION, "locale", code)
	TranslationServer.set_locale(code)


## Loads the content (ContentDB) again in the chosen language. Only while no game runs.
static func reload_content() -> void:
	ContentDB.reload()
	_started_with = get_current()


## true if the content (items, story ...) still is in the language the game started with.
static func needs_restart() -> bool:
	return get_current() != _started_with


## The text in the current language (German text = key). For content from data/content.
static func translate(text: String) -> String:
	if text.is_empty() or is_base():
		return text
	return String(TranslationServer.translate(text))


## Name of a composed item: German joins the words ("Eisen" + "Schwert" -> "Eisenschwert"),
## other languages use the pattern "{material} {item}" from their .po file ("Iron Sword",
## Spanish e.g. "{item} de {material}").
static func compose_name(material: String, item_name: String) -> String:
	# The name has its metal already (e.g. "Eisen-Feuerstab"): not "Eiseneisen-feuerstab".
	if not material.is_empty() and item_name.to_lower().begins_with(material.to_lower()):
		return item_name
	if is_base():
		return material + item_name.to_lower()
	return translate("{material} {item}").format({"material": material, "item": item_name})


## Translates every text in a loaded JSON value (dictionaries and lists, keys stay).
static func translate_data(value: Variant) -> Variant:
	if value is String:
		return translate(value)
	if value is Dictionary:
		for key in value.keys():
			value[key] = translate_data(value[key])
	elif value is Array:
		for i in value.size():
			value[i] = translate_data(value[i])
	return value
