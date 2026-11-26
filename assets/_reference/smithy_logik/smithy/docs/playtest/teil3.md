# Playtest Teil 3: Sylvaris, Schmiedeturnier, Angriff auf die Elfen

Bot: `sim_play_story.gd`, weitergespielt vom Autosave aus Teil 2 (`assets/_reference/playtest/saves/teil2_ende.json`, Schritt `fight_dragon`, Tag 53). Zwei Läufe: `teil3/lauf_a/` (ohne Waffen für Hadmar, Elfen verlieren den Windkristall) und `teil3/lauf_b/` (mit Waffen, Elfen halten Sylvaris). Bildnamen unten ohne Pfad.

**Ergebnis:** durchgespielt bis `part3_end`, Tag 55 bis Tag 56 (Teil 3 ist kurz). Gold 9 472 » 6 891 (Lauf b nach den Silberschwertern 7 150). Helden: Ilka, Leif, Zora je L35. Keine Skriptfehler im Log.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | keins, die Gruppe aus Teil 2 reicht. Greif (Horst, Stufe 35) im ersten Versuch. |
| 2 | Unschlüssig | B9 Westen/Osten, B10 Lob für nicht gelieferte Waffen, B11 Briefe kommen zu spät |
| 3 | Gesagt, nicht animiert | nichts gefunden: Angriff, Lich, Schild aus Wind, Wurf, Lakes Hieb, Pfeilhagel, Klinge, Karte: alles Cutscene |
| 4 | Komisch | C17 „Der Älteste erwartet dich oben“ |
| 5 | Bugs | keine |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | B12 Rezept-Strafe im Turnier |
| 8 | Wirtschaft | Hadmar: 14 Silberschwerter R1 = 812 Gold Material (mit Greif-Bonus). Gold reicht dicke. |
| 9 | Kampf / Turnier | A10 Schmiedeturnier |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

## A (wichtig)

**A10 · Schmiedeturnier: Runde 3 und 4 nur mit Seltenheit 2 zu gewinnen (bitte von Hand prüfen).** Schritt `tournament_announced`, `economy.json` „smith_tournament“. Punkte = Seltenheit × 100 + Qualität + Zeitbonus (bis 40, 0 ab 360 s) − 30 je unbekanntes Rezept. Gegner: Runde 1 Kupfer 30–75, Runde 2 Eisen 50–100, Runde 3 Bronze 70–120, Runde 4 Silber 90–140 (dazu sein Zeitbonus). Der Bot spielte 18 Turniere mit Qualität 70, Seltenheit 1, Zeit = 360 s: Runde 1 gewann er 16-mal, Runde 2 nie (dort zusätzlich −60 für zwei unbekannte Eisen-Rezepte, siehe B12). Auch ohne Strafe gewinnt 70 in Runde 2 nur gut zur Hälfte, in Runde 3 fast nie, in Runde 4 nie. Wer das Turnier gewinnen will, braucht in den letzten Runden Stücke über 100 (Seltenheit 2), also sehr gute Minispiele, und schnelle. Das Turnier ist kostenlos wiederholbar, also keine Sackgasse, aber es kann für Anfänger eine Wand sein, und die Story hängt daran. Vorschlag: Gegner in Runde 3/4 etwas schwächer (z. B. 60–105 und 75–125), oder ein Tipp vor dem Turnier, dass es um Seltenheit geht.

## B (komisch)

**B9 · Sylvaris liegt im Westen und im Osten.** `crystal_to_king` (Teil 2), Aurelius: „Und jetzt zieht er nach Westen. Zum großen Wald der Elfen.“ `elf_attack_summit`: „Zwei Punkte leuchten auf: ein blasser im Westen, wo Sylvaris liegt“. Der Tipp „Die Kristallkarte“ danach: „dazu den Wald der Elfen mit Sylvaris **östlich** vom Land der Menschen.“ Eins davon stimmt nicht.

**B10 · Der Älteste lobt Waffen, die nie kamen.** Schritt `elf_elder_evening`, `dialogues/elves.json` Zeile 410: „Hadmar hat Eure Waffen auf die Brücken verteilt. Meine Wächter tragen jetzt Metall, das singt …“ steht ohne Bedingung. Bei Hadmar kann man aber mit null Teilen „Mehr habe ich nicht“ wählen (`general_done`), und der Angriff verläuft dann richtig als Niederlage (Lauf a). Vorschlag: Zeile mit `if_flag: elf_defense_level_2`/`_3`, sonst z. B. „Hadmar hat verteilt, was da war. Es ist wenig.“

**B11 · Briefe kommen nach dem Ereignis an (Muster, siehe auch B7 in Teil 2).** Schritt `council_call`: Der Brief „Komm in den Thronsaal, so schnell du kannst“ kommt bei Lotte in Sylvaris an, also nachdem das Gespräch im Thronsaal schon war (Lauf a, Zeilen nach `elf_arrival`). Lotte bringt Briefe beim nächsten Kartenwechsel, auch wenn der Spieler schon dort war, wohin der Brief ihn schickt. Mit Teleportern (ab Teil 2) passiert das leicht. Unsicher, weil der Bot direkt reist. Vorschlag: Ist der Schritt schon weiter als der Brief, den Brief still als gelesen markieren.

**B12 · Rezept-Strafe im Turnier ohne Vorwarnung.** Jede Aufgabe ist ein zufälliges Teil (Speer, Dolch, Keule, Schulterschutz …) im Metall der Runde; jedes Rezept, das man nicht kennt, kostet 30 Punkte. Wer bis hier nur Schwerter und Rüstung aus Eisen geschmiedet hat, verliert in Runde 2 oft schon an der Strafe. Bot-Hinweis: Der Bot kauft keine Gussformen, die −60 sind bei ihm also immer da; ein Spieler mit mehr Eisen-Formen hat weniger. Vorschlag: Der Herold sagt vorher „Kenn deine Formen: Speere, Dolche, Keulen, alles kann drankommen“.

## C (Kleinkram)

**C17 · „Der Älteste erwartet dich oben“, aber das Ziel ist Hadmar unten.** Schritt `elf_return`: Erzähler „Der Älteste erwartet dich oben an der Spitze.“, das Ziel des Schritts ist „Sprich mit General Hadmar am Waldboden“. Erst zwei Schritte später (`elf_elder_evening`) geht es zum Ältesten.

## Was gut war

- Beide Ausgänge des Angriffs sind fertig und passen: mit genug Waffen hält Sylvaris, Lake rettet den Kristall und prahlt danach („Wo warst du, Elf? Am Boden.“), ohne Waffen holt sich der Lich den Wind.
- Das Zeichen auf der Untoten-Klinge, das auf den Meisterhandschuhen auch steht: starker Moment, ohne etwas zu verraten.
- Hadmars Rückmeldung in Stufen („reicht nicht mal für die Ostbrücke“ bis „Das reicht“) ist klar.

## Nicht getestet

- Das Schmiedeturnier selbst (Minispiele): siehe A10, der Bot sprang nach 18 verlorenen Versuchen weiter.
- Hadmars Abgabe-Fenster mit der Maus: Der Bot gibt über `ElfDefense.hand_in` ab.
