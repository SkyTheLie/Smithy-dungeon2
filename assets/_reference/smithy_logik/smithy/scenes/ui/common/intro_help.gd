class_name IntroHelp
extends VBoxContainer
## Introduction / help (tab "Einleitung" of SettingsPanel): a search field on top, below it the
## topics sorted into themes (Grundlagen, Schmieden, Handel …) on the left and the chosen text
## on the right.
## Typing in the search field keeps only the entries whose title or text contain every word
## (case does not matter, e.g. "seltenheit"); the right side then lists all of them with the
## words marked, a click on one shows only that one.
## Entries (get_entries): the tips of story "hints" (intro_hints always, every other one only once
## the game has shown it, GameState.story.shown_hints, so the list never spoils the story) and
## the help texts of "help_topics" (only help, never shown as a tip; with after_hint/after_flag
## only from then on). The themes and their order: "help_categories" (data/content/story/help.json);
## shown tips without a theme stand under "Geschichte" at the end.
## Builds its own children, so it can simply be added with IntroHelp.new().

const FONT_SIZE: int = 11
const LIST_WIDTH: float = 96.0
const COLOR_TITLE: Color = Color(0.95, 0.82, 0.5)
const COLOR_TEXT: Color = Color(0.85, 0.82, 0.75)
const COLOR_HINT: Color = Color(0.62, 0.6, 0.56)
const COLOR_MARK: Color = Color(1.0, 0.9, 0.3)
const COLOR_THEME: Color = Color(0.75, 0.72, 0.66)
## Theme of the shown tips that no category lists (story tips).
const STORY_CATEGORY: String = "story"

var _search: LineEdit
var _tree: Tree
var _text: RichTextLabel
## Entries of the list as built last (get_entries).
var _entries: Array[Dictionary] = []
## Id of the entry shown on the right ("" = none / all hits of the search).
var _selected_id: String = ""
## Themes the player opened in the list (by id), kept while the window is open.
var _open_categories: Dictionary[String, bool] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	_search = LineEdit.new()
	_search.placeholder_text = Language.translate("Suchen, z. B. Seltenheit")
	_search.clear_button_enabled = true
	_search.add_theme_font_size_override("font_size", FONT_SIZE)
	_search.text_changed.connect(func(_text_now: String) -> void: _rebuild())
	add_child(_search)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	add_child(row)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	_tree.focus_mode = Control.FOCUS_NONE
	_tree.add_theme_font_size_override("font_size", FONT_SIZE)
	_tree.add_theme_constant_override("item_margin", 6)
	_tree.add_theme_constant_override("v_separation", 0)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_collapsed.connect(_on_item_collapsed)
	row.add_child(_tree)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text.add_theme_color_override("default_color", COLOR_TEXT)
	row.add_child(_text)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			_entries = get_entries()
			_rebuild())
	if is_visible_in_tree():
		_entries = get_entries()
		_rebuild()


## Types `query` into the search field (as the player would).
func set_search(query: String) -> void:
	_search.text = query
	_rebuild()


## Ids of the entries the list shows now (tests).
func get_listed_ids() -> Array[String]:
	var ids: Array[String] = []
	var category: TreeItem = _tree.get_root().get_first_child() if _tree.get_root() else null
	while category:
		for item in category.get_children():
			ids.append(str(item.get_metadata(0)))
		category = category.get_next()
	return ids


## Shows the entry `id` on the right (as a click in the list does).
func select_entry(id: String) -> void:
	_selected_id = id
	_show_text()


## The text on the right without formatting (tests).
func get_shown_text() -> String:
	return _text.get_parsed_text()


## All entries the player may read now, in the order of the themes: dictionaries with
## "id", "category" (theme id), "category_name", "title" and "text" (placeholders filled in).
static func get_entries() -> Array[Dictionary]:
	var hints: Dictionary = Story.get_data("hints")
	var topics: Dictionary = Story.get_data("help_topics")
	var intro: Array = Story.get_data("intro_hints")
	var entries: Array[Dictionary] = []
	var listed: Dictionary[String, bool] = {}
	for category: Dictionary in Story.get_data("help_categories"):
		for id: String in category.get("hints", []):
			var data: Dictionary = {}
			if topics.has(id) and _is_topic_open(topics[id]):
				data = topics[id]
			elif hints.has(id) and (intro.has(id) or GameState.story.shown_hints.has(id)):
				data = hints[id]
			listed[id] = true
			if not data.is_empty():
				entries.append(_make_entry(id, str(category.get("id", "")), str(category.get("name", "")), data))
	# Tips of the story: the order of the hints in the files.
	for id: String in hints:
		if not listed.has(id) and (intro.has(id) or GameState.story.shown_hints.has(id)):
			entries.append(_make_entry(id, STORY_CATEGORY, Language.translate("Geschichte"), hints[id]))
	return entries


## Ids of the entries whose title or text contain every word of `query` (case does not
## matter); every entry for an empty query.
static func search(entries: Array[Dictionary], query: String) -> Array[String]:
	var words: PackedStringArray = query.strip_edges().to_lower().split(" ", false)
	var ids: Array[String] = []
	for entry in entries:
		var haystack: String = (entry["title"] + "\n" + entry["text"]).to_lower()
		var found: bool = true
		for word in words:
			if not haystack.contains(word):
				found = false
				break
		if found:
			ids.append(entry["id"])
	return ids


static func _is_topic_open(topic: Dictionary) -> bool:
	var after_hint: String = topic.get("after_hint", "")
	if not after_hint.is_empty() and not GameState.story.shown_hints.has(after_hint):
		return false
	var after_flag: String = topic.get("after_flag", "")
	return after_flag.is_empty() or GameState.story.has_flag(after_flag)


static func _make_entry(id: String, category: String, category_name: String, data: Dictionary) -> Dictionary:
	return {"id": id, "category": category, "category_name": category_name,
		"title": GameState.format_story_text(data.get("title", "")),
		"text": GameState.format_story_text(data.get("text", ""))}


func _get_words() -> PackedStringArray:
	return _search.text.strip_edges().to_lower().split(" ", false)


## Builds the list again: all themes, or only the hits of the search (themes opened).
func _rebuild() -> void:
	_tree.clear()
	var root: TreeItem = _tree.create_item()
	var searching: bool = not _get_words().is_empty()
	var hits: Array[String] = search(_entries, _search.text)
	if not hits.has(_selected_id):
		_selected_id = ""
	if not searching and _selected_id.is_empty() and not _entries.is_empty():
		_selected_id = _entries[0]["id"]
	var category_item: TreeItem = null
	var category_id: String = ""
	for entry in _entries:
		if not hits.has(entry["id"]):
			continue
		if entry["category"] != category_id or category_item == null:
			category_id = entry["category"]
			category_item = _tree.create_item(root)
			category_item.set_metadata(0, "")
			category_item.set_selectable(0, false)
			category_item.set_custom_color(0, COLOR_THEME)
			category_item.set_meta(&"category", category_id)
			category_item.set_meta(&"name", entry["category_name"])
			category_item.collapsed = not searching and not _open_categories.get(category_id, false)
		var item: TreeItem = _tree.create_item(category_item)
		item.set_text(0, entry["title"])
		item.set_tooltip_text(0, entry["title"])
		item.set_metadata(0, entry["id"])
		if entry["id"] == _selected_id:
			# the theme of the shown entry stays open
			category_item.collapsed = false
			item.select(0)
	# theme names with the number of entries (of hits while searching)
	var category: TreeItem = root.get_first_child()
	while category:
		category.set_text(0, "%s (%d)" % [category.get_meta(&"name"), category.get_child_count()])
		category = category.get_next()
	if hits.is_empty():
		var none: TreeItem = _tree.create_item(root)
		none.set_text(0, Language.translate("Nichts gefunden"))
		none.set_selectable(0, false)
		none.set_custom_color(0, COLOR_HINT)
		none.set_metadata(0, "")
	_show_text()


func _on_item_selected() -> void:
	var item: TreeItem = _tree.get_selected()
	if item == null or str(item.get_metadata(0)).is_empty():
		return
	_selected_id = str(item.get_metadata(0))
	_show_text()


## Opening/closing a theme by hand is kept (not while searching: then all hits are open).
func _on_item_collapsed(item: TreeItem) -> void:
	if item.has_meta(&"category") and _get_words().is_empty():
		_open_categories[str(item.get_meta(&"category"))] = not item.collapsed


## Right side: the chosen entry, or while searching without a choice all hits one below the
## other; the search words are marked.
func _show_text() -> void:
	var words: PackedStringArray = _get_words()
	var parts: Array[String] = []
	if not _selected_id.is_empty():
		for entry in _entries:
			if entry["id"] == _selected_id:
				parts.append(_format_entry(entry, words))
	elif not words.is_empty():
		var hits: Array[String] = search(_entries, _search.text)
		for entry in _entries:
			if hits.has(entry["id"]):
				parts.append(_format_entry(entry, words))
		if parts.is_empty():
			parts.append("[color=#%s]%s[/color]" % [COLOR_HINT.to_html(false), _escape(Language.translate("Kein Eintrag enthält dieses Wort. Versuch ein anderes oder ein kürzeres."))])
	_text.text = "\n\n".join(parts)
	_text.scroll_to_line(0)


func _format_entry(entry: Dictionary, words: PackedStringArray) -> String:
	return "[color=#%s]%s[/color]\n%s" % [COLOR_TITLE.to_html(false), _mark(entry["title"], words), _mark(entry["text"], words)]


## `text` as BBCode with every search word coloured (plain text otherwise).
static func _mark(text: String, words: PackedStringArray) -> String:
	if words.is_empty():
		return _escape(text)
	var lower: String = text.to_lower()
	# marked[i] = character i belongs to a search word
	var marked: Array[bool] = []
	marked.resize(text.length())
	for word in words:
		var at: int = lower.find(word)
		while at != -1:
			for i in range(at, at + word.length()):
				marked[i] = true
			at = lower.find(word, at + word.length())
	var result: String = ""
	var start: int = 0
	while start < text.length():
		var end: int = start
		while end < text.length() and marked[end] == marked[start]:
			end += 1
		var piece: String = _escape(text.substr(start, end - start))
		result += "[color=#%s]%s[/color]" % [COLOR_MARK.to_html(false), piece] if marked[start] else piece
		start = end
	return result


## Tip texts are plain text: "[" would start a BBCode tag.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
