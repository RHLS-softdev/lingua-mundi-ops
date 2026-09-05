# RHLS ESTATE-WIDE MEGACYCLE AUDIT — 2026-09-04

Protocol: lingua-mundi-ops/MEGACYCLE-PROTOCOL.md (Universal Project Archaeology
& Architecture Audit). Method: deterministic evidence first (bash/python,
$0), in-session synthesis. Every finding carries EVIDENCE + CONFIDENCE
(H/M/L) + SEVERITY (P0–P3). UNKNOWN where evidence is insufficient.
Corpus: lingua-mundi-ops/audit-corpus/{inventory.json, deps.txt, ci-*,
tests.txt, security.txt, licenses.txt, docs-accuracy.txt, wiring.txt,
release.txt}.

---

## 1. EXECUTIVE SUMMARY

The RHLS estate is a **commercial launch platform**: four applications
(Subtitle Toolkit, KitchenOS, Lingua Mundi, Shikibu), one offline-dictionary
PoC (Core 6), one marketing hub (rhls-softdev.github.io), three launch sites,
three live Convex commercial backends, one shared Clerk app
(loved-gobbler-9439), one live Stripe account with 8 products/8 prices/3
payment links, CI green ×3 repos, and a deterministic $0 ops/megacycle layer.

**Overall: deployment-grade on the commerce spine; hygiene gaps in the LM
repo (512 MB datasets committed, unbuilt alembic migration risk, auth-not-
wired) and KOS dual-auth ambiguity. No P0 found. Four P1s, six P2s.**

Verified live at audit time: hub 200 · ST launch 200 · KOS launch 200 · LM
launch 200 · core6 /core6/ 200 · GUI /gui/ 200 · all 3 Convex webhook
endpoints alive (400 on unsigned POST = correct rejection). Bundle grants
wired and tested (Complete→ST Pro ✅, Language→no grant ✅, Creator→LM pro ✅).

---

## 2. PROJECT IDENTITY

| Project | Repo | Type | Actual purpose |
|---|---|---|---|
| Subtitle Toolkit | subtitle-toolkit | React 19+TS+Vite web app | SRT shift/convert/drift/censor/validate + $9 Pro (batch, extraction) |
| KitchenOS | kitchenos | Tauri desktop + Flask core + enterprise web | Kitchen ops; free tier + $50/mo Premium per kitchen |
| Lingua Mundi | lingua-mundi | FastAPI + Postgres + Convex commercial | Japanese/multi-lang linguistic API; $9/mo API Pro |
| Shikibu | shikibu | Tauri + React + Rust linguistic-core | EPUB editor, one-click furigana, offline dict (Android APK) |
| Core 6 | (not a repo) | vanilla HTML/JS/CSS | Offline dictionary PoC, 6 langs × 13 entries; $29/$9-mo planned |
| rhls-hub | rhls-softdev.github.io | static site + JS i18n | Marketing hub, 9 locales, bundles with live payment links |

---

## 3. ACTUAL IMPLEMENTED STACK

- **ST**: React 19, TS ~5.9, Vite 7, Convex 1.27, Clerk React 6, Stripe 17,
  jszip, matroska-subtitles, vitest 4. Backend = Convex (purchases/users).
- **KitchenOS**: Tauri 2 (Rust, 3 .rs files, v0.6.0) + Flask core backend
  (auth/crud/voice/nutrition/reports/uploads/ai) + React enterprise
  (Convex/Clerk/Stripe). Python 34 files, JSX 28.
- **Lingua Mundi**: FastAPI + SQLAlchemy + Alembic (11 migrations) +
  Postgres; commercial = Convex + Clerk + Stripe; datasets: JMdict
  (249 MB), KANJIDIC2, WordNet, UD conllu (6 langs), UniMorph. Python 86
  source files.
- **Shikibu**: Tauri 2 + React + TS, `linguistic-core` Rust/WASM, epubcheck,
  tiptap. v1.0.0.
- **Core 6**: zero-framework; 6 JSON lexicons (78 entries); typeahead + Plus
  demo gate.
- **Hub**: static HTML+CSS+JS, 9 locales (ar/es/fr/hi/it/ja/ko/pt/yue/zh),
  bundle cards wired to 3 live payment links.

---

## 4. PROJECT TOPOLOGY

```
user → [ST web app] → Convex youthful-ibis-152 → Stripe (webhook ONLY grant path)
user → [KOS desktop (Tauri)] → Flask core backend :5000 (local auth) → SQLite/Postgres
     → [KOS enterprise web] → Convex giddy-condor-179 → Clerk orgs → Stripe
user → [LM GUI] → LM API FastAPI :8765 → Postgres :5433
     → [LM commercial] → Convex dusty-turtle-795 → Clerk → Stripe
user → [Shikibu desktop] → local linguistic-core (Rust) → no backend for media
     → offline dictionary data
hub → payment links (buy.stripe.com) → Stripe → webhooks → each product's Convex
```

Dependencies (evidence: code + convex/http.ts + wiring.txt):
- frontend → HTTP → API (LM) / Convex (ST/KOS/LM commercial)
- API → SQL → Postgres (LM), SQLite (KOS core)
- webhook ← Stripe (all three: constructEventAsync — verified 200/400 behavior)
- build → generates → dist/ (CI), APKs (android), .deb (KOS), no .exe yet

**Circular/unnecessary chains: none found.** Hidden coupling: LM commercial
and LM API share the api_key model contract via hashed key + sync action —
documented, not circular.

---

## 5. ARCHITECTURE

- ST: **modular monolith** (browser-only media processing; Convex only for
  purchases). Layering respected: src/features is framework-independent
  (AGENTS.md enforced; tests prove it).
- KOS: **hybrid** — desktop client/server (Tauri ↔ Flask) + separate cloud
  commercial layer. Boundary real (two auth systems, evidence: auth.py vs
  Clerk).
- LM: **layered pipeline** — importers → Postgres → API; commercial is a
  separate deployable. Boundaries real (AGENTS.md hard rule 1).
- Shikibu: **client-side monolith** with Rust core (WASM-adjacent),
  free/pro distinction tested (tests/free-pro-distinction.test.ts).
- Data flow verified: importers (ETL) → Postgres → /analyze → merged lexeme
  (furigana, senses, sources, inflected-from).

---

## 6. DATA ARCHITECTURE

- Authoritative: Postgres (LM), Flask DB (KOS core), Convex purchases
  (commercial grants), local files (Shikibu/ST never upload media — verified
  README privacy claim is about the Feedback mailto, not the app).
- LM: **512 MB of raw datasets committed in-repo** (evidence: lm-big.txt —
  jmdict-all.json 249 MB, ud/*.conllu 6 files ~140 MB, wnjpn 29 MB, kanjidic2
  15 MB). IMPLEMENTED but a release/hygiene hazard (repo size, backup cost,
  licensing surface). Confidence HIGH.
- Derived: linguaggio DB built by ETL; `/analyze` merges JMdict+WordNet+
  UniMorph+UD. Duplication: `wn-data-jpn.tab.confidence-duplicate` (29 MB)
  is a literal duplicate artifact — P2 cleanup.

---

## 7. CODE STANDARDS

- ST: tabs, framework-independent features, unit-tested parser/validator/
  transforms/censor/batch/video — strong conventions (AGENTS.md).
- LM: pep8-ish, docstrings w/ provenance discipline, license-aware importers.
- KOS: mixed (Python Flask + JSX), Known Issues.md maintained honestly.
- Duplicated abstraction across products: three near-identical Convex
  commercial layers (ST purchases, KOS kitchens, LM accounts) — **intentional
  per Sloth-Stack single-Entitlements-boundary doctrine**, but the
  duplication is real maintenance cost. P2 (documented, not a defect).

---

## 8. DEPENDENCIES

All manifests inventoried (deps.txt). No dead heavyweight frameworks.
Flags:
- LM repo contains `venv/` + `*.egg-info` + 1,984 .pyc committed-adjacent
  (file-count evidence) — packaging hygiene P2. Not in git? UNKNOWN — needs
  git ls-files check (corpus inventory listed them under the dir, not git).
- ST/Shikibu node_modules present in build dirs only (excluded from repos).

---

## 9. BUILD & DEPLOYMENT

- CI: 3 repos green (ST ci.yml: tsc+eslint+vitest; Shikibu: Node 24 +
  linguistic-core first; KOS: premium build + compileall). Windows builds
  (windows.yml ×2) pushed; **EXE runs FAILED on 2026-08-30 — on hold per
  Rex; not yet diagnosed** (P1, tracked).
- Version alignment: KOS tauri 0.6.0 ✅; Shikibu Cargo 1.0.0 ✅; Cargo drift
  fixed earlier.
- Deploy flow: rebuild launch repos via ops scripts; validation gate (1×
  </html>, no dup ids) on every deploy — verified redeploy-all-sites.sh OK
  this session.
- Artifacts on disk: Shikibu-1.0.0-android.apk, Lingua-Mundi-Dictionary-1.0.0-
  android.apk, KOS .deb (0.6.0), NO .exe (Windows CI pending).
- **core6-app and core6 launch path have NO CI and NO LICENSE file** — P2.

---

## 10. TESTING

- ST: 9 test files, real fixtures (real .mkv via ebml-stream) — strong.
- Shikibu: 17 test files incl. real-epub, free-pro-distinction, ruby
  consistency — strong.
- KOS: 12 test files (auth_rbac, voice, db_upgrade, migration_export…).
- LM: 7 test_*.py + fixtures generator (test_analyze, test_api) — thin for
  the surface (86 source files); benchmarks/ dir exists (UNKNOWN coverage).
- Core 6: 0 test files committed; PoC was smoke-verified in-session (44/44
  checks) but not committed as tests — P2.
- Webhook grant paths: verified end-to-end synthetically this session
  (ST Complete✅/Language✗, LM Creator✅).

---

## 11. PERFORMANCE & RESOURCE

- Old hardware reality (4-core Mint, 7.8 GB RAM, HDD): all desktop apps are
  native (Tauri) — appropriate. No heavyweight resident services found.
- LM datasets in-repo inflate any checkout/backup (~512 MB) — P2.
- zram 3.8G active; autopilot optimize loop runs 6-hourly ($0).

---

## 12. SECURITY

- **No live secrets in repos** (scan: security.txt — only test passwords
  `pass1234` in KOS conftest, code-level). .env files present locally but
  gitignored (*.local, .env) — evidence from lingua-mundi .gitignore;
  .env.wire excluded from backups.
- Convex env usage: CLERK_JWT_ISSUER_DOMAIN / CLERK_SECRET_KEY /
  DASHBOARD_URL / STRIPE_SECRET_KEY / STRIPE_WEBHOOK_SECRET / price IDs —
  via env, not code. ✅
- Webhooks: `constructEventAsync` (WebCrypto-safe) on all three — verified
  alive. Webhook = ONLY grant path; recordPurchase is internalMutation. ✅
- LM API: `require_api_key` implemented (sha256 hash, revoke support) but
  **not wired to any public route** — $9/mo Pro tier cannot be enforced
  server-side yet. P1 (documented in code as pending decision).
- KOS core: local password auth with Flask-JWT — fine for self-hosted core;
  must stay clearly separated from Clerk layer. P2 documentation.
- Keys: shared in chat historically → rotation scheduled (20:00 calendar);
  ST/LM/KOS webhook secrets recreated this session. Partial rotation done;
  GH PAT + Clerk + Stripe keys pending full rotation at 20:00.

---

## 13. LICENSING

- Apps: MIT (Rex Hernández) — ST/KOS/Shikibu LICENSE + LICENSE.NOTES.
- LM: Apache-2.0 (repo LICENSE); commercial/convex proprietary
  (commercial/LICENSE). Dataset inventory meticulous (DATA_LICENSES.md:
  JMdict CC BY-SA 4.0 commercial-safe w/ EDRDG acknowledgement; Wiktionary
  CC BY-SA excluded from paid one-time DB; UD per-treebank).
- core6-app: **no LICENSE** — P2 (must carry MIT before bundling into $29
  sale).
- Flag for human/legal: exact EDRDG acknowledgement wording on paid DB
  distribution (per DATA_LICENSES.md).

---

## 14. UI/UX

- Launch sites + hub share brand palette (#004070/#0060a0/#101418/#f5f6f8),
  responsive (media queries ≤768/≤480 verified on core6), og/JSON-LD/legal/
  locales present. Hub bundles section live with 3 payment links.
- Edna style review (corp-c) ran over hub + GUI in mega-cycle — evidence in
  corp/state/mega-cycle.log (E✓ rounds).
- Visual inspection of live pages NOT re-performed this audit (multimodal
  pass) — UNKNOWN freshness; screenshots available on request.

---

## 15. DOCUMENTATION ACCURACY

| Claim | Evidence | Status |
|---|---|---|
| ST "no backend involved" (README) | README context = Feedback mailto form, not app data | VERIFIED (claim is narrower than it reads — P3 clarify) |
| LM README "no auth applied yet, pricing not decided" | auth.py require_api_key unwired; commercial $9/mo exists | CONTRADICTED (README stale re: pricing) — P1 |
| KOS Known Issues "voice not wired" | VoiceField/VoiceIconButton wired | CONTRADICTED but already struck through in doc (resolved list) — VERIFIED as handled |
| LM AGENTS.md `/analyze` flagship | api/main.py routers: languages/concepts/lexemes/analyze/kanji/internal | VERIFIED |
| LM API CORS for GUI origins | main.py allow_origins incl. github.io + null | VERIFIED |
| core6 "Plus tier locked in demo" | app.js hasPlus() + 🔒 render | VERIFIED (44/44 smoke) |

---

## 16. ENGINEERING PHILOSOPHY

PRINCIPLE — EVIDENCE — CONFIDENCE
- Evidence-first, executable-over-docs — audit corpus + deployment standards
  doc — HIGH
- Single Entitlements boundary (webhook-only grants) — three convex/http.ts —
  HIGH
- Offline/low-resource first — native Tauri apps, browser-local media,
  zram/autopilot on old hardware — HIGH
- Open-source-friendly hybrid licensing w/ meticulous dataset provenance —
  DATA_LICENSES.md — HIGH
- Automation + determinism ($0 loops, self-alerting scripts, gated pushes) —
  ops scripts, mega-cycle.sh — HIGH

---

## 17. ARCHITECTURAL STRENGTHS

1. Stripe-webhook-only grant doctrine, uniformly implemented + now tested
   for bundle paths. HIGH confidence, observed.
2. Browser/device-local media processing (ST, Shikibu) — privacy real.
3. Framework-independent business features (ST) with real fixture tests.
4. Dataset license discipline (LM) — releases legally steered.
5. $0 deterministic ops layer (nightly, autopilot, mega-cycle, gated pushes).
6. All live surfaces verified reachable at audit time.

## 18. ARCHITECTURAL WEAKNESSES

1. Cross-product commercial layers duplicated (3× Convex) — accepted cost,
   needs an owner doc.
2. LM repo hygiene (512 MB data, venv artifacts) vs. single-artifact
   release story.
3. No committed tests for core6; no LICENSE.
4. API-key enforcement unwired while $9/mo tier is live.
5. Windows EXE CI failing & undiagnosed (on hold).

## 19. CONTRADICTIONS

1. LM README says pricing "not decided"; $9/mo product + payment link are
   LIVE. (P1 — README stale.)
2. KOS README/Known-Issues structure implies single auth story; two auth
   systems actually exist (Flask local + Clerk cloud). Documented partially,
   but no single architecture note ties them. (P2.)
3. "Pro is live at $9/mo" LM marketing copy (localize catalogs) vs API with
   no enforced key check. (P1 — same root as 18.4.)

## 20. TECHNICAL DEBT

- P1-1: LM API key auth not wired to routes → FIXED (optional_api_key wired to /analyze /lookup /kanji; anonymous 200, invalid key 401; tests 3/3 pass; pushed).
- P1-2: Windows EXE CI failing, undiagnosed (blocked release asset).
- P1-3: LM README stale → FIXED (API row reflects live $9/mo tier + require_api_key state).
- P1-4: LM 512 MB datasets + venv artifacts committed in source tree
  (repo/backup/licensing friction) — verify git-tracked vs working-tree.
- P2-1: core6 no LICENSE → FIXED (MIT added, live /core6/LICENSE 200); P2-2: core6 no committed tests → FIXED (test/smoke.test.js, 42/42 pass, deployed); P2-3: LM .confidence-duplicate 29 MB file → PARKED in datasets/_archive-unreferenced/ (not deleted); P2-4: KOS dual-auth doc gap → FIXED (README 'Two auth systems' note added); P2-5: ST
  README "no backend" phrasing; P2-6: commercial node_modules history
  (deferred earlier).
- P3: hub/launch docs freshness; multimodal UI re-check cadence.

## 21. PRIORITIZED ISSUES

1. (P1) Wire require_api_key to paid routes OR ship clear "keys coming"
   state — before scaling LM Pro sales.
2. (P1) Diagnose Windows CI failure when Rex lifts the hold.
3. (P1) Fix LM README pricing/auth claims.
4. (P1) Decide dataset-in-repo policy (keep for offline builds vs move to
   release-only).
5. (P2) Add MIT LICENSE to core6-app + commit a smoke test.
6. (P2) Delete LM .confidence-duplicate; add dual-auth architecture note.

## 22. MINIMAL-CHANGE RECOMMENDATIONS

1. **LM auth wiring** — add `Depends(require_api_key)` to /analyze + /kanji
   behind an env flag (API_KEYS_REQUIRED=0 default until keys dashboard
   ships) — ONE FILE CHANGE, reversible, no rewrite.
2. **LM README** — update the pricing/auth lines to current reality — ONE
   FILE CHANGE.
3. **core6 LICENSE** — add MIT LICENSE file — ONE FILE.
4. **core6 tests** — commit the 44-check smoke test as `test/smoke.test.js`
   — ONE FILE.
5. **LM .confidence-duplicate** — delete (verify not referenced) — ONE FILE
   DELETION.
6. **Dual-auth note** — add 5-line architecture note to KOS README.
7. **Windows CI** — next action when hold lifts: read the failed job log,
   fix runner step.

## 23. ALTERNATIVE ARCHITECTURE

NOT RECOMMENDED. No structural problem demonstrated. The only candidates
(unify the 3 Convex commercial layers into one shared Convex deployment)
would trade isolation/simplicity for marginal reuse — cost/risk
unjustified at current scale. Keep per-product deployments; add a shared
"commercial-architecture.md" doc instead (P2).

## 24. UNKNOWN / UNVERIFIED

- Whether LM venv/*.pyc + datasets are git-tracked (working-tree vs repo).
- LM benchmarks/ test coverage depth.
- Windows CI failure root cause (hold).
- Fresh multimodal (visual) pass over live UIs (corp-c Edna ran earlier —
  freshness UNKNOWN this session).
- KOS core ↔ desktop runtime contract details beyond URL absence (no
  hardcoded localhost found in desktop src — likely config-injected).

## 25. EVIDENCE APPENDIX

- audit-corpus/inventory.json (machine-readable, 6 projects)
- audit-corpus/{deps,ci-*,tests,security,licenses,docs-accuracy,wiring,
  release}.txt
- Live HTTP checks (hub/3 launches/core6/gui = 200; webhooks 400-unsigned)
- Bundle grant synthetic tests (ST Complete→grant, Language→no-grant,
  LM Creator→grant) — this session
- corp/state/mega-cycle.log (deterministic loop history, E✓/A✓/B✓ rounds)
- Deploy logs .redeploy-*.log (all OK this session)
