#!/usr/bin/env bash
# finish-release.sh — deterministic continuation of the Shikibu release-repair.
# Safe to re-run at any point (imports are idempotent get-or-create, export/build
# overwrite, ZIP overwrites). Logs everything to release-run.log next to it.
# Exit 0 = release assembled; non-zero = something failed (see log tail).
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/release-run.log"
DBDIR="$ROOT/lingua-mundi"
DB="$DBDIR/lingua-mundi-jpn.sqlite"
REPO="$ROOT/LinguaMundi/lingua-mundi"
SHIKIBU="$ROOT/Shikibu"
EPUB="/home/rex/Documentos/薬屋のひとりごと１.epub"
export DATABASE_URL="postgresql+psycopg2://rex@localhost:5433/lingua_mundi"
export NPM_CONFIG_CACHE="$ROOT/.npm-cache"
export PIP_CACHE_DIR="$ROOT/.pip-cache"
PSQL="psql -h localhost -p 5433 -U rex -d lingua_mundi -tA"
PY="$REPO/venv/bin/python"

say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }
die() { say "FATAL: $*"; exit 1; }

# ---------- 1. Ensure the full Japanese-module import is done ----------
wait_for_import() {
  # Count DISTINCT sources with a success job — a source can legitimately
  # have more than one success row (e.g. the WordNet re-import after the
  # gloss fix), so "=" on total rows is wrong; distinct names must be 5.
  local names="('JMdict','KANJIDIC2','Japanese WordNet','EJDict','J-UniMorph')"
  for i in $(seq 1 360); do   # up to ~3h
    local done
    done=$($PSQL -c "SELECT count(DISTINCT d.name) FROM import_job j JOIN dataset d ON d.id=j.dataset_id WHERE d.name IN $names AND j.status='success' AND j.started_at > '2026-08-24 20:00';" 2>/dev/null | head -1 | tr -d ' ')
    if [ "${done:-0}" -ge 5 ]; then say "All 5 Japanese sources imported (success)."; return 0; fi
    local conns
    conns=$($PSQL -c "SELECT count(*) FROM pg_stat_activity WHERE datname='lingua_mundi' AND pid<>pg_backend_pid() AND state IN ('active','idle in transaction');" 2>/dev/null | head -1 | tr -d ' ')
    if [ "${conns:-0}" = "0" ]; then
      say "No import process connected and ${done:-0}/5 sources done — import died (reboot?); re-running it."
      return 1
    fi
    say "Waiting on import ($done/5 sources committed)…"
    sleep 20
  done
  die "Timed out waiting for import completion."
}
cd "$ROOT"
say "=== finish-release.sh start ==="
attempt=0
while true; do
  if wait_for_import; then break; fi
  attempt=$((attempt + 1))
  if [ "$attempt" -gt 1 ]; then
    say "Import still incomplete after one re-run — aborting. Inspect import_job and release-run.log."
    exit 1
  fi
  say "Re-running full import pipeline (attempt $attempt)…"
  (cd "$REPO" && "$PY" scripts/run_import.py >>"$LOG" 2>&1)
  say "Import command finished (exit $?)."
done

# WordNet sanity: a real Japanese WordNet import populates ~60k synsets;
# the old sample left only 605. If it's still tiny, the import was hollow.
SYNSETS=$($PSQL -c "SELECT count(*) FROM synset;" 2>/dev/null | head -1 | tr -d ' ')
say "synset rows after import: ${SYNSETS:-?}"
if [ "${SYNSETS:-0}" -lt 10000 ]; then
  die "Japanese WordNet did not import (synset count ${SYNSETS:-0}); fix datasets and re-run."
fi

# ---------- 1a. Ensure WordNet glosses are complete ----------
# The omw-data main-branch flat tab only carries definitions for ~26k of
# 158k lemma-synsets (東京's synset 08923348-n has no gloss there), so
# senses/concepts for the rest never existed. Regenerate the flat tab as
# the UNION with the official NICT Japanese WordNet (jpnwn.xml, omw-data
# v1.3 — all 57k synsets have real glosses), then re-run the WordNet
# importer (idempotent) so every synset gains its real senses, then
# populate_concepts links them. Deterministic completeness signal:
# a complete WordNet yields >100k synset_member rows.
MEMBERS=$($PSQL -c "SELECT count(*) FROM synset_member;" 2>/dev/null | head -1 | tr -d ' ')
say "synset_member rows: ${MEMBERS:-?}"
if [ "${MEMBERS:-0}" -lt 100000 ]; then
  say "WordNet glosses incomplete (${MEMBERS:-0} members) — regenerating tab from official jpnwn.xml…"
  (cd "$ROOT" && python3 build-wn-tab.py >>"$LOG" 2>&1) || die "build-wn-tab.py failed"
  say "Re-running Japanese WordNet importer with complete gloss data…"
  (cd "$REPO" && "$PY" -c "
import importlib.util
spec = importlib.util.spec_from_file_location('run_import', 'scripts/run_import.py')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
from importers.registry import PLUGIN_REGISTRY
from api.db import SessionLocal
db = SessionLocal()
for plugin, path, lang in PLUGIN_REGISTRY:
    if plugin.source_name == 'Japanese WordNet':
        report = mod.run_plugin(plugin, path, lang, db)
        report.print_line()
        break
db.close()
" >>"$LOG" 2>&1) || die "WordNet re-import failed"
  MEMBERS=$($PSQL -c "SELECT count(*) FROM synset_member;" 2>/dev/null | head -1 | tr -d ' ')
  say "synset_member rows after re-import: ${MEMBERS:-?}"
  if [ "${MEMBERS:-0}" -lt 100000 ]; then
    die "WordNet re-import still produced only ${MEMBERS:-0} members."
  fi
fi

# ---------- 1b. Concept Graph population (Phase 3) ----------
# One Concept per WordNet Synset + link every member Sense's concept_id
# (what the export's `senses[].concept` and the local-db test rely on).
# Idempotent; skipped when the links are already in place (reboot-resume).
LINKED=$($PSQL -c "SELECT count(*) FROM sense WHERE concept_id IS NOT NULL;" 2>/dev/null | head -1 | tr -d ' ')
say "senses with concept links: ${LINKED:-?}"
if [ "${LINKED:-0}" -lt 180000 ]; then
  say "=== populate_concepts.py ==="
  (cd "$REPO" && "$PY" scripts/populate_concepts.py >>"$LOG" 2>&1) || die "populate_concepts.py failed"
  CONCEPTS=$($PSQL -c "SELECT count(*) FROM concept;" 2>/dev/null | head -1 | tr -d ' ')
  say "concept rows after populate_concepts: ${CONCEPTS:-?}"
  if [ "${CONCEPTS:-0}" -lt 10000 ]; then
    die "Concept population produced only ${CONCEPTS:-0} rows — expected tens of thousands."
  fi
else
  say "concept links already present — skipping populate_concepts.py."
fi

# ---------- 2. Ensure the complete Pro DB exists ----------
# The export is a single SQLite transaction; a machine reboot mid-run leaves
# a file that SQLite will roll back. If the file already has the full row
# counts AND passes integrity_check (e.g. it was completed in place by
# finish-export.py), reuse it; otherwise re-export from scratch.
say "=== Ensuring lingua-mundi-jpn.sqlite ==="
EXPECTED_ENTRIES=268185
EXPECTED_FORMS=15879
CUR_ENTRIES=$("$PY" -c "import sqlite3;print(sqlite3.connect('$DB').execute('SELECT count(*) FROM entries').fetchone()[0])" 2>/dev/null || echo 0)
CUR_FORMS=$("$PY" -c "import sqlite3;print(sqlite3.connect('$DB').execute('SELECT count(*) FROM surface_forms').fetchone()[0])" 2>/dev/null || echo 0)
CUR_OK=$("$PY" -c "import sqlite3;print(sqlite3.connect('$DB').execute('PRAGMA integrity_check').fetchone()[0])" 2>/dev/null || echo bad)
if [ "${CUR_ENTRIES:-0}" = "$EXPECTED_ENTRIES" ] && [ "${CUR_FORMS:-0}" = "$EXPECTED_FORMS" ] && [ "${CUR_OK:-bad}" = "ok" ]; then
  say "DB already complete (entries=$CUR_ENTRIES forms=$CUR_FORMS integrity=$CUR_OK) — skipping export."
else
  say "Exporting lingua-mundi-jpn.sqlite (entries=$CUR_ENTRIES forms=$CUR_FORMS integrity=$CUR_OK)…"
  rm -f "$DB" "$DB-journal"
  (cd "$REPO" && "$PY" scripts/export_sqlite.py "$DB" --language jpn >>"$LOG" 2>&1)
  [ -s "$DB" ] || die "Export produced no DB file."
  ENTRIES=$("$PY" -c "import sqlite3;print(sqlite3.connect('$DB').execute('SELECT count(*) FROM entries').fetchone()[0])" 2>/dev/null)
  FORMS=$("$PY" -c "import sqlite3;print(sqlite3.connect('$DB').execute('SELECT count(*) FROM surface_forms').fetchone()[0])" 2>/dev/null)
  say "Export OK: entries=$ENTRIES surface_forms=$FORMS"
  [ "${ENTRIES:-0}" -ge 200000 ] || die "Export too small (entries=$ENTRIES) — import likely incomplete."
fi

# ---------- 3. Pro build ----------
say "=== npm run build:pro ==="
(cd "$SHIKIBU" && npm run build:pro >>"$LOG" 2>&1) || die "build:pro failed"
[ -f "$SHIKIBU/dist/lingua-mundi-jpn.sqlite" ] && say "Pro build bundles the DB: $(ls -la "$SHIKIBU/dist/lingua-mundi-jpn.sqlite" | awk '{print $5}') bytes" || die "build:pro output missing lingua-mundi-jpn.sqlite"

# ---------- 4. Real-data tests ----------
say "=== DB-dependent tests ==="
(cd "$SHIKIBU" && npx tsx tests/local-lingua-mundi.test.ts "$DB" >>"$LOG" 2>&1) || die "local-lingua-mundi.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/free-pro-distinction.test.ts "$DB" >>"$LOG" 2>&1) || die "free-pro-distinction.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/auto-ruby.test.ts "$DB" >>"$LOG" 2>&1) || die "auto-ruby.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/glossary-enrichment.test.ts "$DB" >>"$LOG" 2>&1) || die "glossary-enrichment.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/linguistic-search.test.ts "$EPUB" "$DB" >>"$LOG" 2>&1) || die "linguistic-search.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/publisher-qa.test.ts "$EPUB" "$DB" >>"$LOG" 2>&1) || die "publisher-qa.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/ruby-inspector-consistency.test.ts "$EPUB" "$DB" >>"$LOG" 2>&1) || die "ruby-inspector-consistency.test.ts failed"
(cd "$SHIKIBU" && npx tsx tests/epub-safety-auto-ruby.test.ts "$EPUB" "$DB" >>"$LOG" 2>&1) || die "epub-safety-auto-ruby.test.ts failed"
(cd "$SHIKIBU" && npm run test:local-db >>"$LOG" 2>&1) || die "npm run test:local-db failed"
say "All DB-dependent tests passed."

# ---------- 5. Assemble ZIP + clean-machine check ----------
say "=== Assembling self-contained ZIP ==="
TESTDIR="$ROOT/.deliverable-final"
rm -rf "$TESTDIR"
mkdir -p "$TESTDIR"
tar --exclude=./node_modules --exclude=./dist --exclude=./tsconfig.tsbuildinfo -C "$SHIKIBU" -cf - . | tar -C "$TESTDIR" -xf -
mkdir -p "$TESTDIR/lingua-mundi"
cp "$DB" "$TESTDIR/lingua-mundi/"

say "=== Clean-machine verification (extract -> install -> build:pro) ==="
(cd "$TESTDIR" && npm install --no-audit --no-fund >>"$LOG" 2>&1) || die "clean npm install failed"
(cd "$TESTDIR" && npm run build >>"$LOG" 2>&1) || die "clean Free build failed"
(cd "$TESTDIR" && npm run build:pro >>"$LOG" 2>&1) || die "clean Pro build failed"
[ -f "$TESTDIR/dist/lingua-mundi-jpn.sqlite" ] || die "clean Pro build missing bundled DB"
BROKEN=$(find "$TESTDIR/node_modules" -xtype l 2>/dev/null | wc -l)
[ "$BROKEN" = "0" ] || die "clean install has $BROKEN broken symlinks"
say "Clean-machine check passed (no broken symlinks, Pro DB bundled)."

ZIP="$ROOT/Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip"
rm -f "$ZIP"
zip -qr "$ZIP" Shikibu/ lingua-mundi/ \
  -x "Shikibu/node_modules/*" "Shikibu/dist/*" "Shikibu/tsconfig.tsbuildinfo" \
     "Shikibu/public/lingua-mundi-jpn.sqlite" "lingua-mundi/*.zip" 2>/dev/null
[ -s "$ZIP" ] || die "ZIP assembly failed"
say "ZIP created: $ZIP ($(ls -la "$ZIP" | awk '{print $5}') bytes)"

say "=== RELEASE COMPLETE ==="
exit 0
