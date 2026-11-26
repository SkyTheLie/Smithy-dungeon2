# MULTIPLAYER_PLAN.md – LAN-Koop für Smithy

> **Nur lokal.** Diese Datei steht in `.git/info/exclude` und wird nie committet oder gemergt.
> Nicht mit `git add -f` hinzufügen. Sie bleibt beim Branch-Wechsel liegen (ungetrackt).
>
> **Für die KI, die hier weitermacht:** Erst diese Datei ganz lesen, dann Abschnitt 7
> „Fortschritt“ und das Logbuch (Abschnitt 9). Dort steht, wo die letzte Sitzung aufgehört hat.
> Am Ende jeder Sitzung: Checkboxen in Abschnitt 6 abhaken, einen Logbuch-Eintrag schreiben,
> neue Entscheidungen in Abschnitt 4 (mit **Warum**) eintragen. Sonst weiß die nächste Sitzung nichts.
> Alle Regeln aus PROJEKT.md und docs/FEHLERKLASSEN.md gelten weiter.

Erstellt: 2026-11-13 (Stand von `main`: e03dfd1ea).

---

## 1. Ziel

Zwei Spieler spielen über LAN zusammen in **einer** Welt:

- laufen gemeinsam auf derselben Karte herum und sehen sich,
- können **beide gleichzeitig schmieden** (je eine Station, Minispiel bei jedem lokal),
- haben **eigene Helden** (rekrutieren, ausrüsten, in Dungeons schicken) und eigenes Gold/Inventar.

Der Einzelspieler-Modus muss **unverändert** weiterlaufen. Jeder Commit auf dem Branch lässt
das Spiel allein spielbar.

## 2. Bewusste Einschränkungen (und warum)

| Einschränkung | Warum |
|---|---|
| Beide Spieler sind **immer auf derselben Karte**. Nur der Host wechselt die Karte, der Gast kommt mit. | Jede Karte ist eine eigene Szene (174 `.tscn`), gewechselt mit `change_scene_to_file` (`GameState.travel_to`, game_state.gd ~Z. 507). Das ersetzt den ganzen Szenenbaum. Zwei Karten gleichzeitig hieße, die Kartenverwaltung neu zu bauen: Monate an Arbeit. |
| **Story, Cutscenes und Dialoge mit Story-Aktionen nur beim Host.** Der Gast ist dabei eingefroren und sieht einen Hinweis. | Cutscenes sperren „den“ Spieler, laufen Figuren nach Skript und setzen Flags (Regeln 17–21). Mit zwei Spielern müsste man alle neu schreiben. |
| **Aufträge, Miete, Ruf, Ruhm, Haus, Garten, Lagerkiste, Händler und Ninas Laden sind gemeinsam.** | Spart den halben Umbau. Fühlt sich wie „eine Schmiede, zwei Schmiede“ an. |
| **Keine Pause, solange ein Gast verbunden ist.** Esc öffnet die Einstellungen, die Zeit läuft weiter. | `get_tree().paused` (hud.gd ~Z. 470/668) würde sonst nur bei einem stehen bleiben, und die Uhr liefe auseinander. |
| **Schlafen entscheidet der Host.** Der Gast wird mitgenommen (Meldung). | `GameState.sleep()`/`pass_days` springen in der Zeit. Mit zwei Uhren gäbe es Chaos. |
| **Nur zwei Spieler** (Host + 1 Gast). | Jede Station und jedes Fenster muss nur mit „ich / der andere“ umgehen. Mehr Spieler kann man später nachrüsten. |
| **Nur LAN, ENet.** Steam-Netz kommt später. | Godot bringt ENet mit. `steam_bridge.gd` existiert schon; die Peer-Erzeugung steht nur an einer Stelle (`Net`), damit man später einen Steam-`MultiplayerPeer` einsetzen kann. |
| Kein Schutz gegen Schummeln. | LAN unter Freunden. Der Host prüft trotzdem Mengen (Regel 26), damit nichts kaputtgeht. |

## 3. Wichtige Stellen im Code (Stand 2026-11-13)

Vor Änderungen neu nachzählen, die Zahlen werden sich ändern.

- `scripts/core/game_state.gd` (~1970 Z.): der ganze Spielzustand als Autoload. Pro-Spieler-Felder:
  `inventory` (216 Zugriffe im Code), `gold` (38), `heroes` (28), `adventures`, `player_stats`,
  `unlocked_recipes`, `player_appearance`, `player_name`, `trash`, `buyback`, `reward_chest`,
  `reward_chest_gold`, `quest_items`, `achievements`.
- `GameState._process` (~Z. 421): tickt Werkstatt, Uhr, Kunden, Läden, Story-Prüfung und Abenteuer.
  Läuft nur beim Host „echt“ (siehe E3).
- `GameState.travel_to` / `_travel_with_fade` (~Z. 507–530): Kartenwechsel.
- `GameState.sleep` (~Z. 556), `pass_days`, `_start_new_day`.
- `scripts/core/save_data.gd`: `SaveData.collect` / `SaveData.apply`. Der Rundlauf-Test
  `_lib/test_save_roundtrip.gd` beweist, dass collect » apply den ganzen Zustand erhält. Das nutzen
  wir für den Gast-Abgleich (E4).
- `scenes/actors/player.gd` (~340 Z.): Eingabe in `_physics_process` über `Input.get_vector`,
  Auto-Laufen, Abbauen, Cutscene-Signale. Gruppe `Player.GROUP`; 8 Dateien suchen den Spieler darüber.
- `scenes/stations/`: anvil, forge, bow_table, enchanting_table, grindstone, jewel_table.
  Werkstatt-Zustand: `forge_fire`, `smelter`, `extra_smelters`, `alloy_smelter`, `quencher` in GameState.
- `scenes/ui/hud/hud.gd`: Pause beim Einstellungsfenster und bei Meldungen.
- `scenes/world/_template/map_base.tscn`: Basis aller neuen Karten (Player, HUD, Kamera).
- Autoload `Events`: Bus für `*_requested`-Signale (Regel 41).

## 4. Architektur-Entscheidungen

Jede Entscheidung mit Begründung. Wer eine ändert, schreibt hier, warum.

**E1 – Host ist die Autorität (Server + Spieler).**
Der Host hat den echten `GameState`. Der Gast führt nie selbst Spielregeln aus, sondern schickt
Wünsche per RPC (`request_*`). Der Host prüft, führt aus und schickt das Ergebnis zurück.
*Warum:* Es gibt genau einen Spielstand und eine Uhr, also keine Konflikte beim Zusammenführen.
Passt zu Regel 13 (Regeln in `scripts/systems`, die Fenster rufen nur auf).

**E2 – Neuer Autoload `Net` (`scripts/core/net.gd`) kapselt alles Netzwerk.**
Er macht Host, Beitreten und Trennen, LAN-Suche (UDP-Broadcast), `is_host()`, `is_guest()`,
`is_online()` und kennt den lokalen Spieler-Schlüssel. Er sendet Signale `peer_joined`,
`peer_left` und `connection_failed`.
*Warum:* Ein einziger Ort für `ENetMultiplayerPeer`. Offline gibt `is_online()` false zurück, und
jeder Netz-Code steht hinter dieser Abfrage. Damit bleibt der Einzelspieler unberührt.
Ports: Spiel 7777 (ENet), Suche 7778 (UDP). Als Konstanten in `net.gd`, nicht verstreut.

**E3 – Auf dem Gast tickt `GameState` keine Spielregeln.**
In `GameState._process` beim Gast nur die Uhr anzeigen (Werte vom Host), kein `_tick_workshop`,
kein `_tick_adventures`, kein `_check_story_conditions`, keine Kunden.
*Warum:* Sonst laufen zwei Simulationen auseinander, und Belohnungen kämen doppelt.

**E4 – Der Gast ist ein Spiegel: Abgleich über `SaveData.collect`/`apply`.**
Beim Beitreten und nach Änderungen (gebündelt, höchstens 1×/s, Regel 11-Idee) schickt der Host
einen Schnappschuss. Der Gast wendet ihn an, ohne dass dabei Ereignisse ausgelöst werden
(Regel 5: `_loading`-Pfad benutzen).
*Warum:* Der Rundlauf ist schon getestet und deckt jedes Feld ab (Regel 1). Eigene
Synchronisation für hunderte Felder wäre fehleranfällig. Auf LAN sind ein paar hundert KB egal.
Später kann man das, falls nötig, auf Teil-Schnappschüsse (nur geänderte Bereiche) umstellen.
Achtung: Den eigenen Spielerplatz (Position) überschreibt der Schnappschuss nicht.

**E5 – Spielerdaten in eigener Klasse `PlayerData`, GameState leitet weiter.**
Neue Klasse `PlayerData` (`scripts/systems/player_data.gd`) mit den Pro-Spieler-Feldern aus
Abschnitt 3, mit `to_save_data`/`load_save_data`. GameState hat
`players: Dictionary[String, PlayerData]` und `acting_key: String`. Die alten Felder werden zu
Weiterleitungen: `var inventory: Inventory: get: return players[acting_key].inventory`.
*Warum:* So bleiben die über 300 Stellen mit `GameState.inventory`, `.gold` usw. unverändert.
Der Host bearbeitet eine Gast-Anfrage innerhalb von `GameState.as_player(key, callable)`. Das
setzt `acting_key`, ruft auf und setzt zurück.
**Harte Regel:** `as_player` nur synchron. Nach einem `await` ist `acting_key` wieder der Host.
Keine Gast-Aktion darf über ein `await` laufen. Die Signale (`gold_changed` …) sagen nicht, wem
es gehört: Fenster beim Host zeigen immer `local_key` an, also `acting_key` nie während eines
Fenster-Aufbaus umgestellt lassen.

**E6 – Spieler-Schlüssel ist eine UUID, nicht die Peer-ID.**
Jeder Spieler bekommt beim ersten Mal eine UUID in `user://player_id.cfg`. Der Host speichert
Gast-Daten unter `players[uuid]`.
*Warum:* Peer-IDs ändern sich bei jedem Verbinden. Regel 2 verlangt: speichern nach Schlüssel.
Kommt derselbe Freund wieder, findet er seine Helden wieder.

**E7 – Speichern nur beim Host, ein Spielstand enthält beide Spieler.**
Format: bisherige Felder bleiben (= Host). Neu: `"guests": {uuid: PlayerData-Daten}`.
Alte Spielstände ohne `guests` laden wie bisher (Regel 6).
*Warum:* Der Einzelspieler-Spielstand bleibt fast gleich, und es braucht keine Umwandlung der
Host-Daten.

**E8 – Fremde Spielerfigur ist eine eigene Szene `remote_player.tscn`.**
Ohne Eingabe, ohne Kamera, ohne Cutscene-Logik. Position, Blickrichtung und Animation per
`MultiplayerSynchronizer` (unzuverlässig, ~20/s), weich interpoliert. Das Aussehen wird einmal beim
Beitreten über `Appearance` geschickt (Figur baut sich wie im Charakter-Editor).
*Warum:* `player.gd` hängt an GameState, Cutscenes und Abbauen. Netz-Logik dort hineinzumischen
würde den Einzelspieler gefährden. Die eigene Figur bleibt `player.tscn`, auf beiden Rechnern.

**E9 – Stationen werden belegt.**
Der Host führt `station_owner: Dictionary[String, String]` (Stations-ID » Spieler-Schlüssel).
Interagieren heißt beim Gast `request_claim_station`. Ist sie belegt, kommt die Meldung „Wird
gerade benutzt“. Freigeben passiert beim Schließen des Fensters und bei Trennung.
*Warum:* Zwei Spieler am selben Amboss würden dasselbe Werkstück verändern.

**E10 – Minispiele laufen lokal, nur das Ergebnis geht an den Host.**
Der Gast spielt den Amboss im Takt selbst und schickt `submit_*_result(recipe_id, ergebnis)`. Der
Host prüft Zutaten (Regel 26), verbraucht und erzeugt das Item im Inventar des Gasts (`as_player`).
*Warum:* Takt-Spiele über das Netz ruckeln. Auf LAN ist Vertrauen ok.

**E11 – Helden gehören einem Spieler.**
Die Helden liegen in `PlayerData.heroes`, die Abenteuer in `PlayerData.adventures`. Der Host tickt
die Abenteuer **aller** Spieler (`_tick_adventures` über alle `players`), Belohnungen kommen in die
Loot-Kiste des Besitzers. Angebote zum Rekrutieren sind gemeinsam: wer zuerst kommt, mahlt zuerst.
Das Dungeon-Brett zeigt beide, die eigenen hervorgehoben.
*Warum:* Gewünscht ist „selber eigene Helden rekrutieren“. Gemeinsame Angebote sparen einen
zweiten Angebots-Generator.
Live-Kampfansicht für den Gast: erst einmal nur der Fortschritt. Die Live-Ansicht kommt später.

## 5. Tests

- Regel 30 gilt: nur über `run_tests.sh`. Neuer Test-Ordner `assets/_reference/lan/`, Gruppe `lan`
  in `run_tests.sh` eintragen.
- Zwei Spieler in **einem** Prozess: zwei Teilbäume mit eigenem `SceneMultiplayer`
  (`get_tree().set_multiplayer(api, pfad)`), Host und Gast über ENet auf `127.0.0.1`. So braucht es
  keinen zweiten Godot-Prozess, und `user://` bleibt das Test-Verzeichnis.
  Falls das mit den Autoloads nicht geht (GameState gibt es nur einmal): den Gast-Teil als reinen
  Protokoll-Test schreiben (Nachrichten rein, erwarteter Zustand raus), siehe Logbuch.
- Pflicht-Tests je Schritt stehen in Abschnitt 6. Dazu jedes Mal `kern` + die passende Gruppe
  (Regel 35), denn der Einzelspieler darf nicht kaputtgehen.
- Von Hand: zwei Fenster auf einem PC (Godot » Debug » „Run Multiple Instances“ » 2), später zwei PCs.

## 6. Schritte

Jeder Schritt ist ein oder mehrere Commits auf `feature/lan-multiplayer` (von `main`, regelmäßig
`main` hineinmergen). Nach jedem Schritt: allein spielbar? Tests grün? Logbuch geschrieben?

### Schritt 1 – Verbindung und Prototyp
- [ ] Autoload `Net` (E2): `host_game()`, `join_game(ip)`, `leave()`, Signale, LAN-Suche
- [ ] Hauptmenü: „LAN hosten“ (lädt einen Spielstand) und „LAN beitreten“ (Liste gefundener Spiele + IP-Feld)
- [ ] `remote_player.tscn` (E8) + Spawnen/Entfernen bei `peer_joined`/`peer_left`
- [ ] Gast startet auf derselben Karte wie der Host
- **Fertig, wenn:** zwei Fenster, beide sehen den anderen auf dem Schmiedeplatz laufen.
- Test: `lan/test_connect.gd` (verbinden, Peer da, trennen, Figur weg).

### Schritt 2 – Gemeinsame Welt
- [ ] Schnappschuss Host » Gast (E4), beim Beitreten und gebündelt nach Änderungen
- [ ] E3: Gast tickt keine Spielregeln, die Uhr kommt vom Host
- [ ] Kartenwechsel: Host `travel_to` » RPC an den Gast (gleiche Karte, Spawnpunkt neben dem Host). Ausgänge sind beim Gast gesperrt („Nur der Host wechselt die Karte“)
- [ ] Keine Pause, solange online (hud.gd)
- [ ] Cutscene beim Host » Gast eingefroren + Hinweis; Story-Dialoge sind für den Gast gesperrt
- [ ] Schlafen: der Host schläft » der Gast wird mitgenommen
- [ ] Speichern beim Gast deaktiviert (Regel 4: dieselbe Sperre an allen Wegen)
- **Fertig, wenn:** zusammen zum Markt laufen, Uhr gleich, Cutscene sauber eingefroren.
- Test: `lan/test_world_sync.gd`.

### Schritt 3 – Spielerdaten trennen (größter Umbau)
- [ ] `PlayerData` (E5) mit to/load_save_data, Felder aus Abschnitt 3 dorthin verschieben
- [ ] GameState-Weiterleitungen + `as_player()`. **Offline darf sich nichts ändern.**
- [ ] UUID (E6), Speicherformat mit `guests` (E7), alter Spielstand lädt
- [ ] Gast tritt bei: neue `PlayerData` (Startgold wie neues Spiel? siehe Offene Fragen) oder vorhandene laden
- [ ] Gast-HUD/Inventar zeigen die Gast-Daten aus dem Schnappschuss
- [ ] Erste Gast-Aktionen über RPC: Item aufheben, Erz abbauen, kaufen/verkaufen
- [ ] `_lib/test_save_roundtrip.gd` um einen Gast erweitern (Regel 1)
- **Fertig, wenn:** jeder hat eigenes Gold und Inventar, und nach Speichern/Laden ist alles noch da.
- Tests: `kern`, `wirtschaft`, `lan/test_player_data.gd`.

### Schritt 4 – Zwei Schmiede
- [ ] Stationen belegen (E9) für Esse, Gussofen, Amboss, Trog, Arbeitstisch und die übrigen Stationen in `scenes/stations/`
- [ ] Minispiel-Ergebnis an den Host (E10), Verbrauch prüfen (Regel 26)
- [ ] Schmelzen/Abkühlen: Werkstück gehört einem Spieler (Besitzer-Schlüssel an `Smelter`/`Quencher` speichern, Regel 1)
- [ ] Gleichzeitig: zwei Schmelzplätze (`extra_smelters`) müssen nutzbar sein
- **Fertig, wenn:** beide gleichzeitig vom Erz bis zur Waffe schmieden können, ohne sich etwas wegzunehmen.
- Tests: `lan/test_two_smiths.gd`, Gruppe für Schmieden.

### Schritt 5 – Eigene Helden
- [ ] Helden/Abenteuer pro Spieler (E11), Host tickt alle
- [ ] Rekrutieren, Ausrüsten, Dungeon-Brett, Loot-Kiste für den Gast über RPC
- [ ] Gilde/Klassen-Freischaltung: pro Spieler oder gemeinsam? (Offene Fragen)
- **Fertig, wenn:** der Gast stellt einen Helden ein, schickt ihn los und bekommt die Beute in seine Kiste.
- Tests: `kampf`, `lan/test_hero_ownership.gd`.

### Schritt 6 – Robustheit und Abschluss
- [ ] Verbindungsabbruch: Gast zurück ins Hauptmenü mit Meldung, Host spielt weiter, Stationen frei
- [ ] Host beendet: Gast bekommt eine Meldung
- [ ] Gast-Daten im Autosave des Hosts
- [ ] Texte durch `Language.translate`, `extract_po.py` (Regeln 7, 10)
- [ ] Doku: `docs/SYSTEME.md`, `docs/ENTSCHEIDUNGEN.md`, `docs/UEBERBLICK.md` (Net, PlayerData). Wichtig: die Entscheidungen E1–E11 dann dort hinein übertragen, denn diese Datei wird nie gemergt
- [ ] PR nach `main`

## 7. Fortschritt

**Aktueller Schritt:** noch nicht begonnen (Branch `feature/lan-multiplayer` anlegen).
**Nächste konkrete Aufgabe:** Schritt 1, `Net`-Autoload.

## 8. Offene Fragen (mit dem Entwickler klären, Antwort hier eintragen)

- Startet ein neuer Gast mit Startgold/Start-Werkzeug oder bei 0?
- Bekommt der Gast EXP/Level eigenständig? (Plan: ja, `player_stats` gehört zu `PlayerData`)
- Gussformen/Rezepte: pro Spieler oder gemeinsam freigeschaltet?
- Wem gehört der Lohn eines Auftrags, wer liefert ab? (Plan: wer abgibt, bekommt das Gold)
- Gast-Figur: eigenen Charakter-Editor beim ersten Beitreten oder Aussehen aus eigenem Spielstand?
- Darf der Gast Story-NPCs ansprechen (nur Geplauder)?

## 9. Logbuch (neueste oben)

Format: `Datum · Schritt · was gemacht · was offen/kaputt · nächster Handgriff`

- 2026-11-13 · Plan · Datei angelegt, Code-Stellen gezählt, nichts implementiert · Offene Fragen klären · Branch anlegen, Schritt 1 starten
