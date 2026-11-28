# Fehlerklassen und Regeln dagegen

Aus Smithy übernommen, was hier gilt (Smithy: `docs/FEHLERKLASSEN.md`). Kurz halten. Nach jeder Fehlerbehebung unten unter „Ursachen“ eine Zeile eintragen.

## Sprache

1. Jeder sichtbare Text läuft durch `Language.translate` (oder Godots Auto-Übersetzung bei Labels/Buttons); bei `%`-Texten erst übersetzen, dann einsetzen.
2. Nie übersetzten Text vergleichen; Zustand in Variablen halten.
3. Labels, denen der Code schon übersetzten Text gibt, bekommen `auto_translate_mode = 2` (aus), sonst wird doppelt übersetzt.
4. Nach neuen Texten `py assets/_reference/i18n/build_po.py` – erst bei „0 problems“ ist die Aufgabe fertig.

## Daten

5. Jeder Wert hat genau eine Quelle (`data/*.json`). Kein zweiter Standardwert im Code, keine zweite Liste.
6. Was eine Funktion verbraucht (Münzen, Schlüssel, Bomben), prüft sie vorher; Mengen ≤ 0 und negative Preise abweisen (`RunState`).
7. Neue Item-Werte (`stats`, `flags`, `mode`) in `test_content.gd` bei den bekannten Werten eintragen, sonst schlägt der Test an.

## Spiel und Oberfläche

8. Spielregeln (Leben, Münzen, Items, Synergien) stehen in `RunState`/`Dungeon`, nie im HUD. Das HUD zeigt nur an.
9. In `_process`/`_draw` nichts laden und keine Listen neu bauen.
10. Timer pausieren mit dem Spiel: `create_timer(t, false)`; nach jedem `await` kann die Szene weg sein.
11. Gegner-Bilder schauen nach links; nach rechts laufend werden sie gespiegelt (`Enemy._animate`).

## Tests

12. Tests nur über `bash assets/_reference/run_tests.sh` (eigenes `user://` je Test). Neue Tests erben von `_lib/base_test.gd`.
13. Bei Zufall feste Seeds; auf Bedingungen warten (`wait_until`), nicht auf feste Sekunden.
14. Wer Verhalten ändert, passt die Tests im selben Commit an.

## Ursachen (neueste oben)

Format: `Datum · Branch · Ursache · Regel-Nummer (oder „neu“)`

- 2026-11-28 · feature/kisten · `Content.pick_weighted` mit Zahlen als Ids (`rings` [[1, 3], [2, 1]]): `String(1)` gibt es nicht, Absturz beim Bauen der Ebene · neu: `pick_weighted` nur mit Text-Ids; Zahlen-Tabellen vorher mit `str()` umwandeln

- 2026-11-28 · feature/behaelter-tausch · `test_shop` schlug selten fehl: `end_run` mit ungesetztem Zufall, Egon nahm nachts manchmal die ganze Dose (1 %), danach fehlte Gold zum Kaufen · 13 (Tests geben `end_run` immer einen Zufall mit festem Seed)
- 2026-11-27 · fix/lich-bild · Lich-Bild mit 64 px und 4 Reihen (eine je Richtung), Code nahm 48 px und eine Reihe an: ein gestauchter Streifen, das Bild lief „von unten nach oben“ · neu: Gegner-Bilder sind eine Reihe in `frame`-Größe (Test `_check_sheet`); `Enemy._set_sheet` setzt `vframes`, damit mehrreihige Bilder nur die erste Reihe zeigen
- 2026-11-27 · feature/admin-laden · `angles = [..] if a else [..]` gab ein ungetyptes Array; Zuweisung an `Array[float]` brach ab (zeigte sich erst, als Münzen den Zufall verschoben) · neu: getypte Arrays nicht über `x if c else y` füllen, sondern mit `if`/`else`
- 2026-11-27 · feature/laden-raster · Bilder, die erst in `_draw` geladen wurden, erschienen als weiße Flächen (nur das erste klappte) · 9 (Bilder vorher laden, z. B. in `show_pieces`/`refresh`)

- 2026-11-27 · feature/leveln-skillseiten · Karte gab aufgesammelte (freigegebene) Pickups aus `room.loot` an eine Funktion mit Parameter `Node3D` → Script-Fehler · neu: Listen, die freigegebene Nodes enthalten können, nur über ungetypte Parameter (`Variant`) weiterreichen und zuerst `is_instance_valid` prüfen
- 2026-11-27 · feature/3d-ton · `Array.filter()` gibt ein untypisiertes Array zurück; die Zuweisung an `Array[AudioStreamPlayer3D]` brach ab, und ein typisierter Lambda-Parameter bekam schon freigegebene Objekte · neu: getypte Arrays mit einer Schleife neu bauen (nicht `filter`), bei evtl. freigegebenen Objekten `Variant` + `is_instance_valid` vor dem Cast
- 2026-11-27 · feature/3d-ton · Merge trotz roter Tests (Prüfung hing an einem `tail` statt am Rückgabewert) · 12 (Merge nur, wenn `run_tests.sh` mit 0 endet)
- 2026-11-27 · feature/wiese-traenke · Nach dem Teleport in die Boss-Halle rechnete `_physics_process` mit der alten Position weiter und setzte den Raum zurück · neu: wer den Spieler in `_physics_process` versetzt, beendet den Durchlauf danach (`return`)
- 2026-11-27 · feature/wiese-traenke · Ansturm-Gegner hielt sofort an: `get_last_slide_collision()` meldet auch den Boden · neu: „gegen Wand gelaufen“ nur über Kollisionen mit waagrechter Normale prüfen (`EnemyMoves.after_move`)
- 2026-11-27 · feature/wiese-traenke · Test nutzte einen Spiel-Klassennamen (`is EnemyBeam`) und kompilierte nicht (Autoloads beim Test-Kompilieren unbekannt) · neu: in Tests Klassen nur über `script("res://…")` vergleichen

- 2026-11-27 · feature/balance · Neue Klasse `Hazard` (class_name) war den Tests unbekannt, weil Godots Klassen-Liste noch alt war · neu: nach einer neuen `class_name` einmal `Godot --headless --path . --import` laufen lassen (oder den Editor öffnen), dann erst testen
- 2026-11-27 · feature/balance · Anführungszeichen in einem `_info`-Text machten eine JSON-Datei kaputt · neu: in `_info`-Texten keine `"`, nach jeder JSON-Änderung laden (Test oder `py -c "import json…"`)

- 2026-11-26 · feature/beute-inventar · Nach dem Tod sammelte der Spieler in der Sekunde bis zum End-Bildschirm noch Beute auf, die dann in der schon geleerten Tasche landete · neu: Pickups prüfen `run.is_dead()`; was nach dem Run-Ende passiert, darf keine Regeln mehr ändern
- 2026-11-26 · feature/beute-inventar · Hilfsfunktion `_set` in `MetaState` überschrieb Godots eingebautes `Object._set` · neu: keine Namen von Godot-Methoden (`_set`, `_get`, `_init` …) für eigene Hilfsfunktionen

- 2026-11-26 · feature/schwertschwung · Kriegsaxt machte aus dem Feuerball des Magiers einen Schwung (Modus-Vorrang, Waffe hing am Charakter) · neu: Hauptwaffen sind Items (`start_items`); neue Waffen kombinieren über Synergien statt still zu ersetzen
- 2026-11-26 · feature/schwertschwung · Boss-Test „Sonderraum 100 %“ hing davon ab, ob der Spieler vorher getroffen wurde · 13 (Test setzt alle Bedingungen selbst)
- 2026-11-26 · feature/testraum · Boss-Raum stand immer auf der Karte (Sonderfall in `known_cells`), obwohl der Nebel ihn verbergen sollte · neu: Nebel-Regeln nur an einer Stelle (`Dungeon.known_cells`), keine Ausnahmen je Raumtyp ohne Absprache
