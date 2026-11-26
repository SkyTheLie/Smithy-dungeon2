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

- 2026-11-26 · feature/schwertschwung · Kriegsaxt machte aus dem Feuerball des Magiers einen Schwung (Modus-Vorrang, Waffe hing am Charakter) · neu: Hauptwaffen sind Items (`start_items`); neue Waffen kombinieren über Synergien statt still zu ersetzen
- 2026-11-26 · feature/schwertschwung · Boss-Test „Sonderraum 100 %“ hing davon ab, ob der Spieler vorher getroffen wurde · 13 (Test setzt alle Bedingungen selbst)
- 2026-11-26 · feature/testraum · Boss-Raum stand immer auf der Karte (Sonderfall in `known_cells`), obwohl der Nebel ihn verbergen sollte · neu: Nebel-Regeln nur an einer Stelle (`Dungeon.known_cells`), keine Ausnahmen je Raumtyp ohne Absprache
