class_name TournamentBracket
extends Control
## Bracket of a knockout tournament drawn as lines (HeroTournamentMenu): every name stands once on
## the left (first round), from each a line runs to the right; the lines of a pair meet where they
## fight, and the winner's line goes on into the next round, up to the end of the final. A line
## is in the colour of whoever has reached it (the player's hero yellow and thicker); the part
## where somebody lost and places not decided yet are grey; whoever is out keeps his colour faded. Built in show_tournament, _draw only
## draws the stored rectangles (crisp pixel lines instead of draw_line).

## Width of the name column, of one round and of the stub after the final (px).
const NAME_WIDTH: float = 104.0
const ROUND_WIDTH: float = 22.0
const END_WIDTH: float = 14.0
## Height of one name line (px).
const ROW_HEIGHT: float = 13.0
const COLOR_OPEN: Color = Color(0.5, 0.48, 0.46, 0.45)
## How much of his colour the line of somebody who is out keeps.
const OUT_ALPHA: float = 0.4

## Lines to draw: grey ones first, coloured ones on top. Each entry: [Rect2, Color].
var _segments: Array[Array] = []


## Builds the bracket of `tournament`. `tags[i]` = name of entrant i (shown left, in first-round
## order), `colors[i]` = colour of his lines, `out[i]` = he is out (his lines faded); the lines of
## entrant `player` (-1 = none) are 2 px thick.
func show_tournament(tournament: HeroTournament, tags: Array[Control], colors: Array[Color], out: Array[bool],
		player: int) -> void:
	for child in get_children():
		child.queue_free()
	_segments.clear()
	var rounds: int = HeroTournament.round_count()
	var first: Array = tournament.rounds[0] if not tournament.rounds.is_empty() else []
	var size_first: int = first.size()
	custom_minimum_size = Vector2(NAME_WIDTH + ROUND_WIDTH * rounds + END_WIDTH, ROW_HEIGHT * size_first)
	for place in size_first:
		var slot := Control.new()
		slot.position = Vector2(0.0, ROW_HEIGHT * place)
		slot.size = Vector2(NAME_WIDTH, ROW_HEIGHT)
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		var tag: Control = tags[int(first[place])]
		tag.anchor_top = 0.5
		tag.anchor_bottom = 0.5
		tag.grow_vertical = Control.GROW_DIRECTION_BOTH
		slot.add_child(tag)
		add_child(slot)
	var grey: Array[Array] = []
	var bright: Array[Array] = []
	for index in rounds:
		var list: Array = tournament.rounds[index] if index < tournament.rounds.size() else []
		var start_x: float = NAME_WIDTH if index == 0 else _junction_x(index - 1)
		for place in size_first >> index:
			var entrant: int = int(list[place]) if place < list.size() else -1
			var y_from: float = _line_y(index, place)
			var y_to: float = _line_y(index + 1, place >> 1)
			var won: bool = false
			if entrant >= 0 and list.size() > (place | 1):
				won = tournament.get_winner(index, [list[place & ~1], list[place | 1]]) == entrant
			if entrant < 0:
				grey.append([_horizontal(start_x, _junction_x(index), y_from, 1.0), COLOR_OPEN])
				grey.append([_vertical(_junction_x(index), y_from, y_to, 1.0), COLOR_OPEN])
				continue
			var width: float = 2.0 if entrant == player else 1.0
			var color: Color = Color(colors[entrant], OUT_ALPHA) if out[entrant] else colors[entrant]
			bright.append([_horizontal(start_x, _junction_x(index), y_from, width), color])
			if won:
				bright.append([_vertical(_junction_x(index), y_from, y_to, width), color])
			else:
				grey.append([_vertical(_junction_x(index), y_from, y_to, 1.0), COLOR_OPEN])
	# After the final: the champion's line runs on a little.
	var champion: int = int(tournament.rounds[rounds][0]) if tournament.rounds.size() > rounds \
			and not (tournament.rounds[rounds] as Array).is_empty() else -1
	var end_y: float = _line_y(rounds, 0)
	if champion >= 0:
		var champion_width: float = 2.0 if champion == player else 1.0
		bright.append([_horizontal(_junction_x(rounds - 1), _junction_x(rounds - 1) + END_WIDTH, end_y, champion_width), colors[champion]])
	else:
		grey.append([_horizontal(_junction_x(rounds - 1), _junction_x(rounds - 1) + END_WIDTH, end_y, 1.0), COLOR_OPEN])
	_segments.append_array(grey)
	_segments.append_array(bright)
	queue_redraw()


## The drawn lines ([Rect2, Color], grey ones first), e.g. for tests.
func get_segments() -> Array[Array]:
	return _segments


func _draw() -> void:
	for segment: Array in _segments:
		draw_rect(segment[0], segment[1])


## x of the place where the pairs of round `index` meet.
static func _junction_x(index: int) -> float:
	return NAME_WIDTH + ROUND_WIDTH * (index + 1)


## y of place `place` in round `index` (in the middle between the two it came from).
static func _line_y(index: int, place: int) -> float:
	return floorf((place + 0.5) * ROW_HEIGHT * (1 << index))


static func _horizontal(from_x: float, to_x: float, y: float, width: float) -> Rect2:
	return Rect2(from_x, y - floorf(width / 2.0), to_x - from_x + width, width)


static func _vertical(x: float, from_y: float, to_y: float, width: float) -> Rect2:
	return Rect2(x, minf(from_y, to_y) - floorf(width / 2.0), width, absf(to_y - from_y) + width)
