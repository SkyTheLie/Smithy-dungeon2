# SPRACHEN_TODO.md – Sprachen, die noch fehlen

Fertig: Deutsch (Original), Englisch, Spanisch, Französisch, Chinesisch (vereinfacht), Persisch, Russisch (2026-11-23, Schrift `tiny5_cyrillic.ttf`), Japanisch (2026-11-24, Schrift `fusion_pixel_12px_ja.ttf`), Portugiesisch/Brasilien (2026-11-24, nur Micro 5), Koreanisch (2026-11-24, Hangul aus `fusion_pixel_12px_zh_hans.ttf`), Polnisch (2026-11-24, nur Micro 5).
Ablauf für eine neue Sprache: `docs/SPRACHEN.md` » „Neue Sprache“. Name im Menü steht schon in `Language.NAMES` (außer traditionellem Chinesisch). Jede Sprache braucht außerdem eine Flagge `assets/ui/flags/<code>.png` und ein Glossar `assets/_reference/i18n/glossary_<code>.md`.
Erledigte Sprachen hier löschen und in `docs/SPRACHEN.md` unter „Stand“ eintragen.

| Reihenfolge | Sprache | Code | Warum | Aufwand außer Übersetzung |
|---|---|---|---|---|
| 1 | Türkisch | `tr` | stark auf dem Handy | prüfen, ob Micro 5 ş ğ ı İ hat |
| 2 | Italienisch | `it` | mittelgroßer Markt | keiner |
| 3 | Chinesisch (traditionell) | `zh_TW` | Taiwan, Hongkong | aus `zh.po` ableiten, Fusion Pixel `zh_hant`, Eintrag in `Language.NAMES` |
| – | Niederländisch | `nl` | wenig Bedarf (spielen meist Englisch) | eher weglassen |

Übersetzen mit `translate_agy.py <code>` (agy/Gemini). Ist das agy-Kontingent leer, übersetzt Claude selbst (so bei Persisch, Russisch, Koreanisch und Polnisch).
