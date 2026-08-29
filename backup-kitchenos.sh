#!/usr/bin/env bash
# backup-kitchenos.sh — backs up the KitchenOS source to the RHLS-softdev
# GitHub account, mirroring the Shikibu/Subtitle-Toolkit backup pattern:
#   kitchenos  - the app source (excl. node_modules/dist/target/venv/models
#                and other machine-local build artifacts — the .deb release
#                asset on kitchenos-launch is the ready installer)
# Secrets and caches are NEVER pushed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
STK_SRC="${STK_SRC:-$ROOT/.kitchenos-build}"

USER=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])")
echo "backing up as $USER"

make_repo() { # $1 = name, $2 = description
  curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"$1\",\"description\":\"$2\",\"private\":false}" >/dev/null 2>&1 || true
  echo "repo ready: $1"
}

push_dir() { # $1 = repo name, $2 = source dir, $3 = commit msg
  local repo="$1"
  local src="$2"
  local msg="$3"
  local stage="$ROOT/.backup-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"
  tar --exclude='*/node_modules' --exclude='*/dist' --exclude='*/target' \
      --exclude='*/venv' --exclude='*/models' --exclude='*/build' \
      --exclude='*/binaries' --exclude='*/instance' \
      --exclude='*/.git' --exclude='*/.env.local' \
      --exclude='*/__pycache__' \
      -C "$src" -cf - . | tar -C "$stage" -xf -
  cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git add -A
  if git diff --cached --quiet; then echo "  (nothing new in $repo)"; cd "$ROOT"; return; fi
  git commit -qm "$msg"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null || \
    git remote set-url origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git"
  git push -q -f origin main
  echo "  pushed $repo"
  cd "$ROOT"
}

make_repo "kitchenos" "KitchenOS - offline-first kitchen management (source backup; build artifacts excluded)"
push_dir "kitchenos" "$STK_SRC" "backup: KitchenOS 0.6.0 source"

echo
echo "== backup URLs =="
echo "  https://github.com/$USER/kitchenos"
