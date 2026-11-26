# Fertige Systeme

> Die ausführliche Beschreibung aller fertigen Systeme (Dateien, Klassen, Werte, Verhalten) steht seit 2026-11-13
> in einer Datei je System unter `docs/systeme/`. Diese Datei ist das Inhaltsverzeichnis: nach dem Namen suchen,
> dann die genannte Datei lesen. `PROJEKT.md` Abschnitt 7 nennt nur die Namen.
> Nach jeder Aufgabe den passenden Eintrag in der Datei des Systems ergänzen bzw. ändern (neuer Abschnitt oben unter
> „Abschnitte“) und hier den Namen in die Liste des Systems eintragen. Jede Datei beginnt mit Zweck, meistgenannten
> Dateien, Daten, Tests und Fallen, darunter die Kurzfassung.
> Inhalte per JSON (Felder, Formeln): `docs/CONTENT.md`. Grafik-Vorgaben: `docs/ART_STYLE.md`.

| Datei | System | Inhalt |
|---|---|---|
| `docs/systeme/welt.md` | Welt und Karten | Karten, Gebiete, Türen, Reisen (Kutsche, Teleport, Weltkarte), Tageszeit und Licht, Abbau und Sammeln in der Welt, Tiere und Deko. |
| `docs/systeme/spieler.md` | Spieler | Spielerfigur, Bewegung, Inventar, Werkzeuge, Level und Skills des Schmieds, Aussehen und Charakter-Erstellung. |
| `docs/systeme/schmieden.md` | Schmieden und Herstellen | Schmelze, Esse, Gussformen, Amboss-Minispiel, Wassertrog, Werkbank, Rezepte, Qualität und Seltenheit, Verzaubern, Tränke, Schmuck, Garten als Zutatenquelle. |
| `docs/systeme/kampf.md` | Kampf und Dungeons | Automatischer Kampf (Adventure, Combatant, CombatRules), Gegner, Dungeons, Beute, Status-Effekte, Skills im Kampf, Kampffenster und Kampfbühne, Simulator. |
| `docs/systeme/helden.md` | Helden | Angeheuerte Helden: Gilde, Klassen, Level, Skillbäume, Ausrüstung, Rollen und IQ, Heldenfenster. |
| `docs/systeme/story.md` | Story und Dialoge | Story-Schritte, Dialoge, Story-Figuren, Cutscenes und Gesten, Nebenaufgaben, Tipps und Lehrgänge, das goldene Leuchten. |
| `docs/systeme/wirtschaft.md` | Wirtschaft | Gold, Aufträge und Kunden, Ruf, Miete, Händler und Läden, Ninas Laden, Lotte als Gehilfin, Tagesbilanz, Belohnungen, Erfolge. |
| `docs/systeme/haus.md` | Haus und Werkstatt | Hausausbau, Möbel und Baumodus, Raum-Designer, Werkstatt-Upgrades, Lagerkisten, Ruhmeshalle. |
| `docs/systeme/turniere.md` | Turniere | Schmiedeturnier, Heldenturnier, Liga-Turniere mit Rängen, Turnierhallen, Turnierpreise, Arenen. |
| `docs/systeme/ui.md` | Oberfläche | HUD, Fenster und Menüs allgemein, Einstellungen, Tooltips, Lexikon, Startbildschirm, Sprachen, Komfort-Funktionen. |
| `docs/systeme/kern.md` | Kern | GameState, ContentDB und JSON-Inhalte, Events, Speichern und Laden, DevTools und Admin-Panel, Tests, Projekt-Einstellungen, Performance-Regeln. |
| `docs/systeme/audio.md` | Audio | Geräusche, Musik, Lautstärke-Regler, Stimmen der Völker. |
| `docs/systeme/referenz.md` | Referenz-Ordner und Werkzeuge | Der Ordner assets/_reference/ (nicht im Spiel): Back-Skripte, Vorlagen, Werkzeuge für Karten und Grafik. |

## Welt und Karten (`docs/systeme/welt.md`)

- Finsterstadt: Kanäle, Burg, Nebel, Laternen, Geister (2026-11-21, Branch `feature/finsterstadt-nebel`)
- Critter (2026-10-31)
- Wüste, Sahrim und Wüstenkompass (2026-10-27, Branch `feature/wueste`)
- Weltkarte und Teleport-Karte (2026-10-28, Branch `feature/weltkarte`)
- Kutsche mit Zielwahl und Reisetagen, Admin-Uhr (2026-10-28, Branch `feature/kutsche-zeit`)
- E geht an das Nächste (2026-10-28, Branch `feature/quest-durchlauf`)
- Sahrim als Glaskuppel (2026-10-29, Branch `feature/wuestenstadt`)
- Schleich-Labyrinthe und neuer Weg in die Finsterburg (2026-10-29, Branch `feature/festung-
- Sylvaris erweitert und Turnier-Austragungsorte (2026-10-30)
- Offene Karten (2026-10-31, `assets/_reference/open_maps/`)
- Dorfkutsche und Kutscher Jupp (2026-11-01, Branch `feature/kutsche-buergermeister`)
- Tageszeit
- Zeit-Kompass
- Türen und Szenenwechsel
- Dorf / Schmiedeplatz
- Teleport-Kristall
- Reisen
- Marktplatz
- Dorfplatz
- Wohnviertel
- Licht in der Nacht
- Welt öffnet sich mit der Geschichte
- Wald
- Dorftor & Kreuzung
- Südweg
- Mine-Eingang
- Mine
- Tages-Ressourcen
- Alte Mine / Mine 2
- Datum
- Kalender
- Dorfbewohner
- Abbau

## Spieler (`docs/systeme/spieler.md`)

- Schmiedin, Frauen-Kleidung und Schneiderin Wilma (2026-11-25)
- Powernap im Bett (2026-11-25)
- Spielerfigur
- Spielerwerte
- Spieler-Level
- Spieler-Skills
- Charakter-Fenster
- Spitzhacken
- Holzfälleräxte in allen Metallen (2026-10-18, Branch `fix/holzfaelleraxt-metalle`)
- Inventar
- Feste Figuren
- Charakter-Baukasten
- Charakter-Editor
- EXP und PEXP
- Schuhe des Schmieds
- Spitzhacke aus Teilen

## Schmieden und Herstellen (`docs/systeme/schmieden.md`)

- Sammelbuch (2026-11-25)
- Glückstreffer (2026-11-25)
- Verzauberer, Trank-Rezepte und bessere Erde (2026-11-05, Branch `feature/sylvaris-verteidi
- Heilige Kristalle mit Animation (2026-11-01, Branch `feature/heilige-kristalle`)
- Erz-Reihenfolge (2026-11-03, Branch `feature/erz-reihenfolge`)
- Zauberstab-Minispiel mit Pixel-Grafik (2026-11-03, Branch `feature/zauberstab-minispiel-gr
- Schmiede-Raum
- Schmiedeablauf (komplett)
- Stationen
- Baukasten / zusammengesetzte Items
- Rezepte freischalten
- Hitze der Esse
- Rezepte
- Gussform-Icons
- Detaillierte Item-Icons
- Herstellen
- Herstellungs-Fenster
- Schmiede-Minispiel
- Abkühlen
- Amboss zeigt nur Schmiedbares
- Barren-Slots am Gussofen (2026-10-19, Branch `feature/gussofen-barren-slot`)
- Barren-Auswahl am Gussofen (2026-11-05, Branch `feature/gussofen-barren-auswahl`)
- Auswahlliste an allen Stations-Slots (2026-11-09, Branch `feature/slot-auswahl`)
- Abgabe-Slots und Wassertrog (2026-10-19, Branch `feature/abgabe-slot`)
- Schmelze übersichtlicher (2026-10-18, Branch `feature/schmelze-slots`)
- Seltenheit
- Seltenheit und Qualität
- Sockel
- Schleifstein
- Gerberbank
- Phiolen-Tisch
- Rezept-Navigation
- Waffentypen
- Rüstungen (Kupferset)
- Zaubertisch
- Zusammenbau-Fenster
- Items
- Schmelze-Logik
- Schmelze-Fenster
- Legieren
- Bronze statt Nickel
- Sand und Glas
- Bögen und Pfeile
- Aufwertungstisch und Köcher
- Bögen und Pfeile
- Aufwertungstisch und Köcher
- Freischalt-Popups

## Kampf und Dungeons (`docs/systeme/kampf.md`)

- Endloser Turm (2026-11-25)
- Kampffiguren je Metall und Sets (2026-11-12, Branch `feature/paladin-kampffigur`)
- Status-Effekte erklärt, Tooltip zum Hineinfahren (2026-11-11, Branch `feature/statuseffekt
- Segen der Weisheit mit Gruppenschild (2026-11-11, Branch `feature/segen-der-weisheit-schil
- Skill-Skalierung mit Attributen und Duell-Tabelle (2026-11-08, Branch `feature/skill-skali
- Hydra, Skill-Tooltip, Schmieden fern der Schmiede, Sumpf-Beute, Level (2026-11-08, Branch 
- Nebelfürst und Moorschleime (2026-11-06, Branch `feature/sumpf-boss-schleime`)
- Schwere Dungeons (2026-11-05, Branch `feature/dungeon-schwierigkeit`)
- Mana-Verbrauch (2026-11-05, Branch `fix/mana-verbrauch`)
- Rassen, Elemente und Erz-Stufen (2026-10-26)
- Aufgeben im Kampffenster (2026-10-28, Branch `feature/aufgeben`)
- Mehrere Lebensbalken für Bosse (2026-10-28, Branch `feature/boss-balken`)
- Schadensarten, Elemente, Resistenzen, Krit
- Rüstungs-/Magiedurchdringung, Rüstungs-Debuffs und -Buffs
- Status-Effekte
- Kampf
- Dungeon-Brett
- Dungeons und Gegner
- Abenteuer / Idle-Kampf
- Kampffenster
- Ausrüstung im Kampf
- Kampf-Animationen
- Eigene Monster-Animationen
- Kampf-Effekte als Bilder (2026-10-23)
- Kampf-Effekte v2 (2026-10-26)
- Eigene Angriffs-Animation (2026-10-23, bisher nur Bruno)
- Kampf-Effekte
- Loot-Kiste

## Helden (`docs/systeme/helden.md`)

- Skillbäume der Helden (2026-10-19, Branch `feature/skillbaeume`)
- Helden-Mana pro Level und Tränke (2026-10-19, Branch `feature/skillbaeume`)
- Helden umbenennen und Heldenfenster aufgeräumt (2026-11-12, Branch `feature/helden-fenster
- Helden
- Helden-Limit (geändert 2026-11-01)
- Level und Skillpunkte
- Skills
- Schurke
- Paladin
- Abenteurergilde
- Anheuerbarer NPC
- Heldenliste
- Waffen pro Klasse und Klassen freischalten

## Story und Dialoge (`docs/systeme/story.md`)

- Alle Cutscenes auf StoryCutscene, Player.lock (2026-11-13, Branch `feature/cutscenes-storycutscene`)
- Weg in die Finsterstadt: Brief, Sylvaris, Kutsche, Südtor (2026-11-11, Branch `feature/ges
- Lotte als Botin (2026-11-11, Branch `feature/lotte-botin`)
- Story-Animationen, dritte Runde (2026-11-10, Branch `feature/story-animationen-3`)
- Story-Animationen, zweite Runde (2026-11-10, Branch `feature/story-animationen-2`)
- Waffen für Sylvaris und zwei Enden der Nacht (2026-11-05, Branch `feature/sylvaris-verteid
- Goldenes Leuchten (2026-10-26, Branch `feature/einstieg-leuchten`)
- Teil 4: Eisquell, Heldenturnier und Sturmtempel (2026-10-27, Branch `feature/story-teil-4`
- Teil 5: Sumpf, Finsterburg und Schleichen (2026-10-27, Branch `feature/story-teil-5`)
- Story-Umbau: Spieler handelt selbst, Entscheidungen, Dorf-Teil (2026-10-28, Branch `featur
- Selbst erkunden (2026-10-28, Branch `feature/selbst-erkunden`)
- Goblinburg-Rätsel (2026-10-29, Branch `feature/goblinburg-umbau`)
- Fix Sternenstahl-Quest (2026-10-29, Branch `fix/sternstahl`)
- Nebenquests (2026-10-31, Branch `feature/nebenquests`)
- Die Gosse und Kapitel 13/14 (2026-10-18, Branch `feature/kapitel13-gosse`)
- Lich
- Story
- Story-Ablauf bisher
- Story-Figuren und Dialoge
- Zwischensequenzen (2026-10-23)
- Story-Quests und Einkaufslisten
- Erster Auftrag „Eine Axt für den Holzfäller“

## Wirtschaft (`docs/systeme/wirtschaft.md`)

- Wunsch-Kunden (2026-11-25)
- Steam-Erfolge (2026-10-18)
- Belohnungsmomente (2026-10-23, Branch `feature/belohnungsmomente`)
- Tagesbilanz und Eilaufträge (2026-10-23, Branch `feature/tagesbilanz`)
- Belohnungs-Takt (2026-10-23, Branch `feature/belohnungstakt`)
- Waffen mit Geschichte, Ruhm, Lob der Kunden (2026-10-23, Branch `feature/waffen-geschichte
- Aufträge nach Können, IQ-Tränke, Rollen, Schmiedegasse (2026-10-24, Branch `feature/auftra
- Lotte als Gehilfin (2026-11-01, Branch `feature/lotte-gehilfin`)
- Auftragsbrett und Omas Abgang (2026-10-19, Branch `feature/oma-geht-brett`)
- Gold
- Erfolge
- Marktstand mit Händler
- Händler laufen nach Ladenschluss weg
- Ninas Laden
- Miete
- Händler
- Händler-Sortiment und Stückzahlen
- Kunden und Kundenaufträge
- Preise
- Ruf
- Aufträge / Quests
- Auftraggeber
- Auftragsbuch
- Aufgaben-Tracker
- Reisender
- Ninas Laden

## Haus und Werkstatt (`docs/systeme/haus.md`)

- Raum-Designer, Werkstatt-Upgrades und Ruhmeshalle (2026-11-01, Branch `feature/haus-design
- Schlafzimmer
- Haus von Oma Hilde
- Lagertruhe
- Lagerkisten
- Loot-Kiste in der Werkstatt
- Hausausbau

## Turniere (`docs/systeme/turniere.md`)

- Liga-Ränge und Turnierhallen (2026-11-13, Branch `feature/turnierhalle-raenge`)
- Liga-Turniere und Rangliste (2026-10-31, Branch `feature/turnier-rangliste`)

## Oberfläche (`docs/systeme/ui.md`)

- Ziele auf drei Ebenen im Tracker (2026-11-25)
- Admin-Panel auf dem Handy (2026-11-16, Branch `feature/handy-admin`, übergangsweise)
- Handy: Laufen per Tippen oder Joystick (2026-11-16, Branch `feature/handy-laufen`)
- Handy-Version: Touch und Tippen (2026-11-16, Branch `feature/handy-touch`)
- Fenster und Kampfbühne schneller (2026-11-13, Branch `feature/fenster-performance`)
- Komfort aus der Ideenliste (2026-10-18)
- Einstellungen mit Reitern (2026-10-18)
- Rückmeldungen 2026-11-03 (Branch `fix/feedback-1103`)
- Startbildschirm (2026-11-05)
- Lexikon (2026-11-09, Branch `feature/lexikon`)
- Stations-Menü-Basis
- Komfort-Paket (2026-10-18)
- Alpha-Feedback (2026-10-18, Branch `fix/alpha-feedback`)
- Item-Tooltip
- Startbildschirm und Hauptmenü
- Fenster-Titelleiste
- Seitenmenü
- UI-Theme
- HUD
- Shops öffnen das Inventar
- Verhalten (aus `PROBLEME.md` übernommen, gewollt)

## Kern (`docs/systeme/kern.md`)

- Spiel-Protokoll für Tester (2026-11-25)
- Ein Feuer für Esse, Schmelze und Phiolen; Einstellungen gebündelt; Nachschlagen statt Suchen (2026-11-13, Branch `fix/pruefbericht-kleinreste`)
- Story-Dateien und Doku je System (2026-11-13, Branch `docs/systeme-und-story-aufteilen`)
- Godot-Architektur: Events, Kartenvorlage, NpcInfo, Renderer, Timer (2026-11-13, Branch `fe
- Prüfbericht-Korrekturen: Test-Umgebung, Speichern, Prüfer, DevTools, ForgeFire (2026-11-13
- Inhalte als JSON
- Speichern und Laden
- GameState-Autoload

## Audio (`docs/systeme/audio.md`)

- Völker sprechen verschieden (2026-10-28, Branch `feature/rassen-sprache`)

## Referenz-Ordner und Werkzeuge (`docs/systeme/referenz.md`)

- Ordner `assets/_reference/` (nicht im Spiel)
- Standard-Bilder
