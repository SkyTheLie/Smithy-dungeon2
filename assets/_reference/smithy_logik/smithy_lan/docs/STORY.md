# STORY.md – Smithy

> Überblick über die Geschichte: was im Spiel schon umgesetzt ist und was als Nächstes kommt.
> Umgesetzte Story steht technisch in `data/content/story.json` (Felder: `docs/CONTENT.md`, Abschnitt story.json).
> Neue Story-Ideen unten unter **„Geplant“** eintragen. Sobald ein Teil im Spiel ist, wandert er nach oben unter **„Umgesetzt“**.

---

## Stand

> Kapitel und Teile sind nur intern: Im Spiel (Auftragsbuch, Tipps, Dialoge) werden sie nie erwähnt. Sprechstil der Figuren: `docs/DIALOGE.md`.

**Aufteilung:** **Teil 1** = Kapitel 1–9, endet mit dem Morgen nach dem Überfall (`chapter10_end`, Tipp „Ende von Teil 1“). Bis dahin geht die **Alpha** für Tester. Am nächsten Morgen beginnt **Teil 2** = Kapitel 1–9 (1 Der Wiederaufbau, 2 Ein Hauch von Magie, 3 Die Königsstadt, 4 Die Gosse, 5 Die neun Steine, 6 Die verzauberte Gruft, 7 Der Goblinkönig, 8 Der Drache, 9 Der Feuerkristall). Er endet, wenn der Spieler dem König den Feuerkristall gebracht hat und Aurelius vor dem Angriff des Lichs auf die Elfen warnt (`part2_end`). Beim nächsten Schlafen beginnt **Teil 3** = Kapitel 1–5 (1 Der Kriegsrat, 2 Das Schmiedeturnier, 3 Waffen für Sylvaris, 4 Die Nacht in Sylvaris, 5 Der Krisenrat; die Nacht hat zwei Enden). Er endet nach dem Krisenrat in Sylvaris (`part3_end`, Feierabend). Am nächsten Morgen beginnt **Teil 4** = Kapitel 1–5 (1 Die Stadt im Eis, 2 Das Turnier der Gezeiten, 3 Gefangen im Sand, 4 Der Sturmtempel, 5 Der leere Thron). Er endet, wenn der Spieler mit dem Blitzkristall nach Leonheim kommt und der König verschwunden ist (`part4_end`). Am nächsten Morgen beginnt **Teil 5** = Kapitel 1–5 (1 Ohne König, 2 Die Sumpfhechse, 3 Vor der Finsterburg, 4 Der Sturm auf die Finsterburg, 5 Der dunkle Ritter); er endet nach der Enthüllung im Thronsaal der Finsterburg (`part5_end`). Danach **Teil 6** = Kapitel 1–6 (1 Asche und Sternenlicht, 2 Die Glut in deinen Händen, 3 Unter Freunden, 4 Das Gesetz der Strömung, 5 Wo das Eis singt, 6 Der Kampf um den Eiskristall; Ende `part6_end`), **Teil 7** = Kapitel 1–4 (1 Die Stadt im Schatten, 2 Der Widerstand, 3 Zurück in die Finsterburg, 4 Die rechtmäßige Erbin; Ende `part7_end`), **Teil 8** = Kapitel 1–5 (1 Der große Rat, 2 Das Tor öffnet sich, 3 Die Schlacht am Altar, 4 Licht in der Dunkelheit, 5 Die wahre Fassung; Ende `story_end`).

**Die Story ist im Spiel komplett** (seit 2026-10-28, Platzhalter-Grafik). Sie endet mit Teil 8 (`story_end`, „Der Schmied der Neun“): Das Tor am Altar der Neun ist mit der wahren Fassung für tausend Jahre geschlossen, der König ist ins Tor gezogen worden, Lake ist erlöst und wacht am Altar, Nyra herrscht in der Finsterstadt, Halvard lebt im Dorf (`story_complete`). Danach kommt ein Abspann, der Spieler wacht in seiner Schmiede auf und findet Halvard und Lotte am Amboss (`ending_morning`); dann geht das Spiel frei weiter. Davor: Teil 8 (Rat der Völker am Ratstisch auf der Spitze von Sylvaris, Waffen und Sternenstahl für das Bündnis, Schlacht am Altar), Teil 7 (Finsterstadt, Nyra, Halvards Befreiung aus der Kerkerschmiede), Teil 6 ab Kapitel 3 (Eisquell, Eismauer, der König holt den Eiskristall). Davor: Teil 6, Kapitel 2 (`to_eisquell_again`, „Zurück nach Eisquell“): Aurelius hat den Spieler aus der Finsterburg auf seine Lichtung gerettet und dabei seine Magie verloren, der Spieler ist in Leonheim gesucht (Schloss gesperrt), Aurelius erklärt die Siegelglut, und der Spieler kennt den Namen des legendären Schmieds (Meister Halvard), der unter der Finsterburg schmiedet. Davor: Ende von Teil 5 (`part5_end`, „Der neunte Stein“): Der König ist der Bösewicht, Lake ist sein dunkler Ritter, der König hat acht Steine (nur Eis fehlt). Davor: Ende von Teil 4 (Kapitel 5, Schritt `part4_end`, „Der leere Thron“): Der König ist mit Feuer- und Wasserkristall verschwunden, der Lich verlangt den Blitzkristall als Lösegeld. Davor: der Sturmtempel (Siegel, Säulen, Blitzableiter), die Gefangenschaft in Sahrim mit Ulrich und Fürst Ssarok, Kahns Heldenturnier in Eisquell, die Jagd auf Frostmähne. Davor: Ende von Teil 3 (Kapitel 4, Schritt `part3_end`, Titel „Fortsetzung folgt“): Der Lich hat in der Nacht den Windkristall aus Sylvaris geraubt, der Älteste Elarion gibt dem Spieler das Kartenstück der Elfen und erzählt, warum die Karte existiert; der König, Aurelius, Lake und der Spieler wollen zu Kahn in die Stadt des Wasservolks. Davor: das große Schmiedeturnier in Leonheim (4 Runden, Meisterhandschuhe des legendären Schmieds), der Kriegsrat im Thronsaal und der erste Besuch in Sylvaris. Davor: Ende von Teil 2 (Kapitel 9, Schritt `part2_end`): Der Spieler hat dem König den heiligen Feuerkristall übergeben, Meister Aurelius platzt in den Thronsaal und warnt, dass der Lich mit einem Heer gegen den Wald der Elfen zieht, um den Windkristall zu holen. Davor: Ignar ist besiegt, der Spieler nimmt den Kristall, der Drache erwacht ein letztes Mal und reißt die Goblinburg mit sich in die Lava (Kapitel 8). Davor: Goldzahn der Prächtige, die Goblinkrone (Kapitel 7), die verzauberte Gruft mit Kastellan Morwald, die Schatzkammer des Königs mit dem ersten Viertel der Kristallkarte und Lake des Licht (Kapitel 6), Aurelius erzählt die Legende vom Dämonenlord und den neun heiligen Steinen (Kapitel 5), die Krähenbande in der Gosse (Kapitel 4), die Audienz beim König (Kapitel 3), Aurelius im Wald und der erste Trank (Kapitel 2), der Wiederaufbau (Kapitel 1), der Überfall am Ende von Teil 1.
Freigeschaltet sind dann Loot-Kiste, Ninas Laden (ab 2000 Gold Umsatz erweitert), Auftragsbrett und Kunden, Tiefer Rattenkeller und Rattennest, die größere Mine, die Wald-Dungeons, die alte Mine (Mine 2, durch das Rattenloch in der Mine) und der Zaubertisch; ein Jahr lang keine Miete (danach 800 Gold), die Schmiede ist für 100.000 Gold kaufbar. Unabhängig von den Kapiteln: Kalender (Geschenk von Nina) und der Reisende (jeden Sonntag). Die Teleport-Kristalle stehen von Anfang an, schlafen aber; ab Kapitel 5 von Teil 2 weckt der Spieler sie mit dem Portalkristall (vor der Schmiede, in Leonheim; Mine und Wald später).

---

## Figuren

| Figur | id | Wo | Rolle |
|---|---|---|---|
| Spieler | – | – | Junger Schmied, hat den verschwundenen Meisterschmied als Kind bewundert, kommt mit 800 Gold ins Dorf |
| Der legendäre Schmied | – | verschwunden | Früherer Schmied des Dorfes, spurlos verschwunden; seine Schmiede steht leer |
| Oma Hilde | `landlady` | Wohnviertel, eigenes Haus | Vermieterin der Schmiede, kassiert 300 Gold Miete alle 14 Tage. Stirbt beim Überfall (Kapitel 9, `gone_flag` `hilde_dead`) |
| Holger | `woodcutter_market` | erst Marktplatz, dann Holzfällerhütte im Wald | Holzfäller, braucht eine Kupferaxt, liefert danach täglich Holz |
| Bruno | `bruno` | vor der Schmiede | Betrunkener „alter Krieger“, wird der erste Held. Stirbt beim Überfall: fängt den Feuerball des Lichs ab, der dem Spieler galt, und hält den Lich danach allein auf, bis der Spieler mit Lotte entkommen ist (Kapitel 9, `gone_flag` `bruno_dead`) |
| Wachmann Otto | `raid_guard` | Schmiedeplatz (Morgen nach dem Überfall, Morgen von Teil 2) | Überbringt die Nachricht von Brunos und Oma Hildes Tod, schickt den Spieler zum Bürgermeister |
| Bürgermeister Wendelin | `mayor` | Marktplatz, Westeingang (Teil 2, Kapitel 1) | Saß während des Überfalls mit dem Dorfrat im Rathauskeller und schämt sich dafür; fragt, was der Spieler gesehen hat, stellt Konrad vor, dankt mit 300 Gold, schreibt der Hauptstadt (Baukasten-Figur) |
| Baumeister Konrad | `builder` | Marktplatz, Westeingang; nach dem Wiederaufbau nur Di und Do 8–18 Uhr | Baut den Markt wieder auf, danach das Haus des Spielers (Hausausbau) und das Gewächshaus; hat Meister Aurelius im Wald gesehen und Aurelius' Buch hinter der Schmiede |
| Nina | `nina` | Marktplatz, eigener Laden oben am Ende der Straße nach Norden | Ladenbesitzerin, verkauft die Waffen des Spielers gegen 15 % Provision; nennt Oma Hilde „die Hexe“ |

| Der Lich | `lich` | Marktplatz (nur beim Überfall) | Reißt den leuchtenden Kern aus dem Lebensbaum und flieht damit |
| Gustav | `miner` | vor der Mine | Alter Bergmann, Spitzhacke beim Einsturz zerbrochen, die Mine ist seitdem größtenteils verschüttet. Wohnt mit seiner Frau Erna im Bauernhaus mit Scheune unten links am Dorfplatz (npcs.json `gustav`) |
| Erna | (npcs.json `erna`) | Erzstand auf dem Markt, wohnt am Dorfplatz | Gustavs Frau, verkauft das Erz, das er aus der Mine holt; schaut nach Hildes Tod jeden Abend nach Lotte |
| Ulrich | `first_customer` | vor der Schmiede, ab Teil 4 vor der Zelle in Sahrim und in der Markthalle | Echsenmensch (seit 2026-10-28). Der erste Kunde („Ich habe von Ihnen gehört“), will ein Kupferschwert R2. Taucht in Teil 4 als Händler mit Karawane wieder auf (das Schwert hat ihn vor Räubern gerettet), siezt den Spieler und bürgt für ihn bei Fürst Ssarok |
| Berta und Fritz | `gossip_a`, `gossip_b` | Mitte des Marktplatzes | Dorfbewohner, tuscheln über den Orküberfall auf Birkenfeld |
| Hedwig | `guild_master` | Abenteurergilde, neben dem Dungeon-Brett | Gildenmeisterin, rothaarig und direkt. Schaltet den Tiefen Rattenkeller frei, will ein Kupferset sehen (Neben-Aufgabe) |
| Lotte | `niece` | Omas Haus; ab dem Überfall zieht sie umher (zu Hause, vor der Schmiede, Dorfplatz, Markt, Ninas Laden) | Oma Hildes Nichte, lieb und frech, rote Zöpfe (PixelLab-Figur `residents/emma.png`, früher eine eigene Figur „Emma“). Verschwindet beim Pilzesammeln im Wald (Kapitel 7), wird beim Überfall vom Spieler gerettet, erbt Omas Haus und die Schmiede: die Miete geht an sie, auch das Kaufangebot (100.000 Gold). Wohnt danach weiter in Omas Haus, Erna schaut abends nach ihr |
| Meister Aurelius | `magician` | Frühlingsfest (Marktplatz), tiefer Wald (Teil 2, Kapitel 2 und 5), Thronsaal (Ende von Teil 2) | Fahrender Magier (ein Elf) mit sternenblauem Mantel, schenkt dem Spieler den Zaubertisch, erklärt Tränke, erzählt die Legende der neun Steine, jagt den Lich; warnt am Ende von Teil 2 vor dem Angriff auf die Elfen und geht ihnen voraus |
| Rashid | – (Händler) | sonntags vor dem Dorftor (links, vor der Palisade), sonst in der Markthalle von Sahrim (außer Samstag und Montag, da reist er) | Echsenmensch aus Sahrim (seit 2026-10-28). Reisender mit vollbepacktem Planwagen und Kamel, verkauft seltene Gussformen und Barren teuer; wohnt in der Wüstenstadt Sahrim |
| Kutscher Jupp | `coachman` | Wegekreuz vor dem Dorftor, immer (sitzt auf dem Bock der Dorfkutsche) | Fährt die Dorfkutsche, nur mit Erlaubnis des Bürgermeisters; sein Pferd heißt Liese |
| Mohammad | `envoy` | Schlossgarten in Leonheim | Gesandter des Königs im blauen Mantel, empfängt den Spieler im Schlossgarten |
| König Albrecht | `king` | Thronsaal in Leonheim | Alter König mit weißem Bart; lobt den Spieler, bittet ihn, Lotte zu beschützen, hört vom Lich und schickt ihn zur Gilde |
| Schlosswachen | `castle_guard` | vor dem Schlosstor | Wache in Silber und Blau, Wächterin mit Schild |
| Thora | `capital_guild_master` | Gilde von Leonheim, neben dem Dungeon-Brett | Gildenmeisterin mit weißem Haar und rotem Ledermantel, schickt die Helden unter die Stadt |
| Frieda | – (Theke der Gilde) | Gilde von Leonheim | Gildenschreiberin, vermittelt Helden zum Anheuern |
| Bertram | – (Wirt) | Gasthaus in der Einkaufsstraße | Wirt mit rotem Bart, vermietet Zimmer (Schlafen in der Stadt) |
| Vex | – (Händler) | Schwarzmarkt im Hinterhof | Schattenhändler mit Kapuze, verkauft Schmuggelware; daneben steht ein Spielautomat |
| Der Bettler | – (`ShellGameBeggar`) | Dorfplatz, Wiese links vom Schild „Dorftor“ | Spielt mit drei Bechern und einer Murmel um Gold; betrügt, sobald es um echtes Gold geht |
| Lake des Licht | `lake` | Thronsaal (nur während der Schatzkammer-Szene) | Rechte Hand des Königs, ihm blind ergeben (siehe `docs/DIALOGE.md`); sucht die übrigen drei Teile der Kristallkarte |
| Kerkermeister | `jailer` | Kerker im Schloss | Bewacht Varrik, der seit Kapitel 3 in einer Zelle sitzt (`varrik_jailed`) |
| Kastellan Morwald | – (Gegner `castellan_morwald`) | Leonheim IV: Die verzauberte Gruft | Untoter Kastellan, trug den Schlüssel der Schatzkammer, hat 2 Lebensbalken |
| Goldzahn der Prächtige | `goblin_king` | Goblinhöhle, Thronplatte | Goldbesessener Goblinkönig, nennt seine Barren beim Namen; will 500 Gold Audienzgebühr, 30 Bronzebarren (Gold hat ihm der Drache genommen) und eine Bronzekrone; verliert am Ende seine Burg samt Gold an die Lava |
| Goblinwachen | `goblin_guard` | Goblinhöhle, Brücke zum Thron | Kassieren die Audienzgebühr |
| Der dünne Goblin | `goblin_hungry` | erst in der Menge, dann in der Goblinmine | Fragt nach Essen und wird von der Plattform in die Mine geworfen |
| Krummfinger | – (Händler) | Goblinhöhle, Westplatte | Goblin-Händler: Gold-Gussformen, Erz, Rubine, immer offen |
| Aufseher Schlackbart | `goblin_overseer` | Goblinmine | Treibt die Arbeiter an |
| Der Älteste Elarion | `elf_elder` | Spitze von Sylvaris (fliegende Insel) | Herr der Elfen, angelegt an Elrond (`docs/DIALOGE.md`). War vor tausend Jahren dabei, als der Dämonenlord fiel; kennt den Lich „von früher“. Sieht das blaue Licht in den Händen des Spielers. Gibt nach dem Angriff das Kartenstück der Elfen |
| General Hadmar | `general` | Waldboden von Sylvaris (Teil 3, nach dem Turnier) | General des Königs, grauer Bart, trocken; führt die hundert Soldaten aus Leonheim und sammelt die Waffen für Sylvaris (`ElfDefense`) |
| Hauptmann Faelan | `faelan` | Spitze von Sylvaris, abends auf der Kronenebene | Rechte Hand des Ältesten, Hauptmann der Windwache, stolz („Sylvaris kann niemand erobern“), knapp 400 Jahre alt. Verdächtigt nach dem Angriff Lake; die Elfen suchen das vierte Kartenstück |
| Wächterin Liriel | `elf_guard` | Waldboden von Sylvaris, an der Tür des großen Baums | Erklärt die Plattform |
| Fenn (Fennoriel Sternwind) | `elf_inventor` | Flugfeld auf der unteren Kronenebene von Sylvaris (seit 2026-10-30) | Verrückter junger Erfinder, das Gegenteil der anderen Elfen (laut, hastig, duzt alle), will eine Flugmaschine bauen; die anderen dulden ihn, mögen ihn nicht (Laubhüter Caladen, `elf_grumbler`). Nach dem Krisenrat Nebenquest „Fenns Flugmaschine“ (Gestell, Schwingen, Windorb, Funke Leben, siehe `docs/SYSTEME.md` „Nebenquests“); danach fliegt er den Spieler. |
| Nimeriel | `elf_child` | Kronenebene | Elfenkind, will ein Schwert „mit Glitzer“ |
| Sturmschwinge, der Greif | – (Gegner `griffin`) | Sturmgipfel III: Der Horst | Wächter der Elfenpässe, vom Lich mit einem schwarzen Splitter wild gemacht; Boss mit 2 Lebensbalken |
| Herold | – (Turnier-Tisch) | Turnierplatz in Leonheim | Turnier-Fenster (`TournamentMenu`) |
| Kasim aus dem Süden | – (nur Turnier-Gegner) | Turnierplatz, Runde 3 | Schmied aus der Wüste (Anknüpfung an den Blitzkristall) |
| Die alte Ishra | `lizard_elder` | Sahrim (Wüste), im Fürstenzelt; erzählt, wie die Ahnen die Glaskuppel aus Blitzen und Sand bauten | Älteste des Echsenvolks, langsam und freundlich; kennt Aurelius, warnt vor den Gewittern der tiefen Wüste (Blitze machen Glas aus Sand, Andeutung Blitzkristall) |
| Zahir | `treasure_hunter` | Sahrim, im Abenteuerzelt (Zeltviertel) | Echsen-Schatzsucher, prahlt, hat sich hundertmal verlaufen; schenkt die Sandkarte, jeden Tag ein anderer Hinweis |
| Kesh, Mira, Brakk | `lizard_kesh`, `lizard_mira`, `lizard_brakk` | Sahrim (Kesh an der Quelle, Mira und Brakk im Zeltviertel) | Wasserträger, Weberin, alter Torwächter: je ein Hinweis zur ersten Truhe |
| Schmiedin Ssiva, Tuk, Nesha | – (Händler) | Sahrim (Ssiva in der Schmiede im Zeltviertel, Tuk und Nesha in der Markthalle) | Echsen-Schmiedin (Kohle, Barren, Topas), Gewürz- und Stoffhändler (Sand, Glas, Seil, Leder, Kristalle) |
| Kahn | `kahn` | Halle der Strömung in Eisquell, nach dem Turnier in der Arena | Anführer des Wasservolks (Fischmensch), angelegt an Dschingis Khan; gibt dem König den Wasserkristall und dem Spieler das dritte Kartenstück |
| Torgai | `kahn_son` | Halle der Strömung, Gezeitenarena | Kahns Sohn, Krieger, Gegner im Halbfinale des Heldenturniers (arena.json `champions`) |
| Subar | `kahn_right_hand` | vor der Halle der Strömung | Kahns rechte Hand, alter narbiger Krieger, verlangt das Fell der Frostmähne |
| Ausrufer | `arena_crier` | Gezeitenarena | Meldet Helden fürs Turnier an (`HeroTournamentMenu`) |
| Fürst Ssarok | `desert_lord` | vor der Zelle am Südtor, dann im Fürstenzelt von Sahrim (mit zwei Speerkriegern) | Anführer des Echsenvolks, weiß viel über die Welt, glaubt, jemand steht hinter dem Lich; gibt die Karte der Sturmpfade |
| Echsenwachen | `desert_guard` | Sahrim | Verhaften den Spieler als vermeintlichen Spion |
| Muhme Grisla | `swamp_witch` | Stelzenhütte im Sumpf | Uralte Echsen-„Hechse“, Ssaroks Großtante, sieht mit dem Trank der tausend Augen |
| Hauptmann Bertold | `leon_captain` | Heerlager, Torhof der Finsterburg | Hauptmann der Soldaten von Leonheim |
| Meister Halvard | `halvard` | Kerkerschmiede unter der Finsterburg, Versteck, Marktplatz, Altar; nach dem Ende vor der Schmiede im Dorf | Der legendäre Schmied, vor 20 Jahren vom König entführt, musste Waffen und die Fassung des Schlüssels schmieden (manipuliert: sie zerbricht). Verliert am Ende seine Siegelglut |
| Nyra | `nyra` (vorher `hooded`) | Finsterstadt (Gasse), Versteck unter der Färberei, Marktplatz, Altar | Halbdämonin im Kapuzenmantel, die „Verräterin“ vom Steckbrief, Tochter des ermordeten Fürsten und rechtmäßige Fürstin der Finsterstadt |
| Corvin | `corvin` | Versteck unter der Färberei | Alter Diener von Nyras Familie, hat sie versteckt |
| Vessa, Grat, Pip | `finster_citizen_a/b/c` | Finsterstadt | Halbdämonen der Stadt (Bäckerin, alter Mann, Kind) |
| Ignar, der Glutdrache | `dragon` (Gegner `volcano_dragon`) | Drachenkammer der Goblinburg | Hat die Goblins vor hundert Jahren aus ihrer Burg gejagt und schläft auf ihrem Gold und dem Feuerkristall; deutet an, dass nicht nur der Lich Steine sammelt, und reißt nach seiner Niederlage die Burg mit sich in die Lava |

---

## Umgesetzt

### Intro (nach dem Charakter-Editor)

Vor vielen Jahren lebte im Dorf ein Schmied, dessen Klingen man in allen Königreichen kannte. Eines Tages verschwand er spurlos. Seitdem sucht das Dorf einen neuen Meisterschmied, und viele Schmiede wetteifern um den Titel. Der Spieler hat ihn als Kind bewundert, jahrelang gespart und kommt nun mit 800 Gold ins Dorf (story.json `start.gold`).

Start: Dorfplatz (der Spieler läuft von unten auf den Platz).

### Kapitel 1: Eine eigene Schmiede

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 1 | Eine Schmiede finden (`find_smithy`) | Westlich vom Dorfplatz steht die alte Schmiede, Tür verschlossen, Schild „Zu vermieten, 300 Gold alle zwei Wochen“. Tipps: Steuerung, Auftragsbuch, Alles nachlesen (Einstellungen » Einleitung) | Schild gelesen |
| 2 | Die Vermieterin besuchen (`visit_landlady`) | Oma Hilde im Wohnviertel (Norden) bietet die Schmiede an | Spieler mietet (300 Gold) |
| 3 | Die Schmiede aufräumen (`clean_smithy`) | Spinnweben an Schmelze, Werkbank, Amboss und Esse entfernen. Tipp: Miete; Tipp Aufräumen erst beim Betreten der Schmiede (erste Spinnwebe, `Cobweb.ENTER_HINT`) | alle 4 Spinnweben weg |

### Kapitel 2: Holgers Axt

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 4 | Einen Kunden finden (`find_customer`) | Auf dem Marktplatz (Osten) ruft Holger nach einer Axt, die Händler wollen ihm ohne Gold keine geben. Spieler nimmt den Auftrag an („zahl ich später“), Holger geht nach rechts davon | Auftrag angenommen |
| 5 | Ein Rezept für die Axt (`find_axe_recipe`) | In der Truhe im Schlafzimmer liegen Aufzeichnungen des alten Schmieds | Truhe geöffnet: Rezepte Gussform Kupfer-Axtkopf, Kupfer-Axtkopf, Holzstiel, Axt |
| 6 | Kupfer und Wassertrog kaufen (`buy_supplies`) | Auf dem Markt Kupfer (Erz oder Barren) und den Wassertrog kaufen. Tipp: Händler | beides gekauft |
| 7 | Die Kupferaxt schmieden (`forge_axe`) | Schmelzen, Gießen, Amboss, Abkühlen, Holzstiel schnitzen, zusammenbauen | Kupferaxt im Inventar |
| 8 | Die Axt abgeben (`deliver_axe`) | Holger wartet an seiner Hütte im Wald (Süden durchs Dorftor, an der Kreuzung Westen) | Axt abgegeben: Holger liefert ab jetzt täglich Holz |

### Kapitel 3: Hallo Dungeon

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 9 | Feierabend (`go_to_sleep`) | Uhr springt auf 19 Uhr. Tipp: Tageszeit / schlafen | Spieler schläft im Bett |
| 10 | Ein Besucher (`meet_bruno`) | Am Morgen bettelt Bruno vor der Schmiede. „Ihm helfen“: Spieler gibt ihm 100 Gold. Bruno will dafür als Held Schätze holen | Bruno angeheuert |
| 11 | Material kaufen (`buy_sword_parts`) | Beim Gussform-Händler Gussformen Kupferklinge und Kupfergriff, beim Erzhändler Kupferbarren kaufen | alles gekauft |
| 12 | Schwert schmieden (`forge_sword`) | Kupferschwert schmieden | Kupferschwert im Inventar |
| 13 | Bruno ausrüsten (`equip_bruno`) | Schwert in Brunos rechte Hand. Tipp: Ausrüsten | Bruno hat eine Waffe |
| 14 | Zur Abenteurergilde (`go_to_guild`) | Gilde im Osten des Marktplatzes | Gilde betreten |
| 15 | Bruno losschicken (`send_bruno`) | Am Dungeon-Brett in den Rattenkeller schicken (das erste Mal kostenlos, Brett leuchtet: Stadt » Rattenkeller » Bruno). Tipp: Dungeon-Brett | Abenteuer gestartet |
| 16 | Warten auf Bruno (`wait_for_bruno`) | Kampf läuft von allein, im Kampffenster zusehen | gewonnen (bei Niederlage zurück zu 15) |
| 17 | Hallo Dungeon: geschafft! (`dungeon_done`) | Beute liegt in der Loot-Kiste. Freigeschaltet: Loot-Kiste, Bogentisch bei der Möbelhändlerin. Es wird Nacht (21 Uhr). Tipp: Loot-Kiste | Spieler schläft |

### Kapitel 4: Ninas Laden und Gustavs Spitzhacke

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 18 | Einkaufen auf dem Markt (`go_to_market`) | Am nächsten Morgen auf den Markt. Nina steht auf der anderen Marktseite, läuft zum Spieler und spricht ihn an („Bist du nicht der, der die alte Schmiede von der Hexe gemietet hat?“). Sie hat einen Laden, die Händler sind geizig, sie nimmt nur 15 % Provision | Spieler sagt „Abgemacht!“: Nina läuft zurück, ihr Laden (oben rechts am Markt) ist offen |
| 19 | Schwerter ausstellen (`display_swords`) | Im Laden auf die 4 Tische drei Schwerter legen: zwei der Stufe R1, eins R2 oder höher. Tipp: Ninas Laden | die Schwerter liegen aus |
| 20 | Auf Käufer warten (`wait_for_sales`) | Käufer kommen zufällig zwischen 8 und 20 Uhr (pro Stück und Stunde 20 %) | drei Teile verkauft |
| 21 | Geld abholen (`collect_shop_money`) | Nina an der Kasse zahlt aus (oder hat das Geld schon in die Loot-Kiste gelegt) und erzählt von Gustav | Gespräch beendet |
| 22 | Der Bergmann (`meet_miner`) | Gustav vor der Mine: Spitzhacke beim Einsturz zerbrochen, Gänge verschüttet, nur der vordere Teil der Mine ist frei. Gibt die Gussform seines Vaters | Spieler sagt zu: Rezepte Gussform Kupfer-Spitzhackenkopf, Kupfer-Spitzhackenkopf, Holzstiel, Spitzhacke |
| 23 | Eine Spitzhacke für Gustav (`forge_pickaxe`) | Kopf gießen und schmieden, Holzstiel schnitzen, an der Werkbank verbinden | Kupferspitzhacke im Inventar |
| 24 | Die Spitzhacke abgeben (`deliver_pickaxe`) | Gustav prüft sie, sein Rücken macht nicht mehr mit: der Spieler behält sie und soll ihm 5 Kohle und 8 Kupfererz abbauen (im Dorf gibt es nur Kupfer) | Gespräch beendet |
| 25 | Erz für Gustav (`mine_ores`) | In der kleinen Mine wachsen nur 5 Steine pro Tag. Tipps: Spitzhacke anlegen; wenn die Mine leer ist: schlafen gehen, dann wachsen neue nach. Das Auftragsbuch zeigt, wie viel man schon hat | Spitzhacke + Erz bei Gustav abgegeben: 60 Gold |
| 26 | Ruhige Tage (`chapter4_done`) | Gustav räumt die Gänge frei; freies Spielen, bis die erste Miete fällig ist | Spieler hat die Miete in Gold (`have_gold`, Oma kommt dann gleich) oder Morgen, an dem die Miete fällig ist (Ereignis `rent_due`) |

### Kapitel 5: Die erste Miete und der erste Kunde

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 27 | Die erste Miete (`first_rent`) | Oma Hilde wartet morgens vor der Schmiede und läuft zum Spieler: „Zahltag!“ (300 Gold). Bis hierher kassiert sie nie von selbst | Spieler zahlt; ohne genug Gold wartet sie |
| 28 | Ein Fremder (`first_customer`) | Oma erhöht die Miete auf 800 Gold: ihre Nichte braucht neue Schuhe (halb gelogen). Dann kommt Ulrich: „Ich habe von Ihnen gehört“, will ein Kupferschwert R2. Der Spieler zögert, Oma nimmt den Auftrag gierig für ihn an | Gespräch beendet: Auftrag im Auftragsbuch, Auftragsbrett freigeschaltet |
| 29 | Den ersten Kunden vergisst man nie (`first_order`) | Kupferschwert R2 schmieden (Klinge und Griff mit mehr als 60 Qualität) und am Auftragsbrett abgeben. Frist 3 Tage, der Auftrag läuft aber nicht ab. Tipp: Auftragsbrett | Schwert abgegeben |
| 30 | Feierabend (`first_order_done`) | Ab jetzt kommen auch normale Kunden. Tipp: Kunden | Spieler schläft |
| 31 | Gerüchte (`market_rumors`) | Mitten auf dem Marktplatz tuscheln Berta und Fritz: Orks haben das Dorf Birkenfeld überfallen, keine zwei Tagesreisen entfernt | Spieler kommt nahe heran und hört zu |
| 32 | Stärker werden (`train_hero`) | Wegen der Orks sollen die Helden stärker werden. Tipp: Helden leveln | ein Held erreicht Level 5 |
| 33 | Neuigkeiten aus der Gilde (`guild_news`) | Gildenmeisterin Hedwig (neben dem Dungeon-Brett) spricht den Spieler an: Im Rattenkeller ist eine Wand eingestürzt, dahinter geht es tiefer, die Ratten sind „so groß wie Hunde“ | Gespräch beendet: Tiefer Rattenkeller auf dem Brett |
| 34 | Der Tiefe Rattenkeller (`clear_deep_cellar`) | Helden in den Tiefen Rattenkeller schicken (Lv 3, Riesenratten ab Stufe 6) | Tiefer Rattenkeller gewonnen (bei Niederlage nochmal) |
| 35 | Der Rattenkönig (`beat_rat_king`) | Ein Gang führt noch tiefer: ins Rattennest. Hedwig erzählt vom Rattenkönig („Wer ihn erledigt, hat ein Bier frei“). Tipp: Rattennest | Rattennest gewonnen (Rattenkönig auf Stufe 11 besiegt) |
| 36 | Besuch vom Bergmann (`miner_visit`) | Gustav hat davon gehört und läuft vor der Schmiede zum Spieler: Die Gänge sind frei, aber ohne Stützen stürzt alles wieder ein. Er braucht 20 Holzbretter und 5 Kupfernägel („Ein Schmied, der keinen Nagel machen kann?“) | Spieler sagt zu: Rezepte Holzbrett (1 Holz) und Kupfernagel (1 Kupferbarren), Werkbank » Zubehör » Baumaterial |
| 37 | Bretter und Nägel für Gustav (`build_supplies`) | Bretter sägen, Nägel machen, zu Gustav vor die Mine bringen. Das Auftragsbuch zeigt, wie viele man schon hat | Abgabe bei Gustav: 80 Gold |
| 38 | Gustav baut (`mine_repairs`) | Gustav stützt die Stollen ab („Komm morgen wieder“) | Spieler schläft |
| 39 | Die größere Mine (`visit_mine`) | Am Morgen ist die Mine größer (Flag `mine_expanded`): Gänge nach Westen, Norden und Osten frei, 8 statt 5 Steine pro Tag, Kohle und Kupfer je zur Hälfte (Eisen wächst hier erst, wenn die alte Mine in Teil 2 offen ist, `mine_iron_rock.tres`). Gustav zeigt stolz die Kupferader | Gespräch mit Gustav vor der Mine |
| 40 | Feierabend (`chapter5_end`) | Ende von Kapitel 5 | Spieler schläft |

### Kapitel 6: Ratten in der Mine

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 41 | Gustavs neuer Stollen (`mine_tour`) | Gustav wartet vor der Mine: Hinten im neuen Stollen klingt der Fels hohl | Gespräch beendet |
| 42 | Ein Rundgang (`explore_mine`) | Gustav geht vor (vor der Mine ist er weg). In der Mine oben links, am Ende der Kammer: Er klopft an die Wand, das Geröll bricht ein, ein Loch, Ratten kommen heraus, eine so groß wie ein Hund. Gustav hält sie auf, der Spieler rennt raus | Gespräch beendet: Spieler steht vor der Mine |
| 43 | Hilfe holen (`get_help`) | Bruno liegt am Brunnen auf dem Dorfplatz und schnarcht, will nicht („Ratten sind eklig“). „Du schuldest mir noch was!“: Gold, Schwert, keine Münze zurück. Er kommt mit („danach sind wir quitt, und du gibst einen aus“) | Gespräch beendet |
| 44 | Kampf in der Mine (`rat_fight`) | Bruno steht in der Mine bei Gustav. Tipp: Kampf in der Mine | „Los, Bruno!“: Kampf startet (Kampffenster) |
| 45 | Bruno gegen die Ratten (`rat_fight_running`) | Dungeon-Abenteuer `mine_rats`, Bruno allein: Stufe 1 drei Ratten, Stufe 2 zwei Ratten und eine Riesenratte, Stufe 3 die Alte Bergratte (Boss) und eine Riesenratte | gewonnen; verloren: Rückzug (`rat_fight_lost`), der Spieler steht vor der Mine, wieder hineingehen = neuer Versuch |
| 46 | Was ist hinter dem Loch? (`after_rat_fight`) | Gustav, Bruno und der Spieler: hinter dem Loch liegt eine riesige Höhle mit Erz, die alte, eingestürzte Mine. Durch das Loch kommt man nicht hinein: Gustav bräuchte eine Eisenspitzhacke und Eisennägel, und Eisen gibt es erst in der Königsstadt. Bruno geht zurück an seinen Brunnen („wir sind quitt“) | Gespräch beendet (`old_mine_found`); das Angebot für die alte Mine macht Gustav erst in Teil 2 nach Leonheim (siehe Neben-Aufgabe „Die nächste Ebene“) |
| 47 | Feierabend (`chapter6_end`) | – | Spieler schläft |
| 48a | Schuhe für Lotte? (`market_shoes`) | Auf dem Markt vor dem Schuhladen (Haus oben links): Lotte will die roten Schuhe für 100 Gold, Oma kauft die braunen für 50 („Die sehen aus wie zwei Kartoffeln.“) und zieht sie weiter. Der Spieler denkt an die erhöhte Miete | Spieler kommt nahe heran und hört zu |
| 48b | Das Schaufenster (`look_at_shoes`) | Vor dem Schaufenster: „Ja, das könnte funktionieren.“ Rezepte Seil (2 Hanf oder 2 Flachs) und Kinderschuhe (1 Leder + 1 Seil), Werkbank » Zubehör » Zusatz. Tipp: Kinderschuhe | Spieler steht vor dem Laden |
| 48c | Ein Geschenk für Lotte (`shoes_for_lotte`) | Neben-Aufgabe „Schuhe für Lotte“: Leder an der Gerberbank (Möbelhändlerin), Seil aus Hanf/Flachs, Schuhe an der Werkbank. Lotte (bei Oma zu Hause): „Hoffe, sie gefallen dir“, sie will sie morgen gleich im Wald ausprobieren | Schuhe verschenkt: Rezept Lederschuhe für den Spieler |
| 48d | Feierabend (`lotte_gift_evening`) | Ende von Kapitel 6 | Spieler schläft (am nächsten Morgen ist Lotte verschwunden) |

### Kapitel 7: Die verschwundene Nichte

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 48 | Oma in Not (`grandma_begs`) | Oma Hilde wartet morgens vor der Schmiede und läuft zum Spieler: Lottes Bett war heute früh leer, sie ist mit den neuen Schuhen losgezogen. Sie bietet sogar etwas Miete an („die Hälfte. Ein Viertel. Ein bisschen was.“) | „Ich finde sie“ |
| 49 | Wo ist Lotte? (`ask_around`) | Auf dem Marktplatz spricht Holger den Spieler an (er bringt gerade Holz zum Markt): Er hat Lotte heute früh an seiner Hütte gesehen, sie wollte tief im Wald Pilze sammeln, wo die Wölfe sind | Gespräch beendet |
| 50 | Zurück zu Oma (`report_grandma`) | Oma: „Schick deine Helden in den Wald!“ | Gespräch beendet: Reiter Wald auf dem Dungeon-Brett. Tipp: Dungeons im Wald |
| 51 | Suche im Lichten Hain (`forest_edge`) | Dungeon Lichter Hain (Lv 5, Wölfe) | einmal geschafft: ein Stück von Lottes Schal |
| 52 | Suche im Dornendickicht (`forest_thicket`) | Dungeon Dornendickicht (Lv 7, Wölfe und Wildschweine, Mini-Boss zwei Wildschweine) | einmal geschafft: Lottes Korb, riesige Pfotenabdrücke |
| 53 | Die Wolfshöhle (`forest_den`) | Dungeon Wolfshöhle (Lv 9, Boss Schwarzer Wolf mit zwei Wölfen). Tipp: Der Schwarze Wolf | einmal geschafft |
| 54 | Lotte ist gerettet! (`niece_found`) | Tipp: Die Helden laufen nach dem Boss weiter und finden Lotte oben in einer alten Eiche. Bei Oma: Oma will die Miete um 100 Gold senken („für eine Woche“), Lotte erzählt die Sache mit den Schuhen (50 statt 100 Gold), es geht hin und her, bis Oma ein ganzes Jahr Miete erlässt. Danach bietet Oma die Schmiede für 100.000 Gold zum Kauf an | Gespräch beendet: 112 Tage mietfrei |
| 55 | Ein Jahr mietfrei (`chapter7_end`) | Ende von Kapitel 7 | „Die nächste Ebene“ erledigt |
| 56 | Feierabend (`chapter7_rest`) | – | Spieler schläft |

### Kapitel 8: Das Frühlingsfest

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 57 | Gerede im Dorf (`festival_rumors`) | Auf dem Dorfplatz reden Berta und Fritz vom Frühlingsfest morgen und hoffen, dass Meister Aurelius wiederkommt | Spieler kommt nahe heran und hört zu |
| 58 | Morgen ist Frühlingsfest (`festival_eve`) | – | Spieler schläft |
| 59 | Ausgeschlafen (`festival_morning`) | Der Spieler wacht erst um 10 Uhr auf. Der Dorfplatz ist leer (alle Dorfbewohner sind weg), von Osten hört man Jubel | Dorfplatz oder Markt betreten |
| 60 | Das Frühlingsfest (`festival_show`) | Auf dem Markt stehen alle vor dem Lebensbaum, darunter Meister Aurelius (Oma, Lotte, Holger, Bruno, Gustav sind auch da). Show, Zeitsprung auf 19 Uhr, zum Schluss ein blau leuchtendes Schwert im Boden. Bruno, Gustav, Holger und viele andere scheitern, die Menge wird kleiner. Der Spieler zieht es heraus wie aus Luft, Applaus. Aurelius flüstert „Das kann doch nicht sein ...“: im Spieler steckt Magie, wie damals beim legendären Schmied (Andeutung). Das Schwert zerfällt zu Funken, Aurelius schenkt einen Zaubertisch und verschwindet | Gespräch beendet: Zaubertisch steht in der Schmiede |
| 61 | Ein magischer Abend (`festival_night`) | Tipp: Zaubertisch | Spieler schläft |
| 62 | Wie verzaubert man? (`ask_enchanting`) | Nina, Hedwig und Oma fragen: Niemand weiß es; Hedwig erinnert sich an die leuchtenden Klingen des alten Schmieds, Lotte an Omas Geschichten von seinem blauen Licht | alle drei gefragt |
| 63 | Niemand weiß es (`chapter8_end`) | Ende von Kapitel 8 | Spieler schläft (in dieser Nacht kommt der Überfall) |

### Kapitel 9: Der Überfall

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 71 | Mitten in der Nacht (`raid_wake`) | Uhr springt auf 1 Uhr nachts (`raid_started`). Ein Knall, Rauch, Schreie: der Spieler rennt los, ohne Gold und Werkzeug. Alle Dorfbewohner sind weg (`villagers_away`) | Schmiedeplatz betreten |
| 72 | Rauch über dem Dorf (`raid_outside`) | Über den Dächern im Osten Feuerschein und Rauch, ein unheimliches Heulen | Dorfplatz betreten |
| 73 | Bruno ist auch wach (`raid_bruno`) | Bruno kommt dem Spieler entgegen, ausnahmsweise nüchtern, und geht mit (`bruno_follows`, er läuft hinter dem Spieler her). Auf dem Dorfplatz geht es nur noch nach Osten | Gespräch beendet |
| 74 | Zum Marktplatz (`raid_to_market`) | – | Marktplatz betreten |
| 75 | Der Marktplatz brennt (`raid_market`) | Stände brennen, zwei Häuser haben Brandlöcher von Feuerbällen, 8 Zombies torkeln herum. Der Lich hat die Hand im Lebensbaum, grünes Licht fließt in seinen Arm (`tree_drain_start`), dann reißt er den leuchtenden Kern heraus und der Baum welkt vor den Augen des Spielers (`tree_withered`, Animation). In der Ecke unten links liegt Oma Hilde, daneben weint ihre Nichte Lotte. Der Lich bemerkt den Spieler und schleudert einen Feuerball auf ihn; Bruno wirft sich dazwischen und wird getroffen. Hedwig und fünf Abenteurer stürmen aus der Gilde (`raid_heroes`), jeder läuft zu einem Zombie und kämpft mit ihm. Bruno, angekokelt: „Nimm die Kleine und hau ab!“, dankt für das Schwert und geht auf den Lich los, der Weg zu Lotte ist frei | Gespräch beendet |
| 76 | Nimm die Kleine! (`raid_rescue`) | Lotte will ihre Tante nicht allein lassen; „Deine Tante will, dass du in Sicherheit bist“ überredet sie, Oma Hilde bittet ebenfalls darum | Lotte kommt mit (`emma_follows`, sie läuft hinter dem Spieler her; Bruno bleibt zum Kämpfen) |
| 77 | In Sicherheit (`raid_flee`) | Mit Lotte zurück: Marktplatz » Westen » Westen | Schmiede betreten |
| 78 | Ausgeraubt (`raid_robbed`) | Die Schmiede ist ausgeräumt: alles Gold, das ganze Inventar und die Loot-Kiste sind weg (`rob_player`); Rezepte und Gussformen bleiben, ebenso angelegte Werkzeuge und die Ausrüstung der Helden. Lotte darf über Nacht bleiben | Gespräch beendet (`raid_over`) |
| 79 | Eine lange Nacht (`raid_night`) | Der Spieler hält Wache, die Nacht endet von selbst (Aktion `sleep`, kein Bett nötig) | sofort: nächster Morgen |
| 80 | Der Morgen danach (`raid_morning`) | Wachmann Otto kommt zur Schmiede: Zombies zurückgeschlagen, aber Bruno hat den Feuerball für den Spieler abgefangen, sich danach allein dem Lich gestellt und ist gestorben (`bruno_dead`, er verlässt die Heldengruppe, seine Ausrüstung liegt in der Loot-Kiste). Der Lich ist mit dem Kern geflohen. Der Lebensbaum steht seit Jahrhunderten und soll das Dorf beschützt haben, warum, weiß niemand. Oma Hilde ist gestorben, Lotte erbt ihr Haus und die Schmiede (die Miete bekommt jetzt sie). Lotte will im Haus ihrer Tante bleiben, Erna (Gustavs Frau) schaut jeden Abend nach ihr; der Spieler soll für sie sorgen und Geld für beide verdienen | Gespräch beendet (`hilde_dead`, `bruno_dead`) |
| 81 | Ende von Teil 1 (`chapter10_end`) | Ende von Kapitel 9 und von Teil 1 (Tipp „Ende von Teil 1“: danke fürs Spielen, man kann weiterspielen) | Spieler schläft: Teil 2 beginnt |

Danach bleibt der Marktplatz verwüstet (Brandflecken, Trümmer, ein eingestürzter Stand, zwei verkohlte Häuser, `raid_started`), bis er in Teil 2, Kapitel 1 wieder aufgebaut wird (`village_rebuilt`); der Lebensbaum bleibt tot (`tree_withered`). Die Händler verkaufen weiter, Nina führt ihren Laden wie bisher. Lotte wohnt in Omas Haus und zieht tagsüber durchs Dorf; die Miete kassiert jetzt sie, die Schmiede kauft man bei ihr.

## Teil 2

### Teil 2, Kapitel 1: Der Wiederaufbau

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 82 | Ein Besuch von der Wache (`rebuild_call`) | Am Morgen nach Teil 1: überall wird gebaut und aufgeräumt. Wachmann Otto läuft vor der Schmiede zum Spieler: der Bürgermeister will wissen, was er in der Nacht gesehen hat | Gespräch beendet |
| 83 | Der Bürgermeister (`meet_mayor`) | Auf dem Marktplatz am Westeingang: Bürgermeister Wendelin schämt sich, dass er im Rathauskeller saß, und fragt, was der Spieler gesehen hat (Auswahl: der Lich am Baum / Zombies und Feuer). Bruno bekommt einen Gedenkstein. Er stellt Baumeister Konrad vor: 20 Holzbretter, 20 Holzbalken, 20 Kupfernägel, 5 Kupferbarren | Gespräch beendet: Rezepte Holzbrett, Holzbalken, Kupfernagel |
| 84 | Baumaterial für das Dorf (`rebuild_gather`) | Material zu Konrad auf den Markt bringen; das Auftragsbuch zeigt den Fortschritt | alles abgegeben (`rebuild_delivered`): die Dorfbewohner packen mit an |
| 85 | Alle packen mit an (`rebuild_night`) | Über Nacht wird gebaut (`overnight`: `village_rebuilt`) | Spieler schläft |
| 86 | Wie neu (`rebuild_done`) | Brandflecken, Trümmer, der eingestürzte Stand und die Brandlöcher in den Häusern sind weg | Marktplatz betreten |
| 87 | Danke, Schmied (`rebuild_thanks`) | Der Bürgermeister: 300 Gold. Der König soll vom Lich von jemandem hören, der dabei war: Ab jetzt darf der Spieler die Dorfkutsche benutzen (`carriage_allowed`), Wendelin schreibt dem König, dass er kommt. Konrad bleibt in der Gegend: jeden Dienstag und Donnerstag auf dem Markt, baut das Haus aus und für 20 Holzbalken, 20 Glas und 500 Gold ein Gewächshaus (Neben-Aufgabe). Er schickt den Spieler zum Magier im Wald. | Gespräch beendet (`builder_weekly`, `greenhouse_offer`, der Bürgermeister geht) |

Ab Schritt 87 kommt Konrad nur noch dienstags und donnerstags von 8 bis 18 Uhr auf den Markt (Vermerk im Kalender); bei ihm baut man das Haus aus (vorher gibt es keinen Hausausbau).

### Teil 2, Kapitel 2: Ein Hauch von Magie

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 88a | Der Magier im Wald (`forest_mage`) | Aurelius sucht auf der Lichtung oben links im tiefen Wald nach Kräutern, erkennt den Schmied vom Fest und das Schwert („seit zwanzig Jahren hat es niemand herausgezogen“), will 1 Hanf | Gespräch beendet |
| 88b | Ein Bündel Hanf (`forest_hemp`) | Tipp Hanf suchen. Abgabe: der Spieler fragt, wie man verzaubert; Aurelius erklärt Mörser und Verzauberungstränke (Kristall + Mondlilie + Phiole, falsche Mischung = Asche = Dünger), gibt seine Notizen und 3 Mondlilien-Samen und nennt Konrad (Gewächshaus) und die Möbelhändlerin (Pflanztopf und Erde) | Hanf abgegeben |
| 92 | Ein Hauch von Magie (`chapter11_end`) | Ende von Teil 2, Kapitel 2. Gewächshaus, Mondlilien, erster Trank und erste Verzauberung laufen als Neben-Aufgaben (`greenhouse`, `greenhouse_pot`, `lily_plant`, `lily_grow`, `first_potion`, `first_enchant`); alte Spielstände in den früheren Schritten machen hier weiter (`renamed_steps`) | Spieler schläft |

### Teil 2, Kapitel 3: Die Königsstadt

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 93 | Zum König (`royal_carriage`) | Ein Reiter hat die Antwort des Königs gebracht, Lotte bringt sie als Botin ans Bett (`lotte_letter_royal`, Tipp `king_answer` = der Brief). Kutscher Jupp hat die Liese angespannt: „Der König erwartet dich.“ Einzige Antwort: „Nach Leonheim, zum König.“ | Zugestimmt: Überblendung, Fahrt nach Leonheim (`left_for_capital`) |
| 94 | Im Schlossgarten (`castle_arrival`) | Die Kutsche hält im Schlossgarten, Mohammad stellt sich vor („von dem Bürgermeister Wendelin schreibt“) und schickt den Spieler ins Schloss; die Kutsche steht quer auf dem Weg nach Süden | Gespräch beendet |
| 95 | Audienz beim König (`meet_king`) | Thronsaal: König Albrecht lobt den Spieler (Lotte aus dem Feuer gerettet, Nägel für das Dorf geschmiedet), bittet ihn, Lotte ab jetzt zu beschützen und gut für sie zu sorgen. Der Spieler erzählt vom Lich, dem leuchtenden Herz aus dem Lebensbaum, dem verwelkten Baum, Bruno und Oma Hilde. Der König kennt die Bäume aus den Geschichten seines Großvaters, fürchtet, dass das Dorf erst der Anfang war, und schickt den Spieler zur großen Abenteurergilde in der Einkaufsstraße | Gespräch beendet (`king_audience_done`): die Kutsche fährt zur Seite, der Weg in die Stadt ist frei |
| 96 | Die Gilde von Leonheim (`to_city_guild`) | Durch den Garten nach Süden in die Einkaufsstraße: sieben Läden (einer pro Dorfstand) und die Gilde | Gilde betreten |
| 97 | Die Gildenmeisterin (`meet_guild_master`) | In der Gilde spricht Thora den Spieler an: unter der Stadt stehen die Toten wieder auf (Kanalisation, Katakomben, Gruft der Könige), das riecht nach dem Lich. Sie nimmt ihn in die Gilde auf | Gespräch beendet (`capital_guild_joined`): Reiter Leonheim auf dem Dungeon-Brett, Tipp |
| 98 | Feierabend (`chapter12_end`) | Ende von Teil 2, Kapitel 3 | Spieler schläft |

Ab Teil 2, Kapitel 3 fährt die Kutsche zwischen dem Wegekreuz vor dem Dorftor („Kutsche nach Leonheim“), Schlossgarten und dem Westende der Einkaufsstraße („Kutsche ins Dorf“) hin und her.

Spielstände, die noch beim alten Ende `chapter5_done` standen, machen bei Schritt 32 weiter (story.json `renamed_steps`). Spielstände, die im alten Kapitel 9 standen (`mage_rumors`, `find_mage`, `bring_hemp`, `chapter9_end`, noch älter `plant_lily`, `grow_lily`, `first_dust`), machen bei `chapter8_end` weiter (schlafen = Überfall; Aurelius trifft man dann in Teil 2); Pflanzen aus den alten festen Beeten im Gewächshaus kommen beim Laden als Samen zurück ins Inventar; am alten Schritt `rebuild_mourning` geht es bei `rebuild_call` weiter. Wer schon nach dem Wiederaufbau war, trifft Konrad sofort am Markt (`implied_flags`).

### Teil 2, Kapitel 4: Die Gosse

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 99 | Was weiß der König? (`king_question`) | Thronsaal: Der König erinnert sich nicht mehr an die ganze Geschichte vom Lebensbaum („irgendwas mit einem Helden und einem Schlüssel“), hat aber eine Ahnung, wer sie kennt. Eine Hand wäscht die andere: Die Krähenbande in der Gosse (Armenviertel) nimmt Wegzoll und plündert Lagerhäuser, ihr Anführer Varrik nennt sich Krähenkönig | Gespräch beendet (`gutter_unlocked`): Reiter Gosse auf dem Dungeon-Brett, Tipp |
| 100 | Die Krummen Gassen (`gutter_alleys`) | Gosse I, Boss Ratzo der Wegelagerer | Gosse I geschafft |
| 101 | Das Lagerhaus am Kanal (`gutter_warehouse`) | Ratzo hatte einen Zettel „Ware ins Lagerhaus am Kanal“. Gosse II, Boss Lagermeister Grimbald (Zweihänder), Tipp Schildbanditen | Gosse II geschafft |
| 102 | Zum Ersoffenen Hund (`gutter_tavern`) | Die Spelunke der Krähen, Gosse III, Boss Bulle Brakk trinkt Bärenblut (stärker, sehr lange) | Gosse III geschafft |
| 103 | Das Krähennest (`gutter_nest`) | Brakk verrät Varriks Versteck. Gosse IV (nur einmal), Varrik mit Speer ruft bei 75/50/25 % je 2 Banditen | Gosse IV geschafft (`varrik_defeated`, der Dungeon verschwindet) |
| 104 | Der Krähenkönig (`varrik_caught`) | Thronsaal: Varrik kniet gefesselt zwischen zwei Wachen, wird verurteilt und in den Kerker geschleift (`varrik_jailed`). Der König gibt 300 Gold und nennt den alten Hofzauberer Aurelius; der Spieler kennt ihn vom Frühlingsfest. Wo er steckt, weiß niemand: Such ihn | Gespräch beendet |
| 105 | Feierabend (`chapter13_end`) | Ende von Teil 2, Kapitel 4 | Spieler schläft |

### Teil 2, Kapitel 5: Die neun Steine

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 106 | Wo ist Aurelius? (`search_mage`) | Niemand weiß es; nach 4 Tagen hört man etwas (`wait_days`) | 4 Tage vergangen |
| 107 | Gerüchte auf dem Markt (`mage_rumors_return`) | Berta und Fritz: Der Zauberer vom Frühlingsfest ist wieder im tiefen Wald | Gespräch beendet |
| 108 | Aurelius im Wald (`find_mage_again`) | Tiefer Wald: Legende vom Dämonenlord, den ein Held mit einem magischen Schlüssel weggesperrt hat. Der Schlüssel aus einem unbekannten Metall mit neun heiligen Steinen (einer pro Element), die überall versteckt wurden; im Lebensbaum lag der Stein der Erde (deshalb leuchtete der Kern braun). Der Lich sammelt die Steine. Aurelius geht dem Lich nach; der Spieler soll den König um die Karte der Steine bitten. Geschenk: der Portalkristall | Gespräch beendet (`portal_crystal_owned`, Aurelius ist fort) |
| 109 | Den Teleporter wecken (`build_teleporter`) | Der alte Teleport-Kristall vor der Schmiede (stand schon immer da, reagierte nie) wird mit E und dem Portalkristall geweckt, Tipp Teleporter (auch Leonheim) | `teleporter_home_built` |
| 110 | Die Karte der heiligen Steine (`ask_king_map`) | Thronsaal: Der König kann nicht („Jaaa ... die Karte“): Er kommt nicht in seine eigene Schatzkammer. Den Schlüssel trug Kastellan Morwald, der mit ihm in der Gruft begraben wurde; seit der Lich umgeht, ist die Gruft verzaubert, und Morwald bewacht die tiefste Kammer | Gespräch beendet (`king_wants_key`) |

### Teil 2, Kapitel 6: Die verzauberte Gruft

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 111 | Die verzauberte Gruft (`chapter14_end`, früher „Fortsetzung folgt“) | Dungeon Leonheim IV: Die verzauberte Gruft (einmalig, Lv 22). Kastellan Morwald hat 2 Lebensbalken und ruft Skelette | Gruft geschafft (`morwald_defeated`) |
| 112 | Der Schlüssel der Schatzkammer (`key_to_king`) | Thronsaal (über die neue Vorhalle, Treppe hinauf): Der König öffnet hinter dem Thron die Schatzkammer. Auf dem Pult liegt nur ein Viertel der Karte. Drei Punkte leuchten: braun (Dorf, der Kristall der Erde, den hat der Lich), hell (Leonheim, Licht, irgendwo unter der Stadt), rot (Lavaberg, Feuer). Der König vermutet die gierigen Goblins, schickt den Spieler los („Bring ihn mir. Hier ist er sicher.“). Lake des Licht soll die anderen drei Kartenteile suchen | Gespräch beendet: Kristallkarte (`map_piece_1`), Kutsche zum Lavaberg (`volcano_route_open`), Silber-Gussformen bei Quentin (`silver_molds_offered`) |
| 113 | Feierabend (`chapter15_end`) | – | Spieler schläft |

### Teil 2, Kapitel 7: Der Goblinkönig

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 114 | Zum Lavaberg (`to_volcano`) | Kutsche am Westende der Einkaufsstraße, Brücke über die Schlucht, Höhleneingang im Norden des Plateaus; Teleporter neben der Kutsche | Goblinhöhle betreten |
| 115 | Die Goblinhöhle (`goblin_cave_arrival`) | Erzähler: Platten über dem Abgrund, Brücken, Lava und arbeitende Goblins in der Tiefe, Thron im Norden, Händler im Westen, Mine im Osten | Gespräch beendet |
| 116 | Die Wachen des Goblinkönigs (`goblin_guards`) | Die Wachen an der Brücke zum Thron wollen 5000 Gold Audienzgebühr | gezahlt (`goblin_audience_paid`) |
| 117 | Audienz beim Goblinkönig (`goblin_king_audience`) | Goldzahn weiß, wo der Kristall ist, will aber etwas dafür. Automatische Szene: die Menge ruft „Gold!“, ein dünner Goblin „Essen?“, Stille, „!“ über dem König („Wer war das?“), die Menge stößt den Goblin vor den Thron, die Wachen werfen ihn von der Plattform in die Mine. Der König verlangt „fünf … zehn … zwanzig … vierzig Goldbarren!“, der Spieler soll in seiner Mine arbeiten (Gold- und Silbererz) | Gespräch beendet: Goblinmine offen (`goblin_mine_open`) |
| 118 | Dreißig Bronzebarren (`goblin_gold`) | Kupfer- und Eisenerz in der Goblinmine abbauen, schmelzen, zu Bronze legieren, abgeben | 30 Bronzebarren abgegeben: Goldzahn will eine Krone aus seltener Bronze, das Rezept liegt beim Lavagolem. Reiter Vulkan auf dem Dungeon-Brett: Aschegänge und Schmiede des Lavagolems, die Magmahallen nach dem ersten Sieg in den Aschegängen (`volcano_dungeons_unlocked`, `crown_quest_started`) |
| 119 | Das Rezept der Krone (`crown_recipe`) | Dungeon Vulkan: Die Schmiede des Lavagolems (einmalig, Lv 30). Feuer heilt den Golem, auch sein eigener Lava-Ausbruch | geschafft: Rezept Goblinkrone (`crown_recipe_found`) |
| 120 | Die Goblinkrone (`forge_crown`) | Am Amboss aus 5 Bronzebarren ab Fein schmieden. Die Krone ist ein Helm für Helden: Glück 50 (mehr und seltenere Beute, wirkt einmal pro Gruppe) | Goblinkrone im Inventar |
| 121 | Eine Krone für Goldzahn (`deliver_crown`) | Goldzahn setzt sie auf und ist verzückt. „Dann rate doch mal, wo der Feuerkristall ist“: der Spieler rät richtig (Vulkan, Schatzkammer, Drache), dann ist der König gereizt („Klugscheißer!“), oder sagt „Jetzt sag schon!“. Der König erzählt vom Drachen Ignar, der die Goblins aus ihrer Burg gejagt hat, weil Drachen Gold lieben. Den Schlüssel zur Schatzkammer gießt man nur in der verzauberten Schmiede der Burg; die Gussform gibt es gegen das Versprechen, den Drachen zu vertreiben | versprochen: Schlüssel-Gussform, Gang zur tiefen Mine offen (`goblin_castle_path_open`) |
| 122 | Feierabend (`chapter16_end`) | – | Spieler schläft |

### Teil 2, Kapitel 8: Der Drache

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 123 | Die Goblinburg (`to_goblin_castle`) | Goblinmine » tiefe Mine (Kupfer, Eisen) » Burgvorplatz (dunkel, Lava im Hintergrund, Goblins in der Tiefe). Den Felshaufen vor dem Tor räumt nur eine Bronzespitzhacke (Gussform: Bronze-Werkzeug bei Quentin oder Krummfinger) | Brocken weg (`goblin_castle_gate_cleared`) |
| 124 | Das verschlossene Tor (`goblin_forge_tasks`) | Halle: Das Tor der Schatzkammer zeigt bei Berührung 3 Zeichen (die Magie des Schmieds weckt sie, er wundert sich). Alte Schmiede (Treppe links): Kettenhebel lässt Lava ein, 3 Hebel drehen die Zeichen-Scheiben auf die Zeichen des Tors, Gussform des Goblinkönigs einsetzen, 3 Golderz schmelzen, Schlüssel im Wassertrog abkühlen; ein falscher Schlüssel bricht im Schloss | Tor offen (`goblin_key_forged`) |
| 125 | Die Drachenkammer (`open_treasury`) | Treppe hinab in die dunkle Schatzkammer. Der Spieler schleicht zum Feuerkristall auf dem Goldberg, ein grünes Auge öffnet sich, Ignar erhebt sich aus dem Gold („WELCHE KLEINE MADE …“), hält den Schmied für eine Maus, weigert sich („Lichs. Dämonen. Könige. Alle wollen Steine.“) | Gespräch beendet (`dragon_challenge`) |
| 126 | Ignar, der Glutdrache (`fight_dragon`) | Drachen ansprechen » Helden wählen » Kampf (versteckter Dungeon `dragon_lair`): 3 Lebensbalken (träge, ernst, Raserei), schnelle Heilung, Feuer auf alle, ruft Glutgeister | gewonnen (`dragon_defeated`) |
| 127 | Der Feuerkristall (`dragon_defeated`) | Ignar liegt erschöpft da, der Spieler zieht den Kristall unter ihm hervor. Der Drache erwacht ein letztes Mal (Cutscene `dragon_wake`: er glüht und zittert): „Kein Goblin bekommt davon etwas zurück.“ Er warnt: „Wer neun Steine sammelt, will nichts Gutes. Ganz gleich, wie freundlich er lächelt. … Ich habe nicht vom Lich gesprochen.“ Dann speit er Feuer in die Decke, der Boden reißt auf (Cutscene `castle_collapse`: Wackeln, lavaroter Schleier), der Spieler rennt, die Burg stürzt mit dem Drachen und dem Gold in die Lava | Gespräch beendet: heiliger Feuerkristall (`fire_crystal_owned`, `dragon_gone`, `goblin_castle_fallen`), Überblendung in die tiefe Goblinmine; der Gang zur Burg ist eingestürzt |

### Teil 2, Kapitel 9: Der Feuerkristall

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 128 | Der Feuerkristall für den König (`crystal_to_king`) | Thronsaal: Der König nimmt den Kristall („Warm. So warm. Wie ein Herz, das schlägt.“). Aurelius stürmt herein (`aurelius_at_court`): Er ist dem Lich bis in den Norden gefolgt, der Lich sammelt ein Heer aus Untoten und zieht nach Westen zum Wald der Elfen, um den Windkristall (Kristall der Luft) zu holen. Aurelius geht voraus, um die Elfen zu warnen (`mage_left_for_elves`); der König behält den Feuerkristall („Bei mir ist er sicher.“). Goldzahn trauert in der Goblinhöhle um Burg und Gold | Kristall übergeben (`fire_crystal_given`) |
| 129 | Feierabend (`part2_end`, früher „Fortsetzung folgt“) | Ende von Teil 2, schlafen » Teil 3. Alte Spielstände am früheren Ende `chapter17_end` machen bei `crystal_to_king` weiter (`renamed_steps`, `dragon_gone` setzt `goblin_castle_fallen`) | – |

**Logik-Durchsicht (2026-10-27):** Figuren stehen nicht mehr an zwei Orten gleichzeitig: der König fehlt ab seiner Entführung im Thronsaal (`king_taken`) und während Turnier und Aufbruch nach Eisquell; Faelan (Spitze) und Torgai (Halle der Strömung) fehlen, solange sie vor der Finsterburg sind; Subar steht nach dem Fell nur noch in der Halle; Aurelius' Lichtung (Kompass) ist leer, während er im Thronsaal oder im Heerlager ist; Oma, Lotte und Gustav sind beim Fest und beim Überfall nicht zu Hause bzw. vor der Mine, Gustav auch nicht während des Rundgangs in der Mine. Nach dem Ende von Teil 5 verlassen Aurelius, Faelan und Torgai die Finsterburg, Bertold bleibt mit eigenem Satz. Texte: Lotte ist seit heute früh verschwunden, Holger bringt Holz zum Markt; Lotte kennt das blaue Licht des alten Schmieds nur aus Omas Erzählungen; Erna schaut nach Hildes Tod nach Lotte; der König hat den Bericht des Bürgermeisters gelesen und nennt Hilde Lottes Tante; den Wüstenkompass hat der Spieler selbst geschmiedet; der Erzähler zählt nach der Entführung keine Steine, von denen noch niemand weiß; der König erklärt in der Finsterburg, warum nie „Ort und Stunde“ kamen. Außerdem: Konrad erzählt vom Magier im Wald schon beim Dank nach dem Wiederaufbau (nicht erst beim Gewächshaus); der Kern aus dem Lebensbaum leuchtet grün, der Stein darin glüht braun; Elarion: die neun Steine erneuern das Siegel, wer alle hat, kann das Tor öffnen (es öffnet sich nicht von selbst); Aurelius verriet das genaue Versteck nach seinem Besuch in Sylvaris; Ishra und Zahir passen zur Verhaftung und zu Ssaroks Karte; Brandolf, Ilsa und Gorm wissen, dass es das Turnier wieder gibt; Miete-Tipp 14 Tage; Kupferset mit Beinschutz; die Plünderer leeren die Loot-Kiste, statt sie mitzunehmen.

**Angepasst in Teil 2 (2026-10-25, dritte Runde):** Der König wirkt nicht mehr offensichtlich böse (bittet statt zu handeln, gute Gründe, kein Greifen nach Kristallen; den Feuerkristall will er sicher verwahren, weil die Schmiede schon einmal ausgeraubt wurde); falsche Fährten zeigen auf Lake (Varrik, Ignar). Das Schmiedeturnier wird angeteasert (Nina, Schmiedegasse, König). Die Legende ist verteilt: Thora erwähnt den Dämonenlord als altes Märchen (Kapitel 3), Aurelius nennt die neun Elemente nicht mehr alle auf einmal und sagt, dass niemand weiß, wer den Schlüssel geschmiedet hat.

**Angepasst in Teil 2 (2026-10-25, zweite Runde):** Teil 2 hat jetzt 9 Kapitel (Ein Hauch von Magie und Die verzauberte Gruft eigene Kapitel, neues Kapitel 9 Der Feuerkristall). Bruno stirbt, weil er den Spieler vor dem Feuerball des Lichs rettet. Im Lavaberg gibt es nur Gold und Silber zu farmen; Gold-Gussformen gibt es erst in Teil 3 (`gold_molds_unlocked`). Dungeons eines Reiters kommen nacheinander aufs Brett (`required_dungeon`).

**Angepasst in Teil 2 (2026-10-25):** Die „neun heiligen Steine“ sind die Elementkristalle (Aurelius sagt es jetzt so, die Karte heißt Kristallkarte). Der Thronsaal liegt jetzt oben im Schloss: Schlossgarten » Vorhalle » Treppe; Varrik sitzt sichtbar im Kerker (Westen der Vorhalle) und gibt einen Hinweis auf den König. Der Lichtkristall liegt laut Karte unter Leonheim – das erklärt, warum unter der Stadt die Toten aufstehen. Der König zeigt zu großes Interesse am Feuerkristall (Andeutung, siehe Geheimnisse in `docs/DIALOGE.md`).

## Teil 3

> Umgesetzt 2026-10-25 mit Platzhalter-Grafik (Branch `feature/story-teil-3`). Die Elfenstadt heißt **Sylvaris**: Waldboden » großer Baum mit magischer Plattform » Kronenebene mit Brücken und Gästezimmer » fliegende Inseln an der Spitze. Von jeder Ebene sieht man die Ebene darunter.

### Teil 3, Kapitel 1: Der Kriegsrat

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 130 | Ein Brief vom König (`council_call`) | Morgen nach `part2_end`: Lotte bringt den Brief des Königs (`lotte_letter_council`, danach Tipp `king_letter`), Aurelius ist zurück. Gold-Gussformen gibt es ab jetzt (`gold_molds_unlocked`). Im Thronsaal: König, Aurelius, Lake. Aurelius war in Sylvaris, die Elfen glauben nicht an die Gefahr, das Heer lagert am Waldrand. Lake will nicht helfen („Wann hat je ein Elf einem Menschen geholfen?“), der König: zwei von neun Steinen, „Das ist nicht ihr Problem. Das ist unseres.“ Der Älteste will den Spieler hören | „Auf nach Sylvaris“: Überblendung zum Waldboden (`elf_route_open`) |
| 131 | Sylvaris (`elf_arrival`) | Erzähler am Waldboden; durch die leuchtende Tür in den großen Baum, mit der Plattform zu den Kronen und weiter zur Spitze. Dort: Elarion, Faelan, König, Lake, Aurelius. Der Spieler erzählt vom Dorf (Überblendung). Faelan: die Stadt sei uneinnehmbar, der Älteste will kein Leben riskieren und bittet um Hilfe. Der König richtet das große Schmiedeturnier wieder aus, zu Ehren des legendären Schmieds, alles Geschmiedete geht an die Elfen („Wenn der Wald brennt, fragt das Feuer nicht, wem die Bäume gehören“). Elarion sieht das blaue Licht in den Händen des Spielers („Ich kannte einmal einen Schmied mit solchen Händen“). Dann der Sturmgipfel hinter Sylvaris: Der Greif Sturmschwinge wachte dort über die Pässe, seit das Heer am Waldrand lagert, ist er wild (Faelan: ein schwarzer Splitter in seiner Brust, Aurelius: der Lich macht Wächter zu Dienern), über den Gipfel führt der einzige Pass, den die Windwache nicht sieht; Elarion schickt die Helden des Spielers hinauf (Federn, Felle, Sturmessenz) | Gespräch beendet: Überblendung in die Schmiedegasse, Turnierplatz offen (`tournament_open`), Reiter Sturmgipfel auf dem Dungeon-Brett (Tipp `mountain_dungeons`) |

### Teil 3, Kapitel 2: Das Schmiedeturnier

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 132 | Das große Schmiedeturnier (`tournament_announced`) | Turnierplatz am Ende der Schmiedegasse: Rede des Königs („Der Lich fragt nicht, ob jemand Elf oder Mensch ist“), Regeln. Beim Herold antreten: 4 Runden gegen Gorm (Kupfer), Meister Brandolf (Eisen), Kasim aus dem Süden (Bronze), Ilsa Funkenhand (Silber). Inventar, Lagertruhe, Schmelze, Wassertrog, Esse und Rezepte werden beiseitegelegt, Material aus der Vorratstruhe, Zeitbonus, Abzug für unbekannte Rezepte (`SmithTournament`). Verloren = sofort neu versuchen | Turnier gewonnen (`smith_tournament_won`) |
| 133 | Der Sieger (`tournament_ceremony`) | Ilsa will nächsten Monat Revanche. Der König überreicht die **Meisterhandschuhe**: die Handschuhe des legendären Schmieds von seinem letzten Sieg (+5 % Qualität beim Schmieden). Alles Geschmiedete geht mit 100 Soldaten nach Sylvaris. Ab jetzt jeden Monat ein Turnier | „Auf nach Sylvaris“ (`elf_defenses`, Tipp Monatsturnier) |

### Teil 3, Kapitel 3: Waffen für Sylvaris

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 134 | Zurück in Sylvaris (`elf_return`) | Zelte und Soldaten am Waldboden. **General Hadmar** (führt die hundert Soldaten aus Leonheim) zählt die Brücken: die Turnierstücke tragen Faelans Windwache, für den Rest braucht er mehr. Gutes Metall rettet mehr Leben als viel schlechtes; der Greif auf dem Gipfel lässt die Windwache blind | Gespräch beendet |
| 134a | Waffen für Sylvaris (`elf_armory`) | Beliebig viele Waffen und Rüstungsteile bei Hadmar abgeben (`ElfDefense`, Fenster `ArmoryMenu`). Versteckte Punkte nach Metall und Seltenheit, der Sieg im Horst (Greif Sturmschwinge) zählt mit. „Wie steht es?“: Hadmar sagt grob, wie weit es ist („nicht mal die Ostbrücke“ … „Das reicht“) | „Mehr habe ich nicht“ (bei zu wenig fragt er nach) |

### Teil 3, Kapitel 4: Die Nacht in Sylvaris

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 134b | Ein letzter Besuch (`elf_elder_evening`) | An der Spitze dankt Elarion, Faelan lobt widerwillig seine Axt, Lake verteilt die Wachen, Aurelius traut der Ruhe nicht | Gespräch beendet |
| 135 | Eine Nacht in Sylvaris (`elf_rest`) | Kronenebene: Aurelius schaut Sterne („das blaue Licht ist selten“), Faelan zählt Fackeln („mehr als gestern“), Lake will allein die Ostbrücke halten (falsche Fährte), Nimeriel, ein Soldat. Gästezimmer im Westen | „Schlafen gehen“ am Bett: 1 Uhr nachts |
| 136 | Ein Horn in der Nacht (`elf_attack_wake`) | Horn, der Baum zittert (`elf_attack_started`). Jetzt entscheidet sich, ob die Waffen reichen (`elf_defense_check` » `elf_defense_won`) | Kronenebene betreten |
| 137 | Angriff auf Sylvaris (`elf_attack_canopy`) | Wurzeln wachsen wie Leitern die Stämme herauf (der Lich nutzt den Stein der Erde), Untote, Feuer; Knochenvögel fliegen zur Spitze. **Gewonnen:** Elfen in deinen Rüstungen drängen die Untoten Schild an Schild zurück. Aurelius schickt den Spieler hinauf, Lake ist seit Mitternacht verschwunden | Spitze betreten |
| 138 | Die Spitze (`elf_attack_summit`) | Der Lich steigt aus einer schwarzen Wolke, kennt Elarion von vor tausend Jahren, will die neun Steine für seinen Herrn. Elarions Windschild bricht, Elarion und Faelan fallen. Der Spieler stellt sich vor den Kristall, seine Hände leuchten blau („Er hatte es auch“), er wird weggeschleudert. **Verloren:** Der Kristall schwebt zum Lich („Zwei.“), Aurelius kommt zu spät. **Gewonnen:** Lake taucht auf („Nicht heute.“), Elfen in deinen Rüstungen stürmen herauf, die Windwache schießt, der Lich weicht zurück („Gut geschmiedet, kleiner Schmied. Behaltet ihn. Für eine Weile.“) und flieht ohne Kristall. In beiden Fällen: „Bedankt euch bei eurem Freund“ | Gespräch beendet: Nacht vorbei |

### Teil 3, Kapitel 5: Der Krisenrat

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 139 | Der Krisenrat (`crisis_council`) | **Gewonnen:** Faelan fragt Lake, wo er so lange war; der Lich hat nur die Erde. Der Älteste löst den Windkristall und gibt ihn dem Spieler, der gibt ihn dem König für seine Schatzkammer (der König lächelt). **Sonst wie bisher:** Morgen auf der Spitze: Faelan verdächtigt die Menschen und Lake („Allein. Wie praktisch.“), der König beendet den Streit. Das Heer ist stärker, der Lich hat Erde und Wind. Elarion war vor tausend Jahren dabei: Jedes der vier Völker (Menschen, Elfen, Wasservolk, Halbdämonen) bekam ein Kartenstück mit seinen Steinen. Aufgeschrieben wurde es, weil das Siegel alle tausend Jahre schwach wird und die Steine dann zurück in den Schlüssel müssen; geteilt, damit kein Volk sie allein findet. Es ist bald so weit. Elfenstück: Wind (geraubt) und Blitz (Wüste im Süden, Ort unbekannt). Das Wasservolk hat den Wasserkristall in seiner Stadt und das dritte Kartenstück („Kahn lässt jeden hinein. Er lässt nur nicht jeden wieder hinaus.“). Die Elfen suchen das vierte Stück. Elarion gibt sein Stück dem Spieler, nicht dem König | Kristallkarte mit 2 Stücken (`map_piece_2`), Tipp |
| 140 | Fortsetzung folgt (`part3_end`) | Ende von Teil 3 | – |

Nebenher ab Teil 3: **Monatsturnier** auf dem Turnierplatz (einmal pro Kalendermonat, 500 Gold Startgeld, 1000 Gold Preis), **Kutsche nach Sylvaris** am Westende der Einkaufsstraße (`elf_route_open`).

## Teil 4

> Umgesetzt 2026-10-27 mit Platzhalter-Grafik (Branch `feature/story-teil-4`). Die Stadt des Wasservolks heißt **Eisquell**: Stege und Plattformen auf Pfählen über dem Meer, im Norden eine Mauer aus Eis mit Wasserfällen, Häuser aus Eis und Treibholz, Halle der Strömung (Kahn), Gezeitenarena, Kaserne, Händler, Teleporter. Dialoge mit agy (Gemini) entworfen und überarbeitet.

### Teil 4, Kapitel 1: Die Stadt im Eis

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 141 | Aufbruch nach Nordosten (`water_departure`) | Morgen nach `part3_end`: Lotte bringt die Nachricht des Königs, wo der Spieler auch geschlafen hat (`lotte_letter_water`, danach Tipp `water_morning`). Schlossgarten: König, Lake, Aurelius bei der Kutsche. Aurelius kommt nicht mit, er will auf seiner Lichtung herausfinden, was das blaue Licht ist | Gespräch mit dem König: Kutschfahrt nach Eisquell (`water_route_open`) |
| 142 | Die Stadt im Eis (`water_arrival`) | Erzähler bei der Ankunft. Vor der Halle der Strömung hält **Subar** (Kahns rechte Hand) die Gruppe auf: Kahn hört niemanden an, der nur Worte bringt. Beweis: das Fell von **Frostmähne** aus der Tiefen Grotte. Lake braust auf, der König bleibt freundlich | Gespräch: Reiter Eisquell auf dem Dungeon-Brett (`water_dungeons_unlocked`, Tipp) |
| 143 | Jagd auf Frostmähne (`frost_hunt`) | 4 Dungeons nacheinander: Brandungsküste (Lv 33), Gezeitenhöhle (35), Kristallgrotte (37), Tiefe Grotte (38, einmalig, Boss Frostmähne mit 2 Lebensbalken). Monster: Wasser-Immunität, Blitz-Schwäche | Sieg in der Tiefen Grotte (`frost_mane_slain`, das Fell liegt in der Loot-Kiste) |
| 144 | Beweis der Stärke (`frost_proof`) | Subar nimmt das Fell, öffnet die Halle (`kahn_hall_open`) | Fell abgegeben |

### Teil 4, Kapitel 2: Das Turnier der Gezeiten

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 145 | Vor dem Eisthron (`kahn_audience`) | **Kahn** nennt die Gruppe Schwächlinge („Ein König, der Felle schicken lässt.“), erzählt von seiner Jugend (Vater ermordet, verstoßen), will erst reden, wenn sie sein Turnier gewinnen. Lake lehnt ab: Er kämpft nur, wenn es nötig ist, nicht für Beifall. Der König stellt sich hinter ihn, der Spieler meldet einen Helden an. „Das Gesetz der Strömung gibt jedem eine zweite Welle.“ | Arena offen (`kahn_tournament_open`, Tipp) |
| 146 | Das Turnier der Gezeiten (`hero_tournament`) | Gezeitenarena, Ausrufer: 16 Helden, einer gegen einen, 4 Runden; Kahns Sohn **Torgai** kommt im Halbfinale. Verloren = neu anmelden (`HeroTournament`) | Finale gewonnen (`hero_tournament_won`) |
| 147 | Sieger der Arena (`tournament_kahn`) | Torgai: „Ich habe dich enttäuscht, Vater.“ Kahn ist stolz: Ein Sieg lehrt wenig, eine Niederlage alles. Kahn will reden | Gespräch |
| 148 | Rat in der Strömung (`kahn_council`) | König und Spieler erzählen vom Lich und den Steinen. Kahn: „Nehmt ihn.“ Er gibt dem König den Wasserkristall und dem Spieler das Kartenstück des Wasservolks („Dein Held hat gekämpft, nicht dein König.“): Wasser in Eisquell, Eis in der Eismauer (den behält Kahn, er hält die Mauer). Der König schickt den Spieler in die Wüste und bringt mit Lake den Wasserkristall nach Leonheim. Die Arena bleibt offen | Kartenstück 3 (`map_piece_3`), Wüste offen (`desert_open`) |

### Teil 4, Kapitel 3: Gefangen im Sand

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 149 | Weg in den Wüstensand (`to_desert`) | Südweg » Wüste. Wer sich verläuft, bekommt die Neben-Aufgaben zu Aurelius und dem Kompass (wie bisher) | Sahrim betreten |
| 150 | Unter Verdacht (`desert_arrest`) | Zwei Echsenwachen halten den Spieler für einen Spion des Lichs (eine Karawane wurde überfallen, Fremde fragten nach dem Sturm, und er trägt einen Kompass, den die Echsen nur Freunden schenken) | Gespräch: die Nacht im Käfig (`sleep_at` Käfig) |
| 151 | Hinter Gittern (`desert_cage`) | Morgen in der Zelle am Südtor. **Ulrich**, der erste Kunde, kommt mit seinem Kamel vorbei (er ist jetzt Händler, mit dem Kupferschwert hat er Banditen vertrieben, „die dachten, es wäre ein goldenes Schwert“) und bürgt beim Fürsten. Seit 2026-11-06: Oma Hilde hatte ihm den Spieler für 1200 Gold empfohlen, der Spieler hat nur `{first_order_gold}` bekommen. Beim nächsten Treffen (Markthalle Sahrim, `ulrich_hilde`) fragt Ulrich nach Hilde und erfährt von ihrem Tod. Überblendung, Mittag: **Fürst Ssarok** mit zwei Speerkriegern lässt den Spieler frei, entschuldigt sich, hört alles. Er glaubt, der Lich sammelt für jemanden („Ein Toter will nichts mehr.“), und fragt, wer wusste, wo der Windkristall lag – nennt aber keinen Namen. Er erzählt vom Sturmtempel, den nur ein Schmied öffnen kann, und gibt die Karte der Sturmpfade **Weltkarte (2026-10-28):** Ssarok gibt mit der Karte der Sturmpfade auch das Kartenstück des Echsenvolks (Wüste, `map_piece_4`). | Gespräch: zurück nach Sahrim |

### Teil 4, Kapitel 4: Der Sturmtempel

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 152 | Pfad durch das Gewitter (`storm_temple`) | Sahrim » Säulen » S S O S S W N (nur mit der Karte, `storm_map_owned`; Kompass und Sandkarte zeigen den Weg) | Tempel betreten |
| 153 | Drei geschmiedete Siegel (`temple_seals`) | Vorhof mit alter Schmiede (Schmelze, Gussofen, Amboss, Wassertrog, Werkbank). Wandbild: „Wo der Morgen erwacht, ruht die Sonne. Über der Mitte der Nacht wacht der Mond. Und aus dem Land, in dem der Tag stirbt, kommt der Sturm.“ Siegel am Amboss: Sonne (2 Gold), Mond (2 Silber), Sturm (2 Kupfer). Richtig: Sturm links (Westen), Mond Mitte, Sonne rechts (Osten); falsch = sie springen heraus | Tor offen (`temple_gate_open`) |
| 154 | Klang des Donners (`temple_pillars`) | Halle mit 4 Säulen verschiedener Höhe. Wandbild: Der Blitz wählt zuerst das Höchste. Säulen von der höchsten zur niedrigsten anschlagen (3, 1, 4, 2) | Steinplatte weg (`temple_pillars_done`) |
| 155 | Herz des Gewitters (`temple_crystal`) | Innerste Kammer: der Kristall hinter Blitzen. Wandbild: dem Blitz einen Weg in die Erde geben. Blitzableiter (3 Kupfer: Gussofen, Amboss, Wassertrog) in den Sockel, die Blitze verschwinden. Beim Nehmen leuchten die Hände blau, eine Vision: ein Mann am Amboss mit denselben Händen, der etwas sagen will | Blitzkristall genommen (`lightning_crystal_owned`) |

### Teil 4, Kapitel 5: Der leere Thron

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 156 | Rückkehr nach Sahrim (`crystal_to_lord`) | Ssarok und Ishra: Gib den Kristall niemandem, dem du nicht ganz vertraust. Das Echsenvolk ist jetzt Freund | Gespräch |
| 157 | Nachricht für den König (`return_leonheim`) | Thronsaal: Der Thron ist leer. Lake kniet davor: Der Lich kam in der Nacht, die Wachen schliefen, der König und Feuer- und Wasserkristall sind fort. Der König hatte Lake selbst zur Stadtmauer geschickt. Aurelius zeigt einen schwarzen Brief: „Der König gegen den Blitz. Der Schmied soll ihn allein bringen – Ort und Stunde folgen.“ Lake schwört, ihn zurückzuholen | Gespräch (`king_taken`) |
| 158 | Der leere Thron (`part4_end`) | Ende von Teil 4 | – |

Nebenher ab Teil 4: **Gezeitenarena** in Eisquell (Heldenturnier jederzeit neu, später weitere Kämpfe), **Kutsche nach Eisquell** im Schlossgarten (links), Teleporter Eisquell.

## Teil 5

> Umgesetzt 2026-10-27 mit Platzhalter-Grafik (Branch `feature/story-teil-5`). Neue Orte: der Sumpf östlich des Dorfes (Dorftor » Osten, der alte Ostweg), das Heerlager vor der **Finsterburg**, drei Schleich-Gebiete, der Torhof, der Thronsaal. Dialoge mit agy (Gemini) entworfen und überarbeitet.

### Teil 5, Kapitel 1: Ohne König

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 159 | Rat im Thronsaal (`rescue_council`) | Morgen nach `part4_end`. Lake will losreiten, Aurelius bremst ihn („Zorn ist ein schlechter Schmied.“). Plan: die Verbündeten fragen. Lake hält Leonheim, Aurelius geht zu seinen Büchern. Lake: „Ohne den König habe ich hier niemanden.“ | Gespräch |
| 160 | Augen und Ohren (`ask_allies`) | Goldzahn (will Gold für eine Nicht-Auskunft, „wo nichts glänzt und alles stinkt“), Elarion und Faelan (der Lich kam vor tausend Jahren aus dem Osten, Faelan stichelt gegen Lake), Kahn und Torgai (der Tote kommt nicht übers Wasser; Krieger versprochen) | alle drei gefragt (`asked_goblin`, `asked_elder`, `asked_kahn`) |
| 161 | Rat in der Wüste (`ask_ssarok`) | Ssarok stellt zwei Fragen ohne Namen (warum wachte keine Wache auf, wer schickte den treuesten Wächter fort) und schickt den Spieler zu seiner Großtante, der Hechse Muhme Grisla | Ostweg offen (`swamp_road_open`) |

### Teil 5, Kapitel 2: Die Sumpfhechse

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 162 | Weg in den Nebel (`to_swamp`) | Dorftor » Osten in den Sumpf (Nebel, Irrlichter, Stelzenhütte) | Sumpf betreten |
| 163 | Die alte Hechse (`meet_witch`) | „Hexe?“ „Hechse!“ Der Lich hat vor Wochen den Giftkristall aus dem Herz des Sumpfes gerissen. Grisla sieht mit dem Trank der tausend Augen, wohin er ging | Sumpf-Dungeons offen, Rezept (`swamp_dungeons_unlocked`) |
| 164 | Trank der tausend Augen (`witch_potion`) | Nebelmoor (Lv 40, Irrlichter verschleiern sich, nur Flächenangriffe treffen sie, Königin ruft neue), Hydrateich (42, Hydra mit 3 Lebensbalken, Moorschleime teilen sich, Feuer gut, Gift heilt), Knochensumpf (44, Moorleichen heilen sich, Moormutter als Zwischenboss, Nebelfürst verhüllt sich hinter seinen Geistern); je eine Zutat; Trank am Zaubertisch | Trank im Inventar |
| 165 | Blick durch den Schleier (`witch_vision`) | Vision: die Finsterburg im Land der Halbdämonen, der König in Ketten („Wie einer, der nur geduldig wartet.“). Grisla gibt den Knüppeldamm frei; Boten an alle Verbündeten **Weltkarte (2026-10-28):** Grisla malt nach der Vision ein neues Kartenstück: Sumpf und Land der Halbdämonen (`map_piece_5`); auf der alten Karte fehlte dieses Land. | Knüppeldamm offen (`dark_road_open`) |

### Teil 5, Kapitel 3: Vor der Finsterburg

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 166 | Marsch nach Osten (`to_camp`) | Sumpf » Osten ins Heerlager: Banner aller Völker | Lager betreten |
| 167 | Kriegsrat (`camp_council`) | Aurelius, Lake, Faelan, Torgai, Echsenhauptmann, Hauptmann Bertold. Das Tor öffnet sich nur mit dem Hebel im Torhaus; Weg hinein über den Westgraben. Lake will gehen, Faelan misstraut ihm, Aurelius schickt den Spieler (Ketten, Winden, Hebel) **Umbau 2026-10-28:** Nach Lakes Antwort an Faelan **entscheidet der Spieler**: „Ich bürge für Lake.“ (`vouched_for_lake`) oder „Faelan hat nicht ganz unrecht.“ (`doubted_lake`). Lake erwähnt es am Lagerfeuer und bei seiner Erlösung am Altar (Zeilen mit `if_flag`). | Gespräch |
| 168 | Gespräch am Lagerfeuer (`lake_talk`) | Lake erzählt: Findelkind aus der Gosse, der König gab ihm Namen, Schwert, Glauben. Schuld, Einsamkeit. Der Spieler bietet ihm Freundschaft an. „Ich würde alles tun, was er von mir verlangt. Alles.“ Rat fürs Schleichen | Gespräch (Tipp Schleichen) |

### Teil 5, Kapitel 4: Der Sturm auf die Finsterburg

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 169 | Schatten in den Gängen (`sneak_in`) | **Umbau 2026-10-29:** Der Kriegsrat schickt den Schmied außen um die Burg herum zur Westflanke: Die alte Pforte dort haben dieselben Meister gebaut wie den Sturmtempel, nur ein Schmied kann sie öffnen. Drei Gebiete: Felsband an der Westflanke bis zur Pforte (Schloss aus drei Stellringen), Gänge, Torhaus mit Winde und Hebel. Er zieht den Hebel und zerbricht die Sperrklinke; die Wachen rennen zum Tor, zwei zerren an der klemmenden Winde | Hebel gezogen (`fortress_gate_open`) |
| 169b | Raus aus dem Torhaus (`sneak_out`) | **Neu:** hinter dem Rücken der zwei an der Winde hinaus, durch die Kaserne (Wachen drehen sich oder schauen abwechselnd in zwei Richtungen) und den Ringgang (zwei Wachen laufen hintereinander im Kreis, man folgt einer im gleichen Takt) | Torhof erreicht » `gate_battle` |
| 170 | Kampf um den Bergfried (`gate_battle`) | Torhof: Schlacht, Faelan rettet Lake (Rücken an Rücken). Torgai führt die Speerkämpfer, die Kahn bei „Augen und Ohren“ versprochen hat (sagt er im Heerlager und im Hof). **Seit 2026-11-08:** Vor dem Tor zum Bergfried steht der Knochengeneral, man spricht ihn an (einmal Worte, danach E) und schickt die Helden in „Die Finsterburg: Der Bergfried“ (Lv 45, Boss Knochengeneral Varg, 2 Lebensbalken) | Sieg (`keep_taken`) |

### Teil 5, Kapitel 5: Der dunkle Ritter

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 171 | Hinauf zum Thronsaal (`throne_hall`) | Lake besiegt den Lich, der bettelt („Du hast es versprochen!“). Der König: „Töte ihn.“ Lake zögert (man richtet keinen Wehrlosen), der König drängt, Lake köpft den Lich. Die Ketten waren nie verschlossen: Der König lacht, die Finsterburg ist seine, der Lich war sein Diener, Aurelius hatte ihm den Windkristall verraten, die Entführung war ein Spiel für den Blitz. Er nimmt dem Spieler den Blitzkristall (8 Steine, nur Eis fehlt), deutet an, dass der legendäre Schmied den Schlüssel geschmiedet hat. Er bricht Lake: keiner wird ihm mehr glauben, „Das Licht war immer ich.“ Lake kniet, der Dunkelkristall färbt seine Rüstung schwarz: „Erhebe dich, mein dunkler Ritter.“ Vorher flüstert der Lich dem Spieler zu: „Glutträger ... er lebt. Er schmiedet. Unter ... diesen Mauern ...“ (`lich_whispered`). Seit 2026-10-28: Der König lässt Lake den Spieler angreifen, Aurelius fängt den Hieb mit einem Schild aus Sternenlicht ab, begreift, dass er selbst den Verrat ermöglicht hat, schickt Faelan mit dem Heer hinaus und reißt den Spieler mit einem Licht aus der Burg (`fled_to_forest`) **Umbau 2026-10-28:** Aurelius' Licht wirft beide nur in den brennenden Torhof, Aurelius bricht zusammen (`carrying_mage`). **Umbau 2026-11-08:** Kein Sprung mehr: Das Licht des zerbrechenden Schilds blendet Lake, der Spieler trägt Aurelius aus dem Saal, der König schickt Lake hinterher. Unten im Torhof versteckt sich der Spieler, Lake stürmt aus dem Bergfried und rennt zum Haupttor (`escape_start`). | Gespräch: die Nacht endet auf Aurelius' Lichtung (`sleep_at`, Spawnpunkt `AureliusClearing` im tiefen Wald) |
| 171b | Raus aus der Burg (`carry_mage`) | **Neu:** Der Spieler trägt Aurelius durch den Torhof (`fortress_escape.tscn`, Boden des Torhofs aus Teil 5 in Gegenrichtung, brennend, 4 Wachen, Aurelius läuft als Begleiter mit). Gesehen = zurück an den Anfang. An der Ausfallpforte unten links wartet Faelan (`escape_faelan`, ohne Pferde), nach dem Gespräch geht er voraus durch die Pforte, der Spieler folgt. Im Westgraben (`fortress_moat_escape.tscn`) laufen Faelan und der Spieler von selbst zur Mitte, dort kommen 8 Wachen aus der Pforte und 6 vom Ostende des Grabens und umzingeln die Gruppe („Ergebt euch!“), Aurelius verbraucht seinen allerletzten Funken und reißt alle mit weißem Licht auf seine Lichtung (`escape_out`; seit 2026-11-09 so, vorher traf man Faelan erst im Graben) | Gespräch beendet: `escaped_castle`, `fled_to_forest`, Nacht endet auf Aurelius' Lichtung |
| 172 | Der neunte Stein (`part5_end`) | Ende von Teil 5; nach Aurelius' Sprung aus dem Westgraben, im Wald reitet Faelan beim Aufwachen zurück zum Heer; wird sofort übersprungen, weil die Nacht schon vorbei ist (`sleep` » `forest_wake`) | – |

## Teil 6

> Umgesetzt 2026-10-28 mit Platzhalter-Grafik (Branch `feature/story-teil-6`, zusammen mit Teil 7 und 8). Plan und Hintergründe: `docs/STORY_PLAN_6-8.md`. Neuer Ort: die Mauerkrone der Eismauer (Eistreppe in Eisquell).

### Teil 6, Kapitel 1: Asche und Sternenlicht

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 173 | Weißes Licht (`forest_wake`) | Morgen nach der Flucht: Der Spieler erwacht auf Aurelius' Lichtung im tiefen Wald. Aurelius liegt erschöpft im Gras, sein Stab ist zerbrochen. Er braucht einen Sternentau **Umbau 2026-10-28:** Aurelius weiß, dass der Spieler ihn getragen hat. | Gespräch: Rezept Sternentau |
| 174 | Ein Trank für den Zauberer (`brew_tonic`) | Sternentau am Zaubertisch: Mondlilie, Hanf, Kamille, Phiole (Tipp `starlight_tonic`) | Sternentau im Inventar |
| 175 | Sternentau (`tonic_for_mage`) | Aurelius trinkt, steht auf, aber seine Magie ist fort. Faelan kommt auf die Lichtung: Das Heer ist draußen (Torgai nach Eisquell, Bertold nach Leonheim). Steckbrief: Der Spieler und Aurelius hätten den Lich befreit und den König verraten, 10.000 Gold. Das Schloss ist gesperrt (`castle_closed`, Tür im Schlossgarten), die Stadt bleibt offen | Gespräch |

### Teil 6, Kapitel 2: Die Glut in deinen Händen

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 176 | Die Glut in deinen Händen (`glow_lesson`) | Aurelius erklärt die **Siegelglut** (der erste Schmied, Sternenstahl, erwacht in einem Schmied pro Generation). Kompass-Probe: In seiner Hand zeigt er nur nach Sahrim, in der des Spielers schwenkt er. Der Spieler erzählt vom Flüstern des Lichs und nennt den Namen **Meister Halvard**; Aurelius: die Klinge aus Sylvaris war neu. Der König braucht den Spieler für den Eiskristall. Seit dem Umbau: zuerst nach Hause, Werkzeug holen und nach Lotte sehen | Gespräch (`glow_explained`, Tipp `return_home`) |

### Teil 6, Kapitel 3: Unter Freunden

> Umbau 2026-10-28: ein Teil ganz im Dorf, ohne Dungeon. Das Dorf schützt den Spieler, der Spieler macht den Plan.

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 177a | Nach Hause (`return_home`) | Vom Wald zurück ins Dorf | Dorfplatz betreten |
| 177b | Ritter im Dorf (`village_occupied`) | Zwei Finsterritter am Brunnen, dein Steckbrief, Drohung: wer ihn versteckt, dessen Haus brennt. Lotte lügt für den Spieler („Der schuldet mir noch Schuhe.“) und führt ihn zu Omas Haus | Gespräch (`knights_in_village`, Überblendung in Omas Haus) |
| 177c | Bei Lotte (`lotte_hideout`) | Lotte, Gustav und Nina in Omas Haus. Die Schmiede ist versiegelt. **Der Spieler macht den Plan:** eine falsche Spur nach Süden | Gespräch |
| 177d | Eine falsche Spur (`village_ruse`) | Gustav bekommt 5 Kohle (Rauch in der alten Mine), Nina 3 Eisenbarren (Schaufenster „Restposten“), Lotte ein Schwert mit dem Zeichen des Spielers (legt es am Südweg ab). Geschmiedet wird nachts in der versiegelten Schmiede | `ruse_gustav`, `ruse_nina`, `ruse_sword` |
| 177e | Abwarten (`village_night`) | – | Schlafen |
| 177f | Die Ritter ziehen ab (`village_morning`) | Lotte vor der Schmiede: Die Ritter sind nach Süden geritten. „Kommst du wieder?“ – „Ihr seid mein Zuhause.“ Aurelius hat einen Vogel geschickt | Gespräch (`village_freed`, Tipp `eisquell_again`) |
| 177 | Zurück nach Eisquell (`to_eisquell_again`) | Reise nach Eisquell zu Kahn (Kutsche im Schlossgarten oder Teleporter) | Eisquell betreten |

### Teil 6, Kapitel 4: Das Gesetz der Strömung

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 178 | Eine neue Klinge (`eisquell_blade`) | Eisquell: Torgai zeigt eine frische Klinge mit Halvards Zeichen (er lebt). Subar hält dem Spieler den Steckbrief vor. **Umbau:** Torgai bürgt nicht mehr, Subar verlangt eine Probe | Gespräch: Rezept Harpunenspitze |
| 178b | Die Probe (`subar_test`) | **Neu:** Harpunenspitze gießen und schmieden (1 Silber-, 1 Eisenbarren) für Subar; der Stahl glimmt blau, das kann kein Verräter fälschen (`subar_trusts`). Gussform `mold_harpoon_tip` (Gussofen » Zubehör » Eisquell, 1 Silber + 1 Eisen) » heißer Rohling » Amboss » Wassertrog wie jedes Teil; Gussform kommt mit Subars Auftrag, beim Start des Schritts und über recipe_actions (alte Spielstände); Stationen leuchten der Reihe nach golden, mit kalter Spitze Subar. Ein Speer zählt nicht (sagt Subar auch) | Abgabe bei Subar |
| 179 | Das Gesetz der Strömung (`kahn_refuses`) | Kahn will keine Hilfe, weiß aber nicht, wo der Kristall liegt („Wo das Eis für die glühende Hand singt“). Nachts brennt der Hafen | Gespräch: 23 Uhr, Eisquell (`harbor_attacked`) |
| 180 | Feuer im Hafen (`harbor_attack`) | Subar: Finsterritter am Kai, Lake auf einem Eisschiff. Dungeon „Eisquell in Flammen“ (Lv 46, einmalig) | Sieg (`harbor_saved`) |
| 181 | Die Strömung dreht sich (`kahn_decides`) | Kahn hilft und geht mit Torgai und Subar mit | Gespräch (`ice_wall_open`) |

### Teil 6, Kapitel 5: Wo das Eis singt

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 182 | Der Aufstieg (`climb_wall`) | Reiter Eismauer: nur **Der Windbruch** (49) ist Pflicht; Die gefrorenen Fälle (47) und Die Eisstege (48) sind seit dem Umbau freiwillig (Silber, Gold, Edelsteine) | Windbruch geschafft |
| 183 | Wo das Eis singt (`wall_crown`) | Eistreppe links neben der Halle » Mauerkrone (`IceWall`): 5 Eissäulen in der Reihenfolge von Torgais Wiegenlied (Möwe, Wal, Robbe, Fisch, Welle), 3 Silberspiegel (Amboss, 2 Silber) in die Sockel nach dem Eisrelief | `ice_song_done` und `ice_beam_on` |

### Teil 6, Kapitel 6: Der Kampf um den Eiskristall

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 184 | Die singende Wand (`singing_wall`) | Die Wand singt, der Spieler zieht den Eiskristall heraus. König und Lake kommen aus einem Schatten | Gespräch |
| 185 | Kampf auf der Mauerkrone (`wall_battle`) | Kriegstisch: „Die Mauerkrone: Lake“ (Lv 50, Lake mit 3 Lebensbalken) | Sieg |
| 186 | Neun (`wall_aftermath`) | Der König bricht das Eis, Subar stößt den Spieler zurück und rutscht über die Kante, der Eiskristall rollt auf den Riss zu. **Entscheidung:** „Subar packen!“ (`subar_saved`: Subar steht, leicht verletzt, kommt später mit zum Altar) oder „Den Kristall packen!“ (`subar_wounded`: Torgai fängt Subar mit der Harpunenleine, Arm gebrochen). Der König nimmt den Kristall in beiden Fällen: „Neun.“ Kahn schwört Bündnis | Gespräch |
| 187 | Neun Steine (`part6_end`) | Ende von Teil 6 | Schlafen |

## Teil 7

> Umgesetzt 2026-10-28 mit Platzhalter-Grafik. Neue Orte: Finsterstadt (seit 2026-11-11 per Kutsche zum Südtor, vorher Heerlager » Osten), Versteck unter der Färberei, Außenmauer, Wachgang, Kerkertrakt, Kerkerschmiede.

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 188 | Ein Brief aus Sylvaris (`finster_start`) | **Seit 2026-11-11:** Lotte bringt einen Brief von Aurelius (ein Elf hat ihn gebracht). Aurelius wartet in Sylvaris am Waldboden bei der Kutsche: Halvard dreht den Schlüssel; Faelans Späher sahen einen Gefangenenzug mit Halvard durchs Südtor der Finsterstadt; der Spieler soll allein mit Jupps Kutsche hin (vorher: Aurelius im Heerlager) | Gespräch |
| 189 | Die Stadt im Schatten (`to_finster_city`) | Kutsche von Sylvaris » Finsterstadt (3 Tage) | Südtor erreichen |
| 189a | Vor dem Südtor (`finster_gate`) | Jupp hält vor der Stadtmauer, Finsterwachen laufen Streife, Steckbriefe am Tor. Durchs Tor nach Norden zum Platz | Finsterstadt betreten |
| 190 | Gesucht (`finster_wanted`) | Frei herumlaufen, Steckbriefe (Nyra und der Spieler). Sieht eine Wache den Spieler oder betritt er den Platz, startet die Verfolgung von selbst (`FinsterChase`): er rennt los, eine Hand zieht ihn hinter einen Vorhang, die Wachen rennen vorbei. Gespräch mit der Gestalt im Kapuzenmantel, sie heißt Nyra **Umbau 2026-10-28:** Der Spieler versteckt sich selbst hinter dem Vorhang und rettet dann Nyra: Zwei Wachen haben sie in der Gasse gestellt, er tritt den Keil unter einem Gerüst voller Färberfässer weg (`nyra_saved`). | Gespräch: Überblendung ins Versteck |
| 191 | Unter der Färberei (`resistance_hideout`) | Nyra und Corvin, der Plan: Dietrich aus Silber, 2 Kletterhaken, Wachplan | Gespräch (`resistance_joined`, Reiter Finsterstadt) |
| 192 | Werkzeug für den Einbruch (`resistance_prep`) | Dietrich und Haken am Amboss. **Umbau:** Den Wachplan klaut der Spieler selbst aus der Wachstube (Haus nördlich des Platzes, `finster_guardhouse.tscn`, Schleichen bis zum Tisch des Hauptmanns, `roster_stolen`). Aschegassen (51), Schattenkanäle (52), Wachtürme (53, Mordrek) sind freiwillig | Abgabe bei Nyra |
| 193 | Zurück in die Finsterburg (`sneak_castle`) | Nordende der Stadt » Außenmauer » Wachgang » Kerkertrakt (Schleichen wie in Teil 5) | Kerkerschmiede betreten |
| 194 | Die Kerkerschmiede (`free_halvard`) | Halvard am Amboss, Hände mit Sternenstahl gefesselt, erkennt den Spieler und Nyra; legt die gefesselten Hände auf den Amboss | Gespräch |
| 195 | Sternenstahl (`break_shackle`) | E am Amboss: 3 Schläge, alle grün = Fessel springt auf; daneben = Halvard tadelt, neuer Versuch; nach dem 3. Fehlversuch bricht sie von selbst („Huh.“ / „Hmpf.“) | Event am Amboss |
| 196 | Frei (`halvard_freed`) | Halvard erzählt von der manipulierten Fassung und dem Zauber des Königs. Lake in der Tür, das Licht trifft ihn, er tritt zur Seite | Gespräch: Überblendung ins Versteck |
| 197 | Die rechtmäßige Erbin (`princess_reveal`) | Corvin kniet: Nyra ist die Tochter des ermordeten Fürsten. Die Halbdämonen treten dem Bündnis bei | Gespräch |
| 198 | Fünf Völker (`part7_end`) | Ende von Teil 7 | Schlafen |

## Teil 8

> Umgesetzt 2026-10-28 mit Platzhalter-Grafik. Neuer Ort: der Altar der Neun (Finsterstadt » Osten).

| # | Schritt (id) | Was passiert | Endet wenn |
|---|---|---|---|
| 199 | Der große Rat (`grand_council`) | Lotte bringt Aurelius' Brief (`lotte_letter_grand_council`). Spitze von Sylvaris am Ratstisch (seit 2026-11-12, vorher Marktplatz im Dorf). **Umbau 2026-11-12 (2):** Zuerst sind nur die Elfen (Elarion, Faelan), Aurelius, Halvard und Nyra (seit 2026-11-13) da; Faelan spottet über den „Rat“, Nyra besteht auf „Fürstin“. Kahn kommt mit Torgai und Subar über die Steinbrücke (Subar mit Armschlinge, wenn `subar_saved` fehlt), sie planen mit Faelan an der Karte; dann Ssarok mit zwei Speerkriegern. Nyra: die Finsterstadt steht bereit; Aurelius: Bertold sammelt Leonheims Soldaten im Heerlager, Goldzahn per Bote. Halvard verrät den Plan des Königs (Tor des Dämonenlords öffnen, aus Angst vor dem Tod; Altar der Neun östlich der Finsterstadt, die Finsterburg bewacht den Weg; die Fassung ist der Schlüssel, ein Spalt genügt). **Entscheidung** (seit 2026-10-28): Hauptstoß Faelan (`council_lead_elves`), Nyra (`council_lead_finster`) oder Bertold (`council_lead_leon`); Kahn, Halvard bzw. Aurelius antworten für die Abwesenden. | Gespräch (`star_crater_open`) |
| 200 | Der Schmied des Bündnisses (`alliance_forge`) | Aurelius (seit 2026-11-12: fertige Waffen, je mindestens R4, passend zu den Figuren): Gold-Zweihandaxt (Kahn), 2 Bronzespeere (Torgai, Subar), Silberschwert (Faelan), 2 Kupferspeere und Golddolch (Ssarok und seine Speerkrieger), 2 Bronzedolche (Nyra), Silberhammer (Bertold), Goldhelm (Goldzahn); Griff/Schaft/Leder beliebig. Halvard: 3 Sternenstahl (Krater der fallenden Sterne, Lv 54, Sternenerz » Schmelze) | `allies_armed` und `starsteel_ready` |
| 201 | Zum Altar der Neun (`to_altar`) | Finsterstadt (Aufstand, die Wachen sind fort) » Osten | Altar betreten |
| 202 | Das Tor öffnet sich (`gate_opens`) | Der König dreht den Schlüssel, das Tor öffnet sich einen Spalt, die Völker verteilen sich **Umbau 2026-10-28:** Die gewählte Spitze ruft ihren Schlachtruf. | Gespräch |
| 203–207 | Die Schlacht am Altar (`altar_north`, `altar_east`, `altar_south`, `altar_west`, `altar_lake`) | Kriegstisch: Nordtreppe (55), Ostgrat (56), Südtor (57), Westhang (58), dann Lake (59) | je ein Sieg |
| 208 | Licht in der Dunkelheit (`lake_awakens`) | Der Spieler legt die glühenden Hände auf Lakes Herz, Lake erwacht aus dem Bann und verbannt die Dunkelheit | Gespräch (`lake_redeemed`) |
| 209 | Die verzauberte Fassung (`final_forge`) | Die Glut bricht den Zauber, Halvards Riss lässt die Fassung zerspringen, der König wird ins Tor gezogen | Gespräch: Rezept „Die wahre Fassung“ |
| 210 | Die wahre Fassung (`forge_true_setting`) | Am Amboss in der Mitte des Altars: 3 Sternenstahl | Fassung im Inventar |
| 211 | Tausend Jahre (`seal_the_gate`) | Neun Steine, das Tor schließt sich, Halvard verliert seine Glut, Lake bleibt als Wächter, Epilog **Umbau 2026-10-28:** Der Epilog hat eine Zeile für die gewählte Spitze und eine für den geretteten Subar. | Gespräch: Abspann (`story_complete`, `castle_reopened`) |
| 211a | Nach Hause (`ending_night`) | **Abspann** (seit 2026-10-30, story.json `ending`): dunkler Bildschirm, was aus allen wurde, „Die Geschichte von {name}“ mit Zahlen (Tage, Geschmiedet, Aufträge, Helden, Dungeons, Gold), „Danke fürs Spielen“. Danach eine Nacht | Abspann vorbei (oder Spieler schläft) |
| 211b | Ein neuer Morgen (`ending_morning`) | Aufwachen im eigenen Bett, der Erzähler: kein Traum, die Hände leuchten noch, unten hämmert jemand. In der Werkstatt steht Lotte auf einer Kiste am Amboss (ein Schwert für Brunos Grab), Halvard daneben: Die Schmiede gehört dem Spieler, Lotte wird seine Schülerin | Gespräch mit Halvard |
| 212 | Der Schmied der Neun (`story_end`) | Ende der Geschichte, Tipp „Ende“, das Spiel geht frei weiter. Halvard steht vor der Schmiede | – |

Angepasst in Teil 3 (2026-10-28): Im Krisenrat wirft Faelan die Klinge eines Untoten hin, „zu gut für Tote“; sie trägt das Zeichen der Meisterhandschuhe. Aurelius vermutet alte Klingen aus der ausgeräumten Schmiede (`master_mark_seen`).

### Nebenher (nicht an Kapitel gebunden)

| Was | Wann | Technik |
|---|---|---|
| Nina schenkt einen Kalender und erzählt vom Reisenden | sobald in ihrem Laden 200 Gold umgesetzt wurden („!“ über Nina) | Nebendialog `nina_calendar` (story.json `side_dialogues`), Flags `nina_calendar_ready` → `calendar_owned`, `traveler_told` |
| Kalender im Schlafzimmer | nach Ninas Geschenk | anklicken oder E: Monat mit Vermerken (Miete, Fristen, Reisender), vorwärts blättern |
| Rashid, der Reisende | jeden Sonntag am Dorftor, an anderen Tagen in Sahrim (außer Samstag und Montag) | 1–3 zufällige R4-Gussformen (Silber/Gold) für je 450 Gold, dazu 1–2 seltene Barren zum doppelten Preis |
| Neben-Aufgabe „Ein Kupferset für die Gilde“ | sobald der Spieler die erste Rüstungs-Gussform hat (z. B. zufällig aus dem Rattenkeller): Tipp, „!“ über Hedwig | Hedwig nimmt den Auftrag an; die übrigen Rüstungs-Gussformen muss der Spieler selbst besorgen (Gussform-Händler auf dem Markt oder zufällig aus Rattenkeller/Tiefem Rattenkeller). Gesucht: Waffe, Helm, Rüstung, Handschuhe, Stiefel, Schulterschutz, jeweils mit Kupfer (im Inventar oder an einem Helden). Komplett: Tipp, Hedwig zahlt 250 Gold. Technik: story.json `recipe_actions`, `side_tasks.copper_set`, `side_dialogues` (Flags `armor_mold_found` → `copper_set_accepted` → `copper_set_complete` → `copper_set_paid`) |

| Neben-Aufgabe „Schuhe für Lotte“ | Kapitel 6, nach dem Schaufenster | Kinderschuhe (1 Leder + 1 Seil) machen und Lotte schenken. Muss erledigt sein, damit Lotte verschwindet und Kapitel 7 (Wald-Dungeons) beginnt. Danach: Lederschuhe für den Spieler. Technik: `side_tasks.lotte_shoes`, Nebendialog `lotte_shoes_gift` |
| Neben-Aufgabe „Die nächste Ebene“ | Teil 2, sobald der Spieler in Leonheim war (`iron_unlocked`, Nebendialog `miner_iron_offer`, gibt die Gussform Eisen-Spitzhackenkopf) | Gustav vor der Mine nimmt 1000 Gold, eine Eisenspitzhacke (Eisen-Spitzhackenkopf + Holzstiel), 40 Holzbalken, 40 Eisennägel. Am nächsten Morgen ist der Gang hinter dem Rattenloch in der Mine abgestützt (`old_mine_open`): Das Rattenloch ist der Eingang zur alten Mine (Mine 2), der zweite Stollen am Mine-Eingang bleibt verschüttet. Freiwillig: bleibt offen, bis der Spieler sie erledigt, die Story geht ohne sie weiter. Technik: `side_tasks.old_mine` (`show_items`, `show_gold`), Nebendialog `miner_deal_check`, story.json `overnight` |
| Neben-Aufgaben „Was ist Bronze?“ und „Ein Bronzebarren für Gustav“ | sobald ein Bronzebarren im Inventar/in der Lagertruhe liegt oder eine Bronze-Gussform bekannt ist | Tipp, dann Gustav vor der Mine fragen: Bronze ist eine Legierung aus Kupfer und Eisen. Er will einen Bronzebarren (Schmelze, Reiter Legieren: Kupfer- + Eisenbarren) und zahlt 150 Gold. Technik: `item_actions.bronze_ingot`, `recipe_actions.mold_bronze_*` (Flag `bronze_found`), Nebendialoge `miner_bronze_question` (setzt `bronze_explained`) und `miner_bronze_hand_in` (setzt `bronze_delivered`); solange Gustavs Mine-Auftrag offen ist, gibt es dort die Auswahl „Wegen der Bronze ...“. |
| Schmiede kaufen | ab Kapitel 7 (Lotte gerettet) | Oma (stiller Nebendialog, kein „!“), nach dem Überfall Lotte: 100.000 Gold, danach keine Miete mehr (`smithy_owned`) |
| Ninas Erweiterung | ab Kapitel 8, sobald in ihrem Laden 2000 Gold Umsatz gemacht wurden | Nina kommt am nächsten Morgen vor die Schmiede: 6 Waffentische und eine Rüstungspuppe (Helm, Schulterschutz, Rüstung, Umhang, Handschuhe, Stiefel, Schild), mindestens 2 Verkäufe pro Tag. Technik: Flags `nina_expansion_ready` → `nina_expansion_visit` (`overnight`) → `nina_expanded` |
| Lotte als Gehilfin | nach „Lottes erster Hammer“ | „Lotte schaut zu“: sie steht in der Werkstatt, du schmiedest ein Teil am Amboss, sie fragt, woher das Erz kommt. „Einkaufen mit Lotte“: sie läuft mit zu Ernas Stand, du erklärst das Einkaufen, sie bietet an, für dich einzukaufen (Lohn: ein Zehntel). Danach wartet sie jeden Morgen bis 9 Uhr in der Werkstatt und holt eine Ware vom Markt. Später geplant: mehrere Waren, Helden in Dungeons schicken, Aufträge erteilen. Technik: `Assistant`, `side_tasks.lotte_forge` / `lotte_shopping` |
| Lotte zieht umher | ab dem Überfall, 8–20 Uhr | alle 3 Stunden an einem anderen Ort: zu Hause, vor der Schmiede, Dorfplatz, Markt, Ninas Laden; nachts zu Hause. Technik: npcs.json `niece.roam`, `Roaming`, `StoryNpc.roam_spot` |
| Neben-Aufgabe „Die Rüstungspuppe“ | nach Ninas Erweiterung | alle Plätze der Puppe gleichzeitig belegen → Nina zahlt 300 Gold (`side_tasks.nina_dummy`, `check: nina_dummy`) |
| Neben-Aufgaben „Die Gilde ausbauen“, „Ein zweiter Stock für die Gilde“, „Die größte Gilde“ | ab dem Ende des Wiederaufbaus (`builder_weekly`): „!“ über Hedwig | Hedwig will anbauen. Stufe 1: 30 Holzbalken, 30 Eisennägel, 10 Eisenbarren, 1500 Gold; Stufe 2: 40 Holzbretter, 15 Bronzebarren, 10 Leder, 5000 Gold; Stufe 3: 40 Holzbalken, 15 Silberbarren, 20 Glas, 12000 Gold. Jede Stufe: +1 Heldenplatz, stärkere Helden zum Anheuern (Lv 2–6, 5–12, 10–20), mehr Suchtrupps (1, 2, 3) und seltenere Ware (bis R2, R3, R4). Technik: Flags `guild_upgrade_heard`, `guild_level_1`–`3`, `GuildLevel`, guild_heroes.json `guild_levels` |
| Suchaufträge | ab Gildenstufe 1, am Tresen jeder Gilde (Seite „Suchaufträge“) | Ware, Seltenheit und Menge wählen, Gold zahlen, nach 1–2 Tagen liegt alles morgens in der Loot-Kiste. Technik: `SearchOrders`, economy.json `search_orders` |
| Hütchenspiel des Bettlers | jederzeit auf dem Dorfplatz | erst 1 Gold Einsatz und fair, nach 2–3 Siegen will er mindestens 50 Gold und betrügt unsichtbar (man gewinnt nie mehr). Technik: `ShellGame`, `economy.json` `shell_game`, Flags `beggar_win_<n>`, `beggar_high_stakes` |
| Schwarzmarkt mit Spielautomat | ab Teil 2, Kapitel 3 (Hinterhof am Ostende der Einkaufsstraße in Leonheim) | Spielautomat 1–5 Gold (ca. 30 % Gewinn, Jackpot 0,001 %), Schattenhändler Vex mit Schmuggelware. Technik: `SlotMachine`, `economy.json` `slot_machine` |
| Die Wüste und Sahrim | ab Kahns Rat in Teil 4 (`desert_open`; wer Sahrim schon vorher gefunden hat, behält den Weg): Südweg » Süden | Labyrinth (`desert.json`): Schild „GEFAHR“, wer falsch läuft, steht wieder am Schild. Beim ersten Verlaufen Neben-Aufgabe „Sicherlich weiß der Zauberer etwas“ » Aurelius im tiefen Wald: sein Wüstenkompass (Geschenk des Echsenvolks) ist beim Angriff auf Sylvaris zerbrochen, die vier Gussformen hat er selbst versteckt („nie alles an einem Ort“) » 4 Dungeons (Leonheim, Vulkan, Sturmgipfel, Wald) » Kompass an der Werkbank » die Nadel führt nach Sahrim, der Zeltstadt des Echsenvolks. Dort: Ishra, Hinweise, Zahir mit Sandkarte, Händler, Rashid, Teleporter. Drei Truhen (Wüstenläufer, Sandschmied-Handschuhe, Karawanenrucksack), eine beim Skelett, zwei hinter der Säulenruine östlich der Stadt. Der Blitzkristall selbst kommt noch nicht vor (nur Andeutung: Gewitter in der tiefen Wüste). Technik: `DesertMaze`, Neben-Aufgaben `desert_lost`, `desert_compass`, `desert_town`, `desert_treasures` |
| Gasthaus in Leonheim | ab Teil 2, Kapitel 3 | Zimmer für 25 Gold beim Wirt: sofort schlafen, man wacht im Gasthaus auf. Technik: `InnMenu`, `economy.json` `inn` |

### Was wann freigeschaltet wird

| Was | Ab wann | Flag |
|---|---|---|
| Schmiede betreten | Schritt 2 (gemietet) | `smithy_rented` |
| Stationen benutzbar | Schritt 3 (Spinnwebe entfernt) | `cobweb_<station>` |
| Wassertrog | Schritt 6 (gekauft) | `station_water_trough` |
| Holgers tägliches Holz | Schritt 8 (liegt bis Schritt 17 unsichtbar in der Loot-Kiste) | – |
| Bruno als Held | Schritt 10 | `bruno_hired` |
| Loot-Kiste | Schritt 17 | `loot_chest_unlocked` |
| Auftragsbrett | Schritt 28 (erster Auftrag) | `order_board_unlocked` |
| Normale Kunden | Schritt 30 | `regular_customers` |
| Miete kassiert Oma von selbst (jetzt 800) | nach Schritt 27 | `first_rent_paid` |
| Kalender | 200 Gold Umsatz bei Nina | `calendar_owned` |
| Ninas Laden (Tür, Tische, Verkäufe) | Schritt 18 (zugesagt) | `nina_met`, `nina_shop_unlocked` |
| Gustav vor der Mine | Schritt 22 | `reached_meet_miner` |
| Spitzhacken-Rezepte | Schritt 22 | – |
| Mine (kleiner Teil, 5 Steine pro Tag) | jederzeit zu Fuß (Dorfplatz » Süden » Süden » Osten) | – |
| Tiefer Rattenkeller (Dungeon-Brett) | Schritt 33 (Hedwig) | `rat_cellar_deep_unlocked` |
| Rattennest (Dungeon-Brett) | Schritt 35 | `rat_nest_unlocked` |
| Rezepte Holzbrett und Eisennagel | Schritt 36 | – |
| Größere Mine (8 Steine pro Tag, 30 % Eisen) | Schritt 39 (Morgen nach der Abgabe) | `mine_expanded` |
| Neben-Aufgabe Kupferset | erste Rüstungs-Gussform (gekauft oder erbeutet), dann bei Hedwig zusagen | `armor_mold_found`, `copper_set_accepted` |
| Eisen-Spitzhackenkopf (Gussform), Holzbalken | Schritt 46 | – |
| Seil, Kinderschuhe | Schritt 48b | `shoe_idea` |
| Lederschuhe (Schuh-Slot des Spielers, schneller laufen) | Lotte hat die Kinderschuhe | `child_shoes_given` |
| Alte Mine (Mine 2) durch das Rattenloch in der Mine | Morgen nach Gustavs Neben-Aufgabe | `old_mine_open` |
| Wald-Dungeons (Reiter Wald) | Schritte 51–53, einer nach dem anderen | `forest_edge_unlocked`, `forest_thicket_unlocked`, `forest_den_unlocked` |
| Ein Jahr mietfrei | Schritt 54 | `rent_free_year` |
| Schmiede gehört dem Spieler | 100.000 Gold bei Oma | `smithy_owned` |
| Zaubertisch | Schritt 60 (Geschenk von Meister Aurelius) | `station_enchanting_table` |
| Ninas Erweiterung | 2000 Gold Umsatz, ab Kapitel 8 | `nina_expanded` |
| Teleport-Kristalle wecken (Portalkristall) | Teil 2, Kapitel 5 | `portal_crystal_owned`, `teleporter_<ort>_built` |
| Marktplatz wieder aufgebaut (Brandflecken, Trümmer, verkohlte Häuser weg) | Morgen nach der Materialabgabe (Teil 2, Kapitel 1) | `village_rebuilt` |
| Baumeister Konrad am Markt (Hausausbau) | ab dem Bürgermeister jeden Tag, ab dem Dank nur Di/Do 8–18 Uhr | `reached_meet_mayor`, `builder_weekly` |
| Gewächshaus links neben der Schmiede (Neben-Aufgabe) | Morgen nach der Abgabe bei Konrad | `greenhouse_built` |
| Königsstadt Leonheim (Kutsche Dorftor ↔ Schlossgarten / Einkaufsstraße, Läden der Stadt) | nach der Audienz beim König (Teil 2, Kapitel 3) | `king_audience_done` |
| Gilde von Leonheim: Reiter Leonheim auf dem Dungeon-Brett, erst nur die Kanalisation | Gespräch mit Thora (Teil 2, Kapitel 3) | `capital_guild_joined` |
| Katakomben, danach Gruft der Könige | je nach dem ersten Sieg im Dungeon davor | `required_dungeon` (Zähler `dungeon:<id>`) |
| Leonheim IV: Die verzauberte Gruft (einmalig) | Teil 2, Kapitel 6 (König will den Schlüssel) | `king_wants_key`, weg ab `morwald_defeated` |
| Vorhalle und Kerker im Schloss | immer (Schlossgarten » Schloss) | – |
| Eisen: Eisen-Gussformen bei Quentin, Eisen beim Erzkontor in Leonheim und bei Erna im Dorf, Gustavs Angebot für die alte Mine | Teil 2, Kapitel 3 (Weg zur Gilde von Leonheim) | `iron_unlocked` |
| Kristallkarte (Rechtsklick), Kutsche zum Lavaberg, Bronze-Gussformen bei Quentin | Teil 2, Kapitel 6 | `map_piece_1`, `volcano_route_open` |
| Silber-Gussformen bei Quentin (Silber selbst nur aus Dungeons) | Teil 3, Ankunft in Sylvaris | `silver_molds_offered` |
| Gold-Gussformen bei Quentin und Ssiva in Sahrim (Gold selbst nur aus Dungeons), Gold-Ring und -Amulett | Teil 4, Weg in die Wüste | `gold_molds_unlocked` |
| Platin als Beute (Finsterburg, danach alle Dungeons ab Teil 6; kein Platinerz, kein Händler) | Teil 5, Weg in den Sumpf | `reached_to_swamp` (materials.json) |
| Platin-Gussformen bei Quentin, Platin-Ring und -Amulett (seit 2026-11-08, vorher ab dem Sumpf) | Teil 6, Aufwachen im Wald | `reached_forest_wake` |
| Palladium-Gussformen, Palladium-Ring und -Amulett | Teil 7, Finsterstadt | `reached_finster_start` |
| Bronze-Gussformen (Sets) bei Quentin in Leonheim | sobald der Laden erreichbar ist | – |
| Teleporter am Lavaberg | mit dem Portalkristall, sobald man dort ist | `teleporter_lavaberg_built` |
| Krummfinger (Bronze-Gussformen, Kupfer- und Eisenerz, Rubine) | Ankunft in der Goblinhöhle | `reached_goblin_cave_arrival` |
| Brücke zum Goblinkönig | 5000 Gold | `goblin_audience_paid` |
| Goblinmine (nur Gold und Silber) | nach der Audienz | `goblin_mine_open` |
| Reiter Vulkan: Aschegänge, Schmiede des Lavagolems (einmalig) | 30 Bronzebarren abgegeben | `volcano_dungeons_unlocked`, `crown_quest_started`, weg ab `crown_recipe_found` |
| Vulkan II: Die Magmahallen | erster Sieg in den Aschegängen | `required_dungeon` |
| Rezept Goblinkrone | Sieg in der Schmiede des Lavagolems | – |
| Tiefe Goblinmine (nur Gold und Silber), Weg zur Goblinburg | Krone abgegeben, Weg zur Burg zu ab `goblin_castle_fallen` | `goblin_castle_path_open` |
| Burgtor | alle 5 Felsbrocken zerschlagen | `goblin_castle_gate_cleared` |
| Schatzkammer der Goblinburg | Schlüssel geschmiedet | `goblin_key_forged` |
| Kampf gegen Ignar | Gespräch mit dem Drachen | `dragon_challenge`, weg ab `dragon_defeated` |
| Goblinburg versunken (Tür in der tiefen Mine gesperrt) | nach dem Drachen | `goblin_castle_fallen` |
| Gold-Gussformen (Rashid und andere Händler) | Teil 4, Weg in die Wüste (stand hier früher als Teil 3, Kapitel 1) | `gold_molds_unlocked` |
| Kutsche nach Sylvaris (Westende der Einkaufsstraße) und zurück | Kriegsrat (Teil 3, Kapitel 1) | `elf_route_open` |
| Turnierplatz (Ende der Schmiedegasse), Turnier beim Herold | nach dem ersten Besuch beim Ältesten | `tournament_open` |
| Monatsturnier (Startgeld) | nach dem ersten Turniersieg | `smith_tournament_won` |
| Soldaten und Zelte am Waldboden von Sylvaris | nach der Siegerehrung | `elf_defenses` |
| Kristallkarte: Stück der Elfen | Krisenrat | `map_piece_2` |
| Kutsche nach Eisquell (Schlossgarten, links) und zurück, Teleporter Eisquell | Aufbruch in Teil 4 | `water_route_open` |
| Reiter Eisquell auf dem Dungeon-Brett (4 Grotten nacheinander, die Tiefe Grotte einmalig) | Subar | `water_dungeons_unlocked`, weg ab `frost_mane_slain` |
| Halle der Strömung, Gezeitenarena (Heldenturnier) | Fell abgegeben, Kahns Audienz | `kahn_hall_open`, `kahn_tournament_open` |
| Kristallkarte: Stück des Wasservolks | Kahns Rat | `map_piece_3` |
| Wüste (Südweg » Süden) | Kahns Rat | `desert_open` |
| Sturmpfade zum Tempel (Säulen » Süden), Kompass zeigt zum Tempel | Karte von Fürst Ssarok | `storm_map_owned` |

---

## Geplant

> Grundsatz: Das Hauptspiel ist das Schmieden, die Story ist der Rahmen. Der Spieler ist Schmied, kein Kämpfer – kämpfen tun seine Helden, er rüstet sie aus.

### Grober Verlauf bis zum Ende (Vorgabe 2026-10-25)

1. **Teil 3 – Das Elfendorf (umgesetzt):** Kriegsrat, Sylvaris, Schmiedeturnier in Leonheim für die Elfen, der Lich raubt in der Nacht den Windkristall, Krisenrat mit dem zweiten Kartenstück (geändert 2026-10-25: der Kristall bleibt beim Lich).
2. **Der Wasserkristall** beim Kahn in Eisquell: umgesetzt in Teil 4 (Frostmähne, Heldenturnier, Kahn gibt den Kristall dem König). Offen: die Eismauer (Eiskristall, Kahn gibt ihn nicht her), ein Schmiedeturnier in Eisquell.
3. **Der Blitzkristall** in der Wüste: umgesetzt in Teil 4 (Verhaftung, Ulrich, Fürst Ssarok, Sturmtempel mit Rätseln). Kasim aus dem Turnier könnte noch in Sahrim auftauchen.
4. **Der Giftkristall** aus dem Sumpf.
5. **Finale:** Der Lich wird besiegt und der legendäre Schmied befreit. Der König lässt sich zum Schein vom Lich „entführen“; mit einer Rede bringt er Lake dazu, den Lich zu töten. Lake wird zum bösen dunklen Ritter, der König entpuppt sich als Hauptbösewicht. Er hat dann Feuer (Lavaberg), Licht (Leonheim), Erde (Dorf), Blitz (Wüste), Dunkel (Finsterburg, wo er heimlich herrscht), Wasser (Wasserstadt) und Wind (Elfendorf). Der legendäre Schmied hat den Schlüssel in der Gefangenschaft schon geschmiedet; der Dämonenlord öffnet das Tor. Der Spieler rettet alle, weil er dank seiner besonderen Magie etwas Einzigartiges schmieden kann – diese Magie kommt im Lauf des Spiels immer mehr heraus.

### Teil 6 (Ausblick, aus Teil 5)

- **Ausführlicher Entwurf für Teil 6–8 und das Spiel nach dem Ende:** `docs/STORY_PLAN_6-8.md` (2026-10-28, noch nicht entschieden).

- Der König hat acht Steine und Lake als dunklen Ritter; „Den Eiskristall holt mir einer, der jetzt noch nicht weiß, dass er es tun wird.“ Der legendäre Schmied lebt und hat die Fassung für die Steine geschmiedet. Aurelius trägt Schuld, Faelan bereut. Das blaue Licht des Spielers glimmt wieder.

### Teil 5 (Ausblick aus Teil 4, umgesetzt)

- **Die Rettung des Königs:** Der Lich verlangt den Blitzkristall gegen den König („Ort und Stunde folgen“). Geheim: Der König hat sich selbst „entführen“ lassen, um so an den Blitzkristall zu kommen (siehe `docs/DIALOGE.md`, Geheimnisse). Lake will ihn um jeden Preis zurückholen.
- Offen: der Eiskristall in der Eismauer (Kahn gibt ihn nicht her, er hält die Mauer), weitere Kämpfe in der Gezeitenarena, Ssaroks Frage, wer dem Lich den Weg gezeigt hat, die Vision im Sturmtempel (der legendäre Schmied wollte etwas sagen).

### Was aus Teil 3 offen bleibt

- **Wer hat den Lich zum Windkristall geführt?** Der Lich sagt „euer Freund“. Falsche Fährte: Lake (allein an der Ostbrücke, seit Mitternacht verschwunden). Vorschlag für die Auflösung: der König (siehe Geheimnisse in `docs/DIALOGE.md`).
- **Das blaue Licht:** Elarion und der Lich erkennen es; der legendäre Schmied „schmiedet“ irgendwo (Gefangenschaft). Aurelius will herausfinden, was es ist.
- **Tausend Jahre:** Das Siegel wird bald schwach – erklärt, warum gerade jetzt alle die Steine suchen.
- Die Elfen suchen das vierte Kartenstück bei den Halbdämonen (Finsterburg, Gift im Sumpf).
- Kasim aus dem Süden (Turnier) kann später in der Wüste wieder auftauchen.
- Gold-Sets bei einem Händler anbieten (Gold-Gussformen gibt es seit Teil 3 bei Rashid).
- Der Lichtkristall unter Leonheim (Katakomben, Gruft der Könige), Spuren des Lichs; wer hat die Schmiede ausgeraubt?; Ulrich, der erste Kunde, wird vergessen.

### Schmiedeturniere (Leonheim umgesetzt in Teil 3, weitere geplant)

- **Idee:** Wer das große Schmiedeturnier gewinnt, bekommt einen Titel (bis hin zum Meisterschmied, der Wettbewerb aus dem Intro). Seit der legendäre Schmied verschwunden ist, hat es keiner mehr ausgerichtet; am Ende von Teil 2 verspricht der König, es wieder auszurichten.
- **Ablauf:** Der Spieler tritt gegen andere Schmiede an (Brandolf, Ilsa Funkenhand, Gorm aus der Schmiedegasse, später ein Elfenschmied und einer aus der Wasserstadt). Alle bekommen dieselben vorgegebenen Materialien und dieselbe Aufgabe (z. B. „ein Schwert aus 3 Eisenbarren“), bewertet werden Seltenheit und Qualität (0–100), vielleicht auch die Zeit.
- **Umgesetzt (2026-10-25):** Leonheim, Turnierplatz am Ende der Schmiedegasse: 4 Runden (Kupfer, Eisen, Bronze, Silber), Gegner simuliert, erster Sieg = Meisterhandschuhe, danach monatlich mit Startgeld (`SmithTournament`, economy.json `smith_tournament`).
- **Orte:** Leonheim (umgesetzt), Elfendorf, Wasserstadt (je ein Turnier, steigende Schwierigkeit, je ein Titel; in der Wasserstadt kommt zuerst Kahns Kampfturnier).
- **Belohnungen:** Gussformen, die es sonst nicht gibt, z. B. Rucksäcke, Handschuhe, bessere Spitzhacken und Holzfälleräxte, Schuhe.
- **Angeteasert (2026-10-25):** Nina nach ihrer Erweiterung („früher beim großen Schmiedeturnier“), Brandolf, Ilsa, Gorm und Hagen in der Schmiedegasse, der König am Ende von Teil 2.

### Dorf nach Teil 2

- **Abenteurergilde ausbauen** und **Suchaufträge**: umgesetzt (2026-10-25), siehe „Nebenher“.
- Weitere kleine Aufgaben im Dorf, damit es nach dem Wiederaufbau nicht „erledigt“ ist (Lotte, Gustav, Nina, Konrad).

### Vorschläge, damit der Spieler dranbleibt (offen, noch nicht entschieden)

- **Die Magie des Spielers wächst sichtbar:** pro Teil eine neue Schmiedefähigkeit aus der Story (z. B. blaue Glut am Amboss, ein Teil, das nur er schmieden kann), wie das blaue Licht des alten Schmieds.
- **Spuren des legendären Schmieds:** Waffen der Untoten oder Beute aus Dungeons tragen manchmal sein Meisterzeichen – er muss in Gefangenschaft für den Feind schmieden („Der Meister braucht Waffen“). Sammelbare Hinweise, z. B. eingeritzte Botschaften.
- **Ein Rivale**, der in jedem Turnier wiederkommt (z. B. Ilsa Funkenhand).
- **Lotte wird Lehrling** in der Schmiede (kleine Hilfen, eigene Mini-Aufgaben), damit das Dorf und das Versprechen an den König eine Rolle behalten.

### Noch keinem Kapitel zugeordnet

- Ninas Laden weiter ausbauen: später auch Schmuck, Beinschutz an der Puppe (sobald es Beinschutz gibt).
- Mine: noch tiefere Stollen (die alte große Mine `mine.png`, die verschüttete alte Mine am Mine-Eingang, Nickel/Silber/Gold).

### Offene Fragen zur Story

- Gibt es in Version 1 ein Spielende?
- Schmiedeturniere: genaue Regeln, Bewertung und Titelnamen (Grundidee oben).
- Zahlen Holger und Bruno ihre Schulden irgendwann zurück?
