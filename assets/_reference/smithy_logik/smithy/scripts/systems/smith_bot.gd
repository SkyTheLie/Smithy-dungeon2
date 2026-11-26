class_name SmithBot
extends RefCounted
## An opponent smith of the smith tournaments, simulated with the player's rules: he casts every
## metal part (economy.json "crafting_quality.cast_quality"), strikes it on the anvil (points per
## strike as for the player: "anvil" green / yellow / miss), cools it in the trough and joins the
## parts at the workbench ("joining"). Like the player he has skills (data/player_skills), each
## one working as it does for the player:
##   master_hand  "Meisterhand"            gains of anvil and workbench +15 % per rank
##   hardening    "Härtekunst"             points when a part cools in the trough
##   quick_hammer "Flinker Hammer"         one strike less: his anvil step is shorter
##   steady_hand  "Ruhige Hand, gutes Auge" wider anvil zones: green hits more often
##   precise_fit  "Passgenau"             wider joining zone: more perfect joins
## A profile ({"green": [from, to], "miss": [from, to], "skills": {id: rank}}) comes from the
## round (leagues.json league "smith.bot", economy.json story rounds "bot"): "green" = chance that
## one strike is green (before "Ruhige Hand"), "miss" = chance that it misses, the rest is yellow;
## each forging draws his form of the day inside the ranges. The workbench uses his green chance
## too: perfect, otherwise good 70 % / okay 25 % / fail 5 % (a failed join costs every part points
## and he tries again), like assets/_reference/balancing/sim_forge_quality.gd assumes for the player.
## Finishing rounds (task "finish": "sharpen" / "polish", leagues from silver on): the piece goes on
## the grindstone or the polishing table like the player's (economy.json
## "crafting_quality.grindstone" x the time the ball stays green): his share of green time is his
## green chance, "Meisterhand" makes the zone bigger for him as for the player (x 1 + its value),
## and the points grow with his quality gain. Tanning fur changes nothing on the piece (the plate
## decides its rarity, ForgeQuality.inherit), it only costs time (SmithTournament plan).
## Like the player he can have bought workshop upgrades ("upgrades": {station: level}, the levels
## of house.json "workshop_upgrades", summed as House.get_upgrade_value):
##   smelter  more places ("smelt_slots", each melts one ingot at the same time) and "smelt_speed"
##   anvil    "forge_quality" percent more quality gain (like Meisterhand)
## The forge upgrades only save fuel, the tournament gives fuel enough.
## Pure numbers, no autoload state: the simulator (sim_smith_leagues.gd) uses the same functions.

## Skills a smith bot can have (ids of data/player_skills/<id>.tres).
const SKILLS: Array[String] = ["master_hand", "hardening", "quick_hammer", "steady_hand", "precise_fit"]
const SKILL_FOLDER: String = "res://data/player_skills/%s.tres"
## Chances of a join that is not perfect: good, okay (the rest fails), as in sim_forge_quality.
const JOIN_GOOD: float = 0.7
const JOIN_OKAY: float = 0.25
## Green chance never reaches 1: even a master misses sometimes.
const MAX_GREEN: float = 0.97
## Tries at the workbench before he hands in what he has (a fail chance of 5 % never gets there).
const MAX_JOIN_TRIES: int = 20


## The skill resource of `id` (null = unknown).
static func skill(id: String) -> PlayerSkillData:
	var path: String = SKILL_FOLDER % id
	if not SKILLS.has(id) or not ResourceLoader.exists(path):
		return null
	return load(path) as PlayerSkillData


## Rank of skill `id` in `profile`, at most the skill's max_rank.
static func rank(profile: Dictionary, id: String) -> int:
	var data: PlayerSkillData = skill(id)
	if data == null:
		return 0
	return clampi(int((profile.get("skills", {}) as Dictionary).get(id, 0)), 0, data.max_rank)


## Stations whose upgrades help a smith bot.
const UPGRADE_STATIONS: Array[String] = ["smelter", "anvil"]


## Level of his upgrade at `station` (0 = none), at most the levels house.json has.
static func upgrade_level(profile: Dictionary, station: String) -> int:
	var levels: Array = (ContentDB.house("workshop_upgrades") as Dictionary).get(station, {}).get("levels", [])
	return clampi(int((profile.get("upgrades", {}) as Dictionary).get(station, 0)), 0, levels.size())


## Sum of an upgrade effect (e.g. "smelt_slots") over his bought levels, as House.get_upgrade_value.
static func upgrade_value(profile: Dictionary, key: String) -> float:
	var total: float = 0.0
	for station in UPGRADE_STATIONS:
		var levels: Array = (ContentDB.house("workshop_upgrades") as Dictionary).get(station, {}).get("levels", [])
		for i in upgrade_level(profile, station):
			total += float((levels[i] as Dictionary).get(key, 0.0))
	return total


## Ingots he melts at the same time: 1 place + "smelt_slots".
static func smelt_places(profile: Dictionary) -> int:
	return 1 + maxi(0, roundi(upgrade_value(profile, "smelt_slots")))


## Melting time for `ingots` as a multiple of the time one ingot takes on a plain smelter: rounds
## of melting (all places at once) / ("smelt_speed" faster, as Smelter.get_unit_time).
static func smelt_units(profile: Dictionary, ingots: int) -> float:
	var rounds: int = ceili(maxi(1, ingots) / float(smelt_places(profile)))
	return rounds / (1.0 + maxf(0.0, upgrade_value(profile, "smelt_speed")) / 100.0)


## Quality gain of the bot: Meisterhand + anvil upgrade (as PlayerStats.get_quality_gain).
static func quality_gain(profile: Dictionary) -> float:
	return value(profile, "master_hand") + upgrade_value(profile, "forge_quality") / 100.0


## Names of his upgrades for the herald ("" = none), e.g. "Glutkammer, Meisteramboss".
static func describe_upgrades(profile: Dictionary) -> String:
	var names: Array[String] = []
	for station in UPGRADE_STATIONS:
		var level: int = upgrade_level(profile, station)
		if level > 0:
			var levels: Array = (ContentDB.house("workshop_upgrades") as Dictionary)[station]["levels"]
			names.append(Language.translate(str((levels[level - 1] as Dictionary).get("name", station))))
	return ", ".join(names)


## Value of skill `id` at his rank (PlayerStats.skill_value, as for the player).
static func value(profile: Dictionary, id: String) -> float:
	var data: PlayerSkillData = skill(id)
	return PlayerStats.skill_value(data, rank(profile, id)) if data else 0.0


## His anvil strikes per part (the player's base, minus "Flinker Hammer").
static func strikes(profile: Dictionary) -> int:
	return maxi(1, PlayerStats.new().forging_strikes + roundi(value(profile, "quick_hammer")))


## Share of the anvil time he needs (strikes / base strikes): the plan's "forge" step is this long.
static func anvil_time_share(profile: Dictionary) -> float:
	return float(strikes(profile)) / maxf(1.0, float(PlayerStats.new().forging_strikes))


## Copy of `profile` with `extra` ranks on top (e.g. the favourite skill of a smith), each at most
## its max_rank.
static func with_skills(profile: Dictionary, extra: Dictionary) -> Dictionary:
	var copy: Dictionary = profile.duplicate(true)
	var skills: Dictionary = copy.get("skills", {})
	for id: String in extra:
		var data: PlayerSkillData = skill(id)
		if data:
			skills[id] = mini(int(skills.get(id, 0)) + int(extra[id]), data.max_rank)
	copy["skills"] = skills
	return copy


## Copy of `profile` with the green chance `step` higher (later rounds of a league).
static func with_green_step(profile: Dictionary, step: float) -> Dictionary:
	var copy: Dictionary = profile.duplicate(true)
	var green: Array = copy.get("green", [0.5, 0.5])
	copy["green"] = [float(green[0]) + step, float(green[1]) + step]
	return copy


## Score of one piece he forges for `task` (SmithTournament.build_task: "metal_parts", "carved",
## "leather"): rarity x 100 + quality, as ForgeQuality.get_total.
static func forge(profile: Dictionary, task: Dictionary, rng: RandomNumberGenerator) -> int:
	var rules: Dictionary = ForgeQuality.settings()
	var anvil: Dictionary = rules.get("anvil", {})
	var joining: Dictionary = rules.get("joining", {})
	var gain: float = quality_gain(profile)
	var base: PlayerStats = PlayerStats.new()
	var zone_share: float = (base.green_zone_width + value(profile, "steady_hand")) / base.green_zone_width
	var fit_share: float = (base.joining_green_zone_width + value(profile, "precise_fit")) / base.joining_green_zone_width
	var green_range: Array = profile.get("green", [0.5, 0.5])
	var miss_range: Array = profile.get("miss", [0.1, 0.1])
	# His form of the day.
	var green: float = minf(MAX_GREEN, rng.randf_range(float(green_range[0]), float(green_range[1])) * zone_share)
	var miss: float = minf(1.0 - green, rng.randf_range(float(miss_range[0]), float(miss_range[1])))
	var join_perfect: float = minf(MAX_GREEN, green * fit_share)
	var count: int = strikes(profile)
	var quench: int = roundi(value(profile, "hardening"))
	var totals: Array[int] = []
	for i in maxi(0, int(task.get("metal_parts", 1))):
		var total: float = float(ForgeQuality.cast_quality())
		for strike in count:
			var roll: float = rng.randf()
			var key: String = "green" if roll < green else ("miss" if roll < green + miss else "yellow")
			total += _with_gain(float(anvil.get(key, 0)) / count, gain)
		totals.append(roundi(total) + quench)
	if totals.is_empty():
		# Leather only (e.g. a cloak): the leather of the chest, R1 quality 0.
		totals.append(0)
	var parts: int = totals.size() + int(task.get("carved", 0)) + (int(task.get("leather", 0)) if int(task.get("metal_parts", 1)) <= 0 else 0)
	var piece: int = _inherit(totals, rng)
	var finish: int = _finish_points(profile, task, rng)
	if parts < 2:
		return piece + finish
	# Workbench: a failed join costs every part points, then he tries again.
	for attempt in MAX_JOIN_TRIES:
		var roll: float = rng.randf()
		var grade: String = "perfect"
		if roll >= join_perfect:
			var rest: float = (roll - join_perfect) / maxf(0.0001, 1.0 - join_perfect)
			grade = "good" if rest < JOIN_GOOD else ("okay" if rest < JOIN_GOOD + JOIN_OKAY else "fail")
		if grade == "fail":
			var loss: int = roundi(float(joining.get("fail", -15)))
			for i in totals.size():
				totals[i] = maxi(0, totals[i] + loss)
			piece = _inherit(totals, rng)
			continue
		return maxi(0, piece + _with_gain(float(joining.get(grade, 0)), gain)) + finish
	return piece + finish


## Points of sharpening or polishing (0 if the task has no finish): grindstone points x share of
## green time, his share = his form of the day x the Meisterhand zone.
static func _finish_points(profile: Dictionary, task: Dictionary, rng: RandomNumberGenerator) -> int:
	if str(task.get("finish", "")).is_empty():
		return 0
	var green_range: Array = profile.get("green", [0.5, 0.5])
	var share: float = minf(1.0, rng.randf_range(float(green_range[0]), float(green_range[1])) * (1.0 + value(profile, "master_hand")))
	return _with_gain(float(ForgeQuality.settings().get("grindstone", 50)) * share, quality_gain(profile))


## A gain with "Meisterhand" (losses stay as they are), rounded as ForgeQuality.with_skill.
static func _with_gain(points: float, gain: float) -> int:
	return roundi(points * (1.0 + gain)) if points > 0.0 else roundi(points)


## Rarity and quality of the piece from its forged parts (ForgeQuality.inherit with one stack per
## part): rarity between the lowest and the highest part (Crafting.roll_mixed_rarity), quality
## the average quality.
static func _inherit(totals: Array[int], rng: RandomNumberGenerator) -> int:
	var lowest: int = 99
	var highest: int = 0
	var quality_sum: int = 0
	for total in totals:
		var tier: int = mini(floori(total / float(ForgeQuality.POINTS_PER_TIER)), Rarity.Tier.MYTHIC)
		lowest = mini(lowest, tier)
		highest = maxi(highest, tier)
		quality_sum += total - tier * ForgeQuality.POINTS_PER_TIER
	var quality: int = roundi(quality_sum / float(totals.size()))
	return rng.randi_range(lowest, highest) * ForgeQuality.POINTS_PER_TIER + mini(quality, ForgeQuality.MAX_QUALITY)


## Usual scores of `profile` for `task`: x = low (1 in 10 is worse), y = high (1 in 10 is better).
## Plays `samples` pieces with its own random numbers (the game's random state stays as it is).
static func score_range(profile: Dictionary, task: Dictionary, samples: int = 200) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var scores: Array[int] = []
	for i in samples:
		scores.append(forge(profile, task, rng))
	scores.sort()
	return Vector2i(scores[floori(samples * 0.1)], scores[mini(samples - 1, floori(samples * 0.9))])


## "Meisterhand 2, Härtekunst 1" ("" = no skills), in the order of SKILLS.
static func describe_skills(profile: Dictionary) -> String:
	var names: Array[String] = []
	for id in SKILLS:
		var level: int = rank(profile, id)
		if level > 0:
			names.append("%s %s" % [skill(id).display_name, DamageKinds.format_number(level)])
	return ", ".join(names)


## The first bad field of a profile for ContentDB ("" = fine): "green" / "miss" (must be
## [from, to] between 0 and 1), the id of an unknown skill or the station of an unknown upgrade.
static func check_profile(profile: Dictionary) -> String:
	for key in ["green", "miss"]:
		var range_value: Variant = profile.get(key)
		if not range_value is Array or (range_value as Array).size() != 2 				or float(range_value[0]) < 0.0 or float(range_value[1]) > 1.0 or float(range_value[0]) > float(range_value[1]):
			return key
	for id: String in (profile.get("skills", {}) as Dictionary):
		if skill(id) == null:
			return id
	for station: String in (profile.get("upgrades", {}) as Dictionary):
		if not UPGRADE_STATIONS.has(station):
			return station
	return ""
