class_name HeroTournamentMenu
extends StationMenu
## Kahn's hero tournament (HeroTournament) at the crier of the tide arena in Eisquell. Before the
## tournament: one button per hero to enter him (busy heroes are greyed out). During it: the
## bracket (one column per round, the player's hero in gold, who is out in grey) and "Kampf
## beginnen" for the next fight. The arena (WaterArena) lets both heroes step into the ring before
## the fight starts (fight_requested); without an arena the fight starts right away.
## Other venues (the duel ring of Sylvaris) use the same window with their `venue`; opening it
## there drops a bracket of another venue that is not fighting right now.
## Where there are league tournaments (TournamentRanking), two buttons above the heroes choose
## between the great tournament and today's league tournament; the text shows the hero rating.

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

## true = the chosen hero enters today's league tournament instead of the great one.
var _league_mode: bool = false


func _ready() -> void:
	super()
	_fight_button.pressed.connect(_on_fight_pressed)
	_watch_button.pressed.connect(_on_watch_pressed)
	_new_button.pressed.connect(_on_new_pressed)
	%CloseButton.pressed.connect(close)
	GameState.hero_tournament.changed.connect(_refresh)
	GameState.ranking.changed.connect(_refresh)
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
				Language.translate("Helden-Wertung: %d") % GameState.ranking.get_rating("hero"), _text_label.text]
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


## Great tournament or today's league tournament (only where leagues.json has this venue).
func _build_mode_buttons() -> void:
	var ranking: TournamentRanking = GameState.ranking
	var info: String = ranking.describe("hero", venue)
	if info.is_empty():
		_league_mode = false
		return
	_text_label.text += "\n\n" + info
	if HeroTournament.data().get("league_only", false):
		# League rings of the cities (e.g. Sahrim): no great tournament here.
		_league_mode = true
		return
	var blocker: String = ranking.get_blocker("hero", venue)
	if not blocker.is_empty():
		_league_mode = false
	var row := HBoxContainer.new()
	var today: int = ranking.get_today("hero", venue)
	for league_mode: bool in [false, true]:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = league_mode == _league_mode
		button.text = Language.translate("%s (%d Gold)") % [TournamentRanking.league_name(today), TournamentRanking.get_entry_fee("hero", today)] \
				if league_mode else Language.translate("Großes Turnier")
		button.disabled = league_mode and not blocker.is_empty()
		button.tooltip_text = blocker if league_mode else ""
		button.pressed.connect(_on_mode_chosen.bind(league_mode))
		row.add_child(button)
	_heroes_box.add_child(row)


func _on_mode_chosen(league_mode: bool) -> void:
	_league_mode = league_mode
	_refresh()


func _on_hero_chosen(hero: Hero) -> void:
	if _league_mode:
		if not _tournament().register_league(hero):
			var blocker: String = GameState.ranking.get_blocker("hero", venue)
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
