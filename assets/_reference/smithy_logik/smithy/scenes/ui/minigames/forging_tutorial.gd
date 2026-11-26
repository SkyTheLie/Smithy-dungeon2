class_name ForgingTutorial
extends Control
## Tutorial of the forging minigame, shown the first time the player forges at the anvil (and
## again with the "?" of the minigame). Lies over the ForgingMinigame (its last child) and darkens
## everything but the part it talks about (golden frame, like the Guide); the text stands on a card
## under the window.
## Steps (STEPS): three picture cards (the green spot on the piece, the timing bar with its zones,
## the quality), then a hammer shows three strikes on the real piece: one in the green, one a bit
## late in the yellow, one too late (the marker runs through), each followed by what it gave
## (sparks, "+points" floating up, the quality line). The last card says "Jetzt du!". The shown
## strikes count nothing: the minigame begins the forging fresh when `finished` comes.
## Seen once: Story.mark_hint_shown(SEEN_ID) (saved with the tips), also when skipped.

## The tutorial is over (played to the end or skipped): the real forging may begin.
signal finished

const SEEN_ID: String = "forging_tutorial"
const HAMMER: Texture2D = preload("res://assets/sprites/ui/forging_tutorial_hammer.png")
## Hammer picture: middle of the striking face (bottom of the head) and the end of the handle,
## around which it swings.
const HAMMER_FACE: Vector2 = Vector2(6, 24)
const HAMMER_PIVOT: Vector2 = Vector2(37, 12)
## Angle of the raised hammer (radians, the head goes up) and how long a swing down takes.
const HAMMER_RAISED: float = 0.6
const SWING_SECONDS: float = 0.12
## Seconds the hammer glides to its spot, and the marker's seconds per pass in the demo (slower
## than in the game, so the eye can follow).
const MOVE_SECONDS: float = 0.6
const DEMO_PASS_SECONDS: float = 2.6
## Where the yellow strike lands: this far into the right yellow zone (0 = its start, 1 = its end).
const YELLOW_DEPTH: float = 0.55
const DIM: Color = Color(0.0, 0.0, 0.0, 0.6)
const FRAME_GROW: float = 2.0
const PULSE_SPEED: float = 5.0
const FONT_SIZE: int = 11
const CARD_GAP: float = 4.0

## "focus": the parts that stay bright ("piece", "bar", "quality"), "demo": the strike the hammer
## shows ("green", "yellow", "late"), "arrow": points at the quality after the strike.
## Texts: "before" while the hammer waits, "text" (with %+d = the points of the strike) after.
const STEPS: Array[Dictionary] = [
	{"title": "Der Schlagpunkt", "focus": ["piece"],
		"text": "Auf dem glühenden Stück leuchtet ein grüner Kreis. Dorthin schlägst du: Klick mit der linken Maustaste genau auf den Kreis."},
	{"title": "Der Takt", "focus": ["bar"],
		"text": "Darunter läuft ein Zeiger von links nach rechts. Klick, während er im grünen Feld steht. Gelb geht auch, bringt aber weniger."},
	{"title": "Die Qualität", "focus": ["quality"],
		"text": "Jeder Schlag gibt oder kostet Qualitätspunkte. Über 100 steigt das Stück eine Seltenheit auf, unter 0 fällt es eine ab."},
	{"title": "Schau zu (1/3)", "focus": ["piece", "bar"], "demo": "green", "arrow": true,
		"before": "Der Hammer wartet, bis der Zeiger mitten im Grünen steht …",
		"text": "Perfekt! Im Grünen gibt es die meisten Punkte: %+d Qualität."},
	{"title": "Schau zu (2/3)", "focus": ["piece", "bar"], "demo": "yellow", "arrow": true,
		"before": "Jetzt schlägt er ein bisschen zu spät …",
		"text": "Gut. Im Gelben gibt es nur %+d Qualität."},
	{"title": "Schau zu (3/3)", "focus": ["piece", "bar"], "demo": "late", "arrow": true,
		"before": "Und jetzt wartet er zu lange …",
		"text": "Zu spät! Der Zeiger ist durchgelaufen: %+d Qualität. Genauso, wenn du neben den Kreis oder ins Graue klickst."},
	{"title": "Jetzt du!", "focus": ["quality"], "last": true,
		"text": "Oben siehst du die Qualität und die Seltenheit, die das Stück gerade bekommt. Mit dem ? siehst du diese Anleitung noch einmal."},
]

enum Demo { NONE, MOVE, RUN, SWING, SHOWN }

var _minigame: ForgingMinigame
var _step: int = -1
var _demo: Demo = Demo.NONE
## Seconds in the current demo phase, and since the tutorial began (pulse, card 2 marker).
var _phase_time: float = 0.0
var _time: float = 0.0
## Index of the strike the hammer shows (0, 1, 2 = its spot on the piece).
var _demo_index: int = 0
var _hammer_from: Vector2 = Vector2.ZERO
## Hammer: where the middle of its face is (in this Control) and its angle.
var _hammer_at: Vector2 = Vector2.ZERO
var _hammer_angle: float = HAMMER_RAISED
var _hammer_shown: bool = false
## Layout of the current step, worked out once (_lay_out), not in _draw: the bright parts, the
## dark rectangles around them and the timing bar.
var _holes: Array[Rect2] = []
var _dim_rects: Array[Rect2] = []
var _bar_rect: Rect2 = Rect2()
## Where the minigame window stood when the card was placed last (it can be dragged).
var _window_at: Vector2 = Vector2.INF

@onready var _card: PanelContainer = %Card
@onready var _title: Label = %CardTitle
@onready var _text: Label = %CardText
@onready var _next_button: Button = %NextButton
@onready var _skip_button: Button = %SkipButton


static func was_seen() -> bool:
	return GameState.story.was_hint_shown(SEEN_ID)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_button.pressed.connect(next)
	_skip_button.pressed.connect(skip)
	_skip_button.text = Language.translate("Überspringen")
	resized.connect(_lay_out)
	hide()


func is_playing() -> bool:
	return _step >= 0


## Starts with the first card; the minigame shows a fresh piece and nothing runs.
func play(minigame: ForgingMinigame) -> void:
	_minigame = minigame
	_time = 0.0
	show()
	_go_to(0)
	_lay_out.call_deferred()  # the window may not be laid out yet in its first frame


## Next card (button "Weiter"); after the last one the tutorial ends.
func next() -> void:
	if not is_playing():
		return
	if _step + 1 >= STEPS.size():
		_end()
	else:
		_go_to(_step + 1)


func skip() -> void:
	if is_playing():
		_end()


## The window was closed: stop without `finished`, the tutorial counts as seen only once it ended.
func cancel() -> void:
	_step = -1
	_demo = Demo.NONE
	hide()


## Current step (0 = first card, -1 = not playing) and whether the shown strike is done.
func get_step() -> int:
	return _step


func is_demo_waiting() -> bool:
	return _demo != Demo.NONE and _demo != Demo.SHOWN


## Screen position of the hammer's striking face (middle of the bottom of its head).
func get_hammer_face() -> Vector2:
	return get_global_transform() * _hammer_at


func _end() -> void:
	cancel()
	GameState.story.mark_hint_shown(SEEN_ID)
	finished.emit()


func _go_to(index: int) -> void:
	_step = index
	var step: Dictionary = STEPS[index]
	_title.text = Language.translate(step["title"])
	_hammer_shown = step.has("demo")
	_minigame.get_workpiece().hide_strike()
	_minigame.get_timing_bar().marker = 0.0
	if step.has("demo"):
		_demo_index = int(STEPS.slice(0, index).filter(func(s: Dictionary) -> bool: return s.has("demo")).size())
		_demo = Demo.MOVE
		_phase_time = 0.0
		_hammer_from = _hammer_at if index > 0 and STEPS[index - 1].has("demo") else Vector2(size.x + 20.0, _spot(_demo_index).y - 30.0)
		_hammer_angle = HAMMER_RAISED
		_minigame.get_workpiece().show_strike(_demo_index)
		_text.text = Language.translate(step["before"])
	else:
		_demo = Demo.NONE
		_text.text = Language.translate(step["text"])
		if step["focus"].has("piece"):
			_minigame.get_workpiece().show_strike(0)
	_next_button.text = Language.translate("Los geht's!") if step.get("last", false) else Language.translate("Weiter")
	_next_button.disabled = _demo != Demo.NONE
	_skip_button.visible = not step.get("last", false)
	_lay_out()


func _process(delta: float) -> void:
	if not is_playing():
		return
	_time += delta
	_phase_time += delta
	var step: Dictionary = STEPS[_step]
	var bar: TimingBar = _minigame.get_timing_bar()
	if _demo == Demo.NONE and step["focus"].has("bar"):
		bar.marker = fmod(_time / DEMO_PASS_SECONDS, 1.0)
	match _demo:
		Demo.MOVE:
			var t: float = minf(_phase_time / MOVE_SECONDS, 1.0)
			_hammer_at = _hammer_from.lerp(_spot(_demo_index), ease(t, -2.0))
			if t >= 1.0:
				_set_demo(Demo.RUN)
		Demo.RUN:
			bar.marker = minf(bar.marker + delta / DEMO_PASS_SECONDS, 1.0)
			_hammer_angle = HAMMER_RAISED + sin(_phase_time * 4.0) * 0.05
			if bar.marker >= _target(step["demo"]):
				if step["demo"] == "late":
					_strike()  # no swing: the marker ran through
				else:
					_set_demo(Demo.SWING)
		Demo.SWING:
			var t: float = minf(_phase_time / SWING_SECONDS, 1.0)
			_hammer_angle = lerpf(HAMMER_RAISED, 0.0, t * t)
			if t >= 1.0:
				_strike()
		Demo.SHOWN:
			_hammer_angle = lerpf(_hammer_angle, 0.25, minf(delta * 8.0, 1.0))
	var window := get_parent() as Control
	if window and window.global_position != _window_at:
		_place_card()
	queue_redraw()


## Marker position at which the hammer strikes ("late": the end of the bar).
func _target(kind: String) -> float:
	var bar: TimingBar = _minigame.get_timing_bar()
	match kind:
		"green":
			return bar.center
		"yellow":
			return bar.center + bar.green_width / 2.0 + bar.yellow_width * YELLOW_DEPTH
	return 1.0


func _strike() -> void:
	var step: Dictionary = STEPS[_step]
	var bar: TimingBar = _minigame.get_timing_bar()
	var zone: TimingBar.Zone = TimingBar.Zone.MISS if step["demo"] == "late" else bar.get_zone(bar.marker)
	var points: int = _minigame.demo_strike(zone, Language.translate("Zu spät") if step["demo"] == "late" else "")
	_minigame.get_workpiece().hide_strike()
	_text.text = Language.translate(step["text"]) % points
	_set_demo(Demo.SHOWN)
	_next_button.disabled = false


func _set_demo(phase: Demo) -> void:
	_demo = phase
	_phase_time = 0.0


## Middle of the spot of strike `index`, in this Control.
func _spot(index: int) -> Vector2:
	var piece: ForgingWorkpiece = _minigame.get_workpiece()
	return _to_local(piece, piece.get_spot_rect(index).get_center())


## A point of another Control (in its own coordinates) in this Control. Goes through the real
## transforms: on the phone the window is scaled (MobileUi), global distances are larger there.
func _to_local(control: Control, point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * (control.get_global_transform() * point)


## The area of a part of the minigame, in this Control.
func _focus_rect(part: String) -> Rect2:
	var controls: Array[Control] = []
	match part:
		"piece":
			controls.append(_minigame.get_workpiece())
		"bar":
			controls.append(_minigame.get_timing_bar())
		"quality":
			controls.assign(_minigame.get_quality_labels())
	var area := Rect2()
	for control in controls:
		var rect := Rect2(_to_local(control, Vector2.ZERO), Vector2.ZERO).expand(_to_local(control, control.size))
		area = rect if not area.has_area() else area.merge(rect)
	return area.grow(FRAME_GROW)


## The card under the minigame window (above it if there is no room), inside the screen.
func _place_card() -> void:
	var window := get_parent() as Control
	if window == null:
		return
	_card.reset_size()
	# Global sizes: on the phone the window and the card are scaled (MobileUi).
	var screen: Vector2 = get_viewport_rect().size
	var window_rect: Rect2 = window.get_global_rect()
	var card_size: Vector2 = _card.get_global_rect().size
	var top_left := window_rect.position
	var at := Vector2(top_left.x + (window_rect.size.x - card_size.x) / 2.0, window_rect.end.y + CARD_GAP)
	if at.y + card_size.y > screen.y:
		at.y = top_left.y - card_size.y - CARD_GAP
	_window_at = window.global_position
	_card.global_position = at.clamp(Vector2.ZERO, (screen - card_size).max(Vector2.ZERO)).round()


# --- Drawing ------------------------------------------------------------------------

## Works out the bright parts of the current step and the dark rectangles around them.
func _lay_out() -> void:
	if not is_playing():
		return
	_holes.clear()
	for part: String in STEPS[_step]["focus"]:
		_holes.append(_focus_rect(part))
	_bar_rect = _focus_rect("bar")
	_dim_rects.clear()
	var cuts: Array[float] = [0.0, size.y]
	for hole in _holes:
		cuts.append(clampf(hole.position.y, 0.0, size.y))
		cuts.append(clampf(hole.end.y, 0.0, size.y))
	cuts.sort()
	for i in cuts.size() - 1:
		var top: float = cuts[i]
		var bottom: float = cuts[i + 1]
		if bottom <= top:
			continue
		var spans: Array[Rect2] = []
		for hole in _holes:
			if hole.position.y <= top and hole.end.y >= bottom:
				spans.append(hole)
		spans.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		var x: float = 0.0
		for hole in spans:
			if hole.position.x > x:
				_dim_rects.append(Rect2(x, top, hole.position.x - x, bottom - top))
			x = maxf(x, hole.end.x)
		if x < size.x:
			_dim_rects.append(Rect2(x, top, size.x - x, bottom - top))
	_window_at = Vector2.INF
	_place_card()
	queue_redraw()


func _draw() -> void:
	if not is_playing():
		return
	var step: Dictionary = STEPS[_step]
	for rect in _dim_rects:
		draw_rect(rect, DIM)
	var pulse: float = 0.6 + 0.4 * sin(_time * PULSE_SPEED)
	for hole in _holes:
		draw_rect(hole, Color(GuideFrame.COLOR, pulse), false, 1.0)
	if step["focus"].has("bar") and not step.has("demo"):
		_draw_zone_labels()
	if step.get("arrow", false) and _demo == Demo.SHOWN:
		_draw_quality_arrow()
	if _hammer_shown:
		var face_offset: Vector2 = (HAMMER_FACE - HAMMER_PIVOT).rotated(_hammer_angle)
		var pivot: Vector2 = (_hammer_at - face_offset).round()
		draw_set_transform(pivot, _hammer_angle)
		draw_texture(HAMMER, -HAMMER_PIVOT)
		draw_set_transform(Vector2.ZERO)


## "Perfekt", "Gut" and "Daneben" above the zones of the timing bar, each with a small line down.
func _draw_zone_labels() -> void:
	var bar: TimingBar = _minigame.get_timing_bar()
	var area: Rect2 = _bar_rect.grow(-FRAME_GROW)
	var font: Font = get_theme_default_font()
	var green_x: float = area.position.x + area.size.x * bar.center
	var yellow_x: float = area.position.x + area.size.x * (bar.center + bar.green_width / 2.0 + bar.yellow_width / 2.0)
	var miss_x: float = area.position.x + area.size.x * 0.18
	var y: float = area.position.y - 3.0
	_draw_label(font, Language.translate("Perfekt"), Vector2(green_x, y - 16.0), Color(TimingBar.COLOR_GREEN, 1.0).lightened(0.3), green_x)
	_draw_label(font, Language.translate("Gut"), Vector2(yellow_x + 14.0, y - 6.0), TimingBar.COLOR_YELLOW, yellow_x)
	_draw_label(font, Language.translate("Daneben"), Vector2(miss_x, y - 6.0), ForgingWorkpiece.COLOR_MISS, miss_x)


func _draw_label(font: Font, text: String, at: Vector2, color: Color, line_x: float) -> void:
	var bar_top: float = _bar_rect.position.y + FRAME_GROW
	draw_line(Vector2(line_x, at.y + 1.0).round(), Vector2(line_x, bar_top).round(), Color(color, 0.8), 1.0)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var pos := Vector2(at.x - width / 2.0, at.y).round()
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, 1.0))


## A small golden arrow left of the quality line (it changed with the strike).
func _draw_quality_arrow() -> void:
	var labels: Array[Control] = _minigame.get_quality_labels()
	var label := labels[0] as Label
	var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size("font_size")).x
	var mid := _to_local(label, Vector2((label.size.x - text_width) / 2.0 - 4.0, label.size.y / 2.0))
	var nudge: float = absf(sin(_time * PULSE_SPEED)) * 2.0
	var tip := Vector2(mid.x - nudge, mid.y).round()
	var color := Color(GuideFrame.COLOR, 1.0)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-6, -4), tip + Vector2(-6, 4)]), color)
	draw_rect(Rect2(tip + Vector2(-12, -1), Vector2(6, 3)), color)
