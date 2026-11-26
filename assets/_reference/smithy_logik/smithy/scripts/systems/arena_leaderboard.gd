class_name ArenaLeaderboard
extends RefCounted
## The hero leaderboard of the arena halls (ArenaHall, shown by HeroTournamentMenu): the rival
## heroes of leagues.json "hero_leaderboard" "rivals" and the player's heroes, sorted by rank
## points (RP). One hero rating is shared by all heroes of the player (TournamentRanking "hero"),
## so they stand in the list as one line under the player's name.
## A rival has start points and gains `per_day` RP every day (up to "max_points"): nothing to save,
## the list follows from the day (DayCycle.day).


## Lines of the leaderboard, best first: {"name": String, "class": String (hero class id, "" for
## the player), "points": int, "rank": String (name of the rank), "player": bool}.
static func entries(day: int, player_name: String, player_points: int) -> Array[Dictionary]:
	var board: Dictionary = TournamentRanking.data().get("hero_leaderboard", {})
	var cap: int = int(board.get("max_points", 0))
	var list: Array[Dictionary] = []
	for rival: Dictionary in board.get("rivals", []):
		var points: int = int(rival.get("points", 0)) + int(rival.get("per_day", 0)) * maxi(0, day - 1)
		if cap > 0:
			points = mini(points, cap)
		list.append({"name": str(rival.get("name", "?")), "class": str(rival.get("class", "")), "points": points, "player": false})
	list.append({"name": player_name, "class": "", "points": player_points, "player": true})
	# Equal points: the player stands above (he got there first, as far as he can tell).
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		return bool(a["player"]) and not bool(b["player"]))
	# Ranks above the player's own stay unknown ("[???]") until he reaches them.
	var own_rank: int = rank_for(player_points)
	for entry: Dictionary in list:
		var rank: int = rank_for(int(entry["points"]))
		entry["rank"] = TournamentRanking.league_short_name(rank) if rank <= own_rank else TournamentRanking.HIDDEN_NAME
	return list


## Index of the league whose points `points` reach (like TournamentRanking.get_rank).
static func rank_for(points: int) -> int:
	var rank: int = 0
	for index in TournamentRanking.league_count():
		if points >= TournamentRanking.league_points(index):
			rank = index
	return rank


## Place of the player in the list (1 = top).
static func player_place(list: Array[Dictionary]) -> int:
	for index in list.size():
		if list[index]["player"]:
			return index + 1
	return list.size()
