# Überblick: Ordner, Doku-Dateien, fertige Systeme

> Ausgelagert aus `PROJEKT.md` (2026-11-13), damit jene Datei klein bleibt. Diese Datei wird **nicht** automatisch in jede
> KI-Sitzung geladen: bei Bedarf lesen (wo liegt was, welche Doku gibt es, was ist schon gebaut).
> Neue Ordner, neue Doku-Dateien und neue System-Namen hier eintragen.

## Ordnerstruktur

```
res://
├── assets/
│   ├── audio/              # music/ (Hintergrundmusik), sfx/ (Geräusche) – Zuordnung in data/content/audio.json, bisher Platzhalter
│   ├── fonts/              # micro5.ttf (Pixel-Schrift, scharf bei Größe 11 und 22) + Lizenz (OFL)
│   ├── ui/                 # theme.tres (Projekt-Theme), 9-Slice-Rahmen (Fenster, Knöpfe, Slots, Titelleiste), Icons (Sonne, Mond, Münze)
│   ├── sprites/
│   │   ├── buildings/      # Gebäude von außen (smithy_house.png)
│   │   ├── characters/     # Charakter-Baukasten: base.png (Figur mit Markerfarben) + parts/ (Frisuren, Ohren, Hörner, Schwänze, Augen)
│   │   ├── battle/         # Kampf-Hintergründe der Dungeons (Seitenansicht, nahtlos: rat_cellar, forest, volcano, mountain_*)
│   │   ├── effects/        # Icons der Status-Effekte (16×16 px)
│   │   ├── enemies/        # Gegner-Bilder (16×16 px, Blick nach links)
│   │   ├── forging/        # Glühende Werkstücke fürs Amboss-Minispiel (80×48 px, pro Muster)
│   │   ├── heroes/         # Helden-Porträts (24×24 px)
│   │   ├── items/          # Item-Icons (24×24 px), jewelry/ = Ringe und Amulette vom Juweliertisch pro Kristall, holy_crystals/ = animierte Streifen der neun heiligen Steine (48×48 pro Frame)
│   │   ├── lights/         # Licht-Texturen für PointLight2D (sahrim_hex_light.png: Sechsecknetz unter der Glaskuppel)
│   │   ├── molds/          # Gussform-Silhouetten pro Teil-Art (16×16, Rahmen in Metallfarbe entsteht im Spiel)
│   │   ├── maps/           # Gebackene Boden-Bilder von Außenkarten (market_ground.png, 640×480)
│   │   ├── market/         # Marktstände (stall_<händler>.png, 64×64)
│   │   ├── npcs/           # Händler-Figuren (48×48, Blick nach Süden)
│   │   ├── objects/        # Weltobjekte (teleporter_sheet.png: 41 Frames à 64×120 px)
│   │   ├── skills/         # Skill-Icons (16×16 px)
│   │   ├── forest/         # Wald-Hintergründe (deep_forest.png; forest_entrance*.png und hut.png alt, ungenutzt)
│   │   ├── trees/          # Bäume zum Fällen (oak, pine, birch, 48×64)
│   │   ├── plants/         # Pflanzen zum Aufheben (hemp, flax, 24×24)
│   │   ├── elves/          # Sylvaris (Platzhalter per Skript): Waldboden, Baum innen, Kronenebene, Spitze, Gästezimmer + Masken und Ebenen darunter
│   │   ├── ice_wall/       # Mauerkrone (Teil 6): Eissäulen, Spiegelsockel, singende Wand, Feuer im Hafen (Platzhalter)
│   │   ├── finster/        # Finsterstadt (Teil 7): Häuser, Färberei, Laternen, Steckbriefe, Versteck (Platzhalter), west/ Häuser des Westviertels
│   │   ├── altar/          # Altar der Neun (Teil 8): Säulen, Amboss des ersten Schmieds, Tor (Platzhalter)
│   │   ├── mine/           # Mine (mine_small.png + mine_small_mask.png = begehbare Gänge; mine_medium* = größere Mine ab Ende Kapitel 5; mine.png = alte große Mine, für später), Mine-Eingang (cliff.png mit eingeschnittenen Stollen, old_mine_cleared.png; entrance_area*.png alt, ungenutzt)
│   │   ├── props/          # Deko-Objekte (Fass, Säcke, Kohlehaufen, Lore, Kisten, Laternenpfahl, Spitzhacken)
│   │   ├── rocks/          # Erz-Vorkommen der Mine (coal_rock, copper_rock, iron_rock, 32×32)
│   │   ├── rooms/          # Raum-Hintergründe (smithy_room.png: Boden + Rückwand + Wanddeko)
│   │   ├── stations/       # Stations-Grafiken in Originalgröße (anvil, forge, workbench, water_trough, smelter/frame_1–4)
│   │   ├── ui/             # UI-Icons (Seitenmenü, 16×16 px), doll.png (Silhouette fürs Ausrüstungsfenster), skill_trees/ (Skillbaum-Hintergründe pro Klasse, 192×128)
│   │   └── player/         # player_sheet.png (Spieler-Animationen)
│   └── _reference/         # NICHT im Spiel (.gdignore): Konzeptbilder, Quell-Frames, Back-Skripte (Unterordner: docs/systeme/referenz.md)
├── data/
│   ├── content/            # story/ (die Geschichte in mehreren Dateien, Dialoge je Gebiet); JSON: items, materials, weapon_types, (recipes), forging_patterns, status_effects, skills, skill_trees, summons, enemies, dungeons, combat, economy, appearance, story, calendar, house, sockets, mortar (Stäube, Tränke, Gebräu), guild_heroes, light_points, npcs, audio, achievements, desert (Labyrinth der Wüste), arena (Heldenturnier), leagues (Liga-Turniere und Rangliste), world_map (Weltkarte) – Anleitung docs/CONTENT.md
│   ├── destinations/       # TravelDestination-Resources (Teleport-Ziele)
│   ├── hero_classes/       # HeroClass-Resources (Klassen mit Farbe)
│   ├── heroes/             # Hero-Vorlagen (anheuerbare Helden)
│   ├── quests/             # QuestData-Resources (Aufträge von NPCs)
│   ├── player_skills/      # PlayerSkillData-Resources (Skills des Spielers) + skill_tree.tres (Liste, Reihenfolge)
│   ├── rocks/              # RockData-Resources (Steinarten der Mine)
│   ├── hero_level_table.tres  # EXP pro Level der Helden (LevelTable)
│   └── player_level_table.tres  # EXP pro Level des Spielers (LevelTable)
├── docs/
│   ├── ART_STYLE.md        # Grafik-Vorgaben (Stil, Palette, Größen, PixelLab-Einstellungen)
│   ├── ASSET_KATALOG.md    # Alle PixelLab-Grafiken im aktuellen Stil, was wiederverwendbar ist (vor neuen Grafiken lesen)
│   ├── PIXELLAB_TODO.md    # Was noch mit PixelLab erzeugt/ersetzt werden muss (Platzhalter und unbeliebte Bilder hier eintragen)
│   ├── ANLEITUNGEN.md      # Schritt-für-Schritt: neues Gebiet, Quest, Quest-Abfolge, Dialoge, Fenster, Gegenstände (zum Selbstlernen)
│   ├── CONTENT.md          # Inhalte per JSON hinzufügen (Items, Rezepte, Effekte, Skills, Gegner, Dungeons, Formeln)
│   ├── SYSTEME.md          # Inhaltsverzeichnis der fertigen Systeme
│   ├── systeme/            # Details je System: welt, spieler, schmieden, kampf, helden, story, wirtschaft, haus, turniere, ui, kern, audio, referenz
│   ├── BINDUNG.md          # Ideen für Erfolgserlebnis und Spielerbindung (Pakete 1–5, Stand der Umsetzung)
│   ├── STEAM.md            # Erfolge an Steam anbinden (GodotSteam, Steamworks-Liste, Icons)
│   ├── SPRACHEN.md         # Mehrsprachigkeit: locale/<sprache>.po, Texte sammeln und mit agy übersetzen, neue Sprache anlegen
│   ├── ANDROID.md          # APK bauen und aufs Handy bringen (Skript assets/_reference/android/build_and_install.sh, Pfade, Fehlerhilfe)
│   ├── STORY.md            # Story-Überblick: bis wohin sie im Spiel geht, Figuren, Freischaltungen, geplante Kapitel
│   ├── STORY_PLAN_6-8.md   # Entwurf für Teil 6–8 (Eiskristall, legendärer Schmied, Finale) und Inhalte nach dem Ende
│   ├── DIALOGE.md          # Wie jede Figur spricht (Erzähler, Spieler, NPCs), Regeln für Spieltexte (keine Kapitel), Geheimnisse
│   ├── SKILLBAEUME.md      # Plan der 3 Skillbäume pro Heldenklasse mit allen Werten (umgesetzt in skills.json / skill_trees.json)
│   ├── UEBERSICHT.txt      # Liste aller Inhalte (Klassen, Waffen-/Rüstungstypen, Kristalle, Elemente, Skills, Gegner, Dungeons …), erzeugt von assets/_reference/overview/make_overview.py
│   ├── ENTSCHEIDUNGEN.md   # Entscheidungslog
│   ├── UEBERBLICK.md       # Diese Datei: Ordnerbaum, Doku-Liste, Namen der fertigen Systeme
│   ├── FEHLERKLASSEN.md    # Wiederkehrende Fehler und die Regeln dagegen (wird über CLAUDE.md jeder Sitzung mitgegeben; jeder fix/-Branch trägt dort seine Ursache ein)
│   ├── CODE_REVIEW_2026-11-12.md # Prüfbericht: Architektur, Code, Tests, Arbeitsweise, mit Reihenfolge der Verbesserungen
│   ├── PROBLEME.md         # Bekannte Probleme (vollständige Liste)
│   ├── PROBLEME_ERLEDIGT.md # Archiv erledigter/überholter Probleme
│   ├── VERLAUF.md          # Frühere Aufgaben mit Test-Anleitung
│   ├── TESTPLAN.md         # Checkliste der offenen Handtests, nach Sitzungen
│   └── GDD.md
├── scenes/
│   ├── actors/             # Spieler, anheuerbarer NPC, Auftraggeber (quest_npc), Story-Figur (story_npc), Kunde (customer_npc), Marktstand mit Händler (market_stall + merchant.gd)
│   ├── stations/           # Station-Basis + Amboss, Esse, Schmelze, Wassertrog, Werkbank, Zaubertisch, Schleifstein, Gerberbank, Bogentisch, Aufwertungstisch (ausgebaut), Juweliertisch
│   ├── ui/                 # window_title_bar (Titelleiste für alle Fenster)
│   │   ├── main_menu/      # Startbildschirm + Hauptmenü (Hauptszene), Charakter-Editor
│   │   ├── dialogue/       # DialogueBox (Story-Dialoge mit Sprechern und Auswahl)
│   │   ├── common/         # Bausteine: SlidingPages (Seiten mit Schiebe-Animation), EquipmentDoll (Silhouette mit Slots), SkillTreeView (Skillbaum), RichTooltip (farbiger Tooltip, Shift = Details), ResizeGrip (Fenstergröße ziehen)
│   │   ├── hud/            # HUD (Hotbar, Inventar, Seitenmenü, Charakter/Aufträge/Einstellungen/Rezeptbuch, Tipp-Fenster)
│   │   ├── heroes/         # Heldenliste, Heldenfenster, Werte-Fenster („Mehr anzeigen“), Kampffenster
│   │   ├── inventory/      # Slot-Anzeige, Slot-Raster, Item-Tooltip
│   │   ├── menus/          # StationMenu-Basis, RecipeBrowser, Herstellungs-, Zusammenbau-, Schmelze-, Wassertrog-,
│   │   │                   #   Teleport-, Dungeon-Brett-, Gilden-, Turnier-Fenster (Herold, Turnierleiter, Siegerpreis-Wahl), Waffenkammer (General Hadmar), Anheuer-Dialog, Kauf-Dialog, Kunden-Dialog, Auftragsbrett, Einkauf für Lotte
│   │   └── minigames/      # Schmiede-Minispiel, Taktbalken, Werkbank-Minispiel (Teile verbinden), Schleif-Minispiel, Hütchenspiel des Bettlers, Spielautomat, Vex' Bar (Münzen), Höher oder Tiefer, Poker
│   ├── story/              # Intro (Hintergrundgeschichte nach dem Charakter-Editor)
│   └── world/
│       ├── _template/      # map_base.tscn: Vorlage für neue Karten (Neue geerbte Szene), keine echte Karte
│       ├── objects/        # Wiederverwendbare Weltobjekte (Tür, Teleport-Kristall, Dungeon-Brett, Auftragsbrett, Mietschild, Spinnweben, Abenteurergilde, Erzstein, Stein-Spawner, Bettler mit Hütchenspiel, ItemSprite = Item-Icon in der Welt)
│       ├── forest/         # Wald-Eingang, Holzfällerhütte, tiefer Wald
│       ├── market/         # Marktplatz, Ninas Laden
│       ├── mine/           # Mine-Eingang, Mine, CaveWalls (Wände aus Maske)
│       ├── smithy/         # Schmiede (Hauptszene) + Raum, Schlafzimmer
│       ├── capital/        # Königsstadt Leonheim: Schlossgarten, Vorhalle, Thronsaal, Kerker, Einkaufsstraße, Läden/Gilde/Gasthaus innen, Schwarzmarkt mit Spelunke, Schmiedegasse, Turnierplatz
│       ├── elves/          # Sylvaris (Elfenstadt): Waldboden, großer Baum, Kronenebene, Gästezimmer, Spitze; ElfLift (Plattform), ElfAttackCutscene
│       ├── finster/        # Finsterstadt (FinsterChase), Versteck, Wachstube, Schleichen in die Burg, Kerkerschmiede, Altar der Neun (Teil 7–8)
│       ├── village/        # Dorfplatz (Start), Alte Schmiede (village.tscn), Wohnviertel, Omas Haus, Dorftor & Kreuzung, Südweg, CustomerSpawner
│       ├── desert/         # Wüste: ein Bildschirm für alle Felder des Labyrinths (desert.gd, Truhe DesertChest), Sahrim (Glaskuppel des Echsenvolks: vor der Kuppel sahrim_gate.gd, Quellplatz desert_town, Zeltviertel, Markthalle, Fürstenzelt, Gasthaus, Zelle am Südtor; DomeLight, SpringBirds), Sturmtempel (Vorhof, Säulenhalle, innerste Kammer)
│       ├── water/          # Eisquell (Stadt des Wasservolks), Halle der Strömung, Gezeitenarena (Ring der Gezeitenhalle, Heldenturnier)
│       ├── swamp/          # Sumpf am Ostweg (Muhme Grisla)
│       ├── fortress/       # Finsterburg: Heerlager, Schleich-Gebiete (Graben, Mauergänge, Torhof), Burghof, Thronsaal, Flucht mit Aurelius
│       ├── tournament/     # Turnierhallen der Liga-Turniere (TournamentHall: Empfang mit Turnierleiter, eine Szene je Stadt erbt tournament_hall.tscn)
│       ├── sneak/          # SneakGuard (Wache mit Blickkegel), SneakZone (gesehen = zurück zum Anfang); Karten aller Schleich-Gebiete aus assets/_reference/story5/make_sneak_maps.py
│       └── volcano/        # Lavaberg (Schlucht mit Brücke, Goblins in der Tiefe), Kristallhöhle, Goblinhöhle, Goblinminen, Goblinburg (Vorplatz, Halle, Schmiede, Schatzkammer); DepthLayer (Parallaxe), GoblinWorker, GoblinFigure, GoblinThroneCutscene, CastleRubble, TreasuryGate, GoblinKeySwitch, GoblinForgeView, DragonWakeCutscene, Lava-/Dunst-Shader (lava_glow = leuchtet im Dunkeln)
├── scripts/
│   ├── core/               # Autoloads (Events, GameState, AudioManager), DevTools (ein Schalter für Test-Funktionen), SaveData (was im Spielstand steht: sammeln und anwenden), ContentDB (lädt data/content/*.json), WindowLayout (angepinnte Fenster, settings.cfg), DisplaySettings, KeyBindings, SteamBridge, Language (Sprache und .po-Dateien), UiScale
│   ├── resources/          # Resource-Klassen (NpcInfo, ItemData, ItemAttribute, Rarity, InventorySlot, RecipeData, Ingredient, PlayerStats, TravelDestination, RockData, Hero, HeroClass, EnemyData, DungeonData, LevelTable, SkillData, SummonData, Element, DamageType, DamageKinds, PlayerSkillData, PlayerSkillTree, QuestData, QuestReward, StatusEffectData, WeaponType, CustomerOrder, Appearance, SocketBonus, Socket, DustData, UpgradeData)
│   └── systems/            # Logik ohne Szene (Guide, ClassUnlocks, Inventory, ForgeFire, QuestItems, StoryActions, DungeonRewards, Smelter, AlloySmelter, Quencher, Crafting, Joining, Garden, Enchanting, Residents, Sharpening, Tanning, Upgrading, Jewelry, ItemIcons, GuildLevel, SearchOrders, Assistant, SmithTournament, HeroTournament, TournamentRanking, ArenaDuel, HeroBuilder, StormTemple, Adventure, Combatant, CombatRules, DayCycle, GameCalendar, SaveSystem, Customers, Economy, CharacterBaker, Story, Rent, ConsignmentShop, House, SpriteOutline, Roaming, QuestJump, Voice, Carriage, GoblinKey, WaterSlosh, ElfDefense)
├── CLAUDE.md
└── PROJEKT.md
```

## Fertige Systeme

Nur die Namen, neue hinten anhängen. Beschreibung jedes Systems: `docs/systeme/<system>.md` (Kurzfassung oben, Details darunter), Inhaltsverzeichnis `docs/SYSTEME.md`. JSON-Felder: `docs/CONTENT.md`.

Welt, Spieler, Tag und Ressourcen, Schmieden, Inhalte als JSON, Skillbäume, Helden, Attribute, Kampf, Aufträge, Story, Start, Charakter-Baukasten, Datum und Kalender, Reisender, Ninas Laden, Hausausbau, Feste Dorfbewohner, Händler-Sortiment, Kunden und Wirtschaft, Musik und Sounds, Komfort, Alpha, Kristall-Fassung am Altar-Feedback, UI, Erfolge, Belohnungsmomente, Speichern/Laden, Teleporter, Helden-Skills ein/aus, GameState-Autoload, Aufträge nach Können, IQ-Tränke und Rollen, Schmiedegasse und Ritter-Aufträge, Kristallkarte, Goblinhöhle und Goblinburg, Boss-Phasen und Feuer-Absorption, Glück der Krone, Gussform-Sets, Metall-Stiele, Alte Mine (Mine 2), Zauberstäbe aller Metalle, Ende von Teil 2 und Dungeon-Reihenfolge, Schleif-Minispiel und Asche-Dünger, Gilden-Ausbau und Suchaufträge, Schmiedeturnier, Sylvaris, Sturmgipfel, Juweliertisch, Trank-Rezepte, Goldenes Leuchten, Ankunfts-Cinematic, Rassen-Boni, Klassen-Elemente, Erz-Stufen und Dungeon-Faktoren, Gießkanne, Verzaubern mit Vielfalt, Wüste und Wüstenkompass, Eisquell und Heldenturnier, Sturmtempel, Sumpf und Finsterburg, Schleichen, Mehrsprachigkeit, Story Teil 6–8 (Eismauer, Finsterstadt, Altar der Neun), Quest-Sprung im Admin-Panel, Story-Umbau (Entscheidungen, Dorf-Teil), Völker-Sprache, Weltkarte und Teleport-Karte, Kutsche mit Reisetagen, Admin-Uhr, Goblinburg-Rätsel, Eigene Monster-Animationen, Spielende, Sylvaris erweitert (Schwebestein-Brücken), Turnier-Austragungsorte, Fenstergröße ziehen, Offene Karten (Eisquell 3 Ebenen, Pyramide, Unterwelt), Nebenquests (Fenns Flugmaschine, Aufträge in den Städten), Liga-Turniere und Rangliste, Turniere in jeder Stadt, Raum-Designer, Werkstatt-Upgrades, Ruhmeshalle, Lotte als Gehilfin, Dorfkutsche mit Kutscher, Heilige Kristalle mit Animation, Lagerkisten, Charakter-Editor mit Kategorie-Menü und Farbrad, Ohrformen, Heldenplätze nach Ruf-Rang und gleichzeitige Dungeons, Lehrgänge (Leder, Bogen, Zauberstab), Erz-Reihenfolge, Beute nur freigeschalteter Metalle, Aufgaben-Tracker mit Abschnitten, Gäste in Gilde und Gasthaus, Zauberstab-Minispiel mit Pixel-Grafik, Goblin-Thronsaal (Menge macht Platz), Neue Schmied-Skills (Formenbauer, Feuerprobe, Härtekunst, Goldene Zunge, Feldschmied, Gerber), Lotte verkauft aus der Loot-Kiste, Tal der Pyramiden (legendärer Kompass), Waffen für Sylvaris (zwei Enden der Nacht), Rollen-Outfits, Verzauberer als Anlaufstelle (Trank-Rezepte, bessere Erde), Schwere Dungeons (×2 bis ×5), Bewegter Startbildschirm, Nebelfürst und Moorschleime, Hydra mit drei Köpfen, Skill-Schaden im Tooltip, Schmieden fern der Schmiede, Skill-Skalierung mit Attributen, Kampf im Thronsaal (Lake gegen Lich) und Kämpfer im Torhof, Platin ab Teil 6, Schmuck aus Gold/Platin/Palladium, Skill Meisterwerk, Würfeltränke, Lexikon, Südtor der Finsterstadt, Status-Effekte im Lexikon (HoverCard), Hydra als ein Körper, Schmuckvitrine, Gemischte Schild-Attribute, Boss-Lebensbalken, Meldungen unten, Kampffiguren je Metall und Sets (Paladin), Helden umbenennen, Test-Umgebung und Prüfer (eigene Test-Daten, Speicher-Rundlauf, Story-/Inhalts-Prüfer), ForgeFire., Events, Kartenvorlage, NpcInfo, Liga-Ränge mit Rangpunkten und Turnierhallen (TournamentHall, TournamentDeskMenu, PrizeChoiceList), Turnier-Gussformen und Schmiede-Themen, Gruppenkämpfe in der Welt (SkirmishGroup), Element-Säulen am Altar (AltarElements), Umhang der Finsterstadt (Disguise), Schnarchen (SleepZ), Klassen-Instinkte (class_instinct), Rüstung polieren, Balancing-Simulatoren (sim_balance, sim_forge_quality), Poliertisch, Sumpfleder und Höllenleder, Schattenhund, Seltene Beute durch Zählen, Erfolge für Story-Teile, Dungeon-Reihen, Nebenquests, Metalle, Skillbäume, Lexikon, Turniere und Bestwerte, Schmiede-Tutorial (ForgingTutorial), Handy-Version (MobileUi, TouchControls), Laufen per Tippen (TouchWalk), Schmiede-Schild (ForgeSign, ForgeSignWall, ForgeSignMenu, ForgeSignPlacer), Haus außen einrichten (HouseExteriorMenu), Arenahallen der Helden-Ligen (ArenaHall, ArenaFightStage, ArenaFighterPanel, ArenaLeaderboard), Liga-Siegerpreise und Turnier-Marken (TournamentRewards, TournamentShopList), Westviertel der Finsterstadt, Abgeben im Schmiedeturnier (HandInClerk), Siegerfeier der Arenen (ArenaCelebration), Spelunke und Spielmünzen, Nachbarkarten vorladen (MapPreloader), Poker und Höher oder Tiefer an den Spelunken-Tischen (DenPoker, PokerMenu, HigherLowerMenu), Poker-Bots mit Tagesgeld (PokerTable), Steckbrief an der Schmiede, Finsterstadt-Nebel (FinsterFog, StreetLantern, Lamplighter, FogGhost), Sprachwahl vor dem Hauptmenü (LanguageSelect), Begehbare Häuser (HomeDweller, homes/build_home.py), Persisch (Farsi, Schrift Vazirmatn), Textgröße (TextSize), Schmiede-Bots mit Skills (SmithBot, sim_smith_leagues), Russisch (Schrift Tiny5), Japanisch (Fusion Pixel ja), Portugiesisch (Brasilien), Koreanisch, Polnisch, Glückstreffer (Skill Glückshand), Powernap, Wunsch-Kunden, Ziele auf drei Ebenen (Goals), Sammelbuch (Collection), Endloser Turm (TowerDungeon, EndlessTower), Schmiedin und Schneiderin (Tailor, TailorStall, TailorMenu), Spiel-Protokoll (PlayLog)
