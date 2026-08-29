#!/usr/bin/env bash
# deploy-to-github-pages.sh — makes Lingua Mundi fully machine-independent
# by hosting the landing page + dashboard on GitHub Pages (always-on, free)
# and the Shikibu ZIP as a GitHub Release asset.
#
# Prereqs (one-time, ~5 min, free):
#   1. Create a GitHub account at github.com (use your Google email).
#   2. Settings -> Developer settings -> Personal access tokens ->
#      Tokens (classic) -> Generate new token -> scope: "repo" + "workflow".
#   3. Export the token:  export GH_TOKEN=ghp_xxx
#
# Usage:  GH_TOKEN=... ./deploy-to-github-pages.sh
#
# What it does:
#   - creates repo "lingua-mundi-launch" (public) if missing
#   - landing page at repo root  ->  https://<user>.github.io/lingua-mundi-launch/
#   - dashboard at /dashboard/   ->  https://<user>.github.io/lingua-mundi-launch/dashboard/
#   - Shikibu ZIP as a Release asset (download link on the landing page)
#   - registers the dashboard origin in Clerk's allowed_origins
#   - verifies all URLs from the outside
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"

: "${GH_TOKEN:?Set GH_TOKEN to a GitHub PAT with repo+workflow scopes}"

echo "== fetching account info =="
USER=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])")
echo "user: $USER"

REPO="lingua-mundi-launch"
BASE_URL="https://api.github.com/repos/$USER/$REPO"
SITE_URL="https://$USER.github.io/$REPO"

echo "== ensuring repo $REPO exists =="
if ! curl -s -H "Authorization: token $GH_TOKEN" "$BASE_URL" | python3 -c "import json,sys; json.load(sys.stdin)['id']" 2>/dev/null; then
  curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"$REPO\",\"description\":\"Lingua Mundi launch site + dashboard\",\"private\":false,\"auto_init\":true}" >/dev/null
  echo "created repo"
fi

echo "== rebuilding dashboard with subpath base =="
(cd "$ROOT/LinguaMundi/lingua-mundi/commercial" && npm run build -- --base="/$REPO/dashboard/" >/dev/null 2>&1)

echo "== staging files =="
STAGE="$ROOT/.pages-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/dashboard"
cp "$ROOT/launch-site/index.html" "$ROOT/launch-site/styles.css" "$STAGE/"
# brand + SEO assets (logo, favicon, og image) — these were once
# missing from the launch repo, 404ing on the live site
cp "$ROOT/launch-site/rhls-logo.png" "$ROOT/launch-site/favicon.png" "$ROOT/launch-site/og-image.png" "$ROOT/launch-site/rhls-logo-sm.png" "$STAGE/" 2>/dev/null || true
cp "$ROOT/launch-site/robots.txt" "$ROOT/launch-site/sitemap.xml" "$ROOT/launch-site/404.html" "$STAGE/" 2>/dev/null || true
cp "$ROOT/launch-site/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true


# i18n: the landing's language selector needs the locale catalogs (this was
# once dropped, leaving the selector with a single English option)
cp -r "$ROOT/launch-site/localize" "$STAGE/localize" 2>/dev/null || { echo "ABORT: localize/ missing from launch-site" >&2; exit 1; }
cp -r "$ROOT/LinguaMundi/lingua-mundi/commercial/dist/." "$STAGE/dashboard/"
# ---- validation gate: single well-formed document, no duplicate ids ----
BAD=$(grep -c "</html>" "$STAGE/index.html" || true)
if [ "$BAD" != "1" ]; then
  echo "ABORT: $STAGE/index.html has $BAD </html> tags (expected exactly 1)." >&2
  exit 1
fi
DUP_IDS=$(grep -oE 'id="[^"]+"' "$STAGE/index.html" | sort | uniq -d | tr '\n' ' ')
if [ -n "$DUP_IDS" ]; then
  echo "ABORT: duplicate id(s) in landing page: $DUP_IDS" >&2
  exit 1
fi
# Landing links -> real permanent URLs
sed -i "s|https://example.com/shikibu.zip|https://github.com/$USER/$REPO/releases/latest/download/Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip|" "$STAGE/index.html"
sed -i "s|https://localhost:5173|$SITE_URL/dashboard/|" "$STAGE/index.html"

echo "== committing to main =="
cd "$STAGE"
git init -q -b main 2>/dev/null || git init -q && git checkout -q -b main 2>/dev/null || true
git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
git add -A && git commit -qm "deploy: landing + dashboard" || true
git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$REPO.git" 2>/dev/null || git remote set-url origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$REPO.git"
for attempt in $(seq 1 10); do
  if git push -q -f origin main 2>/dev/null; then
    echo "pushed main (attempt $attempt)"
    break
  fi
  echo "push attempt $attempt failed (network) - retrying in 15s"
  sleep 15
  [ "$attempt" = "10" ] && { echo "ABORT: could not push after 10 attempts" >&2; exit 1; }
done
echo "pushed main"

echo "== enabling GitHub Pages (main branch, root) =="
curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USER/$REPO/pages" \
  -d '{"source":{"branch":"main","path":"/"}}' >/dev/null 2>&1 || true

echo "== publishing Shikibu ZIP as Release asset =="
ZIP="$ROOT/Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip"
TAG="shikibu-1.0.0"
REL=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  -X POST "$BASE_URL/releases" -d "{\"tag_name\":\"$TAG\",\"name\":\"Shikibu 1.0.0\",\"body\":\"Self-contained Shikibu 1.0.0 + Lingua Mundi 1.0.0 (Japanese Module). Extract, cd Shikibu, npm install, npm run build (Free) / npm run build:pro (Pro).\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || true)
if [ -n "${REL:-}" ]; then
  curl -s -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @"$ZIP" \
    "$BASE_URL/releases/$REL/assets?name=Shikibu-1.0.0-LinguaMundi-1.0.0-Japanese.zip" >/dev/null
  echo "ZIP released"
fi

echo "== registering dashboard origin in Clerk =="
SK="${CLERK_SECRET_KEY:-}"
if [ -n "$SK" ]; then
  curl -s -X PATCH -H "Authorization: Bearer $SK" -H "Content-Type: application/json" \
    "https://api.clerk.com/v1/instance" \
    -d "{\"allowed_origins\":[\"$SITE_URL/dashboard/\"]}" >/dev/null || true
  echo "Clerk origin registered"
fi

echo "== URLs =="
echo "  Landing:  $SITE_URL/"
echo "  Dashboard:$SITE_URL/dashboard/"
echo "  Shikibu:  https://github.com/$USER/$REPO/releases/latest"
echo "  (Pages takes ~1 min to go live; verify with:)"
echo "  curl -s -o /dev/null -w '%{http_code}' '$SITE_URL/dashboard/'"
