class_name TournamentOpponent
extends Node2D
## The other smith on the tournament ground (SmithTournament): looks like the opponent of the
## current round (economy.json "smith_tournament" "opponent_look") and walks from station to
## station while the round runs, as far as his work has come (get_opponent_progress). Above his
## head stands what he is doing right now. Only for show, his score is simulated.

## His stations in work order (scene coordinates of the parent): smelter, forge, anvil, trough,
## workbench. The last stop is where he waits when he is done.
@export var stops: PackedVector2Array = []
## Where he stands between rounds.
@export var idle_spot: Vector2 = Vector2.ZERO

const WORK: Array[String] = ["schmilzt Erz", "gießt", "schmiedet", "kühlt ab", "baut zusammen"]
const DONE_TEXT: String = "fertig!"
const WALK_SPEED: float = 60.0

var _sprite: AnimatedSprite2D
var _label: Label
var _round: int = -1
var _hammer_wait: float = 0.0


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.position = Vector2(0, -13)
	add_child(_sprite)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_outline_color", Color(0.13, 0.075, 0.12))
	_label.add_theme_constant_override("outline_size", 2)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-60, -44)
	_label.size = Vector2(120, 12)
	add_child(_label)
	position = idle_spot
	GameState.tournament.changed.connect(_update_look)
	_update_look()


func _update_look() -> void:
	var tournament: SmithTournament = GameState.tournament
	visible = tournament.is_active()
	if not visible or tournament.round_index == _round:
		return
	_round = tournament.round_index
	var look: Appearance = Appearance.from_save_data(tournament.get_round().get("opponent_look", {}))
	_sprite.sprite_frames = CharacterBaker.make_frames(CharacterBaker.get_sheet(look))
	_sprite.scale = Vector2.ONE * look.get_scale()
	_sprite.play("idle_down")
	position = idle_spot


func _process(delta: float) -> void:
	var tournament: SmithTournament = GameState.tournament
	if not visible:
		return
	var target: Vector2 = idle_spot
	var text: String = tournament.get_opponent_name()
	if tournament.state == SmithTournament.State.RUNNING and not stops.is_empty():
		var progress: float = tournament.get_opponent_progress()
		var stop: int = mini(floori(progress * WORK.size()), WORK.size() - 1)
		target = stops[mini(stop, stops.size() - 1)]
		text = DONE_TEXT if progress >= 1.0 else Language.translate(WORK[stop])
	_label.text = text
	var offset: Vector2 = target - position
	if offset.length() > 1.0:
		position += offset.limit_length(WALK_SPEED * delta)
		_sprite.play("walk_" + Companion._direction_name(offset))
		return
	_sprite.play("idle_up" if tournament.state == SmithTournament.State.RUNNING else "idle_down")
	# At the anvil a hammer rings now and then.
	if tournament.state == SmithTournament.State.RUNNING and text == Language.translate(WORK[2]):
		_hammer_wait -= delta
		if _hammer_wait <= 0.0:
			_hammer_wait = randf_range(1.2, 2.0)
			AudioManager.play_sound("anvil_good", randf_range(0.8, 0.9))
