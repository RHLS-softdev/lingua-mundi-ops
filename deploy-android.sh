#!/usr/bin/env bash
# deploy-android.sh — attaches the three companion APKs to their launch
# repos' existing releases and pushes the Android sections on the landing
# pages (index.html edits in subtitle-toolkit-launch-site/,
# kitchenos-launch-site/, and the Shikibu download area of the Lingua
# Mundi launch site via lingua-mundi-launch).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"

upload_asset() { # $1 = repo, $2 = release tag, $3 = file
  local repo="$1" tag="$2" file="$3"
  local rel_id
  rel_id=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$USER/$repo/releases/tags/$tag" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
  [ -n "$rel_id" ] || { echo "[deploy] release $tag not found in $repo"; return 1; }
  # Replace same-named asset: GitHub rejects duplicate filenames, so delete
  # any existing asset first (idempotent re-deploys).
  local old_id
  old_id=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$USER/$repo/releases/$rel_id/assets" \
    | python3 -c "import json,sys; name='$(basename "$file")'; [print(a['id']) for a in json.load(sys.stdin) if a['name']==name]" 2>/dev/null)
  if [ -n "$old_id" ]; then
    curl -s -X DELETE -H "Authorization: token $GH_TOKEN" \
      "https://api.github.com/repos/$USER/$repo/releases/assets/$old_id" >/dev/null
    echo "[deploy] removed old $(basename "$file")"
  fi
  curl -sL -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/vnd.android.package-archive" \
    --data-binary @"$file" \
    "https://uploads.github.com/repos/$USER/$repo/releases/$rel_id/assets?name=$(basename "$file")" >/dev/null
  echo "[deploy] uploaded $(basename "$file") -> $repo release $tag"
}

upload_asset subtitle-toolkit-launch subtitle-toolkit-0.2.0 "$ROOT/Subtitle-Toolkit-0.2.0-android.apk"
upload_asset kitchenos-launch kitchenos-0.6.0 "$ROOT/KitchenOS-Premium-0.6.0-android.apk"
upload_asset lingua-mundi-launch shikibu-1.0.0 "$ROOT/Shikibu-1.0.0-android.apk"

# ---- landing pages: commit the Android sections ----
push_landing() { # $1 = repo, $2 = local dir
  local repo="$1" dir="$2"
  local stage="$ROOT/.landing-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"
  cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main && git checkout -q FETCH_HEAD -b main 2>/dev/null || true
  cp "$dir/index.html" "$dir/styles.css" "$stage/" 2>/dev/null || true
  git add -A
  git diff --cached --quiet && { echo "[deploy] $repo landing unchanged"; return 0; }
  git commit -qm "deploy: Android companion app download links"
  git push -q -f origin main && echo "[deploy] pushed $repo landing"
}

push_landing subtitle-toolkit-launch "$ROOT/subtitle-toolkit-launch-site"
push_landing kitchenos-launch "$ROOT/kitchenos-launch-site"
push_landing lingua-mundi-launch "$ROOT/launch-site"
echo "[deploy] done"
