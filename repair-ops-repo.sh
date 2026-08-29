#!/usr/bin/env bash
# repair-ops-repo.sh — restores lingua-mundi-ops (wiped to 3 files by the
# pass-3 force-push). Stages the canonical ops scripts + docs + launch-site,
# asserts content, pushes with token inline + scrub (rules 16/17).
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export GH_TOKEN=$(grep '^GH_TOKEN=' "$W/.env.wire" | cut -d= -f2-)
fail() { echo "[ops-repair] ERROR: $*" >&2; exit 1; }

STAGE="$W/.ops-repair-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE"

# ---- scripts (canonical set from workspace root) ----
cp "$W"/deploy-subtitle-toolkit.sh "$W"/deploy-kitchenos.sh \
   "$W"/deploy-to-github-pages.sh "$W"/deploy-android.sh \
   "$W"/deploy-st-gate.sh "$W"/deploy-seo.sh "$W"/deploy-brand.sh \
   "$W"/deploy-docs.sh "$W"/deploy-localize.sh \
   "$W"/backup-to-github.sh "$W"/backup-subtitle-toolkit.sh \
   "$W"/backup-kitchenos.sh "$W"/backup-manager.sh \
   "$W"/audit-links.sh "$W"/audit-repo-visibility.sh \
   "$W"/finish-release.sh "$W"/finish-ops-backup.sh \
   "$W"/wire-commercial.sh "$W"/verify-wiring.sh \
   "$W"/create-prices.sh "$W"/redeploy-all-sites.sh \
   "$W"/repair-source-repos.sh "$W"/repair-ops-repo.sh \
   "$W"/progress.sh "$W"/calendar-tool.sh "$W"/build-android-all.sh \
   "$STAGE/" 2>/dev/null || true
# build-*.py helpers
cp "$W"/build-wn-tab.py "$W"/build-merosu-epub.py "$W"/create-knowledge-base.sh "$STAGE/" 2>/dev/null || true

# ---- docs ----
cp "$W/lingua-mundi-ops/AUDIT-STATUS-REPORT.md" "$W/lingua-mundi-ops/STRIPE-TASKS.md" \
   "$W/lingua-mundi-ops/WIRING-GUIDE.md" "$W/lingua-mundi-ops/WIRING-GUIDE-SIMPLE.md" \
   "$W/DEPLOYMENT-STANDARDS.md" "$STAGE/" 2>/dev/null || true
cp "$W/Shikibu/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true
# RESUME-STATE if present
[ -f "$W/RESUME-STATE.md" ] && cp "$W/RESUME-STATE.md" "$STAGE/" 2>/dev/null

# ---- README + AGENTS for the ops repo ----
cat > "$STAGE/README.md" <<'EOF'
# lingua-mundi-ops

Operational scripts + release state for the RHLS software collection
(Lingua Mundi, Shikibu, Subtitle Toolkit, KitchenOS).

- **Deploy**: `deploy-*.sh` (landing + app/dashboard to GitHub Pages),
  `deploy-android.sh` (APK release assets), `deploy-st-gate.sh`
  (validated Subtitle Toolkit deploy).
- **Backup**: `backup-to-github.sh` (source repos, secrets excluded),
  `backup-subtitle-toolkit.sh`, `backup-kitchenos.sh`.
- **Audit**: `audit-links.sh`, `audit-repo-visibility.sh`.
- **Wiring**: `wire-commercial.sh` (Convex/Clerk/Stripe), `create-prices.sh`,
  `verify-wiring.sh` — see `WIRING-GUIDE.md` (technical) and
  `WIRING-GUIDE-SIMPLE.md` (plain English).
- **Repair**: `repair-source-repos.sh`, `repair-ops-repo.sh`.
- **Docs**: `DEPLOYMENT-STANDARDS.md` (golden rules incl. 16-17),
  `AUDIT-STATUS-REPORT.md`, `STRIPE-TASKS.md`.
- **Landing source**: `launch-site/` (Lingua Mundi / Shikibu landing).

See `AGENTS.md` for agent instructions.
EOF
cat > "$STAGE/AGENTS.md" <<'EOF'
# Agent instructions — lingua-mundi-ops

Operational scripts + release state for the RHLS collection.

## Golden rules (full: DEPLOYMENT-STANDARDS.md)

16. Never silent-fetch + force-push a staged tree. Assert the staged tree
    contains real content before pushing (`assert_source` in
    repair-*-repo.sh); a fetch failure is fatal.
17. Never persist the PAT into `.git/config`. Push with the token inline;
    scrub `x-access-token:github_pat…` from configs after any push.

## Deploying from here

- Launch sites: run `deploy-<product>.sh` (rebuilds with subpath base).
- Android: `build-android-all.sh` then `deploy-android.sh`.
- Commercial wiring: `wire-commercial.sh` (reads `.env.wire`, excluded
  from backups).
EOF

# ---- launch-site (LM landing source) ----
cp -r "$W/launch-site" "$STAGE/launch-site" 2>/dev/null || fail "launch-site missing"

# ---- assert content before pushing ----
N=$(find "$STAGE" -type f ! -path "*/.git/*" | wc -l)
[ "$N" -ge 25 ] || fail "staged only $N files — NOT pushing"
[ -f "$STAGE/deploy-subtitle-toolkit.sh" ] || fail "missing deploy-subtitle-toolkit.sh"
[ -f "$STAGE/launch-site/index.html" ] || fail "missing launch-site/index.html"
echo "[ops-repair] staged $N files — content confirmed"

# ---- push (clean URL in config; token inline; scrub after) ----
cd "$STAGE" || exit 1
git init -q -b main 2>/dev/null || true
git config user.email "rhls.softdev@gmail.com"; git config user.name "RHLS-softdev"
git config http.postBuffer 524288000
git remote add origin "https://github.com/RHLS-softdev/lingua-mundi-ops.git" 2>/dev/null
git add -A
git -c user.email="rhls.softdev@gmail.com" -c user.name="RHLS-softdev" commit -qm "restore: full ops repo (was wiped by pass-3 force-push); scripts + docs + launch-site" 2>&1 | head -1
for attempt in $(seq 1 20); do
  if timeout 300 git push -q -f "https://x-access-token:$GH_TOKEN@github.com/RHLS-softdev/lingua-mundi-ops.git" main 2>/dev/null; then
    echo "[ops-repair] PUSHED (attempt $attempt)"
    sed -i 's|x-access-token:github_pat[^@]*@|x-access-token:<rotated>@|g' .git/config 2>/dev/null
    rm -rf "$STAGE"
    echo "[ops-repair] DONE"
    exit 0
  fi
  echo "[ops-repair] push attempt $attempt failed - retry 15s"
  sleep 15
done
echo "[ops-repair] FAILED"
exit 1
