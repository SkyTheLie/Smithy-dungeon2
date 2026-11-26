"""Builds locale/<lang>.po from assets/_reference/i18n/translations.json and checks that every
German text of the game has a translation.

Usage (from the project folder):  py assets/_reference/i18n/build_po.py
Exit code 1 if a text is missing in translations.json or a language is missing for a text.

Texts it finds by itself:
  - "text" and "title" of Labels/Buttons in .tscn files (only those with auto translate on)
  - Language.translate("...") in .gd files
  - "name" and "desc" in data/items.json, data/synergies.json, data/enemies.json, data/characters.json, materials in data/loot.json, theme "name" in floors.json,
    "name"/"region"/"desc" in data/dungeons.json
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TRANSLATIONS = os.path.join(ROOT, "assets", "_reference", "i18n", "translations.json")
LANGUAGES = ["en", "es", "fr", "pt", "ru", "ja", "zh", "fa"]
# Texts in scenes that are not meant to be translated (names, numbers).
IGNORE = {"Smithy", "00"}


def find_texts():
    texts = set()
    for folder in ("scenes", "scripts"):
        for base, _dirs, files in os.walk(os.path.join(ROOT, folder)):
            for name in files:
                path = os.path.join(base, name)
                content = open(path, encoding="utf-8").read()
                if name.endswith(".tscn"):
                    for block in content.split("\n[node "):
                        if "auto_translate_mode = 2" in block:
                            continue
                        for match in re.finditer(r'^(?:text|title) = "((?:[^"\\]|\\.)*)"', block, re.M):
                            texts.add(match.group(1))
                elif name.endswith(".gd"):
                    for match in re.finditer(r'Language\.translate\("((?:[^"\\]|\\.)*)"', content):
                        texts.add(match.group(1))
    data = os.path.join(ROOT, "data")
    for file, key in (("items.json", "items"), ("synergies.json", "synergies"), ("enemies.json", "enemies"), ("characters.json", "characters")):
        entries = json.load(open(os.path.join(data, file), encoding="utf-8"))[key]
        for entry in entries.values():
            for field in ("name", "desc"):
                if entry.get(field):
                    texts.add(entry[field])
    loot = json.load(open(os.path.join(data, "loot.json"), encoding="utf-8"))
    for entry in loot["materials"].values():
        for field in ("name", "desc"):
            if entry.get(field):
                texts.add(entry[field])
    dungeons = json.load(open(os.path.join(data, "dungeons.json"), encoding="utf-8"))
    for entry in dungeons["dungeons"].values():
        for field in ("name", "region", "desc"):
            if entry.get(field):
                texts.add(entry[field])
    floors = json.load(open(os.path.join(data, "floors.json"), encoding="utf-8"))
    for theme in floors.get("themes", {}).values():
        texts.add(theme["name"])
    for floor in floors["floors"]:
        if floor.get("name"):
            texts.add(floor["name"])
    return {t for t in texts if t and t not in IGNORE}


def escape(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def main():
    table = json.load(open(TRANSLATIONS, encoding="utf-8"))
    table.pop("_info", None)
    problems = []
    for text in sorted(find_texts()):
        if text not in table:
            problems.append("missing in translations.json: " + text)
            continue
        for lang in LANGUAGES:
            if not table[text].get(lang):
                problems.append("missing %s: %s" % (lang, text))
    for lang in LANGUAGES:
        lines = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', '"Language: %s\\n"' % lang, ""]
        for text in sorted(table):
            translation = table[text].get(lang, "")
            lines += ['msgid "%s"' % escape(text), 'msgstr "%s"' % escape(translation), ""]
        with open(os.path.join(ROOT, "locale", lang + ".po"), "w", encoding="utf-8", newline="\n") as out:
            out.write("\n".join(lines))
    for problem in problems:
        print(problem)
    print("%d texts, %d languages written, %d problems" % (len(table), len(LANGUAGES), len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
