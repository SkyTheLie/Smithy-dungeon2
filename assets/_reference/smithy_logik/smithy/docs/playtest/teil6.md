# Playtest Teil 6: Aurelius, besetztes Dorf, Eisquell, Eismauer

Bot: `sim_play_story.gd`, vom Autosave am Ende von Teil 5 (`saves/teil5_ende.json`, Schritt `forest_wake`, Tag 75). Log und Bilder: `assets/_reference/playtest/teil6/`.

**Ergebnis:** durchgespielt bis `part6_end`, Tag 75 bis Tag 80. Helden L44 » L49. Gold 26 162 » 29 362. Keine Skriptfehler.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Windbruch (`ice_windbreak`, Stufe 49): 20 Farm-Läufe L45 » L48 (gut 2 Tage). Hafen (46) und Mauerkrone (50) kaum. Mild. |
| 2 | Unschlüssig | B15 alte Szenen aus Teil 5 spielen nach |
| 3 | Gesagt, nicht animiert | nichts gefunden: Aurelius trinkt, Faelan, Steckbrief, Lotte führt dich weg, Übergaben bei Nina/Gustav/Lotte, Strohlager und Horn in Kahns Halle, Hafen, singende Wand, Riss mit König und Lake: alles Cutscene |
| 4 | Komisch | C20 Uhr steht nachts um 02:00, Dungeons laufen in null Minuten |
| 5 | Bugs | keine |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | Tipps „Die falsche Spur“, „Gesucht“, „Die Eismauer“ (nur der Windbruch ist Pflicht) sind klar |
| 8 | Wirtschaft | Gold ohne Ziel (siehe B8/B14) |
| 9 | Kampf | Hafen nach 1 Nacht, Windbruch nach Farmen, Lake auf der Mauerkrone (Stufe 50) im ersten Versuch |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

## B (komisch)

**B15 · Liegengebliebene Szenen aus Teil 5 spielen später (unsicher).** Schritt `wall_crown`, Log `teil6/log.txt` Zeilen 324–333. Der Bot lief auf der Suche nach Torgai durch das Heerlager (`fortress_camp`) und den Torhof (`fortress_yard`). Dort liefen beim Betreten zwei Neben-Szenen aus Teil 5 (`side.json`):
- `camp_narrator` » `camp_arrival` (Flag `reached_camp_council`, `done_flag camp_intro_seen`): „Auf der kargen Ebene jenseits des Sumpfes brennen hunderte Lagerfeuer …“
- `leon_captain` » `keep_won` (Flag `reached_throne_hall`, `done_flag keep_won_seen`): „Der Weg zum Thronsaal ist frei.“ – Lake: „Endlich! Mir nach, Schmied – wir holen den König zurück!“ und „Mit leuchtender Klinge stürmt Lake die Stufen hinauf.“

Zu der Zeit ist Lake längst der dunkle Ritter. Grund: Der Bot hatte beide Szenen in Teil 5 nicht gesehen (er reiste direkt zum Kriegsrat bzw. Thronsaal). Ein Spieler, der nach dem Sieg im Bergfried per Teleporter oder Kutsche abreist, kann `keep_won` genauso verpassen. Die Neben-Szenen haben nur eine Start-Bedingung, kein Ende. Vorschlag: `unless_flag` (z. B. `lich_slain` für `keep_won`, `reached_throne_hall` für `camp_arrival`), oder im nächsten Schritt `done_flag` setzen (Regel 47).

## C (Kleinkram)

**C20 · Nach 23 Uhr bleibt die Uhr bei 02:00 stehen, Dungeons laufen dann in null Minuten.** `kahn_refuses` setzt die Zeit auf 23 Uhr (`set_time:23`, Horn). Danach liefen drei Dungeon-Läufe „von Tag 76 02:00 bis Tag 76 02:00“ (einer gewonnen, einer verloren). Wahrscheinlich gewollt (Tagesende 02:00, der Tag endet erst mit dem Schlafen), aber dann kann man nachts unbegrenzt Dungeons laufen lassen, solange die Ausdauer reicht, ohne dass Zeit vergeht. Nur ein Hinweis.

## Was gut war

- Die falsche Spur im besetzten Dorf (Nina zählt die Barren zweimal, Gustav wiegt den Sack, Lotte prüft dein Zeichen) ist ein schöner kleiner Heist.
- Kahns Kehrtwende nach dem Hafen („Wer gegen die Strömung schwimmt, ertrinkt.“) und Torgais Wiegenlied als Rätsel-Hinweis passen gut zusammen.
- Der Steckbrief, „nicht sehr schmeichelhaft gezeichnet“, und „Belohnung: 10.000 Gold“.

## Nicht getestet

- Rätsel auf der Mauerkrone (Säulen nach dem Wiegenlied, drei Silberspiegel): der Bot kam nicht weiter und sprang zu `singing_wall`. Ab jetzt löst er sie über `IceWall` (nicht von Hand).
- Trank für Aurelius (Mondlilie, Hanf, Kamille, Phiole) und Harpunenspitze: „gemacht“.
- E bei Torgais Schwert-Übergabe (`SubarBlade`): der Bot erreichte den E-Bereich einmal nicht, das Gespräch lief über die Figur daneben weiter. Unsicher.
- Erzähler nach dem Kampf (`wall_aftermath`, `ice_crown_narrator`): der Bot fand ihn nicht, der Schritt ging trotzdem weiter (der Erzähler kommt wohl von selbst).
