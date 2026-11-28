# Inhalte anlegen (ohne Code)

Alles in `data/`. Nach jeder Änderung: `bash assets/_reference/run_tests.sh test_content` und bei neuen Texten `py assets/_reference/i18n/build_po.py` (Übersetzungen in `assets/_reference/i18n/translations.json` eintragen).

## Item (`data/items.json`)

```json
"glutkern": {"name": "Glutkern", "desc": "Schaden hoch", "icon": "res://assets/sprites/items/ember_essence.png",
             "stats": {"damage": 1.0}, "flags": [], "mode": "fire", "pools": ["shop", "boss"]}
```

- `stats`: `damage`, `fire_delay` (Sekunden zwischen Schüssen), `reach` (Meter), `shot_speed`, `size`, `spread` (Grad, größter Wert gilt), `move_speed`, `knockback`, `shots` (zusätzliche Schüsse), `orbitals` (Glutmonde), `hearts` (Herz-Container). Mit `_mult` dahinter wird multipliziert (`"fire_delay_mult": 0.65` = schneller).
- `flags`: `homing`, `pierce`, `bounce`, `boomerang`, `split`, `wave`, `bread`, `charge`, `jitter`, `explosive`, `burn` (Gegner brennen), `slow` (Gegner langsamer), `grow` (mehr Schaden, je weiter der Schuss fliegt), `shield` (Feuerbälle zerstören Gegner-Schüsse), `blast_proof` (Explosionen schaden dir nicht), `mantle` (erster Treffer pro Raum wird abgefangen). Zahlen für `burn`, `slow`, `grow` stehen in `data/player.json` unter `effects`.
- `per_coin`: Werte je Münze, die du hast, z. B. `{"damage": 0.04}` (Goldglut).
- `give`: gibt es beim Aufheben dazu: `{"loot": {"amber": 1}, "bombs": 3, "keys": 3}` (`loot` = Beute-Ids aus `loot.json` für die Tasche; Münzen gibt es im Dungeon nicht).
- `mode`: `beam` (Feuerstrahl) oder `bomb` (Bomben werfen).
- `heal_full: true` heilt beim Aufheben ganz.
- Item-Raum: **jedes** Item kann kommen, außer `"secret": true` (für spätere Geheimräume) und noch gesperrte.
- `pools`: zusätzlich `shop` (Laden) und/oder `boss` (Boss-Belohnung: nur einfache Werte- und Herz-Items, keine `flags`/`mode`; das prüft `test_run_state`).
- `stats` kennt auch `blue_hearts` (blaue Herzen: kommen oben drauf, Treffer nehmen sie zuerst, nicht heilbar). Negative `hearts` nehmen Herzen weg.
- `unlock`: das Item ist erst nach einer Freischaltung im Spiel: `{"type": "boss", "id": "rat_king"}`, `{"type": "wins", "count": 1}`, `{"type": "kills", "count": 200}`, `{"type": "discovered", "count": 25}`. Der Text im Lexikon entsteht daraus von selbst.
- Es sind genau 213 Items: 210 plus die drei Start-Waffen der Helden (`test_content` prüft das).
- Flug: `fly` (fliegen: Fallen am Boden tun nichts, kein Absturz in der Räderkluft, Sicht höher, `player.json` `fly_height`/`fly_bob`), `ghost` (fliegen und durch Steine gehen).
- `chance`: Zufallseffekte, z. B. `{"freeze": 0.15}` (15 % pro Schuss, Glück erhöht das).
- `spawn`: Pickups, die beim Aufheben erscheinen (`heart`, `bomb`, `key`).
- `secret: true`: nur im Geheimraum (dann keine `pools`). Weitere `pools`: `pact` (Glutpakt) und `shrine` (Schrein).
- Neue `stats`: `bomb_size`, `luck`, `guard_time` (Sekunden), `helpers` (Funken).
- Neue `flags` und alle Zahlen dazu: `data/items.json` „_info“ und `data/player.json` „effects“.
- `unlock` auch `{"type": "best", "key": "coins", "count": 55}` (hearts, coins, blue, clean_floors, pacts, floor) und `{"type": "fast_win", "count": 30}`.

- `category`: offensiv, defensiv oder utility (Pflicht). `docs/ITEMLISTE.md` wird daraus erzeugt.
- Neue Werte/Flags: `body` (Größe, mit `body_mult`), `bleed`, `shuriken`, `dash`, `blink`, `mode: melee`.

## Charakter (`data/characters.json`)

`name`, `desc`, `icon`, `hearts`, dazu `stats`/`flags`/`mode` wie bei Items und optional `weapon` (Bild in der Hand) und `unlock`.

## Gegner-Extras (`data/enemies.json`)

`leap` {every, range, height}, `burrow` {every, time}, `front_guard` true, `voice` {wave, freq, slide, length, noise, vibrato}. `cries` {idle, wake, near, attack}: je eine Stimme wie `voice`, dazu `noise_end` (Rauschen am Ende, „Wa-chhh“), `rough` (1 = Zischen, 6 = Knurren), `rise` (Anschwellen), `fade`, `tremolo` (Klicken/Rattern), `repeat`/`gap`/`repeat_pitch` („fiep fiep“), `volume` in dB; `idle.every` [min, max], `near.range`/`near.cooldown`. `leap.windup` = Ducken vor dem Sprung. Bosse: `attacks` (siehe `boss_brain.gd`), `traits` (regen, lifesteal).

## Thema und Ebene (`data/floors.json`)

Ein neues Thema in `themes` (mit 2–4 `bosses`, `rock_texture`), dann zwei Einträge in `floors` mit diesem `theme` (eigene `rock_patterns`, gern eigene Texturen). Neue Gegner in `data/enemies.json`.

## Synergie (`data/synergies.json`)

```json
"feuerwerk": {"name": "Feuerwerk", "desc": "…", "requires": [["suchender_funke"], ["zwillingsstab", "dreizack"]], "stats": {"damage": 0.3}}
```

Gilt, wenn aus **jeder** Gruppe in `requires` mindestens ein Item da ist. `stats`/`flags` wie bei Items.

## Gegner (`data/enemies.json`)

`sprite` = Pfad ohne Endung; es braucht `<sprite>_walk.png` und `<sprite>_death.png` (6 Bilder à 48×48 nebeneinander, wie alle Smithy-Gegner in `assets/sprites/enemies/`). Werte: `hp`, `speed` (m/s), `damage` (halbe Herzen), `radius`, `height` (Meter), `ai` (`lurk`, `chase`, `fly`, `hop`, `shooter`, `boss`), `wake` [min, max] für `lurk`, `shot_speed`, `fire_interval`, `keep_distance`, `spray` für Schützen, `attacks`, `summon`, `ring` für Bosse, `drop_chance`.

## Ebene (`data/floors.json`)

- `item_room: false` = diese Ebene hat keinen Item-Raum; `key_doors: ["shop", "item"]` = diese Räume brauchen einen Schlüssel.

Liste `floors` der Reihe nach: `name`, `floor_texture` (32×32), `wall_texture` (32×48), `rooms` (normale Räume), `enemies` ([Id, Gewicht]), `enemy_count`, `first_room_enemies`, `boss`, `music` (Id aus `audio.json`), `light` (Farbe), `key_doors` (Raumarten mit Schlüssel-Tür). Die letzte Ebene endet mit dem Sieg. Dazu `room_styles`, `shop` (Preise, Händler-Bild), `room_drops`, `rocks`.

## Beute (`data/loot.json`)

- `materials`: `"id": {"name", "desc", "icon", "rarity": 1-8, "value"}`. `rarity` = Rahmenfarbe (R1 grau … R8 rosa), `value` = Gold beim Händler.
- `enemies`: `"gegner_id": [{"id": "material", "chance": 0.3, "amount": [1, 2]}, …]`. Jede Zeile wird einzeln gewürfelt. **Jeder Gegner braucht eine Zeile** (der Test prüft das).
- `luck_bonus`: zusätzliche Chance je Glückspunkt.
- `bomb`, `key`, `iron_key`: Bomben und Schlüssel als Beute im Inventar. `key: true` = öffnet Türen, `fragile: true` = zerbricht beim Verlassen des Dungeons; `stack` = so viele auf einem Feld (Bomben 5, Schlüssel 1).
- `room_budget`: `drops` = so viele Dinge gibt ein Raum höchstens her (normale Gegner + Raum-Belohnung; Beute, Münzen, Herz, Bombe), `luck_extra` = mehr je Glückspunkt. Bosse zählen nicht.
- `key_chance`: Chance (0–1), dass ein normaler Gegner einen Schlüssel fallen lässt – ein Wert für alle Gegner (Bosse nie). Zufällige Raum-Belohnungen (`floors.json` `room_drops`) geben keine Schlüssel.
- Neue Texte (`name`, `desc`) danach übersetzen (`build_po.py` findet sie selbst).

## Spielstand-Regeln (`data/meta.json`)

- `bag`: `columns` × `rows` (Raster des Inventars im Run), `safe` [Breite, Höhe] (sicherer Platz, bleibt beim Tod), `stack` (höchste Anzahl pro Platz), `board` [links, oben, rechts, unten] (Bereich, in dem Rucksäcke angebaut werden dürfen; das Inventar liegt bei 0,0).
- Beute (`loot.json` materials): `size` [Breite, Höhe] in Inventar-Feldern (fehlt = `default_size`). Faustregel: Kleinkram 1×1, Felle/Häute 2×2, Federn/Essenzen 1×2, Stäbe 4×1, seltene Edelsteine und große Felle 3×3. Alles muss ins 8×3-Inventar passen (Test).
- Rucksäcke (`backpacks.json`): `name`, `desc`, `icon`, `size` [Breite, Höhe], `color` [r, g, b], `price` (Egons Tisch), `unlock` (ab wann auf dem Tisch). Bekommen über einen Skill mit `effect` `{"backpack": "<id>"}` oder auf Egons Tisch (`shop.json` `backpack_chance`).
- Ausrüstung im Lager: Größe nach `gear.json` slots `size` (Handschuhe 1×1, sonst 2×2). Egons Tisch: `shop.json` `table_grid` [Breite, Höhe].
- `stash`: `columns` × `rows` des Lagers zu Hause (Raster).

## Egons Quests (`data/quests.json`)

- `start` (Egons Ort am Anfang), `locations` (Ort → `name`, `background`), `quests` (der Reihe nach: `name`, `desc`, `dungeon` = Endboss dieses Dungeons lässt den Stein fallen, `item` = Stein aus `loot.json` mit `"quest": true`, `moves_to` = Egons neuer Ort, `gold` = Belohnung). Ein Dungeon öffnet sich mit `unlock` `{"quest": "<id>"}`. Egons Sätze: `story.json` `quest_<id>_intro` und `quest_<id>_done` (aus `docs/figuren/EGON_EHRLICH.md`).
- `money_box`: `limit` (so viel ist in der Dose sicher), `steal_all_chance`, `steal_part_chance`, `steal_part_share` [min, max].

## Dungeon auf Egons Brett (`data/dungeons.json`)

- `"id": {"name", "region", "desc", "level"}`: `name`/`desc` = Text auf dem Brett, `region` = Reiter (z. B. „Umgebung“), `level` = empfohlene Stufe. Reihenfolge = Reihenfolge auf dem Brett.
- Ebenen und Gebiete kommen aus `floors.json` (eigene Ebenen je Dungeon: Phase 4).
- Neue Texte danach übersetzen (`build_po.py` findet `name`, `region`, `desc` selbst).

## Ausrüstung (`data/gear.json`)

- `slots`: Plätze an der Figur, `"id": {"name", "hint", "at": [x, y]}` (`hint` = Bild `assets/sprites/ui/slot_hints/equip_<hint>.png`, `at` = Mitte in der Helden-Ansicht).
- `gear`: `"id": {"name", "desc", "slot", "icon", "price", "class"?, "stats"}`. `stats` wie in `player.json` (wirken ab Phase 3), mal `rarity_stats` je Seltenheit. `class` = nur für diese Klasse (Tooltip „Nur für“).
- Neue Ausrüstung taucht im Laden erst auf, wenn sie in `shop.json` `pool` steht. Der Test prüft Bild und Platz.
- **Bauarten** (`gear.json` `types`, je Platz): `normal` (ohne Name) und Bauarten mit `name`, `weight` (wie oft auf dem Tisch), `mult` (Faktor auf die eigenen Werte des Teils, wächst mit der Seltenheit) und `stats` (Vor-/Nachteile dazu, wachsen nicht; `fire_delay_mult` < 1 = schneller schießen). Jede Bauart braucht einen Vorteil und einen Nachteil (Test). Neue Namen: `build_po.py` nimmt sie mit.

## Egons Laden (`data/shop.json`)

- `table_slots`, `goods_count` [min, max], `roll_prices` (1., 2., 3. … Hebel-Zug am Tag), `reroll_shift` (so viele Prozent wandern mit jedem weiteren Zug am Tag von R1 zu den selteneren Stufen), `reroll_shift_max`, `r1_min` (R1 nie darunter), `pool` [[id, Gewicht]], `rarity_weights` [[Seltenheit, Gewicht]], `rarity_price` (Preis-Faktor R1..R8).
- `tutorial.goods` [{id, rarity, cell}] = Egons erster Tisch, `tutorial.gifts` = was davon geschenkt und angelegt wird.

## Texte der Figuren (`data/story.json`)

- Jeder Schlüssel ist eine Liste von Sprechblasen (höchstens zwei Sätze), `barks` sind einzelne Sätze. Egons Texte werden aus `docs/figuren/EGON_EHRLICH.md` gebaut.
- `build_po.py` findet alle Sätze selbst; danach übersetzen.

## Gold im Dungeon

- Es gibt keine Münzen zu finden. Gold gibt es nur beim Händler im Dungeon-Shop für Beute (`loot.json` `value`, Goldnase `sell_bonus` je Stück). Preise im Run-Shop: `floors.json` `shop`.
- Opferstein-Belohnungen (`floors.json` `sacrifice.rewards`) dürfen Beute-Ids sein (fallen als Beute heraus).
- Bosse: `enemies.json` `summon_max` = so viele gerufene Helfer leben höchstens gleichzeitig.

## Relikte (`data/relics.json`)

- `items`: `"item_id": Stufe` (1 schwach … 4 stark). Neues Item als Relikt erlauben = Zeile hinzufügen.
- `tiers`: `"1": {"dungeons": 0, "price": 40, "rarity": 2, "weight": 4}` … (`dungeons` 0 = hält für immer).
- `table_chance`: Chance je Hebel-Zug, dass ein Relikt auf dem Tisch liegt.

## Stufen (`data/levels.json`) und Skills (`data/skills.json`)

- `levels.json`: `exp_per_kill`, `exp_per_boss`, `first_level_exp`, `growth`, `max_level`, `points_per_level`, `start_points`.
- `skills.json` je Skill: `name`, `desc`, `icon`, `pos` [Spalte, Zeile], `requires`, `max_level`, `gold` [je Stufe], `points` [je Stufe], `min_level` [Spielerstufe je Stufe], `effect` (`stats`, `shield_halves`, `hearts`, `backpack` (Id aus backpacks.json), `safe_slots` (sicherer Platz eine Spalte breiter), `relic_slots`, `relic_runs`, `sell_bonus`, `goods_extra` (mehr Ware auf Egons Tisch), `rarity` (`{"2": 5}` = 5 % von R1 zu R2 je Stufe)). Neuer Skill = neuer Eintrag; Texte danach übersetzen.

## Dungeons, Fallen, Materialien (2026-11-27)

- **Neuer Dungeon:** in `dungeons.json` eintragen (`name`, `region`, `desc`, `level`, `floors` = Name einer Liste in `floors.json`, `unlock` `{"dungeon": "<id davor>"}`, `hp_mult`, `exp_mult`, `shop_mult`), in `floors.json` die Liste `floors_<id>` mit 6 Ebenen anlegen, Gebiete unter `themes`. Der Test `test_dungeons.gd` prüft Texturen, Musik, Gegner, Bosse und Fallen.
- **Gebiet (`themes`):** wie bisher, dazu `hazards` [[Art, [min, max]], …] = Fallen je normalem Raum, `props` [[Bild, Gewicht, Höhe in Metern], …] = Deko an den Wänden (Menge im Abschnitt `props` oben in `floors.json`).
- **Fallen-Arten (`floors.json` `hazard_types`):** `damage` (halbe Herzen), `size` [min, max] m, `cycle` [unten, oben] Sekunden (nur Stacheln), `color` RGB, `glow`.
- **Material (`shop.json` `materials`):** `name`, `weight`, `lever_mult`, `unlock` (`level`, `dungeon`). Für jedes Material braucht `gear.json` alle Teile aus `pool` als `<material>_<teil>` (Test prüft das).
- **Balance nachrechnen:** `py assets/_reference/balance/balance.py`, Erklärung in `docs/BALANCE.md`.

## Tränke (`data/potions.json`, 2026-11-27)

- `potions`: `name`, `desc`, `icon`, `price`, `heal` (halbe Herzen), `rarity`, `unlock` (wie Materialien). `tour_potion` = Egons Geschenk, `unlock_deaths` = nach so vielen Toden zeigt Egon die Tränke, `slots` = Trank-Plätze, `table_chance` = Chance je Hebel-Zug. Neuer Trank = neuer Eintrag, Texte übersetzen (`build_po.py` liest `potions.json` mit).

## Neue Gegner-Muster und hohes Gras (2026-11-27)

- **Gegner (`enemies.json`):** `ai` `charger`, `turret`, `wall`, `bouncer`, `spawner`, `shell` (Erklärung im Kopf von `scenes/actors/enemy_moves.gd`); `pattern` (aimed, fan3, cross, diagonal, star, alternate, ring); `tint` [r, g, b]; `death_shots`, `death_spawn` [Id, Anzahl], `death_blast` {radius, damage}; `revive` {time, times, down_life}; `burrow.shots`; `laser` {aim, fire, width} für `charger`; `range`, `climb`, `flee`, `spawn_every`, `open`, `windup`, `rush`, `sight`.
- **Bosse:** `keep_distance`, `stationary`, Trait `evade`, `snare` (Fallen-Art), Angriffe `aimed_shot`, `snares`, `volley`, `laser`, `laser_sweep`, `cross`.
- **Gras (`floors.json` Gebiet/Ebene `grass`):** `height` m, `per_m2`, `color`, `spread`.
- **Fallen:** `hold` = Sekunden festhalten (Fangeisen), `hidden` = kaum sichtbar.
- Faustregel für neue Gegner: **ein** klares Muster, eine Vorwarnung (Wackeln, Anschwellen, Linie), ein sicherer Weg (schräg stehen, hinter ihn laufen, warten bis er offen ist). Zwei Bausteine kombinieren ergibt neue Gegner.

## Tauben, eigene Fallen, große Bosse (2026-11-27)

- **Etwas auf einer Falle** (`hazard_types` `decor`): `sprite` (Bildstreifen), `frames`, `fps`, `height` (m), `count`, `return` (Sekunden bis es nach dem Aufscheuchen wiederkommt). Nicht auf `hidden`-Fallen.
- **Eigene Falle** (`hazard_types` mit `"owner": "player"`): `damage_mult` (× Schuss-Schaden), `every` (Sekunden je Gegner), `hold` (Fangeisen: betäubt so lange), `life`, `size`, `color`, `glow`.
- **Item oder Relikt, das Fallen legt:** `"traps": [{"kind": "player_fire", "chance": 0.25}]` – der Schuss legt die Falle, wo er endet.
- **Großer Gegner:** `frame` [Breite, Höhe] der Einzelbilder; `attack_sheets` {"spray": "breath"} = `<sprite>_breath.png` während des Angriffs; `arena` {"light": [r, g, b], "hazards": [["lava", [4, 5]]]} für den Boss-Raum.

- **Boss-Halle** (`data/boss_hall.json`): `size` (in Räumen), `wall_height`, Texturen, `gate`/`gate_open`/`altar` (Bilder), `ambient_dark`/`ambient_lit`, `wake_distance`, `pillars` [quer, längs] (Abstand der Säulen), `elements` (9 Kristalle, Bilder `holy_<element>_crystal.png`, `pillar_<element>.png`, `beam_<element>.png`, `crown_<element>.png`), `colors`, `music_altar`, `music_fight`, `silence`, `boss_drop`.
- **Musik austauschen:** in `data/audio.json` `music` z. B. `"boss_rock"` auf eine andere Datei zeigen lassen (ogg/wav/mp3).

## Behälter und Tausch (`data/containers.json`, `data/trades.json`)

- Behälter: `name`, `desc`, `icon`, `kind` (`relic`, `gear`, `weapon`, `loot`), `slots`, `stack` (nur Beute), `size` im Lager, `price` und `unlock` (Egons Tisch, `shop.json` `container_chance`).
- Tausch: Liste `trades`, je `id`, `give` {Beute-Id: Anzahl}, `get` = eins von `container`, `backpack`, `potion`, `relic` (+ `runs`), optional `unlock` (`level`, `dungeon`, `quest`).
- Neue Namen und Beschreibungen danach durch `py assets/_reference/i18n/build_po.py` (liest beide Dateien).

## Räderkluft (`data/gear_chasm.json`)

- Maße in Metern als halbe Größe `[breit, tief]`: `center` (Mitte), `dais` (Boss-Podest), `door` (Tür-Plattform), `platform` (Ring-Plattform), `gap` (Spalt zwischen Nachbarn). Die Schienen ergeben sich daraus.
- `period` = Sekunden je Runde (kleiner = schneller), `wait_at_start`, `reach`, `fall_damage` (halbe Herzen), `fall_depth`, `fall_time`.
- `textures` und `colors` je Art: `fixed`, `outer`, `inner`, `dais` (+ `abyss` für den glühenden Grund).
