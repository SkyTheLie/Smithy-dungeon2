class_name VillageRoads
extends Node2D
## The streets villagers walk along: the Marker2D children are road points, `links` connects
## them ("A-B" = the names of two points). Villager asks for a path from where it stands to a
## road point (A* over the links) and on to its goal.
## Between the points the way goes around every obstacle: at the start a navigation mesh is baked
## from all static collision shapes of the map (houses, stalls, benches, lanterns, fences ...),
## shrunk by the villagers' size, and each leg of the path is planned on it.

## Connections between road points, e.g. ["Centre-West", "Centre-South"].
@export var links: PackedStringArray = []
## Road points never left out of a path.
@export var keep_points: PackedStringArray = []
## Walkable area of the map (the navigation mesh is baked inside it).
@export var area: Rect2 = Rect2(-512, -384, 1024, 768)
## Distance villagers keep from obstacles (about half their width).
@export var clearance: float = 7.0

var _astar := AStar2D.new()
var _ids: Dictionary = {}  # point name -> id
var _region: NavigationRegion2D
var _ready_after: int = 0


func _ready() -> void:
	var id: int = 0
	for point in get_children():
		if point is Marker2D:
			_ids[point.name] = id
			_astar.add_point(id, (point as Marker2D).global_position)
			id += 1
	for link in links:
		var ends: PackedStringArray = link.split("-")
		if ends.size() == 2 and _ids.has(ends[0]) and _ids.has(ends[1]):
			_astar.connect_points(_ids[ends[0]], _ids[ends[1]])
		else:
			push_warning("VillageRoads: unknown link '%s'" % link)
	_bake_navigation.call_deferred()


## Navigation mesh from the static collision shapes of the whole map (this node's parent).
func _bake_navigation() -> void:
	var polygon := NavigationPolygon.new()
	polygon.agent_radius = clearance
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = 1
	polygon.add_outline(PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]))
	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(polygon, source, get_parent())
	NavigationServer2D.bake_from_source_geometry_data(polygon, source)
	_region = NavigationRegion2D.new()
	_region.navigation_polygon = polygon
	add_child(_region)
	# the navigation map lives on (World2D of the window) across scene changes: the new region is
	# only usable after the map has been updated once more
	_ready_after = NavigationServer2D.map_get_iteration_id(get_world_2d().navigation_map)


## True once the navigation mesh is baked and in use (paths go around obstacles).
func is_ready() -> bool:
	return _region != null and NavigationServer2D.map_get_iteration_id(get_world_2d().navigation_map) > _ready_after


## Points (global positions) to walk from `from` via the road point `target` to `goal`, each leg
## planned around obstacles. Road points that would mean walking back are left out.
func find_path(from: Vector2, target: Marker2D, goal: Vector2) -> PackedVector2Array:
	var roads := PackedVector2Array()
	if _ids.has(target.name):
		roads = _astar.get_point_path(_astar.get_closest_point(from), _ids[target.name])
	# leave out a first point the villager would walk back to (the next one is closer from here)
	while not roads.is_empty() and not _keep(roads[0]):
		var next: Vector2 = roads[1] if roads.size() >= 2 else goal
		if from.distance_to(next) > roads[0].distance_to(next):
			break
		roads.remove_at(0)
	# leave out a last point that lies beyond the goal (the goal is closer from the point before)
	while not roads.is_empty() and not _keep(roads[-1]):
		var before: Vector2 = roads[-2] if roads.size() >= 2 else from
		if goal.distance_to(before) > roads[-1].distance_to(before):
			break
		roads.remove_at(roads.size() - 1)
	roads.append(goal)
	var path := PackedVector2Array()
	var start: Vector2 = from
	for point in roads:
		path.append_array(_leg(start, point))
		start = point
	return path


## Points (global) from `from` through each of `points` (global) in turn, every leg planned
## around obstacles (e.g. a crowd walking out of the map along a given street).
func plan_through(from: Vector2, points: PackedVector2Array) -> PackedVector2Array:
	var path := PackedVector2Array()
	var start: Vector2 = from
	for point in points:
		path.append_array(_leg(start, point))
		start = point
	return path


## One leg around the obstacles (without its start). Straight if there is no mesh yet.
func _leg(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not is_ready():
		return PackedVector2Array([to])
	var map: RID = get_world_2d().navigation_map
	# start and goal may lie in the margin around an obstacle (next to a bench, in front of a
	# door): plan between the nearest walkable points
	var start: Vector2 = NavigationServer2D.map_get_closest_point(map, from)
	var end: Vector2 = NavigationServer2D.map_get_closest_point(map, to)
	# both in the same margin (e.g. the last steps to a door): straight on, else a figure that plans
	# every step is pulled back to the mesh edge each time it steps into the margin and stands still
	if start.distance_to(end) < clearance:
		return PackedVector2Array([to])
	var leg: PackedVector2Array = NavigationServer2D.map_get_path(map, start, end, true)
	if leg.is_empty():
		return PackedVector2Array([to])
	if leg[0].distance_to(from) < 1.0:
		leg.remove_at(0)
	# the goal itself may lie closer to an obstacle than the mesh allows (a door, a bench seat)
	if leg.is_empty() or not leg[-1].is_equal_approx(to):
		leg.append(to)
	return leg


func _keep(point: Vector2) -> bool:
	for point_name in keep_points:
		var marker: Marker2D = get_node_or_null(NodePath(point_name))
		if marker and marker.global_position.is_equal_approx(point):
			return true
	return false
