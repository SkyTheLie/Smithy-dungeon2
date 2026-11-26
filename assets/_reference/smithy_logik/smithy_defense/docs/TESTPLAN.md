# Testplan: offene Handtests

Stand 2026-11-22: 91 Einträge in 7 Sitzungen (je etwa 1–2 Stunden, gut zu zweit aufteilbar).
Die genaue Anleitung jedes Punkts steht in `docs/VERLAUF.md` unter „Noch zu testen“, Abschnitt mit derselben Nummer, gleicher Name.
Die Logik ist headless getestet. Hier geht es um das, was ein Test nicht sieht: sieht es gut aus, fühlt es sich richtig an, versteht man es.

## So geht's

1. Sitzung wählen, Vorbereitung erledigen, dann Punkt für Punkt der Anleitung in VERLAUF folgen.
2. Passt alles: hier `[x]` setzen, den Eintrag in VERLAUF löschen (steht er auch in `PROJEKT.md` Abschnitt 8, dort ebenfalls).
3. Passt etwas nicht: unter „Gefundene Fehler“ unten eine Zeile eintragen (Punkt, was passiert, wie oft). Daraus wird ein `fix/`-Branch.
4. Neue Einträge in VERLAUF bekommen hier eine Zeile in der passenden Sitzung.

**Videos statt selbst spielen:** `sh assets/_reference/testvideos/record.sh session5 D:/Smithy/Testvideos/Sitzung5` nimmt die Szenen einer Sitzung im echten Spiel auf (`1.mp4`, `2.mp4` …, oben links Nummer und Titel; Dialoge werden im Lesetempo weitergeklickt, Kämpfe als gewonnen gezählt). Einzelne Videos: Nummern anhängen. Jedes Video läuft mit eigenem leeren Spielstand-Ordner. Welche Nummer zu welchem Punkt gehört, steht in der Sitzung.

**Werkzeuge (Admin-Panel, Taste P, nur aus dem Editor):** Quests/Kapitel-Sprung (an jede Story-Stelle), Karten (überall hin reisen), Flags, Items mit Seltenheit und Qualität, Ränge (RP setzen, „Turniere jederzeit“), Events (Knopf „Sofort“ in Dungeons), Haus (Ausbaustufe).
Allgemein bei jeder Szene darauf achten: jeder Teil läuft genau einmal, danach kann man wieder laufen, nichts steht in Wänden, die Leere außerhalb der Karte ist nie zu sehen, Texte passen zu dem, was man sieht.

---

## Sitzung 1: Spielanfang und Schmieden (VERLAUF Abschnitte 1 und 2)

Vorbereitung: „Neues Spiel“ bis zum ersten Kunden spielen, danach Admin-Panel für Items und Stationen.

- [ ] Schmiede-Verteidigung (2026-11-25): Schmiede mit Körper (Einheiten gehen außen herum), Boss schlägt die Schmiede nicht, wenn seine Einheit stirbt, „Angebot!“-Karten mit gelbem Rahmen
- [ ] Schmiede-Verteidigung (2026-11-25): späte Bosse schwächer (Mumie Teil 18 schaffbar?)
- [ ] Schmiede-Verteidigung (2026-11-25): Bosse mit Rundumschlag, Fähigkeiten je Gebiet und Raserei; Einheiten leuchten ab R2 farbig
- [ ] Schmiede-Verteidigung (2026-11-25): seltener durch Siege, Aufträge je Einheit, Gebietsregeln ab Teil 2, Ansturm, Laden-Jackpot, Gebäude-Banner, HUD durchsichtig, Meisterschafts-Preise später Felder
- [ ] Schmiede-Verteidigung (2026-11-25): Tab Relikte: eingesetzte Relikte nur oben im Platz, nicht mehr in der Liste
- [ ] Schmiede-Verteidigung (2026-11-25): Bosskampf nur mit Boss nach 10 s ×1,5, nach 15 s ×2; Reliktplatz 100 / 800 / 1600 Meisterschaft
- [ ] Schmiede-Verteidigung (2026-11-25): Bäume ziehen/zoomen, Feld kleiner, Hammer-Rückstoß bleibt im Bild, Feuer-/Erdkristall 2/3 Schläge, Gegner schneller, Stopp bei neuer Einheit, Pakete mit 3 Bildern und gemischt, Filter „Im Laden“, mehr Meisterschaft später, Körper, ein Spielstand, Sprache nur einmal, Schatztruhe mit Relikt-Karte, Relikt im Laden, weniger Kristallmünzen später, 1 Einheit je Kristall (30 % zwei), Teile nach Thema, Esc-Pausenmenü
- [ ] Schmiede-Verteidigung: 28 neue Aufträge (42 statt 14), Tab Aufträge bleibt übersichtlich und scrollt, Übersetzungen
- [ ] Schmiede-Verteidigung: Effekte (Hammer-Wucht, Splitter, Münzflug, Kristall-Licht, Nacht, Wetter, Banner, Pfeile, Boss, Fall, Fenster-Effekte), flüssig mit vielen Gegnern
- [ ] Schmiede-Verteidigung: Fenster zwischen den Runs (feste Größe, Laden-Karten, Bäume mit der Maus ziehen)
- [ ] Schmiede-Verteidigung: Kristall-Pfad (Boss + Kauf, ×1,5 Preis, ×2 Einheiten), neue Kristalle Wasser/Blitz/Licht, Hammer wächst mit, Schleicher nach Hammertreffer sichtbar
- [ ] Smithy Roguelike als eigenes Projekt: Name, Spielstände und Einstellungen übernommen, APK neben Smithy
- [ ] Schmiede-Verteidigung (Branch `feature/schmiede-verteidigung`): Wellen, Hammer-Kreis, Münzen, Fenster nach dem Fall
- [ ] Schmiede-Verteidigung: Feuerkristall (15) » Harpyien, Relikte-Tab mit 3 Plätzen, Wellen doppelt so stark, größeres Feld
- [ ] Schmiede-Verteidigung Dungeons als Teile (Boden, Gegner, Boss), Freischalten, Icon-Baum
- [ ] Schmiede-Verteidigung endlose Runs (Teile, Boss + Relikt), Gegner erst auf Einheiten, Kristall-Chancen 80/19/1, Seltenheit R1–R5, Entdeckungs-Zoom
- [ ] Schmiede-Verteidigung Trupps (15 von links/rechts, alle 5 s), Aufträge mit Einkommen, Sammlung, Taverne, Sonderangebote
- [ ] Schmiede-Verteidigung Roguelite: Phase mit Zufallsangeboten + Auffrischen, Einheiten nach Seltenheit, Elite + Relikt-Wahl, Schleicher, Meisterschaft gespeichert
- [ ] Persisch und Textgröße: Flagge „فارسی“, persische Schrift lesbar, Regler Textgröße für Tipps/Dialoge/Werte/Aufgaben
- [ ] Sprachwahl vor dem Hauptmenü: Flaggen ohne Spielstand, Klick startet in der Sprache, mit Spielstand keine Flaggen
- [ ] Playtest Texte und Tipps: richtige Tipps zur richtigen Zeit, Hilde, Spinnweben, Texte
- [ ] Playtest Visuell: kalte Schmiede, Klopfen bei Hilde, Überfall, Bretter in der Mine, Goblinburg
- [ ] Schmiede-Tutorial: Tafeln, vorführender Hammer, „?“ zeigt es wieder, auf Englisch
- [ ] Einleitung mit Suche, gelber Rahmen: Rahmen an den Reglern, Suche „seltenheit“
- [ ] Tipp-Fenster scrollt: lange Tipps höchstens 9 Zeilen, Scrollbalken
- [ ] Zusammensetzen pixelgenau: Schwert, Axt, Spitzhacke, Speer, Streitkolben
- [ ] Schild-Griff aufnieten: 3 Niete, Griff sitzt sichtbar auf der Platte
- [x] Bogen spannen: Rahmen anhalten, Seil einhängen, Langbogen
- [x] Heiße Barren in Form ihres Teils
- [x] Auswahlliste an der Schmelze
- [x] Barren-Wahl bleibt (Gussofen)
- [x] Leder: Stufen und Reihenfolge
- [x] Zweihandwaffe sperrt die linke Hand
- [x] Zauberstab-Absturz: Eisen-Zauberstab mit Kupfer- und Eisenschaft im Inventar
- [x] Poliertisch
- [ ] PixelLab-Grafiken: Poliertisch drehen, Höllenleder-Bilder
- [x] Schmiede-Schild: kaufen, aufhängen, umhängen, Ausbaustufe, Themen
- [x] Ganzen Stapel kaufen (Strg+Klick)
- [x] Gussformen gleich teuer
- [x] Ninas Laden ab 6 Uhr
- [x] Admin-Panel: Seltenheit und Qualität wählen
- [x] Skill-Popup vorn
- [x] Lexikon: Items nach Gruppen
- [ ] Erfolge erweitert
- [ ] Seltenheitsnamen Spanisch/Französisch (Sprache umstellen, neu starten)
- [ ] Nachbarkarten vorladen (am besten mit `game.exe`)

## Sitzung 2: Turniere (VERLAUF Abschnitte 3, 4 und 5)

Vorbereitung: Spielstand nach dem großen Schmiedeturnier oder Admin-Flags `smith_tournament_won` und `hero_tournament_won`, ein freier Held; Admin » Ränge: „Turniere jederzeit“ an, RP je Punkt passend setzen; „Sofort“ in Dungeons an.

- [ ] Schmiede-Bots mit Skills und Werkstatt: Herold nennt Fertigkeiten und Werkstatt, bis Silber leicht, ab Gold schwer, ab Silber schleifen/polieren/gerben
- [ ] Schmiedeturnier-Gegner: Anzeigetafel, Laufwege des Gegners, er lernt dazu
- [x] Schmiedeturnier: Abgeben und Herold-Texte
- [x] Siegerfeier im Schmiedeturnier
- [x] Nur noch Ligen: Story-Turniere in Leonheim, Eisquell, Sylvaris
- [x] Arenahalle: ein Helden-Turnier von vorn bis hinten (Fenster gesperrt, Baum, Ring, Kampffenster bleibt offen, EXP, Feier)
- [x] Spiel um Platz 3
- [x] Alle Skillbäume als Turniergegner
- [ ] Schmuck der Liga-Gegner (ab Silber)
- [x] Liga-Abzeichen (links neben „Lv“, Palladium glänzt)
- [x] Liga-Siegerpreise (3 Karten, Geschenke, Themen)
- [x] Turnier-Marken und Turnier-Händler (Preise)
- [x] Pokale der Städte
- [x] Turnierhallen, Ränge und Anmeldung (Admin-Reiter, „[???]“, Öffnungszeiten)
- [x] Jede Stadt ihre eigene Halle (Eisquell, Sahrim, Finsterstadt)
- [x] Gezeitenhalle in Eisquell (großes Heldenturnier der Story)
- [x] Kampflichtung in Sylvaris
- [x] Schmiede-Liga in Sylvaris
- [x] Turnierplatz und Arena-Pyramide in Sahrim
- [x] Eigene Musik je Arena

## Sitzung 3: Story Teil 4–6 (VERLAUF Abschnitt 6)

Vorbereitung: Admin » Quests, der Reihe nach zu den Schritten springen (Dorf-List, Kahns Halle, Hafen-Angriff, Mauerkrone, Finsterburg, Thronsaal, Flucht, Lichtung).

- [x] Übergaben, späte Anleitungen, Eisquell-Nacht
- [x] Hafen-Angriff nach Kahns Nacht (Strohlager, Tipp in Eisquell, Subar, Schützen)
- [x] Hafen-Brände und Hammer an den Eissäulen
- [x] Mauerkrone nach dem Kampf (Lake taumelt, Subar stößt dich zurück)
- [x] Story-Fehler Teil 5–6 (Aurelius am Schild und an der Schulter, Lotte im Versteck, Torgai und Subar)
- [x] Story-Feinschliff Teil 5 (Torhof, Thronsaal, Fackeln, Lichtung, Morgen-Bildschirm)
- [x] Story-Animationen ab dem Schleichen (Torhaus, Dorf-List, Großer Rat, Versteck, nach dem Ende)

## Sitzung 4: Story Teil 7, Finsterstadt (VERLAUF Abschnitt 7)

Vorbereitung: Admin » Quests ab Ankunft am Südtor der Finsterstadt, dann weiter bis „Die rechtmäßige Erbin“.

- [ ] Finsterstadt im Nebel (Nebel, Laternen, Geister, Kanäle, Schleich-Karten, Arenen)
- [ ] Eistreppe und Vorhang (Eistreppe in Eisquell, Verfolgung, Hinterhof der Kelterei)
- [ ] Finsterstadt-Feinschliff (Nyra im Umhang, Ketten, Fessel, Corvin kniet, Halvard am Amboss, Namensschilder)
- [ ] Umhang, Wachstube, Burg-Ausgang
- [ ] Westviertel der Finsterstadt (und Barrikade im Heerlager)
- [ ] Steckbrief als Trophäe

## Sitzung 5: Story Teil 8 und nach dem Ende (VERLAUF Abschnitt 8)

Als Videos: `D:/Smithy/Testvideos/Sitzung5/1.mp4` … `15.mp4` (Nummern in Klammern). Selbst zu prüfen bleibt nur, was kein Video zeigt: alte Spielstände `slot_1`/`slot_2` laden, Ortsnamen in der Speicherliste, Kapitel-Sprung zurück im Admin-Panel.

- [x] Altar der Neun umgebaut (Videos 4, 5, 6, 9: Tor, Kristalle, Pfade, Schlacht, Lake, Siegel)
- [x] Vor dem Altar: Aufbruch des Rats, Portal, Torwächter (Videos 1, 2, 10)
- [x] Torwächter, Altar nach Sprung, Quest-Sprung, Ortsnamen (Video 2; Rest von Hand, siehe oben)
- [x] Heerführer im Altar (Video 5: Blickrichtung, erst laufen, dann Text)
- [x] Altar-Schlacht: Ausdauer erst nach dem ersten Sieg (Video 5, Brett)
- [x] Erzähler und Szenen nur einmal (Videos 7 und 6)
- [x] Ankunftstext vor dem Altar nur einmal (Video 3)
- [x] Amboss im Altar und die wahre Fassung (Video 8)
- [x] Bündnis-Waffen im Tracker (Video 11)
- [x] Altar nach dem Ende (Video 12)
- [x] Kristall-Fassung am Altar (Video 13)
- [x] Bürgermeister am Lebensbaum (Video 14)
- [x] Lebensbaum heilen (Video 15, auch mit dem Giftkristall welken lassen)

## Sitzung 6: Welt, Spelunke, Musik, Beute, Balancing (VERLAUF Abschnitt 9)

Vorbereitung: später Spielstand mit guten Helden; Admin » Karten zum Reisen, Admin » Items für Münzen bzw. Gold.

- [ ] Begehbare Häuser überall (Gasthaus, Kramladen, Finsterstadt, Sahrim-Zelte, Heerlager, Eisquell)
- [ ] Begehbare Häuser im Heimatdorf (16 eingerichtete Häuser, Statisten gehen abends in ihr Haus)
- [ ] Begehbares Bauernhaus (Gustav und Erna, Dorfplatz)
- [ ] Leben auf Zelt- und Häuserkarten (Heerlager, Sahrim Ost/West, Wüstenstadt, Schmiedegasse, Eisquell: Leute laufen, abends hinein)
- [ ] Gilde wächst mit dem Ausbau (Außenbild und Halle je Stufe, ein bis vier Tische)
- [ ] Schlafsaal der Gilde und gerader Pokalschrank (Treppe ab Stufe 1, 2/4/6 Betten oben)
- [ ] Gildenausbau sichtbar und an der Story (Etagenbetten, Übungsecke, Pokalschrank, Helden-Level, Ausdauer, Admin-Knöpfe)
- [ ] Karten aufgeräumt (Goblinhöhle und 14 weitere Karten, nirgends hängen bleiben)
- [ ] Lavaberg und Goblinhöhle aufgeräumt (und der Admin-Haken „Sofort“)
- [x] Teleporter an Mine und Wüstenrand weg
- [x] Spelunke, Vex und Höher oder Tiefer
- [x] Poker (Bots, Blinds, Gewinner in Gold)
- [x] Restliche Musik (Hauptmenü, Kampf, Boss, Wüste, Abspann)
- [x] Musik für die späten Gebiete (Schleife ohne Knacken, Lautstärke)
- [x] Platin in Teil 8, Sternenerz nur vom Boss
- [x] Beute Teil 6–8: Seelensplitter, Platin, Leder
- [x] Balancing (Helden ohne Heiler, 3 von 4 Läufen, fühlt es sich fair an?)

## Sitzung 7: Handy und Export (VERLAUF Abschnitt 10)

Vorbereitung: Release-Export bauen (`assets/_reference/android/build_release.sh`), für die Handy-Punkte die Test-APK (`docs/ANDROID.md`).

- [ ] X-Knopf auf dem Handy
- [ ] Handy: Baumenü
- [ ] Handy: Laufen per Tippen oder Joystick
- [ ] Handy: Touch und Tippen
- [ ] Release-Export (APK und game.exe ohne Dev-Tools, Dialoge da)

---

## Gefundene Fehler

Format: `Datum · Sitzung/Punkt · was passiert · wie oft (immer / manchmal / einmal)`

