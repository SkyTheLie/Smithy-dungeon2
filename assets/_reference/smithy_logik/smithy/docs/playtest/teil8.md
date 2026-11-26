# Playtest Teil 8: Großer Rat, Altar der Neun, Ende

Bot: wie Teil 7 (`teil7-8/log.txt`).

**Ergebnis:** durchgespielt bis `story_end`, „Danke fürs Spielen“. Tag 82 bis Tag 97. Helden Ilka, Leif, Zora L48 » L58. Gold 22 571 » 40 542. Keine Skriptfehler.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | A12 Torwächter vor dem Altar: 62 Farm-Läufe, L48 » L54, 9 Tage. Danach je Heerführer 5–9 Läufe (je ein Level) |
| 2 | Unschlüssig | nichts gefunden |
| 3 | Gesagt, nicht animiert | nichts gefunden: Kristalle steigen und fallen, Altar erwacht, Heerführer, Lake erlöst, Schatten fährt in den König, Steine setzen, König in den Spalt, Glocke, Jubel, Lotte am Amboss: alles Cutscene |
| 4 | Komisch | C21 Kunden wollen am Ende Kupferkeulen |
| 5 | Bugs | keine |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | Tipp „Der Schmied des Bündnisses“ nennt alle Stücke mit Metall und Mindest-Seltenheit; „Die wahre Fassung“ sagt genau, was zu tun ist |
| 8 | Wirtschaft | 40 000 Gold am Ende, nichts mehr zu kaufen (siehe B8/B14) |
| 9 | Kampf | Heerführer West/Süd/Ost und Lake (Stufe 56–59): nach je einem Level Farmen meist im ersten Versuch, West einmal verloren |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

## A (wichtig)

**A12 · Neun Tage Farmen vor dem Altar.** Schritt `altar_siege`, Dungeon `altar_gate` (Torwächter, Stufe 55). Die Gruppe kam mit L48 aus Teil 6/7 (Teil 7 hat keinen Pflicht-Kampf). Der Bot farmte 62 Läufe (Windbruch, Finster-Dungeons) von Tag 82 bis Tag 91, bis Schnitt L54. Wie bei A7 und A11: Zwischen dem letzten Pflicht-Dungeon (Mauerkrone 50) und dem Altar (55) liegen 5–6 Level ohne Story-Kampf. Die Finster-Dungeons (51–54, `sim_progress.gd`) sind dafür da, sie sind aber freiwillig und die Story sagt nichts dazu. Vorschlag: Ein Hinweis von Aurelius oder Halvard im großen Rat („Schick deine Helden vorher in die Finster-Dungeons, der Altar ist kein Spaziergang“), oder `sim_progress.gd` mit diesem Pfad nachrechnen.

## C (Kleinkram)

**C21 · Kunden wollen am Ende Kupfer.** Tag 82: Greta will eine Kupferkeule (+58 Gold), Lotte eine Kupferaxt (+189). Mit 40 000 Gold auf dem Konto und Palladium-Rezepten wirkt das klein. Bitte prüfen, ob die Kunden mit dem Fortschritt mitwachsen sollen.

## Was gut war

- Das Ende ist rund: Halvards Hände auf deinen beim neunten Stein, nur der weiße Handschuh bleibt, „Dein Name kommt darin vor, leider falsch ausgesprochen“, Lotte mit dem zweitbesten Hammer auf der umgedrehten Kiste.
- Lakes Erlösung (Siegelglut, Schatten mit Klauen, Rüstung reißt, Gold darunter) zahlt den Aufbau seit Teil 2 aus.
- Der große Rat mit der schwebenden Brücke und Ssarok, der nicht nach unten sieht.

## Nicht getestet

- Waffen für das Bündnis (R4 aus Kupfer bis Gold): „gemacht“, die Minispiele für Seltenheit 4 nicht.
- Sternenstahl und „Die wahre Fassung“: „gemacht“.
- Altar-Kämpfe einzeln von Hand (Heerführer kommen herein, E zwischen Altar und Heerführer); der Bot reist zur Figur.
- Nachspiel nach dem Ende (frei weiterspielen, Pyramide/Unterwelt, siehe `karten_ausweg.md`).

## Bot-Hinweise

- Im Lauf liefen einmal das Heerlager-Intro aus Teil 5 und die Turnier-Regeln aus Teil 3 nach (Bot hatte sie damals übersprungen, siehe B15 in Teil 6). Bei einem Spieler, der den Herold anspricht, passiert das beim Turnier nicht.
