class_name FitCamera
extends Camera2D
## The player's camera. The game stretches with aspect "expand": in a window taller or wider than
## 16:9 more of the map is on screen than 640x360. Where the map (the camera limits) is smaller than
## that, the camera zooms in just enough that the view stays inside the limits, so the void beyond
## the map edge never shows. In a 16:9 window nothing changes (zoom 1).


func _ready() -> void:
	get_viewport().size_changed.connect(fit_to_limits)
	fit_to_limits()


## The view the maps are made for (project setting viewport size, 640x360).
const BASE_VIEW := Vector2(640, 360)


## Zoom needed so the visible area fits inside the limits (at least 1, never zoomed out). Measured
## against the 16:9 view: a few small rooms (limits under 640x360, e.g. the hideout) look in 16:9
## exactly as before, a taller or wider window zooms them by the same factor as every other map.
func get_fit_zoom() -> float:
	return maxf(1.0, _fit(get_viewport_rect().size) / _fit(BASE_VIEW))


func _fit(view: Vector2) -> float:
	var width: float = float(limit_right - limit_left)
	var height: float = float(limit_bottom - limit_top)
	var fit: float = 1.0
	if width > 0.0:
		fit = maxf(fit, view.x / width)
	if height > 0.0:
		fit = maxf(fit, view.y / height)
	return fit


func fit_to_limits() -> void:
	var fit: float = get_fit_zoom()
	zoom = Vector2(fit, fit)
