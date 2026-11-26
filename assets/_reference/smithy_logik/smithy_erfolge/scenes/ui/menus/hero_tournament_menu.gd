class_name HeroTournamentMenu
extends StationMenu
## Kahn's hero tournament (HeroTournament) at the crier of the tide arena in Eisquell. Before the
## tournament: one button per hero to enter him (busy heroes are greyed out). During it: the
## bracket (one column per round, the player's hero in gold, who is out in grey) and "Kampf
## beginnen" for the next fight. The arena (WaterArena) lets both heroes step into the ring before
## the fight starts (fight_requested); without an arena the fight starts right away.
## Other venues (the duel ring of Sylvaris) use the same window with their `venue`; opening it
## there drops a bracket of another venue that is not fighting right now.
## Where there are league tournaments (TournamentRanking), buttons above the heroes choose between
## the great tournament and a league (one per rank, up to the hero rank; the text shows it). A
## prize won in a league is picked here too (PrizeChoiceList).

## "Kampf beginnen" was pressed: the arena shows both heroes, then calls start_fight().
signal fight_requested

const NAME_LENGTH: int = 14
const COLOR_PLAYER: Color = Color(1.0, 0.84, 0.35)
const COLOR_OUT: Color = Color(0.5, 0.48, 0.46)
const COLOR_NEXT: Color = Color(0.55, 0.85, 1.0)
const TEXT_CHOOSE: String = "Welchen Helden schickst du in die Arena? Er kämpft allein, vier Runden, einer gegen einen."
const TEXT_NO_HEROES: String = "Du hast keinen Helden, der antreten könnte."
const TEXT_READY: String = "%s: %s gegen %s."
const TEXT_FIGHTING: String = "%s kämpft gerade gegen %s."
const TEXT_LOST: String = "%s ist ausgeschieden. Du kannst einen Helden neu anmelden."
const TEXT_WON: String = "%s hat das Turnier gewonnen."

## Venue of this window ("" = Eisquell, otherwise a key of arena.json "venues").
@export var venue: String = ""

@onready var _text_label: Label = %TextLabel
@onready var _heroes_box: VBoxContainer = %HeroesBox
@onready var _bracket: HBoxContainer = %Bracket
@onready var _fight_button: Button = %FightButton
@onready var _watch_button: Button = %WatchButton
@onready var _new_button: Button = %NewButton

## true = the chosen hero enters a league tournament instead of the great one.
var _league_mode: bool = false
## The league chosen for the league tournament (index in leagues.json, -1 = the highest open one).
var _league_index: int = -1


func _ready() -> void:
	super()
	_fight_button.pressed.connect(_on_fight_pressed)
	_watch_button.pressed.connect(_on_watch_pressed)
	_new_button.pressed.connect(_on_new_pressed)
	%CloseButton.pressed.connect(close)
	GameState.hero_tournament.changed.connect(_refresh)
	GameState.ranking.changed.connect(_queue_refresh)
	visibility_changed.connect(_refresh)


func _tournament() -> HeroTournament:
	return GameState.hero_tournament


func _refresh() -> void:
	if not visible:
		return
	var tournament: HeroTournament = _tournament()
	if HeroTournament.venue != venue and tournament.state != HeroTournament.State.FIGHTING:
		HeroTournament.venue = venue
		tournament.reset()
		return
	var choosing: bool = tournament.state == HeroTournament.State.IDLE
	_heroes_box.visible = choosing
	_bracket.visible = not choosing
	_fight_button.visible = tournament.state == HeroTournament.State.READY
	_watch_button.visible = tournament.state == HeroTournament.State.FIGHTING
	_new_button.visible = tournament.state == HeroTournament.State.LOST or tournament.state == HeroTournament.State.WON
	if choosing:
		_build_hero_buttons()
		return
	var hero_name: String = tournament.player_hero.display_name if tournament.player_hero else "?"
	var opponent: Dictionary = tournament.get_opponent()
	var opponent_name: String = (opponent["hero"] as Hero).display_name if not opponent.is_empty() else "?"
	match tournament.state:
		HeroTournament.State.READY:
			_text_label.text = TEXT_READY % [HeroTournament.round_name(tournament.round_index), hero_name, opponent_name]
		HeroTournament.State.FIGHTING:
			_text_label.text = Language.translate(TEXT_FIGHTING) % [hero_name, opponent_name]
		HeroTournament.State.LOST:
			_text_label.text = Language.translate(TEXT_LOST) % hero_name
		HeroTournament.State.WON:
			_text_label.text = Language.translate(TEXT_WON) % hero_name
	if HeroTournament.is_league():
		_text_label.text = "%s · %s\n%s" % [TournamentRanking.league_name(HeroTournament.league),
				Language.translate("Helden-Rang: %s (%d RP)") % [GameState.ranking.get_rank_name("hero"), GameState.ranking.get_points("hero")],
				_text_label.text]
	_build_bracket()


func _build_hero_buttons() -> void:
	for child in _heroes_box.get_children():
		child.queue_free()
	_text_label.text = Language.translate(TEXT_CHOOSE) if not GameState.heroes.is_empty() else Language.translate(TEXT_NO_HEROES)
	_build_mode_buttons()
	for hero in GameState.heroes:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var class_name_text: String = hero.hero_class.display_name if hero.hero_class else ""
		button.text = Language.translate("%s · %s · Lv %d") % [hero.display_name, class_name_text, hero.level]
		button.icon = hero.get_portrait()
		var busy: bool = GameState.is_hero_busy(hero)
		button.disabled = busy
		button.tooltip_text = Language.translate("Unterwegs") if busy else ""
		button.pressed.connect(_on_hero_chosen.bind(hero))
		_heroes_box.add_child(button)


## Great tournament or a league tournament (only where leagues.json has this venue): a row of
## buttons, "Großes Turnier" and one per league up to the hero rank (higher ones greyed out). The
## text below says the entry fee and prizes of the chosen league or why it is closed.
func _build_mode_buttons() -> void:
	var ranking: TournamentRanking = GameState.ranking
	var info: String = ranking.describe("hero", venue)
	if info.is_empty():
		_league_mode = false
		return
	PrizeChoiceList.fill(_heroes_box)
	_text_label.text += "\n\n" + info
	var league_only: bool = HeroTournament.data().get("league_only", false)
	if league_only:
		# League rings of the cities (e.g. Sahrim): no great tournament here.
		_league_mode = true
	if _league_index < 0 or not ranking.is_league_open("hero", _league_index):
		_league_index = ranking.get_rank("hero")
	var row := HFlowContainer.new()
	if not league_only:
		row.add_child(_mode_button(Language.translate("Großes Turnier"), not _league_mode, _on_mode_chosen.bind(false, -1)))
	for index in TournamentRanking.league_count():
		var button: Button = _mode_button(TournamentRanking.league_short_name(index), _league_mode and index == _league_index,
				_on_mode_chosen.bind(true, index))
		button.disabled = not ranking.is_league_open("hero", index)
		button.tooltip_text = ranking.describe_league("hero", index)
		row.add_child(button)
	_heroes_box.add_child(row)
	if _league_mode:
		var blocker: String = ranking.get_blocker("hero", venue, _league_index)
		_text_label.text += "\n" + ranking.describe_league("hero", _league_index) + ("\n" + blocker if not blocker.is_empty() else "")


func _mode_button(text: String, pressed: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = pressed
	button.text = text
	button.pressed.connect(callback)
	return button


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


## One column per round: the names of the heroes still in at its start; the player's hero in gold,
## his next opponent in blue, losers of finished pairs in grey.
func _build_bracket() -> void:
	for child in _bracket.get_children():
		child.queue_free()
	var tournament: HeroTournament = _tournament()
	var next_opponent: Dictionary = tournament.get_opponent() if tournament.state == HeroTournament.State.READY \
			or tournament.state == HeroTournament.State.FIGHTING else {}
	for index in HeroTournament.round_count():
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		var header := Label.new()
		header.text = HeroTournament.round_name(index)
		header.add_theme_color_override("font_color", COLOR_NEXT if index == tournament.round_index else COLOR_OUT)
		column.add_child(header)
		for pair: Array in tournament.get_pairs(index):
			var winner: int = tournament.get_winner(index, pair)
			for entrant: int in pair:
				var label := Label.new()
				var entry: Dictionary = tournament.entrants[entrant]
				label.text = (entry["hero"] as Hero).display_name.left(NAME_LENGTH)
				label.tooltip_text = _describe(entry["hero"])
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				var color: Color = Color.WHITE
				if entry["player"]:
					color = COLOR_PLAYER
				elif entry == next_opponent:
					color = COLOR_NEXT
				if winner >= 0 and winner != entrant:
					color = COLOR_OUT
				if entry["player"] and tournament.state == HeroTournament.State.LOST and index == tournament.round_index:
					color = COLOR_OUT
				label.add_theme_color_override("font_color", color)
				column.add_child(label)
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 2)
			column.add_child(gap)
		_bracket.add_child(column)


static func _describe(hero: Hero) -> String:
	var class_name_text: String = hero.hero_class.display_name if hero.hero_class else ""
	return "%s\n%s, Level %d\n%s" % [hero.display_name, class_name_text, hero.level, hero.get_race_line()]


func _on_fight_pressed() -> void:
	close()
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
