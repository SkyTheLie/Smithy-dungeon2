class_name SpriteOutline
extends RefCounted
## Gives figures the same dark one-pixel outline: every transparent pixel next to a visible pixel
## that is not dark yet becomes OUTLINE. Figures that already have a dark outline stay as they are
## (no double outline), figures with a soft or missing outline get one.
## Works per cell of `cell` px, so nothing leaks into the neighbouring frame of a sprite sheet.
## Used by the residents' bake script and assets/_reference/fixes/outline_npcs.gd.

const OUTLINE := Color("21131e")
## Edge pixels darker than this (luminance 0-1) already count as outline.
const DARK_EDGE: float = 0.22
## Pixels with less alpha count as transparent.
const SOLID_ALPHA: float = 0.5


static func apply(image: Image, cell: Vector2i = Vector2i.ZERO) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var size: Vector2i = image.get_size()
	if cell == Vector2i.ZERO:
		cell = size
	var source: Image = image.duplicate()
	for y in size.y:
		for x in size.x:
			if source.get_pixel(x, y).a >= SOLID_ALPHA:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n := Vector2i(x, y) + offset
				if n.x < 0 or n.y < 0 or n.x >= size.x or n.y >= size.y:
					continue
				if n.x / cell.x != x / cell.x or n.y / cell.y != y / cell.y:
					continue  # other frame
				var neighbour: Color = source.get_pixel(n.x, n.y)
				if neighbour.a >= SOLID_ALPHA and neighbour.get_luminance() > DARK_EDGE:
					image.set_pixel(x, y, OUTLINE)
					break
