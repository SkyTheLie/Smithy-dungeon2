class_name MapPreloader
extends Node
## Loads the neighbouring maps in the background while the player walks around, so walking
## through a door does not wait for the hard disk (the first load of a big map takes up to ~1.5 s).
## Child of GameState. After every scene change it looks for the ways out of the new map (every
## node with a `target_scene`, e.g. Door, ElfLift; not carriages), nearest to the player first, and
## loads them one after another with ResourceLoader.load_threaded_request. The loaded PackedScenes
## are held here, so `change_scene_to_file` finds them in the resource cache. Maps that are no
## longer neighbours are let go (memory).
## Setting "Nachbarkarten vorladen" (tab Grafik, user://settings.cfg section "loading"), on by
## default. Headless (tests, simulators) it only runs if `run_headless` is set.

const SECTION: String = "loading"
const KEY: String = "preload_neighbors"
## Most maps held at once (PC / phone, less memory there).
const MAX_MAPS: int = 8
const MAX_MAPS_MOBILE: int = 4
## Wait this long after a scene change, so the new map builds without competition.
const START_DELAY: float = 0.4

## Tests switch preloading on although they run headless.
var run_headless: bool = false
## Paths still to load, in this order.
var _queue: Array[String] = []
## Path of the threaded load in flight ("" = none). It is always finished, even if no longer wanted.
var _loading: String = ""
## Loaded neighbour maps, held so they stay in the resource cache.
var _held: Dictionary[String, PackedScene] = {}
## Neighbours of the current map (what _held may keep).
var _wanted: Array[String] = []
## Counts scene changes, so an old delayed scan does nothing.
var _scan_id: int = 0
## How often scan() ran (tests wait for the scan after a scene change).
var scan_count: int = 0


static func is_enabled() -> bool:
	return bool(WindowLayout.get_setting(SECTION, KEY, true))


## Switching it off lets go of every held map at once; switching it on loads the neighbours now.
static func set_enabled(on: bool) -> void:
	WindowLayout.set_setting(SECTION, KEY, on)
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null(^"GameState") if tree else null
	if game_state and game_state.get("map_preloader") is MapPreloader:
		(game_state.get("map_preloader") as MapPreloader).scan()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	get_tree().scene_changed.connect(_on_scene_changed)


## Quitting: finish the load in flight and let go of everything (else the exit can hang).
func _exit_tree() -> void:
	finish_loading()
	_held.clear()


func _on_scene_changed() -> void:
	_scan_id += 1
	var id: int = _scan_id
	await get_tree().create_timer(START_DELAY, true, false, true).timeout
	if id == _scan_id:
		scan()


## true while this map is held (loaded and waiting for the player).
func is_held(path: String) -> bool:
	return _held.has(path)


## Paths of the held maps.
func get_held() -> Array[String]:
	return _held.keys()


## true while maps are still being loaded.
func is_busy() -> bool:
	return not _loading.is_empty() or not _queue.is_empty()


## Looks for the neighbours of the current map, lets go of the others and queues the missing ones.
func scan() -> void:
	scan_count += 1
	_wanted = []
	if is_enabled() and (run_headless or DisplayServer.get_name() != "headless"):
		_wanted = find_neighbors(get_tree().current_scene)
	for path: String in _held.keys():
		if not _wanted.has(path):
			_held.erase(path)
	_queue = _wanted.filter(func(path: String) -> bool: return not _held.has(path))
	set_process(is_busy())


## Scene paths reachable on foot from `scene`, nearest to the player first, without the scene itself.
func find_neighbors(scene: Node) -> Array[String]:
	var found: Array[String] = []
	if scene == null:
		return found
	var here: String = scene.scene_file_path
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var origin: Vector2 = player.global_position if player else Vector2.ZERO
	var distances: Dictionary[String, float] = {}
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var target: Variant = node.get("target_scene")
		if not target is String or not (target as String).ends_with(".tscn") or target == here:
			continue
		# A carriage opens a menu with far stops, not this scene.
		if node is Door and not (node as Door).carriage_stop.is_empty():
			continue
		if not ResourceLoader.exists(target):
			continue
		var distance: float = origin.distance_to((node as Node2D).global_position) if node is Node2D else INF
		if not distances.has(target) or distance < distances[target]:
			distances[target] = distance
	found.assign(distances.keys())
	found.sort_custom(func(a: String, b: String) -> bool: return distances[a] < distances[b])
	var limit: int = MAX_MAPS_MOBILE if MobileUi.active() else MAX_MAPS
	return found.slice(0, limit)


## Before a scene change (GameState): waits for the load in flight and starts no new one until
## the next scan, so the main thread never loads the same files at the same time as the worker.
func finish_loading() -> void:
	_queue.clear()
	if not _loading.is_empty():
		_take_loaded(ResourceLoader.load_threaded_get(_loading) as PackedScene)
	set_process(false)


func _process(_delta: float) -> void:
	if _loading.is_empty():
		_start_next()
		return
	match ResourceLoader.load_threaded_get_status(_loading):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_take_loaded(ResourceLoader.load_threaded_get(_loading) as PackedScene)
		_:
			push_warning("MapPreloader: could not load " + _loading)
			_loading = ""
	set_process(is_busy())


func _take_loaded(packed: PackedScene) -> void:
	if packed and _wanted.has(_loading):
		_held[_loading] = packed
	_loading = ""


func _start_next() -> void:
	if _queue.is_empty():
		set_process(false)
		return
	var path: String = _queue.pop_front()
	# Already in memory (e.g. the map we came from): just hold it.
	if ResourceLoader.has_cached(path):
		var packed := load(path) as PackedScene
		if packed:
			_held[path] = packed
		return
	if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
		_loading = path
