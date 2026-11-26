# Art-Style – Smithy

Verbindliche Vorgaben für alle Grafiken (von Hand oder mit PixelLab). Ziel: Alles im Spiel sieht aus, als käme es aus einer Hand.
Aktueller Karten-Stil (Schmiedeplatz, Marktplatz), Tileset-Basis-Kacheln und alle wiederverwendbaren Grafiken: `docs/ASSET_KATALOG.md`.
Palette als Bild: `assets/_reference/style/palette.png`. Stil-Anker: das Schmiedehaus (`assets/sprites/buildings/smithy_house.png`).

## 1. Welt und Stimmung

- **Mittelalter mit Magie.** Ritter, Dörfer, Steinhäuser mit Fachwerk, Schmiedekunst von Hand.
- **Keine Technologie:** keine Zahnräder, Rohre, Ventile, Manometer, Glaskolben, Dampfmaschinen, Schrauben, Glühbirnen, Metallplatten mit Nieten im Industrie-Look.
- **Magie ist selten und kostbar** und zeigt sich als: Runen (eingeritzt, leuchtend), Kristalle, verzauberte Flammen, Portale. Magie ist immer **blau/cyan** (siehe Palette), alles andere bleibt erdig.
- **Gemütlich, handgemacht, etwas abgenutzt:** Holz mit Maserung, grob behauene Steine, Ruß, Werkzeug an der Wand, Fässer, Säcke, Kohle.

## 2. Technik-Regeln

| Regel | Wert |
|---|---|
| Ansicht | **hohe Draufsicht** (high top-down, ca. 3/4): Oberseite und Vorderseite sichtbar |
| Licht | von **oben links**, Schatten nach unten rechts |
| Umriss | 1 px, **dunkles Violett-Braun `#21131e`**, nicht reines Schwarz |
| Schattierung | mittel (2–4 Stufen pro Material), kein Dithering-Rauschen, keine Verläufe |
| Detail | mittel, lesbar bei 1× Größe |
| Pixelgröße | **Im Spiel nie skalieren** (Scale immer 1). Ausnahme: HUD-Teile kann der Spieler in den Einstellungen als ganzen Block vergrößern (100–200 %, `UiScale`; Standard Aktionsleiste und Gold 150 %). Grafiken direkt in Zielgröße erzeugen. Gemischte Skalierungen (0,3 / 0,5 / 0,7) führen zu unterschiedlich großen Pixeln – das ist der Hauptgrund, warum die alten Stationen nicht zusammenpassen. |
| Hintergrund | transparent |
| Raster | 16 px |

## 3. Größen (bei Scale 1)

| Was | Größe (Leinwand) | Hinweis |
|---|---|---|
| Spielfigur | 48×48, Figur ca. 39 px hoch (PixelLab Größe 36, so groß wie die Dorfbewohner) | Maßstab für alles andere; Welt und Stationen sind noch auf die alte 32-px-Figur gezeichnet |
| Boden-Platte | 32×32 (im Raum 31 px Raster, damit die Fugen 1 px breit sind) | Draufsicht, nicht isometrisch |
| Wand (Rückwand) | 16 breit × 48 hoch | Vorderseite sichtbar, oben Mauerkrone |
| Amboss | 32×32 | auf Holzklotz, ca. hüfthoch zur Figur |
| Esse (Gussstation) | 48×48 | |
| Schmelzofen | 48×64 | höchste Station |
| Werkbank | 48×32 | |
| Wassertrog | 32×24 | |
| Deko (Fass, Sack, Kohlehaufen) | 16×16 bis 16×24 | |
| Item-, Skill-, Effekt- und Menü-Icons | 24×24 | **Seit 2026-10-23 sind alle Icons 24×24** (PixelLab Pixen auf 28er-Leinwand, Umriss `#21131e`, Metallteile in Eisen gezeichnet und umgefärbt; `assets/_reference/item_icons_v4/`). Vorher: 12×12. Seit 2026-10-22 dürfen Icons bis 24×24 groß sein (Item-Plätze 28×28 mit 24×24 Icon-Fläche, Scale 1 wie alle anderen): Helmschalen 16×16, Beinplatten 24×24. 32×32 mit 2 Bildpixeln pro Spielpixel wurde getestet und war zu fein – die Technik dafür (`HiResTexture`) bleibt im Code |

## 4. Palette

Nur diese Farben verwenden (kleine Abweichungen für Zwischentöne ok). Gruppen von dunkel nach hell.

| Gruppe | Farben | Verwendung |
|---|---|---|
| Umriss | `#21131e` | alle Umrisse, tiefste Schatten |
| Stein | `#2b2638` `#4c5262` `#766967` `#928778` `#a59c8d` | Wände, Boden, Esse, Ofen |
| Holz | `#473238` `#5f4342` `#8c6552` `#a68062` | Balken, Werkbank, Fässer, Griffe |
| Eisen / Schiefer | `#363d51` `#626f81` `#78828b` `#9ba3ac` | Amboss, Werkzeug, Beschläge, Dach |
| Leder / Stoff | `#6c4f4d` `#8f5e61` | Schürze, Säcke, Blasebalg |
| Glut / Feuer | `#4d0f2c` `#8b1e28` `#ad4337` `#e0703a` `#f5b84a` `#ffe9a0` | Feuer, glühendes Metall, Lichtschein |
| Magie (nur Magie!) | `#1b2d60` `#144cad` `#0390fc` `#28cffc` `#80eefe` | Runen, Kristalle, Portal |
| Wasser | `#1b2d60` `#2f5b7a` `#4f8fa8` | Wassertrog, Brunnen |

Faustregel: Wärme kommt nur aus Feuer, Kühle nur aus Magie und Wasser. Die Umgebung bleibt gedeckt, damit Feuer und Magie hervorstechen.

## 5. PixelLab-Einstellungen

Für alle Objekte gleich:

- **view:** `high top-down` · **outline:** `single color outline` · **shading:** `medium shading` · **detail:** `medium detail`
- **Größe:** wie in Abschnitt 3, ohne spätere Skalierung
- Prompt = Objektbeschreibung + Stil-Anhang:

> `..., medieval fantasy blacksmith, hand-made, stone and dark wood, wrought iron, no technology, cozy, pixel art, dark purple-brown outline, light from top left`

Magische Objekte zusätzlich: `glowing blue runes` bzw. `glowing cyan crystal`.

Wo möglich das Schmiedehaus als Stil-Referenz (style image) mitgeben.

## 6. Die Schmiede (Innenraum)

Kleiner, gemütlicher Raum, der komplett ins Bild passt (Bildschirm 640×360).

- **Bodenfläche:** 310×155 px (10×5 Platten à 31 px), dunkle, grob behauene Steinplatten. Umgesetzt als ein Hintergrundbild `assets/sprites/rooms/smithy_room.png`.
- **Rückwand:** 48 px hoch, Steinmauer mit Holzbalken (wie das Schmiedehaus), daran Werkzeug, ein Fenster mit warmem Licht, ein Wappenschild (Ritter-Bezug).
- **Seiten-/Vorderwand:** schmale Mauerkrone (16 px).
- **Magischer Akzent:** eine Rune über der Esse, die schwach blau leuchtet (Hinweis auf Verzaubern später).

```
 ┌──────────────────── Rückwand (Werkzeug, Fenster, Wappen) ───────────────────┐
 │  Werkbank          Esse (Rune)              Schmelzofen      Kohle/Holz    │
 │                                                                            │
 │  Fass                       Amboss        Wassertrog                       │
 │                                                                            │
 │  Säcke                                                          Tür ↓      │
 └────────────────────────────────────────────────────────────────────────────┘
```

Arbeitsweg: Ofen → Esse → Amboss → Trog → Werkbank liegen nah beieinander, der Weg zwischen ihnen ist kurz.
