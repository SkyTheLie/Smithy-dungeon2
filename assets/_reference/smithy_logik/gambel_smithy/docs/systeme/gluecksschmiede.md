# Glücksschmiede (Smithy Gamba)

**Zweck:** Das Spiel von Smithy Gamba: ein Schmiede-Glücksspiel als Roguelite. Schwerter erhitzen, auf dem Amboss schlagen, jeder Schlag ist ein Zug aus fünf Eimern; abends Abgabe an die Zunft.
**Meistgenannte Dateien:** `scripts/systems/gamba_run.gd` (alle Regeln), `scripts/systems/gamba_sword.gd` (ein Schwert), `scripts/systems/gamba_saves.gd` (der eine Spielstand), `scenes/gamba/gamba_game.tscn/.gd` (Szene), `scenes/gamba/gamba_buckets.gd` (Eimer-Anzeige).
**Daten:** `data/content/gamba.json` (alle Zahlen, Relikte, Verbrauchsgüter, Materialien; `_hilfe` erklärt jedes Feld). Geprüft von `ContentDB._check_gamba`.
**Tests:** `assets/_reference/gamba/test_gamba.gd` (`bash assets/_reference/run_tests.sh gamba`). Simulator: `assets/_reference/gamba/sim_gamba.gd`.
**Fallen:** Zahlen nur mit Simulator-Lauf ändern (FEHLERKLASSEN 28). Ein laufender Tag wird nicht gespeichert (nur zwischen den Tagen). Die Raserei läuft in Spielzeit (`GambaRun.tick`), sie steht in der Pause still.

## Kurzfassung

- Herkunft: Abgespalten aus Smithy Roguelike (Repo `SkyTheLie/Smithy-Gamba`, 2026-11-25). Idee nach einem Video über ein Schmiede-Glücksspiel (`r.txt`), Mechanik übernommen, Namen, Figuren und Grafik eigen (Smithy).
- Ein Run: bis zu 21 Tage (`contract_days`). Start: 3 Kupferschwerter, kein Relikt.
- Jeden Tag kommen 3 neue Kupferschwerter (`daily_swords`, Relikt Zunftsiegel +1). Alte Schwerter bleiben auf der Werkbank.
- Schmieden: „Schmieden“ an einem Schwert der Werkbank » es glüht in der Esse (`heat_seconds`) und liegt dann auf dem Amboss. Klick ins Bild, Leertaste oder „Schlagen“ = ein Schlag (Pause dazwischen `strike_cooldown`). „Abnehmen“ legt es zurück (kühlt ab), man kann es später wieder schmieden.
- Ein Schlag zieht nach Losen aus fünf Eimern: Zerbrochen (Schwert weg, kein Wert) | Beschädigt (Seltenheit -1) | Nichts | Verbessert (+1) | Verbessert ++ (+2). Seltenheit R1 bis R8 (Namen/Farben aus `Rarity`), darüber „R8+n“ (Mythisch +n), höchstens `max_level`.
- Lose: ein neues Schwert hat `start_tickets` (viel Verbessert, kein Zerbrochen). Nach jedem Schlag verschieben sie sich um `drift` × (1 + `drift_growth` × Schläge) × Zufall (`drift_random`): deutlich Richtung Zerbrochen, aber nie gleich. Chance = Lose / Summe. Die Lose gehören zum Schwert und bleiben (auch im Spielstand).
- Raserei: nach 12 Schlägen an einem Schwert (`frenzy.strikes`) 2,5 s (`frenzy.seconds`) lang: nichts kann brechen, die Lose stehen still, schnellere Schläge (`frenzy_cooldown`). Danach zählt es wieder von vorn.
- Wert: `materials[m].value` × `value_growth` (1,4) ^ Stufe × (1 + Wert-Relikte).
- Abend: Schwerter mit „Abgeben“ auf den Tisch der Zunft, „Glocke läuten“. Wert auf dem Tisch ≥ Abgabe des Tages (`demand`: 700 × 1,15^(Tag-1) × Abgabe-Relikte) » alles wird als Gold ausgezahlt, die Schwerter sind weg. Zu wenig » Fehlschlag, Schwerter zurück. 3 Fehlschläge (`max_failures`, Gnadenbrief +1) = Run verloren; Tag 21 bezahlt = gewonnen.
- Händler nach jedem 3. Tag (`merchant_every`): 3 Schwerter besserer Metalle (Fenster wandert mit den Tagen nach oben), 2 Verbrauchsgüter, für Gold. Verbrauchsgut-Preise steigen je Tag (`price_per_day`). Relikte verkauft er nicht.
- Reliktschrein (Knopf oben „Reliktschrein (Marken)“, jederzeit am Tag): Relikte gibt es nie geschenkt. Ein Schwert ab `coin_min_level` (3 = R4) von Werkbank oder Tisch „Einzahlen“ » es ist weg, +1 Zunftmarke. Der Schrein bietet `relic_offers` (3) Relikte an, nach jeder Glocke neue (nie ein schon besessenes); ein Relikt kostet `coins` Marken (1–3). Regeln in `GambaRun.deposit_sword` / `buy_relic`.
- Relikte (höchstens 5, `relic_slots`; voll » eines ablegen), bewusst schwach (2026-11-25): Bruch-Lose ×0,9, Lose dazu, Schwertwert +8 %/+15 %, Schwerter je Tag (2 Marken), Raserei +0,5 s / einen Schlag früher, 25 % der Brüche werden Beschädigt (2 Marken), 15 % Gold beim Bruch, Beschädigung senkt Bruchchance, Gnadenbrief +1 Fehlschlag (3 Marken), Abgabe -7 % (2 Marken). Liste: `gamba.json` `relics`.
- Verbrauchsgüter: Schutzrune (nächster Schlag kann nicht brechen), Stundenglas (letzter Schlag rückgängig, auch ein Bruch; nur solange das Schwert noch nicht abgenommen ist).
- Speichern: ein Spielstand `user://gamba_save.json` (`GambaSaves`), geschrieben beim Start eines Runs, nach der Glocke und nach dem Händler; gelöscht, wenn der Run endet. Gespeichert: Tag, Gold, Fehlschläge, Schwerter (mit Losen), Relikte, Zunftmarken, Schrein-Angebot, Verbrauchsgüter, Händler-Ware, Zufallszahlen-Stand, Statistik. Bewusst nicht: Schwert auf dem Amboss, Tisch, Raserei, Schutzrune, Stundenglas-Stand (laufender Tag; auch Einzahlen und Relikt-Kauf mitten am Tag gehen beim Verlassen verloren). Alte Stände: Relikt-Ware des Händlers wird beim Laden verworfen.
- Hauptmenü: das bewegte Startbild von Smithy, „Weiterspielen“ (nur mit Spielstand, Tooltip `GambaSaves.summary`), „Neues Spiel“ (fragt einmal nach, löscht den Spielstand). Untertitel „Die Glücksschmiede“.
- Esc: Pausenmenü der Verteidigung (`DefensePauseMenu`): Weiterspielen, Einstellungen, Run aufgeben, Hauptmenü, Beenden.
- Musik: „den“ (Spelunke), Hintergrund: Esse (`audio.json` `scene_ambience`).

## Szene (`scenes/gamba/gamba_game.tscn`)

```
GambaGame (Node2D, gamba_game.gd)
├── Camera (Camera2D, Mitte 320×180)
├── World (Node2D)
│   ├── Backdrop (Sprite2D: assets/ui/title_inside.png bei -24,-12)
│   ├── Fire (Sprite2D: title_inside_fire.png, Bilder im Code)
│   ├── ForgeSword / AnvilSword (Node2D mit Handle + Blade Sprite2D)
│   └── Hammer (Node2D, Sprite2D title_hammer.png um den Griff gedreht)
└── UI (CanvasLayer)
    ├── TopBar: Tag, Gold, Fehlschläge, Händler, ShrineButton (Reliktschrein)
    ├── BenchPanel (links): Werkbank-Liste (Karten im Code)
    ├── TablePanel (rechts): Abgabe, Tisch-Liste, Glocke
    ├── BucketPanel (oben Mitte): AnvilInfo, Buckets (GambaBuckets), StrikeInfo, FrenzyBar
    ├── Hint, Actions (Schlagen, Abnehmen, Schutzrune, Stundenglas)
    ├── RelicBar (unten links), ConsumableBar (unten rechts)
    ├── Dim + Popup (Regeln, Tagesergebnis, Reliktschrein, Ablegen, Händler, Ergebnis; PopupScroll/PopupList: Schwerter zum Einzahlen; die Karten liegen in `PopupItemsScroll`, mindestens 380 px breit, und scrollen, wenn das Fenster sonst höher als der Bildschirm würde, gemessen einen Frame nach dem Öffnen in `_center_popup`)
    └── PauseMenu (defense_pause_menu.tscn)
```

Lichter, Funken, Splitter und schwebende Wörter entstehen im Code (`_build_effects`, `_float_text`).

## Abstimmung (Simulator, 300 Runs je Einstellung)

Aufruf mit Überschreibungen zum Ausprobieren: `-- 300 0.15 7 value_growth=1.4 demand.growth=1.15` (nur für den Lauf, `gamba.json` bleibt).

Bot schlägt, solange die Bruchchance unter X liegt (bis 3 Schläge vor der Raserei bis X + 15 %; in der Raserei 7 Klicks/s), gibt die besten Schwerter bis zur Abgabe ab, zahlt übrige Schwerter im Schrein ein und kauft das billigste Relikt, kauft beim Händler das teuerste Schwert.

- Erste Fassung (Wert ×1,5 je Stufe, Abgabe 600 × 1,3^Tag, starke Relikte, eines täglich geschenkt): X 25 % » 29 % Siege; im Spiel lag an Tag 3 das Zwanzigfache der Abgabe auf dem Tisch.
- 2026-11-25 (Wert ×1,4, Abgabe 700 × 1,15^Tag, schwache Relikte über den Schrein): X 8 % » 0 % Siege (Median Tag 12), X 15 % » 5 % Siege (Median Tag 14, Tag 15 erreichen 49 %, Tag 18 27 %), X 25 % » 0 % (Median Tag 4). Wer vorsichtig, aber nicht zu vorsichtig schlägt, kommt weit; Gier wird schnell bestraft. Ein Mensch, der Verbrauchsgüter und Relikte gezielt nutzt, sollte etwas besser abschneiden.

## Abschnitte

- 2026-11-25 · `feature/gluecksschmiede`: erste Fassung.
- 2026-11-25 · `feature/gluecksschmiede`: Reliktschrein statt Gratis-Relikt (Schwert » Marke » Relikt), Relikte abgeschwächt, zwei neue (Gnadenbrief, Freund in der Zunft), Eisenkappe jetzt Zufall statt sicher, Händler ohne Relikte, Wert und Abgabe neu abgestimmt.
