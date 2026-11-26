class_name HeroTournamentMenu
extends StationMenu
## Hero tournament window (HeroTournament): the crier of the duel ring of Sylvaris, the arena keeper
## of the arena halls (ArenaHall; in Eisquell's Gezeitenhalle the crier). Three views, all with a card
## on top:
## - registration (no tournament): card = hero rank, RP and a bar to the next rank; below the
##   prize to pick (PrizeChoiceList), "Liga" with one button per league (and "Großes Turnier"
##   where there is one) plus one line entry fee / prizes / why it is closed, and "Held" with one
##   button per hero (name in the colour of his class, busy heroes greyed out). "Rangliste" (only
##   here, only with `show_leaderboard`) shows the hero leaderboard (ArenaLeaderboard) instead,
##   "Turnier-Händler" the tournament shop (TournamentShopList).
## - tournament: card = league and round, the next match ("Sigurd gegen Gunter"); below the bracket
##   as lines (TournamentBracket: every name once on the left, lines to the right, names and lines
##   in the colour of their class, the player's hero framed and drawn in yellow, who is out faded).
## "Nächster Kampf" asks the arena (fight_requested: ArenaHall) to start the fight;
## without one it starts right away. Opening the window at another venue drops a bracket that is not
## fighting right now.
## A tournament is only left by winning or losing (is_locked_open): while it waits for the next
## fight, the window can't be closed (no X, no "Schließen", E and Escape do nothing), the player
## stands still, "Nächster Kampf" is the only button.

## "Kampf beginnen" was pressed: the arena shows both heroes, then calls start_fight().
signal fight_requested

const COLOR_PLAYER: Color = Color(1.0, 0.84, 0.35)
## How much of its class colour a hero who is out keeps.
const OUT_ALPHA: float = 0.4
const COLOR_OUT: Color = Color(0.5, 0.48, 0.46)
const COLOR_NEXT: Color = Color(0.55, 0.85, 1.0)
const COLOR_BLOCKED: Color = Color(1.0, 0.55, 0.45)
const TEXT_CHOOSE: String = "Welchen Helden schickst du in die Arena? Er kämpft allein, vier Runden, einer gegen einen."
const TEXT_NO_HEROES: String = "Du hast keinen Helden, der antreten könnte."
const TEXT_LOST: String = "%s ist ausgeschieden. Du kannst einen Helden neu anmelden."
const TEXT_WON: String = "%s hat das Turnier gewonnen."
const TEXT_PLACE: String = "%s belegt Platz %d. Du kannst einen Helden neu anmelden."

## Venue of this window ("" = Eisquell, otherwise a key of arena.json "venues").
@export var venue: String = ""
## true = the "Rangliste" button is there (arena halls).
@export var show_leaderboard: bool = false

@onready var _text_label: Label = %TextLabel
@onready var _next_label: Label = %NextLabel
@onready var _rank_bar: ProgressBar = %RankBar
@onready var _match_row: HBoxContainer = %MatchRow
@onready var _heroes_box: VBoxContainer = %HeroesBox
@onready var _bracket: HBoxContainer = %Bracket
@onready var _fight_button: Button = %FightButton
@onready var _watch_button: Button = %WatchButton
@onready var _new_button: Button = %NewButton
@onready var _rank_button: Button = %RankButton
@onready var _leaderboard: GridContainer = %Leaderboard
@onready var _shop_box: VBoxContainer = %ShopBox
@onready var _shop_button: Button = %ShopButton

## true = the chosen hero enters a league tournament instead of the great one.
var _league_mode: bool = false
## The league chosen for the league tournament (index in leagues.json, -1 = the highest open one).
var _league_index: int = -1


func _ready() -> void:
	super()
	_fight_button.pressed.connect(_on_fight_pressed)
	_watch_button.pressed.connect(_on_watch_pressed)
	_new_button.pressed.connect(_on_new_pressed)
	_rank_button.toggled.connect(_on_rank_toggled)
	_shop_button.toggled.connect(_on_shop_toggled)
	%CloseButton.pressed.connect(close)
	GameState.hero_tournament.changed.connect(_refresh)
	GameState.ranking.changed.connect(_queue_refresh)
	visibility_changed.connect(_refresh)


func _tournament() -> HeroTournament:
	return GameState.hero_tournament


## true while the player's hero is in a tournament waiting for its next fight: the window stays
## open until the tournament is won or lost (only "Nächster Kampf" goes on).
func is_locked_open() -> bool:
	return _tournament().state == HeroTournament.State.READY


func close() -> void:
	if is_locked_open():
		return
	super()


## E at the desk: opens the window; closing goes through close() (not while locked).
func toggle() -> void:
	if visible:
		close()
	else:
		show()


func _refresh() -> void:
	if not visible:
		return
	var tournament: HeroTournament = _tournament()
	if HeroTournament.venue != venue and tournament.state != HeroTournament.State.FIGHTING:
		HeroTournament.venue = venue
		tournament.reset()
		return
	var choosing: bool = tournament.state == HeroTournament.State.IDLE
	if not choosing and _rank_button.button_pressed:
		_rank_button.set_pressed_no_signal(false)
	if not choosing and _shop_button.button_pressed:
		_shop_button.set_pressed_no_signal(false)
	_shop_button.visible = choosing
	var shop_shown: bool = choosing and _shop_button.button_pressed
	_shop_button.text = Language.translate("Zurück") if shop_shown else Language.translate("Turnier-Händler")
	_rank_button.visible = show_leaderboard and choosing and not shop_shown
	var ranking_shown: bool = _rank_button.visible and _rank_button.button_pressed
	_rank_button.text = "Zurück" if ranking_shown else "Rangliste"
	_leaderboard.visible = ranking_shown
	_shop_box.visible = shop_shown
	_heroes_box.visible = choosing and not ranking_shown and not shop_shown
	_bracket.visible = not choosing
	_match_row.visible = false
	var locked: bool = is_locked_open()
	_title_bar.set_closable(not locked)
	%CloseButton.visible = not locked
	_fight_button.visible = tournament.state == HeroTournament.State.READY
	_watch_button.visible = tournament.state == HeroTournament.State.FIGHTING
	_new_button.visible = tournament.state == HeroTournament.State.LOST or tournament.state == HeroTournament.State.WON
	if shop_shown:
		_show_rank_card()
		for child in _shop_box.get_children():
			child.queue_free()
		TournamentShopList.fill(_shop_box)
	elif ranking_shown:
		_show_rank_card()
		_build_leaderboard()
	elif choosing:
		_build_registration()
	else:
		_show_match_card()
		_build_bracket()


# --- Card --------------------------------------------------------------------------------

## Card: hero rank and RP, the next rank on the right, a bar from this rank to the next one.
## false if this venue has no leagues (the card then shows TEXT_CHOOSE).
func _show_rank_card() -> bool:
	var ranking: TournamentRanking = GameState.ranking
	var has_leagues: bool = not TournamentRanking.venue_key("hero", venue).is_empty()
	_next_label.visible = has_leagues
	_rank_bar.visible = has_leagues
	if not has_leagues:
		_text_label.text = Language.translate(TEXT_CHOOSE)
		return false
	var rank: int = ranking.get_rank("hero")
	var points: int = ranking.get_points("hero")
	_text_label.text = Language.translate("Helden-Rang: %s · %d RP") % [ranking.get_rank_name("hero"), points]
	if rank + 1 < TournamentRanking.league_count():
		var low: int = TournamentRanking.league_points(rank)
		var high: int = TournamentRanking.league_points(rank + 1)
		_next_label.text = Language.translate("%s ab %d RP") % [TournamentRanking.HIDDEN_NAME, high]
		_rank_bar.value = clampf(float(points - low) / maxf(1.0, high - low), 0.0, 1.0)
	else:
		_next_label.text = Language.translate("Höchster Rang")
		_rank_bar.value = 1.0
	return true


## Card during a tournament: league (or the great tournament) and round, the next match below;
## after the end the result instead.
func _show_match_card() -> void:
	var tournament: HeroTournament = _tournament()
	_rank_bar.visible = false
	var heading: String = TournamentRanking.league_name(HeroTournament.league) if HeroTournament.is_league() \
			else Language.translate("Großes Turnier")
	_text_label.text = "%s · %s" % [heading, tournament.get_round_title()]
	_next_label.visible = HeroTournament.is_league()
	_next_label.text = Language.translate("%s · %d RP") % [GameState.ranking.get_rank_name("hero"), GameState.ranking.get_points("hero")]
	var hero_name: String = tournament.player_hero.display_name if tournament.player_hero else "?"
	match tournament.state:
		HeroTournament.State.LOST:
			if tournament.final_place == 3 or tournament.final_place == 4:
				_text_label.text += "\n" + Language.translate(TEXT_PLACE) % [hero_name, tournament.final_place]
			else:
				_text_label.text += "\n" + Language.translate(TEXT_LOST) % hero_name
			return
		HeroTournament.State.WON:
			_text_label.text += "\n" + Language.translate(TEXT_WON) % hero_name
			return
	var opponent: Dictionary = tournament.get_opponent()
	if tournament.player_hero == null or opponent.is_empty():
		return
	for child in _match_row.get_children():
		child.queue_free()
	_match_row.add_child(name_tag(hero_name, class_color(tournament.player_hero), COLOR_PLAYER))
	var versus := Label.new()
	versus.text = Language.translate("kämpft gerade gegen") if tournament.state == HeroTournament.State.FIGHTING \
			else Language.translate("gegen")
	versus.add_theme_color_override("font_color", COLOR_OUT)
	_match_row.add_child(versus)
	var rival: Hero = opponent["hero"]
	var rival_tag: PanelContainer = name_tag(rival.display_name, class_color(rival), Color.TRANSPARENT)
	rival_tag.tooltip_text = _describe(rival)
	_match_row.add_child(rival_tag)
	_match_row.visible = true


# --- Registration ------------------------------------------------------------------------

func _build_registration() -> void:
	for child in _heroes_box.get_children():
		child.queue_free()
	var has_leagues: bool = _show_rank_card()
	if has_leagues:
		PrizeChoiceList.fill(_heroes_box)
		_build_mode_buttons()
	else:
		_league_mode = false
	_heroes_box.add_child(_section("Held"))
	if GameState.heroes.is_empty():
		_heroes_box.add_child(_note(Language.translate(TEXT_NO_HEROES), COLOR_OUT))
	for hero in GameState.heroes:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var class_name_text: String = hero.hero_class.display_name if hero.hero_class else ""
		button.text = Language.translate("%s · %s · Lv %d") % [hero.display_name, class_name_text, hero.level]
		button.icon = hero.get_portrait()
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, class_color(hero))
		var busy: bool = GameState.is_hero_busy(hero)
		button.disabled = busy
		button.tooltip_text = Language.translate("Unterwegs") if busy else ""
		button.pressed.connect(_on_hero_chosen.bind(hero))
		_heroes_box.add_child(button)


## "Liga": a row of buttons, "Großes Turnier" (not in league-only rings) and one per league (the
## ones above the hero rank greyed out), below one line about the chosen league (entry fee, prizes)
## and, if it is closed right now, why.
func _build_mode_buttons() -> void:
	var ranking: TournamentRanking = GameState.ranking
	var league_only: bool = HeroTournament.is_league_only()
	if league_only:
		# League rings of the cities, and Eisquell once Kahn's tournament is won.
		_league_mode = true
	if _league_index < 0 or not ranking.is_league_open("hero", _league_index):
		_league_index = ranking.get_rank("hero")
	_heroes_box.add_child(_section("Liga" if league_only else "Turnier"))
	var row := HFlowContainer.new()
	if not league_only:
		row.add_child(_mode_button(Language.translate("Großes Turnier"), not _league_mode, _on_mode_chosen.bind(false, -1)))
	for index in TournamentRanking.league_count():
		var button: Button = _mode_button(ranking.shown_short_name("hero", index), _league_mode and index == _league_index,
				_on_mode_chosen.bind(true, index))
		button.disabled = not ranking.is_league_open("hero", index)
		button.tooltip_text = ranking.describe_league("hero", index)
		row.add_child(button)
	_heroes_box.add_child(row)
	if not _league_mode:
		return
	var prizes: Array[String] = []
	for place in [1, 2, 3]:
		prizes.append(str(int(TournamentRanking.get_place_prize("hero", _league_index, place).get("gold", 0))))
	_heroes_box.add_child(_note(Language.translate("Startgeld %d Gold · Preise %s Gold") % [TournamentRanking.get_entry_fee("hero", _league_index),
			" / ".join(prizes)], COLOR_OUT))
	var blocker: String = ranking.get_blocker("hero", venue, _league_index)
	if not blocker.is_empty():
		_heroes_box.add_child(_note(blocker, COLOR_BLOCKED))


func _mode_button(text: String, pressed: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = pressed
	button.text = text
	button.pressed.connect(callback)
	return button


## Small grey heading of a part of the window (German key).
func _section(text: String) -> Label:
	var label := Label.new()
	label.text = Language.translate(text)
	label.add_theme_color_override("font_color", COLOR_NEXT)
	return label


## One line of text (already translated) in `color`, wrapping.
func _note(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	return label


func _on_mode_chosen(league_mode: bool, index: int) -> void:
	_league_mode = league_mode
	if index >= 0:
		_league_index = index
	_refresh()


func _on_hero_chosen(hero: Hero) -> void:
	if _league_mode:
		if not _tournament().register_league(hero, _league_index):
			var blocker: String = GameState.ranking.get_blocker("hero", venue, _league_index)
			GameState.show_message(blocker if not blocker.is_empty() else Language.translate("%s ist gerade unterwegs.") % hero.display_name)
		return
	if not _tournament().register(hero):
		GameState.show_message(Language.translate("%s ist gerade unterwegs.") % hero.display_name)


# --- Bracket -----------------------------------------------------------------------------

## The bracket as lines (TournamentBracket): every name once on the left, the lines show who went
## how far. Names and lines in the colour of the class, the player's hero framed and drawn in
## yellow, who is out faded.
func _build_bracket() -> void:
	for child in _bracket.get_children():
		child.queue_free()
	var tournament: HeroTournament = _tournament()
	var tags: Array[Control] = []
	var colors: Array[Color] = []
	var out: Array[bool] = []
	var player: int = -1
	for entrant in tournament.entrants.size():
		var entry: Dictionary = tournament.entrants[entrant]
		var hero: Hero = entry["hero"]
		var is_out: bool = _is_out(entrant)
		if entry["player"]:
			player = entrant
		var tag: PanelContainer = name_tag(hero.display_name, class_color(hero), COLOR_PLAYER if entry["player"] else Color.TRANSPARENT,
				is_out, TournamentBracket.NAME_WIDTH - 4)
		tag.tooltip_text = _describe(hero)
		tags.append(tag)
		colors.append(COLOR_PLAYER if entry["player"] else class_color(hero))
		out.append(is_out)
	var bracket := TournamentBracket.new()
	_bracket.add_child(bracket)
	bracket.show_tournament(tournament, tags, colors, out, player)


## true = the entrant lost a fight (or the player's hero is out in the current round).
func _is_out(entrant: int) -> bool:
	var tournament: HeroTournament = _tournament()
	for index in tournament.rounds.size():
		for pair: Array in tournament.get_pairs(index):
			if pair.has(entrant):
				var winner: int = tournament.get_winner(index, pair)
				if winner >= 0 and winner != entrant:
					return true
	return tournament.entrants[entrant]["player"] and tournament.state == HeroTournament.State.LOST


## Colour of the hero's class (HeroClass.color), white without a class.
static func class_color(hero: Hero) -> Color:
	return hero.hero_class.color if hero and hero.hero_class else Color.WHITE


## A name in `color` inside a thin frame (`frame` transparent = no frame, same size, so the names
## stay in line); `faded` = out of the tournament. `max_width` > 0: a longer name is cut with "…"
## (the tooltip has it whole).
static func name_tag(text: String, color: Color, frame: Color, faded: bool = false, max_width: float = 0.0) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = frame
	style.set_border_width_all(1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	tag.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(color, OUT_ALPHA) if faded else color)
	if max_width > 0.0:
		var font: Font = label.get_theme_font("font")
		var font_size: int = label.get_theme_font_size("font_size")
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width > max_width - 6:
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.custom_minimum_size.x = max_width - 6
	tag.add_child(label)
	return tag


# --- Leaderboard -------------------------------------------------------------------------

func _on_rank_toggled(_on: bool) -> void:
	_refresh()


func _on_shop_toggled(on: bool) -> void:
	if on:
		_rank_button.set_pressed_no_signal(false)
	_refresh()


## The hero leaderboard (ArenaLeaderboard): place, name (class colour, the player framed in
## yellow), rank and RP; the card says the player's place.
func _build_leaderboard() -> void:
	for child in _leaderboard.get_children():
		child.queue_free()
	var ranking: TournamentRanking = GameState.ranking
	var list: Array[Dictionary] = ArenaLeaderboard.entries(GameState.day_cycle.day, GameState.get_player_name(),
			ranking.get_points("hero"))
	_next_label.text = Language.translate("Platz %d von %d") % [ArenaLeaderboard.player_place(list), list.size()]
	for header: String in ["Platz", "Name", "Rang", "RP"]:
		var label := Label.new()
		label.text = Language.translate(header)
		label.add_theme_color_override("font_color", COLOR_OUT)
		_leaderboard.add_child(label)
	var own_tag: Control = null
	for index in list.size():
		var entry: Dictionary = list[index]
		var player: bool = entry["player"]
		var hero_class: HeroClass = HeroClass.load_class(str(entry["class"]))
		var color: Color = hero_class.color if hero_class else Color.WHITE
		var place := Label.new()
		place.text = "%d." % (index + 1)
		_leaderboard.add_child(place)
		var tag: PanelContainer = name_tag(str(entry["name"]), color, COLOR_PLAYER if player else Color.TRANSPARENT)
		tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tag.tooltip_text = Language.translate("Deine Helden") if player else (hero_class.display_name if hero_class else "")
		_leaderboard.add_child(tag)
		if player:
			own_tag = tag
		var rank := Label.new()
		rank.text = str(entry["rank"])
		_leaderboard.add_child(rank)
		var points := Label.new()
		points.text = DamageKinds.format_number(int(entry["points"]))
		points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_leaderboard.add_child(points)
	# About 100 lines: scroll to the player's own line (after the layout has its sizes).
	var scroll := _leaderboard.get_parent().get_parent() as ScrollContainer
	if scroll and own_tag:
		_scroll_to_line.call_deferred(scroll, own_tag)


func _scroll_to_line(scroll: ScrollContainer, line: Control) -> void:
	if not is_instance_valid(scroll) or not is_instance_valid(line) or not line.is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(line):
		scroll.ensure_control_visible(line)


static func _describe(hero: Hero) -> String:
	var class_name_text: String = hero.hero_class.display_name if hero.hero_class else ""
	return "%s\n%s, Level %d\n%s" % [hero.display_name, class_name_text, hero.level, hero.get_race_line()]


func _on_fight_pressed() -> void:
	# hide(), not close(): the window is locked until the fight starts.
	hide()
	if fight_requested.get_connections().is_empty():
		_tournament().start_fight()
	else:
		fight_requested.emit()


func _on_watch_pressed() -> void:
	var duel: ArenaDuel = _tournament().duel
	close()
	if duel:
		Events.adventure_view_requested.emit(duel)


func _on_new_pressed() -> void:
	_tournament().reset()
