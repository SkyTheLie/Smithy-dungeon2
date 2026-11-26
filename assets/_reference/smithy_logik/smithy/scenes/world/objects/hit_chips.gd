class_name HitChips
extends RefCounted
## Pickaxe hit on a rock: the rock's picture jolts sideways and a few chips of stone (in the ore's
## colour) and dust jump out and fall to its foot.

const CHIP_COUNT: int = 7
const DUST_COLOR: Color = Color(0.62, 0.58, 0.54, 0.8)
const LIFETIME: float = 0.45
## Where the chips start, above the rock's foot (the rock's origin).
const SPAWN_HEIGHT: float = 14.0


## `visual` is the rock's picture (Sprite2D or the ColorRect placeholder), `color` the ore's colour.
static func spawn(rock: Node2D, visual: CanvasItem, color: Color) -> void:
	var rest: Vector2 = visual.position
	var shake: Tween = rock.create_tween()
	for offset in [2.0, -2.0, 1.0, 0.0]:
		shake.tween_property(visual, "position", rest + Vector2(offset, 0.0), 0.03)
	for chip_color: Color in [color, DUST_COLOR]:
		var chips := CPUParticles2D.new()
		chips.position = Vector2(0.0, -SPAWN_HEIGHT)
		chips.z_index = 1
		chips.one_shot = true
		chips.explosiveness = 1.0
		chips.amount = CHIP_COUNT if chip_color == color else CHIP_COUNT - 3
		chips.lifetime = LIFETIME
		chips.direction = Vector2.UP
		chips.spread = 70.0
		chips.initial_velocity_min = 35.0
		chips.initial_velocity_max = 70.0
		chips.gravity = Vector2(0.0, 260.0)
		chips.scale_amount_min = 1.0
		chips.scale_amount_max = 2.0
		chips.color = chip_color
		chips.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		chips.emission_rect_extents = Vector2(5.0, 3.0)
		chips.finished.connect(chips.queue_free)
		rock.add_child(chips)
		chips.emitting = true
