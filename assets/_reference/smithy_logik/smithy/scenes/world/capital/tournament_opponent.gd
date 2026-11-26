class_name TournamentOpponent
extends Node2D
## The other smith on the tournament ground (SmithTournament): looks like the opponent of the
## current round ("opponent_look") and works through his plan (SmithTournament.opponent_plan):
## to his chest for the material, the ore into the smelter, cast, forge, quench, and at the
## workbench carve the shaft and put the piece together. An experienced opponent takes everything
## from the chest at once and carves the shaft while the ore melts. Above his head stands what he
## is doing right now. Only for show, his score is simulated.

## His stations (scene coordinates of the parent) in this order: smelter, forge, anvil, trough,
## workbench, grindstone, polishing table, tanning rack. He stands there while he works.
@export var stops: PackedVector2Array = []
## Where he stands at his supply chest.
@export var chest_spot: Vector2 = Vector2.ZERO
## Where he stands between rounds.
@export var idle_spot: Vector2 = Vector2.ZERO

## Plan stops (SmithTournament.build_opponent_plan) in the order of `stops`.
const STOP_NAMES: Array[String] = ["smelter", "forge", "anvil", "trough", "workbench", "grindstone",
		"polishing_table", "tanning_rack"]
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


## Where the plan stop `stop` is (idle_spot if the scene has no such place).
func get_stop_position(stop: String) -> Vector2:
	if stop == "chest":
		return chest_spot if chest_spot != Vector2.ZERO else idle_spot
	var index: int = STOP_NAMES.find(stop)
	if index < 0 or stops.is_empty():
		return idle_spot
	return stops[mini(index, stops.size() - 1)]


func _process(delta: float) -> void:
	if not visible:
		return
	var tournament: SmithTournament = GameState.tournament
	var running: bool = tournament.state == SmithTournament.State.RUNNING
	var target: Vector2 = idle_spot
	var text: String = tournament.get_opponent_name()
	var step: Dictionary = tournament.get_opponent_step()
	if running and not step.is_empty():
		target = get_stop_position(str(step["stop"]))
		text = Language.translate(str(step["text"]))
	elif running:
		# Done: he waits at the workbench with his piece.
		target = get_stop_position("workbench")
		text = Language.translate(DONE_TEXT)
	_label.text = text
	var offset: Vector2 = target - position
	if offset.length() > 1.0:
		position += offset.limit_length(WALK_SPEED * delta)
		_sprite.play("walk_" + Companion._direction_name(offset))
		return
	_sprite.play("idle_up" if running and not step.is_empty() else "idle_down")
	# At the anvil a hammer rings now and then.
	if running and str(step.get("stop", "")) == "anvil" and not step.get("walk", false):
		_hammer_wait -= delta
		if _hammer_wait <= 0.0:
			_hammer_wait = randf_range(1.2, 2.0)
			AudioManager.play_sound("anvil_good", randf_range(0.8, 0.9))
