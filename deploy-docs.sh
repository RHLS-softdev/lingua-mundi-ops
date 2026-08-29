#!/usr/bin/env bash
# deploy-docs.sh — pushes the README documentation to every RHLS-softdev repo.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"

# push from an existing git stage (backup/ops stages)
push_stage() { # $1 = stage dir, $2 = repo, $3 = commit msg
  local stage="$1" repo="$2" msg="$3"
  cd "$stage"
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git add -A
  git diff --cached --quiet && { echo "[docs] $repo: no changes"; return 0; }
  git commit -qm "$msg"
  git push -q -f origin main && echo "[docs] pushed $repo"
}

# fetch a repo, drop files in, commit, push
push_files() { # $1 = repo, $2 = local file, $3 = dest path in repo, $4 = commit msg
  local repo="$1" file="$2" dest="$3" msg="$4"
  local stage="$ROOT/.docs-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"; cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main && git checkout -q FETCH_HEAD -b main 2>/dev/null || true
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
  git add -A
  git diff --cached --quiet && { echo "[docs] $repo: no changes"; return 0; }
  git commit -qm "$msg"
  git push -q -f origin main && echo "[docs] pushed $repo"
}

# 1. ops repo: README + synced launch-site READMEs (stage exists)
cp "$ROOT/subtitle-toolkit-launch-site/README.md" "$ROOT/.backup-stage/lingua-mundi-ops/subtitle-toolkit-launch-site/README.md" 2>/dev/null || true
cp "$ROOT/kitchenos-launch-site/README.md" "$ROOT/.backup-stage/lingua-mundi-ops/kitchenos-launch-site/README.md" 2>/dev/null || true
cp "$ROOT/launch-site/README.md" "$ROOT/.backup-stage/lingua-mundi-ops/launch-site/README.md" 2>/dev/null || true
push_stage "$ROOT/.backup-stage/lingua-mundi-ops" lingua-mundi-ops "docs: ops hub README + launch-site READMEs"

# 2. source backup repos (stages exist)
push_stage "$ROOT/.backup-stage/subtitle-toolkit" subtitle-toolkit "docs: deployment + Android companion section"
push_stage "$ROOT/.backup-stage/kitchenos" kitchenos "docs: deployment + Android companion section"

# 3. shikibu + lingua-mundi (no local stage — fetch-push README)
push_files shikibu "$ROOT/Shikibu/README.md" README.md "docs: repo README"
push_files lingua-mundi "$ROOT/LinguaMundi/lingua-mundi/README.md" README.md "docs: deployment section"

# 4. launch repos: add README.md (index/styles untouched)
push_files subtitle-toolkit-launch "$ROOT/subtitle-toolkit-launch-site/README.md" README.md "docs: launch repo README"
push_files kitchenos-launch "$ROOT/kitchenos-launch-site/README.md" README.md "docs: launch repo README"
push_files lingua-mundi-launch "$ROOT/launch-site/README.md" README.md "docs: launch repo README"

echo "[docs] done"
