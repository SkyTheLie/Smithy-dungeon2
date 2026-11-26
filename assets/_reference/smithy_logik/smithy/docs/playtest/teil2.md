# Playtest Teil 2: Wiederaufbau bis zum Feuerkristall

Bot: `assets/_reference/playtest/sim_play_story.gd`, Start vom echten Autosave am Ende von Teil 1 (`raid_morning`, Tag 15, Ilka L6, Leif L6, 0 Gold), also ohne Kapitel-Sprung. Bilder und Log: `assets/_reference/playtest/teil2/lauf3/` (Zahlen und Bilder), dazu `teil2/lauf2/` (zwei Bilder, Log des Laufs mit falscher Skill-Verteilung, siehe „Bot“ unten).

**Ergebnis Lauf 3:** durchgespielt bis `part2_end`, Tag 15 bis Tag 53 (38 Tage). Gold 0 » 11 227. Helden am Ende: Ilka (Priesterin) L35, Leif (Paladin) L35, Zora (Magierin) L35. Im Log nur der bekannte Fehler A5 aus Teil 1 (2× `is_shown` bei Lotte), sonst keine Skriptfehler.

**Was der Bot anders macht als in Teil 1 (wichtig für die Zahlen):**
- Ausrüstung wie `balancing/sim_progress.gd`: jeder Held ein volles Set im Metall der Story-Stufe (Kupfer, ab `to_city_guild` Eisen, ab `crown_recipe` Bronze), R1, Qualität 0, Material in Gold bezahlt. Also die schwächste Ausführung. Ein Spieler mit Minispielen ist stärker.
- Attribut- und Skillpunkte nach den Bauplänen aus `balancing/sim_party.gd`.
- Vor jedem Story-Dungeon farmt die stärkste Gruppe, bis sie im Schnitt höchstens 1 Level unter der Empfehlung ist. Unter 3 Helden heuert er an (fehlende Rolle zuerst).
- Nach jedem Lauf: Gold aus der Loot-Kiste nehmen, Beute verkaufen. **Das fehlte in Teil 1:** Dort ließ der Bot Geldbeutel und Beute in der Kiste. Der Goldmangel aus A2/A4 in Teil 1 ist darum teilweise ein Bot-Fehler (siehe Nachtrag unten).
- Rätsel: Teleporter per E geweckt, Felsen mit Bronzespitzhacke (vom Bot gemacht) per E zerschlagen, Goblin-Schlüssel über `GoblinKey` gelöst (nicht von Hand).

## Übersicht je Kapitel (Lauf 3)

| Kapitel | Schritte | Tage | Gold am Ende | Helden |
|---|---|---|---|---|
| 10–11 Wiederaufbau, Aurelius | `chapter10_end` » `chapter11_end` | Tag 15–17 | 299 | Ilka L6, Leif L6 |
| 12 Leonheim | `royal_carriage` » `chapter12_end` | Tag 18 | 0 (Eisen-Sets) | L6 |
| 13 Die Gosse | `king_question` » `chapter13_end` | **Tag 19–38** | 7 171 | L20 + Zora |
| 14 Aurelius, Gruft | `search_mage` » `chapter14_end` | Tag 39–43 | 7 562 | L22 |
| 15 Schatzkammer | `key_to_king` » `chapter15_end` | Tag 43 | 7 562 | L22 |
| 16 Goblinkönig | `to_volcano` » `chapter16_end` | Tag 44–47 | 8 046 | L29 |
| 17 Goblinburg, Drache | `to_goblin_castle` » `part2_end` | Tag 48–53 | 11 227 | L35 |

## Kriterien

| # | Kriterium | Befund |
|---|---|---|
| 1 | Grinden | A7 Gosse: 16 Tage Farmen von L6 auf L13. Lavagolem: 23 Läufe (L22 » L29, 3 Tage). Drache: 23 Läufe (L29 » L35, 3 Tage), dann 1 Niederlage, dann Sieg. |
| 2 | Unschlüssig | B7 Brief vom König, C14 Silber-Gussformen |
| 3 | Gesagt, nicht animiert | A8 Burg stürzt ein, B6 Aurelius „eilt hinaus“ (unsicher) |
| 4 | Komisch | C13 Erzähler mit Namen „Ignar“ |
| 5 | Bugs | nur A5 aus Teil 1 (Lotte, `is_shown`) |
| 6 | Sackgassen | keine |
| 7 | Lernkurve | A9 Skillpunkte: falsche Verteilung macht Helden fast chancenlos, kein Hinweis |
| 8 | Wirtschaft | B8 Gold häuft sich |
| 9 | Kampf | Gruppe Paladin/Priesterin/Magierin mit R1 auf Empfehlung −1: Gosse 1–2 Niederlagen, Lavagolem im ersten Versuch, Drache 1 Niederlage. Passt zum Simulator. |
| 10 | Übersetzung | deutsch, nichts aufgefallen |
| 11 | Platzhalter | keine gesehen |

## A (wichtig)

**A7 · Großer Level-Sprung zur Gosse.** Schritt `gutter_alleys`, Dungeons `gutter_alleys` (Stufe 14) und davor nur Dorf/Wald (bis 13) und Leonheim ab `capital_sewers` (12). Teil 1 endet im echten Lauf mit Level 6 (Bruno tot, Ilka und Leif L6). Bis die Gruppe L13 hatte, vergingen **Tag 19 bis Tag 35, 111 Farm-Läufe**. Bei L8–9 fand der Bot zeitweise nichts Passendes auf dem Brett (Log „kein passender Dungeon“, Schnitt L8,7): Die Kanalisation ist Stufe 12, der Wald endet bei 10/13. Dazu startete die Gruppe mit 2 Helden und 0 Gold (der Überfall nimmt alles). `sim_progress.gd` rechnet für Teil 1 mit zwei Kriegern L2 neben Bruno und viel mehr Farmen. Wer wie der Bot in Teil 1 nur die Story-Dungeons macht, steht hier vor einer Wand. Vorschlag: ein Dungeon Stufe 9–11 in Leonheim (oder Kanalisation auf Stufe 10), oder der Tipp „Die Gosse“ nennt die Empfehlung „Level 14, vorher Kanalisation und Katakomben“.

**A8 · „Du rennst“, aber niemand rennt.** Schritt `dragon_defeated`, Dialog in `dialogues/volcano.json` Zeile 767: „Du rennst. Hinter dir stürzt die Goblinburg mit dem Drachen und seinem Gold in die Lava.“ Kein `action`, kein `hide_for`. Bild `lauf3/454_dragon_defeated_ankunft_talk.png`: Der Drache liegt ruhig auf dem Goldberg, alles ist rot getönt, der Spieler ist nicht zu sehen. Die Zeile davor (`castle_collapse`) zeigt Feuer und Risse, das Weglaufen fehlt (Regel 50). Vorschlag: Cutscene-Teil mit `hide_for`: Spieler rennt zum Ausgang, Kamera wackelt, Burg sackt weg, Überblendung.

**A9 · Skillpunkte falsch verteilt = Helden fast chancenlos, und das Spiel sagt nichts.** Aus Lauf 2 (Bot-Fehler, aber lehrreich): Der Bot steckte bei jedem Levelaufstieg die Punkte wieder in die ersten Skills der Liste (Priesterin: nur `healing_light`, `prayer_shield`, `blessed_hands`, `purify` voll; ohne `greater_heal`, `circle_of_healing`). Gleiche Helden, gleiche Bronze-Ausrüstung, nur die Skills anders (`assets/_reference/playtest/sim_hero_compare.gd`, 30 Kämpfe):

| Dungeon | Skills nur oben voll | Skills wie Simulator |
|---|---|---|
| Magmahallen (28) | 50 % | 100 % |
| Lavagolem (30) | 10 % | 80 % |
| Drache (36) | 0 % | 27 % |

Lauf 2 verlor deshalb Lavagolem und Drachen je 12-mal auf Level 29–36. Ein Spieler, der „das Bekannte weiter hochzieht“, landet genau da. Der Tipp zu Skillpunkten sagt nur, wo man sie verteilt. Vorschlag: Tipp oder Gildenmeisterin Thora erwähnt, dass tiefere Skills (Gruppenheilung, Flächenzauber) ab Leonheim nötig sind; ggf. im Skillbaum markieren, was eine Rolle braucht.

## B (komisch)

**B6 · Aurelius „eilt hinaus“ (unsicher).** Schritt `crystal_to_king`, `dialogues/capital.json` Zeile 934: Aktion nur `set_flag:mage_left_for_elves` mit `hide_for: 1.8`. Auf dem Bild nach dem Gespräch (`lauf2/635_crystal_to_king_ankunft_talk.png`) ist er weg. Ob er sichtbar zur Tür läuft oder nur verschwindet, zeigt kein Bild. Bitte von Hand prüfen (Regel 48: gehen per `set_flag` in normaler Zeile).

**B7 · Brief vom König kommt nach Jupps Frage.** Schritt `royal_carriage`: Jupp sagt „Lotte hat dir den Brief schon gebracht? Gut.“, danach fährt die Kutsche, und erst im Schlossgarten von Leonheim rennt Lotte herbei: „Kai! Ein Reiter war da! … Ich bring es ihm.“ (Bild `lauf2/113_royal_carriage_talk.png`, Lotte neben Mohammad und der Kutsche). Unsicher: Der Bot reist direkt zu Jupp, ohne durchs Dorf zu laufen; ein Spieler trifft Lotte vermutlich vorher. Trotzdem: Wer schnell zum Dorftor geht, bekommt den Brief in der Hauptstadt. Vorschlag: Jupp fährt erst, wenn `letter_royal` gelesen ist, oder Lotte gibt den Brief nicht in Leonheim.

**B8 · Gold häuft sich an.** Lauf 3: 0 Gold an Tag 19, 7 171 an Tag 38, 11 227 am Ende. Einnahmen über Teil 2: 9 899 von 49 Kundenaufträgen, 10 341 aus Beute (1 058 Geldbeutel, 9 283 verkaufte Beute). Ausgaben fast nur Eisen-/Bronze-Sets (je ~250–330 Gold Material), 30 Bronzebarren (450), Goblin-Gebühr 500, Helden 199–228. Die 500 Gold der Goblinwachen sind keine Hürde mehr. Der Bot kauft nichts sonst (Gewächshaus 500, Hausausbau, Werkstatt nicht), also ist das obere Ende. Bitte bei der Balance beachten: Ab Leonheim fehlt ein Goldziel.

## C (Kleinkram)

**C13 · Erzählerzeile mit Namen „Ignar“.** Bild `lauf3/454`: Fenstertitel „Ignar“ über reinem Erzähltext („Du rennst …“). Auch die rote Tönung liegt über HUD, Uhr und Aufgaben.

**C14 · „Silber-Gussformen“ nach der Gruft.** `key_to_king`, Erzähler: „Formenmacher Quentin hat neue Silber-Gussformen.“ Nach `sim_party.gd` (TIERS) kommt erst Bronze (Lavaberg), Silber erst mit dem Sturmgipfel; der Tipp „Bronzespitzhacke“ nennt bei Quentin „Bronze-Werkzeug“. Bitte prüfen, ob Silber hier stimmt.

**C15 · Leere um den Thronsaal bei anderer Fenstergröße.** Bild `lauf2/635_crystal_to_king_ankunft_talk.png` (Fenster war nicht 1280×720): oben und unten schwarze Leere um die Karte. Unsicher, ob das Fenster von Hand verkleinert wurde; bitte mit einem hohen Fenster prüfen (Regel 13: keine Leere sichtbar).

**C16 · Admin „Quest-Sprung“ findet Konrad nicht.** `QuestJump._index_scenes` liest nur `npc_id` direkt in Kartendateien; Konrad steckt als `scenes/actors/builder_npc.tscn` im Marktplatz. Folge im Admin-Panel: Ziel von `rebuild_gather` ist der Bürgermeister statt Konrad. Nur Testwerkzeug.

## Was gut war

- Rote Linie hält: Wiederaufbau » König » Gilde » Gosse » Aurelius erzählt die Schlüssel-Geschichte » Karte in der Schatzkammer » Goblins » Drache. Jeder Schritt sagt, wohin.
- Goblin-Audienz („… Essen?“, Stille, der kleine Goblin wird geworfen) und Varriks Verurteilung („wo selbst die Ratten Ratten haben“) sind stark und als Cutscene da.
- Lake tritt zum ersten Mal auf und wirkt sofort verdächtig („Wer am König zweifelt, zweifelt am Licht.“).
- Tipps kommen jetzt einzeln und passend (Gosse, Gruft, Drache, Bronzespitzhacke).
- Nach dem Ausgleich durch Farmen gewinnt die Gruppe die Story-Dungeons in 1–3 Versuchen, das passt zum Simulator.

## Nicht getestet

- `rebuild_gather` (Baumaterial zu Konrad): Der Bot fand Konrad nicht (C16, inzwischen im Bot behoben) und sprang weiter. Material und Kosten (20 Bretter, 20 Balken, 20 Nägel, 5 Barren) darum nicht gemessen.
- Minispiele, Goblin-Schlüssel-Rätsel und Bronzespitzhacke (vom Bot gemacht bzw. über `GoblinKey` gelöst).
- Gewächshaus, Mondlilien, Verzaubern (Neben-Inhalte, der Bot baut nichts).
- Zwei Dungeons gleichzeitig: Der Bot schickt nur eine Gruppe.

## Nachtrag zu Teil 1

Der Bot nahm in Teil 1 nie das Gold aus der Loot-Kiste und verkaufte keine Beute. A2 (Gold sinkt im Rattennest auf 4) und A4 (Gold-Falle bei Niederlagen) sind darum zu pessimistisch. Die Beobachtung „verlorene Versuche kosten Gold“ bleibt, das Feststecken ohne Gold eher nicht. Zum Vergleich Lauf 3 hier: Kunden und Beute bringen ab Leonheim rund 500 Gold pro Tag.
