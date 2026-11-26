extends "res://assets/_reference/_lib/base_test.gd"
## Egon's table gets better: every further pull of the lever on the same day moves chance from R1
## to the rarer goods there are (shop.json reroll_shift, at most reroll_shift_max, R1 never below
## r1_min), and the shop skills (skills.json group "laden"): Mehr Ware (goods_extra), Glückliches
## Händchen (R2), Seltene Ware (R3). Fixed seeds.

var meta: Script
var goods: Script
var skills: Script


func run() -> void:
	meta = script("res://scripts/systems/meta_state.gd")
	goods = script("res://scripts/systems/shop_goods.gd")
	skills = script("res://scripts/systems/skills.gd")
	meta.call("start_new")
	_rerolls()
	_skills()
	_more_goods()
	_lever_uses_pulls()


func _rerolls() -> void:
	check_eq(_rounded(goods.call("rarity_weights", 0)), [[1, 100]], "level 0, first pull: only R1")
	check_eq(_rounded(goods.call("rarity_weights", 3)), [[1, 100]], "level 0: nothing rarer to move to, even after pulls")
	meta.call("_write", "level", 5)
	check_eq(_rounded(goods.call("rarity_weights", 0)), [[1, 85], [2, 15]], "level 5, first pull: 85 / 15")
	check_eq(_rounded(goods.call("rarity_weights", 1)), [[1, 80], [2, 20]], "second pull: 5 % from R1 to R2")
	check_eq(_rounded(goods.call("rarity_weights", 2)), [[1, 75], [2, 25]], "third pull: 10 %")
	check_eq(_rounded(goods.call("rarity_weights", 20)), [[1, 60], [2, 40]], "at most 25 % (reroll_shift_max)")
	meta.call("_write", "level", 10)
	var shared: Array = goods.call("rarity_weights", 2)
	check(_near(shared, [[1, 55.0], [2, 25.0 + 10.0 * 25.0 / 35.0], [3, 10.0 + 10.0 * 10.0 / 35.0]]),
			"level 10, third pull: 10 % shared out like the chances of R2 and R3 (%s)" % [shared])
	check(is_equal_approx(_sum(shared), 100.0), "together 100 %")
	meta.call("_write", "level", 30)
	var lowest: Array = goods.call("rarity_weights", 20)
	check(is_equal_approx(float(lowest[0][1]), 10.0), "R1 never below r1_min (10 %%): %s" % [lowest[0][1]])
	check(is_equal_approx(_sum(lowest), 100.0), "still 100 %")
	meta.call("start_new")


func _skills() -> void:
	check_eq(skills.call("problem", "mehr_ware"), "Stufe zu niedrig", "Mehr Ware needs level 1")
	check_eq(skills.call("problem", "glueckliches_haendchen"), "Erst den Skill davor lernen", "Glückliches Händchen needs Mehr Ware")
	check_eq(skills.call("problem", "seltene_ware"), "Erst den Skill davor lernen", "Seltene Ware needs Glückliches Händchen")
	meta.call("_write", "skills", {"mehr_ware": 1, "glueckliches_haendchen": 2, "seltene_ware": 1})
	check_eq(skills.call("rarity_bonus"), {2: 10.0, 3: 3.0}, "skills: R2 +10 %, R3 +3 %")
	check_eq(_rounded(goods.call("rarity_weights", 0)), [[1, 87], [2, 10], [3, 3]], "level 0 with the skills: R2 and R3 can come")
	check_eq(_rounded(goods.call("rarity_weights", 1)), [[1, 82], [2, 14], [3, 4]], "and every pull moves more to them")
	meta.call("_write", "level", 5)
	check_eq(_rounded(goods.call("rarity_weights", 0)), [[1, 72], [2, 25], [3, 3]], "level 5: on top of the 15 % R2")
	meta.call("start_new")


func _more_goods() -> void:
	var smallest: int = 99
	var largest: int = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	meta.call("_write", "skills", {"mehr_ware": 2})
	check_eq(goods.call("goods_extra"), 2, "Mehr Ware 2: two more goods")
	for i in 80:
		var count: int = (goods.call("roll", rng) as Array).filter(func(place: Dictionary) -> bool: return not place.is_empty()).size()
		smallest = mini(smallest, count)
		largest = maxi(largest, count)
	check_eq([smallest, largest], [3, 5], "1-3 goods become 3-5")
	meta.call("start_new")


## The lever rolls with the chances of today's pull, and the bar shows the next one.
func _lever_uses_pulls() -> void:
	meta.call("_write", "level", 5)
	meta.call("gift_gold", 100)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	check_eq(_rounded(goods.call("rarity_chances")), [[1, 85], [2, 15]], "before the first pull: 85 / 15")
	check(meta.call("pull_lever", rng), "first pull (free)")
	check(meta.call("pull_lever", rng), "second pull")
	check_eq(_rounded(goods.call("rarity_chances")), [[1, 75], [2, 25]], "after two pulls the next one is better")
	meta.call("end_run", 0, [] as Array[Dictionary], rng)
	check_eq(_rounded(goods.call("rarity_chances")), [[1, 85], [2, 15]], "a new day starts from the beginning")
	meta.call("start_new")


func _rounded(parts: Array) -> Array:
	var result: Array = []
	for part: Array in parts:
		result.append([int(part[0]), roundi(float(part[1]))])
	return result


func _near(parts: Array, expected: Array) -> bool:
	if parts.size() != expected.size():
		return false
	for i in parts.size():
		if int(parts[i][0]) != int(expected[i][0]) or not is_equal_approx(float(parts[i][1]), float(expected[i][1])):
			return false
	return true


func _sum(parts: Array) -> float:
	var total: float = 0.0
	for part: Array in parts:
		total += float(part[1])
	return total
