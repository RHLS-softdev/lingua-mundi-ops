# Deployment Standards — RHLS Software Collection

Consult this document before any deploy, build, audit, or release. It
codifies the patterns, environment facts, and failure lessons learned
across the Lingua Mundi / Shikibu / Subtitle Toolkit / KitchenOS
deployments. Keep it updated when a deploy teaches you something new.

---

## 1. The one-paragraph architecture

Every product follows the same shape:

- **Source backup repo** (`RHLS-softdev/<product>`, public) — canonical
  source, pushed by backup scripts.
- **Launch repo** (`<product>-launch`, public) — GitHub Pages. Landing
  page at the repo root, web app under a subpath (`/app/`, `/premium/`,
  `/dashboard/`). **Never hand-edit these files** — rebuild via the ops
  scripts with the correct `--base`.
- **Release assets** — ZIP / .deb / APK attached to the launch repo's
  GitHub Release (tag = `product-version`, e.g. `subtitle-toolkit-0.2.0`).
- **Commercial layer** — one shared Clerk app + one Convex deployment per
  product + one Stripe account. The **Stripe webhook is the ONLY grant
  path** for paid access. See `WIRING-GUIDE.md`.

## 2. Repo topology (9 repos)

| Repo | Visibility | Role |
|---|---|---|
| `lingua-mundi` | public | Dictionary/API engine + data pipelines |
| `shikibu` | public | EPUB editor (React + TipTap + sql.js) |
| `subtitle-toolkit` | public | SRT tools (React, fully in-browser) |
| `kitchenos` | public | Offline restaurant kitchen manager |
| `lingua-mundi-launch` | public | LM landing + dashboard (`/dashboard/`) + Shikibu release |
| `subtitle-toolkit-launch` | public | ST landing + app (`/app/`) |
| `kitchenos-launch` | public | KitchenOS landing + premium app (`/premium/`) |
| `lingua-mundi-ops` | public | Deploy/audit/backup scripts + docs + launch-site sources |
| `software-development-backup` | **private** | Chat/terminal logs + mirrored source — never public |

Hub site repo: `rhls-softdev/rhls-softdev.github.io` (the main page).

## 3. Live URLs

| Site | URL |
|---|---|
| Hub | `https://rhls-softdev.github.io/` |
| Subtitle Toolkit | `https://rhls-softdev.github.io/subtitle-toolkit-launch/` (+ `/app/`) |
| KitchenOS | `https://rhls-softdev.github.io/kitchenos-launch/` (+ `/premium/`) |
| Lingua Mundi | `https://rhls-softdev.github.io/lingua-mundi-launch/` (+ `/dashboard/`) |

## 4. Release assets (current)

| Repo / tag | Assets |
|---|---|
| `subtitle-toolkit-launch` `subtitle-toolkit-0.2.0` | `Subtitle-Toolkit-0.2.0.zip`, `Subtitle-Toolkit-0.2.0-android.apk` |
| `kitchenos-launch` `kitchenos-0.6.0` | `KitchenOS-0.6.0-linux-amd64.deb` (583 MB), `KitchenOS-0.6.0-source.zip`, `KitchenOS-Premium-0.6.0-android.apk` |
| `lingua-mundi-launch` `shikibu-1.0.0` | `Shikibu-1.0.0-android.apk`, `Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip` |

**Replacing a same-named asset requires delete-then-upload** — the GitHub
API rejects duplicate filenames. `deploy-android.sh` already does this.

## 5. Workspace & environment facts

- Workspace root: `/home/rex/Documentos/Software Development/DeepSeek Harness`
  (writable). Everything else under `/home/rex` appears read-only to the
  sandbox — writes outside the workspace need `danger-full-access`
  escalation (user-approved pattern).
- **`/tmp` is per-command** — never persist state there across commands.
- Android SDK must live at a spaceless path: `/home/rex/Descargas/androidsdk`
  (`sdkmanager` breaks on spaces in the workspace path).
- Gradle: `GRADLE_USER_HOME="$W/.gradle"`, `ANDROID_USER_HOME="$W/.android"`,
  `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`.
- npm cache: `NPM_CONFIG_CACHE="$W/.npm-cache"`.
- GH PAT (fine-grained, repo+workflow): set in `~/.local/bin/github-backup-sync.sh`
  and passed as `GH_TOKEN` to deploy scripts. **Never commit it.**
- systemd user timers (e.g. vault-nightly at 03:00) live in
  `~/.config/systemd/user/*.{service,timer}` + `timers.target.wants` symlink;
  the sandbox can't reach the user bus, so timers activate at next login.
- Clone/push operations are on a flaky network — always use a retry loop
  (see §10).

## 6. Web build standards

1. Vite default base = root-relative (`/assets/…`) — this is what the
   **APK bundle** needs (Capacitor `webDir`).
2. Launch deploys rebuild with the **subpath base**:
   - ST: `npm run build -- --base=/subtitle-toolkit-launch/app/`
   - KitchenOS premium: `--base=/kitchenos-launch/premium/`
   - LM dashboard: `--base=/lingua-mundi-launch/dashboard/`
3. After a subpath build, prefix the favicon: the deploy scripts `sed`
   `href="/favicon.svg"` → `href="${APP_BASE}favicon.svg"`.
4. Landing-page sources live in `subtitle-toolkit-launch-site/`,
   `kitchenos-launch-site/`, `launch-site/` (each with `index.html`,
   `styles.css`, `localize/`, `rhls-logo.png`, `favicon.png`, README,
   AGENTS.md). Deploy scripts stage these + the built app into a fresh
   git repo and force-push to `main`.
5. **Never hand-edit launch repo output.** Rebuild + push via the ops
   scripts only.
6. `cp -r src target` with an existing target **nests** (`localize/localize/`)
   — copy *contents* (`cp -r src/. target/`) or clean the target first.

## 7. Android companion standards

- Capacitor 8.5 wrappers; appIds `com.subtitletoolkit.app`,
  `com.kitchenos.premium`, `com.shikibu.app`; keystore
  `android-keys/release.keystore` (alias `kitos`, pass `kitos-android-2026`).
- `webDir` points at the web build: `../.subtitle-toolkit-build/dist`,
  `../.kitchenos-build/enterprise/dist`, `../Shikibu/dist`.
- **APKs are WebViews of the web apps** — APK responsiveness == web app
  responsiveness. Fix the CSS, rebuild web (root base), `npx cap copy
  android`, then Gradle.
- Pipeline: `build-android-all.sh [--rebuild]` (sequential, shared gradle
  cache, skips existing APKs unless `--rebuild`) → `verify-android.sh`
  (badging, signature, size) → `deploy-android.sh` (delete-then-upload to
  the release tags + landing pages).
- Gradle gotchas:
  - `signingConfig()` must sit inside `buildTypes.release`, not in
    `signingConfigs` (fix all three `android/app/build.gradle` if it moves).
  - Stale absolute paths from a copied `target/` break the first build —
    `cargo clean` + fresh build.
  - First builds take ~35 min; transient failures rebuild fine. Run as a
    background job.

### Responsive / mobile standards (applies to every web app + APK)

- `viewport` meta present in every `index.html`:
  `width=device-width, initial-scale=1.0`.
- Media queries at ≤900 / ≤768 / ≤480 px.
- Rules that work (proven on Shikibu/ST/KitchenOS):
  - Let header/action bars **wrap** (flex-wrap + smaller padding) instead
    of overflowing.
  - Cap fixed sidebars: `width: min(46vw, 220px) !important` (beats the
    inline `style={{width}}`); hide mouse-only resize handles.
  - Inspectors/panels become **full-width bottom sheets** on mobile
    (`flex: 1 1 100%; width: 100% !important; max-height: 42vh; border-top`).
  - Toolbar groups wrap internally (`flex-wrap: wrap; row-gap: 2px`).
  - Modals: `max-height: 92vh; overflow-y: auto`; collapse multi-column
    grids to 1–2 cols.
  - Kill horizontal overflow: tables get `overflow-x: auto`, grids shrink,
    status text hides on tiny screens.
- **Verify at a phone viewport deterministically** (headless chromium;
  the harness model can't view screenshots, so measure instead):
  serve the dist, then dump DOM of a checker page that iframes the app at
  390×844 and reports `scrollWidth` vs `clientWidth` + widest overflowing
  elements. Assert `overflowX: false`. Repeat at 768 and 480.
  - Chromium headless: give each invocation a fresh `--user-data-dir`
    (shared profiles lock and error "Multiple targets are not supported").
  - Don't `pkill -f` with a pattern that matches your own command line
    (kills the job itself, exit 143).
  - Use `--virtual-time-budget=8000` so `setTimeout` in the checker runs.
  - The `(cmd &)` background trick dies with the shell — start servers as
    managed background jobs with `workdir` set, not with `&`.

## 8. Commercial layer standards (Convex + Clerk + Stripe)

Full step-by-step: `WIRING-GUIDE.md`. Constants:

- Shared Clerk app: `loved-gobbler-9439`; issuer domain
  `https://loved-gobbler-9439.clerk.accounts.dev`; publishable key
  `pk_test_bG92ZWQtZ29iYmxlci05NDM5LmNsZXJrLmFjY291bnRzLmRldiQ`; JWT template
  named exactly `convex`.
- One Convex deployment per product (LM live: `dusty-turtle-795.convex.cloud`;
  ST + KitchenOS pending user's account).
- Webhook URL shape: `https://<deployment>.convex.site/stripe/webhook`.
- Env vars (set via `npx convex env set`, per deployment):
  - `CLERK_JWT_ISSUER_DOMAIN` (same for all)
  - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
  - `DASHBOARD_URL` (the app's live origin)
  - `STRIPE_PRO_PRICE_ID` / `STRIPE_PREMIUM_PRICE_ID` (optional for
    ST/KitchenOS — inline $9 / $50-mo fallbacks exist; **required** for LM)
  - LM only: `LINGUA_MUNDI_API_URL`, `LINGUA_MUNDI_INTERNAL_SECRET`
    (must match `api/settings.py`; header `x-internal-secret`)
- Webhook events: ST reads only `checkout.session.completed`; KitchenOS
  and LM also read `customer.subscription.updated` + `.deleted`.
- Clerk origins registered per product (`CLERK_SECRET_KEY` exported lets
  the deploy scripts register them automatically).
- Pricing: ST Pro $9 one-time; KitchenOS Premium $50/mo per kitchen;
  LM Phase 0 pricing still open (see `lingua-mundi-phase0-freeze.md`).
- Degraded mode: until env vars exist, the paid UI shows "store not
  connected" instead of breaking — keep that behavior.

## 9. i18n / localization standards

- Locales: BCP 47 — `en` (base), `es`, `ja`, `zh-Hans`, `zh-Hant`, `yue`
  (Traditional chars + Cantonese), `hi`, `ar` (**RTL**, `dir="rtl"`), `ko`.
- Single source of truth: `localize/catalogs.py` (~105 keys × 9 locales) →
  `build.py` (validates; `INTENTIONAL_IDENTICAL` allowlist for legitimately
  identical strings) → `locales/<tag>.js` (static sites) + `app-locales.ts`
  (React apps).
- `t()` API shaped like i18next; use `Intl` APIs; set `lang`/`dir` on
  `<html>` at init (`syncDom()`), not just on text.
- Runtime resolution order: `?lang=` > localStorage > `navigator.language`.
  `?lang=` works over `http://` but **not** `file://`.
- Every page ships a language switcher; Arabic is RTL; zh-Hans/zh-Hant/yue
  are independent, not fallbacks of each other.
- Deploy: `deploy-localize.sh`; keep `localize/` carried by the deploy
  scripts (it was dropped once by a fresh stage).

## 10. Operations & verification standards

- **Deterministic scripts + background jobs.** Never idle-poll: run long
  work as a background job and rely on completion notices. Kill jobs that
  stop mattering.
- **Fail loudly.** Scripts `set -uo pipefail`, check `[exit code: N]`
  markers, and exit non-zero on problems (see `verify-android.sh`).
- **Retry flaky network** pushes: 3-attempt loop with `git http.postBuffer
  524288000` in `github-backup-sync.sh`; ops backup retries up to 20×/20s.
- **Links audit** (`audit-links.sh`): scan `href`/`src`/`script`-embedded
  URLs; skip `mailto:`, `tel:`, `#`; the first version missed JS-embedded
  URLs and mis-parsed `#*)` case patterns (quote `"#"*`). Target: 0 broken
  links across all pages + READMEs; `?lang=` links and release assets 200.
- **Repo-visibility audit** (`audit-repo-visibility.sh`): no secrets in any
  repo (PAT, surge cred, keystore password, `.env*`). 8 public + 1 private
  verified clean.
- **Backup hygiene** (`backup-to-github.sh`): exclude `node_modules/dist/
  target/build/venv/models/datasets/binaries/instance`, `.deb-test`,
  `.chromium-pro-test`, `.clerk-cli`, `.tmp-wn`, `.surge-cred`,
  `*.apk/*.deb/*.zip/*.sqlite`, `.env*`, `android-keys`, scratch stages.
  `rsync --delete` does **not** remove already-excluded junk in the
  destination — do a one-time manual cleanup + history reset.
- **Large uploads** (583 MB .deb) exceed the 60 s command cap — always a
  background job.

## 11. Branding standards

- Palette: `#004070` (primary), `#0060a0` (accent), `#101418` (ink),
  `#f5f6f8` (background). **Solid colors, no gradients.**
- Logo: `brand/rhls-logo.png` + `favicon.png` on the hub and every landing
  page (from `The Vault/Files/Images/Logo de Rex Hernández Servicios
  Lingüísticos.png`).
- Every deployed app links to/from Convex, Clerk and Stripe (per their
  tier); every README opens with links to the localized versions.

## 12. Golden rules

1. Webhook is the only grant path. Never grant paid access anywhere else.
2. Rebuild launch repos, never hand-edit them.
3. Root base for APKs, subpath base for Pages.
4. Delete-then-upload to replace release assets.
5. Verify before declaring done: links 200, APK signature OK, phone
   viewport overflowX=false.
6. Keep the free tier fully functional without the commercial layer.
7. When in doubt, run the deterministic script — don't improvise.
8. **Landing pages must be single well-formed documents.** Every deploy
   script has a validation gate: exactly one `</html>`, no duplicate
   `id=` attributes, or the deploy ABORTS (a duplicated tail once shipped
   to production).
9. **Secrets never live in source or tars.** Keystore passwords live in
   `android-keys/keystore.properties` (mode 600, excluded from every
   backup); tar excludes use `*/node_modules` (matches nested dirs, which
   `./node_modules` misses — `commercial/node_modules` was once pushed);
   `android-keys/`, `.convex/`, `.env.*`, `.wire-*` are always excluded
   from the workspace-root ops backup.
10. **Never hardcode a service name from memory.** The Clerk app is
    `loved-gobbler-9439` (one "v") — a typo'd "lovely" propagated through
    docs and broke auth. Verify against the publishable key's base64
    decode or the live dashboard, never from memory.
11. **Claims on landing pages must match shipped artifacts.** No
    "macOS/Windows/Linux" if only an APK + source ZIP ship; no "$9/mo Pro
    plan" if the API isn't hosted. Re-audit copy whenever a feature ships
    or doesn't.
12. **Flaky network pushes need a retry loop** (10× 15s) — `git push`
    fails with HTTP 408/RPC errors on this machine's DNS; the loop is
    built into every deploy script.
13. **Never poll `job_output` — scripts alert, agents act.** Long work runs
    as one background job whose script prints its own loud `DONE` /
    `FAILED` line (and writes a log artifact). The agent acts on the
    completion notice only; it does not sit in `job_output` waits. This is
    the user's standing global directive — it applies to every session and
    every tool.
14. **Every asset a page references must be carried by its deploy script.**
    The three launch sites 404'd on `rhls-logo.png`/`favicon.png` because
    the deploy scripts only copied `index.html` + `styles.css` (+
    `localize/`). Deploy scripts copy the full referenced asset set:
    `rhls-logo.png`, `favicon.png`, `og-image.png` (a 96 KB 512 px
    downscale — never the 1.4 MB logo — used by og:image/twitter:image).
    `og:image` tags must point at files that actually ship.
15. **Reminders always go on the DSH calendar.** When the user asks for a
    reminder / alert / "remind me", add a dated event via
    `calendar-tool.sh add "<title>" <date> <HH:MM> [details]` (canonical
    file `.calendar/dsh-calendar.ics`). This is the standing global
    directive — do not invent ad-hoc alert mechanisms. (Examples in the
    calendar: key rotation 2026-08-29 20:00, vault-nightly 03:00.)
16. **Never silent-fetch + force-push a staged tree.** A license re-push
    used `git fetch 2>/dev/null || git checkout -b main` then
    `git push -f` — when the flaky network made the fetch fail silently,
    an empty tree + license files force-pushed over three public source
    repos, wiping them to 2 files each (audit pass 3). Rules:
    (a) a fetch failure is FATAL, never a fallback to an empty branch;
    (b) before any force-push of a "source backup" repo, assert the
    staged tree actually contains source (marker file + ≥10 files) —
    `repair-source-repos.sh` implements this (`assert_source`);
    (c) recovery = re-stage from the local tree and push with the gate.
17. **Never persist the PAT into `.git/config`.** Deploy scripts set the
    remote with `https://x-access-token:$GH_TOKEN@…`, leaving the token
    in 45+ `.git/config` files (audit pass 3). Rules:
    (a) push with the token inline in the command
    (`git push https://x-access-token:$GH_TOKEN@github.com/… main`),
    never via the persisted remote URL;
    (b) after any push, scrub `x-access-token:github_pat…` from
    `.git/config` (the workspace-wide scrub is a `find … -path
    '*/.git/config' -exec sed -i …` one-liner);
    (c) run the scrub before any audit, backup, or rotation.
18. **Never hand-roll a one-off subset push to a repo.** Every wipe in
    this incident chain came from a bespoke `git init` + silent-fetch +
    `git checkout -B main FETCH_HEAD || git checkout -b main` +
    `push -f` in an ad-hoc update script — when the fetch fails silently
    (flaky DNS), the fallback creates an empty branch and the force-push
    replaces the whole repo with a few staged files. Rules:
    (a) repo updates go through the gated full-replacement tools
    (`repair-source-repos.sh`, `repair-ops-repo.sh`) which assert staged
    content before pushing, or through `git clone` + modify + push
    (clone fails loudly, no silent fallback);
    (b) a fetch failure is ALWAYS fatal — never `|| git checkout -b`;
    (c) if a push seems to need the subset pattern, it's a signal to use
    the gated tool instead.
19. **Stripe webhook handlers on Convex must use `constructEventAsync`,
    never the sync `constructEvent`.** Convex's runtime uses the WebCrypto
    `SubtleCryptoProvider`, which cannot run synchronously — the sync
    variant throws "SubtleCryptoProvider cannot be used in a synchronous
    context" and every real webhook fails (customers pay, never get Pro).
    A synthetic-webhook test (sign an event with the endpoint's real
    secret, POST it, expect 200) is the **zero-cost** way to verify the
    money path before launch — the same thing Stripe's dashboard "Send
    test webhook" does, no card needed. The launch-blocking bug in all
    three products was caught exactly this way (audit pass §14).
20. **Use the orchestration primitives to save context.** The `workflow`,
    `subagent`, and `subagent_fork` tools exist so fan-out work (audits,
    multi-product verification, independent checks) runs in child contexts
    and returns one compact structured result — not in the main thread.
    Rules: (a) fan out independent verification to a workflow with a JSON
    schema for the result; (b) a workflow agent's prompt must be fully
    self-contained (it does not see this conversation); (c) verify a
    workflow's claims before acting — agents can mis-report (e.g. "convex
    URL missing" was a false alarm: only the main bundle was checked, not
    the lazy chunk); (d) keep the main thread for decisions and pushes,
    delegate the checking.
