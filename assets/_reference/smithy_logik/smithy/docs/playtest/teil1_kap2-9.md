# Playtest Teil 1: Kapitel 2 bis zum Lich-Überfall

Bot: `assets/_reference/playtest/sim_play_story.gd` (Minispiele übersprungen, Material in Gold bezahlt, siehe `VORGEHEN.md`). Bilder: `assets/_reference/playtest/teil1/<kapitel>/`, Bildnamen unten ohne Pfad.

## Kapitel 2–3 (`find_customer` » `go_to_market`)

**Ergebnis:** läuft ohne Hänger und ohne Skriptfehler durch. Ende Tag 3, 06:00, 188 Gold.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Keins. 2 Tage, 1 Dungeon-Lauf. |
| 2 | Unschlüssig | Holger, siehe C1 |
| 3 | Gesagt, nicht animiert | nichts gefunden (Übergabe der 100 Gold an Bruno ist animiert) |
| 4 | Komisch | B1 Truhe, C2 Rezeptzeile |
| 5 | Bugs | keine im Log |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | viele Tipps am Stück, siehe B2 |
| 8 | Wirtschaft | 500 » 420 (Einkauf 70, Axt 10) » 320 (Spende an Bruno) » 206 (zwei Gussformen je 50, 2 Barren 14) » 188 (Schwert 18). Reicht gut. |
| 9 | Kampf | Bruno L1 gewinnt den Rattenkeller im ersten Versuch |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### B (komisch)

**B1 · Spieler läuft in die Alte Truhe hinein.** Schritt `find_axe_recipe`, Figur `old_chest` (StoryNpc in `bedroom.tscn`), Bild `014_find_axe_recipe_talk.png`: Der Bot lief mit echter Steuerung von unten auf die Truhe zu und stand am Ende mitten auf ihr, die Truhe ist hinter dem Spieler kaum zu sehen. Sieht so aus, als hätte die Truhe keine Kollision. Unsicher, bitte von Hand prüfen.

**B2 · Tipps zur falschen Zeit.** Schritt `find_axe_recipe`, Bilder `016`/`017`: Gleich nach dem Lesen der Truhe kommen im Schlafzimmer die Tipps „Händler“ und „Goldener Rahmen“, beim Kauf danach noch „Einrichten“ (`018`). Der Händler-Tipp ist lang und passt erst vor dem ersten Händler. Vorschlag: Händler-Tipp beim ersten Ansprechen eines Händlers zeigen.

### C (Kleinkram)

**C1 · Holger zahlt oder zahlt nicht.** Dialog am Markt (`find_customer`): „Ich zahle später, Ehrenwort!“, die Quest `woodcutter_axe` sagt dann „Bezahlen kann ich dich nicht, aber ich lass mir was einfallen.“ Kleiner Widerspruch, passt aber noch als „ich kann jetzt nicht“.

**C2 · Rezeptzeile doppelt.** `chest_recipes`, Bild `014`: „Neue Rezepte: Gussform Kupfer-Holzfälleraxtkopf, Kupfer-Holzfälleraxtkopf, Holzstiel und Holzfälleraxt.“ Liest sich wie ein Fehler. Vorschlag: „Gussform und Rezept für den Kupfer-Holzfälleraxtkopf, Holzstiel und Holzfälleraxt.“

**C3 · Der erste Dungeon kostet den ganzen Tag.** `dungeon_done` setzt die Zeit auf 21 Uhr (`set_time:21`), egal ob Bruno um 06:30 losläuft. Ist so gewollt („Darüber ist es Nacht geworden“), nur als Hinweis: Der Spieler verliert am Tag 2 alles nach dem Losschicken.

### Was gut war

- Story-Preise der Gussformen (je 50 statt 200) greifen, das Gold reicht genau.
- Wege zu Holger stehen gleich im Dialog, im Ziel und in der Quest.
- Brunos Einführung ist witzig, die Geldübergabe ist animiert.

### Nicht getestet

- Minispiele (Gießen, Amboss, Werkbank) und der echte Laufweg zu Holger (Bot reist direkt).
- Bot-Fehler aus dem ersten Lauf (Truhe, Holger, Gussform-Preise) sind behoben, kein Spielfehler.

## Kapitel 4 (`go_to_market` » `chapter4_done`)

**Ergebnis:** läuft ohne Hänger und ohne Skriptfehler durch. Start Tag 1 06:00 mit 500 Gold (Sprung), Ende Tag 1 ca. 10:00 mit 601 Gold. Bilder: `teil1/kap4/`.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Keins. Ein halber Tag. |
| 2 | Unschlüssig | A1 Spitzhacke anlegen vs. abgeben |
| 3 | Gesagt, nicht animiert | nichts: Gustavs Schlag (`swing`) und die 60 Gold (`give`) sind animiert |
| 4 | Komisch | C4 Rezeptzeile wie in Kapitel 2 |
| 5 | Bugs | keine im Log |
| 6 | Sackgassen | A1 (fast) |
| 7 | Lernkurve | gut, ein Tipp pro Neuerung (Ninas Laden, Spitzhacke) |
| 8 | Wirtschaft | 3 Kupferschwerter kosten 54 Gold Material, Nina zahlt 105 nach Provision. Gustav zahlt 60 und schenkt ab morgen täglich Kohle. Gut. |
| 9 | Kampf | kein Kampf |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### A (wichtig)

**A1 · Angelegte Spitzhacke lässt sich nicht abgeben.** Schritte `deliver_pickaxe` » `mine_ores`, Dialoge `miner_*` in `dialogues/mine.json` (`miner_check`). Gustav sagt: „Leg die Spitzhacke im Charakter-Fenster an (C), dann geht es schneller“, der Tipp „Spitzhacke“ sagt dasselbe. Bei „Hier, alles da“ öffnen sich aber Abgabe-Slots, und die nehmen nur Sachen aus dem Inventar (`scenes/ui/common/hand_in_slots.gd:102`, nur `inventory_index`). Das Auftragsbuch zählt die angelegte Spitzhacke dagegen mit (`quest_items.gd:115`), zeigt also 1/1. Wer dem Rat folgt, liest „alles da“ im Buch und hört von Gustav „Da fehlt noch was. Schau ins Auftragsbuch“. Aus dem Code gelesen, der Bot hatte die Spitzhacke im Inventar. Bitte von Hand prüfen: Spitzhacke anlegen, Erz holen, abgeben. Vorschlag: Abgabe-Slots nehmen angelegte Werkzeuge mit, oder Gustav sagt „Nimm sie vorher wieder ab“.

### C (Kleinkram)

**C4 · Rezeptzeile doppelt** wie C2: „Neue Rezepte: Gussform Kupfer-Spitzhackenkopf, Kupfer-Spitzhackenkopf, Holzstiel und Spitzhacke.“ (`meet_miner`).
### Was gut war

- Ninas Laden: der Ablauf (zusagen, auslegen, Geld abholen) ist klar, das Geld lohnt sich.
- Wege werden in jedem Gespräch genannt (Mine: „vom Dorfplatz nach Süden, am Dorftor weiter nach Süden und dann nach Osten“).

### Nicht getestet

- Echtes Abbauen in der Mine (der Bot bekommt 5 Kohle und 8 Erz geschenkt). Ob „jeden Tag nur wenige Steine nach[wachsen]“ für 8 Erz reicht, bitte von Hand prüfen.
- Wie lange Ninas Verkauf wirklich dauert: Der Bot lässt die Zeit 16-fach laufen, verkauft war um 09:00.

## Kapitel 5 (`chapter4_done` » `chapter5_end`)

Ab hier ein durchgehender Lauf bis zum Überfall (`k5_10`), damit Level, Gold und Helden echt mitwachsen. Der Bot nimmt nebenbei Kunden an (Teil „gemacht“, Material in Gold bezahlt), heuert nach 3 Niederlagen den billigsten Helden der Gilde an und gibt neuen Helden ein Kupferschwert. Bilder: `teil1/kap5-10/`.

**Ergebnis:** durchgespielt, keine Skriptfehler. Tag 1 bis Tag 8, Gold 500 » 190 (nach Miete 300 und einem angeheuerten Helden).

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Level 3 (`train_hero`): 9 Rattenkeller-Läufe, Tag 2 06:20 bis Tag 3 20:00, fast nur Warten auf Ausdauer. Rattennest (`beat_rat_king`): Tag 4 bis Tag 7, 6 Niederlagen mit Bruno allein (Level 3–4, Kupferschwert, ohne Rüstung), dann mit Brida (Level 2) im ersten Versuch gewonnen. Siehe A2. |
| 2 | Unschlüssig | nichts |
| 3 | Gesagt, nicht animiert | nichts: Hilde zählt die Münzen, Gustav beißt auf den Nagel, die 80 Gold werden übergeben |
| 4 | Komisch | nichts |
| 5 | Bugs | keine im Log |
| 6 | Sackgassen | keine, aber A2 kann sich so anfühlen |
| 7 | Lernkurve | Tipp „Rattennest“ nennt klar Level 7 und ganzes Kupferset für einen Helden allein. Gut. |
| 8 | Wirtschaft | Kunden zahlen 53–162 Gold pro Teil, ein Held kostet 190–323. Hilde kündigt an: nächste Miete 800 statt 300 (siehe Kapitel 7/8). |
| 9 | Kampf | Rattenkeller mit Kupferschwert R2: 9 von 9 gewonnen. Tiefer Keller (Stufe 3) mit Level 3: 1 Niederlage, dann Siege. Rattennest (Stufe 7) allein bis Level 4 chancenlos. |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### A (wichtig)

**A2 · Rattennest: großer Sprung von Stufe 3 auf Stufe 7, und jeder Fehlversuch kostet.** Schritt `beat_rat_king`, Dungeons `rat_cellar_deep` (Stufe 3, 15 Gold) » `rat_nest` (Stufe 7, 20 Gold). Mit Bruno allein (Level 3–5, Kupferschwert R2) verlor der Bot 12-mal in Folge. In einem Lauf ohne Kundenaufträge sank das Gold dabei von 174 auf 4 und Bruno kam gar nicht mehr los („Zu wenig Gold: der Raid kostet 20 Gold“). Der Tipp sagt zwar „Level 7 und ganzes Kupferset“, aber im Spiel ist das der erste Punkt, an dem man mehr als Bruno braucht, und das Anheuern kommt bis dahin nur nebenbei vor (Tipp „Neue Heldenklasse: Krieger … findest du in der Abenteurergilde“; keine Story-Zeile, Hedwig sagt nur „nicht allein“). Mit einer zweiten Heldin (Brida L2, 190 Gold) ging es sofort. Lauf 2: Bruno L4 und Priesterin Ilka L1 verloren noch zweimal, mit Paladin Leif (323 Gold) als Drittem gewannen sie am Tag 6. Vorschlag: Hedwig sagt in `guild_news` ausdrücklich „Ich hab Leute, die du anheuern kannst“, oder der Tipp „Rattennest“ nennt das Anheuern; Rattennest-Kosten erst nach dem ersten Sieg berechnen wie beim Rattenkeller (`free_until_won`).

### C (Kleinkram)

**C6 · Bot-Hinweis zu den Tagen.** Der Bot schläft nach 3 Niederlagen eine Nacht und hat dabei einmal einen Tag ohne Kampf verschlafen (Tag 5). Die Tageszahlen oben sind darum eher zu hoch.

### Was gut war

- Hildes Mieterhöhung („Meine Nichte braucht neue Schuhe ... Mit Schnallen!“) und ihr Einmischen beim ersten Kunden sind lustig und stehen sichtbar im Bild.
- Gerüchte über die Orks am Markt bauen die Bedrohung gut auf.
- Gustavs Bretter-und-Nägel-Auftrag erklärt die neuen Rezepte gleich mit.

### Nicht getestet

- Rüstung schmieden: Der Bot gibt den Helden nur Schwerter. Mit Kupferrüstung wäre Bruno allein vermutlich weiter gekommen.
- Erster Kunde Ulrich verlangt Solide (Qualität über 100): ob das mit dem Amboss-Minispiel für Anfänger machbar ist, bitte von Hand prüfen.

## Kapitel 6 (`chapter5_end` » `chapter6_end`)

**Ergebnis:** durchgespielt, keine Skriptfehler. Tag 9 (ein Tag), Gold unverändert 190. Helden am Ende: Bruno L8, Brida L2.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | Minen-Kampf (`rat_fight`): 45 Niederlagen am Stück, siehe A3 |
| 2 | Unschlüssig | B4 Bruno bleibt in der Mine |
| 3 | Gesagt, nicht animiert | B4; Klopfen, Einsturz, Ratten, Bruno steht auf, Gustav späht: alles als Cutscene da |
| 4 | Komisch | `rat_fight_lost` sagt 45-mal dieselben zwei Zeilen |
| 5 | Bugs | keine im Log |
| 6 | Sackgassen | keine echte, A3 fühlt sich aber so an |
| 7 | Lernkurve | Schritt sagt „Rüste ihn vorher gut aus“, Gustav nach der Niederlage „Gib Bruno ordentliches Zeug“. Klar. |
| 8 | Wirtschaft | Kampf kostet nichts |
| 9 | Kampf | A3 |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### A (wichtig)

**A3 · Minen-Ratten (Stufe 7) mit Bruno allein.** Schritte `rat_fight` » `rat_fight_running` » `rat_fight_lost`, Dungeon `mine_rats` (Stufe 7, 3 Stufen, am Ende `mine_rat_boss` + Riesenratte). Bruno kämpft allein, ein zweiter Held geht nicht. Mit Kupferschwert R2 und ohne Rüstung verlor er auf Level 5 45-mal und gewann erst auf Level 8 (die Erfahrung aus den verlorenen Kämpfen hob ihn an). Der Kampf kostet weder Gold noch Ausdauer, man kann also stur wiederholen, jeder Versuch dauert aber rund 30 Spielminuten plus Weg zurück in die Mine. Der Bot schmiedet keine Rüstung; mit Kupfer-Set ist es sicher leichter. Bitte von Hand prüfen, mit welcher Ausrüstung ein Spieler das auf Level 5 schafft. Vorschlag: im Text von `rat_fight` sagen, was „gut ausrüsten“ heißt (z. B. „Kupferrüstung und Helm“), oder die Bergratte etwas schwächer.

### B (komisch)

**B4 · Bruno geht nicht an seinen Brunnen.** Dialog nach dem Sieg (`dialogues/mine.json`, Zeile „Dann geh ich lieber wieder an meinen Brunnen. *hicks* Schmied, wir sind quitt!“) hat keine Aktion. `StoryBruno` in `mine.tscn` bleibt bis `gustav_deal` stehen, also bis nach Leonheim, und der Bruno am Brunnen (`village_center.tscn`) ist ab `bruno_joins_fight` für immer weg. Bruno steht also tagelang neben dem Loch in der Mine (Regel 50/53: er hat schon einen `leave_path`). Vorschlag: Bruno geht mit `hide_for` und `leave_path`, und der Brunnen-Bruno kommt mit `old_mine_found` zurück.

### Nicht getestet

- „Bis dahin mach ich das Loch mit Brettern zu“: kein Bild nach dem Gespräch. In `mine.tscn` gibt es nur Geröll/Loch-Requisiten mit `mine_cave_in` und `old_mine_open`; ob Bretter zu sehen sind, bitte von Hand prüfen.

## Kapitel 7 (`chapter6_end` » `chapter7_end`)

Texte und Szenen aus Lauf 1, Zahlen aus Lauf 2 (in Lauf 1 verschlief der Bot bei Goldmangel die Kunden).

**Ergebnis Lauf 2:** durchgespielt, keine Skriptfehler. Tag 9 bis Tag 10 11:37, Gold 168 » 63. Mit drei Helden (Bruno L8, Ilka und Leif, in Kapitel 5 angeheuert) waren Lichter Hain, Dornendickicht und Wolfshöhle an einem Vormittag erledigt, je im ersten Versuch (Kosten 30 + 35 + 40 Gold).

**Zum Vergleich Lauf 1** (nur Bruno L8 und Brida L2): Dornendickicht 3 Niederlagen, Wolfshöhle 4 Niederlagen; dazwischen sank das Gold auf 33, die Wolfshöhle kostet 40. Der Bot kam nicht mehr los, ein Spieler müsste erst etwas verkaufen. Siehe A4.

### B (komisch)

**B5 · „Fast Mittag“ um 6 Uhr.** Schritt `grandma_begs` (Oma Hilde im Wohnviertel): „Und jetzt ist schon fast Mittag ...“. Der Schritt beginnt direkt nach dem Aufwachen (`lotte_gift_evening` » schlafen), Hilde steht schon um 06:01 da, die Uhr zeigt Morgen. Vorschlag: „Und jetzt ist sie schon Stunden weg“ oder `set_time:11` beim Start.

### A (wichtig)

**A4 · Gold-Falle bei Niederlagen.** Wald-Dungeons kosten 30/35/40 Gold pro Versuch, auch bei Niederlage (Rattenkeller ist nur bis zum ersten Sieg frei). Wer mit zu schwacher Gruppe mehrmals verliert, hat schnell kein Gold mehr für den nächsten Versuch, und Kunden kommen nur ein- bis zweimal am Tag. In Lauf 1 hing der Bot so von Tag 13 bis Tag 44 fest (er verkauft nichts, ein Spieler könnte Erz abbauen und verkaufen). Vorschlag: Story-Dungeons bis zum ersten Sieg gratis wie der Rattenkeller (`free_until_won`), oder Kosten erst beim Sieg.

### C (Kleinkram)

**C11 · Lotte sitzt „nur eine Nacht“ auf der Eiche.** `niece_found`: Mit drei Helden passt das (Lauf 2: alles an einem Vormittag). Mit schwächerer Gruppe dauert die Suche Tage (Lauf 1: Tag 11 bis über Tag 13), und niemand drängt. Nur falls man es offener will: „die ganze Zeit“ statt „eine Nacht“.

**C7 · Mieterhöhung trifft Langsame.** Die 800 Gold Miete wird am 1. Sommer (Tag 29) fällig, danach kostet jeder Morgen ohne Zahlung 5 Ruf. Erst `niece_found` macht ein Jahr mietfrei. Wer für Kapitel 6–7 länger braucht, zahlt also 800 oder verliert täglich Ruf, obwohl die Story die Miete gleich darauf erlässt. Nur ein Hinweis; im Bot-Lauf mit Goldmangel kamen so 30 Tage × 5 Ruf zusammen.

### Was gut war

- Hildes Feilschen um die Mietsenkung mit Lotte („Drei Monate!“ – „TANTE HILDE.“) ist eine der besten Szenen bisher.
- Die Spur von Holger über den Korb im Dickicht zur Wolfshöhle hält die Suche zusammen.

### Nicht getestet

- `shoes_for_lotte` (Kinderschuhe schenken, Neben-Aufgabe): der Bot sprang darüber.

## Kapitel 8 (`chapter7_end` » `chapter8_end`)

Texte aus Lauf 1, die drei Fragen zum Verzaubern aus einem kurzen Extra-Lauf (`k8ask`). Kein Kampf, kein Grinden: Gerede, schlafen, Fest, fragen, schlafen.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | keins |
| 2 | Unschlüssig | C9 Frühlingsfest im Sommer |
| 3 | Gesagt, nicht animiert | nichts gefunden: Zaubershow, Kürbis, Lichtschwert, Bruno/Gustav/Hilde ziehen, Funken, Aurelius verschwindet: alles mit Flag oder Cutscene |
| 4 | Komisch | nichts |
| 5 | Bugs | keine im Log |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | vier Tipps auf einmal nach dem Fest (Magier, Priester, Zaubertisch, Zauberstäbe), siehe C10 |
| 8 | Wirtschaft | nichts zu kaufen |
| 9 | Kampf | keiner |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### C (Kleinkram)

**C9 · „Frühlingsfest“ nach dem Kalender.** Schritte `festival_eve`/`festival_morning`: Das Fest hängt nur an der Story. Ein Monat hat 28 Tage, wer bis Kapitel 8 länger als bis zum 28. Frühling braucht, feiert das Frühlingsfest im Sommer (Bot: im Herbst, Tag 46). Vorschlag: „Dorffest“ oder „Sommerfest“ je nach Monat, oder nur „das Fest“.

**C10 · Vier Tipps am Stück.** Nach `festival_show`: „Neue Heldenklasse: Magier“, „Neue Heldenklasse: Priester“, „Zaubertisch“, „Zauberstäbe“ kommen direkt nacheinander, dazu der Abschied von Aurelius. Vorschlag: Zauberstab-Tipp erst am Zaubertisch zeigen.

### Was gut war

- Das Fest ist liebevoll inszeniert: Gerede am Vortag, Ausschlafen bis 10, Zeitsprung zum Abend, alle versuchen das Schwert.
- Die drei Antworten zum Verzaubern führen über Hedwig und Lotte zum alten Schmied, ohne es auszusprechen.

## Kapitel 9: Der Überfall (`chapter8_end` » `chapter10_end`)

Aus Lauf 2 (`k5_10`). **Ergebnis:** durchgespielt bis „Danke fürs Spielen“, aber mit **Skriptfehlern im Log** (A5). Tag 14 01:14 bis Tag 15 06:50. Gold 63 » 0 (der Bot wählt „Den Räubern alles geben“). Bruno stirbt wie geplant, danach Ilka L6 und Leif L6. Bilder: `teil1/kap5-10/`.

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | keins |
| 2 | Unschlüssig | C12 Erna |
| 3 | Gesagt, nicht animiert | A6 Bruno und der Lich |
| 4 | Komisch | nichts weiter |
| 5 | Bugs | A5 Skriptfehler `is_shown` |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | – |
| 8 | Wirtschaft | „Alles geben“ nimmt Gold, Erz, Barren, Waffen und die Loot-Kiste. Gewollt. |
| 9 | Kampf | kein eigener Kampf |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

### A (wichtig)

**A5 · Skriptfehler, Lotte spricht ohne Bild.** Schritte `raid_flee`, `raid_home`, `raid_morning`; Bild `497_raid_flee_betreten_talk.png`. Im Log 11× `Invalid call. Nonexistent function 'is_shown' in base 'Node2D (Companion)'` und 1× bei `RaidFighter`, aus `DialogueBox._find_portrait` (`scenes/ui/dialogue/dialogue_box.gd:294`). Die Funktion geht alle Knoten der Gruppe `StoryNpc.GROUP` durch und ruft `is_shown()`, das gibt es aber nur in `StoryNpc` (`story_npc.gd:405`). `Companion` (`companion.gd:61`) und `RaidFighter` tragen sich in dieselbe Gruppe ein. Folge: Lottes Zeilen („Kai ... ich hab Angst.“) erscheinen ohne Porträt. Das trifft jede mitlaufende Figur, die spricht, nicht nur hier. Eingeführt mit `a0dcb4c9f` (2026-11-15, „Lakes Bild“). Vorschlag: `node.has_method("is_shown")` prüfen oder `is_shown()`/`get_portrait()` auch in `Companion` und `RaidFighter`.

**A6 · Bruno geht nicht auf den Lich los.** Schritt `raid_to_market`, Dialog `raid_market_scene`, Erzähler-Zeile 28: „Die Abenteurer schwärmen aus, jeder stellt sich einem Zombie in den Weg. Bruno zieht sein Schwert und stapft auf den Lich zu. Der Weg zu Oma Hilde ist frei.“ Die Zeile hat kein `action` und kein `hide_for`. Bild `487`: Die Kamera steht am Südeingang, das Fenster verdeckt die Platzmitte, Bruno steht noch neben dem Spieler. Danach (Bild `494`, Bot stand am Baum) ist Bruno beim Lich nicht zu sehen. Das ist Brunos letzter Auftritt vor seinem Tod, er sollte sichtbar sein (Regel 50). Vorschlag: Cutscene-Teil mit `hide_for`: Fenster weg, Kamera zur Mitte, Bruno läuft mit gezogenem Schwert zum Lich, Abenteurer gehen auf die Zombies, dann erst „Der Weg zu Oma Hilde ist frei“.

### C (Kleinkram)

**C12 · „Erna vom Bauernhof“.** `raid_morning`, Wachmann Otto: „Erna vom Bauernhof am Dorfplatz schaut jeden Abend nach dir.“ Erna wohnt laut `npcs.json` tatsächlich dort, der Spieler kennt sie aber nur als Erzhändlerin vom Markt. Vorschlag: „Erna, die Erzhändlerin, vom Bauernhof am Dorfplatz“.

### Was gut war

- Sehr starke Szene: der verwelkende Lebensbaum, Bruno fängt den Feuerball ab („Nüchtern und angekokelt. Schlechter Tag für den Lich.“), die Plünderer vor der Schmiede, Lotte, die nichts sagt und nur die Hand drückt.
- Feuerball, Brunos Schutz, Lich dreht sich, Lotte schläft ein, Wachmann verbeugt sich: alles als Cutscene da.
- Der Morgen-Bildschirm „Du hast die ganze Nacht Wache gehalten. Lotte schläft noch tief und fest.“ passt genau.

### Nicht getestet

- `raid_rescue` (mit Lotte sprechen): der Bot steuerte die falsche Lotte-Figur an (die unsichtbare Begleiterin) und sprang weiter. Bitte von Hand prüfen, ob E bei Lotte in der Ecke sicher greift, wenn Hilde direkt daneben liegt.
- „Ne, lieber nicht“ bei den Plünderern.

---

## Zusammenfassung Teil 1 (Kapitel 2 bis Überfall)

**A (wichtig):**
- A5 Skriptfehler `is_shown` bei Begleitern, Lotte ohne Porträt (`dialogue_box.gd:294`)
- A6 Bruno stapft nicht sichtbar auf den Lich zu (`raid_market_scene#28`)
- A1 Angelegte Spitzhacke lässt sich bei Gustav nicht abgeben
- A2 Rattennest Stufe 7 direkt nach Stufe 3, allein kaum zu schaffen, Anheuern nicht erklärt
- A3 Minen-Ratten: Bruno allein verlor mit Kupferschwert 44–45-mal (Level 5 bis 8)
- A4 Gold-Falle: verlorene Dungeon-Versuche kosten 20–40 Gold, schwache Gruppen kommen nicht mehr los

**B (komisch):** B1 Truhe ohne Kollision (unsicher), B2 Tipps zur falschen Zeit, B4 Bruno bleibt nach „an meinen Brunnen“ tagelang in der Mine, B5 „fast Mittag“ um 6 Uhr.

**C (Kleinkram):** C1 Holger zahlt/zahlt nicht, C2/C4 doppelte Rezeptzeile, C3 erster Dungeon bis 21 Uhr, C6 Bot-Hinweis, C7 Miete 800 trifft Langsame, C9 Frühlingsfest im Sommer, C10 vier Tipps am Stück, C11 „nur eine Nacht“, C12 Erna.

**Zeit bis zum Überfall (Lauf 2, Minispiele übersprungen):** Kapitel 2–4 rund 3 Tage, Kapitel 5–9 (ab Sprung) Tag 1 bis Tag 15. Der Bot schmiedet keine Rüstung; mit Rüstung wären A2 und A3 milder.
