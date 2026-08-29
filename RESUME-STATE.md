# RESUME STATE — Shikibu 1.0.0 emergency release-repair (linguistic-core)

> Durable checkpoint. If the machine rebooted, read this file FIRST and re-run
> whatever the "CURRENT STATE" section says is in progress/pending. All commands
> are exact. Everything marked DONE is already verified and survives reboot
> (files on disk + committed Postgres data).
>
> **AUTOMATED CONTINUATION:** `finish-release.sh` (workspace root) deterministically
> does the rest — waits for/re-runs the import, re-exports the Pro DB, verifies
> `build:pro`, runs all DB tests, assembles the ZIP, and logs to `release-run.log`.
> It is safe to re-run at any point. If the machine rebooted, just re-launch it:
> `bash "/home/rex/Documentos/Software Development/DeepSeek Harness/finish-release.sh"`.

Workspace root: `/home/rex/Documentos/Software Development/DeepSeek Harness`
Project: `Shikibu/` (the app), `LinguaMundi/lingua-mundi/` (Python repo + venv),
`lingua-mundi/` (empty dir that holds the final Pro DB export).

---

## CURRENT STATE (updated 2026-08-24 21:06)

- [DONE] linguistic-core reconstructed at `Shikibu/linguistic-core/`
  (src + prebuilt dist + README + scripts). Package `file:./linguistic-core`.
- [DONE] `Shikibu/package.json` fixed (`file:./linguistic-core`), lockfile fixed
  (no `../linguistic-core` anywhere), `Shikibu/.npmrc` has `legacy-peer-deps=true`.
- [DONE] Clean-machine npm install verified (no broken symlinks), Free build
  `npm run build` verified, non-DB tests all green:
  dictionary 14/14, annotation 14/14, epubcheck-import 13/13, real-epub 31/31,
  new-features 13/13, full-book 62 chapters 0 issues.
- [IN PROGRESS] FULL Lingua Mundi import into Postgres
  (`import_job` rows are only committed per-plugin, so check
  `SELECT name, status, log FROM import_job JOIN dataset ... ORDER BY started_at DESC`
  to see which sources already committed). Started ~20:58. Sources to confirm:
  JMdict, KANJIDIC2, Japanese WordNet, EJDict, J-UniMorph must all show
  `success` with real row counts. The other 5 registry plugins (Princeton
  WordNet/omw-en, Japanese Wiktionary, Wikidata, Spanish/English UniMorph)
  FAIL gracefully (their dataset files were never provided — expected, not a
  blocker for the Japanese module).
  Verify completeness with:
  `psql -h localhost -p 5433 -U rex -d lingua_mundi -c "SELECT name, version FROM source;"` (sources)
  `psql -h localhost -p 5433 -U rex -d lingua_mundi -c "SELECT (SELECT count(*) FROM lexeme) lexemes, (SELECT count(*) FROM reading) readings, (SELECT count(*) FROM sense) senses, (SELECT count(*) FROM word_form) word_forms, (SELECT count(*) FROM kanji_detail) kanji_detail;"`
  Expect: lexemes ~276k+, readings ~301k+, senses ~311k+ (should GROW from
  previous values once WordNet/EJDict/J-UniMorph commit), word_forms >= 12,687,
  kanji_detail >= 13,033. WordNet synsets should be ~50k+ (was 605 before!):
  `SELECT count(*) FROM synset;`
- [DONE] Pro DB export COMPLETED IN PLACE after reboot (finish-export.py): entries 268,185 =
- [PENDING] build:pro verification (step B).
- [PENDING] DB-dependent tests (step C).
- [PENDING] ZIP assembly + final clean check (step D).

---

## ENVIRONMENT FACTS (must-know quirks)

- Postgres: `localhost:5433`, user `rex` (no password), DB `lingua_mundi`.
  URL: `postgresql+psycopg2://rex@localhost:5433/lingua_mundi`
- Python venv: `LinguaMundi/lingua-mundi/venv/bin/python` (python3.12).
  PITFALL: `venv/bin/pip` is a STALE wrapper hardcoding the OLD read-only path
  (`/home/rex/Documentos/Software Development/LinguaMundi/...`). NEVER use
  `venv/bin/pip` — always `PIP_CACHE_DIR=<workspace>/.pip-cache venv/bin/python -m pip ...`.
- lxml already installed into the venv (needed by kanjidic importer).
- npm cache is read-only at `/home/rex/.npm` → always pass
  `--cache "/home/rex/Documentos/Software Development/DeepSeek Harness/.npm-cache"`.
- `npm install` needs the project `.npmrc` (legacy-peer-deps=true) — already in Shikibu/.
- Real datasets were copied into `LinguaMundi/lingua-mundi/datasets/`:
  jmdict-all.json (260MB), kanjidic2.xml, wn-data-jpn.tab, wnjpn-all.tab
  (unzipped from wnjpn-all.tab.zip), ejdic-hand-txt/, J-UniMorph-main/.
  **WordNet gotcha (fixed 2026-08-24 23:35):** the delivered
  `Carpeta sin título/.../wn-data-jpn.tab` (29.5MB) was actually the CONFIDENCE
  file (wnjpn-all.tab) misnamed — real wn-data-jpn.tab is ~9.2MB with
  `jpn:lemma` rows, downloaded from
  `https://raw.githubusercontent.com/omwn/omw-data/main/wns/jpn/wn-data-jpn.tab`.
  One junk trailing line (`11171513`) was stripped from it; the misnamed
  original is kept as `wn-data-jpn.tab.confidence-duplicate`.
  **WordNet gloss gap (fixed 2026-08-25 ~05:00):** the omw-data main-branch
  flat tab only carries jpn/eng defs for ~26k of 158k lemma-synsets —
  東京's synset (08923348-n) had no gloss, so no concept-linked sense could
  exist and tests/local-lingua-mundi.test.ts's "concept-linked sense" check
  failed. `build-wn-tab.py` (workspace root) regenerates the tab as the UNION
  with the official NICT Japanese WordNet (`jpnwn.xml`, omw-data v1.3
  jpn.tar.xz — all 57k synsets have real glosses), kept at
  `.tmp-wn/jpn/jpnwn.xml`. finish-release.sh re-runs the WordNet importer +
  populate_concepts when synset_member < 100k.
- DB performance indexes already created on Postgres (ix_lexeme_lang_lemma,
  ix_reading_lexeme, ix_word_form_lexeme, ix_kanji_detail_lexeme,
  ix_sense_lexeme, ix_synset_member_sense).

---

## REMAINING STEPS (exact commands)

### A. Re-export the complete Pro DB (AFTER import finishes)
The import is single-commit per plugin; run this only after the last source
commits. Deletes any stale partial file first.

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
rm -f lingua-mundi/lingua-mundi-jpn.sqlite lingua-mundi/lingua-mundi-jpn.sqlite-journal
cd "LinguaMundi/lingua-mundi"
DATABASE_URL="postgresql+psycopg2://rex@localhost:5433/lingua_mundi" \
  venv/bin/python scripts/export_sqlite.py \
  "/home/rex/Documentos/Software Development/DeepSeek Harness/lingua-mundi/lingua-mundi-jpn.sqlite" --language jpn
```
Expect: "Wrote ... (NNN MB)" with entries ~276k and surface_forms >= 12,687.
(If the machine rebooted mid-export, the partial file is invalid — delete and rerun.)

### B. Verify Pro build
```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness/Shikibu"
npm run build:pro
# then confirm the DB made it into the bundle:
ls -la dist/lingua-mundi-jpn.sqlite
```

### C. Run the DB-dependent real-data tests
```bash
DB="/home/rex/Documentos/Software Development/DeepSeek Harness/lingua-mundi/lingua-mundi-jpn.sqlite"
EPUB="/home/rex/Documentos/薬屋のひとりごと１.epub"
cd "/home/rex/Documentos/Software Development/DeepSeek Harness/Shikibu"
npx tsx tests/local-lingua-mundi.test.ts "$DB"
npx tsx tests/free-pro-distinction.test.ts "$DB"
npx tsx tests/auto-ruby.test.ts "$DB"
npx tsx tests/glossary-enrichment.test.ts "$DB"
npx tsx tests/linguistic-search.test.ts "$EPUB" "$DB"
npx tsx tests/publisher-qa.test.ts "$EPUB" "$DB"
npx tsx tests/ruby-inspector-consistency.test.ts "$EPUB" "$DB"
npx tsx tests/epub-safety-auto-ruby.test.ts "$EPUB" "$DB"
npm run test:local-db   # documented script (uses ../lingua-mundi/... path)
```
Also re-run the non-DB suite for completeness:
`npm test -- "$EPUB"`, `npx tsx tests/dictionary.test.ts`, `npx tsx tests/annotation.test.ts`,
`npx tsx tests/epubcheck-import.test.ts`, `npx tsx tests/new-features.test.ts "$EPUB"`,
`npx tsx tests/full-book.test.ts "$EPUB"`.

### D. Assemble the self-contained ZIP + final clean-machine check
ZIP layout (top level): `Shikibu/` and `lingua-mundi/lingua-mundi-jpn.sqlite`.
`Shikibu/../lingua-mundi/lingua-mundi-jpn.sqlite` is what bundle-local-db.mjs
expects by default. Exclude generated artifacts:

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
rm -rf .deliverable-test
mkdir -p .deliverable-test
# copy Shikibu minus node_modules/dist/tsbuildinfo
tar --exclude=./node_modules --exclude=./dist --exclude=./tsconfig.tsbuildinfo -C Shikibu -cf - . | tar -C .deliverable-test -xf -
# place the DB sibling
mkdir -p .deliverable-test/lingua-mundi
cp lingua-mundi/lingua-mundi-jpn.sqlite .deliverable-test/lingua-mundi/
# clean-machine verification
cd .deliverable-test/Shikibu
npm install --no-audit --no-fund --cache "/home/rex/Documentos/Software Development/DeepSeek Harness/.npm-cache"
npm run build
npm run build:pro
ls -la dist/lingua-mundi-jpn.sqlite
find node_modules -xtype l   # must print nothing
# final zip
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
zip -r "Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip" Shikibu/ lingua-mundi/ \
  -x "Shikibu/node_modules/*" "Shikibu/dist/*" "Shikibu/tsconfig.tsbuildinfo" "Shikibu/.deliverable-test/*"
```

### E. Final report (required format)
Report ONLY: (1) what was reconstructed from old linguistic-core; (2) what
current Shikibu required that was missing/outdated; (3) where the package
lives; (4) final dependency path/config; (5) exact install command
(`npm install` from Shikibu/, with the shipped .npmrc); (6) Free build
(`npm run build`); (7) Pro build (`npm run build:pro`); (8) test results;
(9) any remaining blocker.

---

## ALREADY-VERIFIED DETAILS (don't redo unless the files changed)

- `Shikibu/linguistic-core/dist/` is ESM-safe (raw `node import('linguistic-core')` works).
- `node_modules/linguistic-core` symlinks to `../linguistic-core` inside Shikibu — resolves.
- Free build output: dist/index.html + assets (vite 8.2.2, 400 modules).
- Non-DB tests passed as listed in CURRENT STATE.

---

## LIVE DEMO STATE (2026-08-25, post-deadline demo session)

SUPERSEDED (2026-08-26): all products are now permanently hosted on GitHub
Pages — the ephemeral quick tunnels were shut down. Do NOT recreate them.

Background jobs: bash-31 (dashboard dev), bash-32 (Shikibu dev), bash-20
(landing http.server), bash-27/28/29/30 (cloudflared tunnels).

Shikibu fixes applied (2026-08-25): wasm cache-bust + retry-once in
getSqlJs (LocalLinguaMundiProvider), pre-warm offline DB on app mount
(App.tsx), search modal error handling (LinguisticSearchModal). ZIP
refreshed: Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip (36.2 MB).
Demo book: /home/rex/Documentos/Software Development/DeepSeek Harness/走れメロス.epub
(plain text, no ruby — Aozora Bunko, PD).
Clerk allowed_origins now includes the dashboard tunnel URL.
