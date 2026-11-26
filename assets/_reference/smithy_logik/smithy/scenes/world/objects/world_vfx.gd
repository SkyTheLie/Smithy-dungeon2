class_name WorldVfx
extends Node2D
## Battle effects (BattleVfx: slash, sparks, dark bolts, dust …) drawn in the world, e.g. for cut
## scenes and the fighters in the yard of the Finsterburg. Draws above the figures (z_index 1);
## effects are spawned with global positions. Loops (auras like "aura_holy") follow a node until
## they are removed.

var _vfx := BattleVfx.new()
## node -> {"kind", "color", "offset"}
var _loops: Dictionary = {}
var _time: float = 0.0


func _ready() -> void:
	z_index = 1
	z_as_relative = false


func _process(delta: float) -> void:
	_time += delta
	_vfx.tick(delta)
	queue_redraw()


func _draw() -> void:
	for target: Variant in _loops.keys():
		if not is_instance_valid(target):
			_loops.erase(target)
			continue
		var node := target as Node2D
		var loop: Dictionary = _loops[target]
		if node.is_visible_in_tree():
			BattleVfx.draw_loop(self, loop["kind"], to_local(node.global_position + loop["offset"]), _time, loop["color"])
	_vfx.draw(self)


## Effect `kind` (see BattleVfx) at `at` (global). Flying kinds start at `from` (global).
func spawn(kind: String, at: Vector2, color: Color = Color.WHITE, facing: float = 1.0,
		from: Vector2 = Vector2.ZERO, length: float = 0.0) -> void:
	var start: Vector2 = to_local(from) if from != Vector2.ZERO else Vector2.ZERO
	_vfx.spawn(kind, to_local(at), color, facing, start, length)


## Loops the sheet `kind` (e.g. "aura_holy") at `target` (plus `offset`) until remove_loop.
func add_loop(target: Node2D, kind: String, color: Color = Color.WHITE, offset: Vector2 = Vector2.ZERO) -> void:
	_loops[target] = {"kind": kind, "color": color, "offset": offset}


func remove_loop(target: Node2D) -> void:
	_loops.erase(target)
