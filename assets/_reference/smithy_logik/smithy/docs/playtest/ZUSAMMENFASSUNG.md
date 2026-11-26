# Playtest: Zusammenfassung über das ganze Spiel

Stand 2026-11-16. Story-Bot von Kapitel 1 bis `story_end` (Minispiele übersprungen, Material in Gold bezahlt, R1-Ausrüstung im Metall der Story-Stufe, Punkte nach Simulator-Bauplan). Einzelberichte: `docs/PLAYTEST_KAPITEL1.md`, `teil1_kap2-9.md`, `teil2.md` … `teil8.md`, dazu `karten_ausweg.md`. Am Spiel wurde nichts geändert.

## Spielzeit (Bot, ein durchgehender Spielstand ab Teil 2)

| Teil | Tage | Helden am Ende | Gold am Ende |
|---|---|---|---|
| 1 (Kap. 2 bis Überfall) | bis Tag 15 | L6 | 0 (Überfall) |
| 2 Leonheim, Goblins, Drache | Tag 15–53 | L35 | 11 227 |
| 3 Sylvaris | Tag 53–56 | L35 | 6 891 |
| 4 Eisquell, Wüste | Tag 57–62 | L37 | 1 314 (Bot rüstete 7 Helden um) |
| 5 Sumpf, Finsterburg | Tag 62–75 | L44 | 26 162 |
| 6 Eismauer | Tag 75–80 | L49 | 29 362 |
| 7 Finsterstadt | Tag 81 | L48 | 22 032 |
| 8 Altar, Ende | Tag 82–97 | L58 | 40 542 |

Rund 97 Spieltage. Davon etwa 40 Tage reines Farmen vor vier Level-Wänden (A7, A11, A12 und Lavagolem/Drache).

## A (wichtig), über alle Teile

| Nr. | Teil | Kurz |
|---|---|---|
| A5 | 1 | Skriptfehler `is_shown` bei Begleitern (Lotte ohne Porträt), noch in jedem Teil im Log |
| A6 | 1 | Bruno stapft nicht sichtbar auf den Lich zu |
| A1 | 1 | Angelegte Spitzhacke lässt sich bei Gustav nicht abgeben |
| A2–A4 | 1 | Rattennest/Minen-Ratten/Gold-Falle (Gold-Teil durch Bot-Fehler zu düster, siehe Nachtrag in `teil2.md`) |
| A7 | 2 | Level-Sprung zur Gosse: L6 » L14, 16 Tage Farmen, zeitweise kein passender Dungeon |
| A8 | 2 | „Du rennst, die Burg stürzt in die Lava“ nur Text |
| A9 | 2 | Skillpunkte: wer die ersten Skills hochzieht, gewinnt Lavagolem/Drache fast nie, kein Hinweis |
| A10 | 3 | Schmiedeturnier Runde 3/4 nur mit Seltenheit 2 zu gewinnen (von Hand prüfen) |
| A11 | 5 | Bergfried: L37 » L44, 10 Tage Farmen (Sumpf-Dungeons nicht gespielt) |
| A12 | 8 | Torwächter vor dem Altar: L48 » L54, 9 Tage Farmen |
| Nacht | – | Pyramide von Sahrim: nachts kein Ausweg (`karten_ausweg.md`) |

## Muster (B), die mehrfach vorkamen

- **Briefe kommen zu spät** (B7, B11): Lotte bringt den Brief beim nächsten Kartenwechsel, auch wenn das Ereignis schon passiert ist.
- **Verpasste Neben-Szenen spielen später** (B15): `side.json`-Szenen haben nur eine Start-Bedingung; wer sie überspringt, sieht sie Teile später (der dunkle Lake ruft „wir holen den König zurück“).
- **Gold ohne Ziel** (B8, B14): ab Leonheim wächst das Gold auf 10 000 bis 40 000; Kunden zahlen weiter für Kupferteile (C21).
- **Was ein Held können muss, sagt keiner**: Skills (A9), Heldenturnier mit Heilerin (B13), Rezept-Strafe im Schmiedeturnier (B12).
- **Himmelsrichtungen**: Sylvaris im Westen und im Osten (B9).

## Was gut war

- Keine Sackgasse in der Story, alle 8 Teile laufen ohne neue Skriptfehler durch.
- Fast jede behauptete Handlung ist als Cutscene da (Regel 50). Ausnahmen: A6, A8.
- Beide Ausgänge von Sylvaris, Kahns Rat mit eigenen Zeilen je Ausgang.
- Starke Szenen: Brunos Tod, Goblin-Audienz, Verrat im Thronsaal, Kerkerschmiede, Lakes Erlösung, das Ende mit Lotte am Amboss.

## Grenzen des Bots (nicht getestet)

Minispiele (Amboss, Gießen, Werkbank, Turnier), Schleichen, alle Rätsel (über die System-Klassen gelöst), echtes Abbauen und Laufwege, Gewächshaus und Verzaubern, Neben-Aufgaben, zwei Dungeons gleichzeitig. Ab Teil 3 wurde einzeln vom jeweiligen Autosave weitergespielt (Helden echt, aber die Spielstände hatten Bot-Lücken, z. B. übersprungene Neben-Szenen).
