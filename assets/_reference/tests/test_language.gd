extends "res://assets/_reference/_lib/base_test.gd"
## Languages: all nine are offered (with a flag each), the .po files load, and texts from scenes
## and from data/*.json come out translated.


func run() -> void:
	var language: Script = script("res://scripts/core/language.gd")
	var available: Array = language.call("get_available")
	check_eq(available.size(), 9, "nine languages")
	for code: String in available:
		check(ResourceLoader.exists("res://assets/ui/flags/%s.png" % code), "flag for %s" % code)
	language.call("apply")
	TranslationServer.set_locale("en")
	check_eq(language.call("translate", "Neues Spiel"), "New Game", "menu text in English")
	check_eq(language.call("translate", "Rattenkönig"), "Rat King", "boss name in English")
	check_eq(language.call("translate", "Feuerwerk"), "Fireworks", "synergy in English")
	TranslationServer.set_locale("ja")
	check_eq(language.call("translate", "Ebene %d") % 2, "第2層", "floor in Japanese")
	TranslationServer.set_locale("de")
	check_eq(language.call("translate", "Neues Spiel"), "Neues Spiel", "German stays German")
