#!/usr/bin/env bash
# deploy-brand.sh — pushes the RHLS branding (logo/favicon/palette) +
# localized-links READMEs to all repos.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"

push_site() { # repo, local dir
  local repo="$1" dir="$2"
  local stage="$ROOT/.brand-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"; cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main && git checkout -q FETCH_HEAD -b main 2>/dev/null || true
  cp -r "$dir"/{index.html,styles.css,README.md,AGENTS.md,rhls-logo.png,favicon.png} "$stage/" 2>/dev/null || true
  rm -rf "$stage/localize"; cp -r "$dir/localize" "$stage/localize" 2>/dev/null || true
  git add -A
  git diff --cached --quiet && { echo "$repo: no change"; return; }
  git commit -qm "brand: RHLS logo + studio palette + localized README header"
  git push -q -f origin main && echo "$repo: pushed"
}
push_files() { # repo, local file, dest
  local repo="$1" file="$2" dest="$3"
  local stage="$ROOT/.brand-stage/f-$repo"
  rm -rf "$stage"; mkdir -p "$stage"; cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main && git checkout -q FETCH_HEAD -b main 2>/dev/null || true
  mkdir -p "$(dirname "$dest")"; cp "$file" "$dest"
  git add -A
  git diff --cached --quiet && { echo "$repo: no change"; return; }
  git commit -qm "brand: RHLS logo + localized README header"
  git push -q -f origin main && echo "$repo: pushed"
}

push_site subtitle-toolkit-launch "$ROOT/subtitle-toolkit-launch-site"
push_site kitchenos-launch "$ROOT/kitchenos-launch-site"
push_site lingua-mundi-launch "$ROOT/launch-site"
push_files shikibu "$ROOT/Shikibu/README.md" README.md
push_files lingua-mundi "$ROOT/LinguaMundi/lingua-mundi/README.md" README.md
push_files subtitle-toolkit "$ROOT/.backup-stage/subtitle-toolkit/README.md" README.md
push_files kitchenos "$ROOT/.backup-stage/kitchenos/README.md" README.md
# ops repo: README + the branded launch-site sources + logo
cp "$ROOT/launch-site/README.md" "$ROOT/.backup-stage/lingua-mundi-ops/launch-site/README.md"
cp "$ROOT/launch-site/index.html" "$ROOT/.backup-stage/lingua-mundi-ops/launch-site/index.html"
cp "$ROOT/launch-site/styles.css" "$ROOT/.backup-stage/lingua-mundi-ops/launch-site/styles.css"
cp "$ROOT/launch-site/rhls-logo.png" "$ROOT/.backup-stage/lingua-mundi-ops/launch-site/rhls-logo.png"
cd "$ROOT/.backup-stage/lingua-mundi-ops" && git add -A && git diff --cached --quiet || {
  git commit -qm "brand: RHLS logo + localized README header + branded Lingua Mundi landing source"
  git push -q -f origin main && echo "lingua-mundi-ops: pushed"; }
echo "[deploy-brand] done"
