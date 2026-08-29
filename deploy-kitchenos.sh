#!/usr/bin/env bash
# deploy-kitchenos.sh — deploys KitchenOS the same way Subtitle Toolkit and
# Shikibu were deployed: GitHub Pages for the landing page + premium web
# app, and the free desktop installer + source ZIP as Release assets.
#
# Creates/hosts:
#   repo: kitchenos-launch          (public, mirror of subtitle-toolkit-launch)
#   landing page at repo root       -> https://<user>.github.io/kitchenos-launch/
#   premium web app at /premium/    -> https://<user>.github.io/kitchenos-launch/premium/
#   KitchenOS-0.6.0-linux-amd64.deb + KitchenOS-0.6.0-source.zip as Release assets
#
# Prereqs: GH_TOKEN env var (GitHub PAT with repo+workflow scopes) —
# same one used for the previous deployments.
#
# Usage:  GH_TOKEN=... ./deploy-kitchenos.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"

: "${GH_TOKEN:?Set GH_TOKEN to a GitHub PAT with repo+workflow scopes}"
# Project: workspace copy of "Carpeta sin título/KitchenOS"
STK_SRC="${STK_SRC:-$ROOT/.kitchenos-build}"

VERSION="0.6.0"
REPO="kitchenos-launch"
DEB_NAME="KitchenOS-$VERSION-linux-amd64.deb"
ZIP_NAME="KitchenOS-$VERSION-source.zip"
SITE_URL="https://rhls-softdev.github.io/$REPO"
APP_BASE="/$REPO/premium/"

echo "== fetching account info =="
USER=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])")
echo "user: $USER"
BASE_URL="https://api.github.com/repos/$USER/$REPO"

echo "== ensuring repo $REPO exists =="
if ! curl -s -H "Authorization: token $GH_TOKEN" "$BASE_URL" | python3 -c "import json,sys; json.load(sys.stdin)['id']" 2>/dev/null; then
  curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"$REPO\",\"description\":\"KitchenOS launch site + premium web app (GitHub Pages)\",\"private\":false,\"auto_init\":true}" >/dev/null
  echo "created repo"
fi

echo "== building premium web app with subpath base $APP_BASE =="
(cd "$STK_SRC/enterprise" && NPM_CONFIG_CACHE="$ROOT/.npm-cache" npm run build -- --base="$APP_BASE" >/dev/null 2>&1)

echo "== staging files =="
STAGE="$ROOT/.kitchenos-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/premium"
cp "$ROOT/kitchenos-launch-site/index.html" "$ROOT/kitchenos-launch-site/styles.css" "$STAGE/"
# brand + SEO assets (logo, favicon, og image) — these were once
# missing from the launch repo, 404ing on the live site
cp "$ROOT/kitchenos-launch-site/rhls-logo.png" "$ROOT/kitchenos-launch-site/favicon.png" "$ROOT/kitchenos-launch-site/og-image.png" "$ROOT/kitchenos-launch-site/rhls-logo-sm.png" "$STAGE/" 2>/dev/null || true
cp "$ROOT/kitchenos-launch-site/robots.txt" "$ROOT/kitchenos-launch-site/sitemap.xml" "$ROOT/kitchenos-launch-site/404.html" "$STAGE/" 2>/dev/null || true
cp "$ROOT/kitchenos-launch-site/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true


# i18n: the landing's language selector needs the locale catalogs (this was
# once dropped, leaving the selector with a single English option)
cp -r "$ROOT/kitchenos-launch-site/localize" "$STAGE/localize" 2>/dev/null || { echo "ABORT: localize/ missing from kitchenos-launch-site" >&2; exit 1; }
cp -r "$STK_SRC/enterprise/dist/." "$STAGE/premium/"
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
sed -i "s|https://github.com/RHLS-softdev/kitchenos-launch/releases/latest/download/KitchenOS-0.6.0-linux-amd64.deb|https://github.com/$USER/$REPO/releases/latest/download/$DEB_NAME|" "$STAGE/index.html"

echo "== committing to main =="
cd "$STAGE"
git init -q -b main 2>/dev/null || (git init -q && git checkout -q -b main 2>/dev/null || true)
git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
git add -A && git commit -qm "deploy: landing + KitchenOS premium web app" || true
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

echo "== publishing Release assets =="
DEB="$ROOT/$DEB_NAME"
if [ ! -f "$DEB" ]; then
  echo "  copying freshly built .deb"
  cp "$STK_SRC/desktop/src-tauri/target/release/bundle/deb/KitchenOS_${VERSION}_amd64.deb" "$DEB"
fi
ZIP="$ROOT/$ZIP_NAME"
if [ ! -f "$ZIP" ]; then
  echo "  building $ZIP from project source (excl. node_modules/dist/target/venv/models)"
  PKG="$ROOT/.kitchenos-release-src"
  rm -rf "$PKG"; mkdir -p "$PKG/KitchenOS-$VERSION"
  tar --exclude='*/node_modules' --exclude='*/dist' --exclude='*/target' \
      --exclude='*/venv' --exclude='*/models' --exclude='*/build' \
      --exclude='*/binaries' --exclude='*/instance' \
      --exclude='*/.git' --exclude='*/.env.local' \
      --exclude='*/__pycache__' \
      -C "$STK_SRC" -cf - . | tar -C "$PKG/KitchenOS-$VERSION" -xf -
  (cd "$PKG" && zip -qr "$ZIP" "KitchenOS-$VERSION")
  rm -rf "$PKG"
  echo "  zip ready: $ZIP"
fi

TAG="kitchenos-$VERSION"
REL=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  -X POST "$BASE_URL/releases" -d "{\"tag_name\":\"$TAG\",\"name\":\"KitchenOS $VERSION\",\"body\":\"KitchenOS $VERSION — the free offline desktop app (Linux .deb) plus the premium web app source (enterprise/, Convex+Clerk+Stripe). Roadmap: free tier complete (Stages 1-3), premium tier buildable and deployed; AI analytics intentionally not started. See the repo roadmap.md and enterprise/README.md.\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || true)
if [ -n "${REL:-}" ]; then
  # uploads.github.com is the real endpoint; api.github.com only 302s there.
  curl -sL -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/vnd.debian.binary-package" \
    --data-binary @"$DEB" \
    "https://uploads.github.com/repos/$USER/$REPO/releases/$REL/assets?name=$DEB_NAME" >/dev/null
  curl -sL -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @"$ZIP" \
    "https://uploads.github.com/repos/$USER/$REPO/releases/$REL/assets?name=$ZIP_NAME" >/dev/null
  echo "assets released"
fi

echo "== registering app origin in Clerk (if CLERK_SECRET_KEY set) =="
SK="${CLERK_SECRET_KEY:-}"
if [ -n "$SK" ]; then
  curl -s -X PATCH -H "Authorization: Bearer $SK" -H "Content-Type: application/json" \
    "https://api.clerk.com/v1/instance" \
    -d "{\"allowed_origins\":[\"$SITE_URL/premium/\"]}" >/dev/null || true
  echo "Clerk origin registered: $SITE_URL/premium/"
else
  echo "  (CLERK_SECRET_KEY not set — skipping Clerk origin registration; see enterprise/README.md)"
fi

echo "== URLs =="
echo "  Landing: $SITE_URL/"
echo "  Premium: $SITE_URL/premium/"
echo "  Release: https://github.com/$USER/$REPO/releases/latest"
echo "  (Pages takes ~1 min to go live; verify with:)"
echo "  curl -s -o /dev/null -w '%{http_code}' '$SITE_URL/premium/'"
