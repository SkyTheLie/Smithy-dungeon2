# Audio

> Teil von `docs/SYSTEME.md` (dort das Inhaltsverzeichnis). Der Text der Einträge stammt unverändert aus der früheren einen Datei.
> Neue Einträge: oben unter „Abschnitte“ als eigener Abschnitt `## Name (Datum, Branch)`; gilt etwas nicht mehr, den alten Eintrag ändern statt einen zweiten zu schreiben.

**Zweck:** Geräusche, Musik, Lautstärke-Regler, Stimmen der Völker.

**Meistgenannte Dateien:** `scripts/systems/voice.gd`

**Daten:** `audio.json`, `story.json`

**Genannte Tests:** `assets/_reference/story_umbau/test_voice.gd` (alle über `bash assets/_reference/run_tests.sh`)

**Fallen:** bekannte Probleme stehen in `docs/PROBLEME.md` (nach dem System-Namen suchen), wiederkehrende Fehler in `docs/FEHLERKLASSEN.md`.

## Kurzfassung

- **Musik und Sounds:** `AudioManager` (Autoload) + `data/content/audio.json` (alle Pfade zum Austauschen): Hintergrundmusik (Stück oder Playlist im Wechsel, pro Szene wählbar `scene_music`, nach Story-Flags `flag_music`; Dorf: drei Stücke im Wechsel, Wald `forest_01.wav`, Mine `mine_02.wav`, Vulkan und Goblin-Karten `volcano_01.wav`, Leonheim `city_01.wav`, Schloss `palace_01.wav`, Überfall `scarry_psycho_moment.wav`; seit 2026-11-17 Sylvaris `elves_01.ogg`, Eisquell `ice_01.ogg`, Sumpf `swamp_01.ogg`, Finsterburg `fortress_01.ogg`, Finsterstadt `finster_01.ogg`, Altar `altar_01.ogg`, Wüste `desert_01.ogg`, Pyramide `pyramid_01.ogg`, Unterwelt `underworld_01.ogg`, Turnierhallen und Arenen je Stadt eigene Stücke `arena_<stadt>_01.ogg` (seit 2026-11-19, vorher alle `arena_01.ogg`), Hauptmenü/Intro `title_01.ogg`; Vorrang über die Szene mit `set_music_override`: Kampffenster `battle_01.ogg` (in den Arenen `battle_<stadt>_01.ogg`, `scene_battle_music`) bzw. Boss-Stufe `boss_01.ogg`, Abspann `ending_01.ogg`), Amboss-Treffer, Skills, Level-Up (Platzhalter). Level-Up lässt die Figur golden aufleuchten (`LevelUpGlow`). Einstellungen: Musik/Geräusche 0–100 % und an/aus (`AudioSettings`, `user://settings.cfg`).

# Abschnitte (neueste oben, wie sie entstanden sind)

## Musik der Spelunke (2026-11-21, Branch `feature/spelunke-tische`)

- Neues LMMS-Stück `den_01` (Generator `make_area_music.py`, Stück `den`, Projekt `smithy_audio/den_01.mmp`): verrauchter Saloon-Swing in a-Moll, 104 bpm, 74 s: gestopfte Trompete (A-Teile), Klarinette (B-Teil), Honky-Tonk-Klavier mit Stride (Bass auf 1 und 3, Akkord auf 2 und 4), laufender Kontrabass, Rand-Klicks, leise Bassdrum und Rassel. Lautstärke wie die übrigen Stücke (Mittel -26 dB).
- audio.json: `music.den`, `scene_music` `black_market_den.tscn` » `den` (der Hinterhof davor spielt weiter `city`).
- Test: `spielhoelle/test_gambling_den.gd` prüft, dass in der Spelunke `den` läuft.

## Eigene Musik je Arena (2026-11-19, Branch `feature/arena-musik`)

- Zehn weitere LMMS-Stücke (Generator `make_area_music.py`, Quellen in `smithy_audio/`): je Stadt ein Hintergrund-Stück für Turnierhalle, Arenahalle und Ring (`arena_leonheim_01` königlich, B-Dur, Trompeten und Orgel; `arena_eisquell_01` a-Moll, Horn, Celesta, Kriegstrommel; `arena_sahrim_01` D phrygisch-dominant, Schalmei, Sitar, Handtrommeln; `arena_finster_01` h-Moll, gedämpfte Trompete, Akkordeon, Pizzicato; `arena_sylvaris_01` D lydisch im 3/4-Takt, Flöte, Horn, Harfe) und ein schnelleres Kampflied in derselben Klangfarbe (`battle_<stadt>_01`, 138–160 bpm). Lautstärke wie `arena_01`/`battle_01` (−25 bzw. −24 LUFS, mit ffmpeg `ebur128` gemessen).
- Neu in audio.json: `scene_battle_music` (Szene » Kampflied). Das Kampffenster fragt `AudioManager.get_battle_music("battle")`: in einer Halle oder einem Ring einer Stadt spielt deren Kampflied, sonst `battle`; Boss-Stufen bleiben bei `boss`. `arena_01` spielt nur noch in den zwei Vorlagen-Hallen (`tournament_hall.tscn`, `arena_hall.tscn`).
- Tests: `audio/test_arena_music.gd` (jeder Ring: Hintergrund- und Kampfmusik der Stadt, Dorf: normales Kampflied), `audio/test_music_rules.gd` (jedes Kampflied in `scene_battle_music` gibt es).

## Restliche Musik: Wüste, Pyramide, Unterwelt, Arenen, Kampf, Boss, Titel, Abspann (2026-11-17, Branch `feature/musik-rest`)

- Acht weitere LMMS-Stücke in `smithy_audio/`, gleicher Aufbau und Generator wie unten: `desert_01` (Wüste, Vor Sahrim; D phrygisch-dominant, 90 bpm: Schalmei, Sitar, Handtrommeln), `pyramid_01` (Pyramide von Sahrim, Tal und Halle der Pyramide; A phrygisch-dominant, 70 bpm: Okarina, Cello, Glas-Pad, Gong), `underworld_01` (Unterwelt; cis-Moll, 76 bpm: Posaune, Tuba, Chor, Orgel, Gong), `arena_01` (alle fünf Turnierhallen, Turnierplatz Leonheim, Arena der Krone, Sahrim-Arena; D-Dur-Fanfare, 116 bpm), `battle_01` (Kampf, e-Moll, 140 bpm, 55 s), `boss_01` (Boss, f-Moll, 120 bpm: Chor, Blech, Orgel), `title_01` (Hauptmenü, Charaktererstellung, Intro; G-Dur, 92 bpm: Horn, Streicher, Harfe), `ending_01` (Abspann: dasselbe Thema langsam auf dem Klavier, 72 bpm). Titel und Abspann teilen sich Melodie und Akkorde (`THEME_*` im Generator).
- Sahrim: Schmiedeplatz spielt jetzt die Stadtmusik wie der Rest von Sahrim; Wüste und Vor Sahrim nicht mehr die Vulkanmusik.
- **Vorrang:** `AudioManager.set_music_override(schlüssel, stück)` spielt `stück` über der Szenen- und Flag-Musik, bis derselbe Schlüssel `""` setzt (der zuletzt gesetzte gewinnt). Nicht gespeichert (setzt das Fenster beim Öffnen neu). `BattleWindow` setzt `battle` bzw. auf der Boss-Stufe (`DungeonData.StageType.BOSS`) `boss`, solange es sichtbar ist und der Kampf läuft; nach dem Kampf, beim Schließen oder wenn das Fenster verschwindet, kommt die Szenenmusik zurück. Der Abspann (`ending.gd`) setzt `ending` bis zum Aufwachen.
- Hauptmenü: `AudioManager` startet mit `default` und wechselt einen Frame später auf das Stück der ersten Szene (`main_menu.tscn` » `title`).
- Bewusst ohne eigene Musik: das Amboss-Minispiel (Takt-Klickspiel, eine zweite Musik im anderen Tempo würde den Takt stören) und die übrigen Minispiele.
- Tests: `audio/test_music_override.gd` (Vorrang, Kampffenster mit Boss-Stufe, Abspann), `alpha/test_scene_music.gd` (alle 14 Stücke laden, Wüste, Pyramide, Turnierhalle, Hauptmenü).

## Musik für die späten Gebiete (2026-11-17, Branch `feature/musik-gebiete`)

- Sechs neue LMMS-Stücke, Projekte in `smithy_audio/` (außerhalb des Repos, wie die älteren): `elves_01.mmp` (Sylvaris, D lydisch, 3/4, 66 bpm: Flöte, Harfe, Glockenspiel, langsame Streicher, Windspiel), `ice_01.mmp` (Eisquell mit Grotte, Schmiedeplatz, Kahns Halle, Eiswand, Gezeiten-Arena; a-Moll, 84 bpm: Celesta, Horn, Tremolo-Streicher, Harfe, Chor, Pauke), `swamp_01.mmp` (Sumpf; E phrygisch, 70 bpm: Fagott, Klarinette, Pizzicato, Holzblock), `fortress_01.mmp` (Finsterburg: Heerlager, Torhof, Thronsaal, Flucht, Burggraben, die fünf Schleichkarten, Kerker, Burggang, Mauerkrone, Kerkerschmiede; c-Moll-Marsch, 100 bpm: Posaune, Blech, Streicher-Ostinato, Marschtrommel, Pauke), `finster_01.mmp` (Finsterstadt: Südtor, Stadt, Versteck, Wachstube, Schmiedegrube, Arena; h-Moll, 92 bpm: Akkordeon, gedämpfte Trompete, Pizzicato-Bass), `altar_01.mmp` (Vor dem Altar, Altar der Neun; d-Moll, 88 bpm: Chor, Blech, Streicher, Orgel, Pauke, Glocken).
- Aufbau wie `volcano_01`: Sf2 Player mit GeneralUser GS, Schlagzeug-Samples von LMMS, 32 Takte in den Mustern A1 / A2 / B / A3, Schleife über das ganze Lied (`lp0pos`/`lp1pos`). Spurnamen auf Deutsch („Melodie (Flöte)“ …).
- Im Spiel als `.ogg` in `assets/audio/music/` (je ~2 MB statt ~25 MB als WAV), Zuordnung in audio.json `music` + `scene_music`; `AudioManager._with_loop` schaltet die Schleife auch bei Ogg ein. Lautheit wie die älteren Stücke (ca. -25 LUFS).
- **Ändern:** `.mmp` in LMMS (`D:/LMMS`) öffnen, bearbeiten, speichern, dann „Datei » Exportieren“, Format OGG, „Als Schleife exportieren“ an, über die Datei in `assets/audio/music/` schreiben. Oder per Kommandozeile: `D:/LMMS/lmms.exe render <stück>.mmp -o assets/audio/music/<stück>.ogg -f ogg -l`. Wichtig: Noten dürfen nicht über Takt 32 hinausragen, sonst wird das Stück länger und die Schleife hat eine Pause.
- Erzeugt hat die erste Fassung `assets/_reference/audio/make_area_music.py` (Noten, Akkorde, Instrumente als Text); erneut ausführen **überschreibt** die `.mmp`, also nur für ganz neue Stücke.
- Test: `alpha/test_scene_music.gd` (alle sechs laden als Ogg, Sumpf, Sylvaris und Kerker der Finsterburg spielen ihr Stück), `audio/test_music_rules.gd` (jeder Pfad und jede Zuordnung gültig).

## Völker sprechen verschieden (2026-10-28, Branch `feature/rassen-sprache`)

- **Regeln pro Volk:** `docs/DIALOGE.md`, Abschnitt „Völker – wie sie sprechen“ (Echsen zischen, Goblins chaotisch und gierig, Elfen gehoben, Wasservolk knapp, Halbdämonen trocken-spöttisch).
- **`Voice`** (`scripts/systems/voice.gd`): verändert den fertigen, übersetzten Text nach der Sprechart. `"hiss"`: S am Wortanfang und jedes ss/ß wird zu drei s („Sand“ » „Sssand“, „muss“ » „musss“); von Hand verlängerte S und Namen wie „Ssiva“ zählen einmal, zweimal anwenden ändert nichts. Gilt für jede Sprache.
- **Wo:** `DialogueBox` (Sprechart der Figur aus story.json `npcs.<id>.voice`, `Story.get_npc_voice`) und Händler-Begrüßungen (`Merchant.voice`). Zischen: alle Echsen (Ssarok, Ishra, Brakk, Kesh, Mira, Zahir, Echsenwachen, Muhme Grisla) und die Händler Ssiva und Tuk in Sahrim.
- **Goblins:** 18 Zeilen von Goldzahn, seinen Wachen, dem Aufseher, der Menge und dem dünnen Goblin neu geschrieben (`assets/_reference/story_umbau/patch_goblins.py`). Test: `assets/_reference/story_umbau/test_voice.gd`.
