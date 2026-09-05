# DROPPED / ABANDONED / IN-FLIGHT WORK FROM OTHER SESSIONS — 2026-09-04

Answer to Rex's question: "What about everything that was dropped or
abandoned from other sessions?" — the full inventory beyond the launch
estate, reconstructed from corp/state, AM handoffs, session memories,
project trees, GitHub releases, and the live store.

---

## 0. HOW TO READ THIS

Statuses: ✅ LIVE · 🔶 IN FLIGHT · ⏸ PAUSED/BLOCKED · ⚠️ DROPPED/STALE ·
🗄 ARCHIVED/SUPERSEDED. Evidence listed per item; where memory conflicts
with disk, disk/API wins.

---

## 1. THE "FINISH THE THREE APPS" MANDATE (REORCHESTRATION-2026-09-02)

Rex's last explicit scope (v2, verbatim): *"Make me money… Finish Toscanini,
Chén Báaxal and Ledgerly. MoreComp only goes live when I'm sure it's done."*

| App | Store state | Release assets | Gap (evidence) | Status |
|---|---|---|---|---|
| **Choir Director (Toscanini)** | card live | `choir-director_1.0.0_amd64.deb` only | NO .exe, NO .apk. Kotlin 1.0.0 shipped but SUPERSEDED by Rust rebuild (`projects/toscanini-rs/`, 3.5 GB, no git repo, unverified). Store still sells the Kotlin deb. | 🔶 IN FLIGHT → ⚠️ rebuild not landed |
| **Chén Báaxal** | card live | `ChenBaaxal_0.1.0_amd64.deb` + zip | NO .exe/.apk. Ticket handoff-20260902 asks: is DEB current vs src? content completeness? EXE needed? | ⏸ OPEN (ticket, never actioned) |
| **Ledgerly** | card live | `Ledgerly_0.1.0_amd64.deb` + zip | NO .exe/.apk. Local tree 2 GB has uncommitted dist rebuild + merge-conflict README. | ⏸ OPEN |
| **MoreComp** | NOT in store (Rex: private) | — | 1.3 GB, private. Localization blocked: DeepL key needed (Rex's lane; MyMemory banned). Kaggle training blocked on human identity verification. | ⏸ PRIVATE + BLOCKED |

**Root pattern:** "finish the three apps" was superseded by the money/
outreach push and never returned to. Toscanini-rs (the actual future) is
unverified and unreleased; the store sells yesterday's Kotlin build.

---

## 2. TRAINING / DISTILLATION LANE (money-critical, human-gated)

From DISTILLATION-STATUS.md + session-memory 09-02:
- Golden dataset DONE (806 train / 118 eval, leak-free).
- Eval baseline measured: FORMAT 100%, CAPABILITY ~0-20% — the number only
  moves with the LoRA fine-tune.
- **BLOCKED on a human step**: Kaggle identity verification (token works,
  `~/.kaggle/access_token`), then push Qwen2.5-Coder-1.5B LoRA notebook →
  GGUF Q4 → llama-swap slot → eval PASS notify.
- Honest status: system not broken, blocked on training lane. Runner died
  once and wasn't surfaced loudly (supervisor gap, now in lessons).

| Item | Status |
|---|---|
| Golden dataset | ✅ DONE |
| Eval harness vs untrained baseline | ✅ RUNNING |
| Kaggle identity verification | ⏸ REX (human) |
| LoRA fine-tune → GGUF → slot → PASS | ⏸ blocked on above |

---

## 3. BRAND RENAME DROPPED MID-WAY: Core 6 → Texupan ⚠️

Session-memory 2026-08-31 (authoritative): *"Texupan (formerly 'Core 6')…
Rename Core 6 → Texupan is done on hub/landing but NOT in
core6-app/index.html (C3 open)."*

What the sweep found TODAY:
- Live store + hub + bundles + i18n: **Texupan** everywhere (consistent) ✅
- core6-app title: `Texupan — Offline Dictionary` ✅ (renamed since the memory)
- **Stripe live product: `Core 6 Offline Dictionary`** (prod_VAKnoVjBzQxVI5,
  $29 + $9/mo) ❌ — created under the OLD name in this session's Core-6 work
- **Release assets: `Core6-Dictionary-0.1.0-*`, `Core6-0.1.0-android.apk`** ❌
  (asset filenames under old name)
- **offline-dictionary-plan/ docs (ARCHITECTURE/PRICING/ROADMAP): "Core 6"** ❌
- `.pricing-inventory.env`: `CORE6_*` env names (internal, cosmetic)

**Risk:** a customer on the Texupan card clicks $29/$9-mo → Stripe checkout
page says "Core 6 Offline Dictionary" — visible brand mismatch at the pay
moment. P1 for conversion trust, trivial to fix (product display name on
Stripe; asset filenames are cosmetic but should match for support queries).

---

## 4. PROJECTS/ DIR — THE REST OF THE ESTATE

| Project | What it is | Evidence of state | Status |
|---|---|---|---|
| **toscanini-rs** | Rust/Tauri rebuild of Choir Director (the future) | 3.5 GB, Cargo.toml 1.0.0, NO .git, core/ + ui/ + src-tauri | ⚠️ unverified, unreleased |
| **toscanini** (Kotlin) | shipped 1.0.0 | README says SUPERSEDED by toscanini-rs | 🗄 archived intent |
| **xokbil** | embroidery editor, C++/Qt + Rust core | 900 files, Rust core 12/12 + Qt scaffold, git HEAD 27f3fc6 | 🔶 early-stage, store mentions once |
| **gearbox** | "Machine Definition Format" v0.1 | 12 files, MACHINE-FORMAT.md only | 🗄 spec-only |
| **paperclip** | open desktop assistant platform | MANIFEST.md v3.0, 1 file | 🗄 vision-only |
| **software-generation-machine** | (name says it) | 3 files (KNOWLEDGE/MANIFEST/README) | 🗄 vision-only |
| **universal-wrapper** + uw-specs | app wrapper | 129 files | 🔶 unclear |
| **redshirt** | design-study + downloads organizer | 12 files, python scripts | 🔶 dormant |
| **notion-export** / obsidian-vault | vault migration tooling | 1767 files | 🔶 dormant |
| **lesson-engine** | lesson generator (not on store) | dist + node_modules + "Deprecated version/" | ⚠️ superseded/abandoned |
| **morecomp** | local orchestrator engine | 4563 files 1.3 GB, private per Rex | 🔶 PRIVATE |

---

## 5. KEEPERS / DETACHED RUNNERS (from 09-02 memory — still alive?)

Claimed running on 09-02: mega-cycle · brain-eval · goal-supervisor ·
stripe-notify · outreach-mail (v4) · tlacuatzin-runner · trust-mission ·
design-loop · api-gateway (:8766) · api-tunnel · ops-dashboard (:8091) ·
lm-api · llama-swap (:11435, 7 slots) · store/LM/Planetarium/console 200.

**Audit 09-04 findings:** llama-swap :11435 ✅ live (verified 3 models);
Postgres :5433 ✅; store/launch sites ✅ 200. Others NOT verified this
session — UNKNOWN whether they survived (sandbox reboots kill non-escalated
detached keepers; lesson learned 08-31: keepers need escalated spawns).

---

## 6. LOCALIZATION LANE (Rex's explicit method — still partly open)

- Store 9-locale i18n: mostly complete (105 keys × 9), but session-memory
  09-01: **hi/yue catalogs 62/351 keys remain** (per-locale key gaps).
- Method mandate: DeepL first / Google second, NEVER MyMemory; gender =
  male subject ("Educador/Traductor/Creador", never -a). DeepL key needed.
- l10n-en-pass (local qwen2.5-3b English pass) was running detached as the
  no-key workaround — UNKNOWN if finished/verified.

---

## 7. MONEY / OUTREACH LANE

- 6 sends done (5 PRECISA + Lexi) from rhls.softdev@gmail.com (the only bot
  identity). Day-4 follow-ups pending. Sales = 0 (as of 09-02 memory).
- Stripe live, checkout verified, no sales yet.
- Blocker for posting launch post (dev.to/PH/HN/Reddit): Rex's accounts.
- **Ka-ching**: when the first Stripe payment lands, notify Rex — keeper
  intent, verify still armed.

---

## 8. PLANETARIUM / LM SCALE LANE

- Migration lane (make everything local/offline): Planetarium work must
  survive (handoff-20260901-migrate-planetarium).
- Scale: LM GUI from 6 langs / ~220 concepts → hundreds (handoff
  20260901-planetarium-scale). **C5 known gap:** LM API (eng/jpn/spa) and
  the offline/Texupan dataset were never unified — separate datasets by
  design, documented as open.

---

## 9. PRIORITIZED RECOMMENDATIONS (what to do with this inventory)

1. **P1 — Fix Texupan name at the pay moment**: rename Stripe product
   prod_VAKnoVjBzQxVI5 display to "Texupan — Offline Dictionary" (and
   monthly product if separate). ~1 API call. Assets `Core6-*` filenames:
   optional rename, low priority (links stable).
2. **P1 — Reconcile the "finish three apps" mandate**: decide Toscanini
   fate (ship toscanini-rs vs keep Kotlin deb), Ledgerly/Chén Báaxal EXE
   need (the win64 pipeline exists for other apps — 3 repos have .exe
   assets already, so the toolchain is proven).
3. **P2 — Update offline-dictionary-plan/ + ROADMAP naming** Core 6 →
   Texupan (docs only).
4. **P2 — Verify which detached keepers survived**; re-spawn escalated ones
   (mega-cycle, stripe-notify, outreach, api-gateway/tunnel, dashboard).
5. **P2 — Close hi/yue localization** (or explicitly defer with Rex).
6. **P3 — Archive vision-only projects** (paperclip, gearbox,
   software-generation-machine) into an attic/ so they stop looking active.
7. **Human-gated (Rex)**: Kaggle identity verification (unblocks
   distillation) · DeepL key (unblocks localization quality) · launch-post
   accounts · marketplace accounts.

---

## 10. VERIFICATION NOTES

- All 18 advertised store download links verified present in latest
  releases (API diff, 09-04).
- GitHub repos list confirmed: lingua-mundi(+launch), subtitle-toolkit,
  rhls-softdev.github.io, chen-baaxal, ledgerly(+launch), toscanini(+launch),
  kitchenos-launch, texupan(+launch), xokbil, shikibu, kitchenos,
  lingua-mundi-ops, awesome/awesome-selfhosted (research), private
  software-development-backup.
- Store platform claims: Texupan/Shikibu/LM-Dict/ST/KitchenOS all have
  deb+exe+apk+zip ✅. Ledgerly (deb+zip), Toscanini (deb only), Chén Báaxal
  (deb+zip), Texupan app (zip only) — the EXE-less set matches the open
  tickets above.

## 11. FIXES APPLIED (same session)

- **Stripe product prod_VAKnoVjBzQxVI5 renamed**: "Core 6 Offline Dictionary"
  → "Texupan — Offline Dictionary" (+ description). Checkout now matches the
  store card at the pay moment. Ids/prices/links untouched. Verified via API.
- **offline-dictionary-plan/ docs (ARCHITECTURE/PRICING/ROADMAP/DATA-SUBSET,
  PoC prose)**: Core 6 → Texupan. Code identifiers (Core6DictionaryProvider,
  core6-ja.sqlite, createCore6Provider) intentionally left — internal.
- **bundles/ design docs + copy**: Core 6 → Texupan prose.
- **.pricing-inventory.env**: comments updated.
- Live hub was already fully Texupan (verified: 0 occurrences of "Core 6"
  in index.html; bundles list items + i18n keys all Texupan).
- Root cause recorded: rename Core 6 → Texupan (2026-08-30/31) was applied
  to hub/landing but never propagated to the later Core-6 plan/Stripe work,
  which re-created the old name. Lesson: renames must include Stripe product
  names + plan docs, not just the storefront.

Remaining from this inventory (unchanged): §1 finish-three-apps gaps,
§2 distillation (human-gated), §4 dormant projects, §5 keeper verification,
§6 hi/yue localization, §7 outreach follow-ups, §8 Planetarium scale.
