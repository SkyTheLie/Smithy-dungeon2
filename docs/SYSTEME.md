# Systeme

Jedes System: Zweck, Dateien, wie es funktioniert. Neue Systeme hier anhängen.

## Ablauf (Game, RunScene)

- **Dateien:** `scripts/core/game.gd` (Autoload `Game`), `scenes/run/run.tscn` + `run.gd`
- Ablauf: Hauptmenü → „Neues Spiel“ (`Game.start_intro`) → Intro → Laden (`Game.to_shop`) → Dungeon-Brett „Betreten“ → Charakter → `Game.start_new_run(id)`: neuer `RunState` mit zufälligem Seed, lädt `run.tscn`. Run-Ende „Zum Laden“ → Laden (nächster Tag). „Weiter“ im Hauptmenü → Laden.
- `RunScene` baut die Ebene (`Dungeon.build`), verbindet HUD, Pause (Esc, auch beim Verlassen des Fensters), Tab (Inventar), M (Karte) und gibt die Mausbewegung an den Spieler.
- Falltür → `Game.next_floor()` (gleicher Run, nächste Ebene) oder nach der letzten Ebene der Sieg-Bildschirm. Tod → End-Bildschirm.
- Szenenbaum: `Run` (Node) › `View` (SubViewportContainer, stretch) › `Viewport` (SubViewport 640×360) › `World` (Node3D: `Environment`, `Dungeon`, `Player`); daneben `HUD`, `PauseMenu`, `EndScreen` (CanvasLayer).

## Run-Zustand (RunState, ShotStats)

- **Dateien:** `scripts/systems/run_state.gd`, `scripts/systems/shot_stats.gd`, Daten `data/player.json`, `data/items.json`, `data/synergies.json`
- `give` (Münzen/Bomben/Schlüssel beim Aufheben), `per_coin` (Goldglut: Werte steigen mit den Münzen, `compute_stats` läuft bei jeder Münz-Änderung neu), `blast_proof` (eigene Bomben schaden nicht, `Dungeon.explode`), `mantle` (`block_with_mantle`, jeder neue Raum lädt ihn neu).
- Leben in **halben Herzen** (`health`), `max_hearts`, Münzen, Bomben, Schlüssel, Items, Ebene, Kills.
- `add_item` → `compute_stats`: Startwerte + alle Items + aktive Synergien. Zahlen addieren, `*_mult` multiplizieren, `spread` nimmt den größten Wert. Modus: `beam` schlägt `bomb` schlägt `fire`.
- Synergie: aus jeder `requires`-Gruppe ein Item vorhanden. Neue Synergien sendet `synergy_found` (HUD zeigt „Synergie: …!“).
- `pick_item(pool)`: nie zweimal dasselbe Item pro Run.

## Ebene (FloorLayout, Dungeon, RoomBuilder)

- **Dateien:** `scripts/systems/floor_layout.gd`, `scenes/run/dungeon.gd`, `dungeon_room.gd`, `room_builder.gd`, Daten `data/floors.json`
- `FloorLayout.generate`: Raster 9×8, Start in der Mitte, Räume wachsen nach außen (jeder neue Raum berührt nur einen), danach werden drei Sackgassen zu Boss (am weitesten weg, mind. 3 Räume), Item-Raum und Shop.
- Räume liegen in 3D nebeneinander (15 × 11 m, Wände 3 m); Türöffnungen, wo Nachbarn sind. Farbiger Rahmen: Boss rot, Item gold, Shop grün.
- Raum betreten (ganz drin, nicht im Türdurchgang): normale Räume schließen ihre Türen (`Door.set_closed`) und lassen die vorher ausgewürfelten Gegner erscheinen; der letzte Gegner öffnet sie wieder, manchmal fällt eine Belohnung (`room_drops`).
- Schlüssel-Türen (`key_doors`): Anfassen mit Schlüssel öffnet sie für immer.
- Boss-Raum: Boss erscheint, Lebensbalken oben; danach Falltür (letzte Ebene: goldenes Licht), Boss-Item, ein Herz.
- `explode`: Schaden im Umkreis, sprengt Steine (manchmal mit Münze), eigene Bomben treffen auch den Spieler.

## Testraum (nur beim Start aus dem Editor)

- **Dateien:** `scenes/run/dungeon.gd` (Abschnitt „Test room“), `scenes/objects/pedestal.gd` (`refill`, `RESET`), `RunState.clear_items`
- Admin-Menü (P, nur `OS.is_debug_build()`) → Knopf „Testraum“ bringt den Spieler in einen geschlossenen Raum weit weg von der Ebene (Zelle -10/-10). Nicht während eines Kampfes. Derselbe Knopf = zurück an die alte Stelle.
- Darin ein Sockel für jedes Item aus `data/items.json` (kostenlos). Der rote Sockel „Alle Items ablegen“ nimmt alle Items weg (Herzen zurück auf den Startwert) und füllt alle Sockel wieder. Münzen, Bomben und Schlüssel bleiben.
- Der Raum wird erst beim ersten P gebaut. Keine Gegner darin.

## Spieler und Waffe (Player, Weapon, Projectile)

- **Dateien:** `scenes/actors/player.tscn/.gd`, `weapon.gd`, `projectile.gd`
- Pause nur noch mit Esc (P = Testraum). WASD relativ zur Blickrichtung, Maus dreht (Empfindlichkeit in den Einstellungen), E/Rechtsklick legt eine Bombe (1,6 s Zündschnur). Nach einem Treffer 1 s unverwundbar.
- Dünner weißer Ring am Boden unter dem Spieler zeigt die Körpergröße (`hit_radius`, wächst/schrumpft mit Items; `Fx.ring`).
- Linksklick halten = Dauerfeuer. Schüsse zielen genau auf den Punkt unter dem Fadenkreuz.
- **Feuerball:** fliegt `reach` Meter, fällt dann zu Boden. Flags: `homing` (lenkt zum nächsten Gegner), `pierce`, `bounce` (2×), `boomerang`, `split` (4 Funken beim Treffer), `wave`, `bread` (Brot: Gegner rennen 2,5 s weg), `jitter` (Schrot streut), `explosive`, `burn`/`slow` (Gegner brennen / werden langsamer: `Enemy.afflict`, auch beim Strahl), `grow` (Schaden steigt mit der Flugweite), `shield` (zerstört Gegner-Schüsse). Werte in `player.json` `effects`.
- **Bomben-Modus:** Wurf im Bogen, explodiert am Boden/Gegner; mit `split` Streubomben, mit `homing` rollen sie zum Gegner.
- **Strahl-Modus:** gedrückt halten = Feuerstrahl (Schaden alle 0,1 s); mehrere Schüsse = mehrere Strahlen; `homing` biegt ihn zum Gegner; `explosive` lässt am Ende explodieren.
- **Aufladen (`charge`):** halten lädt (Balken unten), loslassen schießt bis 3× Schaden und größer; mit Strahl: Feuerstoß, so lang wie aufgeladen (Drachenatem).
- **Glutmond (`orbitals`):** Feuerbälle kreisen um den Spieler, verbrennen Gegner, zerstören Gegner-Schüsse.

## Gegner (Enemy, EnemyShot)

- **Dateien:** `scenes/actors/enemy.gd`, `enemy_shot.gd`, Daten `data/enemies.json`
- Smithy-Kampfbilder (`<sprite>_walk.png`, `_death.png`, 6 Bilder à 48 px) als Billboard, gespiegelt je nach Laufrichtung, rot beim Treffer. Dünner orangener Ring am Boden = Treffer-Radius (`radius`); unter der Erde / unsichtbar ausgeblendet.
- KI: `lurk` (Ratten: stehen `wake` Sekunden, laufen dann langsam los), `chase`, `fly`, `hop`, `shooter` (hält Abstand, schießt), `boss` (Angriffe `dash`, `summon`, `ring`, `spray` reihum, unter halbem Leben schneller).
- Berührung kostet `damage` halbe Herzen.

## Oberfläche (Hud, Minimap, Menüs)

- **Dateien:** `scenes/ui/hud/` (`hud.tscn`, `minimap.gd`, `heart_bar.gd`, `crosshair.gd`), `scenes/ui/menus/` (Einstellungen, Pause, Ende), `scenes/ui/main_menu/` (aus Smithy)
- Minimap oben rechts: aktueller Raum von oben, Türen (grau offen, braun zu, gold verschlossen), Steine, liegende Dinge als ihr eigenes Bild (Herz, Bombe, Schlüssel, Beute, Item auf dem Sockel; `Pickup.map_icon`/`Pedestal.map_icon`), Gegner (rot), Spieler (grün mit Blickrichtung). **M** zoomt auf die Ebene. Nebel: nur besuchte Räume und ihre direkten Nachbarn sind zu sehen (`Dungeon.known_cells`), der Boss-Raum erscheint wie jeder Raum erst als Nachbar eines besuchten Raums und bekommt dann einen roten Rand. Geheimräume erscheinen erst nach dem Betreten. Auf der großen Karte zeigt jeder besuchte Raum unten eine Reihe Bilder von dem, was dort noch liegt (zu viele: „+“).
- Pause zeigt die aktuellen Werte und Synergien.
- Herzanzeige: rote Herzen (voll, halb, leer), danach blaue Herzen (`RunState.blue`).

## Sprache und Ton

- `scripts/core/language.gd` (aus Smithy, ohne ContentDB), `scripts/core/audio_manager.gd` (verkleinert), `data/audio.json`. Siehe `docs/SPRACHEN.md`.

## Tests

`bash assets/_reference/run_tests.sh [Name]`: Kompilier-Check aller Skripte/Szenen, `test_floor_layout`, `test_run_state`, `test_content`, `test_language`, `test_dungeon_play` (echte Run-Szene: Kampfraum, echter Schuss, Strahl, Bombe, Boss, Falltür, Tod).

## Fortschritt und Lexikon (Progress, LexiconWindow)

- **Dateien:** `scripts/systems/progress.gd` (statische Klasse, `user://progress.cfg`), `scenes/ui/menus/lexicon_window.tscn/.gd`, Knopf „Lexikon“ im Hauptmenü
- Gemerkt über alle Runs: aufgehobene Items (`discover`, in `RunState.add_item`), Kills (`add_kills`), besiegte Bosse (`beat_boss`, beide in `Dungeon._on_enemy_died`), Siege (`add_win`, `RunScene`). Jede Änderung wird sofort gespeichert.
- Items mit `unlock` sind gesperrt, bis die Bedingung erfüllt ist; `RunState.pick_item` lässt gesperrte weg. Jede Zähl-Funktion gibt die neu freigeschalteten Ids zurück → `RunState.unlocked` → HUD-Banner „Freigeschaltet: …“.
- Wer im Run den Testraum betritt, setzt `record_progress = false`: der Rest des Runs zählt nicht.
- Lexikon: alle Items als Bilder (Reihenfolge wie in `items.json`). Entdeckt: Bild, Name, Wirkung, bekannte Synergien. Sonst dunkel mit „???“; gesperrte rötlich mit der Bedingung und dem Stand („Besiege 200 Gegner (37 / 200)“).
- Testraum: 24 Items pro Seite, blauer Sockel „Nächste Seite“.

## Ebenen und Themen

- `data/floors.json`: `themes` (Name, Texturen, Musik, Licht, Gegner, `bosses`) und `floors` (6 Stück, je `theme`, Raumzahl, `hp_mult`). `Content.floor_data` mischt beides (Ebene gewinnt). Das Thema wechselt alle zwei Ebenen, die zweite Ebene eines Themas hat mehr Gegner-Leben (`hp_mult`).
- Der Boss wird beim Bau der Ebene zufällig aus `bosses` gewählt (`Dungeon.boss_id`).
- Nur der eigene Raum und seine Nachbarn sind sichtbar (`Dungeon._show_near`), der Rest wird nicht gezeichnet.

## Besondere Räume

- `FloorLayout.add_extras` (eigener Zufall, damit die normalen Räume pro Seed gleich bleiben): **Geheimraum** (berührt ≥ 2 Räume, nicht den Boss), **Opferstein** (Chance `sacrifice.room_chance`, Sackgasse an einem normalen Raum), **Sonderraum** hinter dem Boss.
- Versteckte Türen (`Door.hidden`): ein echtes Wandstück mit derselben, an der Welt ausgerichteten Textur füllt die Öffnung, ohne Rahmen und Gitter. Eine Explosion in der Nähe öffnet die Geheimraum-Wand (`Dungeon.explode`), die Karte zeigt solche Räume erst nach dem Betreten.
- Geheimraum: ein Item aus dem Pool `secret` (Items mit `"secret": true`) und drei Pickups.
- Opferstein: Drauftreten kostet ein ganzes Herz (tötet nie), Belohnung nach `sacrifice.rewards` (n-tes Opfer, Chance).
- Nach dem Boss würfelt `RunState.roll_special_room`: Chance steigt 33 → 66 → 100 % pro Ebene ohne Sonderraum, rote Herzen verloren = halbe Chance. **Glutpakt** (Pool `pact`, Preis in Herz-Containern, `RunState.take_pact`) oder **Schrein** (Pool `shrine`, gratis, + ein blaues Herz). Nach dem ersten Pakt kommen nur noch Pakte.

## Neue Item-Mechaniken (Kurzüberblick)

- **Glück** (`luck`): mehr Beute (Raum und Gegner) und jeder Zufallseffekt `chance` +4 % je Punkt (`ShotStats.chance/roll`).
- **Zufallseffekte** (`chance`): pro Schuss gewürfelt (`ShotStats.roll_flags`), mehrere Items mit demselben Effekt stapeln sich. Der Strahl nutzt nur feste Flags.
- **Gegner-Effekte** (`Enemy.afflict`): poison, burn, slow, freeze, fear, daze; Bosse nur kurz eingefroren/verängstigt.
- **Schuss:** spectral, back, cross, shrink, burst, overkill, alternate. **Bomben:** `bomb_size`, bomb_ring, blast_heal.
- **Verteidigung:** damage_cap, dodge (Chance), `guard_time`, thorns, still_guard, regen, kill_heal, double_heal, desperate, fury, small, stomp, extra_life, blue_burst.
- **Geld:** discount, magnet, choice (zwei Boss-Items), `spawn` (Pickups beim Aufheben).
- **Begleiter-Funken** (`helpers`): folgen dem Spieler und schießen auf den nächsten Gegner (`Weapon._update_helpers`).
- Obergrenzen: Laufen `move_speed_min/max`, Schussrate `fire_delay_min` (`player.json limits`).
- HUD links: Tempo, Schaden, Schüsse/s, Reichweite, Schusstempo, Glück, Sonderraum-Chance.
- Neue Freischalt-Arten: `best` (hearts, coins, blue, clean_floors, pacts, floor) und `fast_win` (Minuten).

## Bosse (BossBrain)

- **Dateien:** `scenes/actors/boss_brain.gd`, Daten `enemies.json` (`attacks`, `traits`)
- Jeder Boss hat eine eigene Reihe von Angriffen (Test: keine zwei gleich). Angriffe: dash, charge (bis zur Wand, dann betäubt = doppelter Schaden), summon, rat_wave, ring, spray, spiral, burrow, leap, teleport (hinter den Spieler), phase (unsichtbar), mirror (Feuerbälle fliegen zurück), web (verlangsamt), axes (kommen zurück), boulder (zerplatzt), skulls (verfolgen), march (Schusswand mit Lücke). Unter halbem Leben schneller und mehr Schüsse.
- Ein Boss kommt pro Run nicht zweimal (`RunState.fought_bosses`).

## Gegner-Verhalten

- `leap`: duckt sich, springt hoch auf den Spieler. `burrow`: gräbt sich ein, rote Markierung, kommt unter dem Spieler heraus. `front_guard`: von vorne unverwundbar, dreht sich langsam.
- `voice`: eigener Treffer- und Todes-Laut, im Code erzeugt (`scripts/systems/sound_synth.gd`, `AudioManager.play_stream`). Der Spieler hat auch eine (`player.json voice`).
- `cries` (Tierlaute, `Enemy.cry`): `idle` ab und zu (alle Gegner zusammen höchstens alle 0,7 s), `wake` beim Aufwachen, `near` wenn der Spieler nahe kommt, `attack` kurz **vor** dem Angriff (Ducken vor dem Sprung, 0,45 s vor dem Schuss, Schildstoß, 0,5 s vor jedem Boss-Angriff). Weiter weg = leiser (0,8 dB je Meter ab 2 m). Bisher nur das Thema Rattenkeller (Ratten, Fledermaus, Spinne, 3 Bosse).

## Charaktere

- **Dateien:** `data/characters.json`. Kein Auswahlfenster mehr: der Charakter eines Runs ist die Klasse der angelegten Waffe (`MetaState.run_character`, `gear.json` `class`); ohne Waffe oder solange die Klasse gesperrt ist (`Progress`), der erste Charakter (Magier).
- Die Hauptwaffe ist ein **normales Item** (`start_items`, `RunState._add_start_items`): Magier = Glutstab (Feuerbälle), Bogenschütze (nach einem Sieg) = Jagdbogen (aufladen, viel Reichweite, Pfeil-Bild), Krieger (Ebene 3 erreicht) = Kriegerschwert (Schwung). Sie steht im Inventar, kombiniert sich mit anderen Items über Synergien („Waffen kreuzen“) und bleibt im Testraum beim Leeren. Die Start-Waffen liegen auch im Item-Raum, so findet z. B. der Magier das Schwert. Der Charakter selbst gibt nur noch Herzen (stats/flags dort gehen weiter).
- Waffen kreuzen: **Feuerhieb** (Schwert/Glutschwert/Kriegsaxt + Glutstab/Feuerstab/Höllenstab, Flag `fire_slash`): jeder Schwung schickt ein gebogenes Feuerband nach vorne (`scenes/actors/fire_slash.gd`), Weg = Schwert-Reichweite + Feuer-Reichweite, Schaden x `fire_slash_damage`, trifft jeden Gegner einmal, schlägt Gegner-Schüsse weg, endet an Wand/Stein.
- Das Bild in der Hand ist das neueste Nahkampf-Item (`hand`, sonst `icon`; `Weapon._update_blade_picture`).
- Freischalten über dieselben Bedingungen wie Items (`Progress.meets`).

## Nahkampf, Wurfsterne, Dash

- `mode: melee` (`Weapon._swing`): ein Schnitt von links nach rechts (die Klinge fährt durchs Bild), trifft alle Gegner im Halbkreis vor dem Spieler (`melee_arc` 180°, mehr Schüsse machen ihn nicht breiter), schlägt Gegner-Schüsse weg. Keine Funken und keine Explosionen (auch nicht mit `explosive`). Reihenfolge: Strahl > Bomben > Nahkampf > Feuerball.
- `bleed`: Blutung stapelt sich (bis 5). `shuriken`/`arrow`: nur das Bild des Schusses.
- Shift: `dash` (Sprint, kurz unverwundbar) oder `blink` (Teleport zum Fadenkreuz). Zahlen in `player.json effects`.
- `body` (Größe): Trefferfläche, Augenhöhe; `body_mult` mehrerer Items multipliziert sich (0,5–1,7).

## Räume

- Keine Decken. Steine 1,9 m hoch (man schießt nicht darüber). Muster je Ebene (`floors.json rock_patterns`, `scenes/run/room_patterns.gd`): scatter, walls, pillars, ring, corners, columns, checker; die Wege zwischen den Türen bleiben frei. Jede zweite Ebene eines Themas hat eigene Boden-, Wand- und Steinbilder.
- Ende-Bildschirm: Werte in zwei Spalten, Items scrollbar.
- Items haben eine Kategorie (offensiv / defensiv / utility), Liste: `docs/ITEMLISTE.md`.

## Beute und Inventar (Bag, Pickup, BagWindow) – 2026-11-26, `feature/beute-inventar`

- **Dateien:** `scripts/systems/bag.gd` (`Bag`), `scenes/objects/pickup.gd` (Art `loot`), `scenes/run/dungeon.gd` (`_drop_enemy_loot`, `_drop_loot`, `drop_from_bag`), `scenes/ui/hud/bag_window.gd` (`BagWindow`, im Code gebaut), `scripts/systems/rarity.gd` (`Rarity`, Farben aus Smithy), Daten `data/loot.json`, `data/meta.json` „bag“
- Jeder Gegner würfelt beim Tod jede Zeile seiner Beute-Tabelle (`loot.json` „enemies“) einzeln (`chance` + Glück × `luck_bonus`), Menge `amount` [min, max]. Die Beute liegt als `Pickup` am Boden.
- Drüberlaufen legt sie in die Tasche (`RunState.bag`): erst auf gleiche Stapel (höchstens `stack`), dann in leere Plätze. Passt nichts mehr: Meldung „Inventar voll!“, die Beute bleibt liegen. Nach dem Tod wird nichts mehr aufgehoben.
- **Tab** (`Controls.BAG`) öffnet das Inventar und hält das Spiel an. Rahmen in Seltenheitsfarbe, Anzahl unten rechts, unten die Beschreibung des Platzes unter der Maus. Drag & Drop (`set_drag_forwarding`): auf einen Platz = stapeln oder tauschen (`Bag.move`), auf den dunklen Hintergrund = vor dem Spieler auf den Boden (`Dungeon.drop_from_bag`). Fallengelassenes wird erst wieder aufgehoben, wenn man einmal 1,6 m weg war.
- Der **sichere Platz** (`safe_slots`, goldener Rahmen) wird nur von Hand gefüllt; beim Tod bleibt nur er (`Bag.lose_unsafe`).
- Das **Geldbündel** zeigt `RunState.coins` (kein Platz der Tasche). Münzen gehen jetzt bis 9999 (`MAX_COINS`); `per_coin`-Items zählen höchstens 99.
- **M** ist jetzt die Karte (vorher Tab).

## Spielstand zwischen Runs (MetaState) – 2026-11-26, `feature/beute-inventar`

- **Dateien:** `scripts/systems/meta_state.gd` (statische Klasse, `user://save_<a|b|c>.cfg`), Daten `data/meta.json` „money_box“
- **Drei Spielstand-Plätze** A, B, C (`SLOTS`), je Platz genau ein Spielstand. Der gewählte Platz steht in den Einstellungen (`save`/`slot`). `has_save`, `peek` (Tag und Gold eines Platzes für die Auswahl), `start_new` (Neues Spiel: Platz beginnt bei Tag 1).
- Gespeichert wird am Ende jedes Tages (`end_run`, nach der Nacht mit Egons Griff in die Dose) und wenn Gold das sichere Zuhause verlässt (`take_purse_for_run`, `deposit`, `withdraw`), damit Beenden nie Gold verdoppelt. Ein Run selbst wird nie gespeichert.
- `purse` (Gold bei sich), `box` (die Dose), `stash` (mitgebrachte Beute), `day` (ein Run = ein Tag), `last_theft`.
- `Game.start_new_run` nimmt die Geldbörse mit in den Run (`take_purse_for_run` → `RunState.bring_gold`).
- Run-Ende (`RunScene`): Sieg → `end_run(coins, ganze Tasche)`, Tod → `end_run(0, nur sicherer Platz)`. Wer den Run über das Hauptmenü verlässt, verliert die mitgenommene Geldbörse auch.
- `end_run` beginnt einen neuen Tag und würfelt den Diebstahl (`roll_theft`): bis `limit` nie; darüber `steal_all_chance` = alles, `steal_part_chance` = ein Anteil (`steal_part_share`) des Geldes über dem Limit.
- `deposit` / `withdraw` prüfen die Menge (≤ 0 oder zu viel = abgelehnt). Noch kein Bildschirm dafür (kommt mit dem Laden).

## Spielstand-Wahl, Intro, Laden, Dungeon-Brett – 2026-11-26, `feature/intro-laden`

- **Dateien:** `scenes/ui/main_menu/slot_select.gd` (`SlotSelect`), `scenes/story/intro.tscn/.gd` (`Intro`), `scenes/story/waving_hand.gd` (`WavingHand`), `scenes/shop/shop.tscn/.gd` (`MerchantShop`), `scenes/shop/dungeon_board.gd` (`DungeonBoard`), Daten `data/dungeons.json`
- **Hauptmenü:** Sprache (erster Start) → Spielstand-Wahl A/B/C (einmal je Programmstart, `MainMenu.slot_chosen`) → Schmiede-Tür → Amboss-Menü. „Weiter“ steht oben, nur wenn der Platz einen Spielstand hat. „Neues Spiel“ fragt bei einem belegten Platz nach („überschreiben?“), dann wird es schwarz → Intro.
- **Intro** (Einsteiger-Szene, Skizze `assets/_reference/vorlagen/intro_skizze.png`): kurz schwarz, dann hell; draußen vor der Felswand (`mine/cliff_open.png`) mit dem Dungeon-Eingang, davor ein glühender Weg (gezeichnet). Links daneben Egon an seinem Stand, er winkt (`WavingHand`) und ruft dich (`story.json` `intro_call`). Drei Bilder (`ZOOMS`): man geht in zwei Schritten auf ihn zu (Zoom mit Wippen), dann stellt er sich vor (`intro`). Danach schwarz → Laden. Leertaste/Klick = nächster Satz, Esc = überspringen.
- **Laden:** siehe „Egons Laden“ unten.
- **Dungeon-Brett** (wie das Brett der Abenteuergilde in Smithy): links Reiter je Gebiet (`region`) mit seinen Dungeons, rechts Name, Stufe, Anzahl Ebenen und Gebiete (aus `floors.json`), Beschreibung, „Betreten“ → sofort der Run (Charakter = Klasse der angelegten Waffe, `MetaState.run_character`). Bisher spielen alle Dungeons die Ebenen aus `floors.json`.

## Egons Laden, Ausrüstung, Sprechfenster – 2026-11-26, `feature/laden-tutorial`

- **Dateien:** `scenes/shop/shop.gd` (`MerchantShop`), `shop_slot.gd` (`ShopSlot`), `hero_panel.gd` (`HeroPanel`), `scenes/story/dialog_box.gd` (`DialogBox`), `scripts/systems/shop_goods.gd` (`ShopGoods`), `MetaState`; Daten `data/gear.json`, `data/shop.json`, `data/story.json`; Skizze `assets/_reference/vorlagen/laden_skizze.png`
- **Aufbau** (640×360 in der Mitte): oben Egons Tisch (5×2 `ShopSlot` mit Preis), rechts daneben der Hebel (`fortress/lever_up/down.png`) mit dem heutigen Preis darunter, links die Helden-Ansicht (`HeroPanel`: Silhouette `ui/doll.png`, ein Platz je `gear.json` `slots`, leer mit Hinweisbild), unten das Inventar (`MetaState.stash`, 8 Spalten, wächst mit), in der Mitte Egons Sprechfenster, rechts Egon. Oben links Tag und Gold, unten links „Hauptmenü“, unten rechts „Dungeons“.
- **Regeln** (nur in `MetaState`/`ShopGoods`): Hebel `pull_lever` (Preis `roll_prices` nach Zügen heute, der erste am Tag gratis, ohne Gold abgelehnt) → `ShopGoods.roll`: `goods_count` Sachen aus `pool` auf zufälligen Plätzen, Seltenheit aus `rarity_weights`, Preis = `price` × `rarity_price`. `buy` (Gold prüfen, Ware ins Inventar), `equip` (nur Ausrüstung, Altes zurück ins Inventar), `unequip`. Ein neuer Tag (`end_run`) setzt die Hebel-Züge zurück; der Tisch bleibt liegen.
- **Ausrüstung** im Inventar: `{id, count 1, rarity}`, getragen: `equipment` = Platz → `{id, rarity}`. Werte = `gear.json` `stats` × `rarity_stats`.
- **Ausrüstung im Run** (`RunState.use_gear`, aufgerufen von `Game.start_new_run`): `shield_hearts` werden weiße Schild-Herzen (`RunState.shield`, halbe Herzen, gerundet): Treffer nehmen sie vor blauen und roten, sie heilen nicht nach. Alle anderen Werte (Waffe: Schaden) zählen wie ein Item den ganzen Run. Jedes Kupfer-Rüstungsteil = ½ Schild-Herz; die `HeartBar` zeigt sie weiß hinter den blauen.
- **Bedienung:** Hebel anklicken (Tisch klappt um, Ware ploppt auf); Ware anklicken = kaufen (fliegt ins Inventar); Ausrüstung im Inventar anklicken = anlegen (fliegt an die Figur); Platz an der Figur anklicken = ablegen. Egon kommentiert (`story.json` `barks`).
- **Erster Besuch** (`tutorial_done` = false): alles gesperrt, Egon redet (`tutorial_*`), der Hebel leuchtet, er zieht ihn (`lay_tutorial_table`, `shop.json` `tutorial.goods`), seine Geschenke (`tutorial.gifts`) leuchten auf, er kauft sie (gratis) ins Inventar, zieht sie dir an und schickt dich los: das Dungeon-Brett geht auf und lässt sich nicht schließen (`DungeonBoard.forced`, Esc und „Schließen“ aus).
- **`DialogBox`:** Gesicht (Ausschnitt aus `story.json` `portrait`), Name, Text tippt sich; `speak(lines)` wartet auf Leertaste/Enter/Klick (erster Druck zeigt den ganzen Satz), `bark(line)` wartet nicht.

## Dungeon: Flucht, Münzen, Tab-Karte, HUD – 2026-11-26, `feature/dungeon-flucht`

- **Ausgang im Startraum** (`scenes/objects/dungeon_exit.gd`, `DungeonExit`): in jedem Startraum eine Leiter mit Tageslicht in der hinteren linken Ecke (Ecken haben nie Türen), Schild „Ausgang“. Drauftreten → `Dungeon.exit_entered` → `RunScene` hält das Spiel an und fragt „Flüchten / Weiterkämpfen“. Flüchten = wie ein Sieg: Münzen und ganze Tasche nach Hause (`MetaState.end_run`), End-Bildschirm „Geflüchtet!“. Nach „Weiterkämpfen“ fragt die Leiter erst wieder, wenn man weggegangen ist.
- **Tod** unverändert (Entscheidung 2026-11-26): Münzen und Tasche weg, nur der sichere Platz bleibt.
- **Münzen:** eine aufgehobene Münze ist `player.json` `coin_pickup` [8, 12] wert (`RunState.pick_up_coin`, gewürfelt mit dem Seed des Runs).
- **Tab** (`BagWindow`): links die Ausrüstung von zu Hause (`HeroPanel`, nur Anzeige) und darunter die Werte des Runs (Schaden, Angriffstempo, Tempo, Glück), in der Mitte die Tasche, rechts die ganze Ebene (`Minimap` mit `always_big`, so weit rausgezoomt, dass alle bekannten Räume passen), unten die Items des Runs groß (26 px) mit Name und Beschreibung beim Drüberfahren.
- **HUD:** oben links größere Herzen (`HeartBar` 28 px), darunter nur Bomben und Schlüssel; die Münz-Anzeige (Geld steht im Inventar beim Geldbündel) und die Werte-Spalte links sind weg (Werte stehen im Pausenmenü).

## Einstellungen und Spielstände löschen – 2026-11-26, `feature/spielstand-einstellungen`

- **Spielstand löschen:** unter jedem belegten Platz der Spielstand-Wahl ein Knopf „Löschen“, nach Rückfrage `MetaState.delete_slot` (Datei weg).
- **Einstellungen** (`scenes/ui/menus/settings_window.gd`, im Code gebaut, Reiter wie in Smithy):
  - Grafik: Anzeige Fenster / Rahmenlos / Vollbild, Fenstergröße (nur im Fenster), VSync, Sichtfeld 60–100° (`DisplaySettings`, `scripts/core/display_settings.gd`; der Spieler hört auf `Game.fov_changed`), Sprache (nur Hauptmenü).
  - Audio: Lautstärke, Musik, Effekte.
  - Steuerung: Maus und die erste Taste jeder Aktion in `Controls.REBINDABLE` (Taste anklicken, neue drücken, Esc bricht ab); eine Taste, die schon eine andere Aktion hat, wird dort weggenommen (die bekommt ihren Standard zurück); „Standard wiederherstellen“. Gespeichert in `settings.cfg` Abschnitt `keys`; Pfeiltasten und Maustasten bleiben fest.

## Item-Raum nur mit Schlüssel – 2026-11-26, `feature/item-raum-schluessel`

- Ebene 1 hat keinen Item-Raum (`floors.json` `"item_room": false` → `FloorLayout.remove_item_room`, der Raum wird ein normaler Raum; die Karte bleibt für denselben Seed gleich). Ab Ebene 2 steht `item` in `key_doors`: die Tür geht nur mit einem Schlüssel auf, drin liegt ein zufälliges Item aus dem Item-Pool auf einem Sockel.
- **Erste Ebene des ersten Dungeons klein (2026-11-27):** höchstens 6 Räume: Start, 3 normale, Boss, sicherer Opferraum. `floors.json` je Ebene: `shop_room: false` (kein Shop, `FloorLayout.generate(rng, n, dead_ends)` braucht dann eine Sackgasse weniger), `secret_room` / `special_room: false` (`add_extras`), `sacrifice_chance` (überschreibt `sacrifice.room_chance`; findet sich keine Sackgasse an einem normalen Raum, kommt der Opferraum an den Start-Raum).

## Gold in der Tasche – 2026-11-26, `feature/geld-in-tasche`

- Das Gold des Runs ist das Material `gold` (`loot.json`, Stapel bis 999 über `stack`) in der Tasche: fallen lassen, umsortieren, in den sicheren Platz legen wie alles andere. `RunState.coins` zählt nur das Gold in der Tasche (eine Quelle); `add_coins` legt hinein (gibt zurück, was nicht passt), `spend` nimmt heraus (`Bag.remove`, normale Plätze zuerst). Das Geldbündel-Feld im Tab-Fenster ist weg.
- Münzen auf dem Boden werden beim Anfassen zu 8–12 Gold für die Tasche; ist sie voll, bleibt das Gold liegen („Inventar voll!“).
- Run-Ende: Gold aus der Tasche geht in die Geldbörse zu Hause (`MetaState.end_run`), nicht ins Inventar. Beim Tod nur das Gold im sicheren Platz.
- **End-Bildschirm** (2026-11-26): keine Knöpfe mehr. Nach 0,6 s blinkt „Klicken, um weiterzumachen“; ein Klick oder eine Taste, und man wacht vor Egon auf (`Game.to_shop`). Ins Hauptmenü geht es aus dem Laden.
- ~~**Kleiner Rucksack** (2026-11-26)~~ ersetzt durch das Raster-Inventar (2026-11-27, unten): im Run nur 4 Plätze plus sicherer Platz (`meta.json` `bag.slots` 4), Beute stapelt nicht (`bag.stack` 1), nur Gold stapelt (bis 999). Zu Hause im Laden ist das Inventar weiter groß und wächst mit.

## Relikte – 2026-11-26, `feature/relikte`

- **Daten:** `data/relics.json`: `items` (Item-Id → Stufe 1–4; nur gelistete Items können Relikte werden, die Startwaffen nicht), `tiers` (je Stufe `dungeons` = Runs Haltbarkeit, 0 = für immer, `price`, `rarity` = Rahmenfarbe, `weight` = wie oft auf dem Tisch), `table_chance` (je Hebel-Zug). Erste Stufen per Faustregel aus den Item-Werten vergeben (schwach = +Herz/Tempo/Reichweite → 1, Schaden → 2, Flags/Multiplikatoren → 3, Mehrfachschuss/Modus/geheim → 4).
- **Freischalten:** ein Item, das einmal aufgehoben wurde (`Progress.discover`, steht im Lexikon), kann ab dann als Relikt auf Egons Tisch liegen (`ShopGoods.pick_relic`).
- **Kaufen und Anlegen:** wie Ausrüstung (`MetaState.buy` / `equip`); Relikte gehen in den Platz `relic` (`gear.json` slots). Im Inventar und am Helden `{id, relic: true, left}` (`left` -1 = für immer).
- **Im Run:** `RunState.use_gear` fügt das Relikt als sein Item hinzu (zählt für Synergien, steht in der Item-Leiste).
- **Haltbarkeit:** `MetaState.end_run` zieht dem angelegten Relikt einen Run ab; bei 0 ist es kaputt (`broken_relic`), Egon sagt es beim nächsten Laden-Besuch (`story.json` `barks.relic_broken`).

## Stufen und Skillbaum – 2026-11-26, `feature/level-skillbaum`

- **Stufen** (`data/levels.json`, `Skills`, `MetaState.level/exp_points/skill_points/add_exp`): jeder Kill gibt EXP (`RunState.add_kill_exp`, Boss mehr), gutgeschrieben am Ende jedes Runs (Tod, Flucht, Sieg; `RunScene`). Start mit Stufe 0 und 0 Skillpunkten; Stufe 1 braucht 64 EXP, Stufe 2–4 je 90 (`exp_table`, nach dem ersten Run ≈ 80 % von Stufe 1, nach dem zweiten Stufe 1 + ≈ 80 %), danach 30 × 1,25^Stufe wie vorher, bis Stufe 30. Jede Stufe +1 Skillpunkt. Laden oben links: Tag, Stufe, EXP; End-Bildschirm: EXP und neue Stufe.
- **Skillbaum** (`data/skills.json`, `scenes/shop/skill_tree.gd`, `skill_tree_window.gd`, `scenes/ui/common/pan_zoom_view.gd` aus Smithy Defense): Knopf „Skills (N)“ im Laden. Jeder Skill: Position, Vorgänger, Stufen mit Gold-, Skillpunkt-Preis und Mindest-Spielerstufe. Ziehen in alle Richtungen, Mausrad zoomt, goldener Rahmen = lernbar (`MetaState.buy_skill`, prüft `Skills.problem`).
- **Wirkung im Run** (`RunState.use_skills`, von `Game.start_new_run`): Rucksack-Plätze und sichere Plätze (`Bag.grow`), weiße Schild-Herzen, rote Herzen, Werte (eine Quelle wie ein Item), Gold je Münze. Relikt-Plätze: Reihe unter der Figur (`MetaState.relic_slot_names`, relic_1 … bis 3), Reliktpflege: neue Relikte halten länger (`ShopGoods.make_relic`).

## Verkaufen bei Egon – 2026-11-26, `feature/verkaufen`

- Oben rechts im Laden der Ankauf-Platz: Rechtsklick auf ein Ding im Inventar legt es dorthin (im Inventar abgedunkelt), „Verkaufen: N Gold“ verkauft den ganzen Stapel (`MetaState.sell`), Klick auf den Ankauf-Platz legt es zurück. Preis (`ShopGoods.sell_price`): Beute = `loot.json` `value` × Anzahl; Ausrüstung und Relikte = `shop.json` `sell_share` (30 %) des Kaufpreises.

## Münzsack und Dose im Laden – 2026-11-26, `feature/dose`

- Das Gold zu Hause ist der **Münzsack** im Inventar (Eintrag `gold` im `stash`, immer am Ende; `MetaState.purse` zählt ihn, `_set_purse` schreibt ihn; alte Spielstände mit Zahl „purse“ werden mitgezählt). Er kann nicht verkauft oder angezogen werden.
- **Dose** unten rechts im Laden (`MetaState.box`, Limit `meta.json` `money_box.limit`): darüber „Dose 120/200“, grün bis zum Limit, rot darüber mit „Egon könnte klauen!“ (die Diebstahl-Regel `roll_theft` gab es schon). Münzsack auf die Dose ziehen = alles hinein, Dose ins Inventar ziehen oder anklicken = alles heraus, „+10“ / „−10“.
- **Skillbaum in Gruppen** (2026-11-26, Skizze des Entwicklers): drei Gruppen ohne gemeinsame Wurzel, je mit Überschrift (`skills.json` `groups`): Kampf (Kraft → Leichtfuß → Flinke Hände → Weitblick / Glückspilz), Rucksack (Größerer Rucksack → Geheimtasche), Relikte & Überleben (Zähigkeit → Relikt-Platz → Reliktpflege → Dicke Haut / Goldnase). Beim Öffnen ist der ganze Baum zu sehen (`PanZoomView.fit_view`).

## Laden-Tour mit Leuchten, Chancen-Balken, Lexikon nach Stufen – 2026-11-26, `feature/laden-erklaerung`

- **Tour:** was Egon erklärt, leuchtet (goldene, pulsierende Rahmen, `MerchantShop._explain` / `_spotlight`): Tisch, Hebel, Ware, Chancen-Balken, Hebel-Preis (Neu-Würfeln), Geschenke, Inventar, Figur, Anziehen/Ausziehen, Münzsack + Goldanzeige (Egon schenkt `shop.json` `tutorial.gold` = 50), Dose, Ankauf, Skills, Dungeons. Texte `story.json` `tutorial_*`.
- **Chancen-Balken** über dem Hebel (`scenes/shop/chance_bar.gd`): Abschnitte je Seltenheit in ihrer Farbe mit „R1 85 % · R2 15 %“, Tooltip mit Relikt-Chance und offenen Relikt-Stufen. Die Chancen hängen von der Spielerstufe ab (`shop.json` `rarity_by_level`, `ShopGoods.rarity_weights/rarity_chances`); am Anfang nur R1 (Kupfer).
- **Relikt-Stufen nach Spielerstufe** (`relics.json` tiers `level`: R1 ab 0, R2 ab 5, R3 ab 10, R4 ab 20; Rahmenfarbe = Stufe). `ShopGoods.pick_relic` nimmt nur offene Stufen.
- **Lexikon** gruppiert nach Relikt-Stufe (R1 … R4 mit Haltbarkeit, dann „Kein Relikt“).

## Gold nur in der Dose, im Dungeon nur Beute – 2026-11-26, `feature/geld-schatulle`

Gilt ab jetzt statt der älteren Abschnitte über Geldbörse, Münzsack und Münzen am Boden.

- **Zu Hause:** alles Gold liegt in der **Dose** (`MetaState.box`, eine Quelle). Es gibt keinen Münzsack im Inventar und keine Geldbörse mehr (`purse`, `deposit`, `withdraw`, `take_purse_for_run` sind weg). Kaufen, Hebel und Skills zahlen aus der Dose, Verkaufen bei Egon füllt sie. Über dem Limit (200) kann Egon jede Nacht klauen: Gold sparen ist ein Risiko. Alte Spielstände: Geldbörse und Münzsack wandern beim Lesen einmal in die Dose (`MetaState._move_old_gold`).
- Im Laden: Gold oben links = Dose; die Dose rechts unten zeigt nur noch „Dose 120/200“ (grün/rot, Warnung), keine Knöpfe und kein Ziehen mehr.
- **Im Dungeon gibt es kein Gold zu finden:** keine Münzen von Gegnern, Steinen, Raum-Belohnungen (`floors.json` `room_drops` ohne `coin`, Chance 0,25) oder am Opferstein (dort jetzt Beute: Kupfererz, Eisenerz, Bernstein). Ein Run startet mit 0 Gold (`player.json` ohne `coins`/`coin_pickup`).
- **Dungeon-Shop:** der Händler dort kauft Beute an. Im Shop-Raum Tab → Rechtsklick auf einen Platz verkauft den ganzen Stapel für den `loot.json`-Wert (+ Goldnase je Stück) (`BagWindow.sell` → `Dungeon.sell_from_bag` → `RunState.sell_from_bag`). Das Gold kommt in die Tasche (auf den Gold-Stapel, sonst in den frei gewordenen Platz). Beim ersten Betreten: „Der Händler kauft Beute: Tab, Rechtsklick“. Außerhalb des Shops verkauft der Rechtsklick nichts.
- Übriges Gold nach dem Run (Sieg, Flucht) → Dose; Tod → weg, außer im sicheren Platz.
- **Münz-Items umgebaut:** `give` kennt `loot` statt `coins` (`{"loot": {"amber": 1}}`; passt es nicht in die Tasche, fällt es auf den Boden, Signal `RunState.loot_overflow`). Wanderbündel → Bernstein, Karawanenrucksack → Wolfsfell, Schatzbeutel → Rubin, Goblinkrone/Silberader → Silbererz, Goldader → Golderz, Glühender Schlüssel → zwei Golderze. Truhenschlüssel ohne Münze. Neue Beute `silver_ore` (15) und `gold_ore` (30). Goldglut/Spardose zählen das Gold in der Tasche (also das Shop-Guthaben).
- **Goldnase** (Skill): `effect` `sell_bonus` statt `coin_bonus`: der Händler im Dungeon zahlt 2 Gold mehr je Beute-Stück.

## Bosse: höchstens 5 Helfer – 2026-11-26, `feature/geld-schatulle`

- `Dungeon.summon` ruft nur, solange weniger als `enemies.json` `summon_max` (5) Helfer gleichzeitig leben (`Dungeon.helper_count` = Gegner außer dem Boss). Gilt für alle Bosse und alle Ruf-Angriffe (`summon`, `rat_wave`).

## Laden-Skills und bessere Chancen beim Neu-Würfeln – 2026-11-26, `feature/laden-skills`

- **Chancen** (`ShopGoods.rarity_weights(pulls_today)`, Prozent je Seltenheit): Grundwerte nach Spielerstufe (`shop.json` `rarity_by_level`), dann die Skills (`effect` `rarity`: so viele Prozent von R1 zur Seltenheit, `Skills.rarity_bonus`), dann das Neu-Würfeln: jeder frühere Zug heute schiebt `reroll_shift` (5) Prozent von R1 zu den selteneren Stufen, die es gerade gibt, verteilt nach deren Chancen (höchstens `reroll_shift_max` 25). R1 bleibt mindestens `r1_min` (10 %). Nur R1 (Stufe 0, ohne Skills): Neu-Würfeln ändert nichts.
- `MetaState.pull_lever` würfelt mit den Chancen des aktuellen Zugs (`ShopGoods.roll(rng, pulls_today)`); der Chancen-Balken zeigt den nächsten Zug (Tooltip nennt die Verschiebung). Neuer Tag = wieder Grundwerte.
- **Skill-Gruppe „Laden“** (`skills.json`, Spalte 6): Mehr Ware (+1 Sache auf dem Tisch je Stufe, `goods_extra`, 3 Stufen) → Glückliches Händchen (+5 % R2 je Stufe, 3 Stufen) → Seltene Ware (+3 % R3 je Stufe, 2 Stufen; R3 also schon vor Spielerstufe 10).
- Egons Tour: neuer Satz beim Neu-Würfeln („Dafür wird die Ware mit jedem Dreh besser.“).

## Vier Dungeons, Materialien, Fallen, Balance – 2026-11-27, `feature/balance`

Zahlen und Ziele: `docs/BALANCE.md`, Rechner `py assets/_reference/balance/balance.py`.

- **Mehrere Dungeons:** `dungeons.json` je Dungeon `floors` (Liste in `floors.json`: `floors` für die Glut, `floors_moor`, `floors_frost`, `floors_vulkan`), `unlock` (`dungeon` = vorher schaffen, `level`), `hp_mult`, `exp_mult`, `shop_mult`. `Content.active_dungeon` (gesetzt von `Game.start_new_run(character, dungeon)`) wählt die Ebenen; `Content.floors(id)` / `Content.floor_data(index, id)` rechnen die Dungeon-Faktoren ein (Leben = Ebene × Dungeon, EXP je Kill × `exp_mult` über `RunState.add_kill_exp`, Run-Shop × `shop_mult` × (1 + `shop.floor_step` × Ebene)).
- **Siege je Spielstand:** `MetaState.win_dungeon` (beim Sieg in `RunScene`), `has_won`, `is_dungeon_open`, `meets({dungeon, level})`. Neues Spiel = nur der erste Dungeon offen. Dungeon-Brett: gesperrte Dungeons grau mit „Gesperrt: erst … schaffen.“, „Betreten“ aus; geschaffte mit „Schon einmal geschafft!“.
- **Materialien bei Egon:** `shop.json` `materials` (Kupfer, Bronze ab Stufe 3, Eisen nach der Glut, Silber nach dem Moor, Gold nach Frost). `ShopGoods.roll` würfelt erst das Material (`open_materials`, alte Materialien × `old_material_mult`), dann das Teil (`pool`); Ware = `gear.json` `<material>_<teil>` (40 Teile). Der Hebel kostet × `lever_mult` des besten offenen Materials. Tooltip des Chancen-Balkens: Material-Chancen und was als Nächstes öffnet.
- **Ausrüstung neu verteilt:** Waffe und Handschuhe = Schaden, Helm/Brust/Beine = Schild-Herzen, Stiefel = Tempo (Werte je Material, `docs/BALANCE.md`).
- **Fallen** (`scenes/objects/hazard.gd`, `Hazard`): `floors.json` `hazard_types` (lava, poison, spikes, ice_spikes: damage, size, cycle, color, glow); Gebiete/Ebenen `hazards` [[Art, [min, max]]]. `Dungeon._add_hazards` legt sie in normale Räume (eigener Zufall, Tür-Wege ±1,4 m, Mitte und Steine frei), `_check_hazards` trifft den Spieler über `Player.take_hit` (danach die übliche Unverwundbarkeit). Stacheln fahren im Takt `cycle` [unten, oben] aus, kurz vorher wackeln sie.
- **Neue Gegner:** 65 (davon 22 Bosse) aus den Smithy-Bildern, mit eigener Stimme und Beute; 23 neue Beute-Sorten (Werte steigen je Dungeon).
- **Größere Dose** (Skill, Gruppe „Laden“): `MetaState.box_limit` = `meta.json` Limit + `Skills.bonus("box_limit")`.
- **Stufen** `growth` 1,25; Seltenheiten R4/R5/R7 ab Stufe 16/21/28; Skill-Preise nach Stufe gestaffelt.

## Tränke und Trank-Platz – 2026-11-27, `feature/wiese-traenke`

- **Daten:** `data/potions.json` (`unlock_deaths` 2, `slots` 1, `table_chance`, `tour_potion`, `potions`: Heiltrank heilt 2 Herzen, Großer Heiltrank 3 Herzen nach der Glut). Ein Trank ist `{id, potion: true}` (+ `price` auf dem Tisch, + `count` im Inventar).
- **Tode zählen:** `MetaState.add_death` (in `RunScene._on_died`, Flucht zählt nicht), `deaths`. Nach dem 2. Tod ist `MetaState.potion_tour_due`: beim nächsten Laden-Besuch macht Egon seine **Trank-Vorführung** (`MerchantShop._run_potion_tour`): kurz besorgt, er zieht den Hebel (gratis, kein Zug des Tages, `MetaState.lay_potion_table` / `ShopGoods.potion_table`), der Heiltrank leuchtet, er kauft ihn (gratis), er fliegt ins Inventar, dann in den Trank-Platz. Danach `MetaState.unlock_potions`: Tränke kommen auf den Tisch (`ShopGoods.pick_potion`, Chance `table_chance`).
- **Trank-Platz:** in der Helden-Ansicht unten links neben den Füßen (`HeroPanel`, „Trank“, erst nach der Vorführung sichtbar; eine eigene Reihe unter den Relikten hätte den Hauptmenü-Knopf verdeckt). `MetaState.potion_slot_names`, `slot_of` (Trank → erster freier Trank-Platz), `equip`/`unequip` wie bei Ausrüstung; Egon kauft Tränke für 30 % zurück.
- **Im Dungeon:** `RunState.use_gear` nimmt die Tränke mit (`RunState.potions`), **Q** (`Controls.POTION`, in den Einstellungen änderbar) ruft `Player._drink_potion` → `RunState.drink_potion` (heilt, nimmt den Trank auch zu Hause vom Helden: `MetaState.use_potion`). Bei vollem Leben oder ohne Trank passiert nichts (HUD-Meldung). Das HUD zeigt unter Bomben/Schlüsseln das Trank-Bild und die Taste.

## Wispernde Wiese, neue Gegner-Muster – 2026-11-27, `feature/wiese-traenke`

- **Dungeon `wiese`** (nach dem Moor, wie der Frostgipfel; Leben ×2,5): Gebiete Hohes Gras, Kristallwiese, Jagdgrund (`floors_wiese`). Ebene 6 hat immer den Wildhüter als Boss (Ebene 3/4 nehmen Kristallkoloss und Spinnenmutter vorweg).
- **Hohes Gras** (`scenes/run/meadow.gd`, `Meadow.add_grass`): je Raum ein `MultiMeshInstance3D` aus vielen gekreuzten 2D-Büscheln (Bild im Code), `floors.json` `grass` {height, per_m2, color, spread}. Kleine Gegner (Grasotter 0,8 m) und Fallen verschwinden darin. Nicht im Startraum (Steuerungs-Text).
- **Neue Fallen:** `snare` (Fangeisen, versteckt), `snare_thrown` (vom Boss geworfen, sichtbar), `hidden_spikes`. `Hazard.holds()` / `spring(player)`: schnappt einmal zu, halber Herz Schaden, `Player.hold(sek)` (kein Laufen, kein Dash; Schießen geht), dann weg. `hidden`: kaum sichtbarer Fleck. `Dungeon.add_hazard(kind, at, life)` für geworfene Fallen.
- **Neue Gegner-Arten** (`scenes/actors/enemy_moves.gd`, `EnemyMoves`), jede mit Vorwarnung (Wackeln, Anschwellen, Ziel-Linie):
  - `charger` (Grasotter): läuft auf den Raum-Achsen; steht der Spieler in seiner Reihe/Spalte, wackelt er und stürmt geradeaus bis zur Wand, dann kurz betäubt. Mit `laser` (Funkelstein): Strahl statt Ansturm. Schutz: schräg zu ihm stehen.
  - `turret` (Kreuzkrabbe hüpft, Riedwächter steht fest und wird nicht geschubst): schießt sein `pattern`.
  - `wall` (Wandspinne): klettert an den Wänden (`climb` m hoch), berührt nie, schießt Dreifach-Schuss.
  - `bouncer` (Knallkäfer): fliegt schräg, prallt ab, explodiert beim Tod (`death_blast`, trifft auch den Spieler).
  - `spawner` (Wespenbär): flieht, lässt Wespen frei (schwillt vorher an), platzt beim Tod in Wespen (`death_spawn`).
  - `shell` (Kristallbrocken): im Panzer unverwundbar (Treffer prallen ab), öffnet sich kurz, schießt, nur dann verwundbar.
  - Dazu: `revive` (Strohmann fällt erst um, liegend nochmal treffen), `death_spawn` (Teilschleim → 2 Schleimchen), `death_shots` (Distelkrähe), `burrow.shots` (Wühlmaus schießt beim Auftauchen), `pattern` für Schützen (Wilderer: Dreifach-Schuss), `tint` (ein Bild, mehrere Gegner).
- **Schussmuster** (`Enemy.shoot_pattern`): aimed, fan3, cross (+), diagonal (x), star, alternate (+ dann x), ring.
- **Laser** (`scenes/actors/enemy_beam.gd`, `EnemyBeam`, `Enemy.fire_beam`): erst dünne blinkende Warn-Linie (blinkt kurz vor dem Schuss schneller), dann dicker Strahl bis zur Wand; `sweep` dreht ihn, `track` lässt die Linie dem Spieler folgen (Bogen spannen), `fire` 0 = nur die Linie.
- **Bosse** (`BossBrain`): `keep_distance` (umkreist den Spieler auf Abstand), `stationary`, Trait `evade` (springt zur Seite, wenn ein Schuss kommt; nicht beim Spannen; Spieler-Schüsse in Gruppe `Projectile.GROUP`). Neue Angriffe: `aimed_shot` (Bogen spannen mit Ziel-Linie, dann schneller Pfeil, 1 Herz), `snares` (3 Fangeisen im Dreieck um den Spieler, Lücken dazwischen), `volley` (3 Pfeile, wütend 5), `laser`, `laser_sweep` (hinter dem Boss ist sicher), `cross` (+ dann x). Hängt der Spieler in einem Fangeisen, spannt der Wildhüter sofort (kurz) – Rüstung/Schild-Herzen fangen den Treffer ab.
- **Pfeile:** `EnemyShot.arrow` (Stab mit Spitze in 3D), `damage`.
- Tests: `test_meadow_play.gd` (Gras, jedes Muster einmal), `test_potions.gd` (Regeln, Vorführung im echten Laden, Trinken im echten Dungeon).

## Tauben auf Fallen, eigene Fallen, Vulkandrache – 2026-11-27

- **Tauben** (`floors.json` `hazard_types` `decor`: sprite `world_props/city_7_walk.png`, 6 Bilder, fps, height, count, return): `Hazard._build_decor` stellt sie auf sichtbare Fallen (nie auf `hidden`), sie picken; `Hazard.scare()` (von `Dungeon._check_hazards`, wenn der Spieler getroffen wird) lässt sie hoch und weg fliegen, nach `return` Sekunden landen sie wieder.
- **Eigene Fallen** (Logik fertig, noch kein Item): `hazard_types` mit `owner: "player"` (Krähenfüße `player_spikes`, Glutfleck `player_fire`, eigenes Fangeisen `player_snare`). `Hazard.from_player`, `touch_enemy` (Schaden `damage_mult` × Schuss-Schaden, je Gegner höchstens alle `every` s, Fangeisen betäubt `hold` s über `stun_left`; fliegende und eingegrabene Gegner nicht), `hurts_at` trifft nie den Spieler bei eigenen Fallen. Item-/Relikt-Feld `traps` [{kind, chance}] → `ShotStats.traps` (`RunState.compute_stats`) → `Projectile._end` → `Dungeon.shot_ended` würfelt und ruft `place_player_trap` (höchstens `PLAYER_TRAPS_MAX` 6 je Raum, die älteste geht, verschwindet nach `life`).
- **Große Gegner-Bilder:** `enemies.json` `frame` [Breite, Höhe] (Standard 48 × 48), `attack_sheets` {Angriff: Endung} → `Enemy.show_attack` / `end_attack` (von `BossBrain._start` / `_finish`).
- **Boss-Arena:** `enemies.json` `arena` {light, hazards} → `Dungeon._build_arena` nach der Boss-Wahl (eigener Zufall; `_place_hazards` wie bei normalen Räumen, Tür-Wege und Mitte frei).
- **Vulkandrache** (`volcano_dragon`): 128 × 96, 4,4 m, Leben 240, Feuer (spray/spiral/ring, Bild `breath`), Schwanzhieb (charge, Bild `tail`), ruft Lavahunde; Arena mit 4–5 Lava-Feldern und rotem Licht; fester Boss von `floors_vulkan` Ebene 6.
- Tests: `test_traps_play.gd` (Tauben, eigene Fallen, Schuss legt Falle, Höchstzahl), `test_new_dungeons_play.gd` (Drache, Arena), `test_dungeons.gd` (Daten eigener Fallen und Tauben).

## Boss-Halle mit dem Altar der Neun (BossHall) – 2026-11-27

- **Dateien:** `scenes/run/boss_hall.gd` (`BossHall`, erbt von `DungeonRoom`), `scenes/run/dungeon.gd` (Abschnitt „Boss hall“), Daten `data/boss_hall.json`, Musik `boss_rock` (`assets/audio/music/boss_rock_01.wav`, erzeugt von `assets/_reference/music/make_boss_rock.py`)
- Der Boss-Raum des Rasters ist jetzt eine **Vorhalle** ohne Kampf: in der Mitte steht ein offenes Tor (zur Eingangstür gedreht). Hineinlaufen → `Dungeon.enter_boss_hall`: die Halle wird beim ersten Mal gebaut, weit weg vom Raster (`HALL_CELL`, wie der Testraum), `size` Räume groß (2 × 2 = 29 × 21 m), dunkler (`ambient_dark`), düstere Musik (`music_altar`), das Tor hinter dem Spieler ist zu.
- In der Mitte der Altar (Smithy-Amboss), rundherum 9 Säulen auf einer Ellipse, Rillen im Boden vom Altar zu jeder Säule. Der Boss-Raum-Teil aus `enemies.json` `arena` (Licht, Lava) kommt in die Halle (`_build_arena(hall)`).
- **Szene** (näher als `wake_distance` an den Altar): Steuerung aus, HUD aus, schwarze Balken, Blick zum Altar → die 9 heiligen Kristalle fliegen von oben herein (eigenes Licht in ihrer Farbe) → kreisen immer schneller über dem Altar → blitzen auf und fallen schnell hinein → der Altar leuchtet → Energie fließt durch die Rillen (`beam_<element>.png`), jede Säule leuchtet auf (`pillar_<element>.png`, Element schwebt oben) → Stille (`silence`) → der Boss fällt von oben (`boss_drop`) mit Schatten → Landung: Schlag, `Dungeon.start_boss_fight`, Rock-Musik (`music_fight`), HUD zurück, der Lebensbalken füllt sich (`BossHall.WAKE_TIME`), so lange steht der Boss still → Kampf.
- Wartezeiten laufen über `create_timer(t, false)` (Pause hält die Szene an); `skip_intro()` springt ans Ende (Admin-Menü, Tests).
- Nach dem Boss: Halle hell, Tor offen (`exit_open`), Falltür, Boss-Item und Herz zwischen Altar und Tor (`_boss_rewards(room, base)`). Durchs Tor zurück in die Vorhalle (dort ggf. der Sonderraum).
- Raum-Grenzen laufen jetzt über `Dungeon.room_rect` / `rect_of` / `room_size` (Gegner, Spieler, Fallen, Beute, Karte), weil die Halle größer ist als ein Raum.

## Admin-Menü (AdminMenu, nur im Editor) – 2026-11-27

- **Dateien:** `scenes/ui/menus/admin_menu.gd` (im Code gebaut), `scenes/run/run.gd`, `Game.travel`, `MetaState.give_piece`
- **P** (nur `OS.is_debug_build()`) öffnet es statt des Testraums; das Spiel hält an, P/Esc schließt.
- **Reise:** Dungeon + Ebene wählen → „Hinreisen“ (gleicher Run, Ebene neu gebaut); Knöpfe Boss-Halle, Boss-Szene überspringen, Räderkluft, Räume dieser Ebene (Start, Boss, Item, Shop, Geheim, Opfer, Sonderraum), Testraum (alle Items auf Sockeln, wie vorher).
- **Items:** alle Items mit Suche, Doppelklick gibt eins, „Alle Items ablegen“.
- **Ausrüstung:** Ausrüstung (mit Seltenheit), Relikte, Tränke – Doppelklick legt an (bleibt im Spielstand, der Run nutzt es sofort); angelegte Teile anklicken = ablegen (ins Inventar zu Hause).
- **Cheats:** Leben voll, Unverwundbar, Raum leeren, +5 Bomben/Schlüssel, +1000 Gold in die Dose, +1 Spielerstufe, Dungeon als geschafft markieren.
- Texte nur deutsch (Entwickler-Werkzeug, absichtlich ohne Übersetzung).

## Fliegen (Flags fly, ghost) – 2026-11-28

- **Dateien:** `scenes/actors/player.gd` (`flying`, `_update_flight`), `scenes/run/dungeon.gd` (`_check_hazards`), `scenes/run/gear_chasm.gd` (`tick`), `data/items.json`, `data/player.json` `fly_height`/`fly_bob`
- `fly` oder `ghost`: Fallen am Boden (Gift, Stacheln, Lava, Fangeisen) wirken nicht auf den Spieler, in der Räderkluft fällt er nicht, die Sicht schwebt `fly_height` höher und leicht auf und ab. `ghost` nimmt zusätzlich die Stein-Ebene aus der Kollision des Spielers (geht durch Steine). Schüsse treffen den Flieger wie vorher.

## Räderkluft (GearChasm) – 2026-11-28

- **Dateien:** `scenes/run/gear_chasm.gd`, `data/gear_chasm.json`, `scenes/run/dungeon.gd` (`CHASM_CELL`, `chasm`, `enter_gear_chasm`, `in_gear_chasm`), Admin-Menü Knopf „Räderkluft“, Test `test_gear_chasm_play.gd`
- Boss-Halle über einem Abgrund, weit weg vom Ebenen-Raster (wie der Boss-Altar). Boden nur auf Plattformen: feste Mitte (Boss-Podest = Hindernis), vier feste Tür-Plattformen an den Wänden (Ankunft: Süden), innerer Ring 4 Plattformen gegen den Uhrzeigersinn, äußerer Ring 4 Plattformen im Uhrzeigersinn. Die Schienen sind Rechtecke (`GearChasm.path_point`), beide Ringe brauchen `period` Sekunden je Runde → alle `period`/4 Sekunden ist von jeder Tür ein Weg bis zur Mitte offen (Tür, außen, innen, Mitte). Der erste Weg öffnet `wait_at_start` Sekunden nach dem Betreten.
- Der Spieler hat keine Schwerkraft; `GearChasm.tick` (aus `Dungeon._physics_process`) prüft, ob unter ihm eine Plattform ist (bis `reach` über den Rand), verschiebt ihn mit der Plattform und lässt ihn sonst fallen: Steuerung aus, nach unten, `fall_damage` halbe Herzen, zurück an die letzte Stelle auf festem Boden. `on_leave` bricht einen Fall ab (Admin-Teleport, Testraum).
- **Endboss-Halle:** `dungeons.json` `end_room: "gear_chasm"` (Moor) → das Portal der letzten Ebene führt hierher statt zum Boss-Altar. Der Endboss erscheint auf dem Podest, `Enemy.pinned` (läuft nicht, `tick` hält ihn fest). Das Podest blockt nur den Spieler (Ebene 16, `DAIS_LAYER`), Schüsse gehen durch. Helfer fahren mit ihrer Plattform mit und können nur dort hinüber, wo Plattformen sich berühren. Danach: Podest frei, goldenes Licht, Boss-Item und Herz auf der Mitte, Quest-Stein wie im Boss-Altar (`Dungeon.in_end_hall`).
- Bomben und Blinzeln bleiben nur im Hallen-Rechteck.

## Egons Rubin-Auftrag, Seil und Portal (Rope, Portal, BossAltar) – 2026-11-27

- **Dateien:** `scenes/objects/rope.gd`, `scenes/objects/portal.gd`, `scenes/run/boss_altar.gd`, `scenes/run/dungeon.gd`, `scenes/run/run.gd`, `MetaState.rope_due/ruby_due/deliver_ruby`, `data/meta.json` `ruby_quest`, `data/achievements.json`
- Erster Boss (Spielstand neu, Ebene `ruby_quest.floor`): lässt sicher den Rubin fallen. **Nur wenn der Boss im Boss-Raum besiegt wurde** (`Dungeon._boss_beaten`), fällt zusätzlich ein Seil vom Himmel (`ROPE_SPOT`, neben der Mitte). Falltür nach unten und Boss-Item kommen wie immer.
- Am Seil: hinaufklettern, Tag zu Ende, alles kommt mit, Erfolg `first_boss`, End-Bildschirm „Hinausgeklettert!“. Danach nie mehr ein Seil (`rope_done`).
- Egon nimmt den Rubin im Laden (`ruby_due`: nach dem Seil oder sobald ein Rubin im Inventar ist), einmal.
- Letzte Ebene: nach dem Boss steigt ein Portal statt der Falltür auf → Boss-Altar mit dem End-Boss (`dungeons.json` `end_boss`) → goldenes Licht (Sieg).

## Händler im Dungeon mit F (Handelsfenster) – 2026-11-27

- **Dateien:** `scenes/run/dungeon.gd` (`keeper`, `near_merchant`, `trading`, `merchant_relic`, `buy_relic`), `scenes/ui/hud/bag_window.gd` (`open(trade)`), `scenes/ui/hud/hud.gd` (`talk_prompt`), `scripts/core/controls.gd` (`TALK` = F, änderbar), `data/floors.json` `shop`
- Steht man im Shop-Raum näher als `talk_distance` am Händler, zeigt das HUD „[F] Mit dem Händler handeln“. F öffnet das Inventar als Handelsfenster: nur dort kauft er Beute (Rechtsklick). Tab im Shop-Raum verkauft nichts mehr.
- Oben im Handelsfenster bietet er ein **Relikt** an (ein schon gefundenes Item, `ShopGoods.pick_relic`, Preis = Stufen-Preis × `relic_price_mult` × Shop-Faktor), bezahlt mit dem Gold aus der Tasche. Gekauft liegt es sofort zu Hause im Inventar (`MetaState.give_piece`) und bleibt auch beim Tod.
- Übersetzungs-Skript liest jetzt auch `message.emit("…")` und `show_message("…")`.

## Relikt-Skills, blaues Herz – 2026-11-27

- `data/skills.json`: **Zähigkeit** (Schild-/Eisenherzen) entfernt; an ihrer Stelle **Blaues Herz** (eine Stufe, Effekt `blue_hearts`: ein blaues Herz zu Beginn jedes Runs, `RunState.use_skills`).
- **Reliktschutz** (4 Stufen, Effekt `relic_keep_tier`): Relikte bis zu dieser Stufe gehen nie kaputt (`ShopGoods.relic_forever`, geprüft in `MetaState._wear_relic`, auch für schon gekaufte Relikte). Dafür hält Stufe 1 jetzt 5 Dungeons (`relics.json`).

## Skill-Baum: jede Stufe ein eigenes Feld – 2026-11-27

- `scenes/shop/skill_tree.gd`: Jede Stufe eines Skills ist ein eigener Knopf (`Skill_<id>_<stufe>`), Stufe 1 an `pos`, die weiteren direkt darunter. Eine Stufe geht erst auf, wenn die darüber gelernt ist (`SkillTree.level_problem`: „Erst die Stufe davor lernen“). Unter jedem Feld der Preis dieser Stufe (`G` Gold, `P` Skillpunkte) oder ✓. Ketten (`requires`) laufen seitlich (L-Linie von Stufe 1 zu Stufe 1).
- `Skills.gold_at / points_at / min_level_at` = Kosten einer bestimmten Stufe.

## Skill-Baum in zwei Seiten, langsameres Leveln – 2026-11-27

- **Links** (Spalten < 0, wachsen nach links): Skills, die nur Skillpunkte kosten (Kampf, Überleben mit Blaues Herz → Dicke Haut). **Rechts** (Spalten > 0, wachsen nach rechts): Skills, die nur Gold kosten (Rucksack, Relikte, Laden; Goldnase hängt an Reliktpflege). Trennstrich in Spalte 0, große Seiten-Überschriften (`groups` mit `big`).
- `data/levels.json` `exp_table` [64, 90] + `base_exp` 30: Anfang langsamer, ab etwa Stufe 5 dieselbe Kurve wie vorher.

## Maus-Empfindlichkeit wie CS2 – 2026-11-27

- `Game.get_mouse_sensitivity` / `set_mouse_sensitivity` (0,01–20, Standard 2,5, gespeichert als `controls/mouse_sensitivity_cs2`), `Game.look_radians_per_count` = Empfindlichkeit × 0,022° (CS2 `m_yaw`/`m_pitch`) je Zählschritt der Maus, links/rechts und hoch/runter gleich (`Player.look`, mit `screen_relative`, also ohne Skalierung des Fensters).
- Einstellungen → Steuerung: Schieber (0,1–10) und rechts ein Zahlenfeld (auch mit Komma). Gleiche Zahl wie in CS2 = gleicher Weg pro Zentimeter (gleiche Maus-DPI vorausgesetzt; Windows-Mausbeschleunigung „Zeigerbeschleunigung verbessern“ sollte aus sein).

## Fadenkreuz wie CS2 (Crosshair) – 2026-11-27

- `scenes/ui/hud/crosshair.gd` (`class_name Crosshair`): Stil (Kreuz / nur Punkt / aus), Farbe (die fünf CS2-Farben oder eigene), Deckkraft 0–255, Länge, Dicke, Abstand (auch negativ), Punkt in der Mitte, Umriss + Dicke, T-Form. Größen in Pixeln bei 1080p. Gespeichert in `user://settings.cfg` Abschnitt `crosshair`; `Crosshair.set_value` sendet `Game.crosshair_changed`, HUD und Vorschau zeichnen neu.
- Einstellungen: neuer Reiter „Fadenkreuz“ mit Vorschau und „Standard wiederherstellen“ (= das alte Aussehen).

## Blickrichtung der Gegner – 2026-11-27

- Unter jedem Gegner liegt neben dem Ring ein gefülltes Viertel (`Fx.facing_wedge`, 90°-Keil, Farbe `Enemy.WEDGE_COLOR`), gedreht nach `Enemy.look_direction()`: wohin er läuft (dreht mit `LOOK_TURN_SPEED`), im Stand zum Spieler; Schildträger (`front_guard`, `guard`) zeigen ihre Schild-Seite (`_facing`). Unsichtbar mit dem Ring (unter der Erde, an der Wand).

## 3D-Ton der Gegner – 2026-11-27

- Vorher war kein Ton räumlich (alles `AudioStreamPlayer`, mittig). Jetzt: `AudioManager.play_sound_at(id, ort, parent)` / `play_stream_at(...)` legen einen kurzlebigen `AudioStreamPlayer3D` an den Ort (in `Dungeon.effects`), gehört von der Kamera der SubViewport (`audio_listener_enable_3d`). `data/audio.json` `spatial`: `unit_size`, `max_distance`, `panning_strength`, `voices` (höchstens so viele gleichzeitig, der älteste hört auf).
- Alle Gegner-Töne laufen über `Enemy.sound(id, pitch)` (Treffer, Tod, Rufe, Schüsse, Ansturm, Graben, Laser, Explosion, Boss-Töne) und kommen aus ihrer Richtung; die manuelle Abschwächung der Rufe (`CRY_FALLOFF_DB`) ist weg. Musik und Spieler-/Menü-Töne bleiben ohne Richtung.

## Dungeon-Brett nur offene Dungeons, Gegner im Lexikon – 2026-11-27

- `DungeonBoard`: nur Dungeons mit `MetaState.is_dungeon_open` (`open_dungeons()`), dazu der Hinweis, dass der Sieg den nächsten öffnet. Rechts unter der Beschreibung die Gegner des Dungeons (`Content.dungeon_enemies`: Gegner, Start-Gegner und Bosse aller Ebenen, End-Boss) als kleine Bilder (`Content.enemy_icon`: erstes Bild des Sheets), unbekannte als schwarze Silhouette.
- `Progress.meet_enemy / has_met / met_enemies` (`user://progress.cfg` `enemies`): beim ersten Kill eines Gegners (`Dungeon._on_enemy_died`).
- `LexiconWindow`: Reiter „Items“ (wie vorher) und „Gegner“ (nach Smithy): Gegner nach Dungeon gruppiert, besiegte mit Bild, Leben, Schaden, Tempo, Boss, Beute (`loot.json` mit Chance) und Fundort; sonst Silhouette und „???“.

## Mehr Rückmeldung in der Oberfläche („Juice“) – 2026-11-27

- **Schadenszahlen** (`Fx.damage_number`, über `Dungeon.on_enemy_damaged` aus `Enemy.take_damage`): Zahl ploppt über dem Gegner auf, steigt und verblasst; starker Treffer (≥ 1,6 × eigener Schaden) groß und gold, Kill orange-rot. Immer lesbar (`no_depth_test`, feste Größe).
- **Treffer-Marker** am Fadenkreuz (`Crosshair.show_hit`, Signal `Dungeon.enemy_damaged`): kurzes weißes X, rot beim Kill.
- **Konfetti** beim Tod eines Gegners (`Fx.confetti`, Boss mehr).
- **Beute-Popups** rechts im HUD: „+2 Rattenfell“ in der Seltenheitsfarbe (`RunState.loot_picked`, aus `Pickup`).
- **Wenig Leben** (≤ 1 Herz): roter Rand pulsiert wie ein Herzschlag, die Herzen schlagen mit (`Hud._refresh_low_life`).
- **Knöpfe** (`scripts/core/ui_juice.gd`, von `Game` an jeden neuen Knopf gehängt): wachsen unter der Maus, federn beim Drücken.
- **End-Bildschirm:** EXP-Balken füllt sich animiert; jede neue Stufe: „Stufe X!“ springt auf, Konfetti, Ton.

## Deko in den Räumen – 2026-11-28 (`feature/deko`)

- `RoomProps.add_props` (`scenes/run/room_props.gd`), aufgerufen von `Dungeon` direkt nach `RoomBuilder.build_shell`: legt im Raum einen Knoten `Props` an und stellt 2–5 aufrechte Bilder (Billboard, dreht sich nur um die Hochachse, schattiert wie Steine) an die Wände. Nur Aussehen: keine Kollision, nicht auf der Karte, nicht aufhebbar.
- Daten: Thema `props` in `data/floors.json` = [[Bild, Gewicht, Höhe in Metern], …]; oben `props` = `count` [min, max], `min_gap` (Abstand untereinander), `inset` [min, max] (Abstand zur Wand). Türöffnungen bleiben ±1,9 m frei.
- Eigener Zufall je Raum (`hash([Ebene, Zelle, "props"])`), damit Gegner, Steine und Beute denselben Zufall behalten wie vorher. Test: `test_room_props_play`.

## Stimmung im Dungeon – 2026-11-28 (`feature/stimmung`)

- **Treffer-Blitz:** Gegner-Bilder haben ein eigenes Material (`scenes/actors/enemy_sprite.gdshader`: wie ein Sprite3D, Billboard um Y, Alpha-Schnitt, plus `flash`). Ein Treffer macht den Gegner `Enemy.HIT_WHITE` (0,05 s) ganz weiß, danach die rote Tönung wie vorher (`_flash`). Das Bild setzt `Enemy._set_sheet` auch im Material (`sprite_texture`), sonst bleibt es leer.
- **Fackeln flackern:** `scenes/objects/torch.gd` bekommt von `RoomBuilder._torch` ihr Licht (`light`) und lässt dessen Stärke um ±18 % schwanken (zwei Wellen + langsamer Zufall).
- **Lichthof** (`Fx.halo`): weicher, gestufter Lichtfleck (32×32, additiv, zur Kamera gedreht, ohne Nebel) um Feuerbälle (`Projectile`), Gegner-Kugeln (`EnemyShot`) und Fackeln. Ersetzt Glow: Der Glow des WorldEnvironment ist in GL Compatibility bei ungeschatteten Bildern fast unsichtbar (siehe `docs/ENTSCHEIDUNGEN.md`).

## Raster-Inventar, Rucksäcke, Tutorial im ersten Run – 2026-11-27, `feature/raster-inventar`

- **Dateien:** `scripts/systems/bag.gd` (`Bag`, Raster), `scripts/systems/bag_layout.gd` (`BagLayout`: Formen, Item-Größen, Rucksack-Regeln), `scenes/ui/hud/bag_board.gd` (`BagBoard`: ein Raster auf dem Bildschirm, Drag & Drop, Drehen), `scenes/ui/hud/bag_window.gd` (kompakter), `scenes/shop/backpack_board.gd` + `backpack_window.gd` (Rucksäcke anbauen bei Egon), `scenes/run/dungeon_guide.gd` (`DungeonGuide`), Daten `data/meta.json` „bag“, `data/loot.json` „size“, `data/backpacks.json`, `data/skills.json` Gruppe Rucksack.
- **Inventar als Raster** (wie ein Rucksack-Spiel): 8 × 3 Felder (`meta.json` `bag.columns/rows`). Jede Beute braucht `loot.json` `size` Felder (Fell 2×2, Morscher Zauberstab 4×1, Rubin/Smaragd/Saphir/Diamant 3×3, Erz 1×1 …; fehlt = `default_size`). Ein Platz ist `{id, count, x, y, rot}`. Aufheben legt Beute auf das erste freie Feld (Reihe für Reihe, sonst gedreht); passt sie nirgends: „Inventar voll!“.
- **Sicherer Platz:** eigenes kleines Raster 2×2 (`bag.safe`), liegt im Modell weit rechts (`Bag.SAFE_ORIGIN`), damit nichts über beide reicht. Skill Geheimtasche: je Stufe eine Spalte mehr (`Bag.grow_safe`).
- **Fenster (Tab):** in der Mitte das Raster (Felder von Rucksäcken in deren Farbe), darunter der sichere Platz (golden) mit Info; links klein die Figur (60 %) und die Werte, rechts die Karte (132×150), unten die Items. Ziehen = verschieben (grün passt, gelb tauscht, rot geht nicht; gleiche Dinge stapeln, `Bag.move_to`), **R oder Rechtsklick beim Ziehen = drehen** (`BagBoard.rotate_drag`), aus dem Fenster ziehen = fallen lassen, Rechtsklick im Handelsfenster = verkaufen.
- **Rucksäcke** (`data/backpacks.json`): Kräutertasche 2×2, Kupfer 3×3, Eisen 4×2, Silber 4×3, Karawane 5×3. Man bekommt sie im Skillbaum (Gold-Seite, Gruppe Rucksack, Kette; Skill-Effekt `backpack`). Ein neuer Rucksack wird sofort irgendwo angebaut (`BagLayout.first_spot`). Bei Egon Knopf „Rucksäcke (n)“ (links von Skills, n = nicht angebaute): Raster mit Inventar und Rucksäcken, Rucksack ziehen/drehen, auf die Liste ziehen = abnehmen. Regeln (`BagLayout.is_valid`): im Bereich `bag.board`, nichts überdecken, über Kanten mit dem Inventar verbunden (auch über andere Rucksäcke). Gespeichert in `MetaState` „backpacks“ (`place_backpack`, `remove_backpack`, `loose_backpacks`); im Run `Bag.add_backpacks` (`RunState.use_skills`).
- **Tutorial im ersten Run** (`DungeonGuide`, nur wenn `MetaState.guide_done` noch false ist; `Game.start_new_run` setzt `RunState.guided`, nur Ebene 1): Startraum ohne Schrift, Türen zu. Schritte mit grüner Zeile oben im HUD (`Hud.show_guide`): W A S D laufen → mit der Maus umsehen → Linksklick schießen → die Tür zum Übungsraum öffnet sich (`Dungeon.open_guide_door`) → hinein → Übungsratte (`enemies.json` `tutorial_rat`, `damage` 0 = tut nichts, lässt sicher ein Rattenfell fallen) abschießen → Fell aufheben → Tab → Fell in den sicheren Platz ziehen (Zeile auch im Inventar, sicherer Platz pulsiert) → „Gut gemacht!“, `MetaState.finish_guide`, alle Türen offen (`Dungeon.end_guide`).

## Laden als Raster: Lager, Tisch, Reiter Ausrüstung/Inventar – 2026-11-27, `feature/laden-raster`

- **Dateien:** `scripts/systems/item_grid.gd` (`ItemGrid`: Raster-Regeln für Lager und Tisch), `scenes/shop/item_board.gd` (`ItemBoard`: Raster auf dem Bildschirm, Drag & Drop, Drehen, Preise, Leuchten), `scenes/shop/shop.gd` (neues Layout), `scenes/shop/backpack_board.gd` (Reiter Inventar), `MetaState` (Lager, Rucksäcke), `ShopGoods` (`piece_size`, Rucksäcke auf dem Tisch). Das Rucksack-Fenster (`backpack_window.gd`) ist weg.
- **Aufbau** (Skizze des Entwicklers): oben Egons Tisch als Raster 8×4 (`shop.json` `table_grid`; Ware liegt der Reihe nach auf den ersten freien Feldern, `MerchantShop.table_layout`, Preis unten rechts), links zwei Reiter **Ausrüstung** (Figur) und **Inventar** (Inventar des nächsten Runs mit angebauten Rucksäcken und dem sicheren Platz), unten das **Lager** 5 breit × 4 hoch (`meta.json` `stash`), daneben „Kein Platz“ für alles, was nicht hineinpasst. Knöpfe (Hauptmenü, Skills, Dungeons) unten am Rand.
- **Größen** (`ShopGoods.piece_size`): Beute nach `loot.json` `size`, Ausrüstung nach ihrem Platz (`gear.json` slots `size`: Handschuhe 1×1, sonst 2×2), Relikte und Tränke 1×1, Rucksäcke ihre Größe.
- **Lager** (`MetaState.stash`): jedes Teil `{id, count, x, y, rot}`, Beute liegt einzeln (alte Stapel werden geteilt). Jede Änderung wird „gesetzt“ (`ItemGrid.settle`): Teile ohne Platz bekommen das erste freie Feld oder liegen unter „Kein Platz“ (kein `x`). Ziehen = verschieben (`move_in_stash`, auch tauschen), R/Rechtsklick beim Ziehen = drehen, Rechtsklick = auf den Ankauf-Platz, Klick = anlegen (Ausrüstung) bzw. anbauen (Rucksack).
- **Rucksäcke als Gegenstände:** Skill lernen legt den Rucksack ins Lager; auf Egons Tisch kommen sie auch (`shop.json` `backpack_chance`, `backpacks.json` `price`, `unlock`). Aus dem Lager auf den Reiter Inventar ziehen = anbauen (`MetaState.attach_backpack`), angebaut verschieben (`place_backpack`), zurück ins Lager ziehen = abnehmen (`detach_backpack`). Jeder Rucksack nur einmal angebaut.

## Drag & Drop im Laden, Egons Quests, Skillbaum zur Seite – 2026-11-27, `feature/laden-raster`

- **Drag & Drop** (`MerchantShop`): Tisch → Lager = kaufen (genau auf das Feld, `MetaState.buy(index, false, cell, rot)`), Lager → Tisch = verkaufen (`MetaState.sell`), Lager → Platz an der Figur = anlegen (`MetaState.equip(index, slot)`, auch Tränke und Relikte), Figur → Lager = ablegen (`unequip(slot, cell, rot)`). Beim Ziehen ist das Bild unter der Maus; darunter grün (geht) oder rot (geht nicht): Raster (`ItemBoard`) und einzelne Plätze (`ShopSlot.set_drop_hint`). Der Ankauf-Platz ist weg.
- **Quests** (`data/quests.json`, `scripts/systems/quests.gd`, `scenes/shop/quest_window.gd`): eine Kette Glut → Moor → Wiese → Frostgipfel → Glutschlund. Offen ist eine Quest, solange ihr Dungeon offen und sie nicht erledigt ist; dann lässt der Endboss im Boss-Altar ihren Stein fallen (`Quests.drop_for`, nur wenn der Spieler ihn nicht schon im Lager oder in der Tasche hat; nach der Abgabe nie wieder). Steine (`loot.json` `quest: true`) sind unverkäuflich (Egon und der Händler im Dungeon).
- **Abgeben:** Stein auf den **Quest-Platz** oben rechts ziehen (statt Ankauf) oder im Quest-Fenster (Knopf **Quests** unten, „Quests !“ wenn ein Stein bereitliegt) „Abgeben“. `MetaState.deliver_quest`: Quest erledigt, Dungeons mit `unlock` `{"quest": id}` öffnen sich, Egon zieht um (`MetaState.location`, `quests.json` `locations`: anderer Hintergrund im Laden, Ortsname neben dem Gold), Gold in die Dose. Egon sagt `story.json` `quest_<id>_intro` einmal, wenn die Quest neu ist, und `quest_<id>_done` bei der Abgabe.
- **Dungeons öffnen nur noch über Quests** (`dungeons.json` `unlock` `quest`); Siege zählen weiter für Materialien bei Egon. Egons alter erster Auftrag (Rubin vom ersten Boss, Seil) bleibt zusätzlich.
- **Skillbaum:** Stufen eines Skills stehen nebeneinander in einer Zeile (links nach links, rechts nach rechts, `SkillTree._level_cell`); Skills einer Kette stehen in Zeilen darunter, die Linie läuft am inneren Rand.

## Das Inventar bleibt zwischen den Runs – 2026-11-27, `feature/inventar-bleibt`

- Was man aus dem Dungeon mitbringt, bleibt im **Inventar** (`MetaState` „bag“, `bag_places`) auf seinen Feldern, auch im sicheren Platz. Der nächste Run startet damit (`Game.start_new_run` → `Bag.restore`). Ins Lager kommt nur, was im Inventar keinen Platz hat, und Egons Auftrags-Rubin (er nimmt ihn aus dem Lager).
- Im Laden, Reiter **Inventar**: das Raster mit Rucksäcken und Beute (`BackpackBoard`), darunter der sichere Platz (`ItemBoard`). Beute ziehen: im Inventar verschieben (`move_in_bag`), ins Lager (`bag_to_stash`), aus dem Lager zurück (nur Beute, `stash_to_bag`), auf den Tisch = verkaufen (`sell_from_bag`), Quest-Stein auf den Quest-Platz (`deliver_quest_from_bag`). Ein Rucksack mit Beute darin lässt sich nicht verschieben oder abnehmen (`backpack_in_use`).
- Die linke Spalte im Laden ist breiter (Felder des Inventars ~15 px statt 9); Tisch, Lager, Hebel und Quest-Platz sind nach rechts gerückt (`MerchantShop.MIDDLE_X`), der Tisch hat 20-px-Felder.

## Admin-Menü im Laden – 2026-11-27, `feature/admin-laden`

- **P** in Egons Laden (nur `OS.is_debug_build()`, also aus dem Editor) öffnet `ShopAdminMenu` (`scenes/shop/shop_admin_menu.gd`); P oder Esc schließt. Texte nur Deutsch, nicht übersetzt (wie `AdminMenu`).
- **Geben:** Ausrüstung (mit Seltenheit), Relikte, Tränke, Rucksäcke und Beute ins Lager, „Geben + anlegen“, Lager leeren. **Laden:** Gold in die Dose (+100/+1000/+10000), Dose leeren, neue Ware gratis, Tisch leeren, Hebel wieder gratis, neuer Tag. **Fortschritt:** +1 Stufe, +5 Skillpunkte, Dungeon (oder alle) geschafft, Quest ohne Stein erledigen (Egon zieht um), Tour überspringen, Rubin abgegeben, Tränke frei, Trank-Vorführung zeigen, Laden neu öffnen.
- Die Regeln dafür stehen in `MetaState` (`admin_*`); danach zeigt der Laden alles neu (`MerchantShop.refresh_all`).

## Münzen von Gegnern – 2026-11-27, `feature/admin-laden`

- Gegner lassen **Münzen** fallen (`data/loot.json` `coins`): normale Gegner mit `chance` (Glück hilft) `amount` Münzen, Bosse immer `boss_amount`, je tiefere Ebene `per_floor` mehr (`Dungeon._drop_coins`). Sie liegen als ein Häufchen Beute `gold` am Boden.
- Aufheben legt sie ins Inventar (`RunState.add_coins`); eine Münze ist ein Stück Beute „Münze“ (Bild `sprites/ui/slot/coin.png`), **bis 999 auf einem Feld** (`loot.json` `gold.stack`), mehr kommt aufs nächste Feld. Nach dem Run kommen sie in die Dose, beim Tod sind sie weg (außer im sicheren Platz) – wie vorher das Gold vom Händler im Dungeon.

## Ausrüstung im Inventar, Rucksack-Grenze – 2026-11-27, `feature/ausruestung-im-inventar`

- **Ausrüstung, Relikte und Tränke** lassen sich im Laden aus dem Lager ins Inventar ziehen (auch in den sicheren Platz) und kommen mit in den Dungeon. Ein Platz im `Bag` ist dann ein Teil mit eigenen Feldern (`rarity` / `relic`, `left` / `potion`), Anzahl 1, Größe nach `ShopGoods.piece_size` (`Bag.is_piece`, `size_of`, `put_place`, `add_piece`, `fits_piece`). Im Dungeon: verschieben ja, fallen lassen nein (es gibt kein Bodenbild dafür), der Händler kauft sie nicht. Beim Tod weg, außer im sicheren Platz; nach einem guten Run wieder im Inventar zu Hause. Ins Lager zurück mit Seltenheit.
- **Rucksack-Grenze:** `meta.json` `bag.backpack_slots` (1) + Skill **Rucksack-Riemen** (`effect.backpack_slots`, 4 Stufen) = `MetaState.backpack_limit`. Anbauen über der Grenze geht nicht (rot). Über dem Inventar im Laden steht „Rucksäcke 1/2“.
- **Skillbaum:** die Rucksack-Kette steht nebeneinander (links nach rechts); Ketten in derselben Zeile bekommen eine gerade Linie von der letzten Stufe (`SkillTree.build`). Gruppen Relikte und Laden nach rechts gerückt.
- **Ziehen:** das Bild unter der Maus nimmt die Feldgröße des Rasters an, über dem es gerade ist (`BagBoard.fit_preview`, `DragPreview.use_cell`).
- **Tab-Fenster im Dungeon:** feste Größe (`BagWindow.PANEL_SIZE` 300×292), Beschreibung mit fester Fläche (200 px breit, 7 Zeilen); das Fenster springt beim Überfahren nicht mehr.

## Bauarten der Ausrüstung – 2026-11-27, `feature/bauarten`

- Jedes Teil auf Egons Tisch bekommt eine **Bauart** seines Platzes (`gear.json` `types`, `ShopGoods.pick_type`); das Teil merkt sie sich als `type` (Tisch, Lager, Inventar, Figur). Normal = ohne Feld.
- Werte: `ShopGoods.stats(id, rarity, type)` = eigene Werte × `mult` der Bauart × Seltenheit, dazu `stats` der Bauart (Vor-/Nachteile, wachsen nicht). `RunState.use_gear` nimmt sie; Schild-Herzen nie unter 0.
- Bauarten: Waffe Schwer (+60 % Schaden, langsamer) / Leicht (−40 % Schaden, schneller) / Weitreichend (+Reichweite, −20 % Schaden); Kopf Visier (mehr Schild, −Glück) / Kapuze (weniger Schild, +Glück); Brust Platte (mehr Schild, −Tempo) / Leder (weniger Schild, +Tempo) / Robe (kein Schild, schneller schießen); Hände Kampfhand (mehr Schaden, −Tempo) / Diebeshand / Flinke Hand; Beine Schwer / Leicht; Füße Sprint (viel Tempo, −½ Schild-Herz) / Eisenschuh (kein Tempo, +½ Schild-Herz) / Glücksschuh.
- Beschreibung: „Eisen-Brustplatte (Platte)“, darunter jeder Wert mit + oder − (`ShopSlot.stat_line`; schneller schießen als „Angriffstempo +18 %“). Admin-Menü im Laden: „Bauart würfeln“.

## Weniger Beute, Egons Dankeschön – 2026-11-28, `feature/weniger-beute`

- **Beute-Budget je Raum** (`data/loot.json` `room_budget`): `drops` (1) Dinge gibt ein Raum höchstens her, Glück gibt `luck_extra` je Punkt mehr (abgerundet). Normale Gegner lassen je höchstens eins fallen (`Dungeon._drop_from_normal`): erst Beute (dann nur 1 Stück), sonst Münzen, sonst Herz/Bombe (`enemies.json` `drop_chance`). Die Raum-Belohnung beim Leeren (`floors.json` `room_drops`) zählt mit. Ist das Budget weg (`DungeonRoom.drops_left`, `Dungeon.room_drops_left`), fällt nichts mehr. Bosse (Beute + Münzen wie bisher), Schlüssel und Quest-Steine zählen nicht. Münz-Chance 0,6 → 0,25.
- **Dankeschön für den Rubin:** `MetaState.deliver_ruby` legt `ruby_reward()` ins Lager (`meta.json` `ruby_quest` `reward_relic` = Moorherz, `reward_runs` = 4 Runs). Im Laden leuchtet es auf, Egon sagt `story.json` `ruby_reward`.

## Behälter im Lager, Tausch bei Egon – 2026-11-28, `feature/behaelter-tausch`

- **Behälter** (`data/containers.json`, Regeln in `ShopGoods` und `MetaState`): ein Teil im Lager `{id, container: true, uid, items}` mit Größe `size`. Arten (`kind`): `relic`, `gear` (Rüstung ohne Waffen), `weapon`, `loot` (Beute ohne Münzen und Quest-Steine; `ShopGoods.kind_of`). Jedes Teil braucht einen Platz (`slots`), gleiche Beute stapelt bis `stack`. Klein: Reliktdose 3, Rüstungsständer 4, Waffenständer 3, Materialbeutel 4 (×10); groß: Reliktruhe 8, Rüstungskiste 8, Waffenschrank 6, Materialfass 8 (×25).
- `MetaState.container_put(uid, index)` / `container_take(uid, slot, cell, rot)` (Beute einzeln heraus), `container_fits`, `container_items`, `container_index(uid)`. Die `uid` vergibt `_owned` (Zähler `next_uid`), damit der Laden ein offenes Fenster wiederfindet, auch wenn sich die Lager-Reihenfolge ändert.
- Behälter gehen nicht ins Inventar/in den Dungeon (`Bag.is_known` kennt sie nicht), lassen sich nur leer verkaufen (`sell_price` 0 und `MetaState.sell` lehnt ab), Egon legt sie manchmal auf den Tisch (`shop.json` `container_chance`, `unlock`).
- **Im Laden:** Klick auf einen Behälter öffnet `ContainerWindow` (über dem Lager, 4 Plätze je Reihe, X schließt). Teil auf einen Platz ziehen = hinein; Platz ins Lager ziehen = heraus; ein Teil im Lager direkt auf den Behälter ziehen = hinein (`MerchantShop._container_under`).
- **Tausch** (`data/trades.json`, `Trades`, `MetaState.trade`): dritter Reiter „Tausch“ links (`TradePanel`). Jedes Angebot: `give` {Beute: Anzahl} → `get` (Behälter, Rucksack, Trank oder Relikt mit `runs`), `unlock` wie bei Dungeons; gesperrte stehen grau mit Grund da. Gezählt wird alles zu Hause (`MetaState.home_count`: Lager, Kein Platz, Inventar, Behälter), genommen zuerst aus „Kein Platz“, dann Lager, Inventar, Behälter. Das neue Teil leuchtet im Lager kurz auf, Egon sagt `barks.traded`.
- Admin-Menü (P): Behälter geben.

## Bomben und Schlüssel im Inventar – 2026-11-28, `feature/bomben-schluessel`

- **Bomben und Schlüssel sind Beute** (`data/loot.json`): `bomb` (stapelt bis 5 auf einem Feld), `key` (zerbrechlicher Schlüssel, `key: true`, `fragile: true`, stapelt nicht), `iron_key` (Eisenschlüssel, `key: true`, stapelt nicht, hält ewig). Sie liegen im Raster-Inventar wie alles andere: verschieben, in den sicheren Platz legen, fallen lassen; am Boden liegen sie als Beute (`Dungeon._drop` macht aus „bomb“/„key“ Beute).
- `RunState.bombs` / `keys` zählen nur, was im Inventar liegt (wie die Münzen). `add_bombs` / `add_keys` legen hinein, was nicht passt, fällt vor die Füße (`loot_overflow`). `use_bomb` nimmt eine Bombe heraus, `use_key` zuerst einen zerbrechlichen Schlüssel, dann einen bleibenden (`key_ids`).
- **Zerbrechliche Schlüssel** (aus dem Dungeon: `key_chance`, Händler, Items mit `give.keys`) zerbrechen beim Verlassen: `MetaState.end_run` lässt alles mit `fragile` weg, der End-Bildschirm zeigt „Schlüssel zerbrochen: n“ (`RunState.fragile_keys`). **Eisenschlüssel** kommen im Inventar mit nach Hause und wieder mit hinein; es gibt sie bei Egon im Tausch (`trades.json` `eisenschluessel`: 3 Kupfererz + 2 Eisenerz; `get` kann jetzt auch `loot` sein).
- Keine Start-Bombe mehr (`player.json` `bombs` 0, Wunsch 2026-11-28). Wäre der Wert größer: `RunState.top_up_start` füllt nur auf, was fehlt, nachdem `Game.start_new_run` das Inventar von zu Hause zurückgelegt hat; Bomben von zu Hause stapeln sich so nicht mit Gratis-Bomben.
