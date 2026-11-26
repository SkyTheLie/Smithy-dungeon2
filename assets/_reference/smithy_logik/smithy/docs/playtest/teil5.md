# Playtest Teil 5: Rettung des Königs, Sumpf, Finsterburg

Bot: `sim_play_story.gd`, vom Autosave aus Teil 4 (`saves/teil4_kaefig2.json`, mit `load:part4_end` vorgesprungen; Helden und Ausrüstung echt). Log und Bilder: `assets/_reference/playtest/teil5/`.

**Ergebnis:** durchgespielt bis `part5_end`, Tag 62 bis Tag 75. Helden Ilka, Leif, Zora L37 » L44. Gold 1 314 » 26 162. Im Log nur der bekannte A5 (2× `is_shown` bei Lotte).

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | A11 Bergfried: 72 Farm-Läufe, L37 » L44, Tag 63 bis 73 |
| 2 | Unschlüssig | nichts gefunden |
| 3 | Gesagt, nicht animiert | nichts gefunden: Duell Lake/Lich, Hinrichtung, Ketten, König nimmt den Kristall, Lake wird dunkel, Aurelius' Schild, Flucht: alles Cutscene |
| 4 | Komisch | nichts |
| 5 | Bugs | nur A5 aus Teil 1 |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | Tipps zu Sumpf, Schleichen, Bergfried, Aurelius tragen: klar |
| 8 | Wirtschaft | B14 Gold ohne Ziel (26 000) |
| 9 | Kampf | Bergfried (`dark_keep`, Stufe 45) im ersten Versuch nach dem Farmen |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

## A (wichtig)

**A11 · Langer Level-Sprung vor dem Bergfried (bitte mit Sumpf-Dungeons nachrechnen).** Schritt `gate_battle`, Dungeon `dark_keep` Stufe 45. Die Gruppe kam mit L37 aus Teil 4 (Gold-Set R1). Bis Schnitt L44 farmte der Bot 72 Läufe, gut 10 Spieltage (Tag 63 bis 73). Einschränkung: Der Bot hat die drei Sumpf-Dungeons (Nebelmoor 40, Knochen 42, Hydra 44), die für den Trank der tausend Augen nötig sind, nicht gespielt, sondern den Trank „gemacht“ (`witch_potion`). Ein Spieler levelt dort. Trotzdem: Von Stufe 38 (Frostmähne) auf 45 sind es 7 Level, die Teil 5 im Story-Ablauf nur über den Sumpf hergibt. Vorschlag: Sumpf-Dungeons und Bergfried mit `sim_progress.gd` nachrechnen; ob der Sumpf allein reicht.

## B (komisch)

**B14 · Gold wächst ohne Ziel weiter.** 26 162 Gold an Tag 75, obwohl der Bot für die drei Kämpfer schon Gold- und Platin-Sets bezahlt hat. Einnahmen fast nur Kundenaufträge und verkaufte Beute beim Farmen. Siehe B8 in Teil 2; ab Teil 4 wird es deutlicher.

## Was gut war

- Der Verrat im Thronsaal ist die stärkste Szene bisher: Lake richtet den Lich hin, die Ketten waren nie zu, der König nimmt den Kristall „mit fast väterlicher Ruhe“, Lakes Gold wird zu Eisen.
- Der Kriegsrat mit Wahl („Ich bürge für Lake.“) und das Gespräch am Lagerfeuer bauen Lake vorher gut auf.
- Grislas Trank-Vision, das ganze Heer am Sumpfrand: gut erzählt.

## Nicht getestet

- Schleichen (`sneak_in`, `sneak_out`) und Aurelius tragen (`carry_mage`): der Bot reist direkt zum Hebel und zum Ausgang, die Wachen-Kegel hat er nie gesehen.
- Sumpf-Dungeons und der echte Trank (Irrlichtglut, Herz der Moormutter, Hydra-Teil): übersprungen, siehe A11.
- Ask Allies: Goldzahn, Elarion und Kahn befragt, Texte im Log ohne Auffälligkeiten.
