class_name Voice
extends RefCounted
## How a people sounds when it speaks (docs/DIALOGE.md, "Völker"). A story figure gets a voice with
## story.json "npcs.<id>.voice", a merchant with its `voice` export; DialogueBox and the shop greeting
## run the finished (translated) text through apply(). Works on any language, so the English text
## hisses too.
## - "hiss" (the lizard people): words starting with s and every ss / ß are drawn out like a snake
##   ("Sand" » "Sssand", "muss" » "musss", "groß" » "grosss"). S that someone already drew out by hand
##   in the text (or a name like "Ssiva") count once, so nothing gets longer than three.

const HISS: String = "hiss"

static var _drawn_out: RegEx
static var _drawn_out_start: RegEx
static var _double_s: RegEx
static var _word_start: RegEx


static func apply(text: String, voice: String) -> String:
	match voice:
		HISS:
			return hiss(text)
	return text


static func hiss(text: String) -> String:
	if _drawn_out == null:
		_drawn_out = RegEx.create_from_string("([sS])s{2,}")
		_drawn_out_start = RegEx.create_from_string("(?<!\\p{L})([sS])s+")
		# Two s in a row that are not part of a longer run.
		_double_s = RegEx.create_from_string("(?<![sS])ss(?!s)")
		_word_start = RegEx.create_from_string("(?<!\\p{L})([sS])(?=\\p{L})")
	var result: String = _drawn_out_start.sub(_drawn_out.sub(text, "$1", true), "$1", true)
	result = result.replace("ß", "sss")
	result = _double_s.sub(result, "sss", true)
	return _word_start.sub(result, "$1ss", true)
