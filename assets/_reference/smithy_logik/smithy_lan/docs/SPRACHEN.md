# SPRACHEN.md – Smithy in mehreren Sprachen

> Deutsch ist die Originalsprache. Spieltexte im Code, Dokus, JSON-Inhalte und Szenen bleiben auf Deutsch (Bezeichner und Kommentare im Code sind Englisch, `PROJEKT.md` Abschnitt 4).
> Jede weitere Sprache ist **eine Datei** `locale/<code>.po` (z. B. `en.po`, später `es.po`).

## Wie es funktioniert

- **Der deutsche Text ist der Schlüssel.** In der `.po`-Datei steht pro Text `msgid "Deutscher Text"` und `msgstr "Übersetzung"`. Fehlt eine Übersetzung (oder ist sie leer), zeigt das Spiel den deutschen Text.
- **Sprache wählen:** Einstellungen » Grafik » Sprache (`Language`, gespeichert in `user://settings.cfg`, Abschnitt `language`). Beim ersten Start: Systemsprache, falls es eine Datei dafür gibt, sonst Englisch, sonst Deutsch.
- **Oberfläche:** Labels und Knöpfe übersetzen ihren Text selbst (Godot „auto translate“). Ein deutscher Text, der ganz in ein Label kommt, braucht also nichts weiter.
- **Zusammengesetzte Texte im Code** (mit `%`): erst übersetzen, dann einsetzen: `Language.translate("Du nimmst %d Gold aus der Kasse.") % gold`. Nicht `"..." % gold` direkt in ein Label, sonst passt der fertige Satz zu keinem Schlüssel.
- **Inhalte aus `data/content/*.json`** (Items, Story, Skills ...) übersetzt `ContentDB` beim Laden einmal ganz (`Language.translate_data`). Im Hauptmenü lädt ein Sprachwechsel deshalb alles neu (`Language.reload_content`, `ContentDB.reload`, Menü wird neu aufgebaut); in einem laufenden Spiel wirkt er bei Inhalten erst nach einem Neustart (die Einstellungen sagen das).
- **Text-Felder von Ressourcen/Knoten** (`display_name`, `description`, `title`, `greeting` ...) haben einen Getter, der übersetzt (`add_text_getters.py`). Neue Text-Felder genauso anlegen:
  `@export var display_name: String = "":` / `get:` / `return Language.translate(display_name)`.
- **Text im Code:** deutsche Texte, die nicht ganz in ein Label gehen, immer als `Language.translate("...")` schreiben. Text-Tabellen in `const` bleiben deutsch, beim Lesen übersetzen: `Language.translate(ItemData.PART_TYPE_NAMES[t])`.
- **Prüfen:** `py assets/_reference/i18n/audit_german.py --list` zeigt deutsche Texte im Code, die noch nicht übersetzt würden (übrig sein dürfen nur interne Namen und die const-Tabellen selbst). Nachrüsten automatisch: `wrap_literals.py`, `wrap_const_reads.py`, `wrap_format_strings.py` (danach headless `test_language.gd`).
- Mit Text zusammengeklebte Stücke (`"Gold: " + str(x)`) und selbst gezeichnete Texte (`draw_string`) werden **nicht** übersetzt: Solche Stellen auf `Language.translate("Gold: %d") % x` umbauen, wenn sie auffallen.
- **Gleiche Wörter, zwei Bedeutungen:** Ein deutscher Text hat nur eine Übersetzung. Darum die Tafeln „Mietschild“ und „Warnschild“ statt „Schild“ (= Rüstungsschild). Bei neuen Texten auf so etwas achten.

## Neue oder geänderte Texte übersetzen

Aus `D:/Smithy/Smithy`:

1. `py assets/_reference/i18n/extract_po.py en` – sammelt alle Texte (JSON, Szenen, `.tres`, deutsche Literale im Code) und aktualisiert `locale/en.po`. Bestehende Übersetzungen bleiben; geänderte deutsche Texte sind danach leer (= wieder Deutsch im Spiel), weggefallene landen als `#~` am Ende.
2. `py assets/_reference/i18n/translate_agy.py en` – schickt alle leeren Einträge in Paketen an agy (Google AI) und schreibt nur Übersetzungen zurück, deren Platzhalter (`{name}`, `%d`, `[b]` ...) stimmen. Begriffe und Sprechstil: `assets/_reference/i18n/glossary_en.md`. Optionen: `--only story.json`, `--limit 2`, `--model gemini-4-argon-medium`, `--parallel 3`.
3. Stichproben im Spiel ansehen (Sprache auf Englisch, neu starten).

Einzelne Übersetzungen kann man auch direkt in der `.po`-Datei verbessern (z. B. mit Poedit oder im Texteditor): Sie bleiben bei späteren Läufen erhalten.

**Fehlt etwas trotz „alles übersetzt“?** Der Sammler sieht nur, was er kennt: Am 2026-10-31 fehlten alle 150 Tipp-Texte (Block `hints`), `extract_po.py` liest sie jetzt mit. Prüfen im laufenden Spiel statt in der Datei: jeden Text aus `data/content/*.json` durch `TranslationServer.translate` schicken und auflisten, was gleich bleibt.

## Korrektur lesen

`py assets/_reference/i18n/proofread_agy.py en --out <datei.json>` lässt Original und Übersetzung von agy (Argon) auf echte Fehler prüfen und ändert nichts. Die Vorschläge selbst durchsehen (am 2026-11-01 wollte Argon die Seltenheit „Solide“ durch „Ungewöhnlich“ ersetzen), dann `apply_proofread.py en <datei.json> --skip <abgelehnt.json>` und `extract_po.py en`. Deutsche Korrekturen werden in allen Quellen ersetzt, die Übersetzung bleibt dran.

## Neue Sprache (z. B. Spanisch)

1. `assets/_reference/i18n/glossary_en.md` nach `glossary_es.md` kopieren und die Begriffe auf Spanisch umstellen (am besten von agy entwerfen lassen und prüfen).
2. `py assets/_reference/i18n/extract_po.py es` und `py assets/_reference/i18n/translate_agy.py es`.
3. Fertig: Die Sprache taucht von selbst in den Einstellungen auf (`Language.get_available()` sucht `locale/*.po`). Der Name im Menü steht in `Language.NAMES`.
4. Schriften: Die Pixel-Schrift `micro5.ttf` kann nur lateinische Zeichen. Was ihr fehlt, kommt aus den Ersatzschriften in `Language.FALLBACK_FONTS` (an die Theme-Schrift gehängt in `Language.add_font_fallbacks`). Für Chinesisch: `assets/fonts/fusion_pixel_12px_zh_hans.ttf` (Fusion Pixel Font, OFL, die „ms.bitmap.ttf“-Variante mit eingebetteten Bitmaps, Import mit `disable_embedded_bitmaps=false`): feste Pixelgröße 12, nur ganzzahlig skaliert, dadurch bei 9–16 scharf, bei 22/44 doppelt/dreifach. Japanisch/Koreanisch: dieselbe Schrift gibt es als `ja`/`ko`. Kyrillisch braucht eine eigene Pixel-Schrift.
5. Sprachen ohne Leerzeichen (Chinesisch, Japanisch): Zeilenumbruch über die ICU-Daten des Text-Servers, deshalb `internationalization/locale/include_text_server_data=true` (sonst bricht ein exportiertes Spiel solche Texte nicht um).

## Stand

- Spanisch und Französisch: `locale/es.po`, `locale/fr.po`, alle Einträge gefüllt (2026-11-10, Argon, die letzten ~5 % mit gemini-3.8-flash-high, weil das Argon-Wochenlimit erreicht war), Glossare `glossary_es.md` / `glossary_fr.md`, noch nicht im Spiel durchgesehen. Prüfung zur Laufzeit: `test_es_fr.gd` (headless). Französisch: nach jedem `translate_agy.py fr` noch `py assets/_reference/i18n/fr_nbsp.py` (geschützte Leerzeichen vor `! ? : ;` und in `« »`).
- Chinesisch (vereinfacht): `locale/zh.po`, mit Argon übersetzt (2026-11-09), Glossar `glossary_zh.md`, noch nicht im Spiel durchgesehen.
- Englisch: `locale/en.po`, alle Einträge gefüllt (2026-10-31), noch nicht im Spiel durchgesehen.
- Bekannte Lücken: per `+` zusammengesetzte Texte im Code (Suche 2026-10-31 fand keine auffälligen mehr); `draw_string` nutzt übersetzte Texte, der Kompass zeigt den ersten Buchstaben der übersetzten Himmelsrichtung. Interne Richtungen `N/O/S/W` nie übersetzen.
