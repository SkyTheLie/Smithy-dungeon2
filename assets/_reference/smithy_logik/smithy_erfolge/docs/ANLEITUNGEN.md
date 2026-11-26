# Anleitungen: Smithy selbst erweitern

Schritt-für-Schritt-Anleitungen für die häufigsten Aufgaben, mit den echten Dateien und Funktionen aus dem Projekt. Die Nachschlage-Doku ergänzt diese Anleitungen:

- `docs/CONTENT.md`: jedes JSON-Feld (Items, Story, Gegner, Dungeons …)
- `docs/SYSTEME.md`: Inhaltsverzeichnis, welches System in welcher Datei unter `docs/systeme/` beschrieben ist
- `docs/STORY.md`: der Inhalt der Geschichte

Diese Datei erklärt, **wie man vorgeht**. Die Felder schlägst du in CONTENT.md nach.

---

## 0. Das Grundprinzip in 5 Minuten

Wenn du diese fünf Dinge verstanden hast, findest du dich überall zurecht.

**1. GameState ist das Gedächtnis des Spiels.**
`scripts/core/game_state.gd` ist ein *Autoload*: ein Node, den Godot beim Start einmal anlegt und den jedes Skript über `GameState` erreicht. Dort liegen Gold, Inventar, Helden, Tageszeit und die Geschichte (`GameState.story`). Szenen kommen und gehen, GameState bleibt. Auch das Speichern läuft über GameState (`_collect_save_data()` / `_apply_save_data()`).

**2. Inhalte stehen in JSON, nicht im Code.**
Alles in `data/content/*.json` liest `ContentDB` (`scripts/core/content_db.gd`) beim Start. Ein neues Item, ein neuer Dialog oder ein neuer Gegner braucht keine Zeile GDScript. Tippfehler meldet ContentDB in der Godot-Ausgabe.

**3. Die Geschichte ist eine Kette von Schritten plus Flags.**
`scripts/systems/story.gd` (Klasse `Story`):
- **Schritt** (`step`): die aktuelle Hauptaufgabe, z. B. `"festival_show"`. Es gibt immer genau einen.
- **Flag**: ein Häkchen „ist passiert“, z. B. `"smithy_rented"`. Flags bleiben für immer, außer man nimmt sie mit `clear_flags` zurück.
- Fast alles in der Welt fragt nur nach Flags: Türen (`required_flag`), Figuren (`required_flag`, `hidden_when_flag`), Stationen, Deko (`StoryProp`).

**4. Szenen sind Karten.**
Jede Karte ist eine `.tscn` unter `scenes/world/`. Gewechselt wird mit `GameState.travel_to(szene, spawnpunkt)`, meistens über eine Tür (`Door`). Beim Betreten meldet der Spieler das Ereignis `enter:<dateiname ohne .tscn>`, z. B. `enter:market`. Die Geschichte kann darauf reagieren.

**5. Kommunikation über Signale.**
Systeme rufen sich nicht direkt über Pfade auf, sondern senden Signale. Beispiele: `GameState.gold_changed`, `GameState.story.changed`, `Station.interacted`. Wer reagieren will, verbindet sich mit `signal.connect(funktion)`.

### Werkzeuge zum Testen (nur wenn das Spiel aus dem Editor läuft)

- **P = Admin-Panel** (`scenes/ui/menus/admin_panel.gd`):
  - Items: jedes Item nehmen
  - Ereignisse: Story-Ereignisse neu starten
  - Haus: Hausstufe setzen
  - Kapitel: an den Anfang eines Kapitels springen
  - Karten: auf jede Karte teleportieren
- **Godot-Ausgabe** (unten im Editor): Fehler von ContentDB und `print()`-Ausgaben.
- **Remote-Baum** (Szenenbaum oben auf „Remote“, während das Spiel läuft): Dort siehst du die echten Nodes und kannst unter `root/GameState` Werte wie `story` ansehen.
- **Headless-Tests**: Skripte in `assets/_reference/<thema>/test_*.gd`, siehe Abschnitt 7.

---

## 1. Ein neues Gebiet erstellen

Beispiel: eine neue Karte „Steinbruch“, erreichbar vom Südweg nach Westen.

### 1.1 Was du brauchst

| Was | Wo | Pflicht? |
|---|---|---|
| Die Szene | `scenes/world/<bereich>/quarry.tscn` | ja |
| Bodenbild | `assets/sprites/maps/…` oder ein vorhandenes Bild aus `docs/ASSET_KATALOG.md` | ja (Platzhalter geht) |
| Spawnpunkte | `Marker2D` in der Szene | ja |
| Türen hin und zurück | `door.tscn`-Instanzen in **beiden** Szenen | ja |
| Schöner Name im Admin-Panel | `MAP_NAMES` in `admin_panel.gd` | nein |
| Nachts gesperrt / Zeit stoppt | `WILD_SCENES` in `game_state.gd` | nur für Wildnis |
| Musik | `scene_music` in `data/content/audio.json` | nein |
| Teleport-Ziel | `data/destinations/<id>.tres` | nein |

### 1.2 Ein bestehendes Gebiet als Vorlage nehmen

**Am einfachsten (seit 2026-11-13):** im FileSystem-Dock Rechtsklick auf `scenes/world/_template/map_base.tscn` » **Neue geerbte Szene**, als `quarry.tscn` in den passenden Ordner speichern. Darin ist der Aufbau unten schon fertig (DayTint, Ground, Bounds, Lights, Spawnpunkt, Player mit Kamera-Grenzen, HUD); du setzt nur Bild, Grenzen und Ränder auf die Größe deiner Karte. Der Test `map_tools/test_map_setup.gd` prüft, dass nichts davon fehlt.

Alternativ kopierst du eine bestehende Karte:

Die beste Vorlage für eine Außenkarte ist **`scenes/world/village/south_road.tscn`**: klein und mit allem Nötigen. Für Innenräume nimmst du **`scenes/world/village/grandma_house.tscn`**.

1. Im Godot-Editor im FileSystem-Dock Rechtsklick auf `south_road.tscn` » **Duplizieren…**, Name `quarry.tscn`, in den passenden Ordner legen. (Duplizieren im Editor sorgt für neue UIDs. Kopieren im Explorer kann doppelte UIDs erzeugen.)
2. Szene öffnen, den Wurzel-Node umbenennen (`SouthRoad` → `Quarry`).
3. Alles löschen, was nur zum Südweg gehört (Fluss, Brücke, Blumen), und Folgendes behalten:

```
Quarry (Node2D, y_sort_enabled = true)        ← Figuren werden nach Höhe sortiert
├── DayTint (CanvasModulate, day_tint.gd)      ← Tag/Nacht-Färbung, PFLICHT
├── Ground (Sprite2D)                          ← Bodenbild
├── Bounds (StaticBody2D)                      ← unsichtbare Wände am Kartenrand
│   ├── Top / Bottom / Left / Right (CollisionShape2D)
├── Lights (Node2D)                            ← NightLight-Instanzen für Lampen
├── ExitEast (door.tscn)                       ← Weg zurück zum Südweg
├── FromSouthRoad (Marker2D, Gruppe "spawn_points")
├── Player (player.tscn)
│   └── Camera2D  ← limit_left/top/right/bottom = Kartenrand
└── HUD (hud.tscn)
```

**Warum das so ist:**
- `y_sort_enabled` am Wurzel-Node sorgt dafür, dass der Spieler hinter einem Baum verschwindet, wenn er darüber steht.
- `DayTint` färbt die Karte je nach Uhrzeit. Ohne ihn ist es nachts taghell.
- Für Orte, die immer düster sind, nimmst du `Gloom` statt `DayTint` (wie beim Schwarzmarkt).

### 1.3 Das Gebiet einrichten

1. **Boden:** `Ground.texture` = dein Bild. Bei einer 1024×768-Karte mit Mittelpunkt (0, 0) reicht die Karte von −512 bis +512 und von −384 bis +384.
2. **Kamera-Grenzen** (Projektregel): `Player` auswählen, Rechtsklick » **Editierbare Kinder**, dann `Camera2D` die `limit_*`-Werte genau auf den Kartenrand setzen. Sonst sieht man die graue Leere außerhalb.
3. **Ränder:** `Bounds` bekommt vier `CollisionShape2D` mit `RectangleShape2D` direkt am Rand. So läuft der Spieler gegen eine Wand, bevor die Kamera stehen bleibt.
4. **Hindernisse:** Häuser, Felsen und Zäune sind `StaticBody2D` mit Sprite und CollisionShape. Die Kollision sitzt nur am **Fuß** des Objekts (flacher Streifen), damit man hinter dem oberen Teil vorbeilaufen kann.
5. **Licht:** Jede Lampe, Fackel oder jedes Feuer bekommt eine `night_light.tscn`-Instanz (`scenes/world/objects/`, Felder `color`, `night_energy`, `flicker`). Projektregel: alles, was leuchtet, leuchtet nachts.
6. **Fertige Bausteine** aus `scenes/world/objects/`: Bäume (`oak_big.tscn`, `fir.tscn` …), `bench.tscn`, `well.tscn`, `torch.tscn`, `lantern.tscn`, `fence_h.tscn`/`fence_v.tscn`, `direction_sign.tscn`. Einfach in die Szene ziehen.

### 1.4 NPCs, Objekte, Quests und Interaktionen hinzufügen

| Du willst … | Nimm … | Wichtige Felder im Inspector |
|---|---|---|
| eine Figur, die redet (Story) | `scenes/actors/story_npc.tscn` | `npc_id`, Aussehen (`appearance` / `resident` / `figure_texture`), `required_flag`, `hidden_when_flag`, `auto_talk` |
| eine Figur mit Auftrag (Item bringen) | `scenes/actors/quest_npc.tscn` | `npc_name`, `sprite`, `greeting`, `quest` (eine QuestData-.tres) |
| Erz, Bäume, Pflanzen zum Sammeln | `ore_rock.tscn` (einzeln) oder ein Node mit `rock_spawner.gd` (zufällig jeden Tag) | `data` bzw. `rock_types` = `.tres` aus `data/rocks/` |
| eine Truhe | `reward_chest.tscn` (Loot-Kiste) | – |
| Deko, die mit der Geschichte kommt und geht | `Node2D` mit `scenes/world/objects/story_prop.gd`, die Sprites als Kinder | `required_flag`, `hidden_when_flag` |
| eine Station mit Fenster (E drücken) | eine Station (erbt von `Station`) + ein Fenster (erbt von `StationMenu`), siehe Abschnitt 5 | `required_flag` |

**Eine Story-Figur braucht zwei Teile:**
1. In der Szene die `story_npc.tscn`-Instanz mit `npc_id = "quarry_worker"`.
2. In `data/content/story/npcs.json` unter `"npcs"`:

```json
"quarry_worker": {
	"name": "Steinmetz Odo",
	"dialogues": {
		"default": "odo_idle"
	}
}
```

Wie Dialoge funktionieren, steht in Abschnitt 4.

**Wie E-Drücken funktioniert** (`scenes/stations/station.gd`): Jede Station und jede Figur hat eine `InteractionArea` (Area2D). Läuft der Spieler hinein, merkt sich die Station das (`_player_in_range`). Drückt er dann E (`interact`), sendet sie das Signal `interacted`. Wer daran hängt (z. B. das Fenster mit `toggle`), reagiert. In der `.tscn` sieht das so aus:

```
[connection signal="interacted" from="Bed" to="SleepMenu" method="toggle"]
[connection signal="player_left" from="Bed" to="SleepMenu" method="close"]
```

Im Editor machst du das im **Node-Dock » Signale** per Doppelklick.

### 1.5 Übergänge zu anderen Gebieten

Ein Übergang besteht immer aus **zwei Teilen in jeder Szene**: einer Tür, die hinausführt, und einem Spawnpunkt, an dem man ankommt.

**In `quarry.tscn`:**
1. `door.tscn` instanziieren, Name `ExitEast`, an den Ostrand setzen.
   - `scale = (1, 3)` macht die Tür zu einem hohen Streifen, damit man sie nicht verfehlt.
   - `target_scene` = `res://scenes/world/village/south_road.tscn`
   - `target_spawn_point` = `FromQuarry`
   - Rechtsklick » Editierbare Kinder » `Visual.visible = false`, sonst sieht man ein Türbild.
2. `Marker2D` namens `FromSouthRoad` etwas **innerhalb** der Karte, neben der Tür. Im Node-Dock » Gruppen die Gruppe **`spawn_points`** hinzufügen.

**In `south_road.tscn`:**
3. `ExitWest` (door.tscn) mit `target_scene` = `res://…/quarry.tscn` und `target_spawn_point` = `FromSouthRoad`.
4. Einen `Marker2D` `FromQuarry` neben dieser Tür, Gruppe `spawn_points`.

Der Spawnpunkt muss ein paar Pixel von der Tür entfernt sein. Sonst steht der Spieler beim Ankommen schon in der Tür und reist sofort zurück.

**So läuft es im Code ab** (`door.gd` → `GameState.travel_to`):
1. Die Tür prüft `required_flag`, `blocked_flag`, die Nacht und die Öffnungszeiten.
2. `GameState.next_spawn_point` wird gesetzt und die neue Szene geladen.
3. `Player._move_to_spawn_point()` sucht in der Gruppe `spawn_points` den Marker mit genau diesem Namen.

**Gesperrte Wege:** `Door.required_flag` öffnet die Tür erst ab einem Flag. `blocked_flag` / `unblocked_flag` sperren sie zeitweise. Die Meldung legst du in `locked_text` bzw. `blocked_text` fest.

### 1.6 Das Gebiet im Projekt anmelden

Es gibt **keine zentrale Liste**, die du pflegen musst. Folgendes ist optional:

- **Admin-Panel:** findet jede Szene unter `scenes/world/`, die einen Player enthält, von selbst. Einen schönen Namen trägst du in `MAP_NAMES` ein (`"quarry": "Steinbruch"`).
- **Wildnis:** Soll die Karte nachts gesperrt sein und die Uhr dort bei Nachtbeginn stehen bleiben, nimmst du den Pfad in `WILD_SCENES` in `scripts/core/game_state.gd` auf.
- **Musik:** `data/content/audio.json` » `"scene_music": {"quarry.tscn": "forest"}`.
- **Teleporter:** Neue Datei `data/destinations/quarry.tres` nach dem Vorbild von `mine.tres` (`id`, `display_name`, `scene_path`, `spawn_point = FromTeleporter`). Dazu ein Marker `FromTeleporter` und `teleporter.tscn` in der Karte. Bekannt wird das Ziel über `GameState.known_destinations` (Start: `START_DESTINATIONS`).
- **Geschichte:** Das Ereignis `enter:quarry` gibt es automatisch und kann in `story.json` genutzt werden (Abschnitt 3).

### 1.7 Testen

1. Szene öffnen und **F6** (aktuelle Szene starten): Läuft man herum, stimmen Kamera, Ränder und Sortierung?
2. Spiel normal starten, **P » Karten » Steinbruch**: Funktioniert das Teleportieren?
3. Durch beide Türen hin und zurück laufen: Kommt man am richtigen Marker an?
4. Im Admin-Panel die Zeit auf Nacht stellen (oder schlafen): Leuchten die Lichter?
5. Speichern, laden: Steht man wieder im Steinbruch?

**Typische Fehler:**
- Man kommt in der Kartenmitte (oder bei (0, 0)) an: Der Spawnpunkt-Name passt nicht oder der Marker ist nicht in der Gruppe `spawn_points`.
- Man sieht graue Ränder: Die Kamera-Limits stimmen nicht.
- Man springt sofort zurück: Der Spawnpunkt liegt in der Tür.

---

## 2. Eine neue Quest erstellen

### 2.1 Welche Arten von Quests es gibt

Im Projekt gibt es **vier** Arten von Aufgaben. Wähle die passende:

| Art | Wofür | Daten | Code |
|---|---|---|---|
| **Story-Schritt** | die Hauptgeschichte, immer genau einer aktiv | `story.json` » `steps` | `Story` |
| **Neben-Aufgabe** (`side_tasks`) | läuft parallel zur Geschichte, z. B. Gewächshaus | `story.json` » `side_tasks` | `Story`, `GameState._check_story_conditions` |
| **Auftrag einer Figur** (`QuestData`) | „Bring mir X, dann bekommst du Y“ (Holgers Axt) | `data/quests/<id>.tres` | `QuestNpc`, `GameState.accept_quest/complete_quest` |
| **Kundenauftrag** | zufällige Kunden in der Schmiede | `economy.json` | `Customers` |

Alle erscheinen im Auftragsbuch (J). Die ersten drei sind „Quests“ im üblichen Sinn und werden hier erklärt.

### 2.2 Variante A: Auftrag einer Figur (QuestData). Am einfachsten, ganz ohne Code

**Aufbau** (`scripts/resources/quest_data.gd`): Eine `.tres`-Datei pro Auftrag mit
- Titel, Auftraggeber und Ort,
- dem gewünschten Item (`required_item_id`, optional `required_part_id`, `required_amount`),
- vier Texten (`offer_text`, `reminder_text`, `done_text`, `after_text`),
- Belohnungen (`rewards`, je eine `QuestReward`: `EXPERIENCE`, `GOLD`, `ITEM`, `DAILY_ITEM`),
- Rezepten, die beim Annehmen frei werden (`unlock_recipe_ids`).

**Anlegen:**
1. FileSystem: `data/quests/woodcutter_axe.tres` duplizieren, z. B. als `odo_chisel.tres`.
2. Im Inspector ausfüllen:
   - `title = "Ein Meißel für Odo"`
   - `required_item_id = "chisel"` (muss in `items.json` existieren)
   - `required_amount = 1`
   - Texte
   - `rewards`: Element hinzufügen » Neue `QuestReward` » `kind = GOLD`, `amount = 50`
3. In der Szene eine `quest_npc.tscn`-Instanz setzen und ihr Feld `quest` = `odo_chisel.tres` geben.

**Voraussetzungen:**
- `QuestData.required_flag`: Die Figur bietet den Auftrag erst ab diesem Flag an.
- `QuestNpc.required_flag` (geerbt von `Station`): Die Figur selbst existiert erst ab diesem Flag.
- **Folgeaufträge:** im `QuestNpc` das Feld `follow_up_quests` füllen. Der nächste wird angeboten, sobald der vorige erledigt ist (und sein `required_flag` gesetzt ist), siehe `QuestNpc.get_current_quest()`.

**Ablauf im Code:**
1. Spieler drückt E bei der Figur → `QuestDialog` öffnet sich.
2. „Annehmen“ → `GameState.accept_quest(quest)`: Der Zustand wird `ACTIVE`, `accept_flag` wird gesetzt, Rezepte werden frei.
3. Hat er das Item, zeigt die Figur „?“ → „Abgeben“ → `GameState.complete_quest(quest)`: Das Item wird genommen, die Belohnungen kommen, der Zustand wird `COMPLETED`, das Signal `quest_completed` geht raus.

**Gespeichert** wird in `GameState.quest_states` (Pfad der .tres → Zustand) und `quest_log`. Benenne die .tres also nicht mehr um, wenn es schon Spielstände gibt.

**Kein doppelter Abschluss:** `accept_quest` macht nichts, wenn der Auftrag nicht `AVAILABLE` ist. `complete_quest` geht nur bei `ACTIVE`. Das ist schon eingebaut.

### 2.3 Variante B: Story-Schritt (Hauptgeschichte)

**Aufbau** (`story.json` » `"steps"`): Ein Schritt ist ein Eintrag mit id:

```json
"quarry_visit": {
	"title": "Der Steinbruch",
	"text": "Odo sucht Hilfe. Geh zum Steinbruch (Südweg » Westen).",
	"hints": ["quarry_tip"],
	"on_start": "set_flag:quarry_open",
	"events": {
		"enter:quarry": "quarry_talk"
	}
}
```

| Feld | Bedeutung |
|---|---|
| `title`, `text` | erscheinen im Auftragsbuch und im Tracker oben rechts |
| `hints` | Tipp-Fenster beim Start (Texte unter `"hints"`, jeder nur einmal) |
| `on_start` | Aktionen, die beim Start des Schritts laufen (`GameState._on_story_step_started`) |
| `events` | „wenn X passiert, geh zu Schritt Y“ |
| `progress_flags` + `next` | „wenn alle diese Flags gesetzt sind, geh zu `next`“ (das Buch zeigt „2/3“) |
| `quest_done`, `have_item`, `hero_level`, `wait_days` … + `next` | automatische Bedingungen (Liste in CONTENT.md) |
| `show_items` | „Kohle 3/5“ im Auftragsbuch |

**Wie ein Schritt endet: genau einer dieser vier Wege**

1. **Ereignis:** `"events": {"enter:quarry": "next_step"}`. Ereignisse sind `enter:<szene>`, `sleep`, `adventure_won`, `adventure_won:<dungeon>` usw. Sie werden in `GameState.story_event()` ausgewertet.
2. **Dialog:** Ein Dialog endet mit `"on_end": "advance:next_step"`. Das ist am häufigsten.
3. **Flags sammeln:** `"progress_flags": ["a", "b"], "next": "next_step"` (`Story._check_progress`).
4. **Bedingung:** z. B. `"have_item": "chisel", "next": "next_step"`. GameState prüft das zweimal pro Sekunde (`_check_story_conditions`).

**Belohnungen** gibt es per Aktion, meist am Ende eines Dialogs:

```
"on_end": "give_gold:100;give_items:iron_ingot*3;unlock_recipes:iron_chisel;advance:quarry_done"
```

Alle Aktionen findest du in CONTENT.md unter „Aktionen“. Der Code dazu steht in `GameState._run_single_story_action()`.

**Gespeichert** wird `story.to_save_data()`: der aktuelle Schritt, alle Flags und die gezeigten Tipps. Mehr nicht. Alles andere ergibt sich daraus.

### 2.4 Variante C: Neben-Aufgabe (parallel zur Geschichte)

```json
"side_tasks": {
	"quarry_stones": {
		"title": "Steine für Odo",
		"text": "Bring Odo 10 Steine.",
		"start_flag": "quarry_stones_started",
		"done_flag": "quarry_stones_done",
		"show_items": "stone*10"
	}
}
```

- Sie läuft, sobald `start_flag` gesetzt ist (z. B. per Dialog-Aktion `set_flag:quarry_stones_started`).
- Sie ist erledigt, sobald `done_flag` gesetzt ist.
- Abgeben lässt man sie über einen **Nebendialog** (Abschnitt 4.6) mit `take_items:stone*10;give_gold:80;set_flag:quarry_stones_done`.

### 2.5 Testen

- **QuestData:** P » Items » das gewünschte Item nehmen, zur Figur gehen, annehmen, abgeben, ins Auftragsbuch schauen.
- **Story-Schritt:** Am einfachsten über einen Headless-Test (Abschnitt 7) mit `story.advance("quarry_visit")`. Oder ins Kapitel davor springen (P » Kapitel) und durchspielen.
- **Prüfliste:** Steht der Text im Auftragsbuch? Kommt der nächste Schritt? Bleibt der Fortschritt nach Speichern und Laden?

---

## 3. Quest-Abfolge und Aufgaben verändern

Alles passiert in den Dateien unter **`data/content/story/`**. Code musst du dafür fast nie anfassen.

> **Seit 2026-11-13 ist die frühere `story.json` aufgeteilt** (sie war 712 KB groß): `steps.json` (Schritte), `npcs.json` (Figuren), `hints.json` (Tipps), `side.json` (Neben-Aufgaben und Nebendialoge), `general.json` (Start, Intro, Abspann, Listen) und die Dialoge je Gebiet in `dialogues/<gebiet>.json` (`village`, `market`, `mine`, `volcano` …, ohne Gebiet: `misc`). Das Spiel fügt alle Dateien beim Laden zusammen (`ContentDB.read_story`); wo in dieser Anleitung „story.json » `steps`“ steht, ist der Abschnitt `"steps"` in der passenden Datei gemeint. Ein neuer Dialog darf in jeder Datei unter `dialogues/` stehen (am besten beim Gebiet der Figur); dieselbe id in zwei Dateien meldet das Spiel beim Start als Fehler. Einen Dialog finden: in VS Code nach `"<dialog-id>":` im Ordner suchen.

### 3.1 So findest du heraus, was auf was folgt

Ein Schritt nennt seinen Nachfolger an genau einer dieser Stellen:
- in `"events"` (`"enter:market": "festival_show"`),
- in `"next"` (zusammen mit `progress_flags` oder einer Bedingung),
- in einem **Dialog**, der `advance:<schritt>` ausführt (in `on_end`, in einer `choice.action` oder in einer Zeile `action`).

**Suchen:** Im Editor oder in VS Code nach `advance:festival_show` und `"festival_show"` suchen. So findest du jede Stelle, die zu diesem Schritt führt.

Beispiel aus dem echten Spiel (Frühlingsfest):

```
chapter7_end  --(sleep)-->  festival_rumors
festival_rumors: Dialog "festival_gossip" endet mit advance:festival_eve
festival_eve  --(sleep)-->  festival_morning
festival_morning --(enter:market)--> festival_show
festival_show: Dialog "magician_sword" endet mit advance:festival_night
```

### 3.2 Reihenfolge ändern

Du willst B und C tauschen (A → B → C → D wird zu A → C → B → D). Ändere nur die **Verweise**:
- A zeigt auf C (statt auf B),
- C zeigt auf B (statt auf D),
- B zeigt auf D (statt auf C).

Die Reihenfolge der Einträge in der JSON-Datei ist egal. Nur die Verweise zählen. Passe danach die Texte an („Geh jetzt zu …“).

### 3.3 Eine neue Aufgabe zwischen zwei bestehenden einfügen

Vorher: `A --(Dialog endet mit advance:B)--> B`

1. Neuen Schritt `X` anlegen (`title`, `text`, ein Weg zum Beenden, der auf `B` zeigt).
2. In A den Verweis `advance:B` durch `advance:X` ersetzen.
3. Falls Figuren in `npcs.<id>.dialogues` einen Dialog für Schritt A oder B haben, überlegen, ob sie in X auch etwas sagen sollen (`"X": "dialog_id"`).
4. **Alte Spielstände:** Wer gerade in A steht, läuft ganz normal über X weiter. Wer schon in B ist, überspringt X. Ist X wichtig (z. B. weil es ein Rezept freischaltet), trag in `"implied_flags"` ein, dass z. B. `reached_B` das Flag von X mit sich bringt.

### 3.4 Parallel oder nacheinander

- **Nacheinander:** Das ist die normale Schrittkette.
- **Parallel innerhalb eines Schritts:** `"progress_flags": ["asked_nina", "asked_hedwig", "asked_landlady"], "next": "chapter8_end"`. Drei Gespräche in beliebiger Reihenfolge, jedes setzt sein Flag. Sind alle drei da, geht es weiter (echtes Beispiel: `ask_enchanting`).
- **Ganz unabhängig von der Geschichte:** Neben-Aufgaben (`side_tasks`, Abschnitt 2.4) und Nebendialoge (`side_dialogues`).

### 3.5 Voraussetzungen definieren

| Voraussetzung | Wie |
|---|---|
| Figur oder Tür erst ab einem Punkt da | `required_flag = "reached_<schritt>"` (das Flag `reached_<id>` entsteht automatisch beim Start jedes Schritts) |
| Auswahl im Dialog nur manchmal | in der `choice`: `"if_flag": "x"` oder `"unless_flag": "x"` |
| Gold oder Items nötig | Aktion `has_gold:100` bzw. `has_items:coal*5` **vor** `take_items` bzw. `pay_gold`, plus `"else": "dialog_wenn_nicht"` |
| Nach und nach abgeben (Neben-Aufgabe mit `show_items`/`show_gold`) | `deliver:<aufgabe>` (Sachen aus den Abgabe-Slots, auch Teilmengen) und `deliver_gold:<aufgabe>` (zahlt, was fehlt und da ist); sind alle Sachen und das Gold da, wird der `done_flag` der Aufgabe gesetzt. Folge-Dialog mit `if_flag`/`unless_flag` auf den `done_flag` (Beispiel: Gustav, `miner_deal_check`) |
| Ruf, Level | Bedingung `hero_level`, oder im Code `GameState.reputation` |

Mehrere Aktionen hintereinander brechen beim ersten Fehlschlag ab (`run_story_action`). Prüfungen gehören deshalb nach vorne.

### 3.6 Folgequests freischalten

- **Story:** Der Endpunkt des einen Schritts zeigt auf den nächsten.
- **QuestData:** `follow_up_quests` am QuestNpc, optional mit `required_flag` an der Folge-Quest.
- **Neben-Aufgabe:** Am Ende der einen `set_flag:<start_flag der nächsten>`.
- **Dungeon:** `required_flag` in `dungeons.json`.

### 3.7 Doppelten Abschluss verhindern

- `set_flag` setzt ein Flag nur einmal. Ist es schon da, passiert nichts.
- Nebendialoge mit `done_flag` verschwinden, sobald das Flag gesetzt ist.
- Bei Belohnungen in Dialogen: Belohnung und `done_flag` in **dieselbe** Aktionskette schreiben: `take_items:stone*10;give_gold:80;set_flag:stones_done`.
- QuestData schützt sich selbst über den Zustand (`ACTIVE` → `COMPLETED`).
- Tipps (`hints`) zeigt `Story.show_hint` nur einmal.

### 3.8 Welche Dateien du dabei änderst

| Änderung | Datei |
|---|---|
| Schritte, Dialoge, Figuren-Zuordnung, Neben-Aufgaben | `data/content/story/` (`steps.json`, `dialogues/<gebiet>.json`, `npcs.json`, `side.json`) |
| Wann Figuren, Türen, Deko auftauchen | Inspector der Szene (`required_flag` …) |
| Kapitel-Sprünge im Admin-Panel | `scripts/systems/story_skip.gd` (`CHAPTERS`) |
| Neue Art von Aktion (`mein_befehl:…`) | `GameState._run_single_story_action()`, Code |
| Neue Art von Bedingung | `GameState._check_story_conditions()`, Code |
| Überblick der Geschichte | `docs/STORY.md` |

---

## 4. Dialoge und Dialogreihenfolge verändern

### 4.1 Wo Dialoge gespeichert sind

In `data/content/story/` (Schritte in `steps.json`, Dialoge in `dialogues/<gebiet>.json`):
- **`"dialogues"`**: der Text,
- **`"npcs"`**: wer wann welchen Dialog hat,
- **`"side_dialogues"`**: Nebendialoge.

Angezeigt werden sie von `scenes/ui/dialogue/dialogue_box.gd` (`DialogueBox`).

### 4.2 Aufbau eines Dialogs

```json
"odo_offer": {
	"lines": [
		{ "speaker": "", "text": "Staub liegt in der Luft." },
		{ "speaker": "quarry_worker", "text": "Na, {name}? Hilfst du mir?" },
		{ "speaker": "player", "text": "Worum geht's?", "action": "set_flag:met_odo" },
		{ "speaker": "quarry_worker", "text": "Pass auf!", "wait": 2.0 }
	],
	"choices": [
		{ "text": "Klar!", "action": "set_flag:quarry_stones_started", "then": "odo_thanks" },
		{ "text": "Kostet 20 Gold", "action": "pay_gold:20", "then": "odo_paid", "else": "odo_no_gold" },
		{ "text": "Später", "unless_flag": "met_odo" }
	],
	"on_end": "advance:quarry_done"
}
```

| Feld | Bedeutung |
|---|---|
| `speaker` | `""` = Erzähler (kein Bild), `"player"` = der Spieler, sonst eine npc-id. Andere Figuren dürfen mitreden, wenn sie in der Szene stehen. |
| `text` | Platzhalter: `{name}` (Spielername), `{rent}`, `{gold}` … |
| `action` (Zeile) | läuft, sobald die Zeile erscheint (z. B. Schwert erscheint, Kürbis fliegt) |
| `wait` (Zeile) | Sekunden, in denen „Weiter“ gesperrt ist (Zwischensequenzen) |
| `choices` | Knöpfe nach der letzten Zeile |
| `on_end` | Aktionen nach der letzten Zeile, **nur wenn es keine `choices` gibt** |

### 4.3 Wie Figuren an ihren Dialog kommen

Das passiert in `Story.get_npc_dialogue(npc_id)`, **in dieser Reihenfolge**:

1. **Dialog für den aktuellen Schritt:** `npcs.<id>.dialogues.<aktueller schritt>`
2. **Offener Nebendialog:** der erste Eintrag in `side_dialogues` mit `npc` = diese Figur, dessen `flag` (und `flags`) gesetzt sind und dessen `done_flag` noch nicht gesetzt ist
3. **`default`**
4. sonst nichts (die Figur sagt nichts)

Das „!“ über der Figur erscheint bei 1 oder 2 (außer `"quiet": true`), siehe `npc_has_news`.

**Herausfinden, welcher Dialog als Nächstes kommt:**
1. Den aktuellen Schritt ansehen: im Auftragsbuch (der Titel), im Remote-Baum unter `GameState` » `story` » `step`, oder kurz `print(GameState.story.step)` in ein Skript schreiben.
2. In `story.json` bei `npcs.<id>.dialogues` nach diesem Schritt suchen. Gefunden? Dann ist es dieser Dialog.
3. Sonst in `side_dialogues` den ersten passenden Eintrag für die Figur suchen.
4. Sonst `default`.

Schneller Test im Code, z. B. vorübergehend in `story_npc.gd` in `_on_interacted`:
```gdscript
print(npc_id, " → ", GameState.story.step, " → ", GameState.story.get_npc_dialogue(npc_id).get("lines", [{}])[0].get("text", "(nichts)"))
```

### 4.4 Optionen und Verzweigungen

- Eine `choice` führt ihre `action` aus.
  - Klappt sie (oder gibt es keine), geht es mit dem Dialog in `then` weiter.
  - Schlägt sie fehl (z. B. `pay_gold` bei zu wenig Gold), geht es mit `else` weiter.
  - Gibt es kein `then` bzw. `else`, schließt sich das Fenster.
- **Schleife:** Eine Auswahl darf auf ihren eigenen Dialog zeigen. Echtes Beispiel ist der Überfall: „Niemals!“ führt zu `raid_looter_refuse`, und das bietet dieselben Knöpfe wieder an, bis „Alles hergeben“ gewählt wird.
- **Abgeben mit Slots:** Steht in einer `choice.action` `take_items:…`, `deliver:…` oder `hand_in_set:…`, zeigt die Box automatisch Abgabe-Slots und öffnet das Inventar (`HandInSlots`).

### 4.5 Wie Dialoge den Quest-Fortschritt ändern

Über Aktionen:
- `advance:<schritt>` (nächster Story-Schritt),
- `set_flag:<flag>` (z. B. eines der `progress_flags`),
- `accept_quest:<id>` (QuestData annehmen),
- `give_*`, `take_items`, `unlock_recipes` …

Sie können stehen in einer **Zeile** (`action`, läuft beim Anzeigen), in einer **Auswahl** (`choices[].action`) oder **am Ende** (`on_end`).

### 4.6 Neue Dialoge hinzufügen

1. Unter `"dialogues"` einen Eintrag mit neuer id anlegen.
2. Ihn verbinden, je nach Fall:
   - an einen **Schritt**: `npcs.<id>.dialogues.<schritt> = "<dialog-id>"`
   - **immer, wenn nichts anderes ansteht**: `npcs.<id>.dialogues.default`
   - **unabhängig von Schritten** (Nebendialog):
     ```json
     "side_dialogues": [
       { "npc": "quarry_worker", "flag": "quarry_stones_started", "done_flag": "quarry_stones_done", "dialogue": "odo_stones" }
     ]
     ```
   - **nach einer Auswahl**: `"then": "<dialog-id>"`
3. Spiel starten und die Ausgabe auf Fehler prüfen.

### 4.7 Reihenfolge von Dialogen ändern

- **Reihenfolge der Zeilen:** einfach die Einträge in `lines` umstellen.
- **Welcher Dialog in welchem Schritt:** die Zuordnung in `npcs.<id>.dialogues` ändern.
- **Mehrere Nebendialoge einer Figur:** Der **erste** passende Eintrag in `side_dialogues` gewinnt. Die Reihenfolge in der Liste ist also wichtig.
- **Kette von Gesprächen:** Jeder Dialog setzt am Ende ein Flag, und der nächste Nebendialog hat dieses Flag als `flag`.

### 4.8 Dialoge an Bedingungen knüpfen, wieder verfügbar machen, sperren

| Ziel | Vorgehen |
|---|---|
| erst ab einem Ereignis | Nebendialog mit `flag` |
| nur einmal | Nebendialog mit `done_flag`, und der Dialog setzt es (`on_end: "set_flag:…"`) |
| immer wieder (z. B. ein Angebot) | Nebendialog **ohne** `done_flag` (evtl. `"quiet": true`) |
| nach einer Quest **wieder** verfügbar | neuer Nebendialog mit `flag` = Abschluss-Flag der Quest und eigenem `done_flag` |
| nach einer Quest **gesperrt** | `done_flag` = Abschluss-Flag der Quest |
| einzelne Auswahl ein-/ausblenden | `if_flag` / `unless_flag` an der `choice` |
| Figur ganz weg | `hidden_when_flag` am StoryNpc oder `gone_flag` in `npcs.<id>` |

---

## 5. Ein neues Fenster oder UI-Element erstellen

### 5.1 Wie die UI aufgebaut ist

Es gibt zwei Familien von Fenstern:

| Familie | Basis | Beispiel | Wird geöffnet von |
|---|---|---|---|
| **Stationsfenster** (an etwas in der Welt) | `StationMenu` (`scenes/ui/menus/station_menu.gd`), ein `CanvasLayer` | `sleep_menu` (Bett), `smelter_menu`, `house_menu` | dem Signal `interacted` einer Station |
| **HUD-Fenster** (über Taste oder Seitenleiste) | `PanelContainer` in `scenes/ui/hud/hud.tscn` | `character_window`, `quest_log_window` | `hud.gd` |

Jedes Fenster besteht aus zwei Dateien nebeneinander:
- **`.tscn` = Layout:** welche Nodes, Größen, Texte.
- **`.gd` = Logik:** was beim Klick passiert, welche Daten angezeigt werden.

Das Aussehen (Schrift, Rahmen, Knöpfe) kommt automatisch aus `assets/ui/theme.tres`. Die Titelleiste zum Verschieben und Schließen ist `scenes/ui/window_title_bar.tscn`.

**Schrift:** Micro 5, nur Größe **11** oder **22**. Andere Größen werden unscharf.

### 5.2 Vorlage: das Bett-Fenster (`sleep_menu`)

Es ist das kleinste vollständige Fenster:

```
SleepMenu (CanvasLayer, sleep_menu.gd, title = "Bett")
└── Panel (PanelContainer)                  ← Rahmen, Position am Bildschirm
    └── VBox (VBoxContainer)                ← stapelt alles untereinander
        ├── TitleBar (window_title_bar.tscn, %TitleBar)   ← PFLICHT für StationMenu
        ├── TextLabel (Label, %TextLabel)
        └── Buttons (HBoxContainer)
            ├── SleepButton (Button, %SleepButton)
            └── StayButton  (Button, %StayButton)
```

```gdscript
class_name SleepMenu
extends StationMenu

@onready var _text_label: Label = %TextLabel

func _ready() -> void:
	super()                                      # StationMenu: Titel, verstecken, Gruppe
	%SleepButton.pressed.connect(_on_sleep_pressed)
	%StayButton.pressed.connect(close)
	visibility_changed.connect(_update_text)     # Text bei jedem Öffnen neu

func _on_sleep_pressed() -> void:
	close()
	GameState.sleep()
```

**Wichtig:**
- `%Name` funktioniert nur, wenn am Node „**Als eindeutigen Namen zugreifen**“ an ist (Rechtsklick auf den Node). In der .tscn steht dann `unique_name_in_owner = true`.
- `super()` in `_ready` nicht vergessen, sonst funktionieren Titel, Schließen-X und Escape nicht.

### 5.3 Ein neues Stationsfenster erstellen (Beispiel: Steinmetz-Tisch)

1. `sleep_menu.tscn` und `sleep_menu.gd` im Editor duplizieren → `scenes/ui/menus/stone_menu.tscn` / `.gd`.
2. Im Skript `class_name StoneMenu` setzen, in der Szene das neue Skript anhängen und den `title` ändern.
3. **Inhalte hinzufügen** (Node hinzufügen unter `VBox`):
   - **Text:** `Label` (`autowrap_mode = Word`, `custom_minimum_size.x` setzen, sonst wird es unendlich schmal)
   - **Knopf:** `Button`, `focus_mode = None` (sonst „klebt“ die Leertaste am Knopf)
   - **Bild:** `TextureRect` (`expand_mode`/`stretch_mode` für Pixel-Art: Keep Aspect Centered)
   - **Eingabe:** `LineEdit` (Text) oder `SpinBox` (Zahl)
   - **Item-Slot:** `scenes/ui/inventory/item_slot.tscn` (`ItemSlotUI`, Methode `display(stack)`)
   - **Nebeneinander / untereinander:** `HBoxContainer` / `VBoxContainer`, Abstand über `theme_override_constants/separation`
4. **In die Welt bringen:** In der Karte die `stone_menu.tscn` instanziieren (direkt unter dem Wurzel-Node, wie `SleepMenu` in `bedroom.tscn`). Dann die Signale der Station verbinden:
   - `interacted` → `StoneMenu.toggle`
   - `player_left` → `StoneMenu.close`

   Die Station selbst ist ein `StaticBody2D` mit dem Skript `station.gd` und einem `InteractionArea`-Kind (Vorlage: `bed.tscn`).
5. **Öffnen und schließen:** erledigt `StationMenu` (`toggle()`, `close()`, X, Escape, E bei `closes_on_interact`). Mit `freezes_player = true` steht der Spieler still, solange das Fenster offen ist.

### 5.4 Ein neues HUD-Fenster (über Taste oder Seitenleiste)

Vorlage: `scenes/ui/hud/save_window.tscn` oder `quest_log_window.tscn`.

1. Fenster-Szene anlegen (Wurzel `PanelContainer` mit `VBox/TitleBar`, wie die anderen).
2. In `hud.tscn` instanziieren, „eindeutigen Namen“ einschalten.
3. In `hud.gd`:
   - `@onready var _mein_fenster: MeinFenster = %MeinFenster`
   - in die Liste `_all_windows` aufnehmen (dann schließt es mit Escape und dem X),
   - für „nur eins gleichzeitig“ zusätzlich in `_main_windows` aufnehmen und mit `_toggle_main_window.bind(_mein_fenster)` öffnen,
   - Knopf in der Seitenleiste: `%MeinButton.pressed.connect(_toggle_main_window.bind(_mein_fenster))`,
   - eigene Taste: Aktion unter Projekt » Projekteinstellungen » Eingabezuordnung anlegen und in `_unhandled_input` von `hud.gd` abfragen (wie C/I). Tastenbelegung zum Umstellen: `scripts/core/key_bindings.gd`.
4. **Größe einstellbar** (optional): in `apply_ui_scale()` eintragen.

### 5.5 Daten aus anderen Systemen anzeigen

**Muster** (so machen es alle Fenster, z. B. `character_window.gd`):

```gdscript
func _ready() -> void:
	GameState.gold_changed.connect(func(_g: int) -> void: _refresh())   # Daten ändern sich
	visibility_changed.connect(_refresh)                                # Fenster geht auf

func _refresh() -> void:
	if not visible:
		return            # unsichtbar nichts berechnen
	_gold_label.text = "%d Gold" % GameState.gold
	_name_label.text = GameState.player_name
	_step_label.text = GameState.story.get_objective().get("title", "")
```

Woher die Daten kommen:

| Daten | Abruf | Änderungs-Signal |
|---|---|---|
| Gold | `GameState.gold` | `GameState.gold_changed` |
| Inventar | `GameState.inventory.slots` | `GameState.inventory.changed` |
| Spielerwerte | `GameState.player_stats` | `stats_changed`, `experience_changed` |
| Geschichte | `GameState.story` | `story.changed` |
| Helden | `GameState.heroes` | `GameState.heroes_changed` |
| Item-Infos | `ContentDB.item("iron_ore")` | – |

### 5.6 Benutzereingaben verarbeiten

- **Knopf:** `button.pressed.connect(_on_x_pressed)`
- **Text:** `line_edit.text_submitted.connect(...)` oder `line_edit.text` beim Klick auslesen
- **Zahl:** `spin_box.value_changed.connect(...)`
- **Drag & Drop von Items:** `slot.set_drag_forwarding(...)` wie in `character_window.gd` (`_can_drop_into`, `_drop_into`)
- **Rechtsklick aus dem Inventar:** in deinem `StationMenu` die Methode `try_quick_move(inventory_index, amount)` überschreiben (Vorlage: `dialogue_box.gd` oder `smelter_menu.gd`)

Die eigentliche Logik (Gold abziehen, Item geben) gehört **nicht** ins Fenster, sondern in `GameState` oder ein System unter `scripts/systems/`. Das Fenster ruft nur auf und zeigt an. So bleibt sie testbar.

### 5.7 Mit anderen Systemen verbinden

- Das Fenster **ruft** Funktionen von GameState oder Systemen auf (`GameState.spend_gold(50)`, `GameState.inventory.add_item(...)`).
- Das Fenster **hört** auf deren Signale (5.5).
- Andere sollen dein Fenster öffnen können? Dann ein Signal in GameState anlegen (Vorbild `recipe_book_requested`), das `hud.gd` mit deinem Fenster verbindet. So muss niemand den Pfad zum Fenster kennen.

### 5.8 Testen

- Szene mit dem Fenster öffnen und F6: Sieht es richtig aus? Bei Bedarf in `_ready()` vorübergehend `show()` aufrufen.
- Im Spiel: öffnen, schließen (X, Escape, E), Knöpfe, Fenster verschieben, unter Einstellungen » Oberfläche verschiedene Größen ausprobieren.
- Logik headless testen (Abschnitt 7).

---

## 6. Gegenstände

### 6.1 Neuen Gegenstand anlegen

Alles in **`data/content/items.json`**. Ganz oben steht der Block `"_hilfe"` mit einer Vorlage.

```json
"chisel": {
	"name": "Meißel",
	"description": "Für feine Steinarbeiten.",
	"icon": "res://assets/sprites/items/chisel.png",
	"type": "material",
	"value": 12,
	"stack": 10
}
```

1. **id** wählen (`chisel`, klein mit Unterstrich, später nicht mehr ändern, denn sie steht in Spielständen).
2. **Bild** 12×12 nach `assets/sprites/items/`. Ohne Bild erscheint ein Standard-„?“, das ist als Platzhalter erlaubt.
3. **`type`** bestimmt, was das Item kann: `material`, `ore` (+ `smelt_to`), `fuel` (+ `heat`), `part`, `weapon`, `pickaxe` … Alle Felder stehen in `docs/CONTENT.md` » „items.json – alle Felder“.
4. Spiel starten, Ausgabe prüfen. Mit P » Items im Admin-Panel nachsehen.

**Besondere Fälle:**
- **Schmiedbare Teile und Waffen** (Klinge, Griff, Schwert): bekommen ihre Rezepte automatisch aus `part`/`material`/`parts`, siehe CONTENT.md „Beispiel: Goldklinge“.
- **Samen:** Feld `plant`.
- **Werkzeuge für den Spieler** (Spitzhacke, Axt, Rucksack, Schuhe, Buch): Typ setzen, den Slot regelt `PlayerStats.can_equip_tool()`.

### 6.2 Gegenstände in die Welt einbauen

| Wie bekommt der Spieler es? | Wo eintragen |
|---|---|
| **Abbauen / Sammeln** (Erz, Baum, Pflanze) | neue `data/rocks/<x>.tres` (Duplikat von `hemp_plant.tres`, `tool` = PICKAXE/AXE/HAND, `drop_item_id`), dann in der Karte als `ore_rock.tscn` (Feld `data`) oder in die `rock_types` eines `RockSpawner` |
| **Beim Händler kaufen** | `economy.json` » `market_stock.<stock_id>` (Tagesangebot) oder das Feld `offers` am Händler in der Szene |
| **Aus Dungeons** | `dungeons.json` » `rewards.items` oder als Monster-Drop in `enemies.json` » `drops` |
| **Täglich in die Loot-Kiste** | `story.json` » `daily_rewards` (an ein Flag gebunden) oder eine Quest-Belohnung `DAILY_ITEM` |
| **Herstellen** | über `parts`/`needs` (automatisch) oder `recipes.json` |
| **Aus der Schmelze / Gerberbank / Schleifstein** | Felder `smelt_to`, `tan_to`, `grind_to`, `vial_to` am Ausgangs-Item |

### 6.3 Dem Spieler Gegenstände geben

**Ohne Code** (in `story.json`, als Dialog-Aktion):
```
"give_items:chisel"            ein Meißel
"give_items:coal*5,chisel"     5 Kohle und ein Meißel
"give_gold:50"
```
Was nicht ins Inventar passt, landet in der Loot-Kiste (`GameState.give_items`).

**Als Quest-Belohnung:** `QuestReward` mit `kind = ITEM` (Abschnitt 2.2).

**Im Code:**
```gdscript
# Ein Stück; der Rückgabewert ist, was NICHT gepasst hat
var leftover: int = GameState.inventory.add_item(ContentDB.item("chisel"), 1)
if leftover > 0:
	GameState.put_into_reward_chest(ContentDB.item("chisel"), leftover)

# Oder kürzer, mit derselben Schreibweise wie in story.json
GameState.give_items("chisel,coal*5")
```

**Wegnehmen / prüfen:** `GameState.has_items("coal*5")`, `GameState.take_items("coal*5")` (oder die gleichnamigen Story-Aktionen).

**Reagieren, wenn der Spieler etwas hat:** `story.json` » `"item_actions": {"chisel": "set_flag:has_chisel"}` oder als Schritt-Bedingung `"have_item": "chisel"`.

---

## 7. Testen: von Hand und automatisch

### Von Hand
- **F6** startet nur die offene Szene. Gut für Layout und Kollisionen. Die Geschichte steht dann aber am Anfang.
- **F5** startet das ganze Spiel. Mit **P** springst du zu Kapiteln, Karten und Items.

### Automatisch (headless)
Vorlage: `assets/_reference/festival/test_festival_show.gd`. Gestartet wird so (Pfad zu deiner Godot-Exe anpassen):

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://assets/_reference/<ordner>/test_x.gd
```

Regeln, die sich bewährt haben:
- `extends SceneTree`, Start in `_initialize()` (nicht `_init`, da gibt es GameState noch nicht).
- **Keine** Projektklassen als Typ im Test (`var box = …` statt `var box: DialogueBox = …`).
- Nach `root.add_child(szene)` erst `await process_frame`, dann damit arbeiten.
- Nach einer neuen `class_name` einmal `--headless --path . --import` laufen lassen.
- Vorsicht bei `GameState.sleep()`: Es schreibt den **echten** Autosave. Vorher sichern.

Mini-Beispiel: Kommt man vom Steinbruch-Schritt zum nächsten?

```gdscript
extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var gs = root.get_node("GameState")
	await process_frame
	gs.story.start_new()
	gs.story.advance("quarry_visit")
	gs.story_event("enter:quarry")
	print("Schritt jetzt: ", gs.story.step)   # erwartet: quarry_talk
	quit()
```

---

## 8. Spickzettel: Wo ist was?

| Ich will … | Datei |
|---|---|
| Item, Gegner, Dungeon, Preis ändern | `data/content/*.json` (Felder: `docs/CONTENT.md`) |
| Geschichte, Dialog, Figur-Zuordnung | `data/content/story/` (`steps.json`, `dialogues/<gebiet>.json`, `npcs.json`) |
| Story-Aktion verstehen / neue bauen | `scripts/core/game_state.gd` » `_run_single_story_action` |
| Welche Figur was sagt | `scripts/systems/story.gd` » `get_npc_dialogue` |
| Dialogfenster | `scenes/ui/dialogue/dialogue_box.gd` |
| Figur in der Welt | `scenes/actors/story_npc.gd` |
| Tür / Kartenwechsel | `scenes/world/objects/door.gd`, `GameState.travel_to` |
| Spieler-Bewegung | `scenes/actors/player.gd` |
| Station (E drücken) | `scenes/stations/station.gd` |
| Fenster-Basis | `scenes/ui/menus/station_menu.gd` |
| HUD, Tasten, Hauptfenster | `scenes/ui/hud/hud.gd` |
| Speichern / Laden | `GameState._collect_save_data` / `_apply_save_data`, `scripts/systems/save_system.gd` |
| Admin-Panel | `scenes/ui/menus/admin_panel.gd` |

**Nach jeder Änderung** (Projektregel 10): Kurzfassung in `PROJEKT.md`, Details in `docs/systeme/<system>.md`, Entscheidungen in `docs/ENTSCHEIDUNGEN.md`.
