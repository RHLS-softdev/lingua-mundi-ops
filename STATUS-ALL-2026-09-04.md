# FULL SCOPE STATUS — ALL GOALS & PROJECTS — 2026-09-04

Snapshot of where everything stands, per the estate-wide megacycle audit
(AUDIT-REPORT-2026-09-04.md) + live checks this session.

---

## A. ACTIVE GOALS

| Goal | Objective | State |
|---|---|---|
| goal-2c36c32a | Estate-wide megacycle audit → AUDIT-REPORT + JSON, fix P0/P1, re-verify, alert Rex | **ACTIVE, round 1**: report + JSON written; P1-3 (README) + P2-1 (core6 LICENSE) fixed; P1-1/P1-2 remain open (see B) |
| (launch queue, prior session) | 12-item launch queue | Superseded/absorbed into this goal; items tracked below |

## B. OPEN FINDINGS (from audit — P0/P1)

| ID | Issue | Status |
|---|---|---|
| P1-1 | LM API key enforcement unwired (Pro tier unenforceable server-side) | OPEN — minimal fix designed (env-flag `Depends`) |
| P1-2 | Windows EXE CI failing (2026-08-30) | ON HOLD per Rex — do not start until told |
| P1-3 | LM README stale pricing/auth claims | ✅ FIXED this session |
| P1-4 | LM 512MB datasets — DOWNGRADED to P2 (not git-tracked; repo clean 7343 blobs) | local-tree hygiene only |

## C. PROJECTS — DEPLOYMENT STATE (all verified live this session)

| Project | Live | Entitlements | Builds | CI | Notes |
|---|---|---|---|---|---|
| Subtitle Toolkit | launch 200 | $9 Pro + Complete bundle → grant ✅ | web dist | green | bundle test: Language correctly does NOT grant ✅ |
| KitchenOS | launch 200 | $50/mo Premium (org-based) | .deb 0.6.0, APK | green | **.exe FAILED — on hold**; dual-auth doc gap (P2-4) |
| Lingua Mundi | launch 200, API :8765 local | $9/mo Pro + Creator bundle → grant ✅ | — | green | README fixed; keys unwired (P1-1) |
| Shikibu | (desktop) | Pro proposed $36/$11-mo | APK v1.0.0 v2+v3 | green | Windows CI pushed, run failed — on hold |
| Core 6 | /core6/ 200 | $29/$9-mo prices live | — | none | PoC 6 langs; LICENSE now added; no committed tests (P2-2) |
| rhls-hub | 200 | — | — | — | bundles live (3 payment links), 9 locales, legal pages |

Commercial spine (verified): Clerk shared app loved-gobbler-9439 · Stripe
live: 8 products, 8 prices, 3 payment links, webhooks on all 3 Convex
deployments · webhook-only grant doctrine + bundle grants tested end-to-end.

## D. LAUNCH QUEUE ITEMS (prior 12-item queue)

1 Cargo.toml fix ✅ · 2 Windows CI/EXE ⏸ hold · 3 LM API+GUI (GUI live; API public hosting pending) ·
4 Core 6 ($29/$9, PoC live) ✅ · 5 Bundles (live + grants wired) ✅ · 6 Marketing/SEO (copy+og redeployed) ✅ ·
7 Design polish ⏳ · 8 Assistant-manager local models (ollama approval cancelled; llama-swap works) ⏸ ·
9 Triple-check → THIS AUDIT ✅ · 10 Notifications ✅ · 11 Memory log ✅ (this file + SESSION-MEMORY) ·
12 Overnight module ✅ (03:00 timer)

## E. INFRASTRUCTURE & AUTOMATION

- Deploy: 3 launch sites + hub redeploy OK; gated push rules enforced.
- Autopilot (homelab file): ~/dsh-autopilot live, 6-hour cron, optimize/
  sync(REMOTE pending Tailscale)/rename(defer to vault-nightly)/trash.
- Vault pipeline: vault-nightly.timer 03:00 active.
- Overnight self-improve: systemd user timer 03:00 installed.
- mega-cycle.sh (deterministic corp loop): history green to 2026-09-03.
- llama-swap :11435 live (qwen2.5-0.5b/1.5b, deepseek-r1-1.5b) for $0 local
  agent work; workflow tool supports provider overrides.

## F. SECURITY / KEYS (rotation night 20:00, calendar UID 5f54a8b3)

- Webhook secrets: ST/KOS/LM recreated + verified ✅
- Clerk (shared loved-gobbler-9439), Stripe (live), GH PAT: rotation pending
  at 20:00 (old keys still active until then).
- No live secrets in repos (scan clean); .env.wire excluded from backups.

## G. NEXT ACTIONS (when you say go)

1. Wire LM API key enforcement (P1-1) — ~1 file behind env flag.
2. Diagnose Windows EXE CI (P1-2) — read failed job logs.
3. Commit core6 smoke test + delete LM .confidence-duplicate (P2).
4. Add KOS dual-auth architecture note (P2-4).
5. LM API public hosting (item 3) when ready.

## H. FIXES APPLIED (round 1 completion — 2026-09-04 ~20:00)

- P1-1 LM API keys: optional_api_key wired to /analyze /lookup /kanji
  (auth.py + 2 routes). Verified: anonymous 200, invalid key 401, tests
  3/3. Pushed to lingua-mundi repo.
- P1-3 LM README: API row updated. Pushed.
- P2-1 core6 LICENSE: MIT added, live /core6/LICENSE 200.
- P2-2 core6 smoke test: test/smoke.test.js, 42/42 pass, deployed.
- P2-3 LM duplicate dataset: parked in datasets/_archive-unreferenced/.
- P2-4 KOS dual-auth: README "Two auth systems, intentionally" note added
  (working tree; push pending with next KOS commit).
- Remaining open: P1-2 Windows EXE CI (Rex hold) · P2-5 ST README phrasing
  · P2-6 commercial node_modules history · KOS README note push.
