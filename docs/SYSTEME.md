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
- **P** (nur `OS.is_debug_build()`, also nicht im exportierten Spiel) bringt den Spieler in einen geschlossenen Raum weit weg von der Ebene (Zelle -10/-10). Nicht während eines Kampfes. Nochmal P = zurück an die alte Stelle.
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
- Minimap oben rechts: aktueller Raum von oben, Türen (grau offen, braun zu, gold verschlossen), Steine, Beute (gelb), Gegner (rot), Spieler (grün mit Blickrichtung). **M** zoomt auf die Ebene. Nebel: nur besuchte Räume und ihre direkten Nachbarn sind zu sehen (`Dungeon.known_cells`), der Boss-Raum erscheint wie jeder Raum erst als Nachbar eines besuchten Raums und bekommt dann einen roten Rand. Geheimräume erscheinen erst nach dem Betreten.
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

## Gold in der Tasche – 2026-11-26, `feature/geld-in-tasche`

- Das Gold des Runs ist das Material `gold` (`loot.json`, Stapel bis 999 über `stack`) in der Tasche: fallen lassen, umsortieren, in den sicheren Platz legen wie alles andere. `RunState.coins` zählt nur das Gold in der Tasche (eine Quelle); `add_coins` legt hinein (gibt zurück, was nicht passt), `spend` nimmt heraus (`Bag.remove`, normale Plätze zuerst). Das Geldbündel-Feld im Tab-Fenster ist weg.
- Münzen auf dem Boden werden beim Anfassen zu 8–12 Gold für die Tasche; ist sie voll, bleibt das Gold liegen („Inventar voll!“).
- Run-Ende: Gold aus der Tasche geht in die Geldbörse zu Hause (`MetaState.end_run`), nicht ins Inventar. Beim Tod nur das Gold im sicheren Platz.
