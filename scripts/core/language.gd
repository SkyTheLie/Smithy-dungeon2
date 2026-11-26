class_name Language
extends RefCounted
## The game's language (taken over from Smithy). German is the original: every German text is its
## own key, and each other language is one file res://locale/<code>.po (msgid = German text,
## msgstr = translation; made with assets/_reference/i18n/build_po.py, see docs/SPRACHEN.md).
## A missing or empty translation shows the German text. Saved in user://settings.cfg
## (section "language", WindowLayout).
## Labels and buttons translate their text by themselves (Godot's auto translate). Texts from
## data/*.json (item names, descriptions ...) go through translate() where they are shown.

const SECTION: String = "language"
const BASE: String = "de"
const LOCALE_DIR: String = "res://locale/"
## Name of each language in its own language (for the choice). Languages without a .po file are
## not offered.
const NAMES: Dictionary = {
	"de": "Deutsch", "en": "English", "es": "Español", "fr": "Français", "it": "Italiano",
	"pt": "Português", "pl": "Polski", "ru": "Русский", "tr": "Türkçe", "nl": "Nederlands",
	"ja": "日本語", "zh": "中文", "ko": "한국어", "fa": "فارسی",
}

## Loading the .po files happens once per start of the program. Not game state.
static var _applied: bool = false


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


## true once the player chose a language (language choice at the first start, settings).
static func has_choice() -> bool:
	return get_available().has(String(WindowLayout.get_setting(SECTION, "locale", "")))


static func is_base() -> bool:
	return TranslationServer.get_locale().begins_with(BASE)


## Loads the translations and switches to the chosen language (once, Game calls it at the start).
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
	TranslationServer.set_locale(get_current())


## The pixel font micro5 only has Latin letters. Characters it lacks come from these fonts, in
## this order. path -> pixel size: > 0 = a bitmap pixel font drawn at its own pixel size and only
## scaled by whole numbers, 0 = an outline font drawn at the size of the text, -1 = an outline
## pixel font drawn at the size of the text without smoothing.
##   Russian: Tiny5 (OFL), Chinese / Japanese: Fusion Pixel Font (OFL), Persian: Vazirmatn (OFL).
const FALLBACK_FONTS: Dictionary[String, int] = {
	"res://assets/fonts/tiny5_cyrillic.ttf": -1,
	"res://assets/fonts/fusion_pixel_12px_zh_hans.ttf": 12,
	"res://assets/fonts/fusion_pixel_12px_ja.ttf": 12,
	"res://assets/fonts/vazirmatn_regular.ttf": 0,
}


static func add_font_fallbacks() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	var base: Font = theme.default_font if theme else null
	if base == null:
		return
	var fallbacks: Array[Font] = base.fallbacks.duplicate()
	for path: String in FALLBACK_FONTS:
		var font := load(path) as FontFile
		if font == null or fallbacks.has(font):
			continue
		var pixel_size: int = FALLBACK_FONTS[path]
		if pixel_size != 0:
			font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			font.hinting = TextServer.HINTING_NONE
			font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		if pixel_size > 0:
			font.fixed_size = pixel_size
			font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		fallbacks.append(font)
	base.fallbacks = fallbacks


## Saves the choice; every text changes at once.
static func set_current(code: String) -> void:
	WindowLayout.set_setting(SECTION, "locale", code)
	TranslationServer.set_locale(code)


## The text in the current language (German text = key).
static func translate(text: String) -> String:
	if text.is_empty() or is_base():
		return text
	return String(TranslationServer.translate(text))
