class_name BattleVfx
extends RefCounted
## Short effects on the BattleStage in any colour (element, damage kind or status effect): a slash
## arc, a stab streak, sparks, a flying arrow or magic bolt, rising heal crosses, arrows up (buff)
## or down (debuff), a ring (spell leaves the hand). The stage spawns them and draws them on top of
## the fighters. A kind with a sprite sheet in SHEET_DIR (<kind>.png + <kind>.json, exported from
## the PixelLab VFX workbench in white/grey) plays its frames tinted in the colour; a sheet in
## SHEET_DIR/color/ is already coloured (elements, auras, areas) and only takes the alpha; kinds
## without a sheet are drawn from simple pixel shapes. Per element there are "<element>_bolt"
## (flies) and "<element>_hit" (element_kind picks them), area skills play one "area_*" sheet
## over the whole group, status effects loop an "aura_*" sheet at the feet (draw_loop), the stage
## also loops "shield" and "stun" on fighters.

## Effects drawn from shapes when they have no sheet, used in skills.json "vfx" ("none" = no
## effect). Every other kind needs a sheet (is_kind).
const KINDS: Array[String] = ["slash", "pierce", "impact", "arrow", "bolt", "heal", "buff", "debuff", "glow", "claw", "none"]
## "claw": three slashes side by side (claws and bites of animals), offsets from the hit point.
const CLAW_OFFSETS: Array[Vector2] = [Vector2(-4, -5), Vector2(0, 0), Vector2(4, 5)]
## Area effect of an area skill (target all enemies) by its main damage kind; skills.json
## "area_vfx" overrides it.
const AREA_KINDS: Dictionary = {"fire": "area_fire", "earth": "area_quake", "lightning": "area_thunder",
		"ice": "area_nova", "water": "area_ice", "air": "area_storm", "poison": "area_poison", "dark": "area_shadow", "light": "area_holy"}
## Where an area sheet's pivot sits above the ground point (clouds have their pivot in the middle).
const AREA_OFFSET: Dictionary = {"area_poison": Vector2(0, -16), "area_shadow": Vector2(0, -14)}
## The meteor falls from up here (relative to where it lands, x towards the caster) for this long.
const METEOR_FROM: Vector2 = Vector2(-70, -110)
const METEOR_FALL: float = 0.35
## Seconds per effect (arrow and bolt: their flight time, set by the stage).
const LENGTH: Dictionary = {"slash": 0.22, "pierce": 0.18, "impact": 0.3, "heal": 0.75, "buff": 0.7,
		"debuff": 0.7, "glow": 0.3}
const SLASH_RADIUS: float = 10.0
## Slash from behind-above over the top to in front-below (degrees, 0 = right, -90 = up).
const SLASH_FROM: float = -150.0
const SLASH_TO: float = 60.0
const COLOR_SHAFT: Color = Color(0.55, 0.38, 0.22)
const COLOR_CORE: Color = Color(1.0, 1.0, 0.95)
## Sprite sheets of the effects (Aseprite-style JSON: frames with rect, pivot and duration).
const SHEET_DIR: String = "res://assets/sprites/battle/vfx/"
## Where a sheet's pivot sits relative to the spawn point (heal/buff/debuff: around the feet, so
## the signs rise over the body instead of starting at the chest).
const SHEET_OFFSET: Dictionary = {"heal": Vector2(0, 8), "buff": Vector2(0, 10), "debuff": Vector2(0, 10)}

## Loaded sheets: kind -> {"texture", "frames": Array[Rect2] (blank frames at the start and end
## left out), "pivot": Vector2, "fps": float, "colored": bool, "depth": "behind" | "front" | "both"};
## {} = no sheet for this kind.
static var _sheets: Dictionary = {}

## {"kind", "at", "from", "color", "facing" (1 = right, -1 = left), "age", "length", "seed", "rotate"}.
var _effects: Array[Dictionary] = []
## Where the canvas draws from (the stage's shake), needed to turn a flying sheet.
var offset: Vector2 = Vector2.ZERO


## Effect `kind` at `at` (the target's middle). `facing` = which way the attacker looks. Flying
## ones (arrow, bolts) start at `from` and arrive at `at` after `length` seconds; `rotate` turns a
## flying sheet along its path (a meteor falling). A sheet without a set length plays all its frames once.
func spawn(kind: String, at: Vector2, color: Color, facing: float = 1.0, from: Vector2 = Vector2.ZERO, length: float = 0.0,
		rotate: bool = false) -> void:
	if kind.is_empty() or kind == "none" or not is_kind(kind):
		return
	if kind == "claw":
		for claw_offset in CLAW_OFFSETS:
			spawn("slash", at + claw_offset * Vector2(facing, 1.0), color, facing)
		return
	if length <= 0.0:
		var sheet: Dictionary = get_sheet(kind)
		length = LENGTH.get(kind, sheet["frames"].size() / sheet["fps"] if not sheet.is_empty() else 0.3)
	_effects.append({"kind": kind, "at": at, "from": from, "color": color, "facing": facing, "age": 0.0,
			"length": length, "seed": randf() * TAU, "rotate": rotate})


## A known effect: drawn from shapes (KINDS) or with a sheet.
static func is_kind(kind: String) -> bool:
	return KINDS.has(kind) or not get_sheet(kind).is_empty()


## Kinds that fly from the attacker to the target.
static func is_flying(kind: String) -> bool:
	return kind == "arrow" or kind == "bolt" or kind.ends_with("_bolt")


## The element's own effect instead of a plain one: "bolt" -> "fire_bolt", "impact" -> "fire_hit"
## (if that sheet exists), anything else stays.
static func element_kind(kind: String, damage_kind: String) -> String:
	var own: String = ""
	if kind == "bolt":
		own = damage_kind + "_bolt"
	elif kind == "impact":
		own = damage_kind + "_hit"
	return own if not own.is_empty() and not get_sheet(own).is_empty() else kind


## How long a sheet plays once (seconds), 0 = no sheet.
static func get_length(kind: String) -> float:
	var sheet: Dictionary = get_sheet(kind)
	return sheet["frames"].size() / sheet["fps"] if not sheet.is_empty() else 0.0


func clear() -> void:
	_effects.clear()


func tick(delta: float) -> void:
	for effect in _effects:
		effect["age"] += delta
	_effects = _effects.filter(func(effect: Dictionary) -> bool: return effect["age"] < effect["length"])


func draw(canvas: CanvasItem) -> void:
	for effect in _effects:
		var progress: float = clampf(effect["age"] / effect["length"], 0.0, 1.0)
		var color: Color = effect["color"]
		if _draw_from_sheet(canvas, effect, progress, color):
			continue
		match effect["kind"]:
			"slash":
				_draw_slash(canvas, effect, progress, color)
			"pierce":
				_draw_pierce(canvas, effect, progress, color)
			"impact":
				_draw_impact(canvas, effect, progress, color)
			"arrow":
				_draw_arrow(canvas, effect, progress, color)
			"bolt":
				_draw_bolt(canvas, effect, progress, color)
			"heal":
				_draw_rising(canvas, effect, progress, color, "plus")
			"buff":
				_draw_rising(canvas, effect, progress, color, "up")
			"debuff":
				_draw_rising(canvas, effect, progress, color, "down")
			"glow":
				_draw_glow(canvas, effect, progress, color)


## The effect from its sheet: one-shots run through their frames once over the effect's length,
## the flying bolt loops its frames along the flight. false = no sheet for this kind.
func _draw_from_sheet(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> bool:
	var kind: String = effect["kind"]
	var sheet: Dictionary = get_sheet(kind)
	if sheet.is_empty():
		return false
	var frames: Array = sheet["frames"]
	var at: Vector2 = effect["at"]
	var frame: int
	if is_flying(kind):
		var arc: float = 0.0 if effect["rotate"] else 3.0
		at = _get_flight_position(effect, progress, arc)
		frame = int(effect["age"] * sheet["fps"]) % frames.size()
		if effect["rotate"]:
			# Turned along the path (the sheets fly to the right); drawn around the pivot.
			var direction: Vector2 = effect["at"] - effect["from"]
			canvas.draw_set_transform(offset + at.round(), direction.angle())
			draw_sheet_frame(canvas, sheet, frame, Vector2.ZERO, color)
			canvas.draw_set_transform(offset)
			return true
	else:
		frame = mini(int(progress * frames.size()), frames.size() - 1)
	draw_sheet_frame(canvas, sheet, frame, at + SHEET_OFFSET.get(kind, Vector2.ZERO), color, effect["facing"])
	return true


## A looping sheet (e.g. "shield", "stun") at `at`, its frame from `time` (seconds). false = no sheet.
static func draw_loop(canvas: CanvasItem, kind: String, at: Vector2, time: float, color: Color) -> bool:
	var sheet: Dictionary = get_sheet(kind)
	if sheet.is_empty():
		return false
	var frames: Array = sheet["frames"]
	draw_sheet_frame(canvas, sheet, int(time * sheet["fps"]) % frames.size(), at, color)
	return true


## Behind the fighter ("behind") or over it, from the sheet's export.
static func get_depth(kind: String) -> String:
	return get_sheet(kind).get("depth", "front")


## One frame with its pivot on `at`, tinted (the white/grey sheets; coloured ones only take the
## alpha), mirrored for `facing` < 0.
static func draw_sheet_frame(canvas: CanvasItem, sheet: Dictionary, frame: int, at: Vector2, color: Color,
		facing: float = 1.0) -> void:
	var region: Rect2 = sheet["frames"][frame]
	var pivot: Vector2 = sheet["pivot"]
	var origin: Vector2 = at.round() - Vector2(pivot.x * facing, pivot.y)
	# A negative width draws the picture mirrored.
	var target := Rect2(origin, Vector2(region.size.x * facing, region.size.y))
	if sheet["colored"]:
		color = Color(1.0, 1.0, 1.0, color.a)
	canvas.draw_texture_rect_region(sheet["texture"], target, region, color)


## The sheet of an effect kind, loaded once ({} = none, the effect is drawn from shapes).
static func get_sheet(kind: String) -> Dictionary:
	if not _sheets.has(kind):
		_sheets[kind] = _load_sheet(kind, true)
		if _sheets[kind].is_empty():
			_sheets[kind] = _load_sheet(kind, false)
	return _sheets[kind]


static func _load_sheet(kind: String, colored: bool) -> Dictionary:
	var dir: String = SHEET_DIR + ("color/" if colored else "")
	var png: String = dir + kind + ".png"
	var json_path: String = dir + kind + ".json"
	if not ResourceLoader.exists(png) or not FileAccess.file_exists(json_path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not data is Dictionary or (data as Dictionary).get("frames", []).is_empty():
		return {}
	var texture: Texture2D = load(png)
	var image: Image = texture.get_image()
	var frames: Array[Rect2] = []
	var first: Dictionary = data["frames"][0]
	for entry: Dictionary in data["frames"]:
		var rect: Dictionary = entry["frame"]
		frames.append(Rect2(rect["x"], rect["y"], rect["w"], rect["h"]))
	# One-shots often start or end with empty frames (dead time in a short effect).
	while frames.size() > 1 and image.get_region(Rect2i(frames.back())).is_invisible():
		frames.pop_back()
	while frames.size() > 1 and image.get_region(Rect2i(frames.front())).is_invisible():
		frames.pop_front()
	var size: Dictionary = first["sourceSize"]
	var pivot: Dictionary = first.get("pivot", {"x": 0.5, "y": 0.5})
	return {"texture": texture, "frames": frames,
			"pivot": Vector2(roundf(pivot["x"] * size["w"]), roundf(pivot["y"] * size["h"])),
			"fps": 1000.0 / maxf(float(first.get("duration", 83)), 1.0), "colored": colored,
			"depth": data.get("meta", {}).get("depth", "front")}


## Arc whose head runs ahead and whose tail follows (mirrored for an attacker looking left).
func _draw_slash(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	var head: float = lerpf(SLASH_FROM, SLASH_TO, minf(progress * 1.6, 1.0))
	var tail: float = lerpf(SLASH_FROM, SLASH_TO, clampf((progress - 0.35) * 1.6, 0.0, 1.0))
	if effect["facing"] < 0.0:
		head = 180.0 - head
		tail = 180.0 - tail
	color.a = 1.0 - progress * progress
	canvas.draw_arc(effect["at"], SLASH_RADIUS, deg_to_rad(tail), deg_to_rad(head), 10, color, 2.0)
	canvas.draw_arc(effect["at"], SLASH_RADIUS - 2.0, deg_to_rad(tail), deg_to_rad(head), 10, Color(COLOR_CORE, color.a * 0.6), 1.0)


## Three streaks shooting through the target.
func _draw_pierce(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	var facing: float = effect["facing"]
	var at: Vector2 = effect["at"]
	color.a = 1.0 - progress
	for row in [-3.0, 0.0, 3.0]:
		var length: float = (8.0 if row == 0.0 else 5.0) * (1.0 - progress * 0.6)
		var front: float = at.x + facing * (-6.0 + 16.0 * progress)
		canvas.draw_line(Vector2(roundf(front - facing * length), at.y + row), Vector2(roundf(front), at.y + row), color, 1.0)


## Sparks flying out in all directions.
func _draw_impact(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	var distance: float = 2.0 + 10.0 * (1.0 - pow(1.0 - progress, 2.0))
	var size: float = 2.0 if progress < 0.5 else 1.0
	color.a = 1.0 - progress
	for i in 6:
		var angle: float = effect["seed"] + i * TAU / 6.0
		var spot: Vector2 = (effect["at"] + Vector2.from_angle(angle) * distance).round()
		canvas.draw_rect(Rect2(spot - Vector2(size, size) / 2.0, Vector2(size, size)), color)


func _get_flight_position(effect: Dictionary, progress: float, arc: float) -> Vector2:
	return effect["from"].lerp(effect["at"], progress) + Vector2(0.0, -arc * sin(PI * progress))


## An arrow on a flat arc: wooden shaft, tip in the colour.
func _draw_arrow(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	var at: Vector2 = _get_flight_position(effect, progress, 6.0)
	var ahead: Vector2 = _get_flight_position(effect, minf(progress + 0.05, 1.0), 6.0)
	var direction: Vector2 = (ahead - at).normalized() if ahead != at else Vector2(effect["facing"], 0.0)
	at = at.round()
	canvas.draw_line(at - direction * 6.0, at, COLOR_SHAFT, 1.0)
	canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), color)


## A glowing ball with a short trail.
func _draw_bolt(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	for step in [0.16, 0.08]:
		var trail: Vector2 = _get_flight_position(effect, maxf(progress - step, 0.0), 3.0).round()
		canvas.draw_circle(trail, 2.0 - step * 6.0, Color(color, 0.5))
	var at: Vector2 = _get_flight_position(effect, progress, 3.0).round()
	canvas.draw_circle(at, 3.0, color)
	canvas.draw_circle(at, 1.5, COLOR_CORE)


## Four small signs next to each other, one after another: crosses (heal) and arrows (buff) rise,
## arrows down (debuff) sink.
func _draw_rising(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color, shape: String) -> void:
	var offsets: Array[float] = [-7.0, 2.0, -2.0, 7.0]
	for i in offsets.size():
		var own: float = clampf((progress - i * 0.12) / 0.64, 0.0, 1.0)
		if own <= 0.0 or own >= 1.0:
			continue
		var rise: float = 14.0 * own
		var center: Vector2 = effect["at"] + Vector2(offsets[i], (6.0 - rise) if shape != "down" else (-12.0 + rise))
		center = center.round()
		var faded := Color(color, 1.0 - own * own)
		match shape:
			"plus":
				canvas.draw_rect(Rect2(center + Vector2(-1, 0), Vector2(3, 1)), faded)
				canvas.draw_rect(Rect2(center + Vector2(0, -1), Vector2(1, 3)), faded)
			"up":
				canvas.draw_polyline(PackedVector2Array([center + Vector2(-2, 1), center + Vector2(0, -1), center + Vector2(2, 1)]), faded, 1.0)
			"down":
				canvas.draw_polyline(PackedVector2Array([center + Vector2(-2, -1), center + Vector2(0, 1), center + Vector2(2, -1)]), faded, 1.0)


## A ring that grows and fades (a spell leaves the hand).
func _draw_glow(canvas: CanvasItem, effect: Dictionary, progress: float, color: Color) -> void:
	var at: Vector2 = effect["at"].round()
	canvas.draw_arc(at, 2.0 + 7.0 * progress, 0.0, TAU, 16, Color(color, 1.0 - progress), 1.0)
	if progress < 0.4:
		canvas.draw_circle(at, 2.0, Color(COLOR_CORE, 1.0 - progress * 2.5))
