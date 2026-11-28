"""Balance calculator for Smithy Dungeon 2 (reads data/*.json, changes nothing).

Run from the project folder:  py assets/_reference/balance/balance.py
Prints per dungeon and floor: expected kills, EXP, loot (gold if everything is sold), average
enemy life, boss life; then the player levels a run brings and what things cost at Egon's.
The numbers are expectations (averages), not a simulation of fights. See docs/BALANCE.md.
"""
import json
import io
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))


def load(name):
    with io.open(os.path.join(ROOT, "data", name + ".json"), encoding="utf-8") as f:
        return json.load(f)


floors_file = load("floors")
enemies = load("enemies")["enemies"]
loot = load("loot")
levels = load("levels")
dungeons = load("dungeons")["dungeons"]
gear = load("gear")
shop = load("shop")
skills = load("skills")["skills"]


def floor_list(dungeon):
    return floors_file.get(dungeons[dungeon].get("floors", "floors"), [])


def floor_data(entry):
    data = dict(floors_file["themes"].get(entry.get("theme", ""), {}))
    data.update(entry)
    return data


def loot_value(enemy_id):
    """Expected gold of the loot one kill drops (every entry rolled on its own)."""
    total = 0.0
    for entry in loot["enemies"].get(enemy_id, []):
        amount = entry.get("amount", [1, 1])
        value = loot["materials"].get(entry["id"], {}).get("value", 0)
        total += entry.get("chance", 0) * (amount[0] + amount[-1]) / 2.0 * value
    return total


def loot_pieces(enemy_id):
    total = 0.0
    for entry in loot["enemies"].get(enemy_id, []):
        amount = entry.get("amount", [1, 1])
        total += entry.get("chance", 0) * (amount[0] + amount[-1]) / 2.0
    return total


def exp_to_next(level):
    """Like Skills.exp_to_next: exp_table first, then base_exp x growth^level."""
    if level >= levels.get("max_level", 30) or level < 0:
        return 0
    table = levels.get("exp_table", [30])
    if level < len(table):
        return int(table[level])
    return max(int(table[-1]), round(levels.get("base_exp", 30) * levels.get("growth", 1.25) ** level))


def exp_total(level):
    """EXP from level 0 to `level`."""
    return sum(exp_to_next(lvl) for lvl in range(level))


def level_after(exp):
    lvl = 0
    while lvl < levels["max_level"] and exp >= exp_total(lvl + 1):
        lvl += 1
    return lvl


def floor_report(dungeon):
    mult = float(dungeons[dungeon].get("hp_mult", 1.0))
    rows = []
    for index, entry in enumerate(floor_list(dungeon)):
        data = floor_data(entry)
        weights = data.get("enemies", [])
        weight_sum = sum(w for _, w in weights) or 1
        avg_hp = sum(enemies[e]["hp"] * w for e, w in weights) / weight_sum
        avg_dmg = sum(enemies[e].get("damage", 1) * w for e, w in weights) / weight_sum
        avg_loot = sum(loot_value(e) * w for e, w in weights) / weight_sum
        avg_pieces = sum(loot_pieces(e) * w for e, w in weights) / weight_sum
        count = data.get("enemy_count", [3, 5])
        rooms = data.get("rooms", 7)
        kills = rooms * (count[0] + count[1]) / 2.0
        bosses = data.get("bosses", [])
        boss_hp = sum(enemies[b]["hp"] for b in bosses) / max(1, len(bosses))
        boss_loot = sum(loot_value(b) for b in bosses) / max(1, len(bosses))
        hp_mult = float(data.get("hp_mult", 1.0)) * mult
        rows.append({
            "floor": index + 1, "theme": data.get("name", "?"), "kills": kills,
            "exp": (kills * levels["exp_per_kill"] + levels["exp_per_boss"]) * float(dungeons[dungeon].get("exp_mult", 1.0)),
            "gold": kills * avg_loot + boss_loot, "pieces": kills * avg_pieces,
            "hp": avg_hp * hp_mult, "dmg": avg_dmg, "boss_hp": boss_hp * hp_mult,
            "hazards": ", ".join(h[0] for h in data.get("hazards", [])),
        })
    return rows


# Assumed player when entering a dungeon (see docs/BALANCE.md): damage per shot without items of
# the run, from the base (player.json), the weapon and gloves (gear.json x rarity_stats) and Kraft.
PLAYER_MODEL = [
    # label, dungeon, material, rarity, Kraft levels
    ("Neu (Kupfer-Stab von Egon)", "glut", "copper", 1, 0),
    ("Ende Dungeon 1 (Bronze R2, Kraft 2)", "glut", "bronze", 2, 2),
    ("Start Dungeon 2 (Eisen R2, Kraft 3)", "moor", "iron", 2, 3),
    ("Start Dungeon 3 (Silber R2, Kraft 4)", "frost", "silver", 2, 4),
    ("Start Dungeon 4 (Gold R3, Kraft 5)", "vulkan", "gold", 3, 5),
]
RUN_ITEMS = 1.6  # items found in a run: damage about this many times higher by the deep floors


def player_damage(material, rarity, kraft):
    factor = gear["rarity_stats"][rarity - 1]
    base = load("player")["stats"]["damage"]
    weapon = gear["gear"]["%s_staff" % material]["stats"]["damage"] * factor
    gloves = gear["gear"]["%s_gloves" % material]["stats"]["damage"] * factor
    return base + weapon + gloves + 0.5 * kraft


def main():
    out = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    exp_so_far = 0
    for dungeon in dungeons:
        rows = floor_report(dungeon)
        name = dungeons[dungeon].get("name", dungeon)
        out.write("\n== %s (%s, Stufe %s, Leben x%.2f)\n" % (name, dungeon, dungeons[dungeon].get("level"), dungeons[dungeon].get("hp_mult", 1.0)))
        out.write("Ebene Gebiet            Kills  EXP  Beute(G) Stücke  Gegner-HP Schaden Boss-HP  Fallen\n")
        gold_sum = 0.0
        exp_sum = 0.0
        for r in rows:
            gold_sum += r["gold"]
            exp_sum += r["exp"]
            out.write("%5d %-17s %5.0f %4.0f %8.0f %6.1f %9.1f %7.1f %7.0f  %s\n" % (
                r["floor"], r["theme"], r["kills"], r["exp"], r["gold"], r["pieces"], r["hp"], r["dmg"], r["boss_hp"], r["hazards"]))
        two = sum(r["gold"] for r in rows[:2])
        out.write("Summe: %.0f Gold, %.0f EXP (Tod auf Ebene 3: ca. %.0f Gold, %.0f EXP)\n" % (
            gold_sum, exp_sum, two, sum(r["exp"] for r in rows[:2])))
        exp_so_far += exp_sum
    out.write("\n== Spieler-Modell: Schüsse je Gegner (Ebene 1 ohne Items / Ebene 6 mit Items x%.1f)\n" % RUN_ITEMS)
    for label, dungeon, material, rarity, kraft in PLAYER_MODEL:
        dmg = player_damage(material, rarity, kraft)
        rows = floor_report(dungeon)
        out.write("%-40s Schaden %.2f: Ebene 1 %.1f Schüsse, Ebene 6 %.1f, Boss 6: %.0f Schüsse\n" % (
            label, dmg, rows[0]["hp"] / dmg, rows[-1]["hp"] / (dmg * RUN_ITEMS), rows[-1]["boss_hp"] / (dmg * RUN_ITEMS)))
    out.write("\n== Stufen (EXP gesamt)\n")
    for lvl in (1, 2, 3, 5, 8, 10, 12, 15, 18, 20, 25, 30):
        out.write("Stufe %2d: %6d EXP\n" % (lvl, exp_total(lvl)))
    out.write("\n== Ausrüstung (Preis R1 / R2 / R3, Werte R1)\n")
    factors = shop.get("rarity_price", [1.0])
    for gid, g in gear["gear"].items():
        p = g.get("price", 0)
        out.write("%-24s %4d / %4d / %4d   %s %s\n" % (gid, p, round(p * factors[1]), round(p * factors[2]), g.get("stats"), g.get("unlock", g.get("min_level", ""))))
    skill_report(out)
    out.write("\nHebel: %s\n" % shop.get("roll_prices"))


# Where the player is when a dungeon opens (player level after the dungeons before, see
# BALANCE.md) and the damage he has then (PLAYER_MODEL), to judge what a skill level is worth.
DUNGEON_STAGE = {"": (1, 1.3), "glut": (1, 1.3), "moor": (14, 2.75), "wiese": (20, 3.9), "frost": (20, 3.9), "vulkan": (23, 5.2)}
POINTS_BY_END = 26


def _at(lst, level):
    if not isinstance(lst, list) or not lst:
        return lst if not isinstance(lst, list) else 0
    return lst[min(level - 1, len(lst) - 1)]


def skill_report(out):
    """Every skill level: price, when it opens (player level, dungeon) and what it is worth then:
    damage as % more damage, fire rate as % more shots, life as hearts; points vs the points a
    player has at the end (about level 27)."""
    out.write("\n== Skills: Preis, Freischaltung, Wert\n")
    out.write("Skill/Stufe              Gold Pkt  ab   Dungeon  Wert\n")
    total_points = 0
    for sid, s in skills.items():
        effect = s.get("effect", {})
        for level in range(1, int(s.get("max_level", 1)) + 1):
            gold = _at(s.get("gold", [0]), level)
            points = _at(s.get("points", [0]), level)
            min_level = _at(s.get("min_level", [1]), level)
            dungeon = _at(s.get("dungeon", [""]), level) or ""
            total_points += points
            stage_level, damage = DUNGEON_STAGE.get(dungeon, (1, 1.3))
            # The damage the player has at that point: the stage of the dungeon or of the level.
            for key, (lvl, dmg) in DUNGEON_STAGE.items():
                if min_level >= lvl:
                    damage = max(damage, dmg)
            worth = []
            stats = effect.get("stats", {})
            if "damage" in stats:
                worth.append("+%.0f%% Schaden" % (100.0 * stats["damage"] / damage))
            if "fire_delay_mult" in stats:
                worth.append("+%.0f%% Schüsse" % (100.0 * (1.0 / stats["fire_delay_mult"] - 1.0)))
            if "move_speed" in stats:
                worth.append("+%.0f%% Tempo" % (100.0 * stats["move_speed"] / 5.0))
            if "luck" in stats:
                worth.append("+%.2f Beute je Raum" % (0.5 * stats["luck"]))
            if "reach" in stats:
                worth.append("+%.0f%% Reichweite" % (100.0 * stats["reach"] / 2.5))
            for key in ("hearts", "blue_hearts"):
                if key in effect:
                    worth.append("+%s %s" % (effect[key], key))
            for key in ("backpack", "backpack_slots", "safe_slots", "relic_slots", "relic_runs", "relic_keep_tier", "sell_bonus", "goods_extra", "box_limit", "rarity"):
                if key in effect:
                    worth.append("%s %s" % (key, effect[key]))
            out.write("%-22s %d %5d %3d %4d   %-8s %s\n" % (sid, level, gold, points, min_level, dungeon or "-", ", ".join(worth)))
    out.write("Skillpunkte: alle Skills zusammen %d, bis zum Ende (Stufe ~27) gibt es etwa %d: man muss wählen.\n" % (total_points, POINTS_BY_END))


if __name__ == "__main__":
    main()
