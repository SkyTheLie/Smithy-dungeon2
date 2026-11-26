# Karten ohne Ausweg (Nacht-Sperre)

Wunsch vom Nutzer: Abends kam 1–2-mal die Meldung „Es ist Nacht, das Dorf verlässt man jetzt besser nicht.“ und man kam nicht mehr aus der Karte („Ich stecke fest“ half). Geprüft am 2026-11-16, ohne Änderungen am Spiel.

Werkzeug: `assets/_reference/playtest/night_exits.py` (liest alle Türen aller Karten, `WILD_SCENES`, `WILD_STEPS_HOME` aus `game_state.gd` und rechnet nach, ob man nachts von jeder Karte zu einem Bett, Gasthaus, einer Kutsche oder einem Teleporter kommt). Start: `py assets/_reference/playtest/night_exits.py .`

## Wie die Sperre funktioniert

- Nacht ist ab 21 Uhr (`DayCycle.PHASE_START_HOURS`).
- `GameState.is_blocked_at_night(ziel, hier)` (`game_state.gd:645`) sperrt nachts jede Tür in eine „wilde“ Karte (`WILD_SCENES`: Dorftor, Südweg, Wald, Mine, Lavaberg, Goblin-Karten, Wüste, Wüstentor).
- Ausnahme nur, wenn man **aus einer wilden Karte** kommt und das Ziel näher am Dorf liegt (`WILD_STEPS_HOME`).
- Kommt man aus einer **zahmen** Karte (nicht in der Liste), ist jede Tür in eine wilde Karte nachts zu, auch wenn sie der Heimweg ist.
- In wilden Karten bleibt die Uhr um 21 Uhr stehen, in zahmen läuft sie weiter. Im Vulkan-Ordner steht sie um 18 Uhr (dort gibt es keine Nacht).
- Kutschen prüfen die Nacht nicht, der Teleporter sperrt nur wilde Ziele. Das Wüsten-Labyrinth (`desert.walk`) prüft sie auch nicht.

## Ergebnis

### A · Pyramide von Sahrim: nachts eingesperrt

Karten `desert/sahrim_pyramid.tscn`, `desert/pyramid_hall.tscn`, `desert/underworld.tscn`. Alle drei sind zahm (die Uhr läuft weiter bis in die Nacht). Der einzige Weg hinaus ist die Tür `ToGate` in `sahrim_pyramid.tscn` zum Wüstentor `sahrim_gate.tscn`, und das ist wild. Ab 21 Uhr: Meldung „Es ist Nacht …“, kein Bett, keine Kutsche, kein Teleporter. Man steckt bis zum „Ich stecke fest“-Knopf fest. Die Pyramide ist vom Wüstentor aus ohne Story-Flag erreichbar; die Unterwelt ist ab `story_complete` offen (Endspiel, lange Dungeon-Läufe, da wird es leicht Abend).

Vorschlag (eins davon): die drei Karten in `WILD_SCENES` mit Wert 5/6/7 aufnehmen (dann bleibt die Uhr stehen und der Heimweg zum Wüstentor ist offen), oder die Sperre nur für Wege **weg** vom Dorf anwenden, auch aus zahmen Karten.

### B · Allgemeine Lücke: zahme Karte mit wildem Heimweg

Die Regel „aus einer zahmen Karte ist jede wilde Tür zu“ trifft auch Karten mit Kutsche, wo es nur nicht so schlimm ist:
- **Sumpf** (`swamp/swamp.tscn`, zahm): Der Fußweg nach Hause geht über das Dorftor (wild) und ist nachts zu. Es gibt eine Kutsche, also kein Festsitzen, aber wer zu Fuß kam, versteht nicht, warum der Heimweg zu ist.
- **Leonheim** (`capital/capital_street.tscn`): Der Weg zum Dorftor ist nachts zu, nur die Kutsche geht.
- **Sahrim** (`desert/desert_town.tscn`): Tor zur Wüste nachts zu; Gasthaus und Kutsche da.

Gerade das passt zur Meldung „das Dorf verlässt man jetzt besser nicht“, obwohl man nach Hause will. Vorschlag: Meldung je nach Richtung („Nimm nachts die Kutsche“), oder Heimweg auch aus zahmen Karten offen lassen.

### C · Finsterburg-Kerker (unsicher)

`finster/castle_walk.tscn`, `castle_cells.tscn`, `kerker_forge.tscn` haben keinen Ausgang per Tür zu einem sicheren Ort; man verlässt sie über die Story (Schleichen, Halvard befreien). Kein Nacht-Problem (zahm, keine wilden Nachbarn), aber falls man dort nach der Story nochmal hineinkommt, gibt es keinen Rückweg. Bitte von Hand prüfen.

### Kein Problem

- Sturmtempel (`storm_temple*`): Ausgang über das Wüsten-Labyrinth, nicht nachts gesperrt.
- Wald, Mine, Goblin-Karten: Die Werte in `WILD_STEPS_HOME` passen, von jeder wilden Karte führt nachts eine Tür näher nach Hause.

## Nicht geprüft

- Türen mit `required_flag`/`blocked_flag`, die zu einem bestimmten Story-Stand den Heimweg zumachen (die Rechnung nimmt alle Türen als offen an).
- Ob der Teleporter am jeweiligen Ort schon gebaut ist (die Rechnung nimmt ihn als da).
- Welche Karte es beim Nutzer genau war. Wenn es nicht die Pyramide war, passt am ehesten B (zahme Karte, Heimweg zu Fuß über eine wilde Karte).
