#!/usr/bin/env bash
# deploy-localize.sh — pushes the localized landing pages (localize/ +
# index.html + styles.css) to the three launch repos.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"

push_site() { # repo, local dir
  local repo="$1" dir="$2"
  local stage="$ROOT/.l10n-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"; cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main && git checkout -q FETCH_HEAD -b main 2>/dev/null || true
  cp -r "$dir/index.html" "$dir/styles.css" "$dir/README.md" "$dir/AGENTS.md" "$stage/" 2>/dev/null || true
  rm -rf "$stage/localize"; cp -r "$dir/localize" "$stage/localize"
  git add -A
  git diff --cached --quiet && { echo "$repo: no changes"; return; }
  git commit -qm "i18n: localize landing (es, ja, zh-Hans, zh-Hant, yue, hi, ar, ko) + switcher"
  git push -q -f origin main && echo "$repo: pushed"
}

push_site subtitle-toolkit-launch "$ROOT/subtitle-toolkit-launch-site"
push_site kitchenos-launch "$ROOT/kitchenos-launch-site"
push_site lingua-mundi-launch "$ROOT/launch-site"
echo "[deploy-localize] done"
