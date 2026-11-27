# Aufgaben (Liste vom 2026-11-27)

Jede Aufgabe bekommt einen eigenen Branch. Nach jeder fertigen Aufgabe: Tests, Commit, Push, Merge nach `main`, dann hier abhaken (mit Branch und Datum).

Vorher: offener Stand `feature/rubin-seil-altar` (Seil nach dem ersten Boss, Rubin für Egon, Portal zum Boss-Altar) fertig gemacht und gemergt.

| # | Aufgabe | Status |
|---|---|---|
| 1 | **Händler im Dungeon mit F ansprechen**, um Sachen zu verkaufen; auch Relikte verkaufen. | ✅ erledigt |
| 2 | **Schlüssel:** am Anfang keinen Schlüssel. Beim Verlassen des Dungeons zerbrechen die Schlüssel; Egon sagt das: „so ein Magie-Ding, keine Ahnung, bin ein Gaunerverkäufer“. | ✅ erledigt |
| 3 | **Erste Ebene kleiner:** höchstens 6 Räume, davon Boss-Raum und Opfer-Raum. | ✅ erledigt |
| 4 | **Start-Bildschirm** „Hier klicken“ nur einmal. Spiel → Hauptmenü landet im Hauptmenü ohne die Reingeh-Animation. | ✅ erledigt |
| 5 | **3D-Ton:** Geräusche von Gegnern räumlich (Stereo/3D), Musik bleibt mono. | ✅ erledigt |
| 6 | **Skills einzeln:** jede Stufe ein eigener Skill, untereinander; kauft man den oberen, wird der darunter freigeschaltet. | ✅ erledigt |
| 7 | **Seil nur nach Boss-Sieg im Boss-Raum**, sonst wie vorher die Treppe/Falltür nach unten. | ✅ erledigt |
| 8 | **Relikt-Skills:** Skill „Stufe-1-Relikte gehen nicht mehr kaputt“, dann Stufe 2 usw. Skill „Eisenherzen“ entfernen; neuer Skill: 1 blaues Herz zusätzlich. | ✅ erledigt |
| 9 | **Maus-Empfindlichkeit** als Zahl mit Eingabefeld (Kommazahl), 1 zu 1 wie in Counter-Strike 2. | ✅ erledigt |
| 10 | **Fadenkreuz** einstellbar (auch aus), Einstellungen wie in CS2 (Länge, Dicke, Abstand, Punkt, Umriss, Farbe). | ✅ erledigt |
| 11 | **Blickrichtung der Gegner:** Kreis am Boden unter jedem Gegner, ein Viertel gefüllt = Blickrichtung (sieht man, ob man hinter ihm steht). | ✅ erledigt |
| 12 | **Leveln langsamer:** nach dem ersten Run etwa 80 % Erfahrung zur nächsten Stufe, nach dem zweiten ebenso. **Skill-Baum:** Skills mit Geld rechts (gehen von links nach rechts), Skills nur mit Skill-Punkten links (gehen von rechts nach links). | ✅ erledigt |
| 13 | **Dungeon-Brett** zeigt nur freigeschaltete Dungeons. **Lexikon** mit Gegnern, beim Dungeon sind seine Gegner aufgelistet (nach dem Lexikon von Smithy). | ✅ erledigt |
| 14 | **Oberfläche schöner:** bunter, Effekte, „Dopamin“; Vorschläge machen und direkt umsetzen. | ✅ erledigt |

Reihenfolge: 7 zuerst (baut auf dem Seil-Stand auf), dann 2, 3, 4, 1, 8, 6, 12, 9, 10, 11, 5, 13, 14 (die große Oberflächen-Aufgabe zuletzt, damit sie alles Neue mit erfasst).

## Erledigt

(neueste oben, mit Branch und Datum)

- **14** · `feature/ui-juice` · 2026-11-27 · Vorschläge umgesetzt: Schadenszahlen über Gegnern (stark = groß und gold), Treffer-X am Fadenkreuz (rot beim Kill), Konfetti beim Gegner-Tod, Beute-Popups „+2 Rattenfell“ in Seltenheitsfarbe, pulsierender roter Rand bei wenig Leben, federnde Knöpfe überall, animierter EXP-Balken mit „Stufe X!“ und Konfetti auf dem End-Bildschirm. Im Spiel: Gegner treffen/töten, Beute aufheben, auf ein halbes Herz runter, Run beenden.

- **13** · `feature/brett-lexikon` · 2026-11-27 · Dungeon-Brett zeigt nur freigeschaltete Dungeons und darunter die Gegner des Dungeons (bekannte mit Namen, sonst Silhouetten). Lexikon hat jetzt die Reiter Items und Gegner (nach Smithy): Gegner nach Dungeon, nach dem ersten Kill mit Werten, Beute und Fundort. Im Spiel: neues Spiel → Brett zeigt nur Dungeon der Glut; ein paar Gegner besiegen → Hauptmenü → Lexikon → Gegner.

- **5** · `feature/3d-ton` · 2026-11-27 · Vorher war kein Ton 3D. Jetzt kommen alle Gegner-Geräusche (Treffer, Tod, Rufe, Schüsse, Boss) räumlich aus ihrer Richtung (links/rechts, leiser mit Abstand, AudioStreamPlayer3D). Musik und eigene Töne bleiben ohne Richtung. Im Spiel: mit Kopfhörern einen Gegner links stehen lassen → sein Ruf kommt von links.

- **11** · `feature/gegner-blickrichtung` · 2026-11-27 · Unter jedem Gegner ist ein Viertel des Rings gefüllt und zeigt die Blickrichtung (wohin er läuft; im Stand zum Spieler; Schildträger: Schild-Seite). Im Spiel: Gegner umlaufen → der Keil dreht mit, steht man hinter ihm, zeigt der Keil weg.

- **10** · `feature/fadenkreuz` · 2026-11-27 · Neuer Reiter „Fadenkreuz“ in den Einstellungen wie in CS2: Stil (Kreuz, nur Punkt, aus), Farbe (CS2-Farben oder eigene), Deckkraft, Länge, Dicke, Abstand (auch negativ), Mittelpunkt, Umriss mit Dicke, T-Form, Vorschau, Standard wiederherstellen. Im Spiel: Esc → Einstellungen → Fadenkreuz → ändern, im Dungeon sofort sichtbar.

- **9** · `feature/maus-cs2` · 2026-11-27 · Maus-Empfindlichkeit als Zahl wie in CS2 (Empfindlichkeit × 0,022° je Maus-Zählschritt), Schieber plus Zahlenfeld rechts (Komma oder Punkt). Standard 2,5. Im Spiel: Einstellungen → Steuerung → eigene CS2-Zahl eintragen → im Dungeon fühlt sich das Drehen gleich an.

- **12** · `feature/leveln-skillseiten` · 2026-11-27 · Leveln langsamer am Anfang (Stufe 1 = 64 EXP, dann 90; erster Run ≈ 80 %, zweiter Run Stufe 1 + ≈ 80 %), später wie vorher. Skill-Baum: links nur Skillpunkte (Kampf, Überleben), wächst nach links; rechts nur Gold (Rucksack, Relikte, Laden), wächst nach rechts; Trennstrich in der Mitte. Im Spiel: neues Spiel → erster Run → End-Bildschirm/Laden: EXP-Balken bei ~80 %; Skills → zwei Seiten.

- **6** · `feature/skills-einzeln` · 2026-11-27 · Jede Skill-Stufe ist ein eigenes Feld; die Stufen stehen untereinander, die nächste geht erst nach der darüber auf. Ketten laufen seitlich. Im Spiel: Laden → Skills → oberste Stufe lernen → die darunter leuchtet golden.

- **8** · `feature/relikt-skills` · 2026-11-27 · Zähigkeit (Schild-Herzen) raus, neuer Skill Blaues Herz (1 Stufe). Neuer Skill Reliktschutz (4 Stufen): Stufe 1 macht Relikte der Stufe 1 unzerbrechlich, Stufe 2 auch die der Stufe 2 usw.; Relikte der Stufe 1 halten ohne den Skill 5 Dungeons. Im Spiel: Skills → Blaues Herz lernen → im Dungeon ein blaues Herz; Reliktschutz lernen → Relikt-Text sagt „Hält für immer“.

- **1** · `feature/haendler-f` · 2026-11-27 · F beim Händler im Dungeon-Shop öffnet sein Handelsfenster (HUD-Hinweis in der Nähe): Beute verkaufen (Rechtsklick) und ein Relikt kaufen, das dann zu Hause im Inventar liegt. Taste in den Einstellungen änderbar („Reden“). Im Spiel: Ebene 2 → Shop → zum Händler → F → verkaufen, Relikt kaufen → nach dem Run bei Egon im Inventar.

- **4** · `feature/startbild-einmal` · 2026-11-27 · „Hier klicken“ kommt nur beim ersten Mal nach dem Programmstart (MainMenu.title_seen). Danach (Hauptmenü aus Laden/Pause, Rückkehr aus dem Run) startet das Menü direkt am Amboss ohne Tür-Animation. Im Spiel: starten → Tür öffnen → Weiter → im Laden Esc → Hauptmenü → direkt das Menü.

- **3** · `feature/erste-ebene-klein` · 2026-11-27 · Erste Ebene (Dungeon der Glut): Start, 3 normale Räume, Boss und sicher ein Opferraum = 6 Räume; kein Shop, kein Geheimraum, kein Sonderraum (neue Felder in floors.json). Im Spiel: neues Spiel → Dungeon → M: Karte hat 6 Räume.

- **2** · `feature/schluessel` · 2026-11-27 · Start ohne Schlüssel (data/player.json keys 0). Schlüssel gehören zum Run und bleiben im Dungeon; der End-Bildschirm zeigt „Schlüssel zerbrochen: N“. Egon erklärt es im ersten Laden-Besuch (tutorial_dungeon). Im Spiel: neues Spiel → Laden-Tour bis zum Ende anhören → im Dungeon 0 Schlüssel; mit Schlüssel über die Leiter raus → End-Bildschirm.

- **7** · `feature/seil-treppe` · 2026-11-27 · Falltür und Boss-Item kommen nach dem ersten Boss wieder wie immer; das Seil kommt zusätzlich daneben, aber nur, wenn der Boss im Boss-Raum besiegt wurde. Egon nimmt den Rubin auch, wenn man ihn über die Falltür/Leiter heimbringt. Im Spiel: neues Spiel → ersten Boss besiegen → Falltür in der Mitte, Seil links daneben.
