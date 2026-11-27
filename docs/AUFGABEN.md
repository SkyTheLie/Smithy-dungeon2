# Aufgaben (Liste vom 2026-11-27)

Jede Aufgabe bekommt einen eigenen Branch. Nach jeder fertigen Aufgabe: Tests, Commit, Push, Merge nach `main`, dann hier abhaken (mit Branch und Datum).

Vorher: offener Stand `feature/rubin-seil-altar` (Seil nach dem ersten Boss, Rubin für Egon, Portal zum Boss-Altar) fertig gemacht und gemergt.

| # | Aufgabe | Status |
|---|---|---|
| 1 | **Händler im Dungeon mit F ansprechen**, um Sachen zu verkaufen; auch Relikte verkaufen. | offen |
| 2 | **Schlüssel:** am Anfang keinen Schlüssel. Beim Verlassen des Dungeons zerbrechen die Schlüssel; Egon sagt das: „so ein Magie-Ding, keine Ahnung, bin ein Gaunerverkäufer“. | ✅ erledigt |
| 3 | **Erste Ebene kleiner:** höchstens 6 Räume, davon Boss-Raum und Opfer-Raum. | ✅ erledigt |
| 4 | **Start-Bildschirm** „Hier klicken“ nur einmal. Spiel → Hauptmenü landet im Hauptmenü ohne die Reingeh-Animation. | ✅ erledigt |
| 5 | **3D-Ton:** Geräusche von Gegnern räumlich (Stereo/3D), Musik bleibt mono. | offen |
| 6 | **Skills einzeln:** jede Stufe ein eigener Skill, untereinander; kauft man den oberen, wird der darunter freigeschaltet. | offen |
| 7 | **Seil nur nach Boss-Sieg im Boss-Raum**, sonst wie vorher die Treppe/Falltür nach unten. | ✅ erledigt |
| 8 | **Relikt-Skills:** Skill „Stufe-1-Relikte gehen nicht mehr kaputt“, dann Stufe 2 usw. Skill „Eisenherzen“ entfernen; neuer Skill: 1 blaues Herz zusätzlich. | offen |
| 9 | **Maus-Empfindlichkeit** als Zahl mit Eingabefeld (Kommazahl), 1 zu 1 wie in Counter-Strike 2. | offen |
| 10 | **Fadenkreuz** einstellbar (auch aus), Einstellungen wie in CS2 (Länge, Dicke, Abstand, Punkt, Umriss, Farbe). | offen |
| 11 | **Blickrichtung der Gegner:** Kreis am Boden unter jedem Gegner, ein Viertel gefüllt = Blickrichtung (sieht man, ob man hinter ihm steht). | offen |
| 12 | **Leveln langsamer:** nach dem ersten Run etwa 80 % Erfahrung zur nächsten Stufe, nach dem zweiten ebenso. **Skill-Baum:** Skills mit Geld rechts (gehen von links nach rechts), Skills nur mit Skill-Punkten links (gehen von rechts nach links). | offen |
| 13 | **Dungeon-Brett** zeigt nur freigeschaltete Dungeons. **Lexikon** mit Gegnern, beim Dungeon sind seine Gegner aufgelistet (nach dem Lexikon von Smithy). | offen |
| 14 | **Oberfläche schöner:** bunter, Effekte, „Dopamin“; Vorschläge machen und direkt umsetzen. | offen |

Reihenfolge: 7 zuerst (baut auf dem Seil-Stand auf), dann 2, 3, 4, 1, 8, 6, 12, 9, 10, 11, 5, 13, 14 (die große Oberflächen-Aufgabe zuletzt, damit sie alles Neue mit erfasst).

## Erledigt

(neueste oben, mit Branch und Datum)

- **4** · `feature/startbild-einmal` · 2026-11-27 · „Hier klicken“ kommt nur beim ersten Mal nach dem Programmstart (MainMenu.title_seen). Danach (Hauptmenü aus Laden/Pause, Rückkehr aus dem Run) startet das Menü direkt am Amboss ohne Tür-Animation. Im Spiel: starten → Tür öffnen → Weiter → im Laden Esc → Hauptmenü → direkt das Menü.

- **3** · `feature/erste-ebene-klein` · 2026-11-27 · Erste Ebene (Dungeon der Glut): Start, 3 normale Räume, Boss und sicher ein Opferraum = 6 Räume; kein Shop, kein Geheimraum, kein Sonderraum (neue Felder in floors.json). Im Spiel: neues Spiel → Dungeon → M: Karte hat 6 Räume.

- **2** · `feature/schluessel` · 2026-11-27 · Start ohne Schlüssel (data/player.json keys 0). Schlüssel gehören zum Run und bleiben im Dungeon; der End-Bildschirm zeigt „Schlüssel zerbrochen: N“. Egon erklärt es im ersten Laden-Besuch (tutorial_dungeon). Im Spiel: neues Spiel → Laden-Tour bis zum Ende anhören → im Dungeon 0 Schlüssel; mit Schlüssel über die Leiter raus → End-Bildschirm.

- **7** · `feature/seil-treppe` · 2026-11-27 · Falltür und Boss-Item kommen nach dem ersten Boss wieder wie immer; das Seil kommt zusätzlich daneben, aber nur, wenn der Boss im Boss-Raum besiegt wurde. Egon nimmt den Rubin auch, wenn man ihn über die Falltür/Leiter heimbringt. Im Spiel: neues Spiel → ersten Boss besiegen → Falltür in der Mitte, Seil links daneben.
