class_name SteamBridge
extends Node
## Reports the achievements (Achievements) to Steam. Needs the GodotSteam plugin (GDExtension,
## registers the singleton "Steam"); without it, or with achievements.json "steam.enabled" false,
## it does nothing and the game runs as usual. Setup: docs/STEAM.md.
## Every reached level becomes its Steam achievement (Achievements.get_steam_names); achievements
## with "steam_stat" also send their progress as a Steam stat. Reached levels are sent again after
## loading, so achievements earned while Steam was off appear later.
## GameState adds this node as a child (setup()).

## Seconds between two uploads of changed stats (Steam limits how often storeStats may be called).
const STORE_DELAY: float = 5.0

var _steam: Object
var _achievements: Achievements
## API names already sent this session.
var _reported: Dictionary = {}
## Stat name -> last value sent.
var _stats_sent: Dictionary = {}
var _store_pending: bool = false
var _store_timer: float = 0.0


## Connects to the achievements and starts Steam (if available).
func setup(achievements: Achievements) -> void:
	_achievements = achievements
	var settings: Dictionary = Achievements.get_steam_settings()
	if not settings.get("enabled", false) or not Engine.has_singleton("Steam"):
		return
	_steam = Engine.get_singleton(Language.translate("Steam"))
	if not _init_steam(int(settings.get("app_id", 0))):
		_steam = null
		return
	achievements.unlocked.connect(_sync.unbind(2))
	achievements.changed.connect(_sync)
	_sync()


func is_active() -> bool:
	return _steam != null


func _process(delta: float) -> void:
	if _steam == null:
		return
	_steam.call("run_callbacks")
	if _store_pending:
		_store_timer -= delta
		if _store_timer <= 0.0:
			_store()


## steamInitEx changed its parameters between GodotSteam versions:
## old (retrieve_stats, app_id, embed_callbacks), new (app_id, embed_callbacks).
func _init_steam(app_id: int) -> bool:
	var result: Variant = null
	for method: Dictionary in _steam.get_method_list():
		if method["name"] != "steamInitEx":
			continue
		var args: Array = method["args"]
		if not args.is_empty() and args[0]["name"] == "retrieve_stats":
			result = _steam.call("steamInitEx", true, app_id, false)
		else:
			result = _steam.call("steamInitEx", app_id, false)
		break
	var status: int = int(result.get("status", -1)) if result is Dictionary else -1
	if status != 0:
		push_warning("SteamBridge: Steam is not running or the app id is wrong (%s)." % str(result))
		return false
	return true


## Sends every reached level that was not sent yet, and changed stats. New achievements are
## uploaded right away (Steam shows its popup), stats only every STORE_DELAY seconds.
func _sync() -> void:
	var new_achievement: bool = false
	for id: String in Achievements.get_all():
		var names: Array[String] = Achievements.get_steam_names(id)
		var level: int = _achievements.get_level(id)
		for index in mini(level, names.size()):
			var api_name: String = names[index]
			if not _reported.has(api_name):
				_reported[api_name] = true
				_steam.call("setAchievement", api_name)
				new_achievement = true
		var stat: String = Achievements.get_steam_stat(id)
		if not stat.is_empty():
			var value: int = _achievements.get_progress(id)
			if int(_stats_sent.get(stat, -1)) != value:
				_stats_sent[stat] = value
				_steam.call("setStatInt", stat, value)
				if not _store_pending:
					_store_pending = true
					_store_timer = STORE_DELAY
	if new_achievement:
		_store()


func _store() -> void:
	_store_pending = false
	_steam.call("storeStats")
