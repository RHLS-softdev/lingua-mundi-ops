#!/usr/bin/env bash
# deploy-subtitle-toolkit.sh — deploys Subtitle Toolkit the same way Shikibu
# was deployed: GitHub Pages for the landing page + app (always-on, free),
# and the release ZIP as a GitHub Release asset.
#
# Creates/hosts:
#   repo: subtitle-toolkit-launch  (public, mirror of lingua-mundi-launch)
#   landing page at repo root      -> https://<user>.github.io/subtitle-toolkit-launch/
#   app at /app/                   -> https://<user>.github.io/subtitle-toolkit-launch/app/
#   Subtitle-Toolkit-0.2.0.zip as a Release asset (download link on the landing page)
#
# Prereqs: GH_TOKEN env var (GitHub PAT with repo+workflow scopes) —
# same one used for the Shikibu deployment.
#
# Usage:  GH_TOKEN=... ./deploy-subtitle-toolkit.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"

: "${GH_TOKEN:?Set GH_TOKEN to a GitHub PAT with repo+workflow scopes}"
# Source project: default = workspace copy of "Subtitle Toolkit - Final/src"
STK_SRC="${STK_SRC:-$ROOT/.subtitle-toolkit-build}"

VERSION="0.2.0"
REPO="subtitle-toolkit-launch"
ZIP_NAME="Subtitle-Toolkit-$VERSION.zip"
SITE_URL="https://rhls-softdev.github.io/$REPO"
APP_BASE="/$REPO/app/"

echo "== fetching account info =="
USER=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])")
echo "user: $USER"
BASE_URL="https://api.github.com/repos/$USER/$REPO"

echo "== ensuring repo $REPO exists =="
if ! curl -s -H "Authorization: token $GH_TOKEN" "$BASE_URL" | python3 -c "import json,sys; json.load(sys.stdin)['id']" 2>/dev/null; then
  curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"$REPO\",\"description\":\"Subtitle Toolkit launch site + app (GitHub Pages)\",\"private\":false,\"auto_init\":true}" >/dev/null
  echo "created repo"
fi

echo "== building app with subpath base $APP_BASE =="
(cd "$STK_SRC" && NPM_CONFIG_CACHE="$ROOT/.npm-cache" npm run build -- --base="$APP_BASE" >/dev/null 2>&1)
# favicon lives in public/ and Vite keeps it at an absolute path — prefix it
# so it resolves under the subpath too.
sed -i "s|href=\"/favicon.svg\"|href=\"${APP_BASE}favicon.svg\"|" "$STK_SRC/dist/index.html"

echo "== staging files =="
STAGE="$ROOT/.subtitle-toolkit-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/app"
# Landing page for Subtitle Toolkit (checked in next to this script)
cp "$ROOT/subtitle-toolkit-launch-site/index.html" "$ROOT/subtitle-toolkit-launch-site/styles.css" "$STAGE/"
# brand + SEO assets (logo, favicon, og image) — these were once
# missing from the launch repo, 404ing on the live site
cp "$ROOT/subtitle-toolkit-launch-site/rhls-logo.png" "$ROOT/subtitle-toolkit-launch-site/favicon.png" "$ROOT/subtitle-toolkit-launch-site/og-image.png" "$ROOT/subtitle-toolkit-launch-site/rhls-logo-sm.png" "$STAGE/" 2>/dev/null || true
cp "$ROOT/subtitle-toolkit-launch-site/robots.txt" "$ROOT/subtitle-toolkit-launch-site/sitemap.xml" "$ROOT/subtitle-toolkit-launch-site/404.html" "$STAGE/" 2>/dev/null || true
cp "$ROOT/subtitle-toolkit-launch-site/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true


cp -r "$ROOT/subtitle-toolkit-launch-site/localize" "$STAGE/localize" 2>/dev/null || true
cp -r "$STK_SRC/dist/." "$STAGE/app/"
# ---- validation gate: the landing page must be a single well-formed doc ----
# (a duplicated </html> tail was shipped once; fail the deploy instead of
#  publishing corruption again)
BAD=$(grep -c "</html>" "$STAGE/index.html" || true)
if [ "$BAD" != "1" ]; then
  echo "ABORT: $STAGE/index.html has $BAD </html> tags (expected exactly 1). Fix the source first." >&2
  exit 1
fi
DUP_IDS=$(grep -oE 'id="[^"]+"' "$STAGE/index.html" | sort | uniq -d | tr '\n' ' ')
if [ -n "$DUP_IDS" ]; then
  echo "ABORT: duplicate id(s) in landing page: $DUP_IDS" >&2
  exit 1
fi
echo "validation gate: landing page OK (1 </html>, no duplicate ids)"
# Landing links -> real permanent URLs
sed -i "s|https://github.com/RHLS-softdev/subtitle-toolkit-launch/releases/latest/download/Subtitle-Toolkit-0.1.0.zip|https://github.com/$USER/$REPO/releases/latest/download/$ZIP_NAME|" "$STAGE/index.html"
sed -i "s|https://github.com/RHLS-softdev/subtitle-toolkit-launch/releases/latest/download/Subtitle-Toolkit-0.2.0.zip|https://github.com/$USER/$REPO/releases/latest/download/$ZIP_NAME|" "$STAGE/index.html"

echo "== committing to main =="
cd "$STAGE"
git init -q -b main 2>/dev/null || (git init -q && git checkout -q -b main 2>/dev/null || true)
git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
git add -A && git commit -qm "deploy: landing + Subtitle Toolkit app" || true
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

echo "== enabling GitHub Pages (main branch, root) =="
curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USER/$REPO/pages" \
  -d '{"source":{"branch":"main","path":"/"}}' >/dev/null 2>&1 || true

echo "== publishing ZIP as Release asset =="
ZIP="$ROOT/$ZIP_NAME"
if [ ! -f "$ZIP" ]; then
  echo "  building $ZIP from project source (excl. node_modules/dist) + fresh dist"
  PKG="$ROOT/.subtitle-toolkit-release-src"
  rm -rf "$PKG"; mkdir -p "$PKG/$VERSION"
  tar --exclude=./node_modules --exclude=./.git --exclude=./tsconfig.tsbuildinfo \
      --exclude=./convex/_generated --exclude=./.env.local --exclude=./.env \
      -C "$STK_SRC" -cf - . | tar -C "$PKG/$VERSION" -xf -
  # keep the just-built subpath dist AND a default-base dist for local use
  rm -rf "$PKG/$VERSION/dist"
  (cd "$STK_SRC" && NPM_CONFIG_CACHE="$ROOT/.npm-cache" npm run build >/dev/null 2>&1)
  cp -r "$STK_SRC/dist" "$PKG/$VERSION/dist"
  (cd "$PKG" && zip -qr "$ZIP" "$VERSION")
  rm -rf "$PKG"
  echo "  zip ready: $ZIP"
fi
echo "== registering app origin in Clerk (if CLERK_SECRET_KEY set) =="
SK="${CLERK_SECRET_KEY:-}"
if [ -n "$SK" ]; then
  curl -s -X PATCH -H "Authorization: Bearer $SK" -H "Content-Type: application/json" \
    "https://api.clerk.com/v1/instance" \
    -d "{\"allowed_origins\":[\"$SITE_URL/app/\"]}" >/dev/null || true
  echo "Clerk origin registered: $SITE_URL/app/"
else
  echo "  (CLERK_SECRET_KEY not set — skipping Clerk origin registration; see SETUP.md)"
fi
TAG="subtitle-toolkit-$VERSION"
REL=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  -X POST "$BASE_URL/releases" -d "{\"tag_name\":\"$TAG\",\"name\":\"Subtitle Toolkit $VERSION\",\"body\":\"Subtitle Toolkit $VERSION — free single-file SRT tools plus Pro (\$9 one-time): batch processing with ZIP output, batch video extraction, saved presets. Everything runs in the browser; extract, cd $VERSION, npm install, npm run dev (or serve the prebuilt dist/). See SETUP.md to connect the Pro store (Convex+Clerk+Stripe).\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || true)
if [ -n "${REL:-}" ]; then
  # uploads.github.com is the real endpoint; api.github.com only 302s there,
  # so -L is required (this bit us the first run — asset silently missing).
  curl -sL -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @"$ZIP" \
    "https://uploads.github.com/repos/$USER/$REPO/releases/$REL/assets?name=$ZIP_NAME" >/dev/null
  echo "ZIP released"
fi

echo "== URLs =="
echo "  Landing: $SITE_URL/"
echo "  App:     $SITE_URL/app/"
echo "  ZIP:     https://github.com/$USER/$REPO/releases/latest"
echo "  (Pages takes ~1 min to go live; verify with:)"
echo "  curl -s -o /dev/null -w '%{http_code}' '$SITE_URL/app/'"
