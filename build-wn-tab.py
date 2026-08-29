#!/usr/bin/env python3
"""Regenerates datasets/wn-data-jpn.tab as the UNION of two real sources:

1. jpn/jpnwn.xml — the official NICT Japanese WordNet (WN-LMF, omw-data
   v1.3 release): ALL 57,184 synsets carry their real Japanese glosses.
   The omw-data main-branch flat file only carries definitions for a
   subset of synsets (~26k), which is why 東京's synset (08923348-n) had
   no gloss in it and no concept-linked sense could exist.

2. The existing omw-data flat tab's eng:def / eng:exe rows (real English
   glosses, preserved so the importer still creates the English senses it
   already created).

Output uses the exact flat-tab format the WordNet importer parses:
    # Japanese Wordnet\tjpn\thttp://nlpwww.nict.go.jp/wn-ja/\twordnet
    <offset>-<pos>\tjpn:lemma\t<word>
    <offset>-<pos>\tjpn:def\t<idx>\t<definition>
    <offset>-<pos>\teng:def\t<idx>\t<definition>
    <offset>-<pos>\tjpn:exe\t<idx>\t<example>

This is a format conversion of real data only — no invented glosses.
Idempotent: re-running produces the same file.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent / "LinguaMundi" / "lingua-mundi"
DATASETS = REPO / "datasets"
JPNWN = Path(__file__).resolve().parent / ".tmp-wn" / "jpn" / "jpnwn.xml"
OUT = DATASETS / "wn-data-jpn.tab"

if not JPNWN.exists():
    sys.exit(f"jpnwn.xml not found at {JPNWN} — download omw-data v1.3 jpn.tar.xz first.")

xml = JPNWN.read_text(encoding="utf-8")

# ---- 1. Parse jpnwn.xml ----
lemma_rows: set[tuple[str, str]] = set()          # (offset_pos, lemma)
jpn_defs: dict[str, list[str]] = {}
jpn_exes: dict[str, list[str]] = {}
synset_pos: dict[str, str] = {}                   # offset_pos -> partOfSpeech

# LexicalEntry blocks: <Lemma writtenForm=.../> + <Sense synset="jpnwn-XXXX-n"/>
for m in re.finditer(
    r"<LexicalEntry[^>]*>\s*<Lemma writtenForm=\"([^\"]*)\"[^>]*/>\s*<Sense[^>]*synset=\"jpnwn-([^\"]+)\"",
    xml,
):
    lemma, synset_id = m.group(1), m.group(2)
    if lemma:
        lemma_rows.add((synset_id, lemma))

# Synset blocks: <Synset id="jpnwn-XXXX-n" partOfSpeech="n"> <Definition ...>...</Definition> <Example ...>...</Example>
for m in re.finditer(r"<Synset id=\"jpnwn-([^\"]+)\"([^>]*)>(.*?)</Synset>", xml, re.S):
    offset_pos = m.group(1)
    attrs = m.group(2)
    pos_m = re.search(r'partOfSpeech="([^"]+)"', attrs)
    synset_pos[offset_pos] = pos_m.group(1) if pos_m else "?"
    block = m.group(3)
    defs = re.findall(r"<Definition[^>]*>(.*?)</Definition>", block, re.S)
    jpn_defs.setdefault(offset_pos, []).extend(d.strip() for d in defs if d.strip())
    exes = re.findall(r"<Example[^>]*>(.*?)</Example>", block, re.S)
    jpn_exes.setdefault(offset_pos, []).extend(e.strip() for e in exes if e.strip())

# ---- 2. Read the existing omw-data flat tab (preserve eng rows + any extra lemmas/defs) ----
eng_defs: dict[str, list[str]] = {}
eng_exes: dict[str, list[str]] = {}
if OUT.exists():
    with OUT.open(encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            kind = parts[1]
            if kind == "jpn:lemma":
                lemma_rows.add((parts[0], parts[2]))
            elif kind == "jpn:def" and len(parts) >= 4:
                jpn_defs.setdefault(parts[0], []).append(parts[3])
            elif kind == "eng:def" and len(parts) >= 4:
                eng_defs.setdefault(parts[0], []).append(parts[3])
            elif kind == "jpn:exe" and len(parts) >= 4:
                jpn_exes.setdefault(parts[0], []).append(parts[3])
            elif kind == "eng:exe" and len(parts) >= 4:
                eng_exes.setdefault(parts[0], []).append(parts[3])

# ---- 3. Dedupe lists preserving order ----
def uniq(items):
    seen = set()
    out = []
    for it in items:
        if it not in seen:
            seen.add(it)
            out.append(it)
    return out

for d in (jpn_defs, eng_defs, jpn_exes, eng_exes):
    for k in d:
        d[k] = uniq(d[k])

# ---- 4. Write the merged flat tab ----
lines = ["# Japanese Wordnet\tjpn\thttp://nlpwww.nict.go.jp/wn-ja/\twordnet"]
for offset_pos, lemma in sorted(lemma_rows):
    lines.append(f"{offset_pos}\tjpn:lemma\t{lemma}")
for offset_pos, defs in sorted(jpn_defs.items()):
    for i, d in enumerate(defs):
        lines.append(f"{offset_pos}\tjpn:def\t{i}\t{d}")
for offset_pos, defs in sorted(eng_defs.items()):
    for i, d in enumerate(defs):
        lines.append(f"{offset_pos}\teng:def\t{i}\t{d}")
for offset_pos, exes in sorted(jpn_exes.items()):
    for i, e in enumerate(exes):
        lines.append(f"{offset_pos}\tjpn:exe\t{i}\t{e}")
for offset_pos, exes in sorted(eng_exes.items()):
    for i, e in enumerate(exes):
        lines.append(f"{offset_pos}\teng:exe\t{i}\t{e}")

OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

# ---- 5. Report ----
n_lemmas = len(lemma_rows)
n_jpndef = sum(len(v) for v in jpn_defs.values())
n_engdef = sum(len(v) for v in eng_defs.values())
n_jpnexe = sum(len(v) for v in jpn_exes.values())
n_engexe = sum(len(v) for v in eng_exes.values())
print(f"wrote {OUT}")
print(f"  jpn:lemma rows: {n_lemmas}")
print(f"  jpn:def rows:   {n_jpndef} (synsets with jpn defs: {len(jpn_defs)})")
print(f"  eng:def rows:   {n_engdef} (synsets with eng defs: {len(eng_defs)})")
print(f"  jpn:exe rows:   {n_jpnexe}")
print(f"  eng:exe rows:   {n_engexe}")
print(f"  東京 present: {'08923348-n' in jpn_defs} -> {jpn_defs.get('08923348-n')}")
