# TICKET QUEUE — SORTED BY EFFORT (easiest → hardest) — 2026-09-04

Rex's priorities: **website first, distillation second**, clear the easy
tickets so the tough work gets full focus. Tiers: 🟢 quick (minutes),
🟡 moderate (a focused session), 🔴 hard (multi-hour / cross-toolchain),
⛔ blocked (needs Rex or an account).

---

## TIER 🟢 — QUICK WINS (clear first; most are done or minutes each)

| # | Ticket | Effort | Status |
|---|---|---|---|
| Q1 | Website: hub locale gap — Chen-Baaxal rows untranslated in ko/zh-Hans/zh-Hant/ar/fr/it/ja | 🟢 | ✅ DONE — translated + pushed + live (fr verified) |
| Q2 | Website: en.js had Spanish value (`hub.about.h1` '¡Hola, soy Rex!') mirrored in all locales — flagged for Rex (may be intentional brand greeting); real contamination elsewhere: NONE found | 🟢 | ⏸ REX DECISION on greeting; hi content verified real Hindi |
| Q3 | Website: hi + yue only 62/351 keys — **fixed the failure mode**: i18n-site.js now falls back to English (enCatalog) instead of raw key strings for partial locales; tested PASS. Full 289-key translation of hi/yue remains (needs quality source) | 🟡 | OPEN (fallback ✅ shipped; translation pending) |
| Q4 | Texupan naming: release assets still `Core6-*` filenames | 🟢 | OPEN — cosmetic; rename optional (links stable) |
| Q5 | DROPPED: archive vision-only projects (paperclip, gearbox, software-generation-machine) to attic/ | 🟢 | ✅ DONE — moved to projects/_attic/ |
| Q6 | Keepers: verified via systemd — most ALIVE (console :8792, llama-swap, mem-guard, 8 timers). FIXED: rhls-lm-api + rhls-assistant failed 8500× (unquoted space-in-path ExecStart) → quoted, both running; LM API :8765 health OK. AM brought online (CORP_OFFLINE=0) | 🟢 | ✅ DONE |
| Q7 | AUDIT P2-3: LM `_archive-unreferenced/` cleanup confirmed (parked already) | 🟢 | ✅ DONE |
| Q8 | AUDIT P1-3: LM README stale | 🟢 | ✅ DONE + pushed |
| Q9 | AUDIT P2-1: core6 MIT LICENSE | 🟢 | ✅ DONE + live |
| Q10 | AUDIT P2-2: core6 smoke test 42/42 | 🟢 | ✅ DONE + deployed |
| Q11 | AUDIT P2-4: KOS dual-auth README note | 🟢 | ✅ DONE + pushed |
| Q12 | Texupan Stripe product name ("Core 6" → Texupan at checkout) | 🟢 | ✅ DONE + verified |
| Q13 | offline-dictionary-plan/ + bundles docs: Core 6 → Texupan prose | 🟢 | ✅ DONE |
| Q14 | AUDIT P2-5: ST README "no backend" — verified accurate, no change | 🟢 | ✅ CLOSED (no churn) |
| Q15 | Hub live-link re-check (18 download links) | 🟢 | ✅ DONE (all exist) |

## TIER 🟡 — MODERATE (focused effort, $0 or low cost)

| # | Ticket | Effort | Status |
|---|---|---|---|
| M1 | **WEBSITE**: hi + yue catalogs — index.html page now 100% covered (62→125 keys each, 63 real translations authored per locale, 0 used-missing). Remaining 226 keys = about/cv/contact + other-product pages (English-fallback, never raw keys after the i18n fix) | 🟡 | ✅ DONE for index; extended pages tracked |
| M2 | **WEBSITE**: wrong-language scan of all 9 locales — VERIFIED CLEAN (only intentional mixed content: names, 語 anecdote, language lists; the es/fr/zh-Hant/ar/yue `hub.about.h1` '¡Hola soy Rex' is identical everywhere = brand decision, flagged for Rex) | 🟡 | ✅ VERIFIED CLEAN |
| M3 | Website: Chen-Baaxal rows translated in ko/zh-Hans/zh-Hant/ar/fr/it/ja (7 locales, earlier this session) | 🟡 | ✅ DONE |
| M4 | Distillation prep: golden 806/118 ✅, eval harness ✅, Kaggle token ✅ — NO notebook written, NO kaggle CLI. True blocker = Rex identity verification (human) | 🟡 | ⏸ human-gated; everything else verified ready |
| M5 | Chén Báaxal: DEB (Sep 1) NEWER than all src (Aug 31) = current ✅. FIXED: remote README had LIVE merge-conflict markers (visible on GitHub) → resolved via API (a34e671), local repo re-pointed to clean main. Content: Phase-0 core (OBJ/GLB→unwrap→PDF, 13/13 tests) + Qt6 shell + locked SPEC | 🟡 | ✅ DONE |
| M6 | Ledgerly: Tauri 0.1.0 desktop wrapper FOUND uncommitted (prior session WIP, bundle targets=all = EXE/APK path) — saved + committed + pushed (1323109/57bf094). README conflict resolved twice (force-push regression caught + fixed, eb20b98). EXE build itself = Windows toolchain = Rex hold | 🟡 | ✅ WIP saved; build on Rex hold |
| M7 | DROPPED §1: Toscanini decision — verify toscanini-rs builds, ship as replacement or keep Kotlin deb | 🟡→🔴 | OPEN |
| M8 | xokbil (Rust core 12/12 + Qt scaffold, active commits) = KEEP — real project. universal-wrapper/uw-specs = generator tooling used by projects (ledgerly README references it) = KEEP. No attic move | 🟡 | ✅ assessed — both KEEP |
| M9 | AUDIT P2-6: commercial node_modules in lingua-mundi history (future backups already exclude; deep-history purge = 🔴, skip unless needed) | 🟡 | DEFER (accepted) |
| M10 | Website: product status labels (P1 editorial from earlier audit) | 🟡 | OPEN |
| M11 | Website: nav/IA hierarchy pass (P1 editorial) | 🟡 | OPEN |
| M12 | Website: CSS token consolidation (P2) | 🟡 | OPEN |

## TIER 🔴 — HARD (the tough work to focus on after clearing above)

| # | Ticket | Effort | Status |
|---|---|---|---|
| H1 | **DISTILLATION (top priority)**: LoRA fine-tune → GGUF Q4 → llama-swap slot → eval PASS. Needs Kaggle GPU (⛔ Rex identity) | 🔴 | BLOCKED on Rex |
| H2 | Windows EXE CI fix (Shikibu + KitchenOS windows.yml failed) | 🔴 | ⛔ REX HOLD |
| H3 | LM API public hosting + gateway wiring (keys metered :8766 exists; public tunnel + domain) | 🔴 | OPEN |
| H4 | Toscanini-rs full verification + release (3.5 GB, no git) | 🔴 | OPEN |
| H5 | Ledgerly + Chén Báaxal full platform parity (exe+apk) | 🔴 | OPEN |
| H6 | LM API ↔ offline Texupan dataset unification (C5) | 🔴 | OPEN |
| H7 | Localization full quality pass (all 9 locales, gender-consistent, DeepL-grade) | 🔴 | needs DeepL key ⛔ |

## ⛔ BLOCKED / HUMAN-GATED (not tickets to clear, but tracked)

- Kaggle identity verification (Rex) → unblocks H1 distillation
- DeepL key (Rex) → unblocks H7 localization quality
- Launch-post accounts (dev.to/PH/HN/Reddit) + marketplace accounts
- Money: first sale / ka-ching
- Windows EXE hold (Rex said "don't start until I say so")

---

## EXECUTION PLAN (this pass)

1. Clear remaining 🟢 items (Q1-Q4, Q5, Q6).
2. Attack M1+M2+M3 (website localization) — the top website priority,
   using the established $0 pipeline (local qwen2.5-3b, 5-key batches) with
   the hi.js contamination fixed first.
3. M4 distillation prep so only Rex's identity step remains.
4. Leave 🔴 for focused scope after the 🟢/🟡 tiers are clear.


## EXECUTION LOG (2026-09-04 evening pass)

Cleared in this pass:
- Q1 Chen-Baaxal i18n rows: 7 locales translated + pushed (fr verified live)
- Q2 locale wrong-language scan: VERIFIED CLEAN (only intentional mixed content)
- Q3 i18n-site.js en-fallback: partial locales (hi/yue) now show English not raw keys — tested 3/3 PASS, live
- Q5 vision-only projects archived → projects/_attic/
- Q6 keepers: rhls-lm-api + rhls-assistant FIXED (unquoted space-in-path ExecStart, 8500 restart failures → active). LM API :8765 live (health ok). AM online (CORP_OFFLINE=0). Audit G1/G3 now PASS.
- M1 hi+yue: index.html keys 100% covered (62→125 each, 63 authored translations/locale), live verified
- M3 Chen-Baaxal rows (dup of Q1) done
- M5 Chen-Baaxal: DEB current; remote README conflict (live on GitHub) resolved via API; local repo re-pointed to clean main
- M6 Ledgerly: prior-session Tauri WIP (1.9GB incl target) SAVED + committed + pushed; README conflict fixed twice (force-push regression caught)
- M8 xokbil/universal-wrapper: assessed — both KEEP (real projects)
- Hub site audit re-run: W1-W5 CLEAN
- Ledgerly + chen-baaxal READMEs: 0 conflict markers (API-verified)

Remaining genuinely-open: Q2 greeting (Rex brand call), Q4 asset rename (cosmetic),
M7 Toscanini-rs decision, M10-M12 website editorial (status labels/nav/CSS tokens —
editorial judgement, low urgency), H1 distillation (Rex Kaggle identity),
H2/H5 Windows EXE (Rex hold), H3 LM API public hosting, H4 toscanini-rs verify,
H6 dataset unification.
