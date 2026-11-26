class_name TowerDungeon
extends DungeonData
## The endless tower (dungeons.json entry with "tower": {...}, created by ContentDB): every stage is
## one floor, there is no last one. A run starts at the last checkpoint (start_floor, set by
## EndlessTower before the party goes) and climbs until the heroes fall or the player calls them
## back. Each floor borrows its monsters from a normal dungeon of fitting level (get_source):
## floor 1 = a dungeon of "start_level", every floor "levels_per_floor" higher, up to the hardest
## dungeon; every "boss_every" floors the boss wave of that dungeon. Past the hardest dungeon the
## monsters grow by "growth_per_floor" each floor (get_enemy_scale), so every run ends somewhere.

## Floor the next run starts on (EndlessTower.get_start_floor), 1 = the bottom.
var start_floor: int = 1
## dungeons.json "tower": start_level, levels_per_floor, growth_per_floor, boss_every.
var settings: Dictionary = {}

## Content cache: the dungeons the floors borrow from, lowest level first.
var _sources: Array[DungeonData] = []


func get_first_stage() -> int:
	return maxi(1, start_floor)


## The normal dungeon floor `floor` borrows its monsters from.
func get_source(number: int) -> DungeonData:
	var sources: Array[DungeonData] = _get_sources()
	if sources.is_empty():
		return null
	var level: float = float(settings.get("start_level", 30)) + (number - 1) * float(settings.get("levels_per_floor", 1.0))
	var chosen: DungeonData = sources[0]
	for source: DungeonData in sources:
		if source.level <= level:
			chosen = source
	# A boss floor takes the nearest dungeon (at or below) that has a boss.
	if is_boss_floor(number) and _boss_stage(chosen) < 0:
		for source: DungeonData in sources:
			if source.level <= chosen.level and _boss_stage(source) >= 0:
				chosen = source
	return chosen


func is_boss_floor(number: int) -> bool:
	var every: int = int(settings.get("boss_every", 10))
	return every > 0 and number % every == 0


## Floors past the hardest dungeon's level: the monsters get stronger by growth_per_floor each.
func get_extra_growth(number: int) -> float:
	var sources: Array[DungeonData] = _get_sources()
	if sources.is_empty():
		return 1.0
	var per_floor: float = maxf(float(settings.get("levels_per_floor", 1.0)), 0.01)
	var top_floor: int = 1 + ceili((sources.back().level - float(settings.get("start_level", 30))) / per_floor)
	return pow(float(settings.get("growth_per_floor", 1.06)), maxi(0, number - top_floor))


func get_wave(number: int) -> Dictionary:
	var source: DungeonData = get_source(number)
	if source == null:
		return default_wave
	if is_boss_floor(number) and _boss_stage(source) >= 0:
		return source.get_wave(_boss_stage(source))
	return source.get_wave(_normal_stage(source, number))


func roll_enemies(number: int) -> Array[EnemyData]:
	var source: DungeonData = get_source(number)
	if source == null:
		return super(number)
	if is_boss_floor(number) and _boss_stage(source) >= 0:
		return source.roll_enemies(_boss_stage(source))
	return source.roll_enemies(_normal_stage(source, number))


## Health and damage factor of the monsters on `floor`: those of the dungeon it borrows from, times
## the extra growth past the hardest dungeon.
func get_enemy_scale(number: int) -> Vector2:
	var source: DungeonData = get_source(number)
	var growth: float = get_extra_growth(number)
	if source == null:
		return Vector2(enemy_health_factor, enemy_damage_factor) * growth
	return Vector2(source.enemy_health_factor, source.enemy_damage_factor) * growth


## For the board: the monsters of the first floors.
func get_enemies() -> Array[EnemyData]:
	var source: DungeonData = get_source(maxi(1, start_floor))
	return source.get_enemies() if source else super()


## Stage of `source` whose wave is its boss ( -1 = none).
static func _boss_stage(source: DungeonData) -> int:
	for stage: int in source.get_special_stages():
		if source.get_stage_type(stage) == StageType.BOSS:
			return stage
	return -1


## A normal (no boss) stage of `source` for this floor, so the pool's stage ranges still apply.
static func _normal_stage(source: DungeonData, number: int) -> int:
	var count: int = maxi(1, source.stage_count)
	for offset in count:
		var stage: int = 1 + (number + offset) % count
		if source.get_stage_type(stage) == StageType.NORMAL:
			return stage
	return 1


## Dungeons with monsters, not the tower itself, not the arena and no story-only fight with a
## single stage; lowest level first.
func _get_sources() -> Array[DungeonData]:
	if not _sources.is_empty():
		return _sources
	for dungeon: DungeonData in ContentDB.get_all_dungeons():
		if dungeon is TowerDungeon or dungeon.stage_count < 3 or dungeon.get_enemies().is_empty():
			continue
		if dungeon.level < int(settings.get("start_level", 30)) - 5:
			continue
		_sources.append(dungeon)
	return _sources
