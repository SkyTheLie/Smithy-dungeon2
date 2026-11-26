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
- `give`: gibt es beim Aufheben dazu: `{"coins": 5, "bombs": 3, "keys": 3}`.
- `mode`: `beam` (Feuerstrahl) oder `bomb` (Bomben werfen).
- `heal_full: true` heilt beim Aufheben ganz.
- Item-Raum: **jedes** Item kann kommen, außer `"secret": true` (für spätere Geheimräume) und noch gesperrte.
- `pools`: zusätzlich `shop` (Laden) und/oder `boss` (Boss-Belohnung: nur einfache Werte- und Herz-Items, keine `flags`/`mode`; das prüft `test_run_state`).
- `stats` kennt auch `blue_hearts` (blaue Herzen: kommen oben drauf, Treffer nehmen sie zuerst, nicht heilbar). Negative `hearts` nehmen Herzen weg.
- `unlock`: das Item ist erst nach einer Freischaltung im Spiel: `{"type": "boss", "id": "rat_king"}`, `{"type": "wins", "count": 1}`, `{"type": "kills", "count": 200}`, `{"type": "discovered", "count": 25}`. Der Text im Lexikon entsteht daraus von selbst.
- Es sind genau 203 Items: 200 plus die drei Start-Waffen der Helden (`test_content` prüft das).
- `chance`: Zufallseffekte, z. B. `{"freeze": 0.15}` (15 % pro Schuss, Glück erhöht das).
- `spawn`: Pickups, die beim Aufheben erscheinen (`coin`, `heart`, `bomb`, `key`).
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
- Neue Texte (`name`, `desc`) danach übersetzen (`build_po.py` findet sie selbst).

## Spielstand-Regeln (`data/meta.json`)

- `bag`: `slots` (normale Plätze), `safe_slots` (bleiben beim Tod), `stack` (höchste Anzahl pro Platz).
- `money_box`: `limit` (so viel ist in der Dose sicher), `steal_all_chance`, `steal_part_chance`, `steal_part_share` [min, max].

## Dungeon auf Egons Brett (`data/dungeons.json`)

- `"id": {"name", "region", "desc", "level"}`: `name`/`desc` = Text auf dem Brett, `region` = Reiter (z. B. „Umgebung“), `level` = empfohlene Stufe. Reihenfolge = Reihenfolge auf dem Brett.
- Ebenen und Gebiete kommen aus `floors.json` (eigene Ebenen je Dungeon: Phase 4).
- Neue Texte danach übersetzen (`build_po.py` findet `name`, `region`, `desc` selbst).

## Ausrüstung (`data/gear.json`)

- `slots`: Plätze an der Figur, `"id": {"name", "hint", "at": [x, y]}` (`hint` = Bild `assets/sprites/ui/slot_hints/equip_<hint>.png`, `at` = Mitte in der Helden-Ansicht).
- `gear`: `"id": {"name", "desc", "slot", "icon", "price", "class"?, "stats"}`. `stats` wie in `player.json` (wirken ab Phase 3), mal `rarity_stats` je Seltenheit. `class` = nur für diese Klasse (Tooltip „Nur für“).
- Neue Ausrüstung taucht im Laden erst auf, wenn sie in `shop.json` `pool` steht. Der Test prüft Bild und Platz.

## Egons Laden (`data/shop.json`)

- `table_slots`, `goods_count` [min, max], `roll_prices` (1., 2., 3. … Hebel-Zug am Tag), `pool` [[id, Gewicht]], `rarity_weights` [[Seltenheit, Gewicht]], `rarity_price` (Preis-Faktor R1..R8).
- `tutorial.goods` [{id, rarity, cell}] = Egons erster Tisch, `tutorial.gifts` = was davon geschenkt und angelegt wird.

## Texte der Figuren (`data/story.json`)

- Jeder Schlüssel ist eine Liste von Sprechblasen (höchstens zwei Sätze), `barks` sind einzelne Sätze. Egons Texte werden aus `docs/figuren/EGON_EHRLICH.md` gebaut.
- `build_po.py` findet alle Sätze selbst; danach übersetzen.

## Münzwert (`data/player.json`)

- `coin_pickup`: [min, max] Münzen je aufgehobener Münze (bisher [8, 12]). Preise im Run-Shop (`floors.json` `shop`) passen dazu.
