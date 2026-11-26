# Playtest Teil 4: Eisquell, Gezeitenarena, Wüste und Sturmtempel

Bot: `sim_play_story.gd`. Bis `desert_cage` aus dem Lauf Teil 3+4 (`teil4/lauf_a/`, vom Autosave aus Teil 2); Heldenturnier bis Ende neu ab dem Autosave in der Zelle (`saves/teil4_kaefig.json`, mit `load:hero_tournament` zurückgesprungen, Helden und Gold bleiben echt): `teil4/lauf_b/`.

**Ergebnis:** durchgespielt bis `part4_end`, Tag 57 bis Tag 62. Helden: Ilka (Priesterin), Leif (Paladin), Zora (Magierin) je L37. Keine Skriptfehler im Log.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Frostmähne (`water_deep_grotto`, Stufe 38): 9 Farm-Läufe L35 » L37 (gut 1 Tag), 1 Niederlage, dann Sieg an Tag 60. Mild. |
| 2 | Unschlüssig | nichts: Kahns Rat hat für „Sylvaris gehalten“ und „Wind verloren“ je eigene Zeilen (`if_flag elf_defense_won`) |
| 3 | Gesagt, nicht animiert | nichts gefunden. Festnahme in Sahrim: Text zuerst, Bild danach (`on_end: cutscene:arrest_lock`), passt noch |
| 4 | Komisch | C19 Turnier-Rundennamen (nur Bot-Log) |
| 5 | Bugs | keine |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | B13 Heldenturnier: welcher Held? |
| 8 | Wirtschaft | Gold reicht weiter dicke (Lauf a: 7 150 » 11 864 an einem Farm-Tag). Der Bot gab 8 557 » 1 314 für Silber- und Gold-Sets aus (siehe Bot-Hinweis) |
| 9 | Kampf | Heldenturnier: Paladin L37 (Bronze-Set) gewann im 5. Versuch, dreimal im Finale, Gegner L33–39 |
| 10 | Übersetzung | deutsch, Echsen-Lispeln („Sssahrim“) liest sich gut |
| 11 | Platzhalter | keine gesehen |

## B (komisch)

**B13 · Heldenturnier: die Heilerin hat keine Chance, das sagt niemand.** Schritt `hero_tournament`. Erster Bot-Lauf schickte den Helden mit dem höchsten Level, die Priesterin Ilka L37: 30 Versuche, nie über das Viertelfinale (meist Achtelfinale verloren). Mit dem Paladin Leif: dreimal im Finale, einmal gewonnen; die Magierin Zora flog zweimal im Viertelfinale raus. Der Tipp „Turnier in der Gezeitenarena“ sagt nur „einen einzelnen Helden anmelden“. Ein Spieler mit Heiler-Hauptheld (oder nur Heilern) läuft dagegen. Vorschlag: Der Ausrufer sagt „Allein im Sand zählt, wer zuschlägt, nicht wer heilt“, oder der Tipp nennt das.

## C (Kleinkram)

**C19 · Nur Bot-Log:** Die Rundennamen im Log hinken eine Runde hinterher (der Bot liest den Namen nach dem Sieg). Kein Spielfehler.

## Was gut war

- Kahn und Torgai nach dem Turnier („hundert Kämpfe im Schlamm verloren, bevor ich den ersten gewann“) sind ein schöner ruhiger Moment.
- Ulrich in Sahrim und die 1200 Gold, die Oma Hilde ihm damals berechnet hat („Ich habe nur 120 bekommen.“): toller Rückgriff auf Kapitel 5.
- Leerer Thron und der Brief des Lichs: Der Schluss von Teil 4 sitzt, auch der Spieler verliert endlich den Witz („Zum ersten Mal fällt dir kein einziger Spruch ein“).
- Tempel: Siegel, Säulen und Blitzstab sind klar über Wandbilder erklärt (aus den Texten von `storm_temple.gd`).

## Nicht getestet

- Tempelrätsel von Hand (Siegel, Säulen, Blitzstab): der Bot löst sie über `StormTemple` in der richtigen Reihenfolge, Siegel und Blitzstab „gemacht“ ohne Materialkosten (Story-Teile).
- Wüstenkarte, Sturmpfade und Kompass: der Bot reist direkt.
- E bei der Wache in der Zelle (`desert_arrest`, `ArrestGuard`): der Bot kam nicht in den E-Bereich (Spieler y 318, Wache y 331, wohl hinter Gittern). Das Gespräch lief trotzdem weiter. Unsicher, bitte von Hand prüfen.
- `to_desert` „Aurelius fragen“ (Kompass-Dungeons nach einer Niederlage in der Wüste): nicht ausgelöst.

## Bot-Hinweis

- Ab Teil 4 rüstet der Bot nur noch die drei stärksten Helden neu aus. In Lauf b bekamen noch alle sieben Helden Silber- und Gold-Sets (rund 7 000 Gold), daher der Goldabfall.
- Das Heldenturnier lief, bevor der Bot auf Silber umrüstete: Leif kämpfte in Bronze R1.
