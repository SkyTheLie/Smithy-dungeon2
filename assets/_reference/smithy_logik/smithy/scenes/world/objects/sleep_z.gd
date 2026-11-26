class_name SleepZ
extends Node2D
## Someone sleeps here (e.g. the guard in the bed of the guardhouse): every `interval` seconds a
## few little "z" rise from this point and fade, like the "sleep" gesture of NpcActing.

@export var interval: float = 2.2

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = interval
	_timer.timeout.connect(_puff)
	add_child(_timer)
	_timer.start()
	_puff()


func _puff() -> void:
	for i in 3:
		var z := Label.new()
		z.text = "z"
		z.add_theme_font_size_override("font_size", 8 + i * 2)
		z.modulate = Color(0.85, 0.9, 1.0, 0.0)
		z.position = Vector2(4 * i, -2 * i)
		z.z_index = 2
		add_child(z)
		var rise := z.create_tween()
		rise.tween_interval(0.35 * i)
		rise.tween_property(z, "modulate:a", 1.0, 0.2)
		rise.tween_property(z, "position:y", z.position.y - 14.0, 1.2)
		rise.parallel().tween_property(z, "modulate:a", 0.0, 1.2)
		rise.tween_callback(z.queue_free)
