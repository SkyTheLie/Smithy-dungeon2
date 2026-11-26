class_name CharacterBaker
extends RefCounted
## Builds the sprite sheet of an Appearance: the base figure of its outfit (appearance.json
## "outfits.<id>.base", e.g. assets/sprites/characters/base_smith.png; 7 frames x 4 rows of 48x48,
## rows down/up/left/right, frame 0 = idle, 1-6 = walk) with the parts of race, hair style and eye
## shape on top (parts/<outfit>/<name>.png; <name>_back.png behind the body), then the marker
## colours are painted with the chosen colours. Results are cached, so many NPCs with the same look
## cost nothing.
##
## Marker colours (R = shade 0 = lightest):  skin (i, 255, 0)  hair (i, 0, 255)  eye (i, 255, 255)
## cloth (i, 128, 255)  horn (i, 128, 0).
## Races with ears of their own hide the human ears of the base figure: the part HIDE_EARS_PART is
## laid on the base before the other parts, its ERASE_MARKER pixels become transparent.
## The bases and the parts are made by assets/_reference/characters/bake_characters.py.

const FRAME: int = 48
const COLUMNS: int = 7
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
const IDLE_SPEED: float = 5.0
const WALK_SPEED: float = 10.0
## Highest shade index of a marker (5 shades).
const MAX_SHADE: int = 4
## Part that hides the human ears (appearance.json ear_styles "hide_human_ears") and its marker of
## pixels that become transparent.
const HIDE_EARS_PART: String = "no_human_ears"
const ERASE_MARKER: Color = Color8(255, 0, 255)
## Base figure when an outfit has none.
const DEFAULT_BASE: String = "res://assets/sprites/characters/base_smith.png"
## Mining animation (swinging the pickaxe, assets/_reference/characters/bake_mining.py):
## mine_<outfit>.png, 9 frames x 4 rows of 64x64, parts in parts/<outfit>/mine/. The 64 px frame
## has 8 px more room at the sides and 16 px above, so it sits MINE_OFFSET higher than a 48 px one.
const MINE_BASE: String = "res://assets/sprites/characters/mine_%s.png"
## Chopping a tree with the lumber axe: chop_<outfit>.png, same layout as the mining sheet, parts
## in parts/<outfit>/chop/.
const CHOP_BASE: String = "res://assets/sprites/characters/chop_%s.png"
## Same layout as MINE_BASE, the first frame of each row has both arms up (holding up a sword).
const RAISE_BASE: String = "res://assets/sprites/characters/raise_%s.png"
## Attack poses in fights: pose_<pose>_<outfit>.png, 7 frames x 4 rows of 64x64 like the mining sheet;
## the 48 px frame of frame `col` starts at gear.json "crop_x" and POSE_CROP_Y of its cell.
const POSE_BASE: String = "res://assets/sprites/characters/pose_%s_%%s.png"
const POSE_CROP_Y: int = 16
const MINE_FRAME: int = 64
const MINE_COLUMNS: int = 9
const MINE_OFFSET: Vector2 = Vector2(0, -8)

## Equipment in fights (get_battle_sheet): folder with region maps, overlays and gear.json.
const GEAR_DIR: String = "res://assets/sprites/characters/gear/"
## Region id in the map -> Hero.get_battle_gear key whose material colours it.
const GEAR_REGIONS: Dictionary = {1: "helmet", 2: "armor", 3: "gloves", 4: "boots", 5: "legs", 6: "helmet"}
const HELMET_REGION: int = 1
const BRIM_REGION: int = 6
const BRIM_SHADE: int = 3
## Helmet shade per row from the top of the head (light on top).
const HELMET_ROW_SHADES: Array[int] = [1, 0, 0, 1, 1, 2]
## Where the overlays sit relative to the anchors in gear.json.
const WEAPON_OFFSET: Vector2i = Vector2i.ZERO
const SHIELD_OFFSET: Vector2i = Vector2i(-1, 3)
const SHOULDER_OFFSET: Vector2i = Vector2i(1, 2)
## Darker pixels are outline and keep their colour under armour.
const LUMINANCE_OUTLINE: float = 0.16
const OUTLINE_COLOR: Color = Color8(24, 14, 18)

static var _sheets: Dictionary = {}
static var _images: Dictionary = {}
static var _battle_sheets: Dictionary = {}
static var _gear_data: Dictionary = {}


## The finished sprite sheet of a look.
static func get_sheet(look: Appearance) -> Texture2D:
	var key: String = look.get_key()
	if not _sheets.has(key):
		_sheets[key] = ImageTexture.create_from_image(_bake(look))
	return _sheets[key]


## Drops the cached sheet of a look (the character creator tries many own colours).
static func forget(look: Appearance) -> void:
	_sheets.erase(look.get_key())


## Head of the idle frame looking down (for dialogs, hero lists ...).
static func get_portrait(look: Appearance) -> Texture2D:
	var portrait := AtlasTexture.new()
	portrait.atlas = get_sheet(look)
	var rect: Array = ContentDB.appearance_value("portrait_rect", [11, 5, 24, 24])
	portrait.region = Rect2(rect[0], rect[1], rect[2], rect[3])
	return portrait


## Head of the idle frame looking down of any sheet in this layout (e.g. a PixelLab resident).
static func get_sheet_portrait(sheet: Texture2D) -> Texture2D:
	var portrait := AtlasTexture.new()
	portrait.atlas = sheet
	var rect: Array = ContentDB.appearance_value("portrait_rect", [11, 5, 24, 24])
	portrait.region = Rect2(rect[0], rect[1], rect[2], rect[3])
	return portrait


## Folder of the PixelLab sheets (same as Villager.RESIDENT_DIR; not referenced, so this class stays free of scene scripts).
const RESIDENT_DIR: String = "res://assets/sprites/residents/"


## Sheet of a PixelLab resident (assets/sprites/residents/<resident>.png), null if there is none.
static func get_resident_sheet(resident: String) -> Texture2D:
	var path: String = RESIDENT_DIR + resident + ".png"
	return load(path) if not resident.is_empty() and ResourceLoader.exists(path) else null


## Region of one frame in the sheet (direction "down"/"up"/"left"/"right", frame 0 = idle).
static func get_frame_rect(direction: String, frame: int = 0) -> Rect2:
	return Rect2(frame * FRAME, DIRECTIONS.find(direction) * FRAME, FRAME, FRAME)


## Animations "idle_<direction>" and "walk_<direction>" like the player's (for AnimatedSprite2D).
static func make_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction in DIRECTIONS:
		for kind in ["idle", "walk"]:
			var animation := StringName("%s_%s" % [kind, direction])
			frames.add_animation(animation)
			frames.set_animation_speed(animation, IDLE_SPEED if kind == "idle" else WALK_SPEED)
			frames.set_animation_loop(animation, true)
			var range_start: int = 0 if kind == "idle" else 1
			var range_end: int = 1 if kind == "idle" else COLUMNS
			for frame in range(range_start, range_end):
				var texture := AtlasTexture.new()
				texture.atlas = sheet
				texture.region = get_frame_rect(direction, frame)
				frames.add_frame(animation, texture)
	return frames


## The mining sheet of a look (see MINE_BASE), null if its outfit has none (fixed figures).
static func get_mine_sheet(look: Appearance) -> Texture2D:
	return _get_action_sheet(look, MINE_BASE, "mine")


## The chopping sheet of a look (see CHOP_BASE), null if its outfit has none.
static func get_chop_sheet(look: Appearance) -> Texture2D:
	return _get_action_sheet(look, CHOP_BASE, "chop")


## The sheet with raised arms of a look (see RAISE_BASE), null if its outfit has none.
static func get_raise_sheet(look: Appearance) -> Texture2D:
	return _get_action_sheet(look, RAISE_BASE, "mine")


static func _get_action_sheet(look: Appearance, base: String, action: String) -> Texture2D:
	var path: String = base % look.outfit
	if look.is_fixed() or not ResourceLoader.exists(path):
		return null
	var key: String = base + "|" + look.get_key()
	if not _sheets.has(key):
		_sheets[key] = ImageTexture.create_from_image(_compose(look, _load_image(path), action + "/"))
	return _sheets[key]


## Adds the animations "<action>_<direction>" (not looping) of a mining or chopping sheet to
## `frames` (both 9 frames of 64x64 per direction).
static func add_mine_frames(frames: SpriteFrames, sheet: Texture2D, action: String = "mine") -> void:
	for direction in DIRECTIONS:
		var animation := StringName(action + "_" + direction)
		if frames.has_animation(animation):
			frames.remove_animation(animation)
		frames.add_animation(animation)
		frames.set_animation_loop(animation, false)
		for frame in MINE_COLUMNS:
			var texture := AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(frame * MINE_FRAME, DIRECTIONS.find(direction) * MINE_FRAME, MINE_FRAME, MINE_FRAME)
			frames.add_frame(animation, texture)


static func _bake(look: Appearance) -> Image:
	var base: Image = _load_image(look.get_outfit_data().get("base", DEFAULT_BASE))
	# A fixed figure (Bruno, Gustav from PixelLab) is its base picture as it is.
	if look.is_fixed():
		return base.duplicate()
	return _compose(look, base, "")


## `base` with the parts of the look (from parts/<outfit>/<folder>) behind and on top, painted.
static func _compose(look: Appearance, base: Image, folder: String) -> Image:
	var sheet := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	var parts: Array[String] = _get_parts(look)
	var full := Rect2i(Vector2i.ZERO, base.get_size())
	if parts.has(HIDE_EARS_PART):
		parts.erase(HIDE_EARS_PART)
		var mask: Image = _load_part(look, folder + HIDE_EARS_PART)
		if mask:
			base = _hide_ears(base, mask)
	for part in parts:
		var back: Image = _load_part(look, folder + part + "_back")
		if back:
			sheet.blend_rect(back, full, Vector2i.ZERO)
	sheet.blend_rect(base, full, Vector2i.ZERO)
	for part in parts:
		var front: Image = _load_part(look, folder + part)
		if front:
			sheet.blend_rect(front, full, Vector2i.ZERO)
	_paint(sheet, look)
	return sheet


## `base` with the pixels of `mask` on it; ERASE_MARKER pixels become transparent.
static func _hide_ears(base: Image, mask: Image) -> Image:
	var result: Image = base.duplicate()
	var data: PackedByteArray = result.get_data()
	var cover: PackedByteArray = mask.get_data()
	for i in range(0, mini(data.size(), cover.size()), 4):
		if cover[i + 3] == 0:
			continue
		var erase: bool = cover[i] == ERASE_MARKER.r8 and cover[i + 1] == ERASE_MARKER.g8 and cover[i + 2] == ERASE_MARKER.b8
		for k in 4:
			data[i + k] = 0 if erase else cover[i + k]
	result.set_data(result.get_width(), result.get_height(), false, Image.FORMAT_RGBA8, data)
	return result


## Ears (with the part that hides the human ones), race parts, then hair style, eye shape and horns
## (later ones are drawn on top).
static func _get_parts(look: Appearance) -> Array[String]:
	var parts: Array[String] = []
	if look.has_ears():
		var ears: Dictionary = ContentDB.appearance_section("ear_styles").get(look.ear_style, {})
		if ears.get("hide_human_ears", false):
			parts.append(HIDE_EARS_PART)
		if ears.has("part"):
			parts.append(ears["part"])
	for part: String in look.get_race_data().get("parts", []):
		parts.append(part)
	var sections: Array = [["hair_styles", look.hair_style], ["eye_types", look.eye_type]]
	if look.has_horns():
		sections.append(["horn_styles", look.horn_style])
	for section_field: Array in sections:
		var entry: Dictionary = ContentDB.appearance_section(section_field[0]).get(section_field[1], {})
		if entry.has("part"):
			parts.append(entry["part"])
	return parts


## Replaces the marker colours with the colours of the look.
static func _paint(sheet: Image, look: Appearance) -> void:
	var skin: PackedByteArray = _ramp("skin", look.skin)
	var hair: PackedByteArray = _ramp("hair_color", look.hair_color)
	var eyes: PackedByteArray = _ramp("eye_color", look.eye_color)
	var cloth: PackedByteArray = _ramp("clothes_color", look.clothes_color)
	var horn: PackedByteArray = _ramp("horn_color", look.horn_color)
	var bald: bool = ContentDB.appearance_section("hair_styles").get(look.hair_style, {}).get("bald", false) \
			or look.get_race_data().get("no_hair", false)
	if bald:
		hair = skin
	var data: PackedByteArray = sheet.get_data()
	for i in range(0, data.size(), 4):
		var shade: int = data[i]
		if data[i + 3] == 0 or shade > MAX_SHADE:
			continue
		var g: int = data[i + 1]
		var b: int = data[i + 2]
		var ramp: PackedByteArray
		if g == 255 and b == 0:
			ramp = skin
		elif g == 0 and b == 255:
			ramp = hair
		elif g == 255 and b == 255:
			ramp = eyes
		elif g == 128 and b == 255:
			ramp = cloth
		elif g == 128 and b == 0:
			ramp = horn
		else:
			continue
		var index: int = mini(shade, ramp.size() / 3 - 1) * 3
		data[i] = ramp[index]
		data[i + 1] = ramp[index + 1]
		data[i + 2] = ramp[index + 2]
	sheet.set_data(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8, data)


## Shades of a colour field (Appearance.get_colors) as bytes r, g, b, r, g, b, ...
static func _ramp(field: String, value: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	for color: Color in Appearance.get_colors(field, value):
		bytes.append_array(PackedByteArray([color.r8, color.g8, color.b8]))
	return bytes


static func _load_part(look: Appearance, name: String) -> Image:
	var path: String = ContentDB.appearance_value("parts_dir", "res://assets/sprites/characters/parts/") 			+ look.outfit + "/" + name + ".png"
	return _load_image(path) if ResourceLoader.exists(path) else null


static func _load_image(path: String) -> Image:
	if not _images.has(path):
		var image: Image = (load(path) as Texture2D).get_image()
		image.convert(Image.FORMAT_RGBA8)
		_images[path] = image
	return _images[path]


# --- Equipment in fights ------------------------------------------------------------------

## The side view (row "right": 7 frames of 48x48, frame 0 = standing, 1-6 = walking) of a hero
## wearing `gear` (Hero.get_battle_gear). Armour recolours the body where it is worn (region map
## gear/map_<outfit>.png) in the colours of its material (materials.json "colors"); weapon,
## shield, shoulder plates and cloak are drawn on top or behind (gear/<name>.png). Made by
## assets/_reference/characters/bake_gear.py, cached like the sheets. Without `with_weapon` the
## weapon is left out (the battle stage draws it on its own, get_weapon_overlay, to swing it).
static func get_battle_sheet(look: Appearance, gear: Dictionary, with_weapon: bool = true) -> Texture2D:
	if not with_weapon:
		gear = gear.duplicate()
		gear.erase("weapon")
	var key: String = look.get_key() + "|" + JSON.stringify(gear, "", true)
	if not _battle_sheets.has(key):
		_battle_sheets[key] = ImageTexture.create_from_image(_bake_battle(look, gear))
	return _battle_sheets[key]


## The weapon of `gear["weapon"]` on its own, in its material colours: {"texture", "anchor" (the
## pixel that sits in the hand)}. Empty without a weapon.
static func get_weapon_overlay(weapon: Dictionary) -> Dictionary:
	if weapon.is_empty():
		return {}
	var data: Dictionary = _get_gear_data()
	var name: String = _overlay_name(weapon)
	var key: String = "weapon|" + JSON.stringify(weapon, "", true)
	if not _battle_sheets.has(key):
		var path: String = GEAR_DIR + name + ".png"
		if not ResourceLoader.exists(path):
			return {}
		var overlay: Image = _load_image(path)
		var image := Image.create(overlay.get_width(), overlay.get_height(), false, Image.FORMAT_RGBA8)
		var anchor: Array = data["overlays"][name]
		_stamp_image(image, overlay, Vector2i.ZERO, weapon)
		_battle_sheets[key] = {"texture": ImageTexture.create_from_image(image), "anchor": Vector2(anchor[0], anchor[1])}
	return _battle_sheets[key]


## Where the weapon hand of `outfit` is in battle frame `frame` (0 = standing, 1-6 = walking),
## in frame pixels (the weapon overlay's anchor goes there).
static func get_weapon_hand(outfit: String, frame: int) -> Vector2:
	var frames: Array = _get_gear_data().get("outfits", {}).get(outfit, [])
	if frame >= frames.size():
		return Vector2(28, 28) + Vector2(WEAPON_OFFSET)
	var hand: Array = frames[frame]["hand"]
	return Vector2(hand[0], hand[1]) + Vector2(WEAPON_OFFSET)


## true if the outfit has its own attack animation (gear.json "attacks", so far only Bruno's:
## assets/_reference/characters/bake_attack.py).
static func has_attack(outfit: String) -> bool:
	return _get_gear_data().get("attacks", {}).has(outfit)


## How many frames the attack animation of `outfit` has (0 = none).
static func get_attack_frame_count(outfit: String) -> int:
	return _get_gear_data().get("attacks", {}).get(outfit, []).size()


## The attack animation (one row, looking right: wind up, strike, follow through, back) of a hero
## wearing `gear`, armour coloured like get_battle_sheet; without the weapon (the stage draws it
## at get_attack_hand). null if the outfit has none.
static func get_attack_sheet(look: Appearance, gear: Dictionary) -> Texture2D:
	if not has_attack(look.outfit):
		return null
	gear = gear.duplicate()
	gear.erase("weapon")
	var key: String = "attack|" + look.get_key() + "|" + JSON.stringify(gear, "", true)
	if not _battle_sheets.has(key):
		var body: Image = _load_image("res://assets/sprites/characters/attack_%s.png" % look.outfit).duplicate()
		body.convert(Image.FORMAT_RGBA8)
		var frames: Array = _get_gear_data()["attacks"][look.outfit]
		var region_map: Image = _load_image(GEAR_DIR + "map_" + look.outfit + "_attack.png")
		_battle_sheets[key] = ImageTexture.create_from_image(
				_bake_frames(body, region_map, frames, gear, look.outfit) if not gear.is_empty() else body)
	return _battle_sheets[key]


## true if the outfit has this attack pose (gear.json "poses": "swing", "thrust", "shoot", "cast";
## assets/_reference/characters/bake_battle_poses.py).
static func has_pose(outfit: String, pose: String) -> bool:
	return _get_gear_data().get("poses", {}).get(outfit, {}).has(pose)


static func get_pose_frame_count(outfit: String, pose: String) -> int:
	return _get_gear_data().get("poses", {}).get(outfit, {}).get(pose, []).size()


## The attack pose of a builder figure wearing `gear` (one row of 48x48, looking right, without the
## weapon; the stage draws it at get_pose_hand). null if the outfit has no such pose.
static func get_pose_sheet(look: Appearance, gear: Dictionary, pose: String) -> Texture2D:
	if not has_pose(look.outfit, pose):
		return null
	gear = gear.duplicate()
	gear.erase("weapon")
	var key: String = "pose|" + pose + "|" + look.get_key() + "|" + JSON.stringify(gear, "", true)
	if not _battle_sheets.has(key):
		var frames: Array = _get_gear_data()["poses"][look.outfit][pose]
		var cells: Image = _get_action_sheet(look, POSE_BASE % pose, "pose_" + pose).get_image()
		cells.convert(Image.FORMAT_RGBA8)
		var body := Image.create(frames.size() * FRAME, FRAME, false, Image.FORMAT_RGBA8)
		var row: int = DIRECTIONS.find("right")
		for col in frames.size():
			var cell := Vector2i((col + 1) * MINE_FRAME + int(frames[col]["crop_x"]), row * MINE_FRAME + POSE_CROP_Y)
			body.blit_rect(cells, Rect2i(cell, Vector2i(FRAME, FRAME)), Vector2i(col * FRAME, 0))
		var region_map: Image = _load_image(GEAR_DIR + "map_" + look.outfit + "_" + pose + ".png")
		_battle_sheets[key] = ImageTexture.create_from_image(
				_bake_frames(body, region_map, frames, gear, look.outfit) if not gear.is_empty() else body)
	return _battle_sheets[key]


## The hand holding the weapon in frame `frame` of an attack pose (frame pixels).
static func get_pose_hand(outfit: String, pose: String, frame: int) -> Vector2:
	var frames: Array = _get_gear_data().get("poses", {}).get(outfit, {}).get(pose, [])
	if frame >= frames.size():
		return get_weapon_hand(outfit, 0)
	var hand: Array = frames[frame]["hand"]
	return Vector2(hand[0], hand[1])


## Angle of the weapon in frame `frame` of a weapon pose (0 = upright, + = forward), read from the
## animation with the placeholder rod (build_weapon_poses.py).
static func get_pose_angle(outfit: String, pose: String, frame: int) -> float:
	var frames: Array = _get_gear_data().get("poses", {}).get(outfit, {}).get(pose, [])
	return float(frames[frame].get("angle", 0.0)) if frame < frames.size() else 0.0


## The hand holding the weapon in attack frame `frame` (frame pixels; the overlay's anchor goes there).
static func get_attack_hand(outfit: String, frame: int) -> Vector2:
	var frames: Array = _get_gear_data().get("attacks", {}).get(outfit, [])
	if frame >= frames.size():
		return get_weapon_hand(outfit, 0)
	var hand: Array = frames[frame]["hand"]
	return Vector2(hand[0], hand[1])


static func _bake_battle(look: Appearance, gear: Dictionary) -> Image:
	var row: int = DIRECTIONS.find("right")
	var body: Image = get_sheet(look).get_image().get_region(Rect2i(0, row * FRAME, COLUMNS * FRAME, FRAME))
	body.convert(Image.FORMAT_RGBA8)
	var frames: Array = _get_gear_data().get("outfits", {}).get(look.outfit, [])
	if frames.size() < COLUMNS or gear.is_empty():
		return body
	var region_map: Image = _load_image(GEAR_DIR + "map_" + look.outfit + ".png")
	return _bake_frames(body, region_map, frames, gear, look.outfit)


## One row of frames (`body`, one frame per entry of `frames` = gear.json frame infos) with the
## equipment: armour recoloured by `region_map`, cloak behind, shoulder plates, shield and weapon on top.
static func _bake_frames(body: Image, region_map: Image, frames: Array, gear: Dictionary, outfit: String) -> Image:
	var data: Dictionary = _get_gear_data()
	var out := Image.create(frames.size() * FRAME, FRAME, false, Image.FORMAT_RGBA8)
	for col in frames.size():
		var info: Dictionary = frames[col]
		var origin := Vector2i(col * FRAME, 0)
		if gear.has("cloak"):
			_draw_cloak(out, origin, info, _material_ramp(gear["cloak"]["head"]))
		_draw_body(out, body, region_map, origin, int(info["top"]), gear,
				float(data.get("outline_luminance", {}).get(outfit, LUMINANCE_OUTLINE)))
		if gear.has("shoulders"):
			var shoulder: Array = info["shoulder"]
			var plate: Dictionary = {"type": "shoulder", "head": gear["shoulders"]["head"], "grip": gear["shoulders"]["head"]}
			_stamp(out, origin, _overlay_name(plate), Vector2i(shoulder[0], shoulder[1]) + SHOULDER_OFFSET, plate)
		if gear.has("shield"):
			var front := Vector2i(int(info["chest_front"]), int(info["chest_y"])) + SHIELD_OFFSET
			_stamp(out, origin, _overlay_name(gear["shield"]), front, gear["shield"])
		if gear.has("weapon"):
			var hand: Array = info["hand"]
			var weapon: Dictionary = gear["weapon"]
			_stamp(out, origin, _overlay_name(weapon), Vector2i(hand[0], hand[1]) + WEAPON_OFFSET, weapon)
	return out


## The overlay of a held piece: its own shape for the metal (gear/<type>_<metal>.png, made by
## assets/_reference/characters/bake_gear_tiers.py) if there is one, else the plain picture of the type.
static func _overlay_name(piece: Dictionary) -> String:
	var data: Dictionary = _get_gear_data()
	var type_id: String = piece.get("type", "sword")
	var name: String = data.get("aliases", {}).get(type_id, type_id)
	var overlays: Dictionary = data.get("overlays", {})
	if not overlays.has(name):
		name = "sword"
	var tier: String = name + "_" + str(piece.get("head", ""))
	return tier if overlays.has(tier) else name


## The body of one frame; pixels in an armour region take the colour of the worn material (the
## outline stays). Shades: by brightness, stretched over the whole ramp per region (so armour over
## a dark apron is not all dark); the helmet by row (light on top), its brim always darker.
## `outline_luminance`: darker pixels are outline and keep their colour (gear.json can set it per
## outfit, e.g. Bruno's dark hair is only a little lighter than his outline).
static func _draw_body(out: Image, body: Image, region_map: Image, origin: Vector2i, top: int, gear: Dictionary,
		outline_luminance: float = LUMINANCE_OUTLINE) -> void:
	var ramps: Dictionary = {}
	for region: int in GEAR_REGIONS:
		var slot: String = GEAR_REGIONS[region]
		if gear.has(slot):
			ramps[region] = _material_ramp(gear[slot]["head"])
	# Brightness range of every region in this frame.
	var lightest: Dictionary = {}
	var darkest: Dictionary = {}
	for y in FRAME:
		for x in FRAME:
			var at := origin + Vector2i(x, y)
			var region: int = _region_at(region_map, at)
			var luminance: float = body.get_pixelv(at).get_luminance()
			if ramps.has(region) and body.get_pixelv(at).a > 0.0 and luminance > outline_luminance:
				lightest[region] = maxf(lightest.get(region, 0.0), luminance)
				darkest[region] = minf(darkest.get(region, 1.0), luminance)
	# Worked metal: every region shows the make of its material (materials.json "armor_detail").
	var details: Dictionary = {}
	for region: int in ramps:
		var detail: Dictionary = ContentDB.material_armor_detail(gear[GEAR_REGIONS[region]]["head"])
		if not detail.is_empty() and region != BRIM_REGION:
			details[region] = detail
	var left: int = FRAME
	for y in FRAME:
		for x in FRAME:
			if x < left and body.get_pixelv(origin + Vector2i(x, y)).a > 0.0:
				left = x
	for y in FRAME:
		for x in FRAME:
			var at := origin + Vector2i(x, y)
			var color: Color = body.get_pixelv(at)
			if color.a == 0.0:
				continue
			var region: int = _region_at(region_map, at)
			if ramps.has(region) and color.get_luminance() > outline_luminance:
				var shade: int
				if region == BRIM_REGION:
					shade = BRIM_SHADE
				elif region == HELMET_REGION:
					shade = HELMET_ROW_SHADES[clampi(y - top, 0, HELMET_ROW_SHADES.size() - 1)]
				else:
					var span: float = maxf(lightest[region] - darkest[region], 0.01)
					shade = clampi(int((lightest[region] - color.get_luminance()) / span * 4.99), 0, MAX_SHADE - 1)
				if details.has(region):
					shade = _detail_shade(details[region], x - left, y - top, shade)
				color = ramps[region][shade]
			out.set_pixelv(at, out.get_pixelv(at).blend(color))


## The shade of an armour pixel with the material's make: "bands" = a dark seam every n rows, "rivets"
## = a bright rivet every n pixels on the seam, "trim" = bright rows every n rows, "chevrons" = bright
## engraved lines every n pixels, "studs" = bright dots on a grid of n.
static func _detail_shade(detail: Dictionary, x: int, y: int, shade: int) -> int:
	var bands: int = int(detail.get("bands", 0))
	if bands > 0 and y % bands == 0:
		var rivets: int = int(detail.get("rivets", 0))
		return 0 if rivets > 0 and x % rivets == 0 else MAX_SHADE
	var trim: int = int(detail.get("trim", 0))
	if trim > 0 and y % trim == 1:
		return 0
	var chevrons: int = int(detail.get("chevrons", 0))
	if chevrons > 0 and (x + absi(y % (chevrons * 2) - chevrons)) % chevrons == 0:
		return maxi(shade - 2, 0)
	var studs: int = int(detail.get("studs", 0))
	if studs > 0 and x % studs == 0 and y % studs == 2:
		return 0
	return shade


static func _region_at(region_map: Image, at: Vector2i) -> int:
	var pixel: Color = region_map.get_pixelv(at)
	return roundi(pixel.r * 255.0) if pixel.a > 0.0 else 0


## A cloak behind the back: from the shoulders down, a bit wider towards the bottom.
static func _draw_cloak(out: Image, origin: Vector2i, info: Dictionary, ramp: Array) -> void:
	var top: int = info["top"]
	var back: Dictionary = info["back"]
	for y_text: String in back:
		var y: int = int(y_text)
		var width: int = 2 + (y - top - 13) / 6
		for dx in width + 1:
			var x: int = int(back[y_text]) - dx + 1
			if x < 0 or x >= FRAME:
				continue
			var color: Color = OUTLINE_COLOR if dx == width else ramp[4 if dx > width / 2 else 2]
			out.set_pixelv(origin + Vector2i(x, y), color)


## Draws overlay `name` (gear/<name>.png) with its anchor pixel at `at` (frame coordinates),
## head markers in the colours of piece["head"], grip markers in those of piece["grip"].
static func _stamp(out: Image, origin: Vector2i, name: String, at: Vector2i, piece: Dictionary) -> void:
	var path: String = GEAR_DIR + name + ".png"
	if not ResourceLoader.exists(path):
		return
	var anchor: Array = _get_gear_data().get("overlays", {}).get(name, [0, 0])
	var frame := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	frame.blit_rect(out, Rect2i(origin, Vector2i(FRAME, FRAME)), Vector2i.ZERO)
	_stamp_image(frame, _load_image(path), at - Vector2i(anchor[0], anchor[1]), piece)
	out.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(FRAME, FRAME)), origin)


## Draws `overlay` with its top left corner at `at` into `out` (clipped), head markers in the
## colours of piece["head"], grip markers in those of piece["grip"].
static func _stamp_image(out: Image, overlay: Image, at: Vector2i, piece: Dictionary) -> void:
	var head: Array = _material_ramp(piece.get("head", "iron"))
	var grip: Array = _material_ramp(piece.get("grip", piece.get("head", "iron")))
	for y in overlay.get_height():
		for x in overlay.get_width():
			var color: Color = overlay.get_pixel(x, y)
			if color.a == 0.0:
				continue
			var shade: int = color.r8
			if color.g8 == 200 and color.b8 == 0 and shade <= MAX_SHADE:
				color = head[shade]
			elif color.g8 == 200 and color.b8 == 128 and shade <= MAX_SHADE:
				color = grip[shade]
			var target := at + Vector2i(x, y)
			if target.x >= 0 and target.x < out.get_width() and target.y >= 0 and target.y < out.get_height():
				out.set_pixelv(target, color)


## 5 colours of a material (materials.json "colors"), grey if it has none.
static func _material_ramp(material_id: String) -> Array:
	var ramp: Array = []
	for text: String in ContentDB.material_colors(material_id):
		ramp.append(Color.html(text))
	while ramp.size() <= MAX_SHADE:
		ramp.append(Color(0.6, 0.6, 0.6) if ramp.is_empty() else ramp[-1])
	return ramp


static func _get_gear_data() -> Dictionary:
	if _gear_data.is_empty():
		var text: String = FileAccess.get_file_as_string(GEAR_DIR + "gear.json")
		var parsed: Variant = JSON.parse_string(text)
		_gear_data = parsed if parsed is Dictionary else {"outfits": {}}
	return _gear_data
