# Inhalte hinzufügen (JSON)

Alle Items, Materialien, Rezepte, Status-Effekte, Skills, Gegner und Kampf-Formeln stehen in `data/content/` als JSON. Das Spiel liest sie beim Start (`ContentDB`, `scripts/core/content_db.gd`). Neue Inhalte brauchen **keinen Code**. Tippfehler meldet das Spiel beim Start in der Godot-Ausgabe, z. B.:

```
ContentDB: items.json, 'gold_blade': unknown material 'gld' (see materials.json).
```

Jeder Eintrag hat eine **id** (der Schlüssel, klein mit Unterstrich, z. B. `"gold_blade"`). Die id wird überall verwendet (Spielstände, Händler, Aufträge, Steine) und sollte nicht mehr geändert werden, wenn sie einmal im Spiel ist.

## Spickzettel

| Datei | Was steht drin | Bild-Feld | Größe | Standard-Bild, wenn es fehlt |
|---|---|---|---|---|
| `items.json` | Items: Rohstoffe, Erze, Barren, Teile, Waffen, Werkzeug | `icon` | 12×12 | `res://assets/sprites/items/default.png` |
| | heißer Barren (automatisch aus gegossenen Teilen) | `hot_icon` oder Datei `hot_<teil>_blank.png` | 12×12 | `res://assets/sprites/items/hot_blank.png` |
| `materials.json` | Materialien (Metall = gießen, Holz = schnitzen) | – | | |
| `weapon_types.json` | Waffentypen = Kategorien an Werkbank und Zaubertisch | – | | |
| `recipes.json` (optional) | Rezepte, die nicht automatisch entstehen | – | | |
| `status_effects.json` | Buffs und Debuffs | `icon` | 16×16 | `res://assets/sprites/effects/default.png` |
| `skills.json` | Skills für Helden und Monster (aktiv und passiv) | `icon` | 16×16 | `res://assets/sprites/skills/default.png` |
| `skill_trees.json` | die drei Skillbäume jeder Heldenklasse | – | | |
| `summons.json` | Beschwörungen der Helden (Elementare, Wolf) | `look` (Gegner-id) | wie der Gegner | Bild des Gegners |
| `audio.json` | Musik und Geräusche (Pfade zum Austauschen) | – | WAV/OGG/MP3 | still (Warnung) |
| `enemies.json` | Monster | `sprite.path` | 16×16 pro Bild | `res://assets/sprites/enemies/default.png` |
| `dungeons.json` | Dungeons mit Wellen und Belohnungen | `background` | z. B. 192×112 | keins (Beispiel `res://assets/sprites/battle/rat_cellar.png`) |
| `appearance.json` | Aussehen: Rassen, Hautfarben, Frisuren, Haarfarben, Augen, Größen | `part` (Name eines Teils) | 336×192 (ganzes Sheet) | – (fehlt ein Teil, wird es weggelassen) |
| `story.json` | Geschichte: Intro, Schritte, Dialoge, Tipps, Story-Figuren | – | | |
| `combat.json` | Kampf-Formeln | – | | |
| `economy.json` | Preise, Kunden, Ruf | – | | |
| `house.json` | Hausausbau (5 Stufen), eigener Laden, Möbel | `texture` (Möbel) | bis 48×48 | – (ohne Bild wird das Möbelstück nicht gezeigt) |
| `forging_patterns.json` | Amboss-Minispiel: glühendes Teil und Schlagflächen (nur noch für Items ohne eigenes Icon; sonst zeigt das Minispiel das Item-Icon) | `image` | 80×48 | `res://assets/sprites/forging/default.png` |
| `sockets.json` | Sockel-Boni für Ausrüstung (Stufen 1–9 mit Chancen, erlaubte Slots) | – | | |
| `mortar.json` | Mörser: Staub aus Kristallen und Mondlilie, Verzauberungstränke | `icon` (oder `color`) | 24×24 | Staub `res://assets/sprites/items/magic_dust.png`, Trank `enchant_potion.png`, eingefärbt mit `color` |
| `npcs.json` | Feste Dorfbewohner: Name, Beruf, Partner, Wohnhaus, Aussehen, Tagesablauf | `look` (Baukasten) | | – |
| `achievements.json` | Erfolge (Charakter-Fenster, Reiter Erfolge): Kategorien, Stufen, geheime Erfolge | `icon`, `item` oder `enemy` | 16×16 | `res://assets/sprites/items/default.png` |

**Hilfe in den Dateien:** JSON erlaubt keine Kommentare. Deshalb steht oben in jeder Datei ein Eintrag `"_hilfe"` mit Kurzbeschreibung, allen Feldern, Standard-Bildern und einer Vorlage zum Kopieren. Das Spiel ignoriert alle Einträge, deren Schlüssel mit `_` beginnt. Man kann also auch eigene Notizen als `"_notiz": "..."` ablegen (nur ganz oben in der Datei, nicht innerhalb eines Eintrags).

**Neuen Inhalt anlegen in 3 Schritten:**
1. Vorlage aus `"_hilfe"` kopieren, als neuen Eintrag mit eigener id einfügen (id klein_mit_unterstrich, später nicht mehr ändern).
2. Felder anpassen. Bild weglassen ist erlaubt: dann erscheint das Standard-Bild mit „?“.
3. Spiel starten und die Godot-Ausgabe prüfen. Tippfehler werden mit Datei und id gemeldet.

## Beispiel: Goldklinge

1. Bild zeichnen: `assets/sprites/items/gold_blade.png` (12×12, auf der Schwert-Leinwand, siehe PROJEKT.md „Baukasten“).
2. In `data/content/items.json` eintragen:

```json
"gold_blade": {
	"name": "Goldklinge",
	"description": "Eine prächtige Klinge aus Gold.",
	"icon": "res://assets/sprites/items/gold_blade.png",
	"type": "part",
	"part": "blade",
	"material": "gold",
	"damage": [6, 9],
	"damage_type": "slash",
	"category": "Schwerter"
}
```

Fertig. Automatisch entstehen daraus:

- der **heiße Barren** `hot_gold_blade_blank` („Heißer Goldbarren (Klinge)“),
- am **Gussofen** (intern `forge`, früher Esse) die Gussform `mold_gold_blade` (1 Goldbarren → heißer Barren),
- am **Amboss** das Rezept `gold_blade` (heißer Barren → glühende Goldklinge),
- an der **Werkbank** passt sie in jedes Schwert (das Schwert nimmt „irgendeine Klinge“). Name: „Goldschwert“.

Seltenheit: alle Materialien sind R1; eine Goldklinge wird seltener durch seltene Barren (z. B. R4 vom Reisenden) und gutes Schmieden (Qualitätspunkte, siehe economy.json `crafting_quality`). Die Materialstufe (`tier`, Gold 5) bestimmt Preis, Ruf und Schwierigkeit.

Optional: eigenes Bild für den heißen Barren unter `assets/sprites/items/hot_gold_blade_blank.png` (sonst ein Standardbild) oder `"hot_icon": "res://..."`.

## Fehlende Bilder

Fehlt bei einem Item, Skill, Status-Effekt oder Gegner das Bild (Feld leer, weggelassen oder Datei nicht da), wird ein **Standard-Bild** mit „?“ angezeigt (`assets/sprites/items/default.png`, `skills/default.png`, `effects/default.png`, `enemies/default.png`; neu zeichnen mit `py -I assets/_reference/ui/make_defaults.py`). So kann man JSON-Einträge schon anlegen, bevor die Grafik fertig ist. Ein falscher Pfad wird zusätzlich als Fehler gemeldet.

## Schadensarten

Ein Treffer besteht aus Anteilen verschiedener Schadensarten. Diese ids gelten überall (`damage_split`, `resistances`, `damage_type`):

| id | Art | wird verringert durch |
|---|---|---|
| `physical`, `stab`, `blunt`, `slash` | Physisch, Stich, Stumpf, Schnitt | Rüstung + Resistenz gegen diese Art |
| `fire`, `water`, `earth`, `air`, `dark`, `light`, `lightning`, `ice`, `poison` | Elemente | Resistenz gegen das Element + Widerstand (RES) |
| `magic` | Magie ohne Element | Magie-Resistenz + Widerstand (RES) |
| `true` | Wahrer Schaden | nichts (ignoriert Rüstung und Resistenzen) |

Formel pro Anteil: **Schaden × 100 / (100 + R)**. R ist bei physischem Schaden Rüstung + Resistenz, bei Elementen/Magie Magieresistenz + Resistenz; Widerstand gibt +1 auf jede Resistenz (Werte in combat.json). Negative Resistenz = Schwäche (höchstens doppelter Schaden). **Kritische Treffer** machen 150 % Schaden; Chance 5 % + 1 % pro Beweglichkeit + Boni von Ausrüstung, Skills und Buffs. Im Spiel stehen die Arten in ihrer Farbe (Feuer orangerot, Blitz blau, Dunkelheit dunkelviolett …), mit **Shift** zeigen Item- und Skill-Tooltips Details (z. B. die Aufteilung).

## items.json – alle Felder

| Feld | Bedeutung | Beispiel |
|---|---|---|
| `name` | Anzeigename | `"Eisenklinge"` |
| `description` | Text im Tooltip | |
| `icon` | Bildpfad (12×12) | `"res://assets/sprites/items/iron_blade.png"` |
| `type` | `material`, `fuel`, `ore`, `ingot`, `weapon`, `armor`, `accessory`, `part`, `helmet`, `boots`, `pickaxe`, `shoulders`, `cloak`, `legs`, `necklace`, `ring`, `shield`, `gloves`, `backpack`, `shoes`, `lumber_axe`, `watering_can` (Stiefel `boots` tragen nur Helden, Schuhe `shoes` und die Holzfälleraxt `lumber_axe` nur der Schmied; die Gießkanne `watering_can` liegt nur im Inventar) | `"part"` |
| `rarity` | Grund-Seltenheit `R1`–`R8` (sonst die des Materials, sonst R1) | `"R2"` |
| `material` | id aus `materials.json` (bei Teilen und Barren) | `"iron"` |
| `part` | Teil-Art: `blade`, `handle`, `axe_head`, `shaft`, `dagger_blade`, `greatsword_blade`, `spear_head`, `hammer_head`, `mace_head`, `greataxe_head`, `shield_plate`, `pickaxe_head`, `chest_plate`, `helmet_plate`, `shoulder_plate`, `boot_plate`, `glove_plate`, `lumber_axe_head`, `leg_plate`, `can_body` (Kannenkörper der Gießkanne) | `"blade"` |
| `ingots` | Metall-Teile: Barren pro Gussform (Standard 1; Brustplatte und Zweihandklingen 2) | `2` |
| `layer` | Zeichen-Reihenfolge beim Zusammensetzen des Icons (höher = oben) | `1` |
| `icon_frames` | Animiertes Icon: `icon` ist ein Streifen aus so vielen gleich großen Frames nebeneinander (z. B. die heiligen Kristalle, 48×48 pro Frame) | `16` |
| `icon_fps` | Frames pro Sekunde des animierten Icons (Standard 10) | `12` |
| `icon_slosh` | `true` = das animierte Icon läuft nicht von selbst, sondern zeigt Wasser, das gegen die Laufrichtung schwappt (25 Frames = 5×5 Neigungen, `WaterSlosh`) | `true` |
| `own_icon` | `true` = das Item zeigt immer sein eigenes `icon`, auch wenn es aus Teilen gebaut ist (sonst wird das Icon aus den Teilen zusammengesetzt). Für Items, bei denen etwas Wichtiges kein Teil ist, z. B. der Kristall der Eisen-Zauberstäbe | `true` |
| `value` | Wert in Gold (Barren, Kohle und Holz bestimmen die Preise der Kundenaufträge, siehe economy.json) | `5` |
| `sell_price` | Fester Preis, den Händler für ein Stück R1 zahlen (ersetzt die Rechnung aus `value`; `0` = Händler nimmt es nicht). Jede Seltenheitsstufe höher: × `sell_price_factor`, gerundet. Selbst geschmiedete Waffen bekommen weiter +7 Gold. Gilt nur beim Verkauf an Händler, nicht für Kaufpreise, Ninas Laden oder Aufträge | `9` |
| `sell_price_factor` | Faktor pro Seltenheitsstufe für `sell_price` (Standard: economy.json `prices.sell_price_factor` = 1.2). Beispiel `sell_price` 10, Faktor 1.2: R1 10, R2 12, R3 14, R4 17 | `1.5` |
| `soil` | `true` = Erde für die Pflanztöpfe im Gewächshaus (bleibt im Topf, kann nur gegen andere Erde getauscht werden) | `true` |
| `soil_bonus` | bessere Erde: Seltenheitsstufen mehr bei jeder Ernte aus diesem Topf, der Rest als Chance (`Garden.get_soil_tiers`) | `0.5` (Waldhumus), `1.0` (Mondhumus) |
| `stack` | max. Stapelgröße (Standard 99; Ausrüstung – Waffen, Rüstung, Schmuck, Werkzeuge – stapelt nie, egal was hier steht) | `1` |
| `damage` | Schaden `[von, bis]` (Waffen-Teile) | `[4, 7]` |
| `armor` | Rüstungswert | `3` |
| `magic_resistance` | Magieresistenz (verringert Zauber- und Element-Schaden) | `2` |
| `damage_type` | `none`, `stab`, `blunt`, `slash` | `"slash"` |
| `damage_split` | Aufteilung des Schadens in Arten (Zahlen werden auf 100 % umgerechnet); ohne = 100 % `damage_type` | `{"slash": 50, "fire": 50}` |
| `magic_damage` | Magieschaden `[von, bis]` (z. B. Zauberstab), kommt zu magischen Skills dazu | `[3, 5]` |
| `resistances` | Resistenzen beim Tragen (Arten siehe oben, negativ = Schwäche) | `{"fire": 10}` |
| `crit_chance`, `crit_damage` | Krit-Chance / Krit-Schaden in Prozentpunkten beim Tragen | `5` = +5 % |
| `armor_pen`, `magic_pen` | Durchdringung beim Tragen in %: ignoriert diesen Anteil der Rüstung / Magieresistenz des Ziels (Summe aller getragenen Teile) | `10` = 10 % |
| `armor_pen_flat`, `magic_pen_flat` | Durchdringung in Punkten (zählt nach den %) | `5` = 5 Rüstung weniger |
| `element` | `none`, `fire`, `water`, `earth`, `air`, `dark`, `light`, `lightning`, `ice` | `"fire"` |
| `attributes` | feste Attribute: `str`, `agi`, `con`, `int`, `wis`, `res` | `{"str": 2}` |
| `effect` | Effekt-Text im Tooltip | |
| `smelt_to` | Erz (oder Sand): id dessen, was in der Schmelze daraus wird | `"iron_ingot"` |
| `plant` | Samen: `{"grows": <item-id>, "days": 3, "amount": 2, "bloom": <bild 16×24, optional>}` – im Pflanztopf (Gewächshaus) gepflanzt, nach `days` Tagen reif (jede Samenart eigene Dauer), Ernte = `amount` × `grows`; `"full_moon": true` = bei Vollmond geerntet eine Seltenheit besser (Mondlilie) | `{"grows": "moon_lily", "days": 3, "amount": 2}` |
| `alloy` | Legierung: genau 2 Zutaten mit Menge, entsteht in der Schmelze unter „Legieren“ (Dauer `smelt_time`) | `{"copper_ingot": 1, "iron_ingot": 1}` |
| `tan_to` | Fell: id des Leders, das an der Gerberbank daraus wird (Seltenheit bleibt gleich) | `"leather"` (Rattenleder, wie Kupfer), `"wolf_leather"` (Eisen), `"dragon_leather"` (aus Drachenhaut, Bronze), `"hippogriff_leather"` (Silber) |
| `part: "fletching"` | Befiederung für Pfeile (Pfeile = `arrow_tip` + `arrow_shaft` + `fletching`): `feather` (ohne Material, einfachste Stufe), `harpy_feather` (Material `harpy_feather`, Stufe 3 wie Silber, `damage` [1, 2]); weitere Stufen = neues Item mit Material (`process` `gather`) | `"part": "fletching", "material": "harpy_feather"` |
| `vial_to` | Sand: id der Phiole, die am Phiolen-Tisch daraus wird (1 Stück = 1 Phiole, Seltenheit bleibt; Brennstoff nach `smelt_charges`) | `"vial"` |
| `smelt_time` | Schmelzdauer in Sekunden | `10` |
| `heat` | Brennstoff: Schmiedevorgänge pro Stück | `5` |
| `mining_damage` | Spitzhacke: zusätzlicher Abbau-Schaden | `2` |
| `purse_gold` | Geldbeutel: `[von, bis]` Gold, das jedes Stück in der Loot-Kiste wird (Banditen-Beute `coin_purse`) | `[4, 12]` |
| `smelt_charges` | Brennstoff: so viele Erze schmilzt ein Stück in der Schmelze (Standard 1, Kohle 2) | `2` |
| `chopping_damage` | Holzfälleraxt bzw. ihr Kopf: zusätzlicher Schaden an Bäumen (Kupfer 3, Eisen 5, Bronze 7, Silber/Gold 9, Platin 11, Palladium 13) |
| `inventory_slots` | Rucksack (`type: backpack`) bzw. sein Gestell (Teil `backpack_frame`): so viele Plätze mehr im Inventar, solange er im Rucksack-Platz des Schmieds liegt (Kupfer 2, Eisen 5, Bronze 7, Silber 9, Gold 12) | `3` |
| `water_charges` | Gießkanne (`type: watering_can`) bzw. ihr Kannenkörper (Teil `can_body`): so viele Pflanzen gießt eine Füllung am Wasserhahn im Gewächshaus (Kupfer 2, Eisen 3, Bronze 4, Silber 5, Gold 6) | `3` |
| `move_speed` | Schuhe (`type: shoes`) im Schuh-Slot des Schmieds: schneller laufen in % auf R1, +2 % pro Seltenheitsstufe | `10` |
| `forge_quality` | Handschuhe im Handschuh-Platz des Schmieds: mehr Qualitätspunkte beim Schmieden, Zusammenbauen und Schleifen in % (wie der Skill Meisterhand) | `5` (Meisterhandschuhe) |
| `minigame_calm` | Handschuhe im Handschuh-Platz des Schmieds: Amboss- und Werkbank-Minispiel laufen so viele % langsamer (0–90) | `20` (Sandschmied-Handschuhe) |
| `loot_luck` | Glück in %, solange ein Held es trägt: Monster lassen öfter Beute fallen (+ halbes Glück) und seltener (Seltenheits-Chancen + Glück); nur das beste Stück der Gruppe zählt (Goblinkrone 50) | `50` || `forging_pattern` | eigenes Muster fürs Amboss-Minispiel (id aus forging_patterns.json, z. B. für Unique-Gegenstände); weglassen = Muster des Teil-Typs (`part`), sonst `default` | `"blade"` |
| `parts` | Waffe/Rüstung aus Teilen: welche Teil-Arten (Werkbank-Rezept entsteht automatisch). Dieselbe Teil-Art mehrmals = eine Zutat mit dieser Menge (Umhang: 3 Leder). Leder ist ein Teil (`part: "leather"`), daher zählt sein Rüstungswert mit | `["chest_plate", "leather"]` |
| `part_materials` | Nur diese Materialien für eine Teil-Art (sonst jedes) | `{"shaft": ["wood"]}` (Spitzhacke nur mit Holzstiel) |
| `needs` | Werkbank: feste Zutaten zusätzlich zu den Teilen (nur `needs` ohne `parts` = Rezept nur aus Zutaten). Zählen nicht als Teil (Name und Icon kommen nur von den Teilen) | `{"rope": 1}` |
| `weapon_type` | Waffentyp aus `weapon_types.json` (Waffen): bestimmt die Kategorie im Stations-Menü, die Hände und das Angriffstempo | `"sword"` |
| `category` | Kategorie in den Stations-Menüs (ohne Angabe: Name des `weapon_type`) | `"Schwerter"` |
| `tab` | Reiter: `weapon`, `armor`, `jewelry`, `accessory`, `enchant` (Zaubertisch) | `"accessory"` |
| `locked` | `true` = Rezepte müssen erst freigeschaltet werden (Dungeon, Auftrag) | `true` |
| `quest_part` | `true` = Teil nur für eine Quest (z. B. Kompass): seine Gussform steht im Charakter-Fenster unter Kupfer | `true` |
| `mold_shape` | Silhouette der Gussform für ein Item ohne `part` (Dateiname in `assets/sprites/molds/`), z. B. die Harpunenspitze (Gussofen-Rezept `mold_harpoon_tip`) | `"spear_head"` |
| `hot_icon` | Bild des heißen Barrens (gegossene Teile) | |

**Tränke für Helden:** ein Item mit `"hero_potion"` wirkt per Rechtsklick bei offenem Heldenfenster auf den gezeigten Helden: `skill_point` (+1 Skillpunkt, höchstens `hero_max_bonus_skill_points` = 3 pro Held), `attribute_point` (+1 Attributpunkt, höchstens `hero_max_bonus_attribute_points` = 6), `reset_skills` (alle Skills verlernen, Punkte zurück), `reset_attributes` (alle verteilten Attributpunkte zurück), `level_up` (genau +1 Level, gesammelte EXP verfallen; nur für den Admin-Trank). Vorhanden: `skill_reset_potion`, `attribute_reset_potion`, `admin_level_potion` (Admin-Trank: Level +1, nur übers Admin-Panel, darf nirgends in Läden, Beute oder Rezepten stehen); `skill_point_potion` (Trank des Wissens: 2 Glutessenzen + Mondlilie) und `attribute_point_potion` (Trank der Stärkung: Sturmessenz + Mondlilie) sind Mörser-Rezepte in mortar.json `brews`. Den Hinweis im Tooltip schreibt man in `effect`.
**Ringe:** Ringfassung (`part: "ring_band"`, gegossen aus 1 Barren, nur Silber, Gold, Platin, Palladium; bringt Magieresistenz 2/3/4/5) + geschliffener Edelstein (`part: "gem"`, entsteht am Schleifstein aus einem Kristall mit `"grind_to": "<kristall>_gem"`, ohne Material, mit `attributes`, `resistances` oder `crit_chance`/`crit_damage`) an der Werkbank (Reiter Schmuck » Ringe) = `ring` (Typ `ring`, zwei Ring-Plätze am Helden). Name nach der Fassung („Goldring“), Seltenheit gemischt aus Fassung und Kristall wie bei Rüstung und Leder, zufällige Attribute aus der Seltenheit wie bei Waffen. Neuer Kristall = ein Eintrag mit `"type": "part", "part": "gem"` und einem Bild auf der Ring-Leinwand (Kristall oben, siehe `assets/_reference/jewelry/make_ring_icons.py`). Werkbank-Rezepte mit Teilen, die kein Rezept herstellt (Leder, Kristalle), werden frei, sobald die übrigen Teile herstellbar sind.
**Juweliertisch (Kristall-Schmuck):** Ring- oder Amulettfassung (`part: "ring_band"` / `"amulet_band"`, z. B. `silver_ring_band`, `silver_amulet_band`) + roher Kristall mit `"jewel"` = `jewel_ring` (Typ `ring`) bzw. `jewel_amulet` (Typ `necklace`, Ketten-Platz). Der Kristall nennt bis zu 3 Eigenschaften pro Art mit ihrem Wert bei R1: `"jewel": {"ring": {"lifesteal": 2, "crit_damage": 8, "damage_element": 5}, "amulet": {"max_health": 4, "health_regen": 0.3, "armor": 5}}`. Das Schmuckstück bekommt eine davon zufällig; Seltenheit aus Fassung und Kristall (50/50-Regel), Wert = Kristall-Wert × `economy.json jewelry.rarity_factor` (R1 ×1 … R8 ×4) × `jewelry.metal_factor` des Fassungs-Metalls (Silber 1, Gold 1,2, Platin 1,4, Palladium 1,6). Fassungen gibt es aus Silber, Gold, Platin und Palladium. Name „<Kristall>ring“/„<Kristall>amulett“, Bild `assets/sprites/items/jewelry/<ring|amulet>_<kristall>.png`. Mögliche Eigenschaften (`Jewelry.STATS`, wirken wie passive Skillwerte): Ring `lifesteal`, `armor_pen`, `magic_pen`, `crit_chance`, `crit_damage`, `stun_chance` (jeder Treffer kann betäuben), `cooldown`, `pet_damage`, `damage_element`, `damage_poison`, `damage_slash`, `damage_blunt`, `mana_regen`, `debuff_chance`; Amulett `tenacity`, `evasion`, `health_regen` (% Leben/s), `max_health`, `armor`, `heal_power`, `shield_power`, `element_resist`, `buff_duration` (alle Werte in %, `mana_regen`/`element_resist` als Zahl). Neuer Kristall = nur ein `"jewel"`-Eintrag (+ Bilder im Skript `assets/_reference/jewelry/make_jewel_icons.py`).

## weapon_types.json – Waffentypen

```json
"sword": { "name": "Schwerter", "hands": "one", "station": "workbench", "attack_speed": 1.0 }
```

| Feld | Bedeutung |
|---|---|
| `name` | Name im Plural = Kategorie im Reiter „Waffe“ der Station |
| `hands` | `one` (Einhand), `two` (Zweihand), `either` (in beiden Händen haltbar), `left` (nur linke Hand) |
| `station` | `workbench` (Werkbank) oder `enchanting_table` (Zaubertisch) |
| `attack_anim` | Bewegung des Helden im Kampffenster: `swing` (Schwung), `thrust` (Stich), `slam` (schwerer Schlag von oben), `shoot` (Schuss, Pfeil fliegt), `cast` (Zauber, Kugel fliegt), `lunge` (Sprung). Standard `swing` |
| `attack_speed` | Angriffstempo des Helden mit dieser Waffe (Standard 1 = 1 Schlag pro Sekunde bei `hero_attack_interval` 1). Schwert/Keule 1, Dolch 1.3, Axt 0.9, Hammer/Speer 0.8, Zweihandschwert 0.7, Zweihandaxt 0.65 |

Die Station listet alle ihre Waffentypen in Datei-Reihenfolge, auch wenn es noch kein Rezept dafür gibt („Noch keine Rezepte“). Eine Waffe kommt in die Liste, indem sie in items.json `"weapon_type": "<id>"` bekommt. Zweihand-Waffen (`two`) kommen nur in die rechte Hand und halten die linke frei (kein Schild); wer eine anlegt, bekommt das Teil der linken Hand zurück ins Inventar. `either` (Dolch) wird bisher wie Einhand behandelt (die linke Hand kämpft noch nicht mit).

**Schaden der Teile (Seltenheit R1, ohne Bonus):** Der Waffenschaden ist die Summe der Teile + 2 pro Seltenheitsstufe (Eisen ist R2 = +2). Schwert: Kupferklinge 4–6 / Eisenklinge 6–9, Kupfergriff 0–1 / Eisengriff 3–4 (Eisenschwert 11–15, Eisenklinge + Kupfergriff 8–12, Kupferschwert 4–7). Dolchklinge 1–2 / 2–3 (+5 % Krit), Zweihandklinge 12–16 / 22–28, Speerspitze 11–14 / 22–28, Zweihandaxtkopf 15–20 / 29–36, Axtkopf 5–8 / 12–17, Hammerkopf 8–12 / 18–24, Keulenkopf 3–6 / 7–10. Weitere Metalle = Eisen × Faktor (Bronze 1,25, Silber und Gold 1,5, Platin 1,9, Palladium 2,3). Schnelle Waffen haben wenig Schaden pro Schlag, weil Grundschaden und Stärke bei jedem Schlag dazukommen. Schildplatten: Kupfer 3, Eisen 5 Rüstung. Schilde machen keinen Schaden.

## materials.json

```json
"gold": {"name": "Gold", "ingot": "gold_ingot", "rarity": "R4", "process": "cast"},
"wood": {"name": "Holz", "raw": "wood", "rarity": "R1", "process": "carve"}
```

- `process: "cast"` = Metall: Gussofen (Gussform aus `ingot`) → Amboss.
- `process: "carve"` = an der Werkbank aus 1× `raw` schnitzen (Reiter Zubehör).
- `process: "tan"` = Leder von der Gerberbank, kein Rezept (`rat_leather` „Ratten“ R1, `wolf_leather` „Wolfs“ R2). Rattenleder (id `leather`, Rüstung 1) entspricht Kupfer, Wolfsleder (`wolf_leather`, Rüstung 2) Eisen. Ein Umhang aus 3 Wolfsleder heißt „Wolfslederumhang“.
- `name` wird für Namen benutzt: „Gold“ + „schwert“ = „Goldschwert“, „Heißer Goldbarren“.
- `unlock_flag` (nur Metalle, seit 2026-11-03): Story-Flag, ab dem Erz und Barren dieses Metalls als Beute kommen (Monster-Drops, Boss-Barren, Dungeon-Belohnungen, Zufalls-Gussformen; `GameState.is_loot_unlocked`). Vorher fallen sie einfach weg, das Dungeon-Brett zeigt sie nicht. Ohne Feld = von Anfang an (Kupfer). Eisen `iron_unlocked`, Bronze `volcano_route_open`, Silber `silver_molds_offered`, Gold `gold_molds_unlocked`, Platin `reached_to_swamp`, Palladium `reached_finster_start`.
- **Metall-Stufen** (seit 2026-10-26): Teile aus Bronze haben das 1,6-Fache der Eisen-Werte (Schaden der Waffenteile, Rüstung der Platten), Silber und Gold das 2,3-Fache, Platin 3,0, Palladium 3,8 (Kupfer bleibt etwa 0,55). Platten ab Silber haben zusätzlich Magieresistenz (halb so viel wie ihre Rüstung): Silber und Gold schützen auch vor Feuer und Magie, das braucht man im Vulkan. Zauberstäbe (Stab + Kristall am Zaubertisch), Bogenrahmen und Pfeilteile gibt es aus Eisen, Bronze, Silber und Gold (in den Waffen-Gussform-Sets).

## recipes.json (optional)

Für Rezepte, die nicht automatisch entstehen. Die Datei darf fehlen.

```json
"iron_nails": {
	"station": "anvil",
	"name": "Nägel",
	"ingredients": [{"item": "iron_ingot", "amount": 1}],
	"result": "iron_nails",
	"amount": 10,
	"hot": false,
	"tab": "accessory",
	"category": "Kleinteile",
	"locked": false
}
```

Zutaten: `{"item": id, "amount": n}` oder `{"part": "blade"}` (irgendein Teil dieser Art). Mit `"min_rarity": "R3"` zählen nur Stücke ab dieser Seltenheit (Goblinkrone: 5 Goldbarren ab R3). Mit `"materials": ["copper"]` bei einem Teil zählen nur Teile aus diesen Materialien (Kupfer-Zauberstäbe nehmen nur den Kupferstab); das Rezept wird erst frei, wenn so ein Teil herstellbar ist.

**Rezept-Gruppen:** `"group": "Eisen-Zauberstab"` und `"group_slot": "Kristall"` – alle (freigeschalteten) Rezepte mit demselben `group` stehen an der Station als **ein** Eintrag mit diesem Namen. Die Zutat, die sich zwischen ihnen unterscheidet, bekommt einen Slot mit dem Namen aus `group_slot`, der jedes ihrer Items nimmt; das eingelegte Item entscheidet, welches Rezept gebaut wird. Die Rezepte einer Gruppe müssen gleich viele Zutaten in gleicher Reihenfolge haben. Freischalten, Spielstände und Rezeptbuch arbeiten weiter mit den einzelnen Rezept-ids. Beispiel: die 9 Eisen-Zauberstäbe (Eisenstab + Kristall).

## status_effects.json – Buffs und Debuffs

```json
"poison": {
	"name": "Gift",
	"description": "Verursacht Giftschaden pro Sekunde.",
	"icon": "res://assets/sprites/effects/poison.png",
	"kind": "debuff",
	"duration": 5,
	"stacking": "stack",
	"max_stacks": 10,
	"damage_per_second": 1,
	"element": "poison",
	"color": "#7cc35a"
}
```

| Feld | Bedeutung |
|---|---|
| `icon` | Bild 16×16 für die Buff-Anzeige im Kampffenster |
| `kind` | `buff` oder `debuff` |
| `duration` | Dauer in Sekunden, danach läuft der Effekt aus |
| `stacking` | `stack` = jede neue Anwendung +1 Stapel (bis `max_stacks`) und die Dauer beginnt neu; `refresh` = nur die Dauer beginnt neu |
| `damage_per_second` | Schaden pro Sekunde **und Stapel** (ignoriert Rüstung) |
| `damage_percent_per_second` | % der max. Lebenspunkte des Trägers pro Sekunde **und Stapel** (Gift: 0.75, 7 Stapel = 5,25 %); kommt zu `damage_per_second` dazu, Gift-Boni des Wirkers und Resistenz des Ziels wirken wie bisher |
| `element` | Element des Schadens (`poison`, `fire` …) |
| `damage_from_magic`, `damage_scaling` | Schaden pro Sekunde und Stapel, der mit dem Wirker wächst: X % seines durchschnittlichen Zauberschadens (Magieschaden der Waffe × Faktor des Attributs `damage_scaling`, z. B. `wis`); kommt zu `damage_per_second` dazu (Schmerz des Schattenpriesters: 25, `wis`) |
| `damage_percent_on_expire` | Schaden in % der max. Lebenspunkte, wenn der Effekt ausläuft (Blutung: 5) |
| `heal_percent_per_second` | Heilung in % der max. Lebenspunkte pro Sekunde (Recovery: 3) |
| `block_health_regen` | `true` = keine Lebensregeneration, solange er wirkt |
| `shield_percent` | Schild: fängt Schaden bis zu X % der max. Lebenspunkte ab (verbraucht = weg) |
| `caster_shield` | `true` = Schild aus dem Wirker: Level + 5 × Weisheit (combat.json `shield_per_caster_level`, `shield_per_caster_wis`), wirkt wie Extra-Leben (weiße Leiste im Kampf), verbraucht = weg |
| `attributes` | Attribut-Faktoren, z. B. `{"str": 1.1}` = Stärke +10 % |
| `resistances` | Resistenz-Änderung, solange der Effekt wirkt | `{"fire": 20}` |
| `crit_chance`, `crit_damage` | Krit-Chance / Krit-Schaden in Prozentpunkten, solange er wirkt |
| `armor_percent`, `magic_resistance_percent` | Rüstung / Magieresistenz des Trägers in %, solange er wirkt: `-30` = 30 % weniger (Debuff „Rüstung gebrochen“), `30` = 30 % mehr (Buff „Gepanzert“). Zählt vor der Durchdringung des Angreifers |
| `armor_pen`, `magic_pen`, `armor_pen_flat`, `magic_pen_flat` | Durchdringung der Treffer des Trägers, solange er wirkt (wie bei Items) |
| `attack_speed` | Angriffstempo in %, solange er wirkt (`-30` = 30 % langsamer, `20` = schneller) |
| `stun` | `true` = kann weder angreifen noch Skills einsetzen |
| `taunt` | `true` = Herausforderung: die andere Seite trifft mit Einzelangriffen nur diesen Kämpfer (Flächenangriffe nicht), z. B. Schildbandit |
| `damage_bonus` | Schaden aller Treffer in % (z. B. Bärenblut 40) |
| `evasion` | Chance in %, Treffern (Angriff und Skills) komplett auszuweichen („Ausgewichen“) |
| `lifesteal` | % des eigenen Trefferschadens, der den Träger heilt |
| `cleanse` | `true` = **sofort**: entfernt Debuffs des Ziels (der Effekt bleibt nicht); `cleanse_count` = so viele (die neuesten zuerst), `0` = alle |
| `revive_percent` | **sofort**: belebt einen gefallenen Verbündeten mit X % Leben wieder; ein Skill damit wird nur eingesetzt, wenn jemand gefallen ist |
| `damage_taken` | erlittener Schaden in %: `15` = 15 % mehr (Verwundbar), `-30` = weniger, `-100` = unverwundbar (auch gegen Gift/Brand) |
| `damage_bonus` | negativ = Schwächung, z. B. `-15` = 15 % weniger Schaden |
| `physical_damage`, `magic_damage` | physischer / magischer Schaden des Trägers in % (Segen der Kraft, Segen des Geistes) |
| `extra_damage`, `extra_damage_kind` | jeder Treffer macht zusätzlich X % Schaden dieser Art (Lichtweihe: `20`, `light`) |
| `mana_regen` | Mana pro Sekunde zusätzlich |
| `silence` | `true` = keine Skills (normale Angriffe gehen) |
| `untargetable` | `true` = nicht als Einzelziel angreifbar, Flächenangriffe treffen trotzdem (Verschleiert) |
| `undying` | `true` = fällt nicht unter 1 Leben (Unbeugsam) |
| `stun_immune` | `true` = Betäubungen wirken nicht (Bastion) |
| `thorns` | Angreifer erleiden X % ihres Trefferschadens als Magieschaden (Runenschild) |
| `guard_share` | X % des Schadens, den Verbündete erleiden, nimmt der Träger auf sich (Schutzwall) |
| `heal_percent_on_expire` | Heilung in % der max. Lebenspunkte beim Auslaufen |
| `on_hit_effect`, `on_hit_chance` | jeder Treffer des Trägers setzt diesen Effekt (id) mit X % Chance (Giftklinge) |
| `spread_on_death` | stirbt der Träger, springen Gift und dieser Effekt auf einen anderen Kämpfer seiner Seite (Seuche) |
| `cleave` | `true` = normale Angriffe treffen alle Gegner (Wilde Jagd) |
| `shield_attribute`, `shield_factor` | bei `caster_shield`: Attribut statt Weisheit (z. B. `int`) und Faktor auf den Schild |
| `color` | Farbe des Namens im Kampffenster |
| `aura` | Schleife an den Füßen im Kampf, solange der Effekt wirkt (je Kämpfer der neueste Buff und der neueste Debuff mit Aura): `burn`, `poison`, `bleed`, `frozen`, `slow`, `rage`, `haste`, `holy`, `arcane`, `spirit`, `regen`, `curse`, `up`, `down` (`up`/`down` = Pfeile in `color`). Bild `assets/sprites/battle/vfx/color/aura_<name>.png` (farbig) oder `vfx/aura_<name>.png` (weiß, eingefärbt) |
| `apply_vfx` | Effekt beim Auftragen statt Pfeil hoch/runter, z. B. `cleanse` |

Vorhanden (Auswahl): `poison` (Gift), `bleed` (Blutung), `burn` (Brand), `rage` (Rage), `frenzy` (Raserei), `haste` (Eile), `calm` (Calm), `recovery` (Recovery), `barrier` (Schutzschild), `arcane_barrier` (Arkaner Schild), `stun` (Betäubt), `frozen` (Eingefroren), `silence` (Schweigen), `slow` (Verlangsamt), `rooted` (Verwurzelt), `cripple` (Gelähmt), `weaken` (Geschwächt), `vulnerable` (Verwundbar), `evasion` (Ausweichen), `stealth` (Verschleiert), `lifesteal` (Lebensraub), `arcane_power` (Arkane Kraft), `cleanse` (Läuterung), `resurrection` (Wiederbelebung), `invulnerable` (Unverwundbar). Alle mit Werten: `docs/UEBERSICHT.txt`.

Effekte auf sich selbst (`target: self`) wirken vor dem Treffer des Skills, z. B. zählt der Lebensraub von „Lebensraub“ schon für diesen Schlag.

**Skill → Effekt:** Ein Skill verweist in seiner Liste `effects` auf die id eines Effekts (z. B. `"effect": "bleed"`). So bewirkt Skill X den Status Y, ohne Code.

## skills.json – Skills für Helden und Monster

Derselbe Skill kann von mehreren Klassen und von Monstern benutzt werden.

```json
"deep_cut": {
	"name": "Tiefer Schnitt",
	"description": "Ein Schnitt, der eine Blutung verursacht.",
	"icon": "res://assets/sprites/skills/deep_cut.png",
	"cooldown": 8,
	"mana": 4,
	"damage": 1.0,
	"damage_per_level": 0.15,
	"max_level": 5,
	"damage_kind": "physical",
	"effects": [{"effect": "bleed", "chance": 1.0, "target": "enemy"}],
	"points": 4,
	"tier": 1,
	"requires": "sword_strike"
}
```

Ein Effekt, der pro Stufe stärker wird (Schildbruch: Rüstung −40 % −5 % pro Stufe, 5 s +1 s pro Stufe):

```json
"effects": [{"effect": "armor_break", "chance": 1.0, "target": "enemy",
	"set": {"armor_percent": -40, "duration": 5}, "per_level": {"armor_percent": -5, "duration": 1}}]
```

`set` überschreibt Felder des Effekts (wie in status_effects.json), `per_level` zählt pro weiterer Stufe dazu (auch in Unterlisten, z. B. `{"attributes": {"str": 0.02}}`). Dazu `chance_per_level` (z. B. `0.05` = +5 % Chance pro Stufe).

Ein passiver Skill (wirkt immer, wird nie eingesetzt):

```json
"armored": {
	"name": "Gepanzert",
	"description": "Rüstung +8 % (+8 % pro Stufe).",
	"icon": "res://assets/sprites/skills/default.png",
	"max_level": 5,
	"passive": {"armor": [8, 8]},
	"points": 2,
	"tier": 0
}
```

| Feld | Bedeutung |
|---|---|
| `icon` | Bild 16×16 (optional) |
| `cooldown` | Sekunden bis zum nächsten Einsatz |
| `mana` | Manakosten |
| `damage` | Schaden auf Stufe 1 als Anteil vom Waffenschaden mit Attribut-Bonus (1.5 = 150 %; Zauber: vom Zauberschaden = Grundschaden + Magieschaden der Waffe, × Attribut-Bonus, siehe `scaling`), `0` = kein Schaden (z. B. Buff) |
| `damage_per_level` | wie viel `damage` pro weiterer Stufe dazukommt (Standard 0.15 = +15 %; Schwertschlag Stufe 5 = 150 % + 4 × 15 % = 210 %) |
| `max_level` | höchste Stufe, jede Stufe kostet 1 Skillpunkt (Standard 5) |
| `scaling` | Attribute, mit denen der Schaden des Helden wächst, in Prozent: `{"agi": 100, "str": 40}` (Schnellschuss) oder nur ein Attribut `"wis"` (= 100 %). Die gewichtete Summe (100 % AGI + 40 % STR) zählt bei Waffen-Skills wie Stärke (`damage_per_str` = +0,5 Schaden je Punkt) und bei Zaubern wie Intelligenz (`magic_damage_per_int` = +2 % je Punkt). Standard: Zauber `int`, sonst `str` (= Verhalten vor 2026-11-08). Faustregel: Hauptattribut der Klasse 100, Nebenattribut 30–50 (Magie-Anteil » `int`/`wis`, Körper » `con`, Präzision » `agi`). Monster nutzen nur das größte Attribut |
| `base` | `"weapon"`: ein Zauber (`magic`), dessen Grundwert der Waffenschaden ist statt des Magieschadens eines Stabs (Natur-Skills des Waldläufers mit Bogen, Richtspruch des Paladins mit Hammer); bleibt Magieschaden (gegen Magieresistenz) |
| `weapon_damage` | veraltet, wird nicht mehr benutzt |
| `damage_kind` | `physical` (% vom Waffenschaden, gegen Rüstung) oder `magic` (Zauber, Intelligenz-Bonus, gegen Magieresistenz) |
| `element`, `damage_type` | wie bei Items. Ohne `damage_split` gilt: magischer Skill = 100 % sein Element (oder `magic`), physischer Skill = 100 % sein `damage_type`, sonst wie die Waffe (Schwert = Schnitt) |
| `damage_split` | Aufteilung in Schadensarten, z. B. Feuerschwerthieb `{"fire": 50, "slash": 50}`; `{"true": 100}` = Wahrer Schaden |
| `crit_chance` | zusätzliche Krit-Chance dieses Skills in Prozentpunkten |
| `armor_pen`, `magic_pen` | Durchdringung dieses Skills in %, kommt zur Durchdringung des Helden dazu (Rüstungsdurchbruch: `30` = ignoriert 30 % Rüstung) |
| `armor_pen_flat`, `magic_pen_flat` | Durchdringung in Punkten (zählt nach den %) |
| `target` | `enemy`, `self`, `ally` (der Verbündete mit den wenigsten Lebenspunkten in %, auch man selbst), `all_enemies` (alle lebenden Gegner, Schaden wird für jeden einzeln gewürfelt) oder `all_allies` (alle lebenden Verbündeten, auch man selbst) |
| `effects` | Liste: `effect` (id aus status_effects.json), `chance` (0–1), `target` (`enemy`/`self`/`ally`/`all_enemies`/`all_allies`), optional `stacks`, `duration` (Sekunden, sonst die des Effekts), `chance_per_level`, `set`, `per_level` (siehe oben) |
| `tier` | Reihe im Skillbaum (0 = unten, höhere Reihen wachsen nach oben; im Heldenfenster passen 5 Reihen: 0–4) |
| `points` | Punkte, die vorher **im selben Baum** ausgegeben sein müssen (der letzte Skill eines Baums: 19, damit er mit Lv 40 = 20 Punkten erreichbar ist) |
| `requires`, `requires_also` | Skill, der vorher gelernt sein muss / ein zweiter |
| `passive` | macht den Skill passiv: `{"wert": [Stufe 1, pro Stufe]}`, Werte siehe unten |
| `passive_scaling` | ein Passiv-Wert wächst zusätzlich mit einem Attribut: `{"damage_poison": {"int": 0.5}}` = +0,5 pro Punkt Intelligenz (Attribute `str`, `agi`, `con`, `int`, `wis`, `res`; der Wert muss in `passive` stehen). Ätzende Gifte Stufe 5 mit 100 Intelligenz = +100 % |
| `unlock_weapons` | passiv: `{"right_hand": ["sword"]}` / `"left_hand"`: diese Waffe darf die Klasse in der Hand erst halten, wenn der Skill gelernt ist (Schurke: Schwertkunst, Zwei Schwerter) |
| `heal` | `[%, % pro Stufe]`: heilt die Ziele um so viel ihres max. Lebens (× Heilkraft des Wirkers); reine Heil-Skills warten, bis jemand unter 90 % Leben hat |
| `self_damage` | kostet den Anwender X % seines max. Lebens (PAIN!) |
| `hits`, `random_targets`, `hit_splits` | mehrere Treffer (jeder würfelt Krit und Effekte einzeln) / jeder Treffer auf einen zufälligen Gegner / eigene Aufteilung pro Treffer (Liste, wird reihum benutzt) |
| `chain`, `chain_falloff` | Ziele nacheinander (erstes + Sprünge, `99` = alle) / weniger Schaden pro weiterem Ziel in % (Kettenblitz, Durchschuss) |
| `execute_below`, `execute_factor` | Ziele unter X % Leben erleiden Schaden × Faktor (Hinrichten, Meucheln) |
| `bonus_vs`, `bonus_vs_factor` | gegen Gegner, deren Angriffe diese Schadensart haben (z. B. `dark`), Schaden × Faktor |
| `crit_damage`, `crit_from_stealth` | zusätzlicher Krit-Schaden in % / aus dem Verschleiern immer kritisch |
| `reset_on_kill`, `once_per_dungeon` | tötet der Treffer, ist die Abklingzeit sofort vorbei / nur einmal pro Dungeon |
| `base_from` | Schaden aus eigenen Werten statt aus der Waffe: `{"armor": 0.5, "max_health": 0.08}` (Schildschlag) |
| `summon`, `summon_share`, `summon_duration`, `summon_upgrades` | Beschwörung (id aus summons.json) / `[% der Werte, + pro Stufe]` / Sekunden (`0` = bis zum Tod) / `[{"skill", "summon", "share"}]`: ist der Skill gelernt, kommt stattdessen diese Beschwörung mit `share` % (Wolfsjunges » Wolf » Riesenwolf) |
| `pet_attack`, `pet_effects`, `sacrifice_summon` | die eigene Beschwörung führt den Treffer aus (Fass!) / Effekte auf die Beschwörung / opfert die Beschwörung, Schaden in ihren Schadensarten |
| `detonate` | Effekt-id (z. B. `poison`): Schaden × Stapel dieses Effekts, der Effekt verschwindet (Toxischer Ausbruch) |
| `allies_refresh` | `{"cooldown": Sekunden, "mana_percent": [%, pro Stufe]}`: alle Verbündeten bekommen kürzere Abklingzeiten / Mana (Inspiration, Zeitstillstand) |
| `heal_allies_from_damage` | alle Verbündeten heilen sich um X % des verursachten Schadens |
| `summon_enemies`, `summon_count`, `summon_max` | nur Monster: ruft diese Gegner (enemies.json-ids) in den Kampf, `summon_count` pro Einsatz, solange weniger als `summon_max` von ihnen leben (Morwald: Skelette, Ignar: Glutgeister) |
| `hits_self` | `true` = der Skill trifft auch den Anwender (Lava-Ausbruch: heilt den Lavagolem über `absorb`) |
| `random_ally` | nur Monster: ein Skill mit `"target": "ally"` trifft einen zufälligen lebenden Verbündeten (auch sich selbst) statt des am meisten verletzten (Nebelheilung des Nebelfürsten) |
| `requires_effect` | Effekt-id: der Skill geht nur, solange der Anwender diesen Effekt trägt (Nebelheilung nur `shrouded`) |

**Passive Werte** (`passive`, alle in % außer wo anders angegeben): `max_health`, `armor`, `tenacity`, `evasion`, `crit_chance`, `crit_damage`, `cooldown` (Abklingzeiten kürzer), `buff_duration`, `debuff_duration`, `debuff_chance`, `heal_power`, `mana_regen` (pro Sekunde), `health_regen` (% max. Leben pro Sekunde), `health_regen_flat` (Leben pro Sekunde), `element_resist` (Punkte auf alle Elemente), `magic_pen`, `damage_<art>` für jede Schadensart (`damage_slash`, `damage_blunt`, `damage_stab`, `damage_fire`, `damage_water`, `damage_earth`, `damage_air`, `damage_dark`, `damage_light`, `damage_lightning`, `damage_ice`, `damage_poison`, `damage_magic`; Gift und Brand pro Sekunde zählen mit), `damage_element` (alle Elemente), `arcane_blade` (normale Angriffe + X % Magieschaden), `low_health_damage` und `low_health_lifesteal` (unter 50 % Leben), `parry` (Einzelangriff abwehren), `stealth_damage` (aus dem Verschleiern), `poisoned_target_damage`, `skill_lifesteal`, `offhand` (Waffe in der linken Hand greift mit X % an), `summon_duration` (Sekunden), `bond_damage` und `bond_mana_regen` (solange eine eigene Beschwörung lebt), `pet_damage`, `pet_health`, `pet_guard` (Chance, dass der Wolf einen Angriff abfängt), `aura_armor` (Rüstung der ganzen Gruppe), `martyr` (heilt Verbündete unter 25 % Leben, höchstens alle 20 s). Mit `requires_weapon` zählt ein passiver Skill nur mit dieser Waffe in der Hand.

Im Kampf wird ein Skill automatisch eingesetzt, sobald er bereit ist und genug Mana da ist. Helden versuchen die teuren Skills zuerst: Ein bereiter Skill ab 15 Mana, für den das Mana noch fehlt, hält es für sich zurück (billigere Skills mit Manakosten warten, Heilungen nicht).

## skill_trees.json – Skillbäume der Klassen

Jede Klasse hat drei Bäume. Schlüssel = id der Klasse (`data/hero_classes/<id>.tres`), Reihenfolge der Skills = Reihenfolge im Baum (links nach rechts in einer Reihe). Die Werte stehen in skills.json, der Plan mit allen Zahlen in `docs/SKILLBAEUME.md`.

```json
"warrior": [
	{"id": "sword", "name": "Schwert", "skills": ["sword_strike", "blade_sharpness", "deep_cut", "..."]},
	{"id": "body", "name": "Körper", "skills": ["toughness", "heal_wounds", "..."]},
	{"id": "arcane", "name": "Arkaner Krieger", "skills": ["fire_slash", "..."]}
]
```

`outfit` (seit 2026-11-09): Kleidung der Rolle, z. B. `"outfit": {"outfit": "vest", "clothes_color": "red"}`: Schnitt aus appearance.json `outfits`, Farbe aus `clothes_colors`. Ab 10 Punkten in einem Baum trägt der Held die Kleidung des Baums mit den meisten Punkten (`Hero.ROLE_OUTFIT_POINTS`), der Skill-Reset-Trank nimmt sie wieder weg. Jede Rolle soll anders aussehen (Test `assets/_reference/role_outfits/test_role_outfits.gd` prüft 18 verschiedene).

## summons.json – Beschwörungen

Elementare des Magiers und der Wolf des Waldläufers. Ein Skill ruft sie mit `summon`; sie kämpfen zusätzlich zu den 3 Helden, erben einen Anteil der Werte des Beschwörers (Leben, Schaden, Rüstung, Attribute, Resistenzen) und zählen beim Schaden für ihn.

| Feld | Bedeutung |
|---|---|
| `name` | Name im Kampf |
| `look` | Gegner-id aus enemies.json, deren Bild sie nutzen (gespiegelt, schaut nach rechts) |
| `tint`, `scale` | eigene Farbe / Größe (sonst die des Gegners) |
| `damage_split` | Schadensarten der normalen Angriffe |
| `magic` | `true` = normale Angriffe sind Zauber (aus dem Magieschaden des Beschwörers) |
| `health_factor`, `attack_speed` | Leben × Faktor, Angriffstempo × Faktor |
| `buffable` | `true` = Verbündete können sie heilen und buffen (Wolf), `false` = nicht (Elementare) |
| `skills` | Skill-ids, die sie benutzen (z. B. `elemental_taunt`, `golem_stomp`) |
| `on_hit` | `[{"effect", "chance" (0–1)}]`: Effekte ihrer normalen Angriffe |

## mortar.json – Mörser und Verzauberungstränke

```json
"plant": "moon_lily",
"vial": "vial",
"failed": "ash",
"dusts": {
	"ruby_dust": {"name": "Rubinstaub", "from": "ruby", "color": "#e8503a", "value": 12}
},
"potions": {
	"fire_potion": {"name": "Feuertrank", "crystal": "ruby", "weapon": "enchant_fire", "armor": "ward_fire", "color": "#e8503a", "value": 60}
}
```

- Am Zaubertisch, Reiter **Mörser**: 3 Felder für Zutaten + 1 Feld für die Phiole (`vial`).
- **Zerkleinern:** eine einzelne Zutat ohne Phiole, die in `dusts` als `from` steht, wird zu diesem Staub, mit derselben Seltenheit (Rubin R3 » Rubinstaub R3).
- **Trank:** ein Kristall (`potions.<id>.crystal`, es geht auch ein anderes Item, z. B. die Harpyienfeder beim Federtrank) oder sein Staub + die Pflanze oder ihr Staub + Phiole. Die Pflanze ist `plant` oben (Mondlilie), außer der Trank nennt eine eigene (`potions.<id>.plant`, z. B. `"nightshade"` = Fluch, `"sunflower"` = Segen). Die Seltenheit mischt sich aus den Zutaten wie bei Rüstungen (`Crafting.roll_mixed_rarity`). Jede andere Mischung mit Phiole misslingt: alles ist weg, übrig bleibt 1 `failed` (Asche, Dünger).
- **Drittes Feld:** derselbe Kristall noch einmal = starker Trank (eine Seltenheit besser, `Enchanting.STRONG_TIERS`); zwei verschiedene Kristalle + Pflanze = Kombi-Trank, wenn es einen mit `"crystal2"` gibt (`{"crystal": "ruby", "crystal2": "topaz", "weapon": "combo_magma", ...}`, Reihenfolge egal), sonst Asche.
- **Geheime Tränke:** Tränke mit eigener Pflanze oder `crystal2` stehen erst im Rezeptbuch, am Tisch und im Charakterfenster, wenn sie einmal gebraut wurden (Flag `potion_found_<id>`); vorher zeigt der Mörser „???“. Kundenwünsche nehmen nur die gewöhnlichen Tränke.
- **Vollmond und Rühren:** Bei Vollmond (calendar.json) gebraute Verzauberungstränke sind eine Seltenheit besser. Jede Mischung mit Phiole wird erst gerührt (Minispiel `StirringMinigame`): klumpig = eine Seltenheit schlechter (nie unter die eigene des Items), gut = gleich, perfekt = eine besser; gilt auch für die weiteren Tränke (`brews`).
- Staub und Tränke sind **Items mit derselben id** (darf es in items.json nicht geben); `color` färbt das Standard-Bild, `icon` = eigenes Bild.
- Reiter **Verzaubern**: Trank auf eine Waffe (Bonus `weapon`) oder ein Rüstungsteil/Schild (Bonus `armor`), beides aus sockets.json mit `"enchant": true`. Fehlt einer der beiden, wirkt der Trank nur auf den anderen (Federtrank: nur `weapon`). Stufe des Bonus = Seltenheit des Tranks (R1 = Stufe 1, Legendär = Stufe 7). Ein Item hat nur eine Verzauberung, ein neuer Trank ersetzt sie (`InventorySlot.enchantment`, zählt wie ein Sockel in alle Werte).
- Die Trank-Rezepte stehen am Tisch und im Rezeptbuch (Reiter Mörser), sobald der Spieler Aurelius' Notizen hat (Flag `enchanting_book_owned`).
- **Weitere Tränke** (`brews.<id>`): `ingredients` (Item-ids, eine pro Feld, Staub zählt wie die Zutat; dieselbe Zutat darf mehrmals stehen), `rarity_from` (der Trank bekommt die Seltenheit dieser Zutat, bei mehreren die niedrigste), `name`, `description`, `effect`, `color`/`icon`, `value`, `stack`. Heldentrank: `hero_potion` (z. B. `"iq"`), `hero_potion_value`, `hero_potion_per_rarity` (pro Stufe über R1). Qualitätstrank: `quality_points`, `quality_per_rarity` – kommt am Zaubertisch (Reiter Verzaubern) ins Trank-Feld, 100 Punkte = eine Seltenheit höher. Würfeltrank: `reroll` = `attributes` (Zufalls-Attribute neu, Werte bleiben) oder `sockets` (alle Sockel neu, Bonus und Stufe), ebenfalls ins Trank-Feld, beliebig oft (Trank des Wandels, Funkentrank). Beispiele: Klarkopf-Trank (Kamille + Salbei), Mondweisheits-Elixier (+ Mondlilie), Mondglanz-Trank (3 Mondlilien). `locked: true`: erst brau- und sichtbar, wenn die Story `unlock_recipes:<id>` ausführt (vorher gibt die Mischung Asche). Steht die id schon in items.json und fehlt `name`, braut der Mörser genau dieses Item (Story-Tränke: `seers_brew` = Irrlichtglut + Moorherz + Hydraschuppe, `starlight_tonic` = Mondlilie + Hanf + Kamille). Die Felder `hero_potion_value` usw. gehen auch in items.json.

## achievements.json – Erfolge

```json
"categories": { "dungeons": { "name": "Dungeons" } },
"achievements": {
	"rat_king": { "name": "Königsmord", "description": "Besiege den Rattenkönig.", "category": "dungeons",
		"counter": "kill:rat_king", "levels": [1, 5, 50, 100, 200], "enemy": "rat_king" },
	"set_copper": { "name": "Kupferset", "description": "...", "category": "forging",
		"all": ["made:weapon:copper", "made:helmet:copper", "made:shoulders:copper", "made:armor:copper", "made:gloves:copper", "made:boots:copper"] },
	"story_rented": { "name": "Ein eigenes Dach", "description": "...", "category": "story", "flag": "smithy_rented", "secret": true }
}
```

| Feld | Bedeutung |
|---|---|
| `categories` | Kategorien in der Reihenfolge im Fenster: `name` |
| `name`, `description` | Titel und Text im Tooltip (was man tun muss) |
| `category` | id aus `categories` |
| `counter` + `levels` | Zähler und Ziele der Stufen (1–5 Einträge; der letzte = „max lv“) |
| `all` | Liste von Zählern, die alle mindestens 1 sein müssen (eine Stufe, Fortschritt „3 / 6“) |
| `flag` | Story-Flag (z. B. `smithy_rented`, `reached_<schritt>`), eine Stufe |
| `secret` | `true` = bis zur ersten Stufe nur `[?]`, Tooltip „Geheimer Erfolg“ |
| `icon` / `item` / `enemy` | Bild: Pfad, oder Icon eines Items bzw. Bild eines Gegners (id) |
| `steam_id` | Name bei Steam statt der id (Großbuchstaben); nie mehr ändern, sobald bei Steam angelegt |
| `steam` | `false` = nicht zu Steam |
| `steam_stat` | Steam-Statistik für den Fortschritt (z. B. `STAT_RATS`) |
| `steam` (oben in der Datei) | `enabled`, `app_id`, `name_pattern`, `single_pattern` – Anbindung an Steam, siehe `docs/STEAM.md` |

**Zähler, die das Spiel schon zählt:** `forge`, `forge:<item>` (Amboss), `forge_perfect` (Amboss, alle Schläge grün), `craft`, `craft:<item>` (Werkbank), `made:<typ>:<material>` (Ausrüstung von der Werkbank; typ = `weapon`, `helmet`, `shoulders`, `armor`, `gloves`, `boots`, `shield`, `cloak`; material = Material der Platte/Klinge), `smelt` (Barren), `rock` (Erz/Stein abgebaut), `kill`, `kill:<gegner>` (alle Helden zusammen), `dungeon`, `dungeon:<id>` (geschafft), `order` (Kundenauftrag), `sold` (Ninas/eigener Laden), `flag:<flag>`. Neuer Erfolg mit diesen Zählern = nur ein Eintrag in der Datei. Braucht ein Erfolg etwas, das noch nicht gezählt wird, an der passenden Stelle `GameState.achievements.count("<name>")` aufrufen.

## npcs.json – feste Dorfbewohner

Gelesen als `NpcInfo` (`scripts/resources/npc_info.gd`). Unbekannte oder falsch getippte Felder (z. B. `jbo` statt `job`, Text statt Zahl) meldet das Spiel beim Start als Fehler; Felder, die mit `_` beginnen, sind Notizen.

```json
"gustav": {
	"name": "Gustav",
	"job": "Bergmann",
	"partner": "erna",
	"home": {"scene": "village_center", "door": "DoorFarmhouse"},
	"look": {"race": "human", "skin": "tan", "hair_style": "bald", "hair_color": "white", "eye_type": "narrow", "eye_color": "grey", "size": "small"},
	"day": [7, 22],
	"work": {"scene": "mine_entrance", "leave_by": "LeaveSouth", "from": 8, "until": 21}
}
```

- `home.door`: Name eines Tür-Spots (`VillagerSpot`, Art DOOR, unter `Spots`) in der Wohn-Szene; dort kommt die Figur morgens heraus und geht abends hinein.
- `day`: Stunden draußen, sonst im Haus (Werte über 24 = nach Mitternacht). Ohne `day` kein Tagesablauf (nur Wohnort-Info für später, z. B. Oma, Nina, Holger, Hedwig).
- `work`: in dieser Zeit ist die Figur bei der Arbeit in einer anderen Szene; sie geht über den Ausgangs-Spot `leave_by` (unter dem Knoten `Exits` der Wohn-Szene) weg und kommt dort zurück. Ein Marktstand mit `npc_id` (`Merchant`) ist nur in dieser Zeit besetzt, sonst „geschlossen“.
- In der Wohn-Szene steht die Figur als `villager.tscn` mit Skript `resident.gd` (`npc_id`, `spots`, `roads`, `exits`).
- `roam` (Story-Figuren, die durchs Dorf ziehen, z. B. Lotte): `{"flag": "hilde_dead", "day": [8, 20], "slot_hours": 3, "spots": {"home": 2, "smithy": 2, "village_center": 2, "market": 2, "nina_shop": 1}}`. Vor `flag` ist die Figur immer zu Hause (`home`), danach außerhalb von `day` auch; tagsüber alle `slot_hours` Stunden an einem gewürfelten Ort (Gewicht = wie oft). Jeder Ort braucht in seiner Szene einen `StoryNpc` mit dieser `npc_id` und `roam_spot` = Ortsname.
- `visits` (Figuren, die nur an bestimmten Tagen kommen, z. B. Baumeister Konrad, Szene `builder_npc.tscn`): `{"flag": "builder_weekly", "weekdays": [1, 3], "hours": [8, 18]}` (Wochentage: 0 = Montag). Vor `flag` ist die Figur jeden Tag da. Der Kalender vermerkt die Tage.
- `sleeps` (nur `goblin_king`): `{"weekday": 2, "every_weeks": 2, "week": 0, "text": "…"}` – an diesem Wochentag (0 = Montag) jede `every_weeks`-te Woche (ab Spielbeginn gezählt, Start bei Woche `week`) schläft der Goblinkönig, die Menge lässt keinen durch, `text` erscheint als Meldung.

## sockets.json – Sockel-Boni

Boni mit `"enchant": true` kommen nur über Verzauberungstränke (mortar.json) ins Item und nie zufällig in einen Sockel (`enchant_<element>` für Waffen, `ward_<element>` für Rüstungen, 8 Stufen = R1 bis R8).

Jedes Ausrüstungsteil kann bis zu **4 Sockel** haben (`InventorySlot.MAX_SOCKETS`), in jedem steckt ein Bonus mit einer Stufe 1–9. Wie Boni ins Item kommen, kommt später (im Code: `stack.add_socket(Socket.roll_for(stack.item))` würfelt einen passenden Bonus mit Stufe). Die Werte wirken sofort in Schaden, Rüstung, Attributen, Resistenzen und Krit, also auch im Kampf und im Tooltip („Sockel: Wucht 3: +12 % Stumpf-Schaden“).

```json
"blunt_damage": {
	"name": "Wucht",
	"effect": "extra_damage",
	"kind": "blunt",
	"levels": [4, 8, 12, 16, 20],
	"chances": [30, 25, 20, 15, 10],
	"slots": ["weapon"]
}
```

| Feld | Bedeutung |
|---|---|
| `name` | Name im Tooltip |
| `effect` | `on_hit` (Waffe: Wert % Chance, dass ein körperlicher Treffer den Status-Effekt `status` auslöst, z. B. Feuerfluch = Brand), `combo` (mehrere Boni auf einmal: `combo` = Liste von Bonus-ids, jeder mit `combo_factor` seines Werts, z. B. Magma = Feuer- und Erdschaden je 70 %; `levels`/`chances` kommen von den Teilen), `extra_damage` (Waffe: +Wert % des Schadens zusätzlich als Art `kind`; Kupferschwert 10–15 Schnitt + Wucht 20 = 10–15 Schnitt und 2–3 Stumpf), `damage_percent` (+Wert % Schaden), `attribute` (+Wert Punkte in `attribute`), `resistance` (+Wert Resistenz gegen `kind`), `armor_percent` (+Wert % Rüstung des Teils), `magic_resistance`, `crit_chance`, `crit_damage` (Prozentpunkte), `attack_speed` (Waffe: +Wert % Angriffstempo, 10 = 1,1-mal so schnell; Federtrank) |
| `kind` | nur `extra_damage` / `resistance`: Schadensart (siehe „Schadensarten“) |
| `attribute` | nur `attribute`: `str`, `agi`, `con`, `int`, `wis`, `res` |
| `status` | nur `on_hit`: id aus status_effects.json (z. B. `burn`, `frozen`, `stun`) |
| `combo`, `combo_factor` | nur `combo`: Bonus-ids der Teile und ihr Anteil (0.7 = 70 %) |
| `levels` | Wert pro Stufe, 1 bis 9 Zahlen: `[2, 4, 5, 6, 8]` = Stufe 1–5 |
| `chances` | Gewicht pro Stufe, gleich viele wie `levels`: `[30, 20, 20, 20, 10]` = 30 % Stufe 1, 10 % Stufe 5 (wird auf 100 % umgerechnet) |
| `slots` | wo der Bonus hinein darf: Item-Typen (`weapon`, `shield`, `armor`, `helmet`, `shoulders`, `boots`, `gloves`, `cloak`, `legs`, `necklace`, `ring`, `shoes` …), Gruppen `armor_all` (alle Rüstungsteile ohne Schild), `jewelry` (Halskette + Ring), `hero_equipment` (alles, was Helden tragen) oder ein Waffentyp: `"weapon:hammer"` |

Neuer Bonus = neuer Eintrag, kein Code. Nur eine neue **Art** von Effekt braucht Code (`SocketBonus.Effect` und die passende Stelle in `InventorySlot`).

## forging_patterns.json – Amboss-Minispiel

Ein Muster legt fest, was beim Schmieden auf dem Amboss zu sehen ist und wo man draufhauen muss.

```json
"blade": {
	"name": "Klinge",
	"image": "res://assets/sprites/forging/blade.png",
	"spots": [
		{"x": 20, "y": 36, "w": 9, "h": 7},
		{"x": 32, "y": 29, "w": 9, "h": 7}
	]
}
```

| Feld | Bedeutung |
|---|---|
| `name` | Anzeigename (nur zur Übersicht) |
| `image` | Bild des glühenden Teils, **80×48 px** (im Spiel doppelt so groß); fehlt es: `default.png` |
| `spots` | Schlagflächen (Ellipsen) in der Reihenfolge, in der sie aufleuchten: `x`, `y` = Mittelpunkt, `w`, `h` = Breite und Höhe, alles in Pixeln des 80×48-Bildes (0,0 = oben links). Gibt es mehr Schläge als Flächen (Skills), geht es wieder von vorne los |

**Welches Muster ein Item bekommt:** das eigene `forging_pattern` aus items.json, sonst das Muster, dessen id wie der Teil-Typ heißt (`blade`, `handle`, `axe_head`, `greataxe_head`, `dagger_blade`, `greatsword_blade`, `spear_head`, `hammer_head`, `mace_head`, `shield_plate`, `pickaxe_head`), sonst `default`. Ein neues Teil derselben Art (z. B. Goldklinge) braucht also nichts; ein Unique-Gegenstand bekommt ein eigenes Muster:

1. Bild zeichnen (80×48, Teil glühend orange, Rest transparent) und unter `assets/sprites/forging/` ablegen – oder in `assets/_reference/forging/bake_patterns.py` eine Form ergänzen und das Skript ausführen.
2. In `forging_patterns.json` einen Eintrag mit eigener id anlegen, Flächen eintragen (Pixel-Koordinaten z. B. in Aseprite ablesen).
3. Im Item `"forging_pattern": "<id>"` setzen.

## enemies.json – Monster und Gegner

```json
"rat": {
	"name": "Ratte",
	"level": 1,
	"exp": 3,
	"sprite": {"path": "res://assets/sprites/enemies/rat.png", "frame_size": [16, 16], "frames": 1, "fps": 4},
	"hp": [7, 10],
	"mana": 0,
	"damage": [2, 2],
	"attack_interval": 1.0,
	"armor": 0,
	"attributes": {"str": 2},
	"drops": [
		{"item": "copper_ore", "chance": 0.15, "amount": [1, 2]},
		{"item": "rat_fur", "chance": 0.05, "rarity": {"R2": 0.1}}
	],
	"skills": ["poison_bite"]
}
```

| Feld | Bedeutung |
|---|---|
| `level` | Grund-Level (wird angezeigt, zählt für die Kill-EXP) |
| `exp` | EXP, die **jeder lebende Held** pro Kill sofort bekommt (auch bei Niederlage). Ist das Monster mindestens 5 Level über dem Helden: ×1,5, mindestens 5 darunter: ×0,5 (`kill_exp_level_gap`, `kill_exp_higher_factor`, `kill_exp_lower_factor` in combat.json) |
| `sprite` | Bild mit den Animations-Bildern nebeneinander (`frame_size`, `frames`, `fps`); `frames: 1` = Standbild. Optional `anims`: Bilder, die im Kampf einmal abgespielt werden (gleiche `frame_size`), Schlüssel = Skill-id oder Pose (`lunge` = normaler Angriff, `cast`, `slam` …), dazu `hit` (getroffen) und `death` (bleibt auf dem letzten Bild liegen, statt Rauchwolke): `"anims": {"lunge": {"path": "...", "frames": 8, "fps": 12}}` (Beispiel: `volcano_dragon`). Eine Animation darf größere Bilder haben als `frame_size` (eigenes `"frame_size": [288, 96]`, z. B. Feueratem mit Platz für die Flamme): links und rechts gleich viel Rand, dann bleibt das Monster an seinem Platz |
| `faces_right` | `true` = die Bilder schauen nach rechts: der Kampf spiegelt sie (alle Bilder, auch `anims`), damit das Monster nach links zu den Helden schaut; als Beschwörung (`look`) schaut es dann ohne Spiegeln nach rechts. Gegnerbilder sollen nach links schauen, das Feld ist für neue Bilder, die falsch herum kommen |
| `hp`, `damage` | Zahl oder `[von, bis]` |
| `mana`, `armor`, `attack_interval` | Mana, Rüstung, Sekunden zwischen zwei Schlägen |
| `row` | `"back"` = hintere Reihe (z. B. Bogenschützen): Einzelangriffe der Helden treffen sie erst, wenn vorne kein Gegner mehr lebt, Flächenangriffe immer; im Kampf ganz rechts |
| `summon` | Boss ruft Hilfe: `{"every_percent": 25, "count": 2, "enemies": [ids]}` = bei 75 %, 50 % und 25 % Leben je 2 zufällige Gegner aus der Liste (Varrik) |
| `summon_shout` | was der Gegner ruft, wenn er Hilfe holt (Standard „Zu mir, Jungs!“) |
| `absorb` | Schadensarten, die ihn heilen statt verletzen, in %: `{"fire": 100}` (Lavagolem, auch Brand heilt ihn) |
| `shroud` | Effekt-id (z. B. `"shrouded"`): trägt ihn, solange ein anderer Gegner lebt (mit `untargetable` und `damage_taken: -100` = gar nicht zu treffen, auch nicht mit Flächenangriffen); allein verliert er ihn, und seine Skills mit `summon_enemies` kühlen neu ab (Nebelfürst) |
| `split` | teilt sich, statt zu sterben: `{"below_percent": 25, "count": 2, "share_percent": 50, "size": 0.75, "times": 2}` = unter 25 % Leben (oder auf einen Schlag getötet) gilt er als besiegt (EXP, Beute) und 2 Teile mit 50 % seines Lebens und Schadens kommen, Bild × 0,75; die Teile teilen sich noch einmal, die letzten sterben normal (Moorschleim) |
| `regrow` | wächst nach, solange ein anderer Gegner derselben Gruppe lebt: `{"group": "hydra", "seconds": 30, "health_percent": [50, 25], "text": "Der Kopf wächst nach!"}` = gefallen wartet er 30 s (Sekunden stehen im Kampffenster), dann kommt er mit 50 % Leben zurück, beim nächsten Mal mit 25 % (der letzte Wert gilt weiter). Sind alle der Gruppe gleichzeitig unten, bleiben sie liegen; Beute und EXP erst dann (Köpfe der Hydra) |
| `body`, `body_label` | mehrere Gegner mit demselben `body` (z. B. `"hydra"`) stehen im Kampffenster als **ein** Bild an einer Stelle, darüber ein Lebensbalken pro Gegner (der erste oben), links davon `body_label` (z. B. „Biss“). Jeder bleibt ein eigener Gegner mit Leben, Angriffen und Ziel; Klick auf seinen Balken = gezielt angreifen. Das Bild verschwindet erst, wenn alle unten sind (Köpfe der Hydra) |
| `phases` | weitere Lebensbalken eines Bosses: Liste von `{"name", "text" (Ruf beim Wechsel), "hp", "damage", "magic_damage", "attack_interval", "armor", "magic_resistance", "hp_regen", "mana_regen", "scale", "skills"}` – was fehlt, bleibt wie vorher. Ist ein Balken leer, beginnt die nächste Phase mit vollem Leben (Morwald 1 Phase, Ignar 2). Im Kampf zeigen Kästchen über dem Lebensbalken, wie viele Balken übrig sind |
| `drops` mit Waffe | `"item": "sword:copper_blade+copper_handle"` = eine ganze Waffe mit ihren Teilen (Banditen) |
| `magic_resistance` | Magieresistenz (verringert Zauber- und Element-Schaden wie Rüstung) |
| `hp_regen`, `mana_regen` | Regeneration pro Sekunde (Standard 0) |
| `attributes` | `str`, `agi`, `con`, `int`, `wis`, `res` – wirken über combat.json |
| `drops` | Liste: `item`, `chance` (0–1), `amount` (Zahl oder `[von, bis]`), optional `rarity` = Chance auf eine bessere Seltenheit, z. B. `{"R2": 0.1}` (10 % R2, sonst die Seltenheit des Items; mehrere Stufen werden von der höchsten aus geprüft). Die Beute fällt im Kampffenster aus dem Monster, die Helden sammeln sie ein; bei Sieg kommt sie in die Truhe |
| `skills` | Skill-ids aus skills.json |
| `damage_type` / `damage_split` | Art des normalen Schlags (Standard `physical`), z. B. `"stab"` oder `{"fire": 100}` |
| `magic_damage` | Magieschaden für magische Skills (Zahl oder `[von, bis]`) |
| `resistances` | Resistenzen, z. B. `{"slash": 10, "fire": -20}` (Feuer-Schwäche) |
| `crit_chance` | zusätzliche Krit-Chance in Prozentpunkten |
| `scale` | Größe im Kampf im Vergleich zu einem normalen Monster (Standard 1, z. B. `1.5` Mini-Boss, `2` Boss) |
| `tint` | Farbe, mit der das Bild eingefärbt wird (Standard `#ffffff` = unverändert), z. B. um einen Boss von normalen Ratten zu unterscheiden |

Monster sollten nach **links** schauen (zu den Helden). Welche Monster wo vorkommen, steht in dungeons.json.

## dungeons.json – Dungeons

```json
"rat_nest": {
	"name": "Rattennest",
	"region": "Stadt",
	"description": "Tief unter dem Keller hausen größere Ratten – und ihr König.",
	"level": 5,
	"background": "res://assets/sprites/battle/rat_cellar.png",
	"stages": 11,
	"time_limit": 300,
	"enemies": {
		"count": [2, 3],
		"pool": [
			{"enemy": "rat", "chance": 80},
			{"enemy": "giant_rat", "chance": 20, "from_stage": 6}
		]
	},
	"special_stages": {
		"5": {"type": "mini_boss", "fixed": ["giant_rat"], "count": [0, 1]},
		"11": {"type": "boss", "fixed": ["rat_king"], "count": [2, 2], "pool": [{"enemy": "rat"}]}
	},
	"rewards": {
		"gold": {"amount": [60, 100], "chance": 0.7},
		"exp": {"amount": [130, 170], "chance": 0.9},
		"items": [
			{"item": "iron_ore", "amount": 3, "chance": 0.5},
			{"item": "feather", "amount": 1, "chance": 0.3}
		],
		"random_mold": {"material": "iron", "chance": 0.5}
	}
}
```

| Feld | Bedeutung |
|---|---|
| `name`, `description` | Name und Text auf dem Dungeon-Brett (Stufen, Level, Zeitlimit und Gegner ergänzt das Brett selbst) |
| `region` | Reiter auf dem Dungeon-Brett, unter dem der Dungeon steht (Standard `"Stadt"`); neue Gegend = neuer Name, der Reiter entsteht automatisch |
| `level` | empfohlenes Helden-Level (Anzeige, Sortierung auf dem Brett) |
| `required_flag` | optional: Story-Flag, ab dem der Dungeon auf dem Brett steht (z. B. `"rat_nest_unlocked"`); weglassen = immer da |
| `rewards.exp` | PEXP für den **Spieler** beim Abschließen (Helden leveln nur über die `exp` der getöteten Monster) |
| `cost` | Gold, das der Spieler pro Raid den Helden zahlt (Stadt 10–20, Wald 30–40); Gold-Belohnungen gibt es keine mehr (`rewards.gold` ginge technisch noch) |
| `free_until_won` | `true` = kostenlos, bis der Dungeon einmal gewonnen wurde (der erste Dungeon der Story, Rattenkeller) |
| `stamina` | optional: Ausdauer, die jeder Held für einen Raid braucht und verbraucht (Standard `dungeon_stamina` aus combat.json = 20) |
| `hidden` | optional: `true` = nie auf dem Brett, nur die Story startet ihn (Aktion `start_adventure`, z. B. `mine_rats` in Kapitel 6) |
| `gone_flag` | optional: ab diesem Story-Flag ist der Dungeon vom Brett (Quest-Dungeon, z. B. Gosse IV: `varrik_defeated`) – aber nur, wenn er nie geschafft wurde. Jeder einmal geschaffte Dungeon (auch `hidden`) bleibt für immer auf dem Brett; Story-Gegenstände (`story_item`) droppen nur beim ersten Sieg |
| `required_dungeon` | optional: id eines anderen Dungeons, den die Helden erst einmal geschafft haben müssen (Dungeons eines Reiters nacheinander, z. B. Katakomben nach `capital_sewers`); gezählt über den Erfolgs-Zähler `dungeon:<id>`, alte Spielstände zählen mit |
| `background` | Bild hinter dem Kampf (Seitenansicht, z. B. 192×112, muss sich links/rechts nahtlos wiederholen) |
| `stages` | Anzahl der Stufen |
| `enemy_scale` | optional: `{"health": 1.5, "damage": 1.5}` = alle Monster dieses Dungeons haben 50 % mehr Leben und Schaden (Treffer, Zauber, Boss-Phasen) als in enemies.json, ihre Kill-EXP wächst mit dem Lebens-Faktor. So werden die Dungeons einer neuen Erz-Stufe härter, ohne Monster zu kopieren. Werte per Simulator (`assets/_reference/balancing/sim_party.gd`, Modus `tune`) |
| `time_limit` | Sekunden für alle Stufen zusammen; danach ist das Abenteuer gescheitert. Weglassen = 300 (5 Minuten), `0` = kein Limit |
| `enemies` | die **Welle** jeder normalen Stufe (siehe unten) |
| `special_stages` | Stufen mit eigener Welle: `"Stufennummer": Welle` – z. B. Mini-Boss auf 5, Boss auf 11 |
| `rewards` | bei Sieg, jede Belohnung mit eigener Chance (ein Lauf kann also nichts, nur EXP, Gold und EXP oder alles bringen): `gold` und `exp` als Zahl, `[von, bis]` oder `{"amount": [von, bis], "chance": 0–1}` (jeder Held bekommt die volle EXP; seit 2026-10-20 haben alle Dungeons die EXP ohne `chance`, also immer bei Sieg), `items` (Liste: `item`, `amount` als Zahl oder `[von, bis]`, optional `chance` 0–1), `recipes` (Rezept-ids, die freigeschaltet werden), `random_mold` (`{"material": "copper", "chance": 0–1}`: eine zufällige, noch unbekannte Gussform dieses Metalls samt Amboss-Rezept; Werkbank-Waffen, deren Teile jetzt alle herstellbar sind, werden mit freigeschaltet; kennt man alle, gibt es keine mehr), `drop_factor` (Faktor auf die Drop-Chancen der normalen Monster in diesem Dungeon, Bosse und Mini-Bosse behalten ihre; z. B. `0.5` im Vulkan und auf dem Sturmgipfel), `boss_ingot` (Barren-id, den der Endboss mit Glück fallen lässt, einmal pro Lauf, z. B. `"iron_ingot"`: immer das Metall des Story-Teils, siehe docs/SYSTEME.md „Erz-Reihenfolge“; weglassen = keiner), `early_metals` (Metall-ids, deren Erz und Barren dieser Dungeon schon gibt, bevor die Story das Metall freischaltet, z. B. `["gold"]` in der vergessenen Gießerei vor der Wüste). Das Brett zeigt alles als Icons, Menge und Chance im Tooltip |

**Welle** (in `enemies` und jeder Spezial-Stufe):

| Feld | Bedeutung |
|---|---|
| `type` | `normal`, `mini_boss` oder `boss` (wird im Kampf und auf dem Brett angezeigt) |
| `fixed` | Gegner-ids, die **immer** kommen (z. B. der Boss) |
| `count` | wie viele Gegner **zusätzlich** zufällig aus dem Pool kommen: Zahl oder `[von, bis]` (Standard 1, mit `fixed` 0) |
| `pool` | Liste möglicher Gegner: `enemy` (id), `chance` (Gewicht: 80 und 20 = 80 % und 20 %; Standard 1), optional `from_stage` / `to_stage` (nur ab / bis zu dieser Stufe) |

Hat eine Spezial-Stufe keinen eigenen `pool`, kommen ihre zusätzlichen Gegner aus dem `pool` von `enemies`. Belohnungen gibt es nur, wenn alle Stufen rechtzeitig geschafft sind; die Beute der Monster (`drops` in enemies.json) kommt dazu. Alles landet in der Belohnungs-Truhe. Neuer Dungeon = neuer Eintrag hier, er erscheint automatisch auf dem Dungeon-Brett.

## economy.json – Preise, Kunden, Ruf

Preise entstehen aus dem `value` der Items (Barren, Kohle, Holz) und diesen Faktoren:

| Abschnitt / Wert | Bedeutung | Standard |
|---|---|---|
| `prices.fuel_item`, `prices.fuel_per_cast_part` | Brennstoff, der pro gegossenem Teil mitgerechnet wird | `"coal"`, `2` |
| `prices.work_share` | Arbeitslohn als Anteil der Materialkosten | `0.5` = 50 % |
| `prices.order_bonus` | Bonus für einen Auftrag | `0.2` = 20 % |
| `prices.order_base_gold` | fester Betrag pro Auftrag (vor Seltenheits- und Ruf-Bonus) | `65` |
| `prices.order_gold_per_tier` | Gold pro Teil und Materialstufe (Holz 0, Kupfer 1, Eisen 2 …) | `6` |
| `prices.order_min_gold` | so viel Gold gibt ein Auftrag mindestens | `90` |
| `prices.rarity_bonus_per_step` | mehr Geld pro Seltenheitsstufe über der des Metalls | `0.25` |
| `prices.experience_per_gold` | EXP pro Gold der Bezahlung | `0.2` |
| `skill_reset.gold_per_point` | Gold pro ausgegebenem Skillpunkt, wenn der Spieler seine Skills zurücksetzt (Charakter-Fenster » Skills) | `50` |
| `customers.arrive_from_hour`, `arrive_until_hour`, `leave_hour` | wann Kunden kommen und gehen | `9`, `18`, `20` |
| `customers.order_days` | Frist in Tagen `[von, bis]` | `[2, 4]` |
| `customers.same_material_chance` | Chance, dass alle Teile aus demselben Metall sein sollen | `0.7` |
| `customers.order_stations` | Stationen, deren Rezepte Kunden bestellen (gekaufte nur, wenn sie da sind) | `["workbench", "bow_table", "enchanting_table"]` |
| `customers.raw_parts` | Teile ohne eigenes Rezept (Leder) » ab welchem Story-Flag Kunden sie verlangen (`""` = immer) | `{"leather": "", "wolf_leather": "forest_den_unlocked"}` |
| `customers.order_kinds` | Arten von Aufträgen `{big, normal, small}`: `chance`, `pay` (Gold-Faktor), `title` (Wort vor dem Titel). Seltenheit: Glocke von R1 bis zur besten selbst gebauten Stufe dieser Waffe in diesem Metall (R5 gebaut: R3 am häufigsten, R2 = R4, R1 = R5 am seltensten); `big` nur obere Hälfte und bestes Metall, `small` immer R1 und billigstes Metall | 0,3 / 0,4 / 0,3; × 1,8 / 1 / 0,55 |
| `knight_orders` | Ritter der Stadtwache nach Hagens Rüstung (`flag`): `name`, `appearance_seed`, `resident` (PixelLab-Figur, geht vor), `arrive_hour`, `order_days`, `kinds {easy, good, hard: chance, rarity [von, bis], pay, extra_chance, enchant_chance, extra_bonus, title}`; Extra = Attribut (Wert wie bei Stücken dieser Seltenheit) und/oder Verzauberung, erfüllt gibt es `extra_bonus` × Gold dazu | siehe Datei |
| `customers.min_per_day` | So viele Kunden kommen mindestens pro Tag (auch wenn der Ruf-Rang weniger würfelt) | `1` |
| `customers.rush_chance` | Chance pro Tag, dass der erste Kunde einen Eilauftrag bringt | `0.5` |
| `customers.rush_days` / `rush_pay` | Frist des Eilauftrags in Tagen / Gold-Faktor | `2` / `1.5` |
| `customers.names` | Namen der Kunden | |
| `reputation.ranks` | Ruf-Ränge von unten nach oben (F, E, D, C, B, A, S, S+): `id`, `from` (Punkte), `required_flag` (Story-Flag, vorher bleibt der Rang gesperrt, Punkte zählen trotzdem), `customers` `[min, max]` pro Tag, `pay_bonus` (% für Aufträge), `shop_bonus` (% in den Läden), `house_level` (so weit baut der Baumeister aus), `auto_materials` (Metalle, deren Minispiele an Amboss und Werkbank ab diesem Rang immer perfekt gelingen), `color` (Wappen) | F 0, E 150, D 400 (nach dem Überfall), C 1000 (nach Leonheim), B 2500, A 5000, S 9000, S+ 15000 |
| `reputation.gains` | Ruf-Punkte für `order_completed`, `order_expired`, `rent_late` | `10`, `-10`, `-5` |
| `reputation.sale` | Ruf pro verkauftem Stück (Ninas und eigener Laden) = (Materialstufe × `per_tier`, mindestens 1) × (1 + Seltenheitsstufen über R1 × `per_rarity`): Kupfer R1 = 1, Kupfer R2 = 2, Eisen R1 = 2, Eisen R2 = 4 | `1`, `1` |
| `market_hours` | Öffnungszeiten aller Händler: `from`, `until` (ab dann geschlossen; Feste Bewohner wie Erna zusätzlich nur in ihrer Arbeitszeit, der Schwarzmarkt hat immer offen: `Merchant.keeps_market_hours`) | `6`, `19` |
| `reputation.story` | `{Story-Flag: Punkte}`, einmalig, sobald das Flag gesetzt ist (Kapitel, Quests) | |
| `rent.amount`, `rent.days`, `rent.landlady` | Miete, Abstand in Tagen, Name der Vermieterin (Ruf-Abzug pro Tag ohne Zahlung: `reputation.gains.rent_late`) | `300`, `14`, `"Oma Hilde"` |
| `prices.buy_markup`, `prices.sell_factor`, `prices.sell_crafted_factor` | Händler verkaufen zu Wert × 1,25; kaufen Rohstoffe zu Wert × 0,6 und Selbstgemachtes zu Materialwert × 1,3 × Seltenheits-Bonus (+25 % je Stufe über R1); Items mit `sell_price` (items.json) kaufen sie zu genau diesem Preis | |
| `prices.sell_price_factor` | Standard-Faktor pro Seltenheitsstufe für Items mit `sell_price` (R2 = R1 × 1,2, R3 = R2 × 1,2 …), das Item kann mit `sell_price_factor` einen eigenen haben | `1.2` |
| `recipes.<id>` | kaufbare Gussform/Rezepte: `name`, `price`, `unlock` (Rezept-ids), `icon`, `description`, optional `unlock_flag` (erst ab diesem Story-Flag im Angebot) und `rank` (erst ab diesem Ruf-Rang, z. B. `"E"`); beim Händler `"recipe:<id>"`, bis zum Kauf jeden Tag da | |
| `shop.slots`, `shop.price_factor`, `shop.commission`, `shop.sale_chance_per_hour`, `shop.open_from_hour`, `shop.open_until_hour` | Ninas Laden: Ausstellungsplätze, Preis = Materialwert × Faktor × Seltenheits-Bonus (+25 % je Stufe über R1, nicht über der Material-Seltenheit) × Ruf-Bonus (Laden-Bonus des Rangs, reputation.ranks.shop_bonus), Ninas Anteil, Verkaufschance pro Stück und Stunde, Öffnungszeit | `4`, `1.8`, `0.02`, `0.15`, `0.2`, `8`, `20` |
| `shop.calendar_gift_sales` | ab so viel Umsatz in Ninas Laden schenkt sie den Kalender | `200` |
| `shop.expansion_sales` | ab so viel Umsatz erweitert Nina ihren Laden (frühestens in Kapitel 8, sie kommt am nächsten Morgen) | `2000` |
| `shop.expansion` | nach der Erweiterung: `weapon_slots` (Waffentische), `dummy` (Item-Typ » Name der Plätze an der Rüstungspuppe, z. B. `"helmet": "Helm"`; neue Typen nur hinten anhängen, sonst verrutschen gespeicherte Teile), `min_sales_per_day` (so viele Teile verkauft sie mindestens pro Tag) | `6`, 7 Plätze, `2` |
| `traveler.name`, `weekday`, `greeting` | Reisender: Name, Wochentag (0 = Montag, 6 = Sonntag), Begrüßung | `"Rashid"`, `6` |
| `traveler.home_greeting` | Begrüßung in Sahrim, seinem Zuhause (dort steht er an allen Tagen außer seinem Markttag und den Tagen davor und danach, `Traveler.at_home`) | `"Salam, mein Freund. …"` |
| `traveler.mold_tier`, `mold_count`, `mold_price` | er verkauft `[von, bis]` zufällige Gussformen dieser Materialstufe(n) (Zahl oder Liste, `[4, 5]` = Silber und Gold) zu diesem Preis; `[0, 0]` = keine (seit 2026-10-26) | `[4, 5]`, `[0, 0]`, `1000` |
| `assistant` | Lotte als Gehilfin (`Assistant`): `npc`, `flag` (ab da kauft sie ein), `wait_hours` [von, bis] wartet sie morgens in der Werkstatt, `market_hours` (Dauer des Einkaufs mit Wegen), `deliver_until` (danach Loot-Kiste), `wage` (Anteil am ausgegebenen Gold), `max_amount`, `merchants` [{`name`, `key` (Szene:Pfad des Stands), `stock_id`}] | `{"wage": 0.1, "wait_hours": [7, 9]}` |
| `search_orders.items` | Suchaufträge in der Gilde: `[{"item", "flag" (erst ab diesem Story-Flag), "rarity" (false = Seltenheit nicht wählbar)}]` | `{"item": "silver_ingot", "flag": "king_audience_done"}` |
| `search_orders.price_factor`, `rarity_factor`, `fee`, `days`, `max_amount` | Preis = `fee` + Händlerpreis eines Stücks × `price_factor` × `rarity_factor`^(Stufe über R1) × Menge; Lieferung nach `days` [von, bis] Tagen; höchstens `max_amount` Stück | `1.5`, `1.6`, `20`, `[1, 2]`, `10` |
| `traveler.mold_material_flags` | Metall » Story-Flag: Gussformen dieses Metalls erst ab dem Flag | `{"gold": "gold_molds_unlocked"}` (Gold erst ab Teil 3) |
| `traveler.offers`, `offer_count`, `price_factor` | Item-Vorrat, davon `[von, bis]` zufällig, Preis = normaler Händlerpreis × Faktor; `*Zahl` = so viele Stück statt der Standard-Menge, `=Preis` hinten = fester Preis eines R1-Stücks (+25 % je Seltenheitsstufe) | `["ruby*3@R3-R4=250", …]`, `[3, 4]`, `2.0` |
| `traveler.always_offers` | Angebote aus `offers`, die er immer dabeihat | `["silver_ring_band*2@R2-R3", "silver_amulet_band*2@R2-R3"]` |
| `jewelry.ring_item`, `amulet_item`, `rarity_factor` | Juweliertisch: fertiges Item für Ringe/Amulette, Faktor auf den Kristall-Wert je Seltenheit R1–R8 | `"jewel_ring"`, `"jewel_amulet"`, `[1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4]` |
| `jewelry.metal_factor` | Faktor auf den Kristall-Wert je Metall der Fassung (materials.json-id, fehlt = 1) | `{"silver": 1.0, "gold": 1.2, "platinum": 1.4, "palladium": 1.6}` |
| `stations.<id>` | kaufbare Station: `name`, `price`, `flag` (Story-Flag, das sie in der Schmiede erscheinen lässt), `icon`, `description`; beim Händler `"station:<id>"` in `offers` | |
| `shell_game.bait_stake`, `bait_wins_min`, `bait_wins_max` | Hütchenspiel des Bettlers: Einsatz am Anfang (fair) und nach wie vielen Siegen (zufällig dazwischen) er mehr will | `1`, `2`, `3` |
| `shell_game.high_stakes` | Einsätze danach (dann gewinnt man nie mehr) | `[50, 100, 200]` |
| `shell_game.swaps`, `swap_seconds`, `show_seconds` | Vertauschungen pro Runde, Dauer einer Vertauschung, so lange zeigt er die Murmel | `5`, `0.8`, `1.2` |
| `slot_machine.bets`, `symbols`, `jackpot_symbol` | Spielautomat im Schwarzmarkt: wählbare Einsätze, Symbole (Bilder `assets/sprites/ui/slot/<id>.png`), Symbol nur für den Jackpot | `[1..5]`, 6 Symbole, `"crown"` |
| `slot_machine.outcomes` | der Reihe nach ausgewürfelt: `id`, `chance` (pro Dreh), `pays` (Vielfaches des Einsatzes), `symbols` (welche drei Gleichen erscheinen; `pair` = zwei Gleiche); Rest = verloren | Jackpot 0,001 % ×2000, Edelsteine 0,99 % ×10, drei Gleiche 7 % ×4, Paar 22 % ×2 |
| `elf_defense` | Teil 3, Waffen für Sylvaris (`ElfDefense`): `goal` (Punkte für den Sieg), `per_tier`, `per_rarity` (Punkte pro Teil = (Stufe × per_tier, mindestens 1) × (1 + Seltenheit × per_rarity)), `griffin_dungeon` + `griffin_bonus` (einmal gewonnen = Bonus), `levels` (Anteile am Ziel für Hadmars Stufen), `verdict_start`, `verdicts` (Hadmars Satz im Fenster pro Stufe 0–3) | `80`, `1.0`, `0.5`, `"mountain_summit"`, `25` |
| `potion_recipes.<id>` | geheimes Trank-Rezept zum Kaufen (Händler-Angebot `potion_recipe:<id>`): `name` (nur das steht im Laden), `price`, `potions` (Trank-ids, Kauf setzt `potion_found_<id>`), `unlock_flag`, `rank` | `"magma": {"name": "Rezept: Magmatrank", "price": 900, "potions": ["magma_potion"]}` |
| `inn.room_price` | Gasthaus in Leonheim: Gold für eine Nacht | `25` |
| `smith_tournament.rounds` | Schmiedeturnier (`SmithTournament`), eine Runde pro Eintrag: `opponent_name`, `opponent_look` (Aussehen wie appearance.json), `metal` (Metall der Runde), `leather` (Leder-id für Rüstungen), `ores` (Erz pro Barren, Bronze `{"copper_ore": 1, "iron_ore": 1}`), `tasks` (optional: eigene Aufgaben-ids statt der aus `pieces`), `opponent_quality` [von, bis] (Punkte = Seltenheit × 100 + Qualität), `opponent_time` [von, bis] (Faktor auf `par_seconds`) | 4 Runden: Gorm (Kupfer), Brandolf (Eisen), Kasim (Bronze), Ilsa (Silber) |
| `smith_tournament.pieces`, `shaft`, `spare_ingots` | Werkbank-Items, die als Aufgabe drankommen können (Waffen, Schild, Rüstungsteile; Pfeile, Bögen, Zauberstäbe, Schmuck fehlen, weil die Tische fehlen); daraus entsteht pro Runde automatisch die Aufgabe `<piece>@<metal>` mit Teilen im Metall, Stielen aus `shaft`, Rezepten und Truhe (Erz für alle Barren + `spare_ingots`, Kohle, Holz, Leder) | 15 Stücke, `"wooden_shaft"`, `1` |
| `smith_tournament.tasks.<id>` | eigene Aufgaben (sonst leer): `name`, `piece` (abzugebendes Stück wie `have_item`, z. B. `"axe:iron_axe_head+wooden_shaft"`), `recipes` (für die Runde bekannt; jedes vorher unbekannte kostet Punkte), `chest` (Inhalt der Vorratstruhe, Liste wie `give_items`) | `iron_axe` |
| `smith_tournament.par_seconds`, `time_bonus`, `unknown_recipe_penalty` | Zeitbonus = `time_bonus` × (1 − Zeit / `par_seconds`), mindestens 0; Abzug pro unbekanntem Rezept (eine Runde in `rounds` kann ein eigenes `unknown_recipe_penalty` haben; Silberrunde: `0`) | `360`, `40`, `30` |
| `smith_tournament.entry_fee`, `prize_gold`, `first_win_reward`, `forge_heat`, `open_flag` | Startgeld (erst nach dem ersten Sieg), Preis pro Sieg, Item beim ersten Sieg, Güsse der Esse im Turnier, Story-Flag, ab dem der Turnierplatz offen ist | `500`, `1000`, `"master_gloves"`, `99`, `"tournament_open"` |
| `smith_tournament.venues.<ort>` | Weitere Austragungsorte (seit 2026-10-30: `sylvaris`, Turnierplatz der Kronen). Jedes Feld hier ersetzt das von Leonheim (z. B. `rounds`, `entry_fee`, `prize_gold`, `first_win_reward` (nur ein Item), `open_flag`), dazu: `monthly` (true = jedes Turnier kostet Startgeld, eins pro Monat und Ort), `won_flag` (Story-Flag nach dem ersten Sieg dort), `closed_text` (was der Herold sagt, solange `open_flag` fehlt), `intro_text`, `champion_text` (Texte im Fenster). Der Herold des Orts: `TournamentMenu.venue` | `"open_flag": "smith_tournament_won"` |


### Händler-Sortiment (`market_stock`)

Jeder Markt-Händler mit `stock_id` (im Inspector am Händler-Knoten) bekommt sein Tagesangebot aus `market_stock.<stock_id>`. Neue Ware = neue Zeile, kein Code:

```json
"herbalist": {"items": [
	{"item": "wood", "amount": [15, 30]},
	{"item": "feather", "amount": [2, 5], "chance": 0.25},
	{"item": "hemp", "amount": [2, 5], "rank": "E"}
]},
"enchanter": {"items": [
	{"pick": ["ruby", "sapphire"], "amount": 1, "extra_chance": 0.3, "price": 438, "rare_chance": 0.1, "rare_rarity": "R2", "rare_price": 547}
]},
"weapons": {"equipment": {"types": ["sword", "dagger"], "count": [3, 5], "part_count": [2, 4],
	"materials": {"F": ["copper"], "E": ["copper", "iron"]}, "part_materials": {"shaft": {"*": "wooden_shaft"}},
	"rare_chance": 0.1, "rare_count": [1, 2], "rare_rarity": "R2", "rare_price_factor": 2.0}}
```

| Feld | Bedeutung |
|---|---|
| `item` / `pick` | Item-id / Liste, aus der jeden Tag eins gewählt wird |
| `amount` | Stückzahl pro Tag, `[von, bis]` oder Zahl |
| `chance` | Chance, dass es die Ware heute gibt (Standard 1) |
| `rank`, `flag` | erst ab diesem Ruf-Rang (`F` … `S+`) bzw. Story-Flag (z. B. `mine_expanded`) |
| `price` | fester Preis pro Stück (sonst aus dem Item-Wert) |
| `extra_chance` | Chance auf 1 Stück mehr |
| `rare_chance`, `rare_rarity`, `rare_price` | Chance auf diese Seltenheit, dann dieser Preis |
| `equipment.types` | Item-ids mit `parts` (Waffen, Rüstungen) |
| `equipment.materials` | Rang → Materialien; es gilt die Liste des höchsten erreichten Rangs |
| `equipment.material_flags` | Metall → Story-Flag: ein Metall aus `materials` erst ab diesem Flag (z. B. `"iron": "iron_unlocked"`); bleibt keins übrig, gibt es Kupfer |
| `equipment.part_materials` | Teil-Art → {Material: Item-id, `*`: sonst}, wenn es das Teil nicht aus dem Material gibt |
| `offer_count` | `[von, bis]`: pro Tag nur so viele zufällige Waren aus `items` und `equipment` zusammen (z. B. Krummfinger 1–8) |
| `random_offers` | `true`: auch die Gussformen/Rezepte aus `offers` des Händlers werden mit ausgelost (nur die, die man gerade kaufen kann: freigeschaltet und noch nicht gekauft), statt immer alle da zu sein (Krummfinger) |
| `always_offers` | `{Angebot: Story-Flag}` (nur mit `random_offers`): ab diesem Flag ist die Gussform/das Rezept jeden Tag da und zählt nicht zu `offer_count` (Krummfinger: Bronze-Spitzhacke und -Holzfälleraxt ab `goblin_castle_path_open`) |
| `always` | `true` an einer `items`-Zeile: diese Ware ist immer da und zählt nicht zu `offer_count` (Kohle beim Schmied, Ithiels Herzblatt) |
| `equipment.price` | fester Preis pro fertigem Stück (sonst aus dem Materialwert), z. B. Krummfingers Bronze-Ausrüstung für 700 Gold (`goblin`: `count` 99 = alle Typen, `materials` nur `F: bronze`) |
| `default` | Stückzahl für Händler ohne `stock_id`: `stackable` und `equipment` je `[von, bis]` |
| `story_limits` | Liste `{from, until, stocks, offers}`: vom Story-Flag `from` bis `until` verkaufen alle Händler nur `stocks.<stock_id>` (Zeilen wie `items`) und von ihren festen Angeboten nur die in `offers`, alle anderen nichts. Die erste passende Regel gilt; jede Phase hat ihren eigenen Tagesvorrat. `prices` {Angebot: Preis} macht feste Angebote in dieser Phase billiger (Kupferklinge/-griff 50 statt 200 nach Brunos Spende). Vom Spielstart (`reached_find_smithy`) bis Bruno (`bruno_hired`) nur Kupfererz, Kohle, Holz und der Wassertrog (alles für Holgers Axt). Bisher: nach Brunos Spende (`bruno_hired`) bis zum Rattenkeller (`reached_wait_for_bruno`) nur 3 Kupferbarren, 2 Kohle, 1 Holz und die Gussformen Kupferklinge/-griff |
## house.json – Hausausbau, eigener Laden, Möbel

Der Ausbau des eigenen Hauses (Schmiede) in 5 Stufen, der eigene Laden und die Einrichtung dafür (Klasse `House`). Die Grafiken jeder Stufe stecken in den Szenen, hier stehen nur Namen, Preise und Zahlen.

| Feld | Bedeutung | Beispiel |
|---|---|---|
| `levels` | Liste der Stufen 1–5 (Reihenfolge = Stufe): `name`, `price` (Gold beim Baumeister, Stufe 1 = 0), `description`, `smithy_displays` (Verkaufstische in der Werkstatt), `shop_displays` (Verkaufstische im Laden-Anbau), `armor_stand` (true = Rüstungsständer, ein Platz pro Rüstungsart) | Stufe 4: `5000`, `2`, `6` |
| `shop.commission` | Anteil, den beim eigenen Laden jemand anderes behält | `0.0` |
| `shop.max_furniture_bonus` | höchster Preis-Bonus durch aufgestellte Möbel | `0.5` (= +50 %) |
| `shop.price_factor`, `sale_chance_per_hour`, `open_from_hour`, `open_until_hour` | optional; fehlt ein Wert, gilt der von Ninas Laden (economy.json `shop`) | |
| `furniture.<id>` | Möbelstück: `name`, `price` (bei der Möbelhändlerin), `bonus` (Preis-Bonus im eigenen Laden, `0.03` = +3 %, nur solange es im Laden steht), `texture`, `floor` (`true` = liegt flach wie ein Teppich, man läuft darüber), `size` `[Breite, Tiefe]` der Standfläche in Pixeln (Kollision und Platzbedarf), `description` | `"bear_trophy"`: `1200`, `0.06`, `[24, 8]` |
| `furniture.<id>.planter` / `rooms` / `unlock_flag` | Pflanztopf mit `planter` × `planter` Feldern (Gewächshaus, siehe `Garden`); `rooms`: nur in diesen Räumen aufstellbar (z. B. `["greenhouse"]`, ohne = überall); `unlock_flag`: die Möbelhändlerin verkauft es erst ab diesem Story-Flag | `"planter": 2` |
| `furniture.<id>.jewel_slots` / `max_owned` | Schmuckvitrine: so viele Plätze für Ringe und Amulette im eigenen Laden (nur im Laden-Anbau ab Hausstufe 4, siehe `JewelDisplay`); `max_owned`: höchstens so viele Stück kaufbar | `"jewel_slots": 8, "max_owned": 1` |
| `furniture.<id>.storage` / `rank` | Lagerkiste mit so vielen Plätzen (E öffnet sie, Kistenschild `chest_sign` beschriftet sie, siehe `StorageBox`); `rank`: die Möbelhändlerin verkauft das Stück erst ab diesem Ruf-Rang (F, E, D …) | `"storage": 8, "rank": "E"` |
| `decorations.<Knotenname>` | Deko, die schon in einem Raum steht und sich mit B einlagern lässt: `name`, `icon` (Bild im Lager-Fenster). Der Knoten muss außerdem in `movables` des `HouseEditor` stehen. | `"Barrel": {"name": "Fass", "icon": "res://assets/sprites/props/barrel.png"}` |

| `room_styles.<id>` | Boden, Wand oder Tür für den Raum-Designer: `name`, `kind` (`floor`, `wall`, `door`), `price`, `bonus` (Preis-Bonus, nur wenn im Laden gesetzt), `texture` (Boden 32×32 und Wand 32×48 werden gekachelt, Tür 17×32), `unlock_flag` (optional), `description` | `"floor_red_carpet"`: `1200`, `0.02` |
| `workshop_upgrades.<station>` | `name` und `levels` (der Reihe nach): `name`, `price`, `items` (wie bei `has_items`), `unlock_flag` (optional), `description` und die Wirkung: `forge_quality` (% Qualität beim Schmieden), `smelt_speed` (% schneller schmelzen), `smelt_slots` (Plätze mehr in der Schmelze, jeder schmilzt für sich, höchstens 3), `heat_bonus` (% mehr Güsse pro Brennstoff); Werte aller gekauften Stufen werden addiert | Amboss Stufe 1: `2000`, `"iron_ingot*10"`, `forge_quality: 2` |
| `hall_of_fame` | Ruhmeshalle: `price`, `items` (nur Doku, die Abgabe steht im Konrad-Dialog in story.json), `reputation_per_trophy`, `max_trophies_counted`, `description` | `15000`, `2`, `14` |

Neuer Stil: Eintrag unter `room_styles`, Bild nach `assets/sprites/rooms/styles/`. Ein neuer Raum braucht in seiner Szene einen `RoomStyleLayer` unter dem `Background`-Sprite (Rechtecke in Bild-Pixeln) und einen `HouseEditor`.

Neues Möbelstück: Eintrag unter `furniture` anlegen, Bild nach `assets/sprites/furniture/shop/` und `"furniture:<id>"` bei der Möbelhändlerin (`market.tscn`, Stand `FurnitureTrader`, `offers`) eintragen.

## Bögen und Pfeile in items.json

Neue Teil-Typen: `bow_frame`, `longbow_frame`, `arrow_tip`, `arrow_shaft`. Neuer Item-Typ `arrows` (Pfeile, gehören in die linke Hand). Zusätzliche Felder für Rezepte: `station` (wo geschnitzt bzw. gebaut wird, Standard `workbench`, z. B. `bow_table`) und `amount` (Stück pro Bau, z. B. 30 Pfeile). In `weapon_types.json` macht `"uses_arrows": true` aus einem Waffentyp einen Bogen. Beispiel:

```json
"arrows": { "name": "Pfeile", "type": "arrows", "stack": 99, "parts": ["arrow_tip", "arrow_shaft"],
	"needs": { "feather": 1 }, "amount": 30, "station": "bow_table", "tab": "arrows", "category": "Pfeile" }
```

## Aufwertungs-Materialien und Köcher in items.json

(Aufwertungstisch seit 2026-10-26 ausgebaut, das Feld wirkt im Spiel gerade nicht.) Ein Material mit `"upgrade"` kann am Aufwertungstisch auf Waffen, Rüstungen oder Pfeile gelegt werden. `targets`: `weapon`, `armor`, `arrows`; `damage_kind`: Schadensart des Zusatzschadens (z. B. `poison`, `fire`); `effect`: id aus status_effects.json (optional); `arrows`: so viele Pfeile wertet ein Material auf (Standard 30); `tiers`: Werte je Seltenheit des Materials (`damage` = Zusatzschaden pro Treffer, `chance` = % auf den Effekt; höhere Seltenheiten ohne eigene Stufe nehmen die nächstniedrigere). Neue Materialien brauchen keinen Code:

```json
"rat_venom_fang": { "name": "Rattengiftzahn", "type": "material", "rarity": "R1",
	"upgrade": { "name": "Vergiftet", "targets": ["weapon", "arrows"], "damage_kind": "poison", "effect": "poison", "arrows": 30,
		"tiers": { "R1": {"damage": [1, 2], "chance": 10}, "R2": {"damage": [2, 3], "chance": 15} } } }
```

Resistenz statt Schaden (Kristalle): `"resistance_kind": "fire"` und in den Stufen `"resistance": 2`, z. B. `"ruby": {..., "upgrade": {"name": "Rubin", "targets": ["armor"], "resistance_kind": "fire", "tiers": {"R1": {"resistance": 2}, "R2": {"resistance": 3}}}}`. Seltene Drops eines Steins (data/rocks/*.tres): `rare_drop_item_ids` (einer davon zufällig) und `rare_drop_chance` (z. B. 0.03).

Gegner, deren normale Angriffe einen Effekt auslösen (enemies.json): `"on_hit": [{"effect": "poison", "chance": 30}]` (Chance in %).

Skills, die eine bestimmte Waffe brauchen (skills.json): `"requires_weapon": ["shield"]` bzw. `["bow", "longbow"]` (ids aus weapon_types.json, eine davon muss in einer Hand sein); weglassen = jede Waffe.

Aussehen eines Skills im Kampffenster (skills.json, beide optional): `"anim"` = Bewegung (`swing`, `thrust`, `slam`, `shoot`, `cast`, `lunge`; weglassen: Zauber, Hilfs-Skills und Skills ohne Schaden `cast`, sonst `attack_anim` der Waffe), `"vfx"` = Effekt am Ziel (`slash`, `pierce`, `impact`, `arrow`, `bolt`, `heal`, `buff`, `debuff`, `glow`, `none`; weglassen: passend zur Bewegung, `swing`/`slam` » `slash`, `thrust` » `pierce`, `shoot` » `arrow`, `cast` » `bolt`). Die Farbe kommt von der Schadensart (Element). Beispiel Schildschlag: `"anim": "lunge", "vfx": "impact"`. Mit Element nimmt das Spiel automatisch das eigene Geschoss und den eigenen Einschlag (`fire_bolt`/`fire_hit` … für fire, water, earth, air, dark, light, lightning, ice, poison); ein Nahkampftreffer mit Element zeigt zusätzlich den Element-Einschlag. `"vfx"` darf auch jeder andere Bildname aus `assets/sprites/battle/vfx/` (oder `vfx/color/`) sein. `"area_vfx"` (optional) = ein Effekt über der ganzen Gruppe bei Skills auf alle Gegner (und Heilung auf alle Verbündeten): `area_meteor` (fällt vom Himmel; gesetzt bei Meteor, Kleiner Meteor, Glutregen), `area_fire`, `area_quake`, `area_thunder`, `area_ice`, `area_poison`, `area_shadow`, `area_holy`, `area_heal`, `none` = je Ziel ein Effekt; weglassen: nach Element (Feuer `area_fire` = Einschlag ohne Fallen, Erde Beben, Blitz Donner, Eis/Wasser Eisdornen, Gift Wolke, Dunkel Schatten, Licht Lichtstrahl), ohne Element `slam` » Beben, Heilung auf alle » `area_heal`.

Waffen pro Klasse (weapon_types.json): `"classes": ["warrior", "rogue"]` (ids aus data/hero_classes/); weglassen = alle Klassen. Eine Klasse erscheint erst in der Gilde, wenn der Spieler eine ihrer Waffen herstellen kann.

Köcher: Item-Typ `quiver` mit `quiver_slots` (Plätze für Pfeil-Stapel; verschossen wird rechts, links, dann 3. und 4. Platz), z. B. `"type": "quiver", "quiver_slots": 2, "parts": ["leather", "leather"], "station": "bow_table", "tab": "arrows"`. Ein größerer Köcher ist nur ein weiterer Eintrag mit mehr Plätzen (das Heldenfenster zeigt bis zu 4).

## appearance.json – Aussehen von Spieler und NPCs

```json
"races": { "elf": { "name": "Elf", "skin_tones": ["light", "pale", "tan", "brown", "dark"], "parts": ["elf_ears"] } },
"skin_tones": { "light": { "name": "Hell", "colors": ["#fbc195", "#fab488", "#f39b71", "#ed8c66", "#e06e48"] } },
"hair_styles": { "long": { "name": "Lang", "part": "hair_long" }, "bald": { "name": "Glatze", "bald": true } },
"eye_types": { "big": { "name": "Groß", "part": "eyes_big" } },
"sizes": { "tall": { "name": "Groß", "scale": 1.08 } }
```

| Abschnitt / Feld | Bedeutung |
|---|---|
| `races.<id>.name` | Anzeigename im Charakter-Editor |
| `races.<id>.skin_tones` | erlaubte Hautfarben (ids aus `skin_tones`) |
| `races.<id>.parts` | Teile, die die Rasse immer hat (Bilder in `assets/sprites/characters/parts/`) |
| `races.<id>.no_hair` | `true` = keine Haare (Frisur ist immer Glatze), z. B. Echse |
| `races.<id>.hero_bonus` | Bonus für Helden dieser Rasse, Werte wie bei passiven Skills (`skills.json`, Liste oben), z. B. `{"damage_light": 5}` = Lichtschaden +5 %, `{"max_health": 10}` = Leben +10 %, `crit_chance`, `evasion` |
| `races.<id>.hero_resistances` | Resistenzen der Helden dieser Rasse, z. B. `{"fire": 5}` |
| `races.<id>.player_bonus` | Bonus für den Schmied dieser Rasse: Namen aus `PlayerStats.Stat` mit dem Wert wie bei einem Spieler-Skill, z. B. `{"FORGING_ZONES": 0.01}` (Amboss-Zonen +1 %-Punkt), `SELL_PRICE` 0.05 (+5 % Gold), `JOINING_GREEN_ZONE`, `MINING_DAMAGE`, `RARE_FIND`, `FUEL_DURATION`, `PLANT_RARITY`, `QUALITY_GAIN` |

Die Texte (Charakter-Editor, Gilde, Heldenfenster) entstehen aus diesen Zahlen (`Appearance.get_race_hero_text`, `PlayerStats.get_race_bonus_text`).
| `skin_tones`, `hair_colors` | `name` + `colors`: 5 Töne von hell nach dunkel |
| `eye_colors` | `name` + `colors`: 2 Töne (Farbe, Glanz) |
| `hair_styles`, `eye_types` | `name`, optional `part` (Bild) und bei Frisuren `bald` (Haare werden zu Haut) |
| `sizes` | `name`, `scale` (Pixel-Art: nur leicht, 0.92–1.08) |
| `outfits` | Kleidung: `name`, `base` (Basis-Figur), `colorable` (`true` = Hauptkleidungsstück nimmt die Kleidungsfarbe an) |
| `clothes_colors` | `name` + `colors`: 5 Töne für das Hauptkleidungsstück |
| `races.<id>.horns` | `true` = Rasse mit Hörnern: im Editor die Kategorie „Hörner“, Form und Farbe zählen |
| `horn_styles` | `name`, `part` (Bild `horns_<form>`, Vorlage in `bake_characters.py` `HORN_STYLES`) |
| `races.<id>.ears` | Ohrformen der Rasse (ids aus `ear_styles`, die erste ist Standard): im Editor die Kategorie „Ohren“ |
| `ear_styles` | `name`, `part` (Bild, z. B. `cat_ears_round`, Vorlagen in `bake_characters.py`), `hide_human_ears` (`true` = die Menschenohren der Basis-Figur werden ausgeblendet: Teil `no_human_ears`, Magenta `(255, 0, 255)` = durchsichtig) |
| `horn_colors` | `name` + `colors`: 4 Töne von hell nach dunkel (Markerfarbe Horn `(i, 128, 0)`) |

**Eigene Farben:** Statt einer id kann `skin`, `hair_color`, `eye_color` oder `clothes_color` eines Aussehens auch `"#rrggbb"` sein (Farbrad im Charakter-Editor). Die Töne entstehen dann im Code (`Appearance.get_colors`: die Farbe ist Ton 1, die anderen heller/dunkler, Haut enger beieinander; Augen: Farbe + aufgehellter Glanz).
| `parts_dir`, `portrait_rect` | Ordner der Teile (darin ein Unterordner pro Kleidung), Ausschnitt des Kopfes `[x, y, breite, höhe]` |

**Teile-Bilder:** gleiches Layout wie das Spieler-Sheet (7 Bilder × 4 Richtungen à 48×48, Reihen unten/oben/links/rechts, Bild 0 = Stehen, 1–6 = Laufen); `<teil>_back.png` liegt hinter dem Körper. Statt fester Farben werden **Markerfarben** gemalt, die das Spiel einfärbt: Haut `(i, 255, 0)`, Haare `(i, 0, 255)`, Augen `(i, 255, 255)`, Kleidung `(i, 128, 255)`, `i` = Ton 0 (hell) bis 4 (dunkel). Alles andere bleibt, wie es ist (z. B. Hörner). Die mitgelieferten Teile erzeugt `py -I assets/_reference/characters/bake_characters.py` (ASCII-Vorlagen im Skript); eine Vorschau zufälliger Figuren: `... bake_characters.py --preview vorschau.png`. Neue Frisur = Teil zeichnen (oder Vorlage im Skript) + Eintrag in `hair_styles`, ohne Code. Nur einzelne Teile neu backen (in alle Bildblätter: Laufen, Hacken, Holzfällen, Kampf-Posen; alles andere bleibt): `py -I assets/_reference/characters/bake_head_parts.py <ordner> <teil> ...`, danach aus `<ordner>` nach `assets/sprites/characters/parts/` kopieren.

**Materialfarben:** `materials.json` hat pro Material `colors` (5 Töne hell » dunkel). So sehen Rüstung und Waffen aus diesem Material an Helden im Kampf aus (`CharacterBaker.get_battle_sheet`). Neues Metall = Farben eintragen, keine Grafik nötig.

## story.json – Geschichte

| Abschnitt | Bedeutung |
|---|---|
| `start` | `scene`, `spawn` (Start nach dem Intro), `step` (erster Schritt), `gold` (Startgold), `clock_stops_until` + `clock_stops_at_hour` (bis zu diesem Flag läuft die Uhr höchstens bis zu dieser Stunde und bleibt dort stehen) |
| `intro` | Seiten der Hintergrundgeschichte (Liste von Texten) |
| `steps.<id>` | `title`, `text` (Aufgabe im Auftragsbuch), `goal` (kurze Zeile im Aufgaben-Tracker statt des ersten Satzes von `text`, z. B. `"Geh zu Oma Hilde im Norden"`; `{done}`/`{total}` = Fortschritt der `progress_flags`, z. B. `"{done}/{total} Spinnweben entfernt"`), `hints` (Tipps beim Start), `on_start` (Aktionen beim Start). Ende: `progress_flags` + `next`, `quest_ready` / `quest_done` / `have_item` (z. B. `"sword:copper_blade+copper_handle"`) / `hero_armed` (Held-id) / `shop_display` (z. B. `"sword*2:R1,sword*1:R2"`: so viele Teile mit mindestens dieser Seltenheit liegen in Ninas Laden) / `shop_sold` (Anzahl verkaufter Teile) / `shop_goal` (z. B. `"sword*3"`: so viele Schwerter hat Nina insgesamt verkauft, egal wann und ob einzeln; das Auftragsbuch zeigt „Verkauft: 1/3 · Gerade ausgestellt: 2“) / `hero_level` (ein Held hat mindestens dieses Level) / `wait_days` (so viele Tage nach Beginn des Schritts) / `have_gold` (so viel Gold hat der Spieler, Platzhalter erlaubt, z. B. `"{rent}"`) + `next`, `show_items` (Liste wie bei `take_items`, das Auftragsbuch zeigt „Kohle 3/5“), `shopping` (Einkaufsliste: `[{"name", "where", "flag" oder "items", "buy"}]`, abgehakt per Flag oder Inventar, z. B. `"items": "wood*2"`; `buy` = Angebot im Laden, z. B. `"copper_ore"`, `"station:water_trough"`, `"recipe:copper_blade"`: solange der Eintrag offen ist, leuchten die Ware und jeder Händler, der sie heute hat, golden; nur die ersten Einkaufsschritte), `shopping_done` (true = der Schritt endet, sobald die ganze Einkaufsliste abgehakt ist, dann `next`), `guide` (goldenes Leuchten, `Guide`: Liste von Stufen `{"if", "show"}`, die erste passende gilt; `if` = Bedingungen mit Komma, `!` davor = nicht: `has:<item>` (im Inventar), `cold:<item>`, `hot:<item>` (glühend), `flag:<flag>`, `smelter_busy`, `smelter_ready` (Barren im Ergebnis-Feld), `trough_busy`; `show` = Ziele: `station:<szenen-name>` (z. B. `station:smelter`, `station:cobweb`, `station:storage_chest`), `npc:<npc-id>`, `recipe:<rezept-id>` (Reiter, Kategorie, Rezept, dann Knopf), `smelter:ore` / `smelter:fuel` / `smelter:output`, `trough:slot`, `inv:<item>` (Inventar-Feld), `dungeon:<id>` / `hero:<id>` (Dungeon-Brett: Reiter, Dungeon, Heldenplatz, Held, Losschicken; Beispiel: `send_bruno`); ein Ziel kann `{"target", "if"}` sein; in Bedingungen `|` = oder, weitere Bedingungen `part:<teil-art>` (kaltes Teil dieser Art, z. B. `part:leather`), `weapon:<waffentyp>` (z. B. `weapon:staff`), `order_item` (passt zu einem offenen Kundenauftrag); `*` in Item-ids und Zielen = beliebiger Text (z. B. `has:hot_*_staff_rod_blank`, `recipe:*_staff_rod`); weitere Ziele `order:slot` (Auftragsbrett), `tanning:slot` (Gerberbank), `buy:<angebot>` (Ware und Händler). Beispiel: `forge_axe`), `move_in_dialogue` (true = der Spieler darf laufen, solange ein Dialog offen ist; sonst steht er bei jedem Dialog still – nur `first_rent`, Oma Hilde läuft hinter ihm her, bis die Miete bezahlt ist), `events` (Ereignis → Schritt: `sleep`, `enter:<szenen-datei>`, `adventure_started`, `adventure_won`, `adventure_lost`, `adventure_won:<dungeon-id>` / `adventure_lost:<dungeon-id>` = nur dieser Dungeon, hat Vorrang) oder eine Dialog-Aktion `advance:<id>` |
| `tutorials.<id>` | Lehrgänge außerhalb der Schritte (goldenes Leuchten beim ersten Mal): `start` (Bedingungen wie bei `guide`, z. B. `flag:station_bow_table`), `done` (danach nie wieder), `hint` (Tipp aus `hints` beim Start), `guide` (Stufen wie bei `steps`). Laufen nur, solange der aktuelle Schritt kein eigenes `guide` hat. Beispiele: `leather_armor`, `bow`, `staff` |
| `npcs.<id>` | Story-Figur/Objekt: `name`, `voice` (Sprechart des Volkes, `"hiss"` = zischt wie eine Schlange, siehe `Voice` und `docs/DIALOGE.md` „Völker“), `dialogues` (Schritt → Dialog-id, `default` = sonst, `daily` = Liste von Dialog-ids, jeden Tag der nächste, wenn weder Schritt noch Nebendialog passen, z. B. Zahirs Hinweise), `gone_flag` (ab diesem Flag ist die Figur in keiner Szene mehr da, z. B. Oma Hilde nach dem Überfall `hilde_dead`; die Miete geht dann an Lotte) |
| `dialogues.<id>` | `lines` (`speaker`: `player`, `""` = Erzähler, oder npc-id; `text`), `on_end` (Aktionen nach der letzten Zeile), `choices` (`text`, `action`, `then` = nächster Dialog, `else` = Dialog, wenn die Aktion nicht ging, `if_flag` = nur zu sehen, wenn das Flag gesetzt ist, `unless_flag` = nur, solange es nicht gesetzt ist, `decision: true` = Entscheidung: beim Überspringen per Admin-Panel gilt nur die erste Antwort). Auch einzelne `lines` können `if_flag` / `unless_flag` haben: Die Zeile fehlt dann, je nach Flag beim Start des Dialogs (z. B. Lake erinnert sich, dass der Spieler für ihn gebürgt hat) |
| `hints.<id>` | Tipp: `title`, `text` (jeder Tipp erscheint nur einmal), `glow` (Ziele, die golden leuchten, solange der Tipp auf dem Bildschirm ist: `menu:settings`, `menu:save`, `menu:load` = Knöpfe der Leiste rechts; z. B. `intro_help`, `saving`) |
| `purchase_flags` | item-id → Flag, das beim Kauf gesetzt wird (z. B. Kupfer → `bought_copper`) |
| `purchase_hints` | Kauf (wie oben, auch `station:<id>`) → Tipp-id aus `hints`, der danach einmal erscheint (z. B. Wassertrog → `move_stations`) |
| `intro_hints` | Tipp-ids, die in den Einstellungen unter „Einleitung“ immer stehen (in dieser Reihenfolge); andere Tipps erst, wenn sie schon gezeigt wurden |
| `recipe_actions` | Rezept-id → Aktionen, solange das Rezept bekannt ist (eine id mit `*` am Ende passt auf alle Rezepte, die so anfangen, z. B. `mold_bronze_*`; z. B. erste Rüstungs-Gussform → `set_flag:armor_mold_found;hint:armor_mold`). Laufen nach jedem neuen Rezept und beim Laden erneut: nur `set_flag`, `hint` und `unlock_recipes` benutzen (z. B. erste Rüstungs-Gussform → Lederumhang; Kupferaxt-Gussform aus alten Spielständen → Holzfälleraxt) |
| `item_actions` | Item-id → Aktionen, sobald so ein Item im Inventar oder in der Lagertruhe liegt (wird ständig geprüft, nur `set_flag`/`hint`), z. B. `"bronze_ingot": "set_flag:bronze_found;hint:bronze_found"` | |
| `side_tasks.<id>` | Neben-Aufgabe (Auftragsbuch unter „Nebenquests“): `title`, `text`, `start_flag` (ab da läuft sie), `done_flag` (danach unter „Erledigt“). Set-Aufgaben: `set_items` (Item-Typ → Anzeigename, z. B. `{"weapon": "Waffe", "gloves": "Handschuhe"}`) – statt eines Typs geht auch eine Item-id (`"sword"`), `set_min_rarity` (z. B. `"R5"`) verlangt eine Mindest-Seltenheit und `set_material` (z. B. `"copper"`): hat der Spieler von jedem Typ ein abgekühltes Teil mit einem Teil aus diesem Metall (Inventar oder an einem Helden), wird `complete_flag` gesetzt, `on_complete` läuft und `complete_text` steht im Auftragsbuch. Den `done_flag` setzt dann z. B. ein Nebendialog. Abgabe-Aufgaben: `show_items` (wie bei Schritten) und `show_gold` zeigen den Fortschritt im Detailfenster. Checkliste: `todo` = Liste von `{"items": "chamomile"}` (zählt wie `show_items`, z. B. „Kamille: 1/1“) oder `{"name": "Trank brauen", "flag": "<flag>"}` (abgehakt, sobald gesetzt); ist ein späterer Punkt erledigt, gelten alle davor auch als erledigt (z. B. „Der erste Trank“); `"own": true` = der Punkt hakt nur sich selbst ab (Dinge in beliebiger Reihenfolge, z. B. die vier Kompass-Gussformen). `check: "nina_dummy"`: `complete_flag`, sobald Ninas Rüstungspuppe voll ist. Mit `"hand_in": true` zählt ein Set-Teil erst, wenn es abgegeben ist: Dialog-Aktion `hand_in_set:<aufgaben-id>` nimmt jedes noch fehlende Teil aus dem Inventar (eins pro Typ, Flag `<aufgaben-id>_given_<typ>`), false = nichts dabei; sind alle da, wird `complete_flag` gesetzt. Das Auftragsbuch zeigt pro Teil 0/1 bzw. 1/1 (Kupferset für Hedwig) |
| `overnight` | Liste `{if: [flags], set: flag, text, hint}`: beim Schlafen wird `set` gesetzt, wenn alle `if`-Flags da sind; `text` steht im Aufwach-Text (z. B. Gustav räumt über Nacht den alten Stollen frei), `hint` (optional) ist ein Tipp aus `hints`, der dann erscheint |
| `daily_rewards` | Liste `{flag, until, item, amount}`: jeden Morgen kommt `amount` × `item` in die Loot-Kiste, solange `flag` gesetzt ist und `until` (optional) noch nicht (z. B. Gustavs Kohle: 1, nach der Eisenspitzhacke 3) |
| `villagers_away` | `{from, until}` oder eine Liste davon: zwischen diesen Flags sind alle umherlaufenden Dorfbewohner weg (Frühlingsfest, Überfall in der Nacht) |
| `renamed_steps` | alte Schritt-id → neue: Spielstände an einem entfernten Schritt (z. B. altes „Fortsetzung folgt“) machen dort weiter |
| `implied_flags` | Flag → Liste von Flags, die beim Laden dazukommen (alte Spielstände, z. B. `reached_chapter11_end` → `builder_weekly`) |
| `skip_flags`, `skip_recipes` | was beim Überspringen der Story (Debug, alte Spielstände) freigeschaltet wird |
| `legacy_recipes` | Rezepte, die vor „neues Spiel kennt keine Rezepte“ ab Start bekannt waren; bekommen alte Spielstände und das Überspringen der Story |

`side_dialogues`: Nebendialoge außerhalb der Schritte, Liste von `{npc, flag, flags, done_flag, dialogue, quiet}` (`flags` = weitere Flags, die alle gesetzt sein müssen) (läuft, solange `flag` gesetzt und `done_flag` nicht gesetzt ist, ohne `done_flag` für immer; `quiet: true` = kein „!“ über der Figur; Vorrang: Dialog des Schritts, dann Nebendialog, dann `default`; `topic` = Knopftext im Gesprächsmenü, siehe `npcs.<id>.menu`; `courier: true` = die Figur bringt es dem Spieler, wo er gerade ist, und es spielt vor allem anderen ohne Gesprächsmenü, bisher nur Lotte mit Briefen, siehe `LotteCourier`). Ereignis `rent_due`: am Morgen, an dem die erste Miete fällig ist.

Gesprächsmenü: `npcs.<id>.menu` = Dialog-ID der Begrüßung (z. B. `lotte_menu`, optional `talk_text`/`bye_text` für die Knöpfe „Reden“/„Tschüss“). Hat die Figur offene Nebendialoge mit `topic`, fragt sie erst und zeigt Knöpfe: „Reden“ (erster offener Nebendialog ohne `topic`, sonst `daily`/`default`), je ein Knopf pro `topic` (gleicher Text nur einmal) und „Tschüss“. Ohne Themen oder mit einem Dialog für den aktuellen Schritt redet sie wie bisher direkt (`Story.get_npc_menu`).

Aktionen (mehrere mit `;`): `accept_quest:<id>` (data/quests/<id>.tres), `unlock_recipes:<id>,<id>`, `unlock_molds:<gussform-id>,<gussform-id>` (Gussformen samt Amboss-Rezept und den Werkbank-Rezepten, die dadurch herstellbar werden), `set_flag:<flag>`, `advance:<schritt>`, `hint:<tipp>`, `set_time:<stunde>`, `hire_hero:<id>` (kostenlos), `donate_gold:<menge>` (so viel Gold verschenken, höchstens alles; ohne Gold Flag `donated_nothing`), `read_rent_sign`, `rent_smithy` (kostet die Miete, `else`-Dialog ohne Gold), `has_items:<liste>` (hat der Spieler das, auch angelegte Werkzeuge? Liste z. B. `coal*5,pickaxe:copper_pickaxe_head+wooden_shaft`), `take_items:<liste>` (nimmt es weg, sonst `else`), `give_gold:<menge>`, `give_items:<liste>` (Items schenken, Liste wie bei `has_items`, was nicht passt, kommt in die Loot-Kiste), `errand_hand_over` (Lotte gibt Einkauf und Restgold, `Assistant`; ihr Fenster: `open_menu:errand`; Platzhalter `{errand_report}`), `collect_shop_gold` (Nina zahlt aus, `else` = nichts verkauft), `pay_rent` (erste Miete an Oma, `else` = zu wenig Gold), `set_rent:<gold>`, `story_order:<npc-id>,<item>,<seltenheit>,<tage>` (Kundenauftrag dieser Figur, läuft nicht ab, Abgabe setzt `order_done_<npc-id>`), `pay_gold:<menge>` (zahlen, `else` bei zu wenig Gold), `deliver:<neben-aufgabe>` / `deliver_gold:<neben-aufgabe>` (Sachen bzw. Gold für `show_items`/`show_gold` der Neben-Aufgabe nach und nach abgeben, gespeichert in `Story.delivered`; alles da = `done_flag`; `else`, wenn nichts abgegeben wurde), `has_gold:<menge>` (hat der Spieler so viel Gold? nur prüfen, vor `take_items` schreiben), `open_menu:<name>` (die Figur öffnet ihr Fenster, z. B. `house` = Hausausbau beim Baumeister), `rent_free:<tage>` (so lange keine Miete), `buy_smithy` (Schmiede gehört dem Spieler, keine Miete mehr), `start_adventure:<dungeon>,<held-id>` (Helden kämpfen sofort, Kampffenster geht auf; `else`, wenn ein Held fehlt oder unterwegs ist), `travel:<szenen-pfad>,<spawnpunkt>[,<nur aus szene>]` (Spieler wechselt die Szene, z. B. flieht aus der Mine),  `travel_fade:<szenen-pfad>,<spawnpunkt>` (dasselbe mit Überblendung, z. B. Kutschfahrt in die Königsstadt), `expand_nina_shop` (Ninas Laden erweitern), `clear_flags:<flag>,<flag>` (Flags zurücknehmen, z. B. der Test-Auslöser des Überfalls), `lose_hero:<held-id>` (der Held stirbt: weg aus der Gruppe, seine Ausrüstung kommt in die Loot-Kiste), `sleep` (die Nacht endet ohne Bett, z. B. Wache halten nach dem Überfall: nächster Morgen mit Aufwach-Bild), `rob_player` (Überfall: alles Gold, das ganze Inventar und die Loot-Kiste weg; Rezepte, Gussformen, angelegte Werkzeuge bleiben), `sleep_at:<szenen-pfad>,<spawnpunkt>` (wie `sleep`, aber die Autospeicherung dieser Nacht wacht dort auf, z. B. auf der Spitze von Sylvaris), `show_ending` (Abspann nach dem Ende der Geschichte: Seiten aus story.json `ending` wie beim Intro, die Seite `{stats}` zeigt `stats_title` und die Zahlen aus `stats` (`value`: `days`, `gold`, `heroes` oder ein Erfolgs-Zähler wie `forge`, `order`, `dungeon`), danach laufen die Aktionen aus `then`, z. B. `sleep_at`), `cutscene:fade` (Bild kurz schwarz und wieder hell, in jeder Szene), `temple_seal:<vertiefung 0-2>,<siegel-id>` (Sturmtempel: Siegel aus dem Inventar einsetzen, `else` ohne Siegel; sind alle drei voll, prüft `StormTemple` die Plätze), `temple_pillar:<1-4>` (Sturmtempel: Säule anschlagen), `open_menu:hero_tournament` (Ausrufer der Gezeitenarena: Turnier-Fenster), `open_menu:armory` (General Hadmar: Waffen für Sylvaris abgeben, `ArmoryMenu`), `elf_defense_update` (setzt Hadmars Stufen-Flags `elf_defense_level_<0-3>` und `elf_defense_griffin_open`), `elf_defense_check` (genug Punkte » Flag `elf_defense_won`, siehe `ElfDefense`), `cutscene:<id>` (etwas in der Szene läuft von allein, z. B. `crowd_gold`, `crowd_food`, `silence`, `king_alert`, `crowd_throw`, `goblin_fall` beim Goblinkönig, `GoblinThroneCutscene`; die Dialogzeile hält mit `wait` die Knöpfe so lange zurück). Dialogzeilen können eine eigene `action` haben, die beim Anzeigen der Zeile läuft; mit `hide_for` (Sekunden) läuft sie bei ausgeblendeter Dialogbox, danach erscheint der Text. Kurze Gesten ohne eigene Cutscene: `cutscene:act:<npc-id>:<geste>[:<item>]` (Figur mit dieser npc-id in der Szene, `player` = Spieler; Item = Item-id, mehrere mit `+` zusammengesetzt, oder `res://`-Pfad), Gesten in `NpcActing` (`scenes/actors/npc_acting.gd`): `bite`, `eat`, `count`, `count_bite`, `hold`, `swing`, `strike`, `thrust`, `give`, `inspect`, `knead`, `glow`, `shake`, `tremble`, `hop`, `nod`, `bow`, `kneel`/`rise`, `sit`/`stand_up`, `get_up`, `face_player`, `turn:<richtung>`, `vanish`, `whistle`, `quake`, `boom`, `firelight`, `cheer`, `build`, `swarm`, `hammering`, `stomp`, `ring:<farbe>`, `unlock:<x>,<y>`, `block`, `push`, `splash`, `shadows`, `laugh`, `drink`, `drop`, `fizzle`, `sleep`, `trace`, `crash`, `run_off`; `glow:<farbe>` (ohne Farbe Schmiede-Blau); `give` mit mehreren Dingen nacheinander: `<item>|<item>` (z. B. Geldbeutel `res://assets/sprites/items/coin_purse.png` und ein Edelstein); mehrere Gesten hintereinander: `<geste>><geste>` (z. B. `drink>get_up`). Auch ein `Companion` mit `npc_id` spielt Gesten. Prüfen: `py assets/_reference/story_anims/check_beats.py`, eintragen ohne die Formatierung zu ändern: `add_beats.py`. Mehrere Aktionen hintereinander brechen beim ersten Fehlschlag ab (Prüfungen wie `has_items` und `pay_gold` daher vor `take_items` schreiben). Platzhalter in Texten: `{name}`, `{rent}`, `{rent_day}`, `{gold}`, `{donated}`, `{shop_gold}`, `{weekday}` (heute), `{first_order_gold}` (was Ulrich für das erste Schwert gezahlt hat, `GameState.story_order_gold`); `{rent_day}` ist ein Datum. Käufe setzen das Flag `bought_<angebot>` (`:` wird `_`). In Szenen: `StoryNpc` mit `npc_id`, `required_flag` (ab wann da), `hidden_when_flag` (wann weg), `auto_talk`, `walk_to_player` (läuft erst zum Spieler, nach `hidden_when_flag` zurück), `wait_for_player` (spricht erst, wenn der Spieler nahe kommt), `talk_area_scale` (größerer Sprechbereich, z. B. über eine Theke), `absent_steps` (in diesen Schritten weg), `talk_on_new_step`, `lying`, `facing`, `narrator` (unsichtbarer Erzähler), `resident` (Aussehen aus einem PixelLab-Bewohner, `assets/sprites/residents/<id>.png`), `vanish_on_leave` (mit `walk_to_player`: verschwindet nach `hidden_when_flag` sofort, statt zurückzulaufen), `roam_spot` (Ort einer umherziehenden Figur, npcs.json `roam`); Deko, die mit der Story kommt und geht: `StoryProp` (`required_flag`, `hidden_when_flag`); andere Knoten zeitweise ausblenden: `StoryHider` (`from_flag`, `until_flag`, `nodes`, z. B. die Händler beim Überfall); Bild wechseln ab einem Flag: `StoryTexture` (Sprite2D, `flag`, `texture_after`, `until_flag` = ab da wieder das erste Bild, z. B. verkohlte Häuser bis zum Wiederaufbau); Figur, die hinter dem Spieler herläuft: `Companion` (`npc_id` = spricht in Dialogen mit und spielt Gesten, `resident` / `hero` / `appearance`, `required_flag`, `hidden_when_flag`); Station, die nur zwischen zwei Flags auf E reagiert und E sonst durchlässt: `StoryStation` (`open_flag`, `close_flag`, z. B. die Heldenwahl am Drachen); ein Dungeon-Brett nur für bestimmte (auch versteckte) Dungeons: `DungeonBoardMenu.only_dungeons`; Plattform, die eine Ebene hoch oder runter fährt: `ElfLift` (`target_scene`, `target_spawn_point`, `text`, zeitweise gesperrt mit `closed_flag`/`open_flag`/`closed_text`); Cutscenes des Lich-Angriffs auf Sylvaris: `ElfAttackCutscene`; Felsbrocken, die erst eine bestimmte Spitzhacke zerschlägt: `HardBoulder` (`flag`, `min_pickaxe_damage`, `group_flags`, `group_done_flag`); Figur ohne Gespräch, die laufen kann: `GoblinFigure`; Türen können zeitweise gesperrt sein: `Door.blocked_flag`, `unblocked_flag`, `blocked_text`; `Door.fade` = Reise mit Überblendung (Kutsche); immer düstere Orte: `Gloom` statt `DayTint` (alle `NightLight`s brennen dauerhaft, `NightLight.always_on`); Zombies, die herumschlurfen: `Zombie` (`resident`, `wander_radius`); Kämpfer beim Überfall: `RaidFighter` (`resident` / `hero` / `appearance`, `target` = Zombie oder Lich, `start_flag`, `hidden_when_flag`, `start_from` = übernimmt den Platz eines Begleiters, `fight_distance`, `npc_id` = spricht mit); fehlt `required_flag` noch, wartet die Figur unsichtbar und erscheint, sobald es gesetzt wird; in Dialogen können weitere Figuren der Szene mitreden (`speaker` = deren npc-id); Flags `reached_<schritt>` entstehen automatisch. Mauerkrone (Teil 6, `IceWall`): `ice_pillar:<n>` (Eissäule 1–5 anschlagen, Reihenfolge `IceWall.PILLAR_ORDER`), `ice_mirror:<n>` (Silberspiegel in Sockel 1–3, false ohne Spiegel).

## leagues.json – Liga-Turniere und Rangliste

| Feld | Bedeutung |
|---|---|
| `rating` | `start` (Wertung am Anfang), `k` (Änderung pro Runde), `opponent_over_league` (Wertung des ersten Gegners über der Grenze der Liga), `round_step` (pro Runde stärker) |
| `open_hours` | Anmeldung `[von, bis]` Uhr |
| `season_shift`, `quality_step`, `time_step`, `level_step` | Spielplan-Verschiebung pro Jahreszeit; Schmiede-Gegner pro Runde besser / schneller; Helden-Gegner pro Runde Level höher |
| `venues.<id>` | `type` (`smith`/`hero`), `venue` (`""` = Leonheim bzw. Eisquell, sonst Ort aus economy.json bzw. arena.json `venues`), `city`, `offset`, `open_flag` |
| `leagues[]` | `id`, `name`, `rating` (Grenze); `smith`: `metal`, `leather`, `ores`, `quality` [von, bis], `time` [von, bis]; `hero`: `levels` [von, bis] (erste Runde), `metal`, `rarity` [von, bis] (0 = R1); beide: `entry_fee`, `prize_gold`, `title`, `trophy` (Möbel-id aus house.json), `first_win` (Items wie bei `give_items`), `season_reward` (`gold`, `items`) |
| `smith_opponents` | `name`, `look` (wie appearance.json) |

Orte nur für Ligen: in economy.json `smith_tournament.venues.<ort>` bzw. arena.json `venues.<ort>` `"league_only": true` (dazu `intro_text`, `closed_text` bzw. `round_names`, `opponents`).

Neue Liga: Eintrag in `leagues` (Grenze höher als die darunter, Pokal in house.json `furniture` mit `price` 0). Neuer Ort: Eintrag in `venues` und dort ein Herold- bzw. Ausrufer-Fenster mit demselben `venue`.

## world_map.json – die Weltkarte

Kristallkarte und Karte des Teleporters (`CrystalMapView`). Koordinaten in Karten-Einheiten (1180 × 600, wie die Skizze `assets/_reference/weltkarte/weltmap.png`).

| Feld | Bedeutung |
|---|---|
| `regions.<id>` | Gebiet: `name`, `flag` (Kartenteil, ab dem es zu sehen ist), `piece` (Nummer), `color`, `label` ([x, y] des Namens), `polygon` (Liste von [x, y]) oder `circle` ([x, y, radius]). Gezeichnet in Datei-Reihenfolge |
| `places` | Orte auf einem Gebiet: `name`, `region`, `at`, `kind` (village, city, volcano, castle, hut, tree, forest, water_city, ice_wall, tent_city, camp, temple, altar, mine, dunes, waves), `label` (Name daneben) |
| `crystals` | Elementkristalle: `name`, `place` (für die Legende), `region`, `at`, `color`, `gone_flag` (durchgestrichen), `owned_flag` (Ring), `title` |
| `teleporters.<ziel-id>` | Platz des Teleporters auf der Karte: `at`, `region`. Die Ziel-id ist die von `data/destinations/<id>.tres` und `Teleporter.spot_id` |
| `carriage` | Kutschen: `units_per_day` (Karten-Einheiten pro Reisetag), `min_days`, `arrival_hour`, `stops.<id>` (Haltestelle: `name`, `scene`, `spawn` = Ankunftspunkt, `at` = Platz auf der Karte, `flag` = ab hier fährt die Kutsche dorthin). In der Szene: Tür (`door.tscn`) mit `needs_interact` und `carriage_stop = "<id>"` |

Neuer Teleporter: Kristall in die Szene (`teleporter.tscn`, `spot_id`, `open_flag`, Spawnpunkt `FromTeleporter`), `data/destinations/<id>.tres`, in die Liste `destinations` des `TeleportMenu` in `teleporter.tscn` und einen Eintrag unter `teleporters` hier.

## desert.json – die Wüste (Labyrinth)

Die Wüste ist ein Labyrinth aus immer gleichen Bildschirmen (`DesertMaze`, Szene `scenes/world/desert/desert.tscn`). Benannte Orte sind durch Wege verbunden; jeder Schritt eines Weges ist ein eigener Bildschirm.

| Feld | Bedeutung | Beispiel |
|---|---|---|
| `start`, `town` | Feld am Anfang (Schild, dorthin kommt man nach dem Verlaufen), Feld der Stadt | `"start"`, `"town"` |
| `places.<id>` | benannter Ort: `name` (Sandkarte), `mark` (`sign`, `bones`, `ruins`, `chest`), `chest` (id aus `chests`), `scene` (eigene Szene statt der Wüste, z. B. Sahrim), `exits` (Richtung » `{scene, spawn}`: hinaus aus der Wüste) | `"bones": {"name": "Das Skelett", "mark": "bones"}` |
| `routes` | Liste `{from, to, moves, required_flag}` (`required_flag` optional: ohne das Story-Flag heißt diese Richtung verlaufen, mit ihm steht der Weg ganz auf der Sandkarte): Richtungen `N`, `O`, `S`, `W` mit Leerzeichen. Jeder Weg geht in beide Richtungen, jede andere Richtung = verlaufen. Aus einem Feld darf jede Richtung nur einen Weg haben | `{"from": "start", "to": "bones", "moves": "S S O O N W S S W"}` |
| `chests.<id>` | Truhe: `item`, `flag` (gesetzt, sobald offen), `text`, `required_flag` (optional: erst ab diesem Story-Flag zeigt der Kompass die Truhe; den Weg dorthin mit demselben `required_flag` sperren, z. B. Zahirs Amulett) | `"boots": {"item": "desert_runner_sandals", …}` |
| `goals` | Ziele der Kompassnadel (dazu immer jede ungeöffnete Truhe); ein Ziel kann `{place, flag, until}` sein (nur zwischen diesen Story-Flags) | `["town", {"place": "temple", "flag": "storm_map_owned", "until": "lightning_crystal_owned"}]` |
| `lost_hours`, `lost_flag`, `lost_text` | Verlaufen: so viele Stunden vergehen, Flag beim ersten Mal, Text | `1`, `"desert_lost_once"` |
| `required_compass` | bei `routes` (und als `compass` bei `goals`): Seltenheit, die der Wüstenkompass im Inventar mindestens haben muss (0 Gewöhnlich … 6 Legendär); sonst verlaufen, der Kompass zeigt nicht hin, auf der Sandkarte erst nach dem ersten Besuch | `{"from": "chest_gloves", "to": "pyramids", "moves": "S S O O N O N", "required_compass": 6}` |
| `outside_way` | Karte » nächste Karte auf dem Weg zur Wüste (Dorf, Schmiede, Markt, Wald, Mine). Außerhalb der Wüste zeigt der Kompass auf die Tür dorthin, auf anderen Karten auf den Teleporter. Erzeugt von `assets/_reference/compass/make_compass_way.py`, nicht von Hand pflegen | `"res://scenes/world/village/village_center.tscn": "res://scenes/world/village/village_gate.tscn"` |
| `storm_map` | Karte der Sturmpfade: `routes` = Wege `[von, nach]`, die von Anfang an darauf stehen; alle anderen erscheinen, sobald man am Ende war, die Truhe offen ist oder ihr `required_flag` gesetzt ist | `{"routes": [["start", "bones"], ["bones", "town"]]}` |
| `empty_chest_text`, `arrive_text` | Text einer leeren Truhe, Text beim ersten Betreten der Stadt | |

Neuer Ort: Eintrag in `places`, Weg in `routes`, bei `mark` ein neues Merkmal auch einen Knoten unter `Marks` in `desert.tscn` und in `desert.gd` (`MARKS`). Neuer Schatz: `chests` + Ort mit `mark: chest`. Test: `assets/_reference/desert/test_desert.gd` (prüft die Wege).

## calendar.json – Datum

| Feld | Bedeutung | Standard |
|---|---|---|
| `weekdays`, `weekdays_short` | Namen der Wochentage (die Woche beginnt mit dem ersten) | Montag … Sonntag, Mo … So |
| `start_weekday` | Wochentag von Tag 1 (0 = erster Eintrag) | `0` |
| `months` | Namen der Monate (hier Jahreszeiten); nach dem letzten beginnt ein neues Jahr | Frühling, Sommer, Herbst, Winter |
| `days_per_month` | Tage pro Monat | `28` |
| `moon_cycle`, `full_moon_day` | alle `moon_cycle` Tage ist Vollmond, der erste an Spieltag `full_moon_day` (Vermerk im Kalender, „Vollmond“ in der Zeitleiste; Mondlilien und Verzauberungstränke eine Seltenheit besser) | `14`, `7` |

## audio.json – Musik und Geräusche

Alle Sounds an einer Stelle; zum Austauschen nur den Pfad ändern (Datei nach `assets/audio/` legen, WAV, OGG oder MP3). Abgespielt vom Autoload `AudioManager` (`scripts/core/audio_manager.gd`).

| Feld | Bedeutung |
|---|---|
| `music_volume_db`, `sound_volume_db` | Lautstärke in Dezibel (0 = unverändert, -6 ≈ halb so laut, -80 = stumm) |
| `music` | id → Datei, läuft in Endlosschleife (die Schleife wird beim Abspielen eingeschaltet, egal wie importiert), oder id → Liste von Dateien: die Stücke laufen abwechselnd nacheinander (ohne Schleife, nach dem letzten wieder das erste). `default` läuft ab Spielstart und überall ohne eigenes Stück (derzeit `placeholder_theme.wav` und `village_background01.wav` im Wechsel); andere Stücke per `scene_music`, `flag_music` oder `AudioManager.play_music("<id>")` |
| `scene_music` | Szenen-Datei → Musik-id, z. B. `"deep_forest.tscn": "forest"`: beim Betreten der Szene wechselt die Musik (Wald-Eingang, tiefer Wald und Holzfällerhütte spielen `forest` = `forest_01.wav`) |
| `flag_music` | Liste von Regeln `{"from": Flag, "until": Flag, "music": id}`: läuft in jeder Szene (vor `scene_music`), sobald das Story-Flag `from` gesetzt ist, bis `until` gesetzt ist (`until` darf fehlen); die erste passende Regel gewinnt. Beispiel: der Überfall (Kapitel 10) spielt von `raid_started` bis `raid_over` das Stück `raid` |
| `sounds` | id → Datei: `anvil_perfect` (Amboss, grüner Punkt), `anvil_good` (gelb), `anvil_miss` (daneben / nicht im Takt), `skill_used` (Skill ohne eigenen Sound), `level_up` (Spieler steigt auf), `quench_hiss` (Wassertrog), `ingot_ready` (Schmelze fertig, nur in der Schmiede), `cast_pour` (Gießen an der Esse), `pickaxe_hit`/`axe_hit` (Schlag auf Stein/Baum), `rock_break`/`wood_break`/`plant_pick` (Stein/Baum/Pflanze weg), `door` (Tür), `step` (Schritte), `coins` (Gold bekommen/bezahlen), `ui_click` (jeder Knopf), `window_open`/`window_close` (Stations-Fenster), `chest_open` (Loot-Kiste), `achievement` (Erfolg), `item_reveal`, `rarity_up`. Neue Sounds im Code mit `AudioManager.play_sound("<id>")` |
| `sound_buses` | id → Regler im Menü: `Ambience` (Umgebung: Schritte, Türen, Hintergrundgeräusche) oder `Interface` (Oberfläche: Klicks, Fenster); ohne Eintrag `Sounds` (Effekte). Gesamt und Musik haben eigene Regler | `"step": "Ambience"` |
| Liste statt Pfad | Ein Geräusch kann eine Liste von Dateien sein, jedes Mal wird eine zufällig gespielt (Schritte, Münzen, Spitzhacke) | `"step": ["…/footstep00.ogg", "…/footstep01.ogg"]` |
| `sound_volume_db_by_id` | id → dB zusätzlich zu `sound_volume_db` (z. B. Schritte leiser) | `"step": -10` |
| `ambience` | Hintergrundgeräusch-Schleifen: id → Datei; `<id>_night` läuft nachts statt `<id>`, wenn vorhanden | `"forest": "res://assets/audio/ambience/forest.wav"` |
| `scene_ambience` | Szenen-Datei → id aus `ambience` (ohne Eintrag still), Regler „Umgebung“, Grundlautstärke `ambience_volume_db` | `"deep_forest.tscn": "forest"` |
| `indoor_scenes` | Innenräume (Szenen-Dateien): eine Tür hinein oder hinaus spielt `door`, Kartenwechsel draußen nicht | `["smithy.tscn", "nina_shop.tscn"]` |
| `skill_sounds` | Skill-id → Datei, z. B. `"fireball": "res://assets/audio/sfx/fireball.wav"`; ohne Eintrag `skill_used` |

Die Geräusche erzeugt `assets/_reference/audio/make_sfx.py` (selbst gemacht, keine Lizenz nötig; ein Geräusch = eine Funktion, ändern und neu ausführen, die Lautstärke steckt in der Datei), die Hintergrundgeräusche `make_ambience.py` (24-s-Schleifen: Wald, Dorf, Dorf nachts, Schmiedefeuer, Höhle, Lava), die Platzhalter-Musik `make_placeholder_sounds.py`. Dateien in `assets/audio/sfx/kenney/` sind von Kenney.nl (CC0, frei auch kommerziell, Nennung freiwillig; `LICENSE.txt` dort). Skill-Sounds hört man nur bei offenem Kampffenster.

## combat.json – Formeln

„pro 10“ = je volle 10 Punkte. Ein Held hat auf Level 1 in jedem Attribut `start_attribute` (5), dazu den Klassen-Bonus aus `data/hero_classes/*.tres` (`attribute_bonuses`: Krieger Stärke +3, Schurke und Waldläufer Beweglichkeit +3, Magier Intelligenz +3, Priester Weisheit +3, Paladin Konstitution +2 und Widerstand +1) und alle `levels_per_attribute_bonus` (4) Level +1 auf alle Attribute, plus verteilte Punkte und Ausrüstung.

| Wert | Bedeutung |
|---|---|
| `hero_base_health`, `hero_base_mana` | Grund-Leben (20) und -Mana (8) |
| `mana_per_level` | Mana pro Helden-Level über 1 (1; bis 2026-11-05 0,5) |
| `skill_mana_per_level` | Skills kosten pro Skill-Stufe über 1 so einen Anteil ihrer Mana mehr (0,25: Stufe 3 = 150 %, Stufe 5 = 200 %); skills.json `mana_per_level` überschreibt es pro Skill (0 = gleiche Kosten auf jeder Stufe). Gilt nur für Helden, Monster benutzen Stufe 1 |
| `health_per_level` | Leben pro Level über 1 (4) |
| `hero_health_regen`, `hero_mana_regen` | Grund-Regeneration pro Sekunde (0.1) |
| `hero_base_damage_min/max` | Grund-Waffenschaden (1–3), Waffe und Stärke kommen dazu; auch Grundwert der Zauber |
| `hero_attack_interval` | Sekunden zwischen zwei Schlägen (1 = 1 Angriff pro Sekunde), geteilt durch `attack_speed` des Waffentyps |
| `offhand_attack_classes`, `offhand_attack_interval_factor`, `offhand_attack_damage` | Klassen, deren Waffe in der linken Hand selbst zuschlägt (`["rogue"]`), so viel langsamer als die rechte (`2` = halb so oft), Schaden als Anteil von Waffe links + Attribut-Schaden (`0.5`, Passive `offhand` = Beidhändig kommt dazu) |
| `no_arrow_damage_factor` | Bogen ohne Pfeile: Anteil des Bogenschadens (0.25 = 25 %) |
| `arrow_damage_factor` | Pfeile: Schaden von Spitze + Schaft + Befiederung mal diesen Wert (3), so machen bessere Pfeile Waldläufer deutlich stärker |
| `hero_max_stamina`, `hero_stamina_per_hour`, `hero_stamina_per_night`, `dungeon_stamina` | Ausdauer der Helden: höchstens 100, pro Spielstunde +5, über Nacht +30, Standard-Kosten eines Dungeons 20 (dungeons.json `stamina` überschreibt sie) |
| `hero_slots_base`, `hero_slots_per_rank` | Heldenplätze: 3 am Anfang, +2 pro Ruf-Rang über F (E = 5, D = 7 … S+ = 17); dazu +1 pro Gildenausbau (guild_heroes.json `hero_slots`) |
| `parallel_dungeons_base`, `parallel_dungeons_flags` | So viele Dungeons laufen gleichzeitig: 1 am Anfang, +1 pro gesetztem Story-Flag der Liste (`reached_chapter10_end` = Ende von Teil 1), +1 pro Rang des Spieler-Skills „Gefolgschaft“. Story-Kämpfe (z. B. Ratten in der Mine) und Turnier-Duelle zählen nicht |
| `defeat_loot_share`, `defeat_experience_share` | Verlorener Dungeon: so ein Anteil der Monster-Beute (jedes Stück einzeln gewürfelt) kommt trotzdem in die Loot-Kiste, und so ein Anteil der PEXP des Dungeons gibt es für den Spieler | `0.3`, `0.3` |
| `hero_base_armor`, `hero_base_magic_resistance` | Grund-Rüstung (5) und -Magieresistenz (0) |
| `damage_per_str`, `health_per_10_str` | Stärke: +0,5 Waffenschaden pro Punkt (abgerundet), +1 Leben pro 10 |
| `crit_chance_per_agi`, `evasion_per_10_agi` | Beweglichkeit: +1 % Krit-Chance pro Punkt, +2,5 % Ausweichen pro 10 |
| `health_per_con`, `health_regen_per_10_con` | Konstitution: +2 Leben pro Punkt, +1 Leben/s pro 10 |
| `magic_damage_per_int`, `mana_per_int`, `mana_regen_per_10_int` | Intelligenz: +2 % Zauberschaden und +1 Mana pro Punkt, +0,6 Mana/s pro 10 (bis 2026-11-05 +1) |
| `mana_regen_per_10_wis` | Weisheit: +0,6 Mana/s pro 10 (bis 2026-11-05 +1) (Priester und Paladine zaubern mit Weisheit; seit 2026-10-26, vorher hatten sie fast kein Mana) |
| `heal_power_per_wis`, `shield_power_per_wis`, `health_per_10_wis` | Weisheit: +0,3 % Heil- und Schildkraft pro Punkt (seit 2026-11-08, vorher 1 %), +2 Leben pro 10. Heilkraft/Schildkraft aus Passiven und Ringen wird dazu addiert, nicht multipliziert: 1 + 0,3 % × WIS + Bonus |
| `shield_per_caster_level`, `shield_per_caster_wis` | Zauber-Schilde (`caster_shield`): Schildpunkte pro Level und pro Weisheit des Wirkers (1 und 5) |
| `hero_start_iq`, `iq_simple`, `iq_specific`, `iq_all` | IQ der Helden für Befehle: Start 60, ab 80 einfache Ziele, ab 100 Bosse und Bedingungen mit < / >, ab 120 alles (siehe `SkillCommand`) |
| `hero_max_bonus_skill_points`, `hero_max_bonus_attribute_points` | so viele Skill- / Attributpunkte kann ein Held höchstens aus Tränken bekommen (3 / 6) |
| `hero_max_iq`, `iq_focus`, `iq_role_<rolle>` | höchster IQ durch Tränke (150); ab `iq_focus` (80) folgen Helden dem Fokus (Gegner im Kampfbild anklicken); IQ pro Rolle (`HeroRole`, Standard: Bossjäger/Aufräumer 85, Vollstrecker/Schwächer 100, Unterstützer 110) |
| `hard_modes` | Schwere Dungeons, ein Eintrag pro Stufe: `power` (Gegner so oft so stark), `drop_factor` (Drops öfter, Belohnungs-Items mehr), `rarity_factor` (seltener), `rarity_shift` (jede Beute so viele Stufen seltener: 1 = mindestens R2, gewürfeltes R2 wird R3), `extra_ingots` (Boss-Barren sicher + so viele), `gold_factor`, `exp_factor` (PEXP). Stufe N öffnet nach einem Sieg auf Stufe N−1 |
| `dungeon_loot` | `chance_factor` (Monster-Drops öfter), `rarity` (Material/Erz/Barren, die R1 blieben, z. B. `{"R2": 0.35}`), `boss_ingot_chance`, `boss_ingot_rarity` (welcher Barren: `rewards.boss_ingot` im Dungeon) |
| `resistance_per_res`, `tenacity_per_10_res` | Widerstand: +1 auf jede Resistenz pro Punkt, +3 % Zähigkeit pro 10 |
| `max_evasion`, `max_tenacity`, `max_cooldown_reduction` | Obergrenzen (0.9, 0.8, 0.5) |
| `resistance_base` | Formel Schaden × B / (B + R), Standard 100 – gilt für Rüstung, Magieresistenz und Resistenzen |
| `max_penetration_percent` | höchste Durchdringung in % (1.0 = 100 %). Reihenfolge pro Treffer: Rüstung × Buffs/Debuffs in %, dann Durchdringung in %, dann in Punkten, nie unter 0 |
| `crit_chance`, `crit_damage` | Grund-Krit-Chance (0.05 = 5 %) und Krit-Schaden (1.5 = 150 %) |

**Schaden:** normaler Schlag = Grundschaden + Waffe + Stärke. Physischer Skill = dieser Schaden × Skill-Faktor. Zauber (`damage_kind: magic`) = (Grundschaden + Magieschaden der Waffe) × Skill-Faktor × (1 + 2 % pro Intelligenz). **Abwehr:** physische Arten werden durch Rüstung + ihre Resistenz verringert, Elemente und reine Magie durch Magieresistenz + ihre Resistenz, Wahrer Schaden gar nicht. **Zähigkeit** verkürzt Debuffs auf dem Helden, **Buff-Dauer** verlängert Buffs, die er wirkt, **Abklingzeit** verkürzt Skill-Cooldowns (beide noch ohne Quelle, später Items/Skills). **Heilkraft** verstärkt Heilungen (z. B. Erholung), **Schildkraft** Schilde. Monster: Leben, Mana, Schaden kommen aus enemies.json; ihre Attribute wirken auf Krit, Ausweichen, Zauberschaden, Resistenzen und Zähigkeit (Stärke erhöht ihren Schaden nicht).

## Wo ids sonst stehen

- Händler (`market.tscn`, Feld `offers`): `"wood"`, `"wood*5"`, fertige Waffe: `"sword:iron_blade+iron_handle"`, fertiger Schmuck: `"jewel_ring:silver_ring_band#ruby.lifesteal"` (Kristall und Wirkung; `#ruby` = zufällige Wirkung des Kristalls, `#any` = zufälliger Kristall; Amulett: `jewel_amulet:silver_amulet_band#…`).
- Steine/Bäume/Pflanzen (`data/rocks/*.tres`): `drop_item_id`, `bonus_drop_item_id`, `better_rarity_chance` (Chance, dass das Gesammelte eine Seltenheitsstufe besser ist, Hanf und Flachs 0.1 = 10 % R2).
- Aufträge (`data/quests/*.tres`): `required_item_id`, `required_part_id`, Belohnung `item_id`, `unlock_recipe_ids`.
- Rezept-ids: gegossene Teile `mold_<teil>` (Gussofen) und `<teil>` (Amboss), geschnitzte Teile `<teil>`, Waffen `<waffe>`.

## Export

Beim Windows-Export müssen die JSON-Dateien mit: im Export-Dialog unter „Ressourcen → Filter für Nicht-Ressourcen-Dateien“ `*.json` eintragen. Die Vorlage „Windows Desktop“ in `export_presets.cfg` hat das schon eingetragen.

## Seltenheit, Qualität und seltene Materialien

- `materials.json`: `rarity` ist für alle Materialien R1, `tier` ist die Materialstufe (0 Holz, 1 Kupfer/Rattenleder, 2 Eisen/Wolfsleder, 3 Bronze/Drachenleder, 4 Silber/Hippogreifleder/Harpyienfeder, 5 Gold, 6 Platin, 7 Palladium; seit 2026-11-10, vorher teilten sich Silber und Gold Stufe 3). Leder und Federn haben die Stufe ihres Metalls.
- `economy.json` → `crafting_quality`: `cast_quality` (Qualität jedes gegossenen Rohlings, 50; die Seltenheit kommt vom Barren), `anvil` (green/yellow/miss: Punkte fürs ganze Teil), `joining` (perfect/good/okay/fail), `grindstone` (Punkte am Schleifstein bei 100 % im Grünen, anteilig weniger; jede Waffe ist schärfbar), `grindstone_game` ({seconds, zone, zone_speed, lift, gravity}: Dauer, Höhe und Tempo des grünen Bereichs, Beschleunigung des Balls mit / ohne Linksklick), `difficulty` (Liste {max_gap, name, speed, green, yellow}: Abstand = tier − Ruf-Rang − Materialkunde), `loot_rarity` ({chances: {R2: 0.12, …}, per_dungeon_level}).
- Item-Angaben bei Händlern und in `give_items` können eine Seltenheit haben: `silver_ingot@R3` (genau R3) oder `silver_ingot@R3-R4` (zufällig R3 oder R4).
- In `has_items`, `take_items` und `show_items` heißt `@R4+` „mindestens R4“ (seit 2026-11-12): `polearm:bronze_spear_head*2@R4+` = zwei Speere mit Bronze-Spitze, jeder Schaft, ab R4. Nur die genannten Teile zählen (vorne beginnend), die übrigen sind egal; das Auftragsbuch zeigt „(ab Ungewöhnlich)“. Beispiel: Waffen fürs Bündnis (`council_weapons`).
- Steine (`data/rocks/*.tres`): `better_rarity_chance` (Metallerze 0,05 = 5 % R2), `rare_drop_chance` (Kristalle aus Eisenstein 0,05); der Skill Glücksfund addiert seinen Wert.
- Neuer Teil-Typ `staff_rod` (Eisenstab); Eisen-Zauberstäbe sind Items mit `damage_split` (`{"magic": 50, "fire": 50}`) und Rezepten in `recipes.json` (Zaubertisch, Eisenstab + Kristall, `locked`: werden mit der Eisenstab-Gussform frei).

## Gildenstufen (`guild_heroes.json` → `guild_levels`)

Ausbaustufen der Abenteurergilde (Hedwig), der Reihe nach. Die Kosten stehen in `story.json` (Dialoge `guild_upgrade_1`–`3`, Neben-Aufgaben `guild_upgrade_1`–`3`).

| Feld | Bedeutung | Beispiel |
|---|---|---|
| `flag` | Story-Flag der Stufe (setzt Hedwigs Dialog) | `"guild_level_1"` |
| `hero_slots` | so viele Heldenplätze mehr | `1` |
| `level`, `count` | Level-Spanne und Anzahl der Helden pro Tag (ersetzen `level`/`count` oben in der Datei) | `[2, 6]`, `[2, 5]` |
| `search_orders` | so viele Suchaufträge gleichzeitig | `1` |
| `search_max_rarity` | beste Seltenheit bei Suchaufträgen | `"R2"` |

## arena.json – Kahns Heldenturnier

Turnier in der Gezeitenarena von Eisquell (`HeroTournament`, Kämpfe `ArenaDuel`, Gegner `HeroBuilder`).

| Feld | Bedeutung | Beispiel |
|---|---|---|
| `dungeon` | versteckter Dungeon aus dungeons.json: Name, Hintergrund und Zeitlimit eines Kampfs (Zeit um = mehr Leben in Prozent gewinnt) | `"arena_duel"` |
| `health_factor`, `heal_factor` | Leben beider Kämpfer mal das, jede Heilung mal das (sonst ist ein Duell in Sekunden vorbei bzw. ein Heiler verliert nie) | `4`, `0.25` |
| `participants`, `round_names` | Größe des Turnierbaums (Zweierpotenz) und Name jeder Runde | `16`, `["Achtelfinale", …, "Finale"]` |
| `opponents` | Zufällige Gegner: `level_offset` (pro Runde `[von, bis]` zum Level des eigenen Helden), `level_min`, `rarity` (`[von, bis]`, 0 = R1), `metals` (`[ab Level, Metall]`), `builds`, `races`, `names` | |
| `champions` | Feste Gegner: `name`, `build`, `race`, `seed`, `appearance`, `attributes` (Gewichte), `level_min`, `level_over_hero`, `metal`, `rarity`, `slot` (Platz im Baum), `wins_until` (gewinnt alle Kämpfe ohne den Spieler bis zu dieser Runde) | Torgai auf Platz 4 = Halbfinale |
| `builds` | Baupläne wie im Simulator: `class`, `weapon`, `shield`, `offhand`, `staff`, `attributes`, `skills` | |

| `venues.<ort>` | Weitere Austragungsorte (seit 2026-10-30: `sylvaris`, Wettkampfring der Kronen). Jedes Feld hier ersetzt das von Eisquell (`opponents` und `champions` ganz), dazu: `won_flag` und `wins_flag_prefix` (eigene Story-Flags statt `hero_tournament_won` / `hero_tournament_win_<n>`), `prize_gold` (Gold für jeden Turniersieg dort). Das Fenster des Orts: `HeroTournamentMenu.venue`; öffnet man es, verfällt ein nicht kämpfender Turnierbaum eines anderen Orts | `"round_names": ["Wurzelkreis", …]` |

Balancing: `assets/_reference/story4/sim_tournament.gd` (Siegquote und Dauer pro Runde und Klasse).
