# Entscheidungen

Neue Entscheidungen unten anhängen (Datum, was, warum).

- **2026-11-26 · Eigenes Projekt neben Smithy** (`Game/dungeon_smithy`), Assets kopiert statt verlinkt: Smithy bleibt unberührt, beide Spiele können sich unabhängig ändern.
- **2026-11-26 · 3D-Räume, Gegner/Items als Billboards:** Smithy-Grafik ist 2D; Billboards (`Sprite3D`, immer zur Kamera) nutzen sie direkt.
- **2026-11-26 · Pixel-Look über SubViewport** (640×360, scharf hochskaliert) statt Shader: einfach, Oberfläche bleibt scharf.
- **2026-11-26 · Schüsse ohne Physik-Körper:** Strahlen-Abfragen für Wände, Abstand für Gegner (`Enemy.hits`). Einfach zu testen, Abprallen und Zielsuche leicht.
- **2026-11-26 · Räume liegen nebeneinander in einer Welt** (kein Szenenwechsel pro Raum): man läuft echt durch die Türen, die Minimap kennt alle Räume.
- **2026-11-26 · Leben in halben Herzen** (wie üblich bei Roguelikes), Gegner machen 1–2 halbe Herzen.
- **2026-11-26 · Startreichweite 2,5 m** (Wunsch „2 m oder so“): 2 m war in 15-m-Räumen sehr knapp. In `data/player.json` änderbar.
- **2026-11-26 · Tab schaltet die große Karte um** (statt halten).
- **2026-11-26 · Kein Speichern eines Runs:** Tod beendet den Run. Nur Einstellungen werden gespeichert.
- **2026-11-26 · Hauptmenü aus Smithy** (Schmiede-Tür, Amboss, Flaggen); „Weiterspielen“/„Laden“ entfallen, Einstellungen sind ein eigenes kleines Fenster.
- **2026-11-26 · Strahl schlägt Bomben-Modus:** beide zusammen = Strahl, der am Ende explodiert (Synergie „Sprengstrahl“).
- **2026-11-26 · Fortschritt zwischen Runs wird gespeichert** (`user://progress.cfg`): für Lexikon und Freischaltungen. Der Run selbst bleibt ungespeichert.
- **2026-11-26 · Item-Raum = alle Items** (außer geheimen und gesperrten), Boss = nur einfache Werte-/Herz-Items: Bosse geben verlässlich etwas Solides, der Item-Raum bleibt überraschend.
- **2026-11-26 · Blaue Herzen** kommen oben auf die roten, werden zuerst verbraucht und nicht geheilt (genre-üblich). Rot + Blau zusammen höchstens 12.
- **2026-11-26 · 6 Ebenen, 3 Themen, zufällige Bosse:** Das Thema wechselt alle 2 Ebenen; die zweite Ebene eines Themas ist härter (`hp_mult`).
- **2026-11-26 · Nur Nachbarräume zeichnen:** weniger Lichter und Meshes, wichtig für GL Compatibility.
- **2026-11-26 · Genre-Mechaniken mit eigenen Namen:** Sonderraum nach dem Boss heißt Glutpakt (Herz-Container gegen Item) oder Schrein (gratis); Opferstein; Geheimraum per Bombe. Regeln an das Genre angelehnt, Zahlen eigene.
- **2026-11-26 · Glück** erhöht Beute und alle Zufallseffekte (+4 % je Punkt).
- **2026-11-26 · Gegner-Sounds im Code erzeugt** (SoundSynth): es gibt kaum passende Dateien; so hat jeder Gegner einen eigenen Laut, einstellbar in den Daten.
- **2026-11-26 · Charaktere zählen wie ein Item:** keine Sonderregeln, alles über stats/flags/mode. Krieger-Freischaltung (Ebene 3) war nicht vorgegeben, in `characters.json` änderbar.
- **2026-11-26 · Keine Decken,** Steine höher als die Schusshöhe.
- **2026-11-26 · Hauptwaffe = Start-Item** (Glutstab, Jagdbogen, Kriegerschwert): Waffen sind normale Items und kombinieren sich über Synergien („Waffen kreuzen“, z. B. Feuerhieb = Schwert + Feuerstab). Grund: Die Kriegsaxt hat beim Magier den Feuerball ersetzt. Wunsch des Entwicklers: kombinieren statt tauschen.
- **2026-11-26 · Tierlaute vor Angriffen** (`cries` in `enemies.json`): Gegner kündigen Angriffe hörbar an; erst Rattenkeller.

## Smithy Dungeon 2

- **2026-11-26 · Teil 2 als eigenes Projekt** (`Game/Smithy_Dungeon_2`, Repo `SkyTheLie/Smithy-dungeon2`), Kopie von Dungeon Smithy `main`: der Dungeon-Teil läuft sofort, Dungeon Smithy bleibt unberührt. Eigener Projektname „Smithy Dungeon 2“ = eigener `user://`-Ordner.
- **2026-11-26 · Smithy-Logik als Bibliothek statt im Spiel** (`assets/_reference/smithy_logik/`, durch `.gdignore` nicht geladen): Smithy und seine Forks haben dieselben Klassennamen und Autoloads (`GameState`, `ContentDB`, `Language`), zusammen im Projekt würde Godot nicht starten. Smithy komplett, von den Forks nur abweichende Dateien. Systeme werden einzeln übernommen und angepasst.
- **2026-11-26 · Assets:** alle Bilder/Töne aller Smithy-Spiele (Smithy-Satz war schon da, dazu 22 Dateien aus Smithy, Erfolge, LAN).
- **2026-11-26 · Antworten des Entwicklers:** ein Tag = ein Run; erneutes Würfeln wird teurer; Ausrüstung bleibt beim Tod, Inventar (außer sicherem Platz) und mitgenommenes Geld sind weg; Dungeon bleibt 1 : 1 wie Dungeon Smithy (3D); der Händler heißt **Egon Ehrlich** (Charakter-Datei `docs/figuren/EGON_EHRLICH.md`, Dialoge werden daraus gebaut).
- **2026-11-26 · Beute in eigener Datei** (`data/loot.json`, Gegner-Id → Tabelle) statt in `enemies.json`: dort steht jeder Gegner in einer langen Zeile; so bleibt die Beute an einem Ort und der Test prüft, dass jeder Gegner etwas fallen lässt.
- **2026-11-26 · Münzen = Gold des Runs:** Die Run-Münzen sind das Gold, das man nach Hause bringt (bis 9999). Das Geldbündel im Inventar zeigt sie nur an, es belegt keinen Platz. `per_coin`-Items zählen höchstens 99 Münzen, damit mitgebrachtes Gold sie nicht zu stark macht. Freischaltung „Münzen erreicht“ zählt nur im Run gefundene Münzen (`bring_gold` zählt nicht).
- **2026-11-26 · Tab = Inventar, M = Karte:** Wunsch des Entwicklers (Tab zeigt das Inventar).
- **2026-11-26 · Spielstand als ConfigFile** (`user://save.cfg`, wie `progress.cfg`) statt JSON: gleiche Art wie der Fortschritt, einfach zu lesen.
